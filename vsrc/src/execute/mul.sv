`ifdef VERILATOR
`include "include/common.sv"
`endif

module mul import common::*;(
    input logic clk,
    input u64 ia, ib,
    input u4 mulOp,
    output u64 mulOut
);
//ops:
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
u64 sign_extended_a;
u64 sign_extended_b;
u64 unsigned_a;
u64 unsigned_b;

assign sign_extended_a = {{32{ia[31]}}, ia[31:0]};
assign sign_extended_b = {{32{ib[31]}}, ib[31:0]};
assign unsigned_a = {32'b0, ib[31:0]};
assign unsigned_b = {32'b0, ib[31:0]};

always_comb begin
    case(mulOp)
        4'b0000: mulOut = ia * ib;
        4'b0100: mulOut = ia / ib;
        4'b0101: mulOut = ia / ib;
        4'b0110: mulOut = ia % ib;
        4'b0111: mulOut = ia % ib;
        4'b1000: mulOut = ia * ib;
        4'b1100: mulOut = sign_extended_a / sign_extended_b;
        4'b1101: mulOut = unsigned_b / unsigned_b;
        4'b1110: mulOut = sign_extended_a % sign_extended_a;
        4'b1111: mulOut = unsigned_b % unsigned_b;
        default: mulOut = 0;
    endcase



end

endmodule