`timescale 1ns/1ps
//格雷码转二进制

module gray2bin #(parameter PTR_WIDTH = 4)(
    input wire [PTR_WIDTH-1:0] gray,
    output wire [PTR_WIDTH-1:0] bin
);
    genvar i;

    generate
        for (i = 0; i < PTR_WIDTH; i = i + 1) begin : conv
            assign bin[i] = ^gray[PTR_WIDTH-1:i];  //归约异或
        end
    endgenerate
endmodule
