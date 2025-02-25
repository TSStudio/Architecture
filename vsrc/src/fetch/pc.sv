`ifdef VERILATOR
`include "include/common.sv"
`endif

module programCounter import common::*;(
    input logic clk,rst,
    input u64 pcIn,
    input logic pcInEn,
    input logic bubbleHold,
    input logic lwHold,
    output REG_IF_ID moduleOut,

    input ibus_resp_t ibus_resp,
    output ibus_req_t ibus_req
);

u64 curPC;
u64 nextPC;

logic hold;
assign hold = bubbleHold | lwHold | (~(ibus_resp.addr_ok&ibus_resp.data_ok));
logic curPCSent;

initial begin
    curPC = PCINIT;
    nextPC = PCINIT+4;
    ibus_req.addr = curPC;
    ibus_req.valid = 1;
    curPCSent = 0;
    moduleOut.valid = 0;
end

always_ff @(posedge clk or posedge rst) begin
    if(hold) begin
        moduleOut.valid <= 0;
    end else begin
        moduleOut.valid <= 1;
        moduleOut.pcPlus4 <= nextPC;
        moduleOut.instr <= ibus_resp.data;
        moduleOut.instrAddr <= curPC;
        curPCSent = 1;
    end
end

always_ff @(negedge clk) begin
    if (curPCSent) begin
        curPC <= nextPC;
        nextPC <= nextPC + 4;
        ibus_req.addr <= nextPC;
        ibus_req.valid <= 1;
        curPCSent = 0;
    end
end

endmodule