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
    output word_t data
);

assign msize =  (memMode == 4'b0000) ? MSIZE4: // lb
                (memMode == 4'b0001) ? MSIZE4: // lh
                (memMode == 4'b0010) ? MSIZE4: // lw
                (memMode == 4'b0011) ? MSIZE8: // ld
                (memMode == 4'b0100) ? MSIZE4: // lbu
                (memMode == 4'b0101) ? MSIZE2: // lhu
                (memMode == 4'b0110) ? MSIZE4: // lwu
                (memMode == 4'b1000) ? MSIZE1: // sb
                (memMode == 4'b1001) ? MSIZE2: // sh
                (memMode == 4'b1010) ? MSIZE4: // sw
                (memMode == 4'b1011) ? MSIZE8: // sd
                MSIZE1;
assign addr = {addressReq[63:2], 2'b00};

assign strobe = (memMode == 4'b1000) ? (// sb
                    addressReq[1:0] == 2'b00 ? 8'b00000001:
                    addressReq[1:0] == 2'b01 ? 8'b00000010:
                    addressReq[1:0] == 2'b10 ? 8'b00000100:
                    addressReq[1:0] == 2'b11 ? 8'b00001000:
                    8'b0
                ): 
                (memMode == 4'b1001) ? (// sh
                    addressReq[1:0] == 2'b00 ? 8'b00000011:
                    addressReq[1:0] == 2'b10 ? 8'b00001100:
                    8'b0
                ): 
                (memMode == 4'b1010) ? 8'b00001111: // sw
                (memMode == 4'b1011) ? 8'b11111111: // sd
                0;

assign data = (memMode == 4'b1000)?(
                addressReq[1:0] == 2'b00 ? {56'b0,dataIn[7:0]}:
                addressReq[1:0] == 2'b01 ? {48'b0,dataIn[15:8],8'b0}:
                addressReq[1:0] == 2'b10 ? {40'b0,dataIn[23:16],16'b0}:
                addressReq[1:0] == 2'b11 ? {32'b0,dataIn[31:24],24'b0}:
                0
            ): 
            (memMode == 4'b1001)?(
                addressReq[1:0] == 2'b00 ? {48'b0,dataIn[15:0]}:
                addressReq[1:0] == 2'b10 ? {32'b0,dataIn[31:16],16'b0}:
                0
            ): dataIn;


endmodule