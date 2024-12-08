module security_clock_system (
    input clock,
    input reset,
    input [9:0] sw,
    input [3:0] code_sw,
    input mode_switch,
    input ir_sensor,
    input alarm_switch,
    input time_adjust_button,   // เพิ่ม input สำหรับสวิตช์นาฬิกาปลุก
    output reg buzzer,
    output reg [3:0] led_ext,
    output reg [15:0] led,
    output reg [2:0] status_led,
    output [3:0] an,
    output [6:0] seg
);

    reg [3:0] random_pattern;       
    reg security_triggered;
    reg lockdown_mode;
    reg ir_detected;
    reg [24:0] counter;
    reg prev_mode_switch;
    reg alarm_enabled;  // สถานะเปิดใช้งานนาฬิกาปลุก
    wire slow_clock;
    wire multiplexing_clock_out;
    wire [5:0] minutes;
    wire [4:0] hours;
    reg [5:0] alarm_minutes = 6'd1;  // ค่าเริ่มต้น: นาทีปลุก
    reg [4:0] alarm_hours = 5'd17;   // ค่าเริ่มต้น: ชั่วโมงปลุก
    reg prev_time_adjust_button = 1'b0;  // สำหรับตรวจจับการกดปุ่ม
    reg [24:0] buzzer_counter;  // Counter สำหรับควบคุมความถี่การเปิด/ปิด Buzzer
    reg buzzer_toggle;          // สถานะของเสียง (ดัง-ปิด)

    

    // Clock Divider for 1 Hz
    clock_divider clk_div (
        .clock_in(clock),
        .reset(reset),
        .clock_out(slow_clock)
    );

    // Multiplexing Clock Divider
    multiplexing_clock mux_clk (
        .clock_in(clock),
        .reset(reset),
        .clock_out(multiplexing_clock_out)
    );

    // Clock Time
    clock_time time_keeper (
        .clock(slow_clock),
        .reset(reset),
        .minutes(minutes),
        .hours(hours)
    );

    // Seven Segment Display
    seven_seg_display display (
        .clk(multiplexing_clock_out),  // ใช้ clock ที่ลดความถี่แล้ว
        .rst(reset),
        .dig0(minutes % 10),           // หลักหน่วยของนาที
        .dig1(minutes / 10),           // หลักสิบของนาที
        .dig2(hours % 10),             // หลักหน่วยของชั่วโมง
        .dig3(hours / 10),             // หลักสิบของชั่วโมง
        .an(an),
        .seg(seg)
    );
        
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            // ค่าเริ่มต้นทั้งหมด
            alarm_enabled <= 1'b0;      
            led[14] <= 1'b0;           
            buzzer <= 1'b1;            
            buzzer_toggle <= 1'b1;     // เริ่มต้น Buzzer ปิด
            buzzer_counter <= 25'b0;  // รีเซ็ต Counter
            random_pattern <= 4'b1010; 
            security_triggered <= 1'b0;   
            lockdown_mode <= 1'b0;      
            ir_detected <= 1'b0;        
            counter <= 25'b0;
            led_ext <= 4'b0;            
            led <= 16'b0;               
            prev_mode_switch <= 1'b0;  
            status_led <= 3'b001;
            alarm_minutes <= 6'd1;       // นาทีปลุกเริ่มต้น
            alarm_hours <= 5'd17;        // ชั่วโมงปลุกเริ่มต้น
            prev_time_adjust_button <= 1'b0; // เก็บสถานะปุ่มก่อนหน้า
        end else begin
            // ควบคุม Counter สำหรับ Buzzer
            buzzer_counter <= buzzer_counter + 1;
    
            // กระพริบ Buzzer ในโหมดนาฬิกาปลุก
            if (buzzer_counter[22]) begin  // ปรับค่าเพื่อตั้งช่วงเวลาสลับ (22 บิต = 2^22 รอบสัญญาณ)
                buzzer_toggle <= ~buzzer_toggle;  // Toggle สถานะเสียง
                buzzer_counter <= 25'b0;         // รีเซ็ต Counter เมื่อถึงขอบเขต
            end
    
            // ตรวจสอบสถานะของ alarm_switch
            if (alarm_switch) begin
                alarm_enabled <= 1'b1;
                led[14] <= 1'b1; // LED ติดเมื่อเปิดสวิตช์
            end else begin
                alarm_enabled <= 1'b0;
                led[14] <= 1'b0; // LED ดับเมื่อปิดสวิตช์
            end
    
            // ตรวจจับการกดปุ่ม time_adjust_button
            if (time_adjust_button && !prev_time_adjust_button) begin
                if (alarm_minutes == 6'd59) begin
                    alarm_minutes <= 6'd0; // รีเซ็ตนาทีเมื่อเกิน 59
                    if (alarm_hours == 5'd23) begin
                        alarm_hours <= 5'd0; // รีเซ็ตชั่วโมงเมื่อเกิน 23
                    end else begin
                        alarm_hours <= alarm_hours + 1;
                    end
                end else begin
                    alarm_minutes <= alarm_minutes + 1;
                end
            end
            prev_time_adjust_button <= time_adjust_button;
    
            // **การทำงานของ mode_switch (โหมดรักษาความปลอดภัย)**
            if (mode_switch) begin
                status_led <= 3'b010;    // แสดงสถานะในโหมดรักษาความปลอดภัย
                led[5] <= 1'b1;         // LED ติดแสดงสถานะโหมด
                lockdown_mode <= 1'b1;  // เปิดใช้งานโหมด Lockdown
    
                if (!ir_sensor && !ir_detected) begin
                    ir_detected <= 1'b1; 
                end
    
                if (ir_detected && !security_triggered) begin
                    security_triggered <= 1'b1; 
                end
    
                if (security_triggered) begin
                    status_led <= 3'b100; // แสดงสถานะ Lockdown
                    counter <= counter + 1;
    
                    if (counter[24]) begin
                        led[15:10] <= ~6'b0; // กระพริบ LED
                    end else begin
                        led[15:10] <= 6'b0;
                    end
    
                    led[6] <= code_sw[0];
                    led[7] <= code_sw[1];
                    led[8] <= code_sw[2];
                    led[9] <= code_sw[3];
                    led_ext <= 4'b1111;
    
                    if (code_sw == random_pattern) begin
                        // ปลดล็อกเมื่อรหัสตรง
                        ir_detected <= 1'b0;        
                        security_triggered <= 1'b0; 
                        lockdown_mode <= 1'b0;      
                        led <= 16'b0;               
                        led_ext <= 4'b0;            
                        counter <= 25'b0;           
                        status_led <= 3'b010;       
                    end
                end
            end else begin
                // รีเซ็ตสถานะไฟเมื่อออกจากโหมด
                security_triggered <= 1'b0;
                lockdown_mode <= 1'b0;  
                counter <= 25'b0;
                led[5] <= 1'b0;          // ดับ LED ที่แสดงสถานะโหมด
                status_led <= 3'b001;    // กลับสู่สถานะปกติ
                led_ext <= sw[3:0];
                ir_detected <= 1'b0;
                // ควบคุม led_ext[0] (ไฟรั้วบ้าน)
                if ((hours == 5'd17) && (minutes == 6'd2)) begin
                    led_ext[0] <= 1'b1; // เปิดไฟรั้วบ้าน
                end else if ((hours == 5'd17) && (minutes == 6'd4)) begin
                    led_ext[0] <= 1'b0; // ปิดไฟรั้วบ้าน
                end else begin
                    led_ext[0] <= sw[0]; // ควบคุมตามสวิตช์เมื่อไม่อยู่ในช่วงเวลาอัตโนมัติ
                end
    
                // ควบคุมไฟภายนอกดวงอื่น (led_ext[3:1])
                if ((hours == 5'd17) && (minutes == 6'd2)) begin
                    led_ext[3:1] <= 3'b000; // ดับไฟภายนอกดวงอื่น
                end else if ((hours == 5'd17) && (minutes == 6'd4)) begin
                    led_ext[3:1] <= sw[3:1]; // เปิดไฟตามสวิตช์ที่เปิดอยู่
                end else begin
                    led_ext[3:1] <= sw[3:1]; // เปิดไฟตามสวิตช์ในเวลาปกติ
                end
            end
    
            // ควบคุม Buzzer ให้ทำงานเมื่อใดก็ตามที่ระบบใดระบบหนึ่งเปิดใช้งาน
            if ((alarm_switch && (hours == alarm_hours) && (minutes == alarm_minutes))) begin
                buzzer <= buzzer_toggle; // นาฬิกาปลุก: กระพริบเสียง
            end else if (mode_switch && security_triggered) begin
                buzzer <= 1'b0;          // ระบบรักษาความปลอดภัย: เสียงดังต่อเนื่อง
            end else begin
                buzzer <= 1'b1;          // ปิดเสียงในกรณีอื่น
            end
        end
    end
    
endmodule
