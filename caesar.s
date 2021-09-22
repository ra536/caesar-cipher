.data

        HelloWorld:
                .asciz "Hello World!\n"
		lenHelloWorld = .-HelloWorld

	# plaintext prompt
	# plaintext prompt length

	# shift key prompt
	# shift key prompt length
	
	PowerOfTen:
		.int 0x1

	Conversion:
		.int 0x0

.bss
	.comm ShiftKeyPointer, 4
	.comm ShiftKeyLength, 4

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
		# read system call for plaintext
		# push plaintext to stack

		# read system call for shift key
		# push shift key to stack
		movl $3, %eax
		movl $0x0,  %ebx
		movl $ShiftKeyPointer, %ecx
		movl $ShiftKeyLength, %edx
		int $0x80
			
		# write system call (TODO: Delete)
		movl $4, %eax
		movl $1, %ebx
		movl $ShiftKeyPointer, %ecx
		movl $ShiftKeyLength, %edx
		int $0x80
		
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

		# call CaesarCipher

		# adjust stack pointer	

	
		# Hello World Example
                movl $4, %eax
                movl $1, %ebx
                movl $HelloWorld, %ecx
                movl $lenHelloWorld, %edx
                int $0x80		

		# Quit
                movl $1, %eax
                movl $0, %ebx
                int $0x80
