`ifdef VERILATOR
`include "include/common.sv"
`endif

module mmu import common::*;(
    input logic clk,rst,
    input u64 satp,
    input u2 priviledgeMode,
    input cbus_req_t cbus_req_from_core,
    output cbus_resp_t dummy_cbus_resp_to_core,
    output cbus_req_t cbus_req_to_mem,
    output logic skip,
    input cbus_resp_t cbus_resp_from_mem
);

u3 state;// 0: idle, 1: l2, 2: l1, 3: l0, 4:mem, 5: ok

`ifndef VERILATOR
logic ok_2_state;
u64 temp;
`endif

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= 0;
        cbus_req_to_mem.valid <= 0;
        dummy_cbus_resp_to_core.ready <= 0;
        skip <= 0;
        `ifndef VERILATOR
        ok_2_state <= 0;
        `endif
    end else begin
        case (state)
            0: begin
                if (cbus_req_from_core.valid) begin
                    if(priviledgeMode==3 || satp[63:60]==0) begin
                        state <= 4;
                        cbus_req_to_mem.valid <= 1;
                        cbus_req_to_mem.is_write <= cbus_req_from_core.is_write;
                        cbus_req_to_mem.size <= cbus_req_from_core.size;
                        cbus_req_to_mem.addr <= cbus_req_from_core.addr;
                        cbus_req_to_mem.strobe <= cbus_req_from_core.strobe;
                        cbus_req_to_mem.data <= cbus_req_from_core.data;
                        cbus_req_to_mem.len <= cbus_req_from_core.len;
                        cbus_req_to_mem.burst <= cbus_req_from_core.burst;
                        skip <= cbus_req_from_core.addr[31]==0;
                    end else begin
                        state <= 1;
                        cbus_req_to_mem.valid <= 1;
                        cbus_req_to_mem.is_write <= 0;
                        cbus_req_to_mem.size <= MSIZE8;
                        cbus_req_to_mem.addr <= {8'b0, satp[43:0], 12'b0}+{52'b0, cbus_req_from_core.addr[38:30], 3'b0};
                        cbus_req_to_mem.strobe <= 0;
                        cbus_req_to_mem.data <= 0;
                        cbus_req_to_mem.len <= MLEN1;
                        cbus_req_to_mem.burst <= AXI_BURST_FIXED;
                    end
                end
            end
            1: begin
                `ifdef VERILATOR
                if (cbus_resp_from_mem.ready&&cbus_resp_from_mem.last) begin
                    state <= 2;
                    cbus_req_to_mem.valid <= 1;
                    cbus_req_to_mem.is_write <= 0;
                    cbus_req_to_mem.size <= MSIZE8;
                    cbus_req_to_mem.addr <= {8'b0, cbus_resp_from_mem.data[53:10], 12'b0}+{52'b0, cbus_req_from_core.addr[29:21],3'b0};
                    cbus_req_to_mem.strobe <= 0;
                    cbus_req_to_mem.data <= 0;
                    cbus_req_to_mem.len <= MLEN1;
                    cbus_req_to_mem.burst <= AXI_BURST_FIXED;
                end
                `else
                if (cbus_resp_from_mem.ready&&cbus_resp_from_mem.last) begin
                    if(ok_2_state) begin
                        ok_2_state <= 0;
                        state <= 2;
                        cbus_req_to_mem.valid <= 1;
                        cbus_req_to_mem.is_write <= 0;
                        cbus_req_to_mem.size <= MSIZE8;
                        cbus_req_to_mem.addr <= {8'b0, temp[53:10], 12'b0}+{52'b0, cbus_req_from_core.addr[29:21],3'b0};
                        cbus_req_to_mem.strobe <= 0;
                        cbus_req_to_mem.data <= 0;
                        cbus_req_to_mem.len <= MLEN1;
                        cbus_req_to_mem.burst <= AXI_BURST_FIXED;
                    end else begin
                        ok_2_state <= 1;
                        temp <= cbus_resp_from_mem.data;
                    end
                end 
                `endif
            end
            2: begin
                `ifdef VERILATOR
                if (cbus_resp_from_mem.ready&&cbus_resp_from_mem.last) begin
                    state <= 3;
                    cbus_req_to_mem.valid <= 1;
                    cbus_req_to_mem.is_write <= 0;
                    cbus_req_to_mem.size <= MSIZE8;
                    cbus_req_to_mem.addr <= {8'b0, cbus_resp_from_mem.data[53:10],12'b0}+{52'b0, cbus_req_from_core.addr[20:12],3'b0};
                    cbus_req_to_mem.strobe <= 0;
                    cbus_req_to_mem.data <= 0;
                    cbus_req_to_mem.len <= MLEN1;
                    cbus_req_to_mem.burst <= AXI_BURST_FIXED;
                end
                `else
                if (cbus_resp_from_mem.ready&&cbus_resp_from_mem.last) begin
                    if(ok_2_state) begin
                        ok_2_state <= 0;
                        state <= 3;
                        cbus_req_to_mem.valid <= 1;
                        cbus_req_to_mem.is_write <= 0;
                        cbus_req_to_mem.size <= MSIZE8;
                        cbus_req_to_mem.addr <= {8'b0, temp[53:10], 12'b0}+{52'b0, cbus_req_from_core.addr[20:12],3'b0};
                        cbus_req_to_mem.strobe <= 0;
                        cbus_req_to_mem.data <= 0;
                        cbus_req_to_mem.len <= MLEN1;
                        cbus_req_to_mem.burst <= AXI_BURST_FIXED;
                    end else begin
                        ok_2_state <= 1;
                        temp <= cbus_resp_from_mem.data;
                    end
                end
                `endif
            end
            3: begin
                `ifdef VERILATOR
                if (cbus_resp_from_mem.ready&&cbus_resp_from_mem.last) begin
                    state <= 4;
                    cbus_req_to_mem.valid <= 1;
                    cbus_req_to_mem.is_write <= cbus_req_from_core.is_write;
                    cbus_req_to_mem.size <= cbus_req_from_core.size;
                    cbus_req_to_mem.addr <= {8'b0, cbus_resp_from_mem.data[53:10],cbus_req_from_core.addr[11:0]};
                    cbus_req_to_mem.strobe <= cbus_req_from_core.strobe;
                    cbus_req_to_mem.data <= cbus_req_from_core.data;
                    cbus_req_to_mem.len <= cbus_req_from_core.len;
                    cbus_req_to_mem.burst <= cbus_req_from_core.burst;
                    skip <= cbus_resp_from_mem.data[29]==0;
                end
                `else
                if (cbus_resp_from_mem.ready&&cbus_resp_from_mem.last) begin
                    if(ok_2_state) begin
                        ok_2_state <= 0;
                        state <= 4;
                        cbus_req_to_mem.valid <= 1;
                        cbus_req_to_mem.is_write <= cbus_req_from_core.is_write;
                        cbus_req_to_mem.size <= cbus_req_from_core.size;
                        cbus_req_to_mem.addr <= {8'b0, temp[53:10], cbus_req_from_core.addr[11:0]};
                        cbus_req_to_mem.strobe <= cbus_req_from_core.strobe;
                        cbus_req_to_mem.data <= cbus_req_from_core.data;
                        cbus_req_to_mem.len <= cbus_req_from_core.len;
                        cbus_req_to_mem.burst <= cbus_req_from_core.burst;
                        skip <= temp[29]==0;
                    end else begin
                        ok_2_state <= 1;
                        temp <= cbus_resp_from_mem.data;
                    end
                end
                `endif
            end
            4: begin
                if (cbus_resp_from_mem.ready&&cbus_resp_from_mem.last) begin
                    state <= 5;
                    cbus_req_to_mem.valid <= 0;
                    dummy_cbus_resp_to_core.ready <= 1;
                    dummy_cbus_resp_to_core.last <= 1;
                    dummy_cbus_resp_to_core.data <= cbus_resp_from_mem.data;
                end
            end
            5: begin
                state <= 0;
                dummy_cbus_resp_to_core.ready <= 0;
                dummy_cbus_resp_to_core.last <= 0;
                dummy_cbus_resp_to_core.data <= 0;
            end
        endcase
    end
end

endmodule