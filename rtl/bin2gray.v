`timescale 1ns/1ps
//二进制转换为格雷码

module bin2gray #(
    parameter PTR_WIDTH = 4
    )(
    input wire [PTR_WIDTH-1:0] bin,
    output wire [PTR_WIDTH-1:0] gray
    );
    assign gray = bin ^ (bin >> 1);
endmodule
