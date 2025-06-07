`ifdef VERILATOR
`ifndef AMO_ALU_SV
`define AMO_ALU_SV
`include "include/common.sv"
`endif

module amo_alu import common::*;(
    input u64 m_rs1,rs2,
    input amo_t amo_type,
    output u64 result
);

u32 m_rs1_lo, rs2_lo, res32;
assign m_rs1_lo = m_rs1[31:0];
assign rs2_lo = rs2[31:0];
u64 res_signextend;
assign res_signextend = {{32{res32[31]}}, res32};

    // LR_W = 6'b000010,
    // SC_W = 6'b000011,
    // AMO_SWAP_W = 6'b000001,
    // AMO_ADD_W = 6'b000000,
    // AMO_XOR_W = 6'b000100,
    // AMO_AND_W = 6'b001100,
    // AMO_OR_W = 6'b001000,
    // AMO_MIN_W = 6'b010000,
    // AMO_MAX_W = 6'b010100,
    // AMO_MINU_W = 6'b011000,
    // AMO_MAXU_W = 6'b011100,
    // LR_D = 6'b100010,
    // SC_D = 6'b100011,
    // AMO_SWAP_D = 6'b100001,
    // AMO_ADD_D = 6'b100000,
    // AMO_XOR_D = 6'b100100,
    // AMO_AND_D = 6'b101100,
    // AMO_OR_D = 6'b101000,
    // AMO_MIN_D = 6'b110000,
    // AMO_MAX_D = 6'b110100,
    // AMO_MINU_D = 6'b111000,
    // AMO_MAXU_D = 6'b111100
always_comb begin
    res32 = 0; // Default value
    case (amo_type)
        AMO_SWAP_W: begin 
            res32 = rs2_lo;
            result = res_signextend;
        end
        AMO_ADD_W: begin
            res32 = m_rs1_lo + rs2_lo;
            result = res_signextend;
        end
        AMO_XOR_W: begin
            res32 = m_rs1_lo ^ rs2_lo;
            result = res_signextend;
        end
        AMO_AND_W: begin
            res32 = m_rs1_lo & rs2_lo;
            result = res_signextend;
        end
        AMO_OR_W: begin
            res32 = m_rs1_lo | rs2_lo;
            result = res_signextend;
        end
        AMO_MIN_W: begin
            res32 = ($signed(m_rs1_lo) < $signed(rs2_lo)) ? m_rs1_lo : rs2_lo;
            result = res_signextend;
        end
        AMO_MAX_W: begin
            res32 = ($signed(m_rs1_lo) > $signed(rs2_lo)) ? m_rs1_lo : rs2_lo;
            result = res_signextend;
        end
        AMO_MINU_W: begin
            res32 = (m_rs1_lo < rs2_lo) ? m_rs1_lo : rs2_lo;
            result = res_signextend;
        end
        AMO_MAXU_W: begin
            res32 = (m_rs1_lo > rs2_lo) ? m_rs1_lo : rs2_lo;
            result = res_signextend;
        end
        AMO_SWAP_D: begin
            result = rs2;
        end
        AMO_ADD_D: begin
            result = m_rs1 + rs2;
        end
        AMO_XOR_D: begin
            result = m_rs1 ^ rs2;
        end
        AMO_AND_D: begin
            result = m_rs1 & rs2;
        end
        AMO_OR_D: begin
            result = m_rs1 | rs2;
        end
        AMO_MIN_D: begin
            result = ($signed(m_rs1) < $signed(rs2)) ? m_rs1 : rs2;
        end
        AMO_MAX_D: begin
            result = ($signed(m_rs1) > $signed(rs2)) ? m_rs1 : rs2;
        end
        AMO_MINU_D: begin
            result = (m_rs1 < rs2) ? m_rs1 : rs2;
        end
        AMO_MAXU_D: begin
            result = (m_rs1 > rs2) ? m_rs1 : rs2;
        end
        SC_W: begin
            res32 = rs2_lo;
            result = res_signextend;
        end
        SC_D: begin
            result = rs2;
        end
        default: begin
            result = 0; // Default case, should not happen
        end

    endcase
end


endmodule


`endif