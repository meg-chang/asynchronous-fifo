# ============================================================
#  异步 FIFO 仿真 Makefile
#  工具链：iverilog（编译）+ vvp（运行）+ gtkwave（看波形）
#  用法：
#    make            # 编译并运行 tb_async_fifo，生成 tb_async_fifo.vcd
#    make wave       # 仿真完用 gtkwave 打开波形
#    make lint       # 只做语法/可综合性检查，不生成仿真文件
#    make clean      # 清理所有生成产物
#    make TOP=tb_bin2gray   # 切换去编译其他测试平台（可选）
# ============================================================

# 1. 顶层测试模块名：决定编译哪一个 testbench，默认就是异步 FIFO 测试
TOP     ?= tb_async_fifo

# 2. RTL（设计源码）与 TB（测试平台）目录，相对本 Makefile 所在的 sim/ 而言
RTL_DIR := ../rtl
TB_DIR  := ../tb

# 3. 自动收集 rtl/ 下所有 .v 文件，作为设计的源文件（无需逐个手写）
RTL_SRC := $(wildcard $(RTL_DIR)/*.v)

# 4. iverilog 编译选项：-Wall 打开全部告警，-g2005 指定 Verilog-2005 语法标准
VFLAGS  := -Wall -g2005

# 5. 由 TOP 推导出的两个产物文件名：仿真可执行文件 + 波形文件
SIM_OUT := $(TOP).sim
VCD     := $(TOP).vcd

# 6. 编译/运行过程中如果出错，自动删除半成品目标，避免留下损坏的 .sim 文件
.DELETE_ON_ERROR:

# 7. 声明伪目标：这些是“动作”而非真实文件，防止目录下恰好有同名文件时 make 误判
.PHONY: all wave lint clean

# 8. 默认目标（敲 make 不带参数时执行）：最终目标是拿到 VCD 波形文件
all: $(VCD)

# 9. VCD 规则：依赖仿真可执行文件；先跑仿真，再把生成的 wave.vcd 改名为 $(VCD)
$(VCD): $(SIM_OUT)
	vvp $(SIM_OUT)
	@mv -f wave.vcd $@

# 10. 仿真可执行文件规则：依赖测试平台源文件 + 全部 RTL 源文件
#     $^ 代表上面所有依赖，$@ 代表目标名 $(SIM_OUT)
$(SIM_OUT): $(TB_DIR)/$(TOP).v $(RTL_SRC)
	iverilog $(VFLAGS) -o $@ $^

# 11. wave 目标：VCD 生成后用 gtkwave 图形化查看（& 后台挂起，不阻塞终端）
wave: $(VCD)
	gtkwave $(VCD) &

# 12. lint 目标：仅做语法/可综合性检查（-tnull 表示不生成可执行文件）
lint:
	iverilog $(VFLAGS) -tnull $(TB_DIR)/$(TOP).v $(RTL_SRC)

# 13. clean 目标：删除本次生成的所有产物（*.sim、*.vcd、sim.out）
clean:
	rm -f *.sim *.vcd sim.out
