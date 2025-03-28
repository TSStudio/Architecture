`ifdef VERILATOR
`include "include/common.sv"
`endif

module mul import common::*;(
    input logic clk,
    input u64 ia, ib,
    input logic en,
    input logic newOp,
    output logic busy,
    input u3 mulOp,
    output u64 mulOut,
    output u32 mulOut32
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

assign busy = 0;

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

u64 out_tmp;
u32 out32_tmp;

always_comb begin
    case(mulOp)
        3'b000: begin
            mulOut = ia * ib;
            mulOut32 = ia32 * ib32;
            out_tmp = 0;
            out32_tmp = 0;
        end
        3'b100: begin
            if (ib == 0) begin
                mulOut = ~0;
                mulOut32 = ~0;
                out_tmp = 0;
                out32_tmp = 0;
            end else begin
                if (ib32 == 0) begin 
                    out_tmp = ia_abs / ib_abs;
                    mulOut = out_sign ? (~out_tmp) + 1 : out_tmp;
                    mulOut32 = ~0;
                    out32_tmp = 0;
                end else begin
                    out_tmp = ia_abs / ib_abs;
                    out32_tmp = ia32_abs / ib32_abs;
                    mulOut = out_sign ? (~out_tmp) + 1 : out_tmp;
                    mulOut32 = out32_sign ? (~out32_tmp) + 1 : out32_tmp;
                end
            end
        end
        3'b101: begin
            if (ib == 0) begin
                mulOut = ~0;
                mulOut32 = ~0;
                out_tmp = 0;
                out32_tmp = 0;
            end else begin
                if (ib32 == 0) begin
                    mulOut = ia / ib;
                    out_tmp = 0;
                    mulOut32 = ~0;
                    out32_tmp = 0;
                end else begin
                    mulOut = ia / ib;
                    mulOut32 = ia32 / ib32;
                    out_tmp = 0;
                    out32_tmp = 0;
                end
            end
        end
        3'b110: begin
            if(ib==0) begin
                mulOut = ia;
                mulOut32 = ia32;
                out_tmp = 0;
                out32_tmp = 0;
            end else begin
                if(ib32==0) begin
                    out_tmp = ia_abs % ib_abs;
                    mulOut = ia_sign ? (~out_tmp) + 1 : out_tmp;

                    mulOut32 = ia32;
                    out32_tmp = 0;
                end else begin
                    out_tmp = ia_abs % ib_abs;
                    mulOut = ia_sign ? (~out_tmp) + 1 : out_tmp;
                    out32_tmp = ia32_abs % ib32_abs;
                    mulOut32 = ia32_sign ? (~out32_tmp) + 1 : out32_tmp;
                end
            end
        end
        3'b111: begin
            if (ib == 0) begin
                mulOut = ia;
                mulOut32 = ia32;
                out_tmp = 0;
                out32_tmp = 0;
            end else begin
                if (ib32 == 0) begin
                    mulOut = ia % ib;
                    out_tmp = 0;
                    mulOut32 = ia32;
                    out32_tmp = 0;
                end else begin
                    mulOut = ia % ib;
                    mulOut32 = ia32 % ib32;
                    out_tmp = 0;
                    out32_tmp = 0;
                end
            end
        end
        default: begin
            mulOut = 0;
            mulOut32 = 0;
            out_tmp = 0;
            out32_tmp = 0;
        end
        
    endcase
end

endmodule