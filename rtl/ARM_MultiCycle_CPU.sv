module ARM_MultiCycle_CPU
	#(parameter	BusWidth	= 32)
	(input logic					i_CLK, i_NRESET,

	//	Common Memory control
	output logic					o_MemWrite,

	output logic[(BusWidth - 1):0]	o_Address,
	output logic[(BusWidth - 1):0]	o_WriteData,
	input logic[(BusWidth - 1):0]	i_ReadData);


	//	Controller pins
	logic		s_PC_Write, s_AddrSrc, s_MemW, s_IR_Write, s_RegWrite, s_ALU_Src_A;
	logic[1:0]	s_RegSrc, s_ImmSrc, s_ALU_Src_B, s_ALU_Control, s_ResultSrc;
	logic[15:0]	s_ControlUnitSignals;

	//	Datapath pins
	logic[(BusWidth - 1):0]	s_Address, s_Instr, s_WriteData, s_Read_InstructionData;
	logic[3:0]				s_ALU_Flags;


	assign s_Read_InstructionData = i_ReadData;

	ARM_MultiCycle_Datapath		Datapath
		(i_CLK, i_NRESET,
		s_PC_Write,
		s_Address, s_AddrSrc, 
		s_WriteData, s_Read_InstructionData,
		s_IR_Write, s_Instr,
		s_RegSrc, s_RegWrite,
		s_ImmSrc,
		s_ALU_Src_A, s_ALU_Src_B, s_ALU_Control, s_ALU_Flags,
		s_ResultSrc);


	assign s_ControlUnitSignals = {s_Instr[31:20], s_Instr[15:12]};

	ARM_MultiCycle_Controller	ControlUnit
		(i_CLK, i_NRESET,
		s_ControlUnitSignals,
		s_ALU_Flags,
		s_PC_Write,
		s_AddrSrc, s_MemW,
		s_IR_Write,
		s_RegSrc, s_RegWrite,
		s_ImmSrc,
		s_ALU_Src_A, s_ALU_Src_B, s_ALU_Control,
		s_ResultSrc);


	assign o_Address = s_Address;
	assign o_WriteData	= s_WriteData;
	assign o_MemWrite	= s_MemW;

endmodule
