//==========================================================
// timer.v
// Reusable down-counter timer.
// On 'load', latches (duration-1) and counts down to 0.
// 'done' is high for the cycle when count == 0.
//==========================================================
module timer #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,        // synchronous, active-high
    input  wire             load,       // 1-cycle pulse: start timing
    input  wire [WIDTH-1:0] duration,   // number of clock cycles
    output wire             done         // high when timing elapsed
);

    reg [WIDTH-1:0] count;

    always @(posedge clk) begin
        if (rst)
            count <= {WIDTH{1'b0}};
        else if (load)
            count <= duration - 1'b1;   // N cycles => load N-1
        else if (!done)
            count <= count - 1'b1;
    end

    assign done = (count == {WIDTH{1'b0}});

endmodule
