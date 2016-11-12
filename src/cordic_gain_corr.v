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
// Module     	: cordic_gain_corr
// File     	: cordic_gain_corr.v
// Created by   : ksd
//
// Revision  	: 
//
// Abstract:  X and Y outputs from CORDIC are scaled by processing gain.
//            This module corrects for this gain on X.
//
//            For Cartesian to Polar conversion the output X value from CORDIC is scaled and will require dividing by
//            processing gain.
//
//            For Polar to Cartesian conversion the output X and Y values from CORDIC are scaled. Rather than dividing
//            both X and Y outputs by processing gain, can divide X input to CORDIC by processing gain. However
//            to keep module generic, Y input is also scaled (cope with
//            situations where rotating a vector through an angle; i.e.
//            where y_in is nonzero)
//
//            Processing gain = product (for i=0 to number of iterations) sq_rt(1+2^-2i).
//
//            As iterations approachs infinity processing gain approaches ~1.6467
//
//            Divide X in/output by processing gain OR
//                multiply X in/output by 1/processing_gain = 1/1.6467 ~ 0.607275156
//
//
//          TWO IMPLEMENTATIONS selected by value of parameter GAIN_MODEL:
//
//          GAIN_MODEL==1
//          =============
//          Perform this by doing series of shifts and adds/sub :
//          int_val01 = ((1/2)X + (1/8)X) - ((1/64)X + (1/512)X) = (311/512)X.
//
//          int_val02 = int_val01 - (1/4096)int_val01 = (311/512)X - (1/4096*311/512)X = (1273545/2097152)X
//
//
//          GAIN_MODEL==2
//          ==============
//          Multiply x value by gain factor given by parameter RECIP_GAIN.
//          Then SHIFT result to the right by x_bits - 1 to correct for scaling factor in calculations
//
//          This solution is intended to be implemented in a STRATIX DSP block.
//
//          When x_in is divided down
//          =========================
//          Only if rotnvec_mode_in equals comp_mode, is the x_in value/ y_in_value divided down.
//          Otherwise a delayed version of x_in/y_in  is output.
//
//          This allows both Cartesian to Polar conversion requests and Polar to Cartesian conversion requests to be
//          fed into this block and only the relevant requests (given by setting of comp_mode) have their x_in values
//          divided down.
//
//          Unmodified inputs
//          ==================
//          rotnvec_mode_in, y_in and z_in are delayed by the number of cycles required to divide down the x_in input,
//          so that all values are output in the same cycle.
//
//        
//----------------------------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

module cordic_gain_corr
  (
    clk,
    rst_n,
    
    //Input data
    rotnvec_mode_in,
    comp_mode,
    x_in,
    y_in,
    z_in,
    
    //Output data
    rotnvec_mode_out,
    x_out,
    y_out,
    z_out
    
  );

//----------------------------------------------------------------------------------------------------------------------
// Parameters
//----------------------------------------------------------------------------------------------------------------------

