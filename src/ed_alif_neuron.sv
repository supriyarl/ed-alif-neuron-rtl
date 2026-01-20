module ed_alif_neuron #(
    parameter int V_WIDTH = 12,     // Voltage bit width
    parameter int W_WIDTH = 8,      // Adaptation bit width
    parameter int LEAK_SHIFT = 4,   // Leakage factor: V >> LEAK_SHIFT
    parameter logic [V_WIDTH-1:0] V_INIT = 12'sd0,  // Initial voltage
    parameter logic [W_WIDTH-1:0] W_INIT = 8'd0     // Initial adaptation
)(
    input  logic                    clk,
    input  logic                    rst,              // synchronous reset
    input  logic                    enable,           // neuron scheduled
    input  logic signed [V_WIDTH-1:0] I_syn,        // synaptic input
    input  logic signed [V_WIDTH-1:0] V_th,         // base threshold
    input  logic signed [V_WIDTH-1:0] V_reset,      // reset voltage
    input  logic        [W_WIDTH-1:0] B,            // adaptation increment (spike)
    input  logic        [W_WIDTH-1:0] D,            // adaptation decay (input event)
    input  logic                    input_event,     // neuron received spike
    input  logic        [3:0]       refract_cnt,     // refractory counter (external)

    output logic                    spike,
    output logic signed [V_WIDTH-1:0] V_out,
    output logic        [W_WIDTH-1:0] W_out
);

    // -------------------------------
    // Neuron state
    // -------------------------------
    logic signed [V_WIDTH-1:0] V_reg;   // membrane
    logic        [W_WIDTH-1:0] W_reg;   // adaptation

    // -------------------------------
    // Combinational datapath
    // -------------------------------
    logic signed [V_WIDTH-1:0] leak;
    logic signed [V_WIDTH-1:0] V_int;
    logic signed [V_WIDTH:0]   thresh_eff;  // Extra bit for addition

    assign leak       = V_reg >>> LEAK_SHIFT;     // Configurable leakage
    assign thresh_eff = $signed({1'b0, V_th}) + $signed({1'b0, W_reg});

    assign V_int = V_reg + I_syn - leak - $signed({1'b0, W_reg});

    // Spike only if not in refractory (external counter management)
    assign spike = (enable & (V_int >= thresh_eff) & (refract_cnt == 4'd0));

    // -------------------------------
    // Next-state logic
    // -------------------------------
    logic signed [V_WIDTH-1:0] V_next;
    logic        [W_WIDTH-1:0] W_next;

    always_comb begin
        V_next = V_reg;
        W_next = W_reg;

        if (enable) begin
            if (spike) begin
                V_next = V_reset;
                W_next = (W_reg + B > {W_WIDTH{1'b1}}) ? {W_WIDTH{1'b1}} : W_reg + B;
            end else begin
                V_next = V_int;
                if (input_event) begin
                    W_next = (W_reg > D) ? W_reg - D : '0;
                end
            end
        end
    end

    // -------------------------------
    // State registers
    // -------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            V_reg <= V_INIT;
            W_reg <= W_INIT;
        end else begin
            V_reg <= V_next;
            W_reg <= W_next;
        end
    end

    assign V_out = V_reg;
    assign W_out = W_reg;

endmodule
