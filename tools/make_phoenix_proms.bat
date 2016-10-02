make_vhdl_prom phoenix_unzip\b1-ic39.3b   prom_ic39.vhd
make_vhdl_prom phoenix_unzip\b2-ic40.4b   prom_ic40.vhd
make_vhdl_prom phoenix_unzip\ic23.3d      prom_ic23.vhd
make_vhdl_prom phoenix_unzip\ic24.4d      prom_ic24.vhd
make_vhdl_prom phoenix_unzip\mmi6301.ic40 prom_palette_ic40.vhd
make_vhdl_prom phoenix_unzip\mmi6301.ic41 prom_palette_ic41.vhd

copy /B phoenix_unzip\ic45 + phoenix_unzip\ic46 + phoenix_unzip\ic47 + phoenix_unzip\ic48 + phoenix_unzip\h5-ic49.5a + phoenix_unzip\h6-ic50.6a + phoenix_unzip\h7-ic51.7a + phoenix_unzip\h8-ic52.8a phoenix_prog.bin
make_vhdl_prom phoenix_prog.bin phoenix_prog.vhd