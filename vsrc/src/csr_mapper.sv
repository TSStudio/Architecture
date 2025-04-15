`ifdef VERILATOR
`include "include/common.sv"
`include "include/csr.sv"
`endif 

module csr_mapper import common::*; import csr_pkg::*;(
    input u12 target,
    output u5 mapped_target,
    output u64 mask
);
always_comb begin
    case(target)
        CSR_MSTATUS: mapped_target = 0;
        CSR_MHARTID: mapped_target = 4;
        CSR_MIE: mapped_target = 1;
        CSR_MIP: mapped_target = 2;
        CSR_MTVEC: mapped_target = 3;
        CSR_MSCRATCH: mapped_target = 5;
        CSR_MEPC: mapped_target = 6;
        CSR_SATP: mapped_target = 7;
        CSR_MCAUSE: mapped_target = 8;
        CSR_MCYCLE: mapped_target = 9;
        CSR_MTVAL: mapped_target = 10;
        CSR_PMPADDR0: mapped_target = 11;
        CSR_PMPCFG0: mapped_target = 12;
        CSR_MEDELEG: mapped_target = 13;
        CSR_MIDELEG: mapped_target = 14;
        CSR_STVEC: mapped_target = 15;
        CSR_SSTATUS: mapped_target = 0;
        CSR_SSCRATCH: mapped_target = 17;
        CSR_SEPC: mapped_target = 18;
        CSR_SCAUSE: mapped_target = 19;
        CSR_STVAL: mapped_target = 20;
        CSR_SIE: mapped_target = 21;
        CSR_SIP: mapped_target = 22;
        default: mapped_target = 31;
    endcase
    case(target)
        CSR_MSTATUS: mask = MSTATUS_MASK;
        CSR_SSTATUS: mask = SSTATUS_MASK;
        CSR_MIP: mask = MIP_MASK;
        CSR_MTVEC: mask = MTVEC_MASK;
        CSR_MEDELEG: mask = MEDELEG_MASK;
        CSR_MIDELEG: mask = MIDELEG_MASK;
        default: mask = ~64'h0;
    endcase
end

endmodule