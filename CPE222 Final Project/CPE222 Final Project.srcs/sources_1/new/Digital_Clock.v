module Digital_Clock(
    input clk,
    input IO_BTN_C, IO_BTN_U, IO_BTN_L, IO_BTN_R, IO_BTN_D,
    input AMPM_Toggle_Button,
    output wire AM_PM_LED,        // แสดงสถานะ AM/PM
    output [6:0] IO_SSEG,         // 7-Segment Display
    output [3:0] IO_SSEG_SEL      // 7-Segment Selectors
);

    reg [31:0] counter = 0;
    parameter max_counter = 100000000;

    reg [5:0] Hours, Minutes, Seconds = 0;
    reg [3:0] Digit_0, Digit_1, Digit_2, Digit_3 = 0;
    reg Military_or_AMPM = 0;
    reg AM_PM = 0;

    assign AM_PM_LED = AM_PM; // ใช้ assign เพื่อส่งค่าไปยัง LED

    sevseg display(
        .clk(clk),
        .binary_input_0(Digit_0),
        .binary_input_1(Digit_1),
        .binary_input_2(Digit_2),
        .binary_input_3(Digit_3),
        .IO_SSEG_SEL(IO_SSEG_SEL),
        .IO_SSEG(IO_SSEG)
    );

    always @(posedge clk) begin
        if (counter < max_counter) begin
            counter <= counter + 1;
        end else begin
            counter <= 0;
            Seconds <= Seconds + 1;
        end

        if (Seconds >= 60) begin
            Seconds <= 0;
            Minutes <= Minutes + 1;
        end
        if (Minutes >= 60) begin
            Minutes <= 0;
            Hours <= Hours + 1;
        end
        if (Hours >= 24) begin
            Hours <= 0;
        end

        if (AMPM_Toggle_Button) begin
            Military_or_AMPM <= ~Military_or_AMPM;
        end

        if (Military_or_AMPM) begin
            Digit_0 <= Minutes % 10;
            Digit_1 <= Minutes / 10;
            Digit_2 <= Hours % 10;
            Digit_3 <= Hours / 10;
            AM_PM <= 0;
        end else begin
            Digit_0 <= Minutes % 10;
            Digit_1 <= Minutes / 10;
            if (Hours < 12) begin
                if (Hours == 0) begin
                    Digit_2 <= 2;
                    Digit_3 <= 1;
                end else begin
                    Digit_2 <= Hours % 10;
                    Digit_3 <= Hours / 10;
                end
                AM_PM <= 0;
            end else begin
                if (Hours == 12) begin
                    Digit_2 <= 2;
                    Digit_3 <= 1;
                end else begin
                    Digit_2 <= (Hours - 12) % 10;
                    Digit_3 <= (Hours - 12) / 10;
                end
                AM_PM <= 1;
            end
        end
    end
endmodule
