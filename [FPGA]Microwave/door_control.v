`timescale 1ns / 1ps

module door_state (
    input clk,
    input reset,
    input door_btn,
    output reg door_open,
    output door_event,
    output door_open_request
);

    reg r_prev_door_btn;

    // 문 버튼 상승 에지 검출
    assign door_event = door_btn && !r_prev_door_btn;

    // 닫힌 상태에서 문 열기 요청
    assign door_open_request = door_event && !door_open;

    // 문 상태 관리
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            door_open <= 1'b0;
            r_prev_door_btn <= 1'b0;
        end else begin
            r_prev_door_btn <= door_btn;

            if (door_event)
                door_open <= !door_open;
        end
    end

endmodule

