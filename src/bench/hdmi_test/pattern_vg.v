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
module pattern_vg # (
    parameter                            COCLOR_DEPP=8, // number of bits per channel
    parameter                            X_BITS=13,
    parameter                            Y_BITS=13,
    parameter                            H_ACT = 12'd1280,
    parameter                            V_ACT = 12'd720
)(                                       
    input                                rstn, 
    input                                pix_clk,
    input [X_BITS-1:0]                   act_x,
    input                                vs_in, 
    input                                hs_in, 
    input                                de_in,
    
    output reg                           vs_out, 
    output reg                           hs_out, 
    output reg                           de_out,
    output reg [COCLOR_DEPP-1:0]         r_out, 
    output reg [COCLOR_DEPP-1:0]         g_out, 
    output reg [COCLOR_DEPP-1:0]         b_out
);
    localparam H_ACT_ARRAY_0 = H_ACT/8;
    localparam H_ACT_ARRAY_1 = 2* (H_ACT/8);
    localparam H_ACT_ARRAY_2 = 3* (H_ACT/8);
    localparam H_ACT_ARRAY_3 = 4* (H_ACT/8);
    localparam H_ACT_ARRAY_4 = 5* (H_ACT/8);
    localparam H_ACT_ARRAY_5 = 6* (H_ACT/8);
    localparam H_ACT_ARRAY_6 = 7* (H_ACT/8);
    localparam H_ACT_ARRAY_7 = 8* (H_ACT/8);
    
    always @(posedge pix_clk)
    begin
        vs_out <= `UD vs_in;
        hs_out <= `UD hs_in;
        de_out <= `UD de_in;
    end

    always @(posedge pix_clk)
    begin
        if (de_in)
        begin
            if(act_x < H_ACT_ARRAY_0)
            begin
                r_out <= 8'hff;
                g_out <= 8'hff;
                b_out <= 8'hff;
            end
            else if(act_x < H_ACT_ARRAY_1)
            begin
                r_out <= 8'hff;
                g_out <= 8'hff;
                b_out <= 8'h00;
            end
            else if(act_x < H_ACT_ARRAY_2)
            begin
                r_out <= 8'h00;
                g_out <= 8'hff;
                b_out <= 8'hff;
            end
            else if(act_x < H_ACT_ARRAY_3)
            begin
                r_out <= 8'h00;
                g_out <= 8'hff;
                b_out <= 8'h00;
            end
            else if(act_x < H_ACT_ARRAY_4)
            begin
                r_out <= 8'hff;
                g_out <= 8'h00;
                b_out <= 8'hff;
            end
            else if(act_x < H_ACT_ARRAY_5)
            begin
                r_out <= 8'hff;
                g_out <= 8'h00;
                b_out <= 8'h00;
            end
            else if(act_x < H_ACT_ARRAY_6)
            begin
                r_out <= 8'h00;
                g_out <= 8'h00;
                b_out <= 8'hff;
            end
            else
            begin
                r_out <= 8'h0;
                g_out <= 8'h0;
                b_out <= 8'h0;
            end
        end
        else
        begin
            r_out <= 8'h00;
            g_out <= 8'h00;
            b_out <= 8'h00;
        end
    end
    
endmodule
