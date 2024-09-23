module voice_recgnize(
    input clk,
    input rst_n,
    input signed [15:0] mfcc_means,
    input mfcc_means_valid,
    input [4:0] keys,
    input data_hi,
    output reg data_valid,
    output reg [4:0] led
);

    wire [4:0] btn_deb;
    // button denoise
    btn_deb_fix#(                    
        .BTN_WIDTH   (  4'd5        ), //parameter                  BTN_WIDTH = 4'd8
        .BTN_DELAY   (20'h7_ffff    )
    ) u_btn_deb                           
    (                            
        .clk         (  clk         ),//input                      clk,
        .btn_in      (  keys        ),//input      [BTN_WIDTH-1:0] btn_in,
                                    
        .btn_deb_fix (  btn_deb     ) //output reg [BTN_WIDTH-1:0] btn_deb
    );

reg [2:0] state;
reg signed [15:0] mfcc_feature [4:0][15:0];
reg data_val;
reg [3:0] cnt;
reg [3:0] feature_fill;
reg [2:0] name;
reg signed [16:0] subtract;
wire [33:0] subtract2;
reg [37:0] distance;
reg [37:0] distance_min;
reg [2:0] min_index;

integer i;

localparam IDLE = 3'd0;
localparam FEATURE = 3'd1;
localparam LOAD = 3'd2;
localparam RECGNIZE = 3'd3;
localparam COMPARE = 3'd4;

always @(posedge clk)
if(~rst_n) begin
    state <= IDLE;
    led <= 5'd0;
    data_val <= 1'b0;
    data_valid <= 1'b0;
    feature_fill <= 4'd0;
    name <= 2'b0;
    distance <= 38'd0;
    distance_min <= 38'h3F_FFFF_FFFF;
    subtract <= 17'd0;
    min_index <= 3'd5;
    for(i=0;i<16;i=i+1) begin
        mfcc_feature[0][i] <= 16'd0;
        mfcc_feature[1][i] <= 16'd0;
        mfcc_feature[2][i] <= 16'd0;
        mfcc_feature[3][i] <= 16'd0;
        mfcc_feature[4][i] <= 16'd0;
    end
end else case(state)
IDLE: begin
    case(btn_deb)
    5'b00001: begin name <= 2'd0; state <= FEATURE; end
    5'b00010: begin name <= 2'd1; state <= FEATURE; end 
    5'b00100: begin name <= 2'd2; state <= FEATURE; end
    5'b01000: begin name <= 2'd3; state <= FEATURE; end
    5'b10000: begin name <= 2'd0; state <= LOAD;   end
    default : begin name <= 2'd0; state <= IDLE;    end
    endcase
    case(min_index)
    3'd0:   led <= 5'b00001;
    3'd1:   led <= 5'b00010;
    3'd2:   led <= 5'b00100;
    3'd3:   led <= 5'b01000;
    3'd4:   led <= 5'b10000;
    default:led <= 5'b00000;
    endcase
    data_val <= 1'b0;
    cnt <= 4'd0;
    distance <= 38'd0;
    distance_min <= 38'h3F_FFFF_FFFF;
    subtract <= 17'd0;
end
FEATURE:begin
    if(data_hi) data_val <= 1'b1;
    data_valid <= data_val && btn_deb[name];
    led <= 5'd0;
    led[name] <= data_valid;
    if(mfcc_means_valid)begin
        cnt <= cnt + 1'b1;
        mfcc_feature[name][cnt] <= mfcc_means;
    end
    if(cnt==12) begin
        state <= IDLE;
    end
    else state <= FEATURE;
    feature_fill[name] <= 1'b1;
    min_index <= 3'd5;
end
LOAD: begin
    if(data_hi) data_val <= 1'b1;
    data_valid <= data_val && btn_deb[4];
    led <= {data_valid,4'd0};
    if(mfcc_means_valid)begin
        cnt <= cnt + 1'b1;
        mfcc_feature[4][cnt] <= mfcc_means;
    end
    if(cnt==12) begin
        cnt <= 4'd0;
        state <= RECGNIZE;
    end
    else state <= LOAD;
end
RECGNIZE: begin
    if(feature_fill[name]) begin
        if(cnt==12+3) begin
            state <= COMPARE;
            cnt <= 4'd0;
        end else begin
            state <= RECGNIZE;
            cnt <= cnt + 1'b1;
        end
        subtract <= mfcc_feature[4][cnt] - mfcc_feature[name][cnt];
        if(cnt>=3)//delay 3
            distance <= distance + subtract2;
    end else begin
        state <= COMPARE;
        distance <= 38'h3F_FFFF_FFFF;
    end
end
COMPARE: begin
    if(name==3) begin
        name <= 0;
        state <= IDLE;
    end else begin
        name <= name + 1'b1;
        state <= RECGNIZE;
    end
    if(distance < distance_min) begin
        distance_min <= distance;
        min_index <= name;
    end
    distance <= 38'd0;
end
default:state <= IDLE;
endcase

MUL17x17 MUL17x17 (
  .a(subtract),        // input [16:0]
  .b(subtract),        // input [16:0]
  .clk(clk),    // input
  .rst(~rst_n),    // input
  .ce(1'b1),      // input
  .p(subtract2)         // output [33:0]
);

endmodule