`ifdef VERILATOR
`include "include/common.sv"
`include "src/decode/maindecoder.sv"
`endif

module decoder import common::*;(
    input logic clk,rst,
    output logic lwHold,
    input REG_IF_ID moduleIn,
    output REG_ID_EX moduleOut,

    output u5 rs1, rs2,
    input u64 rs1Data, rs2Data,

    input FORWARD_SOURCE fwdSrc1, fwdSrc2,
    input CSR_FORWARD_SOURCE csrFwdSrc1, csrFwdSrc2,

    output logic ok_to_proceed,
    input logic ok_to_proceed_overall,

    output u12 CSR_addr,
    input u64 CSR_value,

    input logic JumpEn
);

u64 imm;
u5 wd;
u3 aluOp;
u2 srcA,srcB;
logic isBranch, isWriteBack, isMemWrite, isMemRead, isJump;
u4 memMode;
logic rv64;
logic rvm;
u4 mulOp;
logic cns, cmpSrcB, flagInv;
u2 useflag; //use which flag

logic isCSRWrite;
csr_op_t csr_op;

assign lwHold = (isBranch||isJump||isMemRead) & moduleIn.valid & ~JumpEn;

maindecoder maindecoder_inst(
    .instr(moduleIn.instr),
    .imm(imm),
    .rs1(rs1),
    .rs2(rs2),
    .wd(wd),
    .aluOp(aluOp),
    .mulOp(mulOp),
    .isBranch(isBranch),
    .isJump(isJump),
    .isWriteBack(isWriteBack),
    .srcA(srcA),
    .srcB(srcB),
    .isMemWrite(isMemWrite),
    .isMemRead(isMemRead),
    .rv64(rv64),
    .memMode(memMode),
    .rvm(rvm),
    .cns(cns),
    .cmpSrcB(cmpSrcB),
    .flagInv(flagInv),
    .useflag(useflag),

    .isCSRWrite(isCSRWrite),
    .csr_op(csr_op),
    .CSR_addr(CSR_addr)
);

u64 rs1DataOutS1, rs1DataOutS2, rs2DataOutS1, rs2DataOutS2;

assign rs1DataOutS1 = fwdSrc1.valid & fwdSrc1.isWb & fwdSrc1.wd == rs1 ? fwdSrc1.wdData : rs1Data;
assign rs1DataOutS2 = fwdSrc2.valid & fwdSrc2.isWb & fwdSrc2.wd == rs1 ? fwdSrc2.wdData : rs1DataOutS1;

assign rs2DataOutS1 = fwdSrc1.valid & fwdSrc1.isWb & fwdSrc1.wd == rs2 ? fwdSrc1.wdData : rs2Data;
assign rs2DataOutS2 = fwdSrc2.valid & fwdSrc2.isWb & fwdSrc2.wd == rs2 ? fwdSrc2.wdData : rs2DataOutS1;

u64 CSRoutS1, CSRoutS2;

assign CSRoutS1 = csrFwdSrc1.valid & csrFwdSrc1.wd == CSR_addr ? csrFwdSrc1.wdData : CSR_value;
assign CSRoutS2 = csrFwdSrc2.valid & csrFwdSrc2.wd == CSR_addr ? csrFwdSrc2.wdData : CSRoutS1;

assign ok_to_proceed = 1; // always proceed

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        moduleOut.valid <= 0;
    end else if(ok_to_proceed_overall) begin
        moduleOut.valid <= moduleIn.valid & ~JumpEn;
        moduleOut.pc <= moduleIn.pc;
        moduleOut.pcPlus4 <= moduleIn.pcPlus4;

        moduleOut.srcA <= srcA;
        moduleOut.srcB <= srcB;

        moduleOut.rs1 <= rs1DataOutS2;
        moduleOut.rs2 <= rs2DataOutS2;

        moduleOut.imm <= imm;
        moduleOut.isWriteBack <= isWriteBack;
        moduleOut.isMemRead <= isMemRead;
        moduleOut.isMemWrite <= isMemWrite;
        moduleOut.isBranch <= isBranch;
        moduleOut.isJump <= isJump;
        moduleOut.memMode <= memMode;
        moduleOut.wd <= wd;
        moduleOut.aluOp <= aluOp;
        moduleOut.mulOp <= mulOp;
        moduleOut.isBranch <= isBranch;
        moduleOut.rv64 <= rv64;
        moduleOut.rvm <= rvm;

        moduleOut.cns <= cns;
        moduleOut.cmpSrcB <= cmpSrcB;
        moduleOut.useflag <= useflag;
        moduleOut.flagInv <= flagInv;

        moduleOut.isCSRWrite <= isCSRWrite;
        moduleOut.CSR_addr <= CSR_addr;
        moduleOut.CSR_value <= CSRoutS2;
        moduleOut.csr_op <= csr_op;

        moduleOut.instrAddr <= moduleIn.instrAddr;
        moduleOut.instr <= moduleIn.instr;
    end
end



endmodule