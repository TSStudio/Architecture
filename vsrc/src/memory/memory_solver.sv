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
                    addressReq[2:0] == 3'b000 ? {{56{dataIn[7]}}, dataIn[7:0]}:
                    addressReq[2:0] == 3'b001 ? {{56{dataIn[15]}}, dataIn[15:8]}:
                    addressReq[2:0] == 3'b010 ? {{56{dataIn[23]}}, dataIn[23:16]}:
                    addressReq[2:0] == 3'b011 ? {{56{dataIn[31]}}, dataIn[31:24]}:
                    addressReq[2:0] == 3'b100 ? {{56{dataIn[39]}}, dataIn[39:32]}:
                    addressReq[2:0] == 3'b101 ? {{56{dataIn[47]}}, dataIn[47:40]}:
                    addressReq[2:0] == 3'b110 ? {{56{dataIn[55]}}, dataIn[55:48]}:
                    addressReq[2:0] == 3'b111 ? {{56{dataIn[63]}}, dataIn[63:56]}:
                    64'b0
                ): 
                (memMode == 4'b0001) ? (// lh
                    addressReq[2:0] == 3'b000 ? {{48{dataIn[15]}}, dataIn[15:0]}:
                    addressReq[2:0] == 3'b010 ? {{48{dataIn[31]}}, dataIn[31:16]}:
                    addressReq[2:0] == 3'b100 ? {{48{dataIn[47]}}, dataIn[47:32]}:
                    addressReq[2:0] == 3'b110 ? {{48{dataIn[63]}}, dataIn[63:48]}:
                    64'b0
                ): 
                (memMode == 4'b0010) ? (// lw
                    addressReq[2:0] == 3'b000 ? {{32{dataIn[31]}}, dataIn[31:0]}:
                    addressReq[2:0] == 3'b100 ? {{32{dataIn[63]}}, dataIn[63:32]}:
                    64'b0
                ):
                (memMode == 4'b0011) ? (// ld
                    dataIn
                ):
                (memMode == 4'b0100) ? (// lbu
                    addressReq[2:0] == 3'b000 ? {{56'b0}, dataIn[7:0]}:
                    addressReq[2:0] == 3'b001 ? {{56'b0}, dataIn[15:8]}:
                    addressReq[2:0] == 3'b010 ? {{56'b0}, dataIn[23:16]}:
                    addressReq[2:0] == 3'b011 ? {{56'b0}, dataIn[31:24]}:
                    addressReq[2:0] == 3'b100 ? {{56'b0}, dataIn[39:32]}:
                    addressReq[2:0] == 3'b101 ? {{56'b0}, dataIn[47:40]}:
                    addressReq[2:0] == 3'b110 ? {{56'b0}, dataIn[55:48]}:
                    addressReq[2:0] == 3'b111 ? {{56'b0}, dataIn[63:56]}:
                    64'b0
                ):
                (memMode == 4'b0101) ? (// lhu
                    addressReq[2:0] == 3'b000 ? {{48'b0}, dataIn[15:0]}:
                    addressReq[2:0] == 3'b010 ? {{48'b0}, dataIn[31:16]}:
                    addressReq[2:0] == 3'b100 ? {{48'b0}, dataIn[47:32]}:
                    addressReq[2:0] == 3'b110 ? {{48'b0}, dataIn[63:48]}:
                    64'b0
                ):
                (memMode == 4'b0110) ? (//lwu
                    addressReq[2:0] == 3'b000 ? {{32'b0}, dataIn[31:0]}:
                    addressReq[2:0] == 3'b100 ? {{32'b0}, dataIn[63:32]}:
                    64'b0
                ):
                dataIn;              

endmodule