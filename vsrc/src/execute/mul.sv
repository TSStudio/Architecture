`ifdef VERILATOR
`include "include/common.sv"
`endif

module mul import common::*;(
    input logic clk,
    input u64 ia, ib,
    input u4 mulOp,
    output mbus_req_t req,
    output logic inv
);
//ops:
// 000: mul
// 100: div
// 101: divu
// 110: rem
// 111: remu
// 000: mulw
// 100: divw
// 101: divuw
// 110: remw
// 111: remuw

u64 ia_inv, ib_inv;
assign ia_inv = (~ia) + 1;
assign ib_inv = (~ib) + 1;

u32 ia32, ib32, ia32_inv, ib32_inv;

assign ia32 = ia[31:0];
assign ib32 = ib[31:0];
assign ia32_inv = ia_inv[31:0];
assign ib32_inv = ib_inv[31:0];

logic ia_sign,ib_sign,ia32_sign,ib32_sign;
logic out_sign,out32_sign;

assign ia_sign = ia[63];
assign ib_sign = ib[63];
assign ia32_sign = ia32[31];
assign ib32_sign = ib32[31];

assign out_sign = ia_sign ^ ib_sign;
assign out32_sign = ia32_sign ^ ib32_sign;

u64 ia_abs, ib_abs;
u32 ia32_abs, ib32_abs;

assign ia_abs = ia_sign ? ia_inv : ia;
assign ib_abs = ib_sign ? ib_inv : ib;
assign ia32_abs = ia32_sign ? ia32_inv : ia32;
assign ib32_abs = ib32_sign ? ib32_inv : ib32;

always_comb begin
    case(mulOp[2:0])
        3'b000: begin
            req = {~mulOp[3], MUL, ia, ia, ib};
            inv = 0;
        end
        3'b100: begin
            if(mulOp[3])
                req = {~mulOp[3], DIV, {32'b0,ia32_abs}, ia, {32'b0,ib32_abs}};
            else
                req = {~mulOp[3], DIV, ia_abs, ia, ib_abs};
            inv = mulOp[3] ? out32_sign : out_sign;
        end
        3'b101: begin
            req = {~mulOp[3], DIV, ia, ia, ib};
            inv = 0;
        end
        3'b110: begin
            if(mulOp[3])
                req = {~mulOp[3], REM, {32'b0,ia32_abs}, ia, {32'b0,ib32_abs}};
            else
                req = {~mulOp[3], REM, ia_abs, ia, ib_abs};
            inv = mulOp[3] ? ia32_sign : ia_sign;
        end
        3'b111: begin
            req = {~mulOp[3], REM, ia, ia, ib};
            inv = 0;
        end
        default: begin
            req = {~mulOp[3], MUL, ia, ia, ib};
            inv = 0;
        end
        
    endcase
end

endmodule