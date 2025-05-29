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

    logic busy;
    int index, select;
    cbus_req_t saved_req, selected_req;

    // assign oreq_middle = ireqs[index];
    assign oreq_middle = busy ? ireqs[index] : '0;  // prevent early issue
    assign selected_req = ireqs[select];

    // select a preferred request
    always_comb begin
        select = 0;

        for (int i = 0; i < NUM_INPUTS; i++) begin
            if (ireqs[i].valid) begin
                select = i;
                break;
            end
        end
    end

    // feedback to selected request
    always_comb begin
        iresps = '0;

        if (busy) begin
            for (int i = 0; i < NUM_INPUTS; i++) begin
                if (index == i)
                    iresps[i] = oresp_middle;
            end
        end
    end

    always_ff @(posedge clk or posedge reset)
    if (reset) begin
        {busy, index, saved_req} <= '0;
    end else begin
        if (busy) begin
            if (oresp_middle.last)
                {busy, saved_req} <= '0;
        end else begin
            // if not valid, busy <= 0
            busy <= selected_req.valid;
            index <= select;
            saved_req <= selected_req;
        end
    end

    `UNUSED_OK({saved_req});
endmodule



`endif