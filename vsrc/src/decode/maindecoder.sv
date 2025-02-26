`ifdef VERILATOR
`include "include/common.sv"
`include "src/decode/signextend.sv"
`endif

module maindecoder import common::*;(
    input u32 instr,
    output u64 imm,
    output u5 rs1, rs2, wd,
    output u3 aluOp,
    output u4 mulOp,
    output logic rv64,
    output logic isBranch, isWriteBack, srcB, isMemWrite, isMemRead,
    output u4 memMode,
    output logic rvm
);

assign isBranch    =  0; // todo lab3


u2 immtype; // I:00 S:01 B:10 J:11
u3 optype;

u3 funct3 = instr[14:12];
u7 funct7 = instr[31:25];

assign immtype =
                (instr[6:0]==7'b0010011 || instr[6:0]==7'b0000011 || instr[6:0]==7'b0011011)? 2'b00:
                (instr[6:0]==7'b0100011)? 2'b01:
                (instr[6:0]==7'b1100011)? 2'b10:
                2'b11;

assign optype =
                (instr[6:0]==7'b0110011)? 3'b000: // R-type
                (instr[6:0]==7'b0010011)? 3'b001: // I-type
                (instr[6:0]==7'b0000011)? 3'b010: // I-type
                (instr[6:0]==7'b1100011)? 3'b011: // B-type
                (instr[6:0]==7'b0100011)? 3'b100: // S-type
                (instr[6:0]==7'b1101111)? 3'b101: // U-type
                (instr[6:0]==7'b1100111)? 3'b110: // J-type

                (instr[6:0]==7'b0011011)? 3'b001: // 64-bit I-type 
                (instr[6:0]==7'b0111011)? 3'b000: // 64-bit R-type
                3'b111; // Unknown

assign isWriteBack = ((instr[6:0]==7'b0000011) | (instr[6:0]==7'b0010011) | (instr[6:0]==7'b0110011) | (instr[6:0]==7'b0111011) | (instr[6:0]==7'b0011011)) ; // todo lab3

assign rv64 = (instr[6:0]==7'b0111011 | instr[6:0]==7'b0011011)? 1:0;

assign isMemWrite = (instr[6:0]==7'b0100011)? 1:0;

assign isMemRead = (instr[6:0]==7'b0000011)? 1:0;

assign memMode[2:0] = funct3;
assign memMode[3]=isMemWrite;


/*
module signextend(
    input u32 instr,
    input u2 immSrc,
    output u64 immOut
);
*/

signextend signextend_inst(
    .instr(instr),
    .immSrc(immtype),
    .immOut(imm)
);

assign rs1 = instr[19:15];
assign rs2 = instr[24:20];

assign wd = instr[11:7];

assign srcB = (immtype==2'b00)? 1:0;
/*
        3'b000: aluOut = ia + ib;
        3'b001: aluOut = ia - ib;
        3'b010: aluOut = ia ^ ib;
        3'b011: aluOut = ia | ib;
        3'b100: aluOut = ia & ib;
        3'b101: aluOut = ia << ib;
        3'b110: aluOut = ia >> ib;
        3'b111: aluOut = ia >>> ib;
        */
assign aluOp = (optype==3'b000)?// R-type
                    ((funct3==3'b000)? 
                        ((funct7==7'b0000000)? 3'b000:3'b001) // add, sub
                    : (funct3==3'b100)?
                        3'b010 // xor
                    : (funct3==3'b110)?
                        3'b011 // or
                    : (funct3==3'b111)?
                        3'b100 // and
                    : (funct3==3'b001)?
                        3'b101 // sll
                    : (funct3==3'b101)?
                        ((funct7==7'b0000000)? 3'b110:3'b111) // srl, sra
                    : 3'b000
                    )
                : (optype==3'b001)?
                    ((funct3==3'b000)?
                        3'b000 // addi
                    : (funct3==3'b100)?
                        3'b010 // xori
                    : (funct3==3'b110)?
                        3'b011 // ori
                    : (funct3==3'b111)?
                        3'b100 // andi
                    : (funct3==3'b001)?
                        3'b101 // slli
                    : (funct3==3'b101)?
                        ((funct7==7'b0000000)? 3'b110:3'b111) // srli, srai
                    : 3'b000
                    )
                : (optype==3'b010)?
                    (3'b000)
                : (optype==3'b011)?
                    (3'b000)
                : (optype==3'b100)?
                    (3'b000)
                : (optype==3'b101)?
                    (3'b000)
                : (optype==3'b110)?
                    (3'b000)
                : 3'b111;


endmodule