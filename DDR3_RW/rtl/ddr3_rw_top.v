//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           ddr3_rw_top
// Last modified Date:  2020/05/04 9:19:08
// Last Version:        V1.0
// Descriptions:        ddr3��д���Զ���ģ��
//                      
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2019/05/04 9:19:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module ddr3_rw_top(
    input             sys_clk          , //ϵͳʱ��50M
    input             sys_rst_n        , //ϵͳ��λ
    output            led_error        , //��д����led��
    output            led_ddr_init_done, //ddr3��ʼ�����led��

    //DDR3�ӿ�
    input             pad_loop_in      , //��λ�¶Ȳ�������
    input             pad_loop_in_h    , //��λ�¶Ȳ�������
    output            pad_rstn_ch0     , //Memory��λ
    output            pad_ddr_clk_w    , //Memory���ʱ������
    output            pad_ddr_clkn_w   , //Memory���ʱ�Ӹ���
    output            pad_csn_ch0      , //MemoryƬѡ
    output [15:0]     pad_addr_ch0     , //Memory��ַ����
    inout  [16-1:0]   pad_dq_ch0       , //��������
    inout  [16/8-1:0] pad_dqs_ch0      , //����ʱ������
    inout  [16/8-1:0] pad_dqsn_ch0     , //����ʱ�Ӹ���
    output [16/8-1:0] pad_dm_rdqs_ch0  , //����Mask
    output            pad_cke_ch0      , //Memory���ʱ��ʹ��
    output            pad_odt_ch0      , //On Die Termination
    output            pad_rasn_ch0     , //�е�ַstrobe
    output            pad_casn_ch0     , //�е�ַstrobe
    output            pad_wen_ch0      , //дʹ��
    output [2:0]      pad_ba_ch0       , //Bank��ַ����
    output            pad_loop_out     , //��λ�¶Ȳ������
    output            pad_loop_out_h     //��λ�¶Ȳ������    
   );

//parameter define 
parameter  APP_ADDR_MIN = 28'd0  ;  //ddr3��д��ʼ��ַ����һ��16bit������Ϊһ����λ
//APP_ADDR_MAX = APP_ADDR_MIN + BURST_LENGTH * 8 * n��n��ʾͻ��������
parameter  APP_ADDR_MAX = 28'd5120 ;  //ddr3��д������ַ����һ��16bit������Ϊһ����λ
parameter  BURST_LENGTH = 8'd64    ;  //ddr3��дͻ�����ȣ�64��128bit������
parameter  DATA_MAX = APP_ADDR_MAX - APP_ADDR_MIN;  //��дddr3�����������

//wire define
wire  [15:0]  wr_data        ;  //DDR3������ģ��д����
wire  [15:0]  rd_data        ;  //DDR3������ģ�������
wire          wr_en          ;  //DDR3������ģ��дʹ��
wire          rd_en          ;  //DDR3������ģ���ʹ��
wire          ddr_init_done  ;  //ddr3��ʼ������ź�
wire          error_flag     ;  //ddr3��д�����־

////*****************************************************
////**                    main code
////***************************************************** 
//ddr3����������ģ��
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
 //DDR3�ӿ�
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

//ddr3��������ģ��  
ddr_test u_ddr_test(
    .clk_50m       (sys_clk         ),    //ʱ��
    .rst_n         (sys_rst_n       ),    //��λ,����Ч
    .wr_en         (wr_en           ),    //дʹ��
    .wr_data       (wr_data         ),    //д����
    .rd_en         (rd_en           ),    //��ʹ��
    .rd_data       (rd_data         ),    //������  
    .data_max      (DATA_MAX        ),    //��дddr�����������
    .ddr3_init_done(ddr_init_done   ),    //ddr3��ʼ������ź�
    .error_flag    (error_flag      )     //ddr3��д����
    );

//����LED��ָʾddr3��д���ԵĽ����ddr3�Ƿ��ʼ�����
led_disp u_led_disp(
    .clk_50m            (sys_clk          ),
    .rst_n              (sys_rst_n        ),
    .ddr3_init_done     (ddr_init_done    ),
    .error_flag         (error_flag       ),
    .led_error          (led_error        ),
    .led_ddr_init_done  (led_ddr_init_done)
    );

endmodule