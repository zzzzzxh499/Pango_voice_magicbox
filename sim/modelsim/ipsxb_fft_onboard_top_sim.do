file delete -force work
file delete -force vsim_ipsxb_fft_onboard_top.log
vlib  work
vmap  work work
vlog +define+SIMULATION -incr -sv \
C:/pango/PDS_2022.2-SP1-Lite/arch/vendor/pango/verilog/simulation/GTP_APM_E1.v \
C:/pango/PDS_2022.2-SP1-Lite/arch/vendor/pango/verilog/simulation/GTP_DRM18K_E1.v \
C:/pango/PDS_2022.2-SP1-Lite/arch/vendor/pango/verilog/simulation/GTP_DRM18K.v \
C:/pango/PDS_2022.2-SP1-Lite/arch/vendor/pango/verilog/simulation/GTP_DRM9K.v \
C:/pango/PDS_2022.2-SP1-Lite/arch/vendor/pango/verilog/simulation/GTP_GRS.v \
C:/pango/PDS_2022.2-SP1-Lite/arch/vendor/pango/verilog/simulation/GTP_PLL_E3.v \
-f ./ipsxb_fft_onboard_top_filelist.f -l vlog.log
vsim {-voptargs=+acc} -suppress 12110 work.top_tb -l vsim.log
do ipsxb_fft_onboard_top_wave.do
run -all
