`ifdef VERILATOR
`include "include/common.sv"
`include "include/csr.sv"
`include "src/memory/memory_helper.sv"
`include "src/memory/memory_solver.sv"
`include "src/memory/prediction_util.sv"
`include "src/memory/amo_alu.sv"
`endif

module memory import common::*; import csr_pkg::*;(
    input logic clk,rst,
    input REG_EX_MEM moduleIn,
    output REG_MEM_WB moduleOut,
    output FORWARD_SOURCE forwardSource,

    output dbus_req_t dreq,
    input  dbus_resp_t dresp,

    output logic JumpEn,
    output logic csrJump,
    output u64 JumpAddr,

    output logic ok_to_proceed,
    input logic ok_to_proceed_overall,

    output logic priviledgeModeWrite,
    output u2 newPriviledgeMode,

    input u2 priviledgeMode,
    input u64 mtvec,
    input u64 mepc,
    input u64 mstatus,
    input logic skip,

    output logic feedback_valid,
    output u64 feedback_pc,
    output logic feedback_result
);

u2 mem_state; // 0: idle, 1: request sent, 2: request2 sent, 3: response received

u64 cur_mem_data;
logic cur_mem_op_started;

assign ok_to_proceed = ~(moduleIn.valid) | ~(moduleIn.isMemRead|moduleIn.isMemWrite) | mem_state == 3;

assign JumpEn = (
    (moduleIn.adopt_branch!=
        (moduleIn.isJump|(moduleIn.isBranch&moduleIn.flagResult))
    |moduleIn.isCSRWrite) 
& moduleIn.valid) | exception!=NO_EXCEPTION;

assign feedback_valid = moduleIn.valid & moduleIn.isBranch & prediction_util_valid;
assign feedback_pc = moduleIn.instrAddr;
assign feedback_result = moduleIn.flagResult;

assign csrJump = ((moduleIn.isCSRWrite) & moduleIn.valid) | exception!=NO_EXCEPTION;

assign JumpAddr = exception!=NO_EXCEPTION? mtvec:
    moduleIn.isCSRWrite? (
        moduleIn.csr_op==ETRAP&&moduleIn.trap==MRET? mepc: moduleIn.pcPlus4
    ): (moduleIn.isJump|(moduleIn.isBranch&moduleIn.flagResult))?
      {moduleIn.addr_if_jump[63:1],1'b0}:{moduleIn.addr_if_not_jump[63:1],1'b0};

assign forwardSource.valid = moduleIn.valid & moduleIn.wd != 0;
assign forwardSource.isWb = moduleIn.isWriteBack;
assign forwardSource.wd = moduleIn.wd;
assign forwardSource.wdData = moduleIn.isJump?moduleIn.pcPlus4 : (moduleIn.isMemRead|moduleIn.is_amo) ? dataOut : moduleIn.aluOut;

prediction_util prediction_util_inst(
    .clk(clk),
    .rst(rst),
    .valid(prediction_util_valid),
    .isPrediction((moduleIn.isJump|moduleIn.isBranch) & moduleIn.valid),
    .predictionHit(moduleIn.adopt_branch==(moduleIn.isJump|(moduleIn.isBranch&moduleIn.flagResult)))
);

u64 amo_res;

amo_alu amo_alu_inst(
    .m_rs1(dresp.data),
    .rs2(moduleIn.rs2),
    .amo_type(moduleIn.amo_type),
    .result(amo_res)
);

logic prediction_util_valid;

msize_t msize;
strobe_t strobe;
addr_t addr;
word_t data;

logic skp_send;

logic memNotAligned, addr_not_aligned;

assign memNotAligned = (moduleIn.isMemRead | moduleIn.isMemWrite | moduleIn.is_amo) & addr_not_aligned & moduleIn.valid;
exception_t exception;

assign exception = (moduleIn.exception_valid) ? moduleIn.exception : 
                  (memNotAligned) ? (
                    moduleIn.isMemRead ? LOAD_ADDRESS_MISALIGNED :
                    moduleIn.isMemWrite ? STORE_AMO_ADDRESS_MISALIGNED :
                    NO_EXCEPTION
                  ): NO_EXCEPTION;

u64 addr_req;
u64 data_req;

assign data_req=moduleIn.is_amo?amo_res:moduleIn.rs2;

assign addr_req=moduleIn.is_amo?moduleIn.rs1:moduleIn.aluOut;
                
memoryHelper memoryHelper_inst(
    .addressReq(addr_req),
    .dataIn(data_req),
    .memMode(moduleIn.memMode),
    .addr(addr),
    .msize(msize),
    .strobe(strobe),
    .data(data),
    .mis_aligned(addr_not_aligned)
);

memorySolver memorySolver_inst(
    .addressReq(addr_req),
    .dataIn(cur_mem_data),
    .memMode(moduleIn.memMode),
    .data(dataOut)
);

