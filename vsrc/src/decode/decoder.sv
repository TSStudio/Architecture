`ifdef VERILATOR
`include "include/common.sv"
`include "src/decode/maindecoder.sv"
`endif

/*
typedef struct packed {
    logic  valid;
    u64 pcPlus4;
    u32 instr;
} REG_IF_ID;

typedef struct packed {
    logic  valid;
    u64 pcPlus4;
    u64 rs1;
    logic srcB;
    u64 rs2;
    u64 imm;
    logic isWriteBack;
    logic isMemWrite;
    u5  wd;
    u3  aluOp;
    logic  isBranch;
} REG_ID_EX;
*/

module decoder import common::*;(
    input logic clk,rst,
    input logic bubbleHold,
    input REG_IF_ID moduleIn,
    output REG_ID_EX moduleOut,

    output u5 rs1, rs2,
    input u64 rs1Data, rs2Data,

    input FORWARD_SOURCE fwdSrc1, fwdSrc2
);

/*
typedef struct packed {
    logic valid;
    logic isWb;
    u5  wd;
    u64 wdData;
} FORWARD_SOURCE;
*/
u64 imm;
u5 wd;
u3 aluOp;
logic isBranch, isWriteBack, srcB, isMemWrite;
logic rv64;

maindecoder maindecoder_inst(
    .instr(moduleIn.instr),
    .imm(imm),
    .rs1(rs1),
    .rs2(rs2),
    .wd(wd),
    .aluOp(aluOp),
    .isBranch(isBranch),
    .isWriteBack(isWriteBack),
    .srcB(srcB),
    .isMemWrite(isMemWrite),
    .rv64(rv64)
);

u64 rs1DataOutS1, rs1DataOutS2, rs2DataOutS1, rs2DataOutS2;

assign rs1DataOutS1 = fwdSrc1.valid & fwdSrc1.isWb & fwdSrc1.wd == rs1 ? fwdSrc1.wdData : rs1Data;
assign rs1DataOutS2 = fwdSrc2.valid & fwdSrc2.isWb & fwdSrc2.wd == rs1 ? fwdSrc2.wdData : rs1DataOutS1;

assign rs2DataOutS1 = fwdSrc1.valid & fwdSrc1.isWb & fwdSrc1.wd == rs2 ? fwdSrc1.wdData : rs2Data;
assign rs2DataOutS2 = fwdSrc2.valid & fwdSrc2.isWb & fwdSrc2.wd == rs2 ? fwdSrc2.wdData : rs2DataOutS1;

always_ff @(posedge clk or posedge rst) begin
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
        moduleOut.isMemWrite <= isMemWrite;
        moduleOut.wd <= wd;
        moduleOut.aluOp <= aluOp;
        moduleOut.isBranch <= isBranch;
        moduleOut.rv64 <= rv64;

        moduleOut.instrAddr <= moduleIn.instrAddr;
        moduleOut.instr <= moduleIn.instr;
    end
end



endmodule