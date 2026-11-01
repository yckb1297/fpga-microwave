`timescale 1ns / 1ps

module rotary(
    input clk,
    input reset,
    input s1,
    input s2,
    input key,
    input ctrl_en,
    input clear_set_time,
    output [11:0] set_time,
    output reg rotary_event
    );

    reg [1:0] r_direction = 2'b00;  // CW: 2'b01, CCW: 2'b10
    reg [1:0] r_prev_state = 2'b00;
    reg [1:0] r_curr_state = 2'b00;
    reg [1:0] r_step = 2'b00;
    reg [11:0] r_counter = 0;
    
    reg r_led_toggle = 1'b0;
    reg r_prev_key = 1'b1;

    // 1. s1, s2 (순차)
    //  CW: 00 -> 10 -> 11 -> 01 -> 00 (1증가 r_step)
    // CCW: 00 -> 01 -> 11 -> 10 -> 00
    always @(posedge clk, posedge reset) begin
        if(reset || clear_set_time) begin
            r_direction <= 2'b00;
            r_prev_state <= 2'b00;
            r_curr_state <= 2'b00;
            r_step <= 2'b00;
            r_prev_key <= 1'b1; 
            r_counter <= 0;
            rotary_event <= 1'b0;
        end else begin
            r_prev_state <= r_curr_state;
            r_prev_key <= key;
            r_curr_state <= {s1, s2};
            rotary_event <= 1'b0;
            if (ctrl_en) begin
            case({r_prev_state, r_curr_state})
                4'b0010, 4'b1011, 4'b1101, 4'b0100: begin


                    if(r_step == 2'b11) begin
                        if(r_counter <= 12'd3589) begin
                            r_counter <= r_counter + 12'd10;
                            rotary_event <= 1'b1;
                        end else r_counter <= 12'd3599;
                    end
                    
                    r_step <= r_step + 1;
                    r_direction <= 2'b01;   //CW indicator
                end
                
                4'b0001, 4'b0111, 4'b1110, 4'b1000: begin

                    if(r_step == 2'b11) begin
                        if(r_counter >= 10) begin
                            r_counter <= r_counter - 12'd10;
                            rotary_event <= 1'b1;
                        end else r_counter <= 0;
                    end
                    
                    r_step <= r_step + 1;
                    r_direction <= 2'b10;   //CCW indicator
                end
            endcase

            if(r_prev_key && !key) begin    //하강 에지 검출
                rotary_event <= 1'b1;

                if(r_counter <= 12'd3569)
                    r_counter <= r_counter + 12'd30;
                else r_counter <= 12'd3599;                
            end
            end else begin
                r_step <= 2'b00;
            end
        end
    end

    assign set_time = r_counter;
endmodule
