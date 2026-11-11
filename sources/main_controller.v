`timescale 1ns / 1ps

module main_controller(
    input clk,
    input reset,
    input [1:0] btn,
    input door_open,
    input door_open_request,
    input [11:0] set_time,
    output [11:0] seg_data,
    output ctrl_en,
    output blink_en,
    output clear_set_time,
    output finish_en
    );

    //mode define
    parameter IDLE = 2'b00;
    parameter MS_TIMER = 2'b01;
    parameter PAUSE = 2'b10;
    parameter FINISH = 2'b11;

    reg [1:0] r_mode;

    // 100MHz -> 10ms
    reg [19:0] r_10ns_counter;
    reg [6:0] r_clock_10ms;

    // MM:SS
    reg [5:0] r_clock_sec;
    reg [5:0] r_clock_min;

    reg [1:0] r_prev_btn;

    wire start_pulse;
    wire pause_pulse;

    reg [1:0] r_blink_count;
    reg r_blink_on;

    assign seg_data = {r_clock_min, r_clock_sec};
    assign start_pulse = btn[0] && !r_prev_btn[0];
    assign pause_pulse = btn[1] && !r_prev_btn[1];

    assign blink_en = (r_mode != FINISH) || r_blink_on;     // 동작 종료시 fnd 깜빡임 신호
    assign ctrl_en = (r_mode == IDLE);                      // 로터리 시간 설정 허용
    assign finish_en = (r_mode == FINISH);
    assign clear_set_time = (r_mode == FINISH) ||
                            (r_mode == PAUSE && pause_pulse);   // FINISH면 시간 카운터 초기화하도록 신호 전달용

    // 버튼 이전 상태 저장
    always @(posedge clk or posedge reset) begin
        if (reset)
            r_prev_btn <= 2'b00;
        else
            r_prev_btn <= btn;
    end

    // 모드 및 시간 제어
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            r_mode         <= IDLE;
            r_10ns_counter <= 0;
            r_clock_10ms   <= 0;
            r_clock_min    <= 0;
            r_clock_sec    <= 0;
            r_blink_count  <= 0;
            r_blink_on     <= 0;
        end
        else begin
            case (r_mode)

                IDLE: begin
                    r_10ns_counter <= 0;
                    r_clock_10ms   <= 0;

                    // 로터리 설정 시간 표시
                    r_clock_min <= set_time / 60;
                    r_clock_sec <= set_time % 60;

                    if (start_pulse && set_time != 0 && !door_open && !door_open_request) begin
                        r_mode <= MS_TIMER;
                    end
                end

                MS_TIMER: begin
                    // 일시정지 버튼
                    if (door_open || door_open_request || pause_pulse) begin
                        r_mode <= PAUSE;
                    end
                    else if (r_10ns_counter == 20'd999_999) begin
                        r_10ns_counter <= 0;

                        if (r_clock_10ms == 7'd99) begin
                            r_clock_10ms <= 0;

                            // 남은 시간이 1초인 경우
                            if (r_clock_min == 0 && r_clock_sec == 1) begin
                                r_clock_sec <= 0;
                                r_mode <= FINISH;

                                r_blink_count <= 0;
                                r_blink_on <= 1;
                                r_10ns_counter <= 0;
                                r_clock_10ms <= 0;
                            end
                            // 초가 0이면 분에서 빌림
                            else if (r_clock_sec == 0) begin
                                if (r_clock_min > 0) begin
                                    r_clock_min <= r_clock_min - 1'b1;
                                    r_clock_sec <= 6'd59;
                                end
                                else begin
                                    r_mode <= IDLE;
                                end
                            end
                            // 일반적인 초 감소
                            else begin
                                r_clock_sec <= r_clock_sec - 1'b1;
                            end

                        end
                        else begin
                            r_clock_10ms <= r_clock_10ms + 1'b1;
                        end
                    end
                    else begin
                        r_10ns_counter <= r_10ns_counter + 1'b1;
                    end
                end

                PAUSE: begin
                    if (pause_pulse) begin
                        r_mode <= IDLE;      // 정지/취소 버튼으로 취소
                    end
                    else if (start_pulse && !door_open && !door_open_request) begin
                        r_mode <= MS_TIMER;  // 문을 닫고 시작 버튼으로 재개
                    end
                end
                
                FINISH: begin
                    if (r_10ns_counter == 20'd999_999) begin
                        r_10ns_counter <= 0;

                        if (r_clock_10ms == 7'd49) begin
                            r_clock_10ms <= 0;
                            r_blink_on <= ~r_blink_on;

                            if (r_blink_count == 2'd2 && r_blink_on == 0) begin
                                r_mode <= IDLE;
                                r_blink_count <= 0;
                            end
                            else if (r_blink_on == 0) begin
                                r_blink_count <= r_blink_count + 1'b1;
                            end
                        end
                        else begin
                            r_clock_10ms <= r_clock_10ms + 1'b1;
                        end
                    end
                    else begin
                        r_10ns_counter <= r_10ns_counter + 1'b1;
                    end
                end

                default: begin
                    r_mode <= IDLE;
                end
            endcase
        end
    end

endmodule
