
//////////////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2022 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
//
// THE SOURCE CODE CONTAINED HEREIN IS PROPRIETARY TO PANGO MICROSYSTEMS, INC.
// IT SHALL NOT BE REPRODUCED OR DISCLOSED IN WHOLE OR IN PART OR USED BY
// PARTIES WITHOUT WRITTEN AUTHORIZATION FROM THE OWNER.
//
//////////////////////////////////////////////////////////////////////////////

module ipsxb_fft_demo_r2_1024 ( 
    i_aclk                 ,
    
    i_axi4s_data_tvalid    ,
    i_axi4s_data_tdata     ,
    i_axi4s_data_tlast     ,
    o_axi4s_data_tready    ,
        
    i_axi4s_cfg_tvalid     ,
    i_axi4s_cfg_tdata      ,
    
    o_axi4s_data_tvalid    ,
    o_axi4s_data_tdata     ,
    o_axi4s_data_tlast     ,
    o_axi4s_data_tuser     ,
    
    o_alm                  ,
    o_stat
);

localparam  AS_LATENCY        = 2       ; 
localparam  RAM_LATENCY       = 2       ; 

localparam  CLKDIV_EN         = ("FALSE" == "TRUE") ? 1 : 0;

localparam  RST_EN            = ("FALSE" == "TRUE") ? 1 : 0;

localparam  FFT_ARCH          = ("Radix-2 Burst" == "Radix-2 Burst") ? 1 : 0; 

localparam  LOG2_FFT_LEN      = ("1024" == "8"    ) ? 3  :
                                ("1024" == "16"   ) ? 4  :
                                ("1024" == "32"   ) ? 5  :
                                ("1024" == "64"   ) ? 6  :
                                ("1024" == "128"  ) ? 7  :
                                ("1024" == "256"  ) ? 8  :
                                ("1024" == "512"  ) ? 9  :
                                ("1024" == "1024" ) ? 10 :
                                ("1024" == "2048" ) ? 11 :
                                ("1024" == "4096" ) ? 12 :
                                ("1024" == "8192" ) ? 13 :
                                ("1024" == "16384") ? 14 :
                                ("1024" == "32768") ? 15 :
                                                    16 ;

localparam  OUTPUT_ORDER      = ("Natural Order" == "Natural Order") ? 1 : 0; 

localparam  SCALE_MODE        = ("Unscaled" == "Block Floating Point") ? 1 : 0; 
 
localparam  ROUND_MODE        = ("Convergent Rounding" == "Convergent Rounding") ? 1 : 0; 

localparam  INPUT_WIDTH       = 16;
localparam  TWIDDLE_WIDTH     = 16;
localparam  USE_DRM_NUM       = 0; 

localparam  OUTPUT_RAM_TYPE   = ("DRM" == "DRM") ? 1 : 0; 

localparam  BURST_DATA_RAM_TYPE    = ("DRM" == "DRM") ? 1 : 0; 

localparam  BURST_TWIDDLE_RAM_TYPE    = ("DRM" == "DRM") ? 1 : 0; 


localparam  DATAIN_BYTE_NUM   = ((INPUT_WIDTH%8)==0) ? INPUT_WIDTH/8 : INPUT_WIDTH/8 + 1;
localparam  DATAIN_WIDTH      = DATAIN_BYTE_NUM*8;

localparam  UNSCALED_WIDTH    = INPUT_WIDTH + LOG2_FFT_LEN + 1;
localparam  OUTPUT_WIDTH      = SCALE_MODE ? INPUT_WIDTH : UNSCALED_WIDTH;
localparam  DATAOUT_BYTE_NUM  = ((OUTPUT_WIDTH%8)==0) ? OUTPUT_WIDTH/8 : OUTPUT_WIDTH/8 + 1;
localparam  DATAOUT_WIDTH     = DATAOUT_BYTE_NUM * 8;
localparam  USER_BYTE_NUM     = ((LOG2_FFT_LEN%8)==0) ? LOG2_FFT_LEN/8 + 1: LOG2_FFT_LEN/8 + 2; // blk_exp and index
localparam  USER_WIDTH        = USER_BYTE_NUM * 8;

