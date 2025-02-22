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
    output WB_COMMIT wb_commit,
    output u64 regs [31:0]
);

REG_IF_ID if_id;
REG_ID_EX id_ex;
REG_EX_MEM ex_mem;
REG_MEM_WB mem_wb;

u5 rs1,rs2,wd;
u64 rs1Data,rs2Data,wdData;
logic wbEn;

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
    .bubbleHold(0),//todo
    .moduleOut(if_id),
    .ibus_resp(iresp),
    .ibus_req(ireq)
);

decoder decoder_inst(
    .clk(clk),
    .rst(rst),
    .bubbleHold(0),//todo
    .moduleIn(if_id),
    .moduleOut(id_ex),
    .rs1(rs1),
    .rs2(rs2),
    .rs1Data(rs1Data),
    .rs2Data(rs2Data)
);

execute execute_inst(
    .clk(clk),
    .rst(rst),
    .bubbleHold(0),//todo
    .moduleIn(id_ex),
    .moduleOut(ex_mem)
);

memory memory_inst(
    .clk(clk),
    .rst(rst),
    .bubbleHold(0),//todo
    .moduleIn(ex_mem),
    .moduleOut(mem_wb)
);

writeback writeback_inst(
    .clk(clk),
    .rst(rst),
    .moduleIn(mem_wb),
    .wbEn(wbEn),
    .wd(wd),
    .wbData(wdData),
    .moduleOut(wb_commit)
    
);



endmodule
