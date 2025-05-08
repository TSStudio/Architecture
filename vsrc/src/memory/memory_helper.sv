`ifdef VERILATOR
`include "include/common.sv"
`endif

module memoryHelper import common::*;(
    input u64 addressReq,
    input u64 dataIn,
    input u4 memMode,
    output addr_t addr,
    output msize_t msize,
    output strobe_t strobe,
    output word_t data,
    output logic mis_aligned
);

assign msize =  (memMode == 4'b0000) ? MSIZE8: // lb
                (memMode == 4'b0001) ? MSIZE8: // lh
                (memMode == 4'b0010) ? MSIZE8: // lw
                (memMode == 4'b0011) ? MSIZE8: // ld
                (memMode == 4'b0100) ? MSIZE8: // lbu
                (memMode == 4'b0101) ? MSIZE8: // lhu
                (memMode == 4'b0110) ? MSIZE8: // lwu
                (memMode == 4'b1000) ? MSIZE8: // sb
                (memMode == 4'b1001) ? MSIZE8: // sh
                (memMode == 4'b1010) ? MSIZE8: // sw
                (memMode == 4'b1011) ? MSIZE8: // sd
                MSIZE1;
// assign addr = {addressReq[63:3], 3'b000};

assign addr = addressReq;

assign strobe = (memMode == 4'b1000) ? (// sb
                    addressReq[2:0] == 3'b000 ? 8'b00000001:
                    addressReq[2:0] == 3'b001 ? 8'b00000010:
                    addressReq[2:0] == 3'b010 ? 8'b00000100:
                    addressReq[2:0] == 3'b011 ? 8'b00001000:
                    addressReq[2:0] == 3'b100 ? 8'b00010000:
                    addressReq[2:0] == 3'b101 ? 8'b00100000:
                    addressReq[2:0] == 3'b110 ? 8'b01000000:
                    addressReq[2:0] == 3'b111 ? 8'b10000000:
                    8'b0
                ): 
                (memMode == 4'b1001) ? (// sh
                    addressReq[2:0] == 3'b000 ? 8'b00000011:
                    addressReq[2:0] == 3'b010 ? 8'b00001100:
                    addressReq[2:0] == 3'b100 ? 8'b00110000:
                    addressReq[2:0] == 3'b110 ? 8'b11000000:
                    8'b0
                ): 
                (memMode == 4'b1010) ? ( // sw
                    addressReq[2:0] == 3'b000 ? 8'b00001111:
                    addressReq[2:0] == 3'b100 ? 8'b11110000:
                    8'b0
                ):
                (memMode == 4'b1011) ? 8'b11111111: // sd
                0;

assign mis_aligned = (memMode[1:0] == 2'b00) ? 0 : //never when only 1 byte
                (memMode[1:0] == 2'b01) ? (addressReq[0] != 0) : // 2 byte
                (memMode[1:0] == 2'b10) ? (addressReq[1:0] != 0) : // 4 byte
                 (addressReq[2:0] != 0); // 8 byte
                


assign data = (memMode == 4'b1000)?(
                addressReq[2:0] == 3'b000 ? {56'b0,dataIn[7:0]}:
                addressReq[2:0] == 3'b001 ? {48'b0,dataIn[7:0],8'b0}:
                addressReq[2:0] == 3'b010 ? {40'b0,dataIn[7:0],16'b0}:
                addressReq[2:0] == 3'b011 ? {32'b0,dataIn[7:0],24'b0}:
                addressReq[2:0] == 3'b100 ? {24'b0,dataIn[7:0],32'b0}:
                addressReq[2:0] == 3'b101 ? {16'b0,dataIn[7:0],40'b0}:
                addressReq[2:0] == 3'b110 ? {8'b0,dataIn[7:0],48'b0}:
                addressReq[2:0] == 3'b111 ? {dataIn[7:0],56'b0}:
                0
            ): 
            (memMode == 4'b1001)?(
                // addressReq[1:0] == 2'b00 ? {48'b0,dataIn[15:0]}:
                // addressReq[1:0] == 2'b10 ? {32'b0,dataIn[31:16],16'b0}:
                // 0
                addressReq[2:0] == 3'b000 ? {48'b0,dataIn[15:0]}:
                addressReq[2:0] == 3'b010 ? {32'b0,dataIn[15:0],16'b0}:
                addressReq[2:0] == 3'b100 ? {16'b0,dataIn[15:0],32'b0}:
                addressReq[2:0] == 3'b110 ? {dataIn[15:0],48'b0}:
                0
            ):
            (memMode == 4'b1010)?(
                addressReq[2:0] == 3'b000 ? {32'b0,dataIn[31:0]}:
                addressReq[2:0] == 3'b100 ? {dataIn[31:0],32'b0}:
                0
            ):
            dataIn;


endmodule