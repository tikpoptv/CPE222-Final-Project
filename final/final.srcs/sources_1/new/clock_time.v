module clock_time (
    input clock,          // สัญญาณ clock 1 Hz
    input reset,          // รีเซ็ต
    input [4:0] set_hours,   // ชั่วโมงที่ตั้งค่า
    input [5:0] set_minutes, // นาทีที่ตั้งค่า
    input set_enable,        // สัญญาณเปิดการตั้งค่าเวลา
    output reg [5:0] minutes, // นาที (0-59)
    output reg [4:0] hours    // ชั่วโมง (0-23)
);
    reg [5:0] seconds; // วินาที (0-59)

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            seconds <= 0;
            minutes <= 0;
            hours <= 17; // ค่าเริ่มต้น
        end else if (set_enable) begin
            // ใช้ค่าใหม่จากการตั้งค่า
            hours <= set_hours;
            minutes <= set_minutes;
            seconds <= 0; // รีเซ็ตวินาที
        end else begin
            // การนับเวลาปกติ
            seconds <= seconds + 1;
            if (seconds == 59) begin
                seconds <= 0;
                minutes <= minutes + 1;
                if (minutes == 59) begin
                    minutes <= 0;
                    hours <= hours + 1;
                    if (hours == 23) begin
                        hours <= 0;
                    end
                end
            end
        end
    end
endmodule
