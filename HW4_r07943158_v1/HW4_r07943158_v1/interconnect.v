// Single transaction interconnect
module interconnect #
(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 16
)
(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [ADDR_WIDTH-1:0] m0_awaddr,
    input  wire                  m0_awvalid,
    output wire                  m0_awready,
    input  wire [DATA_WIDTH-1:0] m0_wdata,
    input  wire                  m0_wvalid,
    output wire                  m0_wready,
    input  wire [ADDR_WIDTH-1:0] m1_awaddr,
    input  wire                  m1_awvalid,
    output wire                  m1_awready,
    input  wire [DATA_WIDTH-1:0] m1_wdata,
    input  wire                  m1_wvalid,
    output wire                  m1_wready,
    output wire [ADDR_WIDTH-1:0] mem_awaddr,
    output wire                  mem_awvalid,
    input  wire                  mem_awready,
    output wire [DATA_WIDTH-1:0] mem_wdata,
    output wire                  mem_wvalid,
    input  wire                  mem_wready,
    input  wire [           1:0] mem_bresp,
    input  wire                  mem_bvalid,
    output wire                  mem_bready,
    output wire [           1:0] m0_bresp,
    output wire                  m0_bvalid,
    input  wire                  m0_bready,
    output wire [           1:0] m1_bresp,
    output wire                  m1_bvalid,
    input  wire                  m1_bready,

   	output wire                  m_priority
);

	localparam IDLE  = 0;
	localparam M0_AW = 1;
	localparam M0_W  = 2;
	localparam M0_B  = 3;
	localparam M1_AW = 4;
	localparam M1_W  = 5;
	localparam M1_B  = 6;
	localparam S_AW  = 7;
	localparam S_W   = 8;
	localparam S_B   = 9;

	reg  [           3:0] STATE, NEXT_STATE;
	reg  [           2:0] counter_r, counter_w;
	reg                   priority_r, priority_w;
	reg  [ADDR_WIDTH-1:0] addr_buf_r, addr_buf_w;
	reg  [DATA_WIDTH-1:0] data_buf_r, data_buf_w;
	reg  [           1:0] resp_buf_r, resp_buf_w;
	wire                  m0_aw_handshake, m1_aw_handshake, s_aw_handshake;
	wire                  m0_w_handshake, m1_w_handshake, s_w_handshake;
	wire                  m0_b_handshake, m1_b_handshake, s_b_handshake;

	// control signals
	assign m0_aw_handshake = m0_awready && m0_awvalid;
	assign m1_aw_handshake = m1_awready && m1_awvalid;
	assign s_aw_handshake  = mem_awready && mem_awvalid;
	assign m0_w_handshake  = m0_wready && m0_wvalid;
	assign m1_w_handshake  = m1_wready && m1_wvalid;
	assign s_w_handshake   = mem_wready && mem_wvalid;
	assign m0_b_handshake  = m0_bready && m0_bvalid;
	assign m1_b_handshake  = m1_bready && m1_bvalid;
	//assign s_b_handshake   = mem_bready || mem_bvalid;
	assign s_b_handshake   = mem_bready && mem_bvalid;

	// m0_interface	
	assign m0_awready = (STATE == M0_AW);
	assign m0_wready  = (STATE == M0_W );
	assign m0_bvalid  = (STATE == M0_B );
	assign m0_bresp   = resp_buf_r;
	// m1_interface	
	assign m1_awready = (STATE == M1_AW);
	assign m1_wready  = (STATE == M1_W );
	assign m1_bvalid  = (STATE == M1_B );
	assign m1_bresp   = resp_buf_r;
	// s_interface
	assign mem_awvalid = (STATE == S_AW);
	assign mem_awaddr  = addr_buf_r; 
	assign mem_wvalid  = (STATE == S_W ); 
	assign mem_wdata   = data_buf_r;
	assign mem_bready  = (STATE == S_B );

	assign m_priority = priority_r;

	// NEXT_STATE
	always@(*) begin
		case(STATE)
			IDLE  : NEXT_STATE = M0_AW;
			M0_AW : NEXT_STATE = (m0_aw_handshake) ? M0_W : M0_AW;
			M0_W  : NEXT_STATE = (m0_w_handshake)  ? S_AW : M0_W;
			//M0_B  : NEXT_STATE = (m0_b_handshake)  ? (counter_r == 9 ? M1_AW : M0_AW) : M0_B;
			M0_B  : NEXT_STATE = (m0_b_handshake)  ? (counter_r == 7 ? M1_AW : M0_AW) : M0_B;
			M1_AW : NEXT_STATE = (m1_aw_handshake) ? M1_W : M1_AW;
			M1_W  : NEXT_STATE = (m1_w_handshake)  ? S_AW : M1_W;
			//M1_B  : NEXT_STATE = (counter_r == 7)  ? M0_AW : M1_AW;
			M1_B  : NEXT_STATE = (m1_b_handshake)  ? (counter_r == 7 ? M0_AW : M1_AW) : M1_B;
			S_AW  : NEXT_STATE = (s_aw_handshake)  ? S_W : S_AW;
			S_W   : NEXT_STATE = (s_w_handshake)   ? S_B : S_W;
			//S_B   : NEXT_STATE = priority_r ? M1_B : M0_B;
			S_B   : NEXT_STATE = (s_b_handshake) ? (priority_r ? M1_B : M0_B) : S_B;
		endcase
	end

	// counter_w & priority_w
	always@(*) begin
		if(STATE == M0_B) begin
			counter_w  = (m0_b_handshake) ? counter_r + 1 : counter_r;
			priority_w = (counter_r == 7 && m0_b_handshake) ? 1 : 0;
		end
		else if(STATE == M1_B) begin
			counter_w  = (m1_b_handshake) ? counter_r + 1 : counter_r;
			priority_w = (counter_r == 7 && m1_b_handshake) ? 0 : 1;
		end
		else begin
			counter_w  = counter_r;
			priority_w = priority_r;
		end
	end

	// addr_buf_w, data_buf_w, resp_buf_w
	always@(*) begin
		if     (STATE == M0_AW) addr_buf_w = (m0_aw_handshake) ? m0_awaddr : addr_buf_r;
		else if(STATE == M1_AW) addr_buf_w = (m1_aw_handshake) ? m1_awaddr : addr_buf_r;
		else                    addr_buf_w = addr_buf_r;
		//if     (STATE == M0_W)  data_buf_w = (m0_w_handshake) ? ~m0_wdata : data_buf_r;
		if     (STATE == M0_W)  data_buf_w = (m0_w_handshake) ? m0_wdata : data_buf_r;
		else if(STATE == M1_W)  data_buf_w = (m1_w_handshake) ? m1_wdata : data_buf_r;
		else                    data_buf_w = data_buf_r;
		if     (STATE == S_B)   resp_buf_w = (s_b_handshake) ? mem_bresp : resp_buf_r;
		else                    resp_buf_w = resp_buf_r;
	end

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			STATE      <= IDLE;
			counter_r  <= 0;
			priority_r <= 0;
			addr_buf_r <= 0;
			data_buf_r <= 0;
			resp_buf_r <= 0;
		end
		else begin
			STATE      <= NEXT_STATE;
			counter_r  <= counter_w;
			//priority_r <= priority_r;
			priority_r <= priority_w;
			addr_buf_r <= addr_buf_w;
			data_buf_r <= data_buf_w;
			resp_buf_r <= resp_buf_w;
		end
	end

endmodule
