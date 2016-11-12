`timescale 1ns/1ps 
/////////////////////////// INCLUDE /////////////////////////////
`include            "cordic_inc.v"

////////////////////////////////////////////////////////////////
//
//  Module  : cordic_tb
//  Designer: Hoki
//  Company : HWorks
//  Date    : 2016/11/12 15:45:46
//
////////////////////////////////////////////////////////////////
// 
//  Description: Testbench
//
////////////////////////////////////////////////////////////////
// 
//  Revision: 1.0

/////////////////////////// MODULE //////////////////////////////
module cordic_tb();

   ///////////////// PARAMETER ////////////////

   //Clk high/low time
   parameter           THALF                             = 32'd10;
   //reset pulse width
   parameter           RST_LOW                           = 32'd205;


   ////////////////// ARCH ////////////////////

   //----------------------------------------------------------------------------------------------------------------------
   // Generate clk with period 2*THALF
   //----------------------------------------------------------------------------------------------------------------------
   reg                        clk;
   initial
     clk                                                 = 0;
     
   always
     #THALF  clk                                         = ~clk;
     
   //----------------------------------------------------------------------------------------------------------------------
   // Generate reset pulse
   //----------------------------------------------------------------------------------------------------------------------
   reg                        rst_n;
   initial
     begin
       rst_n                                             = 1'b0;
       #RST_LOW rst_n                                    = 1'b1;    
     end

   ////////////////// Cordic
   reg     [1:0]             mode;
   reg     [(D_WIDTH-1):0]   x_in;
   reg     [(D_WIDTH-1):0]   y_in;
   wire    [(D_WIDTH-1):0]   r_out;
   
   assign z_in = 0;

   initial begin
      mode = 1;
      @(posedge rst_n);
      mode = 0;
      x_in = 30000;
      y_in = 40000;
      @(negedge clk);
      mode = 0;
      x_in = 40000;
      y_in = 30000;
      @(negedge clk);
      mode = 0;
      x_in =-30000;
      y_in = 40000;
      @(negedge clk);
      mode = 0;
      x_in =-40000;
      y_in = 30000;
      @(negedge clk);
      mode = 1;
   end
      
   cordic_top cordic_top_u(
       .clk         (clk),
       .rst_n       (rst_n),
       .mode        (mode ),
       .x_in        (x_in),
       .y_in        (y_in),
       .r_out       (r_out)
     );
  
endmodule