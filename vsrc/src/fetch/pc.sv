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

logic curPCSent;

initial begin
    curPC = PCINIT;
    nextPC = PCINIT+4;
    ibus_req.addr = curPC;
    ibus_req.valid = 1;
    curPCSent = 0;
    moduleOut.valid = 0;
    ok_to_proceed = 0;
end

always_ff @(posedge clk or posedge rst) begin
    if(ok_to_proceed_overall) begin
        moduleOut.valid <= 1;
        moduleOut.pcPlus4 <= nextPC;
        moduleOut.instr <= ibus_resp.data;
        moduleOut.instrAddr <= curPC;
        curPCSent = 1;
    end
end

always_ff @(negedge clk) begin
    if (ibus_resp.addr_ok & ibus_resp.data_ok) begin
        ok_to_proceed <= 1;
    end
    if (curPCSent) begin
        curPC <= nextPC;
        nextPC <= nextPC + 4;
        ibus_req.addr <= nextPC;
        ibus_req.valid <= 1;
        curPCSent = 0;
        ok_to_proceed <= 0;
    end
end

endmodule