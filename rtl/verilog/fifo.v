/******************************************************************************
 This Source Code Form is subject to the terms of the
 Open Hardware Description License, v. 1.0. If a copy
 of the OHDL was not distributed with this file, You
 can obtain one at http://juliusbaxter.net/ohdl/ohdl.txt

 Description: Store buffer
 Currently a simple single clock FIFO, but with the ambition to
 have combining and reordering capabilities in the future.

 Copyright (C) 2013 Stefan Kristiansson <stefan.kristiansson@saunalahti.fi>

 ******************************************************************************/

module fifo
  #(
    parameter DEPTH_WIDTH = 0,
    parameter DATA_WIDTH = 0
    )
   (
`ifdef FORMAL
    // peek_address and peek_data break out direct access to the block RAM backing the FIFO, which is useful for formal
    // proofs by induction.
    input  [DEPTH_WIDTH-1:0] peek_address,
    output [DATA_WIDTH-1:0]  peek_data,
    // space_remaining is the number of free items left in the FIFO, which is useful for formal proofs by induction.
    output [DEPTH_WIDTH:0] space_remaining,
`endif

    input 		    clk,
    input 		    rst,

    input [DATA_WIDTH-1:0]  wr_data_i,
    input 		    wr_en_i,

    output [DATA_WIDTH-1:0] rd_data_o,
    input 		    rd_en_i,

    output 		    full_o,
    output 		    empty_o
    );

   localparam DW = (DATA_WIDTH  < 1) ? 1 : DATA_WIDTH;
   localparam AW = (DEPTH_WIDTH < 1) ? 1 : DEPTH_WIDTH;

   //synthesis translate_off
   initial begin
      if(DEPTH_WIDTH < 1) $display("%m : Warning: DEPTH_WIDTH must be > 0. Setting minimum value (1)");
      if(DATA_WIDTH < 1) $display("%m : Warning: DATA_WIDTH must be > 0. Setting minimum value (1)");
   end
   //synthesis translate_on

   reg [AW:0] write_pointer;
   reg [AW:0] read_pointer;

   wire 	       empty_int = (write_pointer[AW] ==
				    read_pointer[AW]);
   wire 	       full_or_empty = (write_pointer[AW-1:0] ==
					read_pointer[AW-1:0]);
   
   assign full_o  = full_or_empty & !empty_int;
   assign empty_o = full_or_empty & empty_int;

`ifdef FORMAL
   assign space_remaining = empty_o? 2**AW : {1'b0, read_pointer[AW-1:0] - write_pointer[AW-1:0]};
`endif
   
   always @(posedge clk) begin
      if (wr_en_i)
	write_pointer <= write_pointer + 1'd1;

      if (rd_en_i)
	read_pointer <= read_pointer + 1'd1;

      if (rst) begin
	 read_pointer  <= 0;
	 write_pointer <= 0;
      end
   end
   simple_dpram_sclk
     #(
       .ADDR_WIDTH(AW),
       .DATA_WIDTH(DW),
       .ENABLE_BYPASS(1)
       )
   fifo_ram
     (
`ifdef FORMAL
      .peek_address (peek_address),
      .peek_data    (peek_data),
`endif
      .clk			(clk),
      .dout			(rd_data_o),
      .raddr			(read_pointer[AW-1:0]),
      .re			(rd_en_i),
      .waddr			(write_pointer[AW-1:0]),
      .we			(wr_en_i),
      .din			(wr_data_i)
      );

endmodule
