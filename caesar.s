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
	.comm PlaintextPointer, 51
	.comm PlaintextLength, 4	

	.comm ShiftKeyPointer, 4
	.comm ShiftKeyLength, 4

	.comm CiphertextPointer, 51
	.comm CiphertextLength, 4

	.comm ShiftKeyInteger, 4
	.comm ShiftKeySize, 4	

	# TODO: Delete
	.comm ConversionLength, 4

.text

        .globl _start
	.type CaesarCipher, @function

	CaesarCipher:
		# find plaintext on stack
		# find shift key on stack

		# convert shift key to integer

		# LOOP (calculate ciphertext)

		# print ciphertext

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
		movl $PlaintextPointer, %ecx
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
		# push shift key to stack
		movl $3, %eax
		movl $0x0,  %ebx
		movl $ShiftKeyPointer, %ecx
		movl $ShiftKeyLength, %edx
		int $0x80

		# includes newline
		movl %eax, ShiftKeyLength
			
		# set up counter and prep %esi for lodsb command
		movl $0x0, %ecx
		movl $ShiftKeyPointer, %esi
	findEnd:
		# load next byte into %al
		lodsb

		# if newline, finish execution
		cmp $0x0a, %al
		jz done
		
		# else, increment size, repeat loop		
		inc %ecx
		jmp findEnd 

	done:
		# last lodsb left pointer at null character, bring to newline
		dec %esi  

		# change direction to read digits from lowest order first
		std  
		
		# skip over newline
		lodsb  

		# store ConversionLength (TODO: Delete)
		movl %ecx, ConversionLength

	convertInt:
		# clear out %eax, since lodsb only fills lowest byte
		movl $0x0, %eax

		# load next byte into %al
		lodsb   

		# decrement counter, since no null character at front
		dec %ecx

		# load Conversion label into %ebx
		movl Conversion, %ebx

		# convert ASCII character to corresponding integer
		sub $0x30, %eax  # e.g. bring 0x37 down to 7
		
		# scale up the digit, depending on place value
		imul PowerOfTen, %eax 

		# add to accumulator
		addl %ebx, %eax

		# TODO: check if necessary
		push %eax
		
		# multiply assign by 10, save to PowerOfTen label
		movl PowerOfTen, %ebx
		imul $10, %ebx, %ebx
		movl %ebx, PowerOfTen
		
		# TODO: check if necessary
		pop %eax

		# save new accumulated total
		movl %eax, Conversion

		# if all digits read, continue
		cmp $0x0, %ecx
		jnz convertInt 

	setup:
		cld

		# call CaesarCipher
		movl $PlaintextPointer, %esi
		movl PlaintextLength, %ecx
		movl $CiphertextPointer, %edi
		
		# bring down Conversion...
		movl Conversion, %ebx
	modConversion:
		cmp $26, %ebx
		jb doneConversion 
	
	subConversion:
		sub $26, %ebx
		jmp modConversion

	doneConversion:
		movl %ebx, Conversion	

	shiftLoop:
		movl $0x0, %eax
		lodsb
		cmp $0x0a, %al
		jz doneShift	
		
		# inc %ecx
		
		# compare with space
		cmp $0x20, %al
		jz store
		
		#SHIFT
		sub $65, %al
		add Conversion, %al	


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

	doneShift:
		movl %ecx, CiphertextLength
		mov $0x0a, %al
		stosb
		
		# write system call 
		movl $4, %eax
		movl $1, %ebx
		movl $CiphertextPointer, %ecx
		movl CiphertextLength, %edx
		int $0x80

		# adjust stack pointer	


		# Quit
                movl $1, %eax
                movl $0, %ebx
                int $0x80
