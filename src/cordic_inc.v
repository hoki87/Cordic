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
// Module     	: cordic_inc
// File     	: cordic_inc.vh
// Created by   : ksd
//
// Revision  	: 
//
// Abstract: Include file for CORDIC module. Contains parameter and function declarations
//
//----------------------------------------------------------------------------------------------------------------------

//----------------------------------------------------------------------------------------------------------------------
// Parameters
//----------------------------------------------------------------------------------------------------------------------

parameter           IN_WIDTH                          = 17; // width of input
parameter           OUT_WIDTH                         = 18; // width of output

//----------------------------------------------------------------------------------------------------------------------
// Don't modify following parameters
//----------------------------------------------------------------------------------------------------------------------

//**********************************************************************************************************************
// Following paramters are auto-generated by MATLAB program and stored in file cordic_inc_p2.vh
//
parameter           XY_WIDTH                          = IN_WIDTH+2; // input X/Y increased by 2
parameter           Z_WIDTH                           = IN_WIDTH+2; // input Z   increased by 2
//
//Number of iterations (=pipeline stages) of CORDIC algorithm
parameter           ITER                              = IN_WIDTH;  // equal to the width of intput
parameter           CORE_DELAY                        = ITER+3;
parameter           GAIN_CORR_DELAY                   = 6;
parameter           CORDIC_DELAY                      = CORE_DELAY+GAIN_CORR_DELAY;

//
//----------------------------------------------------------------------------------------------------------------------
// Parameters for ARCTAN VALUES
// MAXIMUM ARCTAN VALUE= arctan(2^0)= pi/4
//
// Assume 32bits is maxmium that would be used to represent an input angle of between -pi to +pi
// Thus 31 bits required to represent -pi/2 to +pi/2
// =>   30 bits required to represent -pi/4 to +pi/4
//
// +pi    = 32'h8000_0000 = -pi
// +pi/2  = 32'h4000_0000
// +pi/4  = 32'h2000_0000
// ....
// -pi/4  = 32'hE000_0000
// -pi/2  = 32'hC000_0000
// -pi    = 32'h8000_0000 
//----------------------------------------------------------------------------------------------------------------------
parameter           ATAN_0                            = 18'h08000;	
parameter           ATAN_1                            = 18'h04B90;	
parameter           ATAN_2                            = 18'h027ED;	
parameter           ATAN_3                            = 18'h01444;	
parameter           ATAN_4                            = 18'h00A2C;	
parameter           ATAN_5                            = 18'h00517;	
parameter           ATAN_6                            = 18'h0028C;	
parameter           ATAN_7                            = 18'h00146;	
parameter           ATAN_8                            = 18'h000A3;	
parameter           ATAN_9                            = 18'h00051;	
parameter           ATAN_10                           = 18'h00029;	
parameter           ATAN_11                           = 18'h00014;	
parameter           ATAN_12                           = 18'h0000A;	
parameter           ATAN_13                           = 18'h00005;	
parameter           ATAN_14                           = 18'h00003;	
parameter           ATAN_15                           = 18'h00001;	
parameter           ATAN_16                           = 18'h00001;	
parameter           ATAN_17                           = 18'h00000;	
parameter           ATAN_18                           = 18'h00000;	
parameter           ATAN_19                           = 18'h00000;	
parameter           ATAN_20                           = 18'h00000;	
parameter           ATAN_21                           = 18'h00000;	
parameter           ATAN_22                           = 18'h00000;	
parameter           ATAN_23                           = 18'h00000;	
parameter           ATAN_24                           = 18'h00000;	
parameter           ATAN_25                           = 18'h00000;	
parameter           ATAN_26                           = 18'h00000;	
parameter           ATAN_27                           = 18'h00000;	
parameter           ATAN_28                           = 18'h00000;	
parameter           ATAN_29                           = 18'h00000;	
parameter           ATAN_30                           = 18'h00000;	
parameter           ATAN_31                           = 18'h00000;	

//----------------------------------------------------------------------------------------------------------------------
// Parameters for GAIN Compensation block which is not part of CORDIC
//----------------------------------------------------------------------------------------------------------------------

//Number bits to extend x value when compensating for processing gain; improves accuracy of result
//extended bits are added as LSB
parameter           X_GAIN_EXT_BITS                   = 0;
parameter           GAIN_MODEL                        = 1; // using a series if shifts and adds
parameter           RECIP_GAIN                        = 32'h7FFFFFFF;


//**********************************************************************************************************************

