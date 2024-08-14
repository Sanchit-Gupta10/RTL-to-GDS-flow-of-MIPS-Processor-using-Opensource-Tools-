//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.06.2023 00:35:17
// Design Name: 
// Module Name: mips_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mips_top(clk,rst_n,pc_out,alu_result);

//--------------------------------------------PORT DECLARATIONS------------------------------------------//
input clk,rst_n;
output [15:0]pc_out,alu_result;

//--------------------------------------------INTERMEDIATE SIGNAL DECLARATIONS------------------------------------------//
reg [15:0]pc_current;
wire signed [15:0]pc_2,pc_next;
wire [15:0]instruction;
wire [14:0]jump_shift_1;
wire [1:0]reg_dest,mem_to_reg,alu_op;
wire jump,branch,mem_rd,mem_wr,alu_src,reg_wr,sign_or_zero;
wire [15:0]reg_wr_data,reg_rd_data1,reg_rd_data2;
wire [2:0]reg_wr_dest;
wire [2:0]alu_ctrl;
wire zero_flag,carry_flag;
wire [15:0]src_op2,res;
wire [15:0]rd_data;
wire [15:0]zero_ext_imm,sign_ext_imm;
wire jr_ctrl;
wire [15:0]imm_ext,no_sign_ext;
wire signed[15:0]im_shift_1,PC_j,PC_beq,PC_4beq,PC_4beqj,PC_jr;
wire beq_control;

//--------------------------------------------PROGRAM COUNTER LOGIC------------------------------------------//
always@(posedge clk or negedge rst_n)
    begin
        if(!rst_n) pc_current <= 16'd0;
        else pc_current <= pc_next;
    end
    
assign pc_2 = pc_current + 16'd2;

//--------------------------------------------INSTRUCTION MEMORY INSTANTIATION------------------------------------------//    
instruction_memory inst1(pc_current,instruction);

