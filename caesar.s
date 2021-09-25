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
		movl $PlaintextPrompt, %ecx         # moves the address of the Plaintext Prompt string into ecx
		movl $lenPlaintextPrompt, %edx      # moves the length of the Plaintext string into edx 
		int $0x80			    # calls kernel

		# read system call for plaintext
		# push plaintext to stack
		movl $3, %eax                     # syscall for read()
		movl $0x0, %ebx          	  # File descriptor for std_in  	
		movl $PlaintextPointer, %ecx      # moves the address of the PlaintextPointer var into ecx
		movl $PlaintextLength, %edx       # moves the length of Plaintext var into edx     
		int $0x80			  # calls kernel	

		# includes newline
		movl %eax, PlaintextLength         #moves eax's content into variable PlaintextLength var
  
		# write system call 
		movl $4, %eax			 # syscall for write()
		movl $1, %ebx			 # File descriptor for std_out 
		movl $ShiftKeyPrompt, %ecx       # moves the address of the ShiftKeyPrompt string into ecx
		movl $lenShiftKeyPrompt, %edx    # moves the length of the ShiftKeyPrompt string into edx
		int $0x80                        # calls kernel 

		# read system call for shift key
		# push shift key to stack
		movl $3, %eax                  # syscall for read()
		movl $0x0,  %ebx               # File descriptor for std_in   
		movl $ShiftKeyPointer, %ecx    # moves the address of the ShiftKeyPointer var into ecx         
		movl $ShiftKeyLength, %edx     # moves the length of the ShiftKeyPointer var into edx       
		int $0x80	               # calls kernel

		# includes newline
		movl %eax, ShiftKeyLength      # moves eax's content into variable ShiftKeyLength var
			
		
		movl $0x0, %ecx		       # set up counter 
		movl $ShiftKeyPointer, %esi    # moves shiftKeyPointer into  %esi, prep for loadsb command	 
	
	CountShiftKeyDigits:  
		lodsb				# load next byte into %al register and increments %esi
				
		cmp $0x0a, %al   		# compare byte in %al register with newline character to see if were at the end of line
		jz done                         # if comparison yields zero then zero flag set, and then jump to done label 
		   						
		inc %ecx			# else, increment size of ecx to count the number of character in plaintext	
		jmp CountShiftKeyDigits 	# repeat the loop, until all digits are counted

	done:
		dec %esi  			# previous lodsb pointer made %esi point to a null character, we decrement to go back to newline character

		std  				# change direction to read shift key digits from lowest order first (right to left)
				
		lodsb  				# by starting right to left we know where to skip over newline, (loads newline character to %al, increments %esi address)

	convertShiftKeyToInt:				
		movl $0x0, %eax			# clear out %eax, since new line character was sitting %al (lodsb only fills lowest byte)
					
		lodsb   			# load next byte from %esi into %al, and increments %esi address 
		
		dec %ecx			# decrement counter for every byte loaded in %al,( no null character at front)
						
		movl Conversion, %ebx		# load Conversion label into %ebx (0x0 is first load onto %ebx, then previously saved Conversion )

						# convert ASCII character to corresponding integer
		sub $0x30, %eax  		# e.g. bring 0x37 down to 0x07
		
		imul PowerOfTen, %eax 		# scale up the digit, depending on place value
		
		addl %ebx, %eax			# add to the next digit to accumulator
						# (first loop adds ones, next loops add tens, next loop add hundreds group)
						
		push %eax			# TODO: check if necessary push onto stack
		
		movl PowerOfTen, %ebx		# multiply assign by 10, save to PowerOfTen label
		imul $10, %ebx
		movl %ebx, PowerOfTen
		
		pop %eax		        # TODO: check if necessary
								
		movl %eax, Conversion           # save new value in Conversion var in memory

		cmp $0x0, %ecx			# once ecx is decrement to zero then all digits have been read, continue
		jnz convertShiftKeyToInt 	# if compare z flag is not set then loop again

	setup:
		cld
						
		# call CaesarCipher
		movl $PlaintextPointer, %esi       # load address of Plaintext into  %esi  
		movl PlaintextLength, %ecx	   # load length of Plaintext into  %ecx 
		movl $CiphertextPointer, %edi      # load address of Ciphertext into  %esi  
		
		# bring down Conversion...
		movl Conversion, %ebx              # Conversion holds the shift key value in hex
	modConversion:
		cmp $26, %ebx			   # Compare by subtracting 26 - %ebx(shiftKeyValue) (result is not stored)
		jb doneConversion 		   # if the %ebx(shiftKeyValue) is less than 26 then jump to doneConversion	
	
	subConversion:
		sub $26, %ebx			   # subtracts 26 from %ebx(shiftKeyValue) and save it in %ebx
		jmp modConversion		   # jmps back to modConversion to check if less than 26, if not will come down to repeat subConversion

	doneConversion:
		movl %ebx, Conversion		   # stores the modded %ebx(shiftKeyValue) value back to Conversion 	

	shiftLoop:
		movl $0x0, %eax			   # reset %eax to zero 
		lodsb				   # loads byte from %esi(PlaintextPointer) into %al  (still reading right to left)	
		cmp $0x0a, %al			   # compare byte in %al register with newline character to see if were at the end of line
		jz doneShift		           #  if zflag set jumpto doneShift 
						
		# inc %ecx			  # increment the %ecx value as we have increment the letter	
				
		cmp $0x20, %al			  # compare with space char 
		jz store			  # if %al is space char then zflag is set and jump to store the space char 	
		
		#SHIFT
		sub $65, %al			  # subtract 65 from the %al register to set to zero
		add Conversion, %al		  # add the shift value to the %al register

	modPlaintext:
		cmp $26, %al			 # compare by doing 26 - %al(one byte) 	
		jb donePlaintext 		 # if the %al(plainText letter) is less than 26 then jump to donePlaintext	
	
	subPlaintext:
		sub $26, %al 			 # subtract %al - 26 and store value in %al
		jmp modPlaintext		 # jmp to modPlaintext

	donePlaintext:	
		add $65, %al			 # add 65 to %al reg to be able to convert into ascii to print on screen
		
	store:
		stosb				 # store the char character from %al register into memory %edi (Ciphertext)
		jmp shiftLoop 			 # restart the loop for the next char

	doneShift:
		movl %ecx, CiphertextLength	  # store the %ecx char count into  CiphertextLength
		mov $0x0a, %al		          # mov a new line char to reg eax
		stosb				  # store the char character from %al register into memory %edi (Ciphertext)
		
		# write system call          
		movl $4, %eax     		   # syscall for write()
		movl $1, %ebx			   # File descriptor for std_out 
		movl $CiphertextPointer, %ecx	   # moves the address of the CiphertextPointer string into %ecx
		movl CiphertextLength, %edx 	   # moves the length of CiphertextLength var into %edx     
		int $0x80			   # calls kernel	

		# adjust stack pointer	

		# Exit
                movl $1, %eax			  # sys_exit	  	
                movl $0, %ebx			  
                int $0x80			  # calls kernel	
