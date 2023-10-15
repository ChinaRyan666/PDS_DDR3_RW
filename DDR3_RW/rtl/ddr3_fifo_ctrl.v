//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           ddr3_fifo_ctrl
// Last modified Date:  2020/05/04 9:19:08
// Last Version:        V1.0
// Descriptions:        ddr3������fifo����ģ��
//                      
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2019/05/04 9:19:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

`timescale 1ns / 1ps
module ddr3_fifo_ctrl(
    input           rst_n            ,  //��λ�ź�
    input           wr_clk           ,  //wfifoʱ��
    input           rd_clk           ,  //rfifoʱ��
    input           clk_100          ,  //�û�ʱ��
    input           datain_valid     ,  //������Чʹ���ź�
    input  [15:0]   datain           ,  //��Ч����
    input  [127:0]  rfifo_din        ,  //�û�������
    input           rdata_req        ,  //�������ص���ɫ��������
    input           rfifo_wren       ,  //��ddr3�������ݵ���Чʹ��
    input           wfifo_rden       ,  //wfifo��ʹ��
    output [127:0]  wfifo_dout       ,  //�û�д����
    output [10:0]   wfifo_rcount     ,  //rfifoʣ�����ݼ���
    output [10:0]   rfifo_wcount     ,  //wfifoд�����ݼ���
    output [15:0]   pic_data            //��Ч����
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