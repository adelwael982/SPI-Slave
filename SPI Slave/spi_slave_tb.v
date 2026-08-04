`timescale 1ns/1ns
module spi_s_tb;

parameter depth = 8, half=5;

reg clk, rst, ss_n, mosi, tx_valid;
reg [depth-1:0] tx_data;

wire [depth+1:0] rx_data;
wire rx_valid, miso;

spi_s #(.depth(depth)) dut (
    .mosi(mosi), .clk(clk), .rst(rst), .ss_n(ss_n),
    .tx_valid(tx_valid), .tx_data(tx_data),
    .rx_data(rx_data), .miso(miso), .rx_valid(rx_valid)
);

always #half clk = ~clk;

task send_frame;
    input [depth+1:0] frame;
    integer i;
begin
    @(posedge clk);
    ss_n = 0;
    for (i = 0; i < depth+2; i = i + 1) begin
        @(posedge clk);
        mosi = frame[depth+1-i];
    end
end
endtask
task capture_miso;
    input integer n;
    output [depth-1:0] cap;
    integer i;
begin
    cap = 0;
    for (i = 0; i < n; i = i + 1) begin
        @(posedge clk);
        cap = {cap[depth-2:0], miso};
    end
end
endtask

reg [depth-1:0] miso_capture;

initial begin
  $dumpfile("spi_s_tb.vcd");
  $dumpvars;

    clk = 0; rst = 0; ss_n = 1; mosi = 0; tx_valid = 0; tx_data = 0;
    #40 rst = 1;

    // Test 1: WRITE
    send_frame({1'b0, 9'b100101110});   // cmd=0 (write) + 9 data bits
    @(posedge clk);#10; ss_n = 1;
    @(posedge clk);
    if (rx_data == 10'b0100101110 && rx_valid)
        $display("Test 1 (WRITE) Pass: rx_data=%b rx_valid=%b", rx_data, rx_valid);
    else
        $display("Test 1 (WRITE) FAIL: rx_data=%b rx_valid=%b", rx_data, rx_valid);
    #30;

    // Test 2: READ_ADD
    send_frame({1'b1, 9'b000101110});   // cmd=1 (first read -> read_add) + 9 addr bits
    @(posedge clk);#10; ss_n = 1;
    @(posedge clk);
    if (rx_data == 10'b1000101110 && rx_valid)
        $display("Test 2 (READ_ADD) Pass: rx_data=%b rx_valid=%b", rx_data, rx_valid);
    else
        $display("Test 2 (READ_ADD) FAIL: rx_data=%b rx_valid=%b", rx_data, rx_valid);
    #30;

    //Test 3: READ_DATA
    tx_data  = 8'b11001010;   // value we want shifted out on miso
    tx_valid = 1;
    ss_n = 0;
    @(posedge clk); mosi = 1'b1; 
    repeat (14) @(posedge clk);

    capture_miso(depth, miso_capture);
    @(posedge clk); ss_n = 1;

    $display("Test 3 (READ_DATA) captured miso = %b (expected %b)", miso_capture, tx_data);
    if (miso_capture == tx_data)
        $display("Test 3 (READ_DATA) Pass");
    else
        $display("Test 3 (READ_DATA) FAIL ");

    #100 $stop;
end

endmodule