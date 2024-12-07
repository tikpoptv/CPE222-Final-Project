module clock_divider (
    input clock_in,
    input reset,
    output reg clock_out
);
    reg [26:0] counter;

    always @(posedge clock_in or posedge reset) begin
        if (reset) begin
            counter <= 27'b0;
            clock_out <= 0;
        end else begin
            counter <= counter + 1;
            if (counter == 50_000_000) begin // 50 MHz clock -> 1 Hz
                clock_out <= ~clock_out;
                counter <= 0;
            end
        end
    end
endmodule
