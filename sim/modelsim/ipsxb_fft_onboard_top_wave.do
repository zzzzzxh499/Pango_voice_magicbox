onerror {resume}
quietly WaveActivateNextPane {} 0  

add wave -noupdate -divider {logE}

add wave -noupdate /top_tb/top/voice_recgnize/*


#add wave -noupdate /top_tb/top/mfcc_u/logE/*

#add wave -noupdate -divider {algorithm}
#add wave -noupdate /top_tb/top/algorithm/ram_addr
#add wave -noupdate /top_tb/top/algorithm/freq_data
#add wave -noupdate /top_tb/top/algorithm/freq_valid
#add wave -noupdate /top_tb/top/algorithm/freq_tlast
#add wave -noupdate -divider {girl2boy}
#add wave -noupdate /top_tb/top/algorithm/boy2girl_u/*

# add wave -noupdate /top_tb/top/u_fft_wrapper/xn_fft_mode

# add wave -noupdate -divider {clk_rst}
# add wave -noupdate /top_tb/top/stream_ctrler/rst_n
# add wave -noupdate /top_tb/top/stream_ctrler/sclk
# add wave -noupdate /top_tb/top/stream_ctrler/i_aclk

# add wave -noupdate -divider {org_data}
# add wave -noupdate /top_tb/test_data_l

# add wave -noupdate -divider {iis_interface}
# add wave -noupdate /top_tb/top/stream_ctrler/l_lvd
# add wave -noupdate /top_tb/top/stream_ctrler/rx_data
# add wave -noupdate /top_tb/top/stream_ctrler/l_lvd_out
# add wave -noupdate /top_tb/top/stream_ctrler/tx_data

# add wave -noupdate -divider {fft_interface_ctrl}
# add wave -noupdate /top_tb/top/stream_ctrler/o_axi4s_cfg_tvalid
# add wave -noupdate /top_tb/top/stream_ctrler/o_axi4s_cfg_tdata

# add wave -noupdate -divider {fft_interface_out}
# add wave -noupdate /top_tb/top/stream_ctrler/i_axi4s_data_tready
# add wave -noupdate /top_tb/top/stream_ctrler/o_axi4s_data_tvalid
# add wave -noupdate /top_tb/top/stream_ctrler/o_axi4s_data_tdata
# add wave -noupdate /top_tb/top/stream_ctrler/o_axi4s_data_tlast

# add wave -noupdate -divider {fft_interface_in}
# add wave -noupdate /top_tb/top/stream_ctrler/i_axi4s_data_tvalid
# add wave -noupdate /top_tb/top/stream_ctrler/i_axi4s_data_tdata
# add wave -noupdate /top_tb/top/stream_ctrler/i_axi4s_data_tlast

# add wave -noupdate -divider {algorithm}
# add wave -noupdate /top_tb/top/stream_ctrler/freq_data
# add wave -noupdate /top_tb/top/stream_ctrler/freq_valid
# add wave -noupdate /top_tb/top/stream_ctrler/freq_last

# add wave -noupdate -divider {state_ctrl}
# add wave -noupdate /top_tb/top/stream_ctrler/state
# add wave -noupdate /top_tb/top/stream_ctrler/rd_addr
# add wave -noupdate /top_tb/top/stream_ctrler/fft_mode

# add wave -noupdate -divider {fifo_rx_ctrl}
# add wave -noupdate /top_tb/top/stream_ctrler/wr_en
# add wave -noupdate /top_tb/top/stream_ctrler/rx_data
# add wave -noupdate /top_tb/top/stream_ctrler/almost_full
# add wave -noupdate /top_tb/top/stream_ctrler/almost_empty
# add wave -noupdate /top_tb/top/stream_ctrler/rd_en1
# add wave -noupdate /top_tb/top/stream_ctrler/rx_data_fifo


# add wave -noupdate -divider {fifo_tx_ctrl}
# add wave -noupdate /top_tb/top/stream_ctrler/wr_en2
# add wave -noupdate /top_tb/top/stream_ctrler/i_axi4s_data_tdata[14:0]

#add wave -noupdate -divider {spectrogram}
#add wave -noupdate /top_tb/top/spectrogram_0/*


TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2028741734 ps} 0}
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
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {1140304578 ps}
