//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           rw_ctrl_128bit
// Last modified Date:  2020/05/04 9:19:08
// Last Version:        V1.0
// Descriptions:        ddr3��д������ģ��
//                      
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2019/05/04 9:19:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

`timescale 1ps/1ps

module rw_ctrl_128bit 
 (
   input                   clk             , //ʱ��
   input                   rst_n           , //��λ
   input                   ddr_init_done   , //DDR��ʼ�����
   output      [32-1:0 ]   axi_awaddr      , //д��ַ
   output reg  [7:0    ]   axi_awlen       , //дͻ������
   output wire [2:0    ]   axi_awsize      , //дͻ����С
   output wire [1:0    ]   axi_awburst     , //дͻ������
   output                  axi_awlock      , //д��������
   input                   axi_awready     , //д��ַ׼���ź�
   output reg              axi_awvalid     , //д��ַ��Ч�ź�
   output                  axi_awurgent    , //д�����ź�,1:Write addressָ������ִ��
   output                  axi_awpoison    , //д�����ź�,1:Write addressָ����Ч
   output wire [15:0   ]   axi_wstrb       , //дѡͨ
   output reg              axi_wvalid      , //д������Ч�ź�
   input                   axi_wready      , //д����׼���ź�
   output reg              axi_wlast       , //���һ��д�ź�
   output wire             axi_bready      , //д��Ӧ׼���ź�
   output reg              wrfifo_en_ctrl  , //дFIFO���ݶ�ʹ�ܿ���λ
   output      [32-1:0 ]   axi_araddr      , //����ַ
   output reg  [7:0    ]   axi_arlen       , //��ͻ������
   output wire [2:0    ]   axi_arsize      , //��ͻ����С
   output wire [1:0    ]   axi_arburst     , //��ͻ������
   output wire             axi_arlock      , //����������
   output wire             axi_arpoison    , //�������ź�,1:Read addressָ����Ч
   output wire             axi_arurgent    , //�������ź�,1:Read addressָ������ִ��
   input                   axi_arready     , //����ַ׼���ź�
   output reg              axi_arvalid     , //����ַ��Ч�ź�
   input                   axi_rlast       , //���һ�ζ��ź�
   input                   axi_rvalid      , //��������Ч�ź�
   output wire             axi_rready      , //������׼���ź�
   input       [10:0   ]   wfifo_rcount    , //д�˿�FIFO�е�������
   input       [10:0   ]   rfifo_wcount    , //���˿�FIFO�е�������
   input       [27:0   ]   app_addr_rd_min , //��DDR3����ʼ��ַ
   input       [27:0   ]   app_addr_rd_max , //��DDR3�Ľ�����ַ
   input       [7:0    ]   rd_bust_len     , //��DDR3�ж�����ʱ��ͻ������
   input       [27:0   ]   app_addr_wr_min , //дDDR3����ʼ��ַ
   input       [27:0   ]   app_addr_wr_max , //дDDR3�Ľ�����ַ
   input       [7:0    ]   wr_bust_len       //��DDR3��д����ʱ��ͻ������
);

//localparam define 
localparam IDLE        = 4'd1 ; //����״̬
localparam DDR3_DONE   = 4'd2 ; //DDR3��ʼ�����״̬
localparam WRITE_ADDR  = 4'd3 ; //д��ַ
localparam WRITE_DATA  = 4'd4 ; //д����
localparam READ_ADDR   = 4'd5 ; //����ַ
localparam READ_DATA   = 4'd6 ; //������

//reg define
reg        init_start   ; //��ʼ������ź�
reg [31:0] init_addr    ; //ͻ�����ȼ�����
reg [31:0] axi_araddr_n ; //����ַ����
reg [31:0] axi_awaddr_n ; //д��ַ����
reg [3:0 ] state_cnt    ; //״̬������
reg [9:0 ] lenth_cnt    ; //ͻ��д����������

//wire define
wire [9:0 ] lenth_cnt_max; //���ͻ������

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

//�������ͻ������
assign  lenth_cnt_max = app_addr_wr_max / (wr_bust_len * 4'd8);

//��д��ַ��16bit��Ӧһ����ַת��Ϊһ���ֽڶ�Ӧһ����ַ
assign  axi_araddr = {6'b0,axi_araddr_n[24:0],1'b0};
assign  axi_awaddr = {6'b0,axi_awaddr_n[24:0],1'b0};

//�ȶ�ddr3��ʼ���ź�
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        init_start <= 1'b0;
    else if (ddr_init_done)
        init_start <= ddr_init_done;
    else
        init_start <= init_start;
end

//д��ַģ��
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        axi_awaddr_n <= app_addr_wr_min;
        axi_awlen    <= 8'b0;
        axi_awvalid  <= 1'b0;
    end
    //DDR3��ʼ����� 
    else if (init_start) begin
        axi_awlen <= wr_bust_len - 1'b1;
        //��д��ַ����С�����һ��д��ַ��ʼλʱ
        if (axi_awaddr_n < app_addr_wr_max - wr_bust_len * 5'd8) begin
            //д��ַ��Ч�źź�д��ַ׼���źŶ�Ϊ1ʱ
            if (axi_awvalid && axi_awready) begin
                axi_awvalid  <= 1'b0;         //����д��ַ��Ч�ź�
                //д��ַ������һ��ͻ����������ĵ�ַ
                axi_awaddr_n <= axi_awaddr_n + wr_bust_len * 5'd8;//wr_bust_len*128/16
            end
            //״̬������д��ַ״̬��д��ַ׼���ź�Ϊ1ʱ
            else if (state_cnt == WRITE_ADDR && axi_awready)
                axi_awvalid  <= 1'b1;    //����д��ַ��Ч�ź�
        end
        //��д��ַ�����������һ��д��ַ��ʼλʱ
        else if (axi_awaddr_n == app_addr_wr_max - wr_bust_len * 5'd8) begin
            if (axi_awvalid && axi_awready) begin
                axi_awvalid  <= 1'b0;
                axi_awaddr_n <= app_addr_wr_min; //д��ַ�������㣨�ص�д��ʼ��ַ��
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

//д����ģ��
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        axi_wvalid <= 1'b0  ;
        axi_wlast  <= 1'b0  ;
        init_addr  <= 32'd0 ;
        lenth_cnt  <= 8'd0  ;
        wrfifo_en_ctrl <= 1'b0;
    end
    else begin
        //DDR3��ʼ�����
        if (init_start) begin
            //��ͻ��д����������С�����ͻ������ʱ
            if (lenth_cnt < lenth_cnt_max) begin
                if (axi_wvalid && axi_wready && init_addr < wr_bust_len - 2'd2) begin
                    init_addr      <= init_addr + 1'b1;
                    wrfifo_en_ctrl <= 1'b0;
                end 
                //��ΪдDDRʱ�Ѿ���ǰ��FIFO׼���õ�һ�����ݣ�����ʹ����д��βҪ����һ��ʹ������
                else if (axi_wvalid && axi_wready && init_addr == wr_bust_len - 2'd2) begin
                    axi_wlast      <= 1'b1;
                    wrfifo_en_ctrl <= 1'b1;              //��ǰһ��ʱ����������
                    init_addr      <= init_addr + 1'b1;
                end
                //��ͻ�����ȼ���������һ��ͻ������ʱ
                else if (axi_wvalid && axi_wready && init_addr == wr_bust_len - 2'd1) begin
                    axi_wvalid     <= 1'b0;
                    axi_wlast      <= 1'b0;
                    wrfifo_en_ctrl <= 1'b0;
                    lenth_cnt      <= lenth_cnt + 1'b1;  //ͻ��д������������1
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

//����ַģ��
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      axi_araddr_n <= app_addr_rd_min;
      axi_arlen    <= 8'b0;
      axi_arvalid  <= 1'b0;
    end
    //DDR3��ʼ�����
    else if(init_start) begin
        axi_arlen <= rd_bust_len - 1'b1;
        //������ַ����С�����һ�ζ���ַ��ʼλʱ
        if (axi_araddr_n < app_addr_rd_max  - rd_bust_len * 5'd8) begin
            if (axi_arready && axi_arvalid) begin
                axi_arvalid  <= 1'b0;
                axi_araddr_n <= axi_araddr_n + rd_bust_len * 5'd8;
            end
            else if(axi_arready && state_cnt == READ_ADDR)
                axi_arvalid  <= 1'b1;
        end 
        //������ַ�����������һ�ζ���ַ��ʼλʱ
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

//DDR3��д�߼�ʵ��ģ��
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
                    state_cnt <= WRITE_ADDR;         //����д��ַ����
                else if(rfifo_wcount < rd_bust_len)
                    state_cnt <= READ_ADDR;          //��������ַ����
                else 
                    state_cnt <= state_cnt; 
            end             
            WRITE_ADDR:begin
                if(axi_awvalid && axi_awready)
                    state_cnt <= WRITE_DATA;        //����д���ݲ��� 
                else
                    state_cnt <= state_cnt;         //���������㣬���ֵ�ǰֵ
            end
            WRITE_DATA:begin 
                if(axi_wvalid && axi_wready && init_addr == wr_bust_len - 1)
                    state_cnt <= DDR3_DONE;        //д���趨�ĳ��������ȴ�״̬
                else
                    state_cnt <= state_cnt;        //д���������㣬���ֵ�ǰֵ
            end         
            READ_ADDR:begin
                if(axi_arvalid && axi_arready)
                    state_cnt <= READ_DATA;        //����д���ݲ���
                else
                    state_cnt <= state_cnt;        //���������㣬���ֵ�ǰֵ
            end
            READ_DATA:begin
                if(axi_rlast)                      //�����趨�ĵ�ַ����
                    state_cnt <= DDR3_DONE;        //����������״̬
                else
                    state_cnt <= state_cnt;        //���򱣳ֵ�ǰֵ
            end
            default:begin
                state_cnt <= IDLE;
            end
        endcase
    end
end

endmodule