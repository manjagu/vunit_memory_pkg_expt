onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_avalonmm_slave/clk_100
add wave -noupdate -radix unsigned /tb_avalonmm_slave/test_address
add wave -noupdate -radix unsigned /tb_avalonmm_slave/test_signal_write_data
add wave -noupdate -radix unsigned /tb_avalonmm_slave/test_signal_read_data
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {81359 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {199500 ps}