u64 dataOut;

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        moduleOut.valid <= 0;
        mem_state <= 0;
    end else begin 
        if(ok_to_proceed_overall) begin
            prediction_util_valid <= 1;

            moduleOut.valid <= moduleIn.valid | exception!=NO_EXCEPTION;
            moduleOut.aluOut <= moduleIn.aluOut;
            moduleOut.pcPlus4 <= moduleIn.pcPlus4;
            moduleOut.isWriteBack <= moduleIn.isWriteBack & ~moduleIn.exception_valid & ~memNotAligned;
            moduleOut.isMemRead <= moduleIn.isMemRead;
            moduleOut.wd <= moduleIn.wd;
            moduleOut.isJump <= moduleIn.isJump;
            moduleOut.memOut <= dataOut;
            moduleOut.instrAddr <= moduleIn.instrAddr;
            moduleOut.instr <= moduleIn.instr;

            moduleOut.isMem <= moduleIn.isMemRead | moduleIn.isMemWrite;
            moduleOut.memAddr <= addr_req;
            moduleOut.skip <= skp_send;

            if(moduleIn.exception_valid | (memNotAligned & moduleIn.valid)) begin
                moduleOut.isCSRWrite <= 1;
                moduleOut.isCSRWrite2 <= 1;
                moduleOut.isCSRWrite3 <= 1;
                moduleOut.CSR_addr <= 12'h300; // mstatus
                moduleOut.CSR_write_value <= {mstatus[63:13],priviledgeMode,mstatus[10:8],mstatus[3],mstatus[6:4],1'b0,mstatus[2:0]};
                moduleOut.CSR_addr2 <= 12'h341; // mepc
                moduleOut.CSR_write_value2 <= moduleIn.instrAddr;
                moduleOut.CSR_addr3 <= 12'h342; // mcause
                moduleOut.CSR_write_value3[62:0] <= 
                    exception==SUPERVISOR_SOFTWARE_INTERRUPT?1:
                    exception==MACHINE_SOFTWARE_INTERRUPT?3:
                    exception==SUPERVISOR_TIMER_INTERRUPT?5:
                    exception==MACHINE_TIMER_INTERRUPT?7:
                    exception==SUPERVISOR_EXTERNAL_INTERRUPT?9:
                    exception==MACHINE_EXTERNAL_INTERRUPT?11:
                    exception==ILLEGAL_INSTRUCTION?2:
                    exception==INSTRUCTION_ADDRESS_MISALIGNED?0:
                    exception==ENVIRONMENT_CALL_FROM_U_MODE?8:
                    exception==LOAD_ADDRESS_MISALIGNED?4:
                    exception==STORE_AMO_ADDRESS_MISALIGNED?6:0;
                moduleOut.CSR_write_value3[63:63] <= (exception<=4'b0101)? 1 : 0;// interrupt
                
                priviledgeModeWrite <= 1;
                newPriviledgeMode <= 3;
            end else if(moduleIn.isCSRWrite && moduleIn.csr_op==ETRAP && moduleIn.valid && moduleIn.trap==MRET) begin
                // if(moduleIn.trap==ECALL) begin
                //     moduleOut.isCSRWrite <= 1;
                //     moduleOut.isCSRWrite2 <= 1;
                //     moduleOut.isCSRWrite3 <= 1;
                //     moduleOut.CSR_addr <= 12'h300; // mstatus
                //     moduleOut.CSR_write_value <= {mstatus[63:13],priviledgeMode,mstatus[10:8],mstatus[3],mstatus[6:4],1'b0,mstatus[2:0]};
                //     moduleOut.CSR_addr2 <= 12'h341; // mepc
                //     moduleOut.CSR_write_value2 <= moduleIn.instrAddr;
                //     moduleOut.CSR_addr3 <= 12'h342; // mcause
                //     moduleOut.CSR_write_value3 <= 8;
                    
                //     priviledgeModeWrite <= 1;
                //     newPriviledgeMode <= 3;
                // end else if(moduleIn.trap==MRET) begin
                moduleOut.isCSRWrite <= 1;
                moduleOut.isCSRWrite2 <= 0;
                moduleOut.isCSRWrite3 <= 0;
                moduleOut.CSR_addr <= 12'h300; // mstatus
                moduleOut.CSR_write_value <= {mstatus[63:8],1'b1,mstatus[6:4],mstatus[7],mstatus[2:0]};
                
                priviledgeModeWrite <= 1;
                newPriviledgeMode <= mstatus[12:11];
                // end else begin
                //     moduleOut.isCSRWrite <= 0;
                //     moduleOut.isCSRWrite2 <= 0;
                //     moduleOut.isCSRWrite3 <= 0;
                //     priviledgeModeWrite <= 0;
                // end
            end else begin
                moduleOut.isCSRWrite <= moduleIn.isCSRWrite;
                moduleOut.CSR_write_value <= moduleIn.CSR_write_value;
                moduleOut.CSR_addr <= moduleIn.CSR_addr;
                moduleOut.isCSRWrite2 <= 0;
                moduleOut.isCSRWrite3 <= 0;
                priviledgeModeWrite <= 0;
            end

            mem_state <= 0;
            cur_mem_op_started <= 0;
        end else begin 
            prediction_util_valid <= 0;
        end
        if(dresp.addr_ok & dresp.data_ok & mem_state==1) begin
            cur_mem_data <= dresp.data;
            skp_send <= skip;
            dreq.valid <= 0;

            if(moduleIn.is_amo) begin //todo LR SC should be considered
                mem_state <= 2;
                dreq.valid <= 1;
                dreq.addr <= addr;
                dreq.strobe <= strobe;
                dreq.data <= data;
                dreq.size <= msize;
            end else begin
                mem_state <= 3;
            end
        end else if(dresp.addr_ok & dresp.data_ok & mem_state==2) begin
            dreq.valid <= 0;
            mem_state <= 3;
        end
        if(moduleIn.valid & (moduleIn.isMemRead|moduleIn.isMemWrite) & mem_state==0) begin
            //todo LR SC should be considered
            mem_state <= 1;
            dreq.addr <= addr;
            dreq.valid <= 1;
            dreq.size <= msize;
            if(moduleIn.isMemRead | moduleIn.is_amo) begin
                dreq.strobe <= 0;
            end else begin
                dreq.strobe <= strobe;
                dreq.data <= data;
            end
        end
    end
end

endmodule