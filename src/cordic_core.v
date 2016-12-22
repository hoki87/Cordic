// ================================================================================
// (c) 2003 Altera Corporation. All rights reserved.
// Altera products are protected under numerous U.S. and foreign patents, maskwork
// rights, copyrights and other intellectual property laws.
// 
// This reference design file, and your use thereof, is subject to and governed
// by the terms and conditions of the applicable Altera Reference Design License
// Agreement (either as signed by you, agreed by you upon download or as a
// "click-through" agreement upon installation andor found at www.altera.com).
// By using this reference design file, you indicate your acceptance of such terms
// and conditions between you and Altera Corporation.  In the event that you do
// not agree with such terms and conditions, you may not use the reference design
// file and please promptly destroy any copies you have made.
// 
// This reference design file is being provided on an "as-is" basis and as an
// accommodation and therefore all warranties, representations or guarantees of
// any kind (whether express, implied or statutory) including, without limitation,
// warranties of merchantability, non-infringement, or fitness for a particular
// purpose, are specifically disclaimed.  By making this reference design file
// available, Altera expressly does not recommend, suggest or require that this
// reference design file be used in combination with any other product not
// provided by Altera.
// ================================================================================
//
// Module     	: cordic_core
// File     	: cordic_core.v
// Created by   : ksd
//
// Revision  	: 
//
// Abstract:
// CORDIC implementation
//
// Registering the inputs to CORDIC and after every iteration
//
// direction can be +1 (logic 1) or -1 (logic 0)
//
// ROTATIONAL MODE
//=================
// If z_in is negative then direction = -1 ELSE direction = +1 
//
// VECTORING MODE
//===============
// If y_in is negative then direction = + 1 ELSE direction = -1
//----------------------------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

module cordic_core
  (
    clk,
    rst_n,

    rotnvec_mode,
    quadrant,
    x_in,
    y_in,
    z_in,
    
    rotnvec_mode_out,
    quadrant_out,
    x_out,
    y_out,
    z_out
    
  );

