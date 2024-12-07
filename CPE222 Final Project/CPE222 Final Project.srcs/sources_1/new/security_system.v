module security_system (
    input clock,
    input [9:0] sw,
    input [3:0] code_sw,
    input mode_switch,
    input reset,
    input ir_sensor,
    output reg buzzer,
    output reg [3:0] led_ext,
    output reg [15:0] led,
    output reg [2:0] status_led,
    output reg lockdown_mode // Export Lockdown status
);

    // Internal Registers
    reg [3:0] random_pattern = 4'b1010; // Security code
    reg security_triggered;             // Security breach flag
    reg ir_detected;                    // IR detection flag
    reg [24:0] counter;                 // Counter for LED blinking
    reg prev_mode_switch;               // Previous mode switch state

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            // Reset all registers
            random_pattern <= 4'b1010;  // Default security code
            security_triggered <= 1'b0; // No security breach
            lockdown_mode <= 1'b0;      // No lockdown
            ir_detected <= 1'b0;        // No IR detection
            buzzer <= 1'b1;             // Buzzer off
            led_ext <= 4'b0;            // External LEDs off
            led <= 16'b0;               // Main LEDs off
            status_led <= 3'b001;       // Normal mode indicator
            counter <= 25'b0;           // Counter reset
            prev_mode_switch <= 1'b0;   // Reset mode switch flag
        end else begin
            // Handle mode switching
            if (mode_switch && !prev_mode_switch) begin
                ir_detected <= 1'b0;
                security_triggered <= 1'b0;
                lockdown_mode <= 1'b0;
                buzzer <= 1'b1;
                led <= 16'b0;
                led_ext <= 4'b0;
                counter <= 25'b0;
            end
            prev_mode_switch <= mode_switch;

            // Security mode active
            if (mode_switch) begin
                status_led <= 3'b010; // Security mode indicator
                led[5] <= 1'b1;

                // IR Sensor detection
                if (!ir_sensor && !ir_detected && !lockdown_mode) begin
                    ir_detected <= 1'b1;
                end

                // Security triggered
                if (ir_detected && !security_triggered) begin
                    security_triggered <= 1'b1;
                end

                // Lockdown initiated
                if (security_triggered && !lockdown_mode) begin
                    lockdown_mode <= 1'b1;
                end

                // Lockdown mode behavior
                if (lockdown_mode) begin
                    status_led <= 3'b100; // Lockdown indicator
                    counter <= counter + 1;

                    // Blinking LEDs during lockdown
                    if (counter[24]) begin
                        led[15:10] <= ~6'b0;
                    end else begin
                        led[15:10] <= 6'b0;
                    end

                    // Display security code
                    led[6] <= code_sw[0];
                    led[7] <= code_sw[1];
                    led[8] <= code_sw[2];
                    led[9] <= code_sw[3];

                    // External LEDs and buzzer
                    led_ext <= 4'b1111;
                    buzzer <= 1'b0;

                    // Check if code is correct
                    if (code_sw == random_pattern) begin
                        ir_detected <= 1'b0;
                        security_triggered <= 1'b0;
                        lockdown_mode <= 1'b0;
                        led <= 16'b0;
                        led_ext <= 4'b0;
                        buzzer <= 1'b1;
                        counter <= 25'b0;
                        status_led <= 3'b010;
                    end
                end else if (security_triggered && !lockdown_mode) begin
                    status_led <= 3'b010; // Security mode but not lockdown
                    buzzer <= 1'b1;
                end
            end else begin
                // Normal mode behavior
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
