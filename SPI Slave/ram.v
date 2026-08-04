module ram #(
    parameter depth=8,addr=8
) (
    input[depth+1:0] din,
    input rx_valid,clk,rst,
    output reg[depth-1:0] dout,
    output reg tx_valid
);
integer k;
reg [1:0] track;
localparam WR_ADDR = 2'b00, WR_DATA = 2'b01, RD_ADDR = 2'b10, RD_DATA = 2'b11;
reg [depth-1:0]wr_reg,rd_reg;
localparam log=1<<addr;
reg [depth-1:0] mem [0:log-1];
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
        for (k =0 ;k<log;k=k+1 ) begin
            mem[k]<='b0;

        end
        tx_valid<=0;
    end
    track<=din[9:8];
   if (rx_valid) begin
    case (track)
        WR_ADDR: wr_reg<=din[depth-1:0];
        WR_DATA: mem[wr_reg]<=din;
        RD_ADDR: rd_reg<=din[depth-1:0];
        RD_DATA:begin dout<=mem[rd_reg];tx_valid<=1;end
    endcase
   end 
  end  
endmodule
