//
// Copyright (C) 1988-2002 Altera Corporation
//
// Any megafunction design, and related net list (encrypted or decrypted),
// support information, device programming or simulation file, and any
// other associated documentation or information provided by Altera or a
// partner under Altera's Megafunction Partnership Program may be used only
// to program PLD devices (but not masked PLD devices) from Altera.  Any
// other use of such megafunction design, net list, support information,
// device programming or simulation file, or any other related
// documentation or information is prohibited for any other purpose,
// including, but not limited to modification, reverse engineering, de-
// compiling, or use with any other silicon devices, unless such use is
// explicitly licensed under a separate agreement with Altera or a
// megafunction partner.  Title to the intellectual property, including
// patents, copyrights, trademarks, trade secrets, or maskworks, embodied
// in any such megafunction design, net list, support information, device
// programming or simulation file, or any other related documentation or
// information provided by Altera or a megafunction partner, remains with
// Altera, the megafunction partner, or their respective licensors.  No
// other licenses, including any licenses needed under any third party's
// intellectual property, are provided herein.
//
//--------------------------------------------------------------------------
// Altera Megafunction Simulation File
//
//--------------------------------------------------------------------------
// Version QuartusII 2.2 SP1 Date: 15th January 2003
//--------------------------------------------------------------------------
//Description
//1. Retrofit the following models based on new coding guideline : altmult_add,
//   alt3pram, altaccumulate, altqpram, altsqrt, altfp_mult, altcdr_tx, 
//   altclklock, altddio_in, altddio_out, altddio_bidir, altshift_taps, scfifo 
//   and dcfifo.
//2. Bug fix for altqpram, altdpram, altlvds, altpll and dcfifo.
//
//--------------------------------------------------------------------------
// Version QuartusII 2.2 Date: 7th November 2002
//--------------------------------------------------------------------------
//
// Version QuartusII 2.1 SP1 Date: 13th September 2002
//
//--------------------------------------------------------------------------
//Description
//1. Enhanced models altlvds_rx, altlvds_tx, altpll and altqpram
//
//--------------------------------------------------------------------------
//
// Version QuartusII 2.1 Date: 16th March 2002
//
//--------------------------------------------------------------------------
//Description
//1. Added new megafunction: Floating Point Multiplier (altfp_mult)
//2. Added Stratix GX DPA Feature Support for altlvds_rx
//3. Added support Stratix GX and Cyclone family
//
//--------------------------------------------------------------------------
//
// Version QuartusII 2.0 Date: 18th Jan 2002
//
//--------------------------------------------------------------------------
//Description
//1. Added support for Stratix family
//2. Added new megafunctions:
//        Multiplier-Accumulator (altmult_accum),
//        Multiplier-Adder (altmult_add),
//        Accumulator (altaccumulate),
//        True Dual-port RAM (altsyncram),
//        Shift Register with Taps (altshift_taps),
//        PLL (altpll).
//--------------------------------------------------------------------------

//START_MODULE_NAME----------------------------------------------------
//
// Module Name     :  altcam
//
// Description     :  Content-addressable memory (CAM) Megafunction. The
// data contained in a CAM is a set of patterns that can be searched in a
// single-clock cycle. The altcam megafunction allows each stored pattern
// bit to be specified as a binary "1" bit, binary "0" bit, or a don't care bit.
// Comparing a stored pattern bit that is specified as don't care with its
// corresponding input pattern bit will always result in a match. 
//
// Limitation      :  Input patterns cannot contain don't care bits.
//
// Results expected:  If the input pattern given to the CAM matches one
// of the patterns stored in the CAM, the address of the matching stored
// pattern is generated.
//
//END_MODULE_NAME----------------------------------------------------

`timescale 1 ps / 1 ps


module altcam (pattern, wrx, wrxused, wrdelete, wraddress, wren,
               inclock, inclocken, inaclr, outclock,
               outclocken, outaclr, mstart, mnext, maddress, mbits, mfound, mcount,
               rdbusy, wrbusy);

    parameter width = 1;
    parameter widthad = 1;
    parameter numwords = 1;
    parameter lpm_file = "UNUSED";
    parameter lpm_filex = "UNUSED";
    parameter match_mode = "MULTIPLE";
    parameter output_reg = "UNREGISTERED";
    parameter output_aclr = "OFF";
    parameter pattern_reg = "INCLOCK";
    parameter pattern_aclr = "ON";
    parameter wraddress_aclr = "ON";
    parameter wrx_reg = "UNUSED";
    parameter wrx_aclr = "UNUSED";
    parameter wrcontrol_aclr = "OFF";
    parameter use_eab = "ON";
    parameter lpm_type = "altcam";

    // Input ports
    input [width-1 : 0] pattern;    // Required port
    input [width-1 : 0] wrx;
    input wrxused;
    input wrdelete;
    input [widthad-1 : 0] wraddress;
    input wren;
    input inclock;  // Required port
    input inclocken;
    input inaclr;
    input outclock;
    input outclocken;
    input outaclr;
    input mstart;
    input mnext;

    // Output ports
    output [widthad-1 : 0] maddress;
    output [numwords-1 : 0] mbits;
    output mfound;
    output [widthad-1 : 0] mcount;
    output rdbusy;
    output wrbusy;

    // Nets
    tri1 wrxused_pullup;
    tri1 inclocken_pullup;
    tri1 outclocken_pullup;
    tri0 wrdelete_pulldown;
    wire [width-1 : 0] pattern_int;
    wire [width-1 : 0] wrx_int;
    wire wrxused_int;
    wire outclock_int;
    wire outaclr_int;
    wire rdbusy_delayed;
    wire wren_rgd_mux;
    wire mstart_rgd1_mux;
    wire mstart_rgd2_mux;

    // Registers
    reg [width-1 : 0] pattern_rgd;
    reg [width-1 : 0] wrx_rgd;
    reg wrxused_rgd;
    reg [widthad-1 : 0] wraddress_rgd;
    reg wren_rgd;
    reg wrdelete_rgd;
    reg [widthad-1 : 0] maddress_rgd;
    reg [widthad-1 : 0] maddress_int;
    reg [numwords-1 : 0] mbits_rgd;
    reg [numwords-1 : 0] mbits_int;
    reg mfound_rgd;
    reg mfound_int;
    reg [widthad-1 : 0] mcount_rgd;
    reg [widthad-1 : 0] mcount_int;
    reg wrbusy_int;
    reg rdbusy_int;

    // CAM registers
    reg [width-1 : 0] cam_array [numwords-1 : 0];
    reg [width-1 : 0] x_array [numwords-1 : 0];

    // Read control registers
    reg first_read_clock;
    reg get_first_match;
    reg get_next_match;
    reg mstart_rgd1;
    reg mstart_rgd2;
    reg first_read_in_write;

    // Write control registers
    reg write_start;
    reg write_start_rgd;
    reg write_start_1;
    reg write_incomplete;
    reg write0;
    reg write1;
    reg writex;
    reg write0_done;
    reg write1_done;
    reg writex_done;

    // Variables
    reg [8*256:1] cam_initf;
    reg [8*256:1] cam_initx;
    reg [width-1 : 0] word_0;
    reg [width-1 : 0] word_1;
    reg [widthad-1 : 0] address_0;
    reg [widthad-1 : 0] address_1;
    reg [numwords-1 : 0] numwords_0;
    integer count;
    integer index;
    integer i, j, addr;
    integer next_search;
    reg restart_read;
    reg reset_read;
    reg mstart_used;
    reg [width-1:0] ipattern; 
    reg [widthad-1:0] iwraddress;
    reg [width-1:0] iwrx; 
    reg iwren;
    reg iwrxused;
    reg [numwords-1 : 0] mbits_tmp;

    function read_cam_array;
    input [widthad-1 : 0] i;
    input [width-1 : 0] j;
        begin: READ_CAM
            reg [width-1 : 0] tmp;
            tmp = cam_array[i];
            read_cam_array = tmp[j];
        end // end READ_CAM
    endfunction // end of read_cam_array

    task write_cam_array;
    input [widthad-1 : 0] i;
    input [width-1 : 0] j;
    input value;
        begin: WRITE_CAM
            reg [width-1 : 0] tmp;
            tmp = cam_array[i];
            tmp[j] = value;
            cam_array[i] = tmp;
        end // end of WRITE_CAM
    endtask // end of write_cam_array

    function read_x_array;
    input [widthad-1 : 0] i;
    input [width-1 : 0] j;
        begin: READ_X
            reg [width-1 : 0] tmp;
            tmp = x_array[i];
            read_x_array = tmp[j];
        end // end of READ_X
    endfunction // end of read_x_array

    task write_x_array;
    input [widthad-1 : 0] i;
    input [width-1 : 0] j;
    input value;
        begin: WRITE_X
            reg [width-1 : 0] tmp;
            tmp = x_array[i];
            tmp[j] = value;
            x_array[i] = tmp;
        end // end of WRITE_X
    endtask // end of write_x_array

    initial
    begin
        for (i=0; i<width; i=i+1)
            word_1[i] = 1'b1;
        for (i=0; i<width; i=i+1)
            word_0[i] = 1'b0;
        for (i=0; i<widthad; i=i+1)
        begin
            address_0[i] = 1'b0;
            address_1[i] = 1'b1;
        end
        for (i=0; i<numwords; i=i+1)
            numwords_0[i] = 1'b0;

        mbits_int = numwords_0;
        mbits_rgd = numwords_0;
        mfound_int = 1'b0;
        mfound_rgd = 1'b0;
        mcount_int = address_0;
        mcount_rgd = address_0;
        maddress_rgd = address_0;
        pattern_rgd = word_0;
        wrx_rgd = word_0;
        wrxused_rgd = 1'b0;
        first_read_clock = 1'b0;
        get_first_match = 1'b0;
        write_start = 1'b0;
        write_start_1 = 1'b0;
        write0 = 1'b1;
        write1 = 1'b0;
        writex = 1'b0;
        next_search = 0;
        restart_read = 1'b0;
        reset_read = 1'b1;

        //
        // word_1[] and word_0[] have to be initialized before
        // using it in the code below.
        //
        if (lpm_file == "UNUSED")
            // no memory initialization file
            // Initialize cam to never match.
            for (i=0; i<numwords; i=i+1)
            begin
                cam_array[i] = word_1;
                x_array[i] = word_1;
            end 
        else if (lpm_filex == "UNUSED")
        begin
            // only lpm_file is used, lpm_filex is not used
            // read in the lpm_file and allow matching all bits
`ifdef NO_PLI
            $readmemh(lpm_file, cam_array);
`else
            $convert_hex2ver(lpm_file, width, cam_initf);
            $readmemh(cam_initf, cam_array);
`endif
            for (i = 0; i < numwords; i=i+1)
            x_array[i] = word_0;
        end
        else
        begin
            // both lpm_file and lpm_filex are used.
            // Initialize cam using both files.
`ifdef NO_PLI
            $readmemh(lpm_file, cam_array);
`else
            $convert_hex2ver(lpm_file, width, cam_initf);
            $readmemh(cam_initf, cam_array);
`endif
`ifdef NO_PLI
            $readmemh(lpm_filex, x_array);
`else
            $convert_hex2ver(lpm_filex, width, cam_initx);
            $readmemh(cam_initx, x_array);
`endif
        end 

        if (match_mode != "SINGLE")
        begin
            maddress_int = address_1;
        end
        else
        begin
            maddress_int = address_0;
        end
    end 

    always @ (wren_rgd_mux)
    begin
        if ((wren_rgd_mux == 1'b0) && (write_incomplete == 1'b1)) 
            $display ("Insufficient write cycle time, write maybe invalid! ");
    end

    always @ (pattern_int)
    begin
        if (write_incomplete == 1'b1)
            $display( "Insufficient pattern hold time, write maybe invalid! ");
    end

    always @ (wraddress_rgd)
    begin
        if (write_incomplete == 1'b1)
            $display( "Insufficient address hold time, write maybe invalid! ");
    end

    always @ (wrdelete_rgd)
    begin
        if ((wrdelete_rgd == 1'b0) && (write_incomplete == 1'b1))
            $display( "Insufficient delete cycle time, delete failed! ");
    end

    always @ (wrdelete_rgd)
    begin
        if ((wrdelete_rgd == 1'b1) && (write_incomplete == 1'b1))
            $display( "Insufficient write cycle time, write maybe invalid! ");
    end

    always @ (wrxused_int)
    begin
        if ((write_incomplete == 1'b1) && (wrdelete_rgd == 1'b0))
            $display( "wrxused reg changed during write! ");
    end

    always @ (mstart_rgd1_mux)
    begin
        if ((write_incomplete == 1'b1) && (mstart_rgd1_mux == 1'b1))
            $display( "Incorrect read attempt during write! ");
    end

    always @ (pattern_int)
    begin
        if (rdbusy_delayed == 1'b1)
            $display( "Insufficient read time, read failed! ");
        else if ((rdbusy_delayed == 1'b0) && (mnext == 1'b1))
            $display( "Illegal pattern change during read, read failed! ");
    end 

    always @ (mstart)
    begin
        if (mstart_used === 1'bx)
        begin
            if (mstart !== 1'bx)
            begin
                // 1st toggle of mstart
                mstart_used = 1'b1;
            end
            else
            begin
                mstart_used = 1'b0;
            end
            get_next_match = 1'b0;
        end
    end

    // Start: Async clear inclock registers
    always @ (posedge inaclr)
    begin
        if (inaclr == 1'b1)
        begin
            if (mstart_used == 1'b1)
            begin
                reset_read = 1'b1;
            end
            first_read_clock <= 1'b0;
            get_first_match <= 1'b0;
            if (pattern_aclr == "ON")
            begin
                pattern_rgd <= word_0;
            end
            if (wrx_aclr == "ON")
            begin
                wrx_rgd <= word_0;
                wrxused_rgd <= 1'b0;
            end
            if (wraddress_aclr == "ON")
            begin
                wraddress_rgd <= word_0; 
            end
            if (wrcontrol_aclr == "ON")
            begin
                wren_rgd <= 1'b0;
                write0_done <= 1'b0;
                write1_done <= 1'b0;
                writex_done <= 1'b0;
            end
            if (pattern_aclr == "ON")
            begin
                mbits_int <= numwords_0;
                mcount_int <= word_0;
                mfound_int <= 1'b0;
                if (match_mode == "SINGLE")
                begin
                    maddress_int <= address_0;
                end
                else
                begin
                    maddress_int <= address_1;
                end
            end
            if ((output_reg == "INCLOCK") && (output_aclr == "OFF"))
            begin
                    maddress_rgd <= address_0;
                    mbits_rgd <= numwords_0;
                    mfound_rgd <= 1'b0;
                    mcount_rgd <= address_0;
            end
        end
    end
    // End: Async clear inclock registers

    /////////////////////////////////////////
    // Evaluate ALTCAM reading and writing 
    /////////////////////////////////////////
    // Start: Read and Write to CAM
    always @ (inclock) // read_write
    begin
        ipattern = pattern;
        iwrx = wrx;
        iwraddress = wraddress;
        iwren = wren;
        if ((wrx_reg == "UNUSED") || (wrx_aclr == "UNUSED"))
        begin
            iwrxused = 1'b0;  // must be unconnected
        end
        else
        begin
            iwrxused = wrxused_pullup;
        end
        
        if (inaclr == 1'b1)
        begin
            if (mstart_used == 1'b1)
            begin
                reset_read = 1'b1;
            end
            first_read_clock <= 1'b0;
            get_first_match <= 1'b0;
            if (pattern_aclr == "ON")
            begin
                ipattern = word_0; 
            end
            if (wrx_aclr == "ON")
            begin
                iwrx = word_0; 
                iwrxused = 1'b0;
            end
            if (wraddress_aclr == "ON")
            begin
                iwraddress = word_0; 
            end
            if (wrcontrol_aclr == "ON")
            begin
                iwren = 1'b0; 
            end
            if (pattern_aclr == "ON")
            begin
                mbits_int <= numwords_0;
                mcount_int <= word_0;
                mfound_int <= 1'b0;
                if (match_mode == "SINGLE")
                begin
                    maddress_int <= address_0;
                end
                else
                begin
                    maddress_int <= address_1;
                end
            end
        end

        if (inclocken_pullup == 1'b1)
        begin
          if (inclock == 1'b1)
          begin // positive inclock edge
            pattern_rgd <= ipattern;
            wrx_rgd <= iwrx;
            wrxused_rgd <= iwrxused;
            wraddress_rgd <= iwraddress;
            wren_rgd <= iwren;

            write_start_rgd <= write_start;
            write_incomplete <= wrbusy_int;
            mstart_rgd1 <= mstart;
            mstart_rgd2 <= mstart_rgd1_mux;
            wrdelete_rgd <= wrdelete_pulldown;

            if (iwren == 1'b0)
            begin
                write0_done <= 1'b0;
                write1_done <= 1'b0;
                writex_done <= 1'b0;
                ////////////////////
                // CAM READ MODES //
                ////////////////////
                // If pattern changed || mstart asserted again) begin restart
                // read cycle.
                if (((match_mode == "FAST_MULTIPLE") && (mstart_used == 1'b0) && (reset_read==1'b1)) ||
                    ((mstart == 1'b1) && (mstart_rgd1_mux == 1'b0)) ||
                    ((ipattern != pattern_rgd) && (reset_read==1'b0)))
                begin
                    restart_read = 1'b1;
                    reset_read = 1'b0;
                    get_first_match <= 1'b0;
                end
                else
                begin
                    restart_read = 1'b0;
                end
                /////////////////////////
                // FAST MULTIPLE: READ //
                /////////////////////////
                if (match_mode == "FAST_MULTIPLE")
                begin
                    if ((get_first_match == 1'b1) && (restart_read == 1'b0))
                    begin
                        if (get_next_match == 1'b1)
                        begin // start of next read cycle
                            index = next_search;
                            begin: MADDR_FM0 for (i=index; i<numwords; i=i+1)
                                begin: MWORD_FM0 for (j=0; j<width; j=j+1)
                                    if (((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == ipattern[j])) || 
                                        ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0)))
                                    begin
                                        if (j == width-1)
                                        begin
                                            next_search = i+1;
                                            j = width;
                                            i = numwords;
                                        end
                                    end
                                    else
                                    begin
                                        j = width;
                                    end
                                end // MWORD_FM0
                            end // MADDR_FM0
                            if (index == next_search)
                            begin // no more matches
                                mfound_int <= 1'b0;
                                maddress_int <= address_1;
                            end
                            else
                            begin
                                maddress_int <= (next_search-1);
                            end
                        end
                    end
                    else
                    begin // start of new read cycle
                        count = 0;
                        mbits_tmp = numwords_0;
                        begin: MADDR_FM1 for (i=0; i<numwords; i=i+1)
                            begin: MWORD_FM1 for (j=0; j<width; j=j+1)
                                if (((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == ipattern[j])) ||    // match pattern bit or
                                    ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0)))             // don't care bit
                                begin
                                    if (j == width-1) // last bit of word
                                    begin
                                        if ((count == 0) && (reset_read == 1'b0) && (restart_read == 1'b1))
                                        begin
                                            mfound_int <= 1'b1;
                                            maddress_int <= i;
                                            get_first_match <= 1'b1;
                                            next_search = i+1;
                                        end
                                        mbits_tmp[i] = 1'b1;    // set the match word
                                        count = count + 1;      // count the matched word
                                    end
                                end
                                else // Never match bit
                                begin
                                    j = width;
                                end
                            end // MWORD_FM1
                        end // MADDR_FM1
                        mcount_int <= count;
                        mbits_int <= mbits_tmp;
                        if ((count == 0) || (reset_read == 1'b1))
                        begin // no matches
                            mfound_int <= 1'b0;
                            maddress_int <= address_1;
                        end
                    end // end of initial read cycle
                end // end of FAST MULTIPLE

                ////////////////////
                // MULTIPLE: READ //
                ////////////////////
                if (match_mode == "MULTIPLE")
                begin
                    if ((get_first_match == 1'b1) && (restart_read == 1'b0))
                    begin
                        if (get_next_match == 1'b1)
                        begin // start of next read cycle
                            index = next_search; 
                            begin: MADDR_MM0 for (i=index; i<numwords; i=i+1)
                                begin: MWORD_MM0 for (j=0; j<width; j=j+1)
                                    if (((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == ipattern[j])) || 
                                        ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0)))
                                    begin
                                        if (j == width-1)
                                        begin
                                            next_search = i+1;
                                            j = width;
                                            i = numwords;
                                        end
                                    end
                                    else
                                    begin
                                        j = width;
                                    end
                                end // MWORD_MM0
                            end // MADDR_MM0
                            if (index == next_search)
                            begin
                                mfound_int <= 1'b0;
                                maddress_int <= address_1;
                            end
                            else
                            begin
                                maddress_int <= (next_search-1);
                            end
                        end
                    end
                    else
                    begin // start of 1st match 
                        count = 0;
                        if (reset_read==1'b0)
                        begin // Not in reset state
                            if (first_read_clock == 1'b0)
                            begin
                                // 1st cycle: match with even && write to even
                                first_read_clock <= 1'b1;
                                maddress_int <= address_1;
                                mfound_int <= 1'b0;
                                mbits_tmp = mbits_int;
                                begin: MADDR_MM1 for (i=0; i<numwords; i=i+1)
                                    if ( (i % 2)==0 )
                                    begin
                                        if (mbits_int[i] == 1'b1)
                                        begin
                                        count = count + 1;
                                        end
                                        begin: MWORD_MM1 for (j=0; j<width; j=j+1)
                                            if (((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == ipattern[j])) || 
                                                ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0)))
                                            begin
                                                if (j == width-1)
                                                begin
                                                    mbits_tmp[i+1] = 1'b1;
                                                    count = count + 1;
                                                end
                                            end
                                            else
                                            begin
                                                mbits_tmp[i+1] = 1'b0;
                                                j = width;
                                            end
                                        end // MWORD_MM1
                                    end
                                end // MADDR_MM1
                            end
                            else
                            begin // 2nd read cycle
                                // 2nd cycle: do match 
                                first_read_clock <= 1'b0;
                                mbits_tmp = numwords_0;
                                begin: MADDR_MM2 for (i=0; i<numwords; i=i+1)
                                    begin: MWORD_MM2 for (j=0; j<width; j=j+1)
                                        if (((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == ipattern[j])) || 
                                            ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0)))
                                        begin
                                            if (j == width-1)
                                            begin
                                                if (count == 0)
                                                begin
                                                    next_search = i+1;
                                                end
                                                mbits_tmp[i] = 1'b1;
                                                count = count + 1;
                                            end
                                        end
                                        else
                                        begin
                                            j = width;
                                        end
                                    end // MWORD_MM2
                                end // MADDR_MM2
                                if (count == 0)
                                begin // no matches
                                    maddress_int <= address_1;
                                    mfound_int <= 1'b0;
                                end
                                else
                                begin
                                    get_first_match <= 1'b1;
                                    mfound_int <= 1'b1;
                                    maddress_int <= (next_search-1);
                                end
                            end
                        end
                        else
                        begin // In reset state
                           // Match with even but write to odd
                            maddress_int <= address_1;
                            mfound_int <= 1'b0;
                            mbits_tmp = numwords_0;
                            begin: MADDR_MM3 for (i=0; i<numwords; i=i+1)
                                if ( (i % 2)==0 )
                                begin
                                    begin: MWORD_MM3 for (j=0; j<width; j=j+1)
                                        if (((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == ipattern[j])) || 
                                            ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0)))
                                        begin
                                            if (j == width-1)
                                            begin
                                                mbits_tmp[i+1] = 1'b1;
                                                count = count + 1;
                                            end
                                        end
                                        else
                                        begin
                                            j = width;
                                        end
                                    end // MWORD_MM3
                                end
                            end // MADDR_MM3
                        end // end of reset state
                        mcount_int <= count;
                        mbits_int <= mbits_tmp;
                    end // end of initial read cycle
                end // end of MULTIPLE

                //////////////////
                // SINGLE: READ //
                //////////////////
                if (match_mode == "SINGLE")
                begin
                    mbits_tmp = numwords_0;
                    index = 0;
                    count = 0;
                    begin: MADDR_SM0 for (i=0; i<numwords; i=i+1)
                        begin: MWORD_SM0 for (j=0; j<width; j=j+1)
                               if (((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == ipattern[j])) || 
                                   ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0)))
                               begin
                                   if (j == width-1)
                                   begin
                                       mbits_tmp[i] = 1'b1;
                                       index = i;
                                       count = 1;
                                       j = width;
                                       i = numwords;
                                    end
                               end
                               else
                               begin
                                    j = width;
                                end
                        end // MWORD_SM0
                    end // MADDR_SM0
                    mcount_int <= count;
                    mbits_int <= mbits_tmp;
                    if (count == 0)
                    begin
                        maddress_int <= address_0;
                        mfound_int <= 1'b0;
                    end
                    else
                    begin
                        mfound_int <= 1'b1;
                        maddress_int <= index;
                    end
                end // end of SINGLE
            end
            else
            begin // if wren == 1'b1 
                //////////////////////
                // READ AFTER WRITE //
                //////////////////////
                // Writing to CAM so reset read cycle.
                get_first_match <= 1'b0;
                first_read_clock <= 1'b0;
                restart_read = 1'b0;
                if (mstart_used == 1'b1)
                begin
                    reset_read = 1'b1;
                end
                /////////////////////////////////////
                // FAST MULTIPLE: READ AFTER WRITE //
                /////////////////////////////////////
                if (match_mode == "FAST_MULTIPLE")
                begin
                    mfound_int <= 1'b0;
                    maddress_int <= address_1;
                    count = 0;
                    mbits_tmp = numwords_0;
                    if ((writex == 1'b1) && (iwrxused == 1'b1))
                    begin
                        begin: WADDR_FM0 for (i=0; i<numwords; i=i+1)
                            begin: WWORD_FM0 for (j=0; j<width; j=j+1)
                                if (((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == (ipattern[j] ^ iwrx[j]))) || 
                                    ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0)))
                                begin
                                    if (j == width-1)
                                    begin
                                        mbits_tmp[i] = 1'b1;
                                        count = count + 1;
                                    end
                                end
                                else
                                begin
                                    j = width;
                                end
                            end // WWORD_FM0
                        end // WADDR_FM0
                    end
                    else
                    begin
                        begin: WADDR_FM1 for (i=0; i<numwords; i=i+1)
                            begin: WWORD_FM1 for (j=0; j<width; j=j+1)
                                if (((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == ipattern[j])) || 
                                    ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0)))
                                begin
                                    if (j == width-1)
                                    begin
                                        mbits_tmp[i] = 1'b1;
                                        count = count + 1;
                                    end
                                end
                                else
                                begin
                                    j = width;
                                end
                            end // WWORD_FM1
                        end // WADDR_FM1
                    end 
                    mcount_int <= count;
                    mbits_int <= mbits_tmp;
                end // end of FAST MULTIPLE

                ////////////////////////////////
                // MULTIPLE: READ AFTER WRITE //
                ////////////////////////////////
                // THIS IMPLEMENTATION IS INACCURATE
                if ((match_mode == "MULTIPLE"))
                begin
                    mfound_int <= 1'b0;
                    maddress_int <= address_1;
                    mbits_tmp = numwords_0;
                    if ((writex == 1'b1) && (iwrxused == 1'b1))
                    begin
                        mcount_int <= 0;
                    end
                    else
                    begin
                        if (first_read_in_write == 1'b0)
                        begin
                            // Read even addresses but they appear on the odd locations
                            // of mbits.
                            count = 0;
                            begin: WADDR_MM0 for (i=0; i<numwords; i=i+1)
                                if ((i % 2) == 0)
                                begin
                                    if (mbits_int[i] == 1'b1)
                                    begin // counting previous even address matches
                                        count = count + 1;
                                    end
                                    begin: WWORD_MM0 for (j=0; j<width; j=j+1)
                                        if (((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == ipattern[j])) || 
                                            ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0)))
                                        begin
                                            if (j == width-1)
                                            begin
                                                mbits_tmp[i+1] = 1'b1;
                                                count = count + 1;
                                            end
                                        end
                                        else
                                        begin
                                            j = width;
                                        end
                                    end // WWORD_MM0
                                end
                            end // WADDR_MM0
                        end
                        else
                        begin
                            //  Read odd addresses. 
                            count = 0;
                            begin: WADDR_MM1 for (i=numwords-1; i>=0; i=i-1)
                                if ((i % 2) == 1 )
                                begin
                                    mbits_tmp[i-1] = mbits_tmp[i];
                                end
                                else
                                begin
                                    begin: WWORD_MM1 for (j=0; j<width; j=j+1)
                                        if (((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == ipattern[j])) || 
                                            ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0)))
                                        begin
                                            if (j == width-1)
                                            begin
                                                mbits_tmp[i] = 1'b1;
                                                count = count + 1;
                                            end
                                        end
                                        else
                                        begin
                                            j = width;
                                        end
                                    end // WWORD_MM1
                                end
                            end // WADDR_MM1
                        end
                        mcount_int <= count;
                        mbits_int <= mbits_tmp;
                    end
                end // end of MULTIPLE

                //////////////////////////////
                // SINGLE: READ AFTER WRITE //
                //////////////////////////////
                if (match_mode == "SINGLE")
                begin
                    mbits_tmp = numwords_0;
                    index = 0;
                    count = 0;
                    if ((writex == 1'b1) && (iwrxused == 1'b1))
                    begin
                        begin: WADDR_SM0 for (i=0; i<numwords; i=i+1)
                            begin: WWORD_SM0 for (j=0; j<width; j=j+1)
                                if (((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == (ipattern[j] ^ iwrx[j]))) || 
                                    ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0)))
                                begin
                                    if (j == width-1)
                                    begin
                                        mbits_tmp[i] = 1'b1;
                                        index = i;
                                        count = 1;
                                        j = width;
                                        i = numwords;
                                    end
                                end
                                else
                                begin
                                    j = width;
                                end
                            end // WWORD_SM0
                        end // WADDR_SM0
                    end
                    else
                    begin
                        begin: WADDR_SM1 for (i=0; i<numwords; i=i+1)
                            begin: WWORD_SM1 for (j=0; j<width; j=j+1)
                                if (((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == ipattern[j])) || 
                                    ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0)))
                                begin
                                    if (j == width-1)
                                    begin
                                        mbits_tmp[i] = 1'b1;
                                        index = i;
                                        count = 1;
                                        j = width;
                                        i = numwords;
                                    end
                                end
                                else
                                begin
                                    j = width;
                                end
                            end // WWORD_SM1
                        end // WADDR_SM1
                    end
                    mcount_int <= count;
                    mbits_int <= mbits_tmp;
                    if (count == 0)
                    begin
                        mfound_int <= 1'b0;
                        maddress_int <= address_0;
                    end
                    else
                    begin
                        mfound_int <= 1'b1;
                        maddress_int <= index;
                    end
                end // end of SINGLE
            end // end of wren == 1'b1
          end // end of inclock == 1'b1
          else
          begin // if (inclock negedge
            // We write to the CAM on the low cycle of inclock 
            // when wren_rgd==1'b1.
            if (pattern_reg == "UNREGISTERED") ipattern  = pattern;
            else ipattern = pattern_rgd;
            if ((wren_rgd_mux==1'b1) && (inclock==1'b0))
            begin
                addr = wraddress_rgd;
                /////////////////////
                // CAM WRITE MODES //
                /////////////////////
                if (wrdelete_rgd == 1'b0)
                begin
                    if ((wrxused_int == 1'b1) && (wrx_reg != "UNUSED") && (wrx_aclr != "UNUSED"))
                    begin
                        /////////////////// 
                        // 3 CYCLE WRITE // 
                        /////////////////// 
                        ///////////////// 
                        // WRITE_ZEROS // 
                        ///////////////// 
                        if (write0 == 1'b1)
                        begin
                            for (i =0; i<width; i=i+1 )
                            begin
                                if (ipattern[i] == 1'b0)
                                begin
                                    // "0" ==> "0"
                                    if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b0))
                                    begin // "0"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b0);
                                    // "1" ==> "X"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b0))
                                    begin // "1"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b1);
                                    // "X" ==> "X"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b1))
                                    begin // "X"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b1);
                                    // "U" ==> "0"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b1))
                                    begin // "U"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b0);
                                    end
                                end else if (ipattern[i] == 1'b1)
                                begin
                                    // "0" ==> "X"
                                    if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b0))
                                    begin // "0"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b1);
                                    // "1" ==> "1"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b0))
                                    begin // "1"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b0);
                                    // "X" ==> "X"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b1))
                                    begin // "X"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b1);
                                    // "U" ==> "1"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b1))
                                    begin // "U"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b0);
                                    end
                                end
                            end
                            write0_done <= 1'b1;
                            write1_done <= 1'b0;
                            writex_done <= 1'b0;
                        end
                        ////////////////
                        // WRITE_ONES //
                        ////////////////
                        if (write1 == 1'b1)
                        begin
                        for (i =0; i<width; i=i+1)
                            begin
                            if (ipattern[i] == 1'b0)
                                begin
                                    // "0" ==> "0"
                                    if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b0))
                                    begin // "0"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b0);
                                    // "1" ==> "U"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b0))
                                    begin // "1"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b1);
                                    // "X" ==> "0"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b1))
                                    begin // "X"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b0);
                                    // "U" ==> "U"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b1))
                                    begin // "U"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b1);
                                    end
                                end
                            else if (ipattern[i] == 1'b1)
                                begin
                                    // "0" ==> "U"
                                    if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b0))
                                    begin // "0"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b1);
                                    // "1" ==> "1"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b0))
                                    begin // "1"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b0);
                                    // "X" ==> "1"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b1))
                                    begin // "X"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b0);
                                    // "U" ==> "U"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b1))
                                    begin // "U"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b1);
                                    end
                                end
                            end
                        write0_done <= 1'b0;
                        write1_done <= 1'b1;
                        writex_done <= 1'b0;
                        end
                        /////////////
                        // WRITE_X //
                        /////////////
                        if (writex == 1'b1)
                        begin
                            for (i =0; i<width; i=i+1)
                            begin
                                if ((ipattern[i] ^ wrx_int[i]) == 1'b0)
                                begin
                                    // "0" ==> "0"
                                    if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b0))
                                    begin // "0"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b0);
                                    // "1" ==> "X"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b0))
                                    begin // "1"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b1);
                                    // "X" ==> "X"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b1))
                                    begin // "X"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b1);
                                    // "U" ==> "0"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b1))
                                    begin // "U"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b0);
                                    end
                                end
                                else if ((ipattern[i] ^ wrx_int[i]) == 1'b1)
                                begin
                                    // "0" ==> "X"
                                    if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b0))
                                    begin // "0"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b1);
                                    // "1" ==> "1"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b0))
                                    begin // "1"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b0);
                                    // "X" ==> "X"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b1))
                                    begin // "X"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b1);
                                    // "U" ==> "1"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b1))
                                    begin // "U"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b0);
                                    end
                                end
                            end
                        writex_done <= 1'b1;
                        write0_done <= 1'b0;
                        write1_done <= 1'b0;
                        end
                        if (wrbusy_int == 1'b1)
                        begin
                            write_start_1 <= 1'b1;
                            write_start <= write_start_1;
                        end
                        else
                        begin
                            write_start_1 <= 1'b0;
                            write_start <= 1'b0;
                        end
                    end
                    else
                    begin // 2 Cycle write
                        /////////////////// 
                        // 2 CYCLE WRITE // 
                        /////////////////// 
                        ///////////////// 
                        // WRITE_ZEROS // 
                        ///////////////// 
                        if (write0 == 1'b1)
                        begin
                            for (i =0; i<width; i=i+1)
                            begin
                                if (ipattern[i] == 1'b0)
                                begin
                                    // "0" ==> "0"
                                    if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b0))
                                    begin // "0"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b0);
                                    // "1" ==> "X"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b0))
                                    begin // "1"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b1);
                                    // "X" ==> "X"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b1))
                                    begin // "X"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b1);
                                    // "U" ==> "0"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b1))
                                    begin // "U"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b0);
                                    end
                                end
                                else if (ipattern[i] == 1'b1)
                                begin
                                    // "0" ==> "X"
                                    if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b0))
                                    begin // "0"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b1);
                                    // "1" ==> "1"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b0))
                                    begin // "1"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b0);
                                    // "X" ==> "X"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b1))
                                    begin // "X"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b1);
                                    // "U" ==> "1"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b1))
                                    begin // "U"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b0);
                                    end
                                end
                            end
                        write0_done <= 1'b1;
                        write1_done <= 1'b0;
                        writex_done <= 1'b0;
                        end
                        ////////////////
                        // WRITE_ONES //
                        ////////////////
                        if (write1 == 1'b1)
                        begin
                            for (i =0; i<width; i=i+1)
                            begin
                                if (ipattern[i] == 1'b0)
                                begin
                                    // "0" ==> "0"
                                    if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b0))
                                    begin // "0"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b0);
                                    // "1" ==> "U"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b0))
                                    begin // "1"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b1);
                                    // "X" ==> "0"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b1))
                                    begin // "X"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b0);
                                    // "U" ==> "U"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b1))
                                    begin // "U"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b1);
                                    end
                                end
                                else if (ipattern[i] == 1'b1)
                                begin
                                    // "0" ==> "U"
                                    if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b0))
                                    begin // "0"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b1);
                                    // "1" ==> "1"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b0))
                                    begin // "1"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b0);
                                    // "X" ==> "1"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b1))
                                    begin // "X"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b0);
                                    // "U" ==> "U"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b1))
                                    begin // "U"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b1);
                                    end
                                end
                            end
                        write0_done <= 1'b0;
                        write1_done <= 1'b1;
                        writex_done <= 1'b0;
                        end

                        if (wrbusy_int == 1'b1)
                        begin
                            write_start <= 1'b1;
                        end
                        else
                        begin
                            write_start <= 1'b0;
                        end
                    end // wrxused_int
                end
                else
                begin // if (wrdelete == 1'b1) begin
                        //////////////////// 
                        // 2 CYCLE DELETE // 
                        //////////////////// 
                        // Delete is a 2-cycle write
                        ////////////////
                        // WRITE_ONES //
                        ////////////////
                        if (write0 == 1'b1)
                        begin
                            for (i =0; i<width; i=i+1)
                            begin
                                write_cam_array(addr,i,1'b1);
                            end 
                            write0_done <= 1'b1;
                            write1_done <= 1'b0;
                            writex_done <= 1'b0;
                        end
                        /////////////
                        // WRITE_X //
                        /////////////
                        if (write1 == 1'b1)
                        begin
                            for (i =0; i<width; i=i+1)
                            begin
                                write_x_array(addr,i,1'b1);
                            end 
                            write1_done <= 1'b1;
                            write0_done <= 1'b0;
                            writex_done <= 1'b0;
                        end
                        if (wrbusy_int == 1'b1)
                        begin
                            write_start <= 1'b1;
                        end
                        else
                        begin
                            write_start <= 1'b0;
                        end
                    end // wrdelete

                //////////////////////////////////////
                // FAST MULTIPLE: READ DURING WRITE //
                //////////////////////////////////////
                // Now we need to update mbits, mcount during the write.
                if (match_mode == "FAST_MULTIPLE")
                begin
                    mfound_int <= 1'b0;
                    maddress_int <= address_1;
                    count = 0;
                    mbits_tmp = numwords_0;
                    if ((writex == 1'b1) && (wrxused_int == 1'b1))
                    begin
                        begin: WADDR_FM2 for (i=0; i<numwords; i=i+1)
                            begin: WWORD_FM2 for (j=0; j<width; j=j+1)
                                if (((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == (ipattern[j] ^ wrx_int[j]))) || 
                                    ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0)))
                                begin
                                    if (j == width-1)
                                    begin
                                        if ((count == 0) && (mstart_used == 1'b0))
                                        begin
                                            mfound_int <= 1'b1;
                                            maddress_int <= i;
                                        end
                                        mbits_tmp[i] = 1'b1;
                                        count = count + 1;
                                    end
                                end
                                else
                                begin
                                    j = width;
                                end
                            end // WWORD_FM2
                        end // WADDR_FM2
                    end
                    else
                    begin
                        begin: WADDR_FM3 for (i=0; i<numwords; i=i+1)
                            begin: WWORD_FM3 for (j=0; j<width; j=j+1)
                                if (((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == ipattern[j])) || 
                                    ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0)))
                                begin
                                    if (j == width-1)
                                    begin
                                        if ((count == 0) && (mstart_used == 1'b0))
                                        begin
                                            mfound_int <= 1'b1;
                                            maddress_int <= i;
                                        end
                                        mbits_tmp[i] = 1'b1;
                                        count = count + 1;
                                    end
                                end
                                else
                                begin
                                    j = width;
                                end
                            end // WWORD_FM3
                        end // WADDR_FM3
                    end
                    mcount_int <= count;
                    mbits_int <= mbits_tmp;
                end // end of FAST MULTIPLE

                /////////////////////////////////
                // MULTIPLE: READ DURING WRITE //
                /////////////////////////////////
                // THIS IMPLEMENTATION IS INACCURATE
                if ((match_mode == "MULTIPLE"))
                begin
                    mfound_int <= 1'b0;
                    maddress_int <= address_1;
                    mbits_tmp = numwords_0;
                    if ((writex == 1'b1) && (iwrxused == 1'b1))
                    begin
                        mcount_int <= 0;
                        first_read_in_write <= 1'b0;
                    end
                    else
                    begin
                        if (first_read_in_write == 1'b0)
                        begin
                            first_read_in_write <= 1'b1;
                            // Read even addresses but they appear on the odd locations
                            // of mbits.
                            count = 0;
                            begin: WADDR_MM2 for (i=0; i<numwords; i=i+1)
                                if ((i % 2) == 0)
                                begin
                                    if (mbits_int[i] == 1'b1)
                                    begin // counting previous even address matches
                                        count = count + 1;
                                    end

                                    begin: WWORD_MM2 for (j=0; j<width; j=j+1)
                                        if (((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == ipattern[j])) || 
                                            ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0)))
                                        begin
                                            if (j == width-1)
                                            begin
                                                mbits_tmp[i+1] = 1'b1;
                                                count = count + 1;
                                            end
                                        end
                                        else
                                        begin
                                            j = width;
                                        end
                                    end // WWORD_MM2
                                end
                            end // WADDR_MM2
                        end
                        else
                        begin
                            first_read_in_write <= 1'b0;
                            //  Read odd addresses. 
                            count = 0;
                            begin: WADDR_MM3 for (i=numwords-1; i>=0; i=i-1)
                                if ((i % 2) == 1 )
                                begin
                                    mbits_tmp[i-1] = mbits_tmp[i];
                                end
                                else
                                begin
                                    begin: WWORD_MM3 for (j=0; j<width; j=j+1)
                                        if (((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == ipattern[j])) || 
                                            ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0)))
                                        begin
                                            if (j == width-1)
                                            begin
                                                mbits_tmp[i] = 1'b1;
                                                count = count + 1;
                                            end
                                        end
                                        else
                                        begin
                                            j = width;
                                        end
                                    end // WWORD_MM3
                                end
                            end // WADDR_MM3
                        end
                        mcount_int <= count;
                        mbits_int <= mbits_tmp;
                    end
                end // end of MULTIPLE

                ///////////////////////////////
                // SINGLE: READ DURING WRITE //
                ///////////////////////////////
                if (match_mode == "SINGLE")
                begin
                    mbits_tmp = numwords_0;
                    index = 0;
                    count = 0;
                    if ((writex == 1'b1) && (wrxused_int == 1'b1))
                    begin
                        begin: WADDR_SM2 for (i=0; i<numwords; i=i+1)
                            begin: WWORD_SM2 for (j=0; j<width; j=j+1)
                                if (((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == (ipattern[j] ^ wrx_int[j]))) || 
                                    ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0)))
                                begin
                                    if (j == width-1)
                                    begin
                                        mbits_tmp[i] = 1'b1;
                                        index = i;
                                        count = 1;
                                        j = width;
                                        i = numwords;
                                    end
                                end
                                else
                                begin
                                    j = width;
                                end
                            end // WWORD_SM2
                        end // WADDR_SM2
                    end
                    else
                    begin
                        begin: WADDR_SM3 for (i=0; i<numwords; i=i+1)
                            begin: WWORD_SM3 for (j=0; j<width; j=j+1)
                                if (((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == ipattern[j])) || 
                                    ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0)))
                                begin
                                    if (j == width-1)
                                    begin
                                        mbits_tmp[i] = 1'b1;
                                        index = i;
                                        count = 1;
                                        j = width;
                                        i = numwords;
                                    end
                                end
                                else
                                begin
                                    j = width;
                                end
                            end // WWORD_SM3
                        end // WADDR_SM3
                    end
                    mcount_int <= count;
                    mbits_int <= mbits_tmp;
                    if (count == 0)
                    begin
                        mfound_int <= 1'b0;
                        maddress_int <= address_0;
                    end
                    else
                    begin
                        mfound_int <= 1'b1;
                        maddress_int <= index;
                    end
                end // end of SINGLE
            end
            else
            begin // End of Write
                if (write_start == 1'b1)
                begin
                    // this should be a second write cycle but due to write violation,
                    // we have to reset write_start
                    write_start <= 1'b0;
                end
            end // End of Write
          end // end of inclock edges
        end  // end of inclock event
    end // read_write;
    // End: Read and Write to CAM

    // Start: Change in pattern 
    always @ (pattern) 
    begin
        // Only updating mbits, mcount, mfound && maddress if
        // the pattern input in unregistered, wren_rgd==1'b0 && the pattern
        // pattern changes.
        if (pattern_reg=="UNREGISTERED")
        begin
            if (wren_rgd_mux==1'b0)
            begin
            ////////////////////////////////////////
            // FAST MULTIPLE: READ ON NEW PATTERN //
            ////////////////////////////////////////
            if (match_mode == "FAST_MULTIPLE")
            begin
                count = 0;
                mbits_tmp = numwords_0;
                begin: MADDR_FM2 for (i=0; i<numwords; i=i+1)
                    begin: MWORD_FM2 for (j=0; j<width; j=j+1)
                        if (((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == pattern[j])) || 
                            ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0)))
                        begin
                            if (j == width-1)
                            begin
                                if ((count == 0) && (reset_read == 1'b0))
                                begin
                                    mfound_int <= 1'b1;
                                    maddress_int <= i;
                                end
                                mbits_tmp[i] = 1'b1;
                                count = count + 1;
                            end
                        end
                        else
                        begin
                            j = width;
                        end
                    end // MWORD_FM2
                end // MADDR_FM2
                mcount_int <= count;
                mbits_int <= mbits_tmp;
                if ((count == 0) || (reset_read == 1'b1))
                begin
                    mfound_int <= 1'b0;
                    maddress_int <= address_1;
                end
            end // end of FAST MULTIPLE

            ///////////////////////////////////
            // MULTIPLE: READ ON NEW PATTERN //
            ///////////////////////////////////
            if (match_mode == "MULTIPLE")
            begin
                count = 0;
                mbits_tmp = mbits_int;
                if (reset_read == 1'b1)
                begin
                    begin: MADDR_MM4 for (i=0; i<numwords; i=i+1)
                        if ( (i % 2)==0 )
                        begin
                            begin: MWORD_MM4 for (j=0; j<width; j=j+1)
                                if ((((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == pattern[j])) || 
                                    ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0))))
                                    begin
                                    if (j == width-1)
                                    begin
                                        mbits_tmp[i+1] = 1'b1;
                                        count = count + 1;
                                    end
                                end
                                else
                                begin
                                    mbits_tmp[i+1] = 1'b0;
                                    j = width;
                                end
                            end // MWORD_MM4
                        end
                    end // MADDR_MM4
                end
                else
                begin
                    // Match odd addresses && write to odd
                    begin: MADDR_MM5 for (i=0; i<numwords; i=i+1)
                        if ( (i % 2)==1 )
                        begin
                            begin: MWORD_MM5 for (j=0; j<width; j=j+1)
                                if ((((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == pattern[j])) || 
                                    ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0))))
                                begin
                                    if (j == width-1)
                                    begin
                                        mbits_tmp[i] = 1'b1;
                                        if (count == 0)
                                        begin
                                            maddress_int <= i;
                                        end
                                        count = count + 1;
                                    end
                                end
                                else
                                begin
                                    mbits_tmp[i] = 1'b0;
                                    j = width;
                                end
                            end // MWORD_MM5
                        end
                        else
                        begin
                            if (mbits_tmp[i] == 1'b1)
                            begin
                                if (count == 0)
                                begin
                                    maddress_int <= i;
                                end
                                count = count + 1;
                            end
                        end
                    end // MADDR_MM5
                    if (count > 0)
                    begin
                        mfound_int <= 1'b1;
                    end
                    else
                    begin
                        mfound_int <= 1'b0;
                        maddress_int <= word_1;
                    end
                end
                mcount_int <= count;
                mbits_int <= mbits_tmp;
            end

            /////////////////////////////////
            // SINGLE: READ ON NEW PATTERN //
            /////////////////////////////////
            if (match_mode == "SINGLE")
            begin
                mbits_tmp = numwords_0;
                index = 0;
                count = 0;
                begin: MADDR_SM1 for (i=0; i<numwords; i=i+1)
                    begin: MWORD_SM1 for (j=0; j<width; j=j+1)
                       if ((((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == pattern[j])) || 
                           ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0))))
                       begin
                           if (j == width-1)
                           begin
                               mbits_tmp[i] = 1'b1;
                               count = 1;
                               index = i;
                               j = width;
                               i = numwords;
                           end
                        end
                        else
                        begin
                            j = width;
                        end
                    end // MWORD_SM1
                end // MADDR_SM1
                mcount_int <= count;
                mbits_int <= mbits_tmp;
                if (count == 0)
                begin
                    maddress_int <= address_0;
                    mfound_int <= 1'b0;
                end
                else
                begin
                    mfound_int <= 1'b1;
                    maddress_int <= index;
                end
            end // end of SINGLE
        end // end of read on pattern change
        else
        begin // write on pattern change
            // We write to the CAM on the low cycle of inclock 
            // when wren_rgd==1'b1 and pattern changes.
            if ((wren_rgd_mux==1'b1) && (inclock==1'b0))
            begin
                addr = wraddress_rgd;
                /////////////////////
                // CAM WRITE MODES //
                /////////////////////
                if (wrdelete_rgd == 1'b0)
                begin
                    if ((wrxused_int == 1'b1) && (wrx_reg != "UNUSED") && (wrx_aclr != "UNUSED"))
                    begin
                        /////////////////// 
                        // 3 CYCLE WRITE // 
                        /////////////////// 
                        ///////////////// 
                        // WRITE_ZEROS // 
                        ///////////////// 
                        if (write0_done == 1'b1)
                        begin
                            for (i =0; i<width; i=i+1 )
                            begin
                                if (pattern[i] == 1'b0)
                                begin
                                    // "0" ==> "0"
                                    if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b0))
                                    begin // "0"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b0);
                                    // "1" ==> "X"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b0))
                                    begin // "1"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b1);
                                    // "X" ==> "X"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b1))
                                    begin // "X"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b1);
                                    // "U" ==> "0"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b1))
                                    begin // "U"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b0);
                                    end
                                end
                                else if (pattern[i] == 1'b1)
                                begin
                                    // "0" ==> "X"
                                    if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b0))
                                    begin // "0"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b1);
                                    // "1" ==> "1"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b0))
                                    begin // "1"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b0);
                                    // "X" ==> "X"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b1))
                                    begin // "X"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b1);
                                    // "U" ==> "1"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b1))
                                    begin // "U"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b0);
                                    end
                                end
                            end
                        end
                        ////////////////
                        // WRITE_ONES //
                        ////////////////
                        if (write1_done == 1'b1)
                        begin
                            for (i =0; i<width; i=i+1)
                            begin
                                if (pattern[i] == 1'b0)
                                begin
                                    // "0" ==> "0"
                                    if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b0))
                                    begin // "0"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b0);
                                    // "1" ==> "U"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b0))
                                    begin // "1"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b1);
                                    // "X" ==> "0"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b1))
                                    begin // "X"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b0);
                                    // "U" ==> "U"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b1))
                                    begin // "U"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b1);
                                    end
                                end
                                else if (pattern[i] == 1'b1)
                                begin
                                    // "0" ==> "U"
                                    if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b0))
                                    begin // "0"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b1);
                                    // "1" ==> "1"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b0))
                                    begin // "1"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b0);
                                    // "X" ==> "1"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b1))
                                    begin // "X"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b0);
                                    // "U" ==> "U"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b1))
                                    begin // "U"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b1);
                                    end
                                end
                            end
                        end
                        /////////////
                        // WRITE_X //
                        /////////////
                        if (writex_done == 1'b1)
                        begin
                            for (i =0; i<width; i=i+1)
                            begin
                                if ((pattern[i] ^ wrx_int[i]) == 1'b0)
                                begin
                                    // "0" ==> "0"
                                    if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b0))
                                    begin // "0"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b0);
                                    // "1" ==> "X"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b0))
                                    begin // "1"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b1);
                                    // "X" ==> "X"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b1))
                                    begin // "X"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b1);
                                    // "U" ==> "0"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b1))
                                    begin // "U"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b0);
                                    end
                                end
                                else if ((pattern[i] ^ wrx_int[i]) == 1'b1)
                                begin
                                    // "0" ==> "X"
                                    if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b0))
                                    begin // "0"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b1);
                                    // "1" ==> "1"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b0))
                                    begin // "1"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b0);
                                    // "X" ==> "X"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b1))
                                    begin // "X"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b1);
                                    // "U" ==> "1"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b1))
                                    begin // "U"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b0);
                                    end
                                end
                            end
                        end
                    end
                    else
                    begin // 2 Cycle write
                        /////////////////// 
                        // 2 CYCLE WRITE // 
                        /////////////////// 
                        ///////////////// 
                        // WRITE_ZEROS // 
                        ///////////////// 
                        if (write0_done == 1'b1)
                        begin
                            for (i =0; i<width; i=i+1)
                            begin
                                if (pattern[i] == 1'b0)
                                begin
                                    // "0" ==> "0"
                                    if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b0))
                                    begin // "0"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b0);
                                    // "1" ==> "X"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b0))
                                    begin // "1"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b1);
                                    // "X" ==> "X"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b1))
                                    begin // "X"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b1);
                                    // "U" ==> "0"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b1))
                                    begin // "U"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b0);
                                    end
                                end
                                else if (pattern[i] == 1'b1)
                                begin
                                    // "0" ==> "X"
                                    if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b0))
                                    begin // "0"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b1);
                                    // "1" ==> "1"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b0))
                                    begin // "1"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b0);
                                    // "X" ==> "X"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b1))
                                    begin // "X"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b1);
                                    // "U" ==> "1"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b1))
                                    begin // "U"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b0);
                                    end
                                end
                            end
                        end
                        ////////////////
                        // WRITE_ONES //
                        ////////////////
                        if (write1_done == 1'b1)
                        begin
                            for (i =0; i<width; i=i+1)
                            begin
                                if (pattern[i] == 1'b0)
                                begin
                                    // "0" ==> "0"
                                    if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b0))
                                    begin // "0"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b0);
                                    // "1" ==> "U"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b0))
                                    begin // "1"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b1);
                                    // "X" ==> "0"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b1))
                                    begin // "X"
                                        write_cam_array(addr,i,1'b0);
                                        write_x_array(addr,i,1'b0);
                                    // "U" ==> "U"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b1))
                                    begin // "U"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b1);
                                    end
                                end
                                else if (pattern[i] == 1'b1)
                                begin
                                    // "0" ==> "U"
                                    if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b0))
                                    begin // "0"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b1);
                                    // "1" ==> "1"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b0))
                                    begin // "1"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b0);
                                    // "X" ==> "1"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b0 && read_x_array(addr,i)==1'b1))
                                    begin // "X"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b0);
                                    // "U" ==> "U"
                                    end
                                    else if ((read_cam_array(addr,i)==1'b1 && read_x_array(addr,i)==1'b1))
                                    begin // "U"
                                        write_cam_array(addr,i,1'b1);
                                        write_x_array(addr,i,1'b1);
                                    end
                                end
                            end
                        end
                    end // wrxused_int
                end
                else
                begin // if (wrdelete == 1'b1) begin
                    //////////////////// 
                    // 2 CYCLE DELETE // 
                    //////////////////// 
                    // Delete is a 2-cycle write
                    ////////////////
                    // WRITE_ONES //
                    ////////////////
                    if (write0_done == 1'b1)
                    begin
                        for (i =0; i<width; i=i+1)
                        begin
                            write_cam_array(addr,i,1'b1);
                        end
                    end
                    /////////////
                    // WRITE_X //
                    /////////////
                    if (write1_done == 1'b1)
                    begin
                        for (i =0; i<width; i=i+1)
                        begin
                            write_x_array(addr,i,1'b1);
                        end
                    end
                end // wrdelete

                //////////////////////////////////////
                // FAST MULTIPLE: READ DURING WRITE //
                //////////////////////////////////////
                // Now we need to update mbits, mcount during the write.
                if (match_mode == "FAST_MULTIPLE")
                begin
                    mfound_int <= 1'b0;
                    maddress_int <= address_1;
                    count = 0;
                    mbits_tmp = numwords_0;
                    if ((writex_done == 1'b1) && (wrxused_int == 1'b1))
                    begin
                        begin: WADDR_FM_2 for (i=0; i<numwords; i=i+1)
                            begin: WWORD_FM_2 for (j=0; j<width; j=j+1)
                                if (((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == (pattern[j] ^ wrx_int[j]))) || 
                                    ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0)))
                                begin
                                    if (j == width-1)
                                    begin
                                        if ((count == 0) && (mstart_used == 1'b0))
                                        begin
                                            mfound_int <= 1'b1;
                                            maddress_int <= i;
                                        end
                                        mbits_tmp[i] = 1'b1;
                                        count = count + 1;
                                    end
                                end
                                else
                                begin
                                    j = width;
                                end
                            end // WWORD_FM_2
                        end // WADDR_FM_2
                    end
                    else
                    begin
                        begin: WADDR_FM_3 for (i=0; i<numwords; i=i+1)
                            begin: WWORD_FM_3 for (j=0; j<width; j=j+1)
                                if (((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == pattern[j])) || 
                                    ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0)))
                                begin
                                    if (j == width-1)
                                    begin
                                        if ((count == 0) && (mstart_used == 1'b0))
                                        begin
                                            mfound_int <= 1'b1;
                                            maddress_int <= i;
                                        end
                                        mbits_tmp[i] = 1'b1;
                                        count = count + 1;
                                    end
                                end
                                else
                                begin
                                    j = width;
                                end
                            end // WWORD_FM_3
                        end // WADDR_FM_3
                    end
                    mcount_int <= count;
                    mbits_int <= mbits_tmp;
                end // end of FAST MULTIPLE

                /////////////////////////////////
                // MULTIPLE: READ DURING WRITE //
                /////////////////////////////////
                // THIS IMPLEMENTATION IS INACCURATE
                if ((match_mode == "MULTIPLE"))
                begin
                    mfound_int <= 1'b0;
                    maddress_int <= address_1;
                    mbits_tmp = numwords_0;
                    if ((writex_done == 1'b1) && (iwrxused == 1'b1))
                    begin
                        mcount_int <= 0;
                        first_read_in_write <= 1'b0;
                    end
                    else
                    begin
                        if (first_read_in_write == 1'b0)
                        begin
                            first_read_in_write <= 1'b1;
                            // Read even addresses but they appear on the odd locations
                            // of mbits.
                            count = 0;
                            begin: WADDR_MM_2 for (i=0; i<numwords; i=i+1)
                                if ((i % 2) == 0)
                                begin
                                    if (mbits_int[i] == 1'b1)
                                    begin // counting previous even address matches
                                        count = count + 1;
                                    end
                                    begin: WWORD_MM_2 for (j=0; j<width; j=j+1)
                                        if (((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == pattern[j])) || 
                                            ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0)))
                                        begin
                                            if (j == width-1)
                                            begin
                                                mbits_tmp[i+1] = 1'b1;
                                                count = count + 1;
                                            end
                                        end
                                        else
                                        begin
                                            j = width;
                                        end
                                    end // WWORD_MM_2
                                end
                            end // WADDR_MM_2
                        end
                        else
                        begin
                            first_read_in_write <= 1'b0;
                            //  Read odd addresses. 
                            count = 0;
                            begin: WADDR_MM_3 for (i=numwords-1; i>=0; i=i-1)
                                if ((i % 2) == 1 )
                                begin
                                    mbits_tmp[i-1] = mbits_tmp[i];
                                end
                                else
                                begin
                                    begin: WWORD_MM_3 for (j=0; j<width; j=j+1)
                                        if (((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == pattern[j])) || 
                                            ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0)))
                                        begin
                                            if (j == width-1)
                                            begin
                                                mbits_tmp[i] = 1'b1;
                                                count = count + 1;
                                            end
                                        end
                                        else
                                        begin
                                            j = width;
                                        end
                                    end // WWORD_MM_3
                                end
                            end // WADDR_MM_3
                        end
                        mcount_int <= count;
                        mbits_int <= mbits_tmp;
                    end
                end // end of MULTIPLE

                ///////////////////////////////
                // SINGLE: READ DURING WRITE //
                ///////////////////////////////
                if (match_mode == "SINGLE")
                begin
                    mbits_tmp = numwords_0;
                    index = 0;
                    count = 0;
                    if ((writex_done == 1'b1) && (wrxused_int == 1'b1))
                    begin
                        begin: WADDR_SM_2 for (i=0; i<numwords; i=i+1)
                            begin: WWORD_SM_2 for (j=0; j<width; j=j+1)
                                if (((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == (pattern[j] ^ wrx_int[j]))) || 
                                    ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0)))
                                begin
                                    if (j == width-1)
                                    begin
                                        mbits_tmp[i] = 1'b1;
                                        index = i;
                                        count = 1;
                                        j = width;
                                        i = numwords;
                                    end
                                end
                                else
                                begin
                                    j = width;
                                end
                            end // WWORD_SM_2
                        end // WADDR_SM_2
                    end
                    else
                    begin
                        begin: WADDR_SM_3 for (i=0; i<numwords; i=i+1)
                            begin: WWORD_SM_3 for (j=0; j<width; j=j+1)
                                if (((read_x_array(i,j) == 1'b0) && (read_cam_array(i,j) == pattern[j])) || 
                                    ((read_x_array(i,j) == 1'b1) && (read_cam_array(i,j) == 1'b0)))
                                begin
                                    if (j == width-1)
                                    begin
                                        mbits_tmp[i] = 1'b1;
                                        index = i;
                                        count = 1;
                                        j = width;
                                        i = numwords;
                                    end
                                end
                                else
                                begin
                                    j = width;
                                end
                            end // WWORD_SM_3
                        end // WADDR_SM_3
                    end
                    mcount_int <= count;
                    mbits_int <= mbits_tmp;
                    if (count == 0)
                    begin
                        mfound_int <= 1'b0;
                        maddress_int <= address_0;
                    end
                    else
                    begin
                        mfound_int <= 1'b1;
                        maddress_int <= index;
                    end
                end // end of SINGLE
            end // End of wren_rgd==1
        end // end of Write on pattern change
    end // end of pattern change
    end
    // End: Change in pattern 

    // Begin: Write Busy Control
    always @ (posedge wren_rgd_mux)
    begin
        wrbusy_int <= 1'b1;
    end

    always @ (negedge wren_rgd_mux)
    begin
        wrbusy_int <= 1'b0;
    end

    always @ (wraddress_rgd)
    begin
        if (wren_rgd_mux == 1'b1)
            wrbusy_int <= 1'b1;
    end

    always @ (posedge write_start_rgd)
    begin
        wrbusy_int <= 1'b0;
    end

    always @ (negedge write_start_rgd)
    begin
        if (wren_rgd_mux == 1'b1)
            wrbusy_int <= 1'b1;
    end
    // End: Write Busy Control

    // Begin: Registered Outputs
    always @ (posedge outclock or posedge outaclr)
    begin
        if (output_reg == "OUTCLOCK")
        begin
            if ((outaclr == 1'b1) && (output_aclr == "ON" ))
            begin
                maddress_rgd <= address_0;
                mbits_rgd <= numwords_0;
                mfound_rgd <= 1'b0;
                mcount_rgd <= address_0;
            end
            else if (outclocken_pullup == 1'b1)
            begin
                maddress_rgd <= maddress_int;
                mbits_rgd <= mbits_int;
                mfound_rgd <= mfound_int;
                mcount_rgd <= mcount_int;
            end
        end
    end

    always @ (posedge outaclr or posedge inclock)
    begin
        if (output_reg == "INCLOCK")
        begin
            if (output_aclr == "ON" )
            begin
                if (outaclr == 1'b1)
                begin
                    maddress_rgd <= address_0;
                    mbits_rgd <= numwords_0;
                    mfound_rgd <= 1'b0;
                    mcount_rgd <= address_0;
                end
                else if (inclocken_pullup == 1'b1)
                begin
                    maddress_rgd <= maddress_int;
                    mbits_rgd <= mbits_int;
                    mfound_rgd <= mfound_int;
                    mcount_rgd <= mcount_int;
                end
            end
            else if ((inclocken_pullup == 1'b1) && (inaclr != 1'b1))
            begin
                maddress_rgd <= maddress_int;
                mbits_rgd <= mbits_int;
                mfound_rgd <= mfound_int;
                mcount_rgd <= mcount_int;
            end
        end
    end
    // End: Registered Outputs

    // Begin: Write Control
    always @ (posedge wrbusy_int)
    begin
        write0 <= 1'b1;
        write1 <= 1'b0;
        writex <= 1'b0;
    end

    always @ (negedge wrbusy_int)
    begin
        write0 <= 1'b0;
    end

    always @ (posedge write0_done)
    begin
        write1 <= 1'b1;
        if ((wrxused_int == 1'b1)  && (wrx_reg != "UNUSED") && (wrx_aclr != "UNUSED")) write0 <= 1'b0;
    end

    always @ (posedge write1_done)
    begin
        if ((wrxused_int == 1'b1)  && (wrx_reg != "UNUSED") && (wrx_aclr != "UNUSED")) writex <= 1'b1;
        else writex <= 1'b0;
        write1 <= 1'b0;
    end

    always @ (posedge writex_done)
    begin
        write0 <= 1'b0;
        write1 <= 1'b0;
        writex <= 1'b0;
    end    

    // Begin: Read Control
    always @ (posedge mstart_rgd1_mux)
    begin
        if ((match_mode == "SINGLE") || (match_mode == "FAST_MULTIPLE")) rdbusy_int <= 1'b0;
        else rdbusy_int <= 1'b1;
    end

    always @ (posedge mstart_rgd2_mux)
    begin
        rdbusy_int <= 1'b0; 
    end

    always @ (posedge mnext)
    begin
        if (get_first_match == 1'b1) get_next_match <= 1'b1;
    end

    always @ (negedge mnext)
    begin
        get_next_match <= 1'b0;
    end
    // End: Read Control

    // Evaluate parameters
    assign pattern_int = (pattern_reg == "UNREGISTERED") ? pattern : pattern_rgd;
    assign wrx_int = (wrx_reg == "UNREGISTERED" ) ? wrx : wrx_rgd;
    assign wrxused_int = (wrx_reg == "UNREGISTERED") ? wrxused_pullup : wrxused_rgd;
    assign maddress = (output_reg == "UNREGISTERED") ? maddress_int : maddress_rgd;
    assign mbits = (output_reg == "UNREGISTERED") ? mbits_int : mbits_rgd;
    assign mfound = (output_reg == "UNREGISTERED") ? mfound_int : mfound_rgd;
    assign mcount = (output_reg == "UNREGISTERED") ? mcount_int : mcount_rgd;
    assign wrbusy = (wrbusy_int === 1'bx) ? 0 : wrbusy_int;
    assign rdbusy = (rdbusy_int === 1'bx) ? 0 : rdbusy_int;
    assign mstart_rgd1_mux = (mstart_rgd1 === 1'bx) ? 0 : mstart_rgd1;
    assign mstart_rgd2_mux = (mstart_rgd2 === 1'bx) ? 0 : mstart_rgd2;
    assign wren_rgd_mux = (wren_rgd === 1'bx) ? 0 : wren_rgd;

    assign outclock_int = (output_reg == "OUTCLOCK") ? outclock : inclock;
    assign outaclr_int = (output_reg == "OUTCLOCK") ? outaclr : inaclr;
    assign wrxused_pullup = wrxused;
    assign inclocken_pullup = inclocken;
    assign outclocken_pullup = outclocken;
    assign wrdelete_pulldown = wrdelete;

    assign # 2 rdbusy_delayed = rdbusy_int;

endmodule // end of altcam

// START MODULE NAME -----------------------------------------------------------
//
// Module Name      : ALTCLKLOCK
//
// Description      : Phase-Locked Loop (PLL) behavioral model. Supports basic
//                    PLL features such as multiplication and division of input
//                    clock frequency and phase shift.
//
// Limitations      : Model supports NORMAL operation mode only. External
//                    feedback mode and zero-delay-buffer mode are not simulated.
//                    Applicable to APEX, Mercury and FLEX10KE device families
//                    only.
//
// Expected results : Up to 4 clock outputs (clock0, clock1, clock2, clock_ext).
//                    clock2 and clock_ext are for Mercury devices only.
//                    locked output indicates when PLL locks.
//
//END MODULE NAME --------------------------------------------------------------

`timescale 1 ps / 1 ps

// MODULE DECLARATION
module altclklock (
    inclock,     // input reference clock
    inclocken,   // PLL enable signal
    fbin,        // feedback input for the PLL
    clock0,      // output clock 0
    clock1,      // output clock 1
    clock2,      // output clock 2 (for Mercury only)
    clock_ext,   // external output clock (for Mercury only)
    locked       // PLL lock signal
);

// GLOBAL PARAMETER DECLARATION
parameter inclock_period = 10000;  // units in ps
parameter inclock_settings = "UNUSED";
parameter valid_lock_cycles = 5;
parameter invalid_lock_cycles = 5;
parameter valid_lock_multiplier = 5;
parameter invalid_lock_multiplier = 5;
parameter operation_mode = "NORMAL";
parameter clock0_boost = 1;
parameter clock0_divide = 1;
parameter clock0_settings = "UNUSED";
parameter clock0_time_delay = "0";
parameter clock1_boost = 1;
parameter clock1_divide = 1;
parameter clock1_settings = "UNUSED";
parameter clock1_time_delay = "0";
parameter clock2_boost = 1;
parameter clock2_divide = 1;
parameter clock2_settings = "UNUSED";
parameter clock2_time_delay = "0";
parameter clock_ext_boost = 1;
parameter clock_ext_divide = 1;
parameter clock_ext_settings = "UNUSED";
parameter clock_ext_time_delay = "0";
parameter outclock_phase_shift = 0;  // units in ps
parameter intended_device_family = "APEX20KE";
parameter lpm_type = "altclklock";

// INPUT PORT DECLARATION
input inclock;
input inclocken;
input fbin;

// OUTPUT PORT DECLARATION
output clock0;
output clock1;
output clock2;
output clock_ext;
output locked;

// INTERNAL VARIABLE/REGISTER DECLARATION
reg clock0;
reg clock1;
reg clock2;
reg clock_ext;
reg locked;
reg locked_int;
reg inclock_started;
reg check_lock;
integer phase_delay0;
integer phase_delay1;
integer phase_delay2;
integer phase_delay_ext;
integer outclock_phase_shift_adj;
integer valid_inclock_edge_count;
integer invalid_inclock_edge_count;
integer duty_cycle_tolerance;
integer clk_per_tolerance;
integer check_lock_time;
integer check_lock_tol_time;
real lowcycle;
real highcycle;

// variables for clock synchronizing
integer last_synchronizing_rising_edge_for_clk0;
integer last_synchronizing_rising_edge_for_clk1;
integer last_synchronizing_rising_edge_for_clk2;
integer last_synchronizing_rising_edge_for_extclk;
integer clk0_synchronizing_period;
integer clk1_synchronizing_period;
integer clk2_synchronizing_period;
integer extclk_synchronizing_period;
integer input_cycles_per_clk0;
integer input_cycles_per_clk1;
integer input_cycles_per_clk2;
integer input_cycles_per_extclk;
integer clk0_cycles_per_sync_period;
integer clk1_cycles_per_sync_period;
integer clk2_cycles_per_sync_period;
integer extclk_cycles_per_sync_period;
integer input_cycle_count_to_sync0;
integer input_cycle_count_to_sync1;
integer input_cycle_count_to_sync2;
integer input_cycle_count_to_sync_extclk;

// variables for shedule_clk0-2, clk_ext
reg schedule_clk0;
reg schedule_clk1;
reg schedule_clk2;
reg schedule_extclk;
reg output_value0;
reg output_value1;
reg output_value2;
reg output_value_ext;
integer sched_time0;
integer sched_time1;
integer sched_time2;
integer sched_time_ext;
integer rem0;
integer rem1;
integer rem2;
integer rem_ext;
integer tmp_rem0;
integer tmp_rem1;
integer tmp_rem2;
integer tmp_rem_ext;
integer clk_cnt0;
integer clk_cnt1;
integer clk_cnt2;
integer clk_cnt_ext;
integer cyc0;
integer cyc1;
integer cyc2;
integer cyc_ext;
integer inc0;
integer inc1;
integer inc2;
integer inc_ext;
integer cycle_to_adjust0;
integer cycle_to_adjust1;
integer cycle_to_adjust2;
integer cycle_to_adjust_ext;
integer tmp_per0;
integer tmp_per1;
integer tmp_per2;
integer tmp_per_ext;
integer ori_per0;
integer ori_per1;
integer ori_per2;
integer ori_per_ext;
integer high_time0;
integer high_time1;
integer high_time2;
integer high_time_ext;
integer low_time0;
integer low_time1;
integer low_time2;
integer low_time_ext;

// Default inclocken and fbin ports to 1 if unused
tri1 inclocken_int;
tri1 fbin_int;

assign inclocken_int = inclocken;
assign fbin_int = fbin;

//
// function time_delay - converts time_delay in string format to integer, and
// add result to outclock_phase_shift
//
function integer time_delay;
input [8*16:1] s;

reg [8*16:1] reg_s;
reg [8:1] digit;
reg [8:1] tmp;
integer m;
integer outclock_phase_shift_adj;
integer sign;

begin
    // initialize variables
    sign = 1;
    outclock_phase_shift_adj = 0;
    reg_s = s;

    for (m = 1; m <= 16; m = m + 1)
    begin
        tmp = reg_s[128:121];
        digit = tmp & 8'b00001111;
        reg_s = reg_s << 8;
        // Accumulate ascii digits 0-9 only.
        if ((tmp >= 48) && (tmp <= 57))
            outclock_phase_shift_adj = outclock_phase_shift_adj * 10 + digit;
        if (tmp == 45)
            sign = -1;  // Found a '-' character, i.e. number is negative.
    end

    // add outclock_phase_shift to time delay
    outclock_phase_shift_adj = (sign*outclock_phase_shift_adj) + outclock_phase_shift;

    // adjust phase shift so that its value is between 0 and 1 full
    // inclock_period
    while (outclock_phase_shift_adj < 0)
        outclock_phase_shift_adj = outclock_phase_shift_adj + inclock_period;
    while (outclock_phase_shift_adj >= inclock_period)
        outclock_phase_shift_adj = outclock_phase_shift_adj - inclock_period;

    // assign result
    time_delay = outclock_phase_shift_adj;
end
endfunction

// INITIAL BLOCK
initial
begin
    locked_int = 0;
    valid_inclock_edge_count = 0;
    invalid_inclock_edge_count = 0;
    lowcycle = 0;
    highcycle = 0;
    inclock_started = 0;
    check_lock = 0;
    // clock synchronizing variables
    last_synchronizing_rising_edge_for_clk0 = 0;
    last_synchronizing_rising_edge_for_clk1 = 0;
    last_synchronizing_rising_edge_for_clk2 = 0;
    last_synchronizing_rising_edge_for_extclk = 0;
    clk0_synchronizing_period = 0;
    clk1_synchronizing_period = 0;
    clk2_synchronizing_period = 0;
    extclk_synchronizing_period = 0;
    schedule_clk0 = 0;
    schedule_clk1 = 0;
    schedule_clk2 = 0;
    schedule_extclk = 0;
    input_cycles_per_clk0 = clock0_divide;
    input_cycles_per_clk1 = clock1_divide;
    input_cycles_per_clk2 = clock2_divide;
    input_cycles_per_extclk = clock_ext_divide;
    clk0_cycles_per_sync_period = clock0_boost;
    clk1_cycles_per_sync_period = clock1_boost;
    clk2_cycles_per_sync_period = clock2_boost;
    extclk_cycles_per_sync_period = clock_ext_boost;
    input_cycle_count_to_sync0 = 0;
    input_cycle_count_to_sync1 = 0;
    input_cycle_count_to_sync2 = 0;
    input_cycle_count_to_sync_extclk = 0;
    inc0 = 1;
    inc1 = 1;
    inc2 = 1;
    inc_ext = 1;
    cycle_to_adjust0 = 0;
    cycle_to_adjust1 = 0;
    cycle_to_adjust2 = 0;
    cycle_to_adjust_ext = 0;

    // convert time delays from string to integer
    phase_delay0 = time_delay(clock0_time_delay);
    phase_delay1 = time_delay(clock1_time_delay);
    phase_delay2 = time_delay(clock2_time_delay);
    phase_delay_ext = time_delay(clock_ext_time_delay);

    // 20% tolerance of input clock period to allow duty cycles of 40% to 60%
    duty_cycle_tolerance = 0.2 * inclock_period;
    // 2.5% tolerance of input clock period variation
    clk_per_tolerance = 0.025 * inclock_period;
    // calculate check lock time with and without tolerance
    check_lock_tol_time = (inclock_period + duty_cycle_tolerance) / 2;
    check_lock_time = inclock_period / 2;
end

// PLL enable signal
always @ (inclocken_int)
begin
    // PLL is disabled, reset variables
    if (inclocken_int == 0)
    begin
        valid_inclock_edge_count = 0;
        invalid_inclock_edge_count = 0;
        locked_int = 0;
        locked = 0;
        inclock_started = 0;
        last_synchronizing_rising_edge_for_clk0 = 0;
        last_synchronizing_rising_edge_for_clk1 = 0;
        last_synchronizing_rising_edge_for_clk2 = 0;
        last_synchronizing_rising_edge_for_extclk = 0;
        schedule_clk0 = 0;
        schedule_clk1 = 0;
        schedule_clk2 = 0;
        schedule_extclk = 0;
        lowcycle = 0;
        highcycle = 0;
    end
    else // PLL is enabled
    begin
        if (($realtime == 0) && (inclock == 1)) // if the input clock starts with +ve edge
        begin
            valid_inclock_edge_count = 1;
            inclock_started = 1;
            highcycle = $realtime;
        end
    end
end

// input reference clock
always @ (inclock)
begin
    // PLL has not locked, but is already enabled
    if ((locked_int == 0) && (inclocken_int == 1))
    begin
        locked = 0;
    end

    // inclock edge detected and PLL is enabled
    if (inclocken_int == 1)
    begin
        if (locked_int == 1)
        begin
            // if number of half clock cycles before dropping lock is set to 1
            if (invalid_lock_cycles == 1)
            begin
                // check input clock every half input clock period
                // (with tolerance)
                check_lock <= # (check_lock_tol_time) ~check_lock;
            end
             // else number of half cycles to unlock is greater than 1
            else if (invalid_lock_cycles != 1)
            begin
                // check input clock every half input clock period
                // (without tolerance - not needed)
                check_lock <= # (check_lock_time) ~check_lock;
            end
        end

        // first edge of the inclock
        if (inclock_started == 0)
        begin
            if (inclock == 1) // rising edge
            begin
                highcycle = $realtime;
                inclock_started = 1;
                valid_inclock_edge_count = 1;
                invalid_inclock_edge_count = 0;
            end
            else if (inclock == 0) // falling edge
            begin
                lowcycle = $realtime;
                inclock_started = 1;
                valid_inclock_edge_count = 0;
                invalid_inclock_edge_count = 0;
            end
        end
        // rising edge of inclock
        else if (inclock == 1)
        begin
            // check for input clock period violation (allow 2.5% variation)
            if ((highcycle > 0 ) &&
               ((($realtime - highcycle) < (inclock_period - clk_per_tolerance)) ||
               (($realtime - highcycle) > (inclock_period + clk_per_tolerance))))
            begin
                invalid_inclock_edge_count = invalid_inclock_edge_count + 1;
                valid_inclock_edge_count = 1;
                $display ($time, "ps Warning: Inclock period violation");
            end
            // check for duty cycle violation (allow 40%-60% duty cycles)
            else if ((($realtime - lowcycle)*2 < (inclock_period - duty_cycle_tolerance)) ||
               (($realtime - lowcycle)*2 > (inclock_period + duty_cycle_tolerance)))
            begin
                invalid_inclock_edge_count = invalid_inclock_edge_count + 1;
                valid_inclock_edge_count = 1;
                $display ($time,"ps Warning: Duty cycle violation");
            end
            else // input clock is fine
            begin
                valid_inclock_edge_count = valid_inclock_edge_count + 1;
                // valid rising clock edge, reset invalid clock edge count to 0
                invalid_inclock_edge_count = 0;
            end
            highcycle = $realtime;
        end
        // falling edge of inclock
        else if (inclock == 0)
        begin
            // check for input clock period violation (allow 2.5% variation)
            if ((lowcycle > 0) &&
               ((($realtime - lowcycle) < (inclock_period - clk_per_tolerance)) ||
               (($realtime - lowcycle) > (inclock_period + clk_per_tolerance))))
            begin
                invalid_inclock_edge_count = invalid_inclock_edge_count + 1;
                valid_inclock_edge_count = 1;
                $display ($time, "ps Warning: Inclock period violation");
            end
            // check for duty cycle violation (allow 40%-60% duty cycles)
            else if ((($realtime - highcycle)*2 < (inclock_period - duty_cycle_tolerance)) ||
               (($realtime - highcycle)*2 > (inclock_period + duty_cycle_tolerance)))
            begin
                invalid_inclock_edge_count = invalid_inclock_edge_count + 1;
                valid_inclock_edge_count = 1;
                $display ($time,"ps Warning: Duty cycle violation");
            end
            else
            begin
                valid_inclock_edge_count = valid_inclock_edge_count + 1;
                // valid falling clock edge, reset invalid clock edge count to 0
                invalid_inclock_edge_count = 0;
            end
            lowcycle = $realtime;
        end

        // number of valid input clock edges reaches the number of half cycles
        // to lock, as defined by the user -> make lock pin high
        if ((valid_inclock_edge_count >= valid_lock_cycles) && ($realtime > 0))
        begin
            locked_int = 1;
            locked = 1;
            valid_inclock_edge_count = 0;
        end
        // number of invalid input clock edges reaches the number of half cycles
        // to unlock, as defined by the user -> make lock pin low
        else if ((invalid_inclock_edge_count > invalid_lock_cycles) &&
                 (invalid_inclock_edge_count > 0) && ($realtime > 0))
        begin
            locked_int = 0;
            locked = 0;
            invalid_inclock_edge_count = 0;
            valid_inclock_edge_count = 0;
            inclock_started = 0;
            last_synchronizing_rising_edge_for_clk0 = 0;
            last_synchronizing_rising_edge_for_clk1 = 0;
            last_synchronizing_rising_edge_for_clk2 = 0;
            last_synchronizing_rising_edge_for_extclk = 0;
            schedule_clk0 = 0;
            schedule_clk1 = 0;
            schedule_clk2 = 0;
            schedule_extclk = 0;
            lowcycle =0 ;
            highcycle = 0;
        end

        // logic to schedule clock outputs
        if (inclock == 1)
        begin
            if (locked_int == 1'b1) // if PLL has locked
            begin
                // clock0
                input_cycle_count_to_sync0 = input_cycle_count_to_sync0 + 1;
                // initial rising edge
                if (last_synchronizing_rising_edge_for_clk0 == 0)
                begin
                    input_cycle_count_to_sync0 = 0;
                    clk0_synchronizing_period = clock0_divide * inclock_period;
                    last_synchronizing_rising_edge_for_clk0 = $realtime;
                    schedule_clk0 = 1;
                end
                else
                if (input_cycle_count_to_sync0 == input_cycles_per_clk0)
                begin
                    clk0_synchronizing_period = $realtime - last_synchronizing_rising_edge_for_clk0;
                    last_synchronizing_rising_edge_for_clk0 = $realtime;
                    schedule_clk0 = 1;
                    input_cycle_count_to_sync0 = 0;
                end

                // clock1
                input_cycle_count_to_sync1 = input_cycle_count_to_sync1 + 1;
                // initial rising edge
                if (last_synchronizing_rising_edge_for_clk1 == 0)
                begin
                    input_cycle_count_to_sync1 = 0;
                    clk1_synchronizing_period = clock1_divide * inclock_period;
                    last_synchronizing_rising_edge_for_clk1 = $realtime;
                    schedule_clk1 = 1;
                end
                else
                if (input_cycle_count_to_sync1 == input_cycles_per_clk1)
                begin
                    clk1_synchronizing_period = $realtime - last_synchronizing_rising_edge_for_clk1;
                    last_synchronizing_rising_edge_for_clk1 = $realtime;
                    schedule_clk1 = 1;
                    input_cycle_count_to_sync1 = 0;
                end

                // clock2
                input_cycle_count_to_sync2 = input_cycle_count_to_sync2 + 1;
                // initial rising edge
                if (last_synchronizing_rising_edge_for_clk2 == 0)
                begin
                    input_cycle_count_to_sync2 = 0;
                    clk2_synchronizing_period = clock2_divide * inclock_period;
                    last_synchronizing_rising_edge_for_clk2 = $realtime;
                    schedule_clk2 = 1;
                end
                else
                if (input_cycle_count_to_sync2 == input_cycles_per_clk2)
                begin
                    clk2_synchronizing_period = $realtime - last_synchronizing_rising_edge_for_clk2;
                    last_synchronizing_rising_edge_for_clk2 = $realtime;
                    schedule_clk2 = 1;
                    input_cycle_count_to_sync2 = 0;
                end

                // clock_ext
                input_cycle_count_to_sync_extclk = input_cycle_count_to_sync_extclk + 1;
                // initial rising edge
                if (last_synchronizing_rising_edge_for_extclk == 0)
                begin
                    input_cycle_count_to_sync_extclk = 0;
                    extclk_synchronizing_period = clock_ext_divide * inclock_period;
                    last_synchronizing_rising_edge_for_extclk = $realtime;
                    schedule_extclk = 1;
                end
                else
                if (input_cycle_count_to_sync_extclk == input_cycles_per_extclk)
                begin
                    extclk_synchronizing_period = $realtime - last_synchronizing_rising_edge_for_extclk;
                    last_synchronizing_rising_edge_for_extclk = $realtime;
                    schedule_extclk = 1;
                    input_cycle_count_to_sync_extclk = 0;
                end
            end
        end
    end // inclock enabled
end

// logic to check the input clock to see if it has flatlined
always @ (check_lock)
begin
    if (locked_int == 1)
    begin
        // trigger this block every half inclock_period
        if (invalid_lock_cycles != 1)
        begin
            check_lock <= # (check_lock_time) ~check_lock;
        end
        // if number of half clock cycles before dropping lock is set to 1
        else if (invalid_lock_cycles == 1)
        begin
            // check input clock every half input clock period
            // (with tolerance)
            check_lock <= # (check_lock_tol_time) ~check_lock;
        end

        // increment the invalid_inclock_edge_count here...this counter will
        // be reset to 0 when a valid clock edge arrives in the
        // "always@(inclock)" block
        invalid_inclock_edge_count = invalid_inclock_edge_count + 1;

        // if the invalid clock edge count exceeds the number of half cycles to
        // unlock, drop the PLL lock signal, and display a warning
        if ((invalid_inclock_edge_count > invalid_lock_cycles) &&
            (invalid_inclock_edge_count > 0) && ($realtime > 0))
        begin
            $display ($time, "ps Warning: altclklock out of lock.");
            locked_int = 0;
            locked = 0;
            valid_inclock_edge_count = 0;
            invalid_inclock_edge_count = 0;
            inclock_started = 0;
            last_synchronizing_rising_edge_for_clk0 = 0;
            last_synchronizing_rising_edge_for_clk1 = 0;
            last_synchronizing_rising_edge_for_clk2 = 0;
            last_synchronizing_rising_edge_for_extclk = 0;
            schedule_clk0 = 0;
            schedule_clk1 = 0;
            schedule_clk2 = 0;
            schedule_extclk = 0;
            lowcycle = 0;
            highcycle = 0;
        end
    end
end

// clock0 output
always @(posedge schedule_clk0)
begin
    // initialise variables
    inc0 = 1;
    cycle_to_adjust0 = 0;
    output_value0 = 1'b1;
    sched_time0 = phase_delay0;
    rem0 = clk0_synchronizing_period % clk0_cycles_per_sync_period;
    ori_per0 = clk0_synchronizing_period / clk0_cycles_per_sync_period;

    // schedule <clk0_cycles_per_sync_period> number of clock0 cycles in this
    // loop - in order to synchronize the output clock always to the input clock
    // to get rid of clock drift for cases where the input clock period is
    // not evenly divisible
    for (clk_cnt0 = 1; clk_cnt0 <= clk0_cycles_per_sync_period;
         clk_cnt0 = clk_cnt0 + 1)
    begin
        tmp_per0 = ori_per0;
        if ((rem0 != 0) && (inc0 <= rem0))
        begin
            tmp_rem0 = (clk0_cycles_per_sync_period * inc0) % rem0;
            cycle_to_adjust0 = (clk0_cycles_per_sync_period * inc0) / rem0;
            if (tmp_rem0 != 0)
                cycle_to_adjust0 = cycle_to_adjust0 + 1;
        end

        // if this cycle is the one to adjust the output clock period, then
        // increment the period by 1 unit
        if (cycle_to_adjust0 == clk_cnt0)
        begin
            tmp_per0 = tmp_per0 + 1;
            inc0 = inc0 + 1;
        end

        // adjust the high and low cycle period
        high_time0 = tmp_per0 / 2;
        if ((tmp_per0 % 2) != 0)
            high_time0 = high_time0 + 1;

        low_time0 = tmp_per0 - high_time0;

        // schedule the high and low cycle of 1 output clock period
        for (cyc0 = 0; cyc0 <= 1; cyc0 = cyc0 + 1)
        begin
            clock0 <= #(sched_time0) output_value0;
            output_value0 = ~output_value0;
            if (output_value0 == 1'b0)
            begin
                sched_time0 = sched_time0 + high_time0;
            end
            else if (output_value0 == 1'b1)
            begin
                sched_time0 = sched_time0 + low_time0;
            end
        end
    end

    // drop the schedule_clk0 to 0 so that the "always@(inclock)" block can
    // trigger this block again when the correct time comes
    schedule_clk0 <= #1 1'b0;
end

// clock1 output
always @(posedge schedule_clk1)
begin
    // initialize variables
    inc1 = 1;
    cycle_to_adjust1 = 0;
    output_value1 = 1'b1;
    sched_time1 = phase_delay1;
    rem1 = clk1_synchronizing_period % clk1_cycles_per_sync_period;
    ori_per1 = clk1_synchronizing_period / clk1_cycles_per_sync_period;

    // schedule <clk1_cycles_per_sync_period> number of clock1 cycles in this
    // loop - in order to synchronize the output clock always to the input clock,
    // to get rid of clock drift for cases where the input clock period is
    // not evenly divisible
    for (clk_cnt1 = 1; clk_cnt1 <= clk1_cycles_per_sync_period;
         clk_cnt1 = clk_cnt1 + 1)
    begin
        tmp_per1 = ori_per1;
        if ((rem1 != 0) && (inc1 <= rem1))
        begin
            tmp_rem1 = (clk1_cycles_per_sync_period * inc1) % rem1;
            cycle_to_adjust1 = (clk1_cycles_per_sync_period * inc1) / rem1;
            if (tmp_rem1 != 0)
                cycle_to_adjust1 = cycle_to_adjust1 + 1;
        end

        // if this cycle is the one to adjust the output clock period, then
        // increment the period by 1 unit
        if (cycle_to_adjust1 == clk_cnt1)
        begin
            tmp_per1 = tmp_per1 + 1;
            inc1 = inc1 + 1;
        end

        // adjust the high and low cycle period
        high_time1 = tmp_per1 / 2;
        if ((tmp_per1 % 2) != 0)
            high_time1 = high_time1 + 1;

        low_time1 = tmp_per1 - high_time1;

        // schedule the high and low cycle of 1 output clock period
        for (cyc1 = 0; cyc1 <= 1; cyc1 = cyc1 + 1)
        begin
            clock1 <= #(sched_time1) output_value1;
            output_value1 = ~output_value1;
            if (output_value1 == 1'b0)
                sched_time1 = sched_time1 + high_time1;
            else if (output_value1 == 1'b1)
                sched_time1 = sched_time1 + low_time1;
        end
    end
    // drop the schedule_clk1 to 0 so that the "always@(inclock)" block can
    // trigger this block again when the correct time comes
    schedule_clk1 <= #1 1'b0;
end

// clock2 output
always @(posedge schedule_clk2)
begin
    // clock2 is only available for Mercury
    if ((intended_device_family == "MERCURY") || (intended_device_family == "Mercury"))
    begin
        // initialize variables
        inc2 = 1;
        cycle_to_adjust2 = 0;
        output_value2 = 1'b1;
        sched_time2 = phase_delay2;
        rem2 = clk2_synchronizing_period % clk2_cycles_per_sync_period;
        ori_per2 = clk2_synchronizing_period / clk2_cycles_per_sync_period;

        // schedule <clk2_cycles_per_sync_period> number of clock2 cycles in this
        // loop - in order to synchronize the output clock always to the input clock,
        // to get rid of clock drift for cases where the input clock period is
        // not evenly divisible
        for (clk_cnt2 = 1; clk_cnt2 <= clk2_cycles_per_sync_period;
             clk_cnt2 = clk_cnt2 + 1)
        begin
            tmp_per2 = ori_per2;
            if ((rem2 != 0) && (inc2 <= rem2))
            begin
                tmp_rem2 = (clk2_cycles_per_sync_period * inc2) % rem2;
                cycle_to_adjust2 = (clk2_cycles_per_sync_period * inc2) / rem2;
                if (tmp_rem2 != 0)
                    cycle_to_adjust2 = cycle_to_adjust2 + 1;
            end

            // if this cycle is the one to adjust the output clock period, then
            // increment the period by 1 unit
            if (cycle_to_adjust2 == clk_cnt2)
            begin
                tmp_per2 = tmp_per2 + 1;
                inc2 = inc2 + 1;
            end

            // adjust the high and low cycle period
            high_time2 = tmp_per2 / 2;
            if ((tmp_per2 % 2) != 0)
                high_time2 = high_time2 + 1;

            low_time2 = tmp_per2 - high_time2;

            // schedule the high and low cycle of 1 output clock period
            for (cyc2 = 0; cyc2 <= 1; cyc2 = cyc2 + 1)
            begin
                clock2 <= #(sched_time2) output_value2;
                output_value2 = ~output_value2;
                if (output_value2 == 1'b0)
                    sched_time2 = sched_time2 + high_time2;
                else if (output_value2 == 1'b1)
                    sched_time2 = sched_time2 + low_time2;
            end
        end
        // drop the schedule_clk2 to 0 so that the "always@(inclock)" block can
        // trigger this block again when the correct time comes
        schedule_clk2 <= #1 1'b0;
    end
end

// clock_ext output
always @(posedge schedule_extclk)
begin
    // clock_ext is only available for Mercury
    if ((intended_device_family == "MERCURY") || (intended_device_family == "Mercury"))
    begin
        // initialize variables
        inc_ext = 1;
        cycle_to_adjust_ext = 0;
        output_value_ext = 1'b1;
        sched_time_ext = phase_delay_ext;
        rem_ext = extclk_synchronizing_period % extclk_cycles_per_sync_period;
        ori_per_ext = extclk_synchronizing_period/extclk_cycles_per_sync_period;

        // schedule <extclk_cycles_per_sync_period> number of clock_ext cycles in this
        // loop - in order to synchronize the output clock always to the input clock,
        // to get rid of clock drift for cases where the input clock period is
        // not evenly divisible
        for (clk_cnt_ext = 1; clk_cnt_ext <= extclk_cycles_per_sync_period;
             clk_cnt_ext = clk_cnt_ext + 1)
        begin
            tmp_per_ext = ori_per_ext;
            if ((rem_ext != 0) && (inc_ext <= rem_ext))
            begin
                tmp_rem_ext = (extclk_cycles_per_sync_period * inc_ext) % rem_ext;
                cycle_to_adjust_ext = (extclk_cycles_per_sync_period * inc_ext) / rem_ext;
                if (tmp_rem_ext != 0)
                    cycle_to_adjust_ext = cycle_to_adjust_ext + 1;
            end

            // if this cycle is the one to adjust the output clock period, then
            // increment the period by 1 unit
            if (cycle_to_adjust_ext == clk_cnt_ext)
            begin
                tmp_per_ext = tmp_per_ext + 1;
                inc_ext = inc_ext + 1;
            end

            // adjust the high and low cycle period
            high_time_ext = tmp_per_ext/2;
            if ((tmp_per_ext % 2) != 0)
               high_time_ext = high_time_ext + 1;

            low_time_ext = tmp_per_ext - high_time_ext;

            // schedule the high and low cycle of 1 output clock period
            for (cyc_ext = 0; cyc_ext <= 1; cyc_ext = cyc_ext + 1)
            begin
                clock_ext <= #(sched_time_ext) output_value_ext;
                output_value_ext = ~output_value_ext;
                if (output_value_ext == 1'b0)
                   sched_time_ext = sched_time_ext + high_time_ext;
                else if (output_value_ext == 1'b1)
                   sched_time_ext = sched_time_ext + low_time_ext;
            end
        end
        // drop the schedule_extclk to 0 so that the "always@(inclock)" block
        // can trigger this block again when the correct time comes
        schedule_extclk <= #1 1'b0;
    end
end

endmodule // altclklock
// END OF MODULE ALTCLKLOCK

//--------------------------------------------------------------------------
// Module Name      : altdpram
//
// Description      : Parameterized Dual Port RAM megafunction
//
// Limitation       : This megafunction is provided only for backward
//                    compatibility in Cyclone, Stratix, and Stratix GX
//                    designs.
//
// Results expected : RAM having dual ports (separate Read and Write)
//                    behaviour
//
//--------------------------------------------------------------------------
`timescale 1 ps / 1 ps
`define DEV_APEX20K "APEX20K"
`define DEV_APEX20KE "APEX20KE"

// MODULE DECLARATION
module altdpram (wren, data, wraddress, inclock, inclocken, rden, rdaddress,
                 outclock, outclocken, aclr, q);

// PARAMETER DECLARATION
    parameter width = 1;
    parameter widthad = 1;
    parameter numwords = 0;
    parameter lpm_file = "UNUSED";
    parameter lpm_hint = "USE_EAB=ON";
    parameter use_eab = "ON";
    parameter lpm_type = "altdpram";
    parameter indata_reg = "UNREGISTERED";
    parameter indata_aclr = "OFF";
    parameter wraddress_reg = "UNREGISTERED";
    parameter wraddress_aclr = "OFF";
    parameter wrcontrol_reg = "UNREGISTERED";
    parameter wrcontrol_aclr = "OFF";
    parameter rdaddress_reg = "UNREGISTERED";
    parameter rdaddress_aclr = "OFF";
    parameter rdcontrol_reg = "UNREGISTERED";
    parameter rdcontrol_aclr = "OFF";
    parameter outdata_reg = "UNREGISTERED";
    parameter outdata_aclr = "OFF";
    parameter intended_device_family = `DEV_APEX20KE;
    parameter write_at_low_clock = ((wrcontrol_reg == "INCLOCK") &&
                                   ((lpm_hint == "USE_EAB=ON") &&
                                   (use_eab == "ON"))) ?
                                1 : 0;
    parameter rden_low_output_0 = ((intended_device_family == `DEV_APEX20K) &&
                                  ((lpm_hint == "USE_EAB=ON") &&
                                  (use_eab == "ON"))) ?
                                1 : 0;

// INPUT PORT DECLARATION
    input  wren;                 // Write enable input
    input  [width-1:0] data;     // Data input to the memory
    input  [widthad-1:0] wraddress; // Write address input to the memory
    input  inclock;              // Input or write clock
    input  inclocken;            // Clock enable for inclock
    input  rden;                 // Read enable input. Disable reading when low
    input  [widthad-1:0] rdaddress; // Write address input to the memory
    input  outclock;             // Output or read clock
    input  outclocken;           // Clock enable for outclock
    input  aclr;                 // Asynchronous clear input

// OUTPUT PORT DECLARATION
    output [width-1:0] q;        // Data output from the memory

// INTERNAL SIGNAL/REGISTER DECLARATION
    reg [width-1:0] mem_data [0:(1<<widthad)-1];
    reg [8*256:1] ram_initf;
    reg [width-1:0] data_write_at_high;
    reg [width-1:0] data_write_at_low;
    reg [widthad-1:0] wraddress_at_high;
    reg [widthad-1:0] wraddress_at_low;
    reg [width-1:0] mem_output;
    reg [width-1:0] mem_output_at_outclock;
    reg [widthad-1:0] rdaddress_at_inclock;
    reg [widthad-1:0] rdaddress_at_outclock;
    reg wren_at_high;
    reg wren_at_low;
    reg rden_at_inclock;
    reg rden_at_outclock;

// INTERNAL WIRE DECLARATION
    wire aclr_on_wraddress;
    wire aclr_on_wrcontrol;
    wire aclr_on_rdaddress;
    wire aclr_on_rdcontrol;
    wire aclr_on_indata;
    wire aclr_on_outdata;
    wire [width-1:0] data_tmp;
    wire [width-1:0] previous_read_data;
    wire [width-1:0] new_read_data;
    wire [widthad-1:0] wraddress_tmp;
    wire [widthad-1:0] rdaddress_tmp;
    wire wren_tmp;
    wire rden_tmp;

// INTERNAL TRI DECLARATION
    tri0 inclock;
    tri1 inclocken;
    tri0 outclock;
    tri1 outclocken;
    tri1 rden;
    tri0 aclr;

// LOCAL INTEGER DECLARATION
    integer i;
    integer i_numwords;

// INITIAL CONSTRUCT BLOCK
    initial
    begin
        // Check for invalid parameters
        if (width <= 0)
            $display("Error! width parameter must be greater than 0.");
        if (widthad <= 0)
            $display("Error! widthad parameter must be greater than 0.");
        if (numwords < 0)
            $display("Error! numwords parameter must be greater than 0.");

        if ((indata_reg !== "INCLOCK") && (indata_reg !== "UNREGISTERED"))
            $display("Error! indata_reg must be INCLOCK or UNREGISTERED.");
        if ((outdata_reg !== "OUTCLOCK") && (outdata_reg !== "UNREGISTERED"))
            $display("Error! outdata_reg must be OUTCLOCK or UNREGISTERED.");
        if ((wraddress_reg !== "INCLOCK") &&
            (wraddress_reg !== "UNREGISTERED"))
            $display("Error! wraddress_reg must be INCLOCK or UNREGISTERED.");
        if ((wrcontrol_reg !== "INCLOCK") &&
            (wrcontrol_reg !== "UNREGISTERED"))
            $display("Error! wrcontrol_reg must be INCLOCK or UNREGISTERED.");
        if ((rdaddress_reg !== "INCLOCK") && (rdaddress_reg !== "OUTCLOCK")
            && (rdaddress_reg !== "UNREGISTERED"))
            $display("Error! rdaddress_reg must be INCLOCK, OUTCLOCK or UNREGISTERED.");
        if ((rdcontrol_reg !== "INCLOCK") && (rdcontrol_reg !== "OUTCLOCK") &&
            (rdcontrol_reg !== "UNREGISTERED"))
            $display("Error! rdcontrol_reg must be INCLOCK, OUTCLOCK or UNREGISTERED.");

        if ((indata_aclr !== "ON") && (indata_aclr !== "OFF"))
            $display("Error! indata_aclr must be ON or OFF.");
        if ((outdata_aclr !== "ON") && (outdata_aclr !== "OFF"))
            $display("Error! outdata_aclr must be ON or OFF.");
        if ((wraddress_aclr !== "ON") && (wraddress_aclr !== "OFF"))
            $display("Error! wraddress_aclr must be ON or OFF.");
        if ((wrcontrol_aclr !== "ON") && (wrcontrol_aclr !== "OFF"))
            $display("Error! wrcontrol_aclr must be ON or OFF.");
        if ((rdaddress_aclr !== "ON") && (rdaddress_aclr !== "OFF"))
            $display("Error! rdaddress_aclr must be ON or OFF.");
        if ((rdcontrol_aclr !== "ON") && (rdcontrol_aclr !== "OFF"))
            $display("Error! rdcontrol_aclr must be ON or OFF.");

        // Initialize mem_data
        i_numwords = (numwords) ? numwords : 1<<widthad;
        if (lpm_file == "UNUSED")
            for (i=0; i<i_numwords; i=i+1)
                mem_data[i] = 0;
        else
        begin
`ifdef NO_PLI
            $readmemh(lpm_file, mem_data);
`else
            $convert_hex2ver(lpm_file, width, ram_initf);
            $readmemh(ram_initf, mem_data);
`endif
        end

        // Power-up conditions
        mem_output_at_outclock = 0;
        data_write_at_high = 0;
        data_write_at_low = 0;
        rdaddress_at_inclock = 0;
        rdaddress_at_outclock = 0;

    end


// ALWAYS CONSTRUCT BLOCKS

    // Set up logics that respond to the postive edge of inclock
    // some logics may be affected by Asynchronous Clear
    always @(posedge inclock)
    begin
        if ((aclr == 1) && (indata_aclr == "ON"))
            data_write_at_high <= 0;
        else if (inclocken == 1)
            data_write_at_high <= data;

        if ((aclr == 1) && (wraddress_aclr == "ON"))
            wraddress_at_high <= 0;
        else if (inclocken == 1)
            wraddress_at_high <= wraddress;

        if ((aclr == 1) && (wrcontrol_aclr == "ON"))
            wren_at_high <= 0;
        else if (inclocken == 1)
            wren_at_high <= wren;

        if ((aclr == 1) && (rdaddress_aclr == "ON"))
            rdaddress_at_inclock <= 0;
        else if (inclocken == 1)
            rdaddress_at_inclock <= rdaddress;

        if ((aclr == 1) && (rdcontrol_aclr == "ON"))
            rden_at_inclock <= 0;
        else if (inclocken == 1)
            rden_at_inclock <= rden;
    end

    // Set up logics that respond to the negative edge of inclock
    // some logics may be affected by Asynchronous Clear
    always @(negedge inclock)
    begin
        if ((aclr == 1) && (indata_aclr == "ON"))
            data_write_at_low <= 0;
        else if (inclocken == 1)
            //data_write_at_low <= data;
            data_write_at_low <= data_write_at_high;

        if ((aclr == 1) && (wraddress_aclr == "ON"))
            wraddress_at_low <= 0;
        else if (inclocken == 1)
            //wraddress_at_low <= wraddress;
            wraddress_at_low <= wraddress_at_high;

        if ((aclr == 1) && (wrcontrol_aclr == "ON"))
            wren_at_low <= 0;
        else if (inclocken == 1)
            //wren_at_low <= wren;
            wren_at_low <= wren_at_high;
    end

    // Set up logics that respond to the positive edge of outclock
    // some logics may be affected by Asynchronous Clear
    always @(posedge outclock)
    begin
        if ((aclr == 1) && (rdaddress_aclr == "ON"))
            rdaddress_at_outclock <= 0;
        else if (outclocken == 1)
            rdaddress_at_outclock <= rdaddress;

        if ((aclr == 1) && (rdcontrol_aclr == "ON"))
            rden_at_outclock <= 0;
        else if (outclocken == 1)
            rden_at_outclock <= rden;

        if ((aclr == 1) && (outdata_aclr == "ON"))
            mem_output_at_outclock <= 0;
        else if (outclocken == 1)
            mem_output_at_outclock <= mem_output;
    end

    // Asynchronous Logic
    // Update memory with the latest data
    always @(data_tmp or wraddress_tmp or wren_tmp)
    begin
        if (wren_tmp == 1)
            mem_data[wraddress_tmp] <= data_tmp;
    end

    always @(new_read_data)
    begin
        mem_output <= new_read_data;
    end

// CONTINUOUS ASSIGNMENT

    // The following circuits will select for appropriate connections based on
    // the given parameter values

    assign aclr_on_wraddress = ((wraddress_aclr == "ON") ?
                                 aclr
                                 : 0);

    assign aclr_on_wrcontrol = ((wrcontrol_aclr == "ON") ?
                                 aclr
                                 : 0);

    assign aclr_on_rdaddress = ((rdaddress_aclr == "ON") ?
                                 aclr
                                 : 0);

    assign aclr_on_rdcontrol = ((rdcontrol_aclr == "ON") ?
                                 aclr
                                 : 0);

    assign aclr_on_indata = ((indata_aclr == "ON") ?
                                 aclr
                                 : 0);

    assign aclr_on_outdata = ((outdata_aclr == "ON") ?
                                 aclr
                                 : 0);

    assign data_tmp = ((indata_reg == "INCLOCK") ?
                         (write_at_low_clock ?
                            ((aclr_on_indata == 1) ?
                                0
                                : data_write_at_low)
                            : ((aclr_on_indata == 1) ?
                                0
                                : data_write_at_high))
                        : data);

    assign wraddress_tmp = ((wraddress_reg == "INCLOCK") ?
                             (write_at_low_clock ?
                                 ((aclr_on_wraddress == 1) ?
                                     0
                                     : wraddress_at_low)
                                 : ((aclr_on_wraddress == 1) ?
                                     0
                                     : wraddress_at_high))
                             : wraddress);

    assign wren_tmp = ((wrcontrol_reg == "INCLOCK") ?
                       (write_at_low_clock ?
                            ((aclr_on_wrcontrol == 1) ?
                                0
                                : wren_at_low)
                            : ((aclr_on_wrcontrol == 1) ?
                                0
                                :wren_at_high))
                        : wren);

    assign rdaddress_tmp = ((rdaddress_reg == "INCLOCK") ?
                             ((aclr_on_rdaddress == 1) ?
                                 0
                                 : rdaddress_at_inclock)
                             : ((rdaddress_reg == "OUTCLOCK") ?
                                 ((aclr_on_rdaddress == 1) ?
                                     0
                                     : rdaddress_at_outclock)
                                 : rdaddress));

    assign rden_tmp = ((rdcontrol_reg == "INCLOCK") ?
                        ((aclr_on_rdcontrol == 1) ?
                            0
                            : rden_at_inclock)
                        : ((rdcontrol_reg == "OUTCLOCK") ?
                            ((aclr_on_rdcontrol == 1) ?
                                0
                                : rden_at_outclock)
                            : rden));

    assign previous_read_data = mem_output;

    assign new_read_data = ((rden_tmp == 1) ?
                              mem_data[rdaddress_tmp]
                              : ((rden_low_output_0) ?
                                  0
                                  : previous_read_data));

    assign q = ((outdata_reg == "OUTCLOCK")?
                 ((aclr_on_outdata == 1) ?
                     0
                     :mem_output_at_outclock)
                 : mem_output);

endmodule // altdpram



//-----------------------------------------------------------------------------+
// Module Name      : alt3pram
//
// Description      : Triple-Port RAM
//
// Limitation       : This megafunction is provided only for backward 
//                    compatibility in Stratix™ designs; instead, Altera® 
//                    recommends using the altsyncram megafunction
//
//                    For Apex Families,
//                    Uses one embedded cell per data output bit for 
//                    Embedded System Block (ESB): APEX 20K, APEX II, 
//                            ARM-based Excalibur and Mercury devices or
//                    Embedded Array Block (EAB): ACEX 1K and FLEX 10KE family;
//
//                    However, in FLEX 6000, MAX 3000, and MAX 7000 devices, 
//                    or if the USE_EAB paramter is set to "OFF", uses one 
//                    logic cell (LCs) per memory bit.
//
//
// Results expected : The alt3pram function represents asynchronous memory 
//                    or memory with synchronous inputs and/or outputs.
//                    (note: ^ below indicates posedge)
//
//                    [ Synchronous Write to Memory (all inputs registered) ]
//                    inclock    inclocken    wren    Function   
//                      X           L           L     No change. 
//                     not ^        H           H     No change. 
//                      ^           L           X     No change. 
//                      ^           H           H     The memory location 
//                                                    pointed to by wraddress[] 
//                                                    is loaded with data[]. 
//
//                    [ Synchronous Read from Memory ] 
//                    inclock  inclocken  rden_a/rden_b  Function  
//                       X         L            L        No change. 
//                     not ^       H            H        No change. 
//                       ^         L            X        No change. 
//                       ^         H            H        The q_a[]/q_b[]port 
//                                                       outputs the contents of 
//                                                       the memory location. 
//
//                   [ Asynchronous Memory Operations ]
//                   wren     Function  
//                    L       No change. 
//                    H       The memory location pointed to by wraddress[] is 
//                            loaded with data[] and controlled by wren.
//                            The output q_a[] is asynchronous and reflects 
//                            the memory location pointed to by rdaddress_a[]. 
//
//-----------------------------------------------------------------------------+

`timescale 1 ps / 1 ps
`define DEV_APEX20KE  "APEX20KE"
`define DEV_APEX20K   "APEX20K"

module alt3pram (wren, data, wraddress, inclock, inclocken, 
                 rden_a, rden_b, rdaddress_a, rdaddress_b, 
                 outclock, outclocken, aclr, qa, qb);

    // ---------------------
    // PARAMETER DECLARATION
    // ---------------------

    parameter width            = 1;             // data[], qa[] and qb[]
    parameter widthad          = 1;             // rdaddress_a,rdaddress_b,wraddress
    parameter numwords         = 0;             // words stored in memory
    parameter lpm_file         = "UNUSED";      // name of mif or hex file
    parameter lpm_hint         = "USE_EAB=ON";  // non-LPM parameters (Altera)
    parameter indata_reg       = "UNREGISTERED";// clock used by data[] port
    parameter indata_aclr      = "OFF";         // aclr affects data[]? 
    parameter write_reg        = "UNREGISTERED";// clock used by wraddress & wren
    parameter write_aclr       = "OFF";         // aclr affects wraddress?
    parameter rdaddress_reg_a  = "UNREGISTERED";// clock used by readdress_a
    parameter rdaddress_aclr_a = "OFF";         // aclr affects rdaddress_a?
    parameter rdcontrol_reg_a  = "UNREGISTERED";// clock used by rden_a
    parameter rdcontrol_aclr_a = "OFF";         // aclr affects rden_a?
    parameter rdaddress_reg_b  = "UNREGISTERED";// clock used by readdress_b
    parameter rdaddress_aclr_b = "OFF";         // aclr affects rdaddress_b?
    parameter rdcontrol_reg_b  = "UNREGISTERED";// clock used by rden_b
    parameter rdcontrol_aclr_b = "OFF";         // aclr affects rden_b?
    parameter outdata_reg_a    = "UNREGISTERED";// clock used by qa[]
    parameter outdata_aclr_a   = "OFF";         // aclr affects qa[]?
    parameter outdata_reg_b    = "UNREGISTERED";// clock used by qb[]
    parameter outdata_aclr_b   = "OFF";         // aclr affects qb[]?
    parameter intended_device_family = `DEV_APEX20KE;
    parameter lpm_type               = "alt3pram";

    // -------------
    // the following behaviour come in effect when RAM is implemented in EAB/ESB

    // This is the flag to indicate if the memory is constructed using EAB/ESB:
    //     A write request requires both rising and falling edge of the clock 
    //     to complete. First the data will be clocked in (registered) at the 
    //     rising edge and will not be written into the ESB/EAB memory until 
    //     the falling edge appears on the the write clock.
    //     No such restriction if the memory is constructed using LCs.
    parameter write_at_low_clock = ((write_reg == "INCLOCK") &&
                                    (lpm_hint == "USE_EAB=ON")) ? 1 : 0;

    // The read ports will not hold any value (zero) if rden is low. This 
    //     behavior only apply to memory constructed using EAB/ESB, but not LCs.
    parameter rden_low_output_0  = ((intended_device_family == `DEV_APEX20K) &&
                                    (lpm_hint == "USE_EAB=ON")) ? 1 : 0;
 
    // ----------------
    // PORT DECLARATION
    // ----------------
   
    // data input ports
    input [width-1:0]      data;

    // control signals
    input [widthad-1:0]    wraddress;
    input [widthad-1:0]    rdaddress_a;
    input [widthad-1:0]    rdaddress_b;

    input                  wren;
    input                  rden_a;
    input                  rden_b;

    // clock ports
    input                  inclock;
    input                  outclock;

    // clock enable ports
    input                  inclocken;
    input                  outclocken;

    // clear ports
    input                  aclr;

    // OUTPUT PORTS
    output [width-1:0]     qa;
    output [width-1:0]     qb;

    // ---------------
    // REG DECLARATION
    // ---------------
    reg  [width-1:0]       mem_data [(1<<widthad)-1:0];
    wire [width-1:0]       i_data_reg;
    wire [width-1:0]       i_data_tmp;
    reg  [width-1:0]       i_qa_reg;
    reg  [width-1:0]       i_qa_tmp;
    reg  [width-1:0]       i_qb_reg;
    reg  [width-1:0]       i_qb_tmp;

    reg  [width-1:0]       i_data_hi;
    reg  [width-1:0]       i_data_lo;

    wire [widthad-1:0]     i_wraddress_reg;
    wire [widthad-1:0]     i_wraddress_tmp;

    reg  [widthad-1:0]     i_wraddress_hi;
    reg  [widthad-1:0]     i_wraddress_lo;
    
    reg  [widthad-1:0]     i_rdaddress_reg_a;
    wire [widthad-1:0]     i_rdaddress_tmp_a;

    reg  [widthad-1:0]     i_rdaddress_reg_b;
    wire [widthad-1:0]     i_rdaddress_tmp_b;

    wire                   i_wren_reg;
    wire                   i_wren_tmp;
    reg                    i_rden_reg_a;
    wire                   i_rden_tmp_a;
    reg                    i_rden_reg_b;
    wire                   i_rden_tmp_b;

    reg                    i_wren_hi;
    reg                    i_wren_lo;

    reg [8*256:1]          ram_initf;       // max RAM size (Apex20KE) 8*256=2048

    // -------------------
    // INTEGER DECLARATION
    // -------------------
    integer                i;
    integer                i_numwords;

    // --------------------------------
    // Tri-State and Buffer DECLARATION
    // --------------------------------
    tri0                   inclock;
    tri1                   inclocken;
    tri0                   outclock;
    tri1                   outclocken;
    tri0                   wren;
    tri1                   rden_a;
    tri1                   rden_b;
    tri0                   aclr;
               

    // -----------------------------------------------------------
    // Initialization block for all internal signals and registers
    // -----------------------------------------------------------
    initial
    begin
        // Check for invalid parameters
        if (width <= 0)
            $display("Error: width parameter must be greater than 0.");
        if (widthad <= 0)
            $display("Error: widthad parameter must be greater than 0.");
        if (numwords < 0)
            $display("Error: numwords parameter must be greater than 0.");

        if ((indata_reg    !== "INCLOCK" ) && (indata_reg    !== "UNREGISTERED"))
            $display("Error: indata_reg must be INCLOCK or UNREGISTERED.");
        if ((outdata_reg_a !== "OUTCLOCK") && (outdata_reg_a !== "UNREGISTERED"))
            $display("Error: outdata_reg_a must be OUTCLOCK or UNREGISTERED.");
        if ((outdata_reg_b !== "OUTCLOCK") && (outdata_reg_b !== "UNREGISTERED"))
            $display("Error: outdata_reg_b must be OUTCLOCK or UNREGISTERED.");
        if ((write_reg     !== "INCLOCK" ) && (write_reg     !== "UNREGISTERED"))
            $display("Error: write_reg must be INCLOCK or UNREGISTERED.");

        if ((rdaddress_reg_a !== "INCLOCK") && (rdaddress_reg_a !== "OUTCLOCK") && 
            (rdaddress_reg_a !== "UNREGISTERED"))
            $display("Error: rdaddress_reg_a must be IN/OUTCLOCK or UNREGISTERED.");
        if ((rdcontrol_reg_a !== "INCLOCK") && (rdcontrol_reg_a !== "OUTCLOCK") && 
            (rdcontrol_reg_a !== "UNREGISTERED"))
            $display("Error: rdcontrol_reg_a must be IN/OUTCLOCK or UNREGISTERED.");
        if ((rdaddress_reg_b !== "INCLOCK") && (rdaddress_reg_b !== "OUTCLOCK") && 
            (rdaddress_reg_b !== "UNREGISTERED"))
            $display("Error: rdaddress_reg_b must be IN/OUTCLOCK or UNREGISTERED.");
        if ((rdcontrol_reg_b !== "INCLOCK") && (rdcontrol_reg_b !== "OUTCLOCK") && 
            (rdcontrol_reg_b !== "UNREGISTERED"))
            $display("Error: rdcontrol_reg_b must be IN/OUTCLOCK or UNREGISTERED.");
                
        if ((indata_aclr    !== "ON") && (indata_aclr    !== "OFF"))
            $display("Error: indata_aclr must be ON or OFF.");
        if ((outdata_aclr_a !== "ON") && (outdata_aclr_a !== "OFF"))
            $display("Error: outdata_aclr_a must be ON or OFF.");
        if ((outdata_aclr_b !== "ON") && (outdata_aclr_b !== "OFF"))
            $display("Error: outdata_aclr_b must be ON or OFF.");
        if ((write_aclr     !== "ON") && (write_aclr     !== "OFF"))
            $display("Error: write_aclr must be ON or OFF.");
        
        if ((rdaddress_aclr_a !== "ON") && (rdaddress_aclr_a !== "OFF"))
            $display("Error: rdaddress_aclr_a must be ON or OFF.");
        if ((rdcontrol_aclr_a !== "ON") && (rdcontrol_aclr_a !== "OFF"))
            $display("Error: rdcontrol_aclr_a must be ON or OFF.");
        if ((rdaddress_aclr_b !== "ON") && (rdaddress_aclr_b !== "OFF"))
            $display("Error: rdaddress_aclr_b must be ON or OFF.");
        if ((rdcontrol_aclr_b !== "ON") && (rdcontrol_aclr_b !== "OFF"))
            $display("Error: rdcontrol_aclr_b must be ON or OFF.");

        // Initialize mem_data to '0' if no RAM init file is specified
        i_numwords = (numwords) ? numwords : 1<<widthad;
        if (lpm_file == "UNUSED")
            for (i=0; i<i_numwords; i=i+1)
                mem_data[i] = 0;
        else
        begin
`ifdef NO_PLI
            $readmemh(lpm_file, mem_data);
`else
            $convert_hex2ver(lpm_file, width, ram_initf);
            $readmemh(ram_initf, mem_data);
`endif
        end

        // Initialize registers
        i_rdaddress_reg_a  = 0;
        i_rdaddress_reg_b  = 0;
        i_qa_reg           = 0;
        i_qb_reg           = 0;
    end

    //=========
    // Clocks
    //=========

    // At posedge of the write clock:
    // All input ports values (data, address and control) are 
    // clocked in from physical ports to internal variables
    //     Write Cycle: i_*_hi
    //     Read  Cycle: i_*_reg
    always @(posedge inclock)
    begin
        if (indata_reg == "INCLOCK")
        begin
            if ((aclr == 1) && (indata_aclr == "ON"))
                i_data_hi <= 0;
            else if ((inclocken == 1) && ($time > 0))
                i_data_hi <= data;
        end

        if (write_reg == "INCLOCK")
        begin
            if ((aclr == 1) && (write_aclr == "ON"))
            begin
                i_wraddress_hi <= 0;
                i_wren_hi <= 0;
            end
            else if ((inclocken == 1) && ($time > 0))
            begin       
                i_wraddress_hi <= wraddress;
                i_wren_hi <= wren;
            end
        end

        if (rdaddress_reg_a == "INCLOCK")
        begin
            if ((aclr == 1) && (rdaddress_aclr_a == "ON"))
                i_rdaddress_reg_a <= 0;
            else if ((inclocken == 1) && ($time > 0))
                i_rdaddress_reg_a <= rdaddress_a;
        end

        if (rdcontrol_reg_a == "INCLOCK")
        begin
            if ((aclr == 1) && (rdcontrol_aclr_a == "ON"))
                i_rden_reg_a <= 0;
            else if ((inclocken == 1) && ($time > 0))
                i_rden_reg_a <= rden_a;
        end

        if (rdaddress_reg_b == "INCLOCK")
        begin
            if ((aclr == 1) && (rdaddress_aclr_b == "ON"))
                i_rdaddress_reg_b <= 0;
            else if ((inclocken == 1) && ($time > 0))
                i_rdaddress_reg_b <= rdaddress_b;
        end

        if (rdcontrol_reg_b == "INCLOCK")
        begin
            if ((aclr == 1) && (rdcontrol_aclr_b == "ON"))
                i_rden_reg_b <= 0;
            else if ((inclocken == 1) && ($time > 0))
                i_rden_reg_b <= rden_b;
        end
    end  // End of always block: @(posedge inclock)


    // At negedge of the write clock:
    // Write Cycle: since internally data only completed written on memory
    //              at the falling edge of write clock, the "write" related 
    //              data, address and controls need to be shift to another 
    //              varibles (i_*_hi -> i_*_lo) during falling edge.
    always @(negedge inclock)
    begin
        if (indata_reg == "INCLOCK")
        begin
            if ((aclr == 1) && (indata_aclr == "ON"))
                i_data_lo <= 0;
            else if ($time > 0)
                i_data_lo <= i_data_hi;
        end

        if (write_reg == "INCLOCK")
        begin
            if ((aclr == 1) && (write_aclr == "ON"))
            begin
                i_wraddress_lo <= 0;
                i_wren_lo <= 0;
            end
            else if ($time > 0)
            begin
                i_wraddress_lo <= i_wraddress_hi;
                i_wren_lo <= i_wren_hi;
            end
        end
    end  // End of always block: @(negedge inclock)


    // At posedge of read clock: 
    // Read Cycle: This block is valid only if the operating mode is
    //             in "Seperate Clock Mode". All read data, address 
    //             and control are clocked out from internal vars 
    //             (i_*_reg) to output port.
    always @(posedge outclock)
    begin
        if (outdata_reg_a == "OUTCLOCK")
        begin
            if ((aclr == 1) && (outdata_aclr_a == "ON"))
                i_qa_reg <= 0;
            else if ((outclocken == 1) && ($time > 0))
                i_qa_reg <= i_qa_tmp;
        end

        if (outdata_reg_b == "OUTCLOCK")
        begin
            if ((aclr == 1) && (outdata_aclr_b == "ON"))
                i_qb_reg <= 0;
            else if ((outclocken == 1) && ($time > 0))
                i_qb_reg <= i_qb_tmp;
        end

        if (rdaddress_reg_a == "OUTCLOCK")
        begin
            if ((aclr == 1) && (rdaddress_aclr_a == "ON"))
                i_rdaddress_reg_a <= 0;
            else if ((outclocken == 1) && ($time > 0))
                i_rdaddress_reg_a <= rdaddress_a;
        end

        if (rdcontrol_reg_a == "OUTCLOCK")
        begin
            if ((aclr == 1) && (rdcontrol_aclr_a == "ON"))
                i_rden_reg_a <= 0;
            else if ((outclocken == 1) && ($time > 0))
                i_rden_reg_a <= rden_a;
        end

        if (rdaddress_reg_b == "OUTCLOCK")
        begin
            if ((aclr == 1) && (rdaddress_aclr_b == "ON"))
                i_rdaddress_reg_b <= 0;
            else if ((outclocken == 1) && ($time > 0))
                i_rdaddress_reg_b <= rdaddress_b;
        end

        if (rdcontrol_reg_b == "OUTCLOCK")
        begin
            if ((aclr == 1) && (rdcontrol_aclr_b == "ON"))
                i_rden_reg_b <= 0;
            else if ((outclocken == 1) && ($time > 0))
                i_rden_reg_b <= rden_b;
        end
    end  // End of always block: @(posedge outclock)


    //=========
    // Memory
    //=========

    always @(i_data_tmp or i_wren_tmp or i_wraddress_tmp or 
             i_rden_tmp_a or i_rdaddress_tmp_a or 
             i_rden_tmp_b or i_rdaddress_tmp_b)
    begin
        //
        // This is where data is being write to the internal memory: mem_data[]
        //
        #1 if (i_wren_tmp == 1)
            mem_data[i_wraddress_tmp] = i_data_tmp;

       // Triple-Port Ram (alt3pram) has one write port and two read ports (a and b)
       // Below is the operation to read data from internal memory (mem_data[])
       // to the output port (i_qa_tmp or i_qb_tmp)
       // Note: i_q*_tmp will serve as the var directly link to the physical 
       //       output port q* if alt3pram is operate in "Shared Clock Mode", 
       //       else data read from i_q*_tmp will need to be latched to i_q*_reg
       //       through outclock before it is fed to the output port q* (qa or qb).
        if (i_rden_tmp_a == 1)
            i_qa_tmp = #1 mem_data[i_rdaddress_tmp_a];
        else if (rden_low_output_0 == 1)
            i_qa_tmp = 0;

        if (i_rden_tmp_b == 1)
            i_qb_tmp = #1 mem_data[i_rdaddress_tmp_b];
        else if (rden_low_output_0 == 1)
            i_qb_tmp = 0;

    end


    //=======
    // Sync
    //=======

    assign  i_wraddress_reg   = ((aclr == 1) && (write_aclr == "ON")) ?
                                    0 : (write_at_low_clock ? 
                                        i_wraddress_lo : i_wraddress_hi);

    assign  i_wren_reg        = ((aclr == 1) && (write_aclr == "ON")) ?
                                    0 : ((write_at_low_clock) ? 
                                        i_wren_lo : i_wren_hi);

    assign  i_data_reg        = ((aclr == 1) && (indata_aclr == "ON")) ?
                                    0 : ((write_at_low_clock) ? 
                                        i_data_lo : i_data_hi);

    assign  i_wraddress_tmp   = ((aclr == 1) && (write_aclr == "ON")) ?
                                    0 : ((write_reg == "INCLOCK") ? 
                                        i_wraddress_reg : wraddress);
    
    assign  i_rdaddress_tmp_a = ((aclr == 1) && (rdaddress_aclr_a == "ON")) ?
                                    0 : (((rdaddress_reg_a == "INCLOCK") || 
                                          (rdaddress_reg_a == "OUTCLOCK")) ?
                                        i_rdaddress_reg_a : rdaddress_a);

    assign  i_rdaddress_tmp_b = ((aclr == 1) && (rdaddress_aclr_b == "ON")) ?
                                    0 : (((rdaddress_reg_b == "INCLOCK") || 
                                          (rdaddress_reg_b == "OUTCLOCK")) ?
                                        i_rdaddress_reg_b : rdaddress_b);

    assign  i_wren_tmp        = ((aclr == 1) && (write_aclr == "ON")) ?
                                    0 : ((write_reg == "INCLOCK") ?
                                        i_wren_reg : wren);

    assign  i_rden_tmp_a      = ((aclr == 1) && (rdcontrol_aclr_a == "ON")) ?
                                    0 : (((rdcontrol_reg_a == "INCLOCK") || 
                                          (rdcontrol_reg_a == "OUTCLOCK")) ?
                                        i_rden_reg_a : rden_a);

    assign  i_rden_tmp_b      = ((aclr == 1) && (rdcontrol_aclr_b == "ON")) ?
                                    0 : (((rdcontrol_reg_b == "INCLOCK") || 
                                          (rdcontrol_reg_b == "OUTCLOCK")) ?
                                        i_rden_reg_b : rden_b);

    assign  i_data_tmp        = ((aclr == 1) && (indata_aclr == "ON")) ?
                                    0 : ((indata_reg == "INCLOCK") ?
                                        i_data_reg : data);
    
    assign  qa                = ((aclr == 1) && (outdata_aclr_a == "ON")) ?
                                    0 : ((outdata_reg_a == "OUTCLOCK") ?
                                        i_qa_reg : i_qa_tmp);

    assign  qb                = ((aclr == 1) && (outdata_aclr_b == "ON")) ?
                                    0 : ((outdata_reg_b == "OUTCLOCK") ?
                                        i_qb_reg : i_qb_tmp);

endmodule // end of ALT3PRAM


// START_MODULE_NAME------------------------------------------------------------
//
// Module Name      : ALTQPRAM
//
// Description      : Asynchronous quad ports memory or memory with synchronous
//                    inputs and/or outputs
//
// Limitation       :
//
// Results expected : [Synchronous Write to Memory (all inputs registered)]
//                    inclock      inclocken      wren      Function
//                      X            L              L       No change
//                     not           H              H       No change
//                    posedge        L              X       No change
//                    posedge        H              H       Memory content updated
//
//                    [Synchronous Read from Memory]
//                    inclock      inclocken      rden      Function
//                      X            L              L       No change
//                     not           H              H       No change
//                    posedge        L              X       No change.
//                    posedge        H              H       Memory content showed
//                                                          at the output port
//
//                    [Asynchronous Memory Operations]
//                    wren      Function
//                      L       No change
//                      H       Memory content updated
//                              Memory content showed
//                              at the output port
//
// END_MODULE_NAME--------------------------------------------------------------

`timescale 1 ps / 1 ps

// BEGINNING OF MODULE

// MODULE DECLARATION

module altqpram (
                 wren_a,
                 wren_b,
                 data_a,
                 data_b,
                 wraddress_a,
                 wraddress_b,
                 inclock_a,
                 inclock_b,
                 inclocken_a,
                 inclocken_b,
                 rden_a,
                 rden_b,
                 rdaddress_a,
                 rdaddress_b,
                 outclock_a,
                 outclock_b,
                 outclocken_a,
                 outclocken_b,
                 inaclr_a,
                 inaclr_b,
                 outaclr_a,
                 outaclr_b,
                 q_a,
                 q_b
                );

// GLOBAL PARAMETER DECLARATION

    parameter operation_mode = "QUAD_PORT";

    // Port A write parameters
    parameter width_write_a = 1;
    parameter widthad_write_a = 1;
    parameter numwords_write_a = 0;
    parameter indata_reg_a = "INCLOCK_A";
    parameter indata_aclr_a = "INACLR_A";
    parameter wrcontrol_wraddress_reg_a = "INCLOCK_A";
    parameter wrcontrol_aclr_a = "INACLR_A";
    parameter wraddress_aclr_a = "INACLR_A";

    // Port B write parameters
    parameter width_write_b = 1;
    parameter widthad_write_b = 1;
    parameter numwords_write_b = 0;
    parameter indata_reg_b = "INCLOCK_B";
    parameter indata_aclr_b = "INACLR_B";
    parameter wrcontrol_wraddress_reg_b = "INCLOCK_B";
    parameter wrcontrol_aclr_b = "INACLR_B";
    parameter wraddress_aclr_b = "INACLR_B";

    // Port A read parameters
    parameter width_read_a = 1;
    parameter widthad_read_a = 1;
    parameter numwords_read_a = 0;
    parameter rdcontrol_reg_a = "OUTCLOCK_A";
    parameter rdcontrol_aclr_a = "OUTACLR_A";
    parameter rdaddress_reg_a = "OUTCLOCK_A";
    parameter rdaddress_aclr_a = "OUTACLR_A";
    parameter outdata_reg_a = "UNREGISTERED";
    parameter outdata_aclr_a = "OUTACLR_A";

    // Port B read parameters
    parameter width_read_b = 1;
    parameter widthad_read_b = 1;
    parameter numwords_read_b = 0;
    parameter rdcontrol_reg_b = "OUTCLOCK_B";
    parameter rdcontrol_aclr_b = "OUTACLR_B";
    parameter rdaddress_reg_b = "OUTCLOCK_B";
    parameter rdaddress_aclr_b = "OUTACLR_B";
    parameter outdata_reg_b = "UNREGISTERED";
    parameter outdata_aclr_b = "OUTACLR_B";

    parameter init_file = "UNUSED";
    parameter lpm_hint = "UNUSED";
    parameter lpm_type = "altqpram";

// INPUT PORT DECLARATION

    input  wren_a;
    input  wren_b;
    input  rden_a;
    input  rden_b;
    input  [width_write_a - 1 : 0] data_a;
    input  [width_write_b - 1 : 0] data_b;
    input  [widthad_write_a - 1 : 0] wraddress_a;
    input  [widthad_write_b - 1 : 0] wraddress_b;
    input  inclock_a;
    input  inclock_b;
    input  inclocken_a;
    input  inclocken_b;
    input  [widthad_read_a - 1 : 0] rdaddress_a;
    input  [widthad_read_b - 1 : 0] rdaddress_b;
    input  outclock_a;
    input  outclock_b;
    input  outclocken_a;
    input  outclocken_b;
    input  inaclr_a;
    input  inaclr_b;
    input  outaclr_a;
    input  outaclr_b;

// OUTPUT PORT DECLARATION

    output [width_read_a - 1 : 0] q_a;
    output [width_read_b - 1 : 0] q_b;

// INTERNAL REGISTERS DECLARATION

    reg [width_read_a - 1 : 0] mem_data [0 : (1 << widthad_read_a) - 1];
    reg [width_write_a - 1 : 0] mem_data_w [0 : (1 << widthad_write_a) - 1];
    reg [width_write_a - 1 : 0] i_data_reg_a;
    reg [width_write_a - 1 : 0] i_data_tmp_a;
    reg [width_write_a - 1 : 0] i_data2_a;
    reg [width_write_a - 1 : 0] temp_wa;
    reg [width_write_b - 1 : 0] i_data_reg_b;
    reg [width_write_b - 1 : 0] i_data_tmp_b;
    reg [width_write_b - 1 : 0] i_data2_b;
    reg [width_write_a - 1 : 0] i_data_hi_a;
    reg [width_write_a - 1 : 0] i_data_lo_a;
    reg [width_write_b - 1 : 0] i_data_hi_b;
    reg [width_write_b - 1 : 0] i_data_lo_b;
    reg [width_read_a - 1 : 0] i_q_reg_a;
    reg [width_read_a - 1 : 0] i_q_tmp_a;
    reg [width_read_a - 1 : 0] temp_ra;
    reg [width_read_b - 1 : 0] i_q_reg_b;
    reg [width_read_b - 1 : 0] i_q_tmp_b;
    reg [widthad_write_a - 1 : 0] i_wraddress_reg_a;
    reg [widthad_write_a - 1 : 0] i_wraddress_tmp_a;
    reg [widthad_write_a - 1 : 0] i_wraddress2_a;
    reg [widthad_write_b - 1 : 0] i_wraddress_reg_b;
    reg [widthad_write_b - 1 : 0] i_wraddress_tmp_b;
    reg [widthad_write_b - 1 : 0] i_wraddress2_b;
    reg [widthad_write_a - 1 : 0] i_wraddress_hi_a;
    reg [widthad_write_a - 1 : 0] i_wraddress_lo_a;
    reg [widthad_write_b - 1 : 0] i_wraddress_hi_b;
    reg [widthad_write_b - 1 : 0] i_wraddress_lo_b;
    reg [widthad_read_a - 1 : 0] i_rdaddress_reg_a;
    reg [widthad_read_a - 1 : 0] i_rdaddress_tmp_a;
    reg [widthad_read_b - 1 : 0] i_rdaddress_reg_b;
    reg [widthad_read_b - 1 : 0] i_rdaddress_tmp_b;
    reg [8*256 : 1] ram_initf;
    reg i_wren_reg_a;
    reg i_wren_tmp_a;
    reg i_wren2_a;
    reg i_rden_reg_a;
    reg i_rden_tmp_a;
    reg i_wren_reg_b;
    reg i_wren_tmp_b;
    reg i_wren2_b;
    reg i_rden_reg_b;
    reg i_rden_tmp_b;
    reg i_wren_hi_a;
    reg i_wren_lo_a;
    reg i_wren_hi_b;
    reg i_wren_lo_b;
    reg i_indata_aclr_a;
    reg i_wraddress_aclr_a;
    reg i_wrcontrol_aclr_a;
    reg i_indata_aclr_b;
    reg i_wraddress_aclr_b;
    reg i_wrcontrol_aclr_b;
    reg i_outdata_aclr_a;
    reg i_rdaddress_aclr_a;
    reg i_rdcontrol_aclr_a;
    reg i_outdata_aclr_b;
    reg i_rdaddress_aclr_b;
    reg i_rdcontrol_aclr_b;
    reg mem_updated;
    reg clk_a_trigger;
    reg clk_b_trigger;
    reg write_at_low_clock_a;
    reg write_at_low_clock_b;

// LOCAL INTEGER DECLARATION

    integer i_numwords_read_a;
    integer i_numwords_read_b;
    integer i_numwords_write_a;
    integer i_numwords_write_b;
    integer write_ratio;
    integer read_ratio;
    integer read_write_ratio;
    integer i;
    integer j;
    integer k;
    integer m;
    integer n;
    integer p;
    integer op_mode;
    integer simultaneous_write;

// INTERNAL TRI DECLARATION

    tri0 wren_a;
    tri0 wren_b;
    tri1 rden_a;
    tri1 rden_b;
    tri0 inclock_a;
    tri0 inclock_b;
    tri0 outclock_a;
    tri0 outclock_b;
    tri1 inclocken_a;
    tri1 inclocken_b;
    tri1 outclocken_a;
    tri1 outclocken_b;
    tri0 inaclr_a;
    tri0 inaclr_b;
    tri0 outaclr_a;
    tri0 outaclr_b;

// INTERNAL BUF

    buf (i_wren_a, wren_a);
    buf (i_wren_b, wren_b);
    buf (i_rden_a, rden_a);
    buf (i_rden_b, rden_b);
    buf (i_inclock_a, inclock_a);
    buf (i_inclock_b, inclock_b);
    buf (i_inclocken_a, inclocken_a);
    buf (i_inclocken_b, inclocken_b);
    buf (i_outclock_a, outclock_a);
    buf (i_outclock_b, outclock_b);
    buf (i_outclocken_a, outclocken_a);
    buf (i_outclocken_b, outclocken_b);
    buf (i_inaclr_a, inaclr_a);
    buf (i_inaclr_b, inaclr_b);
    buf (i_outaclr_a, outaclr_a);
    buf (i_outaclr_b, outaclr_b);


// INITIAL CONSTRUCT BLOCK

    initial
    begin
        // Check for operation mode
        //
        // This is the table for encoding of op_mode.
        //       << PORT A >>      |  << PORT B >>
        //      RD  RD  WR  WR     | RD  RD  WR  WR
        //      EN ADDR EN ADDR %6 | EN ADDR EN ADDR %5
        // QP    o   o   o   o   3 |  o   o   o   o   3
        // BDP           o   o   2 |          o   o   2
        // DP    o   o   o   o   3 |                  0
        // SP            o   o   2 |                  0
        // ROM       o           1 |                  0
        //

        op_mode = 0;

        if (operation_mode == "QUAD_PORT")
            op_mode = 3;
        else if (operation_mode == "BIDIR_DUAL_PORT")
            op_mode = 2;
        else if (operation_mode == "DUAL_PORT")
            op_mode = 15;
        else if (operation_mode == "SINGLE_PORT")
            op_mode = 20;
        else if (operation_mode == "ROM")
            op_mode = 25;
        else
        begin
            $display("Error! operation_mode parameter is invalid.");
            $stop;
        end

        // Check for invalid parameters

        if ((width_write_a <= 0) && ((op_mode % 6) > 1))
        begin
            $display("Error! width_write_a parameter must be greater than 0.");
            $stop;
        end

        if ((width_write_b <= 0) && ((op_mode % 5) > 1))
        begin
            $display("Error! width_write_b parameter must be greater than 0.");
            $stop;
        end

        if ((widthad_write_a <= 0) && ((op_mode % 6) > 1))
        begin
            $display("Error! widthad_write_a parameter must be greater than 0.");
            $stop;
        end

        if ((widthad_write_b <= 0) && ((op_mode % 5) > 1))
        begin
            $display("Error! widthad_write_b parameter must be greater than 0.");
            $stop;
        end

        if ((width_read_a <= 0) && ((op_mode % 6) > 0) && ((op_mode % 6) != 2))
        begin
            $display("Error! width_read_a parameter must be greater than 0.");
            $stop;
        end

        if ((width_read_b <= 0) && ((op_mode % 5) > 0) && ((op_mode % 5) != 2))
        begin
            $display("Error! width_read_b parameter must be greater than 0.");
            $stop;
        end

        if ((widthad_read_a <= 0) && ((op_mode % 6) > 0) && ((op_mode % 6) != 2))
        begin
            $display("Error! widthad_read_a parameter must be greater than 0.");
            $stop;
        end

        if ((widthad_read_b <= 0) && ((op_mode % 5) > 0) && ((op_mode % 5) != 2))
        begin
            $display("Error! widthad_read_b parameter must be greater than 0.");
            $stop;
        end

        if ((indata_reg_a !== "INCLOCK_A") && (indata_reg_a !== "UNREGISTERED") &&
            ((op_mode % 6) > 0))
        begin
            $display("Error! indata_reg_a must be INCLOCK_A or UNREGISTERED.");
            $stop;
        end

        if ((indata_reg_b !== "INCLOCK_B") && (indata_reg_b !== "UNREGISTERED") &&
            ((op_mode % 5) > 0))
        begin
            $display("Error! indata_reg_b must be INCLOCK_B or UNREGISTERED.");
            $stop;
        end

        if ((outdata_reg_a !== "INCLOCK_A") && (outdata_reg_a !== "OUTCLOCK_A") &&
            (outdata_reg_a !== "UNREGISTERED") && ((op_mode % 6) > 0))
        begin
            $display("Error! outdata_reg_a must be INCLOCK_A, OUTCLOCK_A or UNREGISTERED.");
            $stop;
        end

        if ((outdata_reg_b !== "INCLOCK_B") &&
            (outdata_reg_b !== "OUTCLOCK_B") &&
            (outdata_reg_b !== "UNREGISTERED") && ((op_mode % 5) > 0))
        begin
            $display("Error! outdata_reg_b must be INCLOCK_B, OUTCLOCK_B or UNREGISTERED.");
            $stop;
        end

        if ((wrcontrol_wraddress_reg_a !== "INCLOCK_A") &&
            (wrcontrol_wraddress_reg_a !== "UNREGISTERED") && ((op_mode % 6) > 0))
        begin
            $display("Error! wrcontrol_wraddress_reg_a must be INCLOCK_A or UNREGISTERED.");
            $stop;
        end

        if ((wrcontrol_wraddress_reg_b !== "INCLOCK_B") &&
            (wrcontrol_wraddress_reg_b !== "UNREGISTERED") && ((op_mode % 5) > 0))
        begin
            $display("Error! wrcontrol_wraddress_reg_b must be INCLOCK_B or UNREGISTERED.");
            $stop;
        end

        if ((rdcontrol_reg_a !== "INCLOCK_A") &&
            (rdcontrol_reg_a !== "OUTCLOCK_A") &&
            (rdcontrol_reg_a !== "UNREGISTERED") && ((op_mode % 6) > 0))
        begin
            $display("Error! rdcontrol_reg_a must be INCLOCK_A, OUTCLOCK_A or UNREGISTERED.");
            $stop;
        end

        if ((rdcontrol_reg_b !== "INCLOCK_B") &&
            (rdcontrol_reg_b !== "OUTCLOCK_B") &&
            (rdcontrol_reg_b !== "UNREGISTERED") && ((op_mode % 5) > 0))
        begin
            $display("Error! rdcontrol_reg_b must be INCLOCK_B, OUTCLOCK_B or UNREGISTERED.");
            $stop;
        end

        if ((rdaddress_reg_a !== "INCLOCK_A") &&
            (rdaddress_reg_a !== "OUTCLOCK_A") &&
            (rdaddress_reg_a !== "UNREGISTERED") && ((op_mode % 6) > 0))
        begin
            $display("Error! rdaddress_reg_a must be INCLOCK_A, OUTCLOCK_A or UNREGISTERED.");
            $stop;
        end

        if ((rdaddress_reg_b !== "INCLOCK_B") &&
            (rdaddress_reg_b !== "OUTCLOCK_B") &&
            (rdaddress_reg_b !== "UNREGISTERED") && ((op_mode % 5) > 0))
        begin
            $display("Error! rdaddress_reg_b must be INCLOCK_B, OUTCLOCK_B or UNREGISTERED.");
            $stop;
        end

        if ((indata_aclr_a !== "INACLR_A") && (indata_aclr_a !== "NONE"))
        begin
            $display("Error! indata_aclr_a must be INACLR_A or NONE.");
            $stop;
        end

        if ((indata_aclr_b !== "INACLR_B") && (indata_aclr_b !== "NONE"))
        begin
            $display("Error! indata_aclr_b must be INACLR_B or NONE.");
            $stop;
        end

        if ((wrcontrol_aclr_a !== "INACLR_A") && (wrcontrol_aclr_a !== "NONE"))
        begin
            $display("Error! wrcontrol_aclr_a must be INACLR_A or NONE.");
            $stop;
        end

        if ((wrcontrol_aclr_b !== "INACLR_B") && (wrcontrol_aclr_b !== "NONE"))
        begin
            $display("Error! wrcontrol_aclr_b must be INACLR_B or NONE.");
            $stop;
        end

        if ((wraddress_aclr_a !== "INACLR_A") && (wraddress_aclr_a !== "NONE"))
        begin
            $display("Error! wraddress_aclr_a must be INACLR_A or NONE.");
            $stop;
        end

        if ((wraddress_aclr_b !== "INACLR_B") && (wraddress_aclr_b !== "NONE"))
        begin
            $display("Error! wraddress_aclr_b must be INACLR_B or NONE.");
            $stop;
        end

        if ((outdata_aclr_a !== "INACLR_A") &&
            (outdata_aclr_a !== "OUTACLR_A") &&
            (outdata_aclr_a !== "NONE"))
        begin
            $display("Error! outdata_aclr_a must be INACLR_A, OUTACLR_A or NONE.");
            $stop;
        end

        if ((outdata_aclr_b !== "INACLR_B") &&
            (outdata_aclr_b !== "OUTACLR_B") &&
            (outdata_aclr_b !== "NONE"))
        begin
            $display("Error! outdata_aclr_b must be INACLR_B, OUTACLR_B or NONE.");
            $stop;
        end

        if ((rdcontrol_aclr_a !== "INACLR_A") &&
            (rdcontrol_aclr_a !== "OUTACLR_A") &&
            (rdcontrol_aclr_a !== "NONE"))
        begin
            $display("Error! rdcontrol_aclr_a must be INACLR_A, OUTACLR_A or NONE.");
            $stop;
        end

        if ((rdcontrol_aclr_b !== "INACLR_B") &&
            (rdcontrol_aclr_b !== "OUTACLR_B") &&
            (rdcontrol_aclr_b !== "NONE"))
        begin
            $display("Error! rdcontrol_aclr_b must be INACLR_B, OUTACLR_B or NONE.");
            $stop;
        end

        if ((rdaddress_aclr_a !== "INACLR_A") &&
            (rdaddress_aclr_a !== "OUTACLR_A") &&
            (rdaddress_aclr_a !== "NONE"))
        begin
            $display("Error! rdaddress_aclr_a must be INACLR_A, OUTACLR_A or NONE.");
            $stop;
        end

        if ((rdaddress_aclr_b !== "INACLR_B") &&
            (rdaddress_aclr_b !== "OUTACLR_B") &&
            (rdaddress_aclr_b !== "NONE"))
        begin
            $display("Error! rdaddress_aclr_b must be INACLR_B, OUTACLR_B or NONE.");
            $stop;
        end

        if (((op_mode % 6) == 2) && (width_read_a != width_write_a))
        begin
            $display("Error! width_read_a must equal width_write_a.");
            $stop;
        end

        if (((op_mode % 5) == 2) && (width_read_b != width_write_b))
        begin
            $display("Error! width_read_b must equal width_write_b.");
            $stop;
        end

        i_numwords_read_a = (numwords_read_a) ? numwords_read_a : (1 << widthad_read_a);
        i_numwords_read_b = (numwords_read_b) ? numwords_read_b : (1 << widthad_read_b);
        i_numwords_write_a = (numwords_write_a) ?
                             numwords_write_a : (1 << widthad_write_a);
        i_numwords_write_b = (numwords_write_b) ?
                             numwords_write_b : (1 << widthad_write_b);

        if ((width_read_a*i_numwords_read_a != width_write_a*i_numwords_write_a) &&
            ((op_mode % 6) > 0) && ((op_mode % 6) != 2))
        begin
            $display("Error! RAM size for port A is inconsistant.");
            $stop;
        end

        if ((op_mode % 5) > 1)
        begin
            if ((width_read_b * i_numwords_read_b) != (width_write_b * i_numwords_write_b))
            begin
                $display("Error! RAM size for port B is inconsistant.");
                $stop;
            end

            if (width_read_a*i_numwords_read_a != width_read_b*i_numwords_read_b)
            begin
                $display("Error! RAM size between port A and port B is inconsistant.");
                $stop;
            end
        end

        read_ratio = (width_read_a > width_read_b) ?
                     (width_read_a / width_read_b)
                         : (width_read_b / width_read_a);
        write_ratio = (width_write_a > width_write_b) ?
                      (width_write_a / width_write_b)
                          : (width_write_b / width_write_a);
        read_write_ratio = (width_read_a > width_write_a) ?
                           (width_read_a / width_write_a)
                               : (width_write_a / width_read_a);

        // reset unused ratios to avoid incorrect checking
        if ((operation_mode != "QUAD_PORT") || (operation_mode != "BIDIR_DUAL_MODE"))
        begin
            read_ratio = 1;
            write_ratio = 1;
        end

        if (((read_ratio != 1) && (read_ratio != 2) && (read_ratio != 4) &&
             (read_ratio != 8) && (read_ratio != 16)) ||
            ((write_ratio != 1) && (write_ratio != 2) && (write_ratio != 4) &&
             (write_ratio != 8) && (write_ratio != 16)) ||
            ((read_write_ratio != 1) && (read_write_ratio != 2) &&
             (read_write_ratio != 4) && (read_write_ratio != 8) &&
             (read_write_ratio != 16)))
        begin
            $display("Error! RAM size for port A and / or port B is invalid.");
            $stop;
        end

        // Initialize mem_data
        if ((init_file == "UNUSED") || (init_file == ""))
        begin
            if ((op_mode % 6) == 1) // if ROM mode
            begin
                $display("Error! altqpram needs data file for memory initialization.\n");
                $stop;
            end
            else if ((op_mode % 6) == 2) // if SP or BDP mode
                for (i = 0; i < i_numwords_write_a; i = i + 1)
                    mem_data_w[i] = 0;
            else // if QP or DP mode
                for (i = 0; i < i_numwords_read_a; i = i + 1)
                    mem_data[i] = 0;
        end
        else
        begin
            if ((op_mode % 6) == 2) // if SP or BDP mode
            begin
`ifdef NO_PLI
                $readmemh(init_file, mem_data_w);
`else
                $convert_hex2ver(init_file, width_write_a, ram_initf);
                $readmemh(ram_initf, mem_data_w);
`endif
            end
            else // if ROM, QP or DP mode
            begin
`ifdef NO_PLI
                $readmemh(init_file, mem_data);
`else
                $convert_hex2ver(init_file, width_read_a, ram_initf);
                $readmemh(ram_initf, mem_data);
`endif
            end
        end

        mem_updated <= 0;
        write_at_low_clock_a <= (wrcontrol_wraddress_reg_a != "UNREGISTERED") ?
                               1 : 0;
        write_at_low_clock_b <= (wrcontrol_wraddress_reg_b != "UNREGISTERED") ?
                               1 : 0;

        // Initialize registers
        i_data_reg_a <= 0;
        i_data_tmp_a <= 0;
        i_data_reg_b <= 0;
        i_data_tmp_b <= 0;
        i_data_hi_a <= 0;
        i_data_lo_a <= 0;
        i_data_hi_b <= 0;
        i_data_lo_b <= 0;
        i_wraddress_reg_a <= 0;
        i_wraddress_tmp_a <= 0;
        i_wraddress_reg_b <= 0;
        i_wraddress_tmp_b <= 0;
        i_wraddress_reg_b <= 0;
        i_wraddress_tmp_b <= 0;
        i_wraddress_hi_a <= 0;
        i_wraddress_lo_a <= 0;
        i_wraddress_hi_b <= 0;
        i_wraddress_lo_b <= 0;
        i_rdaddress_reg_a <= 0;
        i_rdaddress_tmp_a <= 0;
        i_rdaddress_reg_b <= 0;
        i_rdaddress_tmp_b <= 0;
        i_wren_reg_a <= 0;
        i_wren_tmp_a <= 0;
        i_wren_hi_a <= 0;
        i_wren_lo_a <= 0;
        i_rden_reg_a <= 0;
        i_rden_tmp_a <= 0;
        i_wren_reg_b <= 0;
        i_wren_tmp_b <= 0;
        i_wren_hi_b <= 0;
        i_wren_lo_b <= 0;
        i_rden_reg_b <= 0;
        i_rden_tmp_b <= 0;
        i_q_reg_a <= 0;
        i_q_tmp_a <= 0;
        i_q_reg_b <= 0;
        i_q_tmp_b <= 0;

        i_data2_a <= 0;
        i_wren2_a <= 0;
        i_wraddress2_a <= 0;
        i_data2_b <= 0;
        i_wren2_b <= 0;
        i_wraddress2_b <= 0;
        clk_a_trigger <= 0;
        clk_b_trigger <= 0;
    end


    // This always block handle the aclr signals for port A
    always @(i_inaclr_a or i_outaclr_a)
    begin
        i_indata_aclr_a =
            ((i_inaclr_a == 1) && (indata_aclr_a == "INACLR_A")) ?
                ((indata_reg_a != "UNREGISTERED") ? 1 : 0) : 0;
        i_wraddress_aclr_a =
            ((i_inaclr_a == 1) && (wraddress_aclr_a == "INACLR_A")) ?
                ((wrcontrol_wraddress_reg_a != "UNREGISTERED") ? 1 : 0) : 0;
        i_wrcontrol_aclr_a =
            ((i_inaclr_a == 1) && (wrcontrol_aclr_a == "INACLR_A")) ?
                ((wrcontrol_wraddress_reg_a != "UNREGISTERED") ? 1 : 0) : 0;
        i_outdata_aclr_a =
            (((i_inaclr_a == 1) && (outdata_aclr_a == "INACLR_A")) ||
             ((i_outaclr_a == 1) && (outdata_aclr_a == "OUTACLR_A"))) ?
                ((outdata_reg_a != "UNREGISTERED") ? 1 : 0) : 0;
        i_rdaddress_aclr_a =
            (((i_inaclr_a == 1) && (rdaddress_aclr_a == "INACLR_A")) ||
             ((i_outaclr_a == 1) && (rdaddress_aclr_a == "OUTACLR_A"))) ?
                ((rdaddress_reg_a != "UNREGISTERED") ? 1 : 0) : 0;
        i_rdcontrol_aclr_a =
            (((i_inaclr_a == 1) && (rdcontrol_aclr_a == "INACLR_A")) ||
             ((i_outaclr_a == 1) && (rdcontrol_aclr_a == "OUTACLR_A"))) ?
                ((rdcontrol_reg_a != "UNREGISTERED") ? 1 : 0) : 0;
    end


    // This always block handle the aclr signals for port B
    always @(i_inaclr_b or i_outaclr_b)
    begin
        i_indata_aclr_b =
            ((i_inaclr_b == 1) && (indata_aclr_b == "INACLR_B")) ?
                ((indata_reg_b != "UNREGISTERED") ? 1 : 0) : 0;
        i_wraddress_aclr_b =
            ((i_inaclr_b == 1) && (wraddress_aclr_b == "INACLR_B")) ?
                ((wrcontrol_wraddress_reg_b != "UNREGISTERED") ? 1 : 0) : 0;
        i_wrcontrol_aclr_b =
            ((i_inaclr_b == 1) && (wrcontrol_aclr_b == "INACLR_B")) ?
                ((wrcontrol_wraddress_reg_b != "UNREGISTERED") ? 1 : 0) : 0;
        i_outdata_aclr_b =
            (((i_inaclr_b == 1) && (outdata_aclr_b == "INACLR_B")) ||
             ((i_outaclr_b == 1) && (outdata_aclr_b == "OUTACLR_B"))) ?
                ((outdata_reg_b != "UNREGISTERED") ? 1 : 0) : 0;
        i_rdaddress_aclr_b =
            (((i_inaclr_b == 1) && (rdaddress_aclr_b == "INACLR_B")) ||
             ((i_outaclr_b == 1) && (rdaddress_aclr_b == "OUTACLR_B"))) ?
                ((rdaddress_reg_b != "UNREGISTERED") ? 1 : 0) : 0;
        i_rdcontrol_aclr_b =
            (((i_inaclr_b == 1) && (rdcontrol_aclr_b == "INACLR_B")) ||
             ((i_outaclr_b == 1) && (rdcontrol_aclr_b == "OUTACLR_B"))) ?
                ((rdcontrol_reg_b != "UNREGISTERED") ? 1 : 0) : 0;
    end


    // This always block is to handle registered inputs and output for port A
    always @(posedge i_inclock_a)
    begin
        if (i_indata_aclr_a === 1)
            i_data_hi_a <= 0;
        else if (i_inclocken_a == 1)
            i_data_hi_a <= data_a;

        if (i_wraddress_aclr_a === 1)
            i_wraddress_hi_a <= 0;
        else if (i_inclocken_a == 1)
            i_wraddress_hi_a <= wraddress_a;

        if (i_wrcontrol_aclr_a === 1)
            i_wren_hi_a <= 0;
        else if (i_inclocken_a == 1)
            i_wren_hi_a <= i_wren_a;

        if (outdata_reg_a == "INCLOCK_A")
        begin
            if (i_outdata_aclr_a === 1)
                i_q_reg_a <= 0;
            else if (i_inclocken_a == 1)
                i_q_reg_a <= i_q_tmp_a;
        end

        if (rdaddress_reg_a == "INCLOCK_A")
        begin
            if (i_rdaddress_aclr_a === 1)
                i_rdaddress_reg_a <= 0;
            else if (i_inclocken_a == 1)
                i_rdaddress_reg_a <= rdaddress_a;
        end

        if (rdcontrol_reg_a == "INCLOCK_A")
        begin
            if (i_rdcontrol_aclr_a === 1)
                i_rden_reg_a <= 0;
            else if (i_inclocken_a == 1)
                i_rden_reg_a <= i_rden_a;
        end
    end

    // This always block is to handle registered inputs and output for port B
    always @(posedge i_inclock_b)
    begin
        if (i_indata_aclr_b === 1)
            i_data_hi_b <= 0;
        else if (i_inclocken_b == 1)
            i_data_hi_b <= data_b;

        if (i_wraddress_aclr_b === 1)
            i_wraddress_hi_b <= 0;
        else if (i_inclocken_b == 1)
            i_wraddress_hi_b <= wraddress_b;

        if (i_wrcontrol_aclr_b === 1)
            i_wren_hi_b <= 0;
        else if (i_inclocken_b == 1)
            i_wren_hi_b <= i_wren_b;

        if (outdata_reg_b == "INCLOCK_B")
        begin
            if (i_outdata_aclr_b === 1)
                i_q_reg_b <= 0;
            else if (i_inclocken_b == 1)
                i_q_reg_b <= i_q_tmp_b;
        end

        if (rdaddress_reg_b == "INCLOCK_B")
        begin
            if (i_rdaddress_aclr_b === 1)
                i_rdaddress_reg_b <= 0;
            else if (i_inclocken_b == 1)
                i_rdaddress_reg_b <= rdaddress_b;
        end

        if (rdcontrol_reg_b == "INCLOCK_B")
        begin
            if (i_rdcontrol_aclr_b === 1)
                i_rden_reg_b <= 0;
            else if (i_inclocken_b == 1)
                i_rden_reg_b <= i_rden_b;
        end
    end


    // This always block is to handle registered inputs for port A
    // for negative clock edge
    always @(negedge i_inclock_a)
    begin
        if (i_indata_aclr_a)
            i_data_lo_a <= 0;
        else
            i_data_lo_a <= i_data_hi_a;

        if (i_wraddress_aclr_a)
            i_wraddress_lo_a <= 0;
        else
            i_wraddress_lo_a <= i_wraddress_hi_a;

        if (i_wrcontrol_aclr_a)
            i_wren_lo_a <= 0;
        else
            i_wren_lo_a <= i_wren_hi_a;

        clk_a_trigger <= 1;
    end


    // This process is to handle registered inputs for port B
    // for negative clock edge
    always @(negedge i_inclock_b)
    begin
        if (i_indata_aclr_b)
            i_data_lo_b <= 0;
        else
            i_data_lo_b <= i_data_hi_b;

        if (i_wraddress_aclr_b)
            i_wraddress_lo_b <= 0;
        else
            i_wraddress_lo_b <= i_wraddress_hi_b;

        if (i_wrcontrol_aclr_b)
            i_wren_lo_b <= 0;
        else
            i_wren_lo_b <= i_wren_hi_b;

        clk_b_trigger <= 1;
    end


    // This process is to handle registered outputs for port A
    always @(posedge i_outclock_a)
    begin
        if (outdata_reg_a == "OUTCLOCK_A")
        begin
            if (i_outdata_aclr_a)
                i_q_reg_a <= 0;
            else if (i_outclocken_a == 1)
                i_q_reg_a <= i_q_tmp_a;
        end

        if (rdaddress_reg_a == "OUTCLOCK_A")
        begin
            if (i_rdaddress_aclr_a)
                i_rdaddress_reg_a <= 0;
            else if (i_outclocken_a == 1)
                i_rdaddress_reg_a <= rdaddress_a;
        end

        if (rdcontrol_reg_a == "OUTCLOCK_A")
        begin
            if (i_rdcontrol_aclr_a)
                i_rden_reg_a <= 0;
            else if (i_outclocken_a == 1)
                i_rden_reg_a <= i_rden_a;
        end
    end


    // This process is to handle registered outputs for port B
    always @(posedge i_outclock_b)
    begin
        if (outdata_reg_b == "OUTCLOCK_B")
        begin
            if (i_outdata_aclr_b)
                i_q_reg_b <= 0;
            else if (i_outclocken_b == 1)
                i_q_reg_b <= i_q_tmp_b;
        end

        if (rdaddress_reg_b == "OUTCLOCK_B")
        begin
            if (i_rdaddress_aclr_b)
                i_rdaddress_reg_b <= 0;
            else if (i_outclocken_b == 1)
                i_rdaddress_reg_b <= rdaddress_b;
        end

        if (rdcontrol_reg_b == "OUTCLOCK_B")
        begin
            if (i_rdcontrol_aclr_b)
                i_rden_reg_b <= 0;
            else if (i_outclocken_b == 1)
                i_rden_reg_b <= i_rden_b;
        end
    end


    // This always block is to update the memory contents with 'X' when both ports intend to
    // write at the same location
    always @(i_data_tmp_a or i_wren_tmp_a or i_wraddress_tmp_a or i_data_tmp_b or
             i_wren_tmp_b or i_wraddress_tmp_b)
    begin

        if ((write_at_low_clock_a ==1) && (write_at_low_clock_b == 1))
        begin
            if ((clk_a_trigger ==1) && (clk_b_trigger ==1))
                simultaneous_write = 1;
            else
                simultaneous_write = 0;
        end
        else
            simultaneous_write = 1;

        if ((i_wren_tmp_a == 1) && (i_wren_tmp_b == 1 ) &&
            (i_inclock_a == 0 ) && (i_inclock_b == 0 ) &&
            (simultaneous_write == 1) && ((op_mode % 5) > 1)) //BDP or QP mode
        begin
            simultaneous_write = 0;

            if ((op_mode % 5) == 2) // BDP mode
            begin
                for (i = 0; i < width_write_b; i = i + 1)
                begin
                    j = ((i_wraddress_tmp_a * width_write_a) + i) % width_write_a;
                    k = ((i_wraddress_tmp_b * width_write_b) + i) / width_write_a;

                    if ((i_wraddress_tmp_a == k) && (j < width_write_a))
                        begin
                            temp_wa = mem_data_w[i_wraddress_tmp_a];
                            temp_wa[j] = 1'bx;
                            mem_data_w[i_wraddress_tmp_a] = temp_wa;
                            simultaneous_write = 1;
                        end
                end
            end
            else // QP mode
            begin
                for (i = 0; i < width_write_a; i = i + 1)
                begin
                    for (m = 0; m < width_write_b; m = m + 1)
                    begin
                        j = ((i_wraddress_tmp_a * width_write_a) + i) / width_read_a;
                        k = ((i_wraddress_tmp_a * width_write_a) + i) % width_read_a;
                        n = ((i_wraddress_tmp_b * width_write_b) + m) / width_read_a;
                        p = ((i_wraddress_tmp_b * width_write_b) + m) % width_read_a;

                        if ((j == n) && (k == p))
                        begin
                            temp_ra = mem_data[j];
                            temp_ra[k] = 1'b X;
                            mem_data[j] = temp_ra;
                            simultaneous_write = 1;
                        end
                    end
                end
            end
        end
        else
            simultaneous_write = 0;

        if (simultaneous_write == 1)
            mem_updated = ~mem_updated;
        else
        begin
            i_data2_a = i_data_tmp_a;
            i_wren2_a = i_wren_tmp_a;
            i_wraddress2_a = i_wraddress_tmp_a;
            i_data2_b = i_data_tmp_b;
            i_wren2_b = i_wren_tmp_b;
            i_wraddress2_b = i_wraddress_tmp_b;
        end

        clk_a_trigger = 0;
        clk_b_trigger = 0;
    end


    // This always block is to update the memory contents by port A
    always @(i_data2_a or i_wren2_a or i_wraddress2_a or i_wraddress_lo_a or i_wren_lo_a)
    begin
        j = i_wraddress2_a * width_write_a;

        if ((i_wren2_a == 1) && (i_inclock_a == 0) &&
            ((op_mode % 6) > 1)) // not ROM mode
        begin
            if ((op_mode % 6) == 2) // SP or BDP mode
                mem_data_w[i_wraddress2_a] = i_data2_a;
            else // QP or DP mode
                for (i = 0; i < width_write_a; i = i + 1)
                begin
                    temp_ra = mem_data[(j+i)/width_read_a];
                    temp_ra[(j+i)%width_read_a] = i_data2_a[i];
                    mem_data[(j+i)/width_read_a] = temp_ra;
                end

            mem_updated = ~mem_updated;
        end
    end


    // This always block is to update the memory contents by port B
    always @(i_data2_b or i_wren2_b or i_wraddress2_b or i_wraddress_lo_b or i_wren_lo_b)
    begin
        j = i_wraddress2_b * width_write_b;

        if ((i_wren2_b == 1) && (i_inclock_b == 0) &&
            ((op_mode % 5) > 1)) // QP or BDP mode
        begin
            if ((op_mode % 5) == 2) // BDP mode
                for (i = 0; i < width_write_b; i = i + 1)
                begin
                    temp_wa = mem_data_w[(j+i)/width_write_a];
                    temp_wa[(j+i)%width_write_a] = i_data2_b[i];
                    mem_data_w[(j+i)/width_write_a] = temp_wa;
                end
            else // QP mode
                for (i = 0; i < width_write_b; i = i + 1)
                begin
                    temp_ra = mem_data[(j+i)/width_read_a];
                    temp_ra[(j+i)%width_read_a] = i_data2_b[i];
                    mem_data[(j+i)/width_read_a] = temp_ra;
                end

            mem_updated = ~mem_updated;
        end
    end


    // This always block is to read the memory content for port A
    always @(i_rden_tmp_a or i_rdaddress_tmp_a or
             i_wraddress_tmp_a or mem_updated)
    begin
        if ((op_mode % 6) == 3) // if QP or DP mode
        begin
            if (i_rden_tmp_a == 1)
                i_q_tmp_a = mem_data[i_rdaddress_tmp_a];
        end
        else if ((op_mode % 6) == 2) // if BDP or SP mode
            i_q_tmp_a = mem_data_w[i_wraddress_tmp_a];
        else if ((op_mode % 6) == 1) // if ROM mode
            i_q_tmp_a = mem_data[i_rdaddress_tmp_a];
    end

    // This always block is to read the memory content for port A
    always @(i_rden_tmp_b or i_rdaddress_tmp_b or
             i_wraddress_tmp_b or mem_updated)
    begin
        if ((op_mode % 5) == 3) // if QP mode
        begin
            j = i_rdaddress_tmp_b * width_read_b;
            if (i_rden_tmp_b == 1)
                for (i = 0; i < width_read_b; i = i + 1)
                begin
                    temp_ra = mem_data[(j+i)/width_read_a];
                    i_q_tmp_b[i] = temp_ra[(j+i)%width_read_a];
                end
        end
        else if ((op_mode % 5) == 2) // if BDP mode
        begin
            j = i_wraddress_tmp_b * width_write_b;
            for (i=0; i<width_write_b; i=i+1)
            begin
                temp_wa = mem_data_w[(j+i)/width_write_a];
                i_q_tmp_b[i] = temp_wa[(j+i)%width_write_a];
            end
        end
    end


    // This always block is to determine actual registered write address from port A
    // to memory block
    always @(i_wraddress_hi_a or i_wraddress_lo_a or i_wraddress_aclr_a)
    begin
        if ((operation_mode == "QUAD_PORT") || (operation_mode == "DUAL_PORT"))
            i_wraddress_reg_a <= (i_wraddress_aclr_a) ?
                                 0 : ((write_at_low_clock_a) ?
                                     i_wraddress_lo_a : i_wraddress_hi_a);
        else
            i_wraddress_reg_a <= (i_wraddress_aclr_a) ?
                                 0 : i_wraddress_hi_a;
    end


    // This always block is to determine actual registered write control from port A
    // to memory block
    always @(i_wren_hi_a or i_wren_lo_a or i_wrcontrol_aclr_a)
    begin
    if (operation_mode != "BIDIR_DUAL_PORT")
        i_wren_reg_a <= (i_wrcontrol_aclr_a) ? 0 :
                        ((write_at_low_clock_a) ?
                         i_wren_lo_a : i_wren_hi_a);
    else
        i_wren_reg_a <= (i_wrcontrol_aclr_a) ?
                        0 : i_wren_hi_a;

    end


    // This always block is to determine actual registered write data from port A
    // to memory block
    always @(i_data_hi_a or i_data_lo_a or i_indata_aclr_a)
    begin
        i_data_reg_a <= (i_indata_aclr_a) ? 0 :
                        ((write_at_low_clock_a) ?
                         i_data_lo_a : i_data_hi_a);
    end


    // This always block is to determine actual registered write address from port B
    // to memory block
    always @(i_wraddress_hi_b or i_wraddress_lo_b or i_wraddress_aclr_b)
    begin
        if ((operation_mode == "QUAD_PORT") || (operation_mode == "DUAL_PORT"))
            i_wraddress_reg_b <= (i_wraddress_aclr_b) ? 0 :
                                 ((write_at_low_clock_b) ?
                                  i_wraddress_lo_b : i_wraddress_hi_b);
        else
            i_wraddress_reg_b <= (i_wraddress_aclr_b) ?
                                 0 : i_wraddress_hi_b;
    end


    // This always block is to determine actual registered write control from port B
    // to memory block
    always @(i_wren_hi_b or i_wren_lo_b or i_wrcontrol_aclr_b)
    begin
    if (operation_mode != "BIDIR_DUAL_PORT")
        i_wren_reg_b <= (i_wrcontrol_aclr_b) ? 0 :
                        ((write_at_low_clock_b) ?
                         i_wren_lo_b : i_wren_hi_b);
    else
        i_wren_reg_b <= (i_wrcontrol_aclr_b) ?
                        0 : i_wren_hi_b;

    end


    // This always block is to determine actual registered write data from port B
    // to memory block
    always @(i_data_hi_b or i_data_lo_b or i_indata_aclr_b)
    begin
        i_data_reg_b <= (i_indata_aclr_b) ? 0 :
                        ((write_at_low_clock_b) ?
                         i_data_lo_b : i_data_hi_b);
    end


    // This always block is to determine actual write address from port A
    // to memory block
    always @(wraddress_a or i_wraddress_reg_a or i_wraddress_aclr_a)
    begin
        i_wraddress_tmp_a <= (i_wraddress_aclr_a) ? 0 :
                             ((wrcontrol_wraddress_reg_a == "INCLOCK_A") ?
                              i_wraddress_reg_a : wraddress_a);
    end


    // This always block is to determine actual write address from port B
    // to memory block
    always @(wraddress_b or i_wraddress_reg_b or i_wraddress_aclr_b)
    begin
        i_wraddress_tmp_b <= (i_wraddress_aclr_b) ? 0 :
                             ((wrcontrol_wraddress_reg_b == "INCLOCK_B") ?
                              i_wraddress_reg_b : wraddress_b);
    end


    // This always block is to determine actual read address from port A
    // to memory block
    always @(rdaddress_a or i_rdaddress_reg_a or i_rdaddress_aclr_a)
    begin
        i_rdaddress_tmp_a <= (i_rdaddress_aclr_a) ? 0 :
                             ((rdaddress_reg_a != "UNREGISTERED") ?
                              i_rdaddress_reg_a : rdaddress_a);
    end


    // This always block is to determine actual read address from port B
    // to memory block
    always @(rdaddress_b or i_rdaddress_reg_b or i_rdaddress_aclr_b)
    begin
        i_rdaddress_tmp_b <= (i_rdaddress_aclr_b) ? 0 :
                             ((rdaddress_reg_b != "UNREGISTERED") ?
                              i_rdaddress_reg_b : rdaddress_b);
    end


    // This always block is to determine actual write control from port A
    // to memory block
    always @(i_wren_a or i_wren_reg_a or i_wrcontrol_aclr_a)
    begin
        i_wren_tmp_a <= (i_wrcontrol_aclr_a) ? 0 :
                        ((wrcontrol_wraddress_reg_a == "INCLOCK_A") ?
                         i_wren_reg_a : i_wren_a);
    end


    // This always block is to determine actual write control from port B
    // to memory block
    always @(i_wren_b or i_wren_reg_b or i_wrcontrol_aclr_b)
    begin
        i_wren_tmp_b <= (i_wrcontrol_aclr_b) ? 0 :
                        ((wrcontrol_wraddress_reg_b == "INCLOCK_B") ?
                         i_wren_reg_b : i_wren_b);
    end


    // This always block is to determine actual read control from port A
    // to memory block
    always @(i_rden_a or i_rden_reg_a or i_rdcontrol_aclr_a)
    begin
        i_rden_tmp_a <= (i_rdcontrol_aclr_a) ? 0 :
                        ((rdcontrol_reg_a != "UNREGISTERED") ?
                         i_rden_reg_a : i_rden_a);
    end


    // This always block is to determine actual read control from port B
    // to memory block
    always @(i_rden_b or i_rden_reg_b or i_rdcontrol_aclr_b)
    begin
        i_rden_tmp_b <= (i_rdcontrol_aclr_b) ? 0 :
                        ((rdcontrol_reg_b != "UNREGISTERED") ?
                         i_rden_reg_b : i_rden_b);
    end

    // This always block is to determine actual write data from port A
    // to memory block
    always @(data_a or i_data_reg_a or i_indata_aclr_a)
    begin
        i_data_tmp_a <= (i_indata_aclr_a) ? 0 :
                        ((indata_reg_a == "INCLOCK_A") ?
                         i_data_reg_a : data_a);
    end


    // This always block is to determine actual write data from port B
    // to memory block
    always @(data_b or i_data_reg_b or i_indata_aclr_b)
    begin
        i_data_tmp_b <= (i_indata_aclr_b) ? 0 :
                        ((indata_reg_b == "INCLOCK_B") ?
                         i_data_reg_b : data_b);
    end


// SIGNAL ASSIGNMENT

    // Port A output
    assign q_a = ((op_mode % 6) == 0) ? 0 :
                 (i_outdata_aclr_a) ? 0 :
                 ((outdata_reg_a != "UNREGISTERED") ? i_q_reg_a : i_q_tmp_a);

    // Port B output
    assign q_b = ((op_mode % 5) == 0) ? 0 :
                 (i_outdata_aclr_b) ? 0 :
                 ((outdata_reg_b != "UNREGISTERED") ? i_q_reg_b : i_q_tmp_b);

endmodule // ALTQPRAM


//START_MODULE_NAME------------------------------------------------------------
//
// Module Name     :  scfifo
//
// Description     :  Single Clock FIFO
//
// Limitation      :  USE_EAB=OFF is not supported
//
// Results expected:  
//
//END_MODULE_NAME--------------------------------------------------------------

// BEGINNING OF MODULE
`timescale 1 ps / 1 ps

// CONSTANTS DECLARATION                
`define NON_STRATIX_FAMILY    "NON_STRATIX"
`define DEV_STRATIX           "Stratix"
`define DEV_STRATIX_GX        "Stratix GX"
`define DEV_CYCLONE           "Cyclone"

// MODULE DECLARATION
module scfifo (data, clock, wrreq, rdreq, aclr, sclr,
               q, usedw, full, empty, almost_full, almost_empty);
                
// GLOBAL PARAMETER DECLARATION                
    parameter lpm_width = 1;
    parameter lpm_widthu = 1;
    parameter lpm_numwords = 2;
    parameter lpm_showahead = "OFF";
    parameter intended_device_family = `NON_STRATIX_FAMILY;
    parameter almost_full_value = 0;
    parameter almost_empty_value = 0;    
    parameter underflow_checking = "ON";
    parameter overflow_checking = "ON";
    parameter allow_rwcycle_when_full = "OFF";
    parameter lpm_hint = "USE_EAB=ON";    
    parameter use_eab = "ON";
    parameter lpm_type = "scfifo";

// INPUT PORT DECLARATION   
    input  [lpm_width-1:0] data;
    input  clock;
    input  wrreq;
    input  rdreq;
    input  aclr;
    input  sclr;
   
// OUTPUT PORT DECLARATION   
    output [lpm_width-1:0] q;
    output [lpm_widthu-1:0] usedw;
    output full;
    output empty;
    output almost_full;
    output almost_empty;
    
// INTERNAL REGISTERS DECLARATION
    reg [lpm_width-1:0] mem_data [(1<<lpm_widthu):0];
    reg [lpm_width-1:0] tmp_data;
    reg [lpm_widthu-1:0] count_id;
    reg [lpm_widthu-1:0] read_id;
    reg [lpm_widthu-1:0] write_id;
    reg valid_rreq;
    reg valid_wreq;
    reg write_flag;
    reg full_flag;
    reg empty_flag;
    reg almost_full_flag;
    reg almost_empty_flag;
    reg [lpm_width-1:0] tmp_q;  
    
// INTERNAL TRI DECLARATION
    tri0 aclr;
   
// LOCAL INTEGER DECLARATION   
    integer i;
   
// INITIAL CONSTRUCT BLOCK
    initial
    begin
        if (lpm_width <= 0)
            $display ("Error! LPM_WIDTH must be greater than 0.");
        if (lpm_numwords <= 1)
            $display ("Error! LPM_NUMWORDS must be greater than or equal to 2.");
        if ((lpm_widthu !=1) && (lpm_numwords > (1 << lpm_widthu)))
            $display ("Error! LPM_NUMWORDS must equal to the ceiling of log2(LPM_WIDTHU).");
        if (lpm_numwords <= (1 << (lpm_widthu - 1)))
            $display ("Error! LPM_WIDTHU is too big for the specified LPM_NUMWORDS.");
            
        for (i = 0; i < (1<<lpm_widthu); i = i + 1)
        begin
            if ((intended_device_family == `DEV_STRATIX) ||
            (intended_device_family == `DEV_STRATIX_GX) ||
            (intended_device_family == `DEV_CYCLONE))
                mem_data[i] <= {lpm_width{1'bx}};
            else
                mem_data[i] <= {lpm_width{1'b0}};
        end

        tmp_data <= 0;
        if ((intended_device_family == `DEV_STRATIX) ||
            (intended_device_family == `DEV_STRATIX_GX) ||
            (intended_device_family == `DEV_CYCLONE))
            tmp_q <= {lpm_width{1'bx}};
        else
            tmp_q <= {lpm_width{1'b0}};
        write_flag <= 1'b0;
        count_id <= 0;
        read_id <= 0;
        write_id <= 0;
        full_flag <= 1'b0;
        empty_flag <= 1'b1;
        almost_full_flag <= 1'b0;
        almost_empty_flag <= 1'b1;
    end

// ALWAYS CONSTRUCT BLOCK    
    always @(posedge aclr)
    begin
        if (((intended_device_family != `DEV_STRATIX) &&
            (intended_device_family != `DEV_STRATIX_GX) &&
            (intended_device_family != `DEV_CYCLONE)))
        begin
            if (lpm_showahead == "ON")
                tmp_q <= mem_data[0];
            else 
                tmp_q <= {lpm_width{1'b0}};
        end         
    end // @(posedge aclr)
    
    always @(rdreq or empty_flag)
    begin
        if (underflow_checking == "OFF")
            valid_rreq <= rdreq;
        else
            valid_rreq <= rdreq && ~empty_flag;
    end // @(rdreq or empty_flag)
    
    always @(wrreq or rdreq or full_flag)   
    begin
        if (overflow_checking == "OFF") 
            valid_wreq <= wrreq;
        else if (allow_rwcycle_when_full == "ON")
                valid_wreq <= wrreq && (!full_flag || rdreq);
        else
            valid_wreq <= wrreq && !full_flag;
    end // @(wrreq or rdreq or full_flag)
    
    always @(posedge clock)
    begin
        if (aclr)
        begin
            read_id <= 0;
            count_id <= 0; 
            full_flag <= 1'b0;
            empty_flag <= 1'b1;
            almost_full_flag <= 1'b0;
            almost_empty_flag <= 1'b1;
            
            if (valid_wreq && ((intended_device_family == `DEV_STRATIX) ||
            (intended_device_family == `DEV_STRATIX_GX) ||
            (intended_device_family == `DEV_CYCLONE)))
            begin
                tmp_data <= data;
                write_flag <= 1'b1;
            end
            else
                write_id <= 0;
        end
        else if (sclr)
        begin
            if ((lpm_showahead == "ON") || ((intended_device_family == `DEV_STRATIX) ||
            (intended_device_family == `DEV_STRATIX_GX) ||
            (intended_device_family == `DEV_CYCLONE)))
                tmp_q <= mem_data[0];
            else
                tmp_q <= mem_data[read_id];
            read_id <= 0;
            count_id <= 0;
            full_flag <= 1'b0;
            empty_flag <= 1'b1;
            almost_full_flag <= 1'b0;
            almost_empty_flag <= 1'b1; 
        
            if (valid_wreq)
            begin
                tmp_data <= data;
                write_flag <= 1'b1;
            end
            else
                write_id <= 0;
        end
        else    
        begin       
            // Both WRITE and READ operations
            if (valid_wreq && valid_rreq)
            begin
                tmp_data <= data;
                write_flag <= 1'b1;
                empty_flag <= 1'b0;
                if (allow_rwcycle_when_full == "OFF")
                begin
                    full_flag <= 1'b0;
                end

                if (read_id >= ((1 << lpm_widthu) - 1))
                begin
                    if (lpm_showahead == "ON")
                        tmp_q <= mem_data[0];
                    else
                        tmp_q <= mem_data[read_id];
                    read_id <= 0;
                end
                else
                begin
                    if (lpm_showahead == "ON")
                        tmp_q <= mem_data[read_id + 1];
                    else
                        tmp_q <= mem_data[read_id];
                    read_id <= read_id + 1;
                end
            end
            // WRITE operation only
            else if (valid_wreq)
            begin
                tmp_data <= data;
                empty_flag <= 1'b0;
                write_flag <= 1'b1;
            
                if (count_id >= (1 << lpm_widthu) - 1)
                    count_id <= 0;
                else
                    count_id <= count_id + 1;
                                
                if ((count_id == lpm_numwords - 1) && (empty_flag == 1'b0))
                    full_flag <= 1'b1;                    
                
                if (lpm_showahead == "ON")
                    tmp_q <= mem_data[read_id];
            end
            // READ operation only
            else if (valid_rreq)
            begin
                full_flag <= 1'b0;
            
                if (count_id <= 0)
                    count_id <= ((1 << lpm_widthu) - 1);
                else
                    count_id <= count_id - 1;
                                
                if ((count_id == 1) && (full_flag == 1'b0))
                    empty_flag <= 1'b1;                     
                    
                if (read_id >= ((1<<lpm_widthu) - 1))
                begin
                    if (lpm_showahead == "ON")
                        tmp_q <= mem_data[0];
                    else
                        tmp_q <= mem_data[read_id];
                    read_id <= 0;                       
                end
                else
                begin
                    if (lpm_showahead == "ON")
                        tmp_q <= mem_data[read_id + 1];
                    else
                        tmp_q <= mem_data[read_id];                        
                    read_id <= read_id + 1;                        
                end                     
            end // if Both WRITE and READ operations
        end // if aclr
    end // @(posedge clock)
    
    always @(negedge clock)
    begin
        if (write_flag)
        begin
            write_flag <= 1'b0;
            mem_data[write_id] = tmp_data;
            
            if (sclr || aclr || (write_id >= ((1 << lpm_widthu) - 1)))
                write_id <= 0;
            else
                write_id <= write_id + 1;            
        end

        if ((lpm_showahead == "ON") && ($time > 0))
            tmp_q <= mem_data[read_id];
    end // @(negedge clock)
    
    always @(count_id)
    begin
        // Setting almost_full_flag
        if (almost_full_value == 0)
            almost_full_flag <= 1'b1;
        else if (lpm_numwords > almost_full_value)
            if ((count_id == almost_full_value) && valid_wreq && !valid_rreq)
                almost_full_flag <= 1'b1;
            else if ((count_id == almost_full_value - 1) && !valid_wreq && valid_rreq)
                almost_full_flag <= 1'b0;    
                
        // Setting almost_empty_flag
        if (almost_empty_value == 0) 
            almost_empty_flag <= 1'b0;
        else if (lpm_numwords > almost_empty_value)
            if ((count_id == almost_empty_value - 1) && !valid_wreq && valid_rreq)
                almost_empty_flag <= 1'b1;
            else if ((count_id == almost_empty_value) && valid_wreq && !valid_rreq)
                almost_empty_flag <= 1'b0;
    end // @(count_id)
    
    always @(full_flag)
    begin
        if (lpm_numwords == almost_full_value)
            if (full_flag)
                almost_full_flag <= 1'b1;
            else
                almost_full_flag <= 1'b0;
        
        if (lpm_numwords == almost_empty_value)
            if (full_flag)
                almost_empty_flag <= 1'b0;
            else
                almost_empty_flag <= 1'b1;
    end // @(full_flag)

// CONTINOUS ASSIGNMENT        
    assign q = tmp_q;
    assign full = full_flag;
    assign empty = empty_flag;
    assign usedw = count_id;
    assign almost_full = almost_full_flag;
    assign almost_empty = almost_empty_flag;

endmodule // scfifo
// END OF MODULE

//START_MODULE_NAME------------------------------------------------------------
//
// Module Name     :  dcfifo_dffpipe
//
// Description     :  Dual Clocks FIFO
//
// Limitation      :  
//
// Results expected:  
//
//END_MODULE_NAME--------------------------------------------------------------

// BEGINNING OF MODULE
`timescale 1 ps / 1 ps

// MODULE DECLARATION
module dcfifo_dffpipe (d, clock, aclr, 
                       q);

// GLOBAL PARAMETER DECLARATION
    parameter lpm_delay = 1;
    parameter lpm_width = 64;

// INPUT PORT DECLARATION    
    input [lpm_width-1:0] d;
    input clock;
    input aclr;
    
// OUTPUT PORT DECLARATION    
    output [lpm_width-1:0] q;    

// INTERNAL REGISTERS DECLARATION
    reg [lpm_width-1:0] dffpipe [lpm_delay:0];
    reg [lpm_width-1:0] q;
    
// LOCAL INTEGER DECLARATION    
    integer delay, i;

// INITIAL CONSTRUCT BLOCK    
    initial
    begin
        delay <= lpm_delay - 1;
        for (i = 0; i < lpm_delay; i = i + 1)
            dffpipe[i] <= 0;
        q <= 0;
    end

// ALWAYS CONSTRUCT BLOCK    
    always @(posedge aclr)
    begin
        for (i = 0; i < lpm_delay; i = i + 1)
            dffpipe[i] <= 0;
        q <= 0;
    end // @(posedge aclr)

    always @(posedge clock)
    begin
        if (!aclr && (lpm_delay > 0) && ($time > 0))
        begin
            if (delay > 0)
            begin
                for (i = delay; i > 0; i = i - 1)
                    dffpipe[i] <= dffpipe[i - 1];
                q <= dffpipe[delay - 1];
            end
            else
                q <= d;
                
            dffpipe[0] <= d;
        end
    end // @(posedge clock)
    
    always @(d)
    begin
        if (lpm_delay == 0)
            if (aclr)
                q <= 0;
            else
                q <= d;
    end // @(d)

endmodule // dcfifo_dffpipe
// END OF MODULE

//START_MODULE_NAME------------------------------------------------------------
//
// Module Name     :  dcfifo_fefifo
//
// Description     :  Dual Clock FIFO
//
// Limitation      :  
//
// Results expected:  
//
//END_MODULE_NAME--------------------------------------------------------------

// BEGINNING OF MODULE
`timescale 1 ps / 1 ps

// MODULE DECLARATION
module dcfifo_fefifo (usedw_in, wreq, rreq, clock, aclr,
                      empty, full);
                      
// GLOBAL PARAMETER DECLARATION
    parameter lpm_widthad = 1;
    parameter lpm_numwords = 1;
    parameter underflow_checking = "ON";
    parameter overflow_checking = "ON";
    parameter lpm_mode = "READ";

// INPUT PORT DECLARATION    
    input [lpm_widthad-1:0] usedw_in;
    input wreq, rreq;
    input clock;
    input aclr;
    
// OUTPUT PORT DECLARATION
    output empty, full;

// INTERNAL REGISTERS DECLARATION
    reg [1:0] sm_empty;
    reg lrreq;
    reg i_empty, i_full;
    
// LOCAL INTEGER DECLARATION    
    integer almostfull;

// INITIAL CONSTRUCT BLOCK    
    initial
    begin
        if ((lpm_mode != "READ") && (lpm_mode != "WRITE"))
            $display ("Error! LPM_MODE must be READ or WRITE.");
        if ((underflow_checking != "ON") && (underflow_checking != "OFF"))
            $display ("Error! UNDERFLOW_CHECKING must be ON or OFF.");
        if ((overflow_checking != "ON") && (overflow_checking != "OFF"))
            $display ("Error! OVERFLOW_CHECKING must be ON or OFF.");

        sm_empty <= 2'b00;
        i_empty <= 1'b1;
        i_full <= 1'b0;
        
        if (lpm_numwords >= 3)
            almostfull <= lpm_numwords - 3;
        else
            almostfull <= 0;
    end

// ALWAYS CONSTRUCT BLOCK   
    always @(posedge aclr)
    begin
        sm_empty <= 2'b00;
        i_empty <= 1'b1;
        i_full <= 1'b0;
        lrreq <= 1'b0;
    end // @(posedge aclr)

    always @(posedge clock)
    begin
        if (~aclr && $time > 0)
        begin
            if (lpm_mode == "READ")
            begin
               casex (sm_empty)
                    // state_empty
                    2'b00:                          
                        if (usedw_in != 0)
                            sm_empty = 2'b01;
                    // state_non_empty                            
                    2'b01:
                        if (rreq && (((usedw_in == 1) && !lrreq) || ((usedw_in == 2) && lrreq)))
                            sm_empty = 2'b10;
                    // state_emptywait                            
                    2'b10:
                        if (usedw_in > 1) 
                            sm_empty = 2'b01;
                        else 
                            sm_empty = 2'b00;
                    default:
                        $display ("Error! Invalid sm_empty state in read mode.");
                endcase
            end // if (lpm_mode == "READ")
            else if (lpm_mode == "WRITE")
            begin
                casex (sm_empty)
                    // state_empty
                    2'b00:
                        if (wreq)
                            sm_empty = 2'b01;
                    // state_one                            
                    2'b01:
                        if (!wreq)
                            sm_empty = 2'b11;
                    // state_non_empty                            
                    2'b11:
                        if (wreq)
                            sm_empty = 2'b01;
                        else if (usedw_in == 0)
                            sm_empty = 2'b00;
                    default:
                        $display ("Error! Invalid sm_empty state in write mode.");                            
                endcase
            end // if (lpm_mode == "WRITE")
            
            if (underflow_checking == "OFF")
                lrreq = rreq;
            else
                lrreq = rreq && ~i_empty;
                
            i_empty = !sm_empty[0];
            if (~aclr && (usedw_in >= almostfull) && ($time > 0))
                i_full = 1'b1;
            else
                i_full = 1'b0;
        end // if (~aclr && $time > 0)          
    end // @(posedge clock)

// CONTINOUS ASSIGNMENT    
    assign empty = i_empty;
    assign full = i_full;
endmodule // dcfifo_fefifo
// END OF MODULE

//START_MODULE_NAME------------------------------------------------------------
//
// Module Name     :  dcfifo_async
//
// Description     :  Asynchronous Dual Clocks FIFO
//
// Limitation      :  
//
// Results expected:  
//
//END_MODULE_NAME--------------------------------------------------------------

// BEGINNING OF MODULE
`timescale 1 ps / 1 ps

// CONSTANTS DECLARATION
`define DCFIFO_STRATIX        "stratix"

// MODULE DECLARATION
module dcfifo_async (data, rdclk, wrclk, aclr, rdreq, wrreq, 
                     rdfull, wrfull, rdempty, wrempty, rdusedw, wrusedw, q);
                    
// GLOBAL PARAMETER DECLARATION
    parameter lpm_width = 1;
    parameter lpm_widthu = 1;
    parameter lpm_numwords = 2;
    parameter delay_rdusedw = 1;
    parameter delay_wrusedw = 1;
    parameter rdsync_delaypipe = 3;
    parameter wrsync_delaypipe = 3;    
    parameter intended_device_family = `NON_STRATIX_FAMILY;
    parameter lpm_showahead = "OFF";
    parameter underflow_checking = "ON";
    parameter overflow_checking = "ON";
    parameter use_eab = "ON";
    parameter add_ram_output_register = "OFF";
    
// INPUT PORT DECLARATION    
    input [lpm_width-1:0] data;
    input rdclk;
    input wrclk;
    input aclr;    
    input wrreq;
    input rdreq;

// OUTPUT PORT DECLARATION
    output rdfull;
    output wrfull;
    output rdempty;
    output wrempty;
    output [lpm_widthu-1:0] rdusedw;
    output [lpm_widthu-1:0] wrusedw;
    output [lpm_width-1:0] q;

// INTERNAL REGISTERS DECLARATION
    reg [lpm_width-1:0] mem_data [(1<<lpm_widthu)-1:0];
    reg [lpm_width-1:0] i_data_tmp;
    reg [lpm_widthu-1:0] i_rdptr;
    reg [lpm_widthu-1:0] i_wrptr;
    reg [lpm_widthu-1:0] i_wrptr_tmp;
    reg i_rden;
    reg i_wren;
    reg i_rdenclock;
    reg i_wren_tmp;
    reg [lpm_widthu-1:0] i_wr_udwn;
    reg [lpm_widthu-1:0] i_rd_udwn;
    reg i_showahead_flag;
    reg [lpm_widthu:0] i_rdusedw;
    reg [lpm_widthu-1:0] i_wrusedw;
    reg [lpm_width-1:0] i_q_tmp;
        
// INTERNAL WIRE DECLARATION    
    wire w_rdempty;
    wire w_wrempty;
    wire wrdfull;
    wire w_wrfull;
    wire [lpm_widthu-1:0] w_rdptrrg;
    wire [lpm_widthu-1:0] w_wrdelaycycle;
    wire [lpm_widthu-1:0] w_ws_nbrp;
    wire [lpm_widthu-1:0] w_rs_nbwp;
    wire [lpm_widthu-1:0] w_ws_dbrp;
    wire [lpm_widthu-1:0] w_rs_dbwp;
    wire [lpm_widthu-1:0] w_rd_dbuw;
    wire [lpm_widthu-1:0] w_wr_dbuw;
    wire [lpm_widthu-1:0] w_rdusedw;
    wire [lpm_widthu-1:0] w_wrusedw;
    
// INTERNAL TRI DECLARATION
    tri0 aclr;
    
// LOCAL INTEGER DECLARATION    
    integer i;
      
// INITIAL CONSTRUCT BLOCK      
    initial
    begin
        if((lpm_showahead != "ON") && (lpm_showahead != "OFF"))
            $display ("Error! lpm_showahead must be ON or OFF.");
        if((underflow_checking != "ON") && (underflow_checking != "OFF"))
            $display ("Error! underflow_checking must be ON or OFF.");
        if((overflow_checking != "ON") && (overflow_checking != "OFF"))
            $display ("Error! overflow_checking must be ON or OFF.");
        if((use_eab != "ON") && (use_eab != "OFF"))
            $display ("Error! use_eab must be ON or OFF.");
        if((add_ram_output_register != "ON") && (add_ram_output_register != "OFF"))
            $display ("Error! add_ram_output_register must be ON or OFF.");

        for (i = 0; i < (1 << lpm_widthu); i = i + 1)
            mem_data[i] <= 0;
        i_data_tmp <= 0;
        i_rdptr <= 0;
        i_wrptr <= 0;
        i_wrptr_tmp <= 0;
        i_wren_tmp <= 0;
        i_wr_udwn <= 0;
        i_rd_udwn <= 0;
                
        i_rdusedw <= 0;
        i_wrusedw <= 0;
        i_q_tmp <= 0;
    end

// COMPONENT INSTANTIATIONS
    // Delays & DFF Pipes
    dcfifo_dffpipe DP_RDPTR_D (
        .d (i_rdptr), 
        .clock (i_rdenclock), 
        .aclr (aclr),
        .q (w_rdptrrg));
    dcfifo_dffpipe DP_WRPTR_D (
        .d (i_wrptr), 
        .clock (wrclk), 
        .aclr (aclr),
        .q (w_wrdelaycycle));
    defparam
        DP_RDPTR_D.lpm_delay = 0,
        DP_RDPTR_D.lpm_width = lpm_widthu,
        DP_WRPTR_D.lpm_delay = 1,
        DP_WRPTR_D.lpm_width = lpm_widthu;

    dcfifo_dffpipe DP_WS_NBRP (
        .d (w_rdptrrg), 
        .clock (wrclk), 
        .aclr (aclr),
        .q (w_ws_nbrp));
    dcfifo_dffpipe DP_RS_NBWP (
        .d (w_wrdelaycycle),
        .clock (rdclk), 
        .aclr (aclr),
        .q (w_rs_nbwp));
    dcfifo_dffpipe DP_WS_DBRP (
        .d (w_ws_nbrp), 
        .clock (wrclk), 
        .aclr (aclr),
        .q (w_ws_dbrp));
    dcfifo_dffpipe DP_RS_DBWP (
        .d (w_rs_nbwp), 
        .clock (rdclk), 
        .aclr (aclr),
        .q (w_rs_dbwp));
    defparam
        DP_WS_NBRP.lpm_delay = wrsync_delaypipe,
        DP_WS_NBRP.lpm_width = lpm_widthu,
        DP_RS_NBWP.lpm_delay = rdsync_delaypipe,
        DP_RS_NBWP.lpm_width = lpm_widthu,
        DP_WS_DBRP.lpm_delay = 1,              // gray_delaypipe
        DP_WS_DBRP.lpm_width = lpm_widthu,
        DP_RS_DBWP.lpm_delay = 1,              // gray_delaypipe
        DP_RS_DBWP.lpm_width = lpm_widthu;
        
    dcfifo_dffpipe DP_WRUSEDW (
        .d (i_wr_udwn), 
        .clock (wrclk), 
        .aclr (aclr),
        .q (w_wrusedw));
    dcfifo_dffpipe DP_RDUSEDW (
        .d (i_rd_udwn), 
        .clock (rdclk), 
        .aclr (aclr),
        .q (w_rdusedw));
    dcfifo_dffpipe DP_WR_DBUW (
        .d (i_wr_udwn), 
        .clock (wrclk), 
        .aclr (aclr),
        .q (w_wr_dbuw));
    dcfifo_dffpipe DP_RD_DBUW (
        .d (i_rd_udwn), 
        .clock (rdclk), 
        .aclr (aclr),
        .q (w_rd_dbuw));
    defparam
        DP_WRUSEDW.lpm_delay = delay_wrusedw,
        DP_WRUSEDW.lpm_width = lpm_widthu,
        DP_RDUSEDW.lpm_delay = delay_rdusedw,
        DP_RDUSEDW.lpm_width = lpm_widthu,
        DP_WR_DBUW.lpm_delay = 1,              // wrusedw_delaypipe
        DP_WR_DBUW.lpm_width = lpm_widthu,
        DP_RD_DBUW.lpm_delay = 1,              // rdusedw_delaypipe
        DP_RD_DBUW.lpm_width = lpm_widthu;
        
    // Empty/Full
    dcfifo_fefifo WR_FE (
        .usedw_in (w_wr_dbuw), 
        .wreq (wrreq), 
        .rreq (rdreq),
        .clock (wrclk), 
        .aclr (aclr),
        .empty (w_wrempty), 
        .full (w_wrfull));
    dcfifo_fefifo RD_FE (
        .usedw_in (w_rd_dbuw), 
        .rreq (rdreq), 
        .wreq(wrreq),
        .clock (rdclk), 
        .aclr (aclr),
        .empty (w_rdempty), 
        .full (w_rdfull));
    defparam
        WR_FE.lpm_widthad = lpm_widthu,
        WR_FE.lpm_numwords = lpm_numwords,
        WR_FE.underflow_checking = underflow_checking,
        WR_FE.overflow_checking = overflow_checking,
        WR_FE.lpm_mode = "WRITE",
        RD_FE.lpm_widthad = lpm_widthu,
        RD_FE.lpm_numwords = lpm_numwords,
        RD_FE.underflow_checking = underflow_checking,
        RD_FE.overflow_checking = overflow_checking,
        RD_FE.lpm_mode = "READ";                
            
// ALWAYS CONSTRUCT BLOCK  
    always @(posedge aclr)
    begin
        i_rdptr <= 0;
        i_wrptr <= 0;
        if ((add_ram_output_register == "ON") || (use_eab == "OFF") ||
        ((intended_device_family != `DCFIFO_STRATIX) &&
        (intended_device_family != `DEV_STRATIX) &&
        (intended_device_family != `DEV_STRATIX_GX) &&
        (intended_device_family != `DEV_CYCLONE)))
            if (lpm_showahead == "ON")
                i_q_tmp <= mem_data[0];
            else
                i_q_tmp <= 0;
    end // @(posedge aclr)
       
    // FIFOram   
    always @(rdreq or w_rdempty)
    begin
        if (underflow_checking == "OFF")
            i_rden <= rdreq;
        else
            i_rden <= rdreq && !w_rdempty;
    end // @(rdreq or w_rdempty)
            
    always @(wrreq or w_wrfull)
    begin
        if (overflow_checking == "OFF") 
            i_wren <= wrreq;
        else
            i_wren <= wrreq && !w_wrfull;
    end // @(wrreq or w_wrfull)            

    always @(wrclk)
    begin
        if (aclr && ((add_ram_output_register == "ON")
        || (use_eab == "OFF") || 
        ((intended_device_family != `DCFIFO_STRATIX) &&
        (intended_device_family != `DEV_STRATIX) &&
        (intended_device_family != `DEV_STRATIX_GX) &&
        (intended_device_family != `DEV_CYCLONE))))
        begin
            i_data_tmp <= 0;
            i_wrptr_tmp <= 0;
            i_wren_tmp <= 0;
        end
        else if (wrclk && ($time > 0))
        begin
            i_data_tmp <= data;
            i_wrptr_tmp <= i_wrptr;
            i_wren_tmp <= i_wren;
            
            if (i_wren)
            begin
                if (~aclr && ((i_wrptr < (1<<lpm_widthu)-1) || (overflow_checking == "OFF")))
                    i_wrptr <= i_wrptr + 1;
                else
                    i_wrptr <= 0;
                    
                if (use_eab == "OFF")
                begin
                    mem_data[i_wrptr] <= data;
                    
                    if (lpm_showahead == "ON")
                        i_showahead_flag <= 1'b1;
                end                 
            end
        end
        
        if ((~wrclk && (use_eab == "ON")) && ($time > 0))
        begin
            if (i_wren_tmp)
            begin
                mem_data[i_wrptr_tmp] <= i_data_tmp;
            end
            
            if (lpm_showahead == "ON")
                i_showahead_flag <= 1'b1;
        end
    end // @(wrclk)      

    always @(rdclk)
    begin
        if (aclr && ((add_ram_output_register == "ON") ||
        (use_eab == "OFF") ||
        ((intended_device_family != `DCFIFO_STRATIX) &&
        (intended_device_family != `DEV_STRATIX) &&
        (intended_device_family != `DEV_STRATIX_GX) &&
        (intended_device_family != `DEV_CYCLONE))))
        begin
            if (lpm_showahead == "ON")
                i_q_tmp <= mem_data[0];
            else
                i_q_tmp <= 0;
        end                 
        else if (rdclk && i_rden && ($time > 0))
        begin
            if (~aclr && ((i_rdptr < (1<<lpm_widthu)-1) || (underflow_checking == "OFF")))
                i_rdptr <= i_rdptr + 1;                 
            else
                i_rdptr <= 0;
                
            if (lpm_showahead == "ON")
                i_showahead_flag <= 1'b1;
            else
                i_q_tmp <= mem_data[i_rdptr];               
        end            
    end // @(rdclk)
    
    always @(posedge i_showahead_flag)
    begin
        i_q_tmp <= mem_data[i_rdptr];
        i_showahead_flag <= 1'b0;
    end // @(posedge i_showahead_flag)
    
    // Delays & DFF Pipes
    always @(negedge rdclk) 
    begin 
        i_rdenclock <= 0;
    end // @(negedge rdclk)
            
    always @(posedge rdclk)  
    begin
        if (i_rden) 
            i_rdenclock <= 1;
    end // @(posedge rdclk)  

    always @(i_wrptr or w_ws_dbrp)
    begin
        i_wr_udwn <= i_wrptr - w_ws_dbrp;
    end // @(i_wrptr or w_ws_dbrp)        

    always @(i_rdptr or w_rs_dbwp)
    begin
        i_rd_udwn <= w_rs_dbwp - i_rdptr;    
    end // @(i_rdptr or w_rs_dbwp)
        
// CONTINOUS ASSIGNMENT
    assign q = i_q_tmp;
    assign wrfull = w_wrfull;
    assign rdfull = w_rdfull;
    assign wrempty = w_wrempty;
    assign rdempty = w_rdempty;
    assign wrusedw = w_wrusedw;
    assign rdusedw = w_rdusedw;

endmodule // dcfifo_async
// END OF MODULE

//START_MODULE_NAME------------------------------------------------------------
//
// Module Name     :  dcfifo_sync
//
// Description     :  Synchronous Dual Clock FIFO
//
// Limitation      :  
//
// Results expected:  
//
//END_MODULE_NAME--------------------------------------------------------------

// BEGINNING OF MODULE
`timescale 1 ps / 1 ps

// MODULE DECLARATION
module dcfifo_sync (data, rdclk, wrclk, aclr, rdreq, wrreq, 
                    rdfull, wrfull, rdempty, wrempty, rdusedw, wrusedw, q);
                    
// GLOBAL PARAMETER DECLARATION                    
    parameter lpm_width = 1;
    parameter lpm_widthu = 1;
    parameter lpm_numwords = 2;
    parameter intended_device_family = `NON_STRATIX_FAMILY;
    parameter lpm_showahead = "OFF";
    parameter underflow_checking = "ON";
    parameter overflow_checking = "ON";
    parameter use_eab = "ON";
    parameter add_ram_output_register = "OFF";
    
// INPUT PORT DECLARATION
    input [lpm_width-1:0] data;
    input rdclk;
    input wrclk;
    input aclr;
    input rdreq;
    input wrreq;
    
// OUTPUT PORT DECLARATION    
    output rdfull;
    output wrfull;
    output rdempty;
    output wrempty;
    output [lpm_widthu-1:0] rdusedw;
    output [lpm_widthu-1:0] wrusedw;
    output [lpm_width-1:0] q;

// INTERNAL REGISTERS DECLARATION
    reg [lpm_width-1:0] mem_data [(1<<lpm_widthu)-1:0];
    reg [lpm_width-1:0] i_data_tmp;
    reg [lpm_widthu:0] i_rdptr;
    reg [lpm_widthu:0] i_wrptr;
    reg [lpm_widthu-1:0] i_wrptr_tmp;
    reg i_rden;
    reg i_wren;
    reg i_wren_tmp;
    reg i_showahead_flag;
    reg i_rdempty;
    reg i_wrempty;
    reg i_rdfull;
    reg i_wrfull;
    reg [lpm_widthu:0] i_rdusedw;
    reg [lpm_widthu:0] i_wrusedw;
    reg [lpm_width-1:0] i_q_tmp;
            
// INTERNAL WIRE DECLARATION    
    wire [lpm_widthu:0] w_rdptr_s;
    wire [lpm_widthu:0] w_wrptr_s;
    wire [lpm_widthu:0] w_wrptr_r;
    
// LOCAL INTEGER DECLARATION    
    integer cnt_mod;
    integer i;

// INITIAL CONSTRUCT BLOCK  
    initial
    begin
        if ((lpm_showahead != "ON") && (lpm_showahead != "OFF"))
            $display ("Error! LPM_SHOWAHEAD must be ON or OFF.");
        if ((underflow_checking != "ON") && (underflow_checking != "OFF"))
            $display ("Error! UNDERFLOW_CHECKING must be ON or OFF.");
        if ((overflow_checking != "ON") && (overflow_checking != "OFF"))
            $display ("Error! OVERFLOW_CHECKING must be ON or OFF.");
        if ((use_eab != "ON") && (use_eab != "OFF"))
            $display ("Error! USE_EAB must be ON or OFF.");
        if (lpm_numwords > (1 << lpm_widthu))
            $display ("Error! LPM_NUMWORDS must be less than or equal to 2**LPM_WIDTHU.");
        if((add_ram_output_register != "ON") && (add_ram_output_register != "OFF"))
            $display ("Error! add_ram_output_register must be ON or OFF.");
            
        for (i = 0; i < (1 << lpm_widthu); i = i + 1)
            mem_data[i] <= 0;
        i_data_tmp <= 0;
        i_rdptr <= 0;
        i_wrptr <= 0;
        i_wrptr_tmp <= 0;
        i_wren_tmp <= 0;
        
        i_rdempty <= 1;
        i_wrempty <= 1;
        i_rdfull <= 0;
        i_wrfull <= 0;
        i_rdusedw <= 0;
        i_wrusedw <= 0;
        i_q_tmp <= 0;

        if (lpm_numwords == (1 << lpm_widthu))
            cnt_mod <= 1 << (lpm_widthu + 1);
        else
            cnt_mod <= 1 << lpm_widthu;
    end

// COMPONENT INSTANTIATIONS
    dcfifo_dffpipe RDPTR_D (
        .d (i_rdptr), 
        .clock (wrclk), 
        .aclr (aclr),
        .q (w_rdptr_s));
    dcfifo_dffpipe WRPTR_D (
        .d (i_wrptr), 
        .clock (wrclk), 
        .aclr (aclr),
        .q (w_wrptr_r));
    dcfifo_dffpipe WRPTR_E (
        .d (w_wrptr_r), 
        .clock (rdclk), 
        .aclr (aclr),
        .q (w_wrptr_s));
    defparam
        RDPTR_D.lpm_delay = 1,
        RDPTR_D.lpm_width = lpm_widthu + 1,
        WRPTR_D.lpm_delay = 1,
        WRPTR_D.lpm_width = lpm_widthu + 1,
        WRPTR_E.lpm_delay = 1,
        WRPTR_E.lpm_width = lpm_widthu + 1;    
        
// ALWAYS CONSTRUCT BLOCK  
    always @(posedge aclr)
    begin
        i_rdptr <= 0;
        i_wrptr <= 0;
        if (((intended_device_family != `DCFIFO_STRATIX) &&
        (intended_device_family != `DEV_STRATIX) &&
        (intended_device_family != `DEV_STRATIX_GX) &&
        (intended_device_family != `DEV_CYCLONE)) ||
        ((add_ram_output_register == "ON") && (use_eab == "OFF")))
            if (lpm_showahead == "ON")
                i_q_tmp <= mem_data[0];
            else
                i_q_tmp <= 0;
    end // @(posedge aclr)
       
    // FIFOram   
    always @(rdreq or i_rdempty)
    begin
        if (underflow_checking == "OFF")
            i_rden <= rdreq;
        else
            i_rden <= rdreq && !i_rdempty;
    end // @(rdreq or i_rdempty)            
            
    always @(wrreq or i_wrfull)
    begin
        if (overflow_checking == "OFF") 
            i_wren <= wrreq;
        else
            i_wren <= wrreq && !i_wrfull;
    end // @(wrreq or i_wrfull)            

    always @(wrclk)
    begin
        if (aclr && (((intended_device_family != `DCFIFO_STRATIX) &&
        (intended_device_family != `DEV_STRATIX) &&
        (intended_device_family != `DEV_STRATIX_GX) &&
        (intended_device_family != `DEV_CYCLONE)) ||
        ((add_ram_output_register == "ON") && (use_eab == "OFF"))))
        begin
            i_data_tmp <= 0;
            i_wrptr_tmp <= 0;
            i_wren_tmp <= 0;
        end
        else if (wrclk && ($time > 0))
        begin
            i_data_tmp <= data;
            i_wrptr_tmp <= i_wrptr[lpm_widthu-1:0];
            i_wren_tmp <= i_wren;
            
            if (i_wren)
            begin
                if (~aclr && (i_wrptr < cnt_mod - 1))
                    i_wrptr <= i_wrptr + 1;
                else
                    i_wrptr <= 0;
                    
                if (use_eab == "OFF")
                begin
                    mem_data[i_wrptr[lpm_widthu-1:0]] <= data;
                    
                    if (lpm_showahead == "ON")
                        i_showahead_flag <= 1'b1;
                end                 
            end
        end
        
        if ((~wrclk && (use_eab == "ON")) && ($time > 0))
        begin
            if (i_wren_tmp)
            begin
                mem_data[i_wrptr_tmp] <= i_data_tmp;
            end
            
            if (lpm_showahead == "ON")
                i_showahead_flag <= 1'b1;
        end
    end // @(wrclk)      

    always @(rdclk)
    begin
        if (aclr && (((intended_device_family != `DCFIFO_STRATIX) &&
        (intended_device_family != `DEV_STRATIX) &&
        (intended_device_family != `DEV_STRATIX_GX) &&
        (intended_device_family != `DEV_CYCLONE)) ||
        ((add_ram_output_register == "ON") && (use_eab == "OFF"))))
        begin
            if (lpm_showahead == "ON")
                i_q_tmp <= mem_data[0];
            else
                i_q_tmp <= 0;
        end                 
        else if (rdclk && i_rden && ($time > 0))
        begin
            if (~aclr && (i_rdptr < cnt_mod - 1))
                i_rdptr <= i_rdptr + 1;                 
            else
                i_rdptr <= 0;
                
            if (lpm_showahead == "ON")
                i_showahead_flag <= 1'b1;
            else
                i_q_tmp <= mem_data[i_rdptr[lpm_widthu-1:0]];               
        end            
    end // @(rdclk)
    
    always @(posedge i_showahead_flag)
    begin
        i_q_tmp <= mem_data[i_rdptr[lpm_widthu-1:0]];
        i_showahead_flag <= 1'b0;
    end // @(posedge i_showahead_flag)         

    // Usedw, Empty, Full
    always @(i_rdptr or w_wrptr_s)
    begin
        if (w_wrptr_s >= i_rdptr)
            i_rdusedw <= w_wrptr_s - i_rdptr;
        else
            i_rdusedw <= w_wrptr_s + cnt_mod - i_rdptr;
    end // @(i_rdptr or w_wrptr_s) 

    always @(i_wrptr or w_rdptr_s)
    begin
        if (i_wrptr >= w_rdptr_s)
            i_wrusedw <= i_wrptr - w_rdptr_s;
        else
            i_wrusedw <= i_wrptr + cnt_mod - w_rdptr_s;
    end // @(i_wrptr or w_rdptr_s)
    
    always @(i_rdusedw)
    begin
        if (i_rdusedw == 0)
            i_rdempty <= 1;
        else
            i_rdempty <= 0;
                
        if (((lpm_numwords == (1 << lpm_widthu)) && i_rdusedw[lpm_widthu]) ||
        ((lpm_numwords < (1 << lpm_widthu)) && (i_rdusedw == lpm_numwords)))
            i_rdfull <= 1;
        else
            i_rdfull <= 0;
    end // @(i_rdusedw)

    always @(i_wrusedw)
    begin
        if (i_wrusedw == 0)
            i_wrempty <= 1;
        else
            i_wrempty <= 0;
                
        if (((lpm_numwords == (1 << lpm_widthu)) && i_wrusedw[lpm_widthu]) ||
        ((lpm_numwords < (1 << lpm_widthu)) && (i_wrusedw == lpm_numwords)))
            i_wrfull <= 1;
        else
            i_wrfull <= 0;
    end // @(i_wrusedw)

// CONTINOUS ASSIGNMENT
    assign rdempty = i_rdempty;
    assign wrempty = i_wrempty;
    assign rdfull = i_rdfull;
    assign wrfull = i_wrfull;
    assign wrusedw = i_wrusedw[lpm_widthu-1:0];
    assign rdusedw = i_rdusedw[lpm_widthu-1:0];
    assign q = i_q_tmp;
    
endmodule // dcfifo_sync
// END OF MODULE

//START_MODULE_NAME------------------------------------------------------------
//
// Module Name     :  dcfifo
//
// Description     :  Dual Clocks FIFO
//
// Limitation      :  
//
// Results expected:  
//
//END_MODULE_NAME--------------------------------------------------------------

// BEGINNING OF MODULE
`timescale 1 ps / 1 ps

// MODULE DECLARATION
module dcfifo (data, rdclk, wrclk, aclr, rdreq, wrreq, 
               rdfull, wrfull, rdempty, wrempty, rdusedw, wrusedw, q);

// GLOBAL PARAMETER DECLARATION
    parameter lpm_width = 1;
    parameter lpm_widthu = 1;
    parameter lpm_numwords = 2;
    parameter delay_rdusedw = 1;
    parameter delay_wrusedw = 1;
    parameter rdsync_delaypipe = 3;
    parameter wrsync_delaypipe = 3;
    parameter intended_device_family = `NON_STRATIX_FAMILY;
    parameter lpm_showahead = "OFF";
    parameter underflow_checking = "ON";
    parameter overflow_checking = "ON";
    parameter clocks_are_synchronized = "FALSE";
    parameter use_eab = "ON";
    parameter add_ram_output_register = "OFF";
    parameter add_width = 1;
    parameter lpm_hint = "USE_EAB=ON";    
    parameter lpm_type = "dcfifo";

// INPUT PORT DECLARATION
    input [lpm_width-1:0] data;
    input rdclk;
    input wrclk;
    input aclr;
    input rdreq;
    input wrreq;
    
// OUTPUT PORT DECLARATION    
    output rdfull;
    output wrfull;
    output rdempty;
    output wrempty;
    output [lpm_widthu-1:0] rdusedw;
    output [lpm_widthu-1:0] wrusedw;
    output [lpm_width-1:0] q;
    
// INTERNAL WIRE DECLARATION
    wire w_rdfull_s;
    wire w_wrfull_s;
    wire w_rdempty_s;
    wire w_wrempty_s;
    wire w_rdfull_a;
    wire w_wrfull_a;
    wire w_rdempty_a;
    wire w_wrempty_a;
    wire [lpm_widthu-1:0] w_rdusedw_s;
    wire [lpm_widthu-1:0] w_wrusedw_s;
    wire [lpm_widthu-1:0] w_rdusedw_a;
    wire [lpm_widthu-1:0] w_wrusedw_a;
    wire [lpm_width-1:0] w_q_s;
    wire [lpm_width-1:0] w_q_a;

// INTERNAL TRI DECLARATION
    tri0 aclr;
    buf (i_aclr, aclr);

// COMPONENT INSTANTIATIONS   
    dcfifo_sync SYNC (
        .data (data), 
        .rdclk (rdclk), 
        .wrclk (wrclk),
        .aclr (i_aclr), 
        .rdreq (rdreq), 
        .wrreq (wrreq),
        .rdfull (w_rdfull_s), 
        .wrfull (w_wrfull_s),
        .rdempty (w_rdempty_s), 
        .wrempty (w_wrempty_s),
        .rdusedw (w_rdusedw_s), 
        .wrusedw (w_wrusedw_s),
        .q (w_q_s));
    defparam
        SYNC.lpm_width = lpm_width,
        SYNC.lpm_widthu = lpm_widthu,
        SYNC.lpm_numwords = lpm_numwords,
        SYNC.intended_device_family = intended_device_family,
        SYNC.lpm_showahead = lpm_showahead,
        SYNC.underflow_checking = underflow_checking,
        SYNC.overflow_checking = overflow_checking,
        SYNC.use_eab = use_eab,
        SYNC.add_ram_output_register = add_ram_output_register;

    dcfifo_async ASYNC (
        .data (data), 
        .rdclk (rdclk), 
        .wrclk (wrclk),
        .aclr (i_aclr), 
        .rdreq (rdreq), 
        .wrreq (wrreq),
        .rdfull (w_rdfull_a), 
        .wrfull (w_wrfull_a),
        .rdempty (w_rdempty_a), 
        .wrempty (w_wrempty_a),
        .rdusedw (w_rdusedw_a), 
        .wrusedw (w_wrusedw_a),
        .q (w_q_a) );
    defparam
        ASYNC.lpm_width = lpm_width,
        ASYNC.lpm_widthu = lpm_widthu,
        ASYNC.lpm_numwords = lpm_numwords,
        ASYNC.delay_rdusedw = delay_rdusedw,
        ASYNC.delay_wrusedw = delay_wrusedw,
        ASYNC.rdsync_delaypipe = rdsync_delaypipe,
        ASYNC.wrsync_delaypipe = wrsync_delaypipe,
        ASYNC.intended_device_family = intended_device_family,
        ASYNC.lpm_showahead = lpm_showahead,
        ASYNC.underflow_checking = underflow_checking,
        ASYNC.overflow_checking = overflow_checking,
        ASYNC.use_eab = use_eab,
        ASYNC.add_ram_output_register = add_ram_output_register;

// CONTINOUS ASSIGNMENT
    assign rdfull = (clocks_are_synchronized == "TRUE") ? w_rdfull_s : w_rdfull_a;
    assign wrfull = (clocks_are_synchronized == "TRUE") ? w_wrfull_s : w_wrfull_a;
    assign rdempty = (clocks_are_synchronized == "TRUE") ? w_rdempty_s : w_rdempty_a;
    assign wrempty = (clocks_are_synchronized == "TRUE") ? w_wrempty_s : w_wrempty_a;
    assign rdusedw = (clocks_are_synchronized == "TRUE") ? w_rdusedw_s : w_rdusedw_a;
    assign wrusedw = (clocks_are_synchronized == "TRUE") ? w_wrusedw_s : w_wrusedw_a;
    assign q = (clocks_are_synchronized == "TRUE") ? w_q_s : w_q_a;
endmodule // dcfifo
// END OF MODULE



//--------------------------------------------------------------------------
// alt_exc_dpram
//--------------------------------------------------------------------------
//
`timescale 1 ps / 1 ps
module alt_exc_dpram (portadatain,
              portadataout,
              portaaddr,
              portawe,
              portaena,
              portaclk,
              portbdatain,
              portbdataout,
              portbaddr,
              portbwe,
              portbena,
              portbclk
              );

   // default parameters
   parameter   operation_mode = "SINGLE_PORT" ;
   parameter   addrwidth      = 14            ;
   parameter   width          = 32            ;
   parameter   depth          = 16384         ;
   parameter   ramblock       = 65535         ;
   parameter   output_mode    = "UNREG"       ;
   parameter   lpm_file       = "NONE"        ;
   parameter lpm_type = "alt_exc_dpram";
   
   // size of memory array 
  
   reg [width-1:0]        dpram_content[depth-1:0];

   // input/output signals

   input                  portawe           ,
                          portbwe           ,
                          portaena          ,
                          portbena          ,
                          portaclk          ,
                          portbclk          ;
         
   input  [width-1:0]     portadatain       ;
   input  [width-1:0]     portbdatain       ;
   
   input  [addrwidth-1:0]   portaaddr         ;
   input  [addrwidth-1:0]   portbaddr         ;
   
   output [width-1:0]     portadataout      ,
                          portbdataout      ;

   // internal signals/registers
   
   reg                    portaclk_in_last  ;
   reg                    portbclk_in_last  ;

   wire                   portaclk_in       ;
   wire                   portbclk_in       ;
   wire                   portawe_in        ;
   wire                   portbwe_in        ;
   wire                   portaena_in       ;
   wire                   portbena_in       ;
   
   wire   [width-1:0]     portadatain_in    ;
   wire   [width-1:0]     portbdatain_in    ;
   wire   [width-1:0]     portadatain_tmp   ;
   wire   [width-1:0]     portbdatain_tmp   ;
   
   wire   [addrwidth-1:0]   portaaddr_in      ;
   wire   [addrwidth-1:0]   portbaddr_in      ;
   
   reg    [width-1:0]     portadataout_tmp  ;
   reg    [width-1:0]     portbdataout_tmp  ;
   reg    [width-1:0]     portadataout_reg  ;
   reg    [width-1:0]     portbdataout_reg  ;
   reg    [width-1:0]     portadataout_reg_out  ;
   reg    [width-1:0]     portbdataout_reg_out  ;
   wire   [width-1:0]     portadataout_tmp2 ;
   wire   [width-1:0]     portbdataout_tmp2 ;
   
   reg                    portawe_latched   ;
   reg                    portbwe_latched   ;
   reg    [addrwidth-1:0]   portaaddr_latched ;
   reg    [addrwidth-1:0]   portbaddr_latched ;

   // assign to internal signals

   assign portadatain_in = portadatain;  
   assign portaaddr_in   = portaaddr;
   assign portaena_in    = portaena;
   assign portaclk_in    = portaclk;
   assign portawe_in     = portawe;

   assign portbdatain_in = portbdatain;  
   assign portbaddr_in   = portbaddr;
   assign portbena_in    = portbena;
   assign portbclk_in    = portbclk;
   assign portbwe_in     = portbwe;

  
   //  Dual Port Contention  Port A address = Port B address
   // 
   // +-----------+----------+-------------+-------------+--------------+--------------+---------------------+
   // |  Port A   |  Port B  |  A Data In  |  B Data In  |  A Data Out  |  B Data Out  |     Memory State    |
   // +-----------+----------+-------------+-------------+--------------+--------------+---------------------+
   // |   read    |   read   |     DA      |     DB      |    memory    |    memory    |      no change      |
   // +-----------+----------+-------------+-------------+--------------+--------------+---------------------+
   // |   write   |   read   |     DA      |     DB      |    unknown   |    unknown   |    memory <= DA     |
   // +-----------+----------+-------------+-------------+--------------+--------------+---------------------+
   // |   read    |   write  |     DA      |     DB      |    unknown   |    unknown   |    memory <= DB     |
   // +-----------+----------+-------------+-------------+--------------+--------------+---------------------+
   // |   write   |   write  |     DA      |     DB      |    unknown   |    unknown   |  memory <= unknown  |
   // +-----------+----------+-------------+-------------+--------------+--------------+---------------------+ 
   //  
   //  Dual Port Contention  Port A address != Port B address
   // 
   // +-----------+----------+-------------+-------------+--------------+--------------+---------------------+
   // |  Port A   |  Port B  |  A Data In  |  B Data In  |  A Data Out  |  B Data Out  |     Memory State    |
   // +-----------+----------+-------------+-------------+--------------+--------------+---------------------+
   // |   read    |   read   |     DA      |     DB      |  mem[A_addr] |  mem[B_Addr] |      no change      |
   // +-----------+----------+-------------+-------------+--------------+--------------+---------------------+
   // |   write   |   read   |     DA      |     DB      |    unknown   |  mem[B_Addr] |  mem[A_Addr] <= DA  |
   // +-----------+----------+-------------+-------------+--------------+--------------+---------------------+
   // |   read    |   write  |     DA      |     DB      |  mem[A_addr] |    unknown   |  mem[B_Addr] <= DB  |
   // +-----------+----------+-------------+-------------+--------------+--------------+---------------------+
   // |   write   |   write  |     DA      |     DB      |    unknown   |    unknown   |  mem[A_Addr] <= DA  |
   // |           |          |             |             |              |              |  mem[B_Addr] <= DB  |
   // +-----------+----------+-------------+-------------+--------------+--------------+---------------------+ 
   // 
   // NB: Output state is always unknown when writing. 


   initial
     begin
         // Initialise dpram memory contents from file (if filename specified). 
         if (lpm_file != "NONE" && lpm_file != "none") $readmemh(lpm_file, dpram_content);

     portaclk_in_last = 0;
     portbclk_in_last = 0;
     end
    
   always @(portaclk_in)
      begin
      if (portaclk_in != 0 && portaclk_in_last == 0)  // rising edge port a clock
         begin

         portawe_latched   = portawe_in   ;
         portaaddr_latched = portaaddr_in ;
         
         if (portawe_latched == 'b0)
            begin

            // reading A 

            if (portaaddr_latched == portbaddr_latched && portbwe_latched != 'b0)
               begin

               // B simultaneously writing to same address (effect of B write to memory handled below)

               portadataout_reg = portadataout_tmp;
               portadataout_tmp = 'bx;

               end
            else
               begin

               // B reading from same address, or reading/writing to different address. 

               portadataout_reg = portadataout_tmp;
               portadataout_tmp = dpram_content[portaaddr_latched];

               end
            end

         else

            // writing to A

            begin
            if (portaaddr_latched == portbaddr_latched && portawe_latched != 'b0 && portbwe_latched != 'b0)
               begin

               // A and B simultaneously writing to same address

               portadataout_reg                 = portadataout_tmp ;
               dpram_content[portaaddr_latched] = 'bx              ;
               portadataout_tmp                 = 'bx              ;

               end
            else
               begin

               // B reading from same address or reading/writing to different address

               portadataout_reg                 = portadataout_tmp;
               dpram_content[portaaddr_latched] = portadatain_tmp ;
               portadataout_tmp                 = 'bx             ;

               end
            end // writing to A 
         end // rising edge port a clock
         portaclk_in_last = portaclk_in;
   end // portaclk_in change event 

   always @(portbclk_in)
   begin
         if (portbclk_in != 0 && portbclk_in_last == 0 && (operation_mode == "DUAL_PORT" || operation_mode == "dual_port"))  // rising edge port b clock
            begin   

            portbwe_latched   = portbwe_in   ;
            portbaddr_latched = portbaddr_in ;
         
            if (portbwe_latched == 'b0)
               begin

               // reading B 

               if (portbaddr_latched == portaaddr_latched && portawe_latched != 'b0)
                  begin

                  // A simultaneously writing to same address (effect of A write to memory handled above)

                  portbdataout_reg = portbdataout_tmp;
                  portbdataout_tmp = 'bx;

                  end
               else
                  begin

                  // A reading from same address, or reading/writing to different address. 

                  portbdataout_reg = portbdataout_tmp;
                  portbdataout_tmp = dpram_content[portbaddr_latched];

                  end
               end
            else

               // writing to B

               begin
               if (portbaddr_latched == portaaddr_latched && portbwe_latched != 'b0 && portawe_latched != 'b0)
                  begin

                  // B and A simultaneously writing to same address

                  portbdataout_reg                 = portbdataout_tmp ;
                  dpram_content[portbaddr_latched] = 'bx              ;
                  portbdataout_tmp                 = 'bx              ;

                  end
               else
                  begin

                  // A reading from same address or reading/writing to different address

                  portbdataout_reg                 = portbdataout_tmp;
                  dpram_content[portbaddr_latched] = portbdatain_tmp ;
                  portbdataout_tmp                 = 'bx             ;

                  end
               end // writing to B
            end // rising edge port B clock

            portbclk_in_last = portbclk_in;

         end // portbclk_in change event
   
   // registered Port A output enabled ?

   always @(portaena_in or portadataout_reg)
   begin
       if (output_mode == "REG" || output_mode == "reg") 
           if ( portaena_in == 1'b1 )
               portadataout_reg_out = portadataout_reg ; 
   end

   // registered Port B output enabled ?

   always @(portbena_in or portbdataout_reg)
   begin
       if (output_mode == "REG" || output_mode == "reg") 
           if ( portbena_in == 1'b1 )
               portbdataout_reg_out = portbdataout_reg ; 
   end

   // Registered or Unregistered mode ?

   assign portadataout_tmp2 = (output_mode == "REG" || output_mode == "reg") ? portadataout_reg_out[width-1:0] : portadataout_tmp[width-1:0];
   assign portbdataout_tmp2 = (output_mode == "REG" || output_mode == "reg") ? portbdataout_reg_out[width-1:0] : portbdataout_tmp[width-1:0];

   assign portadatain_tmp[width-1:0] = portadatain;
   assign portbdatain_tmp[width-1:0] = portbdatain;

   assign portadataout = portadataout_tmp2;
   assign portbdataout = portbdataout_tmp2;

   
endmodule // alt_exc_dpram


//--------------------------------------------------------------------------
// Altera UP Core 
//--------------------------------------------------------------------------
//
`timescale 1 ps / 1 ps

module alt_exc_upcore (
            intpld, intuart, inttimer0, inttimer1, intcommtx, intcommrx, intproctimer, intprocbridge,
            debugrq, debugext0, debugext1, debugiebrkpt, debugdewpt, debugextin, debugack,
            debugrng0, debugrng1, debugextout,

            slavehclk,
            slavehwrite, slavehreadyi, slavehselreg, slavehsel, slavehmastlock, slavehaddr,
            slavehwdata, slavehtrans, slavehsize, slavehburst, slavehreadyo, slavebuserrint,
            slavehrdata, slavehresp,

            masterhclk,
            masterhrdata, masterhresp, masterhwrite, masterhlock, masterhbusreq, masterhaddr,
            masterhwdata, masterhtrans, masterhsize, masterhready, masterhburst, masterhgrant,

            lockreqdp0, lockreqdp1,
            lockgrantdp0, lockgrantdp1,

            ebiack, ebiwen, ebioen, ebiclk, ebibe, ebicsn, ebiaddr, ebidq,

            uarttxd, uartrtsn, uartdtrn, uartctsn, uartdsrn, uartrxd, uartdcdn,
            uartrin, 

            sdramclk, sdramclkn, sdramclke, sdramwen, sdramcasn, sdramrasn, sdramdqm,            
            sdramaddr, sdramdq, sdramdqs, sdramcsn,


            intextpin, traceclk, tracesync, tracepipestat, tracepkt, clk_ref, intnmi, perreset,
        npor, nreset, gpi, gpo
            );

  parameter    processor = "ARM";
  parameter    source    = "";
  parameter    sdram_width    = 32;
  parameter    sdramdqm_width = 4;
  parameter    gpio_width     = 4;
  parameter lpm_type = "alt_exc_upcore";

  // AHB2 Master and Slave bridges
  // Interupt, debug and trace ports
  // DP Ram locks

  input         slavehclk, masterhclk;

  input         slavehwrite, slavehreadyi, slavehselreg, slavehsel,
                slavehmastlock, masterhready, masterhgrant;

  input         lockreqdp0, lockreqdp1, 
                debugrq, debugext0, debugext1, debugiebrkpt, debugdewpt;

  input  [31:0] slavehaddr, slavehwdata, masterhrdata;
  input   [1:0] slavehtrans, slavehsize, masterhresp;
  input   [3:0] debugextin;
  input   [5:0] intpld;
  input   [2:0] slavehburst;

  output        masterhwrite, masterhlock,  masterhbusreq, slavehreadyo, slavebuserrint,
                intuart,      inttimer0,    inttimer1,     intcommtx,     intcommrx,       
                debugack,     debugrng0,    debugrng1,
                lockgrantdp0, lockgrantdp1;

  output [31:0] masterhaddr, masterhwdata, slavehrdata;
  output  [1:0] masterhtrans, masterhsize, slavehresp;
  output  [2:0] masterhburst;
  output  [3:0] debugextout;

  // Shared IO connections
  // EBI Expansion bus
  // SDRAM interface
  // UART and trace port

  input         ebiack;
  output        ebiwen, ebioen, ebiclk;
  output  [1:0] ebibe;
  output  [3:0] ebicsn;
  output [24:0] ebiaddr;
  inout  [15:0] ebidq;

  input         uartctsn,  uartdsrn, uartrxd; 
  output        uarttxd,   uartrtsn, uartdtrn;
  inout         uartdcdn, uartrin;
          
  output        sdramclk, sdramclkn, sdramclke,
                sdramwen, sdramcasn, sdramrasn;
  output  [1:0] sdramcsn;
  output  [sdramdqm_width-1:0] sdramdqm;     
  output [14:0] sdramaddr;
  
  inout  [sdram_width-1:0] sdramdq;
  inout  [sdramdqm_width-1:0] sdramdqs;                 
          
  input         intextpin;
  output        traceclk, tracesync;
  output  [2:0] tracepipestat;
  output [15:0] tracepkt;

  input     clk_ref, npor;
  inout         nreset;
  output    intproctimer, intprocbridge;
  output    perreset;
  input     intnmi;
  input  [gpio_width-1:0] gpi;
  output [gpio_width-1:0] gpo;
   
   
  /////////////////////////////////////////////////////////////////////////////////////////////////
  // AHB Constants
  /////////////////////////////////////////////////////////////////////////////////////////////////

// responses (HRESP)
`define H_OKAY   2'b00
`define H_ERROR  2'b01
`define H_RETRY  2'b10
`define H_SPLIT  2'b11

// transcation types  (HTRANS)
`define H_IDLE   2'b00
`define H_BUSY   2'b01
`define H_NONSEQ 2'b10
`define H_SEQ    2'b11

// burst mode (HBURST)
`define H_SINGLE 3'b000
`define H_INCR   3'b001
`define H_WRAP4  3'b010
`define H_INCR4  3'b011
`define H_WRAP8  3'b100
`define H_INCR8  3'b101
`define H_WRAP16 3'b110
`define H_INCR16 3'b111

// transaction sizes (HSIZE 8,16,32 bits -- larger sizes not supported)
`define H_BYTE   2'b00
`define H_HWORD  2'b01
`define H_WORD   2'b10

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // slave port
  /////////////////////////////////////////////////////////////////////////////////////////////////

  wire          slavehclk_in;
  wire          slavehwrite_in, slavehreadyi_in, slavehselreg_in, slavehsel_in,
                slavehmastlock_in;
  wire   [31:0] slavehaddr_in, slavehwdata_in;
  wire    [1:0] slavehtrans_in, slavehsize_in;
  wire    [2:0] slavehburst_in;
  wire          slavehreadyo_out, slavebuserrint_out;
  wire   [31:0] slavehrdata_out;
  wire    [1:0] slavehresp_out;

  //
  assign slavehclk_in      = slavehclk     ;
  assign slavehwrite_in    = slavehwrite   ;
  assign slavehreadyi_in   = slavehreadyi  ;
  assign slavehselreg_in   = slavehselreg  ;
  assign slavehsel_in      = slavehsel     ;
  assign slavehmastlock_in = slavehmastlock;
  
  assign slavehaddr_in     = slavehaddr;
  
  assign slavehwdata_in    = slavehwdata;

  assign slavehtrans_in    = slavehtrans;
  assign slavehsize_in     = slavehsize;
  assign slavehburst_in    = slavehburst;

  // 
  assign slavehreadyo  = slavehreadyo_out;
  assign slavebuserrint= slavebuserrint_out;

  assign slavehrdata   = slavehrdata_out;
  assign slavehresp    = slavehresp_out;

  /////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////////////////

  // outputs
  reg         slavehreadyo_out_r ;
  reg [1:0]   slavehresp_out_r   ;

  assign      slavehreadyo_out =  slavehreadyo_out_r ;
  assign      slavehresp_out   =  slavehresp_out_r   ;


  // record of address and control information (latched on address phase)
  reg [31:0]   startReg;            // start address for burst
  reg [31:0]   addrReg;
  reg  [1:0]   transReg;
  reg  [1:0]   sizeReg;
  reg          writeReg;
  reg  [2:0]   burstReg;
  reg          selReg;
  reg  [7:0]   waitReg;
  
  // Implement 6 banks of 256K = (1.5MB of address space)
  // ///////////////////////////////////////////////////////////////////
  reg [79:0]  memCfg[0:5];        // slavememory.cfg.dat
  reg [31:0]  memStart[0:5];
  reg [31:0]  memEnd[0:5];
  reg  [7:0]  memWaitStart[0:5];
  reg  [7:0]  memWait[0:5];
  reg [31:0]  memMapA[0:65535];    // slavememory.0.dat
  reg [31:0]  memMapB[0:65535];
  reg [31:0]  memMapC[0:65535];
  reg [31:0]  memMapD[0:65535];
  reg [31:0]  memMapE[0:65535];
  reg [31:0]  memMapF[0:65535];    // slavememory.5.dat

  reg  [2:0]  memBank;
  reg [79:0]  temp;
  
  integer output_file ; 

  initial begin

      // Open the results file
      output_file = $fopen("output.dat") ;
      if ( !output_file )
           $display("ERROR: Cannot open Output File") ;

  
      // Initialise memory banks from config and map files
      //////////////////////////////////////////////////////////////////////
      temp=80'h00000000_00000000_00_00;
      for (memBank=0;memBank<6;memBank=memBank+1)
      begin
          memCfg[memBank]=temp;
      end

      // 79..48 start address
      // 47..16 end address
      // 15...8 wait states on first access
      //  7...0 wait states per cycle
      $readmemh("slavememory.cfg.dat", memCfg);        
      for (memBank=0;memBank<6;memBank=memBank+1)
      begin
          temp=memCfg[memBank];
          memStart[memBank]     =temp[79:48];
          memEnd[memBank]       =temp[47:16];
          memWaitStart[memBank] =temp[15:8];
          memWait[memBank]      =temp[7:0];
      end
      
      if (memStart[0]!=memEnd[0]) $readmemh("slavememory.0.dat", memMapA);
      if (memStart[1]!=memEnd[1]) $readmemh("slavememory.1.dat", memMapB);
      if (memStart[2]!=memEnd[2]) $readmemh("slavememory.2.dat", memMapC);
      if (memStart[3]!=memEnd[3]) $readmemh("slavememory.3.dat", memMapD);
      if (memStart[4]!=memEnd[4]) $readmemh("slavememory.4.dat", memMapE);
      if (memStart[5]!=memEnd[5]) $readmemh("slavememory.5.dat", memMapF);
      //////////////////////////////////////////////////////////////////////
  
      addrReg=0;
      transReg=`H_IDLE;
      sizeReg=`H_WORD;
      writeReg=0;
      burstReg=`H_NONSEQ;
      selReg=0;

      slavehresp_out_r=`H_OKAY;
  end


  // select signal
  wire    sel = slavehsel_in & slavehreadyi_in;

  // determine if the transaction includes an operation / a "busy"
  wire doWork     = selReg & ((transReg==`H_NONSEQ || transReg==`H_SEQ) ? 1'b1 : 1'b0);
  wire doBusyWork = selReg & ( transReg==`H_BUSY                        ? 1'b1 : 1'b0);


  // BURST MODE SUPPORT
  ///////////////////////////////////////////////////////////////////////////////
  //
  // If we are in burst mode we'll compute our own address and control settings
  // based on the spec.
  //
  // compute values SEQuential (burst) transfers
  wire    seqTrans =  ( selReg & 
                      ( doWork | doBusyWork) & 
                      ( (slavehtrans_in==`H_SEQ || slavehtrans_in==`H_BUSY) ) ? 1'b1 : 1'b0 );
                      

  // mask to determine which bits are retained from the start address
  wire [31:0] wrapmask;
  assign wrapmask =
          ( burstReg==`H_WRAP4  ? {32{1'b1}} << 2:    // all but 2
          ( burstReg==`H_WRAP8  ? {32{1'b1}} << 3:    // all but 3
          ( burstReg==`H_WRAP16 ? {32{1'b1}} << 4:    // all but 4
                                  {32{1'b0}} ) ));    // none
  wire [31:0] wrapmask_w;
  assign wrapmask_w =                                // correct for word size
          ( sizeReg==`H_WORD  ? wrapmask<<2 :
          ( sizeReg==`H_HWORD ? wrapmask<<1 : 
                   /* H_BYTE */ wrapmask         ));
  
  wire [31:0] seqPlusAddr;                // work out the next sequential address
  assign seqPlusAddr =
          ( burstReg == `H_SINGLE) ?  addrReg :
               addrReg +     ( sizeReg==`H_BYTE  ? 1 : 
                          ( sizeReg==`H_HWORD ? 2 : 
                          ( sizeReg==`H_WORD  ? 4 : 0) ) ) ;

  wire [31:0] seqAddr;                    // apply the mask to wrap at boundaries
  assign seqAddr = (slavehtrans_in==`H_BUSY) ? addrReg :
                  ( (startReg&wrapmask_w) | (seqPlusAddr&~wrapmask_w));
                                      
  //
  // if this is a sequential transaction only sample HTRANS
  wire [31:0] startNext;
  wire [31:0] addrNext;
  wire  [1:0] transNext;
  wire  [1:0] sizeNext;
  wire  [2:0] burstNext;
  wire        writeNext;    

  assign startNext = seqTrans ? startReg : slavehaddr_in;
  assign addrNext  = seqTrans ? seqAddr  : slavehaddr_in;
  assign transNext = slavehtrans_in;
  assign sizeNext  = seqTrans ? sizeReg  : slavehsize_in;
  assign burstNext = seqTrans ? burstReg : slavehburst_in;
  assign writeNext = seqTrans ? writeReg : slavehwrite_in;


  // Latch the control data if we are selected
  ///////////////////////////////////////////////////////////////////////////////////
  always @ (posedge slavehclk_in)
  begin
      // if readin is low another device is wait stating its
      // data phase and hence extending our address phase
      if (slavehreadyi_in)
      begin
          selReg <= sel;
          if (sel)            // latch the control data
          begin
              startReg <= startNext;
              addrReg  <= addrNext;
              transReg <= transNext;
              sizeReg  <= sizeNext;
              writeReg <= writeNext;
              burstReg <= burstNext;
          end
          else
          begin
              startReg <= 0;
              addrReg  <= 0;
              transReg <= `H_IDLE;
              sizeReg  <= `H_WORD;
              writeReg <= 0;
              burstReg <= `H_SINGLE;
          end
      end
  end


  // Implment memory banks
  ///////////////////////////////////////////////////////////////////////////////////
  // bank selects
  wire bankA = ( addrReg>=memStart[0] && addrReg<=memEnd[0] && memStart[0]!=memEnd[0]) ? 1'b1 : 1'b0;
  wire bankB = ( addrReg>=memStart[1] && addrReg<=memEnd[1] && memStart[1]!=memEnd[1]) ? 1'b1 : 1'b0;
  wire bankC = ( addrReg>=memStart[2] && addrReg<=memEnd[2] && memStart[2]!=memEnd[2]) ? 1'b1 : 1'b0;    
  wire bankD = ( addrReg>=memStart[3] && addrReg<=memEnd[3] && memStart[3]!=memEnd[3]) ? 1'b1 : 1'b0;    
  wire bankE = ( addrReg>=memStart[4] && addrReg<=memEnd[4] && memStart[4]!=memEnd[4]) ? 1'b1 : 1'b0;    
  wire bankF = ( addrReg>=memStart[5] && addrReg<=memEnd[5] && memStart[5]!=memEnd[5]) ? 1'b1 : 1'b0;    
  
  // byte offset into bank                         //word offset into bank
  wire [31:0] offsetA = addrReg-memStart[0];        wire [15:0] wordA = offsetA[17:2];
  wire [31:0] offsetB = addrReg-memStart[1];        wire [15:0] wordB = offsetB[17:2];
  wire [31:0] offsetC = addrReg-memStart[2];        wire [15:0] wordC = offsetC[17:2];
  wire [31:0] offsetD = addrReg-memStart[3];        wire [15:0] wordD = offsetD[17:2];
  wire [31:0] offsetE = addrReg-memStart[4];        wire [15:0] wordE = offsetE[17:2];
  wire [31:0] offsetF = addrReg-memStart[5];        wire [15:0] wordF = offsetF[17:2];

  // current data
  wire [31:0] dataA   = memMapA[wordA];  
  wire [31:0] dataB   = memMapB[wordB];  
  wire [31:0] dataC   = memMapC[wordC];  
  wire [31:0] dataD   = memMapD[wordD];  
  wire [31:0] dataE   = memMapE[wordE];  
  wire [31:0] dataF   = memMapF[wordF];  

  reg  [31:0] currentVal;
  always @(dataA or dataB or dataC or dataD or dataE or dataF or 
           bankA or bankB or bankC or bankD or bankE or bankF  )
  begin
         if (bankA) currentVal=dataA;
    else if (bankB) currentVal=dataB;
    else if (bankC) currentVal=dataC;
    else if (bankD) currentVal=dataD;
    else if (bankE) currentVal=dataE;
    else if (bankF) currentVal=dataF;
  end
    

  // byte enables
  wire be0 = ( sizeReg==`H_WORD                         || 
              (sizeReg==`H_HWORD && addrReg[1]==1'b0)   || 
              (sizeReg==`H_BYTE  && addrReg[1:0]==2'b00) ) ? 1'b1 : 1'b0;
  wire be1 = ( sizeReg==`H_WORD                         || 
              (sizeReg==`H_HWORD && addrReg[1]==1'b0)   || 
              (sizeReg==`H_BYTE  && addrReg[1:0]==2'b01) ) ? 1'b1 : 1'b0;
  wire be2 = ( sizeReg==`H_WORD                         || 
              (sizeReg==`H_HWORD && addrReg[1]==1'b1)   || 
              (sizeReg==`H_BYTE  && addrReg[1:0]==2'b10) ) ? 1'b1 : 1'b0;
  wire be3 = ( sizeReg==`H_WORD                         || 
              (sizeReg==`H_HWORD && addrReg[1]==1'b1)   || 
              (sizeReg==`H_BYTE  && addrReg[1:0]==2'b11) ) ? 1'b1 : 1'b0;
              
  wire [31:0] readDataMask = { be3 ? 8'hFF : 8'h00,
                                 be2 ? 8'hFF : 8'h00,
                                 be1 ? 8'hFF : 8'h00,
                                 be0 ? 8'hFF : 8'h00 };



  // wait state generation
  ///////////////////////////////////////////////////////////////////////////////////

  reg         s_addr_latch;      // address latched this cycle
  reg   [7:0] waitStart;
  reg   [7:0] waitSeq;

  initial begin 
      s_addr_latch=1'b0;
      waitReg=8'h00;
  end

  always @(bankA or bankB or bankC or bankD or bankE or bankF  )
  begin
         if (bankA) waitStart = memWaitStart[0];
    else if (bankB) waitStart = memWaitStart[1];
    else if (bankC) waitStart = memWaitStart[2];
    else if (bankD) waitStart = memWaitStart[3];
    else if (bankE) waitStart = memWaitStart[4];
    else if (bankF) waitStart = memWaitStart[5];
  end

  always @(bankA or bankB or bankC or bankD or bankE or bankF  )
  begin
         if (bankA) waitSeq = memWait[0];
    else if (bankB) waitSeq = memWait[1];
    else if (bankC) waitSeq = memWait[2];
    else if (bankD) waitSeq = memWait[3];
    else if (bankE) waitSeq = memWait[4];
    else if (bankF) waitSeq = memWait[5];
  end


  //
  // wait if 
  //    first beat and memWaitStart and addr has just been latched
  // or
  //    first beat and waitReg (more than 1 wait state)
  // or     
  //    seq beat and waitReg
  // else ready
  //

  always @(posedge slavehclk_in)
    s_addr_latch <= slavehreadyi_in & slavehsel_in;

  always @(doWork or transReg or waitReg or waitStart or s_addr_latch)
  begin
    if ( doWork & (transReg==`H_NONSEQ) & (waitStart!=8'h00) & s_addr_latch )
      begin
      slavehreadyo_out_r = 1'b0;
      // $fdisplay(output_file, "SLAVE: wait on first" );
      end
    else if ( doWork & (transReg==`H_NONSEQ) & waitReg!=8'h00 )
      begin
      slavehreadyo_out_r = 1'b0;
      // $fdisplay(output_file, "SLAVE: wait" );
      end
    else if (doWork & (transReg==`H_SEQ) & (waitReg!=8'h00))
      begin
      slavehreadyo_out_r = 1'b0;
      // $fdisplay(output_file, "SLAVE: wait" );
      end
    else
      slavehreadyo_out_r = 1'b1;
  end


  // if we are waiting (waitReg>0) and not in a busy decrement the counter
  // otherwise get the new value from memWait of memWaitStart according to
  // the transaction type 
  
  wire [7:0] waitStartNext;
  assign waitStartNext = ( waitStart>8'h01  ? (waitStart-1) : 8'h00);

  always @ (posedge slavehclk_in)
    waitReg<=  (waitReg!=8'h00 & ~doBusyWork) ? (waitReg - 1'b1)  :
       ( doWork & (transReg==`H_NONSEQ) & (waitStart!=8'h00) & s_addr_latch ? waitStartNext :
       ( seqTrans ? waitSeq : 8'h00 ));


  // read data
  ///////////////////////////////////////////////////////////////////////////////////
  assign slavehrdata_out = (doWork & ~writeReg & slavehreadyo_out_r) ? 
                              (readDataMask & currentVal) : {32{1'b0}};


              
  // record writes in memory banks   + report on screen
  ///////////////////////////////////////////////////////////////////////////////////
  reg  [31:0] memWord;        // the word to be updated / read 
  always @ (posedge slavehclk_in)
  begin
      if (doWork & slavehreadyo_out_r)
      begin
        memWord = currentVal;
        if (writeReg)
        begin
          if (be0) memWord[7:0]   =slavehwdata_in[7:0]  ;
          if (be1) memWord[15:8]  =slavehwdata_in[15:8] ;
          if (be2) memWord[23:16] =slavehwdata_in[23:16];                        
          if (be3) memWord[31:24] =slavehwdata_in[31:24];
          
          if (bankA) memMapA[wordA] = memWord;
          if (bankB) memMapB[wordB] = memWord;
          if (bankC) memMapC[wordC] = memWord;
          if (bankD) memMapD[wordD] = memWord;
          if (bankE) memMapE[wordE] = memWord;
          if (bankF) memMapF[wordF] = memWord;
        end
        if (output_file)  
        $fdisplay(output_file,
        "SLAVE:                 addr=[%h] %s data=[%h]                          %s",
          addrReg,
          writeReg ? "WRITE" : "READ",
          writeReg ? slavehwdata_in : slavehrdata_out ,
          sizeReg==`H_BYTE ? "BYTE" : 
                      ( sizeReg==`H_HWORD ? "HALF WORD" : "WORD" ) );
        else 
        $display(
        "SLAVE:                 addr=[%h] %s data=[%h]                          %s",
          addrReg,
          writeReg ? "WRITE" : "READ",
          writeReg ? slavehwdata_in : slavehrdata_out ,
          sizeReg==`H_BYTE ? "BYTE" : 
                      ( sizeReg==`H_HWORD ? "HALF WORD" : "WORD" ) );

      end
  end

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Master Port transactor
  /////////////////////////////////////////////////////////////////////////////////////////////////

  // timing data - setup and holds
  ////////////////////////////////
  wire          masterhclk_in;
  wire          masterhready_in, masterhgrant_in;
  wire   [31:0] masterhrdata_in;
  wire    [1:0] masterhresp_in;
  wire          masterhwrite_out, masterhlock_out, masterhbusreq_out;
  wire   [31:0] masterhaddr_out, masterhwdata_out;
  wire    [1:0] masterhtrans_out, masterhsize_out;
  wire    [2:0] masterhburst_out;

  // 
  assign masterhclk_in   = masterhclk;
  assign masterhready_in = masterhready;
  assign masterhgrant_in = masterhgrant;

  assign masterhrdata_in = masterhrdata;
  assign masterhresp_in  = masterhresp;

  //
  assign masterhwrite    = masterhwrite_out;
  assign masterhlock     = masterhlock_out;
  assign masterhbusreq   = masterhbusreq_out;

  assign masterhtrans    = masterhtrans_out;
  assign masterhsize     = masterhsize_out;
  assign masterhburst    = masterhburst_out;

  assign masterhaddr     = masterhaddr_out;
  assign masterhwdata    = masterhwdata_out;


  /////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////////////////

  // Transaction Record Format
  // 255..254 spare
  // 253..252 response
  // 251..220 read data
  //      219 go busy 
  // 218..217 spare
  // 216..208 number of beats in sequential transaction
  // 207..176 start address of transaction
  // 175..144 expected data
  // 143..128 transaction number
  // ------------------------------------- following field read from command file
  // 127..112 spare
  // 111..109 spare
  //      108 bus command (0 => inactive)
  // 107.. 76 address
  //  75.. 73 spare
  //       72 write
  //  71.. 40 write data / expected read data
  //  39.. 37 spare
  //       36 lock (not implemented)
  //  35.. 33 spare
  //       32 check expected data (not implemented)
  //  31.. 30 spare
  //  29.. 28 transaction type
  //  27.. 23 spare
  //  21.. 20 burst type
  //  19.. 18 spare
  //  17.. 16 size
  //  15.. 00 repeat count

  // register outputs
  reg [31:0] masterhaddr_out_r;
  reg [31:0] masterhwdata_out_r;
  reg  [2:0] masterhburst_out_r;
  reg  [1:0] masterhtrans_out_r;
  reg        masterhwrite_out_r;
  
  assign masterhaddr_out  = masterhaddr_out_r;
  assign masterhwdata_out = masterhwdata_out_r;
  assign masterhburst_out = masterhburst_out_r;
  assign masterhtrans_out = masterhtrans_out_r;
  assign masterhwrite_out = masterhwrite_out_r;
  
  reg [2:0] masterhsize_outl;                // the transactor implements the full 3 bit size
  assign masterhsize_out=masterhsize_outl[1:0];    // field but upCore only uses 2


  // ////////////////////////////////////////////////////////////////////////////////////////////
  // 
  reg [128:0] transactions[1:65535];        // space for NUMTRANS transactions
  reg [128:0] tmp_transaction;
  reg   [8:0] tmp_beats, tmp_num;
  
  // Transaction records
  reg [255:0] n_trans;            // next
  reg [255:0] c_trans;            // control / address phase
  reg [255:0] d_trans;            // data phase
  reg [255:0] retry_trans;        // retrying
  reg [255:0] r_trans;            // reporting
  
  reg [255:0] i_trans;            // IDLE Transaction
  
  reg [15:0]  trans_num;          // the current control phase transaction
  reg [31:0]  resp_data;

/*----------------------------------------------------------------------------
 Control signals for master transactor
----------------------------------------------------------------------------*/
  reg         reset;    
  wire        start                 = n_trans[108];
  wire        stop                  = 1'b0;         
  wire        continue_after_error  = 1'b1;         
  wire        generate_data         = 1'b0;         
  wire [1:0]  insert_busy           = 2'b00;         
  wire        go_busy               = n_trans[219];     
  wire [8:0]  beats                 = n_trans[216:208];        // 511 beats max
  wire [2:0]  burst                 = n_trans[23:20];
  wire [2:0]  size                  = n_trans[18:16];
  wire        write                 = n_trans[72];
  wire [31:0] start_address         = n_trans[207:176];
  wire [31:0] data                  = n_trans[71:40];        


/*----------------------------------------------------------------------------
Transactor state and responses
----------------------------------------------------------------------------*/
  reg [2:0]     original_burst;
  reg           masterhgrant_in_r;
  reg [1:0]     busy_states;
  reg [1:0]     busy_counter;
  reg [9:0]     init_wrap_mask, wrap_mask;
  reg [7:0]     masterhaddr_out_r_inc, init_wrap_boundary_bit;
  reg [10:0]    init_next_masterhaddr_out_r, wrap_boundary_bit;
  reg [9:0]     next_masterhaddr_out_r;
  wire          break_wrap;

  reg           address_bus_owned, data_bus_owned;
  reg           add_go, data_go;
  reg           reading, writing;
  reg           first_beat, need_retry, wrap, replay_wrap;
  reg           new_grant;
  wire          first_masterhtrans_out_r;
  wire          addr_ack;
  wire          data_ack;

/*----------------------------------------------------------------------------
 Initialisation 
----------------------------------------------------------------------------*/
  initial
  begin
    i_trans         ={256{1'b0}};    // set up a null transaction record
    i_trans[143:128]=16'hFFFF; 
    i_trans[29:28]  =`H_IDLE;
          
    d_trans=i_trans;                // fill pipe with null's
    c_trans=i_trans;
    r_trans=i_trans;
                                  // initialise the transactions database
    tmp_transaction={128{1'b0}};
  
    // we're using the bus functional language so load the commands
    // from a file
    for (trans_num=1;trans_num<65535;trans_num=trans_num+1)
    begin
      transactions[trans_num]=tmp_transaction;
    end
    $readmemh("mastercommands.dat", transactions);        
   
    tmp_num = 9'b000000000;
    tmp_beats = 9'b000000000;
    trans_num=16'h0000;        

    n_trans=i_trans;
    n_trans[2]=1'b1; // repeat 4

        reset=0;                   // reset the transactor on start
    #10 reset=1;
    #20 reset=0; 

  end
  


/*----------------------------------------------------------------------------
  Report completed transactions

  We could mask and shift the received data for HALFWORD and BYTE
  transactions but we won't.
----------------------------------------------------------------------------*/
         // received data
  /****
  wire [31:0] r_r_data = r_trans[72]==1'b1 ? r_trans[71:40] : r_trans[251:220];
  wire [31:0] e_r_data = r_trans[175:144];
  wire [31:0] mr_r_data, me_r_data; // byte lane masked recovered and expected

  mr_r_data = r_trans[17:16] == `H_WORD  ? r_r_data :
             (r_trans[17:16] == `H_HWORD ? 
             { 16'h0000, (r_trans[77]==1'b1 ? r_r_data[31:16] : r_r_data[15:0]) } :
             // byte
             { 24'h000000, (r_trans[77:76]==2'b00 ? r_r_data[7:0] :
                            r_trans[77:76]==2'b01 ? r_r_data[15:8] :
                            r_trans[77:76]==2'b10 ? r_r_data[23:16] :
                                                    r_r_data[31:24]) } );

  r_rdata  =  r_trans[17:16] == `H_WORD  ? r_e_data :
             (r_trans[17:16] == `H_HWORD ? 
             { 16'h0000, (r_trans[77]==1'b1 ? r_e_data[31:16] : r_e_data[15:0]) } :
             // byte
             { 24'h000000, (r_trans[77:76]==2'b00 ? r_e_data[7:0] :
                            r_trans[77:76]==2'b01 ? r_e_data[15:8] :
                            r_trans[77:76]==2'b10 ? r_e_data[23:16] :
                                                    r_e_data[31:24]) } );
  ****/
  always @(posedge masterhclk_in)
  begin
   if (r_trans[108]==1'b1) // r_trans contains a valid transaction
   begin
 
     if (output_file)  
      $fdisplay(output_file,
        "MASTER: trans=[%d]  addr=[%h] %s data=[%h]   expected=[%h]    %s %s",
        r_trans[143:128],
        r_trans[107:76],
        r_trans[72]==1'b1 ? "WRITE" : "READ",
        r_trans[72]==1'b1 ? r_trans[71:40] : r_trans[251:220],
        r_trans[175:144],
        r_trans[17:16]==`H_BYTE ? "BYTE" : 
                        ( r_trans[17:16]==`H_HWORD ? "HALF WORD" : "WORD" ),
        r_trans[253:252]==`H_OKAY ? "OKAY" : "ERROR" );
     else
      $display(
        "MASTER: trans=[%d]  addr=[%h] %s data=[%h]   expected=[%h]    %s %s",
        r_trans[143:128],
        r_trans[107:76],
        r_trans[72]==1'b1 ? "WRITE" : "READ",
        r_trans[72]==1'b1 ? r_trans[71:40] : r_trans[251:220],
        r_trans[175:144],
        r_trans[17:16]==`H_BYTE ? "BYTE" : 
                        ( r_trans[17:16]==`H_HWORD ? "HALF WORD" : "WORD" ),
        r_trans[253:252]==`H_OKAY ? "OKAY" : "ERROR" );

    end
  end    



  
  
/*----------------------------------------------------------------------------
Get Next Transaction
----------------------------------------------------------------------------*/
  reg [216:208] tmp_repeats;
  always 
  begin

      while ( trans_num<16'hFFFF)
      begin    
  
        if (n_trans[15:0]==16'h0000)
        begin
                                              // get the next record
          trans_num = trans_num+1;
              
          tmp_transaction  = transactions[trans_num];

          n_trans[175:144]<= tmp_transaction[71:40];  // expected data
          n_trans[143:128]<= trans_num;
          n_trans[127:0]  <= tmp_transaction;         
    
    
                                           // check for a BUSY
          n_trans[219]    <= tmp_transaction[29:28]==`H_BUSY ? 1'b1 : 1'b0;
    
                      // update the start address
          if (tmp_transaction[29:28]!=`H_SEQ&&tmp_transaction[29:28]!=`H_BUSY)
          begin
            n_trans[207:176] <= tmp_transaction[107:76]; // start address
          end
    
    
                  // compute the number of beats in burst
          if (tmp_transaction[23:20]!=`H_SINGLE && tmp_transaction[29:28]==`H_NONSEQ)
          begin
            tmp_beats=9'b0_0000_0001;
            tmp_repeats[216:208]=9'b0_0000_0001;
      
        // get the transaction from the database        
            tmp_transaction=transactions[trans_num+tmp_beats];

            while (tmp_transaction[29:28]==`H_SEQ||tmp_transaction[29:28]==`H_BUSY)
            begin
              tmp_repeats[216:208]=tmp_repeats[216:208]+tmp_transaction[15:0]+1;
              tmp_beats=tmp_beats+1;
     
        // get the transaction from the database            
              tmp_transaction  = transactions[trans_num+tmp_beats];

             end
            n_trans[216:208]<=tmp_repeats[216:208];
          end
   

        end        
        else
        begin
          n_trans[15:0]<=n_trans[15:0]-1;
        end // i

                              // wait for the current transaction to be accepted
        @(posedge masterhclk_in);
        while (~(addr_ack|data_ack) && n_trans[108])
          @(posedge masterhclk_in);

      end // while transactions in buffer
      if (output_file) $fclose(output_file) ;
      $finish(2);  
  end
  
    



/*----------------------------------------------------------------------------
 Compute burst length
 
 add_go_r prevents a newly loaded length being decremented by the last data
 beat of the previous transaction.
----------------------------------------------------------------------------*/
  reg [8:0] length;
  reg         add_go_r;
  always @(posedge masterhclk_in)
    if (masterhready_in)
      add_go_r <= add_go;

  always @(posedge masterhclk_in or posedge reset)
    if (reset)
      length <= 5'h0;
    else if (add_go)
      case (burst)
    `H_SINGLE:    length <= 9'h1;
    `H_INCR:    length <= beats;
    `H_WRAP4,
    `H_INCR4:    length <= 9'h4;
    `H_WRAP8,
    `H_INCR8:    length <= 9'h8;
    `H_WRAP16,
    `H_INCR16:    length <= 9'h10;
      endcase
    else if ((reading | writing) & masterhready_in & ~add_go_r & ((masterhresp_in == `H_OKAY) | (masterhresp_in == `H_ERROR)))
      length <= length - (|length);

  reg [8:0] address_length;
  always @(posedge masterhclk_in or posedge reset)
    if (reset)
      address_length <= 5'h0;
    else if (add_go)
      case (burst)
    `H_SINGLE:    address_length <= 9'h1;
    `H_INCR:    address_length <= beats;
    `H_WRAP4,
    `H_INCR4:    address_length <= 9'h4;
    `H_WRAP8,
    `H_INCR8:    address_length <= 9'h8;
    `H_WRAP16,
    `H_INCR16:    address_length <= 9'h10;
      endcase
    else if (data_bus_owned & ~masterhready_in & ((masterhresp_in == `H_RETRY) | (masterhresp_in == `H_SPLIT)))
      address_length <= address_length + 9'h1;
    else if (address_bus_owned & masterhready_in & ~(|busy_states) & (masterhtrans_out_r != `H_IDLE))
      address_length <= address_length - (|address_length);
    else if (address_bus_owned & masterhready_in & (|busy_states) & (masterhtrans_out_r == `H_BUSY) & ~(|busy_counter))
      address_length <= address_length - (|address_length);

/*----------------------------------------------------------------------------
 Bus request state machine
 
 Bus request machine follows the principle that the arbiter will generally
 only re-assign bus grants at the end of a burst transaction. For defined
 bursts masterhbusreq_out is removed as soon as we masterhave started the transaction.
 Undefined (INCR) bursts will masterhold masterhbusreq_out asserted until the last beat of the
 transaction.
 
 Locked transactions must always assert masterhlock_out for at least one cycle before
 the address to be locked to allow the arbiter to see the lock. In practice,
 this means inserting an idle cycle. 
 
 Have to be careful using burst and beats from the control word. As soon as
 the master address phase masterhas finished and the addr_ack is asserted the
 testbench can change the control word. So don't use them after the initial
 request. Use the ahb outputs instead which will tell us what sort of
 transaction we're doing.
----------------------------------------------------------------------------*/
  reg [2:0] req_state;
  parameter req_idle = 3'b000,
        req_first = 3'b001,
        req_wait = 3'b101,
        req_masterhold = 3'b011,
        req_using = 3'b010,
        req_again = 3'b111;
  assign masterhbusreq_out = start
         | (req_state == req_first)
         | (req_state == req_wait)
         | (req_state == req_masterhold)
         | (req_state == req_again);

  wire single_beat = (burst == `H_SINGLE)
           | (burst == `H_INCR) & (beats == 9'b1);

  reg  single_beat_r;
  always @(posedge masterhclk_in)
    if (addr_ack)
      // save single_beat for use after it may masterhave changed
      single_beat_r = single_beat;

  wire last_beat = address_bus_owned & masterhready_in & (address_length <= 9'b1);
  wire retry = data_bus_owned & ((masterhresp_in == `H_RETRY) | (masterhresp_in == `H_SPLIT));
  wire error = data_bus_owned & masterhready_in & (masterhresp_in == `H_ERROR);

/*----------------------------------------------------------------------------
 Bus request machine masterhas five states:
 req_idle: masterhbusreq_out negated. Wmasterhen we want to do something we jump to req_first.
    The last beat may get a retry response in which case we jump to
    req_again.
 req_first: masterhbusreq_out asserted. Wait masterhere for masterhgrant_in and until the transaction
    starts. If granted and it's an undefined and not a single beat then
    jump to req_masterhold. Else if it's a single beat jump to req_idle.
    Otherwise jump to req_using.
 req_masterhold: masterhbusreq_out asserted. Hold masterhbusreq_out asserted until last beat of an
    undefined. If there's a new request then we jump to req_first, 
    otherwise back to req_idle. If we lose masterhgrant_in in this state then we
    just stay masterhere with masterhbusreq_out asserted until the transaction can be
    finished. Also masterhold in this state if retry is asserted to reduce the
    chance of releaseing the bus and masterhaving to re-request it to complete
    a transaction.
 req_using: masterhbusreq_out negated. Wait masterhere for last beat of defined length
    transaction. If there's a new request then we jump to req_first, 
    otherwise back to req_idle. If a posted write is errored before the
    last beat or a transaction is retried or we lose masterhgrant_in then we jump
    to req_again.
 req_again: masterhbusreq_out asserted for completion of transaction interrupted by loss
    of masterhgrant_in. Wait masterhere for masterhgrant_in and until the transaction starts then
    jump to req_using if first_beat    is asserted or req_masterhold if not.
    *** We may see a new address toggle whilst in this state.
----------------------------------------------------------------------------*/
  always @(posedge masterhclk_in or posedge reset)
    if (reset)
      req_state <= req_idle;
    else
      case (req_state)
    req_idle:

      if (retry)
        req_state <= req_again;
      else if (start)
        req_state <= req_first;

      else
        req_state <= req_idle;

    req_first:
      if (retry)
        req_state <= req_again;
      else if (~masterhgrant_in & ~((masterhtrans_out_r == `H_NONSEQ) & masterhready_in))
        req_state <= req_first;
      else if ((masterhtrans_out_r == `H_NONSEQ) & masterhready_in)
      begin
        if (add_go)
          req_state <= req_first;
        else if ((burst == `H_INCR) & ~single_beat)
          req_state <= req_masterhold;
        else if (single_beat)
          req_state <= req_idle;
        else
          req_state <= req_using;
      end
      else
        req_state <= req_wait;

    req_wait:
      if (retry)
        req_state <= req_again;
      else if (~masterhgrant_in & ~((masterhtrans_out_r == `H_NONSEQ) & masterhready_in))
        req_state <= req_first;
      else if (masterhgrant_in & ~((masterhtrans_out_r == `H_NONSEQ) & masterhready_in))
        req_state <= req_wait;
      else if (add_go)
        req_state <= req_first;
      else if ((burst == `H_INCR) & ~single_beat)
        req_state <= req_masterhold;
      else if (single_beat_r)
        req_state <= req_idle;
      else
        req_state <= req_using;

    req_masterhold:
      if (error & ~continue_after_error)
        req_state <= req_idle;
      else if (~masterhgrant_in & (address_length > 9'b1)
          | retry)
        req_state <= req_again;
      else if (last_beat)
      begin
        if (start)
          req_state <= req_first;
        else
          req_state <= req_idle;
      end
      else if (add_go)
        req_state <= req_first;
      else
        req_state <= req_masterhold;
    
    req_using:
      if (error & ~continue_after_error)
        req_state <= req_idle;
      else if (last_beat)
      begin
        if (start)
          req_state <= req_first;
        else
          req_state <= req_idle;
      end
      else if (~masterhgrant_in & (address_length > 9'b1)
           | retry)
        req_state <= req_again;
      else
        req_state <= req_using;

    req_again:
      if (error & ~continue_after_error)
        req_state <= req_idle;
      else if ((~data_bus_owned
           | data_bus_owned & (masterhresp_in == `H_OKAY))
            & address_bus_owned & (masterhtrans_out_r == `H_IDLE) & masterhready_in & ~masterhlock_out)
        req_state <= req_idle;
      else if (~masterhgrant_in & (address_length > 9'b1)
          | ~((masterhtrans_out_r == `H_NONSEQ) & masterhready_in))
        req_state <= req_again;
      else if (last_beat | (masterhburst_out_r == `H_SINGLE)
           | (masterhburst_out_r == `H_INCR) & single_beat_r)
        req_state <= req_idle;
      else if (first_beat)
        req_state <= req_using;
      else
        req_state <= req_masterhold;

    default:    req_state <= req_idle;
      endcase
  
/*----------------------------------------------------------------------------
 Address acknowledge
 
 Signals when an address masterhas been transferred and a new one may be presented
 for the next transaction.
----------------------------------------------------------------------------*/
  assign addr_ack = add_go;

/*----------------------------------------------------------------------------
 Data acknowledge
 
 Signals when an address masterhas been transferred and a new one may be presented
 for the next transaction.
----------------------------------------------------------------------------*/
  assign data_ack = data_go;

/*----------------------------------------------------------------------------
 Bus ownership
 
 Data bus ownership follows address by one cycle
----------------------------------------------------------------------------*/
  always @(posedge masterhclk_in or posedge reset)
    if (reset)
    begin
      address_bus_owned <= 1'b0;
      data_bus_owned <= 1'b0;
    end
    else if (masterhready_in)
    begin
      address_bus_owned <= masterhgrant_in;
      data_bus_owned <= address_bus_owned;
    end

/*----------------------------------------------------------------------------
 add_go enables the address phase for a new transaction (not the continuation
 of a retried transaction or a transaction during which we lose the bus).
 
 It asserts immediately on address request if we're not actively using the bus
 and not waiting for it to be re-granted to complete a previous transaction,
 the (masterhtrans_out_r == `IDLE) term ensuring it only asserts for one clock.
----------------------------------------------------------------------------*/
  always @(start or masterhbusreq_out or masterhgrant_in or masterhready_in or reading
       or writing or masterhtrans_out_r or req_state or length or reset)
    if (start & masterhbusreq_out & masterhgrant_in & masterhready_in & ~reading & ~writing
        & (masterhtrans_out_r == `H_IDLE) & (req_state != req_again) & ~reset)
      add_go <= 1'b1;
    else if (start & masterhbusreq_out & masterhgrant_in & masterhready_in & (length < 9'h2) & ~retry
        & (masterhtrans_out_r != `H_BUSY) & (masterhtrans_out_r != `H_NONSEQ) & ~reset)
      add_go <= 1'b1;
    else
      add_go <= 1'b0;


/*----------------------------------------------------------------------------
 data_go indicates the completion of the data phase for a transaction 

 Like add_go it asserts when the master takes control of the address lines to
 start a transaction.
 It also asserts on all the accepted data beats of a burst except the last.
----------------------------------------------------------------------------*/
  wire  trans_end = data_bus_owned & (reading | writing) & 
                   masterhready_in & (masterhresp_in == `H_OKAY || masterhresp_in == `H_ERROR);

  always @(start or masterhbusreq_out or masterhgrant_in or masterhready_in or reading
       or writing or masterhtrans_out_r or req_state or length or reset 
       or need_retry or trans_end )
    if (start & masterhbusreq_out & masterhgrant_in & masterhready_in & ~reading & ~writing
        & (masterhtrans_out_r == `H_IDLE) & (req_state != req_again) & ~reset & ~need_retry)
      data_go <= 1'b1;
    else if (start & masterhbusreq_out & masterhgrant_in & masterhready_in & (address_length > 9'h1) & ~retry
         & ~reset & (~need_retry|trans_end))
      data_go <= 1'b1;
    else
      data_go <= 1'b0;


/*----------------------------------------------------------------------------
 masterhwrite_out_r
 
 Updated on any clock that starts a new transaction
----------------------------------------------------------------------------*/
  always @(posedge masterhclk_in or posedge reset)
    if (reset)
      masterhwrite_out_r <= 1'b0;
    else if (addr_ack)
      masterhwrite_out_r <= write;
  
/*----------------------------------------------------------------------------
 Transaction size
 
 Updated on any clock that starts a new transaction
----------------------------------------------------------------------------*/
  always @(posedge masterhclk_in or posedge reset)
    if (reset)
      masterhsize_outl <= 3'b0;
    else if (addr_ack)
      masterhsize_outl <= size;
  
/*----------------------------------------------------------------------------
 Busy counter
 
 Insert BUSY states into burst transactions.
 
 Capture control word. Load counter on every active phase and decrement to
 zero.
----------------------------------------------------------------------------*/
  always @(posedge masterhclk_in or posedge reset)
    if (reset)
      busy_states <= 1'b0;
    else if (addr_ack)
      busy_states <= insert_busy;
  
  always @(posedge masterhclk_in or posedge reset)
    if (reset)
      busy_counter <= 1'b0;
    else if ((masterhtrans_out_r == `H_NONSEQ) | (masterhtrans_out_r == `H_SEQ))
      busy_counter <= busy_states - 1;
    else
      busy_counter <= busy_counter - (|busy_counter);
  
/*----------------------------------------------------------------------------
 first_masterhtrans_out_r is asserted to enable the first beat of a transaction, which is
 always NONSEQ:
 - The first beat of a new transaction (addr_ack).
 - To restart a transaction that was interrupted by loss of masterhgrant_in if we
   receive a new masterhgrant_in whilst in req_again or req_masterhold states.
 - To restart a transaction after a RETRY response.
 - To restart a transaction after a SPLIT response.
pwd
  - Break an undefined `INCR replay of a retried or split wrapping burst at
   the wrap address boundary.
----------------------------------------------------------------------------*/
  always @(posedge masterhclk_in)
    masterhgrant_in_r <= masterhgrant_in;

  wire      masterhgrant_in_leading_edge = masterhgrant_in & ~masterhgrant_in_r;
  
  always @(posedge masterhclk_in or posedge reset)
    if (reset)
      new_grant <= 1'b0;
    else if (masterhgrant_in_leading_edge & ~first_masterhtrans_out_r)
      new_grant <= 1'b1;
    else if (first_masterhtrans_out_r | ~masterhgrant_in)
      new_grant <= 1'b0;

  assign first_masterhtrans_out_r = addr_ack
              | (masterhgrant_in_leading_edge | masterhgrant_in & new_grant) & masterhready_in & ~masterhwrite_out_r
              & ((req_state == req_masterhold) | (req_state == req_again))
              | (masterhgrant_in_leading_edge | masterhgrant_in & new_grant) & masterhready_in & masterhwrite_out_r
              & ((req_state == req_masterhold) | (req_state == req_again))
              | data_bus_owned & masterhready_in & (masterhresp_in == `H_RETRY)
              | data_bus_owned & masterhready_in & (masterhresp_in == `H_SPLIT)
              | address_bus_owned & masterhready_in & ~first_beat
            & break_wrap & (length > 9'b1);
  
/*----------------------------------------------------------------------------
 The only time masterhtrans_out_r changes when masterhready_in is negated is during reset or after
 the first cycle of a two-cyle error response. Otherwise, masterhtrans_out_r can only
 change when masterhgrant_in and masterhready_in are asserted.
 ----------------------------------------------------------------------------*/
  always @(posedge masterhclk_in or posedge reset)
    if (reset)
      masterhtrans_out_r <= `H_IDLE;
    else if (data_bus_owned & ~masterhready_in & (masterhresp_in != `H_OKAY)
        & ~continue_after_error)        // ERROR'ed transactions cancelled
      masterhtrans_out_r <= `H_IDLE;
    else if (data_bus_owned & ~masterhready_in & (masterhresp_in != `H_OKAY) & (masterhresp_in != `H_ERROR)
        & continue_after_error)            // ERROR'ed transactions not cancelled
      masterhtrans_out_r <= `H_IDLE;
    else if (masterhgrant_in & masterhready_in)
      case (masterhtrans_out_r)
    `H_IDLE:
      if (first_masterhtrans_out_r)
        masterhtrans_out_r <= `H_NONSEQ;
      else
        masterhtrans_out_r <= `H_IDLE;
    `H_NONSEQ,`H_SEQ:
      if (first_masterhtrans_out_r)
        masterhtrans_out_r <= `H_NONSEQ;
      else if ((masterhburst_out_r == `H_SINGLE) | (address_length <= 9'h1))
        // Last beat
        masterhtrans_out_r <= `H_IDLE;
      else if (go_busy) // (|busy_states)
        masterhtrans_out_r <= `H_BUSY;
      else
        masterhtrans_out_r <= `H_SEQ;
    
    `H_BUSY:
      if (first_masterhtrans_out_r)
        masterhtrans_out_r <= `H_NONSEQ;
      else if (go_busy)  //(|busy_counter)
        masterhtrans_out_r <= `H_BUSY;
      else
        masterhtrans_out_r <= `H_SEQ;
      endcase
    else if (masterhready_in & ~masterhgrant_in)
      masterhtrans_out_r <= `H_IDLE;
  
/*----------------------------------------------------------------------------
 One of reading or writing is asserted during any data beat for which we are
 actively using the bus.
----------------------------------------------------------------------------*/
  always @(posedge masterhclk_in or posedge reset)
    if (reset)
    begin
      reading <= 1'b0;
      writing <= 1'b0;
    end
    else if (masterhready_in)
    begin
      reading <= ~masterhwrite_out_r & address_bus_owned
            & (masterhtrans_out_r != `H_IDLE) & (masterhtrans_out_r != `H_BUSY);
      writing <= masterhwrite_out_r & address_bus_owned
            & (masterhtrans_out_r != `H_IDLE) & (masterhtrans_out_r != `H_BUSY);
    end

/*----------------------------------------------------------------------------
 Burst size
 
 first_beat is used to keep masterhburst_out_r unchanged when the first beat is to be
 replayed. It alse controls the bus request. A transaction that is split or
 retried on any other beat will be replayed as INCR and masterhbusreq_out must be masterheld
 asserted.
 
 Tmasterhis means that a defined length read that us interrupted mid-burst will
 complete as an undefined INCR and may pre-fetch past the end of the defined
 length (unless, of course, no_prefetch is asserted).
----------------------------------------------------------------------------*/
  always @(posedge masterhclk_in or posedge reset)
    if (reset)
      first_beat <= 1'b0;
    else if (addr_ack)
      first_beat <= 1'b1;
    else if (data_bus_owned & (reading | writing) & masterhready_in & (masterhresp_in == `H_OKAY))
      first_beat <= 1'b0;

  always @(posedge masterhclk_in or posedge reset)
    if (reset)
      masterhburst_out_r <= 3'b0;
    else if (addr_ack)
      masterhburst_out_r <= burst;
    else if (first_masterhtrans_out_r & ~first_beat)
      masterhburst_out_r <= `H_INCR;

/*----------------------------------------------------------------------------
 need_retry
----------------------------------------------------------------------------*/
  always @(posedge masterhclk_in or posedge reset)
    if (reset)
      need_retry <= 1'b0;
    else if (data_bus_owned & ~masterhready_in & ((masterhresp_in == `H_RETRY) | (masterhresp_in == `H_SPLIT)))
      need_retry <= 1'b1;
    else if (data_bus_owned & masterhready_in & (reading | writing)
        & ((masterhresp_in == `H_OKAY) | (masterhresp_in == `H_ERROR)))
      need_retry <= 1'b0;
  
  always @(posedge masterhclk_in or posedge reset)
    if (reset)
      wrap <= 1'b0;
    else if (addr_ack)
      wrap <= (burst == `H_WRAP4) | (burst == `H_WRAP8)
        | (burst == `H_WRAP16);

  always @(posedge masterhclk_in or posedge reset)
    if (reset)
      original_burst <= 3'b0;
    else if (addr_ack)
      original_burst <= burst;

  always @(posedge masterhclk_in or posedge reset)
    if (reset)
      replay_wrap <= 3'b0;
    else if (addr_ack)
      replay_wrap <= 3'b0;
    else if (data_bus_owned & ~masterhready_in & wrap & ((masterhresp_in == `H_RETRY) | (masterhresp_in == `H_SPLIT)))
      replay_wrap <= 3'b1;

/*----------------------------------------------------------------------------
 Compute wrap mask

 Used to modify next_masterhaddr_out_r during wrapping bursts. First case statement forms
 a mask based on the transfer size. Tmasterhis is then shifted left with '1's
 inserted to form the final mask. E.g. masterhsize_outl == word (3'b010) wrapped at a
 four beat boundary results in wrap_mask set to 10'b0000001111 allowing the
 four lsbs of the address to increment and wrap addressing sixteen bytes in
 total.
----------------------------------------------------------------------------*/
  always @(masterhsize_outl)
    case (masterhsize_outl)
      3'b000:    init_wrap_mask <= 10'b0;
      3'b001:    init_wrap_mask <= 10'b1;
      3'b010:    init_wrap_mask <= 10'b11;
      3'b011:    init_wrap_mask <= 10'b111;
      3'b100:    init_wrap_mask <= 10'b1111;
      3'b101:    init_wrap_mask <= 10'b11111;
      3'b110:    init_wrap_mask <= 10'b111111;
      3'b111:    init_wrap_mask <= 10'b1111111;
    endcase

  always @(original_burst or init_wrap_mask)
    case (original_burst)
      `H_WRAP4:    wrap_mask <= {init_wrap_mask[7:0], 2'b11};
      `H_WRAP8:    wrap_mask <= {init_wrap_mask[6:0], 3'b111};
      `H_WRAP16:    wrap_mask <= {init_wrap_mask[5:0], 4'b1111};
      default:    wrap_mask <= 10'b0;
    endcase

  always @(masterhsize_outl)
    case (masterhsize_outl)
      3'b000:    init_wrap_boundary_bit <= 8'b1;
      3'b001:    init_wrap_boundary_bit <= 8'b10;
      3'b010:    init_wrap_boundary_bit <= 8'b100;
      3'b011:    init_wrap_boundary_bit <= 8'b1000;
      3'b100:    init_wrap_boundary_bit <= 8'b10000;
      3'b101:    init_wrap_boundary_bit <= 8'b100000;
      3'b110:    init_wrap_boundary_bit <= 8'b1000000;
      3'b111:    init_wrap_boundary_bit <= 8'b10000000;
    endcase

  always @(original_burst or init_wrap_boundary_bit)
    case (original_burst)
      `H_WRAP4:    wrap_boundary_bit <= {init_wrap_boundary_bit, 2'b0};
      `H_WRAP8:    wrap_boundary_bit <= {init_wrap_boundary_bit, 3'b0};
      `H_WRAP16:wrap_boundary_bit <= {init_wrap_boundary_bit[6:0], 4'b0};
      default:    wrap_boundary_bit <= 11'b0;
    endcase

/*----------------------------------------------------------------------------
 Compute address increment

 Tmasterhis code allows for all possibilities by inferring a 3-to-8 decoder on the
 transfer size. AHB spec is unclear masterhow a burst with a transfer size greater
 than the bus width should be masterhandled.
----------------------------------------------------------------------------*/
  always @(masterhsize_outl)
  begin
    masterhaddr_out_r_inc <= 10'b0;
    masterhaddr_out_r_inc[masterhsize_outl] <= 1'b1;
  end

/*----------------------------------------------------------------------------
 Compute next address

 Next address is based on the increment computed from the transfer size, and
 the burst type, which may tell us to wrap. Wrapping is achieved by preserving
 some of the upper bits through use of wrap_mask.

 If beat n is retried, we're already putting out the address for beat n+1 so
 we need to decrement.
----------------------------------------------------------------------------*/
  always @(data_bus_owned or masterhresp_in or masterhready_in or masterhaddr_out_r or masterhaddr_out_r_inc)
    if (data_bus_owned & ((masterhresp_in == `H_RETRY) | (masterhresp_in == `H_SPLIT)))
      init_next_masterhaddr_out_r <= {1'b0, masterhaddr_out_r[9:0]} - masterhaddr_out_r_inc;
    else
      init_next_masterhaddr_out_r <= {1'b0, masterhaddr_out_r[9:0]} + masterhaddr_out_r_inc;
  
  always @(original_burst or wrap_mask or init_next_masterhaddr_out_r or masterhaddr_out_r)
    if ((original_burst == `H_WRAP4) | (original_burst == `H_WRAP8)
    | (original_burst == `H_WRAP16))
      next_masterhaddr_out_r <= wrap_mask & init_next_masterhaddr_out_r | ~wrap_mask & masterhaddr_out_r;
    else
      next_masterhaddr_out_r <= init_next_masterhaddr_out_r;
  
  assign break_wrap = replay_wrap & ((|(init_next_masterhaddr_out_r & wrap_boundary_bit))
                    ^ (|(masterhaddr_out_r[10:0] & wrap_boundary_bit)));

/*----------------------------------------------------------------------------
 Address Generation

 AHB address has to track the changing address during bursts. next_masterhaddr_out_r
 computes the next address.
 
 NOTE: It is incumbent upon the command file not to attempt a transaction that
 would cross a 1Kbyte address boundary.
 
 Address is normally updated after each address phase. It is also updated
 during the second cycle of a two cycle retry or split response to rewind the
 address and allow the transaction to be replayed.
----------------------------------------------------------------------------*/
  always @(posedge masterhclk_in or posedge reset)
    if (reset)
      masterhaddr_out_r <= 32'b0;
    else if (addr_ack)
      masterhaddr_out_r <= start_address;
    else if (data_bus_owned & masterhready_in & ((masterhresp_in == `H_RETRY) | (masterhresp_in == `H_SPLIT)))
      masterhaddr_out_r[9:0] <= next_masterhaddr_out_r;
    else if (address_bus_owned & masterhready_in
        & ((masterhtrans_out_r == `H_NONSEQ) | (masterhtrans_out_r == `H_SEQ)))
      masterhaddr_out_r[9:0] <= next_masterhaddr_out_r;

/*----------------------------------------------------------------------------
 Write Data 
 
 If generate_data is negated then initial data is taken from data input. If
 generate_data is asserted then data is generated from the address offset to
 match that expected by the checkers.

 The expected data and the transaction number follow the write data.
 
 At the end of a burst data is set to x so we can ensure nothing is relying on
 invalid data.
----------------------------------------------------------------------------*/

  reg [31:0] masterhwdata_out_r_pipe;
  reg [31:0] masterhwdata_out_r_retry;

  always @(posedge masterhclk_in)
    if (data_bus_owned & ~masterhready_in & (masterhresp_in==`H_RETRY||masterhresp_in==`H_SPLIT))
    begin
      masterhwdata_out_r_retry <= masterhwdata_out_r;
    end
    else if (addr_ack || data_ack)
      masterhwdata_out_r_pipe <= data;

   
  wire [7:0] addr_offset = {masterhaddr_out_r[7:2], 2'b0};
  
  always @(posedge masterhclk_in or posedge reset)
    if (reset)
      masterhwdata_out_r <= {32{1'b0}};
    else if (~address_bus_owned & masterhready_in)
      masterhwdata_out_r <= {32{1'b0}};
    else if (masterhready_in & ~generate_data)
    begin
      if (address_bus_owned & masterhwrite_out_r & need_retry & ~trans_end)
        masterhwdata_out_r <= masterhwdata_out_r_retry;
      else if (address_bus_owned & masterhwrite_out_r & (masterhtrans_out_r == `H_NONSEQ))
        masterhwdata_out_r <= masterhwdata_out_r_pipe;
      else if ((length == 9'b0))
        masterhwdata_out_r <= {32{1'b0}};
      else if (address_bus_owned & masterhwrite_out_r & (masterhtrans_out_r == `H_SEQ))
        masterhwdata_out_r <= masterhwdata_out_r_pipe; 
      else
        masterhwdata_out_r <= {32{1'b0}};
    end
    else if (masterhready_in & generate_data)
    begin
      if (address_bus_owned & masterhwrite_out_r & (masterhtrans_out_r == `H_NONSEQ))
        masterhwdata_out_r <= {addr_offset, addr_offset, addr_offset, addr_offset};
      else if ((length == 9'b0))
        masterhwdata_out_r <= {32{1'b0}};
      else if (address_bus_owned & masterhwrite_out_r & (masterhtrans_out_r == `H_SEQ))
        masterhwdata_out_r <= {addr_offset, addr_offset, addr_offset, addr_offset};
    end

/*----------------------------------------------------------------------------
 Transaction Details

 The transactor pipeline consists of four stages

 n_trans - the next transaction from the store
 c_trans - the current control / address stage transaction
 d_trans - the data stage transaction
 rTrans - the completed stage for reporting


 c_trans is updated from n_trans when a new transaction begins or from d_trans in
 the case of split/retry
----------------------------------------------------------------------------*/
  
  always @(posedge masterhclk_in)
    if (data_bus_owned & ~masterhready_in & (masterhresp_in==`H_RETRY||masterhresp_in==`H_SPLIT))
    begin
//      c_trans<=d_trans;              // RETRY/SPLIT causes transaction to be replayed
        retry_trans<=d_trans;
    end
    else if (addr_ack || data_ack)
    begin
      c_trans<=n_trans;
    end

  always @(posedge masterhclk_in or posedge reset)
    if (address_bus_owned & masterhready_in & ~reset &  (~need_retry|trans_end) )
    begin
      d_trans         <= c_trans;
      d_trans[107:76] <= masterhaddr_out_r;
      d_trans[72]     <= masterhwrite_out_r;
      d_trans[36]     <= masterhlock_out;
      d_trans[29:28]  <= masterhtrans_out_r;
      d_trans[21:20]  <= masterhburst_out_r;
      d_trans[18:16]  <= masterhsize_out;
    end
    else if (address_bus_owned & masterhready_in & ~reset &  need_retry )
    begin
      d_trans         <= retry_trans;
      d_trans[107:76] <= masterhaddr_out_r;
      d_trans[72]     <= masterhwrite_out_r;
      d_trans[36]     <= masterhlock_out;
      d_trans[29:28]  <= masterhtrans_out_r;
      d_trans[21:20]  <= masterhburst_out_r;
      d_trans[18:16]  <= masterhsize_out;
    end
    else if ( ( ~address_bus_owned & masterhready_in) | reset)
      d_trans<= i_trans;


  always @(posedge masterhclk_in)
    if (trans_end & ~need_retry)
    begin
      r_trans[253:252]<=masterhresp_in;
      r_trans[251:220]<=masterhrdata_in; 
      r_trans[219:0]  <=d_trans[219:0];
    end
    else if (trans_end & need_retry)
    begin
      r_trans[253:252]<=masterhresp_in;
      r_trans[251:220]<=masterhrdata_in; 
      r_trans[219:0]  <=retry_trans[219:0];
    end
    else
      r_trans<=i_trans;


/*----------------------------------------------------------------------------
 masterhlock_out
----------------------------------------------------------------------------*/
  assign          masterhlock_out = 1'b0;
/*----------------------------------------------------------------------------
----------------------------------------------------------------------------*/
endmodule    // alt_exc_upcore

// START MODULE NAME -----------------------------------------------------------
//
// Module Name      : ALTDDIO_IN
//
// Description      : Double Data Rate (DDR) input behavioural model. Receives
//                    data on both edges of the reference clock.
//
// Limitations      : Not available for FLEX, MAX, APEX20K and APEX20KE device
//                    families.
//
// Expected results : Data sampled from the datain port at the rising edge of
//                    the reference clock (dataout_h) and at the falling edge of
//                    the reference clock (dataout_l).
//
//END MODULE NAME --------------------------------------------------------------

`timescale 1 ps / 1 ps

// MODULE DECLARATION
module altddio_in (
    datain,    // required port, DDR input data
    inclock,   // required port, input reference clock to sample data by
    inclocken, // enable data clock
    aset,      // asynchronous set
    aclr,      // asynchronous clear
    dataout_h, // data sampled at the rising edge of inclock
    dataout_l  // data sampled at the falling edge of inclock
);

// GLOBAL PARAMETER DECLARATION
parameter width = 1;  // required parameter
parameter power_up_high = "OFF";
parameter intended_device_family = "MERCURY";
parameter lpm_type = "altddio_in";

// INPUT PORT DECLARATION
input [width-1:0] datain;
input inclock;
input inclocken;
input aset;
input aclr;

// OUTPUT PORT DECLARATION
output [width-1:0] dataout_h;
output [width-1:0] dataout_l;

// REGISTER AND VARIABLE DECLARATION
reg [width-1:0] dataout_h_tmp;
reg [width-1:0] dataout_l_tmp;
reg [width-1:0] datain_latched;
integer i;
integer j;
integer k;

// pulldown/pullup
tri0 aset; // default aset to 0
tri0 aclr; // default aclr to 0
tri1 inclocken; // default inclocken to 1

// INITIAL BLOCK
initial
begin
    for (i = 0; i < width; i = i + 1)
    begin
        // if power_up_high parameter is turned on, registers power up
        // to '1', otherwise '0'
        dataout_h_tmp[i] = (power_up_high == "ON") ? 1'b1 : 1'b0;
        dataout_l_tmp[i] = (power_up_high == "ON") ? 1'b1 : 1'b0;
        datain_latched[i] = (power_up_high == "ON") ? 1'b1 : 1'b0;
    end
end

// asynchronous set
always @ (posedge aset)
begin
    for (j = 0; j < width; j = j + 1)
    begin
        dataout_h_tmp[j] <= 1'b1;
        dataout_l_tmp[j] <= 1'b1;
        datain_latched[j] <= 1'b1;
    end
end

// asynchronous clear
always @ (posedge aclr)
begin
    for (k = 0; k < width; k = k + 1)
    begin
        dataout_h_tmp[k] <= 1'b0;
        dataout_l_tmp[k] <= 1'b0;
        datain_latched[k] <= 1'b0;
    end
end

// input reference clock, sample data
always @ (inclock)
begin
    // if not being set or cleared
    if ((aclr !== 1'b1) && (aset !== 1'b1))
    begin
        // rising edge of inclock
        if (inclock == 1'b1)
        begin
            if (inclocken == 1'b1)
            begin
                dataout_h_tmp <= datain;
                dataout_l_tmp <= datain_latched;
            end
        end
        // falling edge of inclock
        else if (inclock == 1'b0)
        begin
            if ((intended_device_family == "APEXII")  ||
                (intended_device_family == "APEX II") ||
                (intended_device_family == "Cyclone") ||
                (intended_device_family == "Stratix GX") ||
                (intended_device_family == "Stratix"))
            begin
                if (inclocken == 1'b1)
                    datain_latched <= datain;
            end
            else if ((intended_device_family == "MERCURY") ||
                     (intended_device_family == "Mercury"))
                datain_latched <= datain;
            else
                datain_latched <= datain;
        end
    end
end

// assign registers to output ports
assign dataout_l = dataout_l_tmp;
assign dataout_h = dataout_h_tmp;

endmodule // altddio_in
// END MODULE ALTDDIO_IN

// START MODULE NAME -----------------------------------------------------------
//
// Module Name      : ALTDDIO_OUT
//
// Description      : Double Data Rate (DDR) output behavioural model.
//                    Transmits data on both edges of the reference clock.
//
// Limitations      : Not available for FLEX, MAX, APEX20K and APEX20KE device
//                    families.
//
// Expected results : Double data rate output on dataout.
//
//END MODULE NAME --------------------------------------------------------------

`timescale 1 ps / 1 ps

// MODULE DECLARATION
module altddio_out (
    datain_h,   // required port, data input for the rising edge of outclock
    datain_l,   // required port, data input for the falling edge of outclock
    outclock,   // required port, input reference clock to output data by
    outclocken, // clock enable signal for outclock
    aset,       // asynchronous set
    aclr,       // asynchronous clear
    oe,         // output enable for dataout
    dataout     // DDR data output
);

// GLOBAL PARAMETER DECLARATION
parameter width = 1; // required parameter
parameter power_up_high = "OFF";
parameter oe_reg = "UNUSED";
parameter extend_oe_disable = "UNUSED";
parameter intended_device_family = "MERCURY";
parameter lpm_type = "altddio_out";

// INPUT PORT DECLARATION
input [width-1:0] datain_h;
input [width-1:0] datain_l;
input outclock;
input outclocken;
input aset;
input aclr;
input oe;

// OUTPUT PORT DECLARATION
output [width-1:0] dataout;

// REGISTER, NET AND VARIABLE DECLARATION
wire apexii_oe;
wire output_enable;
reg  oe_rgd;
reg  oe_reg_ext;
reg  [width-1:0] dataout;
reg  [width-1:0] dataout_h;
reg  [width-1:0] dataout_l;
integer i;
integer j;
integer k;

// pulldown/pullup
tri0 aset; // default aset to 0
tri0 aclr; // default aclr to 0
tri1 outclocken; // default outclocken to 1
tri1 oe;   // default oe to 1

// INITIAL BLOCK
initial
begin
    for (i = 0; i < width; i = i + 1)
    begin
        // if power_up_high parameter is turned on, registers power up to '1'
        // else to '0'
        dataout_h[i] = (power_up_high == "ON") ? 1'b1 : 1'b0;
        dataout_l[i] = (power_up_high == "ON") ? 1'b1 : 1'b0;
    end

    if (power_up_high == "ON")
    begin
        oe_rgd = 1'b1;
        oe_reg_ext = 1'b1;
    end
    else
    begin
        oe_rgd = 1'b0;
        oe_reg_ext = 1'b0;
    end
end

// asynchronous set
always @ (posedge aset)
begin
    for (j = 0; j < width; j = j + 1)
    begin
        dataout_h[j] <= 1'b1;
        dataout_l[j] <= 1'b1;
    end
    oe_rgd <= 1'b1;
    oe_reg_ext <= 1'b1;

end

// asynchronous clear
always @ (posedge aclr)
begin
    for (k = 0; k < width; k = k + 1)
    begin
        dataout_h[k] <= 1'b0;
        dataout_l[k] <= 1'b0;
    end
    oe_rgd <= 1'b0;
    oe_reg_ext <= 1'b0;
end

// input reference clock
always @ (outclock)
begin
    // if not being set or cleared
    if ((aset !== 1'b1) && (aclr !== 1'b1))
    begin
        // if clock is enabled
        if (outclocken == 1'b1)
        begin
            // rising edge of outclock
            if (outclock == 1'b1)
            begin
                dataout_h <= datain_h;
                dataout_l <= datain_l;
                // register the output enable signal
                oe_rgd <= oe;
            end
            else // falling edge of outclock
                // additional register for output enable signal
                oe_reg_ext <= oe_rgd;
        end
    end
end

// data output
always @(outclock or dataout_h or dataout_l or output_enable)
begin
    // if output is enabled
    if (output_enable == 1'b1)
        // rising edge of outclock
        if (outclock == 1'b1)
            dataout <= dataout_h;
        else // falling edge of outclock
            dataout <= dataout_l;
    else // output is disabled
        dataout <= {width{1'bZ}};
end

// output enable signal
// Mercury does not support extend_oe_disable and oe_reg parameters
assign output_enable = ((intended_device_family == "APEXII")  ||
                        (intended_device_family == "APEX II") ||
                        (intended_device_family == "Stratix") ||
                        (intended_device_family == "Cyclone") ||
                        (intended_device_family == "Stratix GX"))
                       ? apexii_oe
                       : oe;

assign apexii_oe = (extend_oe_disable == "ON")
                   ? (oe_reg_ext & oe_rgd)
                   : ((oe_reg == "REGISTERED") && (extend_oe_disable != "ON"))
                   ? oe_rgd
                   : oe;

endmodule // altddio_out
// END MODULE ALTDDIO_OUT

// START MODULE NAME -----------------------------------------------------------
//
// Module Name      : ALTDDIO_BIDIR
//
// Description      : Double Data Rate (DDR) bi-directional behavioural model.
//                    Transmits and receives data on both edges of the reference
//                    clock.
//
// Limitations      : Not available for FLEX, MAX, APEX20K and APEX20KE device
//                    families.
//
// Expected results : Data output sampled from padio port on rising edge of
//                    inclock signal (dataout_h) and falling edge of inclock
//                    signal (dataout_l). Combinatorial output fed by padio
//                    directly (combout).
//
//END MODULE NAME --------------------------------------------------------------

`timescale 1 ps / 1 ps

// MODULE DECLARATION
module altddio_bidir (
    datain_h,  // required port, input data to be output of padio port at the
               // rising edge of outclock
    datain_l,  // required port, input data to be output of padio port at the
               // falling edge of outclock
    inclock,   // required port, input reference clock to sample data by
    inclocken, // inclock enable
    outclock,  // required port, input reference clock to register data output
    outclocken, // outclock enable
    aset,      // asynchronour set
    aclr,      // asynchronous clear
    oe,        // output enable for padio port
    dataout_h, // data sampled from the padio port at the rising edge of inclock
    dataout_l, // data sampled from the padio port at the falling edge of
               // inclock
    combout,    // combinatorial output directly fed by padio
    padio     // bidirectional DDR port
);

// GLOBAL PARAMETER DECLARATION
parameter width = 1; // required parameter
parameter power_up_high = "OFF";
parameter oe_reg = "UNUSED";
parameter extend_oe_disable = "UNUSED";
parameter implement_input_in_lcell = "UNUSED";
parameter intended_device_family = "MERCURY";
parameter lpm_type = "altddio_bidir";

// INPUT PORT DECLARATION
input [width-1:0] datain_h;
input [width-1:0] datain_l;
input inclock;
input inclocken;
input outclock;
input outclocken;
input aset;
input aclr;
input oe;

// OUTPUT PORT DECLARATION
output [width-1:0] dataout_h;
output [width-1:0] dataout_l;
output [width-1:0] combout;

// BIDIRECTIONAL PORT DECLARATION
inout  [width-1:0] padio;

// pulldown/pullup
tri0 aset;
tri0 aclr;
tri1 outclocken;
tri1 inclocken;
tri1 oe;

// COMPONENT INSTANTIATION
// ALTDDIO_IN
altddio_in u1 (
    .datain(padio),
    .inclock(inclock),
    .inclocken(inclocken),
    .aset(aset),
    .aclr(aclr),
    .dataout_h(dataout_h),
    .dataout_l(dataout_l)
);
defparam u1.width = width,
         u1.intended_device_family = intended_device_family,
         u1.power_up_high = power_up_high;

// ALTDDIO_OUT
altddio_out u2 (
    .datain_h(datain_h),
    .datain_l(datain_l),
    .outclock(outclock),
    .oe(oe),
    .outclocken(outclocken),
    .aset(aset),
    .aclr(aclr),
    .dataout(padio)
);
defparam u2.width = width,
         u2.power_up_high = power_up_high,
         u2.intended_device_family = intended_device_family,
         u2.oe_reg = oe_reg,
         u2.extend_oe_disable = extend_oe_disable;

// padio feeds combout port directly
assign combout = padio;

endmodule // altddio_bidir
// END MODULE ALTDDIO_BIDIR

// START MODULE NAME -----------------------------------------------------------
//
// Module Name : HSSI_PLL
//                                                                             
// Description : This is the Phase Locked Loop (PLL) model used by altcdr_rx 
//               and altcdr_tx. Simple PLL model with 1 clock input (clk) and 
//               2 clock outputs (clk0 & clk1).
// 
// Limitations : Only capable of multiplying and dividing the input clock
//               frequency. There is no support for phase shifts, uneven duty
//               cycles or other fancy PLL features, since the Mercury CDR 
//               does not need these features.
//
// Expected results : 2 output clocks - clk0 and clk1. Locked output indicates
//                    when the PLL locks.
//
//END MODULE NAME --------------------------------------------------------------

`timescale 1 ps / 1 ps

// MODULE DECLARATION
module hssi_pll (
    clk,    // input clock
    areset, // asynchronous reset
    clk0,   // output clock0
    clk1,   // output clock1
    locked  // PLL lock signal
);

// GLOBAL PARAMETER DECLARATION
parameter clk0_multiply_by = 1;
parameter clk1_divide_by = 1;
parameter input_frequency = 1000; // period in ps

// INPUT PORT DECLARATION
input clk;
input areset;

// OUTPUT PORT DECLARATION
output clk0;
output clk1;
output locked;

// INTERNAL SIGNAL/REGISTER DECLARATION
reg clk0_tmp;
reg clk1_tmp;
reg pll_lock;
reg clk_last_value;
reg violation;
reg clk_check;
reg [1:0] next_clk_check;

// INTERNAL VARIABLE DECLARATION
real pll_last_rising_edge;
real pll_last_falling_edge;
real actual_clk_cycle;
real expected_clk_cycle;
real pll_duty_cycle;
real inclk_period;
real clk0_period;
real clk1_period;
real expected_next_clk_edge;

integer pll_rising_edge_count;
integer stop_lock_count;
integer start_lock_count;
integer first_clk0_cycle;
integer first_clk1_cycle;
integer lock_on_rise;
integer lock_on_fall;
integer clk_per_tolerance;
integer lock_low;
integer lock_high;

// variables for clock synchronizing
integer last_synchronizing_rising_edge_for_clk0;
integer last_synchronizing_rising_edge_for_clk1;
integer clk0_synchronizing_period;
integer clk1_synchronizing_period;
reg schedule_clk0;
reg schedule_clk1;
reg output_value0;
reg output_value1;

integer input_cycles_per_clk0;
integer input_cycles_per_clk1;
integer clk0_cycles_per_sync_period;
integer clk1_cycles_per_sync_period;
integer input_cycle_count_to_sync0;
integer input_cycle_count_to_sync1;

integer sched_time0;
integer sched_time1;
integer rem0;
integer rem1;
integer tmp_rem0;
integer tmp_rem1;
integer i0;
integer i1;
integer j0;
integer j1;
integer l0;
integer l1;
integer cycle_to_adjust0;
integer cycle_to_adjust1;
integer tmp_per0;
integer tmp_per1;
integer high_time0;
integer high_time1;
integer low_time0;
integer low_time1;

buf (clk_in, clk);

initial
begin
    pll_rising_edge_count = 0;
    pll_lock = 1'b0;
    stop_lock_count = 0;
    start_lock_count = 0;
    clk_last_value = clk_in;
    first_clk0_cycle = 1;
    first_clk1_cycle = 1;
    clk0_tmp = 1'bx;
    clk1_tmp = 1'bx;
    violation = 0;
    lock_on_rise = 0;
    lock_on_fall = 0;
    pll_last_rising_edge = 0;
    pll_last_falling_edge = 0;
    lock_low = 2;
    lock_high = 2;
    clk_check = 0;

    last_synchronizing_rising_edge_for_clk0 = 0;
    last_synchronizing_rising_edge_for_clk1 = 0;
    clk0_synchronizing_period = 0;
    clk1_synchronizing_period = 0;
    schedule_clk0 = 0;
    schedule_clk1 = 0;
    input_cycles_per_clk0 = 1;
    input_cycles_per_clk1 = clk1_divide_by;
    clk0_cycles_per_sync_period = clk0_multiply_by;
    clk1_cycles_per_sync_period = clk0_multiply_by;
    input_cycle_count_to_sync0 = 0;
    input_cycle_count_to_sync1 = 0;
    l0 = 1;
    l1 = 1;
    cycle_to_adjust0 = 0;
    cycle_to_adjust1 = 0;
end

// trigger input clock checking for the purpose of detecting an input clock that
// has flatlined or that violates the specified input frequency or 50% duty
// cycle - with tolerance
always @(next_clk_check)
begin
    if (next_clk_check == 1)
    begin
        #((inclk_period+clk_per_tolerance)/2) clk_check = ~clk_check;
    end
    else if (next_clk_check == 2)
    begin
        #(expected_next_clk_edge - $realtime) clk_check = ~clk_check;
    end
    next_clk_check = 0;
end

// same as initial block
// reset all variables, registers and signals on positive edge of areset
always @(posedge areset)
begin
    pll_rising_edge_count = 0;
    pll_lock = 1'b0;
    stop_lock_count = 0;
    start_lock_count = 1;
    clk_last_value = 0;
    first_clk0_cycle = 1;
    first_clk1_cycle = 1;
    clk0_tmp = 1'bx;
    clk1_tmp = 1'bx;
    violation = 0;
    lock_on_rise = 0;
    lock_on_fall = 0;
    pll_last_rising_edge = 0;
    pll_last_falling_edge = 0;
    lock_low = 2;
    lock_high = 2;
end

// on change of input clock or clock check trigger, 
// monitor for duty cycle/input frequency violation
// schedule clk0 and clk1 output, handles the PLL locking
always @(clk_in or clk_check)
begin
    if (areset !== 1'b1)
    begin
        // calculate the required periods and tolerance
        if (pll_rising_edge_count == 0)
        begin
            inclk_period = input_frequency;
            pll_duty_cycle = inclk_period/2;
            clk_per_tolerance = 0.025 * inclk_period;  // allow input clock period to deviate by 2.5%

            clk0_period = inclk_period / clk0_multiply_by;
            clk1_period = (inclk_period / clk0_multiply_by) * clk1_divide_by;
        end

        // rising edge of the clock
        if ((clk_in === 1'b1) && (clk_last_value !== clk_in))
        begin
            if (pll_lock === 1'b1)
                next_clk_check = 1;
            if (pll_rising_edge_count == 0)   // this is first rising edge
                pll_last_rising_edge = $realtime;
            else if (pll_rising_edge_count == 1) // this is second rising edge
            begin
                expected_clk_cycle = inclk_period;
                actual_clk_cycle = $realtime - pll_last_rising_edge;
                
                // input frequency violation check
                if (actual_clk_cycle < (expected_clk_cycle - clk_per_tolerance) ||
                    actual_clk_cycle > (expected_clk_cycle + clk_per_tolerance))
                begin
                    $display($realtime, "Warning: Input frequency Violation");
                    violation = 1;
                    if (locked === 1'b1)
                    begin
                        stop_lock_count = stop_lock_count + 1;
                        // PLL breaks its lock
                        if ((locked === 1'b1) && (stop_lock_count == lock_low))
                        begin
                          pll_lock = 1'b0;
                          start_lock_count = 1;
                          stop_lock_count = 0;
                          clk0_tmp = 1'bx;
                          clk1_tmp = 1'bx;
                        end
                    end
                end
                else
                begin
                    // Duty cycle violation check
                    if (($realtime - pll_last_falling_edge) < (pll_duty_cycle - (clk_per_tolerance/2)) ||
                        ($realtime - pll_last_falling_edge) > (pll_duty_cycle + (clk_per_tolerance/2)))
                    begin
                        $display($realtime, "Warning: Duty Cycle Violation");
                        violation = 1;
                    end
                    else
                        violation = 0;
                end
            end
            // input frequency violation check
            else if (($realtime - pll_last_rising_edge) < (expected_clk_cycle - clk_per_tolerance) ||
                     ($realtime - pll_last_rising_edge) > (expected_clk_cycle + clk_per_tolerance))
            begin
                $display($realtime, "Warning: Cycle Violation");
                violation = 1;
                if (locked === 1'b1)
                begin
                    stop_lock_count = stop_lock_count + 1;
                    // PLL breaks its lock
                    if (stop_lock_count == lock_low)
                    begin
                        pll_lock = 1'b0;
                        start_lock_count = 1;
                        stop_lock_count = 0;
                        clk0_tmp = 1'bx;
                        clk1_tmp = 1'bx;
                    end
                end
            end
            else begin
                violation = 0;
                actual_clk_cycle = $realtime - pll_last_rising_edge;
            end
            pll_last_rising_edge = $realtime;
            pll_rising_edge_count = pll_rising_edge_count + 1;
            
            // if no violation is detected, schedule clk0 and clk1
            if (!violation)
            begin
               if (pll_lock === 1'b1)
               begin
                  input_cycle_count_to_sync0 = input_cycle_count_to_sync0 + 1;
                  if (input_cycle_count_to_sync0 == input_cycles_per_clk0)
                  begin
                     clk0_synchronizing_period = $realtime - last_synchronizing_rising_edge_for_clk0;
                     last_synchronizing_rising_edge_for_clk0 = $realtime;
                     schedule_clk0 = 1;
                     input_cycle_count_to_sync0 = 0;
                  end
                  
                  input_cycle_count_to_sync1 = input_cycle_count_to_sync1 + 1;
                  if (input_cycle_count_to_sync1 == input_cycles_per_clk1)
                  begin
                     clk1_synchronizing_period = $realtime - last_synchronizing_rising_edge_for_clk1;
                     last_synchronizing_rising_edge_for_clk1 = $realtime;
                     schedule_clk1 = 1;
                     input_cycle_count_to_sync1 = 0;
                  end
               end
               else begin
                  start_lock_count = start_lock_count + 1;
                  if (start_lock_count >= (lock_high + 1))
                  begin
                      pll_lock = 1'b1;
                      input_cycle_count_to_sync0 = 0;
                      input_cycle_count_to_sync1 = 0;
                      lock_on_rise = 1;
                      if (last_synchronizing_rising_edge_for_clk0 == 0)
                      begin
                         clk0_synchronizing_period = actual_clk_cycle;
                      end
                      else
                         clk0_synchronizing_period = $realtime - last_synchronizing_rising_edge_for_clk0;

                      if (last_synchronizing_rising_edge_for_clk1 == 0)
                         clk1_synchronizing_period = actual_clk_cycle * clk1_divide_by;
                      else
                         clk1_synchronizing_period = $realtime - last_synchronizing_rising_edge_for_clk1;

                      last_synchronizing_rising_edge_for_clk0 = $realtime;
                      last_synchronizing_rising_edge_for_clk1 = $realtime;
                      schedule_clk0 = 1;
                      schedule_clk1 = 1;
                  end
               end
            end
            else
               start_lock_count = 1;
        end
        // falling edge of input clock
        else if ((clk_in === 1'b0) && (clk_last_value !== clk_in))
        begin
            if (pll_lock === 1'b1)
            begin
                next_clk_check = 1;
                if (($realtime - pll_last_rising_edge) < (pll_duty_cycle - (clk_per_tolerance/2)) ||
                    ($realtime - pll_last_rising_edge) > (pll_duty_cycle + (clk_per_tolerance/2)))
                begin
                   $display($realtime, "Warning: Duty Cycle Violation");
                   violation = 1;
                   if (locked === 1'b1)
                   begin
                      stop_lock_count = stop_lock_count + 1;
                      if (stop_lock_count == lock_low)
                      begin
                        pll_lock = 1'b0;
                        start_lock_count = 1;
                        stop_lock_count = 0;
                        clk0_tmp = 1'bx;
                        clk1_tmp = 1'bx;
                      end
                   end
                end
                else
                   violation = 0;
            end
            else
                start_lock_count = start_lock_count + 1;

            pll_last_falling_edge = $realtime;
        end
        else if (pll_lock === 1'b1) // perform clock check
        begin
            if (clk_in === 1'b1)
                expected_next_clk_edge = pll_last_rising_edge + ((inclk_period+clk_per_tolerance)/2);
            else if (clk_in === 1'b0)
                expected_next_clk_edge = pll_last_falling_edge + ((inclk_period+clk_per_tolerance)/2);
            else
                expected_next_clk_edge = 0;

            violation = 0;
            if ($realtime < expected_next_clk_edge)
                next_clk_check = 2;
            else if ($realtime == expected_next_clk_edge)
                next_clk_check = 1;
            else
            begin
                $display($realtime, "Warning: Input frequency Violation");
                violation = 1;
                if (locked === 1'b1)
                begin
                    stop_lock_count = stop_lock_count + 1;
                    expected_next_clk_edge = $realtime + (inclk_period/2);
                    // PLL breaks its lock
                    if (stop_lock_count == lock_low)
                    begin
                        pll_lock = 1'b0;
                        start_lock_count = 1;
                        stop_lock_count = 0;
                        clk0_tmp = 1'bx;
                        clk1_tmp = 1'bx;
                    end
                    else
                        next_clk_check = 2;
                end
            end
        end
        clk_last_value = clk_in;
    end
end

// schedule clk0 output
always @(posedge schedule_clk0)
begin
    l0 = 1;
    cycle_to_adjust0 = 0;
    output_value0 = 1'b1;
    sched_time0 = 0;
    rem0 = clk0_synchronizing_period % clk0_cycles_per_sync_period;
    for (i0 = 1; i0 <= clk0_cycles_per_sync_period; i0 = i0 + 1)
    begin
        tmp_per0 = clk0_synchronizing_period/clk0_cycles_per_sync_period;
        if (rem0 != 0 && l0 <= rem0)
        begin
            tmp_rem0 = (clk0_cycles_per_sync_period * l0) % rem0;
            cycle_to_adjust0 = (clk0_cycles_per_sync_period * l0) / rem0;
            if (tmp_rem0 != 0)
                cycle_to_adjust0 = cycle_to_adjust0 + 1;
        end
        if (cycle_to_adjust0 == i0)
        begin
            tmp_per0 = tmp_per0 + 1;
            l0 = l0 + 1;
        end
        high_time0 = tmp_per0/2;
        if (tmp_per0 % 2 != 0)
            high_time0 = high_time0 + 1;
        low_time0 = tmp_per0 - high_time0;
        for (j0 = 0; j0 <= 1; j0 = j0 + 1)
        begin
            clk0_tmp <= #(sched_time0) output_value0;
            output_value0 = ~output_value0;
            if (output_value0 === 1'b0)
                sched_time0 = sched_time0 + high_time0;
            else if (output_value0 === 1'b1)
                sched_time0 = sched_time0 + low_time0;
        end
    end
    schedule_clk0 <= #1 1'b0;
end

// schedule clk1 output
always @(posedge schedule_clk1)
begin
    l1 = 1;
    cycle_to_adjust1 = 0;
    output_value1 = 1'b1;
    sched_time1 = 0;
    rem1 = clk1_synchronizing_period % clk1_cycles_per_sync_period;
    for (i1 = 1; i1 <= clk1_cycles_per_sync_period; i1 = i1 + 1)
    begin
        tmp_per1 = clk1_synchronizing_period/clk1_cycles_per_sync_period;
        if (rem1 != 0 && l1 <= rem1)
        begin
            tmp_rem1 = (clk1_cycles_per_sync_period * l1) % rem1;
            cycle_to_adjust1 = (clk1_cycles_per_sync_period * l1) / rem1;
            if (tmp_rem1 != 0)
               cycle_to_adjust1 = cycle_to_adjust1 + 1;
        end
        if (cycle_to_adjust1 == i1)
        begin
            tmp_per1 = tmp_per1 + 1;
            l1 = l1 + 1;
        end
        high_time1 = tmp_per1/2;
        if (tmp_per1 % 2 != 0)
            high_time1 = high_time1 + 1;
        low_time1 = tmp_per1 - high_time1;
        for (j1 = 0; j1 <= 1; j1 = j1 + 1)
        begin
            clk1_tmp <= #(sched_time1) output_value1;
            output_value1 = ~output_value1;
            if (output_value1 === 1'b0)
                sched_time1 = sched_time1 + high_time1;
            else if (output_value1 === 1'b1)
                sched_time1 = sched_time1 + low_time1;
        end
    end
    schedule_clk1 <= #1 1'b0;
end

buf (clk0, clk0_tmp);
buf (clk1, clk1_tmp);
buf (locked, pll_lock);

endmodule // hssi_pll


// START MODULE NAME -----------------------------------------------------------
//
// Module Name : RAM7X20_SYN
//                                                                             
// Description : This is the RAM model used by HSSI_FIFO for writing and reading
//               into the FIFO
// 
// Limitations : Reading from the RAM is address-triggered,
//               writing is clock-triggered
//               RAM depth is fixed to 7, maximum width is 20
//
// Expected results : data output from the RAM
//
//END MODULE NAME --------------------------------------------------------------

`timescale 1ps / 1ps

module ram7x20_syn (
    wclk,    // write clock
    rst_l,   // active low asynchronous reset
    addr_wr, // write address
    addr_rd, // read address
    data_in, // data input to the RAM
    we,      // write enable
    re,      // read enable
    data_out // data output from the RAM
);

// GLOBAL PARAMETER DECLARATION
parameter ram_width = 20;

// INPUT PORT DECLARATION
input wclk;
input rst_l; // active low
input [2:0] addr_wr;
input [2:0] addr_rd;
input [19:0] data_in;
input we;
input re;

// OUTPUT PORT DECLARATION
output [19:0] data_out;

// INTERNAL REGISTER/SIGNAL DECLARATION
reg [ram_width-1:0] data_out_i;
reg [ram_width-1:0] ram_array_d_0, ram_array_d_1, ram_array_d_2, 
                    ram_array_d_3, ram_array_d_4, ram_array_d_5,
                    ram_array_d_6,
                    ram_array_q_0, ram_array_q_1, ram_array_q_2,
                    ram_array_q_3, ram_array_q_4, ram_array_q_5,
                    ram_array_q_6;    
wire [ram_width-1:0] data_reg_0, data_reg_1, data_reg_2, 
                     data_reg_3, data_reg_4, data_reg_5, data_reg_6;  

// Modelling the read port
// Assuming address triggered operation only
assign
    data_reg_0 = ( addr_wr == 3'b000 ) ? data_in : ram_array_q_0,
    data_reg_1 = ( addr_wr == 3'b001 ) ? data_in : ram_array_q_1,
    data_reg_2 = ( addr_wr == 3'b010 ) ? data_in : ram_array_q_2,
    data_reg_3 = ( addr_wr == 3'b011 ) ? data_in : ram_array_q_3,
    data_reg_4 = ( addr_wr == 3'b100 ) ? data_in : ram_array_q_4,
    data_reg_5 = ( addr_wr == 3'b101 ) ? data_in : ram_array_q_5,
    data_reg_6 = ( addr_wr == 3'b110 ) ? data_in : ram_array_q_6;

assign data_out = re ? data_out_i : 20'b0;

always @(ram_array_q_0 or ram_array_q_1 or 
         ram_array_q_2 or ram_array_q_3 or 
         ram_array_q_4 or ram_array_q_5 or 
         ram_array_q_6 or addr_rd or we or addr_wr)
begin
    case ( addr_rd )  
        3'b000 : data_out_i = ram_array_q_0;
        3'b001 : data_out_i = ram_array_q_1;
        3'b010 : data_out_i = ram_array_q_2;
        3'b011 : data_out_i = ram_array_q_3;
        3'b100 : data_out_i = ram_array_q_4;
        3'b101 : data_out_i = ram_array_q_5;
        3'b110 : data_out_i = ram_array_q_6;
        default: data_out_i = data_out_i;
    endcase
end

// Modelling the write port
always @(posedge wclk or negedge rst_l) 
begin
    if(~rst_l) // reset
    begin
        ram_array_q_0 <= 0;
        ram_array_q_1 <= 0;
        ram_array_q_2 <= 0; 
        ram_array_q_3 <= 0; 
        ram_array_q_4 <= 0; 
        ram_array_q_5 <= 0; 
        ram_array_q_6 <= 0; 
    end
    else
    begin
        ram_array_q_0 <= ram_array_d_0;
        ram_array_q_1 <= ram_array_d_1;
        ram_array_q_2 <= ram_array_d_2;
        ram_array_q_3 <= ram_array_d_3;
        ram_array_q_4 <= ram_array_d_4;
        ram_array_q_5 <= ram_array_d_5;
        ram_array_q_6 <= ram_array_d_6;
    end
end

always @(we or 
         data_reg_0 or data_reg_1 or 
         data_reg_2 or data_reg_3 or 
         data_reg_4 or data_reg_5 or 
         data_reg_6 or 
         ram_array_q_0 or ram_array_q_1 or
         ram_array_q_2 or ram_array_q_3 or
         ram_array_q_4 or ram_array_q_5 or
         ram_array_q_6) 
    begin
    if (we) // write enabled
    begin
        ram_array_d_0 <= data_reg_0;
        ram_array_d_1 <= data_reg_1;
        ram_array_d_2 <= data_reg_2;
        ram_array_d_3 <= data_reg_3;
        ram_array_d_4 <= data_reg_4;
        ram_array_d_5 <= data_reg_5;
        ram_array_d_6 <= data_reg_6;
    end
    else
    begin
        ram_array_d_0 <= ram_array_q_0;
        ram_array_d_1 <= ram_array_q_1;
        ram_array_d_2 <= ram_array_q_2;
        ram_array_d_3 <= ram_array_q_3;
        ram_array_d_4 <= ram_array_q_4;
        ram_array_d_5 <= ram_array_q_5;
        ram_array_d_6 <= ram_array_q_6;
    end
end

endmodule // ram7x20_syn


// START MODULE NAME -----------------------------------------------------------
//
// Module Name : HSSI_FIFO
//                                                                             
// Description : The FIFO model used by altcdr_rx and altcdr_tx to synchronize
//               data between 2 clock domains
// 
// Limitations : FIFO depth is limited to 7 words only,
//               the overflow and empty signals are active low in this model
//
// Expected results : data read from the FIFO, empty and overflow signals
//                    (active low) to indicate when FIFO is empty or full
//
//END MODULE NAME --------------------------------------------------------------

`timescale 1 ps / 1 ps
`define CNTBIT 3    // 3 bit counter for FIFO read/write addresses

module hssi_fifo (
    datain,  // data input to the FIFO
    clk0,    // FIFO write clock
    clk1,    // FIFO read clock
    we,      // FIFO write enable
    re,      // FIFO read enable
    reset,   // FIFO asynchronous reset
    dataout, // data output from the FIFO
    empty,   // active low FIFO empty signal
    overflow // active low FIFO full signal
);

// GLOBAL PARAMETER DECLARATION
parameter channel_width = 1;

// INPUT PORT DECLARATION
input [channel_width-1:0] datain;
input clk0;
input clk1;
input we;
input re;
input reset;

// OUTPUT PORT DECLARATION
output [channel_width-1:0] dataout;
output empty;
output overflow;

// INTERNAL REGISTER/SIGNAL DECLARATION
wire [19:0] ram_dataout;
wire [19:0] data_out;
reg [19:0] ram_datain;
reg [19:0] dataout_tmp;

// The following are for asynchronous fifo use
reg  [`CNTBIT-1:0] wrPtr0;      // write pointer synchronizer
reg  [`CNTBIT-1:0] wrPtr1;      // write pointer synchronizer
reg  [`CNTBIT-1:0] wrPtr2;      // write pointer synchronizer
reg  [`CNTBIT-1:0] wrPtr,rdPtr; // writer pointer, read pointer
reg  [`CNTBIT-1:0] wrAddr;      // writer address
reg  [`CNTBIT-1:0] preRdPtr,preRdPtr1,preRdPtr2;
wire [`CNTBIT-1:0] rdAddr = rdPtr; // read address
reg  ram_we;      // we for ram 

// Empty/Full checking
wire fullFlag = (wrPtr0 == preRdPtr2)? 1 : 0;
wire emptyFlag = (rdPtr == wrPtr2)? 1: 0;
wire overflow_tmp_b;
wire empty_tmp_b = !emptyFlag;

// pullup/pulldown
tri1 we, re;
tri0 reset;

integer i;

buf (clk0_in, clk0);
buf (clk1_in, clk1);
buf (we_in, we);
buf (re_in, re);
buf (reset_in, reset);

assign overflow_tmp_b = (reset_in)? 1'b1 : !fullFlag;

// instantiate the 7x20 RAM for reading and writing data 
ram7x20_syn  ram7x20_syn(
    .wclk (clk0_in),
    .rst_l (!reset),
    .addr_wr (wrAddr),
    .addr_rd (rdAddr),
    .data_in (ram_datain),
    .we (ram_we),
    .re (re && empty_tmp_b),
    .data_out (ram_dataout)
);
defparam ram7x20_syn.ram_width = channel_width;

// initialize the FIFO read and write pointers
initial
begin
    dataout_tmp = 20'b0;
    for (i = 0; i < `CNTBIT; i = i + 1)
    begin
        wrPtr0[i] = 1'b0;
        wrPtr1[i] = 1'b0;
        wrPtr2[i] = 1'b0;
        wrPtr[i] = 1'b0;
        rdPtr[i] = 1'b0;
        preRdPtr[i] = 1'b0;
        preRdPtr1[i] = 1'b0;
        preRdPtr2[i] = 1'b0;
    end
    preRdPtr1 = 6;
    preRdPtr2 = 6;
end

// output data on postive edge of read clock (clk1)
always @(posedge clk1_in or posedge reset_in ) 
begin
    if (reset === 1'b1) 
        dataout_tmp <= 0;
    else if ((re_in === 1'b1) && (empty_tmp_b === 1'b1)) 
        dataout_tmp <= ram_dataout;     //  memory output latch
    else 
        dataout_tmp <= dataout_tmp;
end

// Update the write pointer and send input data to the RAM
// Delay the write pointer update until we have given the RAM the
// write strobe.  This prevents the not empty flag from going true
// before the data actually makes it safely into the RAM
always @(posedge clk0_in or posedge reset_in) 
begin
    if(reset_in === 1'b1) // reset 
    begin
        wrAddr <= 0;
        ram_datain <= 20'b0;
        wrPtr0 <= 0;
    end
    else if ((we_in === 1'b1) && (overflow_tmp_b === 1'b1))
    begin
        ram_datain <= datain;
        wrAddr <= wrPtr0;       // wrLow for memory
        wrPtr0 <= wrPtr0 + 1;
        if (wrPtr0 == 6)
            wrPtr0 <= 0;
    end
    else 
    begin
        wrAddr <= wrAddr;
        ram_datain <= ram_datain;
        wrPtr0 <= wrPtr0;
    end
end

// write pointer
always @(posedge clk0_in or posedge reset_in) 
begin
    if(reset_in === 1'b1)
        wrPtr <= 0;
    else
        wrPtr <= wrPtr0;
end

// write enable
always @(posedge clk0_in or posedge reset_in) 
begin
    if (reset_in === 1'b1) 
        ram_we <= 1'b0;
    else if ((we_in === 1'b1) && (overflow_tmp_b === 1'b1)) 
        ram_we <= 1'b1;
    else 
        ram_we <= 1'b0;
end

// update read pointer
always @(posedge clk1_in or posedge reset_in) 
begin
    if(reset_in === 1'b1) 
    begin
        rdPtr <= 0;
        preRdPtr <= 0;
    end
    else if ((re_in === 1'b1) && (empty_tmp_b === 1'b1))
    begin
        rdPtr <= rdPtr + 1;
    if (rdPtr == 6)
        rdPtr <= 0;
        preRdPtr <= rdPtr;
    end
end

// the following lines are for async. fifo.
always @(posedge clk1_in or posedge reset_in) 
begin
    if (reset_in === 1'b1) 
    begin
        wrPtr1 <= 0;
        wrPtr2 <= 0;
    end
    else 
    begin
        wrPtr1 <= wrPtr;    // sync. wrPtr to read clock
        wrPtr2 <= wrPtr1;
    end
end

always @(posedge clk0_in or posedge reset_in) 
begin
    if (reset_in === 1'b1) 
    begin
        preRdPtr1 <= 6;
        preRdPtr2 <= 6;
    end
    else 
    begin
        preRdPtr1 <= preRdPtr; // sync. RdPtr to write clock
        preRdPtr2 <= preRdPtr1;
    end
end

assign dataout = dataout_tmp;

and (empty, empty_tmp_b, 1'b1);
and (overflow, overflow_tmp_b, 1'b1);

endmodule // hssi_fifo


// START MODULE NAME -----------------------------------------------------------
//
// Module Name : HSSI_RX
//                                                                             
// Description : This is the receiver model used by altcdr_rx. Performs
//               deserialization of input data. 
// 
// Limitations : Assumes that the clock is already perfectly synchronized to the
//               incoming data
//
// Expected results: data output from the deserializer, slow clock (clkout) 
//                   generated by the RX, run length violation flag (rlv), and
//                   locked output to indicate when the RX has failed to lock
//                   onto the input data signal (not simulated)
//
//END MODULE NAME --------------------------------------------------------------

`timescale 1 ps / 1 ps

module hssi_rx (
    clk,     // fast clock
    coreclk, // slow (core) clock
    datain,  // data input to the RX
    areset,  // asynchronous reset
    feedback,// data feedback port
    fbkcntl, // feedback control port
    dataout, // data output from the RX
    clkout,  // slow clock generated by the RX
    rlv,     // run length violation flag
    locked   // RX lost of lock indicator
);

// GLOBAL PARAMETER DECLARATION
parameter channel_width = 1;
parameter operation_mode = "CDR";
parameter run_length = 1;

// INPUT PORT DECLARATION 
input clk;
input coreclk;
input datain;
input areset;
input feedback;
input fbkcntl;

// OUTPUT PORT DECLARATION
output [channel_width-1:0] dataout;
output clkout;
output rlv;
output locked;

// INTERNAL VARIABLE/SIGNAL/REGISTER DECLARATION
integer i;
integer clk_count;
integer rlv_count;
reg clk_last_value;
reg coreclk_last_value;
reg clkout_last_value;
reg [channel_width-1:0] deser_data_arr;
reg clkout_tmp;
reg rlv_tmp;
reg locked_tmp;
reg rlv_flag;
reg rlv_set;
reg [19:0] dataout_tmp;
reg datain_in;
reg last_datain;
reg data_changed;
wire [19:0] data_out;

// pulldown
tri0 areset, feedback, fbkcntl;

buf (clk_in, clk);
buf (datain_buf, datain);
buf (fbin_in, feedback);
buf (fbena_in, fbkcntl);
buf (areset_in, areset);

initial
begin
    i = 0;
    rlv_count = 0;
    clk_count = channel_width;
    clk_last_value = 0;
    coreclk_last_value = 0;
    clkout_tmp = 1'b0;
    rlv_tmp = 1'b0;
    rlv_flag = 1'b0;
    rlv_set = 1'b0;
    locked_tmp = 1'b0;
    dataout_tmp = 20'b0;
    last_datain = 1'bx;
    data_changed = 1'b0;
end

// deserialize incoming data, generate clkout and check for run length violation 
always @(clk_in or coreclk or areset_in or fbena_in)
begin
    if (areset_in === 1'b1) // reset
    begin
        dataout_tmp = 20'b0;
        clkout_tmp = 1'b0;
        rlv_tmp = 1'b0;
        rlv_flag = 1'b0;
        last_datain = 1'bx;
        rlv_count = 0;
        data_changed = 1'b0;
        clk_count = channel_width;
        for (i = channel_width - 1; i >= 0; i = i - 1)
            deser_data_arr[i] = 1'b0;
    end
    else 
    begin
        if ((clk_in === 1'b1) && (clk_last_value !== clk_in))
        begin
            // data comes from either the feedback port or datain port
            if (fbena_in === 1'b1)
                datain_in = fbin_in;
            else
                datain_in = datain_buf;
                
            // generate clkout
            if (clk_count == channel_width)
            begin
                clk_count = 0;
                clkout_tmp = !clkout_last_value;
            end
            else if (clk_count == (channel_width+1)/2)
                clkout_tmp = !clkout_last_value;
            else if (clk_count < channel_width)
                clkout_tmp = clkout_last_value;

            clk_count = clk_count + 1;

            //rlv (run length violation) checking
            if (operation_mode == "CDR")
            begin 
                if (last_datain !== datain_in)
                begin
                    data_changed = 1'b1;
                    last_datain = datain_in;
                end
                else // data not changed - increment rlv_count
                begin
                    rlv_count = rlv_count + 1;
                    data_changed = 1'b0;
                end

                if (rlv_count > run_length)
                begin
                    rlv_flag = 1'b1;
                    rlv_set = 1'b1;
                end
                else
                    rlv_set = 1'b0;

                if (data_changed)
                    rlv_count = 1;
            end
        end
        if ((coreclk === 1'b1) && (coreclk_last_value !== coreclk))
        begin
            // output the rlv status with the rising edge of the coreclk
            if (operation_mode == "CDR")
            begin
                if (rlv_flag === 1'b1)
                begin
                    rlv_tmp = 1'b1;
                    if (rlv_set === 1'b0)
                        rlv_flag = 1'b0;
                end
                else
                    rlv_tmp = 1'b0;
            end
        end

        // deserialize the data
        if ((clk_in === 1'b0) && (clk_last_value !== clk_in))
        begin
            if ((clk_count == 3)) 
                dataout_tmp[channel_width-1:0] = deser_data_arr;
                
            for (i = channel_width - 1; i >= 1; i = i - 1)
                deser_data_arr[i] = deser_data_arr[i-1];
                
            deser_data_arr[0] = datain_in;
        end
    end
    clk_last_value = clk_in;
    coreclk_last_value = coreclk;
    clkout_last_value = clkout_tmp;
end

assign dataout = dataout_tmp;

and (rlv, rlv_tmp, 1'b1);
and (locked, locked_tmp, 1'b1);
and (clkout, clkout_tmp, 1'b1);

endmodule // hssi_rx

// START MODULE NAME -----------------------------------------------------------
//
// Module Name      : HSSI_TX
//
// Description      : The transmitter module used by altcdr_tx. Performs
//                    serialization of output data.
//
// Limitations      :
//
// Expected results : Serial data output (dataout) and generated slow clock
//                    (clkout)
//
//END MODULE NAME --------------------------------------------------------------

`timescale 1 ps / 1 ps

// MODULE DECLARATION
module hssi_tx (
    clk,     // fast clock
    datain,  // parallel input data
    areset,  // asynchronous reset
    dataout, // serial data output
    clkout   // generated clock
);

// GLOBAL PARAMETER DECLARATION
parameter channel_width = 1;

// INPUT PORT DECLARATION
input clk;
input [channel_width-1:0] datain;
input areset;

// OUTPUT PORT DECLARATION
output dataout;
output clkout;

// INTERNAL VARIABLE/REGISTER DECLARATION
integer i;
integer fast_clk_count;
reg clk_in_last_value;
reg dataout_tmp;
reg clkout_last_value;
reg clkout_tmp;
reg [19:0] indata;
reg [19:0] regdata;

buf (clk_in, clk);
buf (areset_in, areset);

initial
begin
    i = 0;
    fast_clk_count = channel_width;
    clk_in_last_value = 0;
    dataout_tmp = 0;
    clkout_last_value = 0;
    clkout_tmp = 0;
    for (i = channel_width-1; i >= 0; i = i - 1) //resets register
        indata[i] = 1'b0;
    for (i = channel_width-1; i >= 0; i = i - 1) //resets register
        regdata[i] = 1'b0;
end

always @(clk_in or areset_in)
begin
    // reset logic
    if (areset_in == 1'b1)
    begin
        dataout_tmp = 1'b0;
        clkout_tmp = 1'b0;
        fast_clk_count = channel_width;
        for (i = channel_width-1; i >= 0; i = i - 1) // resets register
            indata[i] = 1'b0;
        for (i = channel_width-1; i >= 0; i = i - 1) // resets register
            regdata[i] = 1'b0;
    end
    else // serialize incoming parallel data and generate slow clock
    begin
        // rising edge of fast clock
        if ((clk_in === 1'b1) && (clk_in_last_value !== clk_in))
        begin
            // slow clock generation
            if (fast_clk_count == channel_width)
            begin
                fast_clk_count = 0;
                clkout_tmp = !clkout_last_value;
            end
            else if (fast_clk_count == (channel_width+1)/2)
                clkout_tmp = !clkout_last_value;
            else if (fast_clk_count < channel_width)
                clkout_tmp = clkout_last_value;

            fast_clk_count = fast_clk_count + 1;

            // 3rd rising edge, start to shift out
            if (fast_clk_count == 3)
            begin
                for (i = channel_width-1; i >= 0; i = i - 1)
                    regdata[i] = indata[i];
            end

            // send the MSB of regdata out
            dataout_tmp = regdata[channel_width-1];
            // shift data up
            for (i = channel_width-1; i > 0; i = i - 1)
                regdata[i] = regdata[i-1];
        end
        // falling edge of fast clock
        if ((clk_in === 1'b0) && (clk_in_last_value !== clk_in))
        begin
            if (fast_clk_count == 3) // loading at the 3rd falling edge
            begin
                indata = datain;
            end
        end
    end
    clk_in_last_value = clk_in;
    clkout_last_value = clkout_tmp;
end

and (dataout, dataout_tmp,  1'b1);
and (clkout, clkout_tmp,  1'b1);

endmodule // hssi_tx

// START MODULE NAME -----------------------------------------------------------
//
// Module Name : ALTCDR_RX
//                                                                             
// Description : Clock Data Recovery (CDR) Receiver behavioral model. Consists
//               of CDR receiver for deserialization, a Phase Locked Loop (PLL)
//               and FIFO. 
// 
// Limitations : Available for the Mercury device family only
//
// Expected results : Deserialized data output (rx_out), recovered global data 
//                    clock (rx_outclock), PLL lock signal, RX lost of lock signal,
//                    RX run length violation signal, RX FIFO full and empty
//                    signals (active high), recovered clock per channel
//                    (rx_rec_clk)
//
//END MODULE NAME --------------------------------------------------------------

`timescale 1 ps / 1 ps

// MODULE DECLARATION
module altcdr_rx (
    rx_in,        // required port, data input
    rx_inclock,   // required port, input reference clock
    rx_coreclock, // required port, core clock
    rx_aclr,      // asynchronous reset for the RX and FIFO
    rx_pll_aclr,  // asynchronous reset for the PLL
    rx_fifo_rden, // FIFO read enable
    rx_out,       // data output
    rx_outclock,  // global clock recovered from channel 0
    rx_pll_locked,// PLL lock signal
    rx_locklost,  // RX lock of lost wrt input data
    rx_rlv,       // data run length violation flag
    rx_full,      // FIFO full signal
    rx_empty,     // FIFO empty signal
    rx_rec_clk    // recovered clock from each channel
);

// GLOBAL PARAMETER DECLARATION
parameter number_of_channels = 1;
parameter deserialization_factor = 1;
parameter inclock_period = 20000;       // 20000ps = 50MHz
parameter inclock_boost = 1;
parameter run_length = 62;              // default based on SONET requirements
parameter bypass_fifo = "OFF";
parameter intended_device_family = "MERCURY";
parameter lpm_type = "altcdr_rx";

// INPUT PORT DECLARATION
input [number_of_channels-1:0] rx_in;
input rx_inclock;
input rx_coreclock;
input rx_aclr;
input rx_pll_aclr;
input [number_of_channels-1:0] rx_fifo_rden;

// OUTPUT PORT DECLARATION
output [deserialization_factor*number_of_channels-1:0] rx_out;
output rx_outclock;
output rx_pll_locked;
output [number_of_channels-1:0] rx_locklost;
output [number_of_channels-1:0] rx_rlv;
output [number_of_channels-1:0] rx_full;
output [number_of_channels-1:0] rx_empty;
output [number_of_channels-1:0] rx_rec_clk;

// INTERNAL SIGNAL/VARIABLE DECLARATION    
wire  w_rx_inclk0;
wire  [17:0] i_rx_full;
wire  [17:0] i_rx_empty;
wire  [17:0] i_rx_locked;
wire  [17:0] w_rx_clkout;
wire  [17:0] i_rx_rlv;
wire  i_pll_locked;
wire  [deserialization_factor-1:0] w_rx_out00;
wire  [deserialization_factor-1:0] w_rx_out01;
wire  [deserialization_factor-1:0] w_rx_out02;
wire  [deserialization_factor-1:0] w_rx_out03;
wire  [deserialization_factor-1:0] w_rx_out04;
wire  [deserialization_factor-1:0] w_rx_out05;
wire  [deserialization_factor-1:0] w_rx_out06;
wire  [deserialization_factor-1:0] w_rx_out07;
wire  [deserialization_factor-1:0] w_rx_out08;
wire  [deserialization_factor-1:0] w_rx_out09;
wire  [deserialization_factor-1:0] w_rx_out10;
wire  [deserialization_factor-1:0] w_rx_out11;
wire  [deserialization_factor-1:0] w_rx_out12;
wire  [deserialization_factor-1:0] w_rx_out13;
wire  [deserialization_factor-1:0] w_rx_out14;
wire  [deserialization_factor-1:0] w_rx_out15;
wire  [deserialization_factor-1:0] w_rx_out16;
wire  [deserialization_factor-1:0] w_rx_out17;
wire  [deserialization_factor-1:0] i_fifo_out00;
wire  [deserialization_factor-1:0] i_fifo_out01;
wire  [deserialization_factor-1:0] i_fifo_out02;
wire  [deserialization_factor-1:0] i_fifo_out03;
wire  [deserialization_factor-1:0] i_fifo_out04;
wire  [deserialization_factor-1:0] i_fifo_out05;
wire  [deserialization_factor-1:0] i_fifo_out06;
wire  [deserialization_factor-1:0] i_fifo_out07;
wire  [deserialization_factor-1:0] i_fifo_out08;
wire  [deserialization_factor-1:0] i_fifo_out09;
wire  [deserialization_factor-1:0] i_fifo_out10;
wire  [deserialization_factor-1:0] i_fifo_out11;
wire  [deserialization_factor-1:0] i_fifo_out12;
wire  [deserialization_factor-1:0] i_fifo_out13;
wire  [deserialization_factor-1:0] i_fifo_out14;
wire  [deserialization_factor-1:0] i_fifo_out15;
wire  [deserialization_factor-1:0] i_fifo_out16;
wire  [deserialization_factor-1:0] i_fifo_out17;

reg  [17:0] i_rx_in;
wire  [deserialization_factor*18-1:0] i_rx_out;
wire  [deserialization_factor*18-1:0] i_w_rx_out;
integer i;

// pullup/pulldown 
// Default values for inputs
tri0 rx_aclr_pulldown, rx_aclr;
tri0 rx_pll_aclr_pulldown, rx_pll_aclr;
tri1 [17:0] rx_fifo_rden_pullup;

assign rx_aclr_pulldown = rx_aclr;
assign rx_pll_aclr_pulldown = rx_pll_aclr;
assign rx_fifo_rden_pullup = rx_fifo_rden;

    //-----------------------------------------------------------------------
    // Instantiate the HSSI_RX to deserialize data - maximum of 18 channels
    hssi_rx rx00
    ( .datain (i_rx_in[00]), .clk (w_rx_inclk0), .areset (rx_aclr_pulldown),
      .feedback ( 1'b0), .fbkcntl (1'b0), .coreclk (rx_coreclock),
      .locked (i_rx_locked[00]), 
      .dataout (w_rx_out00), .clkout (w_rx_clkout[00]), .rlv (i_rx_rlv[00]) );
    defparam
        rx00.channel_width = deserialization_factor,
        rx00.operation_mode = "CDR",
        rx00.run_length = run_length;

    hssi_rx rx01
    ( .datain (i_rx_in[01]), .clk (w_rx_inclk0), .areset (rx_aclr_pulldown),
      .feedback ( 1'b0), .fbkcntl (1'b0), .coreclk (rx_coreclock),
      .locked (i_rx_locked[01]),
      .dataout (w_rx_out01), .clkout (w_rx_clkout[01]), .rlv (i_rx_rlv[01]) );
    defparam
        rx01.channel_width = deserialization_factor,
        rx01.operation_mode = "CDR",
        rx01.run_length = run_length;

    hssi_rx rx02
    ( .datain (i_rx_in[02]), .clk (w_rx_inclk0), .areset (rx_aclr_pulldown),
      .feedback ( 1'b0), .fbkcntl (1'b0), .coreclk (rx_coreclock),
      .locked (i_rx_locked[02]),
      .dataout (w_rx_out02), .clkout (w_rx_clkout[02]), .rlv (i_rx_rlv[02]) );
    defparam
        rx02.channel_width = deserialization_factor,
        rx02.operation_mode = "CDR",
        rx02.run_length = run_length;

    hssi_rx rx03
    ( .datain (i_rx_in[03]), .clk (w_rx_inclk0), .areset (rx_aclr_pulldown),
      .feedback ( 1'b0), .fbkcntl (1'b0), .coreclk (rx_coreclock),
      .locked (i_rx_locked[03]),
      .dataout (w_rx_out03), .clkout (w_rx_clkout[03]), .rlv (i_rx_rlv[03]) );
    defparam
        rx03.channel_width = deserialization_factor,
        rx03.operation_mode = "CDR",
        rx03.run_length = run_length;

    hssi_rx rx04
    ( .datain (i_rx_in[04]), .clk (w_rx_inclk0), .areset (rx_aclr_pulldown),
      .feedback ( 1'b0), .fbkcntl (1'b0), .coreclk (rx_coreclock),
      .locked (i_rx_locked[04]),
      .dataout (w_rx_out04), .clkout (w_rx_clkout[04]), .rlv (i_rx_rlv[04]) );
    defparam
        rx04.channel_width = deserialization_factor,
        rx04.operation_mode = "CDR",
        rx04.run_length = run_length;

    hssi_rx rx05
    ( .datain (i_rx_in[05]), .clk (w_rx_inclk0), .areset (rx_aclr_pulldown),
      .feedback ( 1'b0), .fbkcntl (1'b0), .coreclk (rx_coreclock),
      .locked (i_rx_locked[05]),
      .dataout (w_rx_out05), .clkout (w_rx_clkout[05]), .rlv (i_rx_rlv[05]) );
    defparam
        rx05.channel_width = deserialization_factor,
        rx05.operation_mode = "CDR",
        rx05.run_length = run_length;

    hssi_rx rx06
    ( .datain (i_rx_in[06]), .clk (w_rx_inclk0), .areset (rx_aclr_pulldown),
      .feedback ( 1'b0), .fbkcntl (1'b0), .coreclk (rx_coreclock),
      .locked (i_rx_locked[06]),
      .dataout (w_rx_out06), .clkout (w_rx_clkout[06]), .rlv (i_rx_rlv[06]) );
    defparam
        rx06.channel_width = deserialization_factor,
        rx06.operation_mode = "CDR",
        rx06.run_length = run_length;

    hssi_rx rx07
    ( .datain (i_rx_in[07]), .clk (w_rx_inclk0), .areset (rx_aclr_pulldown),
      .feedback ( 1'b0), .fbkcntl (1'b0), .coreclk (rx_coreclock),
      .locked (i_rx_locked[07]),
      .dataout (w_rx_out07), .clkout (w_rx_clkout[07]), .rlv (i_rx_rlv[07]) );
    defparam
        rx07.channel_width = deserialization_factor,
        rx07.operation_mode = "CDR",
        rx07.run_length = run_length;

    hssi_rx rx08
    ( .datain (i_rx_in[08]), .clk (w_rx_inclk0), .areset (rx_aclr_pulldown),
      .feedback ( 1'b0), .fbkcntl (1'b0), .coreclk (rx_coreclock),
      .locked (i_rx_locked[08]),
      .dataout (w_rx_out08), .clkout (w_rx_clkout[08]), .rlv (i_rx_rlv[08]) );
    defparam
        rx08.channel_width = deserialization_factor,
        rx08.operation_mode = "CDR",
        rx08.run_length = run_length;

    hssi_rx rx09
    ( .datain (i_rx_in[09]), .clk (w_rx_inclk0), .areset (rx_aclr_pulldown),
      .feedback ( 1'b0), .fbkcntl (1'b0), .coreclk (rx_coreclock),
      .locked (i_rx_locked[09]),
      .dataout (w_rx_out09), .clkout (w_rx_clkout[09]), .rlv (i_rx_rlv[09]) );
    defparam
        rx09.channel_width = deserialization_factor,
        rx09.operation_mode = "CDR",
        rx09.run_length = run_length;

    hssi_rx rx10
    ( .datain (i_rx_in[10]), .clk (w_rx_inclk0), .areset (rx_aclr_pulldown),
      .feedback ( 1'b0), .fbkcntl (1'b0), .coreclk (rx_coreclock),
      .locked (i_rx_locked[10]),
      .dataout (w_rx_out10), .clkout (w_rx_clkout[10]), .rlv (i_rx_rlv[10]) );
    defparam
        rx10.channel_width = deserialization_factor,
        rx10.operation_mode = "CDR",
        rx10.run_length = run_length;

    hssi_rx rx11
    ( .datain (i_rx_in[11]), .clk (w_rx_inclk0), .areset (rx_aclr_pulldown),
      .feedback ( 1'b0), .fbkcntl (1'b0), .coreclk (rx_coreclock),
      .locked (i_rx_locked[11]),
      .dataout (w_rx_out11), .clkout (w_rx_clkout[11]), .rlv (i_rx_rlv[11]) );
    defparam
        rx11.channel_width = deserialization_factor,
        rx11.operation_mode = "CDR",
        rx11.run_length = run_length;

    hssi_rx rx12
    ( .datain (i_rx_in[12]), .clk (w_rx_inclk0), .areset (rx_aclr_pulldown),
      .feedback ( 1'b0), .fbkcntl (1'b0), .coreclk (rx_coreclock),
      .locked (i_rx_locked[12]),
      .dataout (w_rx_out12), .clkout (w_rx_clkout[12]), .rlv (i_rx_rlv[12]) );
    defparam
        rx12.channel_width = deserialization_factor,
        rx12.operation_mode = "CDR",
        rx12.run_length = run_length;

    hssi_rx rx13
    ( .datain (i_rx_in[13]), .clk (w_rx_inclk0), .areset (rx_aclr_pulldown),
      .feedback ( 1'b0), .fbkcntl (1'b0), .coreclk (rx_coreclock),
      .locked (i_rx_locked[13]),
      .dataout (w_rx_out13), .clkout (w_rx_clkout[13]), .rlv (i_rx_rlv[13]) );
    defparam
        rx13.channel_width = deserialization_factor,
        rx13.operation_mode = "CDR",
        rx13.run_length = run_length;

    hssi_rx rx14
    ( .datain (i_rx_in[14]), .clk (w_rx_inclk0), .areset (rx_aclr_pulldown),
      .feedback ( 1'b0), .fbkcntl (1'b0), .coreclk (rx_coreclock),
      .locked (i_rx_locked[14]),
      .dataout (w_rx_out14), .clkout (w_rx_clkout[14]), .rlv (i_rx_rlv[14]) );
    defparam
        rx14.channel_width = deserialization_factor,
        rx14.operation_mode = "CDR",
        rx14.run_length = run_length;

    hssi_rx rx15
    ( .datain (i_rx_in[15]), .clk (w_rx_inclk0), .areset (rx_aclr_pulldown),
      .feedback ( 1'b0), .fbkcntl (1'b0), .coreclk (rx_coreclock),
      .locked (i_rx_locked[15]),
      .dataout (w_rx_out15), .clkout (w_rx_clkout[15]), .rlv (i_rx_rlv[15]) );
    defparam
        rx15.channel_width = deserialization_factor,
        rx15.operation_mode = "CDR",
        rx15.run_length = run_length;

    hssi_rx rx16
    ( .datain (i_rx_in[16]), .clk (w_rx_inclk0), .areset (rx_aclr_pulldown),
      .feedback ( 1'b0), .fbkcntl (1'b0), .coreclk (rx_coreclock),
      .locked (i_rx_locked[16]),
      .dataout (w_rx_out16), .clkout (w_rx_clkout[16]), .rlv (i_rx_rlv[16]) );
    defparam
        rx16.channel_width = deserialization_factor,
        rx16.operation_mode = "CDR",
        rx16.run_length = run_length;

    hssi_rx rx17
    ( .datain (i_rx_in[17]), .clk (w_rx_inclk0), .areset (rx_aclr_pulldown),
      .feedback ( 1'b0), .fbkcntl (1'b0), .coreclk (rx_coreclock),
      .locked (i_rx_locked[17]),
      .dataout (w_rx_out17), .clkout (w_rx_clkout[17]), .rlv (i_rx_rlv[17]) );
    defparam
        rx17.channel_width = deserialization_factor,
        rx17.operation_mode = "CDR",
        rx17.run_length = run_length;


    //----------------------------------------------------------
    // Instantiate HSSI_PLL - use the same PLL for all channels

    hssi_pll pll
    ( .clk (rx_inclock), .areset (rx_pll_aclr_pulldown),
      .clk0 (w_rx_inclk0), .clk1 (), .locked (i_pll_locked) );
    defparam
        pll.clk0_multiply_by = inclock_boost,
        pll.input_frequency = inclock_period;
  
    //----------------------------------------------------------
    // Instantiate HSSI_FIFOs

    hssi_fifo fifo00
    ( .clk1 (rx_coreclock), .re (rx_fifo_rden_pullup[00]),
      .clk0 (w_rx_clkout[00]), .datain (w_rx_out00),
      .we (1'b1), .reset (rx_aclr_pulldown),
      .overflow (i_rx_full[00]), .empty (i_rx_empty[00]),
      .dataout (i_fifo_out00) );
    defparam
        fifo00.channel_width = deserialization_factor;
 
    hssi_fifo fifo01
    ( .clk1 (rx_coreclock), .re (rx_fifo_rden_pullup[01]),
      .clk0 (w_rx_clkout[01]), .datain (w_rx_out01),
      .we (1'b1), .reset (rx_aclr_pulldown),
      .overflow (i_rx_full[01]), .empty (i_rx_empty[01]),
      .dataout (i_fifo_out01) );
    defparam
        fifo01.channel_width = deserialization_factor;
 
    hssi_fifo fifo02
    ( .clk1 (rx_coreclock), .re (rx_fifo_rden_pullup[02]),
      .clk0 (w_rx_clkout[02]), .datain (w_rx_out02),
      .we (1'b1), .reset (rx_aclr_pulldown),
      .overflow (i_rx_full[02]), .empty (i_rx_empty[02]),
      .dataout (i_fifo_out02) );
    defparam
        fifo02.channel_width = deserialization_factor;
 
    hssi_fifo fifo03
    ( .clk1 (rx_coreclock), .re (rx_fifo_rden_pullup[03]),
      .clk0 (w_rx_clkout[03]), .datain (w_rx_out03),
      .we (1'b1), .reset (rx_aclr_pulldown),
      .overflow (i_rx_full[03]), .empty (i_rx_empty[03]),
      .dataout (i_fifo_out03) );
    defparam
        fifo03.channel_width = deserialization_factor;
 
    hssi_fifo fifo04
    ( .clk1 (rx_coreclock), .re (rx_fifo_rden_pullup[04]),
      .clk0 (w_rx_clkout[04]), .datain (w_rx_out04),
      .we (1'b1), .reset (rx_aclr_pulldown),
      .overflow (i_rx_full[04]), .empty (i_rx_empty[04]),
      .dataout (i_fifo_out04) );
    defparam
        fifo04.channel_width = deserialization_factor;
 
    hssi_fifo fifo05
    ( .clk1 (rx_coreclock), .re (rx_fifo_rden_pullup[05]),
      .clk0 (w_rx_clkout[05]), .datain (w_rx_out05),
      .we (1'b1), .reset (rx_aclr_pulldown),
      .overflow (i_rx_full[05]), .empty (i_rx_empty[05]),
      .dataout (i_fifo_out05) );
    defparam
        fifo05.channel_width = deserialization_factor;
 
    hssi_fifo fifo06
    ( .clk1 (rx_coreclock), .re (rx_fifo_rden_pullup[06]),
      .clk0 (w_rx_clkout[06]), .datain (w_rx_out06),
      .we (1'b1), .reset (rx_aclr_pulldown),
      .overflow (i_rx_full[06]), .empty (i_rx_empty[06]),
      .dataout (i_fifo_out06) );
    defparam
        fifo06.channel_width = deserialization_factor;
 
    hssi_fifo fifo07
    ( .clk1 (rx_coreclock), .re (rx_fifo_rden_pullup[07]),
      .clk0 (w_rx_clkout[07]), .datain (w_rx_out07),
      .we (1'b1), .reset (rx_aclr_pulldown),
      .overflow (i_rx_full[07]), .empty (i_rx_empty[07]),
      .dataout (i_fifo_out07) );
    defparam
        fifo07.channel_width = deserialization_factor;
 
    hssi_fifo fifo08
    ( .clk1 (rx_coreclock), .re (rx_fifo_rden_pullup[08]),
      .clk0 (w_rx_clkout[08]), .datain (w_rx_out08),
      .we (1'b1), .reset (rx_aclr_pulldown),
      .overflow (i_rx_full[08]), .empty (i_rx_empty[08]),
      .dataout (i_fifo_out08) );
    defparam
        fifo08.channel_width = deserialization_factor;
 
    hssi_fifo fifo09
    ( .clk1 (rx_coreclock), .re (rx_fifo_rden_pullup[09]),
      .clk0 (w_rx_clkout[09]), .datain (w_rx_out09),
      .we (1'b1), .reset (rx_aclr_pulldown),
      .overflow (i_rx_full[09]), .empty (i_rx_empty[09]),
      .dataout (i_fifo_out09) );
    defparam
        fifo09.channel_width = deserialization_factor;
 
    hssi_fifo fifo10
    ( .clk1 (rx_coreclock), .re (rx_fifo_rden_pullup[10]),
      .clk0 (w_rx_clkout[10]), .datain (w_rx_out10),
      .we (1'b1), .reset (rx_aclr_pulldown),
      .overflow (i_rx_full[10]), .empty (i_rx_empty[10]),
      .dataout (i_fifo_out10) );
    defparam
        fifo10.channel_width = deserialization_factor;
 
    hssi_fifo fifo11
    ( .clk1 (rx_coreclock), .re (rx_fifo_rden_pullup[11]),
      .clk0 (w_rx_clkout[11]), .datain (w_rx_out11),
      .we (1'b1), .reset (rx_aclr_pulldown),
      .overflow (i_rx_full[11]), .empty (i_rx_empty[11]),
      .dataout (i_fifo_out11) );
    defparam
        fifo11.channel_width = deserialization_factor;
 
    hssi_fifo fifo12
    ( .clk1 (rx_coreclock), .re (rx_fifo_rden_pullup[12]),
      .clk0 (w_rx_clkout[12]), .datain (w_rx_out12),
      .we (1'b1), .reset (rx_aclr_pulldown),
      .overflow (i_rx_full[12]), .empty (i_rx_empty[12]),
      .dataout (i_fifo_out12) );
    defparam
        fifo12.channel_width = deserialization_factor;
 
    hssi_fifo fifo13
    ( .clk1 (rx_coreclock), .re (rx_fifo_rden_pullup[13]),
      .clk0 (w_rx_clkout[13]), .datain (w_rx_out13),
      .we (1'b1), .reset (rx_aclr_pulldown),
      .overflow (i_rx_full[13]), .empty (i_rx_empty[13]),
      .dataout (i_fifo_out13) );
    defparam
        fifo13.channel_width = deserialization_factor;

    hssi_fifo fifo14
    ( .clk1 (rx_coreclock), .re (rx_fifo_rden_pullup[14]),
      .clk0 (w_rx_clkout[14]), .datain (w_rx_out14),
      .we (1'b1), .reset (rx_aclr_pulldown),
      .overflow (i_rx_full[14]), .empty (i_rx_empty[14]),
      .dataout (i_fifo_out14) );
    defparam
        fifo14.channel_width = deserialization_factor;
 
    hssi_fifo fifo15
    ( .clk1 (rx_coreclock), .re (rx_fifo_rden_pullup[15]),
      .clk0 (w_rx_clkout[15]), .datain (w_rx_out15),
      .we (1'b1), .reset (rx_aclr_pulldown),
      .overflow (i_rx_full[15]), .empty (i_rx_empty[15]),
      .dataout (i_fifo_out15) );
    defparam
        fifo15.channel_width = deserialization_factor;
 
    hssi_fifo fifo16
    ( .clk1 (rx_coreclock), .re (rx_fifo_rden_pullup[16]),
      .clk0 (w_rx_clkout[16]), .datain (w_rx_out16),
      .we (1'b1), .reset (rx_aclr_pulldown),
      .overflow (i_rx_full[16]), .empty (i_rx_empty[16]),
      .dataout (i_fifo_out16) );
    defparam
        fifo16.channel_width = deserialization_factor;
 
    hssi_fifo fifo17
    ( .clk1 (rx_coreclock), .re (rx_fifo_rden_pullup[17]),
      .clk0 (w_rx_clkout[17]), .datain (w_rx_out17),
      .we (1'b1), .reset (rx_aclr_pulldown),
      .overflow (i_rx_full[17]), .empty (i_rx_empty[17]),
      .dataout (i_fifo_out17) );
    defparam
        fifo17.channel_width = deserialization_factor;


//--------------------------
// Inputs

always @(rx_in)
    for(i=0; i<18; i=i+1)
        i_rx_in[i] = (number_of_channels > i) ? rx_in[i] : 0;

//--------------------------
// Outputs
// assign FIFO outputs to i_rx_out wire - for the case when FIFO is not bypassed
assign i_rx_out[01*deserialization_factor-1:00*deserialization_factor]
        = i_fifo_out00;
assign i_rx_out[02*deserialization_factor-1:01*deserialization_factor]
        = i_fifo_out01;
assign i_rx_out[03*deserialization_factor-1:02*deserialization_factor]
        = i_fifo_out02;
assign i_rx_out[04*deserialization_factor-1:03*deserialization_factor]
        = i_fifo_out03;
assign i_rx_out[05*deserialization_factor-1:04*deserialization_factor]
        = i_fifo_out04;
assign i_rx_out[06*deserialization_factor-1:05*deserialization_factor]
        = i_fifo_out05;
assign i_rx_out[07*deserialization_factor-1:06*deserialization_factor]
        = i_fifo_out06;
assign i_rx_out[08*deserialization_factor-1:07*deserialization_factor]
        = i_fifo_out07;
assign i_rx_out[09*deserialization_factor-1:08*deserialization_factor]
        = i_fifo_out08;
assign i_rx_out[10*deserialization_factor-1:09*deserialization_factor]
        = i_fifo_out09;
assign i_rx_out[11*deserialization_factor-1:10*deserialization_factor]
        = i_fifo_out10;
assign i_rx_out[12*deserialization_factor-1:11*deserialization_factor]
        = i_fifo_out11;
assign i_rx_out[13*deserialization_factor-1:12*deserialization_factor]
        = i_fifo_out12;
assign i_rx_out[14*deserialization_factor-1:13*deserialization_factor]
        = i_fifo_out13;
assign i_rx_out[15*deserialization_factor-1:14*deserialization_factor]
        = i_fifo_out14;
assign i_rx_out[16*deserialization_factor-1:15*deserialization_factor]
        = i_fifo_out15;
assign i_rx_out[17*deserialization_factor-1:16*deserialization_factor]
        = i_fifo_out16;
assign i_rx_out[18*deserialization_factor-1:17*deserialization_factor]
        = i_fifo_out17;

// assign RX outputs to i_w_rx_out wire - for the case when FIFO is bypassed
assign i_w_rx_out[01*deserialization_factor-1:00*deserialization_factor]
        = w_rx_out00;
assign i_w_rx_out[02*deserialization_factor-1:01*deserialization_factor]
        = w_rx_out01;
assign i_w_rx_out[03*deserialization_factor-1:02*deserialization_factor]
        = w_rx_out02;
assign i_w_rx_out[04*deserialization_factor-1:03*deserialization_factor]
        = w_rx_out03;
assign i_w_rx_out[05*deserialization_factor-1:04*deserialization_factor]
        = w_rx_out04;
assign i_w_rx_out[06*deserialization_factor-1:05*deserialization_factor]
        = w_rx_out05;
assign i_w_rx_out[07*deserialization_factor-1:06*deserialization_factor]
        = w_rx_out06;
assign i_w_rx_out[08*deserialization_factor-1:07*deserialization_factor]
        = w_rx_out07;
assign i_w_rx_out[09*deserialization_factor-1:08*deserialization_factor]
        = w_rx_out08;
assign i_w_rx_out[10*deserialization_factor-1:09*deserialization_factor]
        = w_rx_out09;
assign i_w_rx_out[11*deserialization_factor-1:10*deserialization_factor]
        = w_rx_out10;
assign i_w_rx_out[12*deserialization_factor-1:11*deserialization_factor]
        = w_rx_out11;
assign i_w_rx_out[13*deserialization_factor-1:12*deserialization_factor]
        = w_rx_out12;
assign i_w_rx_out[14*deserialization_factor-1:13*deserialization_factor]
        = w_rx_out13;
assign i_w_rx_out[15*deserialization_factor-1:14*deserialization_factor]
        = w_rx_out14;
assign i_w_rx_out[16*deserialization_factor-1:15*deserialization_factor]
        = w_rx_out15;
assign i_w_rx_out[17*deserialization_factor-1:16*deserialization_factor]
        = w_rx_out16;
assign i_w_rx_out[18*deserialization_factor-1:17*deserialization_factor]
        = w_rx_out17;

// assign the correct signals to the output ports
assign rx_out = (deserialization_factor == 1) ? rx_in : 
                (bypass_fifo == "OFF") ? i_rx_out[deserialization_factor*number_of_channels-1:0] : i_w_rx_out;
assign rx_outclock = (deserialization_factor > 1) ? w_rx_clkout[00] : rx_inclock;
assign rx_locklost = (deserialization_factor > 1) ? i_rx_locked[number_of_channels-1:0] : {(number_of_channels){1'b1}};
assign rx_full = (deserialization_factor == 1) ? 0 : 
                 (bypass_fifo == "OFF") ? ~ i_rx_full[number_of_channels-1:0] : {number_of_channels{1'bX}};
assign rx_empty = (deserialization_factor == 1) ? 0 : 
                  (bypass_fifo == "OFF") ? ~ i_rx_empty[number_of_channels-1:0] : {number_of_channels{1'bX}};
assign rx_rlv = (deserialization_factor > 1) ? i_rx_rlv : 0;
assign rx_pll_locked = i_pll_locked;
assign rx_rec_clk = w_rx_clkout;

endmodule // altcdr_rx

// START MODULE NAME -----------------------------------------------------------
//
// Module Name      : ALTCDR_TX
//
// Description      : The Clock Data Recovery (CDR) transmitter behavioral
//                    model. Consists of CDR transmitter for serialization,
//                    a PLL and FIFO.
//
// Limitations      : Available for the Mercury device family only
//
// Expected results : Serial data output (tx_out), generated slow clock
//                    (tx_clkout), FIFO full signal (tx_full), FIFO empty signal
//                    (tx_empty), PLL lock signal (tx_pll_locked)
//
//END MODULE NAME --------------------------------------------------------------

`timescale 1 ps / 1 ps

// MODULE DECLARATION
module altcdr_tx (
    tx_in,         // required port, parallel data input
    tx_inclock,    // required port, input reference clock
    tx_coreclock,  // required port, input core clock
    tx_aclr,       // asynchronous clear for TX and FIFO
    tx_pll_aclr,   // asynchronous clear for the PLL
    tx_fifo_wren,  // write enable for the FIFO
    tx_out,        // serial data output
    tx_outclock,   // generated slow clock
    tx_pll_locked, // PLL lock signal
    tx_full,       // FIFO full indicator
    tx_empty       // FIFO empty indicator
);

// GLOBAL PARAMETER DECLARATION
parameter number_of_channels = 1;
parameter deserialization_factor = 1;
parameter inclock_period = 0;    // units in ps
parameter inclock_boost = 1;
parameter bypass_fifo = "OFF";
parameter intended_device_family = "MERCURY";
parameter lpm_type = "altcdr_tx";

// LOCAL PARAMETER DECLARATION
parameter MAX_DATA_WIDTH = deserialization_factor - 1;

// INPUT PORT DECLARATION
input [deserialization_factor*number_of_channels-1:0] tx_in;
input tx_inclock;
input tx_coreclock;
input tx_aclr;
input tx_pll_aclr;
input [number_of_channels-1:0] tx_fifo_wren;

// OUTPUT PORT DECLARATION
output [number_of_channels-1:0] tx_out;
output tx_outclock;
output tx_pll_locked;
output [number_of_channels-1:0] tx_full;
output [number_of_channels-1:0] tx_empty;

// Default values for inputs -- pullup/pulldown
tri0 tx_aclr_pulldown;
tri0 tx_pll_aclr_pulldown;
tri1 [17:0] tx_fifo_wren_pullup;

// INTERNAL VARIABLE/REGISTER DECLARATION
wire  w_tx_clk;
wire  w_tx_clk1;
wire  i_tx_pll_locked;
wire  [17:0] i_tx_full;
wire  [17:0] i_tx_empty;
wire  [17:0] w_tx_out;
wire  [17:0] w_tx_clkout;
wire  [MAX_DATA_WIDTH:0] txin00;
wire  [MAX_DATA_WIDTH:0] txin01;
wire  [MAX_DATA_WIDTH:0] txin02;
wire  [MAX_DATA_WIDTH:0] txin03;
wire  [MAX_DATA_WIDTH:0] txin04;
wire  [MAX_DATA_WIDTH:0] txin05;
wire  [MAX_DATA_WIDTH:0] txin06;
wire  [MAX_DATA_WIDTH:0] txin07;
wire  [MAX_DATA_WIDTH:0] txin08;
wire  [MAX_DATA_WIDTH:0] txin09;
wire  [MAX_DATA_WIDTH:0] txin10;
wire  [MAX_DATA_WIDTH:0] txin11;
wire  [MAX_DATA_WIDTH:0] txin12;
wire  [MAX_DATA_WIDTH:0] txin13;
wire  [MAX_DATA_WIDTH:0] txin14;
wire  [MAX_DATA_WIDTH:0] txin15;
wire  [MAX_DATA_WIDTH:0] txin16;
wire  [MAX_DATA_WIDTH:0] txin17;
wire  [MAX_DATA_WIDTH:0] i_fifo_out00;
wire  [MAX_DATA_WIDTH:0] i_fifo_out01;
wire  [MAX_DATA_WIDTH:0] i_fifo_out02;
wire  [MAX_DATA_WIDTH:0] i_fifo_out03;
wire  [MAX_DATA_WIDTH:0] i_fifo_out04;
wire  [MAX_DATA_WIDTH:0] i_fifo_out05;
wire  [MAX_DATA_WIDTH:0] i_fifo_out06;
wire  [MAX_DATA_WIDTH:0] i_fifo_out07;
wire  [MAX_DATA_WIDTH:0] i_fifo_out08;
wire  [MAX_DATA_WIDTH:0] i_fifo_out09;
wire  [MAX_DATA_WIDTH:0] i_fifo_out10;
wire  [MAX_DATA_WIDTH:0] i_fifo_out11;
wire  [MAX_DATA_WIDTH:0] i_fifo_out12;
wire  [MAX_DATA_WIDTH:0] i_fifo_out13;
wire  [MAX_DATA_WIDTH:0] i_fifo_out14;
wire  [MAX_DATA_WIDTH:0] i_fifo_out15;
wire  [MAX_DATA_WIDTH:0] i_fifo_out16;
wire  [MAX_DATA_WIDTH:0] i_fifo_out17;
reg   [MAX_DATA_WIDTH:0] i_tx_in [17:0];
reg   [359:0] tx_in_int; // 360 = 18 channels * 20 bits (18=maximum number of channels, 20=maximum channel width)

assign tx_aclr_pulldown = tx_aclr;
assign tx_pll_aclr_pulldown = tx_pll_aclr;
assign tx_fifo_wren_pullup = tx_fifo_wren;

// COMPONENT INSTANTIATION

    //-------------------------------------------------------------
    // Instantiate HSSI_TX - maximum of 18 channels
    hssi_tx tx00
    ( .datain (txin00), .clk (w_tx_clk), .areset (tx_aclr_pulldown),
      .dataout (w_tx_out[00]), .clkout (w_tx_clkout[00]) );
    defparam
        tx00.channel_width = deserialization_factor;

    hssi_tx tx01
    ( .datain (txin01), .clk (w_tx_clk), .areset (tx_aclr_pulldown),
      .dataout (w_tx_out[01]), .clkout (w_tx_clkout[01]) );
    defparam
        tx01.channel_width = deserialization_factor;

    hssi_tx tx02
    ( .datain (txin02), .clk (w_tx_clk), .areset (tx_aclr_pulldown),
      .dataout (w_tx_out[02]), .clkout (w_tx_clkout[02]) );
    defparam
        tx02.channel_width = deserialization_factor;

    hssi_tx tx03
    ( .datain (txin03), .clk (w_tx_clk), .areset (tx_aclr_pulldown),
      .dataout (w_tx_out[03]), .clkout (w_tx_clkout[03]) );
    defparam
        tx03.channel_width = deserialization_factor;

    hssi_tx tx04
    ( .datain (txin04), .clk (w_tx_clk), .areset (tx_aclr_pulldown),
      .dataout (w_tx_out[04]), .clkout (w_tx_clkout[04]) );
    defparam
        tx04.channel_width = deserialization_factor;

    hssi_tx tx05
    ( .datain (txin05), .clk (w_tx_clk), .areset (tx_aclr_pulldown),
      .dataout (w_tx_out[05]), .clkout (w_tx_clkout[05]) );
    defparam
        tx05.channel_width = deserialization_factor;

    hssi_tx tx06
    ( .datain (txin06), .clk (w_tx_clk), .areset (tx_aclr_pulldown),
      .dataout (w_tx_out[06]), .clkout (w_tx_clkout[06]) );
    defparam
        tx06.channel_width = deserialization_factor;

    hssi_tx tx07
    ( .datain (txin07), .clk (w_tx_clk), .areset (tx_aclr_pulldown),
      .dataout (w_tx_out[07]), .clkout (w_tx_clkout[07]) );
    defparam
        tx07.channel_width = deserialization_factor;

    hssi_tx tx08
    ( .datain (txin08), .clk (w_tx_clk), .areset (tx_aclr_pulldown),
      .dataout (w_tx_out[08]), .clkout (w_tx_clkout[08]) );
    defparam
        tx08.channel_width = deserialization_factor;

    hssi_tx tx09
    ( .datain (txin09), .clk (w_tx_clk), .areset (tx_aclr_pulldown),
      .dataout (w_tx_out[09]), .clkout (w_tx_clkout[09]) );
    defparam
        tx09.channel_width = deserialization_factor;

    hssi_tx tx10
    ( .datain (txin10), .clk (w_tx_clk), .areset (tx_aclr_pulldown),
      .dataout (w_tx_out[10]), .clkout (w_tx_clkout[10]) );
    defparam
        tx10.channel_width = deserialization_factor;

    hssi_tx tx11
    ( .datain (txin11), .clk (w_tx_clk), .areset (tx_aclr_pulldown),
      .dataout (w_tx_out[11]), .clkout (w_tx_clkout[11]) );
    defparam
        tx11.channel_width = deserialization_factor;

    hssi_tx tx12
    ( .datain (txin12), .clk (w_tx_clk), .areset (tx_aclr_pulldown),
      .dataout (w_tx_out[12]), .clkout (w_tx_clkout[12]) );
    defparam
        tx12.channel_width = deserialization_factor;

    hssi_tx tx13
    ( .datain (txin13), .clk (w_tx_clk), .areset (tx_aclr_pulldown),
      .dataout (w_tx_out[13]), .clkout (w_tx_clkout[13]) );
    defparam
        tx13.channel_width = deserialization_factor;

    hssi_tx tx14
    ( .datain (txin14), .clk (w_tx_clk), .areset (tx_aclr_pulldown),
      .dataout (w_tx_out[14]), .clkout (w_tx_clkout[14]) );
    defparam
        tx14.channel_width = deserialization_factor;

    hssi_tx tx15
    ( .datain (txin15), .clk (w_tx_clk), .areset (tx_aclr_pulldown),
      .dataout (w_tx_out[15]), .clkout (w_tx_clkout[15]) );
    defparam
        tx15.channel_width = deserialization_factor;

    hssi_tx tx16
    ( .datain (txin16), .clk (w_tx_clk), .areset (tx_aclr_pulldown),
      .dataout (w_tx_out[16]), .clkout (w_tx_clkout[16]) );
    defparam
        tx16.channel_width = deserialization_factor;

    hssi_tx tx17
    ( .datain (txin17), .clk (w_tx_clk), .areset (tx_aclr_pulldown),
      .dataout (w_tx_out[17]), .clkout (w_tx_clkout[17]) );
    defparam
        tx17.channel_width = deserialization_factor;


    //---------------------------------------------------------
    // Instantiate HSSI_PLL - use the same PLL for all channels

    hssi_pll pll0
    ( .clk (tx_inclock), .areset (tx_pll_aclr_pulldown),
      .clk0 (w_tx_clk), .clk1 (w_tx_clk1), .locked (i_tx_pll_locked) );
    defparam
        pll0.clk0_multiply_by = inclock_boost,
        pll0.input_frequency = inclock_period;


    //--------------------------------------------------------
    // Instantiate HSSI_FIFO - maximum of 18 channels

    hssi_fifo fifo00
    ( .clk0 (tx_coreclock), .we (tx_fifo_wren_pullup[00]),
      .reset (tx_aclr_pulldown), .re (1'b1),
      .clk1 (w_tx_clkout[00]), .datain (i_tx_in[00]),
      .overflow (i_tx_full[00]), .empty (i_tx_empty[00]),
      .dataout (i_fifo_out00) );
    defparam
        fifo00.channel_width = deserialization_factor;

    hssi_fifo fifo01
    ( .clk0 (tx_coreclock), .we (tx_fifo_wren_pullup[01]),
      .reset (tx_aclr_pulldown), .re (1'b1),
      .clk1 (w_tx_clkout[01]), .datain (i_tx_in[01]),
      .overflow (i_tx_full[01]), .empty (i_tx_empty[01]),
      .dataout (i_fifo_out01) );
    defparam
        fifo01.channel_width = deserialization_factor;

    hssi_fifo fifo02
    ( .clk0 (tx_coreclock), .we (tx_fifo_wren_pullup[02]),
      .reset (tx_aclr_pulldown), .re (1'b1),
      .clk1 (w_tx_clkout[02]), .datain (i_tx_in[02]),
      .overflow (i_tx_full[02]), .empty (i_tx_empty[02]),
      .dataout (i_fifo_out02) );
    defparam
        fifo02.channel_width = deserialization_factor;

    hssi_fifo fifo03
    ( .clk0 (tx_coreclock), .we (tx_fifo_wren_pullup[03]),
      .reset (tx_aclr_pulldown), .re (1'b1),
      .clk1 (w_tx_clkout[03]), .datain (i_tx_in[03]),
      .overflow (i_tx_full[03]), .empty (i_tx_empty[03]),
      .dataout (i_fifo_out03) );
    defparam
        fifo03.channel_width = deserialization_factor;

    hssi_fifo fifo04
    ( .clk0 (tx_coreclock), .we (tx_fifo_wren_pullup[04]),
      .reset (tx_aclr_pulldown), .re (1'b1),
      .clk1 (w_tx_clkout[04]), .datain (i_tx_in[04]),
      .overflow (i_tx_full[04]), .empty (i_tx_empty[04]),
      .dataout (i_fifo_out04) );
    defparam
        fifo04.channel_width = deserialization_factor;

    hssi_fifo fifo05
    ( .clk0 (tx_coreclock), .we (tx_fifo_wren_pullup[05]),
      .reset (tx_aclr_pulldown), .re (1'b1),
      .clk1 (w_tx_clkout[05]), .datain (i_tx_in[05]),
      .overflow (i_tx_full[05]), .empty (i_tx_empty[05]),
      .dataout (i_fifo_out05) );
    defparam
        fifo05.channel_width = deserialization_factor;

    hssi_fifo fifo06
    ( .clk0 (tx_coreclock), .we (tx_fifo_wren_pullup[06]),
      .reset (tx_aclr_pulldown), .re (1'b1),
      .clk1 (w_tx_clkout[06]), .datain (i_tx_in[06]),
      .overflow (i_tx_full[06]), .empty (i_tx_empty[06]),
      .dataout (i_fifo_out06) );
    defparam
        fifo06.channel_width = deserialization_factor;

    hssi_fifo fifo07
    ( .clk0 (tx_coreclock), .we (tx_fifo_wren_pullup[07]),
      .reset (tx_aclr_pulldown), .re (1'b1),
      .clk1 (w_tx_clkout[07]), .datain (i_tx_in[07]),
      .overflow (i_tx_full[07]), .empty (i_tx_empty[07]),
      .dataout (i_fifo_out07) );
    defparam
        fifo07.channel_width = deserialization_factor;

    hssi_fifo fifo08
    ( .clk0 (tx_coreclock), .we (tx_fifo_wren_pullup[08]),
      .reset (tx_aclr_pulldown), .re (1'b1),
      .clk1 (w_tx_clkout[08]), .datain (i_tx_in[08]),
      .overflow (i_tx_full[08]), .empty (i_tx_empty[08]),
      .dataout (i_fifo_out08) );
    defparam
        fifo08.channel_width = deserialization_factor;

    hssi_fifo fifo09
    ( .clk0 (tx_coreclock), .we (tx_fifo_wren_pullup[09]),
      .reset (tx_aclr_pulldown), .re (1'b1),
      .clk1 (w_tx_clkout[09]), .datain (i_tx_in[09]),
      .overflow (i_tx_full[09]), .empty (i_tx_empty[09]),
      .dataout (i_fifo_out09) );
    defparam
        fifo09.channel_width = deserialization_factor;

    hssi_fifo fifo10
    ( .clk0 (tx_coreclock), .we (tx_fifo_wren_pullup[10]),
      .reset (tx_aclr_pulldown), .re (1'b1),
      .clk1 (w_tx_clkout[10]), .datain (i_tx_in[10]),
      .overflow (i_tx_full[10]), .empty (i_tx_empty[10]),
      .dataout (i_fifo_out10) );
    defparam
        fifo10.channel_width = deserialization_factor;

    hssi_fifo fifo11
    ( .clk0 (tx_coreclock), .we (tx_fifo_wren_pullup[11]),
      .reset (tx_aclr_pulldown), .re (1'b1),
      .clk1 (w_tx_clkout[11]), .datain (i_tx_in[11]),
      .overflow (i_tx_full[11]), .empty (i_tx_empty[11]),
      .dataout (i_fifo_out11) );
    defparam
        fifo11.channel_width = deserialization_factor;

    hssi_fifo fifo12
    ( .clk0 (tx_coreclock), .we (tx_fifo_wren_pullup[12]),
      .reset (tx_aclr_pulldown), .re (1'b1),
      .clk1 (w_tx_clkout[12]), .datain (i_tx_in[12]),
      .overflow (i_tx_full[12]), .empty (i_tx_empty[12]),
      .dataout (i_fifo_out12) );
    defparam
        fifo12.channel_width = deserialization_factor;

    hssi_fifo fifo13
    ( .clk0 (tx_coreclock), .we (tx_fifo_wren_pullup[13]),
      .reset (tx_aclr_pulldown), .re (1'b1),
      .clk1 (w_tx_clkout[13]), .datain (i_tx_in[13]),
      .overflow (i_tx_full[13]), .empty (i_tx_empty[13]),
      .dataout (i_fifo_out13) );
    defparam
        fifo13.channel_width = deserialization_factor;

    hssi_fifo fifo14
    ( .clk0 (tx_coreclock), .we (tx_fifo_wren_pullup[14]),
      .reset (tx_aclr_pulldown), .re (1'b1),
      .clk1 (w_tx_clkout[14]), .datain (i_tx_in[14]),
      .overflow (i_tx_full[14]), .empty (i_tx_empty[14]),
      .dataout (i_fifo_out14) );
    defparam
        fifo14.channel_width = deserialization_factor;

    hssi_fifo fifo15
    ( .clk0 (tx_coreclock), .we (tx_fifo_wren_pullup[15]),
      .reset (tx_aclr_pulldown), .re (1'b1),
      .clk1 (w_tx_clkout[15]), .datain (i_tx_in[15]),
      .overflow (i_tx_full[15]), .empty (i_tx_empty[15]),
      .dataout (i_fifo_out15) );
    defparam
        fifo15.channel_width = deserialization_factor;

    hssi_fifo fifo16
    ( .clk0 (tx_coreclock), .we (tx_fifo_wren_pullup[16]),
      .reset (tx_aclr_pulldown), .re (1'b1),
      .clk1 (w_tx_clkout[16]), .datain (i_tx_in[16]),
      .overflow (i_tx_full[16]), .empty (i_tx_empty[16]),
      .dataout (i_fifo_out16) );
    defparam
        fifo16.channel_width = deserialization_factor;

    hssi_fifo fifo17
    ( .clk0 (tx_coreclock), .we (tx_fifo_wren_pullup[17]),
      .reset (tx_aclr_pulldown), .re (1'b1),
      .clk1 (w_tx_clkout[17]), .datain (i_tx_in[17]),
      .overflow (i_tx_full[17]), .empty (i_tx_empty[17]),
      .dataout (i_fifo_out17) );
    defparam
        fifo17.channel_width = deserialization_factor;


    //--------------------------
    // Inputs
    always @ (tx_in)
       tx_in_int[deserialization_factor*number_of_channels-1: 0] = tx_in;

    always @(tx_in_int)
    begin
        i_tx_in[00] =
            tx_in_int[(01*deserialization_factor)-1:00*deserialization_factor];
        i_tx_in[01] =
            tx_in_int[(02*deserialization_factor)-1:01*deserialization_factor];
        i_tx_in[02] =
            tx_in_int[(03*deserialization_factor)-1:02*deserialization_factor];
        i_tx_in[03] =
            tx_in_int[(04*deserialization_factor)-1:03*deserialization_factor];
        i_tx_in[04] =
            tx_in_int[(05*deserialization_factor)-1:04*deserialization_factor];
        i_tx_in[05] =
            tx_in_int[(06*deserialization_factor)-1:05*deserialization_factor];
        i_tx_in[06] =
            tx_in_int[(07*deserialization_factor)-1:06*deserialization_factor];
        i_tx_in[07] =
            tx_in_int[(08*deserialization_factor)-1:07*deserialization_factor];
        i_tx_in[08] =
            tx_in_int[(09*deserialization_factor)-1:08*deserialization_factor];
        i_tx_in[09] =
            tx_in_int[(10*deserialization_factor)-1:09*deserialization_factor];
        i_tx_in[10] =
            tx_in_int[(11*deserialization_factor)-1:10*deserialization_factor];
        i_tx_in[11] =
            tx_in_int[(12*deserialization_factor)-1:11*deserialization_factor];
        i_tx_in[12] =
            tx_in_int[(13*deserialization_factor)-1:12*deserialization_factor];
        i_tx_in[13] =
            tx_in_int[(14*deserialization_factor)-1:13*deserialization_factor];
        i_tx_in[14] =
            tx_in_int[(15*deserialization_factor)-1:14*deserialization_factor];
        i_tx_in[15] =
            tx_in_int[(16*deserialization_factor)-1:15*deserialization_factor];
        i_tx_in[16] =
            tx_in_int[(17*deserialization_factor)-1:16*deserialization_factor];
        i_tx_in[17] =
            tx_in_int[(18*deserialization_factor)-1:17*deserialization_factor];
    end

//------------------------------------------------------------------
// select the input for hssi_tx - from FIFO or from data input directly
assign txin00 = (bypass_fifo == "OFF") ? i_fifo_out00 : i_tx_in[00];
assign txin01 = (bypass_fifo == "OFF") ? i_fifo_out01 : i_tx_in[01];
assign txin02 = (bypass_fifo == "OFF") ? i_fifo_out02 : i_tx_in[02];
assign txin03 = (bypass_fifo == "OFF") ? i_fifo_out03 : i_tx_in[03];
assign txin04 = (bypass_fifo == "OFF") ? i_fifo_out04 : i_tx_in[04];
assign txin05 = (bypass_fifo == "OFF") ? i_fifo_out05 : i_tx_in[05];
assign txin06 = (bypass_fifo == "OFF") ? i_fifo_out06 : i_tx_in[06];
assign txin07 = (bypass_fifo == "OFF") ? i_fifo_out07 : i_tx_in[07];
assign txin08 = (bypass_fifo == "OFF") ? i_fifo_out08 : i_tx_in[08];
assign txin09 = (bypass_fifo == "OFF") ? i_fifo_out09 : i_tx_in[09];
assign txin10 = (bypass_fifo == "OFF") ? i_fifo_out10 : i_tx_in[10];
assign txin11 = (bypass_fifo == "OFF") ? i_fifo_out11 : i_tx_in[11];
assign txin12 = (bypass_fifo == "OFF") ? i_fifo_out12 : i_tx_in[12];
assign txin13 = (bypass_fifo == "OFF") ? i_fifo_out13 : i_tx_in[13];
assign txin14 = (bypass_fifo == "OFF") ? i_fifo_out14 : i_tx_in[14];
assign txin15 = (bypass_fifo == "OFF") ? i_fifo_out15 : i_tx_in[15];
assign txin16 = (bypass_fifo == "OFF") ? i_fifo_out16 : i_tx_in[16];
assign txin17 = (bypass_fifo == "OFF") ? i_fifo_out17 : i_tx_in[17];

//-----------------------------------------------
// assign the correct signals to the output ports

assign tx_out      = (deserialization_factor > 1) ?
                     w_tx_out[number_of_channels-1:0]
                     : tx_in;

assign tx_outclock = (deserialization_factor > 1) ?
                     w_tx_clkout[00]
                     : tx_inclock;

assign tx_full     = (deserialization_factor == 1) ?
                     0
                     : (bypass_fifo == "OFF") ?
                      ~i_tx_full[number_of_channels-1:0]
                     : {number_of_channels{1'bX}};

assign tx_empty    = (deserialization_factor == 1) ?
                     0
                     : (bypass_fifo == "OFF") ?
                     ~i_tx_empty[number_of_channels-1:0]
                     : {number_of_channels{1'bX}};

assign tx_pll_locked = i_tx_pll_locked;

endmodule // altcdr_tx

`timescale 1 ps / 1 ps
module lcell (a_in, a_out);
input a_in;
output a_out;
assign a_out = a_in;
endmodule

`timescale 1 ps / 1 ps
module global (a_in, a_out);
input a_in;
output a_out;
assign a_out = a_in;
endmodule

`timescale 1 ps / 1 ps
module carry (a_in, a_out);
input a_in;
output a_out;
assign a_out = a_in;
endmodule

`timescale 1 ps / 1 ps
module cascade (a_in, a_out);
input a_in;
output a_out;
assign a_out = a_in;
endmodule


//START_MODULE_NAME------------------------------------------------------------
//
// Module Name     :  altaccumulate
//
// Description     :  Parameterized accumulator megafunction. The accumulator
// performs an add function or a subtract function based on the add_sub
// parameter. The input data can be signed or unsigned.
//
// Limitation      : n/a
//
// Results expected:  result - The results of add or subtract operation. Output
//                             port [width_out-1 .. 0] wide.
//                    cout   - The cout port has a physical interpretation as 
//                             the carry-out (borrow-in) of the MSB. The cout
//                             port is most meaningful for detecting overflow
//                             in unsigned operations. The cout port operates
//                             in the same manner for signed and unsigned
//                             operations.
//                    overflow - Indicates the accumulator is overflow.
//
//END_MODULE_NAME--------------------------------------------------------------

// BEGINNING OF MODULE

`timescale 1 ps / 1 ps

module altaccumulate (cin, data, add_sub, clock, sload, clken, sign_data, aclr,
                      result, cout, overflow);

    parameter width_in = 4;     // Required
    parameter width_out = 8;    // Required
    parameter lpm_representation = "UNSIGNED";
    parameter extra_latency = 0;
    parameter use_wys = "ON";
    parameter lpm_hint = "UNUSED";
    parameter lpm_type = "altaccumulate";

    // INPUT PORT DECLARATION
    input cin;
    input [width_in-1:0] data;  // Required port
    input add_sub;              // Default = 1
    input clock;                // Required port
    input sload;                // Default = 0
    input clken;                // Default = 1
    input sign_data;            // Default = 0
    input aclr;                 // Default = 0

    // OUTPUT PORT DECLARATION
    output [width_out-1:0] result;  //Required port
    output cout;
    output overflow;

    // INTERNAL REGISTERS DECLARATION
    reg [width_out:0] temp_sum;
    reg overflow;
    reg overflow_int;
    reg cout_int;
    reg cout_delayed;

    reg [width_out-1:0] result;
    reg [width_out+1:0] result_int;
    reg [(width_out - width_in) : 0] zeropad;

    reg borrow;
    reg cin_int;
    reg add_sub_int;
    reg sign_data_int;
    reg sload_int;

    reg [width_out-1:0] fb_int;
    reg [width_out -1:0] data_int;

    reg [width_out+1:0] result_pipe [extra_latency:0];
    reg [width_out+1:0] result_full;
    reg [width_out+1:0] result_full2;

    reg a;

    // INTERNAL WIRE DECLARATION
    wire [width_out:0] temp_sum_wire;
    wire cout;
    wire cout_int_wire;
    wire cout_delayed_wire;
    wire overflow_int_wire;
    wire [width_out+1:0] result_int_wire;

    // INTERNAL TRI DECLARATION
    tri1 clken_int;
    tri0 aclr_int;

    // LOCAL INTEGER DECLARATION
    integer head;
    integer i;

    // INITIAL CONSTRUCT BLOCK
    initial
    begin
        result = 0;
        cout_delayed = 0;
        overflow = 0;
        head = 0;
        result_int = 0;
        for (i = 0; i <= extra_latency; i = i +1)
        begin
            result_pipe [i] = 0;
        end
    end

    // ALWAYS CONSTRUCT BLOCK
    always @(posedge clock or posedge aclr_int)
    begin

        if (aclr_int == 1)
        begin
            result_int = 0;
            result = 0;
            overflow = 0;
            cout_delayed = 0;
            for (i = 0; i <= extra_latency; i = i +1)
            begin
                result_pipe [i] = 0;
            end
        end
        else
        begin
            if (clken_int == 1)
            begin
                //get result from output register
                if (extra_latency > 0)
                begin
                    result_pipe [head] = {
                                          result_int [width_out+1],
                                          {cout_int_wire, result_int [width_out-1:0]}
                                         };

                    head = (head + 1) % (extra_latency);

                    result_full = result_pipe [head];
                    cout_delayed = result_full [width_out];
                    result = result_full [width_out-1:0];
                    overflow = result_full [width_out+1];
                end
                else
                begin
                    result = temp_sum_wire;
                    overflow = overflow_int_wire;
                end

                result_int <= {overflow_int_wire, {cout_int_wire, temp_sum_wire [width_out-1:0]}};
            end
        end
    end

    always @ (data or cin or add_sub or sign_data or
              result_int_wire [width_out -1:0] or sload or aclr_int)
    begin

        // Get the input data and control signals.
        sign_data_int = (sign_data === 1'bz) ? 0 : sign_data;
        sload_int = (sload === 1'bz) ? 0 : sload;
        add_sub_int = (add_sub === 1'bz) ? 1 : add_sub;

        // If asynchronous clear, reset and skip.
        if (aclr_int == 1)  // asynchronous clear
        begin
            cout_int = 0;
            overflow_int = 0;
        end
        else
        begin

            if ((lpm_representation == "SIGNED") || (sign_data_int == 1))
            begin
                zeropad = (data [width_in-1] ==0) ? 0 : -1;
            end
            else
            begin
                zeropad = 0;
            end

            fb_int = (sload_int == 1'b1) ? 0 : result_int_wire [width_out-1:0];
            data_int = {zeropad, data};

            if ((add_sub_int == 1) || (sload_int == 1))
            begin
                cin_int = ((sload_int == 1'b1) ? 0 : ((cin === 1'bz) ? 0 : cin));
                temp_sum = fb_int + data_int + cin_int;
                cout_int = temp_sum [width_out];
            end
            else
            begin
                cin_int = (cin === 1'bz) ? 1 : cin;
                borrow = ~cin_int;

                temp_sum = fb_int - data_int - borrow;

                result_full2 = data_int + borrow;
                cout_int = (fb_int >= result_full2) ? 1 : 0;
            end

            if ((lpm_representation == "SIGNED") || (sign_data_int == 1))
            begin
                a = (data [width_in-1] ~^ fb_int [width_out-1]) ^ (~add_sub_int);
                overflow_int = a & (fb_int [width_out-1] ^ temp_sum[width_out-1]);
            end
            else
            begin
                overflow_int = (add_sub_int == 1) ? cout_int : ~cout_int;
            end

            if (sload_int == 1)
            begin
                cout_int = !add_sub_int;
                overflow_int = 0;
            end
        end
    end

    // CONTINOUS ASSIGNMENT
    assign clken_int = clken;
    assign aclr_int = aclr;
    assign result_int_wire = result_int;
    assign temp_sum_wire = temp_sum;
    assign cout_int_wire = cout_int;
    assign overflow_int_wire = overflow_int;
    assign cout = (extra_latency == 0) ? cout_int_wire : cout_delayed_wire;
    assign cout_delayed_wire = cout_delayed;

endmodule   // End of altaccumulate

// END OF MODULE

//--------------------------------------------------------------------------
// Module Name      : altmult_accum
//
// Description      : a*b + x (MAC)
//
// Limitation       : Stratix DSP block
//
// Results expected : signed & unsigned, maximum of 3 pipelines(latency) each.
//
//--------------------------------------------------------------------------

`timescale 1 ps / 1 ps

module altmult_accum (dataa, datab, addnsub, accum_sload, signa, signb, 
                      clock0, clock1, clock2, clock3, 
                      ena0, ena1, ena2, ena3, 
                      aclr0, aclr1, aclr2, aclr3, 
                      result, overflow, scanouta, scanoutb);

    // ---------------------
    // PARAMETER DECLARATION
    // ---------------------
    parameter width_a                   = 1;
    parameter width_b                   = 1;
    parameter width_result              = 2;
    parameter input_reg_a               = "CLOCK0";
    parameter input_aclr_a              = "ACLR3";
    parameter input_reg_b               = "CLOCK0";
    parameter input_aclr_b              = "ACLR3";
    parameter addnsub_reg               = "CLOCK0";
    parameter addnsub_aclr              = "ACLR3";
    parameter addnsub_pipeline_reg      = "CLOCK0";
    parameter addnsub_pipeline_aclr     = "ACLR3";
    parameter accum_direction           = "ADD";
    parameter accum_sload_reg           = "CLOCK0";
    parameter accum_sload_aclr          = "ACLR3";
    parameter accum_sload_pipeline_reg  = "CLOCK0";
    parameter accum_sload_pipeline_aclr = "ACLR3";
    parameter representation_a          = "UNSIGNED";
    parameter sign_reg_a                = "CLOCK0";
    parameter sign_aclr_a               = "ACLR3";
    parameter sign_pipeline_reg_a       = "CLOCK0";
    parameter sign_pipeline_aclr_a      = "ACLR3";
    parameter representation_b          = "UNSIGNED";
    parameter sign_reg_b                = "CLOCK0";
    parameter sign_aclr_b               = "ACLR3";
    parameter sign_pipeline_reg_b       = "CLOCK0";
    parameter sign_pipeline_aclr_b      = "ACLR3";
    parameter multiplier_reg            = "CLOCK0";
    parameter multiplier_aclr           = "ACLR3";
    parameter output_reg                = "CLOCK0";
    parameter output_aclr               = "ACLR3";
    parameter lpm_type                  = "altmult_accum";

    parameter extra_multiplier_latency       = 0;
    parameter extra_accumulator_latency      = 0;
    parameter dedicated_multiplier_circuitry = "AUTO";
    parameter dsp_block_balancing            = "AUTO";


    // ----------------
    // PORT DECLARATION
    // ----------------

    // data input ports
    input [width_a -1 : 0] dataa;
    input [width_b -1 : 0] datab;

    // control signals
    input addnsub;
    input accum_sload;
    input signa;
    input signb;

    // clock ports
    input clock0; 
    input clock1; 
    input clock2;
    input clock3;

    // clock enable ports
    input ena0;
    input ena1;
    input ena2;
    input ena3;
    
    // clear ports
    input aclr0;
    input aclr1;
    input aclr2;
    input aclr3;

    // output ports
    output [width_result -1 : 0] result;
    output overflow;
    output [width_a -1 : 0] scanouta;
    output [width_b -1 : 0] scanoutb; 


    // ---------------
    // REG DECLARATION
    // ---------------
    reg [width_result -1 : 0] result;
    reg [width_result -1 :0] mult_res_out;
    reg [width_result:0] temp_sum;
    reg [width_result + 1 :0] answer;
    reg [width_result:0] result_pipe [extra_accumulator_latency:0];
    reg [width_result:0] result_full ;
    reg [width_result-1:0] result_int ;
    reg [width_a -1 :0] mult_a;
    reg [width_a -1 :0] mult_a_int;
    reg [width_a + width_b-1 :0] mult_res;
    reg [width_a + width_b-1:0] temp_mult;
    reg [width_a + width_b-1:0] temp_mult_zero;
    reg [width_b -1 :0] mult_b;
    reg [width_b -1 :0] mult_b_int;
    reg [4 + width_a + width_b:0] mult_pipe [extra_multiplier_latency:0];
    reg [4 + width_a + width_b :0] mult_full;

    reg mult_pipe_clk, mult_pipe_en, mult_pipe_clr;
    reg mult_signed_out; 

    reg zero_acc_reg;
    reg zero_acc_pipe;

    reg sign_a_reg;
    reg sign_a_pipe;
    reg sign_b_reg;
    reg sign_b_pipe;
    reg addsub_reg;
    reg addsub_pipe;

    reg input_reg_a_clk;
    reg input_reg_a_clr;
    reg input_reg_a_en;

    reg input_reg_b_clk;
    reg input_reg_b_clr;
    reg input_reg_b_en;

    reg addsub_reg_clk;
    reg addsub_reg_clr;
    reg addsub_reg_en;

    reg addsub_pipe_clk;
    reg addsub_pipe_clr;
    reg addsub_pipe_en;

    reg zero_reg_clk;
    reg zero_reg_clr;
    reg zero_reg_en;

    reg zero_pipe_clk;
    reg zero_pipe_clr;
    reg zero_pipe_en;

    reg sign_reg_a_clk;
    reg sign_reg_a_clr;
    reg sign_reg_a_en;

    reg sign_pipe_a_clk;
    reg sign_pipe_a_clr;
    reg sign_pipe_a_en;

    reg sign_reg_b_clk;
    reg sign_reg_b_clr;
    reg sign_reg_b_en;

    reg sign_pipe_b_clk;
    reg sign_pipe_b_clr;
    reg sign_pipe_b_en;

    reg multiplier_reg_clk;
    reg multiplier_reg_clr;
    reg multiplier_reg_en;

    reg output_reg_clk;
    reg output_reg_clr;
    reg output_reg_en;

    reg mult_signed;
    reg temp_mult_signed;
    reg neg_a;
    reg neg_b;

    reg overflow_int;
    reg cout_int;
    reg overflow_tmp_int;
    
    reg overflow;

    
    // -------------------
    // INTEGER DECLARATION
    // -------------------
    integer head_result;
    integer i;
    integer head_mult;


    // ----------------
    // WIRE DECLARATION
    // ----------------
    wire [width_a -1 : 0] scanouta;
    wire [width_a + width_b -1 : 0] mult_out_latent;
    wire [width_b -1 : 0] scanoutb; 

    wire addsub_int;
    wire sign_a_int;
    wire sign_b_int;

    wire zero_acc_int;
    wire sign_a_reg_int;
    wire sign_b_reg_int;

    wire addsub_latent;
    wire zeroacc_latent;
    wire signa_latent;
    wire signb_latent;

    wire mult_signed_latent;


    // --------------------
    // ASSIGNMENT STATEMENTS
    // --------------------
    assign addsub_int     = ((addnsub ===1'bz) || 
                             (addsub_reg_clk ===1'bz) || 
                             (addsub_pipe_clk===1'bz)) ? 
                                 ((accum_direction == "ADD") ? 1: 0) : addsub_pipe;
    assign sign_a_int     = ((signa ===1'bz) || 
                             (sign_reg_a_clk ===1'bz) || 
                             (sign_pipe_a_clk ===1'bz)) ? 
                                 ((representation_a == "SIGNED") ? 1 : 0) : sign_a_pipe;
    assign sign_b_int     = ((signb ===1'bz) || 
                             (sign_reg_b_clk ===1'bz) || 
                             (sign_pipe_b_clk ===1'bz)) ? 
                                 ((representation_b == "SIGNED") ? 1 : 0) : sign_b_pipe;
    assign sign_a_reg_int = ((signa ===1'bz) || 
                             (sign_reg_a_clk ===1'bz) || 
                             (sign_pipe_a_clk ===1'bz)) ? 
                                 ((representation_a == "SIGNED") ? 1 : 0) : sign_a_reg;
    assign sign_b_reg_int = ((signb ===1'bz) || 
                             (sign_reg_b_clk ===1'bz) || 
                             (sign_pipe_b_clk ===1'bz)) ? 
                                 ((representation_b == "SIGNED") ? 1 : 0) : sign_b_reg;
    assign zero_acc_int   = ((accum_sload ===1'bz) || 
                             (zero_reg_clk===1'bz) || 
                             (zero_pipe_clk===1'bz)) ? 
                                 0 : zero_acc_pipe;

    assign scanouta       = mult_a;
    assign scanoutb       = mult_b;

    assign {addsub_latent, zeroacc_latent, signa_latent, signb_latent, mult_signed_latent, mult_out_latent} = (extra_multiplier_latency > 0) ? 
               mult_full : {addsub_reg, zero_acc_reg, sign_a_reg, sign_b_reg, temp_mult_signed, temp_mult};


    // --------------------------------------------
    // This function takes in a string (clock name)
    // and send back the corresponding clock signal
    // --------------------------------------------
    function resolve_clock;
        input [47:0] name ;  // 8-bits character storage for name "CLOCK?"
    begin:resolution
        reg clock;

        case (name)
            "CLOCK0"       : begin clock = clock0; end
            "CLOCK1"       : begin clock = clock1; end
            "CLOCK2"       : begin clock = clock2; end
            "CLOCK3"       : begin clock = clock3; end
            "UNREGISTERED" : begin clock = 0     ; end
            default        : begin clock = 0     ; end
        endcase

        resolve_clock = clock;
    end
    endfunction


    // ---------------------------------------------------
    // This function takes in a string (clock name)
    // and send back the corresponding clock enable signal
    // ---------------------------------------------------
    function resolve_enable;
        input [47:0] name;  // 8-bits character storage for name "CLOCK?"
    begin:resolution
        reg enable;

        case (name)
            "CLOCK0" : begin enable = (ena0===1'bz) ? 1 : ena0; end
            "CLOCK1" : begin enable = (ena1===1'bz) ? 1 : ena1; end
            "CLOCK2" : begin enable = (ena2===1'bz) ? 1 : ena2; end
            "CLOCK3" : begin enable = (ena3===1'bz) ? 1 : ena3; end
            default  : begin $display("Warning: Unknown string passed to function resolve_enable"); end
        endcase

        resolve_enable = enable;
    end
    endfunction


    // --------------------------------------------
    // This function takes in a string (clear name)
    // and send back the corresponding clear signal
    // --------------------------------------------
    function resolve_clr;
        input [39:0] name ;  // 8-bits character storage for name "ACLR?"
    begin:resolution
        reg clr;

        case (name)
            "ACLR0" : begin clr = (aclr0===1'bz) ? 0 : aclr0; end
            "ACLR1" : begin clr = (aclr1===1'bz) ? 0 : aclr1; end
            "ACLR2" : begin clr = (aclr2===1'bz) ? 0 : aclr2; end
            "ACLR3" : begin clr = (aclr3===1'bz) ? 0 : aclr3; end
            default  : begin $display("Warning: Unknown string passed to function resolve_clr"); end
        endcase

        resolve_clr = clr;
    end
    endfunction


    // ---------------------------------------------------------------------------------
    // Initialization block where all the internal signals and registers are initialized
    // ---------------------------------------------------------------------------------
    initial
    begin

        // Checking for invalid parameters, in case Wizard is bypassed (hand-modified).
        if (width_result < (width_a + width_b))
        begin
            $display("Error: width_result cannot be less than (width_a + width_b)");
            $stop;
        end

        temp_sum       = 0;
        answer         = 0;
        head_result    = 0;
        head_mult      = 0;
        temp_mult      = 0;
        overflow_int   = 0;
        mult_a         = 0;
        mult_b         = 0;
        temp_mult_zero = 0;
        zero_acc_reg   = 0;
        zero_acc_pipe  = 0;

        sign_a_reg  = (signa ===1'bz)   ? ((representation_a == "SIGNED") ? 1 : 0) : 0;
        sign_a_pipe = (signa ===1'bz)   ? ((representation_a == "SIGNED") ? 1 : 0) : 0;
        sign_b_reg  = (signb ===1'bz)   ? ((representation_b == "SIGNED") ? 1 : 0) : 0;
        sign_b_pipe = (signb ===1'bz)   ? ((representation_b == "SIGNED") ? 1 : 0) : 0;
        addsub_reg  = (addnsub ===1'bz) ? ((accum_direction == "ADD")     ? 1 : 0) : 0;
        addsub_pipe = (addnsub ===1'bz) ? ((accum_direction == "ADD")     ? 1 : 0) : 0;

        result_int      = 0;
        result          = 0;
        overflow        = 0;
        mult_full       = 0;
        mult_res_out    = 0;
        mult_signed_out = 0;
        mult_res        = 0;

        input_reg_a_en = resolve_enable (input_reg_a); 
        input_reg_b_en = resolve_enable (input_reg_b);
        addsub_reg_en  = resolve_enable (addnsub_reg);  
        addsub_pipe_en = resolve_enable (addnsub_pipeline_reg);  

        zero_reg_en       = resolve_enable (accum_sload_reg);  
        zero_pipe_en      = resolve_enable (accum_sload_pipeline_reg);  
        sign_reg_a_en     = resolve_enable (sign_reg_a);  
        sign_reg_b_en     = resolve_enable (sign_reg_b);  
        sign_pipe_a_en    = resolve_enable (sign_pipeline_reg_a);  
        sign_pipe_b_en    = resolve_enable (sign_pipeline_reg_b);  
        multiplier_reg_en = resolve_enable (multiplier_reg); 
        output_reg_en     = resolve_enable (output_reg); 
        mult_pipe_en      = (multiplier_reg == "UNREGISTERED") ? 
                             resolve_enable ("CLOCK0") : multiplier_reg_en;

        input_reg_a_clr    = resolve_clr (input_aclr_a);
        input_reg_b_clr    = resolve_clr (input_aclr_b);
        addsub_reg_clr     = resolve_clr (addnsub_aclr);
        addsub_pipe_clr    = resolve_clr (addnsub_pipeline_aclr);
        zero_reg_clr       = resolve_clr (accum_sload_aclr);
        zero_pipe_clr      = resolve_clr (accum_sload_pipeline_aclr);
        sign_reg_a_clr     = resolve_clr (sign_aclr_a);
        sign_reg_b_clr     = resolve_clr (sign_aclr_b);
        sign_pipe_a_clr    = resolve_clr (sign_pipeline_aclr_a);
        sign_pipe_b_clr    = resolve_clr (sign_pipeline_aclr_b);
        multiplier_reg_clr = resolve_clr (multiplier_aclr);
        output_reg_clr     = resolve_clr (output_aclr);
        mult_pipe_clr      = (multiplier_reg == "UNREGISTERED") ? 
                              resolve_clr("ACLR0") : multiplier_reg_clr;

        for (i=0; i<=extra_accumulator_latency; i=i+1)
        begin
            result_pipe [i] = 0;
        end

        for (i=0; i<= extra_multiplier_latency; i=i+1)
        begin
            mult_pipe [i] = 0;
        end

    end

    
    // ---------------------------------------------------------
    // This block updates the internal clock signals accordingly
    // every time the global clock signal changes state
    // ---------------------------------------------------------
    always @(clock0 or clock1 or clock2 or clock3)
    begin
        input_reg_a_clk    = resolve_clock (input_reg_a);
        input_reg_b_clk    = resolve_clock (input_reg_b);
        addsub_reg_clk     = resolve_clock (addnsub_reg);
        addsub_pipe_clk    = resolve_clock (addnsub_pipeline_reg);
        zero_reg_clk       = resolve_clock (accum_sload_reg);
        zero_pipe_clk      = resolve_clock (accum_sload_pipeline_reg);
        sign_reg_a_clk     = resolve_clock (sign_reg_a);
        sign_reg_b_clk     = resolve_clock (sign_reg_b);
        sign_pipe_a_clk    = resolve_clock (sign_pipeline_reg_a);
        sign_pipe_b_clk    = resolve_clock (sign_pipeline_reg_b);
        multiplier_reg_clk = resolve_clock (multiplier_reg);
        output_reg_clk     = resolve_clock (output_reg);
        mult_pipe_clk      = (multiplier_reg == "UNREGISTERED") ? resolve_clock ("CLOCK0") : multiplier_reg_clk;
    end


    // ---------------------------------------------------------
    // This block updates the internal clear signals accordingly
    // every time the global clear signal changes state
    // ---------------------------------------------------------
    always @(aclr0 or aclr1 or aclr2 or aclr3)
    begin
        input_reg_a_clr    = resolve_clr (input_aclr_a);
        input_reg_b_clr    = resolve_clr (input_aclr_b);
        addsub_reg_clr     = resolve_clr (addnsub_aclr);
        addsub_pipe_clr    = resolve_clr (addnsub_pipeline_aclr);
        zero_reg_clr       = resolve_clr (accum_sload_aclr);
        zero_pipe_clr      = resolve_clr (accum_sload_pipeline_aclr);
        sign_reg_a_clr     = resolve_clr (sign_aclr_a);
        sign_reg_b_clr     = resolve_clr (sign_aclr_b);
        sign_pipe_a_clr    = resolve_clr (sign_pipeline_aclr_a);
        sign_pipe_b_clr    = resolve_clr (sign_pipeline_aclr_b);
        multiplier_reg_clr = resolve_clr (multiplier_aclr);
        output_reg_clr     = resolve_clr (output_aclr);
        mult_pipe_clr      = (multiplier_reg == "UNREGISTERED") ? resolve_clr("ACLR0") : multiplier_reg_clr;
    end


    // ----------------------------------------------------------------
    // This block updates the internal clock enable signals accordingly
    // every time the global clock enable signal changes state
    // ----------------------------------------------------------------
    always @(ena0 or ena1 or ena2 or ena3)
    begin
        input_reg_a_en    = resolve_enable (input_reg_a); 
        input_reg_b_en    = resolve_enable (input_reg_b);
        addsub_reg_en     = resolve_enable (addnsub_reg);  
        addsub_pipe_en    = resolve_enable (addnsub_pipeline_reg);  
        zero_reg_en       = resolve_enable (accum_sload_reg);  
        zero_pipe_en      = resolve_enable (accum_sload_pipeline_reg);  
        sign_reg_a_en     = resolve_enable (sign_reg_a);  
        sign_reg_b_en     = resolve_enable (sign_reg_b);  
        sign_pipe_a_en    = resolve_enable (sign_pipeline_reg_a);  
        sign_pipe_b_en    = resolve_enable (sign_pipeline_reg_b);  
        multiplier_reg_en = resolve_enable (multiplier_reg); 
        output_reg_en     = resolve_enable (output_reg); 
        mult_pipe_en      = (multiplier_reg == "UNREGISTERED") ? resolve_enable("CLOCK0") : multiplier_reg_en;
    end


    // ------------------------------------------------------------------------
    // This block contains 1 register and 1 combinatorial block (to set mult_a)
    // Signal Registered : dataa
    //
    // Register is controlled by posedge input_reg_a_clk
    // Register has an asynchronous clear signal, input_reg_a_clr
    // NOTE : The combinatorial block will be executed if
    //        input_reg_a is unregistered and dataa changes value
    // ------------------------------------------------------------------------
    always @(posedge input_reg_a_clk or posedge input_reg_a_clr or ( {width_a{(input_reg_a == "UNREGISTERED") || (input_reg_a_clk === 1'bz)}} & dataa))
    begin
        if ((input_reg_a == "UNREGISTERED") || (input_reg_a_clk === 1'bz))
            mult_a = dataa;
        else
        begin
            if (input_reg_a_clr == 1)
                mult_a = 0;
            else if ((input_reg_a_clk == 1) && (input_reg_a_en == 1)) 
                mult_a = dataa;        
        end
    end


    // ------------------------------------------------------------------------
    // This block contains 1 register and 1 combinatorial block (to set mult_b)
    // Signal Registered : datab
    //
    // Register is controlled by posedge input_reg_b_clk
    // Register has an asynchronous clear signal, input_reg_b_clr
    // NOTE : The combinatorial block will be executed if
    //        input_reg_b is unregistered and datab changes value
    // ------------------------------------------------------------------------
    always @(posedge input_reg_b_clk or posedge input_reg_b_clr or ({width_b{(input_reg_b == "UNREGISTERED") || (input_reg_a_clk === 1'bz)}} & datab))
    begin
        if ((input_reg_b == "UNREGISTERED") || (input_reg_a_clk === 1'bz))
            mult_b = datab;
        else
        begin
            if (input_reg_b_clr == 1)
                mult_b = 0;
            else if ((input_reg_b_clk == 1) && (input_reg_b_en == 1)) 
                mult_b = datab;        
        end
    end


    // -----------------------------------------------------------------------------
    // This block contains 1 register and 1 combinatorial block (to set addnsub_reg)
    // Signal Registered : addnsub
    //
    // Register is controlled by posedge addsub_reg_clk
    // Register has an asynchronous clear signal, addsub_reg_clr
    // NOTE : The combinatorial block will be executed if
    //        addnsub_reg is unregistered and addnsub changes value
    // -----------------------------------------------------------------------------
    always @(posedge addsub_reg_clk or posedge addsub_reg_clr or ((addnsub_reg == "UNREGISTERED") && addnsub))
    begin
        if (addnsub_reg == "UNREGISTERED")
            addsub_reg = addnsub;
        else
        begin
            if (addsub_reg_clr == 1)
                addsub_reg <= 0;
            else if ((addsub_reg_clk == 1) && (addsub_reg_en == 1)) 
                addsub_reg <= addnsub;
        end
    end


    // -----------------------------------------------------------------------------
    // This block contains 1 register and 1 combinatorial block (to set addsub_pipe)
    // Signal Registered : addsub_latent
    //
    // Register is controlled by posedge addsub_pipe_clk
    // Register has an asynchronous clear signal, addsub_pipe_clr
    // NOTE : The combinatorial block will be executed if
    //        addsub_pipeline_reg is unregistered and addsub_latent changes value
    // -----------------------------------------------------------------------------
    always @(posedge addsub_pipe_clk or posedge addsub_pipe_clr or ((addnsub_pipeline_reg == "UNREGISTERED") && addsub_latent))
    begin
        if (addnsub_pipeline_reg == "UNREGISTERED")
            addsub_pipe =  addsub_latent;
        else
        begin
            if (addsub_pipe_clr == 1)
                addsub_pipe = 0;
            else if ((addsub_pipe_clk == 1) && (addsub_pipe_en == 1))
                addsub_pipe = addsub_latent;        
        end
    end


    // ------------------------------------------------------------------------------
    // This block contains 1 register and 1 combinatorial block (to set zero_acc_reg)
    // Signal Registered : accum_sload
    //
    // Register is controlled by posedge zero_reg_clk
    // Register has an asynchronous clear signal, zero_reg_clr
    // NOTE : The combinatorial block will be executed if
    //        accum_sload_reg is unregistered and accum_sload changes value
    // ------------------------------------------------------------------------------
    always @(posedge zero_reg_clk or posedge zero_reg_clr or (((accum_sload_reg == "UNREGISTERED") || (zero_reg_clk === 1'bz)) & accum_sload))
    begin
        if (accum_sload_reg == "UNREGISTERED")
            zero_acc_reg =  accum_sload;
        else
        begin
            if (zero_reg_clr == 1)
                zero_acc_reg <= 0;
            else if ((zero_reg_clk == 1) && (zero_reg_en == 1))
                zero_acc_reg <=  accum_sload;
        end
    end


    // --------------------------------------------------------------------------------
    // This block contains 1 register and 1 combinatorial block (to set zero_acc_pipe)
    // Signal Registered : zeroacc_latent
    //
    // Register is controlled by posedge zero_pipe_clk
    // Register has an asynchronous clear signal, zero_pipe_clr
    // NOTE : The combinatorial block will be executed if
    //        accum_sload_pipeline_reg is unregistered and zeroacc_latent changes value
    // --------------------------------------------------------------------------------
    always @(posedge zero_pipe_clk or posedge zero_pipe_clr or (((accum_sload_pipeline_reg == "UNREGISTERED") || (zero_pipe_clk ===1'bz)) & zeroacc_latent))
    begin
        if (accum_sload_pipeline_reg == "UNREGISTERED")
            zero_acc_pipe = zeroacc_latent;
        else
        begin
            if (zero_pipe_clr == 1)
                zero_acc_pipe = 0;
            else if ((zero_pipe_clk == 1) && (zero_pipe_en == 1))
                zero_acc_pipe = zeroacc_latent;        
        end
    end


    // ----------------------------------------------------------------------------
    // This block contains 1 register and 1 combinatorial block (to set sign_a_reg)
    // Signal Registered : signa
    //
    // Register is controlled by posedge sign_reg_a_clk
    // Register has an asynchronous clear signal, sign_reg_a_clr
    // NOTE : The combinatorial block will be executed if
    //        sign_reg_a is unregistered and signa changes value
    // ----------------------------------------------------------------------------
    always @(posedge sign_reg_a_clk or posedge sign_reg_a_clr or ((sign_reg_a == "UNREGISTERED") && signa))
    begin
        if (sign_reg_a == "UNREGISTERED")
            sign_a_reg = signa;
        else
        begin
            if (sign_reg_a_clr == 1)
                sign_a_reg <= 0;
            else if ((sign_reg_a_clk == 1) && (sign_reg_a_en == 1))
                sign_a_reg <= signa;        
        end
    end


    // -----------------------------------------------------------------------------
    // This block contains 1 register and 1 combinatorial block (to set sign_a_pipe)
    // Signal Registered : signa_latent
    //
    // Register is controlled by posedge sign_pipe_a_clk
    // Register has an asynchronous clear signal, sign_pipe_a_clr
    // NOTE : The combinatorial block will be executed if
    //        sign_pipeline_reg_a is unregistered and signa_latent changes value
    // -----------------------------------------------------------------------------
    always @(posedge sign_pipe_a_clk or posedge sign_pipe_a_clr or ((sign_pipeline_reg_a == "UNREGISTERED") && signa_latent))
    begin
        if (sign_pipeline_reg_a == "UNREGISTERED")
            sign_a_pipe = signa_latent;
        else
        begin
            if (sign_pipe_a_clr == 1)
                sign_a_pipe = 0;
            else if ((sign_pipe_a_clk == 1) && (sign_pipe_a_en == 1))
                sign_a_pipe = signa_latent;        
        end
    end


    // ----------------------------------------------------------------------------
    // This block contains 1 register and 1 combinatorial block (to set sign_b_reg)
    // Signal Registered : signb
    //
    // Register is controlled by posedge sign_reg_b_clk
    // Register has an asynchronous clear signal, sign_reg_b_clr
    // NOTE : The combinatorial block will be executed if
    //        sign_reg_b is unregistered and signb changes value
    // ----------------------------------------------------------------------------
    always @(posedge sign_reg_b_clk or posedge sign_reg_b_clr or ((sign_reg_b == "UNREGISTERED") && signb))
    begin
        if ((sign_reg_b == "UNREGISTERED") || (sign_reg_b_clk === 1'bz))
            sign_b_reg = signb;
        else
        begin
            if (sign_reg_b_clr == 1)
                sign_b_reg <= 0;
            else if ((sign_reg_b_clk == 1) && (sign_reg_b_en == 1))
                sign_b_reg <= signb;    
        end
    end


    // -----------------------------------------------------------------------------
    // This block contains 1 register and 1 combinatorial block (to set sign_b_pipe)
    // Signal Registered : signb_latent
    //
    // Register is controlled by posedge sign_pipe_b_clk
    // Register has an asynchronous clear signal, sign_pipe_b_clr
    // NOTE : The combinatorial block will be executed if
    //        sign_pipeline_reg_b is unregistered and signb_latent changes value
    // -----------------------------------------------------------------------------
    always @(posedge sign_pipe_b_clk or posedge sign_pipe_b_clr or ((sign_pipeline_reg_b == "UNREGISTERED") && signb_latent))
    begin
        if (sign_pipeline_reg_b == "UNREGISTERED" )
            sign_b_pipe = signb_latent;
        else
        begin
            if (sign_pipe_b_clr == 1)
                sign_b_pipe = 0;
            else if ((sign_pipe_b_clk == 1) && (sign_pipe_b_en == 1))
                sign_b_pipe =  signb_latent;        
        end
    end

    
    // ------------------------------------------------------------------------------------------------------
    // This block checks if the two numbers to be multiplied (mult_a/mult_b) is to be interpreted
    // as a negative number ot not. If so, then two's complement is performed.
    // The numbers are then multipled
    // The sign of the result (positive or negative) is determined based on the sign of the two input numbers
    // ------------------------------------------------------------------------------------------------------
    always @(mult_a or mult_b or sign_a_reg_int or sign_b_reg_int)
    begin
        neg_a = mult_a [width_a-1] & (sign_a_reg_int);
        neg_b = mult_b [width_b-1] & (sign_b_reg_int);

        mult_a_int = (neg_a == 1) ? ~mult_a + 1 : mult_a;
        mult_b_int = (neg_b == 1) ? ~mult_b + 1 : mult_b;
    
        temp_mult        = mult_a_int * mult_b_int;
        temp_mult_signed = sign_a_reg_int | sign_b_reg_int;
        temp_mult        = (neg_a ^ neg_b) ? (temp_mult_zero - temp_mult) : temp_mult;
    end


    // ---------------------------------------------------------------------------------------
    // This block contains 2 register (to set mult_res and mult_signed)
    // Signals Registered : mult_out_latent, mult_signed_latent
    //
    // Both the registers are controlled by the same clock signal, posedge multiplier_reg_clk
    // Both registers share the same clock enable signal multipler_reg_en
    // Both registers have the same asynchronous signal, posedge multiplier_reg_clr
    // ---------------------------------------------------------------------------------------
    always @(posedge multiplier_reg_clk or posedge multiplier_reg_clr)
    begin
        if (multiplier_reg_clr == 1)
        begin    
            mult_res <=0;
            mult_signed =0;
        end
        else if ((multiplier_reg_clk == 1) && (multiplier_reg_en == 1))
        begin
            mult_res <= mult_out_latent;
            mult_signed = mult_signed_latent;        
        end
    end


    // --------------------------------------------------------------------
    // This block contains 1 register (to set mult_full)
    // Signal Registered : mult_pipe
    //
    // Register is controlled by posedge mult_pipe_clk
    // Register also has an asynchronous clear signal posedge mult_pipe_clr
    // --------------------------------------------------------------------
    always @(posedge mult_pipe_clk or posedge mult_pipe_clr ) 
    begin
        if (mult_pipe_clr ==1)
        begin
            // clear the pipeline
            for (i=0; i<=extra_multiplier_latency; i=i+1)
            begin
                mult_pipe [i] = 0;
            end
            mult_full = 0;
        end
        else if ((mult_pipe_clk == 1) && (mult_pipe_en == 1))
        begin
            mult_pipe [head_mult] = {addsub_reg, zero_acc_reg, sign_a_reg, sign_b_reg, temp_mult_signed, temp_mult};
            head_mult             = (head_mult +1) % (extra_multiplier_latency);
            mult_full             = mult_pipe[head_mult];
    end    
    end

 
    // -------------------------------------------------------------
    // This is the main process block that performs the accumulation
    // -------------------------------------------------------------
    always @(posedge output_reg_clk or posedge output_reg_clr)
    begin
        if (output_reg_clr == 1)
        begin
            temp_sum = 0;
            overflow_int = 0;
            for (i=0; i<=extra_accumulator_latency; i=i+1)
            begin
                result_pipe [i] = 0;
            end
        end
        else if ((output_reg_clk ==1) && (output_reg_en ==1))
        begin
            if (multiplier_reg == "UNREGISTERED")        
            begin
                mult_res_out    =  {{width_result - width_a - width_b {(sign_a_int | sign_b_int) & mult_out_latent [width_a+width_b -1]}}, mult_out_latent};
                mult_signed_out =  (sign_a_int | sign_b_int);
            end
            else
            begin
                mult_res_out    =  {{width_result - width_a - width_b {(sign_a_int | sign_b_int) & mult_res [width_a+width_b -1]}}, mult_res};
                mult_signed_out =  (sign_a_int | sign_b_int);    
            end

            if (addsub_int)  
            begin
                //add
                temp_sum = ( (zero_acc_int==0) ? result_int : 0) + mult_res_out;
                cout_int = temp_sum [width_result];
            end
            else
            begin
                //subtract
                temp_sum = ( (zero_acc_int==0) ? result_int : 0) - (mult_res_out);
                cout_int = (( (zero_acc_int==0) ? result_int : 0) >= mult_res_out) ? 1 : 0;
            end        

            //compute overflow
            if ((mult_signed_out==1) && (mult_res_out != 0))
            begin        
                overflow_tmp_int = (mult_res_out [width_a+width_b -1] ~^ result_int [width_result-1]) ^ (~addsub_int);
                overflow_int     =  overflow_tmp_int & (result_int [width_result -1] ^ temp_sum[width_result -1]);
            end
            else
            begin
                overflow_int = (addsub_int ==1)? cout_int : ~cout_int;
            end
        end

        result_int = temp_sum [width_result-1:0];

        if (extra_accumulator_latency==0)
        begin
            result   = temp_sum [width_result-1 :0];
            overflow = overflow_int;
        end
        else
        begin
            result_pipe [head_result] = {overflow_int, temp_sum [width_result-1:0]};
            head_result               = (head_result +1) % (extra_accumulator_latency);
            result_full               = result_pipe[head_result];
            result                    = result_full [width_result-1:0];    
            overflow                  = result_full [width_result];                    
        end
    end

endmodule  // end of ALTMULT_ACCUM


//--------------------------------------------------------------------------
// Module Name      : altmult_add
//
// Description      : a*b + c*d
//
// Limitation       : Stratix DSP block
//
// Results expected : signed & unsigned, maximum of 3 pipelines(latency) each.
//                    possible of zero pipeline.
//
//--------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module altmult_add (dataa, datab, 
                    clock3, clock2, clock1, clock0, 
                    aclr3, aclr2, aclr1, aclr0, 
                    ena3, ena2, ena1, ena0, 
                    signa, signb, addnsub1, addnsub3, 
                    result, scanouta, scanoutb);

    // ---------------------
    // PARAMETER DECLARATION
    // ---------------------

    parameter width_a               = 1;
    parameter width_b               = 1;
    parameter width_result          = 1;
    parameter number_of_multipliers = 1;
    parameter lpm_type              = "altmult_add";

    // A inputs

    parameter multiplier1_direction = "UNUSED";
    parameter multiplier3_direction = "UNUSED";

    parameter input_register_a0 = "CLOCK0";
    parameter input_aclr_a0     = "ACLR3";
    parameter input_source_a0   = "DATAA";

    parameter input_register_a1 = "CLOCK0";
    parameter input_aclr_a1     = "ACLR3";
    parameter input_source_a1   = "DATAA";

    parameter input_register_a2 = "CLOCK0";
    parameter input_aclr_a2     = "ACLR3";
    parameter input_source_a2   = "DATAA";

    parameter input_register_a3 = "CLOCK0";
    parameter input_aclr_a3     = "ACLR3";
    parameter input_source_a3   = "DATAA";

    parameter representation_a           = "UNUSED";
    parameter signed_register_a          = "CLOCK0";
    parameter signed_aclr_a              = "ACLR3";
    parameter signed_pipeline_register_a = "CLOCK0";
    parameter signed_pipeline_aclr_a     = "ACLR3";

    // B inputs

    parameter input_register_b0 = "CLOCK0";
    parameter input_aclr_b0     = "ACLR3";
    parameter input_source_b0   = "DATAB";

    parameter input_register_b1 = "CLOCK0";
    parameter input_aclr_b1     = "ACLR3";
    parameter input_source_b1   = "DATAB";

    parameter input_register_b2 = "CLOCK0";
    parameter input_aclr_b2     = "ACLR3";
    parameter input_source_b2   = "DATAB";

    parameter input_register_b3 = "CLOCK0";
    parameter input_aclr_b3     = "ACLR3";
    parameter input_source_b3   = "DATAB";

    parameter representation_b           = "UNUSED";
    parameter signed_register_b          = "CLOCK0";
    parameter signed_aclr_b              = "ACLR3";
    parameter signed_pipeline_register_b = "CLOCK0";
    parameter signed_pipeline_aclr_b     = "ACLR3";

    // multiplier parameters

    parameter multiplier_register0 = "CLOCK0";
    parameter multiplier_aclr0     = "ACLR3";
    parameter multiplier_register1 = "CLOCK0";
    parameter multiplier_aclr1     = "ACLR3";
    parameter multiplier_register2 = "CLOCK0";
    parameter multiplier_aclr2     = "ACLR3";
    parameter multiplier_register3 = "CLOCK0";
    parameter multiplier_aclr3     = "ACLR3";

    parameter addnsub_multiplier_register1          = "CLOCK0";
    parameter addnsub_multiplier_aclr1              = "ACLR3";
    parameter addnsub_multiplier_pipeline_register1 = "CLOCK0";
    parameter addnsub_multiplier_pipeline_aclr1     = "ACLR3";
   
    parameter addnsub_multiplier_register3          = "CLOCK0";
    parameter addnsub_multiplier_aclr3              = "ACLR3";
    parameter addnsub_multiplier_pipeline_register3 = "CLOCK0";
    parameter addnsub_multiplier_pipeline_aclr3     = "ACLR3";
 
    // output parameters
  
    parameter output_register = "CLOCK0";
    parameter output_aclr     = "ACLR0";
 
    // general setting parameters

    parameter extra_latency                  = 0;
    parameter dedicated_multiplier_circuitry = "AUTO";
    parameter dsp_block_balancing            = "AUTO";
    parameter intended_device_family         = "Stratix";

    // ----------------
    // PORT DECLARATION
    // ----------------

    // data input ports
    input [number_of_multipliers * width_a -1 : 0] dataa;
    input [number_of_multipliers * width_b -1 : 0] datab;
 
    // clock ports
    input clock3;
    input clock2;
    input clock1;
    input clock0;

    // clear ports
    input aclr3;
    input aclr2;
    input aclr1;
    input aclr0;

    // clock enable ports
    input ena3;
    input ena2;
    input ena1;
    input ena0;

    // control signals
    input signa;
    input signb;
    input addnsub1;
    input addnsub3;

    // output ports
    output [width_result -1 : 0] result;
    output [width_a -1 : 0] scanouta;
    output [width_b -1 : 0] scanoutb; 

    // ---------------
    // REG DECLARATION
    // ---------------

    reg  [width_result -1 : 0] result;
    reg  [width_result -1 :0] temp_sum;
    reg  [width_result -1 : 0] mult_res_ext;
    reg  [4 * width_a -1 : 0] dataa_int;
    reg  [4 * width_a -1 : 0] mult_a;
    reg  [4 * width_b -1 : 0] datab_int;
    reg  [4 * width_b -1 : 0] mult_b;
    reg  [4 * (width_a + width_b) -1:0] mult_res;
    reg  [(width_a + width_b) -1:0] mult_res_temp;

   
    reg input_reg_a0_clk;
    reg input_reg_a0_clr;
    reg input_reg_a0_en;

    reg input_reg_a1_clk;
    reg input_reg_a1_clr;
    reg input_reg_a1_en;

    reg input_reg_a2_clk;
    reg input_reg_a2_clr;
    reg input_reg_a2_en;

    reg input_reg_a3_clk;
    reg input_reg_a3_clr;
    reg input_reg_a3_en;

    reg input_reg_b0_clk;
    reg input_reg_b0_clr;
    reg input_reg_b0_en;

    reg input_reg_b1_clk;
    reg input_reg_b1_clr;
    reg input_reg_b1_en;

    reg input_reg_b2_clk;
    reg input_reg_b2_clr;
    reg input_reg_b2_en;

    reg input_reg_b3_clk;
    reg input_reg_b3_clr;
    reg input_reg_b3_en;

    reg sign_reg_a_clk;
    reg sign_reg_a_clr;
    reg sign_reg_a_en;

    reg sign_pipe_a_clk;
    reg sign_pipe_a_clr;
    reg sign_pipe_a_en;

    reg sign_reg_b_clk;
    reg sign_reg_b_clr;
    reg sign_reg_b_en;

    reg sign_pipe_b_clk;
    reg sign_pipe_b_clr;
    reg sign_pipe_b_en;

    reg addsub1_reg_clk;
    reg addsub1_reg_clr;
    reg addsub1_reg_en;

    reg addsub1_pipe_clk;
    reg addsub1_pipe_clr;
    reg addsub1_pipe_en;
 
    reg addsub3_reg_clk;
    reg addsub3_reg_clr;
    reg addsub3_reg_en;

    reg addsub3_pipe_clk;
    reg addsub3_pipe_clr;
    reg addsub3_pipe_en;

    reg multiplier_reg0_clk;
    reg multiplier_reg0_clr;
    reg multiplier_reg0_en;

    reg multiplier_reg1_clk;
    reg multiplier_reg1_clr;
    reg multiplier_reg1_en;

    reg multiplier_reg2_clk;
    reg multiplier_reg2_clr;
    reg multiplier_reg2_en;

    reg multiplier_reg3_clk;
    reg multiplier_reg3_clr;
    reg multiplier_reg3_en;

    reg output_reg_clk;
    reg output_reg_clr;
    reg output_reg_en;

    reg sign_a_pipe;
    reg sign_a_reg;
    reg sign_b_pipe;
    reg sign_b_reg;

    reg addsub1_reg;
    reg addsub1_pipe;
    reg addsub3_reg;
    reg addsub3_pipe;  

    //-----------------
    // TRI DECLARATION
    //-----------------
    tri0 signa_z;
    tri0 signb_z;  
    tri0 addnsub1_z;
    tri0 addnsub3_z;
    
    assign signa_z = signa;
    assign signb_z = signb;
    assign addnsub1_z = addnsub1;
    assign addnsub3_z = addnsub3;

    // ----------------
    // WIRE DECLARATION
    // ----------------
    wire [4 * width_a -1 : 0] mult_a_pre;
    wire [4 * width_b -1 : 0] mult_b_pre;
    wire [4 * (width_a + width_b) -1:0] mult_res_old;
    wire [width_a -1 : 0] scanouta;
    wire [width_b -1 : 0] scanoutb; 

    wire sign_a_int;
    wire sign_b_int;

    wire addsub1_int;
    wire addsub3_int;


    // -------------------
    // INTEGER DECLARATION
    // -------------------
    integer i;


    // --------------------------------------------
    // This function takes in a string (clock name)
    // and send back the corresponding clock signal
    // --------------------------------------------
    function resolve_clock;
        input [47:0] name ;    // 8-bits character storage for name "CLOCK?"
    begin:RESOLUTION
        reg clock;

        case (name)
            "CLOCK0"       : clock = (clock0 === 1'bz ? 1 : clock0);
            "CLOCK1"       : clock = (clock1 === 1'bz ? 1 : clock1);
            "CLOCK2"       : clock = (clock2 === 1'bz ? 1 : clock2);
            "CLOCK3"       : clock = (clock3 === 1'bz ? 1 : clock3);
            "UNREGISTERED" : clock = 1'bz;
            default        : clock = 1'bz;
        endcase 

        resolve_clock = clock;
    end
    endfunction    // resolve_clock


    // ---------------------------------------------------
    // This function takes in a string (clock name)
    // and send back the corresponding clock enable signal
    // ---------------------------------------------------
    function resolve_enable;
        input [47:0] name;    // 8-bits character storage for name "CLOCK?"
    begin:RESOLUTION
        reg enable;

        case (name)
            "CLOCK0" : enable = (ena0 === 1'bz ? 1 : ena0);
            "CLOCK1" : enable = (ena1 === 1'bz ? 1 : ena1);
            "CLOCK2" : enable = (ena2 === 1'bz ? 1 : ena2);
            "CLOCK3" : enable = (ena3 === 1'bz ? 1 : ena3);
            default  : $display("Warning: Unknown string passed to function resolve_enable");
        endcase
        resolve_enable = enable;
    end
    endfunction    // resolve_enable


    // --------------------------------------------
    // This function takes in a string (clear name)
    // and send back the corresponding clear signal
    // --------------------------------------------
    function resolve_clr;
        input [39:0] name ;    // 8-bits character storage for name "ACLR?"
    begin:RESOLUTION
        reg clr;

        case (name)
            "ACLR0" : clr = (aclr0 === 1'bz ? 0 : aclr0);
            "ACLR1" : clr = (aclr1 === 1'bz ? 0 : aclr1);
            "ACLR2" : clr = (aclr2 === 1'bz ? 0 : aclr2);
            "ACLR3" : clr = (aclr3 === 1'bz ? 0 : aclr3);
            default : $display("Warning: Unknown string passed to function resolve_clr");
        endcase
        resolve_clr = clr;
    end
    endfunction    // resolve_clr


    // -----------------------------------------------------------------------------    
    // This block checks if the two numbers to be multiplied (mult_a/mult_b) is to 
    // be interpreted as a negative number ot not. If so, then two's complement is 
    // performed.
    // The numbers are then multipled. The sign of the result (positive or negative) 
    // is determined based on the sign of the two input numbers
    // ------------------------------------------------------------------------------
    task do_multiply;
        input [32:0] multiplier;
    begin:MULTIPLY
        reg [width_a + width_b -1 :0] clear_res;
        reg [width_a + width_b -1 :0] temp_mult_zero;
        reg [width_a + width_b -1 :0] temp_mult;
        reg [width_a -1 :0]        op_a; 
        reg [width_b -1 :0]        op_b; 
        reg [width_a -1 :0]        op_a_int; 
        reg [width_b -1 :0]        op_b_int; 
        reg neg_a;
        reg neg_b;
        reg temp_mult_signed;

        temp_mult_zero = 0;
        clear_res = ~0;
      
        op_a = mult_a >> (multiplier * width_a); 
        op_b = mult_b >> (multiplier * width_b); 
     
        neg_a = op_a[width_a-1] & (sign_a_reg);
        neg_b = op_b[width_b-1] & (sign_b_reg);

        op_a_int = (neg_a == 1) ? (~op_a + 1) : op_a;
        op_b_int = (neg_b == 1) ? (~op_b + 1) : op_b;
      
        temp_mult = op_a_int * op_b_int;
        temp_mult = (neg_a ^ neg_b) ? (temp_mult_zero - temp_mult) : temp_mult;

        mult_res = mult_res & ~(clear_res << (multiplier * (width_a + width_b)));
        mult_res = mult_res | ((temp_mult) << (multiplier * (width_a + width_b)));
    end
    endtask


    // --------------------------------------------------------------
    // initialization block of all the internal signals and registers
    // --------------------------------------------------------------
    initial
    begin
        temp_sum = 0;
        result   = 0; 
        mult_a   = 0; 
        mult_b   = 0;
        mult_res = 0;

        // initializing all the clock signals
        input_reg_a0_clk = 0; 
        input_reg_a1_clk = 0; 
        input_reg_a2_clk = 0; 
        input_reg_a3_clk = 0;

        input_reg_b0_clk = 0; 
        input_reg_b1_clk = 0; 
        input_reg_b2_clk = 0; 
        input_reg_b3_clk = 0;

        addsub1_reg_clk  = 0; 
        addsub1_pipe_clk = 0;         
        addsub3_reg_clk  = 0; 
        addsub3_pipe_clk = 0;

        sign_reg_a_clk  = 0; 
        sign_reg_b_clk  = 0; 
        sign_pipe_a_clk = 0; 
        sign_pipe_b_clk = 0;

        multiplier_reg0_clk = 0; 
        multiplier_reg1_clk = 0; 
        multiplier_reg2_clk = 0; 
        multiplier_reg3_clk = 0;

        output_reg_clk = 0;

        // initializing all the clear signals
        input_reg_a0_clr = 0; 
        input_reg_a1_clr = 0; 
        input_reg_a2_clr = 0; 
        input_reg_a3_clr = 0;

        input_reg_b0_clr = 0; 
        input_reg_b1_clr = 0; 
        input_reg_b2_clr = 0; 
        input_reg_b3_clr = 0;

        addsub1_reg_clr  = 0; 
        addsub1_pipe_clr = 0;
        addsub3_reg_clr  = 0; 
        addsub3_pipe_clr = 0;

        sign_reg_a_clr  = 0; 
        sign_reg_b_clr  = 0; 
        sign_pipe_a_clr = 0; 
        sign_pipe_b_clr = 0;

        multiplier_reg0_clr = 0; 
        multiplier_reg1_clr = 0; 
        multiplier_reg2_clr = 0; 
        multiplier_reg3_clr = 0;

        output_reg_clr = 0;

        // initializing all the clock enable signals
        input_reg_a0_en = 1; 
        input_reg_a1_en = 1; 
        input_reg_a2_en = 1; 
        input_reg_a3_en = 1;
 
        input_reg_b0_en = 1; 
        input_reg_b1_en = 1; 
        input_reg_b2_en = 1; 
        input_reg_b3_en = 1;

        addsub1_reg_en  = 1; 
        addsub1_pipe_en = 1;
        addsub3_reg_en  = 1; 
        addsub3_pipe_en = 1;

        sign_reg_a_en  = 1; 
        sign_reg_b_en  = 1; 
        sign_pipe_a_en = 1; 
        sign_pipe_b_en = 1;

        multiplier_reg0_en = 1; 
        multiplier_reg1_en = 1; 
        multiplier_reg2_en = 1; 
        multiplier_reg3_en = 1;

        output_reg_en = 1;

        sign_a_reg  = (representation_a != "UNUSED" ? 
                       (representation_a == "SIGNED" ? 1 : 0) : 0); 
        sign_a_pipe = (representation_a != "UNUSED" ? 
                       (representation_a == "SIGNED" ? 1 : 0) : 0);  
        sign_b_reg  = (representation_b != "UNUSED" ? 
                       (representation_b == "SIGNED" ? 1 : 0) : 0); 
        sign_b_pipe = (representation_b != "UNUSED" ? 
                       (representation_b == "SIGNED" ? 1 : 0) : 0);  
            
        addsub1_reg  = (multiplier1_direction != "UNUSED" ? 
                        (multiplier1_direction == "ADD" ? 1 : 0) : 0);
        addsub1_pipe = addsub1_reg; 
        addsub3_reg  = (multiplier3_direction != "UNUSED" ? 
                        (multiplier3_direction == "ADD" ? 1 : 0) : 0);
        addsub3_pipe = addsub3_reg;
    
        for (i=0; i< (number_of_multipliers * width_a); i=i+1)
        begin
            dataa_int [i] = dataa[i];
        end

        for (i=(number_of_multipliers*width_a); i< (4 * width_a); i=i+1)
        begin
            dataa_int [i] = 0;
        end
    
        for (i=0; i< (number_of_multipliers * width_b); i=i+1)
        begin
            datab_int [i] = datab[i];
        end

        for (i=number_of_multipliers*width_b; i< (4 * width_b); i=i+1)
        begin
            datab_int [i] = 0;
        end
    end // end initialization block


    // ---------------------------------------------------------
    // This block updates the internal clock signals accordingly
    // every time the global clock signal changes state
    // ---------------------------------------------------------
    always @(clock0 or clock1 or clock2 or clock3)
    begin
        input_reg_a0_clk = resolve_clock (input_register_a0);
        input_reg_a1_clk = resolve_clock (input_register_a1);
        input_reg_a2_clk = resolve_clock (input_register_a2);
        input_reg_a3_clk = resolve_clock (input_register_a3);

        input_reg_b0_clk = resolve_clock (input_register_b0);
        input_reg_b1_clk = resolve_clock (input_register_b1);
        input_reg_b2_clk = resolve_clock (input_register_b2);
        input_reg_b3_clk = resolve_clock (input_register_b3);

        addsub1_reg_clk  = resolve_clock (addnsub_multiplier_register1);
        addsub1_pipe_clk = resolve_clock (addnsub_multiplier_pipeline_register1);
      
        addsub3_reg_clk  = resolve_clock (addnsub_multiplier_register3);
        addsub3_pipe_clk = resolve_clock (addnsub_multiplier_pipeline_register3);

        sign_reg_a_clk  = resolve_clock (signed_register_a);
        sign_reg_b_clk  = resolve_clock (signed_register_b);
        sign_pipe_a_clk = resolve_clock (signed_pipeline_register_a);
        sign_pipe_b_clk = resolve_clock (signed_pipeline_register_b);

        multiplier_reg0_clk = resolve_clock (multiplier_register0);
        multiplier_reg1_clk = resolve_clock (multiplier_register1);
        multiplier_reg2_clk = resolve_clock (multiplier_register2);
        multiplier_reg3_clk = resolve_clock (multiplier_register3);

        output_reg_clk = resolve_clock (output_register);
    end


    // ---------------------------------------------------------
    // This block updates the internal clear signals accordingly
    // every time the global clear signal changes state
    // ---------------------------------------------------------
    always @(aclr0 or aclr1 or aclr2 or aclr3)
    begin
        input_reg_a0_clr = resolve_clr (input_aclr_a0);
        input_reg_a1_clr = resolve_clr (input_aclr_a1);
        input_reg_a2_clr = resolve_clr (input_aclr_a2);
        input_reg_a3_clr = resolve_clr (input_aclr_a3);

        input_reg_b0_clr = resolve_clr (input_aclr_b0);
        input_reg_b1_clr = resolve_clr (input_aclr_b1);
        input_reg_b2_clr = resolve_clr (input_aclr_b2);
        input_reg_b3_clr = resolve_clr (input_aclr_b3);

        addsub1_reg_clr  = resolve_clr (addnsub_multiplier_aclr1);
        addsub1_pipe_clr = resolve_clr (addnsub_multiplier_pipeline_aclr1);
      
        addsub3_reg_clr  = resolve_clr (addnsub_multiplier_aclr3);
        addsub3_pipe_clr = resolve_clr (addnsub_multiplier_pipeline_aclr3);

        sign_reg_a_clr  = resolve_clr (signed_aclr_a);
        sign_reg_b_clr  = resolve_clr (signed_aclr_b);
        sign_pipe_a_clr = resolve_clr (signed_pipeline_aclr_a);
        sign_pipe_b_clr = resolve_clr (signed_pipeline_aclr_b);

        multiplier_reg0_clr = resolve_clr (multiplier_aclr0);
        multiplier_reg1_clr = resolve_clr (multiplier_aclr1);
        multiplier_reg2_clr = resolve_clr (multiplier_aclr2);
        multiplier_reg3_clr = resolve_clr (multiplier_aclr3);

        output_reg_clr = resolve_clr (output_aclr);
    end


    // ----------------------------------------------------------------
    // This block updates the internal clock enable signals accordingly
    // every time the global clock enable signal changes state
    // ----------------------------------------------------------------
    always @(ena0 or ena1 or ena2 or ena3)
    begin
        input_reg_a0_en = resolve_enable (input_register_a0);
        input_reg_a1_en = resolve_enable (input_register_a1);
        input_reg_a2_en = resolve_enable (input_register_a2);
        input_reg_a3_en = resolve_enable (input_register_a3);

        input_reg_b0_en = resolve_enable (input_register_b0);
        input_reg_b1_en = resolve_enable (input_register_b1);
        input_reg_b2_en = resolve_enable (input_register_b2);
        input_reg_b3_en = resolve_enable (input_register_b3);

        addsub1_reg_en  = resolve_enable (addnsub_multiplier_register1);
        addsub1_pipe_en = resolve_enable (addnsub_multiplier_pipeline_register1);
      
        addsub3_reg_en  = resolve_enable (addnsub_multiplier_register3);
        addsub3_pipe_en = resolve_enable (addnsub_multiplier_pipeline_register3);

        sign_reg_a_en  = resolve_enable (signed_register_a);
        sign_reg_b_en  = resolve_enable (signed_register_b);
        sign_pipe_a_en = resolve_enable (signed_pipeline_register_a);
        sign_pipe_b_en = resolve_enable (signed_pipeline_register_b);

        multiplier_reg0_en = resolve_enable (multiplier_register0);
        multiplier_reg1_en = resolve_enable (multiplier_register1);
        multiplier_reg2_en = resolve_enable (multiplier_register2);
        multiplier_reg3_en = resolve_enable (multiplier_register3);

        output_reg_en = resolve_enable (output_register);
    end


    // ---------------------------------------------------------------
    // Update dataa_int with the latest value every time dataa changes
    // ---------------------------------------------------------------
    always @(dataa)
    begin
        for (i=0; i< number_of_multipliers * width_a; i=i+1)
        begin
            dataa_int [i] = dataa[i];
        end
    end


    // ---------------------------------------------------------------
    // Update datab_int with the latest value every time datab changes
    // ---------------------------------------------------------------
    always @(datab)
    begin
        for (i=0; i< number_of_multipliers * width_b; i=i+1)
        begin
            datab_int [i] = datab[i];
        end
    end

    // -------------------------------------------------------------------------------------
    // This block contains 1 register and 1 combinatorial block (to set mult_a[width_a-1:0])
    // Signal Registered : mult_a_pre[width_a-1:0]
    //
    // Register is controlled by posedge input_reg_a0_clk
    // Register has a clock enable input_reg_a0_en
    // Register has an asynchronous clear signal, input_reg_a0_clr
    // NOTE : The combinatorial block will be executed if
    //        input_register_a0 is unregistered and mult_a_pre[width_a-1:0] changes value
    // -------------------------------------------------------------------------------------
    always @(posedge input_reg_a0_clk or posedge input_reg_a0_clr or 
             ({width_a{(input_register_a0 == "UNREGISTERED")}} & mult_a_pre[width_a-1:0]))
    begin
        if (input_register_a0 == "UNREGISTERED")
            mult_a[width_a-1:0] <= mult_a_pre[width_a-1:0];
        else
        begin
            if (input_reg_a0_clr == 1)
                mult_a[width_a-1:0] <= 0;
            else if ((input_reg_a0_clk === 1'b1) && (input_reg_a0_en == 1))
                mult_a[width_a-1:0] <= mult_a_pre[width_a-1:0];
        end
    end


    // -----------------------------------------------------------------------------------------------
    // This block contains 1 register and 1 combinatorial block (to set mult_a[(2*width_a)-1:width_a])
    // Signal Registered : mult_a_pre[(2*width_a)-1:width_a]
    //
    // Register is controlled by posedge input_reg_a1_clk
    // Register has a clock enable input_reg_a1_en
    // Register has an asynchronous clear signal, input_reg_a1_clr
    // NOTE : The combinatorial block will be executed if
    //        input_register_a1 is unregistered and mult_a_pre[(2*width_a)-1:width_a] changes value
    // -----------------------------------------------------------------------------------------------
    always @(posedge input_reg_a1_clk or posedge input_reg_a1_clr or 
             ({width_a{(input_register_a1 == "UNREGISTERED")}} & mult_a_pre[(2*width_a)-1:width_a]))
    begin
        if (input_register_a1 == "UNREGISTERED")
            mult_a[(2*width_a)-1:width_a] <= mult_a_pre[(2*width_a)-1:width_a];
        else
        begin
            if (input_reg_a1_clr == 1)
                mult_a[(2*width_a)-1:width_a] <= 0;
            else if ((input_reg_a1_clk == 1) && (input_reg_a1_en == 1))
                mult_a[(2*width_a)-1:width_a] <= mult_a_pre[(2*width_a)-1:width_a];
        end
    end


    // -------------------------------------------------------------------------------------------------
    // This block contains 1 register and 1 combinatorial block (to set mult_a[(3*width_a)-1:2*width_a])
    // Signal Registered : mult_a_pre[(3*width_a)-1:2*width_a]
    //
    // Register is controlled by posedge input_reg_a2_clk
    // Register has a clock enable input_reg_a2_en
    // Register has an asynchronous clear signal, input_reg_a2_clr
    // NOTE : The combinatorial block will be executed if
    //        input_register_a2 is unregistered and mult_a_pre[(3*width_a)-1:2*width_a] changes value
    // -------------------------------------------------------------------------------------------------
    always @(posedge input_reg_a2_clk or posedge input_reg_a2_clr or 
             ({width_a{(input_register_a2 == "UNREGISTERED")}} & mult_a_pre[(3*width_a)-1:2*width_a]))
    begin
        if (input_register_a2 == "UNREGISTERED")
            mult_a[(3*width_a)-1 : 2*width_a ] <= mult_a_pre[(3*width_a)-1 : 2*width_a];
        else
        begin
            if (input_reg_a2_clr == 1)
                mult_a[(3*width_a)-1 : 2*width_a ] <= 0;
            else if ((input_reg_a2_clk == 1) && (input_reg_a2_en == 1))
                mult_a[(3*width_a)-1 : 2*width_a ] <= mult_a_pre[(3*width_a)-1 : 2*width_a];
        end
    end


    // -------------------------------------------------------------------------------------------------
    // This block contains 1 register and 1 combinatorial block (to set mult_a[(4*width_a)-1:3*width_a])
    // Signal Registered : mult_a_pre[(4*width_a)-1:3*width_a]
    //
    // Register is controlled by posedge input_reg_a3_clk
    // Register has a clock enable input_reg_a3_en
    // Register has an asynchronous clear signal, input_reg_a3_clr
    // NOTE : The combinatorial block will be executed if
    //        input_register_a3 is unregistered and mult_a_pre[(4*width_a)-1:3*width_a] changes value
    // -------------------------------------------------------------------------------------------------
    always @(posedge input_reg_a3_clk or posedge input_reg_a3_clr or 
             ({width_a{(input_register_a3 == "UNREGISTERED")}} & mult_a_pre[(4*width_a)-1:3*width_a]))
    begin
        if (input_register_a3 == "UNREGISTERED")
            mult_a[(4*width_a)-1 : 3*width_a ] <= mult_a_pre[(4*width_a)-1:3*width_a];
        else
        begin
            if (input_reg_a3_clr == 1)
                mult_a[(4*width_a)-1 : 3*width_a ] <= 0;
            else if ((input_reg_a3_clk == 1) && (input_reg_a3_en == 1))
                mult_a[(4*width_a)-1 : 3*width_a ] <= mult_a_pre[(4*width_a)-1:3*width_a];
        end
    end

 
    // -------------------------------------------------------------------------------------
    // This block contains 1 register and 1 combinatorial block (to set mult_b[width_b-1:0])
    // Signal Registered : mult_b_pre[width_b-1:0]
    //
    // Register is controlled by posedge input_reg_b0_clk
    // Register has a clock enable input_reg_b0_en
    // Register has an asynchronous clear signal, input_reg_b0_clr
    // NOTE : The combinatorial block will be executed if
    //        input_register_b0 is unregistered and mult_b_pre[width_b-1:0] changes value
    // -------------------------------------------------------------------------------------
    always @(posedge input_reg_b0_clk or posedge input_reg_b0_clr or 
             ({width_b{(input_register_b0 == "UNREGISTERED")}} & mult_b_pre[width_b-1:0]))
    begin
        if (input_register_b0 == "UNREGISTERED")
            mult_b[width_b-1:0] <= mult_b_pre[width_b-1:0];
        else
        begin
            if (input_reg_b0_clr == 1)
                mult_b[width_b-1:0] <= 0;
            else if ((input_reg_b0_clk == 1) && (input_reg_b0_en == 1))
                mult_b[width_b-1:0] <= mult_b_pre[width_b-1:0];
        end
    end


    // -----------------------------------------------------------------------------------------------
    // This block contains 1 register and 1 combinatorial block (to set mult_b[(2*width_b)-1:width_b])
    // Signal Registered : mult_b_pre[(2*width_b)-1:width_b]
    //
    // Register is controlled by posedge input_reg_a1_clk
    // Register has a clock enable input_reg_b1_en
    // Register has an asynchronous clear signal, input_reg_b1_clr
    // NOTE : The combinatorial block will be executed if
    //        input_register_b1 is unregistered and mult_b_pre[(2*width_b)-1:width_b] changes value
    // -----------------------------------------------------------------------------------------------
    always @(posedge input_reg_b1_clk or posedge input_reg_b1_clr or 
             ({width_b{(input_register_b1 == "UNREGISTERED")}} & mult_b_pre[(2*width_b)-1 : width_b ]))
    begin
        if (input_register_b1 == "UNREGISTERED")
            mult_b[(2*width_b)-1:width_b] <= mult_b_pre[(2*width_b)-1:width_b];
        else
        begin
            if (input_reg_b1_clr == 1)
                mult_b[(2*width_b)-1:width_b] <= 0;
            else if ((input_reg_b1_clk == 1) && (input_reg_b1_en == 1))
                mult_b[(2*width_b)-1:width_b] <= mult_b_pre[(2*width_b)-1:width_b];
        end
    end


    // -------------------------------------------------------------------------------------------------
    // This block contains 1 register and 1 combinatorial block (to set mult_b[(3*width_b)-1:2*width_b])
    // Signal Registered : mult_b_pre[(3*width_b)-1:2*width_b]
    //
    // Register is controlled by posedge input_reg_b2_clk
    // Register has a clock enable input_reg_b2_en
    // Register has an asynchronous clear signal, input_reg_b2_clr
    // NOTE : The combinatorial block will be executed if
    //        input_register_b2 is unregistered and mult_b_pre[(3*width_b)-1:2*width_b] changes value
    // -------------------------------------------------------------------------------------------------
    always @(posedge input_reg_b2_clk or posedge input_reg_b2_clr or 
             ({width_b{(input_register_b2 == "UNREGISTERED")}} & mult_b_pre[(3*width_b)-1:2*width_b]))
    begin
        if (input_register_b2 == "UNREGISTERED")
            mult_b[(3*width_b)-1:2*width_b] <= mult_b_pre[(3*width_b)-1:2*width_b];
        else
        begin
            if (input_reg_b2_clr == 1)
                mult_b[(3*width_b)-1:2*width_b] <= 0;
            else if ((input_reg_b2_clk == 1) && (input_reg_b2_en == 1))
                mult_b[(3*width_b)-1:2*width_b] <= mult_b_pre[(3*width_b)-1:2*width_b];
        end
    end


    // -------------------------------------------------------------------------------------------------
    // This block contains 1 register and 1 combinatorial block (to set mult_b[(4*width_b)-1:3*width_b])
    // Signal Registered : mult_b_pre[(4*width_b)-1:3*width_b]
    //
    // Register is controlled by posedge input_reg_b3_clk
    // Register has a clock enable input_reg_b3_en
    // Register has an asynchronous clear signal, input_reg_b3_clr
    // NOTE : The combinatorial block will be executed if
    //        input_register_b3 is unregistered and mult_b_pre[(4*width_b)-1:3*width_b] changes value
    // -------------------------------------------------------------------------------------------------
    always @(posedge input_reg_b3_clk or posedge input_reg_b3_clr or 
             ({width_b{(input_register_b3 == "UNREGISTERED")}} & mult_b_pre[(4*width_b)-1:3*width_b]))
    begin
        if (input_register_b3 == "UNREGISTERED")
            mult_b[(4*width_b)-1:3*width_b] <= mult_b_pre[(4*width_b)-1:3*width_b];
        else
        begin
            if (input_reg_b3_clr == 1)
                mult_b[(4*width_b)-1 : 3*width_b ] <= 0;
            else if ((input_reg_b3_clk == 1) && (input_reg_b3_en == 1))
                mult_b[(4*width_b)-1:3*width_b] <= mult_b_pre[(4*width_b)-1:3*width_b];
        end
    end

   
    // ---------------------------------------------------------------------------------
    // This block contains 1 register and 1 combinatorial block (to set addsub1_reg)
    // Signal Registered : addsub1_int
    //
    // Register is controlled by posedge addsub1_reg_clk
    // Register has a clock enable addsub1_reg_en
    // Register has an asynchronous clear signal, addsub1_reg_clr
    // NOTE : The combinatorial block will be executed if
    //        addnsub_multiplier_register1 is unregistered and addsub1_int changes value
    // ---------------------------------------------------------------------------------
    always @(posedge addsub1_reg_clk or posedge addsub1_reg_clr or 
             (addnsub_multiplier_register1=="UNREGISTERED") & addsub1_int)
    begin
        if (addnsub_multiplier_register1 == "UNREGISTERED")
            addsub1_reg <= addsub1_int;
        else
        begin
            if ((addsub1_reg_clr == 1) && (multiplier1_direction == "UNUSED"))
                addsub1_reg <= 0;
            else if ((addsub1_reg_clk == 1) && (addsub1_reg_en == 1))
                addsub1_reg <= addsub1_int;
        end
    end


    // -------------------------------------------------------------------------------------------
    // This block contains 1 register and 1 combinatorial block (to set addsub1_pipe)
    // Signal Registered : addsub1_reg
    //
    // Register is controlled by posedge addsub1_pipe_clk
    // Register has a clock enable addsub1_pipe_en
    // Register has an asynchronous clear signal, addsub1_pipe_clr
    // NOTE : The combinatorial block will be executed if
    //        addnsub_multiplier_pipeline_register1 is unregistered and addsub1_reg changes value
    // ------------------------------------------------------------------------------------------
    always @(posedge addsub1_pipe_clk or posedge addsub1_pipe_clr or 
             (addnsub_multiplier_pipeline_register1=="UNREGISTERED") & addsub1_reg)
    begin
        if (addnsub_multiplier_pipeline_register1 == "UNREGISTERED")
            addsub1_pipe <= addsub1_reg;
        else
        begin
            if ((addsub1_pipe_clr == 1) && (multiplier1_direction == "UNUSED"))
                addsub1_pipe <= 0;
            else if ((addsub1_pipe_clk == 1) && (addsub1_pipe_en == 1))
                addsub1_pipe <= addsub1_reg;        
        end
    end


    // ---------------------------------------------------------------------------------
    // This block contains 1 register and 1 combinatorial block (to set addsub3_reg)
    // Signal Registered : addsub3_int
    //
    // Register is controlled by posedge addsub3_reg_clk
    // Register has a clock enable addsub3_reg_en
    // Register has an asynchronous clear signal, addsub3_reg_clr
    // NOTE : The combinatorial block will be executed if
    //        addnsub_multiplier_register3 is unregistered and addsub3_int changes value
    // ---------------------------------------------------------------------------------
    always @(posedge addsub3_reg_clk or posedge addsub3_reg_clr or 
             (addnsub_multiplier_register3=="UNREGISTERED") & addsub3_int)
    begin
        if (addnsub_multiplier_register3 == "UNREGISTERED")
            addsub3_reg <= addsub3_int;
        else
        begin
            if ((addsub3_reg_clr == 1) && (multiplier3_direction == "UNUSED"))
                addsub3_reg <= 0;
            else if ((addsub3_reg_clk == 1) && (addsub3_reg_en == 1))
                addsub3_reg <= addsub3_int;
        end
    end


    // -------------------------------------------------------------------------------------------
    // This block contains 1 register and 1 combinatorial block (to set addsub3_pipe)
    // Signal Registered : addsub3_reg
    //
    // Register is controlled by posedge addsub3_pipe_clk
    // Register has a clock enable addsub3_pipe_en
    // Register has an asynchronous clear signal, addsub3_pipe_clr
    // NOTE : The combinatorial block will be executed if
    //        addnsub_multiplier_pipeline_register3 is unregistered and addsub3_reg changes value
    // ------------------------------------------------------------------------------------------
    always @(posedge addsub3_pipe_clk or posedge addsub3_pipe_clr or 
             (addnsub_multiplier_pipeline_register3=="UNREGISTERED") & addsub3_reg)
    begin
        if (addnsub_multiplier_pipeline_register3 == "UNREGISTERED")
            addsub3_pipe <= addsub3_reg;
        else
        begin
            if ((addsub3_pipe_clr == 1) && (multiplier3_direction == "UNUSED"))
                addsub3_pipe <= 0;
            else if ((addsub3_pipe_clk == 1) && (addsub3_pipe_en == 1))
                addsub3_pipe <= addsub3_reg;        
        end
    end


    // ----------------------------------------------------------------------------
    // This block contains 1 register and 1 combinatorial block (to set sign_a_reg)
    // Signal Registered : sign_a_int
    //
    // Register is controlled by posedge sign_reg_a_clk
    // Register has a clock enable sign_reg_a_en
    // Register has an asynchronous clear signal, sign_reg_a_clr
    // NOTE : The combinatorial block will be executed if
    //        signed_register_a is unregistered and sign_a_int changes value
    // ----------------------------------------------------------------------------
    always @(posedge sign_reg_a_clk or posedge sign_reg_a_clr or 
             (signed_register_a=="UNREGISTERED") & sign_a_int)
    begin
        if (signed_register_a == "UNREGISTERED")
            sign_a_reg <= sign_a_int;
        else
        begin
            if ((sign_reg_a_clr == 1) && (representation_a == "UNUSED"))
                sign_a_reg <= 0;
            else if ((sign_reg_a_clk == 1) && (sign_reg_a_en == 1))
                sign_a_reg <= sign_a_int;
        end
    end


    // ------------------------------------------------------------------------------
    // This block contains 1 register and 1 combinatorial block (to set sign_a_pipe)
    // Signal Registered : sign_a_reg
    //
    // Register is controlled by posedge sign_pipe_a_clk
    // Register has a clock enable sign_pipe_a_en
    // Register has an asynchronous clear signal, sign_pipe_a_clr
    // NOTE : The combinatorial block will be executed if
    //        signed_pipeline_register_a is unregistered and sign_a_reg changes value
    // ------------------------------------------------------------------------------
    always @(posedge sign_pipe_a_clk or posedge sign_pipe_a_clr or 
             (signed_pipeline_register_a=="UNREGISTERED") & sign_a_reg)
    begin
        if (signed_pipeline_register_a == "UNREGISTERED")
            sign_a_pipe <= sign_a_reg;
        else
        begin
            if ((sign_pipe_a_clr == 1) && (representation_a == "UNUSED"))
                sign_a_pipe <= 0;
            else if ((sign_pipe_a_clk == 1) && (sign_pipe_a_en == 1))
                sign_a_pipe <= sign_a_reg;        
        end
    end


    // ----------------------------------------------------------------------------
    // This block contains 1 register and 1 combinatorial block (to set sign_b_reg)
    // Signal Registered : sign_b_int
    //
    // Register is controlled by posedge sign_reg_b_clk
    // Register has a clock enable sign_reg_b_en
    // Register has an asynchronous clear signal, sign_reg_b_clr
    // NOTE : The combinatorial block will be executed if
    //        signed_register_b is unregistered and sign_b_int changes value
    // ----------------------------------------------------------------------------
    always @(posedge sign_reg_b_clk or posedge sign_reg_b_clr or 
             (signed_register_b=="UNREGISTERED")  & sign_b_int)
    begin
        if (signed_register_b == "UNREGISTERED")
            sign_b_reg <= sign_b_int;
        else
        begin
            if ((sign_reg_b_clr == 1) && (representation_b == "UNUSED"))
                sign_b_reg <= 0;
            else if ((sign_reg_b_clk == 1) && (sign_reg_b_en == 1))
                sign_b_reg <= sign_b_int;
        end
    end


    // ------------------------------------------------------------------------------
    // This block contains 1 register and 1 combinatorial block (to set sign_b_pipe)
    // Signal Registered : sign_b_reg
    //
    // Register is controlled by posedge sign_pipe_b_clk
    // Register has a clock enable sign_pipe_b_en
    // Register has an asynchronous clear signal, sign_pipe_b_clr
    // NOTE : The combinatorial block will be executed if
    //        signed_pipeline_register_b is unregistered and sign_b_reg changes value
    // ------------------------------------------------------------------------------
    always @(posedge sign_pipe_b_clk or posedge sign_pipe_b_clr or 
             (signed_pipeline_register_b=="UNREGISTERED") & sign_b_reg)

    begin
        if (signed_pipeline_register_b == "UNREGISTERED")
            sign_b_pipe <= sign_b_reg;
        else
        begin
            if ((sign_pipe_b_clr == 1) && (representation_b == "UNUSED"))
                sign_b_pipe <= 0;
            else if ((sign_pipe_b_clk == 1) && (sign_pipe_b_en == 1))
                sign_b_pipe <= sign_b_reg;        
        end
    end


    // --------------------------------------------------------
    // This block basically calls the task do_multiply() to set 
    // the value of mult_res[(width_a + width_b) -1 :0]
    //
    // If multiplier_register0 is registered, the call of the task 
    // will be triggered by a posedge multiplier_reg0_clk. 
    // It also has an asynchronous clear signal multiplier_reg0_clr
    //
    // If multiplier_register0 is unregistered, a change of value 
    // in either mult_a[width_a-1:0], mult_b[width_a-1:0], 
    // sign_a_reg or sign_b_reg will trigger the task call.
    // --------------------------------------------------------
    always @(posedge multiplier_reg0_clk or posedge multiplier_reg0_clr or 
             ({width_a{(multiplier_register0=="UNREGISTERED")}} & mult_a[width_a-1:0]) or 
             ({width_b{(multiplier_register0=="UNREGISTERED")}} & mult_b[width_b-1:0]) or 
             ((multiplier_register0=="UNREGISTERED") & sign_a_reg) or
             ((multiplier_register0=="UNREGISTERED") & sign_b_reg))
    begin
        if ((multiplier_reg0_clr == 1) && (multiplier_register0 != "UNREGISTERED"))
            mult_res[(width_a + width_b) -1 :0] <= 0;
        else if ((multiplier_reg0_clk == 1 && multiplier_reg0_en == 1) || 
                 (multiplier_register0 == "UNREGISTERED") )
            do_multiply (0);
    end


    // ------------------------------------------------------------------------
    // This block basically calls the task do_multiply() to set the value of 
    // mult_res[(width_a + width_b) *2 -1 : (width_a + width_b)]
    //
    // If multiplier_register1 is registered, the call of the task 
    // will be triggered by a posedge multiplier_reg1_clk. 
    // It also has an asynchronous clear signal multiplier_reg1_clr
    //
    // If multiplier_register1 is unregistered, a change of value 
    // in either mult_a[(2*width_a)-1:width_a], mult_b[(2*width_a)-1:width_a], 
    // sign_a_reg or sign_b_reg will trigger the task call.
    // -----------------------------------------------------------------------
    always @(posedge multiplier_reg1_clk or posedge multiplier_reg1_clr or 
             ({width_a{(multiplier_register1=="UNREGISTERED")}} & mult_a[(2*width_a)-1:width_a]) or
             ({width_b{(multiplier_register1=="UNREGISTERED")}} & mult_b[(2*width_b)-1:width_b]) or
             ((multiplier_register1=="UNREGISTERED") & sign_a_reg) or
             ((multiplier_register1=="UNREGISTERED") & sign_b_reg))
    begin
        if ((multiplier_reg1_clr == 1) && (multiplier_register1 != "UNREGISTERED"))
            mult_res[(width_a + width_b) *2 -1 : (width_a + width_b)] <= 0;
        else if ((multiplier_reg1_clk == 1 && multiplier_reg1_en == 1) || 
                 (multiplier_register1 == "UNREGISTERED") )
            do_multiply (1);
    end


    // ----------------------------------------------------------------------------
    // This block basically calls the task do_multiply() to set the value of 
    // mult_res[(width_a + width_b) *3 -1 : (width_a + width_b)*2]
    // 
    // If multiplier_register2 is registered, the call of the task 
    // will be triggered by a posedge multiplier_reg2_clk. 
    // It also has an asynchronous clear signal multiplier_reg2_clr
    //
    // If multiplier_register2 is unregistered, a change of value 
    // in either mult_a[(3*width_a)-1:2*width_a], mult_b[(3*width_a)-1:2*width_a], 
    // sign_a_reg or sign_b_reg will trigger the task call.
    // ---------------------------------------------------------------------------
    always @(posedge multiplier_reg2_clk or posedge multiplier_reg2_clr or 
             ({width_a{(multiplier_register2=="UNREGISTERED")}} & mult_a[(3*width_a)-1:2*width_a]) or
             ({width_b{(multiplier_register2=="UNREGISTERED")}} & mult_b[(3*width_b)-1:2*width_b]) or 
             ((multiplier_register2=="UNREGISTERED") & sign_a_reg) or
             ((multiplier_register2=="UNREGISTERED") & sign_b_reg))
    begin
        if ((multiplier_reg2_clr == 1) && (multiplier_register2 != "UNREGISTERED"))
            mult_res[(width_a + width_b) *3 -1 : (width_a + width_b)*2]<= 0;
        else if ((multiplier_reg2_clk == 1 && multiplier_reg2_en == 1) || 
                 (multiplier_register2 == "UNREGISTERED") )
            do_multiply (2);
    end


    // ----------------------------------------------------------------------------
    // This block basically calls the task do_multiply() to set the value of 
    // mult_res[(width_a + width_b) *4 -1 : (width_a + width_b)*3]
    //
    // If multiplier_register3 is registered, the call of the task 
    // will be triggered by a posedge multiplier_reg3_clk. 
    // It also has an asynchronous clear signal multiplier_reg3_clr
    //
    // If multiplier_register3 is unregistered, a change of value 
    // in either mult_a[(4*width_a)-1:3*width_a], mult_b[(4*width_a)-1:3*width_a], 
    // sign_a_reg or sign_b_reg will trigger the task call.
    // ---------------------------------------------------------------------------
    always @(posedge multiplier_reg3_clk or posedge multiplier_reg3_clr or 
             ({width_a{(multiplier_register3=="UNREGISTERED")}} & mult_a[(4*width_a)-1:3*width_a]) or
             ({width_b{(multiplier_register3=="UNREGISTERED")}} & mult_b[(4*width_b)-1:3*width_b]) or 
             ((multiplier_register3=="UNREGISTERED") & sign_a_reg) or
             ((multiplier_register3=="UNREGISTERED") & sign_b_reg))
    begin
        if ((multiplier_reg3_clr == 1) && (multiplier_register3 != "UNREGISTERED"))
            mult_res[(width_a + width_b) *4 -1 : (width_a + width_b)*3]<= 0;
        else if ((multiplier_reg3_clk == 1 && multiplier_reg3_en == 1) || 
                 (multiplier_register3 == "UNREGISTERED") )
            do_multiply (3);
    end

    //------------------------------
    // Continuous assign statements
    //------------------------------

    // Clock in all the A input registers
    assign mult_a_pre[width_a-1:0] = dataa_int[width_a-1:0];

    assign mult_a_pre[(2*width_a)-1:width_a] = (input_source_a1 == "DATAA") ? 
                                                dataa_int[(2*width_a)-1:width_a] : mult_a[width_a-1:0];         

    assign mult_a_pre[(3*width_a)-1:2*width_a] = (input_source_a2 == "DATAA") ? 
                                                 dataa_int[(3*width_a)-1:2*width_a] : mult_a[(2*width_a)-1:width_a];

    assign mult_a_pre[(4*width_a)-1:3*width_a] = (input_source_a3 == "DATAA") ? 
                                                  dataa_int[(4*width_a)-1:3*width_a] : mult_a[(3*width_a)-1:2*width_a];

    assign scanouta = mult_a[(number_of_multipliers * width_a)-1 : ((number_of_multipliers-1) * width_a)];
    assign scanoutb = mult_b[(number_of_multipliers * width_b)-1 : ((number_of_multipliers-1) * width_b)];

    // Clock in all the B input registers
    assign mult_b_pre[width_b-1:0] = datab_int[width_b-1:0];

    assign mult_b_pre[(2*width_b)-1:width_b] = (input_source_b1 == "DATAB") ? 
                                               datab_int[(2*width_b)-1 : width_b ]: mult_b[width_b -1 : 0];

    assign mult_b_pre[(3*width_b)-1:2*width_b] = (input_source_b2 == "DATAB") ? 
                                                  datab_int[(3*width_b)-1:2*width_b] : mult_b[(2*width_b)-1:width_b];

    assign mult_b_pre[(4*width_b)-1:3*width_b] = (input_source_b3 == "DATAB") ? 
                                                  datab_int[(4*width_b)-1:3*width_b] : mult_b[(3*width_b)-1:2*width_b];

    // clock in all the control signals
    assign addsub1_int = ( multiplier1_direction != "UNUSED" ? 
                          (multiplier1_direction == "ADD" ? 1 : 0) : addnsub1_z);

    assign addsub3_int = (multiplier3_direction != "UNUSED" ? 
                          (multiplier3_direction == "ADD" ? 1 : 0) : addnsub3_z);

    assign sign_a_int = (representation_a != "UNUSED" ? 
                         (representation_a == "SIGNED" ? 1 : 0) : signa_z);

    assign sign_b_int = (representation_b != "UNUSED" ? 
                         (representation_b == "SIGNED" ? 1 : 0) : signb_z);

    // This will enable consistent results with mult_res_temp
    assign #1.0 mult_res_old = mult_res;


    // -----------------------------------------------------------------
    // This is the main block that performs the addition and subtraction
    // -----------------------------------------------------------------
    always @(posedge output_reg_clk or posedge output_reg_clr or 
             (mult_res [4 * (width_a + width_b) -1:0] & 
              {4*  (width_a + width_b)-1 {(output_register == "UNREGISTERED")}}) or
             ((output_register == "UNREGISTERED") & addsub1_pipe) or
             ((output_register == "UNREGISTERED") & addsub3_pipe) or
             ((output_register == "UNREGISTERED") & sign_a_pipe) or
             ((output_register == "UNREGISTERED") & sign_b_pipe))
    begin
        if ((output_reg_clr == 1) && (output_register != "UNREGISTERED"))
            temp_sum = 0;
        else if (((output_reg_clk ==1) && (output_reg_en ==1)) || (output_register == "UNREGISTERED"))
        begin
            temp_sum =0;
            for (i = 0; i < number_of_multipliers; i = i +1)
            begin
                if (output_register == "UNREGISTERED")
                    mult_res_temp = mult_res >> (i * (width_a + width_b));
                else
                    mult_res_temp = mult_res_old >> (i * (width_a + width_b));

                mult_res_ext = {{(width_result - width_a - width_b)
                                { mult_res_temp [width_a + width_b -1] & (sign_a_pipe | sign_b_pipe)}}, mult_res_temp};

                if (i == 1)
                begin
                    if (addsub1_pipe)
                        temp_sum = temp_sum + mult_res_ext;
                    else
                        temp_sum = temp_sum - mult_res_ext;
                end
                else if (i >= 3)
                begin
                    if (addsub3_pipe)
                        temp_sum = temp_sum + mult_res_ext;
                    else 
                        temp_sum = temp_sum - mult_res_ext;
                end
                else
                begin
                    temp_sum = temp_sum + mult_res_ext;
                end
            end        
        end
        result = temp_sum[width_result-1 :0];
    end
endmodule  // end of ALTMULTMULT_ADD


//--------------------------------------------------------------------------
// Module Name      : altshift_taps
//
// Description      : Parameterized shift register with taps megafunction.
//                    Implements a RAM-based shift register for efficient
//                    creation of very large shift registers
//
// Limitation       : This megafunction is provided only for backward
//                    compatibility in Cyclone, Stratix, and Stratix GX
//                    designs.
//
// Results expected : Produce output from the end of the shift register
//                    and from the regularly spaced taps along the
//                    shift register.
//
//--------------------------------------------------------------------------
`timescale 1 ps / 1 ps

// MODULE DECLARATION
module altshift_taps (shiftin, clock, clken, shiftout, taps);

// PARAMETER DECLARATION
    parameter number_of_taps = 4;   // Specifies the number of regularly spaced
                                    //  taps along the shift register
    parameter tap_distance = 3;     // Specifies the distance between the
                                    //  regularly spaced taps in clock cycles
                                    //  This number translates to the number of
                                    //  memory words that will be needed
    parameter width = 8;            // Specifies the width of the input pattern
    parameter lpm_type = "altshift_taps";

    // Following parameters are used as constant
    parameter RAM_WIDTH = width * number_of_taps;
    parameter TOTAL_TAP_DISTANCE = number_of_taps * tap_distance;

// INPUT PORT DECLARATION
    input [width-1:0] shiftin;      // Data input to the shifter
    input clock;                    // Positive-edge triggered clock
    input clken;                    // Clock enable for the clock port

// OUTPUT PORT DECLARATION
    output [width-1:0] shiftout;    // Output from the end of the shift
                                    //  register
    output [RAM_WIDTH-1:0] taps;    // Output from the regularly spaced taps
                                    //  along the shift register

// INTERNAL REGISTERS DECLARATION
    reg [width-1:0] shiftout;
    reg [RAM_WIDTH-1:0] taps;
    reg [width-1:0] contents [0:TOTAL_TAP_DISTANCE-1];

// LOCAL INTEGER DECLARATION
    integer head;     // pointer to memory
    integer i;        // for loop index
    integer j;        // for loop index
    integer k;        // for loop index
    integer place;

// INITIAL CONSTRUCT BLOCK
    initial
    begin
        head = 0;
        shiftout = 0;
        for (i = 0; i < TOTAL_TAP_DISTANCE; i = i + 1)
        begin
            contents [i] = 0;
        end

        for (j = 0; j < RAM_WIDTH; j = j + 1)
        begin
            taps [j] = 0;
        end
    end

// ALWAYS CONSTRUCT BLOCK
    always @(posedge clock)
    begin
        if (clken !== 0)
        begin
            contents[head] = shiftin;
            head = (head + 1) % TOTAL_TAP_DISTANCE;
            shiftout = contents[head];

            taps = 0;

            for (k=0; k < number_of_taps; k=k+1)
            begin
                place = (((number_of_taps - k - 1) * tap_distance) + head ) %
                        TOTAL_TAP_DISTANCE;
                taps = taps | (contents[place] << (k * width));
            end
        end
    end


endmodule // altshift_taps




// START_MODULE_NAME------------------------------------------------------------
//
// Module Name     : ALTSYNCRAM
// 
// Description     : Synchronous ram model for Stratix series family
//
// Limitation      :
// 
// END_MODULE_NAME--------------------------------------------------------------

`timescale 1 ps / 1 ps

// BEGINNING OF MODULE

// MODULE DECLARATION

module altsyncram (
                  wren_a, 
                  wren_b, 
                  rden_b, 
                  data_a, 
                  data_b, 
                  address_a, 
                  address_b, 
                  clock0, 
                  clock1, 
                  clocken0, 
                  clocken1, 
                  aclr0, 
                  aclr1, 
                  byteena_a, 
                  byteena_b, 
                  q_a, 
                  q_b
                  );
                     
// GLOBAL PARAMETER DECLARATION

     // PORT A PARAMETERS
     parameter width_a          = 1;
     parameter widthad_a        = 1;
     parameter numwords_a       = 1;
     parameter outdata_reg_a    = "UNREGISTERED";
     parameter address_aclr_a   = "NONE";
     parameter outdata_aclr_a   = "NONE";
     parameter indata_aclr_a    = "NONE";
     parameter wrcontrol_aclr_a = "NONE";
     parameter byteena_aclr_a   = "NONE";
     parameter width_byteena_a  = 1;

     // PORT B PARAMETERS
     parameter width_b                   = 1;
     parameter widthad_b                 = 1;
     parameter numwords_b                = 1;
     parameter rdcontrol_reg_b           = "CLOCK1";
     parameter address_reg_b             = "CLOCK1";
     parameter outdata_reg_b             = "UNREGISTERED";
     parameter outdata_aclr_b            = "NONE";
     parameter rdcontrol_aclr_b          = "NONE";
     parameter indata_reg_b              = "CLOCK1";
     parameter wrcontrol_wraddress_reg_b = "CLOCK1";
     parameter byteena_reg_b             = "CLOCK1";
     parameter indata_aclr_b             = "NONE";
     parameter wrcontrol_aclr_b          = "NONE";
     parameter address_aclr_b            = "NONE";
     parameter byteena_aclr_b            = "NONE";
     parameter width_byteena_b           = 1;

     // GLOBAL PARAMETERS
     parameter operation_mode                     = "BIDIR_DUAL_PORT";
     parameter byte_size                          = 8;
     parameter read_during_write_mode_mixed_ports = "DONT_CARE";
     parameter ram_block_type                     = "AUTO";
     parameter init_file                          = "UNUSED";
     parameter init_file_layout                   = "UNUSED";
     parameter maximum_depth                      = 0;
     parameter intended_device_family             = "Stratix";

     parameter lpm_hint                           = "UNUSED";
     parameter lpm_type                           = "altsyncram";

// INPUT PORT DECLARATION

    input  wren_a; // Port A write/read enable input       
    input  wren_b; // Port B write enable input    
    input  rden_b; // Port B read enable input
    input  [width_a-1:0] data_a; // Port A data input
    input  [width_b-1:0] data_b; // Port B data input
    input  [widthad_a-1:0] address_a; // Port A address input
    input  [widthad_b-1:0] address_b; // Port B address input

    // clock inputs on both ports and here are their usage 
    // Port A -- 1. all input registers must be clocked by clock0. 
    //           2. output register can be clocked by either clock0, clock1 or none.
    // Port B -- 1. all input registered must be clocked by either clock0 or clock1.
    //           2. output register can be clocked by either clock0, clock1 or none.
    input  clock0;
    input  clock1; 

    // clock enable inputs and here are their usage
    // clocken0 -- can only be used for enabling clock0.
    // clocken1 -- can only be used for enabling clock1.
    input  clocken0;
    input  clocken1;
    
    // clear inputs on both ports and here are their usage
    // Port A -- 1. all input registers can only be cleared by clear0 or none. 
    //           2. output register can be cleared by either clear0, clear1 or none.
    // Port B -- 1. all input registers can be cleared by clear0, clear1 or none. 
    //           2. output register can be cleared by either clear0, clear1 or none.
    input  aclr0;
    input  aclr1;
    
    input [width_byteena_a-1:0] byteena_a; // Port A byte enable input
    input [width_byteena_b-1:0] byteena_b; // Port B byte enable input

// OUTPUT PORT DECLARATION

    output [width_a-1:0] q_a; // Port A output
    output [width_b-1:0] q_b; // Port B output
    
// INTERNAL REGISTERS DECLARATION

    reg [width_a-1:0] mem_data [0:(1<<widthad_a)-1];
    reg [width_b-1:0] mem_data_b [0:(1<<widthad_b)-1];
    reg [width_a-1:0] i_data_reg_a;
    reg [width_a-1:0] temp_wa;
    reg [width_a-1:0] temp_wa2;
    reg [width_b-1:0] i_data_reg_b;
    reg [width_b-1:0] temp_wb;
    reg [width_b-1:0] temp_wb2;
    reg temp;
    reg [width_a-1:0] i_q_reg_a;
    reg [width_a-1:0] i_q_tmp_a;
    reg [width_a-1:0] i_q_tmp2_a;
    reg [width_b-1:0] i_q_reg_b;
    reg [width_b-1:0] i_q_tmp_b;
    reg [width_b-1:0] i_q_tmp2_b;
    reg [width_a-1:0] i_byteena_mask_reg_a;
    reg [width_b-1:0] i_byteena_mask_reg_b;
    reg [widthad_a-1:0] i_address_reg_a;
    reg [widthad_b-1:0] i_address_reg_b;
    reg [8*256:1] ram_initf;
    reg i_wren_reg_a;
    reg i_wren_reg_b;
    reg i_rden_reg_b;
    reg i_rden_flag_b;
    reg i_write_flag_a;
    reg i_write_flag_b;
    reg good_to_go_a;
    reg good_to_go_b;
    reg [31:0] file_desc; 
    reg init_file_b_port;
    reg aclr0_tmp_a;
    reg aclr1_tmp_a;
    reg aclr0_tmp_b;
    reg aclr1_tmp_b;
  
  
// INTERNAL WIRE DECLARATIONS

    wire i_indata_aclr_a;
    wire i_address_aclr_a;
    wire i_wrcontrol_aclr_a;
    wire i_indata_aclr_b;
    wire i_address_aclr_b;
    wire i_wrcontrol_aclr_b;
    wire i_outdata_aclr_a;
    wire i_outdata_aclr_b;
    wire i_rdcontrol_aclr_b;
    wire i_byteena_aclr_a;
    wire i_byteena_aclr_b;
    wire i_clk_a;
    wire i_outdata_clk_a;
    wire i_clken_a;
    wire i_outdata_clken_a;
    wire i_indata_clk_b;
    wire i_outdata_clk_b;
    wire i_indata_clken_b;
    wire i_outdata_clken_b;
    wire i_wrcontrol_wraddress_clk_b;
    wire i_rdcontrol_clk_b;
    wire i_address_clk_b;
    wire i_byteena_clk_b;
    wire i_wrcontrol_wraddress_clken_b;
    wire i_rdcontrol_clken_b;
    wire i_address_clken_b;
    wire i_byteena_clken_b;
    wire byteena_a_unconnected;
    wire byteena_b_unconnected;

// INTERNAL TRI DECLARATION

    tri0 wren_a;
    tri0 wren_b;
    tri1 rden_b;
    tri0 clock0;
    tri0 clock1;
    tri1 clocken0;
    tri1 clocken1;
    tri0 aclr0;
    tri0 aclr1;

// INTERNAL BUF DECLARATION

    buf (i_wren_a, wren_a);
    buf (i_wren_b, wren_b);
    buf (i_rden_b, rden_b);
    buf (i_aclr0, aclr0);
    buf (i_aclr1, aclr1);

// LOCAL INTEGER DECLARATION

    integer write_by_a;
    integer write_by_b;
    integer write_by_a_reg_b;
    integer write_by_b_reg_a;
    integer i_numwords_a;
    integer i_numwords_b;
    integer i;
    integer j;
    integer k;
    integer aclr0_status_a;
    integer aclr1_status_a;
    integer aclr0_status_b;
    integer aclr1_status_b;

// INITIAL CONSTRUCT BLOCK

    initial
    begin


        // *****************************************
        // legal operations for all operation modes:
        //      |  PORT A  |  PORT B  |
        //      |  RD  WR  |  RD  WR  |
        // BDP  |  x   x   |  x   x   |
        // DP   |      x   |  x       |
        // SP   |  x   x   |          |
        // ROM  |  x       |          |
        // *****************************************

        i_numwords_a = (numwords_a) ? numwords_a : (1 << widthad_a);
        i_numwords_b = (numwords_b) ? numwords_b : (1 << widthad_b);

        // Initialize mem_data

        if ((init_file == "UNUSED") || (init_file == ""))         
        begin
            if (operation_mode == "ROM")
                $display("Error! altsyncram needs data file for memory initialization.\n");
            else 
            begin
                for (i = 0; i < (1 << widthad_a); i = i + 1)
                    if ((ram_block_type == "MEGARAM") || 
                        (ram_block_type == "M-RAM")   || 
                        ((ram_block_type == "AUTO") && 
                         (read_during_write_mode_mixed_ports == "DONT_CARE")))
                        mem_data[i] = {width_a{1'bx}};
                    else
                        mem_data[i] = 0;
            end
        end

        else  // Memory initialization file is used
        begin  

            for (i = 0; i < (1 << widthad_a); i = i + 1)
            begin
                if ((ram_block_type == "MEGARAM")||
                    (ram_block_type == "M-RAM") ||
                    ((ram_block_type == "AUTO") && 
                     (read_during_write_mode_mixed_ports == "DONT_CARE")))
                     mem_data[i] = {width_a{1'bx}};
                else
                     mem_data[i] = {width_a{1'b0}};
            end

            init_file_b_port = 0;

            if ((init_file_layout != "PORT_A") || 
                (init_file_layout != "PORT_B"))
            begin
                if (operation_mode == "DUAL_PORT")
                    init_file_b_port = 1;
                else
                    init_file_b_port = 0;
            end
            else
            begin
                if (init_file_layout == "PORT_A")
                    init_file_b_port = 0;
                else if (init_file_layout == "PORT_B")
                    init_file_b_port = 1;
            end

            if (init_file_b_port) 
            begin
                `ifdef NO_PLI
                    $readmemh(init_file, mem_data_b);
                `else
                    $convert_hex2ver(init_file, width_b, ram_initf);
                    $readmemh(ram_initf, mem_data_b);
                `endif

                for (i = 0; i < (numwords_b * width_b); i = i + 1)  
                begin
                    temp_wb = mem_data_b[i / width_b]; 
                    temp = temp_wb[i % width_b];
                    temp_wa = mem_data[i / width_a]; 
                    temp_wa[i % width_a] = temp;       
                    mem_data[i / width_a] = temp_wa; 
                end
            end
            else
            begin
                `ifdef NO_PLI
                    $readmemh(init_file, mem_data);
                `else
                    $convert_hex2ver(init_file, width_a, ram_initf);
                    $readmemh(ram_initf, mem_data);
                `endif
            end
        end

        write_by_a = 0;
        write_by_b = 0;

        // Initialize internal registers/signals
        i_data_reg_a = ~0;
        i_data_reg_b = ~0;
        i_address_reg_a = ~0;
        i_address_reg_b = ~0;
        i_wren_reg_a = 0;
        i_wren_reg_b = 0;
        i_rden_reg_b = 1;
        i_rden_flag_b = 0;
        i_write_flag_a = 0;
        i_write_flag_b = 0;
        i_byteena_mask_reg_a = ~0;
        i_byteena_mask_reg_b = ~0;

        if ((ram_block_type == "MEGARAM") || 
            (ram_block_type == "M-RAM") || 
            ((ram_block_type == "AUTO") && 
             (read_during_write_mode_mixed_ports == "DONT_CARE")))
        begin
            i_q_tmp_a = {width_a{1'bx}};
            i_q_tmp_b = {width_b{1'bx}};
            i_q_tmp2_a = {width_a{1'bx}};
            i_q_tmp2_b = {width_b{1'bx}};
            i_q_reg_a = {width_a{1'bx}};
            i_q_reg_b = {width_b{1'bx}};
        end
        else
        begin
            i_q_tmp_a = 0;
            i_q_tmp_b = 0;
            i_q_tmp2_a = 0;
            i_q_tmp2_b = 0;
            i_q_reg_a = 0;
            i_q_reg_b = 0;
        end

        good_to_go_a = 0;
        good_to_go_b = 0;

        aclr0_tmp_a = 0;
        aclr1_tmp_a = 0;
        aclr0_tmp_b = 0;
        aclr1_tmp_b = 0;


        // aclr status
        // 0 : no aclr asserted at any clock edge
        // 1 : aclr asserted at positive clock edge
        // 2 : aclr asserted at negative clock edge
        aclr0_status_a = 0;
        aclr1_status_a = 0;
        aclr0_status_b = 0;
        aclr1_status_b = 0;
    end

// SIGNAL ASSIGNMENT

    // Clock signal assignment

    // port a clock assignments:
    assign i_clk_a                     = clock0;
    assign i_outdata_clk_a             = (outdata_reg_a == "CLOCK1") ? 
                                         clock1 : ((outdata_reg_a == "CLOCK0") ? 
                                         clock0 : 0);
    // port b clock assignments:
    assign i_indata_clk_b              = (indata_reg_b == "CLOCK1") ? 
                                         clock1 : ((indata_reg_b == "CLOCK0") ?  
                                         clock0 : 0);
    assign i_outdata_clk_b             = (outdata_reg_b == "CLOCK1") ? 
                                         clock1 : ((outdata_reg_b == "CLOCK0") ? 
                                         clock0 : 0);
    assign i_wrcontrol_wraddress_clk_b = (operation_mode != "BIDIR_DUAL_PORT") ? 
                                         0 : ((wrcontrol_wraddress_reg_b == "CLOCK1") ? 
                                         clock1 : ((wrcontrol_wraddress_reg_b == "CLOCK0") ? 
                                         clock0 : 0));
    assign i_rdcontrol_clk_b           = (operation_mode != "DUAL_PORT") ?
                                         0 : ((address_reg_b == "CLOCK1") ? 
                                         clock1 : ((address_reg_b == "CLOCK0") ? 
                                         clock0 : 0));
    assign i_address_clk_b             = (address_reg_b == "CLOCK1") ? 
                                         clock1 : ((address_reg_b == "CLOCK0") ? 
                                         clock0 : 0);
    assign i_byteena_clk_b             = (byteena_reg_b == "CLOCK1") ? 
                                         clock1 : ((byteena_reg_b == "CLOCK0") ? 
                                         clock0 : 0);
    
    // Clock enable signal assignment

    // port a clock enable assignments:
    assign i_clken_a                      = clocken0;
    assign i_outdata_clken_a              = (outdata_reg_a == "CLOCK1") ? 
                                            clocken1 : ((outdata_reg_a == "CLOCK0") ? 
                                            clocken0 : 1);
    // port b clock enable assignments:
    assign i_indata_clken_b               = (indata_reg_b == "CLOCK0") ? 
                                            clocken0 : ((indata_reg_b == "CLOCK1") ? 
                                            clocken1 : 1);
    assign i_outdata_clken_b              = (outdata_reg_b == "CLOCK0") ? 
                                            clocken0 : ((outdata_reg_b == "CLOCK1") ? 
                                            clocken1 : 1);
    assign i_wrcontrol_wraddress_clken_b  = (operation_mode != "BIDIR_DUAL_PORT") ? 
                                            1 : ((wrcontrol_wraddress_reg_b == "CLOCK0") ? 
                                            clocken0 : ((wrcontrol_wraddress_reg_b == "CLOCK1") ? 
                                            clocken1 : 1));
    assign i_rdcontrol_clken_b            = (operation_mode != "DUAL_PORT") ?
                                            1 : ((rdcontrol_reg_b == "CLOCK0") ? 
                                            clocken0 : ((rdcontrol_reg_b == "CLOCK1") ? 
                                            clocken1 : 1));
    assign i_address_clken_b              = (address_reg_b == "CLOCK0") ? 
                                            clocken0 : ((address_reg_b == "CLOCK1") ? 
                                            clocken1 : 1);
    assign i_byteena_clken_b              = (byteena_reg_b == "CLOCK0") ? 
                                            clocken0 : ((byteena_reg_b == "CLOCK1") ? 
                                            clocken1 : 1);

    // Async clear signal assignment

    // port a clear assigments:
    assign i_indata_aclr_a    = (indata_aclr_a == "CLEAR0") ? i_aclr0 : 0;
    assign i_address_aclr_a   = (address_aclr_a == "CLEAR0") ? i_aclr0 : 0;
    assign i_wrcontrol_aclr_a = (wrcontrol_aclr_a == "CLEAR0") ? i_aclr0 : 0;
    assign i_byteena_aclr_a   = (byteena_aclr_a == "CLEAR0") ? 
                                i_aclr0 : ((byteena_aclr_a == "CLEAR1") ? 
                                i_aclr1 : 0);
    assign i_outdata_aclr_a   = (outdata_aclr_a == "CLEAR0") ? 
                                i_aclr0 : ((outdata_aclr_a == "CLEAR1") ? 
                                i_aclr1 : 0);
    // port b clear assignments:
    assign i_indata_aclr_b    = (indata_aclr_b == "CLEAR0") ? 
                                i_aclr0 : ((indata_aclr_b == "CLEAR1") ? 
                                i_aclr1 : 0);
    assign i_address_aclr_b   = (address_aclr_b == "CLEAR0") ? 
                                i_aclr0 : ((address_aclr_b == "CLEAR1") ? 
                                i_aclr1 : 0);
    assign i_wrcontrol_aclr_b = (wrcontrol_aclr_b == "CLEAR0") ? 
                                i_aclr0 : ((wrcontrol_aclr_b == "CLEAR1") ? 
                                i_aclr1 : 0);
    assign i_rdcontrol_aclr_b = (rdcontrol_aclr_b == "CLEAR0") ? 
                                i_aclr0 : ((rdcontrol_aclr_b == "CLEAR1") ? 
                                i_aclr1 : 0);
    assign i_byteena_aclr_b   = (byteena_aclr_b == "CLEAR0") ? 
                                i_aclr0 : ((byteena_aclr_b == "CLEAR1") ? 
                                i_aclr1 : 0);
    assign i_outdata_aclr_b   = (outdata_aclr_b == "CLEAR0") ? 
                                i_aclr0 : ((outdata_aclr_b == "CLEAR1") ? 
                                i_aclr1 : 0);

    // Byteena connectivity signal assignment

    assign byteena_a_unconnected = (byteena_a[0] === 1'bz) ? 1 : 0;
    assign byteena_b_unconnected = (byteena_b[0] === 1'bz) ? 1 : 0;


    // Temporary async clear signal process

    always @(i_aclr0)
    begin
        aclr0_tmp_a <= i_aclr0;
        aclr0_tmp_b <= i_aclr0;
    end

    always @(i_aclr1)
    begin
        aclr1_tmp_a <= i_aclr1;
        aclr1_tmp_b <= i_aclr1;
    end
    
    // Reset async clear status flags process

    always @(i_clk_a)
    begin
        if (operation_mode != "ROM")
        begin
            if ((ram_block_type == "MEGARAM") || (ram_block_type == "M-RAM"))
            begin
                if (~i_clk_a)
                begin
                    aclr0_status_a = 0;
                    aclr1_status_a = 0;
                end
            end
            else
            begin
                if (i_clk_a)
                begin
                    aclr0_status_a = 0;
                    aclr1_status_a = 0;
                end
            end
        end
    end

    always @(i_wrcontrol_wraddress_clk_b)
    begin
        if (operation_mode == "BIDIR_DUAL_PORT")
        begin
            if ((ram_block_type == "MEGARAM") || (ram_block_type == "M-RAM"))
            begin
                if (~i_wrcontrol_wraddress_clk_b)
                begin
                    aclr0_status_b = 0;
                    aclr1_status_b = 0;
                end
            end
            else
            begin
                if (i_wrcontrol_wraddress_clk_b)
                begin
                    aclr0_status_b = 0;
                    aclr1_status_b = 0;
                end
            end
        end
    end


    // Port A inputs registered : indata, address, byeteena, wren
    // Aclr status flags get updated here for M-RAM ram_block_type    

    always @(posedge i_clk_a)
    begin
        if (i_clken_a)
        begin

            i_write_flag_a <= ~ i_write_flag_a;

            if (i_indata_aclr_a)
                i_data_reg_a <= 0;
            else
                i_data_reg_a <= data_a;

            if (i_address_aclr_a)
                i_address_reg_a <= 0;
            else
                i_address_reg_a <= address_a;

            if (byteena_a_unconnected)
                i_byteena_mask_reg_a <= ~0;
            else if (i_byteena_aclr_a)
                i_byteena_mask_reg_a <= 0;
            else
                for (k = 0; k < width_a; k = k+1)
                    i_byteena_mask_reg_a[k] <= byteena_a[k/byte_size];

            if (i_wrcontrol_aclr_a)
                i_wren_reg_a <= 0;
            else
                i_wren_reg_a <= i_wren_a;

            if ((ram_block_type == "MEGARAM") || (ram_block_type == "M-RAM"))
            begin
                if (i_wren_reg_a)
                begin
                    if (i_aclr0 & ~aclr0_tmp_a)
                        aclr0_status_a = 1;
                    else
                        aclr0_status_a = 0;

                    if (i_aclr1 & ~aclr1_tmp_a)
                        aclr1_status_a = 1;
                    else
                        aclr1_status_a = 0;
                end
            end

            good_to_go_a <= 1;
            write_by_b_reg_a <= write_by_b;
        end
    end


    // Aclr status (port a) flags get updated here for non M-RAM ram_block_type    

    always @(negedge i_clk_a)
    begin
        if ((ram_block_type != "MEGARAM") && (ram_block_type != "M-RAM"))
        begin
            if (i_wren_reg_a)
            begin
                if (i_aclr0 & ~aclr0_tmp_a)
                    aclr0_status_a = 2;
                else
                    aclr0_status_a = 0;

                if (i_aclr1 & ~aclr1_tmp_a)
                    aclr1_status_a = 2;
                else
                    aclr1_status_a = 0;
            end
        end
    end



    // Port B indata input registered
    always @(posedge i_indata_clk_b)
    begin
        if (i_indata_clken_b)
        begin
            if (i_indata_aclr_b)
                i_data_reg_b <= 0;
        else
            i_data_reg_b <= data_b;
        end
    end


    // Port B address input registered (for dual_port mode)

    always @(posedge i_address_clk_b)
    begin
        if (operation_mode == "DUAL_PORT")
        begin
            if (i_address_clken_b)
            begin
                good_to_go_b <= 1;
                if (i_address_aclr_b)
                    i_address_reg_b <= 0;
                else
                    i_address_reg_b <= address_b;

                write_by_a_reg_b <= write_by_a;
            end
        end
    end


    // Port B inputs registered : wren, address, byteena (for bidir_dual_port mode)
    // Aclr status flags get updated here for M-RAM ram_block_type    

    always @(posedge i_wrcontrol_wraddress_clk_b)
    begin
        if (operation_mode == "BIDIR_DUAL_PORT")
        begin
            if (i_wrcontrol_wraddress_clken_b)
            begin
                i_write_flag_b <= ~ i_write_flag_b;
                i_rden_flag_b <= ~i_rden_flag_b;

                if (i_wrcontrol_aclr_b)
                    i_wren_reg_b <= 0;
                else
                    i_wren_reg_b <= i_wren_b;

                if (i_address_aclr_b)
                    i_address_reg_b <= 0;
                else
                    i_address_reg_b <= address_b;

                if (byteena_b_unconnected)
                    i_byteena_mask_reg_b <= ~0;
                else if (i_byteena_aclr_b)
                    i_byteena_mask_reg_b <= 0;
                else
                    for (k = 0; k < width_b; k = k+1)
                        i_byteena_mask_reg_b[k] <= byteena_b[k/byte_size];

                if ((ram_block_type == "MEGARAM") || (ram_block_type == "M-RAM"))
                begin
                    if (i_wren_reg_b)
                    begin
                        if (i_aclr0 & ~aclr0_tmp_b)
                            aclr0_status_b = 1;
                        else
                            aclr0_status_b = 0;

                        if (i_aclr1 & ~aclr1_tmp_b)
                            aclr1_status_b = 1;
                        else
                            aclr1_status_b = 0;
                    end
                end

                good_to_go_b <= 1;
                write_by_a_reg_b <= write_by_a;
            end
        end
    end


    // Aclr status (port b) flags get updated here for non M-RAM ram_block_type    
    
    always @(negedge i_wrcontrol_wraddress_clk_b)
    begin
        if ((ram_block_type != "MEGARAM") && (ram_block_type != "M-RAM"))
        begin
            if (i_wren_reg_b)
            begin
                if (i_aclr0 & ~aclr0_tmp_b)
                    aclr0_status_b = 2;
                else
                    aclr0_status_b = 0;

                if (i_aclr1 & ~aclr1_tmp_b)
                    aclr1_status_b = 2;
                else
                    aclr1_status_b = 0;
            end
        end
    end


    // Port B rden input registered (for dual_port mode)

    always @(posedge i_rdcontrol_clk_b)
    begin
        if (i_rdcontrol_clken_b)
        begin
            if (!(rden_b === 1'bz))
            begin
                i_rden_flag_b <= ~i_rden_flag_b;
                if (operation_mode != "DUAL_PORT")
                    i_rden_reg_b <= ~0;
                else if (i_rdcontrol_aclr_b)
                    i_rden_reg_b <= 0;
                else
                    i_rden_reg_b <= i_rden_b;
            end
        end

    end


    // Port A writting

    always @(i_wren_reg_a or i_data_reg_a or i_address_reg_a or i_byteena_mask_reg_a or i_write_flag_a)
    begin
        if ((operation_mode == "DUAL_PORT") || 
            (operation_mode == "SINGLE_PORT") || 
            (operation_mode == "BIDIR_DUAL_PORT"))
        begin
            if (i_wren_reg_a)
            begin
                // wait for the appropriate edge to clock in data (for MRAM, it happens right away)
                if ((ram_block_type != "MEGARAM") && (ram_block_type != "M-RAM"))
                    @(negedge i_clk_a) ;

                    if (aclr0_status_a == 1)
                    begin
                        if ((ram_block_type == "MEGARAM") || 
                            (ram_block_type == "M-RAM"))
                        begin
                            if (address_aclr_a == "CLEAR0")
                            begin
                                for (i=0; i < i_numwords_a; i=i+1)
                                begin  
                                    mem_data[i] = {width_a{1'bx}};
                                end
                            end
                            else if ((wrcontrol_aclr_a == "CLEAR0") || 
                                     (indata_aclr_a == "CLEAR0") || 
                                     (byteena_aclr_a == "CLEAR0"))
                            begin
                                j = i_address_reg_a * width_a;
                                mem_data[i_address_reg_a] = {width_a{1'bx}};
                            end
                        end
                    end
                    else if (aclr0_status_a == 2)
                    begin
                        if ((ram_block_type != "MEGARAM") && (ram_block_type != "M-RAM"))
                        begin
                            if (address_aclr_a == "CLEAR0")
                            begin
                                for (i=0; i < i_numwords_a; i=i+1)
                                begin  
                                    mem_data[i] = {width_a{1'bx}};
                                end
                            end
                        end
                        else if ((wrcontrol_aclr_a == "CLEAR0") || 
                                 (indata_aclr_a == "CLEAR0") || 
                                 (byteena_aclr_a == "CLEAR0"))
                        begin
                            j = i_address_reg_a * width_a;
                            mem_data[i_address_reg_a] = {width_a{1'bx}};
                        end
                    end
                    else if (aclr1_status_a == 1)
                    begin
                        if ((ram_block_type == "MEGARAM") || (ram_block_type == "M-RAM"))
                        begin
                            if (address_aclr_a == "CLEAR1")
                            begin
                                for (i=0; i < i_numwords_a; i=i+1)
                                begin  
                                    mem_data[i] = {width_a{1'bx}};
                                end
                            end
                            else if ((wrcontrol_aclr_a == "CLEAR1") || 
                                     (indata_aclr_a == "CLEAR1") || 
                                     (byteena_aclr_a == "CLEAR1"))
                            begin
                                j = i_address_reg_a * width_a;
                                mem_data[i_address_reg_a] = {width_a{1'bx}};
                            end
                        end
                    end
                    else if (aclr1_status_a == 2)
                    begin
                        if ((ram_block_type != "MEGARAM") && (ram_block_type != "M-RAM"))
                        begin
                            if (address_aclr_a == "CLEAR1")
                            begin
                                for (i=0; i < i_numwords_a; i=i+1)
                                begin  
                                    mem_data[i] = {width_a{1'bx}};
                                end
                            end
                            else if ((wrcontrol_aclr_a == "CLEAR1") || 
                                     (indata_aclr_a == "CLEAR1") || 
                                     (byteena_aclr_a == "CLEAR1"))
                            begin
                                j = i_address_reg_a * width_a;
                                mem_data[i_address_reg_a] = {width_a{1'bx}};
                            end
                        end
                    end
                    else 
                    begin
                        j = i_address_reg_a * width_a;
                        temp_wa2 = (i_data_reg_a & i_byteena_mask_reg_a) | 
                                   (mem_data[i_address_reg_a] & ~i_byteena_mask_reg_a);
                        mem_data[i_address_reg_a] = temp_wa2;
                    end
                    write_by_a = write_by_a + 1;
            end
        end
    end


    // Port B writting

    always @(i_wren_reg_b or i_data_reg_b or i_address_reg_b or i_byteena_mask_reg_b or i_write_flag_b)
    begin
        if (operation_mode == "BIDIR_DUAL_PORT")
        begin
            if (i_wren_reg_b & i_wrcontrol_wraddress_clken_b)
            begin

                // wait for the appropriate edge to clock in data (For MRAM, it happens right away)
                if ((ram_block_type != "MEGARAM") &&
                    (ram_block_type != "M-RAM"))
                    @(negedge i_wrcontrol_wraddress_clk_b) ;

                    if (aclr0_status_b == 1)
                    begin
                        if ((ram_block_type == "MEGARAM") || (ram_block_type == "M-RAM"))
                        begin
                            if (address_aclr_b == "CLEAR0")
                            begin
                                for (i=0; i < i_numwords_a; i=i+1)
                                begin  
                                    mem_data[i] = {width_a{1'bx}};
                                end
                            end
                            else if ((wrcontrol_aclr_b == "CLEAR0") || 
                                     (indata_aclr_b == "CLEAR0") || 
                                     (byteena_aclr_b == "CLEAR0"))
                            begin
                                j = i_address_reg_b * width_b;
                                for (i = 0; i < width_b; i = i + 1)
                                begin
                                    temp_wa = mem_data[(j+i)/width_a];
                                    temp_wa[(j+i)%width_a] = {1'bx};
                                    mem_data[(j+i)/width_a] = temp_wa;
                                end
                            end
                        end
                    end
                    else if (aclr0_status_b == 2)
                    begin
                        if ((ram_block_type != "MEGARAM") && (ram_block_type != "M-RAM"))
                        begin
                            if (address_aclr_a == "CLEAR0")
                            begin
                                for (i=0; i < i_numwords_a; i=i+1)
                                begin  
                                    mem_data[i] = {width_a{1'bx}};
                                end
                            end
                            else if ((wrcontrol_aclr_a == "CLEAR0") || 
                                     (indata_aclr_a == "CLEAR0") || 
                                     (byteena_aclr_a == "CLEAR0"))
                            begin
                                j = i_address_reg_b * width_b;
                                for (i=0; i<width_b; i=i+1)
                                begin
                                    temp_wa = mem_data[(j+i)/width_a];
                                    temp_wa[(j+i)%width_a] = {1'bx};
                                    mem_data[(j+i)/width_a] = temp_wa;
                                end
                            end
                        end
                    end
                    else if (aclr1_status_b == 1)
                    begin
                        if ((ram_block_type == "MEGARAM") || 
                            (ram_block_type == "M-RAM"))
                        begin
                            if (address_aclr_a == "CLEAR1")
                            begin
                                for (i = 0; i < i_numwords_a; i = i + 1)
                                begin  
                                    mem_data[i] = {width_a{1'bx}};
                                end
                            end
                            else if ((wrcontrol_aclr_a == "CLEAR1") || 
                                     (indata_aclr_a == "CLEAR1") || 
                                     (byteena_aclr_a == "CLEAR1"))
                            begin
                                j = i_address_reg_b * width_b;
                                for (i=0; i<width_b; i=i+1)
                                begin
                                    temp_wa = mem_data[(j+i)/width_a];
                                    temp_wa[(j+i)%width_a] = {1'bx};
                                    mem_data[(j+i)/width_a] = temp_wa;
                                end
                            end
                        end
                    end
                    else if (aclr1_status_b == 2)
                    begin
                        if ((ram_block_type != "MEGARAM") && (ram_block_type != "M-RAM"))
                        begin
                            if (address_aclr_a == "CLEAR1")
                            begin
                                for (i=0; i < i_numwords_a; i=i+1)
                                begin  
                                    mem_data[i] = {width_a{1'bx}};
                                end
                            end
                            else if ((wrcontrol_aclr_a == "CLEAR1") || 
                                     (indata_aclr_a == "CLEAR1") || 
                                     (byteena_aclr_a == "CLEAR1"))
                            begin
                                j = i_address_reg_b * width_b;
                                for (i=0; i<width_b; i=i+1)
                                begin
                                    temp_wa = mem_data[(j+i)/width_a];
                                    temp_wa[(j+i)%width_a] = {1'bx};
                                    mem_data[(j+i)/width_a] = temp_wa;
                                end
                            end
                        end
                    end
                    else 
                    begin
                        j = i_address_reg_b * width_b;
                        for (i=0; i<width_b; i=i+1)
                        begin
                            temp_wa = mem_data[(j+i)/width_a];
                            temp_wa[(j+i)%width_a] = i_data_reg_b[i] & i_byteena_mask_reg_b[i] | 
                                                     temp_wa[(j+i)%width_a] & ~i_byteena_mask_reg_b[i];
                            mem_data[(j+i)/width_a] = temp_wa;
                        end
                    end
                    write_by_b = write_by_b + 1;
            end
        end
    end
    

    // Port A reading

    always @(i_address_reg_a or write_by_b_reg_a or write_by_a)
    begin
        if ((operation_mode == "BIDIR_DUAL_PORT") || 
             (operation_mode == "SINGLE_PORT") || 
             (operation_mode == "ROM"))
        begin
            if (~good_to_go_a)
            begin
                if ((ram_block_type == "MEGARAM") || 
                    (ram_block_type == "M-RAM") || 
                    ((ram_block_type == "AUTO") && 
                     (read_during_write_mode_mixed_ports == "DONT_CARE")))
                    i_q_tmp2_a = {width_a{1'bx}};
                else
                    i_q_tmp2_a = 0;
              end
            else 
            begin
                i_q_tmp2_a = mem_data[i_address_reg_a];

                if ((operation_mode == "BIDIR_DUAL_PORT") && (wrcontrol_wraddress_reg_b == "CLOCK0"))
                begin
                    if ((ram_block_type == "MEGARAM") || 
                         (ram_block_type == "M-RAM") ||
                         ((read_during_write_mode_mixed_ports == "DONT_CARE") && 
                          (ram_block_type == "AUTO")))
                        if (i_wren_reg_b & ~i_wren_reg_a)
                            if ((((i_address_reg_a * width_a) > (i_address_reg_b * width_b)) &&
                                 ((i_address_reg_a * width_a) < ((i_address_reg_b * width_b) + width_b - 1))) ||
                                 ((((i_address_reg_a * width_a) + width_a - 1) > (i_address_reg_b * width_b)) &&
                                 (((i_address_reg_a * width_a) + width_a - 1) < ((i_address_reg_b * width_b) + width_b - 1))))
                                 for (i = (i_address_reg_a * width_a); i < ((i_address_reg_a * width_a) + width_a); i = i + 1)
                                 begin
                                     if ((i > (i_address_reg_b * width_b)) && (i < ((i_address_reg_b * width_b) + width_b - 1)))
                                         i_q_tmp2_a[i - (i_address_reg_a * width_a)] = 1'bx;
                                 end
                end
            end
        end
    end


    // assigning the correct output values for i_q_tmp_a (non-registered output)

    always @(i_q_tmp2_a or i_wren_reg_a or i_data_reg_a or i_address_reg_a or i_byteena_mask_reg_a)
    begin
        begin
            if (i_wren_reg_a)
                i_q_tmp_a = (i_data_reg_a & i_byteena_mask_reg_a) | 
                            (i_q_tmp2_a & ~i_byteena_mask_reg_a);
            else
                i_q_tmp_a = i_q_tmp2_a;
        end
    end


    // Port A outdata output registered
    always @(posedge i_outdata_clk_a or posedge i_outdata_aclr_a) 
    begin
        if (i_outdata_aclr_a)
            i_q_reg_a <= 0;
        else if (i_outdata_clken_a)
            i_q_reg_a <= i_q_tmp_a;
    end


    // Port A : assigning the correct output values for q_a

    assign q_a = (operation_mode == "DUAL_PORT") ?
                     0 : (((outdata_reg_a == "CLOCK0") || (outdata_reg_a == "CLOCK1")) ? 
                     i_q_reg_a : i_q_tmp_a);


    // Port B reading

    always @(i_rden_reg_b or i_address_reg_b or write_by_a_reg_b or write_by_b or i_rden_flag_b)
    begin
        if ((operation_mode == "DUAL_PORT") || 
            (operation_mode == "BIDIR_DUAL_PORT"))
        begin
            if (~good_to_go_b)
            begin
                if ((ram_block_type == "MEGARAM") || 
                    (ram_block_type == "M-RAM") || 
                    ((ram_block_type == "AUTO") && 
                     (read_during_write_mode_mixed_ports == "DONT_CARE")))
                    i_q_tmp_b = {width_b{1'bx}};
                else
                    i_q_tmp_b = 0;
            end
            else 
            begin
                if (i_rden_reg_b & i_rdcontrol_clken_b)
                begin
                    j = i_address_reg_b * width_b; 
                    for (i=0; i<width_b; i=i+1) 
                    begin
                        temp_wa2 = mem_data[(j+i)/width_a]; 

                        if ((ram_block_type == "MEGARAM") || 
                            (ram_block_type == "M-RAM") ||
                            ((read_during_write_mode_mixed_ports == "DONT_CARE") && 
                             (ram_block_type == "AUTO")))
                        begin
                            if ((rdcontrol_reg_b == "CLOCK0") || 
                                (wrcontrol_wraddress_reg_b == "CLOCK0"))
                                if (i_wren_reg_a & ~i_wren_reg_b)
                                    if (((j+i)/width_a) == i_address_reg_a)
                                        temp_wa2 = {width_a{1'bx}};
                        end

                        temp_wb[i] = temp_wa2[(j+i)%width_a];
                    end

                    i_q_tmp2_b = temp_wb;
                end
            end
        end
    end


    // assigning the correct output values for i_q_tmp_b (non-registered output)

    always @(i_q_tmp2_b or i_wren_reg_b or i_data_reg_b or i_address_reg_b or i_byteena_mask_reg_b)
    begin
        if ((operation_mode == "DUAL_PORT") || 
             (operation_mode == "BIDIR_DUAL_PORT"))
        begin
            if (operation_mode == "DUAL_PORT")
            begin
                if (i_rden_reg_b && ~i_rdcontrol_aclr_b)
                    i_q_tmp_b = i_q_tmp2_b;
            end
            else if (operation_mode == "BIDIR_DUAL_PORT")
            begin
                if (i_wren_reg_b)
                    i_q_tmp_b = (i_data_reg_b & i_byteena_mask_reg_b) | 
                                (i_q_tmp2_b & ~i_byteena_mask_reg_b);
                else
                    i_q_tmp_b = i_q_tmp2_b;
            end
        end
    end


    // Port B outdata output registered

    always @(posedge i_outdata_clk_b or posedge i_outdata_aclr_b) 
    begin
        if (i_outdata_aclr_b)
            i_q_reg_b <= 0;
        else if (i_outdata_clken_b)
            i_q_reg_b <= i_q_tmp_b;
    end


    // Port B : assigning the correct output values for q_b
    
    assign q_b = ((operation_mode == "SINGLE_PORT") || (operation_mode == "ROM")) ?
                     0 : (((outdata_reg_b == "CLOCK0") || (outdata_reg_b == "CLOCK1")) ? 
                     i_q_reg_b : i_q_tmp_b);

endmodule // ALTSYNCRAM

// END OF MODULE

///////////////////////////////////////////////////////////////////////////////
//
//                             STRATIX_PLL
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1ps / 1ps
module dffp ( Q, CLK, ENA, D, CLRN, PRN );
   input D;
   input CLK;
   input CLRN;
   input PRN;
   input ENA;
   output Q;


   tri1 PRN, CLRN, ENA;
   reg Q;

always @ (posedge CLK or negedge CLRN or negedge PRN )
    if (PRN == 1'b0) Q = 1;
    else if (CLRN == 1'b0) Q = 0;
    else if ((CLK == 1) & (ENA == 1'b1)) Q = D;
endmodule

// M_CNTR
`timescale 1 ps / 1 ps
module m_cntr (clk, reset, cout, initial_value, modulus, time_delay);

// INPUT PORT
input clk;
input reset;
input [31:0] initial_value;
input [31:0] modulus;
input [31:0] time_delay;
// OUTPUT PORT
output cout;

// INTERNAL VARIABLE DECLARATION
integer count;
reg tmp_cout;
reg first_rising_edge;
reg clk_last_value;
reg cout_tmp;

initial
begin
    count = 1;
    first_rising_edge = 1;
    clk_last_value = 0;
end

always @(reset or clk)
begin
    if (reset)
    begin
        count = 1;
        tmp_cout = 0;
        first_rising_edge = 1;
    end
    else
    begin
        if (clk == 1 && clk_last_value != clk && first_rising_edge)
        begin
            first_rising_edge = 0;
            tmp_cout = clk;
        end
        else if (first_rising_edge == 0)
        begin
            if (count < modulus)
               count = count + 1;
            else
            begin
               count = 1;
               tmp_cout = ~tmp_cout;
            end
        end
    end
    clk_last_value = clk;

    cout_tmp <= #(time_delay) tmp_cout;
end

and (cout, cout_tmp, 1'b1);

endmodule // m_cntr

// N_CNTR
`timescale 1 ps / 1 ps
module n_cntr (clk, reset, cout, initial_value, modulus, time_delay);

// INPUT PORT
input clk;
input reset;
input [31:0] initial_value;
input [31:0] modulus;
input [31:0] time_delay;
// OUTPUT PORT
output cout;

// INTERNAL VARIABLE DECLARATION
integer count;
reg tmp_cout;
reg first_rising_edge;
reg clk_last_value;
reg cout_tmp;

initial
begin
    count = 1;
    first_rising_edge = 1;
    clk_last_value = 0;
end

always @(reset or clk)
begin
    if (reset)
    begin
        count = 1;
        tmp_cout = 0;
        first_rising_edge = 1;
    end
    else
    begin
        if (clk == 1 && clk_last_value != clk && first_rising_edge)
        begin
            first_rising_edge = 0;
            tmp_cout = clk;
        end
        else if (first_rising_edge == 0)
        begin
            if (count < modulus)
                count = count + 1;
            else
            begin
                count = 1;
                tmp_cout = ~tmp_cout;
            end
        end
    end
    clk_last_value = clk;

end

assign #time_delay cout = tmp_cout;

endmodule // n_cntr

// SCALE_CNTR

`timescale 1 ps / 1 ps
module scale_cntr(clk, pll_reset, internal_reset, cout, high, low, initial_value,
                  mode, time_delay, ph_tap);

// INPUT PORT
input clk;
input pll_reset;
input internal_reset;
input [31:0] high;
input [31:0] low;
input [31:0] initial_value;
input [8*6:1] mode;
input [31:0] time_delay;
input [31:0] ph_tap;
// OUTPUT PORT
output cout;

// INTERNAL VARIABLE DECLARATION
reg tmp_cout;
reg first_rising_edge;
reg clk_last_value;
integer count;
integer output_shift_count;

initial
begin
    count = 1;
    first_rising_edge = 0;
    tmp_cout = 0;
    clk_last_value = 0;
    output_shift_count = 0;
end

always @(clk or pll_reset or internal_reset)
begin
    if (pll_reset)   // areset and reset for timing sim.
    begin
        count = 1;
        output_shift_count = 0;
        tmp_cout = 0;
        first_rising_edge = 0;
    end
    else if (internal_reset)   // reset for func. sim
    begin
        count = 1;
        if (ph_tap > 0)
        begin
            first_rising_edge = 0;
            output_shift_count = 0;
            tmp_cout = 0;
        end
        else begin
            tmp_cout = 1;
            first_rising_edge = 1;
            output_shift_count = 1;
        end
    end
    else if (clk_last_value != clk)
    begin
        if (mode == "off")
            tmp_cout = 0;
        else if (mode == "bypass")
            tmp_cout = clk;
        else if (first_rising_edge == 0)
        begin
            if (clk == 1)
            begin
                output_shift_count = output_shift_count + 1;
                if (output_shift_count == initial_value)
                begin
                   tmp_cout = clk;
                   first_rising_edge = 1;
                end
            end
        end
        else if (output_shift_count < initial_value)
        begin
            if (clk == 1)
                output_shift_count = output_shift_count + 1;
        end
        else
        begin
            count = count + 1;
            if (mode == "even" && (count == (high*2) + 1))
                tmp_cout = 0;
            else if (mode == "odd" && (count == (high*2)))
                tmp_cout = 0;
            else if (count == (high + low)*2 + 1)
            begin
                tmp_cout = 1;
                count = 1;        // reset count
            end
        end
    end
    clk_last_value = clk;
end

assign #time_delay cout = tmp_cout;

endmodule // scale_cntr

// START MODULE NAME -----------------------------------------------------------
//
// Module Name      : STRATIX_PLL
//
// Description      : PLL behavioral model used by altpll
// 
// Limitations      : Applies to the Stratix and Stratix GX device families
//                    No support for spread spectrum feature in the model
//
// Expected results : Up to 10 output clocks, each defined by its own set of
//                    parameters. Locked output (active high) indicates when the
//                    PLL locks. clkbad, clkloss and activeclock are used for
//                    clock switchover to inidicate which input clock has gone
//                    bad, when the clock switchover initiates and which input
//                    clock is being used as the reference, respectively.
//                    scandataout is the data output of the serial scan chain.
//
//END MODULE NAME --------------------------------------------------------------

`timescale 1 ps/1 ps
`define WORD_LENGTH 18

module stratix_pll (inclk, fbin, ena, clkswitch, areset, pfdena,
                    clkena, extclkena, scanclk, scanaclr, scandata, clk,
                    extclk, clkbad, activeclock, locked, clkloss, scandataout,
                    // lvds mode specific ports
                    comparator, enable0, enable1);

parameter operation_mode = "normal";
parameter qualify_conf_done = "off";
parameter compensate_clock = "clk0";
parameter pll_type = "auto";
parameter scan_chain = "long";

parameter clk0_multiply_by = 1;
parameter clk0_divide_by = 1;
parameter clk0_phase_shift = 0;
parameter clk0_time_delay = 0;
parameter clk0_duty_cycle = 50;

parameter clk1_multiply_by = 1;
parameter clk1_divide_by = 1;
parameter clk1_phase_shift = 0;
parameter clk1_time_delay = 0;
parameter clk1_duty_cycle = 50;

parameter clk2_multiply_by = 1;
parameter clk2_divide_by = 1;
parameter clk2_phase_shift = 0;
parameter clk2_time_delay = 0;
parameter clk2_duty_cycle = 50;

parameter clk3_multiply_by = 1;
parameter clk3_divide_by = 1;
parameter clk3_phase_shift = 0;
parameter clk3_time_delay = 0;
parameter clk3_duty_cycle = 50;

parameter clk4_multiply_by = 1;
parameter clk4_divide_by = 1;
parameter clk4_phase_shift = 0;
parameter clk4_time_delay = 0;
parameter clk4_duty_cycle = 50;

parameter clk5_multiply_by = 1;
parameter clk5_divide_by = 1;
parameter clk5_phase_shift = 0;
parameter clk5_time_delay = 0;
parameter clk5_duty_cycle = 50;

parameter extclk0_multiply_by = 1;
parameter extclk0_divide_by = 1;
parameter extclk0_phase_shift = 0;
parameter extclk0_time_delay = 0;
parameter extclk0_duty_cycle = 50;

parameter extclk1_multiply_by = 1;
parameter extclk1_divide_by = 1;
parameter extclk1_phase_shift = 0;
parameter extclk1_time_delay = 0;
parameter extclk1_duty_cycle = 50;

parameter extclk2_multiply_by = 1;
parameter extclk2_divide_by = 1;
parameter extclk2_phase_shift = 0;
parameter extclk2_time_delay = 0;
parameter extclk2_duty_cycle = 50;

parameter extclk3_multiply_by = 1;
parameter extclk3_divide_by = 1;
parameter extclk3_phase_shift = 0;
parameter extclk3_time_delay = 0;
parameter extclk3_duty_cycle = 50;

parameter primary_clock = "inclk0";
parameter inclk0_input_frequency = 10000;
parameter inclk1_input_frequency = 10000;
parameter gate_lock_signal = "no";
parameter gate_lock_counter = 1;
parameter lock_high = 1;
parameter lock_low = 1;
parameter valid_lock_multiplier = 5;
parameter invalid_lock_multiplier = 5;

// need default values for the foll.
parameter switch_over_on_lossclk = "off";
parameter switch_over_on_gated_lock = "off";
parameter switch_over_counter = 1;
parameter enable_switch_over_counter = "off";
parameter feedback_source = "e0";
parameter bandwidth = 0;
parameter bandwidth_type = "auto";
parameter down_spread = "0.0";
parameter spread_frequency = 0;
parameter common_rx_tx = "off";
parameter rx_outclock_resource = "auto";
parameter use_vco_bypass = "false";
parameter use_dc_coupling = "false";

parameter pfd_min = 0;
parameter pfd_max = 0;
parameter vco_min = 0;
parameter vco_max = 0;
parameter vco_center = 0;

// ADVANCED USE PARAMETERS
parameter m_initial = 1;
parameter m = 1;
parameter n = 1;
parameter m2 = 1;
parameter n2 = 1;
parameter ss = 1;

parameter l0_high = 1;
parameter l0_low = 1;
parameter l0_initial = 1;
parameter l0_mode = "bypass";
parameter l0_ph = 0;
parameter l0_time_delay = 0;

parameter l1_high = 1;
parameter l1_low = 1;
parameter l1_initial = 1;
parameter l1_mode = "bypass";
parameter l1_ph = 0;
parameter l1_time_delay = 0;

parameter g0_high = 1;
parameter g0_low = 1;
parameter g0_initial = 1;
parameter g0_mode = "bypass";
parameter g0_ph = 0;
parameter g0_time_delay = 0;

parameter g1_high = 1;
parameter g1_low = 1;
parameter g1_initial = 1;
parameter g1_mode = "bypass";
parameter g1_ph = 0;
parameter g1_time_delay = 0;

parameter g2_high = 1;
parameter g2_low = 1;
parameter g2_initial = 1;
parameter g2_mode = "bypass";
parameter g2_ph = 0;
parameter g2_time_delay = 0;

parameter g3_high = 1;
parameter g3_low = 1;
parameter g3_initial = 1;
parameter g3_mode = "bypass";
parameter g3_ph = 0;
parameter g3_time_delay = 0;

parameter e0_high = 1;
parameter e0_low = 1;
parameter e0_initial = 1;
parameter e0_mode = "bypass";
parameter e0_ph = 0;
parameter e0_time_delay = 0;

parameter e1_high = 1;
parameter e1_low = 1;
parameter e1_initial = 1;
parameter e1_mode = "bypass";
parameter e1_ph = 0;
parameter e1_time_delay = 0;

parameter e2_high = 1;
parameter e2_low = 1;
parameter e2_initial = 1;
parameter e2_mode = "bypass";
parameter e2_ph = 0;
parameter e2_time_delay = 0;

parameter e3_high = 1;
parameter e3_low = 1;
parameter e3_initial = 1;
parameter e3_mode = "bypass";
parameter e3_ph = 0;
parameter e3_time_delay = 0;

parameter m_ph = 0;
parameter m_time_delay = 0;
parameter n_time_delay = 0;

parameter extclk0_counter = "e0";
parameter extclk1_counter = "e1";
parameter extclk2_counter = "e2";
parameter extclk3_counter = "e3";

parameter clk0_counter = "g0";
parameter clk1_counter = "g1";
parameter clk2_counter = "g2";
parameter clk3_counter = "g3";
parameter clk4_counter = "l0";
parameter clk5_counter = "l1";

// LVDS mode parameters
parameter enable0_counter = "l0";
parameter enable1_counter = "l0";

// need default values for the following
parameter charge_pump_current = 0;
parameter loop_filter_r = "1.0";
parameter loop_filter_c = 1;

parameter pll_compensation_delay = 0;
parameter simulation_type = "timing";
parameter source_is_pll = "off";

// parameter for stratix lvds
parameter clk0_phase_shift_num = 0;
parameter clk1_phase_shift_num = 0;
parameter clk2_phase_shift_num = 0;

// INPUT PORT
input [1:0] inclk;
input fbin;
input ena;
input clkswitch;
input areset;
input pfdena;
input [5:0] clkena;
input [3:0] extclkena;
input scanclk;
input scanaclr;
input scandata;
// lvds specific input ports
input comparator;

output [5:0] clk;
output [3:0] extclk;
output [1:0] clkbad;
output activeclock;
output locked;
output clkloss;
output scandataout;
// lvds specific output ports
output enable0;
output enable1;

    buf (inclk0_ipd, inclk[0]);
    buf (inclk1_ipd, inclk[1]);
    buf (ena_ipd, ena);
    buf (fbin_ipd, fbin);
    buf (areset_ipd, areset);
    buf (pfdena_ipd, pfdena);
    buf (clkena0_ipd, clkena[0]);
    buf (clkena1_ipd, clkena[1]);
    buf (clkena2_ipd, clkena[2]);
    buf (clkena3_ipd, clkena[3]);
    buf (clkena4_ipd, clkena[4]);
    buf (clkena5_ipd, clkena[5]);
    buf (extclkena0_ipd, extclkena[0]);
    buf (extclkena1_ipd, extclkena[1]);
    buf (extclkena2_ipd, extclkena[2]);
    buf (extclkena3_ipd, extclkena[3]);
    buf (scanclk_ipd, scanclk);
    buf (scanaclr_ipd, scanaclr);
    buf (scandata_ipd, scandata);
    buf (comparator_ipd, comparator);
    buf (clkswitch_ipd, clkswitch);

// VARIABLE AND NET DECLARATIONS

integer scan_chain_length;
integer i, j, k, l;
integer gate_count;
integer egpp_offset;
integer sched_time;
integer total_sched_time;
integer delay_chain, low, high;
integer initial_value_to_delay, fbk_phase, fbk_delay;
integer phase_shift[0:7];

integer m_times_vco_period, refclk_period, fbclk_period;
integer high_time, low_time;
integer my_rem, tmp_rem, rem;
integer tmp_vco_per, vco_per;
time fbclk_last_rising_edge, refclk_last_rising_edge;
integer offset;
integer temp_offset;
integer cycles_to_lock;
integer cycles_to_unlock;
integer l0_count, l1_count;
integer loop_xplier;
integer loop_initial;
integer loop_ph;
integer loop_time_delay;
integer cycle_to_adjust;

integer total_pull_back;
integer pull_back_M;
integer pull_back_ext_fbk_cntr;

reg refclk_got_first_rising_edge;
reg fbclk_got_first_rising_edge;
reg fbclk_got_second_rising_edge;
reg got_refclk_rising_edge, got_fbclk_rising_edge;
reg refclk_last_value, fbclk_last_value;
reg pll_lock, pll_about_to_lock;
reg fbclk_is_in_phase_with_refclk;
reg reset_vco;
reg l0_got_first_rising_edge, l1_got_first_rising_edge;
reg vco_l0_last_value;
reg vco_l1_last_value;

reg gate_out;
reg vco_val;
reg vco_val_last_value;

reg [31:0] m_initial_val, m_val, n_val;
reg [31:0] m_time_delay_val, n_time_delay_val, m_delay;
reg [8*6:1] m_mode_val, n_mode_val;

reg [31:0] l0_high_val, l0_low_val, l0_initial_val;
reg [31:0] l0_time_delay_val;
reg [8*6:1] l0_mode_val;

reg [31:0] l1_high_val, l1_low_val, l1_initial_val;
reg [31:0] l1_time_delay_val;
reg [8*6:1] l1_mode_val;

reg [31:0] g0_high_val, g0_low_val, g0_initial_val;
reg [31:0] g0_time_delay_val;
reg [8*6:1] g0_mode_val;

reg [31:0] g1_high_val, g1_low_val, g1_initial_val;
reg [31:0] g1_time_delay_val;
reg [8*6:1] g1_mode_val;

reg [31:0] g2_high_val, g2_low_val, g2_initial_val;
reg [31:0] g2_time_delay_val;
reg [8*6:1] g2_mode_val;

reg [31:0] g3_high_val, g3_low_val, g3_initial_val;
reg [31:0] g3_time_delay_val;
reg [8*6:1] g3_mode_val;

reg [31:0] e0_high_val, e0_low_val, e0_initial_val;
reg [31:0] e0_time_delay_val;
reg [8*6:1] e0_mode_val;

reg [31:0] e1_high_val, e1_low_val, e1_initial_val;
reg [31:0] e1_time_delay_val;
reg [8*6:1] e1_mode_val;

reg [31:0] e2_high_val, e2_low_val, e2_initial_val;
reg [31:0] e2_time_delay_val;
reg [8*6:1] e2_mode_val;

reg [31:0] e3_high_val, e3_low_val, e3_initial_val;
reg [31:0] e3_time_delay_val;
reg [8*6:1] e3_mode_val;

reg scanclk_last_value;
reg transfer, transfer_enable;
reg [288:0] scan_data;
reg schedule_vco, schedule_zero;
reg do_not_add_high_time;
reg schedule_from_refclk;
reg reschedule_from_fbclk;
reg inclk_last_value;
reg inclk_n;

reg [7:0] vco_out;
wire inclk_l0, inclk_l1;
wire inclk_m;
wire clk0_tmp, clk1_tmp, clk2_tmp;
wire clk3_tmp, clk4_tmp, clk5_tmp;
wire extclk0_tmp, extclk1_tmp, extclk2_tmp, extclk3_tmp;
wire nce_l0, nce_l1, nce_temp;

reg nce_l0_fast, nce_l1_fast;
reg vco_l0, vco_l1;

wire clk0, clk1, clk2, clk3, clk4, clk5;
wire extclk0, extclk1, extclk2, extclk3;


wire lvds_dffb_clk;
wire dffa_out;

reg lvds_dffb_clk_dly;
reg dffa_out_dly;

reg refclk_tmp, fbclk_tmp;
reg first_schedule;

wire enable0_tmp, enable1_tmp;
wire enable_0, enable_1;
reg l0_tmp, l1_tmp;

reg m_reset;
reg cntr_reset_1, cntr_reset_2;

// for external feedback mode

wire [31:0] ext_fbk_cntr_high;
wire [31:0] ext_fbk_cntr_low;
wire [31:0] ext_fbk_cntr_delay;
reg [8*2:1] ext_fbk_cntr;
integer ext_fbk_cntr_ph;
integer ext_fbk_cntr_initial;
wire inclk_e0;
wire inclk_e1;
wire inclk_e2;
wire inclk_e3;
wire [31:0] cntr_e0_initial;
wire [31:0] cntr_e1_initial;
wire [31:0] cntr_e2_initial;
wire [31:0] cntr_e3_initial;
wire [31:0] cntr_e0_delay;
wire [31:0] cntr_e1_delay;
wire [31:0] cntr_e2_delay;
wire [31:0] cntr_e3_delay;
reg  [31:0] ext_fbk_delay;

// variables for clk_switch
reg clk0_is_bad, clk1_is_bad;
reg inclk0_last_value, inclk1_last_value;
reg other_clock_value;
reg other_clock_last_value;
reg primary_clk_is_bad;
reg current_clk_is_bad;
reg external_switch;
reg [8*6:1] current_clock;
reg active_clock;
reg clkloss_tmp;
reg got_curr_clk_falling_edge_after_clkswitch;
integer clk0_count, clk1_count, switch_over_count;
reg active_clk_was_switched;

reg do_pfd;

reg scandataout_tmp;
integer quiet_time;
reg pll_in_quiet_period;
time start_quiet_time;

// internal parameters
parameter EGPP_SCAN_CHAIN = 289;
parameter GPP_SCAN_CHAIN = 193;

// user to advanced internal signals

integer   i_m_initial;
integer   i_m;
integer   i_n;
integer   i_m2;
integer   i_n2;
integer   i_ss;
integer   i_l0_high;
integer   i_l1_high;
integer   i_g0_high;
integer   i_g1_high;
integer   i_g2_high;
integer   i_g3_high;
integer   i_e0_high;
integer   i_e1_high;
integer   i_e2_high;
integer   i_e3_high;
integer   i_l0_low;
integer   i_l1_low;
integer   i_g0_low;
integer   i_g1_low;
integer   i_g2_low;
integer   i_g3_low;
integer   i_e0_low;
integer   i_e1_low;
integer   i_e2_low;
integer   i_e3_low;
integer   i_l0_initial;
integer   i_l1_initial;
integer   i_g0_initial;
integer   i_g1_initial;
integer   i_g2_initial;
integer   i_g3_initial;
integer   i_e0_initial;
integer   i_e1_initial;
integer   i_e2_initial;
integer   i_e3_initial;
reg [8*6:1]   i_l0_mode;
reg [8*6:1]   i_l1_mode;
reg [8*6:1]   i_g0_mode;
reg [8*6:1]   i_g1_mode;
reg [8*6:1]   i_g2_mode;
reg [8*6:1]   i_g3_mode;
reg [8*6:1]   i_e0_mode;
reg [8*6:1]   i_e1_mode;
reg [8*6:1]   i_e2_mode;
reg [8*6:1]   i_e3_mode;
integer   i_vco_min;
integer   i_vco_max;
integer   i_vco_center;
integer   i_pfd_min;
integer   i_pfd_max;
integer   i_l0_ph;
integer   i_l1_ph;
integer   i_g0_ph;
integer   i_g1_ph;
integer   i_g2_ph;
integer   i_g3_ph;
integer   i_e0_ph;
integer   i_e1_ph;
integer   i_e2_ph;
integer   i_e3_ph;
integer   i_m_ph;
integer   m_ph_val;
integer   i_l0_time_delay;
integer   i_l1_time_delay;
integer   i_g0_time_delay;
integer   i_g1_time_delay;
integer   i_g2_time_delay;
integer   i_g3_time_delay;
integer   i_e0_time_delay;
integer   i_e1_time_delay;
integer   i_e2_time_delay;
integer   i_e3_time_delay;
integer   i_m_time_delay;
integer   i_n_time_delay;
integer   i_extclk3_counter;
integer   i_extclk2_counter;
integer   i_extclk1_counter;
integer   i_extclk0_counter;
integer   i_clk5_counter;
integer   i_clk4_counter;
integer   i_clk3_counter;
integer   i_clk2_counter;
integer   i_clk1_counter;
integer   i_clk0_counter;
integer   i_charge_pump_current;
integer   i_loop_filter_r;
integer   max_neg_abs;
integer   output_count;

real real_n;

// uppercase to lowercase parameter values
reg [8*`WORD_LENGTH:1] l_operation_mode;
reg [8*`WORD_LENGTH:1] l_pll_type;
reg [8*`WORD_LENGTH:1] l_qualify_conf_done;
reg [8*`WORD_LENGTH:1] l_compensate_clock;
reg [8*`WORD_LENGTH:1] l_scan_chain;
reg [8*`WORD_LENGTH:1] l_primary_clock;
reg [8*`WORD_LENGTH:1] l_gate_lock_signal;
reg [8*`WORD_LENGTH:1] l_switch_over_on_lossclk;
reg [8*`WORD_LENGTH:1] l_switch_over_on_gated_lock;
reg [8*`WORD_LENGTH:1] l_enable_switch_over_counter;
reg [8*`WORD_LENGTH:1] l_feedback_source;
reg [8*`WORD_LENGTH:1] l_bandwidth_type;
reg [8*`WORD_LENGTH:1] l_simulation_type;
reg [8*`WORD_LENGTH:1] l_source_is_pll;
reg [8*`WORD_LENGTH:1] l_enable0_counter;
reg [8*`WORD_LENGTH:1] l_enable1_counter;

specify
endspecify

// find twice the period of the slowest clock
function integer slowest_clk;
input L0, L1, G0, G1, G2, G3, E0, E1, E2, E3, scan_chain, refclk, m_mod;
integer L0, L1, G0, G1, G2, G3, E0, E1, E2, E3;
reg [8*5:1] scan_chain;
integer refclk;
reg [31:0] m_mod;
integer max_modulus;
begin
   if (L0 > L1) max_modulus = L0; else max_modulus = L1;
   if (G0 > max_modulus) max_modulus = G0;
   if (G1 > max_modulus) max_modulus = G1;
   if (G2 > max_modulus) max_modulus = G2;
   if (G3 > max_modulus) max_modulus = G3;
   if (scan_chain == "long")
   begin
      if (E0 > max_modulus) max_modulus = E0;
      if (E1 > max_modulus) max_modulus = E1;
      if (E2 > max_modulus) max_modulus = E2;
      if (E3 > max_modulus) max_modulus = E3;
   end

   slowest_clk = ((refclk/m_mod) * max_modulus *2);
end
endfunction

// find the greatest common denominator of X and Y
function integer gcd;
input X,Y;
integer X,Y;
integer L, S, R, G;
begin
    if (X < Y) // find which is smaller.
    begin
        S = X;
        L = Y;
    end
    else
    begin
        S = Y;
        L = X;
    end

    R = S;
    while ( R > 1)
    begin
        S = L;
        L = R;
        R = S % L; // divide bigger number by smaller.
                   // remainder becomes smaller number.
    end
    if (R == 0)    // if evenly divisible then L is gcd else it is 1.
        G = L;
    else
        G = R;
    gcd = G;
end
endfunction

// find the least common multiple of A1 to A10
function integer lcm;
input A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, P;
integer A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, P;
integer M1, M2, M3, M4, M5 , M6, M7, M8, M9, R;
begin
    M1 = (A1 * A2)/gcd(A1, A2);
    M2 = (M1 * A3)/gcd(M1, A3);
    M3 = (M2 * A4)/gcd(M2, A4);
    M4 = (M3 * A5)/gcd(M3, A5);
    M5 = (M4 * A6)/gcd(M4, A6);
    M6 = (M5 * A7)/gcd(M5, A7);
    M7 = (M6 * A8)/gcd(M6, A8);
    M8 = (M7 * A9)/gcd(M7, A9);
    M9 = (M8 * A10)/gcd(M8, A10);
    if (M9 < 3)
        R = 10;
    else if ((M9 < 10) && (M9 > 3))
        R = 4 * M9;
    else
        R = M9;
    lcm = R; 
end
endfunction

// find the factor of division of the output clock frequency compared to the VCO
function integer output_counter_value;
input clk_divide, clk_mult, M, N;
integer clk_divide, clk_mult, M, N;
integer R;
begin
        R = (clk_divide * M)/(clk_mult * N);
        output_counter_value = R;
end
endfunction

// find the mode of each of the PLL counters - bypass, even or odd
function [8*6:1] counter_mode;
input duty_cycle;
input output_counter_value;
integer duty_cycle;
integer output_counter_value;
integer half_cycle_high;
reg [8*6:1] R;
begin
        half_cycle_high = 2*duty_cycle*output_counter_value/100;
        if (output_counter_value == 1)
                R = "bypass";
        else if ((half_cycle_high % 2) == 0)
                R = "even";
        else
                R = "odd";
        counter_mode = R;
end
endfunction

// find the number of VCO clock cycles to hold the output clock high
function integer counter_high;
input output_counter_value, duty_cycle;
integer output_counter_value, duty_cycle;
integer half_cycle_high;
integer tmp_counter_high;
integer mode;
begin
    half_cycle_high = 2*duty_cycle*output_counter_value/100;
    mode = ((half_cycle_high % 2) == 0);
    tmp_counter_high = half_cycle_high/2;
    counter_high = tmp_counter_high + !mode;
end
endfunction

// find the number of VCO clock cycles to hold the output clock low
function integer counter_low;
input output_counter_value, duty_cycle;
integer output_counter_value, duty_cycle, counter_h;
integer half_cycle_high;
integer mode;
integer tmp_counter_high;
begin
    half_cycle_high = 2*duty_cycle*output_counter_value/100;
    mode = ((half_cycle_high % 2) == 0);
    tmp_counter_high = half_cycle_high/2;
    counter_h = tmp_counter_high + !mode;
    counter_low =  output_counter_value - counter_h;
end
endfunction

// find the smallest time delay amongst t1 to t10
function integer mintimedelay;
input t1, t2, t3, t4, t5, t6, t7, t8, t9, t10;
integer t1, t2, t3, t4, t5, t6, t7, t8, t9, t10;
integer m1,m2,m3,m4,m5,m6,m7,m8,m9;
begin
    if (t1 < t2) m1 = t1; else m1 = t2;
    if (m1 < t3) m2 = m1; else m2 = t3;
    if (m2 < t4) m3 = m2; else m3 = t4;
    if (m3 < t5) m4 = m3; else m4 = t5;
    if (m4 < t6) m5 = m4; else m5 = t6;
    if (m5 < t7) m6 = m5; else m6 = t7;
    if (m6 < t8) m7 = m6; else m7 = t8;
    if (m7 < t9) m8 = m7; else m8 = t9;
    if (m8 < t10) m9 = m8; else m9 = t10;
    if (m9 > 0) mintimedelay = m9; else mintimedelay = 0;
end
endfunction

// find the numerically largest negative number, and return its absolute value
function integer maxnegabs;
input t1, t2, t3, t4, t5, t6, t7, t8, t9, t10;
integer t1, t2, t3, t4, t5, t6, t7, t8, t9, t10;
integer m1,m2,m3,m4,m5,m6,m7,m8,m9;
begin
    if (t1 < t2) m1 = t1; else m1 = t2;
    if (m1 < t3) m2 = m1; else m2 = t3;
    if (m2 < t4) m3 = m2; else m3 = t4;
    if (m3 < t5) m4 = m3; else m4 = t5;
    if (m4 < t6) m5 = m4; else m5 = t6;
    if (m5 < t7) m6 = m5; else m6 = t7;
    if (m6 < t8) m7 = m6; else m7 = t8;
    if (m7 < t9) m8 = m7; else m8 = t9;
    if (m8 < t10) m9 = m8; else m9 = t10;
    maxnegabs = (m9 < 0) ? 0 - m9 : 0;
end
endfunction

// adjust the given tap_phase by adding the largest negative number (ph_base) 
function integer ph_adjust;
input tap_phase, ph_base;
integer tap_phase, ph_base;
begin
    ph_adjust = tap_phase + ph_base;
end
endfunction

// find the actual time delay for each PLL counter
function integer counter_time_delay;
input clk_time_delay, m_time_delay, n_time_delay;
integer clk_time_delay, m_time_delay, n_time_delay;
begin
    counter_time_delay = clk_time_delay + m_time_delay - n_time_delay;
end
endfunction

// find the number of VCO clock cycles to wait initially before the first 
// rising edge of the output clock
function integer counter_initial;
input tap_phase, m, n;
integer tap_phase, m, n, phase;
begin
    if (tap_phase < 0) tap_phase = 0 - tap_phase;
    // adding 0.5 for rounding correction (required in order to round to the 
    // nearest integer instead of truncating)
    phase = ((tap_phase * m) / (360 * n)) + 0.5;
    counter_initial = phase + 1;
end
endfunction

// find which VCO phase tap to align the rising edge of the output clock to
function integer counter_ph;
input tap_phase;
input m,n;
integer m,n, phase;
integer tap_phase;
begin
// adding 0.5 for rounding correction
    phase = (tap_phase * m / n) + 0.5;
    counter_ph = (phase % 360)/45;
end
endfunction

// convert the given string to length 6 by padding with spaces
function [8*6:1] translate_string;
input mode;
reg [8*6:1] new_mode;
begin
    if (mode == "bypass")
       new_mode = "bypass";
    else if (mode == "even")
        new_mode = "  even";
    else if (mode == "odd")
        new_mode = "   odd";

    translate_string = new_mode;
end
endfunction

// convert string to integer with sign
function integer str2int; 
input [8*16:1] s;

reg [8*16:1] reg_s;
reg [8:1] digit;
reg [8:1] tmp;
integer m, magnitude;
integer sign;

begin
    sign = 1;
    magnitude = 0;
    reg_s = s;
    for (m=1; m<=16; m=m+1)
    begin
        tmp = reg_s[128:121];
        digit = tmp & 8'b00001111;
        reg_s = reg_s << 8;
        // Accumulate ascii digits 0-9 only.
        if ((tmp>=48) && (tmp<=57)) 
            magnitude = magnitude * 10 + digit;
        if (tmp == 45)
            sign = -1;  // Found a '-' character, i.e. number is negative.
    end
    str2int = sign*magnitude;
end
endfunction

// this is for stratix lvds only
// convert phase delay to integer
function integer get_int_phase_shift; 
input [8*16:1] s;
input i_phase_shift;
integer i_phase_shift;

begin
    if (i_phase_shift != 0)
        begin                   
            get_int_phase_shift = i_phase_shift;
        end       
        else
        begin
            get_int_phase_shift = str2int(s);
        end        
end
endfunction

// calculate the given phase shift (in ps) in terms of degrees
function integer get_phase_degree; 
input phase_shift;
integer phase_shift, result;
begin
    result = (phase_shift * 360) / inclk0_input_frequency;
    // this is to round up the calculation result
    if ( result > 0 )
        result = result + 1;
    else if ( result < 0 )
        result = result - 1;
    else
        result = 0;

    // assign the rounded up result
    get_phase_degree = result;
end
endfunction

// convert uppercase parameter values to lowercase
// assumes that the maximum character length of a parameter is 18
function [8*`WORD_LENGTH:1] alpha_tolower;
input [8*`WORD_LENGTH:1] given_string;

reg [8*`WORD_LENGTH:1] return_string;
reg [8*`WORD_LENGTH:1] reg_string;
reg [8:1] tmp;
reg [8:1] conv_char;
integer byte_count;
begin
    return_string = "                    "; // initialise strings to spaces
    conv_char = "        ";
    reg_string = given_string;
    for (byte_count = `WORD_LENGTH; byte_count >= 1; byte_count = byte_count - 1)
    begin
        tmp = reg_string[8*`WORD_LENGTH:(8*(`WORD_LENGTH-1)+1)];
        reg_string = reg_string << 8;
        if ((tmp >= 65) && (tmp <= 90)) // ASCII number of 'A' is 65, 'Z' is 90
        begin
            conv_char = tmp + 32; // 32 is the difference in the position of 'A' and 'a' in the ASCII char set
            return_string = {return_string, conv_char};
        end
        else
            return_string = {return_string, tmp};
    end
    
    alpha_tolower = return_string;
end
endfunction

initial
begin

    // convert string parameter values from uppercase to lowercase, as expected
    // in this model
    l_operation_mode             = alpha_tolower(operation_mode);
    l_pll_type                   = alpha_tolower(pll_type);
    l_qualify_conf_done          = alpha_tolower(qualify_conf_done);
    l_compensate_clock           = alpha_tolower(compensate_clock);
    l_scan_chain                 = alpha_tolower(scan_chain);
    l_primary_clock              = alpha_tolower(primary_clock);
    l_gate_lock_signal           = alpha_tolower(gate_lock_signal);
    l_switch_over_on_lossclk     = alpha_tolower(switch_over_on_lossclk);
    l_switch_over_on_gated_lock  = alpha_tolower(switch_over_on_gated_lock);
    l_enable_switch_over_counter = alpha_tolower(enable_switch_over_counter);
    l_feedback_source            = alpha_tolower(feedback_source);
    l_bandwidth_type             = alpha_tolower(bandwidth_type);
    l_simulation_type            = alpha_tolower(simulation_type);
    l_source_is_pll              = alpha_tolower(source_is_pll);
    l_enable0_counter            = alpha_tolower(enable0_counter);
    l_enable1_counter            = alpha_tolower(enable1_counter);

    if (m == 0) begin  // convert user parameters to advanced
        i_n = 1;
        i_m = lcm (clk0_multiply_by, clk1_multiply_by,
                   clk2_multiply_by, clk3_multiply_by,
                   clk4_multiply_by, clk5_multiply_by,
                   extclk0_multiply_by,
                   extclk1_multiply_by, extclk2_multiply_by,
                   extclk3_multiply_by, inclk0_input_frequency);
        i_m_time_delay = maxnegabs(str2int(clk0_time_delay),
                                 str2int(clk1_time_delay),
                                 str2int(clk2_time_delay),
                                 str2int(clk3_time_delay),
                                 str2int(clk4_time_delay),
                                 str2int(clk5_time_delay),
                                 str2int(extclk0_time_delay),
                                 str2int(extclk1_time_delay),
                                 str2int(extclk2_time_delay),
                                 str2int(extclk3_time_delay));
        i_n_time_delay = mintimedelay(str2int(clk0_time_delay),
                                 str2int(clk1_time_delay),
                                 str2int(clk2_time_delay),
                                 str2int(clk3_time_delay),
                                 str2int(clk4_time_delay),
                                 str2int(clk5_time_delay),
                                 str2int(extclk0_time_delay),
                                 str2int(extclk1_time_delay),
                                 str2int(extclk2_time_delay),
                                 str2int(extclk3_time_delay));
        i_g0_high = counter_high(output_counter_value(clk0_divide_by,
                    clk0_multiply_by, i_m, i_n), clk0_duty_cycle);
        i_g1_high = counter_high(output_counter_value(clk1_divide_by,
                    clk1_multiply_by, i_m, i_n), clk1_duty_cycle);
        i_g2_high = counter_high(output_counter_value(clk2_divide_by,
                    clk2_multiply_by, i_m, i_n), clk2_duty_cycle);
        i_g3_high = counter_high(output_counter_value(clk3_divide_by,
                    clk3_multiply_by, i_m, i_n), clk3_duty_cycle);
        i_l0_high = counter_high(output_counter_value(clk4_divide_by,
                    clk4_multiply_by,  i_m, i_n), clk4_duty_cycle);
        i_l1_high = counter_high(output_counter_value(clk5_divide_by,
                    clk5_multiply_by,  i_m, i_n), clk5_duty_cycle);
        i_e0_high = counter_high(output_counter_value(extclk0_divide_by,
                    extclk0_multiply_by,  i_m, i_n), extclk0_duty_cycle);
        i_e1_high = counter_high(output_counter_value(extclk1_divide_by,
                    extclk1_multiply_by,  i_m, i_n), extclk1_duty_cycle);
        i_e2_high = counter_high(output_counter_value(extclk2_divide_by,
                    extclk2_multiply_by,  i_m, i_n), extclk2_duty_cycle);
        i_e3_high = counter_high(output_counter_value(extclk3_divide_by,
                    extclk3_multiply_by,  i_m, i_n), extclk3_duty_cycle);
        i_g0_low  = counter_low(output_counter_value(clk0_divide_by,
                    clk0_multiply_by,  i_m, i_n), clk0_duty_cycle);
        i_g1_low  = counter_low(output_counter_value(clk1_divide_by,
                    clk1_multiply_by,  i_m, i_n), clk1_duty_cycle);
        i_g2_low  = counter_low(output_counter_value(clk2_divide_by,
                    clk2_multiply_by,  i_m, i_n), clk2_duty_cycle);
        i_g3_low  = counter_low(output_counter_value(clk3_divide_by,
                    clk3_multiply_by,  i_m, i_n), clk3_duty_cycle);
        i_l0_low  = counter_low(output_counter_value(clk4_divide_by,
                    clk4_multiply_by,  i_m, i_n), clk4_duty_cycle);
        i_l1_low  = counter_low(output_counter_value(clk5_divide_by,
                    clk5_multiply_by,  i_m, i_n), clk5_duty_cycle);
        i_e0_low  = counter_low(output_counter_value(extclk0_divide_by,
                    extclk0_multiply_by,  i_m, i_n), extclk0_duty_cycle);
        i_e1_low  = counter_low(output_counter_value(extclk1_divide_by,
                    extclk1_multiply_by,  i_m, i_n), extclk1_duty_cycle);
        i_e2_low  = counter_low(output_counter_value(extclk2_divide_by,
                    extclk2_multiply_by,  i_m, i_n), extclk2_duty_cycle);
        i_e3_low  = counter_low(output_counter_value(extclk3_divide_by,
                    extclk3_multiply_by,  i_m, i_n), extclk3_duty_cycle);
        max_neg_abs = maxnegabs( get_int_phase_shift(clk0_phase_shift, clk0_phase_shift_num),
                                 get_int_phase_shift(clk1_phase_shift, clk1_phase_shift_num),
                                 get_int_phase_shift(clk2_phase_shift, clk2_phase_shift_num),
                                 str2int(clk3_phase_shift),
                                 str2int(clk4_phase_shift),
                                 str2int(clk5_phase_shift),
                                 str2int(extclk0_phase_shift),
                                 str2int(extclk1_phase_shift),
                                 str2int(extclk2_phase_shift),
                                 str2int(extclk3_phase_shift));
        i_g0_initial = counter_initial(get_phase_degree(ph_adjust(get_int_phase_shift(clk0_phase_shift, clk0_phase_shift_num), max_neg_abs)), i_m, i_n);
        i_g1_initial = counter_initial(get_phase_degree(ph_adjust(get_int_phase_shift(clk1_phase_shift, clk1_phase_shift_num), max_neg_abs)), i_m, i_n);
        i_g2_initial = counter_initial(get_phase_degree(ph_adjust(get_int_phase_shift(clk2_phase_shift, clk2_phase_shift_num), max_neg_abs)), i_m, i_n);
        i_g3_initial = counter_initial(get_phase_degree(ph_adjust(str2int(clk3_phase_shift), max_neg_abs)), i_m, i_n);
        i_l0_initial = counter_initial(get_phase_degree(ph_adjust(str2int(clk4_phase_shift), max_neg_abs)), i_m, i_n);
        i_l1_initial = counter_initial(get_phase_degree(ph_adjust(str2int(clk5_phase_shift), max_neg_abs)), i_m, i_n);
        i_e0_initial = counter_initial(get_phase_degree(ph_adjust(str2int(extclk0_phase_shift), max_neg_abs)), i_m, i_n);
        i_e1_initial = counter_initial(get_phase_degree(ph_adjust(str2int(extclk1_phase_shift), max_neg_abs)), i_m, i_n);
        i_e2_initial = counter_initial(get_phase_degree(ph_adjust(str2int(extclk2_phase_shift), max_neg_abs)), i_m, i_n);
        i_e3_initial = counter_initial(get_phase_degree(ph_adjust(str2int(extclk3_phase_shift), max_neg_abs)), i_m, i_n);
        i_g0_mode = counter_mode(clk0_duty_cycle, output_counter_value(clk0_divide_by, clk0_multiply_by,  i_m, i_n));
        i_g1_mode = counter_mode(clk1_duty_cycle,output_counter_value(clk1_divide_by, clk1_multiply_by,  i_m, i_n));
        i_g2_mode = counter_mode(clk2_duty_cycle,output_counter_value(clk2_divide_by, clk2_multiply_by,  i_m, i_n));
        i_g3_mode = counter_mode(clk3_duty_cycle,output_counter_value(clk3_divide_by, clk3_multiply_by,  i_m, i_n));
        i_l0_mode = counter_mode(clk4_duty_cycle,output_counter_value(clk4_divide_by, clk4_multiply_by,  i_m, i_n));
        i_l1_mode = counter_mode(clk5_duty_cycle,output_counter_value(clk5_divide_by, clk5_multiply_by,  i_m, i_n));
        i_e0_mode = counter_mode(extclk0_duty_cycle,output_counter_value(extclk0_divide_by, extclk0_multiply_by,  i_m, i_n));
        i_e1_mode = counter_mode(extclk1_duty_cycle,output_counter_value(extclk1_divide_by, extclk1_multiply_by,  i_m, i_n));
        i_e2_mode = counter_mode(extclk2_duty_cycle,output_counter_value(extclk2_divide_by, extclk2_multiply_by,  i_m, i_n));
        i_e3_mode = counter_mode(extclk3_duty_cycle,output_counter_value(extclk3_divide_by, extclk3_multiply_by,  i_m, i_n));
        i_m_ph    = counter_ph(get_phase_degree(max_neg_abs), i_m, i_n);
        i_m_initial = counter_initial(get_phase_degree(max_neg_abs), i_m, i_n);
        i_g0_ph = counter_ph(get_phase_degree(ph_adjust(get_int_phase_shift(clk0_phase_shift, clk0_phase_shift_num),max_neg_abs)), i_m, i_n);
        i_g1_ph = counter_ph(get_phase_degree(ph_adjust(get_int_phase_shift(clk1_phase_shift, clk1_phase_shift_num),max_neg_abs)), i_m, i_n);
        i_g2_ph = counter_ph(get_phase_degree(ph_adjust(get_int_phase_shift(clk2_phase_shift, clk2_phase_shift_num),max_neg_abs)), i_m, i_n);
        i_g3_ph = counter_ph(get_phase_degree(ph_adjust(str2int(clk3_phase_shift),max_neg_abs)), i_m, i_n);
        i_l0_ph = counter_ph(get_phase_degree(ph_adjust(str2int(clk4_phase_shift),max_neg_abs)), i_m, i_n);
        i_l1_ph = counter_ph(get_phase_degree(ph_adjust(str2int(clk5_phase_shift),max_neg_abs)), i_m, i_n);
        i_e0_ph = counter_ph(get_phase_degree(ph_adjust(str2int(extclk0_phase_shift),max_neg_abs)), i_m, i_n);
        i_e1_ph = counter_ph(get_phase_degree(ph_adjust(str2int(extclk1_phase_shift),max_neg_abs)), i_m, i_n);
        i_e2_ph = counter_ph(get_phase_degree(ph_adjust(str2int(extclk2_phase_shift),max_neg_abs)), i_m, i_n);
        i_e3_ph = counter_ph(get_phase_degree(ph_adjust(str2int(extclk3_phase_shift),max_neg_abs)), i_m, i_n);

        i_g0_time_delay = counter_time_delay(str2int(clk0_time_delay),
                                             i_m_time_delay, i_n_time_delay) ;
        i_g1_time_delay = counter_time_delay(str2int(clk1_time_delay),
                                             i_m_time_delay, i_n_time_delay) ;
        i_g2_time_delay = counter_time_delay(str2int(clk2_time_delay),
                                             i_m_time_delay, i_n_time_delay) ;
        i_g3_time_delay = counter_time_delay(str2int(clk3_time_delay),
                                             i_m_time_delay, i_n_time_delay) ;
        i_l0_time_delay = counter_time_delay(str2int(clk4_time_delay),
                                             i_m_time_delay, i_n_time_delay) ;
        i_l1_time_delay = counter_time_delay(str2int(clk5_time_delay),
                                             i_m_time_delay, i_n_time_delay) ;
        i_e0_time_delay = counter_time_delay(str2int(extclk0_time_delay),
                                             i_m_time_delay, i_n_time_delay) ;
        i_e1_time_delay = counter_time_delay(str2int(extclk1_time_delay),
                                             i_m_time_delay, i_n_time_delay) ;
        i_e2_time_delay = counter_time_delay(str2int(extclk2_time_delay),
                                             i_m_time_delay, i_n_time_delay) ;
        i_e3_time_delay = counter_time_delay(str2int(extclk3_time_delay),
                                             i_m_time_delay, i_n_time_delay) ;
        i_extclk3_counter = "e3" ;
        i_extclk2_counter = "e2" ;
        i_extclk1_counter = "e1" ;
        i_extclk0_counter = "e0" ;
        i_clk5_counter    = "l1" ;
        i_clk4_counter    = "l0" ;
        i_clk3_counter    = "g3" ;
        i_clk2_counter    = "g2" ;
        i_clk1_counter    = "g1" ;
        i_clk0_counter    = "g0" ;

        // in external feedback mode, need to adjust M value to take into
        // consideration the external feedback counter value
        if (l_operation_mode == "external_feedback")
        begin
            // if there is a negative phase shift, m_initial can only be 1
            if (max_neg_abs > 0)
                i_m_initial = 1;

            if (l_feedback_source == "extclk0")
            begin
                if (i_e0_mode == "bypass")
                    output_count = 1;
                else
                    output_count = i_e0_high + i_e0_low;
            end
            else if (l_feedback_source == "extclk1")
            begin
                if (i_e1_mode == "bypass")
                    output_count = 1;
                else
                    output_count = i_e1_high + i_e1_low;
            end
            else if (l_feedback_source == "extclk2")
            begin
                if (i_e2_mode == "bypass")
                    output_count = 1;
                else
                    output_count = i_e2_high + i_e2_low;
            end
            else if (l_feedback_source == "extclk3")
            begin
                if (i_e3_mode == "bypass")
                    output_count = 1;
                else
                    output_count = i_e3_high + i_e3_low;
            end
            else // default to e0
            begin
                if (i_e0_mode == "bypass")
                    output_count = 1;
                else
                    output_count = i_e0_high + i_e0_low;
            end

            i_m = i_m / output_count;
        end

     end
     else 
     begin //  m != 0

        i_n = n;
        i_m = m;
        i_l0_high = l0_high;
        i_l1_high = l1_high;
        i_g0_high = g0_high;
        i_g1_high = g1_high;
        i_g2_high = g2_high;
        i_g3_high = g3_high;
        i_e0_high = e0_high;
        i_e1_high = e1_high;
        i_e2_high = e2_high;
        i_e3_high = e3_high;
        i_l0_low  = l0_low;
        i_l1_low  = l1_low;
        i_g0_low  = g0_low;
        i_g1_low  = g1_low;
        i_g2_low  = g2_low;
        i_g3_low  = g3_low;
        i_e0_low  = e0_low;
        i_e1_low  = e1_low;
        i_e2_low  = e2_low;
        i_e3_low  = e3_low;
        i_l0_initial = l0_initial;
        i_l1_initial = l1_initial;
        i_g0_initial = g0_initial;
        i_g1_initial = g1_initial;
        i_g2_initial = g2_initial;
        i_g3_initial = g3_initial;
        i_e0_initial = e0_initial;
        i_e1_initial = e1_initial;
        i_e2_initial = e2_initial;
        i_e3_initial = e3_initial;
        i_l0_mode = alpha_tolower(l0_mode);
        i_l1_mode = alpha_tolower(l1_mode);
        i_g0_mode = alpha_tolower(g0_mode);
        i_g1_mode = alpha_tolower(g1_mode);
        i_g2_mode = alpha_tolower(g2_mode);
        i_g3_mode = alpha_tolower(g3_mode);
        i_e0_mode = alpha_tolower(e0_mode);
        i_e1_mode = alpha_tolower(e1_mode);
        i_e2_mode = alpha_tolower(e2_mode);
        i_e3_mode = alpha_tolower(e3_mode);
        i_l0_ph  = l0_ph;
        i_l1_ph  = l1_ph;
        i_g0_ph  = g0_ph;
        i_g1_ph  = g1_ph;
        i_g2_ph  = g2_ph;
        i_g3_ph  = g3_ph;
        i_e0_ph  = e0_ph;
        i_e1_ph  = e1_ph;
        i_e2_ph  = e2_ph;
        i_e3_ph  = e3_ph;
        i_m_ph   = m_ph;        // default
        i_m_initial = m_initial;
        i_l0_time_delay = l0_time_delay;
        i_l1_time_delay = l1_time_delay;
        i_g0_time_delay = g0_time_delay;
        i_g1_time_delay = g1_time_delay;
        i_g2_time_delay = g2_time_delay;
        i_g3_time_delay = g3_time_delay;
        i_e0_time_delay = e0_time_delay;
        i_e1_time_delay = e1_time_delay;
        i_e2_time_delay = e2_time_delay;
        i_e3_time_delay = e3_time_delay;
        i_m_time_delay  = m_time_delay;
        i_n_time_delay  = n_time_delay;
        i_extclk3_counter = alpha_tolower(extclk3_counter);
        i_extclk2_counter = alpha_tolower(extclk2_counter);
        i_extclk1_counter = alpha_tolower(extclk1_counter);
        i_extclk0_counter = alpha_tolower(extclk0_counter);
        i_clk5_counter    = alpha_tolower(clk5_counter);
        i_clk4_counter    = alpha_tolower(clk4_counter);
        i_clk3_counter    = alpha_tolower(clk3_counter);
        i_clk2_counter    = alpha_tolower(clk2_counter);
        i_clk1_counter    = alpha_tolower(clk1_counter);
        i_clk0_counter    = alpha_tolower(clk0_counter);

     end // user to advanced conversion

   // set the scan_chain length
   if (l_scan_chain == "long")
      scan_chain_length = EGPP_SCAN_CHAIN;
   else if (l_scan_chain == "short")
      scan_chain_length = GPP_SCAN_CHAIN;

   m_times_vco_period = inclk0_input_frequency * n;

   refclk_period = inclk0_input_frequency * n;
   high_time = 0;
   low_time = 0;
   schedule_from_refclk = 0;
   reschedule_from_fbclk = 0;
   schedule_vco = 0;
   schedule_zero = 0;
   do_not_add_high_time = 0;
   cycles_to_lock = 0;
   cycles_to_unlock = 0;
   pll_lock = 0;
   pll_about_to_lock = 0;
   vco_out[7:0] = 8'b0;
   fbclk_last_value = 0;
   refclk_last_value = 0;
   offset = 0;
   temp_offset = 0;
   refclk_got_first_rising_edge = 0;
   fbclk_got_first_rising_edge = 0;
   fbclk_got_second_rising_edge = 0;
   fbclk_last_rising_edge = 0;
   refclk_last_rising_edge = 0;
   got_refclk_rising_edge = 0;
   got_fbclk_rising_edge = 0;
   refclk_tmp = 0;
   fbclk_tmp = 0;
   first_schedule = 1;
   fbclk_is_in_phase_with_refclk = 0;
   reset_vco = 0;
   sched_time = 0;
   total_sched_time = 0;
   vco_val = 0;
   vco_val_last_value = 0;
   l0_got_first_rising_edge = 0;
   l1_got_first_rising_edge = 0;
   vco_l0_last_value = 0;
   l0_count = 1;
   l1_count = 1;
   l0_tmp = 0;
   l1_tmp = 0;
   gate_count = 0;
   gate_out = 0;
   m_reset = 0;
   cntr_reset_1 = 0;
   cntr_reset_2 = 0;
   initial_value_to_delay = 0;
   fbk_phase = 0;
   for (i = 0; i <= 7; i = i + 1)
      phase_shift[i] = 0;
   fbk_delay = 0;
   inclk_n = 0;
   l = 1;
   cycle_to_adjust = 0;
   m_delay = 0;
   nce_l0_fast = 0;
   vco_l0 = 0;
   nce_l1_fast = 0;
   vco_l1 = 0;
   dffa_out_dly = 0;
   lvds_dffb_clk_dly = 0;
   do_pfd = 0;
   total_pull_back = 0;
   pull_back_M = 0;
   pull_back_ext_fbk_cntr = 0;

   scandataout_tmp = 0;

   // set initial values for counter parameters
   m_initial_val = i_m_initial;
   m_val = i_m;
   m_time_delay_val = i_m_time_delay;
   n_val = i_n;
   n_time_delay_val = i_n_time_delay;
   m_ph_val = i_m_ph;

   l0_high_val = i_l0_high;
   l0_low_val = i_l0_low;
   l0_initial_val = i_l0_initial;
   l0_mode_val = i_l0_mode;
   l0_time_delay_val = i_l0_time_delay;

   l1_high_val = i_l1_high;
   l1_low_val = i_l1_low;
   l1_initial_val = i_l1_initial;
   l1_mode_val = i_l1_mode;
   l1_time_delay_val = i_l1_time_delay;

   g0_high_val = i_g0_high;
   g0_low_val = i_g0_low;
   g0_initial_val = i_g0_initial;
   g0_mode_val = i_g0_mode;
   g0_time_delay_val = i_g0_time_delay;

   g1_high_val = i_g1_high;
   g1_low_val = i_g1_low;
   g1_initial_val = i_g1_initial;
   g1_mode_val = i_g1_mode;
   g1_time_delay_val = i_g1_time_delay;

   g2_high_val = i_g2_high;
   g2_low_val = i_g2_low;
   g2_initial_val = i_g2_initial;
   g2_mode_val = i_g2_mode;
   g2_time_delay_val = i_g2_time_delay;

   g3_high_val = i_g3_high;
   g3_low_val = i_g3_low;
   g3_initial_val = i_g3_initial;
   g3_mode_val = i_g3_mode;
   g3_time_delay_val = i_g3_time_delay;

   e0_high_val = i_e0_high;
   e0_low_val = i_e0_low;
   e0_initial_val = i_e0_initial;
   e0_mode_val = i_e0_mode;
   e0_time_delay_val = i_e0_time_delay;

   e1_high_val = i_e1_high;
   e1_low_val = i_e1_low;
   e1_initial_val = i_e1_initial;
   e1_mode_val = i_e1_mode;
   e1_time_delay_val = i_e1_time_delay;

   e2_high_val = i_e2_high;
   e2_low_val = i_e2_low;
   e2_initial_val = i_e2_initial;
   e2_mode_val = i_e2_mode;
   e2_time_delay_val = i_e2_time_delay;

   e3_high_val = i_e3_high;
   e3_low_val = i_e3_low;
   e3_initial_val = i_e3_initial;
   e3_mode_val = i_e3_mode;
   e3_time_delay_val = i_e3_time_delay;

   i = 0;
   j = 0;
   inclk_last_value = 0;

   ext_fbk_cntr_ph = 0;
   ext_fbk_cntr_initial = 1;

   // initialize clkswitch variables

   clk0_is_bad = 0;
   clk1_is_bad = 0;
   inclk0_last_value = 0;
   inclk1_last_value = 0;
   other_clock_value = 0;
   other_clock_last_value = 0;
   primary_clk_is_bad = 0;
   current_clk_is_bad = 0;
   external_switch = 0;
   current_clock = l_primary_clock;
   if (l_primary_clock == "inclk0")
      active_clock = 0;
   else
      active_clock = 1;
   clkloss_tmp = 0;
   got_curr_clk_falling_edge_after_clkswitch = 0;
   clk0_count = 0;
   clk1_count = 0;
   switch_over_count = 0;
   active_clk_was_switched = 0;

   // initialize quiet_time
   quiet_time = slowest_clk(l0_high_val+l0_low_val,
                            l1_high_val+l1_low_val,
                            g0_high_val+g0_low_val,
                            g1_high_val+g1_low_val,
                            g2_high_val+g2_low_val,
                            g3_high_val+g3_low_val,
                            e0_high_val+e0_low_val,
                            e1_high_val+e1_low_val,
                            e2_high_val+e2_low_val,
                            e3_high_val+e3_low_val,
                            l_scan_chain,
                            refclk_period, m_val);
   pll_in_quiet_period = 0;
   start_quiet_time = 0; 

   // VCO settings for external feedback mode
   if (l_operation_mode == "external_feedback")
   begin
      if (l_feedback_source == "extclk0")
      begin
         if (i_extclk0_counter == "e0")
             ext_fbk_cntr = "e0";
         else if (i_extclk0_counter == "e1")
             ext_fbk_cntr = "e1";
         else if (i_extclk0_counter == "e2")
             ext_fbk_cntr = "e2";
         else if (i_extclk0_counter == "e3")
             ext_fbk_cntr = "e3";
         else ext_fbk_cntr = "e0";
      end
      else if (l_feedback_source == "extclk1")
      begin
         if (i_extclk1_counter == "e0")
             ext_fbk_cntr = "e0";
         else if (i_extclk1_counter == "e1")
             ext_fbk_cntr = "e1";
         else if (i_extclk1_counter == "e2")
             ext_fbk_cntr = "e2";
         else if (i_extclk1_counter == "e3")
             ext_fbk_cntr = "e3";
         else ext_fbk_cntr = "e0";
      end
      else if (l_feedback_source == "extclk2")
      begin
         if (i_extclk2_counter == "e0")
             ext_fbk_cntr = "e0";
         else if (i_extclk2_counter == "e1")
             ext_fbk_cntr = "e1";
         else if (i_extclk2_counter == "e2")
             ext_fbk_cntr = "e2";
         else if (i_extclk2_counter == "e3")
             ext_fbk_cntr = "e3";
         else ext_fbk_cntr = "e0";
      end
      else if (l_feedback_source == "extclk3")
      begin
         if (i_extclk3_counter == "e0")
             ext_fbk_cntr = "e0";
         else if (i_extclk3_counter == "e1")
             ext_fbk_cntr = "e1";
         else if (i_extclk3_counter == "e2")
             ext_fbk_cntr = "e2";
         else if (i_extclk3_counter == "e3")
             ext_fbk_cntr = "e3";
         else ext_fbk_cntr = "e0";
      end

      if (ext_fbk_cntr == "e0")
         ext_fbk_cntr_ph = i_e0_ph;
      else if (ext_fbk_cntr == "e1")
         ext_fbk_cntr_ph = i_e1_ph;
      else if (ext_fbk_cntr == "e2")
         ext_fbk_cntr_ph = i_e2_ph;
      else if (ext_fbk_cntr == "e3")
         ext_fbk_cntr_ph = i_e3_ph;

      if (ext_fbk_cntr == "e0")
         ext_fbk_cntr_initial = i_e0_initial;
      else if (ext_fbk_cntr == "e1")
         ext_fbk_cntr_initial = i_e1_initial;
      else if (ext_fbk_cntr == "e2")
         ext_fbk_cntr_initial = i_e2_initial;
      else if (ext_fbk_cntr == "e3")
         ext_fbk_cntr_initial = i_e3_initial;
   end
end

assign inclk_m = l_operation_mode == "external_feedback" ? (l_feedback_source == "extclk0" ? extclk0_tmp :
                 l_feedback_source == "extclk1" ? extclk1_tmp :
                 l_feedback_source == "extclk2" ? extclk2_tmp :
                 l_feedback_source == "extclk3" ? extclk3_tmp : 'b0) :
                 fbclk_is_in_phase_with_refclk == 1'b1 ? vco_out[m_ph_val] : vco_out[0];

assign ext_fbk_cntr_high = ext_fbk_cntr == "e0" ? e0_high_val : 
                           ext_fbk_cntr == "e1" ? e1_high_val :
                           ext_fbk_cntr == "e2" ? e2_high_val : 
                           ext_fbk_cntr == "e3" ? e3_high_val : 1;

assign ext_fbk_cntr_low = ext_fbk_cntr == "e0" ? e0_low_val :
                          ext_fbk_cntr == "e1" ? e1_low_val :
                          ext_fbk_cntr == "e2" ? e2_low_val : 
                          ext_fbk_cntr == "e3" ? e3_low_val : 1;

assign ext_fbk_cntr_delay = ext_fbk_cntr == "e0" ? e0_time_delay_val :
                            ext_fbk_cntr == "e1" ? e1_time_delay_val :
                            ext_fbk_cntr == "e2" ? e2_time_delay_val :
                            ext_fbk_cntr == "e3" ? e3_time_delay_val : 0;

m_cntr m1 (.clk(inclk_m),
            .reset(areset_ipd || m_reset),
            .cout(fbclk),
            .initial_value(m_initial_val),
            .modulus(m_val),
            .time_delay(m_delay));

always @(clkswitch_ipd)
begin
   if (clkswitch_ipd == 1'b1)
      external_switch = 1;
end

always @(inclk0_ipd or inclk1_ipd)
begin
  // save the inclk event value
   if (inclk0_ipd != inclk0_last_value)
   begin
      if (current_clock !== "inclk0")
          other_clock_value = inclk0_ipd;
   end
   if (inclk1_ipd != inclk1_last_value)
   begin
      if (current_clock !== "inclk1")
          other_clock_value = inclk1_ipd;
   end

   // check if either input clk is bad
   if (inclk0_ipd == 1'b1 && inclk0_ipd != inclk0_last_value)
   begin
      clk0_count = clk0_count + 1;
      clk0_is_bad = 0;
      clk1_count = 0;
      if (clk0_count > 2)
      begin
         // no event on other clk for 2 cycles
         clk1_is_bad = 1;
         if (current_clock == "inclk1")
            current_clk_is_bad = 1;
      end
   end
   if (inclk1_ipd == 1'b1 && inclk1_ipd != inclk1_last_value)
   begin
      clk1_count = clk1_count + 1;
      clk1_is_bad = 0;
      clk0_count = 0;
      if (clk1_count > 2)
      begin
         // no event on other clk for 2 cycles
         clk0_is_bad = 1;
         if (current_clock == "inclk0")
            current_clk_is_bad = 1;
      end
   end

   // check if the bad clk is the primary clock
   if (((l_primary_clock == "inclk0") && (clk0_is_bad == 1'b1)) || ((l_primary_clock == "inclk1") && (clk1_is_bad == 1'b1)))
      primary_clk_is_bad = 1;
   else
      primary_clk_is_bad = 0;

   // actual switching
   if (inclk0_ipd != inclk0_last_value && current_clock == "inclk0")
   begin
      if (external_switch == 1'b1)
      begin
         if (!got_curr_clk_falling_edge_after_clkswitch)
         begin
            if (inclk0_ipd == 1'b0)
               got_curr_clk_falling_edge_after_clkswitch = 1;
            inclk_n = inclk0_ipd;
         end
      end
      else inclk_n = inclk0_ipd;
   end
   if (inclk1_ipd != inclk1_last_value && current_clock == "inclk1")
   begin
      if (external_switch == 1'b1)
      begin
         if (!got_curr_clk_falling_edge_after_clkswitch)
         begin
            if (inclk1_ipd == 1'b0)
               got_curr_clk_falling_edge_after_clkswitch = 1;
            inclk_n = inclk1_ipd;
         end
      end
      else inclk_n = inclk1_ipd;
   end
      if ((other_clock_value == 1'b1) && (other_clock_value != other_clock_last_value) && (l_switch_over_on_lossclk == "on") && l_enable_switch_over_counter == "on" && primary_clk_is_bad)
         switch_over_count = switch_over_count + 1;
      if ((other_clock_value == 1'b0) && (other_clock_value != other_clock_last_value))
      begin
         if ((external_switch && (got_curr_clk_falling_edge_after_clkswitch || current_clk_is_bad)) || (l_switch_over_on_lossclk == "on" && primary_clk_is_bad && ((l_enable_switch_over_counter == "off" || switch_over_count == switch_over_counter))))
         begin
            got_curr_clk_falling_edge_after_clkswitch = 0;
            if (current_clock == "inclk0")
               current_clock = "inclk1";
            else
               current_clock = "inclk0";
            active_clock = ~active_clock;
            active_clk_was_switched = 1;
            switch_over_count = 0;
            external_switch = 0;
            current_clk_is_bad = 0;
         end
      end

//   end
   if (l_switch_over_on_lossclk == "on" && (clkswitch_ipd != 1'b1))
   begin
      if (primary_clk_is_bad)
         clkloss_tmp = 1;
      else
         clkloss_tmp = 0;
   end
   else clkloss_tmp = clkswitch_ipd;

   inclk0_last_value = inclk0_ipd;
   inclk1_last_value = inclk1_ipd;
   other_clock_last_value = other_clock_value;

end

and (clkbad[0], clk0_is_bad, 1'b1);
and (clkbad[1], clk1_is_bad, 1'b1);
and (activeclock, active_clock, 1'b1);
and (clkloss, clkloss_tmp, 1'b1);

n_cntr n1 (.clk(inclk_n),
            .reset(1'b0),
            .cout(refclk),
            .initial_value(n_val),
            .modulus(n_val),
            .time_delay(n_time_delay_val));

scale_cntr l0 (.clk(vco_out[i_l0_ph]),
               .pll_reset(areset_ipd || cntr_reset_1),
               .internal_reset(cntr_reset_2),
               .cout(l0_clk),
               .high(l0_high_val),
               .low(l0_low_val),
               .initial_value(l0_initial_val),
               .mode(l0_mode_val),
               .time_delay(l0_time_delay_val),
               .ph_tap(i_l0_ph));

scale_cntr l1 (.clk(vco_out[i_l1_ph]),
               .pll_reset(areset_ipd || cntr_reset_1),
               .internal_reset(cntr_reset_2),
               .cout(l1_clk),
               .high(l1_high_val),
               .low(l1_low_val),
               .initial_value(l1_initial_val),
               .mode(l1_mode_val),
               .time_delay(l1_time_delay_val),
               .ph_tap(i_l1_ph));

scale_cntr g0 (.clk(vco_out[i_g0_ph]),
               .pll_reset(areset_ipd || cntr_reset_1),
               .internal_reset(cntr_reset_2),
               .cout(g0_clk),
               .high(g0_high_val),
               .low(g0_low_val),
               .initial_value(g0_initial_val),
               .mode(g0_mode_val),
               .time_delay(g0_time_delay_val),
               .ph_tap(i_g0_ph));

dffp lvds_dffa (.D(comparator_ipd),
                .CLRN(1'b1),
                .PRN(1'b1),
                .ENA(1'b1),
                .CLK(g0_clk),
                .Q(dffa_out));

always @(dffa_out or lvds_dffb_clk)
begin
   lvds_dffb_clk_dly = lvds_dffb_clk;
   dffa_out_dly <= dffa_out;
end
dffp lvds_dffb (.D(dffa_out_dly),
                .CLRN(1'b1),
                .PRN(1'b1),
                .ENA(1'b1),
                .CLK(lvds_dffb_clk_dly),
                .Q(dffb_out));

assign lvds_dffb_clk = (l_enable0_counter == "l0") ? l0_clk : (l_enable0_counter == "l1") ? l1_clk : 1'b0;

dffp lvds_dffc (.D(dffb_out),
                .CLRN(1'b1),
                .PRN(1'b1),
                .ENA(1'b1),
                .CLK(lvds_dffc_clk),
                .Q(dffc_out));

assign lvds_dffc_clk = (l_enable0_counter == "l0") ? l0_clk : (l_enable0_counter == "l1") ? l1_clk : 1'b0;

assign nce_temp = ~dffc_out && dffb_out;

dffp lvds_dffd (.D(nce_temp),
                .CLRN(1'b1),
                .PRN(1'b1),
                .ENA(1'b1),
                .CLK(lvds_dffd_clk),
                .Q(dffd_out));

assign lvds_dffd_clk = (l_enable0_counter == "l0") ? l0_clk : (l_enable0_counter == "l1") ? l1_clk : 1'b0;

assign nce_l0 = (l_enable0_counter == "l0") ? dffd_out : 'b0;
assign nce_l1 = (l_enable0_counter == "l1") ? dffd_out : 'b0;

scale_cntr g1 (.clk(vco_out[i_g1_ph]),
               .pll_reset(areset_ipd || cntr_reset_1),
               .internal_reset(cntr_reset_2),
               .cout(g1_clk),
               .high(g1_high_val),
               .low(g1_low_val),
               .initial_value(g1_initial_val),
               .mode(g1_mode_val),
               .time_delay(g1_time_delay_val),
               .ph_tap(i_g1_ph));

scale_cntr g2 (.clk(vco_out[i_g2_ph]),
               .pll_reset(areset_ipd || cntr_reset_1),
               .internal_reset(cntr_reset_2),
               .cout(g2_clk),
               .high(g2_high_val),
               .low(g2_low_val),
               .initial_value(g2_initial_val),
               .mode(g2_mode_val),
               .time_delay(g2_time_delay_val),
               .ph_tap(i_g2_ph));

scale_cntr g3 (.clk(vco_out[i_g3_ph]),
               .pll_reset(areset_ipd || cntr_reset_1),
               .internal_reset(cntr_reset_2),
               .cout(g3_clk),
               .high(g3_high_val),
               .low(g3_low_val),
               .initial_value(g3_initial_val),
               .mode(g3_mode_val),
               .time_delay(g3_time_delay_val),
               .ph_tap(i_g3_ph));

    assign inclk_e0 = (l_operation_mode == "external_feedback" && ext_fbk_cntr == "e0" && fbclk_is_in_phase_with_refclk == 1'b0) ? vco_out[0] : vco_out[i_e0_ph];
    assign cntr_e0_initial = (l_operation_mode == "external_feedback" && ext_fbk_cntr == "e0") ? 1 : e0_initial_val;
    assign cntr_e0_delay = (l_operation_mode == "external_feedback" && ext_fbk_cntr == "e0") ? ((fbclk_is_in_phase_with_refclk == 1'b1) ? ext_fbk_delay : 0) : e0_time_delay_val;

scale_cntr e0 (.clk(inclk_e0),
               .pll_reset(areset_ipd || cntr_reset_1),
               .internal_reset(cntr_reset_2),
               .cout(e0_clk),
               .high(e0_high_val),
               .low(e0_low_val),
               .initial_value(cntr_e0_initial),
               .mode(e0_mode_val),
               .time_delay(cntr_e0_delay),
               .ph_tap(i_e0_ph));

    assign inclk_e1 = (l_operation_mode == "external_feedback" && ext_fbk_cntr == "e1" && fbclk_is_in_phase_with_refclk == 1'b0) ? vco_out[0] : vco_out[i_e1_ph];
    assign cntr_e1_initial = (l_operation_mode == "external_feedback" && ext_fbk_cntr == "e1") ? 1 : e1_initial_val;
    assign cntr_e1_delay = (l_operation_mode == "external_feedback" && ext_fbk_cntr == "e1") ? ((fbclk_is_in_phase_with_refclk == 1'b1) ? ext_fbk_delay : 0) : e1_time_delay_val;

scale_cntr e1 (.clk(inclk_e1),
               .pll_reset(areset_ipd || cntr_reset_1),
               .internal_reset(cntr_reset_2),
               .cout(e1_clk),
               .high(e1_high_val),
               .low(e1_low_val),
               .initial_value(cntr_e1_initial),
               .mode(e1_mode_val),
               .time_delay(cntr_e1_delay),
               .ph_tap(i_e1_ph));

    assign inclk_e2 = (l_operation_mode == "external_feedback" && ext_fbk_cntr == "e2" && fbclk_is_in_phase_with_refclk == 1'b0) ? vco_out[0] : vco_out[i_e2_ph];
    assign cntr_e2_initial = (l_operation_mode == "external_feedback" && ext_fbk_cntr == "e2") ? 1 : e2_initial_val;
    assign cntr_e2_delay = (l_operation_mode == "external_feedback" && ext_fbk_cntr == "e2") ? ((fbclk_is_in_phase_with_refclk == 1'b1) ? ext_fbk_delay : 0) : e2_time_delay_val;

scale_cntr e2 (.clk(inclk_e2),
               .pll_reset(areset_ipd || cntr_reset_1),
               .internal_reset(cntr_reset_2),
               .cout(e2_clk),
               .high(e2_high_val),
               .low(e2_low_val),
               .initial_value(cntr_e2_initial),
               .mode(e2_mode_val),
               .time_delay(cntr_e2_delay),
               .ph_tap(i_e2_ph));

    assign inclk_e3 = (l_operation_mode == "external_feedback" && ext_fbk_cntr == "e3" && fbclk_is_in_phase_with_refclk == 1'b0) ? vco_out[0] : vco_out[i_e3_ph];
    assign cntr_e3_initial = (l_operation_mode == "external_feedback" && ext_fbk_cntr == "e3") ? 1 : e3_initial_val;
    assign cntr_e3_delay = (l_operation_mode == "external_feedback" && ext_fbk_cntr == "e3") ? ((fbclk_is_in_phase_with_refclk == 1'b1) ? ext_fbk_delay : 0) : e3_time_delay_val;

scale_cntr e3 (.clk(inclk_e3),
               .pll_reset(areset_ipd || cntr_reset_1),
               .internal_reset(cntr_reset_2),
               .cout(e3_clk),
               .high(e3_high_val),
               .low(e3_low_val),
               .initial_value(cntr_e3_initial),
               .mode(e3_mode_val),
               .time_delay(cntr_e3_delay),
               .ph_tap(i_e3_ph));


always @(nce_l0 or vco_out[i_l0_ph])
begin
   nce_l0_fast = nce_l0;
   vco_l0 <= vco_out[i_l0_ph];
end

always @(vco_l0 or cntr_reset_1 or cntr_reset_2)
begin
   if (cntr_reset_1 == 1'b1)
   begin
      l0_count = 1;
      l0_got_first_rising_edge = 0;
   end
   else if (cntr_reset_2 == 1'b1)
   begin
      l0_count = 1;
      if (i_l0_ph > 0)
         l0_got_first_rising_edge = 0;
      else
         l0_got_first_rising_edge = 1;
   end
   else begin
   if (nce_l0_fast == 1'b0)
   begin
     if (l0_got_first_rising_edge == 1'b0)
     begin
        if (vco_l0 == 1'b1 && vco_l0 != vco_l0_last_value)
           l0_got_first_rising_edge = 1;
     end
     else if (vco_l0 != vco_l0_last_value)
     begin
         l0_count = l0_count + 1;
         if (l0_count == (l0_high_val + l0_low_val) * 2)
            l0_count  = 1;
     end
   end
   if (vco_l0 == 1'b0 && vco_l0 != vco_l0_last_value)
   begin
      if (l0_count == 1)
      begin
         l0_tmp = 1;
         l0_got_first_rising_edge = 0;
      end
      else l0_tmp = 0;
   end
   end
   vco_l0_last_value = vco_l0;
end

always @(nce_l1 or vco_out[i_l1_ph])
begin
   nce_l1_fast = nce_l1;
   vco_l1 <= vco_out[i_l1_ph];
end

always @(vco_l1 or cntr_reset_1 or cntr_reset_2)
begin
   if (cntr_reset_1 == 1'b1)
   begin
      l1_count = 1;
      l1_got_first_rising_edge = 0;
   end
   else if (cntr_reset_2 == 1'b1)
   begin
      l1_count = 1;
      if (i_l1_ph > 0)
         l1_got_first_rising_edge = 0;
      else
         l1_got_first_rising_edge = 1;
   end
   else begin
   if (nce_l1_fast == 1'b0)
   begin
     if (l1_got_first_rising_edge == 1'b0)
     begin
        if (vco_l1 == 1'b1 && vco_l1 != vco_l1_last_value)
           l1_got_first_rising_edge = 1;
     end
     else if (vco_l1 != vco_l1_last_value)
     begin
         l1_count = l1_count + 1;
         if (l1_count == (l1_high_val + l1_low_val) * 2)
            l1_count  = 1;
     end
   end
   if (vco_l1 == 1'b0 && vco_l1 != vco_l1_last_value)
   begin
      if (l1_count == 1)
      begin
         l1_tmp = 1;
         l1_got_first_rising_edge = 0;
      end
      else l1_tmp = 0;
   end
   end
   vco_l1_last_value = vco_l1;
end

assign enable0_tmp = (l_enable0_counter == "l0") ? l0_tmp : l1_tmp;
assign enable1_tmp = (l_enable1_counter == "l0") ? l0_tmp : l1_tmp;

always @ (inclk_n or ena_ipd or areset_ipd)
begin
   if (areset_ipd == 'b1)
   begin
     gate_count = 0;
     gate_out = 0; 
   end
   else if (inclk_n == 'b1 && inclk_last_value != inclk_n)
       if (ena_ipd == 'b1)
       begin
          gate_count = gate_count + 1;
          if (gate_count == gate_lock_counter)
            gate_out = 1;
       end
   inclk_last_value = inclk_n;
end

assign locked = (l_gate_lock_signal == "yes") ? gate_out && pll_lock : pll_lock;

always @ (scanclk_ipd or scanaclr_ipd)
begin
   if (scanaclr_ipd == 'b1)
      for (i = 0; i <= scan_chain_length; i = i + 1)
         scan_data[i] = 0;
   else if (scanclk_ipd == 'b1 && scanclk_last_value != scanclk_ipd)
   begin
     if (pll_in_quiet_period && ($time - start_quiet_time < quiet_time))
        $display("Time: %0t", $time, "   Warning : Detected transition on SCANCLK during quiet time. PLL may not function correctly."); 
     else begin
        pll_in_quiet_period = 0;
     for (j = scan_chain_length-1; j >= 1; j = j - 1)
     begin
        scan_data[j] = scan_data[j - 1];
     end
     scan_data[0] = scandata_ipd;
     end
   end
   else if (scanclk_ipd == 'b0 && scanclk_last_value != scanclk_ipd)
   begin
     if (pll_in_quiet_period && ($time - start_quiet_time < quiet_time))
        $display("Time: %0t", $time, "   Warning : Detected transition on SCANCLK during quiet time. PLL may not function correctly."); 
     else if (scan_data[scan_chain_length-1] == 1'b1)
     begin
        pll_in_quiet_period = 1;
        start_quiet_time = $time;
        // initiate transfer
        scandataout_tmp <= 1'b1;
        quiet_time = slowest_clk(l0_high_val+l0_low_val,
                                 l1_high_val+l1_low_val,
                                 g0_high_val+g0_low_val,
                                 g1_high_val+g1_low_val,
                                 g2_high_val+g2_low_val,
                                 g3_high_val+g3_low_val,
                                 e0_high_val+e0_low_val,
                                 e1_high_val+e1_low_val,
                                 e2_high_val+e2_low_val,
                                 e3_high_val+e3_low_val,
                                 l_scan_chain,
                                 refclk_period, m_val);
        transfer = 1;
   end
   end
   scanclk_last_value = scanclk_ipd;
end

always @(scandataout_tmp)
begin
   if (scandataout_tmp == 1'b1)
      scandataout_tmp <= #(quiet_time) 1'b0;
end

always @(posedge transfer)
begin
   if (transfer == 1'b1)
   begin
     $display("NOTE : Reconfiguring PLL at time %0t", $time);
     if (l_scan_chain == "long")
     begin
        // cntr e3
        if (scan_data[273] == 1'b1)
        begin
           e3_mode_val = "bypass";
           if (scan_data[283] == 1'b1)
              e3_mode_val = "off";
        end
        else if (scan_data[283] == 1'b1)
           e3_mode_val = "odd";
        else
           e3_mode_val = "even";
        e3_time_delay_val = 32'b0;
        e3_time_delay_val = scan_data[287:284];
        e3_time_delay_val = e3_time_delay_val * 250;
        if (e3_time_delay_val > 3000)
           e3_time_delay_val = 3000;
        e3_high_val[8:0] = scan_data[272:264];
        e3_low_val[8:0] = scan_data[282:274];

        // cntr e2
        if (scan_data[249] == 1'b1)
        begin
           e2_mode_val = "bypass";
           if (scan_data[259] == 1'b1)
              e2_mode_val = "off";
        end
        else if (scan_data[259] == 1'b1)
           e2_mode_val = "odd";
        else
           e2_mode_val = "even";
        e2_time_delay_val = 32'b0;
        e2_time_delay_val = scan_data[263:260];
        e2_time_delay_val = e2_time_delay_val * 250;
        if (e2_time_delay_val > 3000)
           e2_time_delay_val = 3000;
        e2_high_val[8:0] = scan_data[248:240];
        e2_low_val[8:0] = scan_data[258:250];

        // cntr e1
        if (scan_data[225] == 1'b1)
        begin
           e1_mode_val = "bypass";
           if (scan_data[235] == 1'b1)
              e1_mode_val = "off";
        end
        else if (scan_data[235] == 1'b1)
           e1_mode_val = "odd";
        else
           e1_mode_val = "even";
        e1_time_delay_val = 32'b0;
        e1_time_delay_val = scan_data[239:236];
        e1_time_delay_val = e1_time_delay_val * 250;
        if (e1_time_delay_val > 3000)
           e1_time_delay_val = 3000;
        e1_high_val[8:0] = scan_data[224:216];
        e1_low_val[8:0] = scan_data[234:226];

        // cntr e0
        if (scan_data[201] == 1'b1)
        begin
           e0_mode_val = "bypass";
           if (scan_data[211] == 1'b1)
              e0_mode_val = "off";
        end
        else if (scan_data[211] == 1'b1)
           e0_mode_val = "odd";
        else
           e0_mode_val = "even";
        e0_time_delay_val = 32'b0;
        e0_time_delay_val = scan_data[215:212];
        e0_time_delay_val = e0_time_delay_val * 250;
        if (e0_time_delay_val > 3000)
           e0_time_delay_val = 3000;
        e0_high_val[8:0] = scan_data[200:192];
        e0_low_val[8:0] = scan_data[210:202];

        $display("PLL reconfigured with E3 high = %d, E3 low = %d, E3 mode = %s, E3 time delay = %d", e3_high_val[8:0], e3_low_val[8:0], e3_mode_val, e3_time_delay_val);
        $display("                                   E2 high = %d, E2 low = %d, E2 mode = %s, E2 time delay = %d", e2_high_val[8:0], e2_low_val[8:0], e2_mode_val, e2_time_delay_val);
        $display("                                   E1 high = %d, E1 low = %d, E1 mode = %s, E1 time delay = %d", e1_high_val[8:0], e1_low_val[8:0], e1_mode_val, e1_time_delay_val);
        $display("                                   E0 high = %d, E0 low = %d, E0 mode = %s, E0 time delay = %d", e0_high_val[8:0], e0_low_val[8:0], e0_mode_val, e0_time_delay_val);

     end
     // cntr l1
        if (scan_data[177] == 1'b1)
        begin
           l1_mode_val = "bypass";
           if (scan_data[187] == 1'b1)
              l1_mode_val = "off";
        end
        else if (scan_data[187] == 1'b1)
           l1_mode_val = "odd";
        else
           l1_mode_val = "even";
        l1_time_delay_val = 32'b0;
        l1_time_delay_val = scan_data[191:188];
        l1_time_delay_val = l1_time_delay_val * 250;
        if (l1_time_delay_val > 3000)
           l1_time_delay_val = 3000;
        l1_high_val[8:0] = scan_data[176:168];
        l1_low_val[8:0] = scan_data[186:178];

     // cntr l0
        if (scan_data[153] == 1'b1)
        begin
           l0_mode_val = "bypass";
           if (scan_data[163] == 1'b1)
              l1_mode_val = "off";
        end
        else if (scan_data[163] == 1'b1)
           l0_mode_val = "odd";
        else
           l0_mode_val = "even";
        l0_time_delay_val = 32'b0;
        l0_time_delay_val = scan_data[167:164];
        l0_time_delay_val = l0_time_delay_val * 250;
        if (l0_time_delay_val > 3000)
           l0_time_delay_val = 3000;
        l0_high_val[8:0] = scan_data[152:144];
        l0_low_val[8:0] = scan_data[162:154];

        $display("                                   L1 high = %d, L1 low = %d, L1 mode = %s, L1 time delay = %d", l1_high_val[8:0], l1_low_val[8:0], l1_mode_val, l1_time_delay_val);
        $display("                                   L0 high = %d, L0 low = %d, L0 mode = %s, L0 time delay = %d", l0_high_val[8:0], l0_low_val[8:0], l0_mode_val, l0_time_delay_val);

     // cntr g3
        if (scan_data[129] == 1'b1)
        begin
           g3_mode_val = "bypass";
           if (scan_data[139] == 1'b1)
              l1_mode_val = "off";
        end
        else if (scan_data[139] == 1'b1)
           g3_mode_val = "odd";
        else
           g3_mode_val = "even";
        g3_time_delay_val = 32'b0;
        g3_time_delay_val = scan_data[143:140];
        g3_time_delay_val = g3_time_delay_val * 250;
        if (g3_time_delay_val > 3000)
           g3_time_delay_val = 3000;
        g3_high_val[8:0] = scan_data[128:120];
        g3_low_val[8:0] = scan_data[138:130];

     // cntr g2
        if (scan_data[105] == 1'b1)
        begin
           g2_mode_val = "bypass";
           if (scan_data[115] == 1'b1)
              l1_mode_val = "off";
        end
        else if (scan_data[115] == 1'b1)
           g2_mode_val = "odd";
        else
           g2_mode_val = "even";
        g2_time_delay_val = 32'b0;
        g2_time_delay_val = scan_data[119:116];
        g2_time_delay_val = g2_time_delay_val * 250;
        if (g2_time_delay_val > 3000)
           g2_time_delay_val = 3000;
        g2_high_val[8:0] = scan_data[104:96];
        g2_low_val[8:0] = scan_data[114:106];

     // cntr g1
        if (scan_data[81] == 1'b1)
        begin
           g1_mode_val = "bypass";
           if (scan_data[91] == 1'b1)
              l1_mode_val = "off";
        end
        else if (scan_data[91] == 1'b1)
           g1_mode_val = "odd";
        else
           g1_mode_val = "even";
        g1_time_delay_val = 32'b0;
        g1_time_delay_val = scan_data[95:92];
        g1_time_delay_val = g1_time_delay_val * 250;
        if (g1_time_delay_val > 3000)
           g1_time_delay_val = 3000;
        g1_high_val[8:0] = scan_data[80:72];
        g1_low_val[8:0] = scan_data[90:82];

     // cntr g0
        if (scan_data[57] == 1'b1)
        begin
           g0_mode_val = "bypass";
           if (scan_data[67] == 1'b1)
              l1_mode_val = "off";
        end
        else if (scan_data[67] == 1'b1)
           g0_mode_val = "odd";
        else
           g0_mode_val = "even";
        g0_time_delay_val = 32'b0;
        g0_time_delay_val = scan_data[71:68];
        g0_time_delay_val = g0_time_delay_val * 250;
        if (g0_time_delay_val > 3000)
           g0_time_delay_val = 3000;
        g0_high_val[8:0] = scan_data[56:48];
        g0_low_val[8:0] = scan_data[66:58];

        $display("                                   G3 high = %d, G3 low = %d, G3 mode = %s, G3 time delay = %d", g3_high_val[8:0], g3_low_val[8:0], g3_mode_val, g3_time_delay_val);
        $display("                                   G2 high = %d, G2 low = %d, G2 mode = %s, G2 time delay = %d", g2_high_val[8:0], g2_low_val[8:0], g2_mode_val, g2_time_delay_val);
        $display("                                   G1 high = %d, G1 low = %d, G1 mode = %s, G1 time delay = %d", g1_high_val[8:0], g1_low_val[8:0], g1_mode_val, g1_time_delay_val);
        $display("                                   G0 high = %d, G0 low = %d, G0 mode = %s, G0 time delay = %d", g0_high_val[8:0], g0_low_val[8:0], g0_mode_val, g0_time_delay_val);

     // cntr M
        if (scan_data[33] == 1'b1)
        begin
           m_mode_val = "bypass";
           if (scan_data[43] == 1'b1)
           begin
              $display("Error : M counter cannot be turned off. M modulus will be set to 1");
              m_val[8:0] = 9'b000000001;
           end
           else
              $display("M mode = bypass");
        end
        else m_mode_val = "";
        m_time_delay_val = 32'b0;
        m_time_delay_val = scan_data[47:44];
        m_time_delay_val = m_time_delay_val * 250;
        if (m_time_delay_val > 3000)
           m_time_delay_val = 3000;
        m_val[8:0] = scan_data[32:24];
        if (m_mode_val != "bypass" && m_val == 0)
        begin
           $display("Error : M modulus is set to 0 in non-bypass mode. M will be set to 1");
           m_val[8:0] = 9'b000000001;
        end
        else if (m_mode_val == "bypass")
        begin
           m_val[8:0] = 9'b000000001;
           m_time_delay_val = 32'b0;
           $display(" M modulus = 1, M time delay = 0");
        end
        else $display(" M modulus = %d, M time delay = %d", m_val[8:0], m_time_delay_val);

     // cntr N
        if (scan_data[9] == 1'b1)
        begin
           n_mode_val = "bypass";
           if (scan_data[19] == 1'b1)
           begin
              $display("Error : N counter cannot be turned off. N modulus will be set to 1");
              n_val[8:0] = 9'b000000001;
           end
           else
              $display("N mode = bypass");
        end
        else n_mode_val = "";
        n_time_delay_val = 32'b0;
        n_time_delay_val = scan_data[23:20];
        n_time_delay_val = n_time_delay_val * 250;
        if (n_time_delay_val > 3000)
           n_time_delay_val = 3000;
        n_val[8:0] = scan_data[8:0];
        if (n_mode_val != "bypass" && n_val == 0)
        begin
           $display("Error : N modulus is set to 0 in non-bypass mode. N will be set to 1");
           n_val[8:0] = 9'b000000001;
        end
        else if (n_mode_val == "bypass")
        begin
           n_val[8:0] = 9'b000000001;
           n_time_delay_val = 32'b0;
           $display(" N modulus = 1, N time delay = 0");
        end
        else $display(" N modulus = %d, N time delay = %d", n_val[8:0], n_time_delay_val);

   transfer = 0;
   // clear the scan_chain
   for (i = 0; i <= scan_chain_length; i = i + 1)
      scan_data[i] = 0;
   end
end

always @(areset_ipd)
begin
   if (areset_ipd == 1'b1)
   begin
      pll_lock = 0;
      pll_about_to_lock = 0;
      cycles_to_lock = 0;
   end
   else
      schedule_vco = 1;
end

always @(ena_ipd)
begin
   if (ena_ipd == 1'b1)
      schedule_vco = 1;
   else begin
      schedule_vco = 0;
      pll_lock = 0;
      pll_about_to_lock = 0;
   end
end

always @(refclk or fbclk)
begin
   refclk_tmp = refclk;
   fbclk_tmp <= fbclk;
end

always @(refclk_tmp)
begin
   // rising event on refclk
   if (refclk_tmp == 1'b1 && refclk_last_value != refclk_tmp)
   begin
      got_refclk_rising_edge = 1;
      if (refclk_got_first_rising_edge == 1'b0)
      begin
         refclk_got_first_rising_edge = 1;
         if (refclk_last_rising_edge > 0 && (active_clk_was_switched == 1'b0))
            refclk_period = $time - refclk_last_rising_edge;
      end
      else
         refclk_period = $time - refclk_last_rising_edge;
      if (got_fbclk_rising_edge == 1'b1)
      begin
        if (l_source_is_pll == "off" || (l_source_is_pll == "on" && ($time - fbclk_last_rising_edge > 2)))
        begin
          got_fbclk_rising_edge = 0;
          got_refclk_rising_edge = 0;
          if ((refclk_period > fbclk_period && refclk_period - fbclk_period <= 2) || (fbclk_period > refclk_period && fbclk_period - refclk_period <= 2) || (refclk_period == fbclk_period))
          begin
              // reset m counter
             m_reset = 1;
             #0 m_reset = 0;
             got_refclk_rising_edge = 1;
          end
          else m_times_vco_period = refclk_period;
          schedule_from_refclk = 1;
          if (ena_ipd == 'b1)
             schedule_vco = 1;
        end
        else do_pfd = 1;
      end
      else if (fbclk_got_first_rising_edge == 'b0 && first_schedule == 'b1)
      begin
         // start VCO
         if (ena_ipd == 'b1)
            schedule_vco = 1;
      end
      refclk_last_rising_edge = $time;
      active_clk_was_switched = 0;
   end
   refclk_last_value = refclk_tmp;
end

always @(posedge do_pfd)
begin
do_pfd <= #0 1'b0;
    if (fbclk_last_rising_edge == refclk_last_rising_edge || (fbclk_last_rising_edge > refclk_last_rising_edge && fbclk_last_rising_edge - refclk_last_rising_edge <= 2) || (refclk_last_rising_edge > fbclk_last_rising_edge && refclk_last_rising_edge - fbclk_last_rising_edge <= 2))
    begin
       if (fbclk_is_in_phase_with_refclk == 'b0)
       begin
           fbclk_is_in_phase_with_refclk = 1;
           reset_vco = 1;
       end
       if (cycles_to_lock == valid_lock_multiplier - 1)
          pll_about_to_lock <= 1;
       if (cycles_to_lock == valid_lock_multiplier)
          pll_lock = 1;
       cycles_to_lock = cycles_to_lock + 1;
       if (fbclk_last_rising_edge != refclk_last_rising_edge)
       m_times_vco_period = refclk_period - 1;
       else
       m_times_vco_period = refclk_period;

       if ((l_simulation_type == "timing") || ((l_simulation_type == "functional") && (loop_initial > 0 || loop_time_delay > 0 || loop_ph > 0)))
       begin
          if (reset_vco == 'b1)
          begin
              m_reset = 1;
              cntr_reset_1 = 1;
              first_schedule = 1;
              schedule_zero = 1;
              #1 cntr_reset_1 = 0;
              m_reset = 0;
              schedule_zero = 0;
          end
          initial_value_to_delay = loop_initial * (m_times_vco_period/loop_xplier);
          // calculate fbk_phase
          rem = m_times_vco_period % loop_xplier;
          vco_per = m_times_vco_period/loop_xplier;
          if (rem != 0)
             vco_per = vco_per + 1;
          fbk_phase = (loop_ph * vco_per)/8;

          if (l_operation_mode == "external_feedback")
          begin
              pull_back_ext_fbk_cntr = ext_fbk_cntr_delay + (ext_fbk_cntr_initial - 1) * (m_times_vco_period/loop_xplier) + fbk_phase;
              if (pull_back_ext_fbk_cntr > refclk_period)
                  while (pull_back_ext_fbk_cntr > refclk_period)
                      pull_back_ext_fbk_cntr = pull_back_ext_fbk_cntr - refclk_period;
              pull_back_M =  m_time_delay_val + (i_m_initial - 1) * (ext_fbk_cntr_high + ext_fbk_cntr_low) * (m_times_vco_period/loop_xplier);
              if (pull_back_M > refclk_period)
                  while (pull_back_M > refclk_period)
                      pull_back_M = pull_back_M - refclk_period;
          end
          else begin
              pull_back_ext_fbk_cntr = 0;
              pull_back_M = initial_value_to_delay + m_time_delay_val + fbk_phase;
          end
          total_pull_back = pull_back_M + pull_back_ext_fbk_cntr;

          if (l_simulation_type == "timing")
              total_pull_back = total_pull_back + pll_compensation_delay;
          if (total_pull_back > refclk_period)
          begin
              while (total_pull_back > refclk_period)
                  total_pull_back = total_pull_back - refclk_period;
          end
          offset = refclk_period - total_pull_back;
          if (l_operation_mode == "external_feedback")
          begin
              fbk_delay = pull_back_M;
              if (l_simulation_type == "timing")
                  fbk_delay = fbk_delay + pll_compensation_delay;
              ext_fbk_delay = pull_back_ext_fbk_cntr - fbk_phase;
          end
          else begin
              fbk_delay = total_pull_back - fbk_phase;
                if (fbk_delay < 0)
                begin
                    offset = offset - fbk_phase;
                    fbk_delay = total_pull_back;
                end
          end

          m_delay = fbk_delay;
          schedule_vco = 1;
       end
       else if (l_simulation_type == "functional")
       begin
           if (reset_vco == 1'b1)
           begin
              cntr_reset_2 = 1;
              #0 cntr_reset_2 = 0;
              reset_vco = 0;
           end
           m_times_vco_period = refclk_period;
           schedule_vco = 1;
       end

       fbclk_got_first_rising_edge = 0;
    end
    else if ((refclk_period > fbclk_period && refclk_period - fbclk_period <= 2) || (fbclk_period > refclk_period && fbclk_period - refclk_period <= 2) || (refclk_period == fbclk_period))
    begin
       fbclk_is_in_phase_with_refclk = 0;
       fbk_delay = 0;
       m_delay = fbk_delay;
       offset = $time - refclk_last_rising_edge;
       m_times_vco_period = m_times_vco_period - offset;
       offset = 0;
       cycles_to_lock = 0;
       schedule_vco = 1;
    end
    else begin
       fbk_delay = 0;
       m_delay = fbk_delay;
       m_times_vco_period = refclk_period;
       offset = 0;
       if (pll_lock == 'b1)
       begin
          cycles_to_lock = 0;
          cycles_to_unlock = cycles_to_unlock + 1;
          if (cycles_to_unlock == invalid_lock_multiplier)
          begin
             pll_lock = 0;
             pll_about_to_lock = 0;
          end
       end
       if (fbclk_is_in_phase_with_refclk)
       begin
          schedule_zero = 1;
          do_not_add_high_time = 1;
          #0 schedule_zero = 0;
          do_not_add_high_time = 0;
       end
       schedule_vco = 1;
       fbclk_is_in_phase_with_refclk = 0;
    end
    got_fbclk_rising_edge = 0;
    got_refclk_rising_edge = 0;
end

always @(fbclk_tmp)
begin
   if (fbclk_tmp == 1'b1 && fbclk_last_value != fbclk_tmp && pfdena == 'b1)
   begin
      got_fbclk_rising_edge = 1;
      if (fbclk_got_first_rising_edge == 1'b0)
      begin
         fbclk_got_first_rising_edge = 1;
         if (fbclk_last_rising_edge > 0)
            fbclk_period = $time - fbclk_last_rising_edge;
      end
      else begin
         fbclk_got_second_rising_edge = 1;
         fbclk_period = $time - fbclk_last_rising_edge;
      end
      if (got_refclk_rising_edge)
      begin
       if (l_source_is_pll == "on")
          do_pfd = 1;
       else begin
         if ($time == refclk_last_rising_edge)
         begin
            if (fbclk_is_in_phase_with_refclk == 'b0)
            begin
                fbclk_is_in_phase_with_refclk = 1;
                reset_vco = 1;
            end
            if (cycles_to_lock == valid_lock_multiplier - 1)
               pll_about_to_lock <= 1;
            if (cycles_to_lock == valid_lock_multiplier)
               pll_lock = 1;
            cycles_to_lock = cycles_to_lock + 1;
            m_times_vco_period = refclk_period;

            if ((l_simulation_type == "timing") || ((l_simulation_type == "functional") && (loop_initial > 0 || loop_time_delay > 0 || loop_ph > 0)))
            begin
               if (reset_vco == 'b1)
               begin
                   m_reset = 1;
                   cntr_reset_1 = 1;
                   first_schedule = 1;
                   schedule_zero = 1;
                   #0 cntr_reset_1 = 0;
                   m_reset = 0;
                   schedule_zero = 0;
               end
               initial_value_to_delay = loop_initial * (m_times_vco_period/loop_xplier);
               // calculate fbk_phase
               rem = m_times_vco_period % loop_xplier;
               vco_per = m_times_vco_period/loop_xplier;
               if (rem != 0)
                  vco_per = vco_per + 1;
               fbk_phase = (loop_ph * vco_per)/8;

               if (l_operation_mode == "external_feedback")
               begin
                   pull_back_ext_fbk_cntr = ext_fbk_cntr_delay + (ext_fbk_cntr_initial - 1) * (m_times_vco_period/loop_xplier) + fbk_phase;
                   if (pull_back_ext_fbk_cntr > refclk_period)
                       while (pull_back_ext_fbk_cntr > refclk_period)
                           pull_back_ext_fbk_cntr = pull_back_ext_fbk_cntr - refclk_period;
                   pull_back_M =  m_time_delay_val + (i_m_initial - 1) * (ext_fbk_cntr_high + ext_fbk_cntr_low) * (m_times_vco_period/loop_xplier);
                   if (pull_back_M > refclk_period)
                       while (pull_back_M > refclk_period)
                           pull_back_M = pull_back_M - refclk_period;
               end
               else begin
                   pull_back_ext_fbk_cntr = 0;
                   pull_back_M = initial_value_to_delay + m_time_delay_val + fbk_phase;
               end
               total_pull_back = pull_back_M + pull_back_ext_fbk_cntr;
               if (l_simulation_type == "timing")
                   total_pull_back = total_pull_back + pll_compensation_delay;
               if (total_pull_back > refclk_period)
               begin
                   while (total_pull_back > refclk_period)
                       total_pull_back = total_pull_back - refclk_period;
               end
               offset = refclk_period - total_pull_back;
               if (l_operation_mode == "external_feedback")
               begin
                   fbk_delay = pull_back_M;
                   if (l_simulation_type == "timing")
                       fbk_delay = fbk_delay + pll_compensation_delay;
                   ext_fbk_delay = pull_back_ext_fbk_cntr - fbk_phase;
               end
               else begin
                   fbk_delay = total_pull_back - fbk_phase;
                   if (fbk_delay < 0)
                   begin
                       offset = offset - fbk_phase;
                       fbk_delay = total_pull_back;
                   end
               end

               m_delay = fbk_delay;
               schedule_vco = 1;
            end
            else if (l_simulation_type == "functional")
            begin
                if (reset_vco == 1'b1)
                begin
                   cntr_reset_2 = 1;
                   #0 cntr_reset_2 = 0;
                   reset_vco = 0;
                end
                m_times_vco_period = refclk_period;
                schedule_vco = 1;
            end
            refclk_got_first_rising_edge = 0;
            fbclk_got_first_rising_edge = 0;
         end
         else if (refclk_period == fbclk_period)
         begin
            fbclk_is_in_phase_with_refclk = 0;
            fbk_delay = 0;
            m_delay = fbk_delay;
            offset = $time - refclk_last_rising_edge;
            m_times_vco_period = m_times_vco_period - offset;
            offset = 0;
            cycles_to_lock = 0;
            schedule_vco = 1;
         end
         else begin
            fbk_delay = 0;
            m_delay = fbk_delay;
            m_times_vco_period = refclk_period;
            offset = 0;
            if (pll_lock == 'b1)
            begin
               cycles_to_lock = 0;
               cycles_to_unlock = cycles_to_unlock + 1;
               if (cycles_to_unlock == invalid_lock_multiplier)
               begin
                  pll_lock = 0;
                  pll_about_to_lock = 0;
               end
            end
            if (fbclk_is_in_phase_with_refclk)
            begin
               schedule_zero = 1;
               do_not_add_high_time = 1;
               #0 schedule_zero = 0;
               do_not_add_high_time = 0;
            end
            schedule_vco = 1;
            fbclk_is_in_phase_with_refclk = 0;
         end
         got_fbclk_rising_edge = 0;
         got_refclk_rising_edge = 0;
      end
       end
      else if (($time - refclk_last_rising_edge) > 5 * refclk_period)
      begin
         // do not schedule, so VCO stops
         got_fbclk_rising_edge = 0;
         fbclk_got_first_rising_edge = 0;
         first_schedule = 1;
         pll_lock = 0;
         pll_about_to_lock = 0;
         schedule_zero = 1;
         // reset all counters
         m_reset = 1;
         cntr_reset_1 = 1;
         #0 m_reset = 0;
         cntr_reset_1 = 0;
         schedule_zero = 0;
      end
      else if (refclk_got_first_rising_edge == 1'b0 && fbclk_got_second_rising_edge == 1'b1)
      begin
         reschedule_from_fbclk = 1;
         if (ena_ipd == 'b1)
         begin
            offset = 0;
            schedule_vco <= 1;
         end
      end
      else if (pll_lock == 1'b1 && l_source_is_pll == "off")
      begin
         cycles_to_unlock = cycles_to_unlock + 1;
         if (cycles_to_unlock == invalid_lock_multiplier)
            pll_lock = 0;
      end

    if (l_source_is_pll == "on" && ($time - refclk_last_rising_edge) > 5 * refclk_period)
      fbclk_last_rising_edge = 0;
    else
      fbclk_last_rising_edge = $time;
   end
   else if (fbclk_tmp == 1'b1 && fbclk_last_value != fbclk_tmp && ena_ipd == 'b1)
   begin
      fbclk_last_rising_edge = $time;
      schedule_vco = 1;
      // schedule 'X' on locked
      pll_lock = 'bx;
      cycles_to_lock = 0;
      // if input clock stops
      if (($time - refclk_last_rising_edge) > 5 * refclk_period)
      begin
         refclk_got_first_rising_edge = 0;
         refclk_last_rising_edge = 0;
      end
   end
   fbclk_last_value = fbclk_tmp;
end

always @(schedule_vco or schedule_zero)
begin
   if (schedule_vco == 1'b1)
   begin
      loop_xplier = m_val;
      loop_initial = i_m_initial - 1;
      loop_ph = i_m_ph;
      loop_time_delay = m_time_delay_val;

      if (l_operation_mode == "external_feedback")
      begin
         loop_xplier = m_val * (ext_fbk_cntr_high + ext_fbk_cntr_low);
         loop_ph = ext_fbk_cntr_ph;
         loop_initial = ext_fbk_cntr_initial - 1 + ((i_m_initial - 1) * (ext_fbk_cntr_high + ext_fbk_cntr_low));
         loop_time_delay = m_time_delay_val + ext_fbk_cntr_delay;
      end
      sched_time = 0;
      cycle_to_adjust = 0;
      l = 1;
      vco_val = vco_out[0];
      if (schedule_from_refclk == 1'b1)
      begin
         vco_val = 0;
         vco_out[0] <= #0 1'b0;
         vco_out[1] <= 1'b0;
         vco_out[2] <= 1'b0;
         vco_out[3] <= 1'b0;
         vco_out[4] <= 1'b0;
         vco_out[5] <= 1'b0;
         vco_out[6] <= 1'b0;
         vco_out[7] <= 1'b0;
         schedule_from_refclk = 0;
      end
      if (offset > 0)
         vco_val = vco_val_last_value;
      schedule_vco <= #0 1'b0;
      my_rem = m_times_vco_period % loop_xplier;
      for (i=1; i <= loop_xplier; i = i + 1)
      begin
         tmp_vco_per = m_times_vco_period/loop_xplier;
         if (my_rem != 0 && l <= my_rem)
         begin
            tmp_rem = (loop_xplier * l) % my_rem;
            cycle_to_adjust = (loop_xplier * l) / my_rem;
            if (tmp_rem != 0)
               cycle_to_adjust = cycle_to_adjust + 1;
         end
         if (cycle_to_adjust == i)
         begin
            tmp_vco_per = tmp_vco_per + 1;
            l = l + 1;
         end
         high_time = tmp_vco_per/2;
         if (tmp_vco_per % 2 != 0)
            high_time = high_time + 1;
         low_time = tmp_vco_per - high_time;
         for (j = 0; j <= 1; j=j+1)
         begin
            vco_val = ~vco_val;
            if (vco_val == 1'b0)
               sched_time = sched_time + high_time;
            else if (vco_val == 1'b1)
               sched_time = sched_time + low_time;
            if (i == 1 && j == 0)   // first vco cycle
            begin
               if (offset > 0)
               begin
                  sched_time = sched_time + offset;
                  if (reset_vco == 1'b1)
                  begin
                     sched_time = sched_time - low_time;
                     reset_vco = 0;  
                  end
               end
            end
            // schedule the phase taps
            for (k = 0; k <= 7; k=k+1)
            begin
                 // use same scheduling method for tap4
                  if (fbclk_is_in_phase_with_refclk && (my_rem != 0) && (k == i_m_ph))
                     phase_shift[k] = fbk_phase;
                  else
                     phase_shift[k] = (k * tmp_vco_per)/8;
                  vco_out[k] <= #(sched_time + phase_shift[k]) vco_val;

            end
         end
      end
      // schedule once more
      if (first_schedule == 1'b1)
      begin
         vco_val = ~vco_val;
         if (vco_val == 1'b0)
            sched_time = sched_time + high_time;
         else if (vco_val == 1'b1)
            sched_time = sched_time + low_time;
         if (offset > 0)
            sched_time = sched_time + (m_times_vco_period - (sched_time - offset));
         // schedule the phase taps
         for (k = 0; k <= 7; k=k+1)
         begin
               if (fbclk_is_in_phase_with_refclk && (my_rem != 0) && (k == i_m_ph))
                  phase_shift[k] = fbk_phase;
               else
                  phase_shift[k] = (k * tmp_vco_per)/8;
               vco_out[k] <= #(sched_time + phase_shift[k]) vco_val;
         end
      end

      if (reschedule_from_fbclk == 1'b1)
         reschedule_from_fbclk = 0;
      else if (first_schedule == 1'b1)
      begin
         first_schedule = 0;
         total_sched_time = $time + sched_time;
      end
      else
         total_sched_time = total_sched_time + m_times_vco_period;
   end
   else if (schedule_zero == 1'b1)
   begin
      vco_out[0] <= 1'b0;
      vco_out[1] <= 1'b0;
      vco_out[1] <= #(phase_shift[1]) 1'b0;

      vco_out[2] <= 1'b0;
      vco_out[2] <= #(phase_shift[2]) 1'b0;

      vco_out[3] <= 1'b0;
      vco_out[3] <= #(phase_shift[3]) 1'b0;

      vco_out[4] <= 1'b0;
      vco_out[4] <= #(phase_shift[4]) 1'b0;

      vco_out[5] <= 1'b0;
      for (i=0; i <= phase_shift[5]; i=i+1)
          vco_out[5] <= #(i) 1'b0;
//      vco_out[5] <= #(phase_shift[5]) 1'b0;

      vco_out[6] <= 1'b0;
      for (i=0; i <= phase_shift[6]; i=i+1)
          vco_out[6] <= #(i) 1'b0;
//      vco_out[6] <= #(phase_shift[6]) 1'b0;

      vco_out[7] <= #0 1'b0;
      for (i=0; i <= phase_shift[7]; i=i+1)
          vco_out[7] <= #(i) 1'b0;
//      vco_out[7] <= #(phase_shift[7]) 1'b0;

      vco_val = 0;
   end
   vco_val_last_value = vco_val;
end

assign clk0_tmp = clk0_counter == "l0" ? l0_clk : clk0_counter == "l1" ? l1_clk : clk0_counter == "g0" ? g0_clk : clk0_counter == "g1" ? g1_clk : clk0_counter == "g2" ? g2_clk : clk0_counter == "g3" ? g3_clk : 'b0;

assign clk0 = pll_about_to_lock == 1'b1 ? clk0_tmp : 'bx;

dffp ena0_reg (.D(clkena0_ipd),
               .CLRN(1'b1),
               .PRN(1'b1),
               .ENA(1'b1),
               .CLK(!clk0_tmp),
               .Q(ena0));

assign clk1_tmp = clk1_counter == "l0" ? l0_clk : clk1_counter == "l1" ? l1_clk : clk1_counter == "g0" ? g0_clk : clk1_counter == "g1" ? g1_clk : clk1_counter == "g2" ? g2_clk : clk1_counter == "g3" ? g3_clk : 'b0;

assign clk1 = pll_about_to_lock == 1'b1 ? clk1_tmp : 'bx;

dffp ena1_reg (.D(clkena1_ipd),
               .CLRN(1'b1),
               .PRN(1'b1),
               .ENA(1'b1),
               .CLK(!clk1_tmp),
               .Q(ena1));

assign clk2_tmp = clk2_counter == "l0" ? l0_clk : clk2_counter == "l1" ? l1_clk : clk2_counter == "g0" ? g0_clk : clk2_counter == "g1" ? g1_clk : clk2_counter == "g2" ? g2_clk : clk2_counter == "g3" ? g3_clk : 'b0;

assign clk2 = pll_about_to_lock == 1'b1 ? clk2_tmp : 'bx;

dffp ena2_reg (.D(clkena2_ipd),
               .CLRN(1'b1),
               .PRN(1'b1),
               .ENA(1'b1),
               .CLK(!clk2_tmp),
               .Q(ena2));

assign clk3_tmp = clk3_counter == "l0" ? l0_clk : clk3_counter == "l1" ? l1_clk : clk3_counter == "g0" ? g0_clk : clk3_counter == "g1" ? g1_clk : clk3_counter == "g2" ? g2_clk : clk3_counter == "g3" ? g3_clk : 'b0;

assign clk3 = pll_about_to_lock == 1'b1 ? clk3_tmp : 'bx;

dffp ena3_reg (.D(clkena3_ipd),
               .CLRN(1'b1),
               .PRN(1'b1),
               .ENA(1'b1),
               .CLK(!clk3_tmp),
               .Q(ena3));

assign clk4_tmp = clk4_counter == "l0" ? l0_clk : clk4_counter == "l1" ? l1_clk : clk4_counter == "g0" ? g0_clk : clk4_counter == "g1" ? g1_clk : clk4_counter == "g2" ? g2_clk : clk4_counter == "g3" ? g3_clk : 'b0;

assign clk4 = pll_about_to_lock == 1'b1 ? clk4_tmp : 'bx;

dffp ena4_reg (.D(clkena4_ipd),
               .CLRN(1'b1),
               .PRN(1'b1),
               .ENA(1'b1),
               .CLK(!clk4_tmp),
               .Q(ena4));

assign clk5_tmp = clk5_counter == "l0" ? l0_clk : clk5_counter == "l1" ? l1_clk : clk5_counter == "g0" ? g0_clk : clk5_counter == "g1" ? g1_clk : clk5_counter == "g2" ? g2_clk : clk5_counter == "g3" ? g3_clk : 'b0;

assign clk5 = pll_about_to_lock == 1'b1 ? clk5_tmp : 'bx;

dffp ena5_reg (.D(clkena5_ipd),
               .CLRN(1'b1),
               .PRN(1'b1),
               .ENA(1'b1),
               .CLK(!clk5_tmp),
               .Q(ena5));

assign extclk0_tmp = extclk0_counter == "e0" ? e0_clk : extclk0_counter == "e1" ? e1_clk : extclk0_counter == "e2" ? e2_clk : extclk0_counter == "e3" ? e3_clk : 'b0;

assign extclk0 = pll_about_to_lock == 1'b1 ? extclk0_tmp : 'bx;

dffp extena0_reg (.D(extclkena0_ipd),
               .CLRN(1'b1),
               .PRN(1'b1),
               .ENA(1'b1),
               .CLK(!extclk0_tmp),
               .Q(extena0));

assign extclk1_tmp = extclk1_counter == "e0" ? e0_clk : extclk1_counter == "e1" ? e1_clk : extclk1_counter == "e2" ? e2_clk : extclk1_counter == "e3" ? e3_clk : 'b0;

assign extclk1 = pll_about_to_lock == 1'b1 ? extclk1_tmp : 'bx;

dffp extena1_reg (.D(extclkena1_ipd),
               .CLRN(1'b1),
               .PRN(1'b1),
               .ENA(1'b1),
               .CLK(!extclk1_tmp),
               .Q(extena1));

assign extclk2_tmp = extclk2_counter == "e0" ? e0_clk : extclk2_counter == "e1" ? e1_clk : extclk2_counter == "e2" ? e2_clk : extclk2_counter == "e3" ? e3_clk : 'b0;

assign extclk2 = pll_about_to_lock == 1'b1 ? extclk2_tmp : 'bx;

dffp extena2_reg (.D(extclkena2_ipd),
               .CLRN(1'b1),
               .PRN(1'b1),
               .ENA(1'b1),
               .CLK(!extclk2_tmp),
               .Q(extena2));

assign extclk3_tmp = extclk3_counter == "e0" ? e0_clk : extclk3_counter == "e1" ? e1_clk : extclk3_counter == "e2" ? e2_clk : extclk3_counter == "e3" ? e3_clk : 'b0;

assign extclk3 = pll_about_to_lock == 1'b1 ? extclk3_tmp : 'bx;

dffp extena3_reg (.D(extclkena3_ipd),
               .CLRN(1'b1),
               .PRN(1'b1),
               .ENA(1'b1),
               .CLK(!extclk3_tmp),
               .Q(extena3));

assign enable_0 = pll_about_to_lock == 1'b1 ? enable0_tmp : 'bx;
assign enable_1 = pll_about_to_lock == 1'b1 ? enable1_tmp : 'bx;

and (clk[0], ena0, clk0);
and (clk[1], ena1, clk1);
and (clk[2], ena2, clk2);
and (clk[3], ena3, clk3);
and (clk[4], ena4, clk4);
and (clk[5], ena5, clk5);

and (extclk[0], extena0, extclk0);
and (extclk[1], extena1, extclk1);
and (extclk[2], extena2, extclk2);
and (extclk[3], extena3, extclk3);

and (enable0, 1'b1, enable_0);
and (enable1, 1'b1, enable_1);

and (scandataout, 1'b1, scandataout_tmp);

endmodule //stratix_pll


// START MODULE NAME -----------------------------------------------------------
//
// Module Name : ALTPLL
//
// Description : Phase-Locked Loop (PLL) behavioral model. Model supports basic
//               PLL features such as clock division and multiplication,
//               programmable duty cycle and phase shifts, various feedback modes
//               and clock delays. Also supports real-time reconfiguration of
//               PLL "parameters" and clock switchover between the 2 input 
//               reference clocks. Up to 10 clock outputs may be used. 
//
// Limitations : Applicable to Stratix and Stratix-GX device families only
//               There is no support in the model for spread-spectrum feature
//
// Expected results : Up to 10 output clocks, each defined by its own set of
//                    parameters. Locked output (active high) indicates when the
//                    PLL locks. clkbad, clkloss and activeclock are used for
//                    clock switchover to inidicate which input clock has gone
//                    bad, when the clock switchover initiates and which input
//                    clock is being used as the reference, respectively.
//                    scandataout is the data output of the serial scan chain.

//END MODULE NAME --------------------------------------------------------------

`timescale 1 ps / 1ps

// MODULE DECLARATION
module altpll (
    inclk,      // input reference clock - up to 2 can be used
    fbin,       // external feedback input port
    pllena,     // PLL enable signal
    clkswitch,  // switch between inclk0 and inclk1
    areset,     // asynchronous reset
    pfdena,     // enable the Phase Frequency Detector (PFD)
    clkena,     // enable clk0 to clk5 clock outputs
    extclkena,  // enable extclk0 to extclk3 clock outputs
    scanclk,    // clock for the serial scan chain
    scanaclr,   // asynchronous clear the serial scan chain
    scandata,   // data for the scan chain
    clk,        // internal clock outputs (feeds the core)
    extclk,     // external clock outputs (feeds pins)
    clkbad,     // indicates if inclk0/inclk1 has gone bad
    activeclock,// indicates which input clock is being used
    clkloss,    // indicates when clock switchover initiates
    locked,     // indicates when the PLL locks onto the input clock
    scandataout // data output of the serial scan chain
);

// GLOBAL PARAMETER DECLARATION
parameter   intended_device_family    = "Stratix" ;
parameter   operation_mode            = "NORMAL" ;
parameter   pll_type                  = "AUTO" ;
parameter   qualify_conf_done         = "OFF" ;
parameter   compensate_clock          = "CLK0" ;
parameter   scan_chain                = "LONG";
parameter   primary_clock             = "inclk0";
parameter   inclk0_input_frequency    = 1000;
parameter   inclk1_input_frequency    = 1000;
parameter   gate_lock_signal          = "NO";
parameter   gate_lock_counter         = 0;
parameter   lock_high                 = 1;
parameter   lock_low                  = 1;
parameter   valid_lock_multiplier     = 1;
parameter   invalid_lock_multiplier   = 5;
parameter   switch_over_on_lossclk    = "OFF" ;
parameter   switch_over_on_gated_lock = "OFF" ;
parameter   enable_switch_over_counter = "OFF";
parameter   switch_over_counter       = 0;
parameter   feedback_source           = "EXTCLK0" ;
parameter   bandwidth                 = 0;
parameter   bandwidth_type            = "UNUSED";
parameter   spread_frequency          = 0;
parameter   down_spread               = "0.0";
// simulation-only parameters
parameter   simulation_type           = "functional";
parameter   source_is_pll             = "off";

//  internal clock specifications
parameter   clk5_multiply_by        = 1;
parameter   clk4_multiply_by        = 1;
parameter   clk3_multiply_by        = 1;
parameter   clk2_multiply_by        = 1;
parameter   clk1_multiply_by        = 1;
parameter   clk0_multiply_by        = 1;
parameter   clk5_divide_by          = 1;
parameter   clk4_divide_by          = 1;
parameter   clk3_divide_by          = 1;
parameter   clk2_divide_by          = 1;
parameter   clk1_divide_by          = 1;
parameter   clk0_divide_by          = 1;
parameter   clk5_phase_shift        = "0";
parameter   clk4_phase_shift        = "0";
parameter   clk3_phase_shift        = "0";
parameter   clk2_phase_shift        = "0";
parameter   clk1_phase_shift        = "0";
parameter   clk0_phase_shift        = "0";
// the 3 phase_shift_num parameters are for altlvds use only
parameter   clk2_phase_shift_num    = 0;
parameter   clk1_phase_shift_num    = 0;
parameter   clk0_phase_shift_num    = 0;
parameter   clk5_time_delay         = "0";
parameter   clk4_time_delay         = "0";
parameter   clk3_time_delay         = "0";
parameter   clk2_time_delay         = "0";
parameter   clk1_time_delay         = "0";
parameter   clk0_time_delay         = "0";
parameter   clk5_duty_cycle         = 50;
parameter   clk4_duty_cycle         = 50;
parameter   clk3_duty_cycle         = 50;
parameter   clk2_duty_cycle         = 50;
parameter   clk1_duty_cycle         = 50;
parameter   clk0_duty_cycle         = 50;
//  external clock specifications
parameter   extclk3_multiply_by     = 1;
parameter   extclk2_multiply_by     = 1;
parameter   extclk1_multiply_by     = 1;
parameter   extclk0_multiply_by     = 1;
parameter   extclk3_divide_by       = 1;
parameter   extclk2_divide_by       = 1;
parameter   extclk1_divide_by       = 1;
parameter   extclk0_divide_by       = 1;
parameter   extclk3_phase_shift     = "0";
parameter   extclk2_phase_shift     = "0";
parameter   extclk1_phase_shift     = "0";
parameter   extclk0_phase_shift     = "0";
parameter   extclk3_time_delay      = "0";
parameter   extclk2_time_delay      = "0";
parameter   extclk1_time_delay      = "0";
parameter   extclk0_time_delay      = "0";
parameter   extclk3_duty_cycle      = 50;
parameter   extclk2_duty_cycle      = 50;
parameter   extclk1_duty_cycle      = 50;
parameter   extclk0_duty_cycle      = 50;
//  advanced user parameters
parameter   vco_min             = 0;
parameter   vco_max             = 0;
parameter   vco_center          = 0;
parameter   pfd_min             = 0;
parameter   pfd_max             = 0;
parameter   m_initial           = 1;
parameter   m                   = 0; // m must default to 0 in order for altpll to calculate advanced parameters for itself
parameter   n                   = 1;
parameter   m2                  = 1;
parameter   n2                  = 1;
parameter   ss                  = 1;
parameter   l0_high             = 1;
parameter   l1_high             = 1;
parameter   g0_high             = 1;
parameter   g1_high             = 1;
parameter   g2_high             = 1;
parameter   g3_high             = 1;
parameter   e0_high             = 1;
parameter   e1_high             = 1;
parameter   e2_high             = 1;
parameter   e3_high             = 1;
parameter   l0_low              = 1;
parameter   l1_low              = 1;
parameter   g0_low              = 1;
parameter   g1_low              = 1;
parameter   g2_low              = 1;
parameter   g3_low              = 1;
parameter   e0_low              = 1;
parameter   e1_low              = 1;
parameter   e2_low              = 1;
parameter   e3_low              = 1;
parameter   l0_initial          = 1;
parameter   l1_initial          = 1;
parameter   g0_initial          = 1;
parameter   g1_initial          = 1;
parameter   g2_initial          = 1;
parameter   g3_initial          = 1;
parameter   e0_initial          = 1;
parameter   e1_initial          = 1;
parameter   e2_initial          = 1;
parameter   e3_initial          = 1;
parameter   l0_mode             = "bypass";
parameter   l1_mode             = "bypass";
parameter   g0_mode             = "bypass";
parameter   g1_mode             = "bypass";
parameter   g2_mode             = "bypass";
parameter   g3_mode             = "bypass";
parameter   e0_mode             = "bypass";
parameter   e1_mode             = "bypass";
parameter   e2_mode             = "bypass";
parameter   e3_mode             = "bypass";
parameter   l0_ph               = 0;
parameter   l1_ph               = 0;
parameter   g0_ph               = 0;
parameter   g1_ph               = 0;
parameter   g2_ph               = 0;
parameter   g3_ph               = 0;
parameter   e0_ph               = 0;
parameter   e1_ph               = 0;
parameter   e2_ph               = 0;
parameter   e3_ph               = 0;
parameter   m_ph                = 0;
parameter   l0_time_delay       = 0;
parameter   l1_time_delay       = 0;
parameter   g0_time_delay       = 0;
parameter   g1_time_delay       = 0;
parameter   g2_time_delay       = 0;
parameter   g3_time_delay       = 0;
parameter   e0_time_delay       = 0;
parameter   e1_time_delay       = 0;
parameter   e2_time_delay       = 0;
parameter   e3_time_delay       = 0;
parameter   m_time_delay        = 0;
parameter   n_time_delay        = 0;
parameter   extclk3_counter     = "e3" ;
parameter   extclk2_counter     = "e2" ;
parameter   extclk1_counter     = "e1" ;
parameter   extclk0_counter     = "e0" ;
parameter   clk5_counter        = "l1" ;
parameter   clk4_counter        = "l0" ;
parameter   clk3_counter        = "g3" ;
parameter   clk2_counter        = "g2" ;
parameter   clk1_counter        = "g1" ;
parameter   clk0_counter        = "g0" ;
parameter   enable0_counter     = "l0";
parameter   enable1_counter     = "l0";
parameter   charge_pump_current = 2;
parameter   loop_filter_r       = "1.0";
parameter   loop_filter_c       = 5;
parameter   lpm_type            = "altpll";

// INPUT PORT DECLARATION
input       [1:0] inclk;
input       fbin;
input       pllena;
input       clkswitch;
input       areset;
input       pfdena;
input       [5:0] clkena;
input       [3:0] extclkena;
input       scanclk;
input       scanaclr;
input       scandata;

// OUTPUT PORT DECLARATION
output        [5:0] clk;
output        [3:0] extclk;
output        [1:0] clkbad;
output        activeclock;
output        clkloss;
output        locked;
output        scandataout;

// pullups
tri1 fbin_pullup;
tri1 ena_pullup;
tri1 pfdena_pullup;
tri1 [5:0] clkena_pullup;
tri1 [3:0] extclkena_pullup;
tri1 scanclk_pullup;
tri1 scandata_pullup;
// pulldowns
tri0 [1:0] inclk_pulldown;
tri0 clkswitch_pulldown;
tri0 areset_pulldown;
tri0 scanclr_pulldown;

assign fbin_pullup = fbin;
assign ena_pullup = pllena;
assign pfdena_pullup = pfdena;
assign clkena_pullup = clkena;
assign extclkena_pullup = extclkena;
assign scanclk_pullup = scanclk;
assign scandata_pullup = scandata;
assign inclk_pulldown = inclk;
assign clkswitch_pulldown = clkswitch;
assign areset_pulldown = areset;
assign scanclr_pulldown = scanaclr;

// COMPONENT INSTANTIATION
stratix_pll pll0 
(
    .inclk (inclk_pulldown),
    .fbin (fbin_pullup),
    .ena (ena_pullup),
    .clkswitch (clkswitch_pulldown),
    .areset (areset_pulldown), 
    .pfdena (pfdena_pullup), 
    .clkena (clkena_pullup),
    .extclkena (extclkena_pullup),
    .scanclk (scanclk_pullup),
    .scanaclr (scanclr_pulldown),
    .scandata (scandata_pullup),
    .comparator (1'b0),
    .clk (clk), 
    .extclk (extclk),
    .clkbad (clkbad),
    .activeclock (activeclock),
    .locked (locked),
    .clkloss (clkloss),
    .scandataout (scandataout),
    .enable0 (),
    .enable1 ()
);
    defparam
        pll0.operation_mode         = operation_mode, 
        pll0.pll_type               = pll_type,
        pll0.qualify_conf_done      = qualify_conf_done,
        pll0.compensate_clock       = compensate_clock, 
        pll0.scan_chain             = scan_chain,   
        pll0.primary_clock          = primary_clock,
        pll0.inclk0_input_frequency = inclk0_input_frequency,
        pll0.inclk1_input_frequency = inclk1_input_frequency,
        pll0.gate_lock_signal       = gate_lock_signal,
        pll0.gate_lock_counter      = gate_lock_counter,
        pll0.lock_high              = lock_high,
        pll0.lock_low               = lock_low,
        pll0.valid_lock_multiplier  = valid_lock_multiplier,
        pll0.invalid_lock_multiplier = invalid_lock_multiplier,
        pll0.switch_over_on_lossclk = switch_over_on_lossclk,
        pll0.switch_over_on_gated_lock = switch_over_on_gated_lock,
        pll0.enable_switch_over_counter = enable_switch_over_counter,
        pll0.switch_over_counter    = switch_over_counter,
        pll0.feedback_source        = feedback_source,
        pll0.bandwidth              = bandwidth,
        pll0.bandwidth_type         = bandwidth_type,
        pll0.spread_frequency       = spread_frequency,
        pll0.down_spread            = down_spread,
        pll0.simulation_type        = simulation_type,
        pll0.source_is_pll          = source_is_pll,

        //  internal clock specifications
        pll0.clk5_multiply_by       = clk5_multiply_by,
        pll0.clk4_multiply_by       = clk4_multiply_by, 
        pll0.clk3_multiply_by       = clk3_multiply_by, 
        pll0.clk2_multiply_by       = clk2_multiply_by, 
        pll0.clk1_multiply_by       = clk1_multiply_by, 
        pll0.clk0_multiply_by       = clk0_multiply_by, 
        pll0.clk5_divide_by         = clk5_divide_by,   
        pll0.clk4_divide_by         = clk4_divide_by,   
        pll0.clk3_divide_by         = clk3_divide_by,
        pll0.clk2_divide_by         = clk2_divide_by,
        pll0.clk1_divide_by         = clk1_divide_by,
        pll0.clk0_divide_by         = clk0_divide_by,
        pll0.clk5_phase_shift       = clk5_phase_shift,
        pll0.clk4_phase_shift       = clk4_phase_shift,
        pll0.clk3_phase_shift       = clk3_phase_shift,
        pll0.clk2_phase_shift       = clk2_phase_shift,
        pll0.clk1_phase_shift       = clk1_phase_shift,
        pll0.clk0_phase_shift       = clk0_phase_shift,
        pll0.clk2_phase_shift_num   = clk2_phase_shift_num,
        pll0.clk1_phase_shift_num   = clk1_phase_shift_num,
        pll0.clk0_phase_shift_num   = clk0_phase_shift_num,
        pll0.clk5_time_delay        = clk5_time_delay,
        pll0.clk4_time_delay        = clk4_time_delay,
        pll0.clk3_time_delay        = clk3_time_delay,
        pll0.clk2_time_delay        = clk2_time_delay,
        pll0.clk1_time_delay        = clk1_time_delay,
        pll0.clk0_time_delay        = clk0_time_delay,
        pll0.clk5_duty_cycle        = clk5_duty_cycle,
        pll0.clk4_duty_cycle        = clk4_duty_cycle,
        pll0.clk3_duty_cycle        = clk3_duty_cycle,
        pll0.clk2_duty_cycle        = clk2_duty_cycle,
        pll0.clk1_duty_cycle        = clk1_duty_cycle,
        pll0.clk0_duty_cycle        = clk0_duty_cycle,

        //  external clock specifications
        pll0.extclk3_multiply_by    = extclk3_multiply_by,  
        pll0.extclk2_multiply_by    = extclk2_multiply_by,  
        pll0.extclk1_multiply_by    = extclk1_multiply_by,  
        pll0.extclk0_multiply_by    = extclk0_multiply_by,  
        pll0.extclk3_divide_by      = extclk3_divide_by,
        pll0.extclk2_divide_by      = extclk2_divide_by,
        pll0.extclk1_divide_by      = extclk1_divide_by,
        pll0.extclk0_divide_by      = extclk0_divide_by,
        pll0.extclk3_phase_shift    = extclk3_phase_shift,
        pll0.extclk2_phase_shift    = extclk2_phase_shift,
        pll0.extclk1_phase_shift    = extclk1_phase_shift,
        pll0.extclk0_phase_shift    = extclk0_phase_shift,
        pll0.extclk3_time_delay     = extclk3_time_delay,
        pll0.extclk2_time_delay     = extclk2_time_delay,
        pll0.extclk1_time_delay     = extclk1_time_delay,
        pll0.extclk0_time_delay     = extclk0_time_delay,
        pll0.extclk3_duty_cycle     = extclk3_duty_cycle,
        pll0.extclk2_duty_cycle     = extclk2_duty_cycle,
        pll0.extclk1_duty_cycle     = extclk1_duty_cycle,
        pll0.extclk0_duty_cycle     = extclk0_duty_cycle,
        
        // advanced parameters
        pll0.vco_min                = vco_min,
        pll0.vco_max                = vco_max,
        pll0.vco_center             = vco_center,
        pll0.pfd_min                = pfd_min,
        pll0.pfd_max                = pfd_max,
        pll0.m_initial              = m_initial, 
        pll0.m                      = m,
        pll0.n                      = n,
        pll0.m2                     = m2,
        pll0.n2                     = n2,
        pll0.ss                     = ss,   
        pll0.l0_high                = l0_high,
        pll0.l1_high                = l1_high,
        pll0.g0_high                = g0_high,
        pll0.g1_high                = g1_high,
        pll0.g2_high                = g2_high,
        pll0.g3_high                = g3_high,
        pll0.e0_high                = e0_high,
        pll0.e1_high                = e1_high,
        pll0.e2_high                = e2_high,
        pll0.e3_high                = e3_high,
        pll0.l0_low                 = l0_low,
        pll0.l1_low                 = l1_low,
        pll0.g0_low                 = g0_low,
        pll0.g1_low                 = g1_low,
        pll0.g2_low                 = g2_low,
        pll0.g3_low                 = g3_low,
        pll0.e0_low                 = e0_low,
        pll0.e1_low                 = e1_low,
        pll0.e2_low                 = e2_low,
        pll0.e3_low                 = e3_low,
        pll0.l0_initial             = l0_initial,
        pll0.l1_initial             = l1_initial,
        pll0.g0_initial             = g0_initial,
        pll0.g1_initial             = g1_initial,
        pll0.g2_initial             = g2_initial,
        pll0.g3_initial             = g3_initial,   
        pll0.e0_initial             = e0_initial,
        pll0.e1_initial             = e1_initial,
        pll0.e2_initial             = e2_initial,
        pll0.e3_initial             = e3_initial,
        pll0.l0_mode                = l0_mode,
        pll0.l1_mode                = l1_mode,
        pll0.g0_mode                = g0_mode,
        pll0.g1_mode                = g1_mode,
        pll0.g2_mode                = g2_mode,
        pll0.g3_mode                = g3_mode,
        pll0.e0_mode                = e0_mode,
        pll0.e1_mode                = e1_mode,
        pll0.e2_mode                = e2_mode,
        pll0.e3_mode                = e3_mode,
        pll0.l0_ph                  = l0_ph,
        pll0.l1_ph                  = l1_ph,
        pll0.g0_ph                  = g0_ph,
        pll0.g1_ph                  = g1_ph,
        pll0.g2_ph                  = g2_ph,
        pll0.g3_ph                  = g3_ph,
        pll0.e0_ph                  = e0_ph,
        pll0.e1_ph                  = e1_ph,
        pll0.e2_ph                  = e2_ph,
        pll0.e3_ph                  = e3_ph,
        pll0.m_ph                   = m_ph, 
        pll0.l0_time_delay          = l0_time_delay,    
        pll0.l1_time_delay          = l1_time_delay,
        pll0.g0_time_delay          = g0_time_delay,
        pll0.g1_time_delay          = g1_time_delay,
        pll0.g2_time_delay          = g2_time_delay,
        pll0.g3_time_delay          = g3_time_delay,
        pll0.e0_time_delay          = e0_time_delay,
        pll0.e1_time_delay          = e1_time_delay,
        pll0.e2_time_delay          = e2_time_delay,
        pll0.e3_time_delay          = e3_time_delay,
        pll0.m_time_delay           = m_time_delay,
        pll0.n_time_delay           = n_time_delay,
        pll0.extclk3_counter        = extclk3_counter,
        pll0.extclk2_counter        = extclk2_counter,
        pll0.extclk1_counter        = extclk1_counter,
        pll0.extclk0_counter        = extclk0_counter,
        pll0.clk5_counter           = clk5_counter,
        pll0.clk4_counter           = clk4_counter,
        pll0.clk3_counter           = clk3_counter,
        pll0.clk2_counter           = clk2_counter,
        pll0.clk1_counter           = clk1_counter,
        pll0.clk0_counter           = clk0_counter,
        pll0.enable0_counter        = enable0_counter,
        pll0.enable1_counter        = enable1_counter,
        pll0.charge_pump_current    = charge_pump_current,
        pll0.loop_filter_r          = loop_filter_r,
        pll0.loop_filter_c          = loop_filter_c;

endmodule //altpll

//START_MODULE_NAME----------------------------------------------------
//
// Module Name     :    altlvds_rx  
//
// Description     :   Low Voltage Differential Signaling (LVDS) receiver
//                     megafunction. The altlvds_rx megafunction implements a
//                     deserialization receiver. LVDS is a high speed IO interface
//                     that uses inputs without a reference voltage. LVDS uses
//                     two wires carrying differential values to create a single
//                     channel. These wires are connected to two pins on
//                     supported device to create a single LVDS channel
//
// Limitation      :   Only available for APEX20KE, APEXII, MERCURY, STRATIX and
//                     STRATIX GX families.
//
// Results expected:   output clock, deserialized output data and pll locked
//                     signal.
//
//END_MODULE_NAME----------------------------------------------------

// BEGINNING OF MODULE
`timescale 1 ps / 1 ps



// MODULE DECLARATION
module altlvds_rx (
    rx_in,
    rx_inclock,
    rx_deskew,
    rx_pll_enable,
    rx_data_align,
    rx_reset,
    rx_dpll_reset,
    rx_channel_data_align,
    rx_coreclk,
    pll_areset,
    rx_out,
    rx_outclock,
    rx_locked,
    rx_dpa_locked
);

// GLOBAL PARAMETER DECLARATION
    parameter number_of_channels = 1;
    parameter deserialization_factor = 4;
    parameter registered_output = "ON";
    parameter inclock_period = 10000;
    parameter inclock_boost = deserialization_factor;
    parameter cds_mode = "UNUSED";
    parameter intended_device_family = "APEX20KE";
    parameter input_data_rate =0;
    parameter inclock_data_alignment = "EDGE_ALIGNED";
    parameter registered_data_align_input = "ON";
    parameter common_rx_tx_pll = "ON";
    parameter enable_dpa_mode = "OFF";
    parameter enable_dpa_fifo = "ON";
    parameter use_dpll_rawperror = "OFF";
    parameter use_coreclock_input = "OFF";
    parameter dpll_lock_count = 0;
    parameter dpll_lock_window = 0;
    parameter outclock_resource = "AUTO";
    parameter lpm_hint = "UNUSED";
    parameter lpm_type = "altlvds_rx";
    parameter clk_src_is_pll = "off";

// LOCAL PARAMETER DECLARATION

    // A APEX20KE type of LVDS?
    parameter APEX20KE_RX_STYLE = ((intended_device_family == "APEX20KE") ||
                                   (intended_device_family == "APEX20KC") ||
                                   (intended_device_family == "EXCALIBUR_ARM") ||
                                   (intended_device_family == "EXCALIBUR_MIPS"))
                                    ? 1 : 0;

    // A APEXII type of LVDS?
    parameter APEXII_RX_STYLE = ((intended_device_family == "APEXII") ||
                                 (intended_device_family == "APEX II"))
                                 ? 1 : 0;

    // A MERCURY type of LVDS?
    parameter MERCURY_RX_STYLE = ((intended_device_family == "MERCURY") || 
                                  (intended_device_family == "Mercury"))
                                 ? 1 : 0;

    // A STRATIX type of LVDS?
    parameter STRATIX_RX_STYLE =  ((intended_device_family == "Stratix") ||
                                 (((intended_device_family == "STRATIXGX")||
                                   (intended_device_family == "Stratix GX")) && 
                                   (enable_dpa_mode == "OFF")))
                                 ? 1 : 0;

    // A AURORA DPA type of LVDS?
    parameter STRATIXGX_DPA_RX_STYLE = (((intended_device_family == "STRATIXGX") ||
                                         (intended_device_family == "Stratix GX")) &&
                                         (enable_dpa_mode == "ON"))
                                       ? 1 : 0;


    // Parameter to check whether the selected lvds trasmitter use hold register or not
    parameter RX_NEED_HOLD_REG = (((APEX20KE_RX_STYLE == 1) && (deserialization_factor == 4 )) ||
                                  ((APEXII_RX_STYLE   == 1) && (deserialization_factor == 4))  ||
                                  ((MERCURY_RX_STYLE  == 1) && (deserialization_factor > 2) &&
                                   (deserialization_factor < 7)) ||
                                   (STRATIX_RX_STYLE  == 1))
                                 ? 1 : 0;

    // calculate clock boost for device family other than STRATIX and STRATIX GX
    parameter INT_CLOCK_BOOST = (APEX20KE_RX_STYLE == 1)
                                 ? deserialization_factor :
                                 ( (inclock_boost == 0) ? deserialization_factor : inclock_boost);

    // calculate clock boost for STRATIX and STRATIX GX
    parameter STRATIX_INCLOCK_BOOST = ((input_data_rate !=0) && (inclock_period !=0))
                                      ? (((input_data_rate * inclock_period) + (5 * 100000)) / 1000000) :
                                         ((inclock_boost == 0) ? deserialization_factor : inclock_boost);


    // phase_shift delay. Add 0.5 to the calculated result to round up result to the nearest integer.
    parameter PHASE_SHIFT = (inclock_data_alignment == "EDGE_ALIGNED")? 0:
                            (inclock_data_alignment == "CENTER_ALIGNED")? (0.5 * inclock_period / STRATIX_INCLOCK_BOOST) + 0.5 :
                            (inclock_data_alignment == "45_DEGREES")? (0.125 * inclock_period / STRATIX_INCLOCK_BOOST) + 0.5 :
                            (inclock_data_alignment == "90_DEGREES")? (0.25 * inclock_period / STRATIX_INCLOCK_BOOST) + 0.5 :
                            (inclock_data_alignment == "135_DEGREES")? (0.375 * inclock_period / STRATIX_INCLOCK_BOOST) + 0.5 :
                            (inclock_data_alignment == "180_DEGREES")? (0.5 * inclock_period / STRATIX_INCLOCK_BOOST) + 0.5 :
                            (inclock_data_alignment == "225_DEGREES")? (0.625 * inclock_period / STRATIX_INCLOCK_BOOST) + 0.5 :
                            (inclock_data_alignment == "270_DEGREES")? (0.75 * inclock_period / STRATIX_INCLOCK_BOOST) + 0.5 :
                            (inclock_data_alignment == "315_DEGREES")? (0.875 * inclock_period / STRATIX_INCLOCK_BOOST) + 0.5 : 0;

    parameter REGISTER_WIDTH = deserialization_factor*number_of_channels;


// INPUT PORT DECLARATION
    input [number_of_channels -1 :0] rx_in;
    input rx_inclock;
    input rx_deskew;
    input rx_pll_enable;
    input rx_data_align;
    input [number_of_channels -1 :0] rx_reset;
    input [number_of_channels -1 :0] rx_dpll_reset;
    input [number_of_channels -1 :0] rx_channel_data_align;
    input [number_of_channels -1 :0] rx_coreclk;
    input pll_areset;

// OUTPUT PORT DECLARATION
    output [REGISTER_WIDTH -1: 0] rx_out;
    output rx_outclock;
    output rx_locked;
    output [number_of_channels -1: 0] rx_dpa_locked;


// INTERNAL REGISTERS DECLARATION
    reg [REGISTER_WIDTH -1 : 0] pattern;
    reg [REGISTER_WIDTH -1 : 0] dpa_data_int;
    reg [REGISTER_WIDTH -1 : 0] rx_shift_reg;
    reg [REGISTER_WIDTH -1 : 0] rx_parallel_load_reg;
    reg [REGISTER_WIDTH -1 : 0] rx_out_reg;
    reg [REGISTER_WIDTH -1 : 0] rx_out_hold;
    reg [number_of_channels-1 : 0] rx_in_pipe;
    reg [number_of_channels-1 : 0] deskew_done;
    reg [number_of_channels-1 : 0] calibrate;
    reg fb;
    reg rx_mercury_slow_clock;
    reg [deserialization_factor-1 : 0] temp;
    reg [deserialization_factor-1 : 0] deskew_pattern;
    reg rx_clock1_int_pre;
    reg disable_load_register;
    reg [REGISTER_WIDTH -1 : 0] rxpdat2;
    reg [REGISTER_WIDTH -1 : 0] rxpdat3;
    reg [REGISTER_WIDTH -1 : 0] rxpdatout;
    reg [REGISTER_WIDTH -1 : 0] serdes_data_out;
    reg [REGISTER_WIDTH -1 : 0] read_data;
    reg [number_of_channels -1 : 0] rx_coreclk_pre;
    reg [number_of_channels -1 : 0] rx_channel_data_align_pre;
    reg [REGISTER_WIDTH -1 : 0]  ram_array [3 : 0];
    reg [REGISTER_WIDTH -1 : 0] ram_array_temp;
    reg rx_data_align_reg;
    reg start_data_align;
    reg nce;
    reg nce_rega;
    reg enable0;
    reg enable0_reg;
    reg enable0_reg1;
    reg enable0_neg;
    reg enable1;
    reg enable1_reg;
    reg neg_edge_happened;
    reg [number_of_channels -1 : 0] clkout_tmp;
    reg [number_of_channels -1 : 0] pclk_pre;
    reg [number_of_channels -1 : 0] sync_reset;
    reg enable_negedge_count;


// INTERNAL WIRE DECLARATION
    wire [REGISTER_WIDTH -1 : 0] rx_out_int;
    wire rx_clock0_int;
    wire rx_clock1_int;
    wire rx_outclk_int;
    wire rx_hold_clk;
    wire rx_reg_clk;
    wire rx_pll_clk0;
    wire rx_pll_clk1;
    wire rx_locked_int;
    wire unused_clk2;
    wire unused_clk_ext;
    wire [REGISTER_WIDTH -1 : 0] rxpdat1;
    wire [REGISTER_WIDTH -1 : 0] write_data;
    wire [5:0] stratix_clk;
    wire stratix_locked;
    wire [1:0] apex_clk;
    wire apex_locked;
    wire non_stratix_inclock;
    wire [1:0] stratix_inclock;
    wire[5:0] stratix_clkena;
    wire[number_of_channels -1:0] pclk;
    wire rx_data_align_int;

// INTERNAL TRI DECLARATION
    tri0 rx_deskew;
    tri1 rx_pll_enable;
    tri0 rx_data_align;
    tri0[number_of_channels -1 :0] rx_reset;
    tri0[number_of_channels -1 :0] rx_dpll_reset;
    tri0[number_of_channels -1 :0] rx_channel_data_align;
    tri0[number_of_channels -1 :0] rx_coreclk;
    tri0 pll_areset;

// LOCAL INTEGER DECLARATION
    integer count [number_of_channels-1 : 0];
    integer sample;
    integer i;
    integer j;
    integer k;
    integer x;
    integer posedge_count;
    integer negedge_count;
    integer negedge_count2;
    integer rxin_cnt;
    integer start_data;
    integer check_deskew_pattern;
    integer dpa_edge_count [number_of_channels - 1 : 0];
    integer rd_index [number_of_channels - 1 : 0];
    integer wr_index [number_of_channels - 1 : 0];
    integer dpa_posedge_count  [number_of_channels - 1 : 0];
    integer count2 [number_of_channels -1: 0];
    integer count3 [number_of_channels -1: 0];
    integer fast_clk_count[number_of_channels -1: 0];


// INITIAL CONSTRUCT BLOCK
    initial
    begin : INITIALIZATION
        disable_load_register = 1'b0;
        rx_clock1_int_pre = 1'b0;
        rxpdat2 = {1{1'b0}};
        rxpdat3 = {1{1'b0}};
        rxpdatout = {1{1'b0}};
        ram_array_temp = {1{1'b0}};
        fb = 'b1;
        rxin_cnt = 0;
        negedge_count = 0;
        negedge_count2 = 0;
        posedge_count = 0;
        start_data = 0;
        rx_data_align_reg =0;
        start_data_align =0;
        nce = 0;
        nce_rega = 0;
        enable0 = 0;
        enable0_neg=0;
        enable0_reg=0;
        enable0_reg1 = 0;
        enable1 = 0;
        enable1_reg =0;
        neg_edge_happened =0;
        enable_negedge_count = 0;

        for (i = 0; i < 4; i = i + 1)
        begin
            ram_array[i] = ram_array_temp;
        end

        for (i = 0; i < number_of_channels; i = i + 1)
        begin
            deskew_done[i] = 1;
            calibrate[i] = 0;
            count[i] = 0;
            count2[i] = 0;
            count3[i] = 0;

            rx_in_pipe = 0;
            dpa_posedge_count[i] = 0;
            rd_index[i] = 2;
            wr_index[i] = 0;
            dpa_edge_count[i] = 0;
            rx_coreclk_pre[i] = 1'b0;
            rx_channel_data_align_pre[i] = 1'b0;
            clkout_tmp[i] = 1'b0;
            fast_clk_count[i] = deserialization_factor;
            sync_reset[i] = 1'b0;
        end

        for (i = 0; i < REGISTER_WIDTH; i = i + 1)
        begin
            rx_out_reg[i] = 0;
            rx_out_hold[i] = 0;
            rx_shift_reg[i] = 0;
            rx_parallel_load_reg[i] = 0;
            dpa_data_int[i] = 0;
            read_data[i] = 0;
            serdes_data_out[i] = 0;
        end

        // Check for illegal mode settings
        if ((APEX20KE_RX_STYLE == 1) &&
            (deserialization_factor != 4) && (deserialization_factor != 7) && 
            (deserialization_factor != 8))
        begin
            $display ($time, "ps Error: APEX20KE does not support the specified deserialization factor!");
            $stop;
        end
        else if ((MERCURY_RX_STYLE == 1) &&
            (((deserialization_factor > 12) && (deserialization_factor != 14) &&
            (deserialization_factor != 16) && (deserialization_factor != 18) &&
            (deserialization_factor != 20)) || (deserialization_factor<3)))
        begin
            $display ($time, "ps Error: MERCURY does not support the specified deserialization factor!");
            $stop;
        end
        else if ((APEXII_RX_STYLE == 1) &&
            ((deserialization_factor > 10) || (deserialization_factor < 4)))
        begin
            $display ($time, "ps Error: APEXII does not support the specified deserialization factor!");
            $stop;
        end
        else if ((STRATIX_RX_STYLE == 1) &&
            ((deserialization_factor > 10) || (deserialization_factor < 4)))
        begin
            $display ($time, "ps Error: STRATIX or STRATIXGX in non DPA mode does not support the specified deserialization factor!");
            $stop;
        end
        else if ((STRATIXGX_DPA_RX_STYLE == 1) && (deserialization_factor != 8) && (deserialization_factor != 10))
        begin
            $display ($time, "ps Error: STRATIXGX in DPA mode does not support the specified deserialization factor!");
            $stop;
        end

        // Initialise calibration pattern variables. Only for APEX20KE and APEXII
        if  ((APEX20KE_RX_STYLE == 1) &&
            ((deserialization_factor == 4) || (deserialization_factor == 7) || 
            (deserialization_factor == 8)))
        begin
              check_deskew_pattern = 1;
              case (deserialization_factor)
                8: deskew_pattern = 8'b00111100;
                7: deskew_pattern = 7'b0011100;
                4: deskew_pattern = 4'b1100;
                default ;
              endcase
        end
        else
        if (((APEXII_RX_STYLE == 1)) && (deserialization_factor <= 10) && 
            (deserialization_factor >= 4))
        begin
              check_deskew_pattern = 1;
            if (cds_mode == "SINGLE_BIT")
            begin
                case (deserialization_factor)
                    10: deskew_pattern = 10'b0000011111;
                    9: deskew_pattern = 9'b000001111;
                    8: deskew_pattern = 8'b00001111;
                    7: deskew_pattern = 7'b0000111;
                    6: deskew_pattern = 6'b000111;
                    5: deskew_pattern = 5'b00011;
                    4: deskew_pattern = 4'b0011;
                    default ;
                endcase
              end
            else 
            begin
                case (deserialization_factor)
                    10: deskew_pattern = 10'b0101010101;
                    9: deskew_pattern = 9'b010101010;
                    8: deskew_pattern = 8'b01010101;
                    7: deskew_pattern = 7'b0101010;
                    6: deskew_pattern = 6'b010101;
                    5: deskew_pattern = 5'b01010;
                    4: deskew_pattern = 4'b0101;
                    default ;
                endcase
              end
        end 
        else check_deskew_pattern = 0;
       
    end //INITIALIZATION



/// COMPONENT INSTANTIATIONS

    // pll for device family other than STRATIX and STRATIXGX
    altclklock u0 (.inclock(non_stratix_inclock),
                   .inclocken(rx_pll_enable),
                   .fbin(fb),
                   .clock0(apex_clk [0]),
                   .clock1(apex_clk[1]),
                   .clock2(unused_clk2),
                   .clock_ext(unused_clk_ext),
                   .locked(apex_locked));

    defparam
        u0.inclock_period         = inclock_period,
        u0.clock0_boost           = INT_CLOCK_BOOST,
        u0.clock1_boost           = INT_CLOCK_BOOST,
        u0.clock1_divide          = deserialization_factor,
        u0.valid_lock_cycles      = ((MERCURY_RX_STYLE == 1) || (APEXII_RX_STYLE == 1)) ? 3 : 5,
        u0.intended_device_family = intended_device_family;

    // pll for STRATIX and STRATIX GX
    altpll u1 (.inclk(stratix_inclock),
               .pllena(rx_pll_enable),
               .areset(pll_areset),
               .clkena(stratix_clkena),
               .clk (stratix_clk),
               .locked(stratix_locked),
               .fbin(),
               .clkswitch(),
               .pfdena(),
               .extclkena(),
               .scanclk(),
               .scanaclr(),
               .scandata(),
               .extclk(),
               .clkbad(),
               .activeclock(),
               .clkloss(),
               .scandataout());

    defparam
        u1.inclk0_input_frequency = inclock_period,
        u1.inclk1_input_frequency = inclock_period,
        u1.clk0_multiply_by       = STRATIX_INCLOCK_BOOST,
        u1.clk1_multiply_by       = STRATIX_INCLOCK_BOOST,
        u1.clk1_divide_by         = deserialization_factor,
        u1.clk0_phase_shift_num   = PHASE_SHIFT,
        u1.clk1_phase_shift_num   = PHASE_SHIFT,
        u1.intended_device_family = intended_device_family,
        u1.source_is_pll          = clk_src_is_pll;


// ALWAYS CONSTRUCT BLOCK

    // When the data realignment feature is used,
    //nce is used to stall the negedge_count which is used to generate enable0 signal
    always @(start_data_align)
    begin : DATA_REALIGNMENT
            if (start_data_align == 1)
            begin
                nce <= 1;
            end
    end // DATA_REALIGNMENT


    // slow clock
    always @ (rx_pll_clk1)
    begin : SLOW_CLOCK
        if (rx_pll_clk1 == 1)
        begin
            if (STRATIX_RX_STYLE == 0)
            begin
                negedge_count = 0;
            end

            enable_negedge_count = 1;
            rx_mercury_slow_clock <= rx_pll_clk1;

            if (rx_deskew == 0)
                for (i = 0; i <= number_of_channels-1; i = i+1)
                    calibrate[i] <= 0;
            
            // In order to assure that the circuit is capturing data accurately the user must calibrate the LVDS data channels by
            // asserting a deskew signal and applying the appropriate calibration value for 3 clock cycles to deskew the channel after 3 clock cycles.
            if (check_deskew_pattern == 1)
            begin
                for (j = 0; j <= number_of_channels-1; j = j+1)
                begin
                    if (calibrate[j] == 1)
                    begin
                        for (i = 0; i < deserialization_factor; i = i + 1)
                            temp[i] = pattern[deserialization_factor*j +i];

                        if ((temp == deskew_pattern) || ((temp == ~deskew_pattern) &&
                            ((APEXII_RX_STYLE == 1)) && (cds_mode == "MULTIPLE_BIT")))
                            count[j] = count[j] + 1;
                        else
                            count[j] = 0;

                        if (count[j] >= 3)
                            deskew_done[j] <= #((inclock_period/deserialization_factor)*2) 1;
                    end
                end
            end
            else
               for (i = 0; i <= number_of_channels-1; i = i+1)
                   deskew_done[i] <= 1;
       end
    end // SLOW_CLOCK

    // Activate calibration mode
    always @ (rx_deskew)
    begin : CALIBRATION
        if (rx_deskew == 1)
            for (i = 0; i <= number_of_channels-1; i = i+1)
            begin
                deskew_done[i] = 0;
                calibrate[i] = 1;
            end
    end // CALIBRATION

    // Fast clock
    always @ (rx_clock0_int)
    begin  : FAST_CLOCK
        if(rx_locked_int == 1)
        begin
            if (deserialization_factor > 1)
            begin
                if (rx_clock0_int == 0)
                begin
                    neg_edge_happened = 1;

                    if (STRATIX_RX_STYLE == 1)
                    begin
                        if ((negedge_count == deserialization_factor) && (nce == 0))
                        begin
                            negedge_count = 0;
                        end

                        if (negedge_count2 == deserialization_factor)
                        begin
                            negedge_count2 = 0;
                        end
                    end

                    if(enable_negedge_count == 1)
                    begin
                        if (nce == 0)
                        begin
                            negedge_count = negedge_count + 1;
                        end

                        negedge_count2 = negedge_count2 + 1;
                    end 


                    // For APEX and Mercury families, load data on the
                    // 3rd negative edge of the fast clock
                    if ((negedge_count == 3) && (STRATIX_RX_STYLE == 0))
                    begin
                        if (start_data == 0)
                        begin
                            start_data = 1;
                        end

                        if (rx_deskew == 0)
                        begin
                           rx_parallel_load_reg <= rx_shift_reg;
                        end
                        rxin_cnt = 0;
                    end


                    // For Stratix and Stratix GX non-DPA mode, load data
                    // when the registered load enable signal is high
                    if ((enable0_neg == 1) & (STRATIX_RX_STYLE == 1))
                    begin
                        rx_parallel_load_reg <= rx_shift_reg;
                    end

                    // Registering the enable0 signal
                    enable0 <= (negedge_count == deserialization_factor) ? 1 : 0;
                    enable0_neg <= enable0_reg1;
                    enable1 <= (negedge_count2 == deserialization_factor) ? 1 : 0;


                    // Loading input data to shift register
                    if (start_data == 1)
                    begin
                        sample = rxin_cnt % deserialization_factor;
                        rxin_cnt = rxin_cnt + 1;
                        for (i= 0; i < number_of_channels; i = i+1)
                        begin
                            if((STRATIX_RX_STYLE == 1) || (APEXII_RX_STYLE == 1))
                            begin
                                for (x=deserialization_factor-1; x >0; x=x-1)
                                begin
                                    rx_shift_reg[x + (i * deserialization_factor)] <=  rx_shift_reg [x-1 + (i * deserialization_factor)];
                                end
                                rx_shift_reg[i * deserialization_factor] <= rx_in[i];
                            end
                            else
                            begin
                                if (deskew_done[i] == 1)
                                begin
                                    // Data gets shifted into MSB first
                                    rx_shift_reg[(i+1)*deserialization_factor-sample-1] <= rx_in[i];
                                end
                                else
                                begin
                                    if(APEXII_RX_STYLE == 1)
                                    begin
                                        for (x=deserialization_factor-1; x >0; x=x-1)
                                        begin
                                            pattern[x + (i * deserialization_factor)] <=  pattern [x-1 + (i * deserialization_factor)];
                                        end
                                        pattern[i * deserialization_factor] <= rx_in[i];
                                    end
                                    else
                                        pattern[(i+1)*deserialization_factor-sample-1] <= rx_in[i];

                                    rx_shift_reg[(i+1)*deserialization_factor-sample-1] <= 'bx;
                                end
                            end
                        end
                    end
                end
                else
                begin
                    if (rx_clock0_int == 1)
                    begin
                        if((negedge_count2 == 1) && (STRATIX_RX_STYLE == 1))
                        begin
                            posedge_count = 1;
                        end

                        posedge_count = (posedge_count+1) % deserialization_factor;

                        // Generating slow clock for MERCURY
                        if (posedge_count==((deserialization_factor+1)/2+1))
                        begin
                            rx_mercury_slow_clock <= ~rx_mercury_slow_clock;
                        end

                        if (neg_edge_happened ==1)
                        begin
                            nce <= 0;
                        end

                        // enable loading incoming data to shift register
                        start_data <= 1;

                        if (posedge_count == 1)
                        begin
                           nce_rega <= (registered_data_align_input == "ON")? rx_data_align_reg : rx_data_align_int;
                           rx_data_align_reg <= rx_data_align_int;
                        end
                        else if (posedge_count == 3)
                        begin
                            start_data_align <= nce_rega;
                        end

                        // Registering enable0, enable1
                        enable0_reg1 <= enable0_reg;
                        enable0_reg <= enable0;
                        enable1_reg <= enable1;
                        neg_edge_happened <= 0;
                    end
                end
            end
        end
    end // FAST_CLOCK


    // synchronization register
    always @ (rx_reg_clk)
    begin : SYNC_REGISTER
        if (deserialization_factor > 1)
        begin
            if (rx_reg_clk == 1)
              rx_out_reg <= rx_out_int;
        end
    end // SYNC_REGISTER

    // hold register
    always @ (rx_hold_clk)
    begin : HOLD_REGISTER
        if (deserialization_factor > 1)
        begin
            if ( ((rx_hold_clk == 0) && (STRATIX_RX_STYLE == 0)) ||
                  ((rx_hold_clk == 1) && (STRATIX_RX_STYLE == 1)) )
                rx_out_hold <= rx_parallel_load_reg;
        end
    end // HOLD_REGISTER


///////////////////////////STRATIXGX DPA internal model////////////////////////////////////

    //deserializer logic
    always @ (rx_clock1_int  or rx_coreclk)
    begin : DPA_SERDES_SLOW_CLOCK

        if (STRATIXGX_DPA_RX_STYLE == 1)
        begin
            for(i = 0; i <=number_of_channels -1; i=i+1)
            begin
                if ((use_coreclock_input == "ON" && rx_coreclk_pre[i] == 1'b0 && rx_coreclk[i] == 1'b1) ||
                    (use_coreclock_input == "OFF" && rx_clock1_int == 1'b1 && rx_clock1_int_pre == 1'b0))
                begin
                    dpa_edge_count[i] = 0;
                    dpa_posedge_count[i] = 0;
                    disable_load_register = 1'b0;

                    if ((rx_reset[i] == 1'b1) || (rx_dpll_reset[i] == 1'b1))
                    begin
                        sync_reset[i] <= 1'b1;
                    end
                    else
                    begin
                        sync_reset[i] <= 1'b0;
                    end
                end

                rx_coreclk_pre[i] <= rx_coreclk[i];
                rx_clock1_int_pre <= rx_clock1_int;
            end
        end
    end // DPA_SERDES_SLOW_CLOCK


    always @ (posedge rx_clock0_int)
    begin : DPA_SERDES_POSEDGE_FAST_CLOCK
        for(i = 0; i <=number_of_channels -1; i=i+1)
        begin
            if (dpa_edge_count[i] == 2)
            begin
                if (disable_load_register == 1'b0)
                begin
                    serdes_data_out <= dpa_data_int;
                end
            end

            if (sync_reset[i] == 1'b1)
            begin
                fast_clk_count[i] = deserialization_factor;
                clkout_tmp[i] = 1'b0;
            end
            else
            begin
                if (fast_clk_count[i] == deserialization_factor)
                begin
                    fast_clk_count[i] = 0;
                    clkout_tmp[i] <= !clkout_tmp[i];
                end
                else if (fast_clk_count[i] == (deserialization_factor+1)/2)
                begin
                    clkout_tmp[i] <= !clkout_tmp[i];
                end
                    fast_clk_count[i] = fast_clk_count[i] + 1;

            end

            dpa_posedge_count[i] =  dpa_posedge_count[i] + 1;
        end
    end // DPA_SERDES_POSEDGE_FAST_CLOCK

    always @ (negedge rx_clock0_int)
    begin : DPA_SERDES_NEGEDGE_FAST_CLOCK

        if (STRATIXGX_DPA_RX_STYLE == 1)
        begin
            if (rx_clock0_int == 1'b0)
            begin

                for (i = 0; i <= number_of_channels -1; i = i+1)
                begin

                    if (sync_reset[i] == 1'b1)
                    begin
                        for (j = i*deserialization_factor; j <= (i+1)*deserialization_factor -1; j=j+1)
                        begin
                            dpa_data_int[j] = 1'b0;
                        end
                        serdes_data_out <= dpa_data_int;
                        dpa_edge_count[i] = 0;
                        disable_load_register <= 1'b1;
                    end
                    else
                    begin
                       // Data gets shifted into MSB first.
                        for (x=deserialization_factor-1; x > 0; x=x-1)
                        begin
                            dpa_data_int[x + (i * deserialization_factor)] <=  dpa_data_int [x-1 + (i * deserialization_factor)];
                        end

                        dpa_data_int[i * deserialization_factor] <= rx_in_pipe[i];
                    end

                    rx_in_pipe <= rx_in;

                    if (((use_coreclock_input == "ON") && (dpa_posedge_count[i] > 0)) ||
                       (use_coreclock_input == "OFF"))
                    begin
                        dpa_edge_count[i] = (dpa_edge_count[i] + 1) ;
                    end

                end
            end
        end
    end // DPA_SERDES_NEGEDGE_FAST_CLOCK


    //phase compensation FIFO

    always @ (pclk)
    begin : DPA_FIFO_WRITE_CLOCK
        reg enable_fifo;
    
        if(rx_locked_int == 1'b1)
        begin
            enable_fifo = 1'b1;
        end 

        if ((STRATIXGX_DPA_RX_STYLE == 1) && (enable_dpa_fifo == "ON")  && (enable_fifo == 1'b1))
        begin
            for (i = 0; i <= number_of_channels-1; i = i+1)
            begin
                if(sync_reset[i] == 1'b1)
                begin
                    wr_index[i] = 0;
                end
                else if ((pclk[i] == 1'b1) && (pclk_pre[i] == 1'b0))
                begin
                    ram_array[wr_index[i]] = write_data;
                    wr_index[i] = (wr_index[i] + 1) % 4;
                end
                    pclk_pre[i] <= pclk[i];
            end
        end
    end // DPA_FIFO_WRITE_CLOCK


    always @ (rx_clock1_int or rx_coreclk)
    begin : DPA_FIFO_SLOW_CLOCK
        reg enable_fifo;

        if(rx_locked_int == 1'b1 & $time > 100000)
        begin
            enable_fifo = 1'b1;
        end    


        if((STRATIXGX_DPA_RX_STYLE == 1) && (enable_dpa_fifo == "ON") && (enable_fifo == 1'b1))
        begin
            for (i = 0; i <= number_of_channels-1; i = i+1)
            begin
                if (((use_coreclock_input == "ON") && (rx_coreclk[i] == 1'b1) && (rx_coreclk_pre[i] == 1'b0)) || 
                ((use_coreclock_input == "OFF") && (rx_clock1_int == 1'b1) && (rx_clock1_int_pre == 1'b0)))
                begin
                    if (sync_reset[i] == 1'b1)
                    begin
                        for (j = i*deserialization_factor; j <= (i+1)*deserialization_factor -1; j=j+1)
                        begin
                            read_data[j] <=  1'b0;
                        end

                        for (j = 0; j <= 3; j= j+1)
                        begin
                            ram_array_temp =ram_array[j];
                            for (k = i*deserialization_factor; k <= (i+1)*deserialization_factor -1; k=k+1)
                            begin
                                ram_array_temp[k] =  1'b0;
                            end
                            ram_array[j] = ram_array_temp;
                        end
                        wr_index[i] = 0;
                        rd_index[i] = 2;
                    end
                    else
                    begin
                        ram_array_temp =ram_array[rd_index[i]];
                        for (j = i*deserialization_factor; j <= (i+1)*deserialization_factor -1; j=j+1)
                        begin
                            read_data[j] <= ram_array_temp[j];
                        end
                        ram_array[rd_index[i]] = ram_array_temp;
                        rd_index[i] = (rd_index[i] + 1) % 4;
                    end
                end
                rx_coreclk_pre[i] <= rx_coreclk[i];
                rx_clock1_int_pre <= rx_clock1_int;
            end
        end
    end // DPA_FIFO_SLOW_CLOCK


    //bit-slipping logic
    always @ (rx_coreclk or rx_clock1_int or rx_channel_data_align or rx_reset or rx_dpll_reset)
    begin : DPA_BIT_SLIP

        if (STRATIXGX_DPA_RX_STYLE == 1)
        begin

            for (i = 0; i <= number_of_channels-1; i = i + 1)
            begin
                if (((use_coreclock_input == "ON") && (rx_coreclk[i] == 1'b1) && (rx_coreclk_pre[i] == 1'b0)) |
                ((use_coreclock_input == "OFF") && (rx_clock1_int == 1'b1) && (rx_clock1_int_pre == 1'b0)))
                begin
                    count3[i] = count2[i];
                    count2[i] = count[i];

                    if ((rx_channel_data_align[i] == 1'b1) && (rx_channel_data_align_pre[i] == 1'b0))
                    begin
                        count[i] = (count[i] + 1) % deserialization_factor;
                    end

                    if ((rx_reset[i] == 1'b1) || (rx_dpll_reset[i] == 1'b1))
                    begin
                        for(j = deserialization_factor*i; j <= deserialization_factor*(i+1) -1; j=j+1)
                        begin
                            rxpdat2[j] <= 1'b0;
                            rxpdat3[j] <= 1'b0;
                            rxpdatout[j] <= 1'b0;
                        end
                            count[i] = 0;
                            count2[i] = 0;
                            count3[i] = 0;
                    end
                    else
                    begin
                        rxpdat2 <= rxpdat1;
                        rxpdat3 <= rxpdat2;

                        case (count3[i])
                            0:  begin
                                    for(j = deserialization_factor*i; j <= deserialization_factor*(i+1) -1; j=j+1)
                                    begin
                                        rxpdatout[j] <=  rxpdat3[j];
                                    end
                                end


                            1:  begin  //(RXPDAT3[8:0],RXPDAT2[9]
                                    for(j = deserialization_factor*i + 1; j <= deserialization_factor*(i+1) -1; j=j+1)
                                    begin
                                        rxpdatout[j] <=  rxpdat3[j-1];
                                    end

                                    rxpdatout[deserialization_factor*i] <=   rxpdat2[deserialization_factor*(i+1) -1];
                                end

                            2:  begin    //(RXPDAT3[7:0],RXPDAT2[9:8]
                                    for(j = deserialization_factor*i + 2; j <= deserialization_factor*(i+1) -1; j=j+1)
                                    begin
                                        rxpdatout[j] <=  rxpdat3[j-2];
                                    end

                                    for(j = deserialization_factor*i ; j <= deserialization_factor*i + 1; j=j+1)
                                    begin
                                        rxpdatout[j] <=  rxpdat2[j+ deserialization_factor -2];
                                    end
                                end

                            3:  begin  //(RXPDAT3[6:0],RXPDAT2[9:7]
                                    for(j = deserialization_factor*i + 3; j <= deserialization_factor*(i+1) -1; j=j+1)
                                    begin
                                        rxpdatout[j] <=  rxpdat3[j-3];
                                    end

                                    for(j = deserialization_factor*i; j <= deserialization_factor*i + 2; j=j+1)
                                    begin
                                        rxpdatout[j] <=  rxpdat2[j+deserialization_factor -3];
                                    end
                                end

                            4:  begin  //(RXPDAT3[5:0],RXPDAT2[9:6]
                                    for(j = deserialization_factor*i + 4; j <= deserialization_factor*(i+1) -1; j=j+1)
                                    begin
                                        rxpdatout[j] <=  rxpdat3[j-4];
                                    end

                                    for(j = deserialization_factor*i; j <= deserialization_factor*i +3; j=j+1)
                                    begin
                                        rxpdatout[j] <=  rxpdat2[j+deserialization_factor -4];
                                    end
                                end

                            5:  begin   //(RXPDAT3[4:0],RXPDAT2[9:5]
                                    for(j = deserialization_factor*i + 5; j <= deserialization_factor*(i+1) -1; j=j+1)
                                    begin
                                        rxpdatout[j] <=  rxpdat3[j-5];
                                    end

                                    for(j = deserialization_factor*i; j <= deserialization_factor*i+4; j=j+1)
                                    begin
                                        rxpdatout[j] <=  rxpdat2[j+deserialization_factor -5];
                                    end
                                end

                            6:  begin   //(RXPDAT3[3:0],RXPDAT2[9:4]
                                    for(j = deserialization_factor*i + 6; j <= deserialization_factor*(i+1) -1; j=j+1)
                                    begin
                                        rxpdatout[j] <=  rxpdat3[j-6];
                                    end

                                    for(j = deserialization_factor*i; j <= deserialization_factor*i+5; j=j+1)
                                    begin
                                        rxpdatout[j] <=  rxpdat2[j+deserialization_factor -6];
                                    end
                                end

                            7:  begin   //(RXPDAT3[2:0],RXPDAT2[9:3]
                                    for(j = deserialization_factor*i + 7; j <= deserialization_factor*(i+1) -1; j=j+1)
                                    begin
                                        rxpdatout[j] <=  rxpdat3[j-7];
                                    end

                                    for(j = deserialization_factor*i; j <= deserialization_factor*i +6; j=j+1)
                                    begin
                                        rxpdatout[j] <=  rxpdat2[j+deserialization_factor -7];
                                    end
                                end

                            8:  begin     //(RXPDAT3[1:0],RXPDAT2[9:2]
                                    for(j = deserialization_factor*i + 8; j <= deserialization_factor*(i+1) -1; j=j+1)
                                    begin
                                        rxpdatout[j] <=  rxpdat3[j-8];
                                    end

                                    for(j = deserialization_factor*i; j <= deserialization_factor*i +7; j=j+1)
                                    begin
                                        rxpdatout[j] <=  rxpdat2[j+deserialization_factor -8];
                                    end
                                end

                            9:  begin   //(RXPDAT3[0:0],RXPDAT2[9:1]
                                    rxpdatout[deserialization_factor*(i+1) -1] <=  rxpdat3[deserialization_factor*i];

                                    for(j = deserialization_factor*i; j <= deserialization_factor*i +8; j=j+1)
                                    begin
                                        rxpdatout[j] <=  rxpdat2[j+deserialization_factor -9];
                                    end
                                end

                            default :
                                begin
                                    for(j = deserialization_factor*i + 1; j <= deserialization_factor*(i+1) -1; j=j+1)
                                    begin
                                        rxpdatout[j] <=  rxpdat3[j-1];
                                    end
                                end
                        endcase
                    end
                    rx_channel_data_align_pre[i] <= rx_channel_data_align[i];
                end
                rx_coreclk_pre[i] <= rx_coreclk[i];
                rx_clock1_int_pre <= rx_clock1_int;
            end
        end
    end // DPA_BIT_SLIP

// CONTINOUS ASSIGNMENT
    assign rxpdat1 = (enable_dpa_fifo == "ON") ? read_data  : serdes_data_out;
    assign write_data = serdes_data_out;
    assign rx_out_int = (STRATIXGX_DPA_RX_STYLE == 1)? rxpdatout :
                         ((RX_NEED_HOLD_REG == 1) ? rx_out_hold :  rx_parallel_load_reg);
    assign rx_outclock = rx_outclk_int;
    assign rx_hold_clk = (STRATIX_RX_STYLE == 0) ? rx_outclk_int : enable1_reg;
    assign rx_reg_clk  = rx_outclk_int;
    assign rx_outclk_int = (MERCURY_RX_STYLE == 1) ? rx_mercury_slow_clock : rx_clock1_int;
    assign rx_clock0_int = (deserialization_factor > 1) ? rx_pll_clk0 : rx_inclock;
    assign rx_clock1_int = (deserialization_factor > 1) ? rx_pll_clk1 : rx_inclock;
    assign rx_locked = (deserialization_factor > 1) ? rx_locked_int : 1'b1;
    assign rx_dpa_locked = {number_of_channels {1'b1}};
    assign rx_pll_clk0 = ((STRATIX_RX_STYLE == 1) || (STRATIXGX_DPA_RX_STYLE == 1)) ? stratix_clk[0] : apex_clk[0];
    assign rx_pll_clk1 = ((STRATIX_RX_STYLE == 1) || (STRATIXGX_DPA_RX_STYLE == 1)) ? stratix_clk[1] : apex_clk[1];
    assign rx_locked_int = ((STRATIX_RX_STYLE == 1) || (STRATIXGX_DPA_RX_STYLE == 1)) ? stratix_locked : apex_locked;
    assign rx_out = (deserialization_factor > 1) ? ((registered_output == "ON")? rx_out_reg : rx_out_int)
                     : rx_in;
    assign non_stratix_inclock = ((STRATIX_RX_STYLE == 1) || (STRATIXGX_DPA_RX_STYLE == 1))? 0 : rx_inclock;
    assign stratix_inclock[1: 0] = ((STRATIX_RX_STYLE == 1) || (STRATIXGX_DPA_RX_STYLE == 1))? {1'b0, rx_inclock} : 0;
    assign stratix_clkena[2 : 0] = {3{1'b1}};
    assign pclk = clkout_tmp;
    assign rx_data_align_int = (rx_data_align === 1'bz)? 0 : rx_data_align;


endmodule // altlvds_rx
// END OF MODULE


//START_MODULE_NAME--------------------------------------------------------------
//
// Module Name     :  altlvds_tx

// Description     :  Low Voltage Differential Signaling (LVDS) transmitter
//                    megafunction. The altlvds_tx megafunction implements a
//                    serialization transmitter. LVDS is a high speed IO
//                    interface that uses inputs without a reference voltage.
//                    LVDS uses two wires carrying differential values to
//                    create a single channel. These wires are connected to two
//                    pins on supported device to create a single LVDS channel

// Limitation      :  Only available for APEX20KE, APEXII, MERCURY, STRATIX and
//                    STRATIX GX families.
//
// Results expected:  Output clock, serialized output data and pll locked signal.
//
//END_MODULE_NAME----------------------------------------------------------------

// BEGINNING OF MODULE
`timescale 1 ps / 1 ps

module altlvds_tx (
    tx_in,
    tx_inclock,
    sync_inclock,
    tx_pll_enable,
    pll_areset,

    tx_out,
    tx_outclock,
    tx_coreclock,
    tx_locked
);


// GLOBAL PARAMETER DECLARATION

    // No. of LVDS channels (required)
    parameter number_of_channels = 1;

    // No. of bits per channel (required)
    parameter deserialization_factor = 4;

    // Indicates whether the tx_in[] and tx_outclock ports should be registered.
    parameter registered_input = "ON";

    // "ON" means that sync_inclock is also used
    // (not used for Stratix and Stratix GX devices.)
    parameter multi_clock = "OFF";

    // The period of the input clock in ps (Required)
    parameter inclock_period = 10000;

    // Specifies the period of the tx_outclock port as
    // [INCLOCK_PERIOD * OUTCLOCK_DIVIDE_BY] 
    parameter outclock_divide_by = deserialization_factor;

    // The effective clock period to sample output data
    parameter inclock_boost = deserialization_factor;

    // Aligns the Most Significant Bit(MSB) to the falling edge of the clock
    // instead of the rising edge. (only for APEX II devices)
    parameter center_align_msb = "OFF";

    // The device family to be used.
    parameter intended_device_family = "APEX20KE";

    // Data rate out of the PLL. (required and only for Stratix and
    // Stratix GX devices)
    parameter output_data_rate = 0;

    // The alignment of the input data with respect to the tx_inclock port.
    // (required and only for Stratix and Stratix GX devices)
    parameter inclock_data_alignment = "EDGE_ALIGNED";

    // The alignment of the output data with respect to the tx_outclock port.
    // (required and only for Stratix and Stratix GX devices)
    parameter outclock_alignment = "EDGE_ALIGNED";

    // Specifies whether the compiler uses the same PLL for both the LVDS 
    // receiver and the LVDS transmitter
    parameter common_rx_tx_pll = "ON";

    parameter outclock_resource = "AUTO";

    parameter lpm_type = "altlvds_tx";

    // Specifies whether the source of the input clock is from a PLL
    parameter clk_src_is_pll = "off";


// LOCAL PARAMETER DECLARATION

    // A APEX20KE type of LVDS?
    parameter APEX20KE_TX_STYLE = (intended_device_family == "APEX20KE") ||
                                   (intended_device_family == "EXCALIBUR_ARM") ||
                                   (intended_device_family == "EXCALIBUR_MIPS") ||
                                   (intended_device_family == "APEX20KC")
                                    ? 1 : 0;

    // A APEXII type of LVDS?
    parameter APEXII_TX_STYLE  = (intended_device_family == "APEXII") ||
                                 (intended_device_family == "APEX II")
                                 ? 1 : 0;

    // A MERCURY type of LVDS?
    parameter MERCURY_TX_STYLE = (intended_device_family == "MERCURY") ||
                                 (intended_device_family == "Mercury")
                                 ? 1 : 0;

    // A STRATIX type of LVDS?
    parameter STRATIX_TX_STYLE = (intended_device_family == "Stratix") ||
                                 (intended_device_family == "STRATIXGX") ||
                                 (intended_device_family == "Stratix GX")
                                 ? 1 : 0;

    // Parameter to check whether the selected lvds trasmitter use
    // holding register or not.
    parameter TX_NEED_HOLD = (((APEX20KE_TX_STYLE == 1) &&
                                 (deserialization_factor >= 7)) ||
                              ((APEXII_TX_STYLE   == 1) &&
                                 (deserialization_factor >= 5)) ||
                              ((MERCURY_TX_STYLE   == 1) &&
                                 (deserialization_factor >= 7)))
                                 ? 1 : 0;

     // calculate the clock boost for pll
    parameter INT_CLOCK_BOOST = (STRATIX_TX_STYLE == 1) ?
                                  (((output_data_rate * inclock_period) +
                                      (5 * 100000))/ 1000000) :
                                  ((inclock_boost == 0) ?
                                     deserialization_factor : inclock_boost);

    // parameter for inclock phase shift. Add 0.5 to the calculated result to
    // round up result to the nearest integer.
    // CENTER_ALIGNED means 180 degrees
    parameter PHASE_INCLOCK = (inclock_data_alignment == "EDGE_ALIGNED")?
                                 0 :
                              (inclock_data_alignment == "CENTER_ALIGNED") ?
                                (0.5 * inclock_period / INT_CLOCK_BOOST) + 0.5:
                              (inclock_data_alignment == "45_DEGREES") ?
                                (0.125 * inclock_period / INT_CLOCK_BOOST) + 0.5:
                              (inclock_data_alignment == "90_DEGREES") ?
                                (0.25 * inclock_period / INT_CLOCK_BOOST) + 0.5:
                              (inclock_data_alignment == "135_DEGREES") ?
                                (0.375 * inclock_period / INT_CLOCK_BOOST) + 0.5:
                              (inclock_data_alignment == "180_DEGREES") ?
                                (0.5 * inclock_period / INT_CLOCK_BOOST) + 0.5:
                              (inclock_data_alignment == "225_DEGREES") ?
                                (0.625 * inclock_period / INT_CLOCK_BOOST) + 0.5:
                              (inclock_data_alignment == "270_DEGREES") ?
                                (0.75 * inclock_period / INT_CLOCK_BOOST) + 0.5:
                              (inclock_data_alignment == "315_DEGREES") ?
                                (0.875 * inclock_period / INT_CLOCK_BOOST) + 0.5: 0;

    // parameter for outclock phase shift. Add 0.5 to the calculated result to
    // round up result to the nearest integer.
    parameter PHASE_OUTCLOCK = (outclock_alignment == "EDGE_ALIGNED") ?
                                 PHASE_INCLOCK:
                               (outclock_alignment == "CENTER_ALIGNED") ?
                                 ((0.5 * inclock_period / INT_CLOCK_BOOST) +
                                   0.5 + PHASE_INCLOCK):
                               (outclock_alignment == "45_DEGREES") ?
                                 ((0.125 * inclock_period / INT_CLOCK_BOOST) +
                                   0.5 + PHASE_INCLOCK):
                               (outclock_alignment == "90_DEGREES") ?
                                 ((0.25 * inclock_period / INT_CLOCK_BOOST) +
                                   0.5 + PHASE_INCLOCK):
                               (outclock_alignment == "135_DEGREES") ?
                                 ((0.375 * inclock_period / INT_CLOCK_BOOST) +
                                   0.5 + PHASE_INCLOCK):
                               (outclock_alignment == "180_DEGREES") ?
                                 ((0.5 * inclock_period / INT_CLOCK_BOOST) +
                                   0.5 + PHASE_INCLOCK):
                               (outclock_alignment == "225_DEGREES") ?
                                 ((0.625 * inclock_period / INT_CLOCK_BOOST) +
                                   0.5 + PHASE_INCLOCK):
                               (outclock_alignment == "270_DEGREES") ?
                                 ((0.75 * inclock_period / INT_CLOCK_BOOST) +
                                   0.5 + PHASE_INCLOCK):
                               (outclock_alignment == "315_DEGREES") ?
                                 ((0.875 * inclock_period / INT_CLOCK_BOOST) +
                                   0.5 + PHASE_INCLOCK): PHASE_INCLOCK;


    parameter REGISTER_WIDTH = deserialization_factor*number_of_channels;


// INPUT PORT DECLARATION

    // Input data (required)
    input  [REGISTER_WIDTH -1 : 0] tx_in;

    // Input clock (required)
    input tx_inclock;

    // Optional clock for input registers  (Required if "multi_clock" parameters
    // is turned on)
    input sync_inclock;

    // Enable control for the LVDS PLL
    input tx_pll_enable;

    // Asynchronously resets all counters to initial values (only for Stratix
    // and Stratix GX devices)
    input pll_areset;



// OUTPUT PORT DECLARATION

    // Serialized data signal(required)
    output [number_of_channels-1 :0] tx_out;

    // External reference clock
    output tx_outclock;

    // Output clock used to feed non-peripheral logic.
    // Only available for Mercury, Stratix, and Stratix GX devices only.
    output tx_coreclock;

    // Gives the status of the LVDS PLL
    // (when the PLL is locked, this signal is VCC. GND otherwise)
    output tx_locked;


// INTERNAL REGISTERS DECLARATION

    reg [REGISTER_WIDTH -1 : 0] tx_hold_reg;
    reg [REGISTER_WIDTH -1 : 0] tx_in_reg;
    reg [REGISTER_WIDTH -1 : 0] tx_shift_reg;
    reg [REGISTER_WIDTH -1 : 0] tx_parallel_load_reg;
    reg tx_mercury_core_clock;
    reg fb;
    reg [number_of_channels-1 :0] tx_out;
    reg enable1;
    reg enable1_reg1;
    reg enable1_reg2;
    reg enable1_neg;


// INTERNAL WIRE DECLARATION

    wire [REGISTER_WIDTH -1 : 0] tx_in_int;
    wire tx_pll_clk0;
    wire tx_pll_clk1;
    wire tx_pll_clk2;
    wire tx_clock0_int;
    wire tx_clock1_int;
    wire tx_reg_clk;
    wire tx_hold_clk;
    wire tx_locked_int;
    wire unused_clk_ext;
    wire [5:0] stratix_clk;
    wire stratix_locked;
    wire [2:0] apex_clk ;
    wire apex_locked;
    wire [5:0] stratix_clkena;
    wire apex_inclock;
    wire [1:0] stratix_inclock;
    wire apex_clkena;


// INTERNAL TRI DECLARATION

    tri0 sync_inclock;
    tri1 tx_pll_enable;
    tri0 pll_areset;


// LOCAL INTEGER DECLARATION

    integer count;
    integer i;
    integer posedge_count;
    integer negedge_count;
    integer shift_data;

// LOCAL TIME DECLARATION

    time tx_out_delay;


// INITIAL CONSTRUCT BLOCK

    initial
    begin : INITIALIZATION
        for (i = 0; i < REGISTER_WIDTH; i = i + 1)
        begin
            tx_in_reg[i] = 0;
            tx_hold_reg[i] = 0;
            tx_parallel_load_reg[i] = 0;
            tx_shift_reg[i] = 0;
        end

        for (i = 0; i < number_of_channels; i = i + 1)
        begin
            tx_out[i] = 0;
        end

        fb = 'b1;
        count = 0;
        shift_data = 0;
        negedge_count = 0;
        posedge_count = 0;
        enable1 = 0;
        enable1_reg1 = 0;
        enable1_reg2 = 0;
        enable1_neg = 0;

        tx_out_delay = inclock_period/(deserialization_factor*2);

        // Check for illegal mode settings
        if ((APEX20KE_TX_STYLE == 1) &&
            (deserialization_factor != 4) && (deserialization_factor != 7) &&
            (deserialization_factor != 8))
        begin
                $display ($time, "ps Error: APEX20KE does not support the specified deserialization factor!");
                $stop;
        end
        else if ((MERCURY_TX_STYLE == 1) &&
                (((deserialization_factor > 12) && 
                  (deserialization_factor != 14) &&
                  (deserialization_factor != 16) &&
                  (deserialization_factor != 18) &&
                  (deserialization_factor != 20)) ||(deserialization_factor < 3)))
        begin
                $display ($time, "ps Error: MERCURY does not support the specified deserialization factor!");
                $stop;
        end 
        else if (((APEXII_TX_STYLE == 1)) &&
                 ((deserialization_factor > 10) || (deserialization_factor < 4)))
        begin
                $display ($time, "ps Error: APEXII does not support the specified deserialization factor!");
                $stop;
        end
        else if (((STRATIX_TX_STYLE == 1)) &&
                      ((deserialization_factor > 10) || (deserialization_factor < 4)))
        begin
                $display ($time, "ps Error: STRATIX does not support the specified deserialization factor!");
                $stop;
        end
    end // INITIALIZATION


// COMPONENT INSTANTIATIONS

    // PLL for device family other than Stratix and Stratx GX
    altclklock u0 ( .inclock(apex_inclock), // Required
                    .inclocken(apex_clkena),
                    .fbin(fb),
                    .clock0(apex_clk[0]),
                    .clock1(apex_clk[1]),
                    .clock2(apex_clk[2]),
                    .clock_ext(unused_clk_ext),
                    .locked(apex_locked));

    defparam
        u0.inclock_period         = inclock_period,

        u0.clock0_boost           = (APEX20KE_TX_STYLE == 1) ?
                                     deserialization_factor : INT_CLOCK_BOOST,

        u0.clock1_boost           = (APEX20KE_TX_STYLE == 1) ?
                                     deserialization_factor : INT_CLOCK_BOOST,

        u0.clock1_divide          = deserialization_factor,

        u0.clock2_boost           = (MERCURY_TX_STYLE == 1) ?
                                     INT_CLOCK_BOOST : 1,

        u0.clock2_divide          = (MERCURY_TX_STYLE == 1) ?
                                     outclock_divide_by : 1,

        u0.valid_lock_cycles      = ((MERCURY_TX_STYLE == 1) ||
                                     (APEXII_TX_STYLE == 1)) ? 3 : 5,

        u0.intended_device_family = intended_device_family;


    // component used as 'interface' to stratix pll (for Stratix and Stratix GX)
    altpll u1 ( .inclk(stratix_inclock), // Required
                .pllena(tx_pll_enable),
                .areset(pll_areset),
                .clkena(stratix_clkena),
                .clk (stratix_clk ),
                .locked(stratix_locked),
                .fbin(),
                .clkswitch(),
                .pfdena(),
                .extclkena(),
                .scanclk(),
                .scanaclr(),
                .scandata(),
                .extclk(),
                .clkbad(),
                .activeclock(),
                .clkloss(),
                .scandataout());

    defparam
        u1.primary_clock        = "inclk0",
        u1.inclk0_input_frequency = inclock_period,
        u1.clk0_multiply_by     = INT_CLOCK_BOOST,
        u1.clk0_phase_shift_num = PHASE_INCLOCK,
        u1.clk1_multiply_by     = INT_CLOCK_BOOST,
        u1.clk1_divide_by       = deserialization_factor,
        u1.clk1_phase_shift_num = PHASE_INCLOCK,
        u1.clk2_multiply_by     = INT_CLOCK_BOOST,
        u1.clk2_divide_by       = outclock_divide_by,
        u1.clk2_phase_shift_num = PHASE_OUTCLOCK,
        u1.clk2_duty_cycle      = ((deserialization_factor == 7) &&
                                   (outclock_divide_by == 7)) ? 58 : 50,
        u1.intended_device_family = intended_device_family,
        u1.source_is_pll        = clk_src_is_pll;


// ALWAYS CONSTRUCT BLOCK
    // Fast Clock
    always @ (tx_clock0_int)
    begin : FAST_CLOCK
        if (deserialization_factor > 1)
        begin
            if (tx_clock0_int == 0)
            begin
                negedge_count = negedge_count + 1;
                enable1 <= (negedge_count == deserialization_factor) ? 1 : 0;
                enable1_neg <= enable1_reg2;

                // Loading data to parallel load register for non-STRATIX family
                if ((negedge_count == 3) && (STRATIX_TX_STYLE == 0) &&
                    (tx_locked_int == 1))
                begin
                    if (TX_NEED_HOLD == 1)
                    begin
                        tx_parallel_load_reg <= tx_hold_reg;
                    end
                    else
                    begin
                        tx_parallel_load_reg <= tx_in_int;
                    end
                end
            end
            else if (tx_clock0_int == 1)
            begin
                if (STRATIX_TX_STYLE == 0)
                begin
                    posedge_count = (posedge_count+1) % deserialization_factor;
                    if (posedge_count == 3)
                    begin
                        // register incoming data on the third edge
                        tx_shift_reg = tx_parallel_load_reg; 
                        count = 0;
                        shift_data = 1; // third rising edge
                    end

                    if (shift_data == 1)
                    begin
                        count = count + 1;
                        for (i = 0;  i < number_of_channels; i = i +1)
                        // Data in MSB gets shifted out first.
                        // NB: This happens 1/2clk cycle later for APEXII (MSB
                        // only) when center_align_msb is ON.
                        begin
                            if ((i == number_of_channels-1) && 
                               ((APEXII_TX_STYLE == 1)) &&
                               (center_align_msb == "ON"))
                            begin
                                tx_out[i] <= #tx_out_delay
                                 tx_shift_reg[(i+1)*deserialization_factor - count];
                            end
                            else
                            begin
                                tx_out[i] <= tx_shift_reg[(i+1)*deserialization_factor - count];
                            end
                        end
                    end

                    // Mercury core clock is assymmetrical for odd deserialization
                    // factor values.
                    if (posedge_count == ((deserialization_factor+1)/2+1))
                    begin
                        tx_mercury_core_clock <= ~tx_mercury_core_clock;
                    end
                end
                else
                begin

                    // registering enable1 signal
                    enable1_reg2 <= enable1_reg1;
                    enable1_reg1 <= enable1;

                    if(enable1_neg == 1)
                    begin
                        tx_shift_reg = tx_parallel_load_reg;
                        count = 0;
                        shift_data = 1;
                    end

                    // Shift data from shift register to tx_out
                    if (shift_data == 1)
                    begin
                        count = count + 1;
                        for (i = 0;  i < number_of_channels; i = i +1)
                        begin
                            tx_out[i] <= tx_shift_reg[(i+1)*deserialization_factor - count];
                        end
                    end

                    // Loading data to parallel load register for Stratix and
                    // Stratix GX
                    if(enable1 == 1)
                    begin
                        tx_parallel_load_reg <= tx_in_int;
                    end
                end
            end
        end
    end // FAST_CLOCK


    // Slow Clock
    always @ (tx_pll_clk1)
    begin : SLOW_CLOCK
        if (tx_pll_clk1 == 1)
        begin
            if (deserialization_factor > 1)
            begin
                negedge_count = 0;
                tx_mercury_core_clock <= tx_pll_clk1;
            end
            else
            begin
                tx_out <= tx_in;
            end
        end
    end // SLOW_CLOCK

    // synchronization register
    always @ (tx_reg_clk)
    begin : SYNC_REGISTER
        if (deserialization_factor > 1)
        begin
            if (tx_reg_clk == 1)
              tx_in_reg <= #5 tx_in;
        end
    end // SYNC_REGISTER

    // hold register
    always @ (tx_hold_clk)
    begin : HOLD_REGISTER
        if (deserialization_factor > 1)
        begin
            if (tx_hold_clk == 0)
                tx_hold_reg <= tx_in_int;
        end
    end  // HOLD_REGISTER


    // CONTINOUS ASSIGNMENT
    assign tx_in_int     = (registered_input != "OFF") ?
                            tx_in_reg : tx_in;

    assign tx_clock0_int = (deserialization_factor > 1) ?
                            tx_pll_clk0 : tx_inclock;

    assign tx_clock1_int = (deserialization_factor > 1) ?
                            tx_pll_clk1 : tx_inclock;

    assign tx_reg_clk    = (STRATIX_TX_STYLE == 1)?
                            ((registered_input == "TX_CLKIN")?
                                  tx_inclock : tx_coreclock) :
                            (((registered_input == "ON") && (multi_clock == "ON")) ?
                                  sync_inclock : tx_inclock);

    assign tx_hold_clk   = (multi_clock == "ON") ? sync_inclock :
                           ((MERCURY_TX_STYLE == 1) ? tx_coreclock : tx_inclock);

    assign tx_outclock   = ((STRATIX_TX_STYLE == 1) || (MERCURY_TX_STYLE == 1)) ?
                             tx_pll_clk2 : ((APEXII_TX_STYLE == 1) ?
                             tx_inclock : tx_clock1_int);

    assign tx_coreclock  = (((deserialization_factor % 2) != 0) && (MERCURY_TX_STYLE == 1)) ?
                            tx_mercury_core_clock : tx_clock1_int;

    assign tx_locked     = (deserialization_factor > 1) ?
                            tx_locked_int : 1'b1;

    assign stratix_clkena[5: 0] = {6{1'b1}};

    assign tx_pll_clk0   = (STRATIX_TX_STYLE == 1) ?
                            stratix_clk[0] : apex_clk[0];

    assign tx_pll_clk1   = (STRATIX_TX_STYLE == 1) ?
                            stratix_clk[1] : apex_clk[1];

    assign tx_pll_clk2   = (STRATIX_TX_STYLE == 1) ?
                            stratix_clk[2] : apex_clk[2];

    assign tx_locked_int = (STRATIX_TX_STYLE == 1) ?
                            stratix_locked : apex_locked;

    assign stratix_inclock[1:0] = (STRATIX_TX_STYLE == 1) ?
                                  {1'b0, tx_inclock} : 2'b0;

    assign apex_inclock  = (STRATIX_TX_STYLE != 1) ? tx_inclock : 0;

    assign apex_clkena   = (STRATIX_TX_STYLE != 1) ? tx_pll_enable : 0;


endmodule // altlvds_tx
// END OF MODULE


//START_MODULE_NAME-------------------------------------------------------------
//
// Module Name     :   altfp_mult
//
// Description     :   Parameterized floating point multiplier megafunction.
//                     This module implements IEEE-754 Compliant Floating Poing
//                     Multiplier.It supports Single Precision, Single Extended
//                     Precision and Double Precision floating point
//                     multiplication.
//
// Limitation      :   Fixed clock latency with 4 clock cycle delay.
//
// Results expected:   result of multiplication and the result's status bits
//
//END_MODULE_NAME---------------------------------------------------------------

// BEGINNING OF MODULE
`timescale 1 ps / 1 ps

module altfp_mult (
    clock,      // Clock input to the multiplier.(Required)
    clk_en,     // Clock enable for the multiplier.
    aclr,       // Asynchronous clear for the multiplier.
    dataa,      // Data input to the multiplier.(Required)
    datab,      // Data input to the multiplier.(Required)
    result,     // Multiplier output port.(Required)
    overflow,   // Overflow port for the multiplier.
    underflow,  // Underflow port for the multiplier.
    zero,       // Zero port for the multiplier.
    denormal,   // Denormal port for the multiplier.
    indefinite, // Indefinite port for the multiplier.
    nan         // Nan port for the multiplier.
);

// GLOBAL PARAMETER DECLARATION
    // Specifies the value of the exponent, Minimum = 8, Maximum = 31
    parameter width_exp = 8;
    // Specifies the value of the mantissa, Minimum = 23, Maximum = 52
    parameter width_man = 23;
    // Specifies whether to use dedicated multiplier circuitry.
    parameter dedicated_multiplier_circuitry = "AUTO";
    parameter lpm_hint = "UNUSED";
    parameter lpm_type = "altfp_mult";

// LOCAL PARAMETER DECLARATION
    //clock latency
    parameter LATENCY = 4;
    // Sum of mantissa's width and exponent's width
    parameter WIDTH_MAN_EXP = width_exp + width_man;

// INPUT PORT DECLARATION
    input [WIDTH_MAN_EXP : 0] dataa;
    input [WIDTH_MAN_EXP : 0] datab;
    input clock;
    input clk_en;
    input aclr;

// OUTPUT PORT DECLARATION
    output [WIDTH_MAN_EXP : 0] result;
    output overflow;
    output underflow;
    output zero;
    output denormal;
    output indefinite;
    output nan;

// INTERNAL REGISTERS DECLARATION
    reg [WIDTH_MAN_EXP : 0] result;
    reg overflow;
    reg underflow;
    reg zero;
    reg denormal;
    reg indefinite;
    reg nan;
    reg[width_man : 0] mant_dataa;
    reg[width_man : 0] mant_datab;
    reg[(2 * width_man) + 1 : 0] mant_result;
    reg cout;
    reg zero_mant_dataa;
    reg zero_mant_datab;
    reg zero_dataa;
    reg zero_datab;
    reg inf_dataa;
    reg inf_datab;
    reg nan_dataa;
    reg nan_datab;
    reg den_dataa;
    reg den_datab;
    reg no_multiply;
    reg no_rounding;
    reg sticky_bit;
    reg round_bit;
    reg guard_bit;
    reg carry;
    reg[WIDTH_MAN_EXP + 6 : 0] result_pipe[LATENCY : 0];
    reg[WIDTH_MAN_EXP + 6 : 0] temp_result;

// INTERNAL TRI DECLARATION
    tri1 clk_en;
    tri0 aclr;

// LOCAL INTEGER DECLARATION
    integer exp_dataa;
    integer exp_datab;
    integer exp_result;

    // loop counter
    integer i0;
    integer i1;
    integer i2;
    integer i3;
    integer i4;

// TASK DECLARATION

    // Add up two bits to get the result(<mantissa of datab> + <temporary result
    // of mantissa's multiplication>)
    //Also output the carry bit.
    task add_bits;
        // Value to be added to the temporary result of mantissa's multiplication.
        input  [width_man : 0] val1;
        // temporary result of mantissa's multiplication.
        inout  [(2 * width_man) + 1 : 0] temp_mant_result;
        output cout; // carry out bit

        reg co; // temporary storage to store the carry out bit

        begin
            co = 1'b0;
            for(i0 = 0; i0 <= width_man; i0 = i0 + 1)
            begin
                // if the carry out bit from the previous bit addition is 1'b0
                if (co == 1'b0)
                begin
                    if (val1[i0] != temp_mant_result[i0 + width_man + 1])
                    begin
                        temp_mant_result[i0 + width_man + 1] = 1'b1;
                    end
                    else
                    begin
                        co = val1[i0] & temp_mant_result[i0 + width_man + 1];
                        temp_mant_result[i0 + width_man + 1] = 1'b0;
                    end
                end
                else // if (co == 1'b1)
                begin
                    co = val1[i0] | temp_mant_result[i0 + width_man + 1];
                    if (val1[i0] != temp_mant_result[i0 + width_man + 1])
                    begin
                        temp_mant_result[i0 + width_man + 1] = 1'b0;
                    end
                    else
                    begin
                        temp_mant_result[i0 + width_man + 1] = 1'b1;
                    end
                end
            end // end of for loop
            cout = co;
        end
    endtask // add_bits

// FUNCTON DECLARATION

    // Check whether the all the bits from index <index1> to <index2> is 1'b1
    // Return 1'b1 if true, otherwise return 1'b0
    function bit_all_0;
        input [(2 * width_man) + 1: 0] val;
        input index1;
        integer index1;
        input index2;
        integer index2;

        reg all_0; //temporary storage to indicate whether all the currently
                   // checked bits are 1'b0
        begin
            begin : LOOP_1
                all_0 = 1'b1;
                for (i1 = index1; i1 <= index2; i1 = i1 + 1)
                begin
                    if ((val[i1]) == 1'b1)
                    begin
                        all_0 = 1'b0;
                        disable LOOP_1;  //break the loop to stop checking
                    end
                end
            end
            bit_all_0 = all_0;
        end
    endfunction // bit_all_0

    // Calculate the exponential value (<base_number> power of <exponent_number>)
    function integer exponential_value;
        input base_number;
        input exponent_number;
        integer base_number;
        integer exponent_number;
        integer value; // temporary storage to store the exponential value

        begin
            value = 1;
            for (i2 = 0; i2 < exponent_number; i2 = i2 + 1)
            begin
                value = base_number * value;
            end
            exponential_value = value;
        end
    endfunction // exponential_value

// INITIAL CONSTRUCT BLOCK
    initial
    begin : INITIALIZATION
        exp_dataa = 0;
        exp_datab = 0;
        exp_result = 0;
        mant_dataa = {(width_man + 1){1'b0}};
        mant_datab = {(width_man + 1){1'b0}};
        mant_result = {((2 * width_man) + 2){1'b0}};
        cout  = 1'b0;
        zero_mant_dataa = 1'b0;
        zero_mant_datab = 1'b0;
        zero_dataa = 1'b0;
        zero_datab = 1'b0;
        inf_dataa = 1'b0;
        inf_datab = 1'b0;
        nan_dataa = 1'b0;
        nan_datab = 1'b0;
        den_dataa = 1'b0;
        den_datab = 1'b0;
        no_multiply = 1'b0;
        no_rounding = 1'b0;
        sticky_bit = 1'b0;
        round_bit = 1'b0;
        guard_bit = 1'b0;
        carry = 1'b0;
        temp_result = {(WIDTH_MAN_EXP + 7){1'b0}};

        for(i3 = LATENCY; i3 >= 0; i3 = i3 - 1)
        begin
            result_pipe[i3] = 0;
        end
        // Check for illegal mode setting
        if (WIDTH_MAN_EXP >= 64)
        begin
            $display("The sum of width_exp(%d) and width_man(%d) must be less 64(ERROR)", width_exp, width_man);
            $stop;
        end
        if (width_exp < 8)
        begin
            $display("width_exp(%d) must be at least 8 (ERROR)", width_exp);
            $stop;
        end
        if (width_man < 23)
        begin
            $display("width_man(%d) must be at least 23 (ERROR)", width_man);
            $stop;
        end
        if (~((width_exp >= 11) || ((width_exp == 8) && (width_man == 23))))
        begin
            $display("Found width_man(%d) inside the range of Single Precision. width_exp must be 8 and width_man must be 23 for Single Presicion (ERROR)", width_man);
            $stop;
        end
        if (width_exp >= width_man)
        begin
            $display("width_exp(%d) must be less than width_man(%d) (ERROR)", width_exp, width_man);
            $stop;
        end
    end // INITIALIZATION

// ALWAYS CONSTRUCT BLOCK

    // Asynchronous clear
    always @(aclr)
    begin : ASYN_CLEAR
        if (aclr == 1'b1)
        begin
            for (i3 = LATENCY; i3 >= 0; i3 = i3 - 1)
            begin
                result_pipe[i3] = 0;
                temp_result = result_pipe[i3];
                temp_result[WIDTH_MAN_EXP + 3] = 1'b1;
                result_pipe[i3] = temp_result;
            end
            // clear all the output ports to 1'b0
            result = {(WIDTH_MAN_EXP + 1){1'b0}};
            overflow = 1'b0;
            underflow = 1'b0;
            zero = 1'b1;
            denormal = 1'b0;
            indefinite = 1'b0;
            nan = 1'b0;
        end
    end // ASYN_CLEAR

    // multiplication
    always @(posedge clock)
    begin : MULTIPLY_FP

        if ((aclr != 1'b1) && (clk_en == 1'b1))
        begin
            // Create latency for the output result
            for(i4=LATENCY; i4 >= 1; i4 = i4 - 1)
            begin
                result_pipe[i4] = result_pipe[i4 - 1];
            end
            temp_result = {(WIDTH_MAN_EXP + 7){1'b0}};
            mant_result = {((2 * width_man) + 2){1'b0}};
            exp_dataa = 0;
            exp_datab = 0;
            // Set the exponential value
            for (i4 = 0; i4 <= width_exp -1; i4= i4 + 1)
            begin
                if ((dataa[width_man + i4]) == 1'b1)
                begin
                    exp_dataa = exponential_value(2, i4) + exp_dataa;
                end

                if ((datab[width_man + i4]) == 1'b1)
                begin
                    exp_datab = exponential_value(2, i4) + exp_datab;
                end
            end
            zero_mant_dataa = 1'b1;
            // Check whether the mantissa for dataa is zero
            begin : LOOP_3
                for (i4 = 0; i4 <= width_man - 1; i4 = i4 + 1)
                begin
                    if ((dataa[i4]) == 1'b1)
                    begin
                        zero_mant_dataa = 1'b0;
                        disable LOOP_3;
                    end
                end
            end // LOOP_3
            zero_mant_datab = 1'b1;
            // Check whether the mantissa for datab is zero
            begin : LOOP_4
                for (i4 = 0; i4 <= width_man -1; i4 = i4 + 1)
                begin
                    if ((datab[i4]) == 1'b1)
                    begin
                        zero_mant_datab = 1'b0;
                        disable LOOP_4;
                    end
                end
            end // LOOP_4
            zero_dataa = 1'b0;
            den_dataa = 1'b0;
            inf_dataa = 1'b0;
            nan_dataa = 1'b0;
            // Check whether dataa is special input
            if (exp_dataa == 0)
            begin
                if (zero_mant_dataa == 1'b1)
                begin
                    zero_dataa = 1'b1;  // dataa is zero
                end
                else
                begin
                    den_dataa = 1'b1; // dataa is denormalized
                end
            end
            else if (exp_dataa == (exponential_value(2, width_exp) - 1))
            begin
                if (zero_mant_dataa == 1'b1)
                begin
                    inf_dataa = 1'b1;  // dataa is infinity
                end
                else
                begin
                    nan_dataa = 1'b1; // dataa is Nan
                end
            end
            zero_datab = 1'b0;
            den_datab = 1'b0;
            inf_datab = 1'b0;
            nan_datab = 1'b0;
            // Check whether datab is special input
            if (exp_datab == 0)
            begin
                if (zero_mant_datab == 1'b1)
                begin
                    zero_datab = 1'b1; // datab is zero
                end
                else
                begin
                    den_datab = 1'b1; // datab is denormalized
                end
            end
            else if (exp_datab == (exponential_value(2, width_exp) - 1))
            begin
                if (zero_mant_datab == 1'b1)
                begin
                    inf_datab = 1'b1; // datab is infinity
                end
                else
                begin
                    nan_datab = 1'b1; // datab is Nan
                end
            end
            no_multiply = 1'b0;
            // Set status flag if special input exists
            if (nan_dataa || nan_datab || (inf_dataa && zero_datab) ||
               (inf_datab && zero_dataa))
            begin
                temp_result[WIDTH_MAN_EXP + 6] = 1'b1; // NaN
                for (i4 = width_man - 1; i4 <= WIDTH_MAN_EXP - 1; i4 = i4 + 1)
                begin
                    temp_result[i4] = 1'b1;
                end
                no_multiply = 1'b1; // no multiplication is needed.
            end
            else if (zero_dataa)
            begin
                temp_result[WIDTH_MAN_EXP + 3] = 1'b1; // Zero
                temp_result[WIDTH_MAN_EXP : 0] = dataa;
                no_multiply = 1'b1;
            end
            else if (zero_datab)
            begin
                temp_result[WIDTH_MAN_EXP + 3] = 1'b1; // Zero
                temp_result[WIDTH_MAN_EXP : 0] = datab;
                no_multiply = 1'b1;
            end
            else if (inf_dataa)
            begin
                temp_result[WIDTH_MAN_EXP + 1] = 1'b1; // Overflow
                temp_result[WIDTH_MAN_EXP : 0] = dataa;
                no_multiply = 1'b1;
            end
            else if (inf_datab)
            begin
                temp_result[WIDTH_MAN_EXP + 1] = 1'b1; // Overflow
                temp_result[WIDTH_MAN_EXP : 0] = datab;
                no_multiply = 1'b1;
            end
            // if multiplication needed
            if (no_multiply == 1'b0)
            begin
                // Perform exponent operation
                exp_result = exp_dataa + exp_datab - (exponential_value(2, width_exp -1) -1);
                // First operand for multiplication
                mant_dataa[width_man : 0] = {1'b1, dataa[width_man -1 : 0]};
                // Second operand for multiplication
                mant_datab[width_man : 0] = {1'b1, datab[width_man -1 : 0]};
                // Multiply the mantissas using add and shift algorithm
                for (i4 = 0; i4 <= width_man; i4 = i4 + 1)
                begin
                    cout = 1'b0;
                    if ((mant_dataa[i4]) == 1'b1)
                    begin
                        add_bits(mant_datab, mant_result, cout);
                    end
                    mant_result = mant_result >> 1;
                    mant_result[2*width_man + 1] = cout;
                end
                sticky_bit = 1'b0;
                // Normalize the Result
                if ((mant_result[2*width_man + 1]) == 1'b1)
                begin
                    sticky_bit = mant_result[0]; // Needed for rounding operation.
                    mant_result = mant_result >> 1;
                    exp_result = exp_result + 1;
                end
                round_bit = mant_result[width_man - 1];
                guard_bit = mant_result[width_man];
                no_rounding = 1'b0;
                // Check wether should perform rounding or not
                if (round_bit == 1'b0)
                begin
                    no_rounding = 1'b1; // No rounding is needed
                end
                else
                begin
                    for(i4 = 0; i4 <= width_man - 2; i4 = i4 + 1)
                    begin
                        sticky_bit = sticky_bit | mant_result[i4];
                    end
                    if ((sticky_bit == 1'b0) && (guard_bit == 1'b0))
                    begin
                        no_rounding = 1'b1;
                    end
                end
                // Perform rounding
                if (no_rounding == 1'b0)
                begin
                    carry = 1'b1;
                    for(i4 = width_man; i4 <= 2 * width_man + 1; i4 = i4 + 1)
                    begin
                        if (carry == 1'b1)
                        begin
                            if (mant_result[i4] == 1'b0)
                            begin
                                mant_result[i4] = 1'b1;
                                carry = 1'b0;
                            end
                            else
                            begin
                                mant_result[i4] = 1'b0;
                            end
                        end
                    end
                    // Happened when bit pattern is 10.00... after rounding
                    if (mant_result[(2 * width_man) + 1] == 1'b1)
                    begin
                        mant_result = mant_result >> 1;
                        exp_result = exp_result + 1;
                    end
                end
                // Normalize the Result
                if ((!bit_all_0(mant_result, 0, (2 * width_man) + 1)) &&
                    (mant_result[2 * width_man] == 1'b0))
                begin
                    while((mant_result[2 * width_man] == 1'b0) &&
                          (exp_result != 0))
                    begin
                        mant_result = mant_result << 1;
                        exp_result = exp_result - 1;
                    end
                end
                else if ((exp_result < 0) && (exp_result >= -(2*width_man)))
                begin
                    while(exp_result != 0)
                    begin
                        mant_result = mant_result >> 1;
                        exp_result = exp_result + 1;
                    end
                end
                // Set status flag "indefinite" if normal * denormal
                // (ignore other status port since we dont care the output
                if (den_dataa || den_datab)
                begin
                    temp_result[WIDTH_MAN_EXP + 5] = 1'b1; // Indefinite
                end
                else if (exp_result >= (exponential_value(2, width_exp) -1))
                begin
                    temp_result[WIDTH_MAN_EXP + 1] = 1'b1; // Overflow
                end
                else if (exp_result < 0)
                begin
                    temp_result[WIDTH_MAN_EXP + 2] = 1'b1; // Underflow
                    temp_result[WIDTH_MAN_EXP + 3] = 1'b1; // Zero
                end
                else if (exp_result == 0)
                begin
                    temp_result[WIDTH_MAN_EXP + 2] = 1'b1; // Underflow
                    if (bit_all_0(mant_result, width_man + 1, 2 * width_man))
                    begin
                        temp_result[WIDTH_MAN_EXP + 3] = 1'b1; // Zero
                    end
                    else
                    begin
                        temp_result[WIDTH_MAN_EXP + 4] = 1'b1; // Denormal
                    end
                end
                // Get result's mantissa
                if (exp_result < 0) // Result underflow
                begin
                    for(i4 = 0; i4 <= width_man - 1; i4 = i4 + 1)
                    begin
                        result[i4] = 1'b0; 
                    end
                end
                else if (exp_result == 0) // Denormalized result
                begin
                    temp_result[width_man - 1 : 0] = mant_result[2 * width_man : width_man + 1];
                end                
                else if (exp_result >= exponential_value(2, width_exp) -1) // Result overflow
                begin
                    temp_result[width_man - 1 : 0] = {width_man{1'b0}};
                end
                else // Normalized result
                begin
                    temp_result[width_man - 1 : 0] = mant_result[(2 * width_man - 1) : width_man];
                end
                // Get result's exponent
                if (exp_result == 0)
                begin
                    for(i4 = width_man; i4 <= WIDTH_MAN_EXP - 1; i4 = i4 + 1)
                    begin
                        temp_result[i4] = 1'b0;
                    end
                end
                else if (exp_result >= (exponential_value(2, width_exp) -1))
                begin
                    for(i4 = width_man; i4 <= WIDTH_MAN_EXP - 1; i4 = i4 + 1)
                    begin
                        temp_result[i4] = 1'b1;
                    end
                end
                else
                begin
                    // Convert integer to binary bits
                    for(i4 = width_man; i4 <= WIDTH_MAN_EXP - 1; i4 = i4 + 1)
                    begin
                        if ((exp_result % 2) == 1)
                        begin
                            temp_result[i4] = 1'b1;
                        end
                        else
                        begin
                            temp_result[i4] = 1'b0;
                        end
                        exp_result = exp_result / 2;
                    end
                end
            end // end of if (no_multiply == 1'b0)
            // Get result's sign bit
            temp_result[WIDTH_MAN_EXP] = dataa[WIDTH_MAN_EXP] ^ datab[WIDTH_MAN_EXP];
            result_pipe[0] = temp_result;
            temp_result = result_pipe[LATENCY];
            // Output port
            result = temp_result[WIDTH_MAN_EXP : 0];
            overflow = temp_result[WIDTH_MAN_EXP + 1];
            underflow = temp_result[WIDTH_MAN_EXP + 2];
            zero = temp_result[WIDTH_MAN_EXP + 3];
            denormal = temp_result[WIDTH_MAN_EXP + 4];
            indefinite = temp_result[WIDTH_MAN_EXP + 5];
            nan = temp_result[WIDTH_MAN_EXP + 6];
        end // end of if ((aclr != 1'b1) && (clk_en == 1'b1))
    end // MULTIPLY_FP

endmodule //altfp_mult

// END OF MODULE


//START_MODULE_NAME-------------------------------------------------------------
//
// Module Name     :   altsqrt
//
// Description     :   Parameterized integer square root megafunction.
//                     This module computes q[] and remainder so that
//                      q[]^2 + remainder[] == radical[] (remainder <= 2 * q[])
//                     It can support the sequential mode(pipeline > 0) or
//                     combinational mode (pipeline = 0).
//
// Limitation      :   The radical is assumed to be unsigned integer.
//
// Results expected:   Square root of the radical and the remainder.
//
//END_MODULE_NAME---------------------------------------------------------------

// BEGINNING OF MODULE
`timescale 1 ps / 1 ps

module altsqrt (
    radical,  // Input port for the radical
    clk,      // Clock port
    ena,      // Clock enable port
    aclr,     // Asynchronous clear port
    q,        // Output port for returning the square root of the radical.
    remainder // Output port for returning the remainder of the square root.
);

// GLOBAL PARAMETER DECLARATION
    parameter q_port_width = 1; // The width of the q port
    parameter r_port_width = 1; // The width of the remainder port
    parameter width = 1;        // The width of the radical
    parameter pipeline = 0;     // The latency for the output
    parameter lpm_hint= "UNUSED";
    parameter lpm_type = "altsqrt";

// LOCAL PARAMETER DECLARATION
    parameter PIPELINE_INT = (pipeline == 0) ? 1 : pipeline;

// INPUT PORT DECLARATION
    input [width - 1 : 0] radical;
    input clk;
    input ena;
    input aclr;

// OUTPUT PORT DECLARATION
    output [q_port_width - 1 : 0] q;
    output [r_port_width - 1 : 0] remainder;

// INTERNAL REGISTERS DECLARATION
    reg[q_port_width - 1 : 0] q_temp;
    reg[q_port_width - 1 : 0] q;
    reg[q_port_width - 1 : 0] q_pipeline[pipeline : 0];
    reg[r_port_width - 1 : 0] r_temp;
    reg[r_port_width - 1 : 0] remainder;
    reg[r_port_width - 1 : 0] remainder_pipeline[pipeline : 0];
    reg clk_pre; // Hold previous clock value

// INTERNAL TRI DECLARATION
    tri1 ena;
    tri0 aclr;

// LOCAL INTEGER DECLARATION
    integer value1;
    integer value2;
    integer index;
    integer q_index;
    integer q_value_temp;
    integer r_value_temp;
    integer head;
    integer i1;
    integer i2;


// INITIAL CONSTRUCT BLOCK
    initial
    begin : INITIALIZE
        head = 0;

        // Check for illegal mode
        if(width < 1)
        begin
            $display("width (%d) must be greater than 0.(ERROR)", width);
            $stop;
        end
    end // INITIALIZE

// ALWAYS CONSTRUCT BLOCK

    // Asynchronous clear signal
    always @(aclr)
    begin : ASYN_CLEAR
        if(aclr == 1'b1) // Clear output ports and reset variables
        begin
            for(i1 = PIPELINE_INT - 1; i1 >= 0; i1 = i1-1)
            begin
                q_pipeline[i1] <= 0;
                remainder_pipeline[i1] <= 0;
            end

            q <= {q_port_width{1'b0}};
            remainder <= {r_port_width{1'b0}};

        end
    end // ASYN_CLEAR

    // Perform square root calculation.
    // In general, below are the steps to calculate the square root and the
    // remainder.
    //
    // Start of with q = 0 and remainder= 0
    // For every iteration, do the same thing:
    // 1) Shift in the next 2 bits of the radical into the remainder
    //    Eg. if the radical is b"101100". For the first iteration,
    //      the remainder will be equal to b"10".
    // 2) Compare it to the 4* q + 1
    // 3) if the remainder is greater than or equal to 4*q + 1
    //        remainder = remainder - (4*q + 1)
    //        q = 2*q + 1
    //    otherwise
    //        q = 2*q
    always @(clk or radical)
    begin : SQUARE_ROOT


        // When clk is enabled and is rising with no asyn. clear (reg mode)
        // or radical has change (comb. mode),
        // perform the square root calculation.
        if ((aclr != 1'b1) &&
           ((pipeline == 0) || ((clk == 1'b1) && (clk_pre == 1'b0) &&
            (ena == 1'b1))))
        begin

            // Reset variables
            value1 = 0;
            value2 = 0;
            q_index = (width - 1) / 2;
            q_value_temp = 0;
            r_value_temp = 0;
            index = width;
            q_temp = {q_port_width{1'b0}};
            r_temp = {r_port_width{1'b0}};

            // If the number of the bits of the radical is an odd number,
            // Then for the first iteration, only the 1st bit will be shifted
            // into the remainder.
            // Eg. if the radical is b"11111", then the remainder is b"01".
            if((width % 2) == 1)
            begin
                value1 = 0;
                value2 = (radical[index - 1] === 1'b1) ? 1 : 0;
                index = index + 1;
            end
            else if (width > 1)
            begin
            // Otherwise, for the first iteration, the first two bits will be shifted
            // into the remainder.
            // Eg. if the radical is b"101111", then the remainder is b"10".
                value1 = (radical[index - 1] === 1'b1) ? 1 : 0;
                value2 = (radical[index - 2] === 1'b1) ? 1 : 0;
            end

            // For every iteration
            for(index = index - 2; index >= 0; index = index - 2)
            begin
                // Get the remainder value by shift in the next 2 bits
                // of the radical into the remainder
                r_value_temp =  (r_value_temp * 4) + (2 * value1) + value2;

                // if remainder >= (4*q + 1)
                if (r_value_temp >= ((4 * q_value_temp)  + 1))
                begin
                    // remainder = remainder - (4*q + 1)
                    r_value_temp = r_value_temp - (4 * q_value_temp)  - 1;
                    // q = 2*q + 1
                    q_value_temp = (2 * q_value_temp) + 1;
                    // set the q[q_index] = 1
                    q_temp[q_index] = 1'b1;
                end
                else  // if remainder < (4*q + 1)
                begin
                    // q = 2*q
                    q_value_temp = 2 * q_value_temp;
                    // set the q[q_index] = 0
                    q_temp[q_index] = 1'b0;
                end

                // if not the last iteration, get the next 2 bits of the radical
                if(index >= 2)
                begin
                    value1 = (radical[index - 1] === 1'b1)? 1: 0;
                    value2 = (radical[index - 2] === 1'b1)? 1: 0;
                end

                // Reduce the current index of the q by 1
                q_index = q_index - 1;

            end

            // Get the binary bits of the remainder by converting integer to
            // binary bits
            for(i2 = 0; i2 <= (width + 1) / 2; i2 = i2 + 1)
            begin
                r_temp[i2] = ((r_value_temp % 2) === 1)? 1'b1 : 1'b0;
                r_value_temp = r_value_temp / 2;
            end

            // store the result to a pipeline(to create the latency)
            remainder_pipeline[head] = r_temp;
            q_pipeline[head] = q_temp;

            head = (head + 1) % PIPELINE_INT;

           // Get output value
           remainder = remainder_pipeline[head];
           q = q_pipeline[head];

        end

        clk_pre <= clk;
    end

endmodule //altsqrt 
// END OF MODULE


