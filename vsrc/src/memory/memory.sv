`ifdef VERILATOR
`include "include/common.sv"
`endif

module memory import common::*;(
    input logic clk,rst,
    input logic bubbleHold,
    input REG_EX_MEM moduleIn,
    output REG_MEM_WB moduleOut
);

initial begin
    moduleOut.valid = 0;
end

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        moduleOut.valid <= 0;
    end else begin
        moduleOut.valid <= moduleIn.valid & ~bubbleHold;
        moduleOut.aluOut <= moduleIn.aluOut;
        moduleOut.isWriteBack <= moduleIn.isWriteBack;
        moduleOut.wd <= moduleIn.wd;
        moduleOut.isBranch <= moduleIn.isBranch;
        moduleOut.pcBranch <= moduleIn.pcBranch;
        moduleOut.memOut <= 0; //TODO
        moduleOut.instrAddr <= moduleIn.instrAddr;
        moduleOut.instr <= moduleIn.instr;
    end
end

endmodule