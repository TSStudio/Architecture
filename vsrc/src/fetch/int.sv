`ifdef VERILATOR
`include "include/common.sv"
`endif

module interruptJudge import common::*;(
    input u2 priviledgeMode,
    input logic trint,
    input logic swint,
    input logic exint,
    input u64 mstatus,
    input u64 mtimecmp,
    input u64 mcycle,
    input u64 mip,
    input u64 mie,

    output logic intEn,
    output exception_t exception
);

always_comb begin
    if(priviledgeMode == 3) begin 
        if(mstatus[3] == 1) begin
            if(exint) begin
                intEn = 1;
                exception = MACHINE_EXTERNAL_INTERRUPT;
            end else if(swint) begin
                intEn = 1;
                exception = MACHINE_SOFTWARE_INTERRUPT;
            end else if((trint)) begin
                intEn = 1;
                exception = MACHINE_TIMER_INTERRUPT;
            end else begin
                intEn = 0;
                exception = NO_EXCEPTION;
            end
        end else begin
            intEn = 0;
            exception = NO_EXCEPTION;
        end
    end else begin
        if(exint & mie[11]) begin
            intEn = 1;
            exception = MACHINE_EXTERNAL_INTERRUPT;
        end else if(swint & mie[3]) begin
            intEn = 1;
            exception = MACHINE_SOFTWARE_INTERRUPT;
        end else if((trint) & mie[7]) begin
            intEn = 1;
            exception = MACHINE_TIMER_INTERRUPT;
        end else begin
            intEn = 0;
            exception = NO_EXCEPTION;
        end
    end
end
endmodule