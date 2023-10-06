`timescale 1ns / 1ps
module top_level(   input clk_100mhz,//时钟
                    input [15:0] sw, //开关控制其中[8:7]控制调式，[15:13]控制音量
                    input btnc, btnd, //复位信号
                    input vauxp3,//差分正极
                    input vauxn3,//差分负极
                    input vn_in,
                    input vp_in,
                    output  [15:0] led,
                    output  aud_pwm,//音频输出
                    output  aud_sd//恒为1
    );  

    parameter SAMPLE_COUNT = 2082;//用100mhz获得48 kHz采样率.

    
    wire [11:0] adc_data;//xadc的数据
    wire sample_trigger;//采样触发信号
    wire adc_ready;     //adc转换完成信号       
    wire [15:0] fft_data;//fft的结果
    wire       fft_ready;//fft完成
    wire       fft_valid;//fft有效
    wire       fft_last;//fft结束
    wire [9:0] fft_data_counter;//fft计数
    wire fft_out_ready;//fft输出准备
    wire fft_out_valid;//fft输出有效
    wire fft_out_last;//fft输出结束
    wire [31:0] fft_out_data;//fft输出结果
    wire sqsum_valid;
    wire sqsum_last;
    wire sqsum_ready;
    wire [31:0] sqsum_data;
    wire [23:0] sqrt_data;
    wire sqrt_valid;
    wire sqrt_last;
    
    assign led = sw; //just to look pretty 
    
    wire oversample_trigger;
    wire [11:0] oversampled_data;
    wire [2:0] state;
    
    hannFSM hann (.clk_100mhz(clk_100mhz), .sample_trigger(oversample_trigger), .adc_data(oversampled_data),
                    .fft_last(fft_last), .fft_valid(fft_valid), .state(state),
                    .fft_data_counter(fft_data_counter), .fft_data(fft_data), .fft_ready(fft_ready));
                    
    oversampler  OS (.clk_100mhz(clk_100mhz), .rst(btnc), .data_in(adc_data), .sample_trigger(oversample_trigger), .data_out(oversampled_data));
       
    xadc_wiz_0 my_adc ( .dclk_in(clk_100mhz), .daddr_in(8'h13), //read from 0x13 for a
                        .vauxn3(vauxn3),.vauxp3(vauxp3),
                        .vp_in(1),.vn_in(1),
                        .di_in(16'b0),
                        .do_out(adc_data),.drdy_out(adc_ready),
                        .den_in(1), .dwe_in(0));
 
 

    //FFT module:
    //CONFIGURATION:
    //1 channel
    //transform length: 2048
    //target clock frequency: 100 MHz
    //target Data throughput: 50 Msps
    //Auto-select architecture
    //IMPLEMENTATION:
    //Fixed Point, Scaled, Truncation
    //Natural ordering!!
    //Input Data Width, Phase Factor Width: Both 16 bits
    //Result uses 12 DSP48 Slices and 6 Block RAMs (under Impl Details)
    xfft_0 my_fft (.aclk(clk_100mhz), .s_axis_data_tdata(fft_data), 
                    .s_axis_data_tvalid(fft_valid),
                    .s_axis_data_tlast(fft_last), .s_axis_data_tready(fft_ready),
                    .s_axis_config_tdata(0), 
                     .s_axis_config_tvalid(0),
                     .s_axis_config_tready(),
                    .m_axis_data_tdata(fft_out_data), .m_axis_data_tvalid(fft_out_valid),
                    .m_axis_data_tlast(fft_out_last), .m_axis_data_tready(fft_out_ready));
    
    //for debugging commented out, make this whatever size,detail you want:
    
    //custom module (was written with a Vivado AXI-Streaming Wizard so format looks inhuman
    //this is because it was a template I customized.
    square_and_sum_v1_0 mysq(.s00_axis_aclk(clk_100mhz), .s00_axis_aresetn(1'b1),
                            .s00_axis_tready(fft_out_ready),
                            .s00_axis_tdata(fft_out_data),.s00_axis_tlast(fft_out_last),
                            .s00_axis_tvalid(fft_out_valid),.m00_axis_aclk(clk_100mhz),
                            .m00_axis_aresetn(1'b1),. m00_axis_tvalid(sqsum_valid),
                            .m00_axis_tdata(sqsum_data),.m00_axis_tlast(sqsum_last),
                            .m00_axis_tready(sqsum_ready));
    
  

    //AXI4-STREAMING Square Root Calculator:
    //CONFIGUATION OPTIONS:
    // Functional Selection: Square Root
    //Architec Config: Parallel (can't change anyways)
    //Pipelining: Max
    //Data Format: UnsignedInteger
    //Phase Format: Radians, the way God intended.
    //Input Width: 32
    //Output Width: 17
    //Round Mode: Truncate
    //0 on the others, and no scale compensation
    //AXI4 STREAM OPTIONS:
    //Has TLAST!!! need to propagate that
    //Don't need a TUSER
    //Flow Control: Blocking
    //optimize Goal: Performance
    //leave other things unchecked.
    cordic_0 mysqrt (.aclk(clk_100mhz), .s_axis_cartesian_tdata(sqsum_data),
                     .s_axis_cartesian_tvalid(sqsum_valid), .s_axis_cartesian_tlast(sqsum_last),
                     .s_axis_cartesian_tready(sqsum_ready),.m_axis_dout_tdata(sqrt_data),
                     .m_axis_dout_tvalid(sqrt_valid), .m_axis_dout_tlast(sqrt_last));
    
    
   
         
    
    wire [31:0]    fft_val;

    // Intermediate values
    wire [31:0] fund_val;
    wire  [15:0] fund_index; // FFT_size is 2048
    wire  [31:0] second_val;
    wire  [15:0] second_index;
    wire  [31:0] third_val;
    wire  [15:0] third_index;
    wire  [31:0] fourth_val;
    wire  [15:0] fourth_index;
    wire         done;
    wire  [23:0]    fcw1;
    wire  [23:0]    fcw2;
    wire  [23:0]    fcw3;
    wire  [23:0]    fcw4;
    
    // Output sine wave
    wire  [11:0]    sin_out1;
    wire  [11:0]    sin_out2;
    wire  [11:0]    sin_out3;
    wire  [11:0]    sin_out4;
    wire  [11:0]    true_sin_out;
    
    assign true_sin_out = (sin_out1 >> 1) + (sin_out2 >> 1) + (sin_out3 >> 2) + (sin_out4 >> 2); 

    // lab5a vals
    reg  [15:0] sample_counter;
    reg   [11:0] sample_gen_data_reg;
    wire  [11:0] sample_gen_data;
    assign sample_gen_data=sample_gen_data_reg;
    wire  [7:0] vol_out;
    wire  pwm_val; //pwm signal (HI/LO)
    wire  sample_trigger2;
    wire  [1:0] scale_choice;
    
    assign scale_choice = sw[8:7];


    assign aud_sd = 1;
    assign sample_trigger2 = (sample_counter == SAMPLE_COUNT);

    always@(posedge clk_100mhz)begin
        if (sample_counter == SAMPLE_COUNT)begin
            sample_counter <= 16'b0;
        end else begin
            sample_counter <= sample_counter + 16'b1;
        end
        if (sample_trigger2) begin
            sample_gen_data_reg <= {~true_sin_out[11],true_sin_out[10:4]}; // data is already in offset binary
            //https://en.wikipedia.org/wiki/Offset_binary
        end
    end

    // EVERYTHING UNTIL THIS POINT WAS IN LAB5A

    ///////////////
    /// TEST VALS
    ///////////////
    wire [5:0]  test_harmonic_counter;
    wire [31:0] test_fft_mem;
    wire        find_harmoincs_test;

    ///////////////
    // PEAK FINDER
    ///////////////
    peak_finder_v4 #(.FFT_SIZE('d1024), .ROI('d3)) v3_test (.clk(clk_100mhz), .reset(btnd), .t_valid(sqsum_valid), .fft_val(sqsum_data[31:0]),
                            .fund_val(fund_val), .fund_index(fund_index),
                            .second_val(second_val), .second_index(second_index),
                            .third_val(third_val), .third_index(third_index),
                            .fourth_val(fourth_val), .fourth_index(fourth_index),
                            .done(done),
                            
                            // Test vals
                            .harmonic_counter_test(test_harmonic_counter),
                            .fft_mem_test(test_fft_mem),
                            .find_harmonics_test(find_harmonics_test)
                        );
                        
    ///////////////
    /// ILA
    ///////////////
    //ila_0 myila (.clk(clk_100mhz), .probe0(sqrt_data), .probe1(fund_val), .probe2(second_val), .probe3(fund_index), .probe4(second_index), .probe5(third_index), .probe6(sqrt_valid), .probe7(done), .probe8(find_harmonics_test), .probe9(test_harmonic_counter), .probe10(test_fft_mem));
    ila_0 myila (.clk(clk_100mhz), .probe0(sqsum_valid), .probe1(sqsum_data));

    ///////////////
    /// TUNING
    ///////////////
    tuning tune_test1 (.clk(clk_100mhz), .rst(btnd), .fundamental_index(fund_index),
                      .scale_choice(scale_choice), .fcw(fcw1));
    tuning tune_test2 (.clk(clk_100mhz), .rst(btnd), .fundamental_index(second_index),
                      .scale_choice(scale_choice), .fcw(fcw2));
    tuning tune_test3 (.clk(clk_100mhz), .rst(btnd), .fundamental_index(third_index),
                      .scale_choice(scale_choice), .fcw(fcw3));
    tuning tune_test4 (.clk(clk_100mhz), .rst(btnd), .fundamental_index(fourth_index),
                      .scale_choice(scale_choice), .fcw(fcw4));
    
    ///////////////
    /// SINE GENERATION
    ///////////////
    sine_resyn resyn_test (.clk(clk_100mhz), .reset(btnd), .fcw(fcw1),
                      .sin_out(sin_out1));
    sine_resyn resyn_test1 (.clk(clk_100mhz), .reset(btnd), .fcw(fcw2),
                      .sin_out(sin_out2));
    sine_resyn resyn_test2 (.clk(clk_100mhz), .reset(btnd), .fcw(fcw3),
                      .sin_out(sin_out3));
    sine_resyn resyn_test3 (.clk(clk_100mhz), .reset(btnd), .fcw(fcw4),
                      .sin_out(sin_out4));


    ///////////////
    /// VOLUME
    ///////////////
    volume_control vc (.vol_in(sw[15:13]),
                       .signal_in(sample_gen_data), .signal_out(vol_out));

    ///////////////
    /// AUDIO OUTPUT
    ///////////////
    pwm (.clk_in(clk_100mhz), .rst_in(btnd), .level_in({~vol_out[7],vol_out[6:0]}), .pwm_out(pwm_val));
    assign aud_pwm = pwm_val?1'bZ:1'b0;
    
endmodule

// this is the module from Joe

module square_and_sum_v1_0 #
    (
        // Users to add parameters here

        // User parameters ends
        // Do not modify the parameters beyond this line


        // Parameters of Axi Slave Bus Interface S00_AXIS
        parameter integer C_S00_AXIS_TDATA_WIDTH    = 32,

        // Parameters of Axi Master Bus Interface M00_AXIS
        parameter integer C_M00_AXIS_TDATA_WIDTH    = 32,
        parameter integer C_M00_AXIS_START_COUNT    = 32
    )
    (
        // Users to add ports here

        // User ports ends
        // Do not modify the ports beyond this line


        // Ports of Axi Slave Bus Interface S00_AXIS
        input wire  s00_axis_aclk,
        input wire  s00_axis_aresetn,
        output wire  s00_axis_tready,
        input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
        input wire  s00_axis_tlast,
        input wire  s00_axis_tvalid,

        // Ports of Axi Master Bus Interface M00_AXIS
        input wire  m00_axis_aclk,
        input wire  m00_axis_aresetn,
        output wire  m00_axis_tvalid,
        output wire [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
        output wire  m00_axis_tlast,
        input wire  m00_axis_tready
    );
    
    reg m00_axis_tvalid_reg_pre;
    reg m00_axis_tlast_reg_pre;
    reg m00_axis_tvalid_reg;
    reg m00_axis_tlast_reg;
    reg [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata_reg;
    
    reg s00_axis_tready_reg;
    reg signed [31:0] real_square;
    reg signed [31:0] imag_square;
    
    wire signed [15:0] real_in;
    wire signed [15:0] imag_in;
    assign real_in = s00_axis_tdata[31:16];
    assign imag_in = s00_axis_tdata[15:0];
    
    assign m00_axis_tvalid = m00_axis_tvalid_reg;
    assign m00_axis_tlast = m00_axis_tlast_reg;
    assign m00_axis_tdata = m00_axis_tdata_reg;
    assign s00_axis_tready = s00_axis_tready_reg;
    
    always @(posedge s00_axis_aclk)begin
        if (s00_axis_aresetn==0)begin
            s00_axis_tready_reg <= 0;
        end else begin
            s00_axis_tready_reg <= m00_axis_tready; //if what you're feeding data to is ready, then you're ready.
        end
    end
    
    always @(posedge m00_axis_aclk)begin
        if (m00_axis_aresetn==0)begin
            m00_axis_tvalid_reg <= 0;
            m00_axis_tlast_reg <= 0;
            m00_axis_tdata_reg <= 0;
        end else begin
            m00_axis_tvalid_reg_pre <= s00_axis_tvalid; //when new data is coming, you've got new data to put out
            m00_axis_tlast_reg_pre <= s00_axis_tlast; //
            real_square <= real_in*real_in;
            imag_square <= imag_in*imag_in;
            
            m00_axis_tvalid_reg <= m00_axis_tvalid_reg_pre; //when new data is coming, you've got new data to put out
            m00_axis_tlast_reg <= m00_axis_tlast_reg_pre; //
            m00_axis_tdata_reg <= real_square + imag_square;
        end
    end
    
    
endmodule


//PWM generator for audio generation!
module pwm (input clk_in, input rst_in, input [7:0] level_in, output pwm_out);
    reg [7:0] count;
    assign pwm_out = count<level_in;
    always @(posedge clk_in)begin
        if (rst_in)begin
            count <= 8'b0;
        end else begin
            count <= count+8'b1;
        end
    end
endmodule

//Volume Control
module volume_control (input [2:0] vol_in, input signed [7:0] signal_in, output signed[7:0] signal_out);
    wire [2:0] shift;
    assign shift = 3'd7 - vol_in;
    assign signal_out = signal_in>>>shift;
endmodule
