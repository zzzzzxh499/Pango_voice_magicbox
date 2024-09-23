第八届集创赛紫光同创赛道国二作品
FPGA部分：声音降噪（滤波器），变声（频域升降采样+滤波器），人声音乐分离（掩膜法），声纹识别（mfcc+欧氏距离），回声消除（自适应滤波器），以太网传输
psd2022.2-SP1-Lite
modelsim 10.5
可仿真，可下载比特流，UART BUS青春版


--/pnr											    // 综合布局布线工程
	-- /example_design							    // FFT IP Example Design的综合布局布线工程文件及约束文件
		-- ipsxb_fft_onboard_top.pds				// Example Design PDS工程文件
		-- ipsxb_fft_onboard_top.fdc				// Example Design PDS约束文件
--/rtl											    // FFT IP Core包含的代码文件
	-- /distram_sdpram							    // FFT IP调用的分布式RAM SDPRAM IP文件夹
	-- /distram_sreg								// FFT IP调用的分布式RAM移位寄存器IP文件夹
	-- /drm_sdpram								    // FFT IP调用的DRM SDPRAM IP文件夹
	-- /synplify									// FFT IP Core加密代码文件夹，包含的代码文件仅用于综合
--/sim											    // Example Design simulation目录
	--modelsim									    // ModelSim仿真运行的.do文件及filelist
		-- ipsxb_fft_onboard_top_sim.do			    // 用于Example Design仿真运行的.do文件
		-- ipsxb_fft_onboard_top_filelist.f		    // 用于Example Design仿真的filelist，被ipsxe_fft_onboard_top_sim.do调用
		-- ipsxb_fft_onboard_top_wave.do			// 用于Example Design仿真运行的波形加载.do文件，被ipsxe_fft_onboard_top_sim.do调用
		-- sim.bat								    // 用于Example Design运行ipsxe_fft_onboard_top_sim.do的脚本
	--mcode											// 部分算法的matlab模型，激励文件
	-- DCT_f.txt									// DCT 查找表
	-- log2_f.txt									// log函数查找表
	-- fbank1.dat									// fbank查找表1
	-- fbank2.dat									// fbank查找表2
	-- hann_lut.dat									// 汉明窗查找表
	-- lut_2boy.dat									// 女变男滤波器
	-- lut_2girl.dat								// 男变女滤波器
	-- sound_data.dat								// 声音激励
	-- code_block.m									// 没什么用
	-- girl2boy_v3.m								// 变声mcode
	-- m4a_2dat.m									// 根据音频文件生成激励数据
	-- myMFCC.m										// mfcc mcode
	-- read_data.m									// 对比fft ip结果
	-- test_log.m									// 硬件计算log
--/sim_lib										 	// FFT IP Core加密代码文件夹，包含的代码文件仅用于仿真
	-- /modelsim									// 适用于ModelSim 10.2c和VCS 2020.03sp2的IP Core加密代码 _sim.vp
--/src
	--bench
	--hdmi_test										// hdmi激励源
	--top_tb.sv										// 仿真顶层
	--rtl											// 用户源代码
	--x.dat											// 语谱图颜色查找表
--ipsxb_fft_demo_xxx.v							    // IP的wrapper文件