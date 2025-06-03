`ifdef VERILATOR
`include "include/common.sv"
`endif

module branch_predictor import common::*;(
    input logic clk, rst,
    input u64 instrAddr_to_predict,
    output logic branch_prediction,

    input u64 instrAddr_to_feedback,
    input logic feedback_valid,
    input logic feedback_branch_taken
);

// 1024 prediction table
u2 prediction_table[0:1023];

assign branch_prediction = prediction_table[instrAddr_to_predict[11:2]][1];

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        // Reset prediction table
        for (int i = 0; i < 1024; i++) begin
            prediction_table[i] <= 2'b10; // Weakly taken
        end
    end else if (feedback_valid) begin
        // Update prediction table based on feedback
        if (feedback_branch_taken) begin
            if (prediction_table[instrAddr_to_feedback[9:0]] < 2'b11) begin
                prediction_table[instrAddr_to_feedback[9:0]] <= prediction_table[instrAddr_to_feedback[9:0]] + 1;
            end
        end else begin
            if (prediction_table[instrAddr_to_feedback[9:0]] > 2'b00) begin
                prediction_table[instrAddr_to_feedback[9:0]] <= prediction_table[instrAddr_to_feedback[9:0]] - 1;
            end
        end
    end
end

endmodule
