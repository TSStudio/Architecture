`ifndef __CORE_SV
`define __CORE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/csr.sv"
`include "src/datapath.sv"
`endif

module core import common::*; import csr_pkg::*;(
	input  logic       clk, reset,
	output ibus_req_t  ireq,
	input  ibus_resp_t iresp,
	output dbus_req_t  dreq,
	input  dbus_resp_t dresp,
	input  logic       trint, swint, exint,
	output u2          priviledgeMode,
	output u64         satp,
	input  logic skip
);

assign satp = csrs[7];

WB_COMMIT wb_commit;
u64 regs[31:0];
u64 csrs[31:0];
datapath datapath_inst(
	.clk(clk),
	.rst(reset),
	.ireq(ireq),
	.iresp(iresp),
	.dreq(dreq),
	.dresp(dresp),
	.wb_commit(wb_commit),
	.regs(regs),
	.csrs(csrs),
	.priviledgeMode(priviledgeMode),
	.skip(skip)
);

`ifdef VERILATOR
	DifftestInstrCommit DifftestInstrCommit(
		.clock              (clk),
		.coreid             (csrs[4][7:0]),
		.index              (0),
		.valid              (wb_commit.valid),
		.pc                 (wb_commit.instrAddr),
		.instr              (wb_commit.instr),
		.skip               ((wb_commit.isMem & wb_commit.skip)),
		.isRVC              (0),
		.scFailed           (0),
		.wen                (wb_commit.isWb),
		.wdest              ({3'b0,wb_commit.wd}),
		.wdata              (wb_commit.wdData)
	);

	DifftestArchIntRegState DifftestArchIntRegState (
		.clock              (clk),
		.coreid             (csrs[4][7:0]),
		.gpr_0              (regs[0]),
		.gpr_1              (regs[1]),
		.gpr_2              (regs[2]),
		.gpr_3              (regs[3]),
		.gpr_4              (regs[4]),
		.gpr_5              (regs[5]),
		.gpr_6              (regs[6]),
		.gpr_7              (regs[7]),
		.gpr_8              (regs[8]),
		.gpr_9              (regs[9]),
		.gpr_10             (regs[10]),
		.gpr_11             (regs[11]),
		.gpr_12             (regs[12]),
		.gpr_13             (regs[13]),
		.gpr_14             (regs[14]),
		.gpr_15             (regs[15]),
		.gpr_16             (regs[16]),
		.gpr_17             (regs[17]),
		.gpr_18             (regs[18]),
		.gpr_19             (regs[19]),
		.gpr_20             (regs[20]),
		.gpr_21             (regs[21]),
		.gpr_22             (regs[22]),
		.gpr_23             (regs[23]),
		.gpr_24             (regs[24]),
		.gpr_25             (regs[25]),
		.gpr_26             (regs[26]),
		.gpr_27             (regs[27]),
		.gpr_28             (regs[28]),
		.gpr_29             (regs[29]),
		.gpr_30             (regs[30]),
		.gpr_31             (regs[31])
	);

    DifftestTrapEvent DifftestTrapEvent(
		.clock              (clk),
		.coreid             (csrs[4][7:0]),
		.valid              (0),
		.code               (0),
		.pc                 (0),
		.cycleCnt           (0),
		.instrCnt           (0)
	);

	DifftestCSRState DifftestCSRState(
		.clock              (clk),
		.coreid             (csrs[4][7:0]),
		.priviledgeMode     (priviledgeMode),
		.mstatus            (csrs[0]),
		.sstatus            (csrs[0] & SSTATUS_MASK),
		.mepc               (csrs[6]),
		.sepc               (csrs[18]),
		.mtval              (csrs[10]),
		.stval              (csrs[20]),
		.mtvec              (csrs[3]),
		.stvec              (csrs[15]),
		.mcause             (csrs[8]),
		.scause             (csrs[19]),
		.satp               (csrs[7]),
		.mip                (csrs[2]),
		.mie                (csrs[1]),
		.mscratch           (csrs[5]),
		.sscratch           (csrs[17]),
		.mideleg            (csrs[14]),
		.medeleg            (csrs[13])
	);
`endif
endmodule
`endif