//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           ddr3_top
// Last modified Date:  2020/05/04 9:19:08
// Last Version:        V1.0
// Descriptions:        ddr3����������ģ��
//                      
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2019/05/04 9:19:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module ddr3_top(
    input              refclk_in        ,//�ⲿ�ο�ʱ������
    input              rst_n            ,//�ⲿ��λ����

    input   [27:0]     app_addr_rd_min  ,//��ddr3����ʼ��ַ
    input   [27:0]     app_addr_rd_max  ,//��ddr3�Ľ�����ַ
    input   [7:0]      rd_bust_len      ,//��ddr3�ж�����ʱ��ͻ������
    input   [27:0]     app_addr_wr_min  ,//��ddr3����ʼ��ַ
    input   [27:0]     app_addr_wr_max  ,//��ddr3�Ľ�����ַ
    input   [7:0]      wr_bust_len      ,//��ddr3�ж�����ʱ��ͻ������
    //�û�     
    input              wr_clk           ,//wfifoдʱ��
    input              rd_clk           ,//rfifo��ʱ��
    input              datain_valid     ,//������Чʹ���ź�
    input   [15:0]     datain           ,//��Ч����
    input              rdata_req        ,//������������
    output  [15:0]     dataout          ,//rfifo�������

    output             ddr_init_done    ,//DDR��ʼ�����
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
    wire [10:0]       wfifo_rcount   ;//rfifoʣ�����ݼ���
    wire [10:0]       rfifo_wcount   ;//wfifoд�����ݼ���
    wire              wrfifo_en_ctrl ;//дFIFO���ݶ�ʹ�ܿ���λ
    wire              wfifo_rden     ;//дFIFO���ݶ�ʹ��
    wire              pre_wfifo_rden ;//дFIFO����Ԥ��ʹ��

//*****************************************************
//**                    main code
//*****************************************************
//��ΪԤ����һ���������Զ�ʹ��wfifo_rdenҪ��һ������ͨ��wrfifo_en_ctrl����
assign wfifo_rden = axi_wvalid && axi_wready && (~wrfifo_en_ctrl) ;
assign pre_wfifo_rden = axi_awvalid && axi_awready ;

//ddr3��д������ģ��
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

 //ddr3IP��ģ��
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

//ddr3������fifo����ģ��
 ddr3_fifo_ctrl u_ddr3_fifo_ctrl (
    .rst_n               (rst_n && ddr_init_done    ) ,  //��λ
    //����Դ�ӿ�
    .wr_clk              (wr_clk                    ) ,  //дʱ��
    .rd_clk              (rd_clk                    ) ,  //��ʱ��
    .clk_100             (axi_clk                   ) ,  //�û�ʱ�� 
    .datain_valid        (datain_valid              ) ,  //������Чʹ���ź�
    .datain              (datain                    ) ,  //��Ч���� 
    .rfifo_din           (axi_rdata                 ) ,  //�û������� 
    .rdata_req           (rdata_req                 ) ,  //�������ص���ɫ��������
    .rfifo_wren          (axi_rvalid                ) ,  //ddr3�������ݵ���Чʹ��
    .wfifo_rden          (wfifo_rden||pre_wfifo_rden) ,  //ddr3 дʹ��
    //�û��ӿ�
    .wfifo_rcount        (wfifo_rcount              ) , //rfifoʣ�����ݼ���
    .rfifo_wcount        (rfifo_wcount              ) , //wfifoд�����ݼ���
    .wfifo_dout          (axi_wdata                 ) , //�û�д����
    .pic_data            (dataout                   )   //rfifo�������
    );

endmodule