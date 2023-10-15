quit -sim                                                                                                          
                                                                                                                   
if {[file exists work]} {                                                                                          
  file delete -force work                                                                                          
}                                                                                                                  
                                                                                                                   
  vlib	work                                                                                                      
  vmap	work work                                                                                                 
                                                                                                                   
set LIB_DIR  D:/pango/PDS_2021.4-SP1.2/ip/system_ip/ipsl_hmic_h/ipsl_hmic_h_eval/ipsl_hmic_h/../../../../../arch/vendor/pango/verilog/simulation
                                                                                                                   
vlib work                                                                                                          
vlog -sv -work work -mfcu -incr -f ../sim/sim_file_list.f -y $LIB_DIR +libext+.v +incdir+../example_design/bench/mem/ 
#vsim -suppress 3486,3680,3781 +nowarn1 -c -sva -lib work ddr_test_top_tb -l sim.log               
vsim -novopt -suppress 3486,3680,3781  -c ddr_test_top_tb -L work -l sim.log
#do wave.do
#run 800us    
             
