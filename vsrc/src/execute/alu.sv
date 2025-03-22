`ifdef VERILATOR
`include "include/common.sv"
`endif

module alu import common::*;(
    input logic clk,
    input u64 ia, ib,
    input u3 aluOp,
    output u64 aluOut,
    output u32 aluOut32
);

// alu operations

u32 ia32, ib32;

assign ia32 = ia[31:0];
assign ib32 = ib[31:0];

always_comb begin
    case(aluOp)
        3'b000: aluOut = ia + ib;
        3'b001: aluOut = ia - ib;
        3'b010: aluOut = ia ^ ib;
        3'b011: aluOut = ia | ib;
        3'b100: aluOut = ia & ib;
        3'b101: aluOut = ia << ib[5:0];
        3'b110: aluOut = ia >> ib[5:0];
        3'b111: aluOut = ($signed(ia)) >>> ib[5:0];
    endcase
    case(aluOp)
        3'b000: aluOut32 = ia32 + ib32;
        3'b001: aluOut32 = ia32 - ib32;
        3'b010: aluOut32 = ia32 ^ ib32;
        3'b011: aluOut32 = ia32 | ib32;
        3'b100: aluOut32 = ia32 & ib32;
        3'b101: aluOut32 = ia32 << ib32[4:0];
        3'b110: aluOut32 = ia32 >> ib32[4:0];
        3'b111: aluOut32 = ($signed(ia32)) >>> ib32[4:0];
    endcase
end

endmodule