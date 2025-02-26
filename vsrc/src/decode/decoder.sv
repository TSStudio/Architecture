`ifdef VERILATOR
`include "include/common.sv"
`include "src/decode/maindecoder.sv"
`endif

module decoder import common::*;(
    input logic clk,rst,
    input logic bubbleHold,
    output logic lwHold,
    input REG_IF_ID moduleIn,
    output REG_ID_EX moduleOut,

    output u5 rs1, rs2,
    input u64 rs1Data, rs2Data,

    input FORWARD_SOURCE fwdSrc1, fwdSrc2
);

u64 imm;
u5 wd;
u3 aluOp;
logic isBranch, isWriteBack, srcB, isMemWrite, isMemRead;
u4 memMode;
logic rv64;
logic rvm;
u4 mulOp;

assign lwHold = isMemRead;

maindecoder maindecoder_inst(
    .instr(moduleIn.instr),
    .imm(imm),
    .rs1(rs1),
    .rs2(rs2),
    .wd(wd),
    .aluOp(aluOp),
    .mulOp(mulOp),
    .isBranch(isBranch),
    .isWriteBack(isWriteBack),
    .srcB(srcB),
    .isMemWrite(isMemWrite),
    .isMemRead(isMemRead),
    .rv64(rv64),
    .memMode(memMode),
    .rvm(rvm)
);

u64 rs1DataOutS1, rs1DataOutS2, rs2DataOutS1, rs2DataOutS2;

assign rs1DataOutS1 = fwdSrc1.valid & fwdSrc1.isWb & fwdSrc1.wd == rs1 ? fwdSrc1.wdData : rs1Data;
assign rs1DataOutS2 = fwdSrc2.valid & fwdSrc2.isWb & fwdSrc2.wd == rs1 ? fwdSrc2.wdData : rs1DataOutS1;

assign rs2DataOutS1 = fwdSrc1.valid & fwdSrc1.isWb & fwdSrc1.wd == rs2 ? fwdSrc1.wdData : rs2Data;
assign rs2DataOutS2 = fwdSrc2.valid & fwdSrc2.isWb & fwdSrc2.wd == rs2 ? fwdSrc2.wdData : rs2DataOutS1;

always_ff @(posedge (clk & ~bubbleHold) or posedge rst) begin
    if(rst) begin
        moduleOut.valid <= 0;
    end else begin
        moduleOut.valid <= moduleIn.valid & ~bubbleHold;
        moduleOut.pcPlus4 <= moduleIn.pcPlus4;
        moduleOut.srcB <= srcB;

        moduleOut.rs1 <= rs1DataOutS2;
        moduleOut.rs2 <= rs2DataOutS2;

        moduleOut.imm <= imm;
        moduleOut.isWriteBack <= isWriteBack;
        moduleOut.isMemRead <= isMemRead;
        moduleOut.isMemWrite <= isMemWrite;
        moduleOut.memMode <= memMode;
        moduleOut.wd <= wd;
        moduleOut.aluOp <= aluOp;
        moduleOut.mulOp <= mulOp;
        moduleOut.isBranch <= isBranch;
        moduleOut.rv64 <= rv64;
        moduleOut.rvm <= rvm;

        moduleOut.instrAddr <= moduleIn.instrAddr;
        moduleOut.instr <= moduleIn.instr;
    end
end



endmodule