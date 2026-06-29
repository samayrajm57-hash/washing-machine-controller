//==========================================================
// washing_machine_top.v
// Top level: connects the control FSM and the datapath timer.
//==========================================================
module washing_machine_top #(
    parameter T_FILL  = 4,
    parameter T_WASH  = 8,
    parameter T_DRAIN = 4,
    parameter T_RINSE = 6,
    parameter T_SPIN  = 6,
    parameter T_DONE  = 2,
    parameter TW      = 8
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire        door_closed,
    output wire        water_valve,
    output wire        motor_wash,
    output wire        drain_pump,
    output wire        motor_spin,
    output wire        done,
    output wire [2:0]  state_out
);

    wire           load_timer;
    wire [TW-1:0]  duration;
    wire           timer_done;

    wm_fsm #(
        .T_FILL (T_FILL), .T_WASH (T_WASH),  .T_DRAIN(T_DRAIN),
        .T_RINSE(T_RINSE),.T_SPIN (T_SPIN),  .T_DONE (T_DONE), .TW(TW)
    ) u_fsm (
        .clk(clk), .rst(rst), .start(start), .door_closed(door_closed),
        .timer_done(timer_done),
        .load_timer(load_timer), .duration(duration),
        .water_valve(water_valve), .motor_wash(motor_wash),
        .drain_pump(drain_pump),   .motor_spin(motor_spin),
        .done(done), .state_out(state_out)
    );

    timer #(.WIDTH(TW)) u_timer (
        .clk(clk), .rst(rst),
        .load(load_timer), .duration(duration),
        .done(timer_done)
    );

endmodule
