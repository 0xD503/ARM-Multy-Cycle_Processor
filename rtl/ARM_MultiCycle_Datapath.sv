module ARM_MultiCycle_Datapath
	#(parameter	BusWidth	= 32)
	(input logic			i_CLK, i_NRESET,

	//	PC control
	input logic				i_PC_Write,

	//	Memory control);
	output logic[(BusWidth - 1):0]	o_Address,

	input logic						i_AddressSrc,

	output logic[(BusWidth - 1):0]	o_WriteData,
	input logic[(BusWidth - 1):0]	i_Read_InstructionData,

	//	Instruction Cycle control
	input logic						i_InstructionWrite,
	output logic[(BusWidth - 1):0]	o_Instr,

	//	Register Sources selector
	input logic[1:0]		i_RegSrc,

	//	Register File control
	input logic				i_RegWrite,

	//	Extension Unit selector control
	input logic[1:0]		i_ImmediateSrc,

	//	ALU Sources selector
	input logic				i_ALU_Src_A,
	input logic[1:0]		i_ALU_Src_B,

	//	ALU control
	input logic[1:0]				i_ALU_Control,
	output logic[3:0]				o_ALU_Flags,
	//output logic[(BusWidth - 1):0]	o_ALU_Result,

	//	Result control
	input logic[1:0]		i_ResultSrc);

	//	PC control
	logic[(BusWidth - 1):0]	s_PC_In, s_PC_Out;
	logic[(BusWidth - 1):0]	s_AddrSrc_0, s_AddrSrc_1;
	logic[(BusWidth - 1):0]	s_Address_Out;
	//logic[(BusWidth - 1):0]	s_Address_In;

	//	Memory pins
	//logic[(BusWidth - 1):0]	s_WriteData, s_ReadData;

	//	Memory register pins
	logic[(BusWidth - 1):0]	s_Instruction_In, s_Instruction_Out;
	logic[(BusWidth - 1):0]	s_Data_In, s_Data_Out;

	//	Register File pins
	logic[3:0]				s_RegAddr_To_Read_Src_1, s_RegAddr_To_Read_Src_2;
	logic[3:0]				s_RegAddr_To_Write;
	logic[(BusWidth - 1):0]	s_RegFile_WriteData;
	logic[(BusWidth - 1):0]	s_R15;
	logic[(BusWidth - 1):0]	RegData_Out_1, RegData_Out_2;

	//	Extension
	logic[(BusWidth - 1):0]	s_ExtendedData;

	//	Register File's register pins
	logic[(BusWidth - 1):0]	s_RegData_Reg_In_1, s_RegData_Reg_In_2;
	logic[(BusWidth - 1):0]	s_RegData_Reg_Out_1, s_RegData_Reg_Out_2;

	//	ALU Muxes pins
	logic[(BusWidth - 1):0]	s_ALU_Src_A_Mux_0, s_ALU_Src_A_Mux_1;
	logic[(BusWidth - 1):0]	s_ALU_Src_B_Mux_0, s_ALU_Src_B_Mux_1, s_ALU_Src_B_Mux_2;
	logic[(BusWidth - 1):0]	s_ALU_Src_A, s_ALU_Src_B;

	//	ALU pins
	//	ALU Inputs -> Outputs
	logic[(BusWidth - 1):0]	s_ALU_Src_1, s_ALU_Src_2;
	logic[(BusWidth - 1):0]	s_ALU_Result;
	logic[3:0]				s_ALU_Flags;

	//	ALU register pins
	logic[(BusWidth - 1):0]	s_ALU_Result_Reg_In, s_ALU_Result_Reg_Out;

	//	Result Mux input pins
	logic[(BusWidth - 1):0] s_Result_Src_0, s_Result_Src_1, s_Result_Src_2;

	//	Result Bus
	logic[(BusWidth - 1):0] s_Result;


	//	PC Input
	assign s_PC_In = s_Result;

	//	
	ARM_MultiCycle_ProgramCounter	PC
		(i_CLK, i_NRESET,
		i_PC_Write,
		s_PC_In,
		s_PC_Out);

	//	Memory control inputs
	assign s_AddrSrc_0 = s_PC_Out;
	assign s_AddrSrc_1 = s_Result;

	//	
	ARM_Mux_2x1						AddressMux
		(s_AddrSrc_0, s_AddrSrc_1,
		i_AddressSrc,
		s_Address_Out);

