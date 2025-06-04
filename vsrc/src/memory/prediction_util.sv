`ifdef VERILATOR
`include "include/common.sv"
`endif

module prediction_util import common::*;(
    input logic clk,
    input logic rst,
    input logic valid,
    input logic isPrediction,
    input logic predictionHit
);

logic[30:0] print_cnt;
real total_branch;
real succ_branch;


always_ff @(posedge clk) begin
    if(rst) begin
        print_cnt <= '0;
        total_branch <= '0;
        succ_branch <= '0;
    end else begin 
        if(valid) begin
            if(isPrediction) begin
                total_branch <= total_branch + 1;
            end
            if(isPrediction && predictionHit) begin
                succ_branch <= succ_branch + 1;
            end
        end
        if(print_cnt[25] == 1)begin // 每隔固定的时间输出结果
            $display("total_jump:%.2f ", total_branch);
            $display("branch success:%.2f%%", (succ_branch/total_branch)*100);
            print_cnt <= '0;	
        end else begin
            print_cnt <= print_cnt + 1;
        end
    end
end


endmodule