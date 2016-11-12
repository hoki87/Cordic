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
// Module     	: ip_quad_info
// File     	: ip_quad_info.v
// Created by   : ksd
//
// Revision  	: 
//
// Abstract:
// DETERMINING CARTESIAN QUADRANT INFORMATION CONCERNING INPUTS
// 
// Polar to Cartesian : Rotational mode
// ====================================
// Use angle z_in to determine quadrant info
//  0     <=  z_in <= pi/2  ===> QUADRANT 1
//  pi/2  <= z_in           ===> QUADRANT 2
//           z_in  < -pi/2  ===> QUADRANT 3 
//  -pi/2 <= z_in < 0       ===> QUADRANT 4
//
// Cartesian to Polar : Vectoring mode
// ===================================
// Sign of x and y provides quadrant info
// x_in_r = +ve && y_in_r = +ve   ===> QUADRANT 1
// x_in_r = -ve && y_in_r = +ve   ===> QUADRANT 2
// x_in_r = -ve && y_in_r = -ve   ===> QUADRANT 3
// x_in_r = +ve && y_in_r = -ve   ===> QUADRANT 4
//
//----------------------------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

module ip_quad_info
  (
    rotnvec_mode,
    
    x_neg,
    y_neg,
    z_in,
    
    quadrant_c
    
  );

//----------------------------------------------------------------------------------------------------------------------
// Parameters
//----------------------------------------------------------------------------------------------------------------------
//include file containing  constants and function declarations
`include            "cordic_inc.v"
//----------------------------------------------------------------------------------------------------------------------
input                                                 rotnvec_mode;

input                                                 x_neg;
input                                                 y_neg;
input   [(Z_WIDTH-1):0]                               z_in;


output  [1:0]                                         quadrant_c;
//----------------------------------------------------------------------------------------------------------------------
wire    [1:0]                                         quadrant_c;
//----------------------------------------------------------------------------------------------------------------------
// Internal signals
reg     [1:0]                                         rot_quad_c;
reg     [1:0]                                         vec_quad_c;


always  @(z_in)
  begin
    if (z_in <= PI2_POS)
      begin
        rot_quad_c                                    = QUAD1;
      end
    else if (z_in < PI_POS)
      begin
        rot_quad_c                                    = QUAD2;
      end
    else if (z_in < PI2_NEG)
      begin
        rot_quad_c                                    = QUAD3;
      end
    else 
      begin
        // z_in >= PI2_NEG
        rot_quad_c                                    = QUAD4;
      end
  end

always  @(x_neg or y_neg)
  begin
    if (x_neg==1'b1) 
      begin
        if (y_neg==1'b1)
          begin
            vec_quad_c                                = QUAD3;
          end
        else
          begin
            vec_quad_c                                = QUAD2;
          end
      end
    else
      begin
        if (y_neg==1'b1)
          begin
            vec_quad_c                                = QUAD4;
          end
        else
          begin
            vec_quad_c                                = QUAD1;
          end
      end
  end

assign  quadrant_c                                    = rotnvec_mode ? rot_quad_c : vec_quad_c;



endmodule
