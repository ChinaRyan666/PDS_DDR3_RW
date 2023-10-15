//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           ddr_test
// Last modified Date:  2020/09/04 9:19:08
// Last Version:        V1.0
// Descriptions:        ddr测试数据模块 
//                      
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2020/09/04 9:19:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module ddr_test(
    input             clk_50m       ,   //时钟
    input             rst_n         ,   //复位,低有效
                                        
    output reg        wr_en         ,   //写使能
    output reg [15:0] wr_data       ,   //写数据
    output reg        rd_en         ,   //读使能
    input      [15:0] rd_data       ,   //读数据
    input      [27:0] data_max      ,   //写入ddr的最大数据量
    
    input             ddr3_init_done,   //ddr3初始化完成信号
    output reg        error_flag        //ddr3读写错误
    
    );

//reg define
reg        init_done_d0;
reg        init_done_d1;
reg [27:0] wr_cnt      ;   //写操作计数器
reg [27:0] rd_cnt      ;   //读操作计数器
reg        rd_valid    ;   //读数据有效标志
reg [27:0] rd_cnt_d0   ;
  
//*****************************************************
//**                    main code
//***************************************************** 

//同步ddr3初始化完成信号
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
        init_done_d0 <= 1'b0 ;
        init_done_d1 <= 1'b0 ;
    end
    else begin
        init_done_d0 <= ddr3_init_done;
        init_done_d1 <= init_done_d0;
    end
end

//对读计数器做一拍延时使数据对齐
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n)
        rd_cnt_d0    <= 28'd0;
    else
        rd_cnt_d0 <= rd_cnt;
end 

//ddr3初始化完成之后,写操作计数器开始计数
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) 
        wr_cnt <= 28'd0;
    else if(init_done_d1 && (wr_cnt < data_max ))
        wr_cnt <= wr_cnt + 1'b1;
    else 
        wr_cnt <= wr_cnt;
end    

//ddr3写端口FIFO的写使能、写数据
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
        wr_en   <= 1'b0;
        wr_data <= 16'd0;
    end
    else if(wr_cnt >= 11'd0 && (wr_cnt < data_max )&&init_done_d1) begin
            wr_en   <= 1'b1;            //写使能拉高
            wr_data <= wr_cnt[15:0];    //写入数据
    end    
    else begin
            wr_en   <= 1'b0;
            wr_data <= 16'd0;
    end
end

//写入数据完成后,开始读操作
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) 
        rd_en <= 1'b0;
    else if(wr_cnt >= data_max )         //写数据完成
        rd_en <= 1'b1;                   //读使能
    else
        rd_en <= rd_en;
end

//对读操作计数
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) 
        rd_cnt <= 28'd0;
    else if(rd_en) begin
        if(rd_cnt < data_max - 1'd1)
            rd_cnt <= rd_cnt + 1'd1;
        else
            rd_cnt <= 28'd0;
    end
end

//第一次读取的数据无效,后续读操作所读取的数据才有效
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) 
        rd_valid <= 1'b0;
    else if(rd_cnt >= data_max - 1'd1 )  //等待第一次读操作结束
        rd_valid <= 1'b1;                //后续读取的数据有效
    else
        rd_valid <= rd_valid;
end

//读数据有效时,若读取数据错误,给出标志信号
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n)
        error_flag <= 1'b0; 
    else if(wr_en)       
        error_flag <= 1'b0;      
    else if(rd_valid && ((rd_data[15:0] != rd_cnt_d0[15:0])) )
        error_flag <= 1'b1;             //若读取的数据错误,将错误标志位拉高
    else
        error_flag <= error_flag;
end

endmodule