/*
	//	
	ARM_MultiCycle_Memory			GeneralMemory
		(i_CLK, i_NRESET,
		i_MemWrite,
		s_Address_In,
		s_WriteData,
		s_ReadData);
*/
	//	Instruction and Data Registers inputs
	assign s_Instruction_In = i_Read_InstructionData;
	assign s_Data_In = i_Read_InstructionData;
	//	Instruction register
	ARM_MultiCycle_Register			IntructionRegister
		(i_CLK, i_NRESET,
		i_InstructionWrite,
		s_Instruction_In,
		s_Instruction_Out);

	//	Data register
	ARM_MultiCycle_Register_NE		DataRegister
		(i_CLK, i_NRESET,
		s_Data_In,
		s_Data_Out);

	//	
	ARM_4_bit_Mux_2x1				Register_Src_1_Mux
		(s_Instruction_Out[19:16], 4'hF,
		i_RegSrc[0],
		s_RegAddr_To_Read_Src_1);

	//	
	ARM_4_bit_Mux_2x1				Register_Src_2_Mux
		(s_Instruction_Out[3:0], s_Instruction_Out[15:12],
		i_RegSrc[1],
		s_RegAddr_To_Read_Src_2);

	//	Register File inputs
	assign s_RegAddr_To_Write = s_Instruction_Out[15:12];
	assign s_RegFile_WriteData = s_Result;
	assign s_R15 = s_Result;
	//	
	ARM_MultiCycle_RegisterFile		RegisterFile
		(i_CLK, i_NRESET,
		i_RegWrite,
		s_RegAddr_To_Read_Src_1, s_RegAddr_To_Read_Src_2,
		s_RegAddr_To_Write,
		s_RegFile_WriteData,
		s_R15,
		RegData_Out_1, RegData_Out_2);

	//	
	ARM_MultiCycle_ExtensionUnit	ExtensionUnit
		(s_Instruction_Out[23:0],
		i_ImmediateSrc,
		s_ExtendedData);


	//	Register File registers
	assign s_RegData_Reg_In_1 = RegData_Out_1;
	assign s_RegData_Reg_In_2 = RegData_Out_2;
	//	
	ARM_MultiCycle_Register_NE		RegData_Reg_1
		(i_CLK, i_NRESET,
		s_RegData_Reg_In_1,
		s_RegData_Reg_Out_1);

	//	
	ARM_MultiCycle_Register_NE		RegData_Reg_2
		(i_CLK, i_NRESET,
		s_RegData_Reg_In_2,
		s_RegData_Reg_Out_2);


	//	ALU Source Muxes
	assign s_ALU_Src_A_Mux_0 = s_RegData_Reg_Out_1;
	assign s_ALU_Src_A_Mux_1 = s_PC_Out;

	assign s_ALU_Src_B_Mux_0 = s_RegData_Reg_Out_2;
	assign s_ALU_Src_B_Mux_1 = s_ExtendedData;
	assign s_ALU_Src_B_Mux_2 = 32'd4;
	//	
	ARM_Mux_2x1						ALU_Src_A_Mux
		(s_ALU_Src_A_Mux_0, s_ALU_Src_A_Mux_1,
		i_ALU_Src_A,
		s_ALU_Src_A);

	//	
	ARM_Mux_4x1						ALU_Src_B_Mux
		(s_ALU_Src_B_Mux_0, s_ALU_Src_B_Mux_1, s_ALU_Src_B_Mux_2, 32'd0,
		i_ALU_Src_B,
		s_ALU_Src_B);

	//	ALU Inputs -> Outputs
	assign s_ALU_Src_1 = s_ALU_Src_A;
	assign s_ALU_Src_2 = s_ALU_Src_B;
	//	
	ARM_ALU							ALU
		(s_ALU_Src_1, s_ALU_Src_2,
		i_ALU_Control,
		s_ALU_Result,
		s_ALU_Flags);

	//	ALU Register
	assign s_ALU_Result_Reg_In = s_ALU_Result;
	//	
	ARM_MultiCycle_Register_NE		ALU_Out_Reg
		(i_CLK, i_NRESET,
		s_ALU_Result_Reg_In,
		s_ALU_Result_Reg_Out);

	//	Result Mux
	assign s_Result_Src_0 = s_ALU_Result_Reg_Out;
	assign s_Result_Src_1 = s_Data_Out;
	assign s_Result_Src_2 = s_ALU_Result;
	//	
	ARM_Mux_4x1						Result_Mux
		(s_Result_Src_0, s_Result_Src_1, s_Result_Src_2, 32'd0,
		i_ResultSrc,
		s_Result);


	//	Output logic
	assign o_Address = s_Address_Out;
	assign	o_WriteData = s_RegData_Reg_Out_2;
	assign o_Instr = s_Instruction_Out;			//	Instruction out for control unit
	assign o_ALU_Flags = s_ALU_Flags;

