//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           rw_ctrl_128bit
// Last modified Date:  2020/05/04 9:19:08
// Last Version:        V1.0
// Descriptions:        ddr3读写控制器模块
//                      
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2019/05/04 9:19:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

`timescale 1ps/1ps

module rw_ctrl_128bit 
 (
   input                   clk             , //时钟
   input                   rst_n           , //复位
   input                   ddr_init_done   , //DDR初始化完成
   output      [32-1:0 ]   axi_awaddr      , //写地址
   output reg  [7:0    ]   axi_awlen       , //写突发长度
   output wire [2:0    ]   axi_awsize      , //写突发大小
   output wire [1:0    ]   axi_awburst     , //写突发类型
   output                  axi_awlock      , //写锁定类型
   input                   axi_awready     , //写地址准备信号
   output reg              axi_awvalid     , //写地址有效信号
   output                  axi_awurgent    , //写紧急信号,1:Write address指令优先执行
   output                  axi_awpoison    , //写抑制信号,1:Write address指令无效
   output wire [15:0   ]   axi_wstrb       , //写选通
   output reg              axi_wvalid      , //写数据有效信号
   input                   axi_wready      , //写数据准备信号
   output reg              axi_wlast       , //最后一次写信号
   output wire             axi_bready      , //写回应准备信号
   output reg              wrfifo_en_ctrl  , //写FIFO数据读使能控制位
   output      [32-1:0 ]   axi_araddr      , //读地址
   output reg  [7:0    ]   axi_arlen       , //读突发长度
   output wire [2:0    ]   axi_arsize      , //读突发大小
   output wire [1:0    ]   axi_arburst     , //读突发类型
   output wire             axi_arlock      , //读锁定类型
   output wire             axi_arpoison    , //读抑制信号,1:Read address指令无效
   output wire             axi_arurgent    , //读紧急信号,1:Read address指令优先执行
   input                   axi_arready     , //读地址准备信号
   output reg              axi_arvalid     , //读地址有效信号
   input                   axi_rlast       , //最后一次读信号
   input                   axi_rvalid      , //读数据有效信号
   output wire             axi_rready      , //读数据准备信号
   input       [10:0   ]   wfifo_rcount    , //写端口FIFO中的数据量
   input       [10:0   ]   rfifo_wcount    , //读端口FIFO中的数据量
   input       [27:0   ]   app_addr_rd_min , //读DDR3的起始地址
   input       [27:0   ]   app_addr_rd_max , //读DDR3的结束地址
   input       [7:0    ]   rd_bust_len     , //从DDR3中读数据时的突发长度
   input       [27:0   ]   app_addr_wr_min , //写DDR3的起始地址
   input       [27:0   ]   app_addr_wr_max , //写DDR3的结束地址
   input       [7:0    ]   wr_bust_len       //从DDR3中写数据时的突发长度
);

//localparam define 
localparam IDLE        = 4'd1 ; //空闲状态
localparam DDR3_DONE   = 4'd2 ; //DDR3初始化完成状态
localparam WRITE_ADDR  = 4'd3 ; //写地址
localparam WRITE_DATA  = 4'd4 ; //写数据
localparam READ_ADDR   = 4'd5 ; //读地址
localparam READ_DATA   = 4'd6 ; //读数据

//reg define
reg        init_start   ; //初始化完成信号
reg [31:0] init_addr    ; //突发长度计数器
reg [31:0] axi_araddr_n ; //读地址计数
reg [31:0] axi_awaddr_n ; //写地址计数
reg [3:0 ] state_cnt    ; //状态计数器
reg [9:0 ] lenth_cnt    ; //突发写次数计数器

//wire define
wire [9:0 ] lenth_cnt_max; //最大突发次数

//*****************************************************
//**                    main code
//*****************************************************

assign  axi_awlock   = 1'b0      ;
assign  axi_awurgent = 1'b0      ;
assign  axi_awpoison = 1'b0      ;
assign  axi_bready   = 1'b1      ;
assign  axi_wstrb    = {16{1'b1}};
assign  axi_awsize   = 3'b100    ;
assign  axi_awburst  = 2'd1      ;
assign  axi_arlock   = 1'b0      ;
assign  axi_arurgent = 1'b0      ;
assign  axi_arpoison = 1'b0      ;
assign  axi_arsize   = 3'b100    ;
assign  axi_arburst  = 2'd1      ;
assign  axi_rready   = 1'b1      ;

//计算最大突发次数
assign  lenth_cnt_max = app_addr_wr_max / (wr_bust_len * 4'd8);

//读写地址，16bit对应一个地址转换为一个字节对应一个地址
assign  axi_araddr = {6'b0,axi_araddr_n[24:0],1'b0};
assign  axi_awaddr = {6'b0,axi_awaddr_n[24:0],1'b0};

//稳定ddr3初始化信号
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        init_start <= 1'b0;
    else if (ddr_init_done)
        init_start <= ddr_init_done;
    else
        init_start <= init_start;
end

//写地址模块
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        axi_awaddr_n <= app_addr_wr_min;
        axi_awlen    <= 8'b0;
        axi_awvalid  <= 1'b0;
    end
    //DDR3初始化完成 
    else if (init_start) begin
        axi_awlen <= wr_bust_len - 1'b1;
        //当写地址计数小于最后一次写地址起始位时
        if (axi_awaddr_n < app_addr_wr_max - wr_bust_len * 5'd8) begin
            //写地址有效信号和写地址准备信号都为1时
            if (axi_awvalid && axi_awready) begin
                axi_awvalid  <= 1'b0;         //拉低写地址有效信号
                //写地址计数加一个突发长度所需的地址
                axi_awaddr_n <= axi_awaddr_n + wr_bust_len * 5'd8;//wr_bust_len*128/16
            end
            //状态机处于写地址状态且写地址准备信号为1时
            else if (state_cnt == WRITE_ADDR && axi_awready)
                axi_awvalid  <= 1'b1;    //拉高写地址有效信号
        end
        //当写地址计数等于最后一次写地址起始位时
        else if (axi_awaddr_n == app_addr_wr_max - wr_bust_len * 5'd8) begin
            if (axi_awvalid && axi_awready) begin
                axi_awvalid  <= 1'b0;
                axi_awaddr_n <= app_addr_wr_min; //写地址计数清零（回到写起始地址）
            end
            else if (state_cnt == WRITE_ADDR && axi_awready)
                axi_awvalid  <= 1'b1;
        end
        else
            axi_awvalid <= 1'b0;
    end 
    else begin
            axi_awaddr_n <= axi_awaddr_n;
            axi_awlen    <= 8'b0;
            axi_awvalid  <= 1'b0;
    end
end

//写数据模块
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        axi_wvalid <= 1'b0  ;
        axi_wlast  <= 1'b0  ;
        init_addr  <= 32'd0 ;
        lenth_cnt  <= 8'd0  ;
        wrfifo_en_ctrl <= 1'b0;
    end
    else begin
        //DDR3初始化完成
        if (init_start) begin
            //当突发写次数计数器小于最大突发次数时
            if (lenth_cnt < lenth_cnt_max) begin
                if (axi_wvalid && axi_wready && init_addr < wr_bust_len - 2'd2) begin
                    init_addr      <= init_addr + 1'b1;
                    wrfifo_en_ctrl <= 1'b0;
                end 
                //因为写DDR时已经提前让FIFO准备好第一个数据，所以使能在写结尾要减少一个使能周期
                else if (axi_wvalid && axi_wready && init_addr == wr_bust_len - 2'd2) begin
                    axi_wlast      <= 1'b1;
                    wrfifo_en_ctrl <= 1'b1;              //提前一个时钟周期拉高
                    init_addr      <= init_addr + 1'b1;
                end
                //当突发长度计数器等于一次突发长度时
                else if (axi_wvalid && axi_wready && init_addr == wr_bust_len - 2'd1) begin
                    axi_wvalid     <= 1'b0;
                    axi_wlast      <= 1'b0;
                    wrfifo_en_ctrl <= 1'b0;
                    lenth_cnt      <= lenth_cnt + 1'b1;  //突发写次数计数器加1
                    init_addr      <= 32'd0;
                end         
                else if (state_cnt == WRITE_DATA && axi_wready)
                    axi_wvalid     <= 1'b1;
                else 
                    lenth_cnt      <= lenth_cnt;
            end
            else begin
                axi_wvalid <= 1'b0     ;
                axi_wlast  <= 1'b0     ;
                init_addr  <= init_addr;
                lenth_cnt  <= 8'd0     ;
            end
        end
        else begin
            axi_wvalid <= 1'b0 ;
            axi_wlast  <= 1'b0 ;
            init_addr  <= 32'd0;
            lenth_cnt  <= 8'd0 ;
        end
    end
end 

//读地址模块
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      axi_araddr_n <= app_addr_rd_min;
      axi_arlen    <= 8'b0;
      axi_arvalid  <= 1'b0;
    end
    //DDR3初始化完成
    else if(init_start) begin
        axi_arlen <= rd_bust_len - 1'b1;
        //当读地址计数小于最后一次读地址起始位时
        if (axi_araddr_n < app_addr_rd_max  - rd_bust_len * 5'd8) begin
            if (axi_arready && axi_arvalid) begin
                axi_arvalid  <= 1'b0;
                axi_araddr_n <= axi_araddr_n + rd_bust_len * 5'd8;
            end
            else if(axi_arready && state_cnt == READ_ADDR)
                axi_arvalid  <= 1'b1;
        end 
        //当读地址计数等于最后一次读地址起始位时
        else if (axi_araddr_n == app_addr_rd_max - rd_bust_len * 5'd8) begin
            if (axi_arready && axi_arvalid) begin
                axi_arvalid  <= 1'b0;
                axi_araddr_n <= app_addr_rd_min;
            end
            else if(axi_arready && state_cnt==READ_ADDR)
                axi_arvalid  <= 1'b1;
        end             
        else
            axi_arvalid <= 1'b0;
    end
    else begin  
            axi_araddr_n   <= app_addr_rd_min;
            axi_arlen      <= 8'b0;
            axi_arvalid    <= 1'b0;
    end     
end 

//DDR3读写逻辑实现模块
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin 
        state_cnt <= IDLE;
    end
    else begin
        case(state_cnt)
            IDLE:begin
                if(init_start)
                    state_cnt <= DDR3_DONE ;
                else
                    state_cnt <= IDLE;
            end
            DDR3_DONE:begin
                if(wfifo_rcount >= wr_bust_len)
                    state_cnt <= WRITE_ADDR;         //跳到写地址操作
                else if(rfifo_wcount < rd_bust_len)
                    state_cnt <= READ_ADDR;          //跳到读地址操作
                else 
                    state_cnt <= state_cnt; 
            end             
            WRITE_ADDR:begin
                if(axi_awvalid && axi_awready)
                    state_cnt <= WRITE_DATA;        //跳到写数据操作 
                else
                    state_cnt <= state_cnt;         //条件不满足，保持当前值
            end
            WRITE_DATA:begin 
                if(axi_wvalid && axi_wready && init_addr == wr_bust_len - 1)
                    state_cnt <= DDR3_DONE;        //写到设定的长度跳到等待状态
                else
                    state_cnt <= state_cnt;        //写条件不满足，保持当前值
            end         
            READ_ADDR:begin
                if(axi_arvalid && axi_arready)
                    state_cnt <= READ_DATA;        //跳到写数据操作
                else
                    state_cnt <= state_cnt;        //条件不满足，保持当前值
            end
            READ_DATA:begin
                if(axi_rlast)                      //读到设定的地址长度
                    state_cnt <= DDR3_DONE;        //则跳到空闲状态
                else
                    state_cnt <= state_cnt;        //否则保持当前值
            end
            default:begin
                state_cnt <= IDLE;
            end
        endcase
    end
end

endmodule