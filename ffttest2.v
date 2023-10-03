`timescale 1ns / 1ps
module FFT_test2();

reg clk;
reg rst_n;
reg signed [15:0] Time_data_I[127:0];
reg data_finish_flag;

wire              fft_s_config_tready;

reg signed [31:0] fft_s_data_tdata;
reg               fft_s_data_tvalid;
wire              fft_s_data_tready;
reg               fft_s_data_tlast;

wire signed [47:0] fft_m_data_tdata;
wire signed [7:0]  fft_m_data_tuser;
wire               fft_m_data_tvalid;
reg                fft_m_data_tready;
wire               fft_m_data_tlast;

wire          fft_event_frame_started;
wire          fft_event_tlast_unexpected;
wire          fft_event_tlast_missing;
wire          fft_event_status_channel_halt;
wire          fft_event_data_in_channel_halt;
wire          fft_event_data_out_channel_halt;

reg [7:0]     count;

reg signed [23:0] fft_i_out;
reg signed [23:0] fft_q_out;
reg signed [47:0] fft_abs;

initial begin
    clk = 1'b1;
    rst_n = 1'b0;
    fft_m_data_tready = 1'b1;
    $readmemb("C:/Users/mengmeng/Desktop/fft.txt",Time_data_I);
end

always #5 clk = ~clk;

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fft_s_data_tvalid <= 1'b0;
        fft_s_data_tdata  <= 32'd0;
        fft_s_data_tlast  <= 1'b0;
        data_finish_flag  <= 1'b0;
        count <= 8'd0;
        rst_n = 1'b1;
    end
    else if (fft_s_data_tready) begin 
        if(count == 8'd127) begin
            fft_s_data_tvalid <= 1'b1;
            fft_s_data_tlast  <= 1'b1;
            fft_s_data_tdata  <= {Time_data_I[count],16'd0};
            count <= 8'd0;
            data_finish_flag <= 1'b1;
        end
        else begin
            fft_s_data_tvalid <= 1'b1;
            fft_s_data_tlast  <= 1'b0;
            fft_s_data_tdata  <= {Time_data_I[count],16'd0};   
            count <= count + 1'b1;
        end
    end
    else begin
        fft_s_data_tvalid <= 1'b0;
        fft_s_data_tlast  <= 1'b0;
    end
end

always @ (posedge clk) begin
    if(fft_m_data_tvalid) begin
        fft_i_out <= fft_m_data_tdata[23:0];
        fft_q_out <= fft_m_data_tdata[47:24];
    end
end

always @ (posedge clk) begin
    fft_abs <= $signed(fft_i_out)* $signed(fft_i_out)+ $signed(fft_q_out)* $signed(fft_q_out);
end


//fft ip������
xfft_0 u_fft(
    .aclk(clk),                                                // ʱ���źţ�input��
    .aresetn(rst_n),                                           // ��λ�źţ�����Ч��input��
    .s_axis_config_tdata(8'd1),                                // ip�����ò������ݣ�Ϊ1ʱ��FFT���㣬Ϊ0ʱ��IFFT���㣨input��
    .s_axis_config_tvalid(1'b1),                               // ip������������Ч����ֱ������Ϊ1��input��
    .s_axis_config_tready(fft_s_config_tready),                // output wire s_axis_config_tready
    //��Ϊ����ʱ������ʱ�Ǵ��豸
    .s_axis_data_tdata(fft_s_data_tdata),                      // ��ʱ���ź���FFT IP�˴��������ͨ��,[31:16]Ϊ�鲿��[15:0]Ϊʵ����input����->�ӣ�
    .s_axis_data_tvalid(fft_s_data_tvalid),                    // ��ʾ���豸��������һ����Ч�Ĵ��䣨input����->�ӣ�
    .s_axis_data_tready(fft_s_data_tready),                    // ��ʾ���豸�Ѿ�׼���ý���һ�����ݴ��䣨output����->��������tvalid��treadyͬʱΪ��ʱ���������ݴ���
    .s_axis_data_tlast(fft_s_data_tlast),                      // ���豸����豸���ʹ�������źţ�input����->�ӣ�����Ϊ������
    //��Ϊ����Ƶ������ʱ�����豸
    .m_axis_data_tdata(fft_m_data_tdata),                      // FFT�����Ƶ�����ݣ�[47:24]��Ӧ�����鲿���ݣ�[23:0]��Ӧ����ʵ������(output����->��)��
    .m_axis_data_tuser(fft_m_data_tuser),                      // ���Ƶ�׵�����(output����->��)����ֵ*fs/N��Ϊ��ӦƵ�㣻
    .m_axis_data_tvalid(fft_m_data_tvalid),                    // ��ʾ���豸��������һ����Ч�Ĵ��䣨output����->�ӣ�
    .m_axis_data_tready(fft_m_data_tready),                    // ��ʾ���豸�Ѿ�׼���ý���һ�����ݴ��䣨input����->��������tvalid��treadyͬʱΪ��ʱ���������ݴ���
    .m_axis_data_tlast(fft_m_data_tlast),                      // ���豸����豸���ʹ�������źţ�output����->�ӣ�����Ϊ������
    //�����������
    .event_frame_started(fft_event_frame_started),                  // output wire event_frame_started
    .event_tlast_unexpected(fft_event_tlast_unexpected),            // output wire event_tlast_unexpected
    .event_tlast_missing(fft_event_tlast_missing),                  // output wire event_tlast_missing
    .event_status_channel_halt(fft_event_status_channel_halt),      // output wire event_status_channel_halt
    .event_data_in_channel_halt(fft_event_data_in_channel_halt),    // output wire event_data_in_channel_halt
    .event_data_out_channel_halt(fft_event_data_out_channel_halt)   // output wire event_data_out_channel_halt
  );
    
    
endmodule
