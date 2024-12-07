module combined_system (
    input clock,                  // Global clock
    input reset,                  // Reset button at W15
    input AMPM_Toggle_Button,     // AM/PM toggle button at R2
    input mode_switch,            // Mode switch for Security System
    input [9:0] sw,               // Security switches
    input [3:0] code_sw,          // Security code switches
    input ir_sensor,              // IR sensor
    output buzzer,                // Security buzzer
    output [3:0] led_ext,         // External LEDs for Security System
    output [15:0] led,            // Main LEDs (shared)
    output [2:0] status_led       // Security status LEDs
);

    wire AM_PM_LED;               // Internal signal for AM/PM status
    wire lockdown_mode;           // Internal signal from Security System
    
    // Instantiate the Digital Clock
    Digital_Clock clock_system (
        .clk(clock),
        .IO_BTN_C(IO_BTN_C),
        .IO_BTN_U(IO_BTN_U),
        .IO_BTN_L(IO_BTN_L),
        .IO_BTN_R(IO_BTN_R),
        .IO_BTN_D(IO_BTN_D),
        .AMPM_Toggle_Button(AMPM_Toggle_Button),
        .AM_PM_LED(AM_PM_LED) // Output AM/PM status
    );

    // Instantiate the Security System
    security_system sec_sys (
        .clock(clock),
        .sw(sw),
        .code_sw(code_sw),
        .mode_switch(mode_switch),
        .reset(reset),
        .ir_sensor(ir_sensor),
        .buzzer(buzzer),
        .led_ext(led_ext),
        .led(led),           // Shared LED array
        .status_led(status_led),
        .lockdown_mode(lockdown_mode) // Internal signal for Lockdown status
    );

    // Override `led[15]` for AM/PM or Lockdown status
    assign led[15] = (lockdown_mode) ? 1'b1 : AM_PM_LED;

endmodule