endmodule



module ARM_MultiCycle_ProgramCounter
	#(parameter	BusWidth	= 32)
	(input logic					i_CLK, i_NRESET,
	input logic						i_ENABLE,
	input logic[(BusWidth - 1):0]	i_Address,
	output logic[(BusWidth - 1):0]	o_Address);


	always_ff	@(posedge i_CLK, negedge i_NRESET)
	begin
		if (~i_NRESET)				o_Address <= 32'd0;
		else if (i_ENABLE)			o_Address <= i_Address;
	end

endmodule

module ARM_MultiCycle_Register
	#(parameter	BusWidth	= 32)
	(input logic					i_CLK, i_NRESET,
	input logic						i_ENABLE,
	input logic[(BusWidth - 1):0]	i_Input,
	output logic[(BusWidth - 1):0]	o_Output);


	always_ff	@(posedge i_CLK, negedge i_NRESET)
	begin
		if (~i_NRESET)				o_Output <= 32'd0;
		else if (i_ENABLE)			o_Output <= i_Input;
	end

endmodule

module ARM_MultiCycle_Register_NE
	#(parameter	BusWidth	= 32)
	(input logic					i_CLK, i_NRESET,
	input logic[(BusWidth - 1):0]	i_Input,
	output logic[(BusWidth - 1):0]	o_Output);


	always_ff	@(posedge i_CLK, negedge i_NRESET)
	begin
		if (~i_NRESET)				o_Output <= 32'd0;
		else 						o_Output <= i_Input;
	end

endmodule

module ARM_Mux_2x1
	#(parameter	BusWidth	= 32)
	(input logic[(BusWidth - 1):0]	i_Input_0, i_Input_1,
	input logic						i_Select,
	output logic[(BusWidth - 1):0]	o_Output);


	assign o_Output = i_Select ?	i_Input_1 : i_Input_0;

endmodule

module ARM_4_bit_Mux_2x1
	#(parameter	BusWidth	= 4)
	(input logic[(BusWidth - 1):0]	i_Input_0, i_Input_1,
	input logic						i_Select,
	output logic[(BusWidth - 1):0]	o_Output);


	assign o_Output = i_Select ?	i_Input_1 : i_Input_0;

endmodule

module ARM_MultiCycle_RegisterFile
	#(parameter	BusWidth			= 32,
				RegAddrWidth		= 4,
				RegisterFileSize	= 15)
	(input logic						i_CLK, i_NRESET,
	input logic							i_WriteEnable,
	
	input logic[(RegAddrWidth - 1):0]	i_RegAddr_ToRead_1, i_RegAddr_ToRead_2,
	input logic[(RegAddrWidth - 1):0]	i_RegAddr_ToWrite,
	
	input logic[(BusWidth - 1):0]		i_WriteData,

	input logic[(BusWidth - 1):0]		i_R15,
	
	output logic[(BusWidth - 1):0]		o_RegData_1, o_RegData_2);

	logic[(BusWidth - 1):0]			Register[(RegisterFileSize - 1):0];


	//	Register logic
	always_ff	@(posedge i_CLK, negedge i_NRESET)
	begin
		if (~i_NRESET)
		begin
			int i;
			for (i = 0; i < RegisterFileSize; i = i + 1)	Register[i] = 32'd0;
		end
		else if (i_WriteEnable)
		begin
			Register[i_RegAddr_ToWrite] = i_WriteData;
		end
	end
	
	//	Combinational
	assign o_RegData_1 = (i_RegAddr_ToRead_1 == 4'hF) ?	i_R15 : Register[i_RegAddr_ToRead_1];
	assign o_RegData_2 = (i_RegAddr_ToRead_2 == 4'hF) ?	i_R15 : Register[i_RegAddr_ToRead_2];

endmodule

module ARM_MultiCycle_ExtensionUnit
	#(parameter	ImmediateBusWidth	= 24,
					ExtendedBusWidth	= 32)
	(input logic[(ImmediateBusWidth - 1):0]	i_Immediate,
	input logic[1:0]						i_ImmediateSelect,
	output logic[(ExtendedBusWidth - 1):0]	o_Extension);


	always_comb
	begin
		case (i_ImmediateSelect)
			2'b00:		o_Extension = {16'd0, i_Immediate[7:0]};
			2'b01:		o_Extension = {12'd0, i_Immediate[11:0]};
			2'b10:		o_Extension = i_Immediate;
			
			default:	o_Extension = 32'd0;
		endcase
	end

