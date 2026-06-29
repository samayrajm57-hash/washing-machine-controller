`timescale 1ns/1ps
//==========================================================
// tb_washing_machine.v
// Self-checking testbench: safety interlock, full cycle, reset.
//==========================================================
module tb_washing_machine;

    reg  clk, rst, start, door_closed;
    wire water_valve, motor_wash, drain_pump, motor_spin, done;
    wire [2:0] state_out;

    // Small durations so the whole cycle simulates quickly
    washing_machine_top #(
        .T_FILL(3), .T_WASH(4), .T_DRAIN(3),
        .T_RINSE(3), .T_SPIN(4), .T_DONE(2)
    ) dut (
        .clk(clk), .rst(rst), .start(start), .door_closed(door_closed),
        .water_valve(water_valve), .motor_wash(motor_wash),
        .drain_pump(drain_pump),   .motor_spin(motor_spin),
        .done(done), .state_out(state_out)
    );

    // 100 MHz clock (10 ns period)
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Decode state to a readable name
    reg [8*11:1] sname;
    always @(*) begin
        case (state_out)
            3'd0: sname = "IDLE";
            3'd1: sname = "FILL_WATER";
            3'd2: sname = "WASH";
            3'd3: sname = "DRAIN";
            3'd4: sname = "RINSE";
            3'd5: sname = "SPIN";
            3'd6: sname = "COMPLETE";
            default: sname = "UNKNOWN";
        endcase
    end

    initial begin
        $dumpfile("wm.vcd");
        $dumpvars(0, tb_washing_machine);

        // ---- Reset ----
        rst = 1; start = 0; door_closed = 0;
        repeat (2) @(posedge clk);
        rst = 0;

        // ---- TEST 1: Start with door OPEN -> must stay IDLE ----
        @(posedge clk);
        start = 1; door_closed = 0;
        @(posedge clk);
        start = 0;
        repeat (2) @(posedge clk);
        if (state_out !== 3'd0)
            $display("TEST1 FAIL: started with door open!");
        else
            $display("TEST1 PASS: stayed IDLE with door open.");

        // ---- TEST 2: Close door, start -> full cycle ----
        door_closed = 1;
        start = 1;
        @(posedge clk);
        start = 0;                 // single-cycle press

        wait (done == 1'b1);       // run until COMPLETE
        $display("TEST2: reached COMPLETE at t=%0t", $time);

        wait (state_out == 3'd0);  // returns to IDLE
        $display("TEST2 PASS: returned to IDLE at t=%0t", $time);

        // ---- TEST 3: Reset in the middle of a cycle ----
        start = 1; @(posedge clk); start = 0;
        repeat (6) @(posedge clk); // somewhere mid-cycle
        rst = 1;  @(posedge clk);  // assert reset
        rst = 0;
        if (state_out === 3'd0)
            $display("TEST3 PASS: reset forced IDLE.");
        else
            $display("TEST3 FAIL: state=%0d after reset", state_out);

        repeat (4) @(posedge clk);
        $finish;
    end

    // Live trace
    initial begin
        $display(" TIME  STATE        VALVE WASH DRAIN SPIN DONE");
        $monitor("%5t  %-11s   %b     %b    %b     %b    %b",
                 $time, sname, water_valve, motor_wash,
                 drain_pump, motor_spin, done);
    end

endmodule
