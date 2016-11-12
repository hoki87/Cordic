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
// Module     	: op_quad_adj
// File     	: op_quad_adj.v
// Created by   : ksd
//
// Revision  	: 
//
// Abstract:
// X, Y, and Z outputs from CORDIC may require adjusting to place the result in the correct quadrant.
// The CORDIC function outputs will be in either quadrant 1 OR 4. They may require shifting to quadrants
// 2 and 3.
//
// X Output
//=========
// Rotational mode :
//  If angle rotation was for quadrant 2 OR 3
//  invert x_in_pipe[ITER] and make it negative
//  invert y_in_pipe[ITER] and make it negative
//
// Vectoring mode :
//  Do not modify x_in_pipe[ITER] as it positive representing magnitude
//
// Y Output
// ========
// Do not modify y_in_pipe[ITER] in Vectoring mode or Rotational mode when
// quadrant is 1 or 4
//
// Z Output
// =======
// Vectoring mode
//  If quadrant 2 then
//      z_in_pipe[ITER] = pi - z_in_pipe[ITER]
//  Else if quadrant 3 then
//      z_in_pipe[ITER] = -pi - z_in_pipe[ITER]
//
// Rotational mode
// No need to modfiy z_in_pipe[ITER] as should be close to zero
//----------------------------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

module op_quad_adj
  (
    rotnvec_mode,
    quadrant,
    
    x_out,
    y_out,
    z_out,
    
    x_out_qadj_c,
    y_out_qadj_c,
    z_out_qadj_c
    
  );

//----------------------------------------------------------------------------------------------------------------------
// Parameters
//----------------------------------------------------------------------------------------------------------------------
//include file containing  constants and function declarations
`include            "cordic_inc.v"
//----------------------------------------------------------------------------------------------------------------------
input                                                 rotnvec_mode;
input   [1:0]                                         quadrant;

input   [(XY_WIDTH-1):0]                              x_out;
input   [(XY_WIDTH-1):0]                              y_out;
input   [(Z_WIDTH-1):0]                               z_out;

output  [(XY_WIDTH-1):0]                              x_out_qadj_c;
output  [(XY_WIDTH-1):0]                              y_out_qadj_c;
output  [(Z_WIDTH-1):0]                               z_out_qadj_c;
//----------------------------------------------------------------------------------------------------------------------
reg     [(XY_WIDTH-1):0]                              x_out_qadj_c;
reg     [(XY_WIDTH-1):0]                              y_out_qadj_c;
reg     [(Z_WIDTH-1):0]                               z_out_qadj_c;
//----------------------------------------------------------------------------------------------------------------------
//Internal signals

reg     [(Z_WIDTH-1):0]                               z_out_temp_c;
//----------------------------------------------------------------------------------------------------------------------
always @(x_out or y_out or rotnvec_mode or quadrant)
  begin
    if ( (rotnvec_mode==1'b1) && ( (quadrant==QUAD2) || (quadrant==QUAD3) ) )
      begin
        x_out_qadj_c                                  =  ~x_out + 1'b1;  //invert to make negative
        y_out_qadj_c                                  =  ~y_out + 1'b1;  //invert to make negative      
      end
    else
      begin
        x_out_qadj_c                                  =  x_out;
        y_out_qadj_c                                  = y_out;
      end
  end
  
 
 always @(z_out  or rotnvec_mode or quadrant)
  begin
    z_out_temp_c                                      = z_out;
//    //sign extension
//    if (rotnvec_mode==1'b1)
//      begin
//        z_out_temp_c[(Z_WIDTH-1)]                     = z_out[Z_WIDTH-2];
//      end
//    else if ((quadrant==QUAD1) || (quadrant==QUAD2))
//      begin
//        z_out_temp_c[(Z_WIDTH-1)]                     = 1'b0; //positive angle
//      end
//    else 
//      begin
//        z_out_temp_c[(Z_WIDTH-1)]                     = 1'b1; //negative angle
//      end
    
    
    if ( (rotnvec_mode==1'b0) && (quadrant!=QUAD1) && (quadrant!=QUAD4) )
      begin
        // PI_POS == PI_NEG; thus following applies to Quadrants 2 AND 3
        z_out_qadj_c                                  = add_sub_z1(PI_POS, z_out_temp_c, 1'b0);  
      end
//    else if ( (rotnvec_mode==1'b0) && (quadrant==QUAD3) )
//      begin
//        z_out_qadj_c                                  = add_sub_z1(PI_NEG, z_out_temp_c, 1'b0);
//      end
    else
      begin
        z_out_qadj_c                                  = z_out_temp_c;
      end
  end

endmodule
