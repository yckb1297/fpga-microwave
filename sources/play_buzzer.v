`timescale 1ns / 1ps

module buzzer #(
    parameter NOTE_CYCLES = 7_000_000   // 70ms(100MHz)
)(
    input clk,
    input reset,
    input door_event,
    input door_open,
    input finish_en,
    input rotary_event,
    output buzzer
    );
    
    reg [21:0] r_clk_cnt[1:0];  //2차원 array, 주파수 생성용
    reg [$clog2(NOTE_CYCLES) -1:0] r_70ms_cnt[1:0];
    reg [1:0] r_buzzer_freq;

    reg r_sound_open;
    
    reg [2:0] r_door_open;
    reg [2:0] r_door_close;
    wire [15:0] w_open_freq;
    wire [15:0] w_close_freq;

    integer i;  //integer: signed 32bit

    assign w_open_freq =
        (r_door_open == 0) ? 16'd50_000 :
        (r_door_open == 1) ? 16'd25_000 :
        (r_door_open == 2) ? 16'd16_666 :
        (r_door_open == 3) ? 16'd12_250 :
        16'd0;
    assign w_close_freq =
        (r_door_close == 0) ? 16'd12_250 :
        (r_door_close == 1) ? 16'd16_666 :
        (r_door_close == 2) ? 16'd25_000 :
        (r_door_close == 3) ? 16'd50_000 :
        16'd0;

    localparam [14:0] FINISH_FREQ = 15'd25_000;
    localparam [25:0] BEEP_CYCLES = 26'd50_000_000;

    reg [14:0] r_finish_freq_cnt;
    reg [25:0] r_finish_time_cnt;
    reg [2:0] r_finish_step;
    reg r_finish_buzzer;
    reg r_prev_finish;
 
    //종료음 출력
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            r_prev_finish      <= 0;
            r_finish_freq_cnt  <= 0;
            r_finish_time_cnt  <= 0;
            r_finish_step      <= 0;
            r_finish_buzzer    <= 0;
        end
        else begin
            r_prev_finish <= finish_en;

            // FINISH 상태 진입 감지
            if (finish_en && !r_prev_finish) begin
                r_finish_freq_cnt <= 0;
                r_finish_time_cnt <= 0;
                r_finish_step <= 0;
                r_finish_buzzer <= 0;
            end
            else if (finish_en && r_finish_step < 5) begin

                // 0.5초 경과
                if (r_finish_time_cnt == BEEP_CYCLES - 1) begin
                    r_finish_time_cnt <= 0;
                    r_finish_freq_cnt <= 0;
                    r_finish_buzzer <= 0;
                    r_finish_step <= r_finish_step + 1'b1;
                end
                else begin
                    r_finish_time_cnt <= r_finish_time_cnt + 1'b1;

                    // 짝수 step에서 소리 출력
                    if (!r_finish_step[0]) begin
                        if (r_finish_freq_cnt == FINISH_FREQ - 1) begin
                            r_finish_freq_cnt <= 0;
                            r_finish_buzzer <= ~r_finish_buzzer;
                        end
                        else begin
                            r_finish_freq_cnt <= r_finish_freq_cnt + 1'b1;
                        end
                    end
                    else begin
                        r_finish_freq_cnt <= 0;
                        r_finish_buzzer <= 0;
                    end
                end
            end
            else begin
                r_finish_freq_cnt <= 0;
                r_finish_time_cnt <= 0;
                r_finish_buzzer <= 0;
            end
        end
    end

    // 문 열기/닫기 효과음 출력
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            for(i = 0; i < 2; i = i + 1) begin
                r_clk_cnt[i] <= 22'd0;
                r_70ms_cnt[i] <= 0;
                r_buzzer_freq[i] <= 1'b0;
            end
            r_door_open <= 4;
            r_door_close <= 4;
            r_sound_open <= 0;

        end else begin
            //btn2: open/close door buzzer
            if (door_event) begin
                for(i = 0; i < 2; i = i + 1) begin
                    r_clk_cnt[i] <= 22'd0;
                    r_70ms_cnt[i] <= 0;
                    r_buzzer_freq[i] <= 1'b0;
                end

                if (!door_open) begin
                    // 문 열기
                    r_sound_open <= 1'b1;
                    r_door_open <= 3'd0;
                    r_door_close <= 3'd4;
                end
                else begin
                    // 문 닫기
                    r_sound_open <= 1'b0;
                    r_door_open <= 3'd4;
                    r_door_close <= 3'd0;
                end
            end else if(r_sound_open && r_door_open < 4) begin
                    if(r_70ms_cnt[0] >= NOTE_CYCLES -1) begin
                        r_70ms_cnt[0] <= 0;
                        r_clk_cnt[0] <= 0;
                        r_buzzer_freq[0] <= 0;
                        r_door_open <= r_door_open + 1;
                    end else begin
                        r_70ms_cnt[0] <= r_70ms_cnt[0] + 1;
                        if(r_clk_cnt[0] >= w_open_freq - 1) begin
                            r_clk_cnt[0] <= 0;
                            r_buzzer_freq[0] <= ~r_buzzer_freq[0];
                        end else begin
                            r_clk_cnt[0] <= r_clk_cnt[0] + 1;
                        end
                    end
            end else if(!r_sound_open && r_door_close < 4) begin
                if(r_70ms_cnt[1] >= NOTE_CYCLES -1) begin
                    r_70ms_cnt[1] <= 0;
                    r_clk_cnt[1] <= 0;
                    r_buzzer_freq[1] <= 0;
                    r_door_close <= r_door_close + 1;
                end else begin
                    r_70ms_cnt[1] <= r_70ms_cnt[1] + 1;
                    if(r_clk_cnt[1] >= w_close_freq - 1) begin
                        r_clk_cnt[1] <= 0;
                        r_buzzer_freq[1] <= ~r_buzzer_freq[1];
                    end else begin
                        r_clk_cnt[1] <= r_clk_cnt[1] + 1;
                    end
                end
            end else begin
                r_buzzer_freq <= 2'b00;
            end
        end
    end

    //노브 돌리거나 key 버튼 눌렀을 때
    localparam [23:0] ROTARY_BEEP_CYCLES = 24'd10_000_000; // 0.1초

    reg [23:0] r_rotary_time_cnt;
    reg [14:0] r_rotary_freq_cnt;
    reg r_rotary_buzzer;
    reg r_rotary_active;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            r_rotary_time_cnt <= 0;
            r_rotary_freq_cnt <= 0;
            r_rotary_buzzer   <= 0;
            r_rotary_active   <= 0;
        end
        else if (rotary_event && !finish_en) begin
            // 조작할 때마다 0.1초 재생 시작
            r_rotary_time_cnt <= 0;
            r_rotary_freq_cnt <= 0;
            r_rotary_buzzer   <= 0;
            r_rotary_active   <= 1;
        end
        else if (r_rotary_active && !finish_en) begin
            if (r_rotary_time_cnt == ROTARY_BEEP_CYCLES - 1) begin
                r_rotary_time_cnt <= 0;
                r_rotary_freq_cnt <= 0;
                r_rotary_buzzer   <= 0;
                r_rotary_active   <= 0;
            end
            else begin
                r_rotary_time_cnt <= r_rotary_time_cnt + 1'b1;

                if (r_rotary_freq_cnt == FINISH_FREQ - 1) begin
                    r_rotary_freq_cnt <= 0;
                    r_rotary_buzzer <= ~r_rotary_buzzer;
                end
                else begin
                    r_rotary_freq_cnt <= r_rotary_freq_cnt + 1'b1;
                end
            end
        end
        else begin
            r_rotary_time_cnt <= 0;
            r_rotary_freq_cnt <= 0;
            r_rotary_buzzer   <= 0;
            r_rotary_active   <= 0;
        end
    end

    wire door_sound_active;

    assign door_sound_active =
        (r_sound_open && r_door_open < 4) ||
        (!r_sound_open && r_door_close < 4);

    assign buzzer =
        finish_en         ? r_finish_buzzer :
        door_sound_active ? (|r_buzzer_freq) :
                            r_rotary_buzzer;
endmodule
