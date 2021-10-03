.data

	
	PlaintextPrompt:
		.asciz "Please enter the plaintext: "        # plaintext prompt string
		lenPlaintextPrompt = .-PlaintextPrompt	     # plaintext prompt string length

	
	ShiftKeyPrompt:
		.asciz "Please enter the shift value: "	     # shift key prompt string
		lenShiftKeyPrompt = .-ShiftKeyPrompt	     # shift key prompt string length
	
	PowerOfTen:					     # integer that represents place value for shift key conversion
		.int 0x1   				    

	Conversion:					     # integer that will hold the calculated numerical value of the shift key string 
		.int 0x0		

.bss	
	.comm Plaintext, 52				    # plaintext string, which can be at most 50 characters + 1 newline + 1 null byte
	.comm PlaintextLength, 4			    # plaintext string length (4 bytes chosen to match register size, although 1 byte would be sufficient)

	.comm ShiftKey, 5				    # shift key string, which can be at most 3 digits + 1 newline + 1 null byte
	.comm ShiftKeyLength, 4				    # shift key string length (4 bytes chosen to match register size, although 2 bytes would be sufficient)

	.comm Ciphertext, 52				    # ciphertext string, which can be at most 50 characters + 1 newline + 1 null byte
							    # no need to keep track of ciphertext length, since it is the same as the plaintext length

