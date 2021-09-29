.data

	# plaintext prompt
	# plaintext prompt length
	PlaintextPrompt:
		.asciz "Please enter the plaintext: "
		lenPlaintextPrompt = .-PlaintextPrompt

	# shift key prompt
	# shift key prompt length
	ShiftKeyPrompt:
		.asciz "Please enter the shift value: "
		lenShiftKeyPrompt = .-ShiftKeyPrompt
	
	PowerOfTen:
		.int 0x1

	Conversion:
		.int 0x0

.bss
	.comm Plaintext, 51
	.comm PlaintextLength, 4	

	.comm ShiftKey, 4
	.comm ShiftKeyLength, 4

	.comm Ciphertext, 51
	.comm CiphertextLength, 4

.text

        .globl _start
	.type CaesarCipher, @function

	CaesarCipher:

		pointers:
			# Store value of EBP on stack
                	pushl %ebp

                	# Make EBP point to top of stack
                	movl %esp, %ebp		

		setup:
			cld				# Clear Flags

			movl 8(%ebp), %ebx		# Conversion number
			movl 12(%ebp), %esi		# Plaintext
			movl $Ciphertext, %edi	# Ciphertext
		
		modConversion:
			cmp $26, %ebx
			jb doneConversion 
		
		subConversion:
			sub $26, %ebx
			jmp modConversion

		doneConversion:
			movl %ebx, 8(%ebp)	

		shiftLoop:
			movl $0x0, %eax
			lodsb
			cmp $0x0a, %al
			jz return	
			
			# compare with space
			cmp $0x20, %al
			jz store
			
			#SHIFT
			sub $65, %al
			add 8(%ebp), %al	


		modPlaintext:
			cmp $26, %al
			jb donePlaintext 
		
		subPlaintext:
			sub $26, %al
			jmp modPlaintext

		donePlaintext:
			add $65, %al

		store:
			stosb	
			jmp shiftLoop 

		return:
			movl %ebp, %esp         # Restore the old value of ESP
                	popl %ebp               # Restore the old value of EBP
			ret


	.type StringShiftKeytoInt, @function

	StringShiftKeytoInt: 
	
		StackSetup: 
		       push %ebp 

		       movl %esp, %ebp
                       
		       movl 8(%ebp), %esi    # Shiftkey

	             # set up counter an prep %esi for lodsb command
	               movl $0x0, %ecx	       
           
	   countShiftKeyDigits:
			# load next byte into %al
			lodsb

			# if reached to newline, finish execution
			cmp $0x0a, %al
			jz ESI_Setup
			
			# else, increment size, repeat loop		
			inc %ecx
			jmp countShiftKeyDigits 
					
		ESI_Setup:
		       dec %esi
           	       std   # changes direction to read digits from lowest order first

		       lodsb #skip over new line

	        convertInt:
			movl $0x0, %eax   # clear out %eax, since lodsb only fills lowest byte
			
			lodsb             # load next byte into %al from %esi
			
                        dec %ecx           # decrement counter

			sub $0x30,%eax         # convert ASCII character to corresponding integer in hex

			imul PowerOfTen, %eax    # scale up the digit, depending on place value in hex
			
			addl %eax, Conversion       #adds on the next hundreds,tens, ones group

			imul $10, PowerOfTen, %ebx     # multiply PowerOfTen by factor of 10, save to PowerOfTen label
		        movl %ebx, PowerOfTen	      

			cmp $0x0, %ecx            # if all digits read, continue
			jnz convertInt

		return2:
			movl %ebp, %esp         # Restore the old value of ESP
			popl %ebp               # Restore the old value of EBP
			ret

        _start:
		# write system call 
		movl $4, %eax
		movl $1, %ebx
		movl $PlaintextPrompt, %ecx
		movl $lenPlaintextPrompt, %edx
		int $0x80

		# read system call for plaintext
		# push plaintext to stack
		movl $3, %eax
		movl $0x0, %ebx
		movl $Plaintext, %ecx
		movl $PlaintextLength, %edx
		int $0x80

		# includes newline
		movl %eax, PlaintextLength

		# write system call 
		movl $4, %eax
		movl $1, %ebx
		movl $ShiftKeyPrompt, %ecx
		movl $lenShiftKeyPrompt, %edx
		int $0x80

		# read system call for shift key
		movl $3, %eax
		movl $0x0,  %ebx
		movl $ShiftKey, %ecx
		movl $ShiftKeyLength, %edx
		int $0x80

		# includes newline
		movl %eax, ShiftKeyLength
				
	pushStringShiftKeyToStack:
		pushl $ShiftKey
		
	callStringShiftKeytoInt:
		call StringShiftKeytoInt
		
	pushPlainTextToStack:
                # Pushing Plaintext to stack
                pushl $Plaintext

                # Pushing Conversion to stack
                pushl Conversion

	callCaesarCipher:
		# Call the Caesar Cipher funtion
		call CaesarCipher

	doneShift:
		mov $0x0a, %al
		stosb
		
		# write system call 
		movl $4, %eax
		movl $1, %ebx
		movl $Ciphertext, %ecx
		movl PlaintextLength, %edx
		int $0x80

		# adjust the stack pointer
                addl $8, %esp

		# Quit
                movl $1, %eax
                movl $0, %ebx
                int $0x80
