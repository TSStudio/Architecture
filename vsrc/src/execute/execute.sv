`ifdef VERILATOR
`include "include/common.sv"
`include "src/execute/alu.sv"
`endif

module execute import common::*;(
    input logic clk,rst,
    input logic bubbleHold,
    input REG_ID_EX moduleIn,
    output REG_EX_MEM moduleOut
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

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        moduleOut.valid = 0;
    end else begin
        moduleOut.valid = moduleIn.valid & ~bubbleHold;
        moduleOut.rs2 = moduleIn.rs2;
        moduleOut.aluOut = aluOut;
        moduleOut.isWriteBack = moduleIn.isWriteBack;
        moduleOut.wd = moduleIn.wd;
        moduleOut.isBranch = moduleIn.isBranch;
        moduleOut.pcBranch = pcBranch;

        moduleOut.instrAddr = moduleIn.instrAddr;
        moduleOut.instr = moduleIn.instr;
    end
end


endmodule