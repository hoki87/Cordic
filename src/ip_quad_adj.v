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
// Module     	: ip_quad_adj
// File     	: ip_quad_adj.v
// Created by   : ksd
//
// Revision  	: 
//
// Abstract:
// X, Y, and Inputs to CORDIC must be "massaged" to ensure that data only in quadrants 1 and 4
// are input. CORDIC will NOT work if this is not obeyed
//
// X Input
//=========
// Rotational mode :
//  Do not modify x_in_r 
// Vectoring mode :
// If x_in_r is negative then invert and make it positive
//
//
// Y Input
// ========
// Do not modify in either mode
//
// Z Input
// =======
// Vectoring mode
//  No need to modify (z_in_r should be zero)
//
// Rotational mode
//  If        input angle > pi/2 then z = z - pi
//  Else if   input angle < -pi/2 then z = z  + pi
//----------------------------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

module ip_quad_adj
  (
    rotnvec_mode,
    
    x_in,
    y_in,
    z_in,
    quadrant,
    x_in_neg,
    
    x_qadj_c,
    y_qadj_c,
    z_qadj_c
    
  );

//----------------------------------------------------------------------------------------------------------------------
// Parameters
//----------------------------------------------------------------------------------------------------------------------
//include file containing  constants and function declarations
`include            "cordic_inc.v"
//----------------------------------------------------------------------------------------------------------------------
input                                                 rotnvec_mode;

input   [(XY_WIDTH-1):0]                              x_in;
input   [(XY_WIDTH-1):0]                              y_in;
input   [(Z_WIDTH-1):0]                               z_in;
input   [1:0]                                         quadrant;
input                                                 x_in_neg;


output  [(XY_WIDTH-1):0]                              x_qadj_c;
output  [(XY_WIDTH-1):0]                              y_qadj_c;
output  [(Z_WIDTH-1):0]                               z_qadj_c;
//----------------------------------------------------------------------------------------------------------------------
reg     [(XY_WIDTH-1):0]                              x_qadj_c;
wire    [(XY_WIDTH-1):0]                              y_qadj_c;
reg     [(Z_WIDTH-1):0]                               z_qadj_c;
//----------------------------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------------------------
always @(x_in or rotnvec_mode or x_in_neg)
  begin
    if ( (rotnvec_mode==1'b0) && (x_in_neg==1'b1)  )
      begin
        x_qadj_c                                      =  ~x_in + 1'b1;  //invert to make positive
      end
    else
      begin
        x_qadj_c                                      =  x_in;
      end
  end
  
 assign  y_qadj_c                                     = y_in;
 
 always @(z_in  or rotnvec_mode or quadrant)
  begin
    if ((rotnvec_mode==1'b1) && ((quadrant!=QUAD1) && (quadrant!=QUAD4)) )
      begin
        // PI_POS == PI_NEG; thus following applies to Quadrants 2 AND 3
        // zin - PI and zin + PI are equivalent to zin + PI_POS
        z_qadj_c                                      = add_sub_z1(PI_POS, z_in, 1'b1);  
      end
//    else if ( (rotnvec_mode==1'b1) && (quadrant==QUAD3))
//      begin
//        z_qadj_c                                      = add_sub_z1(PI_NEG, z_in, 1'b0);
//      end
    else
      begin
        z_qadj_c                                      = z_in;
      end
  end
  

endmodule
