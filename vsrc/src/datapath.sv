`ifdef VERILATOR
`include "include/common.sv"
`include "src/regfile.sv"
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

u5 rs1,rs2,wd;
u64 rs1Data,rs2Data,wdData;
logic wbEn;

logic lwHold;

logic o2p_fetch, o2p_decode, o2p_execute, o2p_memory, o2p_writeback;

logic o2p;

assign o2p = o2p_fetch & o2p_decode & o2p_execute & o2p_memory & o2p_writeback;

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

programCounter pc_inst(
    .clk(clk),
    .rst(rst),
    .pcIn(64'b0),//todo
    .pcInEn(0),//todo
    .lwHold(0),
    .moduleOut(if_id),
    .ibus_resp(iresp),
    .ibus_req(ireq),
    .ok_to_proceed(o2p_fetch),
    .ok_to_proceed_overall(o2p)
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
    .ok_to_proceed_overall(o2p)
);

execute execute_inst(
    .clk(clk),
    .rst(rst),
    .moduleIn(id_ex),
    .moduleOut(ex_mem),
    .forwardSource(fwd_EX_EX),
    .ok_to_proceed(o2p_execute),
    .ok_to_proceed_overall(o2p)
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
    .ok_to_proceed_overall(o2p)
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
    .ok_to_proceed_overall(o2p)
);



endmodule
