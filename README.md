# 基于紫光同创 FPGA 的 DDR3 读写实验
# 0 致读者


此篇为专栏 **《紫光同创FPGA开发笔记》** 的第二篇，记录我的学习FPGA的一些开发过程和心得感悟，刚接触FPGA的朋友们可以先去此专栏置顶 [《FPGA零基础入门学习路线》](http://t.csdnimg.cn/T0Qw2)来做最基础的扫盲。

本篇内容基于笔者实际开发过程和正点原子资料撰写，将会详细讲解此 FPGA 实验的全流程，**诚挚**地欢迎各位读者在评论区或者私信我交流！

**DDR3 SDRAM** 常简称 **DDR3**，是当今较为常见的一种 **DRAM** 存储器，在计算机及嵌入式产品中得到广泛应用，特别是应用在涉及到大量数据交互的场合，比如电脑的内存条。对 **DDR3** 的读写操作大都借助 **IP 核**来完成，本次实验将采用**紫光同创**公司的 **DDR3（Logos HMIC_H） IP 核**来实现 **DDR3 读写测试**。

本文的工程文件**开源地址**如下（基于**ATK-DFPGL22G**，大家 **clone** 到本地就可以直接跑仿真，如果要上板请根据自己的开发板更改约束即可）：

> [https://github.com/ChinaRyan666/PDS_DDR3_RW](https://github.com/ChinaRyan666/PDS_DDR3_RW)

<br/>
<br/>



# 1 实验任务

本文的实验任务是先向 **DDR3** 的存储器中写入 **5120** 个数据，写完之后再从存储器中读取相同地址的数据。若**初始化成功**， 则 **LED0** 常亮，否则 **LED0** 不亮； 若**读取的值全部正确**则 **LED1** 常亮，否则 **LED1** 闪烁。

<br/>
<br/>

# 2 简介
## 2.1 DDR3 简介

**DDR3 SDRAM（Double-Data-Rate Three Synchronous Dynamic Random Access Memory）** 是 **DDR SDRAM** 的第三代产品，相较于 DDR 和 DDR2， **DDR3** 有更高的运行性能与更低的电压。 **DDR SDRAM** 是在 **SDRAM** 技术的基础上发展改进而来的，同 SDRAM 相比， DDR SDRAM 的最大特点是**双沿触发**，即在时钟的上升沿和下降沿都能进行数据采集和发送。同样的工作时钟， **DDR SDRAM** 的读写速度可以比传统的 SDRAM 快一倍。 本次实验使用的 **DDR3** 芯片是南亚的 **NT5CC256M16**。

由于 **DDR3** 的时序非常复杂，如果直接编写 **DDR3** 的控制器代码，那么工作量是非常大的，且性能难以得到保证。值得一提的是， **PGL22 系列 FPGA 自带了 DDR3 控制器的硬核**，用户可以直接借助 **IP 核**来实现对 **DDR3** 的读写操作，从而大大降低了 **DDR3** 的开发难度。本次实验将使用紫光公司的 **Logos HMIC_H IP 核来**实现 **DDR3** 读写测试。

**HMIC_H IP** 是深圳市**紫光同创**电子有限公司 FPGA 产品中用于实现对 **SDRAM** 读写而设计的 IP，通过紫光同创公司 **Pango Design Suite 套件（后文简称 PDS）** 中 IP Compiler 工具（后文简称 IPC）例化生成 IP 模块。

**HMIC_H IP 系统框图**如下图所示：

![在这里插入图片描述](https://img-blog.csdnimg.cn/0539f2aa625248a188446bb91980785f.png)


**HMIC_H IP** 包括了 **DDR Controller**、 **DDR PHY** 和 **PLL**，用户通过 **AXI4** 接口实现数据的读写，通过 **APB** 接口可配置 **DDR Controller** 内部寄存器， **PLL** 用于产生需要的各种时钟。

>**AXI4 接口：** HMIC_H IP 提供三组 AXI4 Host Port： AXI4 Port0(128bit)、 AXI4 Port1(64bit)、 AXI4Port2(64bit)。用户通过 HMIC_H IP 界面可以选择使能这三组 AXI4 Port。三组 AXI4 Host Port 均为标准AXI4 接口。

>**APB 接口：** HMIC_H IP 提供一个 APB 配置接口，通过该接口，可配置 DDR Controller 内部寄存器。HMIC_H IP 可通过 APB 接口对内部 DDRC 配置寄存器进行读写，在初始化阶段， IP 将配置 DDRC 内部的配置寄存器，如果用户需要读写 DDRC 内部寄存器，需要在初始化完成后进行操作。 由于 IP 初始化阶段已将 DDRC 内部寄存器进行了正确的配置，因此不建议用户在初始化完成后随意更改配置寄存器的值。

各个接口具体的端口说明可以详见紫光的 **《Logos 系列产品 HMIC_H IP 用户指南》** 文档，该文档我放在了[此实验Github开源仓库](https://github.com/ChinaRyan666/PDS_DDR3_RW)的doc文件夹中，路径如下图所示。

![在这里插入图片描述](https://img-blog.csdnimg.cn/42ebb48cfca04d42a6e0878bdc52af85.png)

## 2.2 AXI4 协议简介


本设计 **AXI4** 接口为标准的 **AXI4 协议**接口，接口时序可参考 **AXI4** 协议， 下表为部分关键信号的接口说明。


![在这里插入图片描述](https://img-blog.csdnimg.cn/24ee1d04fde54071b0bc045934cd0ec1.png)

**AXI 总线**共有 5 个独立的通道,分别是 **read address channel (ARxxx)**， **write address channel(AWxxx)**，**read data channel(Rxxx)**， **write data channel(Wxxx)**， **write response channel(Bxxx)**。 

>每一个 **AXI** 传输通道都是**单方向**的，且都包含**一个信息信号**和**一个双路的 VALID、 READY 握手机制**。信息源通过 **VALID 信号**来指示通道中的数据和控制信息什么时候有效。目地源用 **READY 信号**来表示何时能够接收数据。读数据和写数据通道都包括一个 **LAST 信号**，用来指明一个事物传输的最后一个数据。

主机/设备之间的**握手过程**以及 **READY** 和 **VALID** 握手信号的关系如下：

>全部 5 个通道使用相同的 **VALID/READY 握手机制**传输数据及控制信息。**传输源**产生 **VALID** 信号来指明何时数据或控制信息有效。而**目地源**产生 **READY** 信号来指明已经准备好接受数据或控制信息。传输发生在 **VALID** 和 **READY** 信号同时为高的时候。 **VALID** 和 **READY** 信号的出现有三种关系。，分别为 **VALID** 先变高 **READY** 后变高、**READY** 先变高 **VALID** 后变高和 **VALID** 和 **READY** 信号同时变高，如下图所示，图中箭头处信息传输发生。


![在这里插入图片描述](https://img-blog.csdnimg.cn/2474b988062c46e4b7acd348588b6c32.png#pic_center)


<center>VALID 先变高 READY 后变高时序图</center>
<br/>
<br/>


![在这里插入图片描述](https://img-blog.csdnimg.cn/0f18e39ed6cd4ffea49efeb7e9044bef.png#pic_center)
<center>READY 先变高 VALID 后变高时序图</center>
<br/>
<br/>



![在这里插入图片描述](https://img-blog.csdnimg.cn/499ce94b8d964152b5f7e693eddd8b9b.png#pic_center)
<center>VALID 和 READY 信号同时变高时序图</center>
<br/>
<br/>


**地址、读、写和写响应通道**之间的关系是灵活的。例如，写数据可以出现在接口上早于与其相关联的写地址。也有可能写数据与写地址在一个周期中出现。但是有两种关系必须被保持：一是**读数据必须总是跟在与其数据相关联的地址之后**；二是**写响应必须总是跟在与其相关联的写事务的最后出现**。

>**通道握手信号**之间是有依赖性的， **读事务握手依赖关系**如下图所示，读事务握手时， 设备可以在 **ARVALID** 出现的时候再给出 **ARREADY** 信号，也可以先给出 **ARREADY** 信号，再等待 **ARVALID** 信号；但是设备必须等待 **ARVALID** 和 **ARREADY** 信号都有效才能给出 **RVALID** 信号，开始数据传输。

![在这里插入图片描述](https://img-blog.csdnimg.cn/692371a638584a498cfcf68328d82e65.png#pic_center)
<center>读事务握手依赖关系图</center>
<br/>
<br/>


>**写事务握手依赖关系**如下图所示，写事务握手时， 主机不能等设备给出 **AWREADY** 或 **WREADY** 信号后再给出信号 **AWVALID** 或 **WVALID**； 设备可以等待信号 **AWVALID** 或 **WVALID** 信号有效或者两个都有效之后再给出 **AWREADY** 信号。


![在这里插入图片描述](https://img-blog.csdnimg.cn/300a38a27bb048d99f471849193d473d.png#pic_center)
<center>写事务握手依赖关系图</center>
<br/>
<br/>



### 2.2.1 AXI4 读时序

>以下均以 **AXI4 Port0** 为例。

**AXI4 接口单次读操作**的时序如下图所示，主设备发送地址，一个周期后从设备接收。主设备在发送地址的同时也发送了一些控制信息标志了 **Burst（突发）** 的程度和类型，为了保持图片的清晰性，在此省略这些信号。用户拉高 **arvalid_0** 信号后等待 **arready_0** 拉高，当 **arvalid_0** 和 **arready_0** 信号同时为高时，表示**读地址有效**，此后在读数据通道上发生数据的传输。

同理用户拉高 **rready_0** 信号后等待 **rvalid_0** 拉高，当 **rready_0** 和 **rvalid_0** 信号同时为高时，表示**读数据有效**。当 **rlast_0** 拉高时，表示在告诉用户当前为**此次读操作的最后一个数据**。

![在这里插入图片描述](https://img-blog.csdnimg.cn/5d1fc0ed9ca64e158f06a07ba4e30723.png#pic_center)
<center>AXI4 接口单次读时序</center>
<br/>
<br/>


**AXI4 接口连续读操作**的时序如下图所示，主设备在从设备接收**第一次**读操作的地址后发送**下一次**读操作的地址。这样可以保证一个从设备在完成第一次读操作的同时可以开始处理第二次读操作的数据。下图中进行了**两次连续读操作**，可以看出也相应的拉高了两次 **rlast_0** 信号，对应**第一次读操作**的最后一个数据和**第二次读操作**的最后一个数据。


![在这里插入图片描述](https://img-blog.csdnimg.cn/a265e5eb440949b3821e80104afa69fc.png#pic_center)
<center>AXI4 接口连续读时序</center>
<br/>
<br/>

### 2.2.2 AXI4 写时序

>以下均以 **AXI4 Port0** 为例。

**AXI4 接口单次写操作**的时序如下图所示，当主设备发送地址和控制信息到写地址通道之后，写操作开始。然后主设备通过写数据通道发送每一个写数据，当为最后一个需要发送的数据时，主设备将 **wlast_0** 信号置高。当从设备接收完所有的数据时，从设备返回给主设备一个**写响应**标志本次写操作的结束。

**连续写操作**与连续读操作类似，即主设备在从设备接收**第一次**写操作的地址后发送**下一次**写操作的地址。例如：用户拉高 **awvalid_0** 信号后等待 **awready_0** 信号拉高，当 **awvalid_0** 和 **awready_0** 信号同时为高时， 表示写地址有效。同理用户拉高 **wvalid_0** 信号后等待 **wready_0** 信号拉高，当 **wvalid_0** 和 **wready_0** 信号同时为高时，表示写数据有效。当用户拉高 **wlast_0** 信号时，表示当前为此次写数据操作的**最后一个数据**。

![在这里插入图片描述](https://img-blog.csdnimg.cn/c340a0fb8c054c4eabd566d11ece3232.png)
<center>AXI4 接口单次写时序</center>
<br/>
<br/>


# 3 硬件设计

我使用的 **ATK-DFPGL22G** 开发板上使用了一片南亚的 **DDR3** 颗粒 **NT5CC256M16**，硬件原理图如下图所示。在 **PCB** 的设计上，完全遵照紫光的 **DDR3** 硬件设计规范，严格保证等长设计和阻抗控制，从而保证高速信号的数据传输的可靠性。

![在这里插入图片描述](https://img-blog.csdnimg.cn/ee5bd9dadc6044fc80bd32c5867a2fe1.png)

需要注意的是，由于约束文件过长，**ddr3 相关的引脚约束**不需要我们进行手动约束，可以将官方生成的约束文件中 **ddr3** 相关的约束代码复制进我们的约束文件即可，**官方约束文件所在路径**如下图所示：

![在这里插入图片描述](https://img-blog.csdnimg.cn/3b42858441324004a6ff25043f13b08a.png)

由于我使用的主控芯片是 **PGL22G-6MBG324**，我在硬件设计中的 **ddr3** 引脚分配在 **L1** 和 **L2 bank**，所以我选择将 **ddr_324_left.fdc** 文件中 **ddr3** 相关的约束代码复制进我的约束文件。

除了将 **ddr3** 相关的约束代码复制进来外，还要再将**如下约束**复制进我们工程的约束文件中。

```bash
define_attribute {i:u_ipsl_hmic_h_top.u_pll_50_400.u_pll_e1} {PAP_LOC} {PLL_82_71}
```

复制进来后需要将路径定位**改成我工程中的定位（根据自己工程路径修改）**，针对本例程的修改后代码如下。

```bash
define_attribute {i:u_ddr3_top.u_ddr3_ip.u_pll_50_400.u_pll_e1} {PAP_LOC} {PLL_82_71}
```

上述约束语句格式是固定的，其中只有第一个 { } 和第三个 { } 内的代码是用户修改的。第一个 { } 内 **“i：”** 后是的代码是用户定义的，此处代码是为了定位到所需约束的 **PLL** 在工程中的位置，这里位置信息不包括顶层。第三个 { } 内为约束 **PLL 编号**， **PLL 编号**可从 **tcl** 中查找，方法如下。

![在这里插入图片描述](https://img-blog.csdnimg.cn/32c98994e74d40fbace34a2005db543d.png)

打开 **Physical Constraint Editor** 界面后点击 **TCL** 图标。

![在这里插入图片描述](https://img-blog.csdnimg.cn/7286005b96444127afcf9bdf0ea7c28e.png)

下图中六个红框分别对应六个 **PLL** 编号(由上到下分别表示 **PLL0 ~ PLL5**)，点击我们需要约束的 **PLL**，即可在下方看到其对应编号。

![在这里插入图片描述](https://img-blog.csdnimg.cn/5a25a7ecf9dc4009b05fabeee5a709c4.png)

如何确定需要对哪个 **PLL** 进行约束可参照下图：

![在这里插入图片描述](https://img-blog.csdnimg.cn/62753bd287d64da394bd4e66c69005cc.png)

因为我这里是对 **ddr3 IP 核**中用到的 **PLL** 进行约束，而我们的 **ddr3 芯片**位于 **bank L1** 和 **bank L2**，我使用的主控芯片是 **PLG22G** 系列，所以从图中可知，我们应该将其约束到 **PPL3** 的编号或者 **PLL4** 的编号。这里我选择的是 **PLL4** 对应的编号。

这里简单的介绍一下 **PAP_LOC** 属性设置。

* **功能：** PAP_LOC 是位置约束， map 时会转化为 pcf 中的位置约束命令 def_ inst_site。
* **对象：** 作用对象通常是一些可以 place 到特殊资源（如 APM）的一些 instance。
* **属性值：** 属性值的形式是一个具体的 device instance 的名字。
* **描述：** PAP_LOC 属性是通过 DB 文件向下传递的，作用对象通常是一些可以 place 到特殊资源的一些instance，在 map 的过程中，这个属性会传递给这个 top 转化的 gop 对象。
* **使用说明：** 在 UCE 中设置 PAP_LOC 属性时，支持对属性对象和属性值进行检查。此命令只在约束文
本中编写。
* **表现形式：** 在 UCE 的 Device 界面可以看到初始阶段的约束，最终属性的表现形式在 PCE 中可以看到，
指定的约束对象会在属性值所指定的位置上被约束。

<br/>
<br/>

# 4 程序设计

## 4.1 总体模块设计


根据实验任务，可以大致规划出系统的控制流程：首先 **FPGA** 调用 **ddr3 测试数据模块**向 **ddr3 控制模块**写入数据，写完之后 **ddr 测试数据模块**从 **ddr3 控制模块**读出所写入的数据，并判断读出的数据与写入的数据是否相同，如果相同则 **LED1** 灯常亮，否则 **LED1** 灯闪烁。由此画出系统的功能框图如下图所示：


![在这里插入图片描述](https://img-blog.csdnimg.cn/c1ca658d3aa54b169eaa3dc32418260b.png)

由系统总体框图可知， **FPGA 顶层模块**例化了以下三个模块，分别是 **ddr3 控制模块(ddr3_top)**、 **ddr 测试数据模块(ddr_test)**和 **led 显示模块(led_disp)**。

>**ddr3 控制模块** 产生读写 **DDR3 IP** 核用户接口的时序，实现与 **DDR3 IP** 核的数据及信号交互。 **ddr3** 控制模块一方面负责与用户 **(FPGA)** 进行数据交互，另一方面还产生控制 **DDR3** 读写的各种时序，并实现对 **DDR** 芯片的读写操作。

> **ddr 测试数据模块** 的作用是写入和读出 **ddr3** 控制器的数据并且将读写数据进行比较。

>**led 显示模块**是根据读写错误信号的高低来判断是否翻转 **LED** 灯的电平，以及显示 **ddr3** 初始化完成情况。

本次实验用到的 **DDR3 IP** 核配置信息如下图所示：

![在这里插入图片描述](https://img-blog.csdnimg.cn/d1337627547b47749d1bada2299e9fb2.png)


**DDR3 IP 核**的接口信号很多，使用时如果每次都要进行新的配置会很繁琐，所以我们将 **DDR3** 控制器封装成类似于 **FIFO** 的接口， 在使用时只需要像读写 **FIFO** 那样给出读/写使能即可，这么做就方便了我们在以后的其他工程中对其进行调用。

**rd_fifo IP 核**参数配置如下图所示：

![在这里插入图片描述](https://img-blog.csdnimg.cn/ceb46049c7e249938500de66166ac711.png)

**wr_fifo IP 核**参数配置如下图所示：

![在这里插入图片描述](https://img-blog.csdnimg.cn/f3a20326b1f54fd4afb381bcf762e87e.png)

<br/>

## 4.2 顶层模块设计



**系统的顶层模块**代码如下：

```
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
```

在代码的第 30~34 行我们定义了四个参数，分别为 **ddr3 读写起始地址(APP_ADDR_MIN)**、 **ddr3 读写结束地址(APP_ADDR_MAX)**、 **ddr3 读写突发长度(BURST_LENGTH)** 以及**读写 ddr3 的最大数据量(DATA_MAX)**。其中 **APP_ADDR_MIN**、 **APP_ADDR_MAX** 和 **DATA_MAX** 是以一个 **16bit** 的数据为一个单位， **BURST_LENGTH** 是以一个 **128bit** 的数据为一个单位。

>**APP_ADDR_MAX** = APP_ADDR_MIN + BURST_LENGTH * 8 * n（n 表示突发次数）

>**DATA_MAX** = APP_ADDR_MAX - APP_ADDR_MIN

对于**突发长度(BURST_LENGTH)** 的设置， 根据配置，列地址是 **10** 位，列地址边界就是 **1023**，一次突发结束地址不能超过 **1023**（即 **1024** 个字节），超过就需要分两次，分两次的话实测是有可能会发生列地址回滚现象的，即列地址回滚到 **0**（起始地址） ，覆盖了一部分以 **0** 为起始地址的数据， 由于 **22G** 器件的 **DDR** 是**硬核 IP**，无法规避，只能从应用层控制，所以这里建议设置为 **2** 的整数次幂且不要超过 **64**（例如 2、 4、 8、 16、 32、 64），以此来**规避可能出现的因为回滚造成数据覆盖而导致读写错误问题**。

由于 **DDR3** 控制器被封装成 **FIFO 接口**，在使用时只需要像 **读/写 FIFO** 那样给出读/写使能即可，如代码 51 ~ 62 行所示。同时定义了最大和最小读写地址，在调用时数据在该地址空间中连续读写。

程序的 53 行及 56 行指定 **DDR3** 控制器的数据突发长度，由于 **DDR3 IP** 核的突发长度位宽为 **8** 位，因此控制器的突发长度不能大于 **255**。


<br/>


## 4.3 ddr3 控制模块设计



**ddr3 控制模块**代码如下：

```
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
```

**ddr3 控制器顶层模块**主要完成 **ddr3 读写控制器模块**、 **FIFO 控制模块**和 **ddr3 IP 核**的例化。**ddr3读写控制器**模块负责与 **ddr3 IP** 核模块的命令和地址的交互，根据 **FIFO** 控制模块中 **fifo** 的剩余数据量来切换 **DDR3** 的读写命令和地址。 **ddr3 IP** 核模块一边与用户端进行交互，另一边对芯片进行操作，以实现数据的存储。 **FIFO** 控制模块负责对输入和输出的数据进行时钟域的切换和位宽的转换。

<br/>

## 4.4 ddr3 读写控制器模块设计



**ddr3 读写控制器模块**代码如下：

```
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
```

代码第 **81** 行代码计算了最大突发次数，由于是从 **0** 地址开始写入，所以 **lenth_cnt_max = app_addr_wr_max / (wr_bust_len * 8)** ；若不是从 **0** 地址开始写入，则 **lenth_cnt_max = (app_addr_wr_max - app_addr_wr_min) / (wr_bust_len * 8)** 。

从第 **60** 行代码可以看出 **lenth_cnt_max（最大突发次数计数器）** 的位宽为 **10**， **10** 位宽的计数器最大可以计数到 **1023**，而根据上面的公式可以计算出本次读写例程只需要进行 **10** 次突发， 所以 **10** 位宽的计数器对于本次实验来说是绰绰有余的，但是当存储更大的数据量时，随着所需突发次数的增加，**lenth_cnt_max** 的位宽也需要做出相应的增大，否则就会出现读写错误的现象。

第 **84** 行和 **85** 行输出读写地址，由于第 **0** 位无效，所以第 **0** 位补 **0**， 读写地址数据从第 **1** 位开始填入。 这里对第 **0** 位无效做一下讲解， 应用中我们在计算 **ddr** 地址时一般是以 **16bit** 为一个单位的，但是 **PDS** 软件的这款 **DDR3 IP** 核是以字节 **（8bit）** 为一个单位的，即需要两个字节地址才能满足一个 **16bit** 的数据地址，所以为了符合 **IP** 核的使用， 我们需要对原本 **16bit** 数据对应的地址做一个乘 **2** 的处理，即在第 **0** 位补 **0**。

第 **88~95** 行代码用于稳定 **ddr3** 初始化完成信号，因为 **ddr3 IP** 核对初始化完成信号存在信号校准，所以初始化完成后该信号并非一直保持为高，会有跳动，因此在这里做当检测到一次 **ddr3** 初始化完成信号后，就将该信号一直拉高，使后续模块运行时， 时序不受影响。

第 **98~136** 行代码执行**写地址操作**， **ddr3** 初始化完成后，若**写地址计数小于最后一次写地址起始位**时，如果当前状态机处于写地址状态且写地址准备信号有效，拉高写地址有效信号； 写地址有效信号和写地址准备信号同时为高时，写地址计数器 **(axi_awaddr_n)** 增加一个突发长度所需的地址并将写地址有效信号拉低，即**写地址有效信号**只拉高了一个时钟周期。 若**写地址计数小于最后一次写地址起始位**时，当写地址有效信号和写地址准备信号同时为高时，将写地址计数器清零（即回到写起始地址），其他信号变化相同。

第 **139~189** 行代码执行**写数据操作**，**ddr3** 初始化完成后，若**突发写次数计数器小于最大突发次数**时，如果当前状态机处于写数据状态且写数据准备信号有效时，拉高写数据有效信号直至完成一次突发写操作后再将其拉低。 因为写 **DDR** 时已经提前让 **FIFO** 准备好第一个数据，所以使能在写结尾要减少一个使能周期，因此在写数据有效信号和写数据准备信号同时为高时，若突发长度计数器 **(init_addr)** 小于突发长度 **-2** 时，突发长度计数器加 **1**； 若突发长度计数器 **(init_addr)** 等于突发长度 **-2 (即写倒数第二个数)** 时，将 **wrfifo_en_ctrl** 信号拉高（即在写结尾减少一个使能周期）；若突发长度计数器 **(init_addr)** 等于突发长度 **-1 (即写最后一个数)** 时，将 **wrfifo_en_ctrl** 信号拉低，即 **wrfifo_en_ctrl** 信号只拉高一个时钟周期，为下一次写数据操作做准备。

>**读地址操作**的信号跳转与**写地址操作**时类似，这里不再赘述。

第 **230~279** 行代码是 **DDR3** 读写逻辑的实现，状态跳转如下图所示，图中**写状态**包含写地址状态和写数据状态；**读状态**包含读地址状态和读数据状态。


![在这里插入图片描述](https://img-blog.csdnimg.cn/5a12d396407346d985b1d0792f6630ec.png#pic_center)


在复位结束后，如果 **DDR3** 没有初始化完成，那么状态一直在空闲状态 **(IDLE)** ，否则跳到 **DDR3** 空闲状态 **(DDR3_DONE)** 。

+ 程序中第 **243~244** 行处理 **DDR3** 写请求，以免写 **FIFO** 溢出，造成写入 **DDR3** 的数据丢失。当写 **FIFO** 中的数据量大于一次突发写长度时，执行 **DDR3** 写地址操作 **(WRITE_ADDR)** 。

+ 程序中第 **245~246** 行处理 **DDR3** 读请求，以免读 **FIFO** 读空，造成空读现象。当读 **FIFO** 中的数据量小于一次读突发长度时，执行 **DDR3** 读地址操作 **(READ_ADDR)** 。

+ 程序中第 **250~261** 行处理 **DDR3** 写地址跳转到写数据状态的过程，当**写地址有效信号**和**写地址准备信号**同时为高时，状态机由写地址状态 **(WRITE_ADDR)** 跳转到写数据状态 **(WRITE_DATA)** ；当执行完一次突发写长度后，状态机由写数据状态跳转到 **DDR3** 空闲状态 **(DDR3_DONE)** 。

+ 程序中第 **262~273** 行处理 **DDR3** 读地址跳转到读数据状态的过程，跳转机制与写状态类似，有别处在于读数据状态 **(READ_DATA)** 跳转到 **DDR3** 空闲状态 **(DDR3_DONE)** 的条件是最后一次读信号 **(axi_rlast)** 为 **1** 时。


## 4.5 ddr3 控制器 fifo 控制模块设计




**ddr3** 控制器 **fifo** 控制模块代码如下：


```
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
```

该模块例化了两个 **FIFO IP** 核，分别为 **128** 位进 **16** 位出的读 **FIFO** 和 **16** 位进 **128** 位出的写 FIFO。读 **FIFO** 是将 **DDR3** 输出的 **128** 位宽的数据转为 **16** 位宽的数据后输出给用户；写 **FIFO** 是将用户输入的 **16** 位宽的数据转为 **128** 位宽的数据后输出给 **DDR3**。

<br/>


## 4.6 ddr3 测试数据模块设计



**ddr3** 测试数据模块代码如下：

```
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
```

**ddr** 测试数据模块从起始地址开始，连续向 **5120** 个存储空间中写入数据 **0~ 5119**。写完成后一直进行读操作，持续将该存储空间的数据读出。其中第 **45~50** 行代码对读计数器做了延时处理，使其与从 **ddr3** 中读出的数据对齐。

需要注意的的是程序中第 **116** 行通过变量 **rd_valid** 将第一次读出的 **5120** 个数据排除，并未参与读写测试。这是由于 **ddr3** 控制器为了保证读 **FIFO** 时刻有数据，在写数据尚未完成时，就将 **ddr3** 中的数据 “预读” 一部分（一次读长度）到读 **FIFO** 中，因此第一次从 **FIFO** 中读出的数据是无效的。**读/写时序**如下图所示：

![在这里插入图片描述](https://img-blog.csdnimg.cn/d87e9f8240754f48b6a1c09bc4260e27.png#pic_center)
<center>写数据时序 1</center>
<br/>
<br/>

![在这里插入图片描述](https://img-blog.csdnimg.cn/6a8752981dcd43a3867a001ca165f944.png#pic_center)
<center>写数据时序 2</center>
<br/>
<br/>


![在这里插入图片描述](https://img-blog.csdnimg.cn/658d2d51cba44ac4a092bbf79c5a8c1c.png#pic_center)
<center>读数据时序</center>
<br/>
<br/>


>从上面几个时序图中可以看出读写数据是一致的，因此信号 **error_flag** 一直处于低电平。


## 4.7 LED 显示模块设计


**LED** 显示模块代码如下：


```
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
```

**LED** 显示模块用 **LED** 不同的显示状态指示 **ddr3** 初始完成情况（**LED0** 常亮表示 **ddr3** 初始化完成）和 **ddr3** 读写测试的结果：若读写测试正确无误，则 **LED1** 常亮；若出现错误（读出的数据与写入的数据不一致），则 **LED1** 以 **0.5s** 为周期闪烁。

<br/>
<br/>



# 5 仿真验证

这里我们讲解一下 **ddr3** 例程如何进行 **Modelsim** 仿真，工程编译完成后 **ddr IP** 会自动生成一个 **sim** 文件夹，文件夹路径及内容如下所示：

![在这里插入图片描述](https://img-blog.csdnimg.cn/355e9c8ffaf64c62b5c767855243fc4e.png)

**接下来的操作流程**我在[此专栏](https://blog.csdn.net/ryansweet716/category_12470860.html?spm=1001.2014.3001.5482)中的第一篇博客中已经详细介绍了，原理是一样的，按照[紫光同创HMIC_S(DDR) IP与Modelsim的仿真](http://t.csdnimg.cn/jZjhF)的步骤操作即可。

![在这里插入图片描述](https://img-blog.csdnimg.cn/9aa4d1ee276d45ddb7223d0fd5d2ccef.png)

这里增加一个知识点，添加完仿真所需观察的信号后，我们可以将其另存为一个 **.do** 文件，这样在下次需要仿真时就可以省去查找和添加信号的时间。选择 **File** 后点击 **Save Format**，操作如下所示。

![在这里插入图片描述](https://img-blog.csdnimg.cn/ae95ace5eb2346feb70eaf749cf8b801.png)

存储路径**保持默认**即可(即工程仿真 **sim** 文件夹下)，然后点击 **ok** 即可。

![在这里插入图片描述](https://img-blog.csdnimg.cn/f295263ed07b493f9fe79e5309bb6f29.png)



我们将 **.do** 文件添加到 **ctrl_phy_sim.tcl**，并取消对 **run 800us** 的注释，这样等下次再对本次工程进行仿真时，只需要双击 **sim.bat** 即可出现仿真波形。**.do** 文件的添加语句为 **do wave.do** (其中 **wave** 为 **do** 文件名) ，如下图所示。

![在这里插入图片描述](https://img-blog.csdnimg.cn/5d41c2401b1d4758ac74209f23b9a0cd.png)

<br/>
<br/>

# 6 总结

本文我们成功实现了基于 **紫光同创 FPGA** 的 **DDR3 读写**，知识点较多，需要一定时间来理解吸收，希望以上的内容对您有所帮助，**诚挚**地欢迎各位读者在评论区或者私信我交流！



微博：沂舟Ryan ([@沂舟Ryan 的个人主页 - 微博 ](https://weibo.com/u/7619968945))

GitHub：[ChinaRyan666](https://github.com/ChinaRyan666)

微信公众号：**沂舟无限进步**（内含精品资料及详细教程）

如果对您有帮助的话请点赞支持下吧！



**集中一点，登峰造极。**
