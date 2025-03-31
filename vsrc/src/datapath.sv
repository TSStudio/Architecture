`ifdef VERILATOR
`include "include/common.sv"
`include "src/regfile.sv"
`include "src/csr.sv"
`include "src/fetch/pc.sv"
`include "src/decode/decoder.sv"
`include "src/execute/execute.sv"
`include "src/memory/memory.sv"
`include "src/writeback/writeback.sv"
`endif

module datapath import common::*;(
    input logic clk,rst,
    output ibus_req_t  ireq,
	input  ibus_resp_t iresp,
    output dbus_req_t dreq,
    input  dbus_resp_t dresp,
    output WB_COMMIT wb_commit,
    output u64 regs [31:0]
);

REG_IF_ID if_id;
REG_ID_EX id_ex;
REG_EX_MEM ex_mem;
REG_MEM_WB mem_wb;

FORWARD_SOURCE fwd_EX_EX, fwd_MEM_EX;

CSR_FORWARD_SOURCE csr_fwd_EX_EX, csr_fwd_MEM_EX;

u5 rs1,rs2,wd;
u64 rs1Data,rs2Data,wdData;
logic wbEn;

logic lwHold;

logic o2p_fetch, o2p_decode, o2p_execute, o2p_memory, o2p_writeback;

logic o2p;

assign o2p = o2p_fetch & o2p_decode & o2p_execute & o2p_memory & o2p_writeback;

logic JumpEn;
u64 JumpAddr;

u12 CSR_addr;
u64 CSR_value;

logic CSR_wbEn;
u12 CSR_write_addr;
u64 CSR_write_value;

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
    .write_target(CSR_write_addr),
    .write_data(CSR_write_value),
    .csrs(),
    .wdEn(CSR_wbEn)
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
    .JumpAddr(JumpAddr)
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
    .csrFwdSrc1(csr_fwd_MEM_EX),
    .csrFwdSrc2(csr_fwd_EX_EX),
    .ok_to_proceed(o2p_decode),
    .ok_to_proceed_overall(o2p),
    .CSR_addr(CSR_addr),
    .CSR_value(CSR_value),
    .JumpEn(JumpEn)
);

execute execute_inst(
    .clk(clk),
    .rst(rst),
    .moduleIn(id_ex),
    .moduleOut(ex_mem),
    .forwardSource(fwd_EX_EX),
    .csrForwardSource(csr_fwd_EX_EX),
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
    .csrForwardSource(csr_fwd_MEM_EX),
    .dreq(dreq),
    .dresp(dresp),
    .ok_to_proceed(o2p_memory),
    .ok_to_proceed_overall(o2p),
    .JumpEn(JumpEn),
    .JumpAddr(JumpAddr)
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
    .CSR_wbEn(CSR_wbEn)
);



endmodule
