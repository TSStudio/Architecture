`ifdef VERILATOR
`include "include/common.sv"
`endif

module signextend import common::*;(
    input u32 instr,
    input u3 immSrc,
    output u64 immOut
);

assign immOut = (immSrc==3'b101)? ({{59'b0},instr[19:15]}): // CSR-I
                (immSrc==3'b100)? ({{32{instr[31]}}, instr[31:12], 12'b0}): // U-type
                (immSrc==3'b001)? ({{52{instr[31]}},instr[31:25],instr[11:7]}): //S-type
				(immSrc==3'b010)? ({{52{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}): // B-type
				(immSrc==3'b011)? ({{44{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}): // J-type
				({{52{instr[31]}},instr[31:20]});// I-type


endmodule 