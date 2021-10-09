`timescale 1ns / 1ps
module uart2apb_tb(

    );
    
     parameter APB_ADDR_WIDTH = 16;
       parameter APB_DATA_WIDTH = 32;
   
       reg                                 clk;
       reg                                 rstn;
       reg                                 rx;
       wire                                tx;
       //apb bus
       wire                                apb_psel;
       wire [APB_ADDR_WIDTH - 1 : 0]       apb_paddr;
       wire [APB_DATA_WIDTH - 1 : 0]       apb_pwdata;
       wire                                apb_pwrite;
       wire                                apb_penable;
       reg                                 apb_pready;
       reg  [APB_DATA_WIDTH - 1 : 0]       apb_prdata;
   
       integer i;
   
       uart2apb inst_uart2apb(
           .clk(clk),
           .rstn(rstn),
           .rx(rx),
           .tx(tx),
           .apb_psel(apb_psel),
           .apb_paddr(apb_paddr),
           .apb_pwdata(apb_pwdata),
           .apb_pwrite(apb_pwrite),
           .apb_penable(apb_penable),
           .apb_pready(apb_pready),
           .apb_prdata(apb_prdata)
       );
   
       always #1 clk = ~clk;
   
       initial begin
           clk = 1'b0;
           rstn = 1'b0;
           rx = 1'b0;
           apb_pready = 1'b0;
           apb_prdata = 32'd0;
       end
   
       initial begin
           #20;
           rstn = 1'b1;
           #100;
           //write(8'ha5, 16'd255, 32'd1022);
           read(8'h5a, 16'd160, 32'd1314);
           #1000;
           $finish;
       end
   
       task rx_byte;
           input [7:0] data;
               begin
                   @(posedge clk)
                       rx <= 1'b1;
                   repeat(434) @(posedge clk);
                   @(posedge clk)
                       rx<= 1'b0;   
                   repeat(434) @(posedge clk);
                   for (i = 0; i < 8; i = i + 1) begin   
                       @(posedge clk)
                           rx <= data[i];
                       repeat(434) @(posedge clk);
                   end
           
                   @(posedge clk)
                       rx <= ~^data[7:0];           
                   repeat(434) @(posedge clk);
                   @(posedge clk)
                       rx <= 1'b1;
               end
       endtask
       
       task read;
           input [7:0] cmd;
           input [15:0] addr;
           input [31:0] data;
           begin            
                rx_byte(cmd);
                rx_byte(addr[7:0]);
                rx_byte(addr[15:8]);
                @(posedge clk);
                apb_prdata <= data;
                apb_pready <= 1'b1;
                repeat(20000) @(posedge clk);
           end
       endtask
   
   
   
   
       task write;
           input [7:0] cmd;
           input [15:0] addr;
           input [31:0] data;
               begin
                   rx_byte(cmd);
                   rx_byte(addr[7:0]);
                   rx_byte(addr[15:8]);
                   rx_byte(data[7:0]);
                   rx_byte(data[15:8]);
                   rx_byte(data[23:16]);
                   rx_byte(data[31:24]);
               end
       endtask
    
endmodule