.text

        .globl _start
	.type CaesarCipher, @function

	CaesarCipher:
		pointers:			
                	pushl %ebp				# save existing value of EBP on the stack				
                	movl %esp, %ebp				# make EBP point to top of the stack

		setup:
			movl 8(%ebp), %ebx			# load Conversion into EBX
			movl 12(%ebp), %esi			# load Plaintext into ESI, for use with lodsb instruction
			movl $Ciphertext, %edi			# load Ciphertext into EDI, for use with stosb instruction
		
		modConversion:
			cmp $26, %ebx 				# compare the shift key to 26
			jb shiftLoop 				# if is less than 26, skip to shifting step, since within modulo 26 range (0-25) 

		subConversion:
			sub $26, %ebx				# else, subtract 26 from the shift key 
			jmp modConversion			# repeat the process until shift key is less than 26 

		shiftLoop:
			movl $0x0, %eax				# zero out EAX, since lodsb will only modify the last byte (AL) 
			lodsb					# load next character byte from the Plaintext into AL	
			
			cmp $0x0a, %al				# if the next character is a newline character,
			jz return				# we have reached the end of the plaintext, skip to return step
			
			cmp $0x20, %al		                # if it is a space character, 
			jz store			        # do not perform shifting, and instead jump to storing the character 
			
			sub $65, %al                            # else, subtract 65 to bring the capital ASCII letter within the modulo 26 range (0-25) 
			add %bl, %al			        # add the shift key value to plaintext letter to shift the letter

								# the reason for doing the modulo of both the shift key and plaintext letter was so that
								# BL could be directly added to AL (else, shift values above 255 would not work properly) 

		modPlaintext:
			cmp $26, %al			        # compare the shifted plaintext to 26
			jb donePlaintext 		        # if is within modulo 26 (0-25) bounds, jump to translate back to ASCII format
		
		subPlaintext:
			sub $26, %al				# else, subtract 26 
			jmp modPlaintext			# and repeat the process 

		donePlaintext:
			add $65, %al				# translates the value back to ASCII format by adding 65

		store:
			stosb					# stores the newly shifted ASCII letter in AL into Ciphertext
			jmp shiftLoop    			# continue the process for the next character in the word

		return:
			mov $0x0a, %al				# append a newline, 
			stosb					# since storing does not occur for the newline character

			movl %ebp, %esp         		# restore the old value of ESP
                	popl %ebp              			# restore the old value of EBP from the stack
			ret					# return from function


	.type StringShiftKeytoInt, @function

	StringShiftKeytoInt: 	
		StackSetup: 
		       push %ebp 			  # save existing value of EBP on the stack
		       movl %esp, %ebp			  # Make EBP point to the top of the stack                     
		       movl 8(%ebp), %esi    	          # load ShiftKey string into ESI
	               movl $0x0, %ecx			  # set up digit counter for ShiftKey value
	                      
	   countShiftKeyDigits:
			lodsb				# load next byte of the ShiftKey into AL
							
			cmp $0x0a, %al			# if reached to newline, 
			jz locateLastDigit		# finish counting and jump to conversion step
							
			inc %ecx			# else, increment the counter
			jmp countShiftKeyDigits		# and repeat the loop	 
					
		locateLastDigit:
           	        std  				# sets direction flag to read digits from lowest order byte first

			lodsb  				# skip over null character, since the last lodsb left pointer at a null character
		        lodsb  				# skip over newline character

	        convertInt:
			movl $0x0, %eax   	        # clear out EAX, since lodsb only fills lowest order byte
			
			lodsb            	        # load next ASCII character into AL 
			
                        dec %ecx        	        # decrement counter

			sub $0x30, %eax        		# convert ASCII character to corresponding integer

			imul PowerOfTen, %eax           # scale up the digit, depending on place value (initially 1, for one's place) 
			
			addl %eax, Conversion           # add value to running Conversion total

			imul $10, PowerOfTen, %ebx      # multiplies PowerOfTen by factor of 10, 
		        movl %ebx, PowerOfTen	        # and saves to PowerOfTen 

			cmp $0x0, %ecx                  # if all digits read stop converting (fall through)
			jnz convertInt			# else, continue looping for the next digit
		
			cld				# clear direction flag

		return2:
			movl %ebp, %esp         # restore the old value of ESP
			popl %ebp               # restore the old value of EBP
			ret			# return from function

        _start:
		# write system call for plaintext prompt 
		movl $4, %eax			     # syscall for write()
		movl $1, %ebx			     # file descriptor for std_out 
		movl $PlaintextPrompt, %ecx          # load the PlaintextPrompt string
		movl $lenPlaintextPrompt, %edx	     # load length of the PlaintextPrompt string
		int $0x80			     # calls kernel interrupt

		# read system call for plaintext
		movl $3, %eax			    # syscall for read()
		movl $0x0, %ebx			    # file descriptor for std_in  
		movl $Plaintext, %ecx		    # load the Plaintext
		movl $52, %edx			    # load 52 for plaintext length (PlaintextLength CANNOT be used, since uninitialized) 
		int $0x80			    # calls kernel interrupt
		
		movl %eax, PlaintextLength          # read call returns total length of input (user input + newline)

		# write system call for shift key prompt 		    
		movl $4, %eax			    # syscall for write() 
		movl $1, %ebx			    # file descriptor for std_out
		movl $ShiftKeyPrompt, %ecx          # load the ShiftKeyPrompt string 
		movl $lenShiftKeyPrompt, %edx       # load length of the ShiftKeyPrompt string 
		int $0x80			    # calls kernel interrupt 

		# read system call for shift key
		movl $3, %eax			    # syscall for read()
		movl $0x0,  %ebx		    # file descriptor for std_in 
		movl $ShiftKey, %ecx		    # load the ShiftKey
		movl $5, %edx			    # load 5 for shift key length (ShiftKeyLength CANNOT be used, since uninitialized)
		int $0x80			    # calls kernel interrupt

		movl %eax, ShiftKeyLength           # read call returns total length of input (user input + newline)
		
	callStringShiftKeytoInt:
		pushl $ShiftKey                      # saves ShiftKey to the stack
		
		call StringShiftKeytoInt  	     # calls function to convert the ShiftKey string value to an integer value

		addl $4, %esp			     # adjust the stack pointer, since ShiftKey was pushed to the stack
		
	callCaesarCipher:
                pushl $Plaintext		     # pushing Plaintext to stack
                pushl Conversion 	             # pushing Conversion to stack

		call CaesarCipher	             # call function to perform caesar cipher

                addl $8, %esp			     # adjust the stack pointer, since Plaintext and Conversion were pushed to the stack

	finish:
		# write system call for ciphertext 
		movl $4, %eax			   # syscall for write() 
		movl $1, %ebx			   # file descriptor for std_out
		movl $Ciphertext, %ecx		   # load Ciphertext 
		movl PlaintextLength, %edx         # load PlaintextLength (since plaintext is the same size as ciphertext)
		int $0x80			   # calls kernel interrupt		

		# Quit
                movl $1, %eax			# sys_exit
                movl $0, %ebx			# return value of 0
                int $0x80			# calls kernel interrupt	
