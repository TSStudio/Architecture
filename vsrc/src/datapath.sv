`ifdef VERILATOR
`include "include/common.sv"
`include "src/regfile.sv"
`include "src/csr.sv"
`include "src/fetch/pc.sv"
`include "src/decode/decoder.sv"
`include "src/execute/execute.sv"
`include "src/memory/memory.sv"
`include "src/writeback/writeback.sv"
`include "src/branch_predictor.sv"
`endif

module datapath import common::*;(
    input logic clk,rst,
    output ibus_req_t  ireq,
	input  ibus_resp_t iresp,
    output dbus_req_t dreq,
    input  dbus_resp_t dresp,
    output WB_COMMIT wb_commit,
    output u64 regs [31:0],
    output u64 csrs [31:0],
    output u2 priviledgeMode,
    input logic skip,
    input logic trint,
    input logic swint,
    input logic exint
);

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        priviledgeMode <= 3;
    end else begin
        if (priviledgeModeWrite) begin
            priviledgeMode <= newPriviledgeMode;
        end
    end
end

REG_IF_ID if_id;
REG_ID_EX id_ex;
REG_EX_MEM ex_mem;
REG_MEM_WB mem_wb;

FORWARD_SOURCE fwd_EX_EX, fwd_MEM_EX;

u5 rs1,rs2,wd;
u64 rs1Data,rs2Data,wdData;
logic wbEn;

logic lwHold;

logic o2p_fetch, o2p_decode, o2p_execute, o2p_memory, o2p_writeback;

logic o2p;

assign o2p = o2p_fetch & o2p_decode & o2p_execute & o2p_memory & o2p_writeback;

logic JumpEn;
u64 JumpAddr;
logic csrJump;

u12 CSR_addr;
u64 CSR_value;

logic CSR_wbEn;
u12 CSR_write_addr;
u64 CSR_write_value;
logic CSR_wbEn2;
u12 CSR_write_addr2;
u64 CSR_write_value2;
logic CSR_wbEn3;
u12 CSR_write_addr3;
u64 CSR_write_value3;

logic priviledgeModeWrite;
u2 newPriviledgeMode;

u64 pcbranch;
logic adopt_branch;

u64 _predictor_instrAddr_to_predict;
logic _predictor_branch_prediction;
logic _predictor_feedback_valid;
u64 _predictor_instrAddr_to_feedback;
logic _predictor_feedback_branch_taken;

regfile regfile_inst(
    .clk(clk),
    .rst(rst),
    .rs1(rs1),
    .rs2(rs2),
    .wd(wd),
    .wdData(wdData),
    .wdEn(wbEn),
    .rs1Data(rs1Data),
    .rs2Data(rs2Data),
    .regs(regs)
);

csr csr_inst(
    .clk(clk),
    .rst(rst),
    .read_target(CSR_addr),
    .read_data(CSR_value),
    .wdEn(CSR_wbEn),
    .write_target(CSR_write_addr),
    .write_data(CSR_write_value),
    .wdEn2(CSR_wbEn2),
    .write_target2(CSR_write_addr2),
    .write_data2(CSR_write_value2),
    .wdEn3(CSR_wbEn3),
    .write_target3(CSR_write_addr3),
    .write_data3(CSR_write_value3),
    .csrs(csrs)
);

branch_predictor predictor_inst(
    .clk(clk),
    .rst(rst),
    .instrAddr_to_predict(_predictor_instrAddr_to_predict),
    .branch_prediction(_predictor_branch_prediction),
    .feedback_valid(_predictor_feedback_valid),
    .instrAddr_to_feedback(_predictor_instrAddr_to_feedback),
    .feedback_branch_taken(_predictor_feedback_branch_taken)
);

programCounter pc_inst(
    .clk(clk),
    .rst(rst),
    .lwHold(lwHold),
    .moduleOut(if_id),
    .ibus_resp(iresp),
    .ibus_req(ireq),
    .ok_to_proceed(o2p_fetch),
    .ok_to_proceed_overall(o2p),
    .JumpEn(JumpEn),
    .JumpAddr(JumpAddr),
    .csrJump(csrJump),
    .trint(trint),
    .swint(swint),
    .exint(exint),
    .priviledgeMode(priviledgeMode),
    .mstatus(csrs[0]),
    .mip(csrs[2]),
    .mie(csrs[1]),
    .pcbranch(pcbranch),
    .adopt_branch(adopt_branch)
);

decoder decoder_inst(
    .clk(clk),
    .rst(rst),
    .lwHold(lwHold),
    .moduleIn(if_id),
    .moduleOut(id_ex),
    .rs1(rs1),
    .rs2(rs2),
    .rs1Data(rs1Data),
    .rs2Data(rs2Data),
    .fwdSrc1(fwd_MEM_EX),
    .fwdSrc2(fwd_EX_EX),
    .ok_to_proceed(o2p_decode),
    .ok_to_proceed_overall(o2p),
    .CSR_addr(CSR_addr),
    .CSR_value(CSR_value),
    .JumpEn(JumpEn),
    .pcbranch(pcbranch),
    .adopt_branch_output(adopt_branch),

    .instrAddr_to_predict(_predictor_instrAddr_to_predict),
    .branch_prediction(_predictor_branch_prediction)
);

execute execute_inst(
    .clk(clk),
    .rst(rst),
    .moduleIn(id_ex),
    .moduleOut(ex_mem),
    .forwardSource(fwd_EX_EX),
    .ok_to_proceed(o2p_execute),
    .ok_to_proceed_overall(o2p),
    .JumpEn(JumpEn)
);

memory memory_inst(
    .clk(clk),
    .rst(rst),
    .moduleIn(ex_mem),
    .moduleOut(mem_wb),
    .forwardSource(fwd_MEM_EX),
    .dreq(dreq),
    .dresp(dresp),
    .ok_to_proceed(o2p_memory),
    .ok_to_proceed_overall(o2p),
    .JumpEn(JumpEn),
    .JumpAddr(JumpAddr),
    .priviledgeMode(priviledgeMode),
    .mtvec(csrs[3]),
    .mepc(csrs[6]),
    .mstatus(csrs[0]),
    .skip(skip),
    .csrJump(csrJump),

    .priviledgeModeWrite(priviledgeModeWrite),
    .newPriviledgeMode(newPriviledgeMode),

    .feedback_valid(_predictor_feedback_valid),
    .feedback_pc(_predictor_instrAddr_to_feedback),
    .feedback_result(_predictor_feedback_branch_taken)
);

writeback writeback_inst(
    .clk(clk),
    .rst(rst),
    .moduleIn(mem_wb),
    .wbEn(wbEn),
    .wd(wd),
    .wbData(wdData),
    .moduleOut(wb_commit),
    .ok_to_proceed(o2p_writeback),
    .ok_to_proceed_overall(o2p),
    .CSR_value(CSR_write_value),
    .CSR_addr(CSR_write_addr),
    .CSR_wbEn(CSR_wbEn),

    .CSR_value2(CSR_write_value2),
    .CSR_addr2(CSR_write_addr2),
    .CSR_wbEn2(CSR_wbEn2),

    .CSR_value3(CSR_write_value3),
    .CSR_addr3(CSR_write_addr3),
    .CSR_wbEn3(CSR_wbEn3)
);



endmodule
