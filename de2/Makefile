###################################################################
# Project Configuration: 
# 
# Specify the name of the design (project) and the Quartus II
# Settings File (.qsf)
###################################################################

PROJECT = project
TOP_LEVEL_ENTITY = phoenix_de2
ASSIGNMENT_FILES = $(PROJECT).qpf $(PROJECT).qsf

###################################################################
# Part, Family, Boardfile
FAMILY = "Cyclone II"
PART = EP2C35F672C6
BOARDFILE = de2.board
CONFIG_DEVICE = EPCS64
SERIAL_FLASH_LOADER_DEVICE = EP4CE6
# OPENOCD_INTERFACE=interface/altera-usb-blaster.cfg
# OPENOCD_INTERFACE=ftdi-fpu1.ocd
OPENOCD_INTERFACE=remote.ocd

###################################################################
#
# Quartus shell environment vars
#
###################################################################

quartus_env ?= . ./quartus_env.sh

# include makefile which does it all
include altera.mk

###################################################################
# Setup your sources here
SRCS = \
top/phoenix_de2.vhd \
clocks/clk_50_250_25MHz.vhd \
../rtl_dar/gen_ram.vhd \
../rtl_dar/io_ps2_keyboard.vhd \
../rtl_dar/kbd_joystick.vhd \
../rtl_dar/phoenix_effect1.vhd \
../rtl_dar/phoenix_effect2.vhd \
../rtl_dar/phoenix_effect3.vhd \
../rtl_dar/phoenix_music.vhd \
../rtl_dar/phoenix_video.vhd \
../rtl_dar/wm8731_dac.vhd \
../rtl_T80/T80_ALU.vhd \
../rtl_T80/T80_MCode.vhd \
../rtl_T80/T80_Pack.vhd \
../rtl_T80/T80_Reg.vhd \
../rtl_T80/T80.vhd \
../rtl_T80/T80s.vhd \
../rtl_T80/T8080se.vhd \
../tools/phoenix_unzip/roms/phoenix_prog.vhd \
../tools/phoenix_unzip/roms/prom_ic23.vhd \
../tools/phoenix_unzip/roms/prom_ic24.vhd \
../tools/phoenix_unzip/roms/prom_ic39.vhd \
../tools/phoenix_unzip/roms/prom_ic40.vhd \
../tools/phoenix_unzip/roms/prom_palette_ic40.vhd \
../tools/phoenix_unzip/roms/prom_palette_ic41.vhd \
../rtl_vga/phoenix.vhd \
../rtl_vga/phoenix_video_vga.vhd \
../rtl_vga/vga.vhd \
../rtl_vga/hdmi/vga2dvid.vhd \
../rtl_vga/hdmi/tmds_encoder.vhd \
../rtl_vga/hdmi_out.vhd \
../rtl_vga/hdmi-audio/av_hdmi.vhd \
../rtl_vga/hdmi-audio/hdmidataencoder.v \
../rtl_vga/hdmi-audio/encoder.vhd \
../rtl_vga/altera/cyclone4/serializer.vhd \
../rtl_vga/hdmi-audio/hdmidelay.vhd \
../rtl_vga/hdmi-audio/serializer_generic.vhd \
