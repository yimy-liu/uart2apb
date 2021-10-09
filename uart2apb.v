{\rtf1\ansi\ansicpg936\cocoartf2580
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;\f1\fnil\fcharset134 PingFangSC-Regular;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx566\tx1133\tx1700\tx2267\tx2834\tx3401\tx3968\tx4535\tx5102\tx5669\tx6236\tx6803\pardirnatural\partightenfactor0

\f0\fs24 \cf0 module uart2apb#(\
    parameter APB_ADDR_WIDTH=16,\
    parameter APB_DATA_WIDTH=32\
    )(\
     input  clk,\
     input   rest,\
     input rx,\
     output reg tx,\
//apb bus\
     output apb_psel,\
     output [APB_ADDR_WIDTH-1:0] apb_paddr,\
    output[APB_DATA_WIDTH-1:0] apb_pwdata,\
     output apb_pwrite,\
    output apb_penable,\
    input apb_pready,\
input [APB_DATA_WIDTH-1:0] apb_prdata\
);\
reg[4:0] curr_state;\
reg[4:0] next_state;\
\
reg [APB_DATA_WIDTH-1:0] apb_write_data_buffer;\
reg [APB_DATA_WIDTH-1:0] apb_read_data_buffer;\
reg [APB_ADDR_WIDTH-1:0] apb_addr_buffer;\
reg [7:0] uart_rx_buffer;\
\pard\tx566\tx1133\tx1700\tx2267\tx2834\tx3401\tx3968\tx4535\tx5102\tx5669\tx6236\tx6803\pardirnatural\partightenfactor0
\cf0 reg [7:0] uart_tx_buffer;\
reg [7:0] uart_rx_cmd_buffer;\
reg [3:0] uart_bit_num_counter;\
reg [8:0] uart_bit_counter
\f1 \'a3\'bb
\f0 \
reg [2:0] rx_dly;\
reg [1:0] write_data_counter;\
reg [1:0] read_data_counter;\
reg [6:0] delay_counter;\
reg addr_flag;\
reg uart_rx_byte_finish_flag;\
\
wire small_counter_en_states;\
wire big_counter_en_states;\
\
wire rcv_cmd_states;\
wire rcv_addr_states;\
wire rcv_write_data_states;\
wire uart_send_tx_states;\
wire delay_staes;\
wire rx_data_bits;\
wire rx_check_bit_finish;\
wire nedge_rx;\
wire check_finish;\
wire rx_sync;\
\
localparameter IDLE=5\'92d0,\
                         RCV_CMD=5\'92d1,\
                         RCV_ADDR_LOW=5\'92d2,\
                         RCV_ADDR_HIGH=5\'92d3,\
                         RCV_WRITE_DATA_BYTE0=5\'92d4;\
                         RCV_WRITE_DATA_BYTE1=5\'92d5;\
\pard\tx566\tx1133\tx1700\tx2267\tx2834\tx3401\tx3968\tx4535\tx5102\tx5669\tx6236\tx6803\pardirnatural\partightenfactor0
\cf0                          RCV_WRITE_DATA_BYTE2=5\'92d6;\
                         RCV_WRITE_DATA_BYTE3=5\'92d7;\
                         APB_WRITE_SEL=5\'92d8;\
                         APB_WRITE_EN=5\'92d9;\
                         APB_READ_SEL=5\'92d10;\
                         APB_READ_EN=5\'92d11;\
                         UART_SEND_TX_BYTE0=5\'92d12;\
                         UART_SEND_TX_WAIT0=5\'92d13;\
                         UART_SEND_TX_BYTE1=5\'92d14;\
                         UART_SEND_TX_WAIT1=5\'92d15;\
                         UART_SEND_TX_BYTE2=5\'92d16;\
                         UART_SEND_TX_WAIT2=5\'92d17;\
                         UART_SEND_TX_BYTE3=5\'92d18;\
\
always @(posedge clk or negedge rstn)begin\
    if(!rstn)\
        curr_state <= IDLE;\
    else\
        curr_state<=next_state;\
end\
\
always @(*)begin\
case(curr_state)\
    IDLE:begin\
                if(nedge_rx)\
                     next_state=RCV_CMD;\
                else\
                     next_state=IDLE;\
               end\
\
    RCV_CMD:begin\
                if(uart_rx_byte_finish_flag&&nedge_rx)\
                     next_state=RCV_ADDR_LOW;\
                else\
                     next_state=RCV_CMD;\
               end\
    RCV_ADDR_LOW:begin\
                if(uart_rx_byte_finish_flag&&nedge_rx)\
                     next_state=RCV_ADDR_HIGH;\
                else\
                     next_state=RCV_ADDR_LOW;\
                end\
   RCV_ADDR_HIGH:begin\
                if(uart_rx_byte_finish_flag)\
                     next_state=uart_rx_cmd_buffer[0]==1\'92b1?RCV_WRITE_DATA_BYTE0:APB_RESD_SEL;\
                else\
                     next_state=RCV_ADDR_HIGH;\
                end\
   RCV_WRITE_DATA_BYTE0:begin\
                if(uart_rx_byte_finish_flag&&nedge_rx)\
                     next_state=RCV_WRITE_DATA_BYTE1;\
                else\
                     next_state=RCV_WRITE_DATA_BYTE0;\
                end\
   RCV_WRITE_DATA_BYTE1:begin\
                if(uart_rx_byte_finish_flag&&nedge_rx)\
                     next_state=RCV_WRITE_DATA_BYTE2;\
                else\
                     next_state=RCV_WRITE_DATA_BYTE1;\
                end\
   RCV_WRITE_DATA_BYTE2:begin\
                if(uart_rx_byte_finish_flag&&nedge_rx)\
                     next_state=RCV_WRITE_DATA_BYTE3;\
                else\
                     next_state=RCV_WRITE_DATA_BYTE2;\
                end\
   RCV_WRITE_DATA_BYTE3:begin\
                if(uart_rx_byte_finish_flag)\
                     next_state=APB_WRITE_SEL;\
                else\
                     next_state=RCV_WRITE_DATA_BYTE3;\
                end\
    APB_WRITE_SEL:begin\
                     next_state=APB_WRITE_EN;\
               end\
    APB_WRITE_EN:begin\
              if(apb_pready)\
                     next_state=IDLE;\
              else \
                     next_state=APB_WRITE_EN;\
              end\
    APB_READ_SEL:begin\
                     next_state=APB_READ_EN;\
              end\
    APB_READ_EN:begin\
                if(apb_ready)\
                     next_state=UART_SEND_TX_BYTE0;\
                else\
                     next_state=APD_READ_EN;\
            end\
     UART_SEND_TX_BYTE0:begin\
                if(uart_bit_num_counter==4'd10&&uart_bit_counter==9'd433)\
                     next_state=UART_SEND_TX_WAIT0;\
                else\
                     next_state=UART_SEND_TX_BYTE0;\
                end\
     UART_SEND_TX_WAIT0:begin\
                if(delay_counter==7'd99)\
                    next_state=UART_SEND_TX_BYTE1;\
                else\
                    next_state=UART_SEND_TX_WAIT0;\
            end\
     UART_SEND_TX_BYTE1:begin\
                if(uart_bit_num_counter==4'd10&&uart_bit_counter==9'd433)\
                    next_state=UART_SEND_TX_WAIT1;\
                else\
                    next_state=UART_SEND_TX_BYTE1;\
            end\
    UART_SEND_TX_WAIT1:begin\
                if(delay_counter==7'd99)\
                    next_state=UART_SEND_TX_BYTE2;\
                else\
                    next_state=UART_SEND_TX_WAIT1;\
            end\
     UART_SEND_TX_BYTE2:begin\
                if(uart_bit_num_counter==4'd10&&uart_bit_counter==9'd433)\
                    next_state=UART_SEND_TX_WAIT2;\
                else\
                    next_state=UART_SEND_TX_BYTE2;\
            end\
     UART_SEND_TX_WAIT2:begin\
                if(delay_counter==7'd99)\
                    next_state=UART_SEND_TX_BYTE3;\
                else\
                    next_state=UART_SEND_TX_WAIT2;\
            end\
      UART_SEND_TX_BYTE3:begin\
                if(uart_bit_num_counter==4'd9&&uart_bit_counter==9'd433)\
                    next_state=IDLE;\
                else\
                    next_state=UART_SEND_TX_BYTE3;\
            end\
     default:next_state=IDLE;\