//include file containing  constants and function declarations
`include            "cordic_inc.v"

parameter           MULT_WIDTH                        = 2 * XY_WIDTH;
//----------------------------------------------------------------------------------------------------------------------
input                                                 clk;
input                                                 rst_n;
    
//Input data
input                                                 rotnvec_mode_in;
input                                                 comp_mode;
input   [(XY_WIDTH-1):0]                              x_in;
input   [(XY_WIDTH-1):0]                              y_in;
input   [(Z_WIDTH-1):0]                               z_in;

//Output data
output                                                rotnvec_mode_out;
output  [(XY_WIDTH-1):0]                              x_out;
output  [(XY_WIDTH-1):0]                              y_out;
output  [(Z_WIDTH-1):0]                               z_out;

//----------------------------------------------------------------------------------------------------------------------

wire                                                  rotnvec_mode_out;
wire    [(XY_WIDTH-1):0]                              x_out;
wire    [(XY_WIDTH-1):0]                              y_out;
wire    [(Z_WIDTH-1):0]                               z_out;

//----------------------------------------------------------------------------------------------------------------------

reg     [(XY_WIDTH-1):0]                              x_in_shift[ 0 : (GAIN_COMP1_LAT-2)];
reg     [(XY_WIDTH-1):0]                              y_in_shift[ 0 : (GAIN_COMP1_LAT-2)];
reg     [(Z_WIDTH-1):0]                               z_in_shift[ 0 : (GAIN_COMP1_LAT-2)];
reg     [(GAIN_COMP1_LAT-2) : 0]                      rotnvec_in_shift;
reg     [(GAIN_COMP1_LAT-2) : 0]                      comp_mode_shift;
reg     [(XY_WIDTH-1):0]                              x_in_r /* synthesis preserve */;
reg     [(XY_WIDTH-1):0]                              y_in_r;
reg     [(Z_WIDTH-1):0]                               z_in_r;
reg                                                   rotnvec_in_r;
reg                                                   comp_mode_r;
reg     [(XY_WIDTH-1):0]                              x_in_r2;
reg     [(XY_WIDTH-1):0]                              y_in_r2;
reg     [(Z_WIDTH-1):0]                               z_in_r2;
reg                                                   rotnvec_in_r2;
reg                                                   comp_mode_r2;

integer                                               stage;

reg                                                   rotnvec_out_mod1;
reg     [(XY_WIDTH-1):0]                              x_out_mod1;
reg     [(XY_WIDTH-1):0]                              y_out_mod1;
reg     [(Z_WIDTH-1):0]                               z_out_mod1;

reg                                                   rotnvec_out_mod2;
reg     [(XY_WIDTH-1):0]                              x_out_mod2;
reg     [(XY_WIDTH-1):0]                              y_out_mod2;
reg     [(Z_WIDTH-1):0]                               z_out_mod2;

wire                                                  rotnvec_mode_out_use;
wire    [(XY_WIDTH-1):0]                              x_out_use;
wire    [(XY_WIDTH-1):0]                              y_out_use;
wire    [(Z_WIDTH-1):0]                               z_out_use;
wire    [(XY_WIDTH-1):0]                              shift_add_res_c;
wire    [(XY_WIDTH-1):0]                              yshift_add_res_c;


wire    [(XY_WIDTH-1):0]                              x_in_shift0_c;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              x_in_ext_c;

reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              x_rshift1_c;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              x_rshift3_c;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              x_rshift6_c;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              x_rshift9_c;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              x_rshift15_c;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              x_rshift17_c;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              x_rshift19_c;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              x_rshift22_c;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              x_rshift24_c;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              x_rshift30_c;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              x_rshift32_c;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              sum1_3_rshift24_c;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              sum1_3_n6_n9_r12_c;
wire    [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              sum_final;

reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              x_rshift9_r;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              x_rshift19_r;

reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              sum1_3_pipe1;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              sum6_9_pipe1;

reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              sum17_n15_pipe2;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              sum19_m1_3_pipe2;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              sum1_3_n6_n9_pipe2;

reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              sum17_n15_19_m_pipe3;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              sum22_24_pipe3;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              sum30_32_pipe3;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              sum_int1_pipe3;

reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              sum_int1_pipe4;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              sum_int2_pipe4;


wire    [(XY_WIDTH-1):0]                              operanda_c;
reg     [(XY_WIDTH-1):0]                              operanda_r /* synthesis preserve */;
reg     [(XY_WIDTH-1):0]                              operandb_r /* synthesis preserve */;
wire    [(XY_WIDTH-1):0]                              operandb_c;
wire    [(2*XY_WIDTH-1):0]                            mult_result_c;
wire    [(XY_WIDTH-1):0]                              scaled_mult_res_c;

//reg     [(2*XY_WIDTH-1):0]                            mult_result_r;
wire    [(2*XY_WIDTH-1):0]                            mult_result_r;

wire    [(XY_WIDTH-1):0]                              y_in_shift0_c;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              y_in_ext_c;

reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              y_rshift1_c;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              y_rshift3_c;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              y_rshift6_c;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              y_rshift9_c;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              y_rshift15_c;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              y_rshift17_c;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              y_rshift19_c;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              y_rshift22_c;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              y_rshift24_c;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              y_rshift30_c;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              y_rshift32_c;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              ysum1_3_rshift24_c;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              ysum1_3_n6_n9_r12_c;
wire    [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              ysum_final;

reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              y_rshift9_r;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              y_rshift19_r;

reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              ysum1_3_pipe1;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              ysum6_9_pipe1;

reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              ysum17_n15_pipe2;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              ysum19_m1_3_pipe2;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              ysum1_3_n6_n9_pipe2;

reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              ysum17_n15_19_m_pipe3;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              ysum22_24_pipe3;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              ysum30_32_pipe3;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              ysum_int1_pipe3;

reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              ysum_int1_pipe4;
reg     [(XY_WIDTH+X_GAIN_EXT_BITS-1):0]              ysum_int2_pipe4;


wire    [(XY_WIDTH-1):0]                              yscaled_mult_res_c;

wire    [(2*XY_WIDTH-1):0]                            ymult_result_r;

//----------------------------------------------------------------------------------------------------------------------
// GAIN COMPENSATION IMPLEMENTATION 1
//  using shifts and adds 
//----------------------------------------------------------------------------------------------------------------------
  
//----------------------------------------------------------------------------------------------------------------------
// Shift Registers for x y z and mode inputs
//----------------------------------------------------------------------------------------------------------------------
always  @(posedge clk or negedge rst_n)
  if (~rst_n)
    begin
      for (stage=0;stage <= (GAIN_COMP1_LAT-2); stage = stage + 1)
        begin
          x_in_shift[stage]                           <= {XY_WIDTH{1'b0}};
          y_in_shift[stage]                           <= {XY_WIDTH{1'b0}};
          z_in_shift[stage]                           <= {Z_WIDTH{1'b0}};
          rotnvec_in_shift[stage]                     <= 1'b0;
          comp_mode_shift[stage]                      <= 1'b0;
        end
    end
  else
    begin
      for (stage=1;stage <= (GAIN_COMP1_LAT-2); stage = stage + 1)
        begin
          x_in_shift[stage]                         <= x_in_shift[stage-1];
          y_in_shift[stage]                         <= y_in_shift[stage-1];
          z_in_shift[stage]                         <= z_in_shift[stage-1];
          rotnvec_in_shift[stage]                   <= rotnvec_in_shift[stage-1];
          comp_mode_shift[stage]                    <= comp_mode_shift[stage-1];
        end
        x_in_shift[0]                               <= x_in;
        y_in_shift[0]                               <= y_in;
        z_in_shift[0]                               <= z_in;
        rotnvec_in_shift[0]                         <= rotnvec_mode_in;
        comp_mode_shift[0]                          <= comp_mode;
      end

//----------------------------------------------------------------------------------------------------------------------
// Registering outputs
//----------------------------------------------------------------------------------------------------------------------
always  @(posedge clk or negedge rst_n)
  if (~rst_n)
    begin
      x_out_mod1                                      <= {XY_WIDTH{1'b0}};
      y_out_mod1                                      <= {XY_WIDTH{1'b0}};
      z_out_mod1                                      <= {Z_WIDTH{1'b0}};
      rotnvec_out_mod1                                <= 1'b0;  
    end
  else
    begin
      if (rotnvec_in_shift[(GAIN_COMP1_LAT-2)]==comp_mode_shift[(GAIN_COMP1_LAT-2)])
        begin
          x_out_mod1                                  <= shift_add_res_c;

          if (rotnvec_in_shift[(GAIN_COMP1_LAT-2)]== 1'b1)
          begin
            y_out_mod1                                <= yshift_add_res_c; 
          end
          else
          begin
            y_out_mod1                                <= y_in_shift[(GAIN_COMP1_LAT-2)];
          end
        end
      else
        begin
          x_out_mod1                                  <= x_in_shift[(GAIN_COMP1_LAT-2)];
          y_out_mod1                                  <= y_in_shift[(GAIN_COMP1_LAT-2)];
        end

        
      z_out_mod1                                      <= z_in_shift[(GAIN_COMP1_LAT-2)];
      rotnvec_out_mod1                                <= rotnvec_in_shift[(GAIN_COMP1_LAT-2)];  
    end

//----------------------------------------------------------------------------------------------------------------------
// x/y value to divide (= registered version of input with extended number of lower bits to improve accuracy of
// calculation)
//----------------------------------------------------------------------------------------------------------------------
assign  x_in_shift0_c                                 = x_in_shift[0];
always  @(x_in_shift0_c)
  begin
    x_in_ext_c                                        = {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
    x_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): X_GAIN_EXT_BITS] = x_in_shift0_c;
  end

assign  y_in_shift0_c                                 = y_in_shift[0];
always  @(y_in_shift0_c)
  begin
    y_in_ext_c                                        = {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
    y_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): X_GAIN_EXT_BITS] = y_in_shift0_c;
  end

  
//----------------------------------------------------------------------------------------------------------------------
// Dividing X/Y by processing gain
// X may not always be positive; Thus need to signextending X (and Y) in
// below calculations.
//
// -- multiplying by 0.1001_1011_0111_0100_1110_1101_1010_0101 = 0.607252934 (reciprocal of processing gain)
//----------------------------------------------------------------------------------------------------------------------

//-- FIRST STAGE
//assign  x_rshift1_c                                   = x_in_ext_c >> 1;
//assign  x_rshift1_c[(XY_WIDTH+X_GAIN_EXT_BITS-2):0]   = x_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1):1];
//assign  x_rshift1_c[(XY_WIDTH+X_GAIN_EXT_BITS-1)]     = x_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1)];

always @(x_in_ext_c or XY_WIDTH or X_GAIN_EXT_BITS)
begin
  x_rshift1_c                                         = x_in_ext_c >> 1;

  x_rshift1_c[(XY_WIDTH+X_GAIN_EXT_BITS-1)]           = x_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1)];
end
                                                      
//assign  x_rshift3_c                                   = x_in_ext_c >> 3;
//assign  x_rshift3_c[(XY_WIDTH+X_GAIN_EXT_BITS-4):0]   = x_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1):3];
//assign  x_rshift3_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-3)]
//                                                      = {3{x_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};

always @(x_in_ext_c or XY_WIDTH or X_GAIN_EXT_BITS)
begin
  x_rshift3_c                                         = x_in_ext_c >> 3;

  if (XY_WIDTH+X_GAIN_EXT_BITS > 3)
  begin
    x_rshift3_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-3)]  =
                                                      {3{x_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
  else
  begin
    x_rshift3_c                                        = {(XY_WIDTH+X_GAIN_EXT_BITS){x_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
end

//assign  x_rshift6_c                                   = x_in_ext_c >> 6;
//assign  x_rshift6_c[(XY_WIDTH+X_GAIN_EXT_BITS-7):0]   = x_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1):6];
//assign  x_rshift6_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-6)]     
//                                                      = {6{x_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};

always @(x_in_ext_c or XY_WIDTH or X_GAIN_EXT_BITS)
begin
  x_rshift6_c                                         = x_in_ext_c >> 6;

  if (XY_WIDTH+X_GAIN_EXT_BITS > 6)
  begin
    x_rshift6_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-6)]  =
                                                      {6{x_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
  else
  begin
    x_rshift6_c                                        = {(XY_WIDTH+X_GAIN_EXT_BITS){x_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
end

//assign  x_rshift9_c                                   = x_in_ext_c >> 9;
//assign  x_rshift9_c[(XY_WIDTH+X_GAIN_EXT_BITS-10):0]  = x_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1):9];
//assign  x_rshift9_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-9)]     
//                                                      = {9{x_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};

always @(x_in_ext_c or XY_WIDTH or X_GAIN_EXT_BITS)
begin
  x_rshift9_c                                         = x_in_ext_c >> 9;

  if (XY_WIDTH+X_GAIN_EXT_BITS > 9)
  begin
    x_rshift9_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-9)]  =
                                                      {9{x_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
  else
  begin
    x_rshift9_c                                        = {(XY_WIDTH+X_GAIN_EXT_BITS){x_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
end

always  @(posedge clk or negedge rst_n)
  if (~rst_n)
    begin
      sum1_3_pipe1                                    <= {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
      sum6_9_pipe1                                    <= {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
      x_rshift9_r                                     <= {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
    end
  else
    begin
      if (GAIN_MODEL==1)
        begin
          sum1_3_pipe1                                <= x_rshift1_c + x_rshift3_c;
          sum6_9_pipe1                                <= x_rshift6_c + x_rshift9_c;
          x_rshift9_r                                 <= x_rshift9_c;
        end
    end

//-- SECOND STAGE
//assign  sum1_3_rshift24_c                             = sum1_3_pipe1 >> 24;
//assign  sum1_3_rshift24_c[(XY_WIDTH+X_GAIN_EXT_BITS-25):0]   = sum1_3_pipe1[(XY_WIDTH+X_GAIN_EXT_BITS-1):24];
//assign  sum1_3_rshift24_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-24)]     
//                                                      = {24{sum1_3_pipe1[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
                                                    
always @(sum1_3_pipe1 or XY_WIDTH or X_GAIN_EXT_BITS)
begin
  sum1_3_rshift24_c                                     = sum1_3_pipe1 >> 24;

  if (XY_WIDTH+X_GAIN_EXT_BITS > 24)
  begin
    sum1_3_rshift24_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-24)]  =
                                                      {24{sum1_3_pipe1[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
  else
  begin
    sum1_3_rshift24_c                                 = {(XY_WIDTH+X_GAIN_EXT_BITS){sum1_3_pipe1[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
end
                                                      
//assign  x_rshift15_c                                  = x_rshift9_r  >> 6;
//assign  x_rshift15_c[(XY_WIDTH+X_GAIN_EXT_BITS-7):0]   = x_rshift9_r[(XY_WIDTH+X_GAIN_EXT_BITS-1):6];
//assign  x_rshift15_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-6)]     
//                                                      = {6{x_rshift9_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};

always @(x_rshift9_r or XY_WIDTH or X_GAIN_EXT_BITS)
begin
  x_rshift15_c                                        = x_rshift9_r >> 6;

  if (XY_WIDTH+X_GAIN_EXT_BITS > 6)
  begin
    x_rshift15_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-6)]  =
                                                      {6{x_rshift9_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
  else
  begin
    x_rshift15_c                                      = {(XY_WIDTH+X_GAIN_EXT_BITS){x_rshift9_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
end

//assign  x_rshift17_c                                  = x_rshift9_r  >> 8;
//assign  x_rshift17_c[(XY_WIDTH+X_GAIN_EXT_BITS-9):0]   = x_rshift9_r[(XY_WIDTH+X_GAIN_EXT_BITS-1):8];
//assign  x_rshift17_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-8)]     
//                                                      = {8{x_rshift9_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};

always @(x_rshift9_r or XY_WIDTH or X_GAIN_EXT_BITS)
begin
  x_rshift17_c                                        = x_rshift9_r >> 8;

  if (XY_WIDTH+X_GAIN_EXT_BITS > 8)
  begin
    x_rshift17_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-8)]  =
                                                      {8{x_rshift9_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
  else
  begin
    x_rshift17_c                                      = {(XY_WIDTH+X_GAIN_EXT_BITS){x_rshift9_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
end
                                                      
//assign  x_rshift19_c                                  = x_rshift9_r  >> 10;
//assign  x_rshift19_c[(XY_WIDTH+X_GAIN_EXT_BITS-11):0]   = x_rshift9_r[(XY_WIDTH+X_GAIN_EXT_BITS-1):10];
//assign  x_rshift19_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-10)]     
//                                                      = {10{x_rshift9_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};

always @(x_rshift9_r or XY_WIDTH or X_GAIN_EXT_BITS)
begin
  x_rshift19_c                                        = x_rshift9_r >> 10;

  if (XY_WIDTH+X_GAIN_EXT_BITS > 10)
  begin
    x_rshift19_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-10)]  =
                                                      {10{x_rshift9_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
  else
  begin
    x_rshift19_c                                      = {(XY_WIDTH+X_GAIN_EXT_BITS){x_rshift9_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
end
                                                      

always  @(posedge clk or negedge rst_n)
  if (~rst_n)
    begin
      sum17_n15_pipe2                                 <= {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
      sum19_m1_3_pipe2                                <= {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
      sum1_3_n6_n9_pipe2                              <= {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
      x_rshift19_r                                    <= {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
    end
  else
    begin
      if (GAIN_MODEL==1)
        begin
          sum17_n15_pipe2                             <= x_rshift17_c - x_rshift15_c;
          sum19_m1_3_pipe2                            <= x_rshift19_c + sum1_3_rshift24_c;
          sum1_3_n6_n9_pipe2                          <= sum1_3_pipe1 - sum6_9_pipe1;
          x_rshift19_r                                <= x_rshift19_c;
        end
    end

//-- THIRD STAGE
//assign  sum1_3_n6_n9_r12_c                            = sum1_3_n6_n9_pipe2 >> 12;
//assign  sum1_3_n6_n9_r12_c[(XY_WIDTH+X_GAIN_EXT_BITS-13):0]   = sum1_3_n6_n9_pipe2[(XY_WIDTH+X_GAIN_EXT_BITS-1):12];
//assign  sum1_3_n6_n9_r12_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-12)]     
//                                                      = {12{sum1_3_n6_n9_pipe2[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
                                                      
always @(sum1_3_n6_n9_pipe2 or XY_WIDTH or X_GAIN_EXT_BITS)
begin
  sum1_3_n6_n9_r12_c                                  = sum1_3_n6_n9_pipe2 >> 12;

  if (XY_WIDTH+X_GAIN_EXT_BITS > 12)
  begin
    sum1_3_n6_n9_r12_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-12)]  =
                                                      {12{sum1_3_n6_n9_pipe2[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
  else
  begin
    sum1_3_n6_n9_r12_c                                = {(XY_WIDTH+X_GAIN_EXT_BITS){sum1_3_n6_n9_pipe2[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
end
                                                      
//assign  x_rshift22_c                                  = x_rshift19_r       >> 3;
//assign  x_rshift22_c[(XY_WIDTH+X_GAIN_EXT_BITS-4):0]   = x_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1):3];
//assign  x_rshift22_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-3)]     
//                                                      = {3{x_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
                                                      
always @(x_rshift19_r or XY_WIDTH or X_GAIN_EXT_BITS)
begin
  x_rshift22_c                                        = x_rshift19_r >> 3;

  if (XY_WIDTH+X_GAIN_EXT_BITS > 3)
  begin
    x_rshift22_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-3)]  =
                                                      {3{x_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
  else
  begin
    x_rshift22_c                                      = {(XY_WIDTH+X_GAIN_EXT_BITS){x_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
end
                                                      
//assign  x_rshift24_c                                  = x_rshift19_r       >> 5;
//assign  x_rshift24_c[(XY_WIDTH+X_GAIN_EXT_BITS-6):0]   = x_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1):5];
//assign  x_rshift24_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-5)]     
//                                                      = {5{x_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
                                                      
always @(x_rshift19_r or XY_WIDTH or X_GAIN_EXT_BITS)
begin
  x_rshift24_c                                        = x_rshift19_r >> 5;

  if (XY_WIDTH+X_GAIN_EXT_BITS > 5)
  begin
    x_rshift24_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-5)]  =
                                                      {5{x_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
  else
  begin
    x_rshift24_c                                      = {(XY_WIDTH+X_GAIN_EXT_BITS){x_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
end
                                                      
//assign  x_rshift30_c                                  = x_rshift19_r       >> 11;
//assign  x_rshift30_c[(XY_WIDTH+X_GAIN_EXT_BITS-12):0]   = x_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1):11];
//assign  x_rshift30_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-11)]     
//                                                      = {11{x_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
                                                      
always @(x_rshift19_r or XY_WIDTH or X_GAIN_EXT_BITS)
begin
  x_rshift30_c                                        = x_rshift19_r >> 11;

  if (XY_WIDTH+X_GAIN_EXT_BITS > 11)
  begin
    x_rshift30_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-11)]  =
                                                      {11{x_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
  else
  begin
    x_rshift30_c                                      = {(XY_WIDTH+X_GAIN_EXT_BITS){x_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
end
                                                      
//assign  x_rshift32_c                                  = x_rshift19_r       >> 13;
//assign  x_rshift32_c[(XY_WIDTH+X_GAIN_EXT_BITS-14):0]   = x_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1):13];
//assign  x_rshift32_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-13)]     
//                                                      = {13{x_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
                                                      
always @(x_rshift19_r or XY_WIDTH or X_GAIN_EXT_BITS)
begin
  x_rshift32_c                                        = x_rshift19_r >> 13;

  if (XY_WIDTH+X_GAIN_EXT_BITS > 13)
  begin
    x_rshift32_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-13)]  =
                                                      {13{x_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
  else
  begin
    x_rshift32_c                                      = {(XY_WIDTH+X_GAIN_EXT_BITS){x_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
end
                                                      

always  @(posedge clk or negedge rst_n)
  if (~rst_n)
    begin
      sum_int1_pipe3                                  <= {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
      sum17_n15_19_m_pipe3                            <= {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
      sum22_24_pipe3                                  <= {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
      sum30_32_pipe3                                  <= {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
    end
  else
    begin
      if (GAIN_MODEL==1)
        begin
          sum_int1_pipe3                              <= sum1_3_n6_n9_pipe2 - sum1_3_n6_n9_r12_c;
          sum17_n15_19_m_pipe3                        <= sum17_n15_pipe2 + sum19_m1_3_pipe2;
          sum22_24_pipe3                              <= x_rshift22_c + x_rshift24_c;
          sum30_32_pipe3                              <= x_rshift30_c + x_rshift32_c;
        end
    end

//-- FOURTH STAGE
always  @(posedge clk or negedge rst_n)
  if (~rst_n)
    begin
      sum_int1_pipe4                                  <= {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
      sum_int2_pipe4                                  <= {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
    end
  else
    begin
      if (GAIN_MODEL==1)
        begin
          sum_int1_pipe4                              <= sum_int1_pipe3 + sum17_n15_19_m_pipe3;
          sum_int2_pipe4                              <= sum22_24_pipe3 + sum30_32_pipe3;
        end
    end

//-- FINAL STAGE
assign  sum_final                                     = sum_int1_pipe4 + sum_int2_pipe4;
assign  shift_add_res_c                               = sum_final[(XY_WIDTH+X_GAIN_EXT_BITS-1): X_GAIN_EXT_BITS];

//----------------------------------------------------------------------------------------------------------------------
// Dividing Y by processing gain
// Y may not always be positive; Thus need to signextending  Y in
// below calculations.
//
// -- multiplying by 0.1001_1011_0111_0100_1110_1101_1010_0101 = 0.607252934 (reciprocal of processing gain)
//----------------------------------------------------------------------------------------------------------------------

//-- FIRST STAGE
//assign  y_rshift1_c                                   = y_in_ext_c >> 1;
//assign  y_rshift1_c[(XY_WIDTH+X_GAIN_EXT_BITS-2):0]   = y_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1):1];
//assign  y_rshift1_c[(XY_WIDTH+X_GAIN_EXT_BITS-1)]     = y_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1)];

always @(y_in_ext_c or XY_WIDTH or X_GAIN_EXT_BITS)
begin
  y_rshift1_c                                         = y_in_ext_c >> 1;

  y_rshift1_c[(XY_WIDTH+X_GAIN_EXT_BITS-1)]           = y_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1)];
end
                                                      
//assign  y_rshift3_c                                   = y_in_ext_c >> 3;
//assign  y_rshift3_c[(XY_WIDTH+X_GAIN_EXT_BITS-4):0]   = y_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1):3];
//assign  y_rshift3_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-3)]
//                                                      = {3{y_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};

always @(y_in_ext_c or XY_WIDTH or X_GAIN_EXT_BITS)
begin
  y_rshift3_c                                         = y_in_ext_c >> 3;

  if (XY_WIDTH+X_GAIN_EXT_BITS > 3)
  begin
    y_rshift3_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-3)]  =
                                                      {3{y_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
  else
  begin
    y_rshift3_c                                      = {(XY_WIDTH+X_GAIN_EXT_BITS){y_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
end

//assign  y_rshift6_c                                   = y_in_ext_c >> 6;
//assign  y_rshift6_c[(XY_WIDTH+X_GAIN_EXT_BITS-7):0]   = y_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1):6];
//assign  y_rshift6_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-6)]     
//                                                      = {6{y_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};

always @(y_in_ext_c or XY_WIDTH or X_GAIN_EXT_BITS)
begin
  y_rshift6_c                                         = y_in_ext_c >> 6;

  if (XY_WIDTH+X_GAIN_EXT_BITS > 6)
  begin
    y_rshift6_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-6)]  =
                                                      {6{y_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
  else
  begin
    y_rshift6_c                                      = {(XY_WIDTH+X_GAIN_EXT_BITS){y_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
end

//assign  y_rshift9_c                                   = y_in_ext_c >> 9;
//assign  y_rshift9_c[(XY_WIDTH+X_GAIN_EXT_BITS-10):0]  = y_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1):9];
//assign  y_rshift9_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-9)]     
//                                                      = {9{y_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};

always @(y_in_ext_c or XY_WIDTH or X_GAIN_EXT_BITS)
begin
  y_rshift9_c                                         = y_in_ext_c >> 9;

  if (XY_WIDTH+X_GAIN_EXT_BITS > 9)
  begin
    y_rshift9_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-9)]  =
                                                      {9{y_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
  else
  begin
    y_rshift9_c                                      = {(XY_WIDTH+X_GAIN_EXT_BITS){y_in_ext_c[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
end

always  @(posedge clk or negedge rst_n)
  if (~rst_n)
    begin
      ysum1_3_pipe1                                    <= {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
      ysum6_9_pipe1                                    <= {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
      y_rshift9_r                                     <= {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
    end
  else
    begin
      if (GAIN_MODEL==1)
        begin
          ysum1_3_pipe1                                <= y_rshift1_c + y_rshift3_c;
          ysum6_9_pipe1                                <= y_rshift6_c + y_rshift9_c;
          y_rshift9_r                                 <= y_rshift9_c;
        end
    end

//-- SECOND STAGE
//assign  ysum1_3_rshift24_c                             = ysum1_3_pipe1 >> 24;
//assign  ysum1_3_rshift24_c[(XY_WIDTH+X_GAIN_EXT_BITS-25):0]   = ysum1_3_pipe1[(XY_WIDTH+X_GAIN_EXT_BITS-1):24];
//assign  ysum1_3_rshift24_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-24)]     
//                                                      = {24{ysum1_3_pipe1[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
                                                      
always @(ysum1_3_pipe1 or XY_WIDTH or X_GAIN_EXT_BITS)
begin
  ysum1_3_rshift24_c                                  = ysum1_3_pipe1 >> 24;

  if (XY_WIDTH+X_GAIN_EXT_BITS > 24)
  begin
    ysum1_3_rshift24_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-24)]  =
                                                      {24{ysum1_3_pipe1[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
  else
  begin
    ysum1_3_rshift24_c                                = {(XY_WIDTH+X_GAIN_EXT_BITS){ysum1_3_pipe1[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
end
                                                      
                                                      
//assign  y_rshift15_c                                  = y_rshift9_r  >> 6;
//assign  y_rshift15_c[(XY_WIDTH+X_GAIN_EXT_BITS-7):0]   = y_rshift9_r[(XY_WIDTH+X_GAIN_EXT_BITS-1):6];
//assign  y_rshift15_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-6)]     
//                                                      = {6{y_rshift9_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
always @(y_rshift9_r or XY_WIDTH or X_GAIN_EXT_BITS)
begin
  y_rshift15_c                                        = y_rshift9_r >> 6;

  if (XY_WIDTH+X_GAIN_EXT_BITS > 6)
  begin
    y_rshift15_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-6)]  =
                                                      {6{y_rshift9_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
  else
  begin
    y_rshift15_c                                      = {(XY_WIDTH+X_GAIN_EXT_BITS){y_rshift9_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
end
                                                      

//assign  y_rshift17_c                                  = y_rshift9_r  >> 8;
//assign  y_rshift17_c[(XY_WIDTH+X_GAIN_EXT_BITS-9):0]   = y_rshift9_r[(XY_WIDTH+X_GAIN_EXT_BITS-1):8];
//assign  y_rshift17_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-8)]     
//                                                      = {8{y_rshift9_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
always @(y_rshift9_r or XY_WIDTH or X_GAIN_EXT_BITS)
begin
  y_rshift17_c                                        = y_rshift9_r >> 8;

  if (XY_WIDTH+X_GAIN_EXT_BITS > 8)
  begin
    y_rshift17_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-8)]  =
                                                      {8{y_rshift9_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
  else
  begin
    y_rshift17_c                                      = {(XY_WIDTH+X_GAIN_EXT_BITS){y_rshift9_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
end
                                                      

                                                      
//assign  y_rshift19_c                                  = y_rshift9_r  >> 10;
//assign  y_rshift19_c[(XY_WIDTH+X_GAIN_EXT_BITS-11):0]   = y_rshift9_r[(XY_WIDTH+X_GAIN_EXT_BITS-1):10];
//assign  y_rshift19_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-10)]     
//                                                      = {10{y_rshift9_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};

always @(y_rshift9_r or XY_WIDTH or X_GAIN_EXT_BITS)
begin
  y_rshift19_c                                        = y_rshift9_r >> 10;

  if (XY_WIDTH+X_GAIN_EXT_BITS > 10)
  begin
    y_rshift19_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-10)]  =
                                                      {10{y_rshift9_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
  else
  begin
    y_rshift19_c                                      = {(XY_WIDTH+X_GAIN_EXT_BITS){y_rshift9_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
end
                                                      

always  @(posedge clk or negedge rst_n)
  if (~rst_n)
    begin
      ysum17_n15_pipe2                                 <= {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
      ysum19_m1_3_pipe2                                <= {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
      ysum1_3_n6_n9_pipe2                              <= {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
      y_rshift19_r                                    <= {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
    end
  else
    begin
      if (GAIN_MODEL==1)
        begin
          ysum17_n15_pipe2                             <= y_rshift17_c - y_rshift15_c;
          ysum19_m1_3_pipe2                            <= y_rshift19_c + ysum1_3_rshift24_c;
          ysum1_3_n6_n9_pipe2                          <= ysum1_3_pipe1 - ysum6_9_pipe1;
          y_rshift19_r                                <= y_rshift19_c;
        end
    end

//-- THIRD STAGE
//assign  ysum1_3_n6_n9_r12_c                            = ysum1_3_n6_n9_pipe2 >> 12;
//assign  ysum1_3_n6_n9_r12_c[(XY_WIDTH+X_GAIN_EXT_BITS-13):0]   = ysum1_3_n6_n9_pipe2[(XY_WIDTH+X_GAIN_EXT_BITS-1):12];
//assign  ysum1_3_n6_n9_r12_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-12)]     
//                                                      = {12{ysum1_3_n6_n9_pipe2[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};

always @(ysum1_3_n6_n9_pipe2 or XY_WIDTH or X_GAIN_EXT_BITS)
begin
  ysum1_3_n6_n9_r12_c                                        = ysum1_3_n6_n9_pipe2 >> 12;

  if (XY_WIDTH+X_GAIN_EXT_BITS > 12)
  begin
    ysum1_3_n6_n9_r12_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-12)]  =
                                                      {12{ysum1_3_n6_n9_pipe2[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
  else
  begin
    ysum1_3_n6_n9_r12_c                               = {(XY_WIDTH+X_GAIN_EXT_BITS){ysum1_3_n6_n9_pipe2[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
end
                                                      
                                                      
//assign  y_rshift22_c                                  = y_rshift19_r       >> 3;
//assign  y_rshift22_c[(XY_WIDTH+X_GAIN_EXT_BITS-4):0]   = y_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1):3];
//assign  y_rshift22_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-3)]     
//                                                      = {3{y_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};

always @(y_rshift19_r or XY_WIDTH or X_GAIN_EXT_BITS)
begin
  y_rshift22_c                                        = y_rshift19_r >> 3;

  if (XY_WIDTH+X_GAIN_EXT_BITS > 3)
  begin
    y_rshift22_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-3)]  =
                                                      {3{y_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
  else
  begin
    y_rshift22_c                                      = {(XY_WIDTH+X_GAIN_EXT_BITS){y_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
end
                                                      
                                                      
//assign  y_rshift24_c                                  = y_rshift19_r       >> 5;
//assign  y_rshift24_c[(XY_WIDTH+X_GAIN_EXT_BITS-6):0]   = y_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1):5];
//assign  y_rshift24_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-5)]     
//                                                      = {5{y_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};

always @(y_rshift19_r or XY_WIDTH or X_GAIN_EXT_BITS)
begin
  y_rshift24_c                                        = y_rshift19_r >> 5;

  if (XY_WIDTH+X_GAIN_EXT_BITS > 5)
  begin
    y_rshift24_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-5)]  =
                                                      {5{y_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
  else
  begin
    y_rshift24_c                                      = {(XY_WIDTH+X_GAIN_EXT_BITS){y_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
end
                                                      
                                                      
//assign  y_rshift30_c                                  = y_rshift19_r       >> 11;
//assign  y_rshift30_c[(XY_WIDTH+X_GAIN_EXT_BITS-12):0]   = y_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1):11];
//assign  y_rshift30_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-11)]     
//                                                      = {11{y_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};

always @(y_rshift19_r or XY_WIDTH or X_GAIN_EXT_BITS)
begin
  y_rshift30_c                                        = y_rshift19_r >> 11;

  if (XY_WIDTH+X_GAIN_EXT_BITS > 11)
  begin
    y_rshift30_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-11)]  =
                                                      {11{y_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
  else
  begin
    y_rshift30_c                                      = {(XY_WIDTH+X_GAIN_EXT_BITS){y_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
end
                                                      
                                                      
//assign  y_rshift32_c                                  = y_rshift19_r       >> 13;
//assign  y_rshift32_c[(XY_WIDTH+X_GAIN_EXT_BITS-14):0]   = y_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1):13];
//assign  y_rshift32_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-13)]     
//                                                      = {13{y_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};

always @(y_rshift19_r or XY_WIDTH or X_GAIN_EXT_BITS)
begin
  y_rshift32_c                                        = y_rshift19_r >> 13;

  if (XY_WIDTH+X_GAIN_EXT_BITS > 13)
  begin
    y_rshift32_c[(XY_WIDTH+X_GAIN_EXT_BITS-1): (XY_WIDTH+X_GAIN_EXT_BITS-13)]  =
                                                      {13{y_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
  else
  begin
    y_rshift32_c                                      = {(XY_WIDTH+X_GAIN_EXT_BITS){y_rshift19_r[(XY_WIDTH+X_GAIN_EXT_BITS-1)]}};
  end
end
                                                      
                                                      

always  @(posedge clk or negedge rst_n)
  if (~rst_n)
    begin
      ysum_int1_pipe3                                  <= {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
      ysum17_n15_19_m_pipe3                            <= {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
      ysum22_24_pipe3                                  <= {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
      ysum30_32_pipe3                                  <= {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
    end
  else
    begin
      if (GAIN_MODEL==1)
        begin
          ysum_int1_pipe3                              <= ysum1_3_n6_n9_pipe2 - ysum1_3_n6_n9_r12_c;
          ysum17_n15_19_m_pipe3                        <= ysum17_n15_pipe2 + ysum19_m1_3_pipe2;
          ysum22_24_pipe3                              <= y_rshift22_c + y_rshift24_c;
          ysum30_32_pipe3                              <= y_rshift30_c + y_rshift32_c;
        end
    end

//-- FOURTH STAGE
always  @(posedge clk or negedge rst_n)
  if (~rst_n)
    begin
      ysum_int1_pipe4                                  <= {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
      ysum_int2_pipe4                                  <= {(XY_WIDTH+X_GAIN_EXT_BITS){1'b0}};
    end
  else
    begin
      if (GAIN_MODEL==1)
        begin
          ysum_int1_pipe4                              <= ysum_int1_pipe3 + ysum17_n15_19_m_pipe3;
          ysum_int2_pipe4                              <= ysum22_24_pipe3 + ysum30_32_pipe3;
        end
    end

//-- FINAL STAGE
assign  ysum_final                                     = ysum_int1_pipe4 + ysum_int2_pipe4;
assign  yshift_add_res_c                               = ysum_final[(XY_WIDTH+X_GAIN_EXT_BITS-1): X_GAIN_EXT_BITS];

//----------------------------------------------------------------------------------------------------------------------
// GAIN COMPENSATION IMPLEMENTATION 2
//  using multiplys 
//----------------------------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------------------------
// Registering  x y z and mode inputs
//----------------------------------------------------------------------------------------------------------------------
always  @(posedge clk or negedge rst_n)
  if (~rst_n)
    begin
        x_in_r                                        <= {XY_WIDTH{1'b0}};
        y_in_r                                        <= {XY_WIDTH{1'b0}};
        z_in_r                                        <= {Z_WIDTH{1'b0}};
        rotnvec_in_r                                  <= 1'b0;
        comp_mode_r                                   <= 1'b0;
    end
  else
    begin
      //using multiply logic
      x_in_r                                          <= x_in;
      y_in_r                                          <= y_in;
      z_in_r                                          <= z_in;
      rotnvec_in_r                                    <= rotnvec_mode_in;
      comp_mode_r                                     <= comp_mode;
    end

always  @(posedge clk or negedge rst_n)
  if (~rst_n)
    begin
      x_in_r2                                         <= {XY_WIDTH{1'b0}};
      y_in_r2                                         <= {XY_WIDTH{1'b0}};
      z_in_r2                                         <= {Z_WIDTH{1'b0}};
      rotnvec_in_r2                                   <= 1'b0; 
      comp_mode_r2                                    <= 1'b0; 
    end
  else
    begin
      x_in_r2                                         <= x_in_r;
      y_in_r2                                         <= y_in_r;
      z_in_r2                                         <= z_in_r;
      rotnvec_in_r2                                   <= rotnvec_in_r; 
      comp_mode_r2                                    <= comp_mode_r;
    end
//----------------------------------------------------------------------------------------------------------------------
// Instantiating Stratix DSP block (registers inputs and also output)
//
//----------------------------------------------------------------------------------------------------------------------
//altmult_add	                                      gain_mult_dsp_blk 
//(
//  .dataa                                              (x_in),
//  .datab                                              (RECIP_GAIN),
//  .clock0                                             (clk),
//  .aclr3                                              (~rst_n),
//  .result                                             (mult_result_r) 
//);
//defparam
//// input reg; output of multiplier reg
//  gain_mult_dsp_blk.multiplier_register0 = "CLOCK0",
//  gain_mult_dsp_blk.signed_pipeline_aclr_b = "ACLR3",
//  gain_mult_dsp_blk.addnsub_multiplier_pipeline_aclr1 = "ACLR3",
//  gain_mult_dsp_blk.signed_aclr_a = "ACLR3",
//  gain_mult_dsp_blk.signed_register_a = "CLOCK0",
//  gain_mult_dsp_blk.number_of_multipliers = 1,
//  gain_mult_dsp_blk.multiplier_aclr0 = "ACLR3",
//  gain_mult_dsp_blk.signed_aclr_b = "ACLR3",
//  gain_mult_dsp_blk.signed_register_b = "CLOCK0",
//  gain_mult_dsp_blk.lpm_type = "altmult_add",
//  gain_mult_dsp_blk.input_aclr_b0 = "ACLR3",
//  gain_mult_dsp_blk.output_register = "UNREGISTERED",
//  gain_mult_dsp_blk.representation_a = "SIGNED",
//  gain_mult_dsp_blk.signed_pipeline_register_a = "CLOCK0",
//  gain_mult_dsp_blk.width_result = MULT_WIDTH,
//  gain_mult_dsp_blk.input_source_b0 = "DATAB",
//  gain_mult_dsp_blk.input_aclr_a0 = "ACLR3",
//  gain_mult_dsp_blk.addnsub_multiplier_register1 = "CLOCK0",
//  gain_mult_dsp_blk.representation_b = "SIGNED",
//  gain_mult_dsp_blk.signed_pipeline_register_b = "CLOCK0",
//  gain_mult_dsp_blk.input_source_a0 = "DATAA",
//  gain_mult_dsp_blk.dedicated_multiplier_circuitry = "YES",
//  gain_mult_dsp_blk.addnsub_multiplier_aclr1 = "ACLR3",
//  gain_mult_dsp_blk.addnsub_multiplier_pipeline_register1 = "CLOCK0",
//  gain_mult_dsp_blk.width_a = XY_WIDTH,
//  gain_mult_dsp_blk.input_register_b0 = "CLOCK0",
//  gain_mult_dsp_blk.width_b = XY_WIDTH,
//  gain_mult_dsp_blk.input_register_a0 = "CLOCK0",
//  gain_mult_dsp_blk.multiplier1_direction = "ADD",
//  gain_mult_dsp_blk.signed_pipeline_aclr_a = "ACLR3";
//
//
//
//assign  scaled_mult_res_c                             = mult_result_r >> (XY_WIDTH-1);
//
//altmult_add	                                      ygain_mult_dsp_blk 
//(
//  .dataa                                              (y_in),
//  .datab                                              (RECIP_GAIN),
//  .clock0                                             (clk),
//  .aclr3                                              (~rst_n),
//  .result                                             (ymult_result_r) 
//);
//defparam
//// input reg; output of multiplier reg
//  ygain_mult_dsp_blk.multiplier_register0 = "CLOCK0",
//  ygain_mult_dsp_blk.signed_pipeline_aclr_b = "ACLR3",
//  ygain_mult_dsp_blk.addnsub_multiplier_pipeline_aclr1 = "ACLR3",
//  ygain_mult_dsp_blk.signed_aclr_a = "ACLR3",
//  ygain_mult_dsp_blk.signed_register_a = "CLOCK0",
//  ygain_mult_dsp_blk.number_of_multipliers = 1,
//  ygain_mult_dsp_blk.multiplier_aclr0 = "ACLR3",
//  ygain_mult_dsp_blk.signed_aclr_b = "ACLR3",
//  ygain_mult_dsp_blk.signed_register_b = "CLOCK0",
//  ygain_mult_dsp_blk.lpm_type = "altmult_add",
//  ygain_mult_dsp_blk.input_aclr_b0 = "ACLR3",
//  ygain_mult_dsp_blk.output_register = "UNREGISTERED",
//  ygain_mult_dsp_blk.representation_a = "SIGNED",
//  ygain_mult_dsp_blk.signed_pipeline_register_a = "CLOCK0",
//  ygain_mult_dsp_blk.width_result = MULT_WIDTH,
//  ygain_mult_dsp_blk.input_source_b0 = "DATAB",
//  ygain_mult_dsp_blk.input_aclr_a0 = "ACLR3",
//  ygain_mult_dsp_blk.addnsub_multiplier_register1 = "CLOCK0",
//  ygain_mult_dsp_blk.representation_b = "SIGNED",
//  ygain_mult_dsp_blk.signed_pipeline_register_b = "CLOCK0",
//  ygain_mult_dsp_blk.input_source_a0 = "DATAA",
//  ygain_mult_dsp_blk.dedicated_multiplier_circuitry = "YES",
//  ygain_mult_dsp_blk.addnsub_multiplier_aclr1 = "ACLR3",
//  ygain_mult_dsp_blk.addnsub_multiplier_pipeline_register1 = "CLOCK0",
//  ygain_mult_dsp_blk.width_a = XY_WIDTH,
//  ygain_mult_dsp_blk.input_register_b0 = "CLOCK0",
//  ygain_mult_dsp_blk.width_b = XY_WIDTH,
//  ygain_mult_dsp_blk.input_register_a0 = "CLOCK0",
//  ygain_mult_dsp_blk.multiplier1_direction = "ADD",
//  ygain_mult_dsp_blk.signed_pipeline_aclr_a = "ACLR3";
//
//
//
//assign  yscaled_mult_res_c                            = ymult_result_r >> (XY_WIDTH-1);


//----------------------------------------------------------------------------------------------------------------------
// Registering outputs
//----------------------------------------------------------------------------------------------------------------------
always  @(posedge clk or negedge rst_n)
  if (~rst_n)
    begin
      x_out_mod2                                      <= {XY_WIDTH{1'b0}};
      y_out_mod2                                      <= {XY_WIDTH{1'b0}};
      z_out_mod2                                      <= {Z_WIDTH{1'b0}};
      rotnvec_out_mod2                                <= 1'b0;  
    end
  else
    begin
      if (rotnvec_in_r2==comp_mode_r2)
        begin
//          x_out_mod2                                  <= scaled_mult_res_c;

          if (rotnvec_in_r2 == 1'b1)
          begin
//            y_out_mod2                                <= yscaled_mult_res_c;
          end
          else
          begin
            y_out_mod2                                <= y_in_r2;
          end
        end
      else
        begin
          x_out_mod2                                  <= x_in_r2;
          y_out_mod2                                  <= y_in_r2;
        end
      z_out_mod2                                      <= z_in_r2;
      rotnvec_out_mod2                                <= rotnvec_in_r2;  
    end

//----------------------------------------------------------------------------------------------------------------------

assign  x_out                                     = (GAIN_MODEL==2) ? x_out_mod2       : x_out_mod1;
assign  y_out                                     = (GAIN_MODEL==2) ? y_out_mod2       : y_out_mod1;
assign  z_out                                     = (GAIN_MODEL==2) ? z_out_mod2       : z_out_mod1;
assign  rotnvec_mode_out                          = (GAIN_MODEL==2) ? rotnvec_out_mod2 : rotnvec_out_mod1; 

endmodule