assign jump_shift_1 = {instruction[13:0],1'b0};

//--------------------------------------------CONTROL UNIT INSTANTIATION------------------------------------------// 
control_unit inst2(instruction[15:13],reg_dest,mem_to_reg,alu_op,jump,branch,mem_rd,mem_wr,alu_src,reg_wr,sign_or_zero);

assign reg_wr_dest = (reg_dest[1]) ? 3'b111 : ( reg_dest[0] ? instruction[6:4] : instruction[9:7]);

//--------------------------------------------REGISTER FILE INSTANTIATION------------------------------------------// 
register_file inst3(clk,rst_n,reg_wr,reg_wr_dest,reg_wr_data,instruction[12:10],reg_rd_data1,instruction[9:7],reg_rd_data2);

//--------------------------------------------ALU CONTROL UNIT INSTANTIATION------------------------------------------//
alu_control_unit inst4(alu_op,instruction[2:0],alu_ctrl);

assign zero_ext_imm = {{9{1'b0}},instruction[6:0]};
assign sign_ext_imm = {{9{instruction[6]}},instruction[6:0]};
assign imm_ext = (sign_or_zero) ? sign_ext_imm : zero_ext_imm;

assign jr_ctrl = ((alu_op==2'b00) && (instruction[3:0]==4'b1000)) ? 1'b1 : 1'b0;

assign src_op2 = (alu_src) ? imm_ext : reg_rd_data2;

//--------------------------------------------ALU DATAPATH UNIT INSTANTIATION------------------------------------------//
alu_datapath_unit inst5(reg_rd_data1,src_op2,res,zero_flag,carry_flag,alu_ctrl);

assign im_shift_1 = {imm_ext[14:0],1'b0};
assign no_sign_ext = ~(im_shift_1) + 1'b1;
assign PC_beq = (im_shift_1[15] == 1'b1) ? (pc_2 - no_sign_ext): (pc_2 +im_shift_1);
assign beq_control = branch & zero_flag; 
assign PC_4beq = (beq_control) ? PC_beq : pc_2;
assign PC_j = {pc_2[15],jump_shift_1};
assign PC_4beqj = jump ? PC_j : PC_4beq;
assign PC_jr = reg_rd_data1;
assign pc_next = jr_ctrl ? PC_jr : PC_4beqj;

//--------------------------------------------DATA MEMORY INSTANTIATION------------------------------------------//
data_memory inst6(clk,rst_n,res,rd_data,reg_rd_data2,mem_rd,mem_wr);

assign reg_wr_data = (mem_to_reg[1]) ? pc_2 : ( mem_to_reg[0] ? rd_data : res);

assign pc_out = pc_current;
assign alu_result = res;
endmodule

module instruction_memory(pc,instruction);
//--------------------------------------------PORT DECLARATIONS------------------------------------------//
input [15:0]pc;
output [15:0]instruction;

//--------------------------------------------INTERMEDIATE SIGNAL DECLARATIONS------------------------------------------//
reg [15:0]instr_mem[0:(1<<16)];

//--------------------------------------------INSTRUCTION MEMORY ENCODING------------------------------------------//
initial  
      begin  
                instr_mem[0]  = 16'b1000000110000000;  
                instr_mem[1]  = 16'b0010110010110010;  
                instr_mem[2]  = 16'b1101110001100111;  
                instr_mem[3]  = 16'b1101110111011001;  
                instr_mem[4]  = 16'b1111110110110001;  
                instr_mem[5]  = 16'b1100000001111011; 
                instr_mem[6]  = 16'b0000000000000000;  
                instr_mem[7]  = 16'b0000000000000000;  
                instr_mem[8]  = 16'b0000000000000000;  
                instr_mem[9]  = 16'b0000000000000000;  
                instr_mem[10] = 16'b0000000000000000;  
                instr_mem[11] = 16'b0000000000000000;  
                instr_mem[12] = 16'b0000000000000000;  
                instr_mem[13] = 16'b0000000000000000;  
                instr_mem[14] = 16'b0000000000000000;  
                instr_mem[15] = 16'b0000000000000000;  
      end 
      
assign instruction = (pc < 16) ? instr_mem[pc] : 16'd0;       
endmodule

module data_memory(clk,rst_n,mem_addr,rd_data,wr_data,rd_en,wr_en);
//-----------------------------------PORT DECLARATIONS-----------------------------------//
input clk,rst_n;
input [15:0]mem_addr;
input [15:0]wr_data;
input wr_en,rd_en;
output [15:0]rd_data;

//---------------------------INTERMEDIATE SIGNAL DECLARATIONS----------------------------//
reg [15:0]data_mem[0:1023];
integer i;

//---------------------------WRITING INTO DATA MEMORY----------------------------//
always@(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            begin
                for(i=0;i<1024;i=i+1)
                    data_mem[i] <= 16'd0;
            end
        else if(wr_en) data_mem[mem_addr] <= wr_data;
    end

//---------------------------READING FROM DATA MEMORY----------------------------// 
assign rd_data = (rd_en) ? data_mem[mem_addr] : 16'd0;
endmodule

module register_file(clk,rst_n,reg_wr_en,reg_wr_dest,reg_wr_data,reg_rd_addr1,reg_rd_data1,reg_rd_addr2,reg_rd_data2);
//--------------------------------------------PORT DECLARATIONS------------------------------------------//
input clk,rst_n;
input reg_wr_en;
input [2:0]reg_wr_dest,reg_rd_addr1,reg_rd_addr2;
input [15:0]reg_wr_data;
output [15:0]reg_rd_data1,reg_rd_data2;

//-----------------------------------INTERMEDIATE SIGNAL DECLARATIONS-----------------------------------//
reg [15:0]reg_file[0:7];
integer i;

//-------------------------------------REGISTER FILE IMPLEMENTATION-------------------------------------//
always@(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            begin
                for(i=0;i<8;i=i+1)
                    reg_file[i] <= 16'd5;
            end
         else if(reg_wr_en) reg_file[reg_wr_dest] <= reg_wr_data;
    end
    
assign reg_rd_data1 = reg_file[reg_rd_addr1];
assign reg_rd_data2 = reg_file[reg_rd_addr2];
    
endmodule

module alu_control_unit(alu_op,alu_funct,alu_ctrl);
//-----------------------------------PORT DECLARATIONS-----------------------------------//
input [1:0]alu_op;
input [2:0]alu_funct;
output reg [2:0]alu_ctrl;

//-----------------------------------CONTROL SIGNALS GENERATION-----------------------------------//
always@(*)
    begin
        case(alu_op)
            2'b00: alu_ctrl <= alu_funct;
            2'b01: alu_ctrl <= 3'b001;
            2'b10: alu_ctrl <= 3'b100;
            2'b11: alu_ctrl <= 3'b000;
            default: alu_ctrl <= 3'b000;
        endcase
    end
endmodule

module alu_datapath_unit(src_op1,src_op2,res,zero_flag,carry_flag,alu_ctrl);
//-----------------------------------PORT DECLARATIONS-----------------------------------//
input [15:0]src_op1,src_op2;
input [2:0]alu_ctrl;
output reg carry_flag;
output zero_flag;
output reg [15:0]res;

//-----------------------------------ARITHMETIC AND LOGIC UNIT-----------------------------------//
always@(*)
    begin
        case(alu_ctrl)
            3'b000: {carry_flag,res} = src_op1 + src_op2;
            3'b001: {carry_flag,res} = src_op1 - src_op2;
            3'b010: res = src_op1 & src_op2;
            3'b011: res = src_op1 | src_op2;
            3'b100: if(src_op1 < src_op2) res = 16'd1; else res = 16'd0;
            default: ;
        endcase
     end
     
assign zero_flag = (res==16'd0) ? 1'b1 : 1'b0;
endmodule

module control_unit(opcode,reg_dest,mem_to_reg,alu_op,jump,branch,mem_rd,mem_wr,alu_src,reg_wr,sign_or_zero);
//--------------------------------------------PORT DECLARATIONS------------------------------------------//
input [2:0]opcode;
output reg [1:0]reg_dest,mem_to_reg,alu_op;
output reg jump,branch,mem_rd,mem_wr,alu_src,reg_wr,sign_or_zero;

//--------------------------------------------CONTROL SIGNALS GENERATION------------------------------------------//
always@(*)
    begin
        case(opcode)
            3'b000: begin
                        reg_dest = 2'b01;
                        mem_to_reg = 2'b00;
                        alu_op = 2'b00;
                        jump = 1'b0;
                        branch = 1'b0;
                        mem_rd = 1'b0;
                        mem_wr = 1'b0;
                        alu_src = 1'b0;
                        reg_wr = 1'b1;
                        sign_or_zero = 1'b1;
                     end
             3'b001: begin
                        reg_dest = 2'b00;
                        mem_to_reg = 2'b00;
                        alu_op = 2'b10;
                        jump = 1'b0;
                        branch = 1'b0;
                        mem_rd = 1'b0;
                        mem_wr = 1'b0;
                        alu_src = 1'b1;
                        reg_wr = 1'b1;
                        sign_or_zero = 1'b0;
                     end
            3'b010: begin
                        reg_dest = 2'b00;
                        mem_to_reg = 2'b00;
                        alu_op = 2'b00;
                        jump = 1'b1;
                        branch = 1'b0;
                        mem_rd = 1'b0;
                        mem_wr = 1'b0;
                        alu_src = 1'b0;
                        reg_wr = 1'b0;
                        sign_or_zero = 1'b1;
                     end
            3'b011: begin
                        reg_dest = 2'b10;
                        mem_to_reg = 2'b10;
                        alu_op = 2'b00;
                        jump = 1'b1;
                        branch = 1'b0;
                        mem_rd = 1'b0;
                        mem_wr = 1'b0;
                        alu_src = 1'b0;
                        reg_wr = 1'b1;
                        sign_or_zero = 1'b1;
                     end
            3'b100: begin
                        reg_dest = 2'b00;
                        mem_to_reg = 2'b01;
                        alu_op = 2'b11;
                        jump = 1'b0;
                        branch = 1'b0;
                        mem_rd = 1'b1;
                        mem_wr = 1'b0;
                        alu_src = 1'b1;
                        reg_wr = 1'b1;
                        sign_or_zero = 1'b1;
                     end
             3'b101: begin
                        reg_dest = 2'b00;
                        mem_to_reg = 2'b00;
                        alu_op = 2'b11;
                        jump = 1'b0;
                        branch = 1'b0;
                        mem_rd = 1'b0;
                        mem_wr = 1'b1;
                        alu_src = 1'b1;
                        reg_wr = 1'b0;
                        sign_or_zero = 1'b1;
                     end
             3'b110: begin
                        reg_dest = 2'b00;
                        mem_to_reg = 2'b00;
                        alu_op = 2'b01;
                        jump = 1'b0;
                        branch = 1'b1;
                        mem_rd = 1'b0;
                        mem_wr = 1'b0;
                        alu_src = 1'b0;
                        reg_wr = 1'b0;
                        sign_or_zero = 1'b1;
                     end
             3'b111: begin
                        reg_dest = 2'b00;
                        mem_to_reg = 2'b00;
                        alu_op = 2'b11;
                        jump = 1'b0;
                        branch = 1'b0;
                        mem_rd = 1'b0;
                        mem_wr = 1'b0;
                        alu_src = 1'b1;
                        reg_wr = 1'b1;
                        sign_or_zero = 1'b1;
                     end
            default: begin
                        reg_dest = 2'b00;
                        mem_to_reg = 2'b00;
                        alu_op = 2'b00;
                        jump = 1'b0;
                        branch = 1'b0;
                        mem_rd = 1'b0;
                        mem_wr = 1'b0;
                        alu_src = 1'b0;
                        reg_wr = 1'b0;
                        sign_or_zero = 1'b1;
                     end
       endcase                                                                                                                                                                       
    end
endmodule

