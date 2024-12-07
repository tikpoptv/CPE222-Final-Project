module seven_seg_display (
    input clk,
    input rst,
    input [3:0] dig0,
    input [3:0] dig1,
    input [3:0] dig2,
    input [3:0] dig3,
    output reg [3:0] an,
    output reg [6:0] seg
);
    reg [1:0] mux_state;
    wire [6:0] seg0, seg1, seg2, seg3;

    seven_seg_decoder dec0 (.digit(dig0), .seg(seg0));
    seven_seg_decoder dec1 (.digit(dig1), .seg(seg1));
    seven_seg_decoder dec2 (.digit(dig2), .seg(seg2));
    seven_seg_decoder dec3 (.digit(dig3), .seg(seg3));

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mux_state <= 0;
            an <= 4'b1111;
        end else begin
            mux_state <= mux_state + 1;
            case (mux_state)
                2'b00: begin
                    an <= 4'b1110;
                    seg <= seg0;
                end
                2'b01: begin
                    an <= 4'b1101;
                    seg <= seg1;
                end
                2'b10: begin
                    an <= 4'b1011;
                    seg <= seg2;
                end
                2'b11: begin
                    an <= 4'b0111;
                    seg <= seg3;
                end
            endcase
        end
    end
endmodule
