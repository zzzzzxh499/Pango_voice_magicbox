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
module key_ctl(
    input            clk,
    input            key,
    
    output           ctrl
);

    wire btn_deb;
    // °´¼üÏû¶¶
    btn_deb_fix#(                    
        .BTN_WIDTH   (  4'd1        ), //parameter                  BTN_WIDTH = 4'd8
        .BTN_DELAY   (20'h7_ffff    )
    ) u_btn_deb                           
    (                            
        .clk         (  clk         ),//input                      clk,
        .btn_in      (  key         ),//input      [BTN_WIDTH-1:0] btn_in,
                                    
        .btn_deb_fix (  btn_deb     ) //output reg [BTN_WIDTH-1:0] btn_deb
    );

    reg btn_deb_1d;
    always @(posedge clk)
    begin
        btn_deb_1d <= `UD btn_deb;
    end

    reg [1:0]  key_push_cnt=2'd0;
    always @(posedge clk)
    begin
        if(~btn_deb & btn_deb_1d)
        begin
            if(key_push_cnt == 1'd1)
                key_push_cnt <= `UD 2'd0;
            else
                key_push_cnt <= `UD key_push_cnt + 2'd1;
        end
    end
    
    assign ctrl = key_push_cnt;

endmodule
