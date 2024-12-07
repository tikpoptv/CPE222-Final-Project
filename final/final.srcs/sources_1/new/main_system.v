module security_clock_system (
    input clock,
    input reset,
    input [9:0] sw,
    input [3:0] code_sw,
    input mode_switch,
    input ir_sensor,
    output reg buzzer,
    output reg [3:0] led_ext,
    output reg [15:0] led,
    output reg [2:0] status_led,
    output [3:0] an,           // สำหรับ 7-segment display
    output [6:0] seg           // สำหรับ 7-segment display
);

    // Internal registers
    reg [3:0] random_pattern;        // รหัสสำหรับปลดล็อค
    reg security_triggered;
    reg lockdown_mode;
    reg ir_detected;
    reg [24:0] counter;
    reg prev_mode_switch;
    wire slow_clock;                 // นาฬิกาที่ลดความถี่ (500 Hz สำหรับ Multiplexing)
    wire [5:0] seconds, minutes;
    wire [4:0] hours;
    wire [5:0] unused_signals = sw[9:4]; // ไม่ได้ใช้ในระบบ
    
    // Clock Divider สำหรับลดความถี่
    clock_divider clk_div (
        .clock_in(clock),
        .reset(reset),
        .clock_out(slow_clock)
    );

    // Time Keeping Module
    clock_time time_keeper (
        .clock(slow_clock),
        .reset(reset),
        .seconds(seconds),
        .minutes(minutes),
        .hours(hours)
    );

    // 7-Segment Display
    seven_seg_display display (
        .clock(clock),
        .reset(reset),
        .digit0(seconds % 10),      // หลักหน่วยของวินาที
        .digit1(seconds / 10),      // หลักสิบของวินาที
        .digit2(minutes % 10),      // หลักหน่วยของนาที
        .digit3(minutes / 10),      // หลักสิบของนาที
        .an(an),
        .seg(seg)
    );

    // Security System Logic
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            random_pattern <= 4'b1010;      // ตั้งรหัสเริ่มต้น
            security_triggered <= 1'b0;    // ไม่มีการแจ้งเตือน
            lockdown_mode <= 1'b0;         // ไม่อยู่ในสถานะล็อค
            ir_detected <= 1'b0;           // ไม่มีการตรวจจับ
            counter <= 25'b0;              // รีเซ็ตตัวนับ
            buzzer <= 1'b1;                // ปิดเสียงแจ้งเตือน
            led_ext <= 4'b0;               // ดับไฟ LED ภายนอก
            led <= 16'b0;                  // ดับไฟ LED
            prev_mode_switch <= 1'b0;      // รีเซ็ตสถานะสวิตช์โหมด
            status_led <= 3'b001;          // สถานะปกติ
        end else begin
            if (mode_switch && !prev_mode_switch) begin
                // เมื่อเปลี่ยนโหมด รีเซ็ตสถานะ
                ir_detected <= 1'b0;        
                security_triggered <= 1'b0; 
                lockdown_mode <= 1'b0;      
                buzzer <= 1'b1;             
                led <= 16'b0;               
                led_ext <= 4'b0;            
                counter <= 25'b0;           
            end
            prev_mode_switch <= mode_switch;

            if (mode_switch) begin
                // โหมดการรักษาความปลอดภัย
                status_led <= 3'b010;
                led[5] <= 1'b1; // แสดงสถานะเปิดระบบ

                if (!ir_sensor && !ir_detected && !lockdown_mode) begin
                    ir_detected <= 1'b1; // ตรวจจับการบุกรุก
                end

                if (ir_detected && !security_triggered) begin
                    security_triggered <= 1'b1; // เริ่มการแจ้งเตือน
                end

                if (security_triggered && !lockdown_mode) begin
                    lockdown_mode <= 1'b1; // เปิดสถานะล็อค
                end

                if (lockdown_mode) begin
                    // เมื่ออยู่ในสถานะล็อค
                    status_led <= 3'b100;  // แสดงสถานะล็อค
                    counter <= counter + 1;

                    // สลับสถานะไฟ LED
                    if (counter[24]) begin
                        led[15:10] <= ~6'b0;
                    end else begin
                        led[15:10] <= 6'b0;
                    end

                    // แสดงรหัสที่ป้อนบน LED
                    led[6] <= code_sw[0];
                    led[7] <= code_sw[1];
                    led[8] <= code_sw[2];
                    led[9] <= code_sw[3];

                    led_ext <= 4'b1111; // เปิดไฟ LED ภายนอก
                    buzzer <= 1'b0;    // เปิดเสียงแจ้งเตือน

                    if (code_sw == random_pattern) begin
                        // หากป้อนรหัสถูกต้อง
                        ir_detected <= 1'b0;        
                        security_triggered <= 1'b0; 
                        lockdown_mode <= 1'b0;      
                        led <= 16'b0;               
                        led_ext <= 4'b0;            
                        buzzer <= 1'b1;             
                        counter <= 25'b0;           
                        status_led <= 3'b010;       // สถานะปลอดภัย
                    end
                end
            end else begin
                // โหมดปกติ
                security_triggered <= 1'b0;
                lockdown_mode <= 1'b0;
                buzzer <= 1'b1;
                counter <= 0;
                ir_detected <= 1'b0; 
                led <= 16'b0;        
                led_ext <= sw[3:0];  
                status_led <= 3'b001;
            end
        end
    end
endmodule
