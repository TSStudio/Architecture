`ifdef VERILATOR
`include "include/common.sv"
`include "src/execute/alu.sv"
`include "src/execute/mul.sv"
`include "src/mul_core/mul_core.sv"
`endif

module execute import common::*;(
    input logic clk,rst,
    input REG_ID_EX moduleIn,
    output REG_EX_MEM moduleOut,
    output FORWARD_SOURCE forwardSource,

    output logic ok_to_proceed,
    input logic ok_to_proceed_overall,

    input logic JumpEn
);

u64 ia,ib;

assign ia=moduleIn.srcA==2'b00 ? 64'b0:
            moduleIn.srcA==2'b01 ? moduleIn.rs1:
            moduleIn.srcA==2'b10 ? moduleIn.pc:
            moduleIn.srcA==2'b11 ? moduleIn.pcPlus4:
            0;

assign ib=moduleIn.srcB==2'b00 ? moduleIn.rs2:
            moduleIn.srcB==2'b01 ? moduleIn.imm:
            moduleIn.srcB==2'b10 ? (moduleIn.imm<<12):
            moduleIn.CSR_value;

u64 aluOut;
u32 aluOut32;
u64 mulOut;
u64 mulOutInved;
logic mulinv;
logic mulready;

mbus_req_t mulReq;

u64 CSR_write_value;

assign CSR_write_value = 
                        moduleIn.csr_op==CSRRW ? moduleIn.rs1:
                        moduleIn.csr_op==CSRRS ? moduleIn.CSR_value | moduleIn.rs1:
                        moduleIn.csr_op==CSRRC ? moduleIn.CSR_value & ~moduleIn.rs1:
                        moduleIn.csr_op==CSRRWI ? moduleIn.imm:
                        moduleIn.csr_op==CSRRSI ? moduleIn.CSR_value | moduleIn.imm:
                        moduleIn.csr_op==CSRRCI ? moduleIn.CSR_value & ~moduleIn.imm:
                        0;

alu alu(
    .clk(clk),
    .ia(ia),
    .ib(ib),
    .aluOp(moduleIn.aluOp),
    .aluOut(aluOut),
    .aluOut32(aluOut32)
);

mul mul(
    .clk(clk),
    .ia(ia),
    .ib(ib),
    .mulOp(moduleIn.mulOp),
    .req(mulReq),
    .inv(mulinv)
);

mul_core mul_core(
    .clk(clk),
    .rst(ok_to_proceed_overall),
    .op_begin(moduleIn.rvm&~req_submitted),
    .req(mulReq),
    .busy(mulbusy),
    .mulOut(mulOut),
    .ready(mulready),
    .divZero(divZero)
);

logic req_submitted;
logic divZero;

assign mulOutInved = mulinv ? (divZero ? mulOut : ~mulOut+1) : mulOut;

u64 datUse;

always_comb begin
    if(moduleIn.rvm) begin
        if (moduleIn.rv64) begin
            datUse = {{32{mulOutInved[31]}},mulOutInved[31:0]};
        end else begin
            datUse = mulOutInved;
        end
    end else begin
        if (moduleIn.rv64) begin
            datUse = {{32{aluOut32[31]}},aluOut32};
        end else begin
            if (moduleIn.cns) begin
                if(moduleIn.flagInv^(flags[moduleIn.useflag])) begin
                    datUse = 1;
                end else begin
                    datUse = 0;
                end
                
            end else begin
                datUse = aluOut;
            end
        end
    end
end

logic mulbusy;

assign forwardSource.valid = moduleIn.valid & moduleIn.wd != 0;
assign forwardSource.isWb = moduleIn.isWriteBack;
assign forwardSource.wd = moduleIn.wd;
assign forwardSource.wdData = moduleIn.isJump?moduleIn.pcPlus4 : datUse;

assign ok_to_proceed = (moduleIn.rvm ? mulready : 1) | ~moduleIn.valid;

u3 flags;//0->2 ia<ib (unsigned)(ia<ib) ia=ib

u64 compB;

assign compB = moduleIn.cmpSrcB ? moduleIn.imm : moduleIn.rs2;

always_comb begin
    if(moduleIn.rs1[63]^compB[63]) begin
        flags[0] = moduleIn.rs1[63];
    end else begin
        flags[0] = moduleIn.rs1<compB;
    end
    flags[1] = moduleIn.rs1<compB;
    flags[2] = moduleIn.rs1==compB;
end

always_ff @(posedge clk  or posedge rst) begin
    if(rst) begin
        moduleOut.valid <= 0;
    end else if(ok_to_proceed_overall) begin
        moduleOut.valid <= moduleIn.valid & ~JumpEn;
        moduleOut.exception_valid <= moduleIn.exception_valid & ~JumpEn;
        moduleOut.exception <= moduleIn.exception;
        moduleOut.rs1 <= moduleIn.rs1;
        moduleOut.rs2 <= moduleIn.rs2;
        moduleOut.aluOut <= datUse;
        moduleOut.pcPlus4 <= moduleIn.pcPlus4;
        moduleOut.isWriteBack <= moduleIn.isWriteBack;
        moduleOut.wd <= moduleIn.wd;
        moduleOut.isBranch <= moduleIn.isBranch;
        moduleOut.isJump <= moduleIn.isJump;

        moduleOut.isMemRead <= moduleIn.isMemRead;
        moduleOut.isMemWrite <= moduleIn.isMemWrite;
        moduleOut.memMode <= moduleIn.memMode;

        moduleOut.instrAddr <= moduleIn.instrAddr;
        moduleOut.instr <= moduleIn.instr;

        moduleOut.flagResult <= moduleIn.flagInv^(flags[moduleIn.useflag]);

        moduleOut.isCSRWrite <= moduleIn.isCSRWrite;
        moduleOut.CSR_write_value <= CSR_write_value;
        moduleOut.CSR_addr <= moduleIn.CSR_addr;
        moduleOut.csr_op <= moduleIn.csr_op;
        moduleOut.trap <= moduleIn.trap;

        moduleOut.addr_if_not_jump <= moduleIn.addr_if_not_jump;
        moduleOut.addr_if_jump <= moduleIn.addr_if_jump;
        moduleOut.adopt_branch <= moduleIn.adopt_branch;

        moduleOut.is_amo <= moduleIn.is_amo;
        moduleOut.amo_type <= moduleIn.amo_type;

        req_submitted <= 0;
    end else begin
        req_submitted <= 1;
    end
end


endmodule