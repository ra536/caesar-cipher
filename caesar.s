.data

	PlaintextPrompt:
		.asciz "Please enter the plaintext: "    # plaintext prompt string
		lenPlaintextPrompt = .-PlaintextPrompt   # plaintext prompt string length 
	
	ShiftKeyPrompt:
		.asciz "Please enter the shift value: "   # shift value pompt string
		lenShiftKeyPrompt = .-ShiftKeyPrompt      # shift value prompt string length
	
	PowerOfTen:
		.int 0x1  

	Conversion:
		.int 0x0

.bss
	.comm PlaintextPointer, 51        # allocates 51 bytes for plaintext which is 50 characters + 1 null byte
	.comm PlaintextLength, 4	  # allocates 4 bytes for  plaintext's length value.

	.comm ShiftKeyPointer, 4          #  allocates 4 bytes for shift key number, which can be up to 1000 (decimal)
	.comm ShiftKeyLength, 4           #  allocates 4 bytes for shift key's length value. 

	.comm CiphertextPointer, 51      # allocates 51 bytes for cipher output which is 50 characters + 1 null byte (maybe needs to 52 bytes)
	.comm CiphertextLength, 4        # allocates 4 ytes for  cipher output's length value.

	.comm ShiftKeyInteger, 4        # allocates 4 bytes for the shift key in an integer form
	.comm ShiftKeySize, 4		# allocates 4 bytes for the shift key's length value.

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
		movl $4, %eax           	    # syscall for write()
		movl $1, %ebx  		    	    # File descriptor for std_out 	
		movl $PlaintextPrompt, %ecx         # moves the address of the string into ecx
		movl $lenPlaintextPrompt, %edx      # moves the length of the string into edx 
		int $0x80			    # calls kernel

		# read system call for plaintext
		# push plaintext to stack
		movl $3, %eax                     # syscall for read()
		movl $0x0, %ebx          	  # File descriptor for std_in  	
		movl $PlaintextPointer, %ecx      # moves the address of the string into ecx
		movl $PlaintextLength, %edx       # moves the length of the string into edx     
		int $0x80			  # calls kernel	

		# includes newline
		movl %eax, PlaintextLength         #moves eax's content into variable PlaintextLength in memory
  
		# write system call 
		movl $4, %eax			 # syscall for write()
		movl $1, %ebx			 # File descriptor for std_out 
		movl $ShiftKeyPrompt, %ecx       # moves the address of the string into ecx
		movl $lenShiftKeyPrompt, %edx    # moves the length of the string into edx
		int $0x80                        # calls kernel 

		# read system call for shift key
		# push shift key to stack
		movl $3, %eax                  # syscall for read()
		movl $0x0,  %ebx               # File descriptor for std_in   
		movl $ShiftKeyPointer, %ecx    #         
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
