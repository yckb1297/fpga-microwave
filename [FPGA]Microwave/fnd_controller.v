`timescale 1ns / 1ps

module fnd_controller(
    input clk,
    input reset,
    input tick,
    input [11:0] fnd_data,
    input blink_en,
    output [3:0] an,
    output [6:0] seg
    );

    wire [1:0] w_sel;
    wire [3:0] w_d1, w_d10, w_d100, w_d1000;
    wire [3:0] w_an;
    wire [6:0] w_seg;

    fnd_digit_select u_fnd_digit_select(
        .clk(clk),
        .reset(reset),
        .tick(tick),
        .sel(w_sel)
    );

    bin2bcd4digit u_bin2bcd4digit(
        .fnd_data(fnd_data),
        .d1(w_d1),
        .d10(w_d10),
        .d100(w_d100),
        .d1000(w_d1000)
    );

    fnd_digit_display u_fnd_digit_display(
        .sel(w_sel),
        .d1(w_d1),
        .d10(w_d10),
        .d100(w_d100),
        .d1000(w_d1000),
        .an(w_an),
        .seg(w_seg)
    );

    assign an  = blink_en ? w_an : 4'b1111;
    assign seg = blink_en ? w_seg : 8'b11111111;

endmodule

//--- 1ms마다 fnd를 display digit 1자리씩 선택하는 logic
module fnd_digit_select(
        input clk,
        input reset,
        input tick,
        output reg [1:0] sel
    );

    always @(posedge clk or posedge reset) begin
        if(reset)
            sel <= 0;
        else if(tick)
            sel <= sel + 1'b1;
    end
endmodule

//천/백/십/일 자리 숫자 0~9 BCD 4bit 표현
module bin2bcd4digit(
    input [11:0] fnd_data,
    output [3:0] d1,
    output [3:0] d10,
    output [3:0] d100,
    output [3:0] d1000
);
    wire [6:0] left_data;
    wire [6:0] right_data;

    assign left_data = fnd_data[11:6];
    assign right_data = fnd_data[5:0];

    assign d1 = right_data % 10;
    assign d10 = right_data / 10;
    assign d100 = left_data % 10;
    assign d1000 = left_data / 10;

endmodule

module fnd_digit_display(
    input [1:0] sel,
    input [3:0] d1,
    input [3:0] d10,
    input [3:0] d100,
    input [3:0] d1000,
    output reg [3:0] an,
    output reg [6:0] seg
);

    reg [3:0] bcd_data;

    always @(*) begin
        case(sel)
            2'b00: begin
                bcd_data = d1;
                an = 4'b1110;
            end
            2'b01: begin
                bcd_data = d10;
                an = 4'b1101;
            end
            2'b10: begin
                bcd_data = d100;
                an = 4'b1011;
            end
            2'b11: begin
                bcd_data = d1000;
                an = 4'b0111;
            end
            
        endcase
    end

    always @(*) begin
            case(bcd_data)
                4'd0: seg = 7'b1000000;   // 0
                4'd1: seg = 7'b1111001;   // 1
                4'd2: seg = 7'b0100100;   // 2
                4'd3: seg = 7'b0110000;   // 3
                4'd4: seg = 7'b0011001;   // 4
                4'd5: seg = 7'b0010010;   // 5
                4'd6: seg = 7'b0000010;   // 6
                4'd7: seg = 7'b1111000;   // 7
                4'd8: seg = 7'b0000000;   // 8
                4'd9: seg = 7'b0010000;   // 9

                default: seg = 8'b11111111;  // all off  
            endcase 
    end
endmodule
