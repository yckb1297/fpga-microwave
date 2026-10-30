`timescale 1ns / 1ps

module top #(
    parameter ROTARY_DEBOUNCE_TIME = 200_000,
    parameter KEY_DEBOUNCE_TIME = 1_000_000,
    parameter KEY_ACTIVE_LOW = 1
) (
    input clk,
    input reset,
    input [2:0] btn,
    input s1,
    input s2,
    input key,
    output pwm_survo,
    output buzzer,
    output [6:0] seg,
    output [3:0] an
    );

    wire [2:0] w_clean_btn;
    wire w_clean_s1, w_clean_s2, w_clean_key;
    wire w_tick;
    wire [11:0] w_set_time;
    wire [11:0] w_fnd_data;

    wire w_ctrl_en, w_clear_set_time, w_blink_en, w_finish_en, w_rotary_event;

    reg r_door_open;
    reg r_prev_door_btn;
    wire w_door_event = w_clean_btn[2] && !r_prev_door_btn;
    wire w_door_open_request = w_door_event && !r_door_open;
    wire w_key_pressed = KEY_ACTIVE_LOW ? !key : key;

    // 문 버튼은 상태와 관계없이 항상 동작한다.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            r_door_open <= 1'b0;
            r_prev_door_btn <= 1'b0;
        end else begin
            r_prev_door_btn <= w_clean_btn[2];
            if (w_door_event)
                r_door_open <= !r_door_open;
        end
    end

    tick_generator u_tick_generator(
        .clk(clk),
        .reset(reset),
        .tick(w_tick)
    );

    buzzer u_buzzer(
        .clk(clk),
        .reset(reset),
        .door_event(w_door_event),
        .door_open(r_door_open),
        .finish_en(w_finish_en),
        .rotary_event(w_rotary_event),
        .buzzer(buzzer)
    );

    rotary u_rotary(
        .clk(clk),
        .reset(reset),
        .s1(w_clean_s1),
        .s2(w_clean_s2),
        .key(w_clean_key),
        .ctrl_en(w_ctrl_en),
        .clear_set_time(w_clear_set_time),
        .set_time(w_set_time),
        .rotary_event(w_rotary_event)
    );

    main_controller u_main_controller(
        .clk(clk),
        .reset(reset),
        .btn(w_clean_btn[1:0]),
        .door_open(r_door_open),
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
        .door_open(r_door_open),
        .pwm_survo(pwm_survo)
    );

    debouncer u_btn1_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_btn(btn[0]),
        .clean_btn(w_clean_btn[0])
    );
    debouncer u_btn2_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_btn(btn[1]),
        .clean_btn(w_clean_btn[1])
    );
    debouncer u_btn3_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_btn(btn[2]),
        .clean_btn(w_clean_btn[2])
    );

    debouncer #(.DEBOUNCE_LIMIT(ROTARY_DEBOUNCE_TIME)) u_s1_debouncer(   //rotary: 2ms(200_000ns)
        .clk(clk),
        .reset(reset),
        .noisy_btn(s1),
        .clean_btn(w_clean_s1)
    );
    debouncer #(.DEBOUNCE_LIMIT(ROTARY_DEBOUNCE_TIME)) u_s2_debouncer(   //rotary: 2ms(200_000ns)
        .clk(clk),
        .reset(reset),
        .noisy_btn(s2),
        .clean_btn(w_clean_s2)
    );
    debouncer #(.DEBOUNCE_LIMIT(KEY_DEBOUNCE_TIME))u_key_debouncer(   //10ms
        .clk(clk),
        .reset(reset),
        .noisy_btn(w_key_pressed),
        .clean_btn(w_clean_key)
    );

endmodule
