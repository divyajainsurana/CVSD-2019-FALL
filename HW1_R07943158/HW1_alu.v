module alu(
             clk_p_i,
             reset_n_i,
             data_a_i,
             data_b_i,
             inst_i,
             data_o,
             overflow_o
             );
  /* ============================================ */
      input           clk_p_i;
      input           reset_n_i;
      input   [7:0]   data_a_i;
      input   [7:0]   data_b_i;
      input   [2:0]   inst_i;

      output reg  [7:0]  data_o;
      output reg         overflow_o;

      reg signed [15:0]  ALU_d2_w;
      reg [7:0]   data_a_d1_r;
      reg [7:0]   data_b_d1_r;
      reg [2:0]   inst_d1_r;
      reg         overflow_d2_w;
      reg signed    [15:0]   data_a_signed_d1_r;
      reg signed    [15:0]   data_b_signed_d1_r;
      wire [7:0] temp_a;
      wire [7:0] temp_b;
  /* ============================================ */
	
      always@ (*)
      begin
          case(inst_d1_r)
            3'b000:    ALU_d2_w =  data_a_signed_d1_r+ data_b_signed_d1_r;
            3'b001:    ALU_d2_w =  data_b_signed_d1_r -  data_a_signed_d1_r;
            3'b010:    ALU_d2_w =  data_a_signed_d1_r * data_b_signed_d1_r;
            3'b011:    ALU_d2_w =  data_a_d1_r & data_b_d1_r;
            3'b100:    ALU_d2_w =  data_a_d1_r ^ data_b_d1_r;
            3'b101:    ALU_d2_w =  (data_a_d1_r[7]) ? (~data_a_signed_d1_r+1) : (data_a_signed_d1_r);
            3'b110:    ALU_d2_w =  (data_a_signed_d1_r+ data_b_signed_d1_r) >>> 1;
            3'b111:    ALU_d2_w = (data_a_signed_d1_r > data_b_signed_d1_r)? data_a_signed_d1_r : data_b_signed_d1_r;
            default:   ALU_d2_w = 0;
          endcase
      end
      
      always@ (*)
      begin
	case(inst_d1_r)
	3'b000:
	if ((ALU_d2_w>127 || ALU_d2_w<-128))
		overflow_d2_w =1;
	else 
		overflow_d2_w = 0;
	3'b001:
	if ((ALU_d2_w>127 || ALU_d2_w < -128))
		overflow_d2_w =1;
	else
		overflow_d2_w =0;
	3'b010:
        if ((ALU_d2_w>127 || ALU_d2_w<-128))
            overflow_d2_w = 1;
	else
	    overflow_d2_w = 0;
	default:
	   overflow_d2_w =0;
	endcase
      end

  /* ============================================ */
      always@(posedge clk_p_i or negedge reset_n_i)
      begin
          if (reset_n_i == 1'b0)
          begin

            data_o <= 0;
            overflow_o <= 0;
          end
          else
          begin
            inst_d1_r <= inst_i;
            data_a_d1_r <= data_a_i;
            data_b_d1_r <= data_b_i;
            data_o <= ALU_d2_w[7:0];
            overflow_o <= overflow_d2_w;
            data_a_signed_d1_r <= { {8{data_a_i[7]}}, data_a_i };
            data_b_signed_d1_r <= { {8{data_b_i[7]}}, data_b_i };
          end
      end
  /* ============================================ */

endmodule

