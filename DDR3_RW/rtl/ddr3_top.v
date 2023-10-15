//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           ddr3_top
// Last modified Date:  2020/05/04 9:19:08
// Last Version:        V1.0
// Descriptions:        ddr3控制器顶层模块
//                      
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2019/05/04 9:19:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module ddr3_top(
    input              refclk_in        ,//外部参考时钟输入
    input              rst_n            ,//外部复位输入

    input   [27:0]     app_addr_rd_min  ,//读ddr3的起始地址
    input   [27:0]     app_addr_rd_max  ,//读ddr3的结束地址
    input   [7:0]      rd_bust_len      ,//从ddr3中读数据时的突发长度
    input   [27:0]     app_addr_wr_min  ,//读ddr3的起始地址
    input   [27:0]     app_addr_wr_max  ,//读ddr3的结束地址
    input   [7:0]      wr_bust_len      ,//从ddr3中读数据时的突发长度
    //用户     
    input              wr_clk           ,//wfifo写时钟
    input              rd_clk           ,//rfifo读时钟
    input              datain_valid     ,//数据有效使能信号
    input   [15:0]     datain           ,//有效数据
    input              rdata_req        ,//请求数据输入
    output  [15:0]     dataout          ,//rfifo输出数据

    output             ddr_init_done    ,//DDR初始化完成
    input              pad_loop_in      ,
    input              pad_loop_in_h    ,
    output             pad_rstn_ch0     ,
    output             pad_ddr_clk_w    ,
    output             pad_ddr_clkn_w   ,
    output             pad_csn_ch0      ,
    output [15:0]      pad_addr_ch0     ,
    inout  [16-1:0]    pad_dq_ch0       ,
    inout  [16/8-1:0]  pad_dqs_ch0      ,
    inout  [16/8-1:0]  pad_dqsn_ch0     ,
    output [16/8-1:0]  pad_dm_rdqs_ch0  ,
    output             pad_cke_ch0      ,
    output             pad_odt_ch0      ,
    output             pad_rasn_ch0     ,
    output             pad_casn_ch0     ,
    output             pad_wen_ch0      ,
    output [2:0]       pad_ba_ch0       ,
    output             pad_loop_out     ,
    output             pad_loop_out_h
   );

//wire define
    wire  [32-1:0]    axi_awaddr     ;
    wire  [7:0]       axi_awlen      ;
    wire  [2:0]       axi_awsize     ;
    wire  [1:0]       axi_awburst    ;
    wire              axi_awlock     ;
    wire              axi_awready    ;
    wire              axi_awvalid    ;
    wire              axi_awurgent   ;
    wire              axi_awpoison   ;
    wire  [128-1:0]   axi_wdata      ;
    wire  [16-1:0]    axi_wstrb      ;
    wire              axi_wvalid     ;
    wire              axi_wready     ;
    wire              axi_wlast      ;
    wire              axi_bready     ;
    wire  [32-1:0]    axi_araddr     ;
    wire  [7:0]       axi_arlen      ;
    wire  [2:0]       axi_arsize     ;
    wire  [1:0]       axi_arburst    ;
    wire              axi_arlock     ;
    wire              axi_arpoison   ;
    wire              axi_arurgent   ;
    wire              axi_arready    ;
    wire              axi_arvalid    ;
    wire  [128-1:0]   axi_rdata      ;
    wire              axi_rlast      ;
    wire              axi_rvalid     ;
    wire              axi_rready     ;
    wire              axi_clk        ;
    wire [10:0]       wfifo_rcount   ;//rfifo剩余数据计数
    wire [10:0]       rfifo_wcount   ;//wfifo写进数据计数
    wire              wrfifo_en_ctrl ;//写FIFO数据读使能控制位
    wire              wfifo_rden     ;//写FIFO数据读使能
    wire              pre_wfifo_rden ;//写FIFO数据预读使能