endcase\
end\
\
assign rcv_cmd_states=curr_state==RCV_CMD;\
assign rcv_addr_states=(curr_state==RCV_ADDR_LOW)||(curr_state==RCV_ADDR_HIGH);\
assign rcv_write_data_states=(curr_state==RCV_WRITE_DATA_BYTE0)|| (curr_state==RCV_WRITE_DATA_BYTE1)||(curr_state==RCV_WRITE_DATA_BYTE2)||(curr_state==RCV_WRITE_DATA_BYTE3);\
assign uart_send_tx_states=(curr_state==UART_SEND_TX_BYTE0)||(curr_state==UART_SEND_TX_BYTE1)||(curr_state==UART_SEND_TX_BYTE2)||(curr_state==UART_SEND_TX_BYTE3);\
\
assign delay_states=(curr_state==UART_SEND_TX_WAIT0)||(curr_state==UART_SEND_TX_WAIT1)(curr_state==UART_SEND_TX_WAIT2);\
\
assign rx_data_bits=(uart_bit_num_counter>0&&uart_bit_num_counter<9)?1\'92b1:1'b0;\
\
assign rx_check_bit_finish=(uart_bit_num_counter==4'd9&&uart_bit_counter==9'd216&&~^uart_rx_buffer==rx_sync);\
\
always @ (posedge clk or negedge rstn)\
begin\
    if(!rstn)\
        rx_dly <= 3'b000;\
    else\
        rx_dly <= \{rx_dly[1:0],rx\}\
end\
\
assign nedge_rx=rx_dly[2:1]==2'b10;\
assign rx_sync =rx_dly[2];\
\
assign small_counter_en_states=(rcv_cmd_states||rcv_addr_states||rcv_write_data_states||uart_send_tx_states);\
\
always@(posedge clk or negedge rstn)\
begin\
    if(!rstn)\
        uart_bit_counter <= 9'd0;\
    else if (small_counter_en_states&&!uart_rx_byte_finish_flag)begin\
        if(uart_bit_counter==9'd433)\
                uart_bit_counter <= 9'd0;\
            else\
                uart_bit_counter <= uart_bit_counter+1'b1;\
        end\
    else\
         uart_bit_counter <= 9'd0;\
end\
\
assign big_counter_en_states=(rcv_cmd_states||rcv_addr_states||rcv_write_data_states||uart_send_tx_states);\
\
always@(posedge clk or negedge rstn)\
begin\
    if(!rstn)\
        uart_bit_num_counter <= 4'd0;\
    else if (big_counter_en_states&&!uart_rx_byte_finish_flag)begin\
        if(uart_bit_counter==9'd433)\
            uart_bit_num_counter <= uart_bit_num_counter+1'b1;\
        end\
    else\
         uart_bit_num_counter <= 4\'92d0;\
end\
\
always@(posedge clk or negedge rstn)\
begin\
    if(!rstn)\
        uart_rx_byte_finish_flag<=1'b0;\
    else if (uart_bit_counter==9'd433&&uart_bit_num_counter==4'd10&&(rcv_cmd_states||rcv_addr_states||rcv_write_data_states))\
        uart_rx_byte_finish_flag<=1'b1;\
     else if (nedge_rx||uart_send_tx_states||delay_states)\
         uart_rx_byte_finish_flag<=1'b0;\
 end\
\
//receive rx\
always @ (posedge clk or negedge rstn)\
begin\
   if(!rstn)\
       uart_rx_buffer<=8'b0;\
   else if (uart_bit_counter==9'd216&&(rcv_cmd_states||rcv_addr_states||rcv_write_data_states)&&rx_data_bits)\
       uart_rx_buffer <= \{rx_sync,uart_rx_buffer[7:1]\};\
