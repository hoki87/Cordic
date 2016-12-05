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
   reg                       en;
   reg     [IN_WIDTH-1:0]    x_in;
   reg     [IN_WIDTH-1:0]    y_in;
   reg     [IN_WIDTH-1:0]    z_in;
   wire    [OUT_WIDTH-1:0]   r_out;
   wire    [OUT_WIDTH-1:0]   a_out;
   
   initial begin
      en=1'b0;
      mode = 0;
      x_in = 0;
      y_in = 0;
      z_in = 0;
      @(posedge rst_n);
      @(posedge clk);
      // Mode 1
      mode = 1;
      en=1'b1;
      x_in = 30000;
      y_in = 40000;
      @(posedge clk);
      x_in = 40000;
      y_in = 30000;
      @(posedge clk);
      x_in =-30000;
      y_in = 40000;
      @(posedge clk);
      x_in =-40000;
      y_in = 30000;
      @(posedge clk);
      x_in = 65535;
      y_in =-65536;
      @(posedge clk);
      x_in = 65535;
      y_in = 65535;
      @(posedge clk);
      x_in =-65536;
      y_in =-65536;
      @(posedge clk);
      en=1'b0;
      mode = 0;
      @(posedge clk);
      // Mode 2
      mode = 2;
      en=1'b1;
      x_in = 0;
      y_in =-50000;
      z_in = 65535; // 90 degree
      @(posedge clk);
      x_in = 35355;
      y_in =-35355;
      z_in = 32767; // 45 degree
      @(posedge clk);
      x_in = 50000;
      y_in = 0;
      z_in = 0;     // 0 degree
      @(posedge clk);
      x_in = 35355;
      y_in = 35355;
      z_in =-32768; //-45 degree
      @(posedge clk);
      x_in = 0;
      y_in = 50000;
      z_in =-65536; //-90 degree
      @(posedge clk);
      en=1'b0;
      mode = 0;
   end
      
   cordic_top cordic_top_u(
       .clk         (clk  ),
       .rst_n       (rst_n),
       .en_in       (en   ),
       .mode_in     (mode ),
       .x_in        (x_in ),
       .y_in        (y_in ),
       .z_in        (z_in ),
       .r_out       (r_out),
       .a_out       (a_out)
     );
  
endmodule