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
    input u64 rs1Data, rs2Data
);

/*
module maindecoder(
    input u32 instr,
    output u64 imm,
    output u5 rs1, rs2, wd,
    output u3 aluOp,
    output logic isBranch, isWriteBack, srcB, isMemWrite
);
*/
u64 imm;
u5 wd;
u3 aluOp;
logic isBranch, isWriteBack, srcB, isMemWrite;

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
    .isMemWrite(isMemWrite)
);

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        moduleOut.valid <= 0;
    end else begin
        moduleOut.valid <= moduleIn.valid & ~bubbleHold;
        moduleOut.pcPlus4 <= moduleIn.pcPlus4;
        moduleOut.rs1 <= rs1Data;
        moduleOut.srcB <= srcB;
        moduleOut.rs2 <= rs2Data;
        moduleOut.imm <= imm;
        moduleOut.isWriteBack <= isWriteBack;
        moduleOut.isMemWrite <= isMemWrite;
        moduleOut.wd <= wd;
        moduleOut.aluOp <= aluOp;
        moduleOut.isBranch <= isBranch;
        moduleOut.instrAddr <= moduleIn.instrAddr;
        moduleOut.instr <= moduleIn.instr;
    end
end



endmodule