end\
\
always @ (posedge clk or negedge rstn)\
begin\
   if(!rstn)\
       uart_rx_cmd_buffer<=8'd0;\
   else if (rcv_cmd_states&&rx_check_bit_finish)\
       uart_rx_cmd_buffer <= uart_rx_buffer;\
   end\
\
always @ (posedge clk or negedge rstn)\
begin\
   if(!rstn)\
       addr_flag<=1'b0;\
   else if (rcv_addr_states&&uart_bit_counter==9'd433&&uart_bit_num_counter==4'd10)\
       addr_flag<= ~addr_flag;\
   end\
\
always @ (posedge clk or negedge rstn)\
begin\
   if(!rstn)\
       apb_addr_buffer<=16'd0;\
   else if (rcv_addr_states&&rx_check_bit_finish)\
       apb_addr_buffer[addr_flag*8+:8]<=uart_rx_buffer;\
   end\
\
always @ (posedge clk or negedge rstn)\
begin\
   if(!rstn)\
       write_data_counter <=2'd0;\
   else if (rcv_write_data_states&&uart_bit_counter==9'd433&&uart_bit_num_counter==4'd10)\
       write_data_counter <= write_data_counter + 1'b1;\
   end\
\
always @ (posedge clk or negedge rstn)\
begin\
   if(!rstn)\
       apb_write_data_buffer <=32'd0;\
   else if (rcv_write_data_states&&rx_check_bit_finish)\
       apb_write_data_buffer[write_data_counter*8+:8]<=uart_rx_buffer;\
   end\
