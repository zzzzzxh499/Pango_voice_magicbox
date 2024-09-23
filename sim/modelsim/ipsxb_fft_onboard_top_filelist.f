// Testbench
../../src/bench/top_tb.sv 
../../src/bench/hdmi_test/hdmi_test.v
../../src/bench/hdmi_test/pattern_vg.v
../../src/bench/hdmi_test/sync_vg.v
// TOP
../../src/rtl/top.v 
// design

../../src/rtl/ES7243E_reg_config.v
../../src/rtl/ES8156_reg_config.v
../../src/rtl/i2c_com.v
../../src/rtl/i2s_loop.v
../../src/rtl/iic_dri.v
../../src/rtl/ms7200_ctl.v
../../src/rtl/ms7210_ctl.v
../../src/rtl/ms72xx_ctl.v
../../src/rtl/pgr_i2s_rx.v
../../src/rtl/pgr_i2s_tx.v
../../src/rtl/spectrum.v
../../src/rtl/spectrogram.v
../../src/rtl/stream_ctrler.v
../../src/rtl/front_show.v
../../src/rtl/hann.v
../../src/rtl/key_ctl.v
../../src/rtl/sync_fifo.v
../../src/rtl/algorithm.v
../../src/rtl/girl2boy.v
../../src/rtl/boy2girl.v 
../../src/rtl/denoise.v
../../src/rtl/echo_des.v
../../src/rtl/round_signed.v
// ../../src/rtl/localbus/CRC4_D16.v
../../src/rtl/localbus/local_bus_slve_cis.v
// ../../src/rtl/localbus/uart_2dsp.v
../../src/rtl/localbus/ubus_top.v
../../src/rtl/separate1.v
../../src/rtl/separate2.v
../../src/rtl/Squares.v
../../src/rtl/filterbank.v
../../src/rtl/mul_add.v
../../src/rtl/logE.v
../../src/rtl/log2.v
../../src/rtl/DCT.v
../../src/rtl/lifter.v
../../src/rtl/mfcc.v
../../src/rtl/mfcc_avg.v
../../src/rtl/btn_deb_fix.v
../../src/rtl/voice_recgnize.v

// FFT TOP
// ../../ipsxe_fft_exp_rom.v 
../../ipsxb_fft_demo_r2_1024.v
// FFT CORE   
../../sim_lib/modelsim/ipsxb_fft_core_v1_0_simvpAll.vp     
../../rtl/drm_sdpram/ipsxb_fft_drm_sdpram_9k.v
../../rtl/drm_sdpram/rtl/ipsxb_fft_drm_sdpram_v1_8_9k.v
../../rtl/distram_sreg/ipsxe_fft_distram_sreg.v
../../rtl/distram_sreg/rtl/ipsxe_fft_distributed_shiftregister_v1_3.v
../../rtl/distram_sreg/rtl/ipsxe_fft_distributed_sdpram_v1_2.v
../../rtl/distram_sdpram/ipsxe_fft_distram_sdpram.v
// FIFO ip
../../pnr/example_design/ipcore/FIFO_1/FIFO_1.v
../../pnr/example_design/ipcore/FIFO_1/rtl/ipml_fifo_v1_6_FIFO_1.v
../../pnr/example_design/ipcore/FIFO_1/rtl/ipml_fifo_ctrl_v1_3.v
../../pnr/example_design/ipcore/FIFO_1/rtl/ipml_sdpram_v1_6_FIFO_1.v
//RAM HANN
../../pnr/example_design/ipcore/HANN_RAM/HANN_RAM.v
../../pnr/example_design/ipcore/HANN_RAM/rtl/ipml_spram_v1_5_HANN_RAM.v
//RAM ip
../../pnr/example_design/ipcore/RAM_1/RAM_1.v
../../pnr/example_design/ipcore/RAM_1/rtl/ipml_spram_v1_5_RAM_1.v
//PLL ip
../../pnr/example_design/ipcore/PLL/PLL.v
../../pnr/example_design/ipcore/PLL0/PLL0.v
//DPRAM ip
../../pnr/example_design/ipcore/DPRAM/DPRAM.v
../../pnr/example_design/ipcore/DPRAM/rtl/ipml_dpram_v1_6_DPRAM.v
//DRAM_spectrogram
../../pnr/example_design/ipcore/DRAM_spectrogram/DRAM_spectrogram.v
../../pnr/example_design/ipcore/DRAM_spectrogram/rtl/DRAM_spectrogram_init_param.v
../../pnr/example_design/ipcore/DRAM_spectrogram/rtl/ipml_dpram_v1_6_DRAM_spectrogram.v
//RGB LUT RAM
../../pnr/example_design/ipcore/R_LUT/R_LUT.v
../../pnr/example_design/ipcore/R_LUT/rtl/ipml_rom_v1_5_R_LUT.v
../../pnr/example_design/ipcore/R_LUT/rtl/ipml_spram_v1_5_R_LUT.v
../../pnr/example_design/ipcore/R_LUT/rtl/R_LUT_init_param.v
../../pnr/example_design/ipcore/G_LUT/G_LUT.v
../../pnr/example_design/ipcore/G_LUT/rtl/ipml_rom_v1_5_G_LUT.v
../../pnr/example_design/ipcore/G_LUT/rtl/ipml_spram_v1_5_G_LUT.v
../../pnr/example_design/ipcore/G_LUT/rtl/G_LUT_init_param.v
../../pnr/example_design/ipcore/B_LUT/B_LUT.v
../../pnr/example_design/ipcore/B_LUT/rtl/ipml_rom_v1_5_B_LUT.v
../../pnr/example_design/ipcore/B_LUT/rtl/ipml_spram_v1_5_B_LUT.v
../../pnr/example_design/ipcore/B_LUT/rtl/B_LUT_init_param.v
//HANN_LUT
../../pnr/example_design/ipcore/HANN_LUT/HANN_LUT.v
../../pnr/example_design/ipcore/HANN_LUT/rtl/ipml_spram_v1_5_HANN_LUT.v
../../pnr/example_design/ipcore/HANN_LUT/rtl/HANN_LUT_init_param.v
//MUL16x16
../../pnr/example_design/ipcore/MUL16x16/MUL16x16.v
../../pnr/example_design/ipcore/MUL16x16/rtl/ipml_mult_v1_2_MUL16x16.v
//MUL_Add
../../pnr/example_design/ipcore/MUL_Add/MUL_Add.v
../../pnr/example_design/ipcore/MUL_Add/rtl/ipml_multadd_v1_1_Mul_Add.v
//mul
../../pnr/example_design/ipcore/mul/mul.v
../../pnr/example_design/ipcore/mul/rtl/ipml_mult_v1_2_mul.v
//LUT
../../pnr/example_design/ipcore/LUT_2GIRL/LUT_2GIRL.v
../../pnr/example_design/ipcore/LUT_2GIRL/rtl/ipml_spram_v1_5_LUT_2GIRL.v
../../pnr/example_design/ipcore/LUT_2GIRL/rtl/LUT_2GIRL_init_param.v

