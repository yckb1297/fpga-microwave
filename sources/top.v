`timescale 1ns / 1ps

module top(
    input clk,
    input reset,
    input [2:0] btn,
    input [2:0] rotary,     //0: s1, 1: s2, 2: key
    output pwm_survo,
    output buzzer,
    output [6:0] seg,
    output [3:0] an
    );

    wire [2:0] w_clean_btn;
    wire [2:0] w_clean_rotary;

    wire w_tick;
    wire [11:0] w_set_time;
    wire [11:0] w_fnd_data;

    wire w_ctrl_en;
    wire w_clear_set_time;
    wire w_blink_en;
    wire w_finish_en;
    wire w_rotary_event;

    wire w_door_open;
    wire w_door_event;
    wire w_door_open_request;

    tick_generator u_tick_generator(
        .clk(clk),
        .reset(reset),
        .tick(w_tick)
    );

    door_state u_door_state(
        .clk(clk),
        .reset(reset),
        .door_btn(w_clean_btn[2]),
        .door_open(w_door_open),
        .door_event(w_door_event),
        .door_open_request(w_door_open_request)
    );

    buzzer u_buzzer(
        .clk(clk),
        .reset(reset),
        .door_event(w_door_event),
        .door_open(w_door_open),
        .finish_en(w_finish_en),
        .rotary_event(w_rotary_event),
        .buzzer(buzzer)
    );

    rotary u_rotary(
        .clk(clk),
        .reset(reset),
        .s1(w_clean_rotary[0]),
        .s2(w_clean_rotary[1]),
        .key(w_clean_rotary[2]),
        .ctrl_en(w_ctrl_en),
        .clear_set_time(w_clear_set_time),
        .set_time(w_set_time),
        .rotary_event(w_rotary_event)
    );

    main_controller u_main_controller(
        .clk(clk),
        .reset(reset),
        .btn(w_clean_btn[1:0]),
        .door_open(w_door_open),
        .door_open_request(w_door_open_request),
        .set_time(w_set_time),
        .seg_data(w_fnd_data),
        .ctrl_en(w_ctrl_en),
        .blink_en(w_blink_en),
        .clear_set_time(w_clear_set_time),
        .finish_en(w_finish_en)
    );

    fnd_controller u_fnd_controller(
        .clk(clk),
        .reset(reset),
        .tick(w_tick),
        .fnd_data(w_fnd_data),
        .blink_en(w_blink_en),
        .an(an),
        .seg(seg)
    );

    pwm_survo u_pwm_survo(
        .clk(clk),
        .reset(reset),
        .door_open(w_door_open),
        .pwm_survo(pwm_survo)
    );

    btn_debouncer u_btn_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_btn(btn),
        .clean_btn(w_clean_btn)
    );

    rotary_debouncer u_rotary_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_rotary(rotary),
        .clean_rotary(w_clean_rotary)
    );
endmodule