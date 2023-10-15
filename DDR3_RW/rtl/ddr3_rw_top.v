//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           ddr3_rw_top
// Last modified Date:  2020/05/04 9:19:08
// Last Version:        V1.0
// Descriptions:        ddr3读写测试顶层模块
//                      
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2019/05/04 9:19:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module ddr3_rw_top(
    input             sys_clk          , //系统时钟50M
    input             sys_rst_n        , //系统复位
    output            led_error        , //读写错误led灯
    output            led_ddr_init_done, //ddr3初始化完成led灯

    //DDR3接口
    input             pad_loop_in      , //低位温度补偿输入
    input             pad_loop_in_h    , //高位温度补偿输入
    output            pad_rstn_ch0     , //Memory复位
    output            pad_ddr_clk_w    , //Memory差分时钟正端
    output            pad_ddr_clkn_w   , //Memory差分时钟负端
    output            pad_csn_ch0      , //Memory片选
    output [15:0]     pad_addr_ch0     , //Memory地址总线
    inout  [16-1:0]   pad_dq_ch0       , //数据总线
    inout  [16/8-1:0] pad_dqs_ch0      , //数据时钟正端
    inout  [16/8-1:0] pad_dqsn_ch0     , //数据时钟负端
    output [16/8-1:0] pad_dm_rdqs_ch0  , //数据Mask
    output            pad_cke_ch0      , //Memory差分时钟使能
    output            pad_odt_ch0      , //On Die Termination
    output            pad_rasn_ch0     , //行地址strobe
    output            pad_casn_ch0     , //列地址strobe
    output            pad_wen_ch0      , //写使能
    output [2:0]      pad_ba_ch0       , //Bank地址总线
    output            pad_loop_out     , //低位温度补偿输出
    output            pad_loop_out_h     //高位温度补偿输出    
   );

//parameter define 
parameter  APP_ADDR_MIN = 28'd0  ;  //ddr3读写起始地址，以一个16bit的数据为一个单位
//APP_ADDR_MAX = APP_ADDR_MIN + BURST_LENGTH * 8 * n（n表示突发次数）
parameter  APP_ADDR_MAX = 28'd5120 ;  //ddr3读写结束地址，以一个16bit的数据为一个单位
parameter  BURST_LENGTH = 8'd64    ;  //ddr3读写突发长度，64个128bit的数据
parameter  DATA_MAX = APP_ADDR_MAX - APP_ADDR_MIN;  //读写ddr3的最大数据量

//wire define
wire  [15:0]  wr_data        ;  //DDR3控制器模块写数据
wire  [15:0]  rd_data        ;  //DDR3控制器模块读数据
wire          wr_en          ;  //DDR3控制器模块写使能
wire          rd_en          ;  //DDR3控制器模块读使能
wire          ddr_init_done  ;  //ddr3初始化完成信号
wire          error_flag     ;  //ddr3读写错误标志

////*****************************************************
////**                    main code
////***************************************************** 
//ddr3控制器顶层模块
ddr3_top u_ddr3_top(
 .refclk_in             (sys_clk         ),
 .rst_n                 (sys_rst_n       ),
 .app_addr_rd_min       (APP_ADDR_MIN    ),
 .app_addr_rd_max       (APP_ADDR_MAX    ),
 .rd_bust_len           (BURST_LENGTH    ),
 .app_addr_wr_min       (APP_ADDR_MIN    ),
 .app_addr_wr_max       (APP_ADDR_MAX    ),
 .wr_bust_len           (BURST_LENGTH    ),
 .wr_clk                (sys_clk         ),
 .rd_clk                (sys_clk         ),
 .datain_valid          (wr_en           ),
 .datain                (wr_data         ),
 .rdata_req             (rd_en           ),
 .dataout               (rd_data         ),
 .ddr_init_done         (ddr_init_done   ),
 //DDR3接口
 .pad_loop_in           (pad_loop_in     ),
 .pad_loop_in_h         (pad_loop_in_h   ),
 .pad_rstn_ch0          (pad_rstn_ch0    ),
 .pad_ddr_clk_w         (pad_ddr_clk_w   ),
 .pad_ddr_clkn_w        (pad_ddr_clkn_w  ),
 .pad_csn_ch0           (pad_csn_ch0     ),
 .pad_addr_ch0          (pad_addr_ch0    ),
 .pad_dq_ch0            (pad_dq_ch0      ),
 .pad_dqs_ch0           (pad_dqs_ch0     ),
 .pad_dqsn_ch0          (pad_dqsn_ch0    ),
 .pad_dm_rdqs_ch0       (pad_dm_rdqs_ch0 ),
 .pad_cke_ch0           (pad_cke_ch0     ),
 .pad_odt_ch0           (pad_odt_ch0     ),
 .pad_rasn_ch0          (pad_rasn_ch0    ),
 .pad_casn_ch0          (pad_casn_ch0    ),
 .pad_wen_ch0           (pad_wen_ch0     ),
 .pad_ba_ch0            (pad_ba_ch0      ),
 .pad_loop_out          (pad_loop_out    ),
 .pad_loop_out_h        (pad_loop_out_h  )
 );  

//ddr3测试数据模块  
ddr_test u_ddr_test(
    .clk_50m       (sys_clk         ),    //时钟
    .rst_n         (sys_rst_n       ),    //复位,低有效
    .wr_en         (wr_en           ),    //写使能
    .wr_data       (wr_data         ),    //写数据
    .rd_en         (rd_en           ),    //读使能
    .rd_data       (rd_data         ),    //读数据  
    .data_max      (DATA_MAX        ),    //读写ddr的最大数据量
    .ddr3_init_done(ddr_init_done   ),    //ddr3初始化完成信号
    .error_flag    (error_flag      )     //ddr3读写错误
    );

//利用LED灯指示ddr3读写测试的结果及ddr3是否初始化完成
led_disp u_led_disp(
    .clk_50m            (sys_clk          ),
    .rst_n              (sys_rst_n        ),
    .ddr3_init_done     (ddr_init_done    ),
    .error_flag         (error_flag       ),
    .led_error          (led_error        ),
    .led_ddr_init_done  (led_ddr_init_done)
    );

endmodule