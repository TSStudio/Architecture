`ifdef VERILATOR
`include "include/common.sv"
`endif

module signextend import common::*;(
    input u32 instr,
    input u2 immSrc,
    output u64 immOut
);

assign immOut = 
                (immSrc==2'b01)? ({{52{instr[31]}},instr[31:25],instr[11:7]}): //S-type
				(immSrc==2'b10)? ({{52{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}): // B-type
				(immSrc==2'b11)? ({{44{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}): // J-type
				({{52{instr[31]}},instr[31:20]});// I-type


endmodule 