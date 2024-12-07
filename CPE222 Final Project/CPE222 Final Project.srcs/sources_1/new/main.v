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
    output reg [2:0] status_led
);

    reg [3:0] random_pattern;
    reg security_triggered;
    reg lockdown_mode;
    reg ir_detected;
    reg [24:0] counter;
    reg prev_mode_switch;

    wire [5:0] unused_signals = sw[9:4];

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            random_pattern <= 4'b1010;
            security_triggered <= 1'b0;   
            lockdown_mode <= 1'b0;      
            ir_detected <= 1'b0;        
            counter <= 25'b0;
            buzzer <= 1'b1;             
            led_ext <= 4'b0;            
            led <= 16'b0;               
            prev_mode_switch <= 1'b0;  
            status_led <= 3'b001;
        end else begin
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

            if (mode_switch) begin
                status_led <= 3'b010;
                led[5] <= 1'b1;
                
                if (!ir_sensor && !ir_detected && !lockdown_mode) begin
                    ir_detected <= 1'b1;
                end

                if (ir_detected && !security_triggered) begin
                    security_triggered <= 1'b1;
                end

                if (security_triggered && !lockdown_mode) begin
                    lockdown_mode <= 1'b1;
                end

                if (lockdown_mode) begin
                    status_led <= 3'b100;
                    counter <= counter + 1;
                    if (counter[24]) begin
                        led[15:10] <= ~6'b0;
                    end else begin
                        led[15:10] <= 6'b0;
                    end

                    led[6] <= code_sw[0];
                    led[7] <= code_sw[1];
                    led[8] <= code_sw[2];
                    led[9] <= code_sw[3];

                    led_ext <= 4'b1111;
                    buzzer <= 1'b0;

             
                    if (code_sw == random_pattern) begin
                        ir_detected <= 1'b0;        
                        security_triggered <= 1'b1; 
                        lockdown_mode <= 1'b0;      
                        led <= 16'b0;               
                        led_ext <= 4'b0;            
                        buzzer <= 1'b1;             
                        counter <= 25'b0;       
                        status_led <= 3'b010;     
                    end
                end else if (security_triggered && !lockdown_mode) begin
                    status_led <= 3'b010;
                    buzzer <= 1'b1;
                end
            end else begin
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
