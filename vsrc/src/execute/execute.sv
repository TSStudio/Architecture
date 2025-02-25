`ifdef VERILATOR
`include "include/common.sv"
`include "src/execute/alu.sv"
`endif

module execute import common::*;(
    input logic clk,rst,
    input logic bubbleHold,
    input REG_ID_EX moduleIn,
    output REG_EX_MEM moduleOut,
    output FORWARD_SOURCE forwardSource
);

u64 ib;

assign ib=moduleIn.srcB?moduleIn.imm:moduleIn.rs2;

u64 aluOut;
u64 pcBranch;

assign pcBranch=moduleIn.pcPlus4+(moduleIn.imm<<2);

alu alu(
    .clk(clk),
    .ia(moduleIn.rs1),
    .ib(ib),
    .aluOp(moduleIn.aluOp),
    .aluOut(aluOut)
);

initial begin
    moduleOut.valid = 0;
end

u64 aluOutProc;

assign aluOutProc = moduleIn.rv64 ? {{32{aluOut[31]}}, aluOut[31:0]}: aluOut;

assign forwardSource.valid = moduleIn.valid;
assign forwardSource.isWb = moduleIn.isWriteBack;
assign forwardSource.wd = moduleIn.wd;
assign forwardSource.wdData = aluOutProc;

always_ff @(posedge (clk & ~bubbleHold) or posedge rst) begin
    if(rst) begin
        moduleOut.valid <= 0;
    end else begin
        moduleOut.valid <= moduleIn.valid ;
        moduleOut.rs2 <= moduleIn.rs2;
        moduleOut.aluOut <= aluOutProc;
        moduleOut.isWriteBack <= moduleIn.isWriteBack;
        moduleOut.wd <= moduleIn.wd;
        moduleOut.isBranch <= moduleIn.isBranch;
        moduleOut.pcBranch <= pcBranch;

        moduleOut.isMemRead <= moduleIn.isMemRead;
        moduleOut.isMemWrite <= moduleIn.isMemWrite;
        moduleOut.memMode <= moduleIn.memMode;

        moduleOut.instrAddr <= moduleIn.instrAddr;
        moduleOut.instr <= moduleIn.instr;
    end
end


endmodule