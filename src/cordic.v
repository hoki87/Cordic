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
// Module     	: cordic
// File     	: cordic.v
// Created by   : ksd
//
// Revision  	: 
//
// Abstract:
//
// Converts between polar to cartesian and cartesian to polar co-ordinates using 
// CORDIC (CO-ordinate Rotatioal DIgital Computer) algorithm.
//
// Polar to Cartesian
// ===================
// x_in           = polar magnitude
// y_in           = 0
// z_in           = phase angle (-pi to + pi)
// rotnvec_mode   = 1 (ROTATIONAL MODE)
//
// The result is
// x_out          = x value (scaled)
// y_out          = y value (scaled)
// z_out          ~ 0
//
// Result arrives at output after ITER + 3 clk cycles
//
// Cartesian to Polar
// ===================
// x_in           = x value
// y_in           = y value
// z_in           = 0
// rotnvec_mode   = 0 (VECTORING MODE)
//
// The result is
// x_out          = polar magnitude (scaled)
// y_out          =  approx ~
// z_out          = phase angle (-pi to +pi)
//
// Result arrives at output after ITER + 3 clk cycles
//
// Scaling
// ========
// Results are scaled by ~1.6467
// This needs to be corrected for somewhere in the system. The CORDIC block itself does not compensate for this scaling.
//
// Inputs
// ======
// x_in/out and y_in/out are twos complement numbers; thus can accept these to be in any of 4 quadrants in Cartesian plane.
// z_in/out is also a twos complement number representing angles of -pi to + pi
//
// PIPELINED
// =========
// On each clk cycle new input data, with different mode setting (rotnvec_mode value) for the CORDIC algorithm, can be fed
// into the CORDIC block.
// After initial latency of ITER + 3 clk cycles, results will be output on every cycle.
//
// Note on length of input/output vectors for X and Y
// ===================================================
// If the required length of X and Y values in the Cartesian plane can be represented by say K BITS, 
// then the length to parameterise (XY_WIDTH set in the include file) the input/output vector lengths for X and Y should
// be :
//      K + 3 BITS
// because : 
//     the same block is to be used for both Cartesian to Polar and Polar to Cartesian conversions; thus an extra bit
//     will be required to represent the magnitude of a K bit XY vector.
//
//     also an extra 2 bits are required to take into account the processing gain of the CORDIC block.
//----------------------------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

