`ifdef VERILATOR
`include "include/common.sv"
`endif

module memorySolver import common::*;(
    input u64 addressReq,
    input u64 dataIn,
    input u4 memMode,
    output u64 data
);

assign data = (memMode == 4'b0000) ? (// lb
                    addressReq[1:0] == 2'b00 ? {{56{dataIn[7]}}, dataIn[7:0]}:
                    addressReq[1:0] == 2'b01 ? {{56{dataIn[15]}}, dataIn[15:8]}:
                    addressReq[1:0] == 2'b10 ? {{56{dataIn[23]}}, dataIn[23:16]}:
                    addressReq[1:0] == 2'b11 ? {{56{dataIn[31]}}, dataIn[31:24]}:
                    64'b0
                ): 
                (memMode == 4'b0001) ? (// lh
                    addressReq[1:0] == 2'b00 ? {{48{dataIn[15]}}, dataIn[15:0]}:
                    addressReq[1:0] == 2'b10 ? {{48{dataIn[31]}}, dataIn[31:16]}:
                    64'b0
                ): 
                (memMode == 4'b0010) ? (// lw
                    {{32{dataIn[31]}}, dataIn[31:0]}
                ):
                (memMode == 4'b0011) ? (// ld
                    dataIn
                ):
                (memMode == 4'b0100) ? (//lbu
                    addressReq[1:0] == 2'b00 ? {{56'b0}, dataIn[7:0]}:
                    addressReq[1:0] == 2'b01 ? {{56'b0}, dataIn[15:8]}:
                    addressReq[1:0] == 2'b10 ? {{56'b0}, dataIn[23:16]}:
                    addressReq[1:0] == 2'b11 ? {{56'b0}, dataIn[31:24]}:
                    64'b0
                ):
                (memMode == 4'b0101) ? (//lhu
                    addressReq[1:0] == 2'b00 ? {{48'b0}, dataIn[15:0]}:
                    addressReq[1:0] == 2'b10 ? {{48'b0}, dataIn[31:16]}:
                    64'b0
                ):
                (memMode == 4'b0110) ? (//lwu
                    {{32'b0}, dataIn[31:0]}
                ):
                dataIn;

endmodule