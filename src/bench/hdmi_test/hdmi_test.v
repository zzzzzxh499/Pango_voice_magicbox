`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:Meyesemi 
// Engineer: Will
// 
// Create Date: 2023-01-29 20:31  
// Design Name:  
// Module Name: 
// Project Name: 
// Target Devices: Pango
// Tool Versions: 
// Description: 
//      
// Dependencies: 
// 
// Revision:
// Revision 1.0 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`define UD #1

module hdmi_test(
    output            rstn_out      ,
    output            iic_tx_scl    ,
    inout             iic_tx_sda    ,
    output            led_int       ,
//hdmi_out 
    input            pix_clk       ,//pixclk                           
    output            vs_out        , 
    output            hs_out        , 
    output            de_out        ,
    output     [7:0]  r_out         , 
    output     [7:0]  g_out         , 
    output     [7:0]  b_out         

);

parameter   X_WIDTH = 4'd12;
parameter   Y_WIDTH = 4'd12;    

//MODE_1080p
    parameter V_TOTAL = 12'd1125;
    parameter V_FP = 12'd4;
    parameter V_BP = 12'd36;
    parameter V_SYNC = 12'd5;
    parameter V_ACT = 12'd1080;
    parameter H_TOTAL = 12'd2200;
    parameter H_FP = 12'd88;
    parameter H_BP = 12'd148;
    parameter H_SYNC = 12'd44;
    parameter H_ACT = 12'd1920;
    parameter HV_OFFSET = 12'd0;

//    wire                        pix_clk    ;
    wire                        cfg_clk    ;
    wire                        locked     ;
    wire                        rstn       ;
    wire                        init_over  ;
    reg  [15:0]                 rstn_1ms   ;
    wire [X_WIDTH - 1'b1:0]     act_x      ;
    wire [Y_WIDTH - 1'b1:0]     act_y      ;    
    wire                        hs         ;
    wire                        vs         ;
    wire                        de         ;
    reg  [3:0]                  reset_delay_cnt;

    sync_vg #(
        .X_BITS               (  X_WIDTH              ), 
        .Y_BITS               (  Y_WIDTH              ),
        .V_TOTAL              (  V_TOTAL              ),//                        
        .V_FP                 (  V_FP                 ),//                        
        .V_BP                 (  V_BP                 ),//                        
        .V_SYNC               (  V_SYNC               ),//                        
        .V_ACT                (  V_ACT                ),//                        
        .H_TOTAL              (  H_TOTAL              ),//                        
        .H_FP                 (  H_FP                 ),//                        
        .H_BP                 (  H_BP                 ),//                        
        .H_SYNC               (  H_SYNC               ),//                        
        .H_ACT                (  H_ACT                ) //                        
 
    ) sync_vg                                         
    (                                                 
        .clk                  (  pix_clk               ),//input                   clk,                                 
        .rstn                 (  rstn_out                 ),//input                   rstn,                            
        .vs_out               (  vs                   ),//output reg              vs_out,                                                                                                                                      
        .hs_out               (  hs                   ),//output reg              hs_out,            
        .de_out               (  de                   ),//output reg              de_out,             
        .x_act                (  act_x                ),//output reg [X_BITS-1:0] x_out,             
        .y_act                (  act_y                ) //output reg [Y_BITS:0]   y_out,             
    );
    
    pattern_vg #(
        .COCLOR_DEPP          (  8                    ), // Bits per channel
        .X_BITS               (  X_WIDTH              ),
        .Y_BITS               (  Y_WIDTH              ),
        .H_ACT                (  H_ACT                ),
        .V_ACT                (  V_ACT                )
    ) // Number of fractional bits for ramp pattern
    pattern_vg (
        .rstn                 (  rstn_out                 ),//input                         rstn,                                                     
        .pix_clk              (  pix_clk               ),//input                         clk_in,  
        .act_x                (  act_x                ),//input      [X_BITS-1:0]       x,   
        // input video timing
        .vs_in                (  vs                   ),//input                         vn_in                        
        .hs_in                (  hs                   ),//input                         hn_in,                           
        .de_in                (  de                   ),//input                         dn_in,
        // test pattern image output                                                    
        .vs_out               (  vs_out               ),//output reg                    vn_out,                       
        .hs_out               (  hs_out               ),//output reg                    hn_out,                       
        .de_out               (  de_out               ),//output reg                    den_out,                      
        .r_out                (  r_out                ),//output reg [COCLOR_DEPP-1:0]  r_out,                      
        .g_out                (  g_out                ),//output reg [COCLOR_DEPP-1:0]  g_out,                       
        .b_out                (  b_out                ) //output reg [COCLOR_DEPP-1:0]  b_out   
    );

endmodule
