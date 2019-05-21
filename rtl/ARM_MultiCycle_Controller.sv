module ARM_MultiCycle_Controller
	#(parameter	BusWidth	= 32)
	(input logic			i_CLK, i_NRESET,

	input logic[15:0]		i_Instr,
	input logic[3:0]		i_ALU_Flags,

	//	PC control
	output logic			o_PC_Write,
	//	Memory control);
	output logic			o_AddressSrc,
	output logic			o_MemWrite,
	//	Instruction Cycle control
	output logic			o_InstructionWrite,
	//	Register Sources selector
	output logic[1:0]		o_RegSrc,
	//	Register File control
	output logic			o_RegWrite,
	//	Extension Unit selector control
	output logic[1:0]		o_ImmSrc,
	//	ALU Sources selector
	output logic			o_ALU_Src_A,
	output logic[1:0]		o_ALU_Src_B,
	//	ALU control
	output logic[1:0]		o_ALU_Control,
	//	Result control
	output logic[1:0]		o_Result_Src);

	logic[3:0]	s_Cond;
	logic[1:0]	s_Op;
	logic[5:0]	s_Funct;
	logic[3:0]	s_Rd;

	//	Internal connections
	logic[1:0]	s_FlagW;
	logic		s_NoWrite;
	logic		s_PC_Src, s_NextPC, s_RegW, s_MemW;

	assign s_Cond		= i_Instr[15:12];
	assign s_Op			= i_Instr[11:10];
	assign s_Funct		= i_Instr[9:4];
	assign s_Rd			= i_Instr[3:0];
	

	ARM_MultiCycle_Decoder	Decoder
		(i_CLK, i_NRESET,
		s_Op, s_Funct,
		s_Rd,
		s_FlagW, s_NoWrite, s_PC_Src, s_NextPC, s_RegW, s_MemW,
		o_InstructionWrite,
		o_AddressSrc,
		o_Result_Src,
		o_ALU_Src_A, o_ALU_Src_B,
		o_RegSrc, o_ImmSrc,
		o_ALU_Control);

	ARM_MultiCycle_ConditionalLogic	ConditionalLogic
		(i_CLK, i_NRESET,
		s_NextPC, s_PC_Src,
		s_RegW, s_MemW, s_FlagW,
		s_Cond, i_ALU_Flags,
		s_NoWrite,
		o_PC_Write,
		o_RegWrite, o_MemWrite);

endmodule



module ARM_MultiCycle_Decoder
	(input logic		i_CLK, i_NRESET,

	input logic[1:0]	i_Op,
	input logic[5:0]	i_Funct,
	input logic[3:0]	i_Rd,

	//	To conditon logic
	output logic[1:0]	o_FlagW,
	output logic		o_NoWrite,
	output logic		o_PC_Src, o_NextPC,
	output logic		o_RegW,
	output logic		o_MemW,

	//	To Datapath
	output logic		o_InstructionWrite,
	output logic		o_AddrSrc,
	output logic[1:0]	o_ResultSrc,
	output logic		o_ALU_Src_A,
	output logic[1:0]	o_ALU_Src_B,
	output logic[1:0]	o_RegSrc, o_ImmSrc,
	output logic[1:0]	o_ALU_Control);

	//	Main FSM control pins
	logic s_Branch;
	logic s_RegW, s_ALU_Op;

	//	ALU Decoder
	logic[1:0]	s_ALU_Control, s_FlagWrite;
	logic		s_NoWrite;


	ARM_MultiCycle_PC_Logic	PC_Logic
		(i_Rd,
		s_Branch, s_RegW,
		o_PC_Src);

	ARM_MultiCycle_MainFSM	MainFSM
		(i_CLK, i_NRESET,
		i_Op, {i_Funct[5], i_Funct[0]},
		s_Branch,
		s_RegW,
		o_MemW,
		o_InstructionWrite,
		o_NextPC,
		o_AddrSrc,
		o_ResultSrc,
		o_ALU_Src_A,
		o_ALU_Src_B,
		s_ALU_Op);

	ARM_MultiCycle_ALUDecoder	ALU_Decoder
		(i_Funct[4:0],
		s_ALU_Op,
		o_ALU_Control, o_FlagW, o_NoWrite);

	ARM_MultiCycle_InstructionDecoder	InstructionDecoder
		(i_Op,
		o_RegSrc, o_ImmSrc);


	//	Outputs
	assign o_RegW = s_RegW;