//----------------------------------------------------------------------------------------------------------------------
// Parameters
//----------------------------------------------------------------------------------------------------------------------
//include file containing  constants and function declarations
`include            "cordic_inc.v"
//----------------------------------------------------------------------------------------------------------------------
input                                                 clk;
input                                                 rst_n;
    
input                                                 rotnvec_mode;
input                                                 linear_mode;
input   [1:0]                                         quadrant;
input   [(XY_WIDTH-1):0]                              x_in;
input   [(XY_WIDTH-1):0]                              y_in;
input   [(Z_WIDTH-1):0]                               z_in;


output                                                rotnvec_mode_out;
output  [1:0]                                         quadrant_out;
output  [(XY_WIDTH-1):0]                              x_out;
output  [(XY_WIDTH-1):0]                              y_out;
output  [(Z_WIDTH-1):0]                               z_out;
//----------------------------------------------------------------------------------------------------------------------
wire                                                  rotnvec_mode_out;
wire    [1:0]                                         quadrant_out;
wire    [(XY_WIDTH-1):0]                              x_out;
wire    [(XY_WIDTH-1):0]                              y_out;
wire    [(Z_WIDTH-1):0]                               z_out;
//----------------------------------------------------------------------------------------------------------------------
// Internal Signals
//
reg     [ITER:0]                                      rotnvec_mode_pipe;
reg     [1:0]                                         quadrant_pipe[0:ITER];
reg                                                   direction;
reg     [(XY_WIDTH-1):0]                              x_in_pipe[0:ITER];
reg     [(XY_WIDTH-1):0]                              y_in_pipe[0:ITER];
reg     [(Z_WIDTH-1):0]                               z_in_pipe[0:ITER];

reg     [(XY_WIDTH-1):0]                              x_wire;
reg     [(XY_WIDTH-1):0]                              y_wire;
reg     [(Z_WIDTH-1):0]                               z_wire;
reg     [(XY_WIDTH-1):0]                              x_shift_wire;
reg     [(XY_WIDTH-1):0]                              y_shift_wire;
reg     [(Z_WIDTH-1):0]                               z_shift_wire;
reg     [(XY_WIDTH-1):0]                              x_shift_wire_use;
reg     [(XY_WIDTH-1):0]                              y_shift_wire_use;


integer                                               stage;
integer                                               signext;


reg                                                   z_neg_wire;
reg                                                   y_neg_wire;
reg                                                   y_addnsub;
reg                                                   x_addnsub;
reg                                                   z_addnsub;
//----------------------------------------------------------------------------------------------------------------------

always  @(posedge clk or negedge rst_n)
  if (~rst_n)
    begin
      for (stage=0; stage <= ITER; stage=stage+1)
        begin
          rotnvec_mode_pipe[stage]                        <= 1'b0;
          quadrant_pipe[stage]                            <= 2'b00;
          x_in_pipe[stage]                                <= {XY_WIDTH{1'b0}};
          y_in_pipe[stage]                                <= {XY_WIDTH{1'b0}};
          z_in_pipe[stage]                                <= {(Z_WIDTH){1'b0}}; 
        end
        
    end
  else
    begin
      rotnvec_mode_pipe[0]                                <= rotnvec_mode;
      quadrant_pipe[0]                                    <= quadrant;
      
      x_in_pipe[0]                                        <= x_in;
      y_in_pipe[0]                                        <= y_in;
      z_in_pipe[0]                                        <= z_in; 
     
      

      for (stage=1; stage <= ITER; stage=stage+1)
        begin
          rotnvec_mode_pipe[stage]                        <= rotnvec_mode_pipe[stage-1];
          quadrant_pipe[stage]                            <= quadrant_pipe[stage-1];
          
          //using blocking assignments (not generally good practice to mix blocking and non-blocking assignments in 
          //same process). However cannot extract bits from the one dimensional arrays representing y_in_pipe and
          //z_in_pipe.
          //Following blocking assignments should result in wires (not registers) being synthesised
          x_wire                                          = x_in_pipe[stage-1];
          y_wire                                          = y_in_pipe[stage-1];
          z_wire                                          = z_in_pipe[stage-1];
          
          z_neg_wire                                      = z_wire[(Z_WIDTH-1)];
          y_neg_wire                                      = y_wire[(XY_WIDTH-1)];
          
          
          if ( ((rotnvec_mode_pipe[stage-1]==1'b1) && (z_neg_wire==1'b0)) ||
               ((rotnvec_mode_pipe[stage-1]==1'b0) && (y_neg_wire==1'b1)) )
            begin
              direction                           = 1'b1;
            end
          else
            begin
              direction                           = 1'b0;
            end

          //For CORDIC equations need a shifted version of x_in and y_in; the number of shifts=(iteration pass-1)
          //these should be syntheised as wires
          x_shift_wire                                    = x_wire >> (stage-1);
          y_shift_wire                                    = y_wire >> (stage-1);
          for (signext=(XY_WIDTH-stage); signext < XY_WIDTH; signext=signext + 1)
            begin
              x_shift_wire[signext]                       = x_wire[(XY_WIDTH-1)]; //sign extending
              y_shift_wire[signext]                       = y_wire[(XY_WIDTH-1)]; //sign extending
            end
          
          case (stage-1)
            0:  z_shift_wire                              = ATAN_0 [33:34-Z_WIDTH];
            1:  z_shift_wire                              = ATAN_1 [33:34-Z_WIDTH];
            2:  z_shift_wire                              = ATAN_2 [33:34-Z_WIDTH];
            3:  z_shift_wire                              = ATAN_3 [33:34-Z_WIDTH];
            4:  z_shift_wire                              = ATAN_4 [33:34-Z_WIDTH];
            5:  z_shift_wire                              = ATAN_5 [33:34-Z_WIDTH];
            6:  z_shift_wire                              = ATAN_6 [33:34-Z_WIDTH];
            7:  z_shift_wire                              = ATAN_7 [33:34-Z_WIDTH];
            8:  z_shift_wire                              = ATAN_8 [33:34-Z_WIDTH];
            9:  z_shift_wire                              = ATAN_9 [33:34-Z_WIDTH];
            10: z_shift_wire                              = ATAN_10[33:34-Z_WIDTH];
            11: z_shift_wire                              = ATAN_11[33:34-Z_WIDTH];
            12: z_shift_wire                              = ATAN_12[33:34-Z_WIDTH];
            13: z_shift_wire                              = ATAN_13[33:34-Z_WIDTH];
            14: z_shift_wire                              = ATAN_14[33:34-Z_WIDTH];
            15: z_shift_wire                              = ATAN_15[33:34-Z_WIDTH];
            16: z_shift_wire                              = ATAN_16[33:34-Z_WIDTH];
            17: z_shift_wire                              = ATAN_17[33:34-Z_WIDTH];
            18: z_shift_wire                              = ATAN_18[33:34-Z_WIDTH];
            19: z_shift_wire                              = ATAN_19[33:34-Z_WIDTH];
            20: z_shift_wire                              = ATAN_20[33:34-Z_WIDTH];
            21: z_shift_wire                              = ATAN_21[33:34-Z_WIDTH];
            22: z_shift_wire                              = ATAN_22[33:34-Z_WIDTH];
            23: z_shift_wire                              = ATAN_23[33:34-Z_WIDTH];
            24: z_shift_wire                              = ATAN_24[33:34-Z_WIDTH];
            25: z_shift_wire                              = ATAN_25[33:34-Z_WIDTH];
            26: z_shift_wire                              = ATAN_26[33:34-Z_WIDTH];
            27: z_shift_wire                              = ATAN_27[33:34-Z_WIDTH];
            28: z_shift_wire                              = ATAN_28[33:34-Z_WIDTH];
            29: z_shift_wire                              = ATAN_29[33:34-Z_WIDTH];
            30: z_shift_wire                              = ATAN_30[33:34-Z_WIDTH];
            31: z_shift_wire                              = ATAN_31[33:34-Z_WIDTH];
            default: z_shift_wire                         = {(Z_WIDTH){1'b0}};
          endcase
          
          //CORDIC equations           
//          x_in_pipe[stage]                                <= add_sub_xy(x_in_pipe[stage-1], y_shift_wire,
//                                                                        ~direction);
//          y_in_pipe[stage]                                <= add_sub_xy(y_in_pipe[stage-1], x_shift_wire,
//                                                                        direction);
//          
//                                                                        
//          z_in_pipe[stage]                                <= add_sub_z2(z_in_pipe[stage-1], z_shift_wire,
//                                                                        ~direction);  
  
          if (direction==1'b1)
            begin
              x_addnsub                               = 1'b0;
              y_addnsub                               = 1'b1;
              z_addnsub                               = 1'b0;
            end
          else
            begin
              x_addnsub                               = 1'b1;
              y_addnsub                               = 1'b0;
              z_addnsub                               = 1'b1;
            end        
          x_in_pipe[stage]                            <= add_sub_xy(x_in_pipe[stage-1], y_shift_wire,
                                                                        x_addnsub);
                                                                        
          y_in_pipe[stage]                            <= add_sub_xy(y_in_pipe[stage-1], x_shift_wire,
                                                                        y_addnsub);
          
                                                                        
          z_in_pipe[stage]                            <= add_sub_z1(z_in_pipe[stage-1], z_shift_wire,
                                                                        z_addnsub);  
        end
    end

assign rotnvec_mode_out                                   = rotnvec_mode_pipe[ITER];
assign quadrant_out                                       = quadrant_pipe[ITER];
assign x_out                                              = x_in_pipe[ITER];
assign y_out                                              = y_in_pipe[ITER];
assign z_out                                              = z_in_pipe[ITER];

endmodule