../../pnr/example_design/ipcore/LUT_2BOY/LUT_2BOY.v
../../pnr/example_design/ipcore/LUT_2BOY/rtl/ipml_spram_v1_5_LUT_2BOY.v
../../pnr/example_design/ipcore/LUT_2BOY/rtl/LUT_2BOY_init_param.v
../../pnr/example_design/ipcore/Sperate_door/Sperate_door.v
../../pnr/example_design/ipcore/Sperate_door/rtl/ipml_sdpram_v1_6_Sperate_door.v
../../pnr/example_design/ipcore/Sperate_door/rtl/Sperate_door_init_param.v

//LUT1
../../pnr/example_design/ipcore/FBANK_LUT1/FBANK_LUT1.v
../../pnr/example_design/ipcore/FBANK_LUT1/rtl/ipml_spram_v1_5_FBANK_LUT1.v
../../pnr/example_design/ipcore/FBANK_LUT1/rtl/FBANK_LUT1_init_param.v

//LUT2
../../pnr/example_design/ipcore/FBANK_LUT2/FBANK_LUT2.v
../../pnr/example_design/ipcore/FBANK_LUT2/rtl/ipml_spram_v1_5_FBANK_LUT2.v
../../pnr/example_design/ipcore/FBANK_LUT2/rtl/FBANK_LUT2_init_param.v

//MUL16x16
../../pnr/example_design/ipcore/MUL16x16/MUL16x16.v
../../pnr/example_design/ipcore/MUL16x16/rtl/ipml_mult_v1_2_MUL16x16.v

//MUL16x16_signed
../../pnr/example_design/ipcore/mul16x16_signed/mul16x16_signed.v
../../pnr/example_design/ipcore/mul16x16_signed/rtl/ipml_mult_v1_2_mul16x16_signed.v

//MUL55x16
../../pnr/example_design/ipcore/mul55x16/mul55x16.v
../../pnr/example_design/ipcore/mul55x16/rtl/ipml_mult_v1_2_mul55x16.v

//MUL26x16
../../pnr/example_design/ipcore/MUL26x16/MUL26x16.v
../../pnr/example_design/ipcore/MUL26x16/rtl/ipml_mult_v1_2_MUL26x16.v

//MUL17x17
../../pnr/example_design/ipcore/MUL17x17/MUL17x17.v
../../pnr/example_design/ipcore/MUL17x17/rtl/ipml_mult_v1_2_MUL17x17.v

../../pnr/example_design/ipcore/div1024/div1024.v
../../pnr/example_design/ipcore/div1024/rtl/ipml_spram_v1_5_div1024.v
../../pnr/example_design/ipcore/div1024/rtl/div1024_init_param.v

//FIFO
../../pnr/example_design/ipcore/logfbe_buff/logfbe_buff.v
../../pnr/example_design/ipcore/logfbe_buff/rtl/ipm_distributed_fifo_ctr_v1_0.v
../../pnr/example_design/ipcore/logfbe_buff/rtl/ipm_distributed_fifo_v1_2_logfbe_buff.v
../../pnr/example_design/ipcore/logfbe_buff/rtl/ipm_distributed_sdpram_v1_2_logfbe_buff.v