//`include            "cordic_inc_p2.v"

//representations of some important phase angles (using 32bit twos complement representation)
// 2^(32-1)     = max value = +pi radians = -pi radians (wraparound)
// -2^(32-1)    = min value = -pi radians
//vector value one of length equal to number of bits in z
parameter           Z_ONE                             = { {(Z_WIDTH-1){1'b0}}, 1'b1};
parameter           PI_NEG                            = (Z_ONE << (Z_WIDTH-1));
parameter           PI_POS                            = PI_NEG;
parameter           PI2_POS                           = PI_POS >> 1;
parameter           PI2_NEG                           = ~PI2_POS + 1'b1;

//quadrant number
parameter           QUAD1                             = 2'b00;
parameter           QUAD2                             = 2'b01;
parameter           QUAD3                             = 2'b10;
parameter           QUAD4                             = 2'b11;


//----------------------------------------------------------------------------------------------------------------------
// Function to add or subtract two numbers for x and y 
//----------------------------------------------------------------------------------------------------------------------
function  [(XY_WIDTH-1):0] add_sub_xy;

  input   [(XY_WIDTH-1):0]                            ip_a;
  input   [(XY_WIDTH-1):0]                            ip_b;
  input                                               addnsub;
  
  reg     [(XY_WIDTH-1):0]                            operand_b;
  reg                                                 carry_in;
  begin
//    if (~addnsub)
//      begin
//        operand_b                                     = ~ip_b;
//        carry_in                                      = 1'b1;
//      end
//    else
//      begin
//        operand_b                                     = ip_b;
//        carry_in                                      = 1'b0;
//      end
//    
//    add_sub_xy                                        = ip_a + operand_b + carry_in;
  
    if (addnsub)
      add_sub_xy                                      = ip_a + ip_b;
    else
      add_sub_xy                                      = ip_a - ip_b;

  end
endfunction
//----------------------------------------------------------------------------------------------------------------------

//----------------------------------------------------------------------------------------------------------------------
// Function to add or subtract two numbers for z_in 
//----------------------------------------------------------------------------------------------------------------------
function  [(Z_WIDTH-1):0] add_sub_z1;

  input   [(Z_WIDTH-1):0]                             ip_a;
  input   [(Z_WIDTH-1):0]                             ip_b;
  input                                               addnsub;
  
  reg     [(Z_WIDTH-1):0]                             operand_b;
  reg                                                 carry_in;
  begin
//    if (~addnsub)
//      begin
//        operand_b                                     = ~ip_b;
//        carry_in                                      = 1'b1;
//      end
//    else
//      begin
//        operand_b                                     = ip_b;
//        carry_in                                      = 1'b0;
//      end
//    
//    add_sub_z1                                        = ip_a + operand_b + carry_in;

    if (addnsub)
      add_sub_z1                                      = ip_a + ip_b;
    else
      add_sub_z1                                      = ip_a - ip_b;

  end
endfunction
//----------------------------------------------------------------------------------------------------------------------

//----------------------------------------------------------------------------------------------------------------------
// Function to add or subtract two numbers for z in CORDIC  
//----------------------------------------------------------------------------------------------------------------------
//function  [(Z_WIDTH-2):0] add_sub_z2;
//
//  input   [(Z_WIDTH-2):0]                             ip_a;
//  input   [(Z_WIDTH-2):0]                             ip_b;
//  input                                               addnsub;
//  
//  reg     [(Z_WIDTH-2):0]                             operand_b;
//  reg                                                 carry_in;
//
//  begin
//    if (~addnsub)
//      begin
//        operand_b                                     = ~ip_b;
//        carry_in                                      = 1'b1;
//      end
//    else
//      begin
//        operand_b                                     = ip_b;
//        carry_in                                      = 1'b0;
//      end
//    
//    add_sub_z2                                        = ip_a + operand_b + carry_in;
//
////    if (addnsub)
////      add_sub_z2                                      = ip_a + ip_b;
////    else
////      add_sub_z2                                      = ip_a - ip_b;
//
//  end
//endfunction

//----------------------------------------------------------------------------------------------------------------------
// Parameters for GAIN Compensation block which is not part of CORDIC
//----------------------------------------------------------------------------------------------------------------------
//Latency in clock cycles through GAIN COMPENSATION BLOCK
parameter           GAIN_COMP1_LAT                    = 6;

parameter           GAIN_COMP2_LAT                    = 3;

//----------------------------------------------------------------------------------------------------------------------

