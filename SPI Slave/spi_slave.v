module spi_s # (parameter depth=8)(
    input mosi,clk,rst,ss_n,tx_valid,
    input [depth-1:0] tx_data,
    output reg [depth+1:0] rx_data,
    output reg miso,rx_valid
);
reg read_add_chk,done;
   reg[2:0] cs,ns;
   reg[depth+1:0] regi_reg,regi_next;
   reg [depth-1:0] tx_next,tx_reg;
   reg[$clog2(depth+1+depth):0] cnt_next,cnt_reg;
localparam 
 idle = 'b000,
 chk_cmd = 'b001,
 write = 'b010,
 read_add = 'b011,
 read_data = 'b100 ;
   always @(posedge clk or negedge rst) begin
    if (!rst) begin
        cs<=0; cnt_reg<=0; regi_reg<=0; miso<=0;done<=0;read_add_chk<=0;tx_reg<=0;
    end
    else begin
    cs<=ns; regi_reg<=regi_next; cnt_reg<=cnt_next;tx_reg<=tx_next;end
   end    

   always @(*) begin
    cnt_next=cnt_reg;
    tx_next=tx_reg;
    regi_next=regi_reg;
    done=0;
    case (cs)
      idle  :begin done=0; cnt_next<=0;
        if (!ss_n) begin 
            ns=chk_cmd;cnt_next=cnt_reg+1;
        end
        else
        ns=idle;
      end
chk_cmd: begin
    cnt_next = cnt_reg + 1;
    regi_next = {regi_reg[depth:0], mosi};
    if (cnt_next != 1) begin
        ns = chk_cmd;              
    end
    else if (mosi == 0) begin
        ns = write;
    end
    else if (mosi == 1 && !read_add_chk) begin
        ns = read_add;            
    end
    else if (mosi == 1 && read_add_chk) begin
        ns = read_data;            
    end
    else begin
        ns = idle;
    end
end
      write :begin     cnt_next = cnt_reg + 1;
  if((cnt_next<10)&&!ss_n) begin
    ns=write; 
    cnt_next = cnt_reg + 1;
    regi_next = {regi_reg[depth:0], mosi};
  end
  else if (cnt_next==10) begin
    ns=write; 
    done=1;
    cnt_next = cnt_reg + 1;
    regi_next = {regi_reg[depth:0], mosi};
  end
  else 
    ns=idle;
      end
      read_add :begin     cnt_next = cnt_reg + 1;
  if((cnt_next<10)&&!ss_n) begin
    ns=read_add; 
    cnt_next = cnt_reg + 1;
    regi_next = {regi_reg[depth:0], mosi};
  end
  else if (cnt_next==10) begin
    ns=read_add; 
    done=1; 
    read_add_chk=1;
    cnt_next = cnt_reg + 1;
        regi_next = {regi_reg[depth:0], mosi};
  end
  else 
    ns=idle;
      end
read_data :begin read_add_chk=0; cnt_next = cnt_reg + 1;
  if ((cnt_next<10)&&!ss_n) begin
    ns=read_data;
    regi_next = {regi_reg[depth:0], mosi};
  end
  else if (cnt_next==10&&!ss_n) begin
    ns=read_data;
    done=1;
  end
  else if (((cnt_next==11)||(cnt_next==12))&&!ss_n) begin
    ns=read_data;
  end
  else if (cnt_next==13&&tx_valid&&!ss_n) begin
    ns=read_data;
    tx_next=tx_data;
  end
  else if (cnt_next<21&&tx_valid&&!ss_n) begin
    ns=read_data;
    tx_next={tx_reg[depth-2:0],1'b0};
  end
  else
    ns=idle;
end
        default: ns=cs;
    endcase
   end
always @(posedge clk) begin
    if (done) begin
        rx_valid<=1;
    end
    else if (!done) begin
        rx_valid<=0;
    end
    if(cs>0||cs==0) begin
        rx_data<=regi_next;
    end
    if(cnt_reg>13) begin
        miso<=tx_next[7];
    end
    else if(cnt_reg<13)  miso<=1;

end
endmodule
