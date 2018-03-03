project = miniSpartan6-plus
vendor = xilinx
family = spartan6
MODEL ?= xc6slx25
part = ${MODEL}-ftg256-3 # last number -3 is speed grade
flashsize = 8192 # KB (kilobytes) - SPI flash device is M25P40
top_module = phoenix_scarab
isedir = /opt/Xilinx/ISE/14.7/ISE_DS
xil_env = . $(isedir)/settings64.sh
SHELL = /bin/bash
# openocd_interface = interface/altera-usb-blaster.cfg
# openocd_interface = ../include/ft2232-fpu1.ocd
openocd_interface = programmer/ft2232-generic.ocd
xc3sprog_interface = ftdi

include ../include/xilinx.mk

vfiles = \
../../../rtl_emard/vga/hdmi-audio/hdmidataencoder.v \

vhdfiles = \
top/phoenix_scarab.vhd \
clocks/clk_50_50_250_25_11MHz.vhd \
../../../rtl_dar/gen_ram.vhd \
../../../rtl_dar/io_ps2_keyboard.vhd \
../../../rtl_dar/kbd_joystick.vhd \
../../../rtl_dar/phoenix_effect1.vhd \
../../../rtl_dar/phoenix_effect2.vhd \
../../../rtl_dar/phoenix_effect3.vhd \
../../../rtl_dar/phoenix_music.vhd \
../../../rtl_dar/phoenix_video.vhd \
../../../rtl_dar/dac.vhd \
../../../rtl_T80/T80_ALU.vhd \
../../../rtl_T80/T80_MCode.vhd \
../../../rtl_T80/T80_Pack.vhd \
../../../rtl_T80/T80_Reg.vhd \
../../../rtl_T80/T80.vhd \
../../../rtl_T80/T80s.vhd \
../../../rtl_T80/T8080se.vhd \
../../../tools/phoenix_unzip/roms/phoenix_prog.vhd \
../../../tools/phoenix_unzip/roms/prom_ic23.vhd \
../../../tools/phoenix_unzip/roms/prom_ic24.vhd \
../../../tools/phoenix_unzip/roms/prom_ic39.vhd \
../../../tools/phoenix_unzip/roms/prom_ic40.vhd \
../../../tools/phoenix_unzip/roms/prom_palette_ic40.vhd \
../../../tools/phoenix_unzip/roms/prom_palette_ic41.vhd \
../../../rtl_emard/osd/osd.vhd \
../../../rtl_emard/osd/char_rom.vhd \
../../../rtl_emard/vga/phoenix.vhd \
../../../rtl_emard/vga/phoenix_video_vga.vhd \
../../../rtl_emard/vga/vga.vhd \
../../../rtl_emard/vga/hdmi/vga2dvid.vhd \
../../../rtl_emard/vga/hdmi/tmds_encoder.vhd \
../../../rtl_emard/vga/hdmi-audio/av_hdmi.vhd \
../../../rtl_emard/vga/hdmi-audio/encoder.vhd \
../../../rtl_emard/vga/hdmi-audio/hdmidelay.vhd \
../../../rtl_emard/vga/hdmi-audio/serializer_generic.vhd \
../../../rtl_emard/vga/altera/cyclone4/serializer.vhd \
../../../rtl_emard/vga/xilinx/xc6/hdmi_out_xc6.vhd \

