`timescale 1ns / 1ps

module pwm_survo(
    input clk,
    input reset,
    input door_open,
    output pwm_survo
    );

    parameter INPUT_FREQ = 100_000_000;     //100MHz
    parameter PULSE_Hz = 50;   //50Hz, T=20ms
    parameter PULSE_COUNT = INPUT_FREQ / PULSE_Hz;    //2_000_000 -> 50Hz
    parameter OPEN_DOOR = 100_000;
    parameter CLOSE_DOOR = 200_000;

    reg [$clog2(PULSE_COUNT)-1:0] r_pwm_counter = 0;

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            r_pwm_counter <= 0;
        end else begin
            if(r_pwm_counter >= PULSE_COUNT - 1) begin
                r_pwm_counter <= 0;
            end else r_pwm_counter <= r_pwm_counter + 1;
        end
    end

    assign pwm_survo = (door_open) ?
                     (r_pwm_counter < OPEN_DOOR) :
                     (r_pwm_counter < CLOSE_DOOR);
endmodule
