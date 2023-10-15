onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /ddr_test_top_tb/u_ddr3_rw_top/u_ddr3_top/u_rw_ctrl_128bit/clk
add wave -noupdate /ddr_test_top_tb/u_ddr3_rw_top/u_ddr3_top/u_rw_ctrl_128bit/ddr_init_done
add wave -noupdate /ddr_test_top_tb/u_ddr3_rw_top/u_ddr3_top/u_rw_ctrl_128bit/axi_awaddr
add wave -noupdate /ddr_test_top_tb/u_ddr3_rw_top/u_ddr3_top/u_rw_ctrl_128bit/axi_awready
add wave -noupdate /ddr_test_top_tb/u_ddr3_rw_top/u_ddr3_top/u_rw_ctrl_128bit/axi_awvalid
add wave -noupdate /ddr_test_top_tb/u_ddr3_rw_top/u_ddr3_top/u_rw_ctrl_128bit/axi_wvalid
add wave -noupdate /ddr_test_top_tb/u_ddr3_rw_top/u_ddr3_top/u_rw_ctrl_128bit/axi_wready
add wave -noupdate /ddr_test_top_tb/u_ddr3_rw_top/u_ddr3_top/u_rw_ctrl_128bit/axi_wlast
add wave -noupdate /ddr_test_top_tb/u_ddr3_rw_top/u_ddr3_top/u_rw_ctrl_128bit/wrfifo_en_ctrl
add wave -noupdate /ddr_test_top_tb/u_ddr3_rw_top/u_ddr3_top/u_rw_ctrl_128bit/axi_araddr
add wave -noupdate /ddr_test_top_tb/u_ddr3_rw_top/u_ddr3_top/u_rw_ctrl_128bit/axi_arready
add wave -noupdate /ddr_test_top_tb/u_ddr3_rw_top/u_ddr3_top/u_rw_ctrl_128bit/axi_arvalid
add wave -noupdate /ddr_test_top_tb/u_ddr3_rw_top/u_ddr3_top/u_rw_ctrl_128bit/axi_rlast
add wave -noupdate /ddr_test_top_tb/u_ddr3_rw_top/u_ddr3_top/u_rw_ctrl_128bit/axi_rvalid
add wave -noupdate /ddr_test_top_tb/u_ddr3_rw_top/u_ddr3_top/u_rw_ctrl_128bit/axi_rready
add wave -noupdate /ddr_test_top_tb/u_ddr3_rw_top/u_ddr3_top/u_rw_ctrl_128bit/axi_araddr_n
add wave -noupdate /ddr_test_top_tb/u_ddr3_rw_top/u_ddr3_top/u_rw_ctrl_128bit/axi_awaddr_n
add wave -noupdate /ddr_test_top_tb/u_ddr3_rw_top/u_ddr3_top/u_rw_ctrl_128bit/state_cnt
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {10000000 fs} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits fs
update
WaveRestoreZoom {950565130630 fs} {989081493130 fs}
