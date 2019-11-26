# ******* project, board and chip name *******
PROJECT = phoenix
BOARD = ulx3s
# 12 25 45 85
FPGA_SIZE = 25

FPGA_PACKAGE = 6bg381c
# config flash: 1:SPI (standard), 4:QSPI (quad)
FLASH_SPI = 4
# chip: is25lp032d is25lp128f s25fl164k
FLASH_CHIP = is25lp128f

# ******* if programming with OpenOCD *******
# using local latest openocd until in linux distribution
OPENOCD=openocd_ft232r
# default onboard usb-jtag
OPENOCD_INTERFACE=$(SCRIPTS)/ft231x.ocd
# ulx3s-jtag-passthru
#OPENOCD_INTERFACE=$(SCRIPTS)/ft231x2.ocd
# ulx2s
#OPENOCD_INTERFACE=$(SCRIPTS)/ft232r.ocd
# external jtag
#OPENOCD_INTERFACE=$(SCRIPTS)/ft2232.ocd

# ******* design files *******
CONSTRAINTS = ../constraints/ulx3s_v20_segpdi.lpf
TOP_MODULE = phoenix_ulx3s
TOP_MODULE_FILE = top/$(TOP_MODULE).vhd

VHDL_FILES = \
  $(TOP_MODULE_FILE) \
  clocks/clk_25_125_68_6_25.vhd \
  ../../../rtl_dar/gen_ram.vhd \
  ../../../rtl_dar/io_ps2_keyboard.vhd \
  ../../../rtl_dar/kbd_joystick.vhd \
  ../../../rtl_dar/phoenix_effect1.vhd \
  ../../../rtl_dar/phoenix_effect2.vhd \
  ../../../rtl_dar/phoenix_effect3.vhd \
  ../../../rtl_dar/phoenix_music.vhd \
  ../../../rtl_dar/phoenix_video.vhd \
  ../../../rtl_dar/wm8731_dac.vhd \
  ../../../rtl_T80/T80_ALU.vhd \
  ../../../rtl_T80/T80_MCode.vhd \
  ../../../rtl_T80/T80_Pack.vhd \
  ../../../rtl_T80/T80_Reg.vhd \
  ../../../rtl_T80/T80.vhd \
  ../../../rtl_T80/T80s.vhd \
  ../../../rtl_T80/T8080se.vhd \
  ../../../rtl_T80/T16450.vhd \
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
  ../../../rtl_emard/spdif/spdif_tx.vhd \
  ../../../rtl_emard/usb/usbhid/usbhid_report_decoder_saitek_joystick.vhd \
  ../../../rtl_emard/usb/usbhid/report_decoded_pack_generic.vhd \
  ../../../rtl_emard/usb/usbhost/usbh_setup_pack.vhd \
  ../../../rtl_emard/usb/usbhost/usbh_host_hid.vhd \
  ../../../rtl_emard/usb/usbhost/usbh_sie_vhdl.vhd \
  ../../../rtl_emard/usb/usb11_phy_vhdl/usb_phy.vhd \
  ../../../rtl_emard/usb/usb11_phy_vhdl/usb_rx_phy_48MHz.vhd \
  ../../../rtl_emard/usb/usb11_phy_vhdl/usb_rx_phy_emard.vhd \
  ../../../rtl_emard/usb/usb11_phy_vhdl/usb_tx_phy.vhd \

#  ../../../rtl_emard/vga/hdmi_out.vhd \
#  ../../../rtl_emard/vga/hdmi/ddr_dvid_out_se.vhd \
 ../../../rtl_emard/vga/lattice/ecp5u/ddr_out.vhd \
   
VERILOG_FILES = \
  ../../../rtl_emard/usb/usbhost/usbh_sie.v \
  ../../../rtl_emard/usb/usbhost/usbh_crc5.v \
  ../../../rtl_emard/usb/usbhost/usbh_crc16.v \


SCRIPTS = ../scripts
include $(SCRIPTS)/trellis_path.mk
include $(SCRIPTS)/diamond_path.mk
include $(SCRIPTS)/diamond_main.mk
