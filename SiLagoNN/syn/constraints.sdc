create_clock -name "clk" -period 20 -waveform {0 10} [get_ports clk]
set_clock_uncertainty 0.2 [get_clock clk]
set_false_path -from [get_port rst_n]
