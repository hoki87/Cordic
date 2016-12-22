`timescale 1ns/1ps 

////////////////////////////////////////////////////////////////
//
//  Module  : cordic_top
//  Designer: Hoki
//  Company : HWorks
//  Date    : 2016/11/12
//
////////////////////////////////////////////////////////////////
// 
//  Description: Top module of cordic
//  Mode  | IN:   X     Y     Z    | OUT:         R             A          |   Remarks:
//   1            x     y     -            (x^2+y^2)^(1/2)  arctan(x/y)        angle(A) -  data:-2^(OUT_WIDTH-1) ~ 2^(OUT_WIDTH-1)-1, degree: -180 ~ 180
//   2            x     y     z              xcosz-ysinz    ycosz+xsinz        angle(Z) -  data:-2^(IN_WIDTH-1)  ~ 2^(IN_WIDTH-1)-1,  degree: -180 ~ 180
//
////////////////////////////////////////////////////////////////
//
//  Revision: 1.0 2016/11/12
//            1.1 2016/12/3

/////////////////////////// MODULE //////////////////////////////
module cordic_top(
    clk,
    rst_n,
    en_in,
    mode_in,
    x_in,
    y_in,
    z_in,
    ready_out,
    r_out,
    a_out
  );
  
/////////////////////////// INCLUDE /////////////////////////////
`include "cordic_inc.v"

   ////////////////// PORT ////////////////////

   input                      clk;       // clock
   input                      rst_n;     // reset, active low
                                         
   //Input data                          
   input                      en_in;     // enable input            
   input   [1:0]              mode_in;   // mode select
   input   [IN_WIDTH-1:0]     x_in;      // x input
   input   [IN_WIDTH-1:0]     y_in;      // y input
   input   [IN_WIDTH-1:0]     z_in;      // z input
                              
   //Output data
   output  [OUT_WIDTH-1:0]    r_out;     // r output
   output  [OUT_WIDTH-1:0]    a_out;     // a output
   output                     ready_out; // process ready output

   ////////////////// ARCH ////////////////////
   
   ////////////////// Mode Decode
   reg   [(XY_WIDTH-1):0]     cordic_x_in;
   reg   [(XY_WIDTH-1):0]     cordic_y_in;   
   reg   [(Z_WIDTH-1):0]      cordic_z_in;
   reg                        rotnvec_mode;

   always@* begin
      case(mode_in)
         1: begin 
            cordic_x_in  <= {{GAIN_EXT_BITS{x_in[IN_WIDTH-1]}},x_in};
            cordic_y_in  <= {{GAIN_EXT_BITS{y_in[IN_WIDTH-1]}},y_in};
            cordic_z_in  <= {Z_WIDTH{1'b0}};
            rotnvec_mode <= 1'b0;
         end
         2: begin
            cordic_x_in  <= {{GAIN_EXT_BITS{x_in[IN_WIDTH-1]}},x_in};
            cordic_y_in  <= {{GAIN_EXT_BITS{y_in[IN_WIDTH-1]}},y_in};
            cordic_z_in  <= {z_in,{GAIN_EXT_BITS{1'b0}}};
            rotnvec_mode <= 1'b1;
         end
         default: begin
            cordic_x_in  <= 0;
            cordic_y_in  <= 0;
            cordic_z_in  <= 0;
            rotnvec_mode <= 1'b1;
         end
      endcase
   end      
   
   ////////////////// Cordic Core
   wire  [(XY_WIDTH-1):0]    x_out_tmp ;  
   wire  [(XY_WIDTH-1):0]    y_out_tmp ;  
   wire  [(Z_WIDTH-1):0]     z_out_tmp ;  

   cordic #(IN_WIDTH) u_cordic(
       .clk            (clk            ),
       .rst_n          (rst_n          ),
       
       //Input data
       .rotnvec_mode   (rotnvec_mode   ),
       .x_in           (cordic_x_in    ),
       .y_in           (cordic_y_in    ),
       .z_in           (cordic_z_in    ),
       
       //Output data
       .x_out          (x_out_tmp      ),
       .y_out          (y_out_tmp      ),
       .z_out          (z_out_tmp      )    
     );

   ////////////////// Mode Delay   
   reg  [1:0]            mode_delay[0:CORDIC_DELAY-1];
   generate
   genvar i;
      for(i=0;i<CORDIC_DELAY;i=i+1)
      begin: MODE_DELAY
         always  @(posedge clk or negedge rst_n) begin
            if(~rst_n) begin
               mode_delay[i] <= 0;
            end
            else begin
               if(i==0) begin
                  mode_delay[i]   <= mode_in;
               end
               else begin
                  mode_delay[i]   <= mode_delay[i-1];
               end
            end
         end
      end
   endgenerate
   
   ////////////////// Gain Compensation                
   reg                   gain_mode;
   always@* begin
      case(mode_delay[CORE_DELAY-1])
         0: gain_mode <= 1'b0;
         default:
            gain_mode <= 1'b1;
      endcase
   end
                                          
   wire [(XY_WIDTH-1):0] gain_corr_x ;
   wire [(XY_WIDTH-1):0] gain_corr_y ;
   wire [(Z_WIDTH-1):0]  gain_corr_z ;

   cordic_gain_corr#(IN_WIDTH)
   u_cordic_gain_corr1(
       .clk                (clk        ),
       .rst_n              (rst_n      ),
                         
       //Input data      
       .rotnvec_mode_in    (gain_mode  ),
       .comp_mode          (gain_mode  ),
       .x_in               (x_out_tmp  ),
       .y_in               (y_out_tmp  ),
       .z_in               (z_out_tmp  ),
                           
       //Output data       
       .rotnvec_mode_out   (),
       .x_out              (gain_corr_x),
       .y_out              (gain_corr_y),
       .z_out              (gain_corr_z)
   );

   ////////////////// OUT
   reg  [CORDIC_DELAY-1:0] p_en_in;
   reg                     ready_out;
   reg  [OUT_WIDTH-1:0]    r_out;
   reg  [OUT_WIDTH-1:0]    a_out;
   always  @(posedge clk or negedge rst_n) begin
      if (~rst_n) begin
         p_en_in <= 0;
         ready_out <= 1'b0;
         r_out <= 0;
         a_out <= 0;
      end
      else begin
         // ready of result output
         p_en_in <= {p_en_in[CORDIC_DELAY-2:0],en_in};
         ready_out <= p_en_in[CORDIC_DELAY-1];
         
         // result output
         case(mode_delay[CORDIC_DELAY-1])
            1: begin // r = (x^2+y^2)^(1/2), a = arctan(x/y)
               r_out <= gain_corr_x;
               a_out <= gain_corr_z;
            end
            2: begin // r = xcosz-ysinz, a = ycosz+xsinz
               r_out <= gain_corr_x;
               a_out <= gain_corr_y;
            end
            default: begin
               r_out <= 0;
               a_out <= 0;
            end
         endcase
      end
   end      

endmodule 