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
    output logic isBranch, isJump, isWriteBack, isMemWrite, isMemRead,
    output u4 memMode,
    output logic rvm,

    output logic isCSRWrite,
    output csr_op_t csr_op,
    output u12 CSR_addr,
    output trap_t trap,

    output logic cns, cmpSrcB, flagInv,
    output u2 useflag, //use which flag
    output logic illegal
);

assign isBranch    =  instr[6:0]==7'b1100011; // B-type
assign isJump      =  instr[6:0]==7'b1100111 || instr[6:0]==7'b1101111; // J-type
assign cns = (optype==3'b000 || optype==3'b001) && (funct3==3'b010 || funct3==3'b011); // slt sltu slti sltiu

always_comb begin
    if((optype==3'b000)) begin
        if(funct3==3'b010) begin
            useflag = 2'b00;
        end else begin
            useflag = 2'b01;
        end
        flagInv = 0;
        cmpSrcB = 0;
    end else if (optype==3'b001) begin
        if(funct3==3'b010) begin
            useflag = 2'b00;
        end else begin
            useflag = 2'b01;
        end
        flagInv = 0;
        cmpSrcB = 1;
    end else begin
        if(funct3==3'b000) begin //beq
            useflag = 2'b10;
            flagInv = 0;
        end else if (funct3==3'b001) begin //bne
            useflag = 2'b10;
            flagInv = 1;
        end else if (funct3==3'b100) begin //blt
            useflag = 2'b00;
            flagInv = 0;
        end else if (funct3==3'b101) begin //bge
            useflag = 2'b00;
            flagInv = 1;
        end else if (funct3==3'b110) begin //bltu
            useflag = 2'b01;
            flagInv = 0;
        end else if (funct3==3'b111) begin //bgeu
            useflag = 2'b01;
            flagInv = 1;
        end else begin
            useflag = 2'b00;
            flagInv = 0;
        end
        cmpSrcB = 0;
    end
end


u3 immtype; // I:00 S:01 B:10 J:11
u3 optype;

u3 funct3;
assign funct3 = instr[14:12];
u7 funct7;
assign funct7 = instr[31:25];

assign immtype =
                (instr[6:0]==7'b0010011 || instr[6:0]==7'b0000011 || instr[6:0]==7'b0011011 || instr[6:0] == 7'b1100111)? 3'b000:
                (instr[6:0]==7'b0100011)? 3'b001:
                (instr[6:0]==7'b1100011)? 3'b010:
                (instr[6:0]==7'b0110111 || instr[6:0]==7'b0010111)? 3'b100: // U-type
                (instr[6:0]==7'b1101111)? 3'b011: // J-type
                (instr[6:0]==7'b1110011) ? 3'b101: // CSR-I
                3'b111;

assign optype =
                (instr[6:0]==7'b0110011)? 3'b000: // R-type
                (instr[6:0]==7'b0010011)? 3'b001: // I-type
                (instr[6:0]==7'b0000011)? 3'b010: // I-type
                (instr[6:0]==7'b1100011)? 3'b011: // B-type
                (instr[6:0]==7'b0100011)? 3'b100: // S-type
                (instr[6:0]==7'b1101111)? 3'b101: // J-type
                (instr[6:0]==7'b1100111)? 3'b110: // I-type jalr
                (instr[6:0]==7'b0011011)? 3'b001: // 64-bit I-type 
                (instr[6:0]==7'b0111011)? 3'b000: // 64-bit R-type
                3'b111; // Unknown

assign isWriteBack = ((instr[6:0]==7'b0000011) | (instr[6:0]==7'b0010011) | (instr[6:0]==7'b0110011) | (instr[6:0]==7'b0111011) | (instr[6:0]==7'b0011011) | (instr[6:0]==7'b0110111) | (instr[6:0]==7'b0010111) | (instr[6:0]==7'b1101111) | (instr[6:0]==7'b1100111)) | (instr[6:0]==7'b1110011);

assign rv64 = (instr[6:0]==7'b0111011 | instr[6:0]==7'b0011011)? 1:0;

assign rvm = ((instr[6:0]==7'b0110011 & funct7 == 7'b0000001) | (instr[6:0]==7'b0111011 & funct7 == 7'b0000001)) ? 1:0;

assign isMemWrite = (instr[6:0]==7'b0100011)? 1:0;

assign isMemRead = (instr[6:0]==7'b0000011)? 1:0;

assign memMode[2:0] = funct3;
assign memMode[3] = isMemWrite;

assign csr_op = csr_op_t'(instr[14:12]);
assign isCSRWrite = (instr[6:0]==7'b1110011)? 1:0;

assign CSR_addr = instr[31:20];

assign trap = 
    instr[31:20]==12'b000000000000 ? ECALL :
    instr[31:20]==12'b000000000001 ? EBREAK :
    instr[31:20]==12'b001100000010 ? MRET :
    UNKNOWN;

logic mret=
    (instr[31:20]==12'b001100000010) & (instr[6:0]==7'b1110011);

signextend signextend_inst(
    .instr(instr),
    .immSrc(immtype),
    .immOut(imm)
);

assign rs1 = instr[19:15];
assign rs2 = instr[24:20];

assign wd = instr[11:7];

assign srcA = (instr[6:0]==7'b0110111)?2'b00: // lui : 0
              (instr[6:0]==7'b1110011)?2'b00: // csr : 0
              (instr[6:0]==7'b0010111)?2'b10: // auipc : pc
              (instr[6:0]==7'b1100011)?2'b10: // branch: pc
              (instr[6:0]==7'b1101111)?2'b10: // jal: pc
              (2'b01); // rest: rs1

assign srcB = (immtype==3'b000 || immtype==3'b100 || immtype==3'b001 || immtype==3'b011 || immtype==3'b010) ? 2'b01:
(immtype==3'b101)? 2'b11:
2'b00; // 00: rs2, 01: imm, 10: imm<<12, 11: CSR
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
                        ((funct7[6:1]==6'b000000)? 3'b110:3'b111) // srl, sra
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
                        ((funct7[6:1]==6'b000000)? 3'b110:3'b111) // srli, srai
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


always_comb begin
    illegal = 0;
    if(instr[6:0]==7'b0110011) begin // RV32I-R RV32M-R, arithmetic
        if(funct3==3'b000) begin
            if(funct7!=7'b0000000 && funct7!=7'b0100000 && funct7!=7'b0000001) begin // add sub mul
                illegal = 1;
            end
        end else if (funct3==3'b001) begin
            if(funct7!=7'b0000000) begin // sll
                illegal = 1;
            end
        end else if (funct3==3'b010) begin
            if(funct7!=7'b0000000) begin // slt
                illegal = 1;
            end
        end else if (funct3==3'b011) begin
            if(funct7!=7'b0000000) begin // sltu
                illegal = 1;
            end
        end else if (funct3==3'b100) begin
            if(funct7!=7'b0000000 && funct7!=7'b0000001) begin // xor div
                illegal = 1;
            end
        end else if (funct3==3'b101) begin
            if(funct7!=7'b0000000 && funct7!=7'b0100000 && funct7!=7'b0000001) begin // srl sra divu
                illegal = 1;
            end
        end else if (funct3==3'b110) begin
            if(funct7!=7'b0000000 && funct7!=7'b0000001) begin // or rem
                illegal = 1;
            end
        end else if (funct3==3'b111) begin
            if(funct7!=7'b0000000 && funct7!=7'b0000001) begin // and remu
                illegal = 1;
            end
        end
    end else if(instr[6:0]==7'b0010011) begin // RV32I-I, arithmetic
        if(funct3==3'b000) begin // addi
            illegal = 0;
        end else if (funct3==3'b010) begin // slti
            illegal = 0;
        end else if (funct3==3'b011) begin // sltiu
            illegal = 0; 
        end else if (funct3==3'b100) begin // xori
            illegal = 0; 
        end else if (funct3==3'b110) begin // ori
            illegal = 0; 
        end else if (funct3==3'b111) begin // andi
            illegal = 0; 
        end else if (funct3==3'b001) begin // slli both RV32I and RV64I
            if(funct7[6:1]!=6'b000000) begin
                illegal = 1;
            end
        end else if (funct3==3'b101) begin // srli srai
            if(funct7[6:1]!=6'b000000 && funct7[6:1]!=6'b010000) begin
                illegal = 1;
            end
        end
    end else if(instr[6:0]==7'b0111011) begin // RV64I-R, arithmetic
        if(funct3==3'b000) begin
            if(funct7!=7'b0000000 && funct7!=7'b0100000 && funct7!=7'b0000001) begin // addw subw mulw
                illegal = 1;
            end
        end else if (funct3==3'b001) begin
            if(funct7!=7'b0000000) begin // sllw
                illegal = 1;
            end
        end else if (funct3==3'b100) begin
            if(funct7!=7'b0000001) begin // divw
                illegal = 1;
            end
        end else if (funct3==3'b101) begin
            if(funct7!=7'b0000000 && funct7!=7'b0100000 && funct7!=7'b0000001) begin // srlw sraw divuw
                illegal = 1;
            end
        end else if (funct3==3'b110) begin
            if(funct7!=7'b0000001) begin // remw
                illegal = 1;
            end
        end else if (funct3==3'b111) begin
            if(funct7!=7'b0000001) begin // remuw
                illegal = 1;
            end
        end 
    end else if(instr[6:0]==7'b0011011) begin // RV64I-I, arithmetic
        if(funct3==3'b000) begin // addiw
            illegal = 0;
        end else if (funct3==3'b001) begin // slliw
            if(funct7[6:1]!=6'b000000) begin
                illegal = 1;
            end
        end else if (funct3==3'b101) begin // srliw sraiw
            if(funct7[6:1]!=6'b000000 && funct7[6:1]!=6'b010000) begin
                illegal = 1;
            end
        end else begin 
            illegal = 1;
        end
    end else if(instr[6:0]==7'b0000011) begin // load
        if(funct3==3'b000) begin // lb
            illegal = 0;
        end else if (funct3==3'b001) begin // lh
            illegal = 0;
        end else if (funct3==3'b010) begin // lw
            illegal = 0;
        end else if (funct3==3'b011) begin // ld
            illegal = 0;
        end else if (funct3==3'b100) begin // lbu
            illegal = 0;
        end else if (funct3==3'b101) begin // lhu
            illegal = 0;
        end else if (funct3==3'b110) begin // lwu
            illegal = 0;
        end else begin 
            illegal = 1;
        end
    end else if(instr[6:0]==7'b0100011) begin // RV32I-S, store
        if(funct3==3'b000) begin // sb
            illegal = 0;
        end else if (funct3==3'b001) begin // sh
            illegal = 0;
        end else if (funct3==3'b010) begin // sw
            illegal = 0;
        end else if (funct3==3'b011) begin // sd
            illegal = 0;
        end else begin 
            illegal = 1;
        end
    end else if(instr[6:0]==7'b1100011) begin // RV32I-B, branch
        if(funct3==3'b000) begin // beq
            illegal = 0;
        end else if (funct3==3'b001) begin // bne
            illegal = 0;
        end else if (funct3==3'b100) begin // blt
            illegal = 0;
        end else if (funct3==3'b101) begin // bge
            illegal = 0;
        end else if (funct3==3'b110) begin // bltu
            illegal = 0;
        end else if (funct3==3'b111) begin // bgeu
            illegal = 0;
        end else begin 
            illegal = 1;
        end
    end else if(instr[6:0]==7'b1101111) begin // RV32I-J, jal
        illegal = 0;
    end else if(instr[6:0]==7'b1100111) begin // RV32I-I, jalr
        if(funct3==3'b000) begin // jalr
            illegal = 0;
        end else begin 
            illegal = 1;
        end
    end else if(instr[6:0]==7'b0110111) begin // lui
        illegal = 0;
    end else if(instr[6:0]==7'b0010111) begin // auipc
        illegal = 0;
    end else if(instr[6:0]==7'b1110011) begin // CSR
        if(funct3==3'b000) begin // etrap
            if(funct7 == 7'b0001001) begin
                illegal = 0;
            end else if(trap==UNKNOWN) begin
                illegal = 1;
            end else begin
                illegal = 0;
            end
        end else if(funct3==3'b001) begin // csrrw
            illegal = 0;
        end else if (funct3==3'b010) begin // csrrs
            illegal = 0;
        end else if (funct3==3'b011) begin // csrrc
            illegal = 0;
        end else if (funct3==3'b101) begin // csrrwi
            illegal = 0;
        end else if (funct3==3'b110) begin // csrrsi
            illegal = 0;
        end else if (funct3==3'b111) begin // csrrci
            illegal = 0;
        end else begin 
            illegal = 1;
        end
    end else begin 
        illegal = 1;
    end
end                

endmodule