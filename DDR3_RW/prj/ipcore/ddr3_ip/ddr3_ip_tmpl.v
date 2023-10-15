// Created by IP Generator (Version 2021.4-SP1.2 build 96435)
// Instantiation Template
//
// Insert the following codes into your Verilog file.
//   * Change the_instance_name to your own instance name.
//   * Change the signal names in the port associations


ddr3_ip the_instance_name (
  .pll_refclk_in(pll_refclk_in),        // input
  .top_rst_n(top_rst_n),                // input
  .ddrc_rst(ddrc_rst),                  // input
  .csysreq_ddrc(csysreq_ddrc),          // input
  .csysack_ddrc(csysack_ddrc),          // output
  .cactive_ddrc(cactive_ddrc),          // output
  .pll_lock(pll_lock),                  // output
  .pll_aclk_0(pll_aclk_0),              // output
  .pll_aclk_1(pll_aclk_1),              // output
  .pll_aclk_2(pll_aclk_2),              // output
  .ddrphy_rst_done(ddrphy_rst_done),    // output
  .ddrc_init_done(ddrc_init_done),      // output
  .pad_loop_in(pad_loop_in),            // input
  .pad_loop_in_h(pad_loop_in_h),        // input
  .pad_rstn_ch0(pad_rstn_ch0),          // output
  .pad_ddr_clk_w(pad_ddr_clk_w),        // output
  .pad_ddr_clkn_w(pad_ddr_clkn_w),      // output
  .pad_csn_ch0(pad_csn_ch0),            // output
  .pad_addr_ch0(pad_addr_ch0),          // output [15:0]
  .pad_dq_ch0(pad_dq_ch0),              // inout [15:0]
  .pad_dqs_ch0(pad_dqs_ch0),            // inout [1:0]
  .pad_dqsn_ch0(pad_dqsn_ch0),          // inout [1:0]
  .pad_dm_rdqs_ch0(pad_dm_rdqs_ch0),    // output [1:0]
  .pad_cke_ch0(pad_cke_ch0),            // output
  .pad_odt_ch0(pad_odt_ch0),            // output
  .pad_rasn_ch0(pad_rasn_ch0),          // output
  .pad_casn_ch0(pad_casn_ch0),          // output
  .pad_wen_ch0(pad_wen_ch0),            // output
  .pad_ba_ch0(pad_ba_ch0),              // output [2:0]
  .pad_loop_out(pad_loop_out),          // output
  .pad_loop_out_h(pad_loop_out_h),      // output
  .areset_0(areset_0),                  // input
  .aclk_0(aclk_0),                      // input
  .awid_0(awid_0),                      // input [7:0]
  .awaddr_0(awaddr_0),                  // input [31:0]
  .awlen_0(awlen_0),                    // input [7:0]
  .awsize_0(awsize_0),                  // input [2:0]
  .awburst_0(awburst_0),                // input [1:0]
  .awlock_0(awlock_0),                  // input
  .awvalid_0(awvalid_0),                // input
  .awready_0(awready_0),                // output
  .awurgent_0(awurgent_0),              // input
  .awpoison_0(awpoison_0),              // input
  .wdata_0(wdata_0),                    // input [127:0]
  .wstrb_0(wstrb_0),                    // input [15:0]
  .wlast_0(wlast_0),                    // input
  .wvalid_0(wvalid_0),                  // input
  .wready_0(wready_0),                  // output
  .bid_0(bid_0),                        // output [7:0]
  .bresp_0(bresp_0),                    // output [1:0]
  .bvalid_0(bvalid_0),                  // output
  .bready_0(bready_0),                  // input
  .arid_0(arid_0),                      // input [7:0]
  .araddr_0(araddr_0),                  // input [31:0]
  .arlen_0(arlen_0),                    // input [7:0]
  .arsize_0(arsize_0),                  // input [2:0]
  .arburst_0(arburst_0),                // input [1:0]
  .arlock_0(arlock_0),                  // input
  .arvalid_0(arvalid_0),                // input
  .arready_0(arready_0),                // output
  .arpoison_0(arpoison_0),              // input
  .rid_0(rid_0),                        // output [7:0]
  .rdata_0(rdata_0),                    // output [127:0]
  .rresp_0(rresp_0),                    // output [1:0]
  .rlast_0(rlast_0),                    // output
  .rvalid_0(rvalid_0),                  // output
  .rready_0(rready_0),                  // input
  .arurgent_0(arurgent_0),              // input
  .csysreq_0(csysreq_0),                // input
  .csysack_0(csysack_0),                // output
  .cactive_0(cactive_0)                 // output
);
