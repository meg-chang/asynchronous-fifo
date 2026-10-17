`timescale 1ns/1ps
//二级同步器

module sync_two_stage #(parameter WIDTH = 5)(
    input wire             rclk, rrst_n,
    input wire [WIDTH-1:0] din,
    output wire [WIDTH-1:0] dout
);

    reg [WIDTH-1:0] sync_ff1, sync_ff2;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            sync_ff1 <= {WIDTH{1'b0}};
            sync_ff2 <= {WIDTH{1'b0}};
        end else begin
            sync_ff1 <= din;
            sync_ff2 <= sync_ff1;
        end
    end

    assign dout = sync_ff2;
endmodule