endmodule

module	ARM_ALU
	#(parameter	BusWidth	= 32)
	(input logic[(BusWidth - 1):0]	i_ALU_Src1, i_ALU_Src2,
	input logic[1:0]				i_ALU_Control,
	output logic[(BusWidth - 1):0]	o_ALU_Result,
	output logic[3:0]				o_ALU_Flags);

	logic[(BusWidth - 1):0]			s_ALU_Result;
	logic							s_Flag_Negative, s_Flag_Zero;
	logic							s_Flag_Carry, s_Flag_Overflow;

	typedef enum logic[1:0] {ADD, SUB, AND, ORR}	ALU_Operation;


	//	Result logic
	always_comb
	begin
		case (i_ALU_Control[1:0])
			ADD:	s_ALU_Result <= i_ALU_Src1 + i_ALU_Src2;
			SUB:	s_ALU_Result <= i_ALU_Src1 - i_ALU_Src2;
			AND:	s_ALU_Result <= i_ALU_Src1 & i_ALU_Src2;
			ORR:	s_ALU_Result <= i_ALU_Src1 | i_ALU_Src2;
			
			default:	s_ALU_Result = 32'b0;
		endcase
	end

	//	Flags logic
	always_comb
	begin
		s_Flag_Negative = (s_ALU_Result[BusWidth - 1] == 1'b1) ?	1'b1 : 1'b0;
		s_Flag_Zero = (s_ALU_Result == 0) ?							1'b1 : 1'b0;
		case (i_ALU_Control[1:0])
			ADD:
			begin
				s_Flag_Carry = (i_ALU_Src1 >= i_ALU_Src2) ?					1'b1 : 1'b0;
				s_Flag_Overflow =	((~i_ALU_Src1[BusWidth - 1] & ~i_ALU_Src2[BusWidth - 1] & s_ALU_Result[BusWidth - 1]) |
									(i_ALU_Src1[BusWidth - 1] & i_ALU_Src2[BusWidth - 1] & ~s_ALU_Result[BusWidth - 1]));
			end
			SUB:
			begin
				s_Flag_Carry = (i_ALU_Src1 < i_ALU_Src2) ?					1'b1 : 1'b0;
				s_Flag_Overflow =	((i_ALU_Src1[BusWidth - 1] & ~i_ALU_Src2[BusWidth - 1] & s_ALU_Result[BusWidth - 1]) |
									(~i_ALU_Src1[BusWidth - 1] & i_ALU_Src2[BusWidth - 1] & s_ALU_Result[BusWidth - 1]));
			end
			
			default:
			begin
				s_Flag_Carry = 1'bx;
				s_Flag_Overflow = 1'bx;
			end
		endcase
	end

	assign o_ALU_Result =	s_ALU_Result;
	assign o_ALU_Flags =	{s_Flag_Negative, s_Flag_Zero,
							s_Flag_Carry, s_Flag_Overflow};

endmodule

module ARM_Mux_4x1
	#(parameter	BusWidth	= 32)
	(input logic[(BusWidth - 1):0]	i_Input_0, i_Input_1, i_Input_2, i_Input_3,
	input logic[1:0]				i_Select,
	output logic[(BusWidth - 1):0]	o_Output);


	always_comb
	begin
		case (i_Select)
			2'b00:		o_Output = i_Input_0;
			2'b01:		o_Output = i_Input_1;
			2'b10:		o_Output = i_Input_2;
			2'b11:		o_Output = i_Input_3;

			default:	o_Output = i_Input_0;
		endcase
	end

endmodule