endmodule

module ARM_MultiCycle_MainFSM
	(input logic		i_CLK, i_NRESET,

	input logic[1:0]	i_Op,
	input logic[1:0]	i_Funct,

	output logic		o_Branch,

	output logic		o_RegW,
	output logic		o_MemW,
	output logic		o_InstrW,
	output logic		o_NextPC,
	output logic		o_AddrSrc,
	output logic[1:0]	o_Result_Src,
	output logic		o_ALU_Src_A,
	output logic[1:0]	o_ALU_Src_B,

	output logic		o_ALU_Op);

	typedef enum logic[3:0]	{STATE_FETCH, STATE_DECODE,
							STATE_MEM_ADDR, STATE_MEM_READ, STATE_MEM_WRITE, STATE_MEM_WR_BACK,
							STATE_EXECUTE_REG, STATE_EXECUTE_IMM, STATE_ALU_WR_BACK,
							STATE_BRANCH}	mainStateType;
	mainStateType	st_CurrentState, st_NewState;

	logic		s_Funct_5, s_Funct_0;

	logic		s_AddrSrc;
	logic		s_ALU_Src_A;
	logic[1:0]	s_ALU_Src_B;
	logic[1:0]	s_Result_Src;
	logic		s_InstrW;
	logic		s_NextPC;
	logic		s_ALU_Op;
	logic		s_Branch;
	logic		s_MemW;
	logic		s_RegW;



	assign s_Funct_5 = i_Funct[1];
	assign s_Funct_0 = i_Funct[0];


	//	Register logic
	always_ff	@(posedge i_CLK, negedge i_NRESET)
	begin
		if (~i_NRESET)	st_CurrentState <= STATE_FETCH;
		else			st_CurrentState <= st_NewState;
	end

	//	Next State logic
	always_comb
	begin
		case (st_CurrentState)
			STATE_FETCH:
			begin
				s_NextPC		= 1'b1;
				s_AddrSrc		= 1'b0;
				s_MemW			= 1'b0;
				s_InstrW		= 1'b1;			//	Save intruction in Instruction register
				s_RegW			= 1'b0;
				s_ALU_Src_A		= 1'b1;
				s_ALU_Src_B		= 2'b10;		//	Save PC + 4 in the PC register
				s_ALU_Op		= 1'b0;			//	Not Data Processing instruction
				s_Result_Src	= 2'b10;
				s_Branch		= 1'b0;

				st_NewState = STATE_DECODE;
			end
			STATE_DECODE:
			begin
				s_NextPC		= 1'b0;
				s_AddrSrc		= 1'bx;
				s_MemW			= 1'b0;
				s_InstrW		= 1'b0;			//	Don't write the next instruction while decoding instruction
				s_RegW			= 1'b0;
				s_ALU_Src_A		= 1'b1;
				s_ALU_Src_B		= 2'b10;		//	Save PC + 8 in R15 register (PC)
				s_ALU_Op		= 1'b0;			//	Not Data Processing instruction
				s_Result_Src	= 2'b10;
				s_Branch		= 1'b0;			//	Don't Branch while decoding instruction

				case (i_Op)
					2'b00:	st_NewState = (s_Funct_5) ?	STATE_EXECUTE_IMM : STATE_EXECUTE_REG;	//	If Funct[5] then process immediate else register A2
					2'b01:	st_NewState = STATE_MEM_ADDR;
					2'b10:	st_NewState = STATE_BRANCH;

					default:	st_NewState = STATE_FETCH;
				endcase
			end
			STATE_MEM_ADDR:					//	Compute the address	for Load/Store instructions and place it in ALU_Result reg
			begin
				s_NextPC		= 1'b0;
				s_AddrSrc		= 1'bx;
				s_MemW			= 1'b0;
				s_InstrW		= 1'b0;
				s_RegW			= 1'b0;		//	Value will neccessary in the next stage (ALU_Result register saves the address)
				s_ALU_Src_A		= 1'b0;
				s_ALU_Src_B		= 2'b01;	//	Add the immediate to the offset register
				s_ALU_Op		= 1'b0;		//	Not Data Processing instruction
				s_Result_Src	= 2'bxx;
				s_Branch		= 1'b0;

				st_NewState = (s_Funct_0) ?	STATE_MEM_READ : STATE_MEM_WRITE;
			end
			STATE_MEM_READ:
			begin
				s_NextPC		= 1'b0;
				s_AddrSrc		= 1'b1;
				s_MemW			= 1'b0;
				s_InstrW		= 1'b0;
				s_RegW			= 1'b0;
				s_ALU_Src_A		= 1'bx;
				s_ALU_Src_B		= 2'bxx;
				s_ALU_Op		= 1'b0;		//	Not DP instruction
				s_Result_Src	= 2'b00;
				s_Branch		= 1'b0;

				st_NewState = STATE_MEM_WR_BACK;
			end
			STATE_MEM_WRITE:
			begin
				s_NextPC		= 1'b0;
				s_AddrSrc		= 1'b1;
				s_MemW			= 1'b1;
				s_InstrW		= 1'b0;
				s_RegW			= 1'b0;
				s_ALU_Src_A		= 1'bx;
				s_ALU_Src_B		= 2'bxx;
				s_ALU_Op		= 1'b0;
				s_Result_Src	= 2'b00;			//	ALU_Out register
				s_Branch		= 1'b0;

				st_NewState = STATE_FETCH;
			end
			STATE_MEM_WR_BACK:
			begin
				s_NextPC		= 1'b0;
				s_AddrSrc		= 1'bx;//1;
				s_MemW			= 1'b0;
				s_InstrW		= 1'b0;
				s_RegW			= 1'b1;
				s_ALU_Src_A		= 1'bx;
				s_ALU_Src_B		= 2'bxx;
				s_ALU_Op		= 1'b0;
				s_Result_Src	= 2'b01;			//	ALU_Out register
				s_Branch		= 1'b0;

				st_NewState = STATE_FETCH;
			end
			STATE_EXECUTE_REG:
			begin
				s_NextPC		= 1'b0;
				s_AddrSrc		= 1'bx;
				s_MemW			= 1'b0;
				s_InstrW		= 1'b0;
				s_RegW			= 1'b0;				//	Result will writen on the writeback stage
				s_ALU_Src_A		= 1'b0;				//	Source register RD1
				s_ALU_Src_B		= 2'b00;			//	Source register RD2	(not immediate !!)
				s_ALU_Op		= 1'b1;				//	Data processing intruction
				s_Result_Src	= 2'bxx;
				s_Branch		= 1'b0;

				st_NewState = STATE_ALU_WR_BACK;
			end
			STATE_EXECUTE_IMM:
			begin
				s_NextPC		= 1'b0;
				s_AddrSrc		= 1'bx;
				s_MemW			= 1'b0;
				s_InstrW		= 1'b0;
				s_RegW			= 1'b0;
				s_ALU_Src_A		= 1'b0;				//	Source register RD1
				s_ALU_Src_B		= 2'b01;			//	Source - immediate	(not register!!)
				s_ALU_Op		= 1'b1;				//	DP instruction
				s_Result_Src	= 2'bxx;			//	Result will saved in the ALU_Out register
				s_Branch		= 1'b0;

				st_NewState = STATE_ALU_WR_BACK;
			end
			STATE_ALU_WR_BACK:
			begin
				s_NextPC		= 1'b0;
				s_AddrSrc		= 1'bx;				//	Write result in the Register File, not in the memory
				s_MemW			= 1'b0;				//	Write result in the Register File, not in the memory
				s_InstrW		= 1'b0;				//	
				s_RegW			= 1'b1;				//	Save ALU_Out result in the Register file
				s_ALU_Src_A		= 1'bx;
				s_ALU_Src_B		= 2'bxx;
				s_ALU_Op		= 1'b1;//x;
				s_Result_Src	= 2'b00;			//	ALU_Out register
				s_Branch		= 1'b0;

				st_NewState = STATE_FETCH;
			end
			STATE_BRANCH:
			begin
				s_NextPC		= 1'bx;
				s_AddrSrc		= 1'bx;
				s_MemW			= 1'b0;
				s_InstrW		= 1'b0;
				s_RegW			= 1'b0;
				s_ALU_Src_A		= 1'b1;				//	PC as source register
				s_ALU_Src_B		= 2'b01;			//	Immediate offset
				s_ALU_Op		= 1'b0;				//	Not DP
				s_Result_Src	= 2'b10;
				s_Branch		= 1'b1;

				st_NewState = STATE_FETCH;
			end

			default:
			begin
				s_NextPC		= 1'b0;
				s_AddrSrc		= 1'b0;
				s_MemW			= 1'b0;
				s_InstrW		= 1'b0;
				s_RegW			= 1'b0;
				s_ALU_Src_A		= 1'b0;
				s_ALU_Src_B		= 2'b00;
				s_ALU_Op		= 1'b1;
				s_Result_Src	= 2'b0;
				s_Branch		= 1'b0;

				st_NewState = STATE_FETCH;
			end
		endcase
	end

	//	Output logic
	assign o_Branch		= s_Branch;
	assign o_RegW		= s_RegW;
	assign o_MemW		= s_MemW;
	assign o_InstrW		= s_InstrW;
	assign o_NextPC		= s_NextPC;
	assign o_AddrSrc	= s_AddrSrc;
	assign o_Result_Src	= s_Result_Src;
	assign o_ALU_Src_A	= s_ALU_Src_A;
	assign o_ALU_Src_B	= s_ALU_Src_B;
	assign o_ALU_Op		= s_ALU_Op;

