# ROMs

MAME ROMs can be used but they are not directly distributed here.
Quickstart guide for Linux users:

Download Phoenix (Amstar) from some link, for example:

    http://www.mameroms.it/clone.php?rom=phoenix

unzip it in directory "phoenix_unzip"

    cd phoenix_unzip
    unzip ../phoenix.zip
    cd ..

run the conversion script

    ./make_phoenix_proms.sh

it will create VHDL files in directory "phoenix_unzip/roms"

    phoenix_prog.vhd
    prom_ic23.vhd
    prom_ic24.vhd
    prom_ic39.vhd
    prom_ic40.vhd
    prom_palette_ic40.vhd
    prom_palette_ic41.vhd

Proceed with FPGA synthesis.
