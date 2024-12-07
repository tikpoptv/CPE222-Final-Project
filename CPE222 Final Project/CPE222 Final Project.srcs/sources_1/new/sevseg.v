module sevseg (
    input clk,
    input [3:0] binary_input_0,
    input [3:0] binary_input_1,
    input [3:0] binary_input_2,
    input [3:0] binary_input_3,
    output reg [3:0] IO_SSEG_SEL,
    output reg [6:0] IO_SSEG
);

    reg [1:0] current_LED = 0;
    reg [18:0] counter = 0;
    parameter max_counter = 500000;

    always @(posedge clk) begin
        if (counter < max_counter) begin
            counter <= counter + 1;
        end else begin
            counter <= 0;
            current_LED <= current_LED + 1;
        end

        case (current_LED)
            0: IO_SSEG_SEL <= 4'b1110;
            1: IO_SSEG_SEL <= 4'b1101;
            2: IO_SSEG_SEL <= 4'b1011;
            3: IO_SSEG_SEL <= 4'b0111;
        endcase

        case (current_LED)
            0: IO_SSEG <= binary_input_0;
            1: IO_SSEG <= binary_input_1;
            2: IO_SSEG <= binary_input_2;
            3: IO_SSEG <= binary_input_3;
        endcase
    end
endmodule
