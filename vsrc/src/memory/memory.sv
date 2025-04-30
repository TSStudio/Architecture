`ifdef VERILATOR
`include "include/common.sv"
`include "src/memory/memory_helper.sv"
`include "src/memory/memory_solver.sv"
`endif

module memory import common::*; import csr_pkg::*;(
    input logic clk,rst,
    input REG_EX_MEM moduleIn,
    output REG_MEM_WB moduleOut,
    output FORWARD_SOURCE forwardSource,

    output dbus_req_t dreq,
    input  dbus_resp_t dresp,

    output logic JumpEn,
    output u64 JumpAddr,

    output logic ok_to_proceed,
    input logic ok_to_proceed_overall,

    input u2 priviledgeMode,
    input u64 mtvec,
    input u64 mepc,
    input u64 mstatus
);

logic cur_mem_op_done;
u64 cur_mem_data;
logic cur_mem_op_started;

assign ok_to_proceed = ~(moduleIn.valid) | ~(moduleIn.isMemRead|moduleIn.isMemWrite) | cur_mem_op_done;

assign JumpEn = (moduleIn.isJump|(moduleIn.isBranch&moduleIn.flagResult)|moduleIn.isCSRWrite) & moduleIn.valid;

assign JumpAddr = moduleIn.isCSRWrite? (
    moduleIn.csr_op==ETRAP?(
        moduleIn.trap==ECALL? mtvec:
        moduleIn.trap==MRET? mepc:
        moduleIn.pcPlus4
    ) : moduleIn.pcPlus4) : {moduleIn.aluOut[63:1],1'b0};

assign forwardSource.valid = moduleIn.valid & moduleIn.wd != 0;
assign forwardSource.isWb = moduleIn.isWriteBack;
assign forwardSource.wd = moduleIn.wd;
assign forwardSource.wdData = moduleIn.isMemRead ? dataOut:moduleIn.aluOut;

msize_t msize;
strobe_t strobe;
addr_t addr;
word_t data;
                
memoryHelper memoryHelper_inst(
    .addressReq(moduleIn.aluOut),
    .dataIn(moduleIn.rs2),
    .memMode(moduleIn.memMode),
    .addr(addr),
    .msize(msize),
    .strobe(strobe),
    .data(data)
);

memorySolver memorySolver_inst(
    .addressReq(moduleIn.aluOut),
    .dataIn(cur_mem_data),
    .memMode(moduleIn.memMode),
    .data(dataOut)
);

u64 dataOut;

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        moduleOut.valid <= 0;
        cur_mem_op_done <= 0;
    end else begin 
        if(ok_to_proceed_overall) begin
            moduleOut.valid <= moduleIn.valid;
            moduleOut.aluOut <= moduleIn.aluOut;
            moduleOut.pcPlus4 <= moduleIn.pcPlus4;
            moduleOut.isWriteBack <= moduleIn.isWriteBack;
            moduleOut.isMemRead <= moduleIn.isMemRead;
            moduleOut.wd <= moduleIn.wd;
            moduleOut.isJump <= moduleIn.isJump;
            moduleOut.memOut <= dataOut;
            moduleOut.instrAddr <= moduleIn.instrAddr;
            moduleOut.instr <= moduleIn.instr;

            moduleOut.isMem <= moduleIn.isMemRead | moduleIn.isMemWrite;
            moduleOut.memAddr <= moduleIn.aluOut;

            if(moduleIn.isCSRWrite && moduleIn.csr_op==ETRAP) begin
                if(moduleIn.trap==ECALL) begin
                    moduleOut.isCSRWrite <= 1;
                    moduleOut.isCSRWrite2 <= 1;
                    moduleOut.isCSRWrite3 <= 1;
                    moduleOut.CSR_addr <= 12'h300; // mstatus
                    moduleOut.CSR_write_value <= {mstatus[63:13],priviledgeMode,mstatus[10:8],mstatus[3],mstatus[6:4],1'b0,mstatus[2:0]};
                    moduleOut.CSR_addr2 <= 12'h341; // mepc
                    moduleOut.CSR_write_value2 <= moduleIn.pcPlus4;
                    moduleOut.CSR_addr3 <= 12'h342; // mcause
                    moduleOut.CSR_write_value3 <= 11;
                    
                    moduleOut.priviledgeModeWrite <= 1;
                    moduleOut.newPriviledgeMode <= 3;
                end else if(moduleIn.trap==MRET) begin
                    moduleOut.isCSRWrite <= 1;
                    moduleOut.isCSRWrite2 <= 0;
                    moduleOut.isCSRWrite3 <= 0;
                    moduleOut.CSR_addr <= 12'h300; // mstatus
                    moduleOut.CSR_write_value <= {mstatus[63:8],1'b1,mstatus[6:4],mstatus[7],mstatus[2:0]};
                    
                    moduleOut.priviledgeModeWrite <= 1;
                    moduleOut.newPriviledgeMode <= mstatus[12:11];
                end else begin
                    moduleOut.isCSRWrite <= 0;
                    moduleOut.isCSRWrite2 <= 0;
                    moduleOut.isCSRWrite3 <= 0;
                    moduleOut.priviledgeModeWrite <= 0;
                end
            end else begin
                moduleOut.isCSRWrite <= moduleIn.isCSRWrite;
                moduleOut.CSR_write_value <= moduleIn.CSR_write_value;
                moduleOut.CSR_addr <= moduleIn.CSR_addr;
                moduleOut.isCSRWrite2 <= 0;
            end

            cur_mem_op_done <= 0;
            cur_mem_op_started <= 0;
        end
        if(dresp.addr_ok & dresp.data_ok & cur_mem_op_started) begin
            cur_mem_data <= dresp.data;
            cur_mem_op_done <= 1;
            dreq.valid <= 0;
        end
        if(moduleIn.valid & (moduleIn.isMemRead|moduleIn.isMemWrite) & ~cur_mem_op_started) begin
            cur_mem_op_started <= 1;
            dreq.addr <= addr;
            dreq.valid <= 1;
            dreq.size <= msize;
            if(moduleIn.isMemRead) begin
                dreq.strobe <= 0;
            end else begin
                dreq.strobe <= strobe;
                dreq.data <= data;
            end
        end
    end
end

endmodule