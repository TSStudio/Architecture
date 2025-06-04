`ifndef __CBUSARBITER_SV
`define __CBUSARBITER_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "util/mmu.sv"
`include "util/CachedCBus.sv"
`else

`endif
/**
 * this implementation is not efficient, since
 * it adds one cycle lantency to all requests.
 */
`define UNUSED_OK(list) \
    logic _unused_ok = &{1'b0, {list}, 1'b0};

module CBusArbiter
	import common::*;#(
    parameter int NUM_INPUTS = 2,  // NOTE: NUM_INPUTS >= 1

    localparam int MAX_INDEX = NUM_INPUTS - 1
) (
    input logic clk, reset,

    input  cbus_req_t  [MAX_INDEX:0] ireqs,
    output cbus_resp_t [MAX_INDEX:0] iresps,
    output cbus_req_t  oreq,
    input  cbus_resp_t oresp,
    input u64 satp,
    input u2 priviledgeMode,
    output logic skip
);
    cbus_req_t oreq_middle,oreq_middle2;
    cbus_resp_t oresp_middle,oresp_middle2;

    CachedCBus cached_cbus(
        .clk(clk),
        .reset(reset),
        .request_from_mmu(oreq_middle2),
        .response_to_mmu(oresp_middle2),
        .request_to_mem(oreq),
        .response_from_mem(oresp)
    );
    mmu vmemory(
        .clk(clk),
        .rst(reset),
        .satp(satp),
        .priviledgeMode(priviledgeMode),
        .cbus_req_from_core(oreq_middle),
        .dummy_cbus_resp_to_core(oresp_middle),
        .cbus_req_to_mem(oreq_middle2),
        .cbus_resp_from_mem(oresp_middle2),
        .skip(skip)
    );

    integer selected;
    logic selected_busy;
    integer smallest_valid_index;
    assign selected_busy = oreq_middle.valid;
    always_comb begin
        smallest_valid_index = -1;
        for (int i = 0; i < NUM_INPUTS; i++) begin
            if (ireqs[i].valid) begin
                smallest_valid_index = i;
                break;
            end
        end
    end
    always_comb begin
        if(selected == -1) begin
            oreq_middle = '0;
            oreq_middle.valid = 0;
        end else begin
            oreq_middle = ireqs[selected];
        end
        for (int i = 0; i < NUM_INPUTS; i++) begin
            if (i == selected) begin
                iresps[i] = oresp_middle;
            end else begin
                iresps[i] = '0;
            end
        end
    end
    
    always_ff @(posedge clk or negedge clk) begin
        if(!selected_busy) begin 
            selected <= smallest_valid_index;
        end
    end
endmodule



`endif