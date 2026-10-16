`timescale 1ns/1ps

//异步 FIFO测试平台
//写时钟周期 10ns，读时钟周期 14ns -- 故意不同频、不同相

module tb_async_fifo;

    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4;
    localparam DEPTH     = 1 << ADDR_WIDTH;

    reg                  wclk, wrst_n, winc;
    reg  [DATA_WIDTH-1:0] wdata;
    wire                 wfull;

    reg                  rclk, rrst_n, rinc;
    wire [DATA_WIDTH-1:0] rtada;
    wire                 rempty;

    integer i;
    integer errors;
    reg [DATA_WIDTH-1:0] got;

    async_fifo #(.DATA_WIDTH(DATA_WIDTH),.ADDR_WIDTH(ADDR_WIDTH)) dut (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .winc(winc),
        .wdata(wdata),
        .wfull(wfull),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .rinc(rinc),
        .rdata(rdata),
        .rempty(rempty)
    );

    always #5 wclk = ~wclk;
    always #7 rclk = ~rclk; //单独定义写时钟和读时钟

    //写步骤：在写时钟上升沿的时候，把数据推入mem，指针同时加一

    task wpush;
        input [DATA_WIDTH-1:0] d;
        begin
            wdata = d;
            winc  = 1'b1;
            @(posedge wclk);
            #1 winc = 1'b0;
        end
    endtask

    //写步骤：rdata是组合逻辑输出，始终反映“当前读指针指向的格子”
    //所以顺序必须先取数，再推进指针
    //反过来写的话会整体错位：第一个读不到，最后一个读到x

    task rpop;
        output [DATA_WIDTH-1:0] d;
        begin
            #1;
            d    = rdata;
            rinc = 1'b1;
            @(posedge rclk);
            rinc = 1'b0;
        end
    endtask

    task expect_data;
        input [DATA_WIDTH-1:0] exp;
        begin
            if (got !== exp) begin
                $display("FAIL t=%0t got=%0h exp=%0h", $time, got, exp);
                errors = errors + 1;
            end else begin
                $display("PASS t=%0t data=%0h", $time, got);
            end
        end
    endtask

    task expect_bit;
        input act;
        input exp;
        begin
            if (act !== exp)begin
                $display("FAIL t=%0t act=%0h exp=%0h", $time, act, exp);
                errors = errors + 1;
            end else begin
                $display("PASS t=%0t act=%0h", $time, act);
            end
        end
    endtask

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_async_fifo);

        errors = 0;
        wclk   = 1'b0;
        rclk   = 1'b0;
        wrst_n = 1'b0;
        rrst_n = 1'b0;
        winc   = 1'b0;
        rinc   = 1'b0;
        wdata  = {DATA_WIDTH{1'b0}};

        repeat (4) @(posedge wclk);
        repeat (4) @(posedge rclk);
        wrst_n = 1'b1;
        rrst_n = 1'b1;
        repeat (3) @(posedge wclk);

        //场景1：复位之后应该是空的
        $display("--- case 1:empty flag after reset ---");
        expect_bit(rempty, 1'b1);

        //场景2：连续写满整个FIFO
        $display("--- case 2:write until full ---");
        for (i = 0; i < DEPTH; i = i + 1) begin
            wpush(i[DATA_WIDTH-1:0]);
        end
        #1;
        expect_bit(wfull, 1'b1);

        //场景3：写满之后再写，应该被 wfull 挡掉
        $display("--- case 3:overflow write must be blocked ---");
        wpush(8'hAA);
        #1;
        expect_bit(wfull, 1'b1);

        //场景4：等同步器把写时针送到读时钟域，再逐个读出比对
        $display("--- case 4:read back and compare ---");
        repeat (5) @(posedge rclk);
        for (i = 0; i < DEPTH; i = i + 1) begin
            rpop(got);
            expect_data(i[DATA_WIDTH-1:0]);
        end

        //场景5：数据读完后应该回到空
        $display("--- case 5:empty flag after reading all ---");
        repeat (5) @(posedge rclk);
        expect_bit(rempty, 1'b1);

        //场景6：小批量突发读写
        $display("--- case 6:small burst ---");
        wpush(8'hF1);
        wpush(8'hF2);
        wpush(8'hF3);
        repeat (5) @(posedge rclk);
        rpop(got); expect_data(8'hF1);
        rpop(got); expect_data(8'hF2);

        #1;
        expect_bit(wfull, 1'b0);
        expect_bit(rempty, 1'b0);

        if (errors == 0) $display("=== SAYNC FIFO ALL CASES PASS ===");
        `else            $display("=== %0d FAILURES ===", errors);
        $finish; 
    end

endmodule