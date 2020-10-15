// TODO: time unit, clock period, etc.
`timescale 1ns/10ps
`define CYCLE    1.0           	        // Modify your clock period here
`define TERMINATION  800000

`define DATA_WIDTH 8
`define ADDR_WIDTH 16
`define MAX_DELAY 16
`define MAX_error 10
//`define MSG
//`define FILE "/path/to/file"

module tb;
    reg clk, rst_n;
    // TODO: clock generation
    always #(`CYCLE/2) clk = ~clk;

    initial begin
        // TODO: setting up .vcd/.fsdb waveform dump
        $timeformat(-9, 2, " ns", 17);

        $fsdbDumpfile("interconnect.fsdb");
        $fsdbDumpvars;
        $fsdbDumpMDA;
    end

    // TODO: module instantiation and reg/wire connection
    parameter ADDR = 2** `ADDR_WIDTH;

    reg down;
    reg [`DATA_WIDTH-1 : 0] mem [0 : ADDR -1];
    reg [`DATA_WIDTH-1 : 0] wdata_order [0 : ADDR -1];
    reg [`ADDR_WIDTH-1 : 0] awaddr_order [0 : ADDR -1];

    reg pre_wvalid, pre_wready, pre_awready, pre_awvalid, pre_w_sel, pre_aw_sel, test3_w, test3_aw;
    integer error, w_received, aw_received, m_wshake, m_awshake, w_ptr, aw_ptr;
    wire w_select, aw_select;

    integer i;
    
    wire [`DATA_WIDTH-1 : 0] m0_wdata, m1_wdata, mem_wdata;
    wire [`ADDR_WIDTH-1 : 0] m0_awaddr, m1_awaddr, mem_awaddr;
    wire m0_wvalid, m0_wready, m0_awvalid, m0_awready;
    wire m1_wvalid, m1_wready, m1_awvalid, m1_awready;
    wire mem_wvalid, mem_wready, mem_awvalid, mem_awready;
    wire mem_wready_test, mem_awready_test, mem_wvalid_test, mem_awvalid_test;

    wire [`ADDR_WIDTH-2 : 0] m0_waddr, m1_waddr, m0_awaddr_o, m1_awaddr_o;
    wire m0_wfinish, m0_awfinish, m1_wfinish, m1_awfinish;

    assign w_select = DUT.Controller.w_select;
    assign aw_select = DUT.Controller.aw_select;
    assign mem_wready_test  = test3_w  ? mem_wready  : 1'b0;
    assign mem_awready_test = test3_aw ? mem_awready : 1'b0;
    assign mem_wvalid_test  = test3_w  ? mem_wvalid  : 1'b0;
    assign mem_awvalid_test = test3_aw ? mem_awvalid : 1'b0;
    

    initial begin
        // TODO: initialize memory with your test pattern
        `ifdef FILE
            $readmemb(`FILE, mem);
        `else 
            for(i = 0; i < ADDR; i = i+1)mem[i] = $random % (2**`DATA_WIDTH);
        `endif

        error = 0;
        w_received = 0;
        aw_received = 0;
        m_wshake = 0;
        m_awshake = 0;
        w_ptr = 0;
        aw_ptr = 0;

        down = 0;
        pre_wready = 0;
        pre_wvalid = 0;
        pre_awready = 0;
        pre_awvalid = 0;
        pre_w_sel = 0;
        pre_aw_sel = 0;
        test3_w = 0;
        test3_aw = 0;
        
        clk = 1;
        rst_n = 1;

        $display("======================================================================");
        $display("Start simulation !");
        $display("======================================================================");
        
        #(`CYCLE/2) rst_n = 0;
        #(`CYCLE*3) rst_n = 1;

        if(w_select !== 1'b0) begin
            error = 81;
            down = 1;
        end

        if(aw_select !== 1'b0) begin
            error = 82;
            down = 1;
        end
    end

    // TODO: interconnect instantiation
    interconnect #(.DATA_WIDTH(`DATA_WIDTH), .ADDR_WIDTH(`ADDR_WIDTH)) DUT (
        // TODO: connection
        .clk(clk), .rst_n(rst_n), .m0_wdata(m0_wdata), .m1_wdata(m1_wdata), .mem_wdata(mem_wdata), 
        .m0_awaddr(m0_awaddr), .m1_awaddr(m1_awaddr), .mem_awaddr(mem_awaddr), 
        .m0_wvalid(m0_wvalid), .m0_wready(m0_wready), .m0_awvalid(m0_awvalid), .m0_awready(m0_awready), 
        .m1_wvalid(m1_wvalid), .m1_wready(m1_wready), .m1_awvalid(m1_awvalid), .m1_awready(m1_awready), 
        .mem_wvalid(mem_wvalid), .mem_wready(mem_wready_test), .mem_awvalid(mem_awvalid), .mem_awready(mem_awready_test)
    );

    memory #(.DATA_WIDTH(`DATA_WIDTH), .ADDR_WIDTH(`ADDR_WIDTH)) memory_inst (
        .clk(clk), .rst_n(rst_n), .wdata(mem_wdata), .awaddr(mem_awaddr), 
        .wvalid(mem_wvalid_test), .wready(mem_wready), .awvalid(mem_awvalid_test), .awready(mem_awready)
    );

    // TODO: feed pattern into DUT
    assign m0_wdata  = m0_wvalid  ? mem[{1'b0, m0_waddr}] : 0;
    assign m1_wdata  = m1_wvalid  ? mem[{1'b1, m1_waddr}] : 0;
    assign m0_awaddr = m0_awvalid ? {1'b0, m0_awaddr_o}   : 0;
    assign m1_awaddr = m1_awvalid ? {1'b1, m1_awaddr_o}   : 0;

    master #(.ADDR_WIDTH(`ADDR_WIDTH-1), .MAX_DELAY(`MAX_DELAY)) m0_aw (
        .clk(clk), .rst_n(rst_n), .ready_i(m0_awready), .addr_o(m0_awaddr_o), .valid_o(m0_awvalid), .finish_o(m0_awfinish) );
    master #(.ADDR_WIDTH(`ADDR_WIDTH-1), .MAX_DELAY(`MAX_DELAY)) m0_w (
        .clk(clk), .rst_n(rst_n), .ready_i(m0_wready), .addr_o(m0_waddr), .valid_o(m0_wvalid), .finish_o(m0_wfinish) );
    master #(.ADDR_WIDTH(`ADDR_WIDTH-1), .MAX_DELAY(`MAX_DELAY)) m1_aw (
        .clk(clk), .rst_n(rst_n), .ready_i(m1_awready), .addr_o(m1_awaddr_o), .valid_o(m1_awvalid), .finish_o(m1_awfinish) );
    master #(.ADDR_WIDTH(`ADDR_WIDTH-1), .MAX_DELAY(`MAX_DELAY)) m1_w (
        .clk(clk), .rst_n(rst_n), .ready_i(m1_wready), .addr_o(m1_waddr), .valid_o(m1_wvalid), .finish_o(m1_wfinish) );
    
    // TODO: check requirements
    always @(posedge clk) begin

        //store previous data
        pre_awready <= mem_awready_test;
        pre_awvalid <= mem_awvalid;
        pre_wvalid <= mem_wvalid;
        pre_wready <= mem_wready_test;
        pre_w_sel <= w_select;
        pre_aw_sel <= aw_select;

        //blocking the handshake between interconnect and memory (check size of fifo)
        test3_w  <= test3_w  || m_wshake  == 8;
        test3_aw <= test3_aw || m_awshake == 8;

        // check the control changes every eight handshake
        if(pre_w_sel !== w_select) begin
            if(m_wshake !== 8) begin
                error = 10;
                down = 1;
            end else m_wshake = 0;
        end

        if(pre_aw_sel !== aw_select) begin
            if(m_awshake !== 8) begin
                error = 20;
                down = 1;
            end else m_awshake = 0;
        end

        //check if ready of both m0 and m1 are high
        if(m0_awready === 1 && m1_awready === 1) begin
            error = 83;
            down = 1;
        end

        if(m0_wready === 1 && m1_wready === 1) begin
            error = 84;
            down = 1;
        end

        //set the order
        if(m0_awready === 1 && m0_awvalid === 1) begin
            awaddr_order[aw_ptr] = m0_awaddr;
            aw_ptr = aw_ptr +1;
            m_awshake = m_awshake +1;
            `ifdef MSG
                $display("[%t] m0_aw  handshake of addr %d.", $time, m0_awaddr);
            `endif
        end 
        
        if(m0_wready === 1 && m0_wvalid === 1) begin
            wdata_order[w_ptr] = m0_wdata;
            w_ptr = w_ptr +1;
            m_wshake = m_wshake +1;
            `ifdef MSG
                $display("[%t] m0_w   handshake of data %h.", $time, m0_wdata);
            `endif
        end

        if(m1_awready === 1 && m1_awvalid === 1) begin
            awaddr_order[aw_ptr] = m1_awaddr;
            aw_ptr = aw_ptr +1;
            m_awshake = m_awshake +1;
            `ifdef MSG
                $display("[%t] m1_aw  handshake of addr %d.", $time, m1_awaddr);
            `endif
        end 
        
        if(m1_wready === 1 && m1_wvalid === 1) begin
            wdata_order[w_ptr] = m1_wdata;
            w_ptr = w_ptr +1;
            m_wshake = m_wshake +1;
            `ifdef MSG
                $display("[%t] m1_w   handshake of data %h.", $time, m1_wdata);
            `endif
        end

        //check the order
        if(mem_awready_test === 1 && mem_awvalid === 1) begin
            if(mem_awaddr !== awaddr_order[aw_received]) begin
                error = 50;
                down = 1;
            end else aw_received = aw_received+ 1;

            `ifdef MSG
                $display("[%t] mem_aw handshake of addr %d.", $time, mem_awaddr);
            `endif
        end 

        if(mem_wready_test === 1 && mem_wvalid === 1) begin
            if (mem_wdata !== wdata_order[w_received]) begin
                error = 60;
                down = 1;
            end else w_received = w_received + 1;

            `ifdef MSG
                $display("[%t] mem_w  handshake of data %h.", $time, mem_wdata);
            `endif
        end 

        //check the falling valid without handshake
        if(pre_awvalid === 1 & pre_awready === 0 & mem_awvalid === 0) begin
            error = 40;
            down = 1;
        end

        if(pre_wvalid === 1 & pre_wready === 0 & mem_wvalid === 0) begin
            error = 41;
            down = 1;
        end

        //finish
        if(aw_received == 2**`ADDR_WIDTH  && w_received == 2**`ADDR_WIDTH && ~down ) begin 
            #(`CYCLE) down = 1;
        end
    end

    initial begin
	    #(`TERMINATION * `CYCLE);
	    error = 80;
        down = 1;
    end

    initial begin
        @(posedge down);
        case(error)
            0 : begin
                $display("============================================================================");

                for (i = 0;i < ADDR ; i = i+1) begin
                    if(mem[i] !== memory_inst.mem[i]) begin
                        $display("errorOR index %0d : the master is %h, you got %h.", i, mem[i], memory_inst.mem[i]);
                        error = error+1;

                        if(error >= `MAX_error) begin
                            $display("================================================================================================================");
                            $display("(/`n`)/ ~#  There is something wrong with your code!!"); 
                            $display("The are more than %d memory errorors. Please check your code!!!!!!!!", `MAX_error); 
                            $display("================================================================================================================"); 
                            #(`CYCLE) $finish;
                        end
                    end
                end

                if(error) begin
                    $display("================================================================================================================");
                    $display("(/`n`)/ ~#  There is something wrong with your code!!"); 
                    $display("The are %d memory errorors. Please check your code!", error); 
                    $display("================================================================================================================"); 
                end else begin
                    $display("\n");
                    $display("        ****************************              ");
                    $display("        **  Congratulations !!    **    |");
                    $display("        **                        **    |");
                    $display("        **  Simulation Complete!! **    |");
                    $display("\n");
                    $display("============================================================================");
                end
            end

            10 : begin
                $display("================================================================================================================");
                $display("(/`n`)/ ~#  There is something wrong with your code!!"); 
                $display("The control of wdata changes to master%0d while doing %0d handshake at %t.", w_select, m_wshake, $time); 
                $display("erroror code : %d.", error); 
                $display("================================================================================================================");
            end

            20 : begin
                $display("================================================================================================================");
                $display("(/`n`)/ ~#  There is something wrong with your code!!"); 
                $display("The control of awaddr changes to master%0d while doing %0d handshake at %t.", aw_select, m_awshake, $time); 
                $display("erroror code : %d.", error); 
                $display("================================================================================================================");
            end

            40 : begin
                $display("================================================================================================================");
                $display("(/`n`)/ ~#  There is something wrong with your code!!"); 
                $display("The mem_awvalid falls before the ready rise at %t.", $time); 
                $display("erroror code : %d.", error); 
                $display("================================================================================================================");
            end

            41 : begin
                $display("================================================================================================================");
                $display("(/`n`)/ ~#  There is something wrong with your code!!"); 
                $display("The mem_wvalid falls before the readt rise at %t.", $time); 
                $display("erroror code : %d.", error); 
                $display("================================================================================================================");
            end

            50 : begin
                $display("================================================================================================================");
                $display("(/`n`)/ ~#  There is something wrong with your code!!"); 
                $display("The %0dth of awaddr is wrong at %t. Correct : %0d, you got : %d.",aw_received, $time, awaddr_order[aw_received], mem_awaddr);
                $display("erroror code : %d.", error);  
                $display("================================================================================================================");
            end

            60 : begin
                $display("================================================================================================================");
                $display("(/`n`)/ ~#  There is something wrong with your code!!"); 
                $display("The %0dth of wdata is wrong at %t. Correct : %0h, you got : %h.",w_received, $time, wdata_order[w_received], mem_wdata); 
                $display("erroror code : %d.", error); 
                $display("================================================================================================================");
            end

            80 : begin
                $display("================================================================================================================");
                $display("(/`n`)/ ~#  There is something wrong with your code!!"); 
                $display("Time out!! The simulation didn't finish after %0d cycles!!, Please check it!!!", `TERMINATION); 
                if(~test3_w)$display("[INFO] It might result in the WFIFO can't afford 8 data whitout the handshake between memory.");
                if(~test3_aw)$display("[INFO] It might result in the AWFIFO can't afford 8 addr whitout the handshake between memory.");
                $display("================================================================================================================");
            end

            81 : begin
                $display("================================================================================================================");
                $display("(/`n`)/ ~#  There is something wrong with your code!!"); 
                $display("The master0 must get the control of wdata first, but master%d gets it!!", w_select); 
                $display("erroror code : %d.", error); 
                $display("================================================================================================================");
            end

            82 : begin
                $display("================================================================================================================");
                $display("(/`n`)/ ~#  There is something wrong with your code!!"); 
                $display("The master0 must get the control of awaddr first, but master%d gets it!!", aw_select);
                $display("erroror code : %d.", error);  
                $display("================================================================================================================");
            end

            83 : begin
                $display("================================================================================================================");
                $display("(/`n`)/ ~#  There is something wrong with your code!!"); 
                $display("m0_awready and m1_awready are both higt at %t.", $time); 
                $display("erroror code : %d.", error); 
                $display("================================================================================================================");
            end

            84 : begin
                $display("================================================================================================================");
                $display("(/`n`)/ ~#  There is something wrong with your code!!"); 
                $display("m0_wready and m1_wready are both higt at %t.", $time); 
                $display("erroror code : %d.", error); 
                $display("================================================================================================================");
            end

            default : begin
                $display("================================================================================================================");
                $display("(/`n`)/ ~#  There is something wrong with your code!!"); 
                $display("erroror code : %d.", error); 
                $display("================================================================================================================");
            end
        endcase

        # `CYCLE $finish;
    end
endmodule

module master # (parameter ADDR_WIDTH = 15, parameter MAX_DELAY = 4) (
    input clk, rst_n,

    input ready_i,
    output [ADDR_WIDTH-1 : 0] addr_o,
    output reg valid_o,
    output reg finish_o
);

integer delay;
reg random_ready;
reg [ADDR_WIDTH-1 : 0] counter;

assign addr_o = { ~counter[ADDR_WIDTH*2/3-1 : ADDR_WIDTH/3], counter[ADDR_WIDTH/3-1 : 0], counter[ADDR_WIDTH-1 : ADDR_WIDTH*2/3]};

initial forever begin
    delay = $random % MAX_DELAY;
    repeat(delay) begin
        @ (posedge clk);
        random_ready = 0;
    end

    @ (posedge clk);
    random_ready = 1;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        counter <= 0;
        valid_o <= 0;
        finish_o <= 0;
    end else begin
        counter <= (ready_i & valid_o & ~finish_o) ? counter +1 : counter;
        valid_o <= valid_o ? ~ready_i : random_ready & ~finish_o;
        finish_o <= finish_o | ( (ready_i & valid_o) && counter == (2**ADDR_WIDTH) -1);
    end
end
endmodule