endmodule

module ARM_MultiCycle_ALUDecoder
	(input logic[4:0]	i_Funct,
	input logic			i_ALU_Operation,
	output logic[1:0]	o_ALU_Control,
	output logic[1:0]	o_Flag_Write,
	output logic		o_No_Write);

	typedef enum logic[3:0]	{ADD = 4'b0100,
							SUB = 4'b0010,
							AND = 4'b0000,
							ORR = 4'b1100,
							CMP = 4'b1010}	InstructionType;


	always_comb
	begin
		if (i_ALU_Operation)
		begin
			o_ALU_Control		= 2'bxx;
			o_No_Write			= 1'bx;
			o_Flag_Write		= 2'bxx;
			case (i_Funct[4:1])
				ADD:
				begin
					o_ALU_Control		= 2'b00;
					o_No_Write			= 1'b0;
					if (i_Funct[0])		o_Flag_Write	= 2'b11;
				end
				SUB:
				begin
					o_ALU_Control		= 2'b01;
					o_No_Write			= 1'b0;
					if (i_Funct[0])		o_Flag_Write	= 2'b11;
				end
				AND:
				begin
					o_ALU_Control		= 2'b10;
					o_No_Write			= 1'b0;
					if (i_Funct[0])		o_Flag_Write	= 2'b10;
				end
				ORR:
				begin
					o_ALU_Control		= 2'b11;
					o_No_Write			= 1'b0;
					if (i_Funct[0])		o_Flag_Write	= 2'b10;
				end
				CMP:
				begin
					o_ALU_Control		= 2'b01;
					o_No_Write			= 1'b1;
					if (i_Funct[0])		o_Flag_Write	= 2'b11;
				end
				
				default:
				begin
					o_ALU_Control		= 2'bxx;
					o_No_Write			= 1'bx;
					o_Flag_Write		= 2'bxx;
				end
			endcase
		end
		else
		begin
			//	Not Data Processing instruction case
			o_ALU_Control	= 2'b0;
			o_Flag_Write	= 2'b0;
			o_No_Write		= 1'b0;
		end
	end

endmodule

module ARM_MultiCycle_InstructionDecoder
	(input logic[1:0]	i_Op,

	output logic[1:0]	o_RegSrc,
	output logic[1:0]	o_ImmSrc);


	always_comb
	begin
		o_RegSrc[1] = (i_Op == 2'b01) ?	1'b1 : 1'b0;
		o_RegSrc[0] = (i_Op == 2'b10) ?	1'b1 : 1'b0;
	end

	assign o_ImmSrc = i_Op;

endmodule

module	ARM_MultiCycle_PC_Logic
	(input logic[3:0]	i_Rd,
	input logic			i_Branch, i_Reg_Write,
	output logic		o_PC_Src);


	assign o_PC_Src = (((i_Rd == 4'd15) & i_Reg_Write) | i_Branch) ?	1'b1 : 1'b0;

endmodule



module ARM_MultiCycle_ConditionalLogic
	(input logic		i_CLK, i_NRESET,
	input logic			i_NextPC, i_PC_Source,
	input logic			i_RegW,
	input logic			i_MemW,
	input logic[1:0]	i_FlagW,

	input logic[3:0]	i_Cond,
	input logic[3:0]	i_ALU_Flags,

	input logic			i_NoWrite,

	output logic		o_PC_Write,
	output logic		o_Reg_Write,
	output logic		o_Mem_Write);

	logic			s_CondEx, s_CondExecuted;
	logic[1:0]		s_FlagWrite;
	logic[3:0]		s_Flags;
	logic			s_PC_Src_Condition;


	ConditionCheck	ConditionChecker
		(i_Cond,
		s_Flags[3:2],
		s_Flags[1:0],

		s_CondEx);


	always_ff	@(posedge i_CLK, negedge i_NRESET)
	begin
		if (~i_NRESET)
		begin
			s_Flags[3:0] <= 4'd0;
		end
		else
		begin
			if (s_FlagWrite[1])	s_Flags[3:2] <= i_ALU_Flags[3:2];
			if (s_FlagWrite[0])	s_Flags[1:0] <= i_ALU_Flags[1:0];
		end
	end

	always_ff	@(posedge i_CLK, negedge i_NRESET)
	begin
		if (~i_NRESET)	s_CondExecuted <= 1'b0;
		else			s_CondExecuted <= s_CondEx;
	end


	assign s_FlagWrite = (s_CondEx) ?	i_FlagW : 2'b00;

	always_comb
	begin
		s_PC_Src_Condition = i_PC_Source & s_CondExecuted;
		o_Reg_Write = (~i_NoWrite & i_RegW) & s_CondExecuted;
		o_Mem_Write = i_MemW & s_CondExecuted;
	end

	assign o_PC_Write = s_PC_Src_Condition | i_NextPC;

endmodule

module ConditionCheck
	(input logic[3:0]	i_Cond,
	input logic[1:0]	i_Flags_NZ,
	input logic[1:0]	i_Flags_CV,
	
	output logic		o_Cond_Executed);

	typedef enum logic[3:0]	{EQ, NE, CS, LO,
							MI, PL, VS, VC,
							HI,	LS, GE, LT,
							GT, LE, AL}	ConditionTyoe;


	always_comb
	begin
		case (i_Cond)
			EQ:	if (i_Flags_NZ[0])		o_Cond_Executed = 1'b1;
				else					o_Cond_Executed = 1'b0;
			NE:	if (i_Flags_NZ[0] == 0)	o_Cond_Executed = 1'b1;
				else					o_Cond_Executed = 1'b0;
			CS:	if (i_Flags_CV[1])		o_Cond_Executed = 1'b1;
				else					o_Cond_Executed = 1'b0;
			LO:	if (i_Flags_CV[1] == 0)	o_Cond_Executed = 1'b1;
				else					o_Cond_Executed = 1'b0;
			MI:	if (i_Flags_NZ[1])		o_Cond_Executed = 1'b1;
				else					o_Cond_Executed = 1'b0;
			PL:	if (i_Flags_NZ[1] == 0)	o_Cond_Executed = 1'b1;
				else					o_Cond_Executed = 1'b0;
			VS:	if (i_Flags_CV[0])		o_Cond_Executed = 1'b1;
				else					o_Cond_Executed = 1'b0;
			VC:	if (i_Flags_CV[0] == 0)	o_Cond_Executed = 1'b1;
				else					o_Cond_Executed = 1'b0;
			
			HI:	if ((i_Flags_NZ[0] == 0) & (i_Flags_CV[1]))	o_Cond_Executed = 1'b1;
				else										o_Cond_Executed = 1'b0;
			LS:	if ((i_Flags_NZ[0]) | (i_Flags_CV[1] == 0))	o_Cond_Executed = 1'b1;
				else										o_Cond_Executed = 1'b0;
			GE:	if (~((i_Flags_NZ[1]) ^ (i_Flags_CV[0])))	o_Cond_Executed = 1'b1;
				else										o_Cond_Executed = 1'b0;
			LT:	if (((i_Flags_NZ[1]) ^ (i_Flags_CV[0])))	o_Cond_Executed = 1'b1;
				else										o_Cond_Executed = 1'b0;
			
			GT:	if ((~i_Flags_NZ[0]) & (~((i_Flags_NZ[1]) ^ (i_Flags_CV[0]))))	o_Cond_Executed = 1'b1;
				else															o_Cond_Executed = 1'b0;
			LE:	if ((i_Flags_NZ[0]) | (((i_Flags_NZ[1]) ^ (i_Flags_CV[0]))))	o_Cond_Executed = 1'b1;
				else															o_Cond_Executed = 1'b0;
			
			AL:	o_Cond_Executed = 1'b1;
			
			default:	o_Cond_Executed = 1'bx;
		endcase
	end

endmodule

