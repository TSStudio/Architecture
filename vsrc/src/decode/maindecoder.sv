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
    output u2 srcA,srcB,
    output logic isBranch, isWriteBack, isMemWrite, isMemRead,
    output u4 memMode,
    output logic rvm
);

assign isBranch    =  0; // todo lab3


u3 immtype; // I:00 S:01 B:10 J:11
u3 optype;

u3 funct3 = instr[14:12];
u7 funct7 = instr[31:25];

assign immtype =
                (instr[6:0]==7'b0010011 || instr[6:0]==7'b0000011 || instr[6:0]==7'b0011011 )? 3'b000:
                (instr[6:0]==7'b0100011)? 3'b001:
                (instr[6:0]==7'b1100011)? 3'b010:
                (instr[6:0]==7'b0110111)? 3'b100: // U-type
                3'b011;

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

assign isWriteBack = ((instr[6:0]==7'b0000011) | (instr[6:0]==7'b0010011) | (instr[6:0]==7'b0110011) | (instr[6:0]==7'b0111011) | (instr[6:0]==7'b0011011) | (instr[6:0]==7'b0110111)) ; // todo lab3

assign rv64 = (instr[6:0]==7'b0111011 | instr[6:0]==7'b0011011)? 1:0;

assign rvm = ((instr[6:0]==7'b0110011 & funct7 == 7'b0000001) | (instr[6:0]==7'b0111011 & funct7 == 7'b0000001)) ? 1:0;

assign isMemWrite = (instr[6:0]==7'b0100011)? 1:0;

assign isMemRead = (instr[6:0]==7'b0000011)? 1:0;

assign memMode[2:0] = funct3;
assign memMode[3] = isMemWrite;


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

assign srcA = (instr[6:0]==7'b0110111)?2'b00:(2'b01);

assign srcB = (immtype==3'b000 ||immtype==3'b100 || immtype==3'b001)? 2'b01:2'b00; // 00: rs2, 01: imm, 10: imm<<12 
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
                : 3'b000;


//mul ops:
// 0000: mul
// 0100: div
// 0101: divu
// 0110: rem
// 0111: remu
// 1000: mulw
// 1100: divw
// 1101: divuw
// 1110: remw
// 1111: remuw

assign mulOp =  (instr[6:0]==7'b0110011)?(
                    (funct3==3'b000)?
                        4'b0000 // mul
                    : (funct3==3'b100)?
                        4'b0100 // div
                    : (funct3==3'b101)?
                        4'b0101 // divu
                    : (funct3==3'b110)?
                        4'b0110 // rem
                    : (funct3==3'b111)?
                        4'b0111 // remu
                    : 4'b0000
                ): (instr[6:0]==7'b0111011)?(
                    (funct3==3'b000)?
                        4'b1000 // mulw
                    : (funct3==3'b100)?
                        4'b1100 // divw
                    : (funct3==3'b101)?
                        4'b1101 // divuw
                    : (funct3==3'b110)?
                        4'b1110 // remw
                    : (funct3==3'b111)?
                        4'b1111 // remuw
                    : 4'b0000
                ): 4'b0000;
                    

endmodule