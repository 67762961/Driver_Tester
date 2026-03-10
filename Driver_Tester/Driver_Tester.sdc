#************************************************************
# THIS IS A WIZARD-GENERATED FILE.                           
#
# Version 13.1.0 Build 162 10/23/2013 SJ Full Version
#
#************************************************************

# Copyright (C) 1991-2013 Altera Corporation
# Your use of Altera Corporation's design tools, logic functions 
# and other software and tools, and its AMPP partner logic 
# functions, and any output files from any of the foregoing 
# (including device programming or simulation files), and any 
# associated documentation or information are expressly subject 
# to the terms and conditions of the Altera Program License 
# Subscription Agreement, Altera MegaCore Function License 
# Agreement, or other applicable license agreement, including, 
# without limitation, that your use is for the sole purpose of 
# programming logic devices manufactured by Altera and sold by 
# Altera or its authorized distributors.  Please refer to the 
# applicable agreement for further details.



# 时钟定义
create_clock -name "clk" -period 20.000ns [get_ports {clk}]
create_clock -period 100.000ns [get_nets Clk_5]

# 但可以确保复位信号正确应用
set_input_delay -clock [get_clocks clk] 0 [get_ports rst_n]

# 输入信号定义
set_input_delay -clock [get_clocks clk] 2 [get_ports ckey0]
set_input_delay -clock [get_clocks clk] 2 [get_ports ckey1]
set_input_delay -clock [get_clocks clk] 2 [get_ports ckey2]
set_input_delay -clock [get_clocks clk] 2 [get_ports ckey3]

# 输出信号定义
set_output_delay -clock [get_clocks clk] 2 [get_ports led_d0]
set_output_delay -clock [get_clocks clk] 2 [get_ports led_d1]
set_output_delay -clock [get_clocks clk] 2 [get_ports led_d2]
set_output_delay -clock [get_clocks clk] 2 [get_ports led_d3]
set_output_delay -clock [get_clocks clk] 2 [get_ports led_d4]
set_output_delay -clock [get_clocks clk] 2 [get_ports led_d5]
set_output_delay -clock [get_clocks clk] 2 [get_ports led_d6]
set_output_delay -clock [get_clocks clk] 2 [get_ports led_d7]

set_output_delay -clock [get_clocks clk] 2 [get_ports PWMO1]
set_output_delay -clock [get_clocks clk] 2 [get_ports PWMO2]