//*****************************************************
//**                    main code
//*****************************************************
//因为预读了一个数据所以读使能wfifo_rden要少一个周期通过wrfifo_en_ctrl控制
assign wfifo_rden = axi_wvalid && axi_wready && (~wrfifo_en_ctrl) ;
assign pre_wfifo_rden = axi_awvalid && axi_awready ;

//ddr3读写控制器模块
rw_ctrl_128bit  u_rw_ctrl_128bit
(
 .clk                 (axi_clk          ),
 .rst_n               (rst_n            ),
 .ddr_init_done       (ddr_init_done    ),
 .axi_awaddr          (axi_awaddr       ),
 .axi_awlen           (axi_awlen        ),
 .axi_awsize          (axi_awsize       ),
 .axi_awburst         (axi_awburst      ),
 .axi_awlock          (axi_awlock       ),
 .axi_awready         (axi_awready      ),
 .axi_awvalid         (axi_awvalid      ),
 .axi_awurgent        (axi_awurgent     ),
 .axi_awpoison        (axi_awpoison     ),
 .axi_wstrb           (axi_wstrb        ),
 .axi_wvalid          (axi_wvalid       ),
 .axi_wready          (axi_wready       ),
 .axi_wlast           (axi_wlast        ),
 .axi_bready          (axi_bready       ),
 .wrfifo_en_ctrl      (wrfifo_en_ctrl   ),
 .axi_araddr          (axi_araddr       ),
 .axi_arlen           (axi_arlen        ),
 .axi_arsize          (axi_arsize       ),
 .axi_arburst         (axi_arburst      ),
 .axi_arlock          (axi_arlock       ),
 .axi_arpoison        (axi_arpoison     ),
 .axi_arurgent        (axi_arurgent     ),
 .axi_arready         (axi_arready      ),
 .axi_arvalid         (axi_arvalid      ),
 .axi_rlast           (axi_rlast        ),
 .axi_rvalid          (axi_rvalid       ),
 .axi_rready          (axi_rready       ),
 .wfifo_rcount        (wfifo_rcount     ),
 .rfifo_wcount        (rfifo_wcount     ),
 .app_addr_rd_min     (app_addr_rd_min  ),
 .app_addr_rd_max     (app_addr_rd_max  ),
 .rd_bust_len         (rd_bust_len      ),
 .app_addr_wr_min     (app_addr_wr_min  ),
 .app_addr_wr_max     (app_addr_wr_max  ),
 .wr_bust_len         (wr_bust_len      )
 );

 //ddr3IP核模块
 ddr3_ip u_ddr3_ip (
  .pll_refclk_in    (refclk_in      ), // input
  .top_rst_n        (rst_n          ), // input
  .ddrc_rst         (0              ), // input
  .csysreq_ddrc     (1'b1           ), // input
  .csysack_ddrc     (               ), // output
  .cactive_ddrc     (               ), // output
  .pll_lock         (               ), // output
  .pll_aclk_0       (axi_clk        ), // output
  .pll_aclk_1       (               ), // output
  .pll_aclk_2       (               ), // output
  .ddrphy_rst_done  (               ), // output
  .ddrc_init_done   (ddr_init_done  ), // output
  .pad_loop_in      (pad_loop_in    ), // input
  .pad_loop_in_h    (pad_loop_in_h  ), // input
  .pad_rstn_ch0     (pad_rstn_ch0   ), // output
  .pad_ddr_clk_w    (pad_ddr_clk_w  ), // output
  .pad_ddr_clkn_w   (pad_ddr_clkn_w ), // output
  .pad_csn_ch0      (pad_csn_ch0    ), // output
  .pad_addr_ch0     (pad_addr_ch0   ), // output [15:0]
  .pad_dq_ch0       (pad_dq_ch0     ), // inout [15:0]
  .pad_dqs_ch0      (pad_dqs_ch0    ), // inout [1:0]
  .pad_dqsn_ch0     (pad_dqsn_ch0   ), // inout [1:0]
  .pad_dm_rdqs_ch0  (pad_dm_rdqs_ch0), // output [1:0]
  .pad_cke_ch0      (pad_cke_ch0    ), // output
  .pad_odt_ch0      (pad_odt_ch0    ), // output
  .pad_rasn_ch0     (pad_rasn_ch0   ), // output
  .pad_casn_ch0     (pad_casn_ch0   ), // output
  .pad_wen_ch0      (pad_wen_ch0    ), // output
  .pad_ba_ch0       (pad_ba_ch0     ), // output [2:0]
  .pad_loop_out     (pad_loop_out   ), // output
  .pad_loop_out_h   (pad_loop_out_h ), // output 
  .areset_0         (0              ), // input
  .aclk_0           (axi_clk        ), // input
  .awid_0           (0              ), // input [7:0]
  .awaddr_0         (axi_awaddr     ), // input [31:0]
  .awlen_0          (axi_awlen      ), // input [7:0]
  .awsize_0         (axi_awsize     ), // input [2:0]
  .awburst_0        (axi_awburst    ), // input [1:0]
  .awlock_0         (axi_awlock     ), // input
  .awvalid_0        (axi_awvalid    ), // input
  .awready_0        (axi_awready    ), // output
  .awurgent_0       (axi_awurgent   ), // input
  .awpoison_0       (axi_awpoison   ), // input
  .wdata_0          (axi_wdata      ), // input [127:0]
  .wstrb_0          (axi_wstrb      ), // input [15:0]
  .wlast_0          (axi_wlast      ), // input
  .wvalid_0         (axi_wvalid     ), // input
  .wready_0         (axi_wready     ), // output
  .bid_0            (               ), // output [7:0]
  .bresp_0          (               ), // output [1:0]
  .bvalid_0         (               ), // output
  .bready_0         (axi_bready     ), // input 
  .arid_0           (0              ), // input [7:0]
  .araddr_0         (axi_araddr     ), // input [31:0]
  .arlen_0          (axi_arlen      ), // input [7:0]
  .arsize_0         (axi_arsize     ), // input [2:0]
  .arburst_0        (axi_arburst    ), // input [1:0]
  .arlock_0         (axi_arlock     ), // input
  .arvalid_0        (axi_arvalid    ), // input
  .arready_0        (axi_arready    ), // output
  .arpoison_0       (axi_arpoison   ), // input 
  .rid_0            (               ), // output [7:0]
  .rdata_0          (axi_rdata      ), // output [127:0]
  .rresp_0          (               ), // output [1:0]
  .rlast_0          (axi_rlast      ), // output
  .rvalid_0         (axi_rvalid     ), // output
  .rready_0         (axi_rready     ), // input
  .arurgent_0       (axi_arurgent   ), // input
  .csysreq_0        (1'b1           ), // input
  .csysack_0        (               ), // output
  .cactive_0        (               )  // output
);

//ddr3控制器fifo控制模块
 ddr3_fifo_ctrl u_ddr3_fifo_ctrl (
    .rst_n               (rst_n && ddr_init_done    ) ,  //复位
    //输入源接口
    .wr_clk              (wr_clk                    ) ,  //写时钟
    .rd_clk              (rd_clk                    ) ,  //读时钟
    .clk_100             (axi_clk                   ) ,  //用户时钟 
    .datain_valid        (datain_valid              ) ,  //数据有效使能信号
    .datain              (datain                    ) ,  //有效数据 
    .rfifo_din           (axi_rdata                 ) ,  //用户读数据 
    .rdata_req           (rdata_req                 ) ,  //请求像素点颜色数据输入
    .rfifo_wren          (axi_rvalid                ) ,  //ddr3读出数据的有效使能
    .wfifo_rden          (wfifo_rden||pre_wfifo_rden) ,  //ddr3 写使能
    //用户接口
    .wfifo_rcount        (wfifo_rcount              ) , //rfifo剩余数据计数
    .rfifo_wcount        (rfifo_wcount              ) , //wfifo写进数据计数
    .wfifo_dout          (axi_wdata                 ) , //用户写数据
    .pic_data            (dataout                   )   //rfifo输出数据
    );

endmodule