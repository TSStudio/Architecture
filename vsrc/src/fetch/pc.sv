`ifdef VERILATOR
`include "include/common.sv"
`endif

module programCounter import common::*;(
    input logic clk,rst,
    input u64 pcIn,
    input logic pcInEn,
    input logic lwHold,
    output REG_IF_ID moduleOut,

    input ibus_resp_t ibus_resp,
    output ibus_req_t ibus_req,

    output logic ok_to_proceed,
    input logic ok_to_proceed_overall
);

u64 curPC;
u64 nextPC;

u32 instr_n;

initial begin
    curPC = PCINIT;
    nextPC = PCINIT+4;
    ibus_req.addr = curPC;
    ibus_req.valid = 1;
    moduleOut.valid = 0;
    ok_to_proceed = 0;
end

always_ff @(posedge clk or posedge rst) begin
    if(ok_to_proceed_overall) begin
        moduleOut.valid <= 1;
        moduleOut.pcPlus4 <= curPC+4;
        moduleOut.instr <= instr_n;
        moduleOut.instrAddr <= curPC;

        curPC <= nextPC;
        ibus_req.addr <= nextPC;
        ibus_req.valid <= 1;
        ok_to_proceed <= 0;
        nextPC <= nextPC + 4;

    end
    if (ibus_resp.addr_ok & ibus_resp.data_ok) begin
        ok_to_proceed <= 1;
        instr_n <= ibus_resp.data;
        ibus_req.valid <= 0;
    end
end

endmodule