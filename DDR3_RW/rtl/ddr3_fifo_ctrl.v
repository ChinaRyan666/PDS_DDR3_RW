//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           ddr3_fifo_ctrl
// Last modified Date:  2020/05/04 9:19:08
// Last Version:        V1.0
// Descriptions:        ddr3控制器fifo控制模块
//                      
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2019/05/04 9:19:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

`timescale 1ns / 1ps
module ddr3_fifo_ctrl(
    input           rst_n            ,  //复位信号
    input           wr_clk           ,  //wfifo时钟
    input           rd_clk           ,  //rfifo时钟
    input           clk_100          ,  //用户时钟
    input           datain_valid     ,  //数据有效使能信号
    input  [15:0]   datain           ,  //有效数据
    input  [127:0]  rfifo_din        ,  //用户读数据
    input           rdata_req        ,  //请求像素点颜色数据输入
    input           rfifo_wren       ,  //从ddr3读出数据的有效使能
    input           wfifo_rden       ,  //wfifo读使能
    output [127:0]  wfifo_dout       ,  //用户写数据
    output [10:0]   wfifo_rcount     ,  //rfifo剩余数据计数
    output [10:0]   rfifo_wcount     ,  //wfifo写进数据计数
    output [15:0]   pic_data            //有效数据
    );

rd_fifo u_rd_fifo  (
  .wr_clk         (clk_100     ),  // input
  .wr_rst         (~rst_n      ),  // input
  .wr_en          (rfifo_wren  ),  // input
  .wr_data        (rfifo_din   ),  // input [127:0]
  .wr_full        (            ),  // output
  .wr_water_level (rfifo_wcount),  // output
  .almost_full    (            ),  // output
  .rd_clk         (rd_clk      ),  // input
  .rd_rst         (~rst_n      ),  // input
  .rd_en          (rdata_req   ),
  .rd_data        (pic_data    ),  // output [15:0]
  .rd_empty       (            ),  // output
  .rd_water_level (            ),  // output
  .almost_empty   (            )   // output
);

wr_fifo u_wr_fifo  (
  .wr_clk         (wr_clk      ),    // input
  .wr_rst         (~rst_n      ),    // input
  .wr_en          (datain_valid), 
  .wr_data        (datain      ),    //input [15:0]
  .wr_full        (            ),    // output
  .wr_water_level (            ),    // output
  .almost_full    (            ),    // output
  .rd_clk         (clk_100     ),    // input 
  .rd_rst         (~rst_n      ),    // input
  .rd_en          (wfifo_rden  ),    // input
  .rd_data        (wfifo_dout  ),    // output [127:0]
  .rd_empty       (            ),    // output
  .rd_water_level (wfifo_rcount),    // output
  .almost_empty   (            )     // output
);
endmodule