input                         i_aclk             ;

input                         i_axi4s_data_tvalid;
input  [DATAIN_WIDTH*2-1:0]   i_axi4s_data_tdata ;
input                         i_axi4s_data_tlast ;
output                        o_axi4s_data_tready;
input                         i_axi4s_cfg_tvalid ;
input                         i_axi4s_cfg_tdata  ;
output                        o_axi4s_data_tvalid;
output [DATAOUT_WIDTH*2-1:0]  o_axi4s_data_tdata ;
output                        o_axi4s_data_tlast ;
output [USER_WIDTH-1:0]       o_axi4s_data_tuser ;
output [2:0]                  o_alm              ;
output                        o_stat             ;

wire                          xn_fft_mode        ;
wire   [INPUT_WIDTH-1:0]      xn_re              ;
wire   [INPUT_WIDTH-1:0]      xn_im              ;
wire   [LOG2_FFT_LEN-1:0]     xn_index           ;
wire                          xk_frame_output    ;
wire   [OUTPUT_WIDTH-1:0]     xk_re              ;
wire   [OUTPUT_WIDTH-1:0]     xk_im              ;
wire   [LOG2_FFT_LEN-1:0]     xk_index           ;
wire   [4:0]                  xk_blk_exp         ;

wire                          xn_sof             ;
wire                          xn_frame_input     ;
wire                          fft_end            ;
wire   [2:0]                  input_alm          ;
wire                          input_stat         ;

wire                          clken              ;
wire                          rstn               ;

 
assign clken = 1'b1;
 
assign rstn = 1'b1;


ipsxe_fft_cfg_ctrl_v1_0 u_cfg_ctrl (
    .i_clk                    (i_aclk             ),
    .i_clken                  (clken              ),
    .i_rstn                   (rstn               ),
    .i_cfg_data               (i_axi4s_cfg_tdata  ), 
    .i_cfg_vld                (i_axi4s_cfg_tvalid ),
    .i_datain_frame_started   (o_stat             ),
    .o_fft_mode               (xn_fft_mode        )
);

