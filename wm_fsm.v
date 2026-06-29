//==========================================================
// wm_fsm.v
// Washing-machine control FSM (Moore).
// Three blocks: state register, next-state logic, output logic.
// Drives the timer via load_timer/duration, reacts to timer_done.
//==========================================================
module wm_fsm #(
    parameter T_FILL  = 4,
    parameter T_WASH  = 8,
    parameter T_DRAIN = 4,
    parameter T_RINSE = 6,
    parameter T_SPIN  = 6,
    parameter T_DONE  = 2,
    parameter TW      = 8           // timer width
)(
    input  wire           clk,
    input  wire           rst,
    input  wire           start,
    input  wire           door_closed,
    input  wire           timer_done,
    output reg            load_timer,
    output reg  [TW-1:0]  duration,
    output reg            water_valve,
    output reg            motor_wash,
    output reg            drain_pump,
    output reg            motor_spin,
    output reg            done,
    output wire [2:0]     state_out
);

    // ---- State encoding ----
    localparam IDLE       = 3'd0;
    localparam FILL_WATER = 3'd1;
    localparam WASH       = 3'd2;
    localparam DRAIN      = 3'd3;
    localparam RINSE      = 3'd4;
    localparam SPIN       = 3'd5;
    localparam COMPLETE   = 3'd6;

    reg [2:0] state, next_state;

    // ---- 1) State register ----
    always @(posedge clk) begin
        if (rst) state <= IDLE;
        else     state <= next_state;
    end

    // ---- 2) Next-state logic ----
    always @(*) begin
        case (state)
            IDLE:       next_state = (start && door_closed) ? FILL_WATER : IDLE;
            FILL_WATER: next_state = timer_done ? WASH     : FILL_WATER;
            WASH:       next_state = timer_done ? DRAIN    : WASH;
            DRAIN:      next_state = timer_done ? RINSE    : DRAIN;
            RINSE:      next_state = timer_done ? SPIN     : RINSE;
            SPIN:       next_state = timer_done ? COMPLETE : SPIN;
            COMPLETE:   next_state = timer_done ? IDLE     : COMPLETE;
            default:    next_state = IDLE;
        endcase
    end

    // ---- 3) Duration of the state we are ENTERING ----
    always @(*) begin
        case (next_state)
            FILL_WATER: duration = T_FILL;
            WASH:       duration = T_WASH;
            DRAIN:      duration = T_DRAIN;
            RINSE:      duration = T_RINSE;
            SPIN:       duration = T_SPIN;
            COMPLETE:   duration = T_DONE;
            default:    duration = {TW{1'b0}};
        endcase
    end

    // Load the timer for exactly one cycle on entry to any timed state.
    // (Never load when entering IDLE, whose duration is 0.)
    always @(*) begin
        load_timer = (state != next_state) && (next_state != IDLE);
    end

    // ---- 4) Output logic (Moore: depends only on current state) ----
    always @(*) begin
        water_valve = 1'b0;
        motor_wash  = 1'b0;
        drain_pump  = 1'b0;
        motor_spin  = 1'b0;
        done        = 1'b0;
        case (state)
            FILL_WATER: water_valve = 1'b1;
            WASH:       motor_wash  = 1'b1;
            DRAIN:      drain_pump  = 1'b1;
            RINSE:      begin water_valve = 1'b1; motor_wash = 1'b1; end
            SPIN:       begin drain_pump  = 1'b1; motor_spin = 1'b1; end
            COMPLETE:   done = 1'b1;
            default:    ; // IDLE: all outputs 0
        endcase
    end

    assign state_out = state;

endmodule
