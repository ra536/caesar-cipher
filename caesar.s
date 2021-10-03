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
							    # no need for keep track of ciphertext length, since it is the same as the plaintext length

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
			ret


	.type StringShiftKeytoInt, @function

	StringShiftKeytoInt: 	
		StackSetup: 
		       push %ebp 			  # save existing value of EBP on the stack
		       movl %esp, %ebp			  # Make EBP point to the top of the stack                     
		       movl 8(%ebp), %esi    	          # Shiftkey's value in ASCII is stored in %esi
	               movl $0x0, %ecx			  # set up digit counter for ShiftKey value
	                      
	   countShiftKeyDigits:
			lodsb				# load next byte into %al register from %esi to parse through the Shiftkey's value in ASCII digit by digit
							
			cmp $0x0a, %al			# if reached to newline, finish execution and stop counting the digits
			jz locateLastDigit
							
			inc %ecx			# else, increment the digits counter and repeat loop	
			jmp countShiftKeyDigits 
					
		locateLastDigit:
           	        std  				# changes direction to read digits from lowest order first

			lodsb  				#skip over null character since the last lodsb left pointer at a null character
		        lodsb  				#skip over new line

	        convertInt:
			movl $0x0, %eax   	       # clear out %eax, since lodsb only fills lowest byte
			
			lodsb            	       # load digits from lowest order first into %al from %esi (Shiftkey value)
			
                        dec %ecx        	       # decrement counter

			sub $0x30,%eax         		# convert ASCII character to corresponding integer in hex

			imul PowerOfTen, %eax           # scale up the digit, depending on place value in hex
			
			addl %eax, Conversion           # adds on the next ones,tens, hundreds group

			imul $10, PowerOfTen, %ebx      # multiplies PowerOfTen by factor of 10, and saves to PowerOfTen
		        movl %ebx, PowerOfTen	      

			cmp $0x0, %ecx                  # if all digits read stop converting, else continue looping for the next digit
			jnz convertInt
		
			cld				# Clear Flags
		return2:
			movl %ebp, %esp         # Restore the old value of ESP
			popl %ebp               # Restore the old value of EBP
			ret

        _start:
		# write system call 
		movl $4, %eax			     # syscall for write()
		movl $1, %ebx			     # File descriptor for std_out 
		movl $PlaintextPrompt, %ecx          # moves the address of the Plaintext Prompt string into ecx
		movl $lenPlaintextPrompt, %edx	     # moves the length of the Plaintext Prompt string into edx
		int $0x80			     # calls kernel

		# read system call for plaintext
		movl $3, %eax			    # syscall for read()
		movl $0x0, %ebx			    # File descriptor for std_in  
		movl $Plaintext, %ecx		    # moves the address of the PlaintextPointer var into ecx
		movl $51, %edx			    # moves the length of Plaintext var into edx 
		int $0x80			    # calls kernel
		
		movl %eax, PlaintextLength          # total length of input (input + newline)

		# write system call 		    
		movl $4, %eax			    # syscall for write() 
		movl $1, %ebx			    # File descriptor for std_out
		movl $ShiftKeyPrompt, %ecx          # moves the address of the ShiftKeyPrompt string into ecx
		movl $lenShiftKeyPrompt, %edx       # moves the length of the ShiftKeyPrompt string into edx
		int $0x80			    # calls kernel 

		# read system call for shift key
		movl $3, %eax			    # syscall for read()
		movl $0x0,  %ebx		    # File descriptor for std_in 
		movl $ShiftKey, %ecx		    # moves the address of the ShiftKeyPointer var into ecx         
		movl $4, %edx			    # moves the length of the ShiftKeyPointer var into edx
		int $0x80			    # calls kernel

		movl %eax, ShiftKeyLength           # total length of input (input + newline)
		
	callStringShiftKeytoInt:
		pushl $ShiftKey                      # passes the ShfitKey value to the stack
		
		call StringShiftKeytoInt  	     # calls the function to convert the string ShiftKey value to an hexadecimal value

		addl $4, %esp			     # adjust the stack pointer, since $ShiftKey was pushed to stack
		
	callCaesarCipher:
                pushl $Plaintext		     # Pushing Plaintext to stack
               
                pushl Conversion 	             # Pushing Conversion to stack

		call CaesarCipher	             # Call the Caesar Cipher funtion

                addl $8, %esp			    # adjust the stack pointer, since $Plaintext and Conversion was pushed to stack

	finish:
		# write system call 
		movl $4, %eax			   # syscall for write() 
		movl $1, %ebx			   # File descriptor for std_out
		movl $Ciphertext, %ecx		   # moves the address of the CiphertextPointer string into %ecx
		movl PlaintextLength, %edx         # moves the length of PlaintextLength into %edx
		int $0x80			    # calls kernel		

		# Quit
                movl $1, %eax			# sys_exit
                movl $0, %ebx
                int $0x80			# calls kernel	