module cordic
  (
    clk,
    rst_n,
    
    //Input data
    rotnvec_mode,
    x_in,
    y_in,
    z_in,
    
    //Output data
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
    
//Input data
input                                                 rotnvec_mode;
input   [(XY_WIDTH-1):0]                              x_in;
input   [(XY_WIDTH-1):0]                              y_in;
input   [(Z_WIDTH-1):0]                               z_in;

//Output data
output  [(XY_WIDTH-1):0]                              x_out;
output  [(XY_WIDTH-1):0]                              y_out;
output  [(Z_WIDTH-1):0]                               z_out;

//----------------------------------------------------------------------------------------------------------------------

reg     [(XY_WIDTH-1):0]                              x_out;
reg     [(XY_WIDTH-1):0]                              y_out;
reg     [(Z_WIDTH-1):0]                               z_out;

//----------------------------------------------------------------------------------------------------------------------
reg                                                   rotnvec_mode_r;
reg     [(XY_WIDTH-1):0]                              x_in_r;
reg     [(XY_WIDTH-1):0]                              y_in_r;
reg     [(Z_WIDTH-1):0]                               z_in_r;

wire    [31:0]                                        ppi2;
wire    [31:0]                                        npi2;

wire    [1:0]                                         quadrant_c;

wire    [(XY_WIDTH-1):0]                              x_in_cd_c;
wire    [(XY_WIDTH-1):0]                              y_in_cd_c;
wire    [(Z_WIDTH-1):0]                               z_in_cd_c;


integer                                               cnt;

wire    [(XY_WIDTH-1):0]                              x_out_c;
wire    [(XY_WIDTH-1):0]                              y_out_c;
wire    [(Z_WIDTH-1):0]                               z_out_c;
wire    [(XY_WIDTH-1):0]                              x_out_pipe;
wire    [(XY_WIDTH-1):0]                              y_out_pipe;
wire    [(Z_WIDTH-1):0]                               z_out_pipe;
wire    [1:0]                                         quad_out_pipe;
wire                                                  rotnvec_mode_pipe;


wire                                                  x_in_neg;
wire                                                  y_in_neg;
//----------------------------------------------------------------------------------------------------------------------
// Registering inputs
//----------------------------------------------------------------------------------------------------------------------
always  @(posedge clk or negedge rst_n)
  if (~rst_n)
    begin
      rotnvec_mode_r                                  <= 1'b0;
      x_in_r                                          <= {XY_WIDTH{1'b0}};
      y_in_r                                          <= {XY_WIDTH{1'b0}};
      z_in_r                                          <= {Z_WIDTH{1'b0}};  
    end
  else
    begin
      rotnvec_mode_r                                  <= rotnvec_mode;
      x_in_r                                          <= x_in;
      y_in_r                                          <= y_in;
      z_in_r                                          <= z_in;  
    end
//----------------------------------------------------------------------------------------------------------------------
// DETERMINING CARTESIAN QUADRANT INFORMATION CONCERNING INPUTS
// 
//----------------------------------------------------------------------------------------------------------------------
assign x_in_neg                                       = x_in_r[(XY_WIDTH-1)];
assign y_in_neg                                       = y_in_r[(XY_WIDTH-1)];

ip_quad_info #(IN_WIDTH)                              u_ip_quad_info 
(
    .rotnvec_mode                                     (rotnvec_mode_r),
    
    .x_neg                                            (x_in_neg),
    .y_neg                                            (y_in_neg),
    .z_in                                             (z_in_r),
    
    .quadrant_c                                       (quadrant_c)
);

//----------------------------------------------------------------------------------------------------------------------

//----------------------------------------------------------------------------------------------------------------------
// Preprocessing X, Y, and Z Inputs to CORDIC
//
// Preforms any quadrant adjustment.
//
//----------------------------------------------------------------------------------------------------------------------
ip_quad_adj #(IN_WIDTH)                               u_ip_quad_adj
  (
    .rotnvec_mode                                     (rotnvec_mode_r),
    
    .x_in                                             (x_in_r),
    .y_in                                             (y_in_r),
    .z_in                                             (z_in_r),
    .quadrant                                         (quadrant_c),
    .x_in_neg                                         (x_in_neg),
    
    .x_qadj_c                                         (x_in_cd_c),
    .y_qadj_c                                         (y_in_cd_c),
    .z_qadj_c                                         (z_in_cd_c)
    
  );

  
//----------------------------------------------------------------------------------------------------------------------
// CORDIC IMPLEMENTATION
//
//----------------------------------------------------------------------------------------------------------------------
cordic_core #(IN_WIDTH)                               u_cordic_core
  (
    .clk                                              (clk),
    .rst_n                                            (rst_n),

    .rotnvec_mode                                     (rotnvec_mode_r),
    .quadrant                                         (quadrant_c),
    .x_in                                             (x_in_cd_c),
    .y_in                                             (y_in_cd_c),
    .z_in                                             (z_in_cd_c),
    
    .rotnvec_mode_out                                 (rotnvec_mode_pipe),
    .quadrant_out                                     (quad_out_pipe),
    .x_out                                            (x_out_pipe),
    .y_out                                            (y_out_pipe),
    .z_out                                            (z_out_pipe)
    
  );


//----------------------------------------------------------------------------------------------------------------------
// POST PROCESSING X, Y, and Z Outputs from CORDIC
//
// Quadrant adjustment
//
//----------------------------------------------------------------------------------------------------------------------
op_quad_adj #(IN_WIDTH)                               u_op_quad_adj
  (
    .rotnvec_mode                                     (rotnvec_mode_pipe),
    .quadrant                                         (quad_out_pipe),
    
    .x_out                                            (x_out_pipe),
    .y_out                                            (y_out_pipe),
    .z_out                                            (z_out_pipe),
    
    .x_out_qadj_c                                     (x_out_c),
    .y_out_qadj_c                                     (y_out_c),
    .z_out_qadj_c                                     (z_out_c)
    
  );

//----------------------------------------------------------------------------------------------------------------------
// Registering outputs
//----------------------------------------------------------------------------------------------------------------------
always  @(posedge clk or negedge rst_n)
  if (~rst_n)
    begin
      x_out                                           <= {XY_WIDTH{1'b0}};
      y_out                                           <= {XY_WIDTH{1'b0}};
      z_out                                           <= {Z_WIDTH{1'b0}};  
    end
  else
    begin
      x_out                                           <= x_out_c;
      y_out                                           <= y_out_c;
      z_out                                           <= z_out_c;  
    end
  
//----------------------------------------------------------------------------------------------------------------------
  
endmodule
