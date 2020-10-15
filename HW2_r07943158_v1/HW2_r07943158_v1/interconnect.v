module interconnect #
(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 16
)
(
	input         			clk,
	input         			rst_n,
	input  [ADDR_WIDTH-1:0] m0_awaddr,
	input         			m0_awvalid,
	output        			m0_awready,
	input  [DATA_WIDTH-1:0] m0_wdata,
	input         			m0_wvalid,
	output        			m0_wready,
	input  [ADDR_WIDTH-1:0] m1_awaddr,
	input         			m1_awvalid,
	output        			m1_awready,
	input  [DATA_WIDTH-1:0] m1_wdata,
	input         			m1_wvalid,
	output        			m1_wready,
	output [ADDR_WIDTH-1:0] mem_awaddr,
	output        			mem_awvalid,
	input         			mem_awready,
	output [DATA_WIDTH-1:0] mem_wdata,
	output        			mem_wvalid,
	input         			mem_wready
);

//FIFO
wire AWFIFO_iready, AWFIFO_full, AWFIFO_almost_full;
wire  WFIFO_iready,  WFIFO_full,  WFIFO_almost_full;

//controller
wire control_aw_sel, control_w_sel;

wire [ADDR_WIDTH-1 : 0] awaddr_sel;
wire [DATA_WIDTH-1 : 0] wdata_sel;
wire awvalid_sel, wvalid_sel;

assign awaddr_sel  = control_aw_sel ? m1_awaddr  : m0_awaddr;
assign awvalid_sel = control_aw_sel ? m1_awvalid : m0_awvalid;
assign  wdata_sel  = control_w_sel  ? m1_wdata   : m0_wdata;
assign  wvalid_sel = control_w_sel  ? m1_wvalid  : m0_wvalid;

fifo #(.DATA_WIDTH(ADDR_WIDTH)) AWFIFO (.clk(clk), .rst_n(rst_n), .idata(awaddr_sel), .ivalid(awvalid_sel), 
	.iready(AWFIFO_iready), .odata(mem_awaddr), .ovalid(mem_awvalid), .oready(mem_awready), 
	.full(AWFIFO_full), .almost_full(AWFIFO_almost_full)); 

fifo #(.DATA_WIDTH(DATA_WIDTH)) WFIFO (.clk(clk), .rst_n(rst_n), .idata(wdata_sel), .ivalid(wvalid_sel), 
	.iready(WFIFO_iready), .odata(mem_wdata), .ovalid(mem_wvalid), .oready(mem_wready), 
	.full(WFIFO_full), .almost_full(WFIFO_almost_full));

controller Controller (.clk(clk), .rst_n(rst_n), .m0_awready(m0_awready), .m1_awready(m1_awready), 
	.m0_wready(m0_wready), .m1_wready(m1_wready), .m0_awvalid(m0_awvalid), .m1_awvalid(m1_awvalid), 
	.m0_wvalid(m0_wvalid), .m1_wvalid(m1_wvalid), .aw_select(control_aw_sel), .w_select(control_w_sel), 
	.awfifo_iready(AWFIFO_iready), .wfifo_iready(WFIFO_iready), .awfifo_almost_full(AWFIFO_almost_full), 
	.wfifo_almost_full(WFIFO_almost_full), .awfifo_full(AWFIFO_full), .wfifo_full(WFIFO_full)); 

endmodule
