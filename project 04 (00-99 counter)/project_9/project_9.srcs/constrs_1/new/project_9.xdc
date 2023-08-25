## Clock signal
set_property PACKAGE_PIN W5 [get_ports clk]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk]
	create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]
	
#7 segment display
set_property PACKAGE_PIN W7 [get_ports {seven_seg[6]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {seven_seg[6]}]
set_property PACKAGE_PIN W6 [get_ports {seven_seg[5]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {seven_seg[5]}]
set_property PACKAGE_PIN U8 [get_ports {seven_seg[4]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {seven_seg[4]}]
set_property PACKAGE_PIN V8 [get_ports {seven_seg[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {seven_seg[3]}]
set_property PACKAGE_PIN U5 [get_ports {seven_seg[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {seven_seg[2]}]
set_property PACKAGE_PIN V5 [get_ports {seven_seg[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {seven_seg[1]}]
set_property PACKAGE_PIN U7 [get_ports {seven_seg[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {seven_seg[0]}]

#set_property PACKAGE_PIN V7 [get_ports dp]							
#	set_property IOSTANDARD LVCMOS33 [get_ports dp]

set_property PACKAGE_PIN U2 [get_ports {enable_seg[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {enable_seg[0]}]
set_property PACKAGE_PIN U4 [get_ports {enable_seg[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {enable_seg[1]}]
set_property PACKAGE_PIN V4 [get_ports {enable_seg[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {enable_seg[2]}]
set_property PACKAGE_PIN W4 [get_ports {enable_seg[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {enable_seg[3]}]

##Buttons
set_property PACKAGE_PIN U18 [get_ports inicio]				
	set_property IOSTANDARD LVCMOS33 [get_ports inicio]
set_property PACKAGE_PIN T18 [get_ports contador_up]						
	set_property IOSTANDARD LVCMOS33 [get_ports contador_up]
set_property PACKAGE_PIN U17 [get_ports contador_down]						
        set_property IOSTANDARD LVCMOS33 [get_ports contador_down]

## Switches
set_property PACKAGE_PIN V17 [get_ports {freq_switch}]			
	set_property IOSTANDARD LVCMOS33 [get_ports {freq_switch}]

