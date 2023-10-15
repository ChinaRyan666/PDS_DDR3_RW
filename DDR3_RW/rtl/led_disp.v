//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           led_disp
// Last modified Date:  2020/09/04 9:19:08
// Last Version:        V1.0
// Descriptions:        LED显示模块
//                      
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2020/09/04 9:19:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module led_disp(
    input      clk_50m          , //系统时钟
    input      rst_n            , //系统复位
                                  
    input      ddr3_init_done   , //ddr3初始化完成信号
    input      error_flag       , //错误标志信号
    output reg led_error        , //读写错误led灯
    output reg led_ddr_init_done  //ddr3初始化完成led灯             
    );

//reg define
reg [24:0] led_cnt     ;   //控制LED闪烁周期的计数器
reg        init_done_d0;                
reg        init_done_d1;

//*****************************************************
//**                    main code
//***************************************************** 

//同步ddr3初始化完成信号
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
        init_done_d0 <= 1'b0 ;
        init_done_d1 <= 1'b0 ;
    end
    else if (ddr3_init_done) begin
        init_done_d0 <= ddr3_init_done;
        init_done_d1 <= init_done_d0;	
    end
	else begin
        init_done_d0 <= init_done_d0;
        init_done_d1 <= init_done_d1;	
    end
end    

//利用LED灯不同的显示状态指示DDR3初始化是否完成
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n)
        led_ddr_init_done <= 1'd0;
    else if(init_done_d1) 
        led_ddr_init_done <= 1'd1;
    else
        led_ddr_init_done <= led_ddr_init_done;
end

//计数器对50MHz时钟计数，计数周期为0.5s
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n)
        led_cnt <= 25'd0;
    else if(led_cnt < 25'd25000000) 
        led_cnt <= led_cnt + 25'd1;
    else
        led_cnt <= 25'd0;
end

//利用LED灯不同的显示状态指示错误标志的高低
always @(posedge clk_50m or negedge rst_n) begin
    if(rst_n == 1'b0)
        led_error <= 1'b0;
    else if(error_flag) begin
        if(led_cnt == 25'd25000000) 
            led_error <= ~led_error;    //错误标志为高时，LED灯每隔0.5s闪烁一次
        else
            led_error <= led_error;
    end    
    else
        led_error <= 1'b1;        //错误标志为低时，LED灯常亮
end

endmodule 