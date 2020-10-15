module fv_tb;
    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 16;

    reg  clk, rst_n;
    wire [ADDR_WIDTH-1:0] m0_addr;
    wire                  m0_avalid;
    wire                  m0_aready;
    wire [DATA_WIDTH-1:0] m0_data;
    wire                  m0_dvalid;
    wire                  m0_dready;
    wire [ADDR_WIDTH-1:0] m1_addr;
    wire                  m1_avalid;
    wire                  m1_aready;
    wire [DATA_WIDTH-1:0] m1_data;
    wire                  m1_dvalid;
    wire                  m1_dready;
    wire [DATA_WIDTH-1:0] s_data;
    wire                  s_dvalid;
    wire                  s_dready;
    wire [ADDR_WIDTH-1:0] s_addr;
    wire                  s_avalid;
    wire                  s_aready;

    wire [           1:0] s_bresp;
    wire                  s_bvalid;
    wire                  s_bready;
    wire [           1:0] m0_bresp;
    wire                  m0_bvalid;
    wire                  m0_bready;
    wire [           1:0] m1_bresp;
    wire                  m1_bvalid;
    wire                  m1_bready;

    wire                  m_priority;
    
    interconnect #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH))
    interconnect_inst(
        .clk(clk),
        .rst_n(rst_n),
        .m0_awaddr(m0_addr),
        .m0_awvalid(m0_avalid),
        .m0_awready(m0_aready),
        .m0_wdata(m0_data),
        .m0_wvalid(m0_dvalid),
        .m0_wready(m0_dready),
        .m1_awaddr(m1_addr),
        .m1_awvalid(m1_avalid),
        .m1_awready(m1_aready),
        .m1_wdata(m1_data),
        .m1_wvalid(m1_dvalid),
        .m1_wready(m1_dready),
        .mem_awaddr(s_addr),
        .mem_awvalid(s_avalid),
        .mem_awready(s_aready),
        .mem_wdata(s_data),
        .mem_wvalid(s_dvalid),
        .mem_wready(s_dready),
        .mem_bresp(s_bresp),
        .mem_bvalid(s_bvalid),
        .mem_bready(s_bready),
        .m0_bresp(m0_bresp),
        .m0_bvalid(m0_bvalid),
        .m0_bready(m0_bready),
        .m1_bresp(m1_bresp),
        .m1_bvalid(m1_bvalid),
        .m1_bready(m1_bready),
        .m_priority(m_priority)
    );


    axi4_master master0 (
        .aclk            (clk),
        .aresetn         (rst_n),
        .awid            (),
        .awaddr          (m0_addr),
        .awlen           (),
        .awsize          (),
        .awburst         (),
        .awvalid         (m0_avalid),
        .awready         (m0_aready),

        .wdata           (m0_data),
        .wstrb           (),
        .wlast           (),
        .wvalid          (m0_dvalid),
        .wready          (m0_dready),
        
        .bid             (),
        .bresp           (m0_bresp),
        .bvalid          (m0_bvalid),
        .bready          (m0_bready)
        
    );

    defparam master0.AXI_LITE                = 1;
    defparam master0.WRITEONLY_INTERFACE     = 1;
    defparam master0.ADDR_WIDTH              = ADDR_WIDTH;
    defparam master0.DATA_WIDTH              = DATA_WIDTH;
    defparam master0.ID_WIDTH                = 1;
    //defparam master0.LEN_WIDTH               = LEN_WIDTH;
    defparam master0.MAX_PENDING             = 1;
    defparam master0.MAX_PENDING_RD          = 0;
    defparam master0.MAX_PENDING_WR          = 1;
    defparam master0.READ_INTERLEAVE_ON      = 0;
    defparam master0.BYTE_STROBE_ON          = 0;
    defparam master0.EXCL_ACCESS_ON          = 0;
    defparam master0.MAX_WAIT_CYCLES_ON      = 0;
    defparam master0.DATA_BEFORE_CONTROL_ON  = 1;

    axi4_master master1 (
        .aclk            (clk),
        .aresetn         (rst_n),
        .awid            (),
        .awaddr          (m1_addr),
        .awlen           (),
        .awsize          (),
        .awburst         (),
        .awvalid         (m1_avalid),
        .awready         (m1_aready),

     
        .wdata           (m1_data),
        .wstrb           (),
        .wlast           (),
        .wvalid          (m1_dvalid),
        .wready          (m1_dready),
        
        .bid             (),
        .bresp           (m1_bresp),
        .bvalid          (m1_bvalid),
        .bready          (m1_bready)
        
    );

    defparam master1.AXI_LITE                = 1;
    defparam master1.WRITEONLY_INTERFACE     = 1;
    defparam master1.ADDR_WIDTH              = ADDR_WIDTH;
    defparam master1.DATA_WIDTH              = DATA_WIDTH;
    defparam master1.ID_WIDTH                = 1;
    //defparam master1.LEN_WIDTH               = LEN_WIDTH;
    defparam master1.MAX_PENDING             = 1;
    defparam master1.MAX_PENDING_RD          = 0;
    defparam master1.MAX_PENDING_WR          = 1;
    defparam master1.READ_INTERLEAVE_ON      = 0;
    defparam master1.BYTE_STROBE_ON          = 0;
    defparam master1.EXCL_ACCESS_ON          = 0;
    defparam master1.MAX_WAIT_CYCLES_ON      = 0;
    defparam master1.DATA_BEFORE_CONTROL_ON  = 1;

    axi4_slave memory (
        .aclk            (clk),
        .aresetn         (rst_n),

        .awid            (),
        .awaddr          (s_addr),
        .awlen           (),
        .awsize          (),
        .awburst         (),
        .awvalid         (s_avalid),
        .awready         (s_aready),
      
        .wdata           (s_data),
        .wstrb           (),
        .wlast           (),
        .wvalid          (s_dvalid),
        .wready          (s_dready),
        
        .bid             (),
        .bresp           (s_bresp),
        .bvalid          (s_bvalid),
        .bready          (s_bready)
        
    );
    defparam memory.AXI_LITE                = 1;
    defparam memory.WRITEONLY_INTERFACE     = 1;
    defparam memory.ADDR_WIDTH              = ADDR_WIDTH;
    defparam memory.DATA_WIDTH              = DATA_WIDTH;
    defparam memory.ID_WIDTH                = 1;
  //defparam memory.LEN_WIDTH               = LEN_WIDTH;
    defparam memory.MAX_PENDING             = 1;
    defparam memory.MAX_PENDING_RD          = 0;
    defparam memory.MAX_PENDING_WR          = 1;
    defparam memory.READ_INTERLEAVE_ON      = 0;
    defparam memory.BYTE_STROBE_ON          = 0;
    defparam memory.EXCL_ACCESS_ON          = 0;
    defparam memory.MAX_WAIT_CYCLES_ON      = 0;
    defparam memory.DATA_BEFORE_CONTROL_ON  = 1;

    
    // Assumptions
    assume_s_aready_finally_come  : assume property ( @(posedge clk) (  s_avalid |-> (##[0:$] s_aready )) );
    assume_s_dready_finally_come  : assume property ( @(posedge clk) (  s_dvalid |-> (##[0:$] s_dready )) );
    assume_m0_avalid_finally_come : assume property ( @(posedge clk) ( m0_aready |-> (##[0:$] m0_avalid)) );
    assume_m1_avalid_finally_come : assume property ( @(posedge clk) ( m1_aready |-> (##[0:$] m1_avalid)) );
    assume_m0_dvalid_finally_come : assume property ( @(posedge clk) ( m0_dready |-> (##[0:$] m0_dvalid)) );
    assume_m1_dvalid_finally_come : assume property ( @(posedge clk) ( m1_dready |-> (##[0:$] m1_dvalid)) );
    assume_m0_bready_finally_come : assume property ( @(posedge clk) ( m0_bvalid |-> (##[0:$] m0_bready)) );
    assume_m1_bready_finally_come : assume property ( @(posedge clk) ( m1_bvalid |-> (##[0:$] m1_bready)) );

    // TODO: Address consistency 
    wire [ADDR_WIDTH-1:0] addr;
    assume_addr_sample_hold: assume property ( @(posedge clk) (addr == $past(addr)));
    assert_m0_addr_good_bb: assert property ( @(posedge clk) (m0_avalid && m0_aready && m0_addr == addr) |-> ##[0:$] s_avalid && s_aready && s_addr == addr);
    assert_m1_addr_good_bb: assert property ( @(posedge clk) (m1_avalid && m1_aready && m1_addr == addr) |-> ##[0:$] s_avalid && s_aready && s_addr == addr);
    
  // TODO: Data consistency
    wire [DATA_WIDTH-1:0] data;
    assume_data_sample_hold: assume property ( @(posedge clk) (data == $past(data)));
    assert_m0_data_good_bb: assert property ( @(posedge clk) (m0_dvalid && m0_dready && m0_data == data) |-> ##[0:$] s_dvalid && s_dready && s_data == data);
    assert_m1_data_good_bb: assert property ( @(posedge clk) (m1_dvalid && m1_dready && m1_data == data) |-> ##[0:$] s_dvalid && s_dready && s_data == data);
  
    // TODO: Response consistency
    wire [           1:0] resp;
    assume_resp_sample_hold: assume property ( @(posedge clk) (resp == $past(resp)));
    assert_m0_resp_good_bb: assert property ( @(posedge clk) (~m_priority && s_bready && s_bvalid && s_bresp == resp ) |-> ##[0:$] m0_bvalid && m0_bvalid && m0_bresp == resp);
    assert_m1_resp_good_bb: assert property ( @(posedge clk) (m_priority && s_bready && s_bvalid && s_bresp == resp ) |-> ##[0:$] m1_bvalid && m1_bvalid && m1_bresp == resp);
  
    // TODO: Arbitrate strategy glue logic
    reg  [3:0] count;
    wire [3:0] count_w;
    assign count_w = ((m0_bready && m0_bvalid) || (m1_bready && m1_bvalid)) ?count +4'd1 :count;
    
    always@(posedge clk or negedge rst_n) begin
	if (!rst_n)
		count <= 4'd0;
	else
		count <= count_w;
    end    

    assert_m0_aready_good_wb:assert property ( @(posedge clk) m0_aready |-> ##[0:$] !count[3]); 
    assert_m0_dready_good_wb:assert property ( @(posedge clk) m0_dready |-> ##[0:$] !count[3]);
    assert_m1_aready_good_wb:assert property ( @(posedge clk) m1_aready |-> ##[0:$]  count[3]);
    assert_m1_dready_good_wb:assert property ( @(posedge clk) m1_dready |-> ##[0:$]  count[3]); 
   
 
endmodule


