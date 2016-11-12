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
//
////////////////////////////////////////////////////////////////
// 
//  Revision: 1.0

/////////////////////////// MODULE //////////////////////////////
module cordic_top(
    clk,
    rst_n,
    mode,
    x_in,
    y_in,
    r_out
  );
  
/////////////////////////// INCLUDE /////////////////////////////
`include "cordic_inc.v"

   ////////////////// PORT ////////////////////

   input                      clk;
   input                      rst_n;
                              
   //Input data               
   input   [1:0]              mode; // 0: mean square root
   input   [(D_WIDTH-1):0]    x_in;
   input   [(D_WIDTH-1):0]    y_in;
                              
   //Output data              
   output  [(D_WIDTH-1):0]    r_out;

   ////////////////// ARCH ////////////////////
   
   ////////////////// Mode Decode
   reg   [(XY_WIDTH-1):0]     cordic_x_in;
   reg   [(XY_WIDTH-1):0]     cordic_y_in;   
   reg   [(Z_WIDTH-1):0]      cordic_z_in;
   reg                        rotnvec_mode;

   always@* begin
      case(mode)
         0: begin // z = (x^2+y^2)^(1/2)
            cordic_x_in <= {{XY_WIDTH-D_WIDTH{x_in[D_WIDTH-1]}},x_in};
            cordic_y_in <= {{XY_WIDTH-D_WIDTH{y_in[D_WIDTH-1]}},y_in};
            cordic_z_in <= {Z_WIDTH{1'b0}};
            rotnvec_mode <= 1'b0;
         end
         default: begin
            cordic_x_in <= 0;
            cordic_y_in <= 0;
            cordic_z_in <= 0;
            rotnvec_mode <= 1'b1;
         end
      endcase
   end      
   
   ////////////////// Cordic Core
   wire  [(XY_WIDTH-1):0]    x_out_tmp ;  
   wire  [(XY_WIDTH-1):0]    y_out_tmp ;  
   wire  [(Z_WIDTH-1):0]     z_out_tmp ;  

   cordic u_cordic(
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
               if(i==0)
                  mode_delay[i] <= mode;
               else
                  mode_delay[i] <= mode_delay[i-1];
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

   cordic_gain_corr    u_cordic_gain_corr1(
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
   reg  [(D_WIDTH-1):0]  r_out;
   always  @(posedge clk or negedge rst_n) begin
      if (~rst_n) begin
         r_out <= 0;
      end
      else begin
         case(mode_delay[CORDIC_DELAY-1])
            0: begin // z = (x^2+y^2)^(1/2)
               r_out <= gain_corr_x[D_WIDTH-1:0];
            end
            default: begin
               r_out <= 0;
            end
         endcase
      end
   end      

endmodule 