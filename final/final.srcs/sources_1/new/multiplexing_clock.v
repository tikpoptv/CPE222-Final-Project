module multiplexing_clock (
    input clock_in,  
    input reset,
    output reg clock_out
);
    reg [15:0] counter;

    always @(posedge clock_in or posedge reset) begin
        if (reset) begin
            counter <= 16'b0;
            clock_out <= 0;
        end else begin
            counter <= counter + 1;
            if (counter == 50_000) begin // ลดความถี่
                clock_out <= ~clock_out;
                counter <= 0;
            end
        end
    end
endmodule