\
assign apb_paddr=(curr_state==APB_WRITE_SEL||curr_state==APB_READY_SEL)?apb_addr_buffer:16\'92d0;\
\
assign apb_psel=(curr_state==APB_WRITE_SEL||APB_WRITE_EN||APB_READ_SEL||APB_READ_EN);\
assign apb_pwrite= (curr_state==APB_WRITE_SEL);\
assign apb_pwdata=(curr_state==APB_WRITE_SEL||curr_state==APB_READ_SEL)?apb_write_data_buffer:32\'92d0;\
assign apb_penable=(curr_state==APB_WRITE_EN)||(curr_state==APB_READ_EN);\
\
always @ (posedge clk or negedge rstn)\
begin\
   if(!rstn)\
       apb_read_data_buffer <=32'd0;\
   else if (curr_state==APB_READ_SEL&&apb_pready)\
       apb_read_data_buffer <=apb_prdata;\
   end\
\
always @ (posedge clk or negedge rstn)\
begin\
   if(!rstn)\
       delay_counter <=7'd0;\
   else if (delay_states)\
       delay_counter <= delay_counter+1'b1;\
   else\
       delay_counter<=7'd0;\
   end\
\
always @ (posedge clk or negedge rstn)\
begin\
   if(!rstn)\
       read_data_counter <=2'd0;\
   else if (uart_send_tx_states&&uart_bit_counter==9'd433&&uart_bit_num_counter==4'd10)\
       read_data_counter <= read_data_counter+1'b1;\
   end\
\
always @ (posedge clk or negedge rst_n)\
begin\
     if(!rst_n)\
         uart_tx_buffer <= 8'd0;\
     else if(uart_send_tx_states)\
        uart_tx_buffer<= apb_read_data_buffer[read_data_counter * 8 +:8];\
  end\
\
always @(*)begin\
    if(!rstn)\
        tx<=1'b0;\
        else if (uart_send_tx_states)begin\
            if(uart_bit_num_counter==0)\
                tx =1'b0;\
            else if(uart_bit_num_counter>0&&uart_bit_num_counter<9)\
                tx =apb_read_data_buffer[read_data_counter*8+uart_bit_num_counter-1];\
            else if (uart_bit_num_counter==4'd9&&uart_bit_counter==9'd433)\
                tx<=~^uart_tx_buffer[7:0];\
            else\
                tx<=1'b1;\
            end \
    else\
        tx=1\'92b1;\
end\
\
endmodule\
}