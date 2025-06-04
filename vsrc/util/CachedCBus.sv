`ifdef VERILATOR
`include "include/common.sv"
`endif

// typedef struct packed {
//     logic    valid;     // in request?
//     logic    is_write;  // is it a write transaction?
//     msize_t  size;      // number of bytes in one burst, use MLEN8 for 8 bytes
//     addr_t   addr;      // start address
//     strobe_t strobe;    // which bytes are enabled?
//     word_t   data;      // the data to write
//     mlen_t   len;       // number of bursts, use MLEN1
//     axi_burst_type_t burst; // use AXI_BURST_FIXED
// } cbus_req_t;

// typedef struct packed {
//     logic  ready;       // is data arrived in this cycle?
//     logic  last;        // is it the last word?
//     word_t data;        // the data from AXI bus
// } cbus_resp_t;

/**
 * NOTE on strobe:
 *
 * strobe is used to mask out unused bytes in data, and
 * data are always assumed be placed at addresses aligned to
 * 8 bytes, no matter the lowest 3 bits of addr says.
 * for example, if you want to write one byte "0xcd" at 0x1f2,
 * the addr is "0x000001f2", but the data should be "0x00cd0000"
 * and the strobe should be "0b0100", rather than "0x000000cd"
 * and "0b0001".
 */

module CachedCBus import common::*;(
    input logic clk, reset,
    input  cbus_req_t request_from_mmu,
    output cbus_resp_t response_to_mmu,
    output cbus_req_t request_to_mem,
    input  cbus_resp_t response_from_mem
);

// 状态：0: 等待请求
//      1: （不在缓存中）请求内存，正在等待响应
//      2: （不在缓存中）写入缓存，
//      3: 腾出缓存空间（LRU）请求写入内存，正在等待响应
//      4: （在缓存中）直接响应并更新 LRU（time stamp）

// 0->1：当有请求，且缓存中没有该请求的地址时。此时应当向总线发起请求。
// 0->4：当有请求，且缓存中有该请求的地址时。此时应当直接响应，并更新LRU（time stamp）。应当将返回的 ready 设为 1。
// 1->3：当请求结束，并且对应的set中没有空闲line时。若timestamp较小的line有脏标记，向总线发请求写入这个line。
// 1->2：当请求结束，并且对应的set中有空闲line时。向缓存写入数据。
// 3->2：腾出空间的响应结束，这时应当向缓存写入新数据。
// 2->4：向缓存写入数据结束，这时应当直接响应，并更新LRU（time stamp）。
// 4->0：直接转移到0，4会持续 1 个周期。
typedef struct packed {
    logic valid;
    logic dirty;
    logic[55:0] tag;
    u64 time_stamp;
    u64 data;
} cache_line_t;

cache_line_t cache[0:31][0:1]; // 32 sets, 2 lines per set

u3 state;
localparam S_IDLE = 3'b000;
localparam S_WAITING_FOR_CURRENT_MEMORY = 3'b001;
localparam S_OK = 3'b010;
localparam S_WAITING_FOR_CACHE_EVICT = 3'b011;
localparam S_RESPONDING = 3'b100;
localparam S_DIRECT_MEMORY = 3'b101; // use for direct memory access without cache
u64 strobe_mask;

assign strobe_mask={{8{request_from_mmu.strobe[7]}}, {8{request_from_mmu.strobe[6]}}, {8{request_from_mmu.strobe[5]}}, {8{request_from_mmu.strobe[4]}}, {8{request_from_mmu.strobe[3]}}, {8{request_from_mmu.strobe[2]}}, {8{request_from_mmu.strobe[1]}}, {8{request_from_mmu.strobe[0]}}};
u64 temp_data;
u64 new_data;

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        response_to_mmu <= '0;
        request_to_mem <= '0;
        state <= S_IDLE;
        for (int i = 0; i < 32; i++)
            for (int j = 0; j < 2; j++)
                cache[i][j] <= '{valid:0, dirty:0, tag:'0, time_stamp:'0, data:'0};
    end else begin
        int hit_idx, free_idx, lru_idx, idx;
        u64 min_time;
        logic [4:0] set_idx;
        logic [55:0] tag;
        set_idx = request_from_mmu.addr[7:3];
        tag = request_from_mmu.addr[63:8];
        unique case (state)
        S_IDLE: begin
            if (request_from_mmu.valid) begin
                if(request_from_mmu.addr[31]==0 ) begin
                    state <= S_DIRECT_MEMORY;
                    request_to_mem <= request_from_mmu;
                end else begin
                    hit_idx = -1;
                    for (int i = 0; i < 2; i++) begin
                        if (cache[set_idx][i].valid && cache[set_idx][i].tag == tag) begin
                            hit_idx = i;
                        end
                    end
                    if (hit_idx != -1) begin
                        response_to_mmu <= '{ready:1, last:1, data:cache[set_idx][hit_idx].data};
                        cache[set_idx][hit_idx].time_stamp <= $time;
                        if (request_from_mmu.is_write) begin
                            cache[set_idx][hit_idx].data <= (request_from_mmu.data & strobe_mask) | (cache[set_idx][hit_idx].data & ~strobe_mask);
                            cache[set_idx][hit_idx].dirty <= 1;
                        end
                        state <= S_OK;
                    end else begin
                        request_to_mem <= '{
                            valid: 1,
                            is_write: 0,
                            size: MSIZE8,
                            addr: {tag, set_idx, 3'b0},
                            strobe: 8'hFF,
                            data: '0,
                            len: MLEN1,
                            burst: AXI_BURST_FIXED
                        };
                        state <= S_WAITING_FOR_CURRENT_MEMORY;
                    end
                end
            end
        end
        S_WAITING_FOR_CURRENT_MEMORY: begin
            if (response_from_mem.ready) begin
                request_to_mem.valid <= 0; // reset request to memory
                free_idx = -1;
                lru_idx = 0;
                min_time = cache[set_idx][0].time_stamp;
                temp_data = response_from_mem.data;
                for (int i = 0; i < 2; i++) begin
                    if (!cache[set_idx][i].valid) free_idx = i;
                    if (cache[set_idx][i].time_stamp < min_time) begin
                        min_time = cache[set_idx][i].time_stamp;
                        lru_idx = i;
                    end
                end
                if (free_idx != -1) begin
                    // 写入cache，按strobe
                    new_data = request_from_mmu.is_write ? ((request_from_mmu.data & strobe_mask) | (response_from_mem.data & ~strobe_mask)) : response_from_mem.data;
                    cache[set_idx][free_idx] <= '{valid:1, dirty:request_from_mmu.is_write, tag:tag, time_stamp:$time, data:new_data};
                    response_to_mmu <= '{ready:1, last:1, data:new_data};
                    state <= S_RESPONDING;
                end else if (cache[set_idx][lru_idx].dirty) begin
                    request_to_mem <= '{
                        valid:1,
                        is_write:1,
                        size:MSIZE8,
                        addr:{cache[set_idx][lru_idx].tag, set_idx, 3'b0},
                        strobe:8'hFF,
                        data:cache[set_idx][lru_idx].data,
                        len:MLEN1,
                        burst:AXI_BURST_FIXED
                    };
                    state <= S_WAITING_FOR_CACHE_EVICT;
                end else begin
                    new_data = request_from_mmu.is_write ? ((request_from_mmu.data & strobe_mask) | (response_from_mem.data & ~strobe_mask)) : response_from_mem.data;
                    cache[set_idx][lru_idx] <= '{valid:1, dirty:request_from_mmu.is_write, tag:tag, time_stamp:$time, data:new_data};
                    response_to_mmu <= '{ready:1, last:1, data:new_data};
                    state <= S_RESPONDING;
                end
            end
        end
        S_WAITING_FOR_CACHE_EVICT: begin
            if (response_from_mem.ready) begin
                request_to_mem.valid <= 0; // reset request to memory
                lru_idx = (cache[set_idx][0].time_stamp < cache[set_idx][1].time_stamp) ? 0 : 1;
                new_data = request_from_mmu.is_write ? ((request_from_mmu.data & strobe_mask) | (temp_data & ~strobe_mask)) : temp_data;
                cache[set_idx][lru_idx] <= '{valid:1, dirty:request_from_mmu.is_write, tag:tag, time_stamp:$time, data:new_data};
                response_to_mmu <= '{ready:1, last:1, data:new_data};
                state <= S_RESPONDING;
            end
        end
        S_DIRECT_MEMORY: begin
            if (response_from_mem.ready) begin
                response_to_mmu <= '{ready:1, last:1, data:response_from_mem.data};
                request_to_mem <= '0; // reset request to memory
                state <= S_OK;
            end
        end
        S_RESPONDING: begin
            idx = -1;
            for (int i = 0; i < 2; i++) begin
                if (cache[set_idx][i].tag == tag && cache[set_idx][i].valid) idx = i;
            end

            
            if (idx != -1) cache[set_idx][idx].time_stamp <= $time;
            response_to_mmu <= '{default:0};
            state <= S_IDLE;
        end
        S_OK: begin
            state <= S_IDLE;
            response_to_mmu <= '{default:0};
        end
        default: state <= S_IDLE;
        endcase
    end
end

endmodule