generate
    if (FFT_ARCH == 0) begin: use_pipeline
        ipsxe_fft_pipeline_input_ctrl_v1_0 #(
            .LOG2_FFT_LEN       (LOG2_FFT_LEN       ),
            .INPUT_WIDTH        (INPUT_WIDTH        )
        ) u_pipeline_input_ctrl (
            .i_clk              (i_aclk             ),
            .i_clken            (clken              ),
            .i_rstn             (rstn               ),
            .i_datain           (i_axi4s_data_tdata ),
            .i_datain_vld       (i_axi4s_data_tvalid),
            .i_datain_last      (i_axi4s_data_tlast ),
            .o_re               (xn_re              ),
            .o_im               (xn_im              ),
            .o_index            (xn_index           ),
            .o_input_alm        (input_alm          ),
            .o_input_stat       (input_stat         )
        );
        
        ipsxb_fft_pipeline_core_v1_0 #(
            .AS_LATENCY         (AS_LATENCY         ),
            .RAM_LATENCY        (RAM_LATENCY        ),
            .LOG2_FFT_LEN       (LOG2_FFT_LEN       ),
            .OUTPUT_ORDER       (OUTPUT_ORDER       ),
            .SCALE_MODE         (SCALE_MODE         ),
            .ROUND_MODE         (ROUND_MODE         ),
            .TWIDDLE_WIDTH      (TWIDDLE_WIDTH      ),
            .INPUT_WIDTH        (INPUT_WIDTH        ),
            .USE_DRM_NUM        (USE_DRM_NUM        ),
            .OUTPUT_RAM_TYPE    (OUTPUT_RAM_TYPE    )
        ) u_pipeline_core (          
            .i_clk              (i_aclk             ),
            .i_clken            (clken              ),
            .i_rstn             (rstn               ),
            .i_index            (xn_index           ),
            .i_fft_mode         (xn_fft_mode        ),
            .i_re               (xn_re              ),
            .i_im               (xn_im              ),
            .o_frame_output     (xk_frame_output    ),
            .o_index            (xk_index           ),
            .o_re               (xk_re              ),
            .o_im               (xk_im              ),
            .o_blk_exp          (xk_blk_exp         )
        );
        
        assign o_axi4s_data_tready = 1'b1;
    end    
    else begin: use_radix2_burst
        ipsxe_fft_burst_input_ctrl_v1_0 #(
            .LOG2_FFT_LEN       (LOG2_FFT_LEN       ),
            .INPUT_WIDTH        (INPUT_WIDTH        )
        ) u_burst_input_ctrl (
            .i_clk              (i_aclk             ),
            .i_clken            (clken              ),
            .i_rstn             (rstn               ),
            .i_datain           (i_axi4s_data_tdata ),
            .i_datain_vld       (i_axi4s_data_tvalid),
            .i_datain_last      (i_axi4s_data_tlast ),
            .o_datain_rdy       (o_axi4s_data_tready),
            .i_fft_end          (fft_end            ),
            .o_re               (xn_re              ),
            .o_im               (xn_im              ),
            .o_index            (xn_index           ),
            .o_sof              (xn_sof             ),
            .o_frame_input      (xn_frame_input     ),
            .o_input_alm        (input_alm          ),
            .o_input_stat       (input_stat         )
        );
        
        ipsxb_fft_radix2_burst_core_v1_0 #(
            .AS_LATENCY         (AS_LATENCY         ),
            .RAM_LATENCY        (RAM_LATENCY        ),
            .LOG2_FFT_LEN       (LOG2_FFT_LEN       ),
            .OUTPUT_ORDER       (OUTPUT_ORDER       ),
            .SCALE_MODE         (SCALE_MODE         ),
            .ROUND_MODE         (ROUND_MODE         ),
            .TWIDDLE_WIDTH      (TWIDDLE_WIDTH      ),
            .INPUT_WIDTH        (INPUT_WIDTH        ),
            .BURST_DATA_RAM_TYPE(BURST_DATA_RAM_TYPE),
            .BURST_TWIDDLE_RAM_TYPE (BURST_TWIDDLE_RAM_TYPE)
        ) u_radix2_burst_core (          
            .i_clk              (i_aclk             ),
            .i_clken            (clken              ),
            .i_rstn             (rstn               ),
            .i_sof              (xn_sof             ),
            .i_frame_input      (xn_frame_input     ),
            .i_index            (xn_index           ),
            .i_fft_mode         (xn_fft_mode        ),
            .i_re               (xn_re              ),
            .i_im               (xn_im              ),
            .o_fft_end          (fft_end            ),
            .o_frame_output     (xk_frame_output    ),
            .o_index            (xk_index           ),
            .o_re               (xk_re              ),
            .o_im               (xk_im              ),
            .o_blk_exp          (xk_blk_exp         )
        );
    end
endgenerate

ipsxe_fft_output_ctrl_v1_0 #(
    .LOG2_FFT_LEN       (LOG2_FFT_LEN       ),
    .OUTPUT_ORDER       (OUTPUT_ORDER       ),
    .INPUT_WIDTH        (INPUT_WIDTH        ),
    .SCALE_MODE         (SCALE_MODE         )
) u_output_ctrl (
    .i_clk              (i_aclk             ),
    .i_clken            (clken              ),
    .i_rstn             (rstn               ),
    .o_dataout          (o_axi4s_data_tdata ), 
    .o_dataout_vld      (o_axi4s_data_tvalid),
    .o_dataout_last     (o_axi4s_data_tlast ),
    .o_dataout_usr      (o_axi4s_data_tuser ),   
    .i_re               (xk_re              ),
    .i_im               (xk_im              ),
    .i_frame_output     (xk_frame_output    ),
    .i_index            (xk_index           ),
    .i_blk_exp          (xk_blk_exp         )
);

assign o_stat = input_stat;
assign o_alm = input_alm;

endmodule
