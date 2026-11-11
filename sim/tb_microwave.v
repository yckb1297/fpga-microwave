
`timescale 1ns / 1ps

module tb_top;

    reg clk = 0;
    reg reset = 0;
    reg [2:0] btn = 0;
    reg [2:0] rotary = 3'b100;

    wire pwm_survo, buzzer;
    wire [6:0] seg;
    wire [3:0] an;

    top uut (
        .clk(clk),
        .reset(reset),
        .btn(btn),
        .rotary(rotary),
        .pwm_survo(pwm_survo),
        .buzzer(buzzer),
        .seg(seg),
        .an(an)
    );

    always #5 clk = ~clk;  // 100MHz

    // 일반 버튼: Active High
    task press_btn(input integer n);
    begin
        btn[n] = 1;
        #12_000_000;
        btn[n] = 0;
        #12_000_000;
    end
    endtask

    // 로터리 KEY: Active Low
    task press_key;
    begin
        rotary[2] = 0;
        #12_000_000;
        rotary[2] = 1;
        #12_000_000;
    end
    endtask

    initial begin
        reset = 1;
        #1000000;
        reset = 0;

        // 1. 조리 시간 30초 설정
        press_key();

        // 2. 조리 시작
        press_btn(0);

        // 3. 일시정지
        press_btn(1);

        // 4. 조리 재개
        press_btn(0);

        // 5. 조리 중 문 열기 -> PAUSE
        press_btn(2);
        
        // 6. 문 열린 상태에서 Start -> 동작 불가
        press_btn(0);

        // 7. 문 닫기 -> PAUSE 유지
        press_btn(2);

        // 8. Start -> 조리 재개
        press_btn(0);

        // 9. Stop -> PAUSE
        press_btn(1);

        // 10. Stop -> IDLE (취소)
        press_btn(1);

        #1000;
        $finish;
    end

    initial begin
        $monitor("Time=%0t | Mode=%b | SetTime=%d | Door=%b",
                 $time,
                 uut.u_main_controller.r_mode,
                 uut.w_set_time,
                 uut.w_door_open);
    end

endmodule
