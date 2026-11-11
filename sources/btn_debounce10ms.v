module btn_debouncer(
    input      clk,
    input      reset,
    input   [2:0]   noisy_btn,   
    output  [2:0]   clean_btn
);

    debouncer u_btn0_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_btn(noisy_btn[0]),
        .clean_btn(clean_btn[0])
    );
    debouncer u_btn1_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_btn(noisy_btn[1]),
        .clean_btn(clean_btn[1])
    );
    debouncer u_btn2_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_btn(noisy_btn[2]),
        .clean_btn(clean_btn[2])
    );
endmodule

module rotary_debouncer #(
    parameter DEBOUNCE_LIMIT = 20'd999_999,
    parameter ROTARY_DEBOUNCE_TIME = 200_000,
    parameter KEY_DEBOUNCE_TIME = 1_000_000)
(
    input clk,
    input reset,
    input [2:0] noisy_rotary,
    output [2:0] clean_rotary
    );

    debouncer #(.DEBOUNCE_LIMIT(ROTARY_DEBOUNCE_TIME)) u_s1_debouncer(   //rotary: 2ms(200_000ns)
        .clk(clk),
        .reset(reset),
        .noisy_btn(noisy_rotary[0]),
        .clean_btn(clean_rotary[0])
    );
    debouncer #(.DEBOUNCE_LIMIT(ROTARY_DEBOUNCE_TIME)) u_s2_debouncer(   //rotary: 2ms(200_000ns)
        .clk(clk),
        .reset(reset),
        .noisy_btn(noisy_rotary[1]),
        .clean_btn(clean_rotary[1])
    );
    debouncer #(
        .DEBOUNCE_LIMIT(KEY_DEBOUNCE_TIME),
        .INIT_STATE(1'b1)
        )u_key_debouncer(   //10ms
        .clk(clk),
        .reset(reset),
        .noisy_btn(noisy_rotary[2]),
        .clean_btn(clean_rotary[2])
    );
endmodule

module debouncer #(
    parameter DEBOUNCE_LIMIT = 20'd999_999,
    parameter INIT_STATE = 1'b0
) (
    input      clk,
    input      reset,
    input      noisy_btn,   // raw noisy button input
                            // 클럭과 무관하게 들어오는 비동기 신호
    output reg clean_btn
);
    reg [19:0] r_count;
    reg r_btn_state = INIT_STATE;

    //--- start 2단 FF 동기화기: 비동기 버튼 입력(noisy_btn)을 클럭 도메인에 맞춘다.
    reg r_sync1, r_sync2;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            r_sync1 <= INIT_STATE;
            r_sync2 <= INIT_STATE;
        end else begin
            r_sync1 <= noisy_btn;   // 메타스터빌리티가 생길 수 있는 FF
            r_sync2 <= r_sync1;     // 안정된 값 -> 아래 디바운스 로직에서 사용
        end                         // 비동기 입력은 2단 FF 동기화 후 FSM에 투입
    end
    //--------------

    always @(posedge clk or posedge reset) begin
        if (reset) begin   // active-high reset
            r_count <= 0;
            r_btn_state <= INIT_STATE;
            clean_btn <= INIT_STATE;
        end else if (r_sync2 == r_btn_state) begin  // 버튼 상태가 이전과 동일할 경우 (안정됨)
            r_count <= 0;
        end else begin
            if (r_count < DEBOUNCE_LIMIT)  // 버튼 상태가 바뀌었지만 아직 안정되지 않은 경우
                r_count <= r_count + 1;
            else begin  // 상태가 충분히 오랫동안 유지됨(10ms)
                r_btn_state <= r_sync2;   // 2단 FF 
                clean_btn <= r_sync2;     // 2단 FF 
                r_count <= 0;  // clear하면 다음 변경을 다시 감지할 수 있음
            end
        end
    end
endmodule