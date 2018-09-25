onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib hard_rom_opt

do {wave.do}

view wave
view structure
view signals

do {hard_rom.udo}

run -all

quit -force
