module security_system (
    input clock,
    input [9:0] sw,         // สวิตช์ทั้งหมด
    input [3:0] code_sw,    // รหัสผ่านใน Lockdown Mode
    input mode_switch,      // สวิตช์เปิด Security Mode
    input reset,            // ปุ่มรีเซ็ต
    input ir_sensor,        // เซนเซอร์ตรวจจับการเคลื่อนไหว
    output reg buzzer,      // Buzzer
    output reg [3:0] led_ext, // LED ภายนอก
    output [15:0] led,      // LED ภายใน
    output reg [2:0] status_led // LED แสดงสถานะ
);

    // Internal signals for Digital Clock
    reg [5:0] hours, minutes, seconds;
    reg [31:0] counter;
    reg [15:0] clock_led; // LED สำหรับ Digital Clock
    parameter MAX_COUNTER = 100000000; // 1Hz clock

    // Digital Clock Mode Switch
    wire clock_enable = sw[9];      // เปิด/ปิด Digital Clock
    wire am_pm_mode = !sw[8];       // โหมด AM/PM: sw[8] = 0 สำหรับ AM/PM, 1 สำหรับ Military

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            // Reset logic
            buzzer <= 1'b1;
            led_ext <= 4'b0;
            clock_led <= 16'b0;
            status_led <= 3'b001;
            hours <= 6'b0;
            minutes <= 6'b0;
            seconds <= 6'b0;
        end else begin
            // Security and Normal Modes
            if (mode_switch) begin
                status_led <= 3'b010; // Security Mode
                led_ext <= 4'b1111;
                if (!ir_sensor) begin
                    buzzer <= 1'b0;
                    led_ext <= 4'b1111; // Lockdown Trigger
                end
            end else begin
                status_led <= 3'b001; // Normal Mode
                buzzer <= 1'b1;
                led_ext <= sw[3:0];
            end

            // Digital Clock Logic
            if (clock_enable) begin
                if (counter < MAX_COUNTER) begin
                    counter <= counter + 1;
                end else begin
                    counter <= 0;
                    seconds <= seconds + 1;

                    if (seconds >= 60) begin
                        seconds <= 0;
                        minutes <= minutes + 1;
                    end
                    if (minutes >= 60) begin
                        minutes <= 0;
                        hours <= hours + 1;
                    end
                    if (hours >= 24) begin
                        hours <= 0;
                    end
                end

                // Display Hours and Minutes
                if (am_pm_mode) begin
                    // AM/PM Mode
                    clock_led[15] <= (hours >= 12); // PM = 1, AM = 0
                    if (hours == 0) begin
                        clock_led[14:10] <= 5'b00010; // 12:00 AM
                    end else if (hours > 12) begin
                        clock_led[14:10] <= (hours - 12);
                    end else begin
                        clock_led[14:10] <= hours;
                    end
                end else begin
                    // Military Time
                    clock_led[15] <= 0;
                    clock_led[14:10] <= hours;
                end

                clock_led[9:5] <= minutes; // Minutes
                clock_led[4:0] <= seconds; // Seconds
            end else begin
                clock_led <= 16'b0;
            end
        end
    end

    // Assign LED for output
    assign led = clock_led;

endmodule
