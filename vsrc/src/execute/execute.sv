`ifdef VERILATOR
`include "include/common.sv"
`include "src/execute/alu.sv"
`include "src/execute/mul.sv"
`endif

module execute import common::*;(
    input logic clk,rst,
    input REG_ID_EX moduleIn,
    output REG_EX_MEM moduleOut,
    output FORWARD_SOURCE forwardSource,
    output CSR_FORWARD_SOURCE csrForwardSource,

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
u32 mulOut32;

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
    .en(mulen),
    .busy(mulbusy),
    .newOp(newOp),
    .ia(ia),
    .ib(ib),
    .mulOp(moduleIn.mulOp[2:0]),
    .mulOut(mulOut),
    .mulOut32(mulOut32)
);

initial begin
    moduleOut.valid = 0;
end

u64 datUse;

always_comb begin
    if(moduleIn.rvm) begin
        if (moduleIn.rv64) begin
            datUse = {{32{mulOut32[31]}},mulOut32};
        end else begin
            datUse = mulOut;
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

logic mulen;
logic mulbusy;
logic newOp;

assign mulen = moduleIn.rvm;

assign forwardSource.valid = moduleIn.valid & moduleIn.wd != 0;
assign forwardSource.isWb = moduleIn.isWriteBack;
assign forwardSource.wd = moduleIn.wd;
assign forwardSource.wdData = datUse;

assign csrForwardSource.valid = moduleIn.valid & moduleIn.isCSRWrite;
assign csrForwardSource.wd = moduleIn.CSR_addr;
assign csrForwardSource.wdData = CSR_write_value;

assign ok_to_proceed = 1; // always proceed, todo if multiply cannot complete in one cycle

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

        newOp <= 1;
    end

    if(newOp && !ok_to_proceed_overall) begin
        newOp <= 0;
    end
end


endmodule