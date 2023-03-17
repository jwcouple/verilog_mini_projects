#!/bin/bash -f
# ****************************************************************************
# Vivado (TM) v2020.1 (64-bit)
#
# Filename    : elaborate.sh
# Simulator   : Xilinx Vivado Simulator
# Description : Script for elaborating the compiled design
#
# Generated by Vivado on Fri Mar 17 14:13:25 PDT 2023
# SW Build 2902540 on Wed May 27 19:54:35 MDT 2020
#
# Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
#
# usage: elaborate.sh
#
# ****************************************************************************
set -Eeuo pipefail
echo "xelab -wto 7ad585d8f386467ab5c91725ac5ce52d --incr --debug typical --relax --mt 8 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -L xpm --snapshot uart_top_TB_behav xil_defaultlib.uart_top_TB xil_defaultlib.glbl -log elaborate.log"
xelab -wto 7ad585d8f386467ab5c91725ac5ce52d --incr --debug typical --relax --mt 8 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -L xpm --snapshot uart_top_TB_behav xil_defaultlib.uart_top_TB xil_defaultlib.glbl -log elaborate.log

