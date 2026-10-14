//异步 FIFO主体
//结构：双口 RAM + 二进制指针 ＋ 格雷码编码 + 二级同步器 + 空满判断

module async_fifo #(
    parameter DATA_DEPTH = 8,
    parameter ADDR_WIDTH = 4         //FIFO 深度 = 2^ADDR_WIDTH
) (
    //写时钟域
    input wire                  wclk,
    input wire                  wrst_n,
    input wire                  winc,   //写使能
    input wire [DATA_DEPTH-1:0] wdata,
    output wire                 wfull,  //写满标志
    //读时钟域
    input wire                  rclk,
    input wire                  rrst_n,
    input wire                  rinc,   //读使能
    output wire [DATA_DEPTH-1:0] rdata,
    output wire                 rempty //读空标志
);

    localparam DEPTH     = 1 << ADDR_WIDTH;     //16
    localparam PTR_WIDTH = ADDR_WIDTH + 1;      //指针比地址多一位，用来区分空和满

    //1.读写使能：空满标志会挡掉非法操作，这一层是整个FIFO的保险丝
    wire wen = winc & ~wfull;
    wire ren = rinc & ~rempty;

    //2.指针计数器
    //  写侧在 wclk 域自增，读侧在 rclk 域自增，互不干涉
    //  多出的最高位（bit4）是“圈数标记”，RAM 地址只取低 4 位
    reg [PTR_WIDTH-1:0] wbin;
    reg [PTR_WIDTH-1:0] rbin;

    wire [PTR_WIDTH-1:0] wbin_nxt = wbin + wen;
    wire [PTR_WIDTH-1:0] rbin_nxt = rbin + ren;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) wbin <= {PTR_WIDTH{1'b0}};
        else         wbin <= wbin_nxt;
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) rbin <= {PTR_WIDTH{1'b0}};
        else         rbin <= rbin_nxt;
    end

    //RAM 地址 = 指针低 ADDR_WIDTH 位
    wire [ADDR_WIDTH-1:0] waddr = wbin[ADDR_WIDTH-1:0];
    wire [ADDR_WIDTH-1:0] raddr = rbin[ADDR_WIDTH-1:0];

    //3.存储体
    //这里可以不复位，真实芯片里是 SEAM/BRAM，因为给存储阵列加复位会吃掉大量布线资源，工程上不做
    reg [DATA_DEPTH-1:0] mem [0:DEPTH-1];

    always @(posedge wclk) begin
        if (wen) mem[waddr] <= wdata;
    end

    assign rdate = mem[raddr];

    //4.二进制指针 -> 格雷码
    //  复用已有的模块，跨时钟域前必须转格雷码
    //  不然的话多位同时翻转会被对面采到乱码指针
    wire [PTR_WIDTH-1:0] wgray;
    wire [PTR_WIDTH-1:0] rgray;

    // output declaration of module bin2gray
    wire [PTR_WIDTH-1:0] gray;
    
    bin2gray #(.PTR_WIDTH(PTR_WIDTH))u_b2gw(
        .bin  	(wbin   ),
        .gray 	(wgray  )
    );
    
    bin2gray #(.PTR_WIDTH(PTR_WIDTH))u_b2gr(
        .bin  	(rbin   ),
        .gray 	(rgray  )
    );

    //5.跨时钟域：两级同步器
    //  写指针送到读时钟域判空，把读指针送到写时钟域判满
    //  同步会带来 2 拍延迟，所以空满标志是“保守”的
    //  ——可能会提前报空/满，但不会丢数据
    reg [PTR_WIDTH-1:0] wbin_sync;
    reg [PTR_WIDTH-1:0] rbin_sync;
    

endmodule