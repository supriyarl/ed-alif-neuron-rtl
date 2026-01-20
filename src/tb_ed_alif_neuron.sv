`timescale 1ns/1ps

module tb_ed_alif_neuron;

  // -------------------------------------------------
  // Parameters (match DUT defaults)
  // -------------------------------------------------
  localparam int V_WIDTH    = 12;
  localparam int W_WIDTH    = 8;
  localparam int LEAK_SHIFT = 4;

  // -------------------------------------------------
  // DUT I/O
  // -------------------------------------------------
  logic                     clk;
  logic                     rst;
  logic                     enable;
  logic signed [V_WIDTH-1:0] I_syn;
  logic signed [V_WIDTH-1:0] V_th;
  logic signed [V_WIDTH-1:0] V_reset;
  logic        [W_WIDTH-1:0] B;
  logic        [W_WIDTH-1:0] D;
  logic                     input_event;
  logic        [3:0]         refract_cnt;

  logic                     spike;
  logic signed [V_WIDTH-1:0] V_out;
  logic        [W_WIDTH-1:0] W_out;

  // -------------------------------------------------
  // Instantiate DUT
  // -------------------------------------------------
  ed_alif_neuron #(
    .V_WIDTH(V_WIDTH),
    .W_WIDTH(W_WIDTH),
    .LEAK_SHIFT(LEAK_SHIFT),
    .V_INIT(12'sd0),
    .W_INIT(8'd0)
  ) dut (
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .I_syn(I_syn),
    .V_th(V_th),
    .V_reset(V_reset),
    .B(B),
    .D(D),
    .input_event(input_event),
    .refract_cnt(refract_cnt),
    .spike(spike),
    .V_out(V_out),
    .W_out(W_out)
  );

  // -------------------------------------------------
  // Clock Generation
  // -------------------------------------------------
  initial clk = 0;
  always #5 clk = ~clk; // 100 MHz

  // -------------------------------------------------
  // Waveform Dump
  // -------------------------------------------------
  initial begin
    $dumpfile("tb_ed_alif_neuron.vcd");
    $dumpvars(0, tb_ed_alif_neuron);
  end

  // -------------------------------------------------
  // Reset Task
  // -------------------------------------------------
  task automatic apply_reset();
    begin
      rst          = 1;
      enable       = 0;
      I_syn        = '0;
      V_th         = 12'sd100;
      V_reset      = -12'sd20;
      B            = 8'd5;
      D            = 8'd2;
      input_event  = 0;
      refract_cnt  = 0;

      @(posedge clk);
      @(posedge clk);
      rst = 0;
      @(posedge clk);

      // Self-check
      assert(V_out == 0) else $error("RESET FAIL: V_out != 0");
      assert(W_out == 0) else $error("RESET FAIL: W_out != 0");

      $display("[%0t] Reset complete", $time);
    end
  endtask

  // -------------------------------------------------
  // Single Step Task
  // -------------------------------------------------
  task automatic step_neuron(
    input logic en,
    input logic signed [V_WIDTH-1:0] I,
    input logic in_evt,
    input logic [3:0] refr
  );
    begin
      enable      = en;
      I_syn       = I;
      input_event= in_evt;
      refract_cnt= refr;
      @(posedge clk);
    end
  endtask

  // -------------------------------------------------
  // Test 1: Basic Integration (No Spike)
  // -------------------------------------------------
  task automatic test_basic_integration();
    begin
      $display("\n--- Test 1: Basic Integration ---");

      step_neuron(1, 12'sd20, 0, 0);
      step_neuron(1, 12'sd20, 0, 0);
      step_neuron(1, 12'sd20, 0, 0);

      assert(spike == 0) else $error("Unexpected spike in basic integration");
      $display("[%0t] PASS: Basic integration", $time);
    end
  endtask

  // -------------------------------------------------
  // Test 2: Spike Generation
  // -------------------------------------------------
  task automatic test_spike_generation();
    begin
      $display("\n--- Test 2: Spike Generation ---");

      repeat (10) step_neuron(1, 12'sd40, 0, 0);

      assert(spike == 1) else $error("Spike not generated when expected");
      @(posedge clk);

      assert(V_out == V_reset)
        else $error("V_out not reset after spike");

      $display("[%0t] PASS: Spike generation", $time);
    end
  endtask

  // -------------------------------------------------
  // Test 3: Refractory Gating
  // -------------------------------------------------
  task automatic test_refractory();
    begin
      $display("\n--- Test 3: Refractory Gating ---");

      refract_cnt = 4'd5;
      step_neuron(1, 12'sd200, 0, refract_cnt);

      assert(spike == 0)
        else $error("Spike occurred during refractory");

      refract_cnt = 4'd0;
      step_neuron(1, 12'sd200, 0, refract_cnt);

      assert(spike == 1)
        else $error("Spike not generated after refractory");

      $display("[%0t] PASS: Refractory gating", $time);
    end
  endtask

  // -------------------------------------------------
  // Test 4: Adaptation Increment (B)
  // -------------------------------------------------
  task automatic test_adaptation_increment();
    logic [W_WIDTH-1:0] w_before;
    begin
      $display("\n--- Test 4: Adaptation Increment ---");

      w_before = W_out;
      step_neuron(1, 12'sd300, 0, 0); // force spike

      @(posedge clk);

      assert(W_out > w_before)
        else $error("Adaptation did not increase on spike");

      $display("[%0t] PASS: Adaptation increment", $time);
    end
  endtask

  // -------------------------------------------------
  // Test 5: Adaptation Decay (D)
  // -------------------------------------------------
  task automatic test_adaptation_decay();
    logic [W_WIDTH-1:0] w_before;
    begin
      $display("\n--- Test 5: Adaptation Decay ---");

      w_before = W_out;
      step_neuron(1, 12'sd0, 1, 0); // input_event only

      @(posedge clk);

      assert(W_out < w_before || W_out == 0)
        else $error("Adaptation did not decay on input_event");

      $display("[%0t] PASS: Adaptation decay", $time);
    end
  endtask

  // -------------------------------------------------
  // Test 6: Saturation of W_reg
  // -------------------------------------------------
  task automatic test_adaptation_saturation();
    begin
      $display("\n--- Test 6: Adaptation Saturation ---");

      repeat (40) begin
        step_neuron(1, 12'sd500, 0, 0);
        @(posedge clk);
      end

      assert(W_out == {W_WIDTH{1'b1}})
        else $error("Adaptation did not saturate");

      $display("[%0t] PASS: Adaptation saturation", $time);
    end
  endtask

  // -------------------------------------------------
  // Test 7: Enable Gating
  // -------------------------------------------------
  task automatic test_enable_gating();
    logic signed [V_WIDTH-1:0] v_before;
    begin
      $display("\n--- Test 7: Enable Gating ---");

      v_before = V_out;
      step_neuron(0, 12'sd200, 1, 0);

      assert(V_out == v_before)
        else $error("State changed when enable=0");

      $display("[%0t] PASS: Enable gating", $time);
    end
  endtask

  // -------------------------------------------------
  // Main Test Sequence
  // -------------------------------------------------
  initial begin
    apply_reset();

    test_basic_integration();
    test_spike_generation();
    test_refractory();
    test_adaptation_increment();
    test_adaptation_decay();
    test_adaptation_saturation();
    test_enable_gating();

    $display("\n====================================");
    $display(" ALL ED-ALIF NEURON TESTS PASSED ");
    $display("====================================\n");

    #50;
    $finish;
  end

endmodule
