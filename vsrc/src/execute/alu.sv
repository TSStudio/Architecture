`ifdef VERILATOR
`include "include/common.sv"
`endif

module alu import common::*;(
    input logic clk,
    input u64 ia, ib,
    input u3 aluOp,
    output u64 aluOut
);

// alu operations

always_comb begin
    case(aluOp)
        3'b000: aluOut = ia + ib;
        3'b001: aluOut = ia - ib;
        3'b010: aluOut = ia ^ ib;
        3'b011: aluOut = ia | ib;
        3'b100: aluOut = ia & ib;
        3'b101: aluOut = ia << ib;
        3'b110: aluOut = ia >> ib;
        3'b111: aluOut = ia >>> ib;
    endcase
end

endmodule