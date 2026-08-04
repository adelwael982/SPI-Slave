module spi_w #(parameter  depth=8,addr=8 ) (
    input clk,rst,mosi,ss_n,
    output miso
);
    wire tx_valid,rx_valid;
    wire [depth-1:0] tx_data;
    wire [depth+1:0] rx_data;
spi_s  #(.depth(depth))d1(
.ss_n(ss_n),
    .tx_data(tx_data),
    .mosi(mosi),
    .tx_valid(tx_valid),
    .clk(clk),
    .rst(rst),
    .rx_valid(rx_valid),
    .miso(miso),
    .rx_data(rx_data))
;
ram #(.depth(depth),.addr(addr))d2(
  .dout(tx_data),
    .tx_valid(tx_valid),
    .clk(clk),
    .rst(rst),
    .rx_valid(rx_valid),
    .din(rx_data))
;
endmodule
