.data

	
	PlaintextPrompt:
		.asciz "Please enter the plaintext: "        # plaintext prompt
		lenPlaintextPrompt = .-PlaintextPrompt	     # plaintext prompt length

	
	ShiftKeyPrompt:
		.asciz "Please enter the shift value: "	     # shift key prompt
		lenShiftKeyPrompt = .-ShiftKeyPrompt	     # shift key prompt length
	
	PowerOfTen:					     # This PowerOfTen var will be used to upscale the digits from ones to tens or hundreds group
		.int 0x1   				    

	Conversion:					    # This Conversion var will hold the ASCII translated hexadecimal number
		.int 0x0		

.bss	
	.comm Plaintext, 51				    # allocates 51 bytes for plaintext which is 50 characters + 1 null byte
	.comm PlaintextLength, 4			    # allocates 4 bytes for  plaintext length value of 51

	.comm ShiftKey, 4				    # allocates 4 bytes for shift key number which is inputted in ASCII.
	.comm ShiftKeyLength, 4				    # allocates 4 bytes for shift key's length value. 

	.comm Ciphertext, 51				   # allocates 51 bytes for cipher output which is 50 characters + 1 null byte
	.comm CiphertextLength, 4			   # allocates 4 ytes for  cipher output's length value.

.text

        .globl _start
	.type CaesarCipher, @function

	CaesarCipher:

		pointers:
			
                	pushl %ebp				# Store value of EBP on stack
				
                	movl %esp, %ebp				# Make EBP point to top of stack

		setup:
			movl 8(%ebp), %ebx			# Conversion number
			movl 12(%ebp), %esi			# Plaintext
			movl $Ciphertext, %edi			# Ciphertext
		
		modConversion:
			cmp $26, %ebx 				# check if the shiftKey number is less than 26. 
			jb shiftLoop 				# if the number is less than 26 then we do the shift 
		
		subConversion:
			sub $26, %ebx				# if the number is larger than 26 we repeately subtract by 26 to find the modules of 26
			jmp modConversion

		shiftLoop:
			movl $0x0, %eax				# reset %eax to zero 
			lodsb					# loads character byte from %esi(PlaintextPointer) into %al register to do shift operation	
			cmp $0x0a, %al				# compare byte in %al register with newline character to see if were at the end of line
			jz return				# if we are at the end of line then we finish shifting
			
			cmp $0x20, %al		               # compare with space char 
			jz store			       # if it space char then store the space char do not shift it
			
			#SHIFT
			sub $65, %al                          # subtract 65 from the %al register to scale down ASCII letter to 0-25 range
			add %bl, %al			      # add the shift value to plaintext letter


		modPlaintext:
			cmp $26, %al			       #compare that the added value is within the bounds of the alphabet (0-25)
			jb donePlaintext 		       # if is wihin bounds jump to donePlainText to translate back to ASCII
		
		subPlaintext:
			sub $26, %al			      # substract 26 if the added value is greater then bounds of the alphabet values (0-25)
			jmp modPlaintext		      # jump to modPlaintext to compare again

		donePlaintext:
			add $65, %al			      # translates the value back to ASCII format by adding 65 

		store:
			stosb				 # stores the letter from %al register into memory %edi (Ciphertext memory location) 
			jmp shiftLoop    		 # restart the loop for the next letter in word

		return:
			mov $0x0a, %al			#adds a newline character and stores in the %edi (Ciphertext memory location)
			stosb

			movl %ebp, %esp         # Restore the old value of ESP
                	popl %ebp               # Restore the old value of EBP
			ret


	.type StringShiftKeytoInt, @function

	StringShiftKeytoInt: 
	
		StackSetup: 
		       push %ebp 			  # pushes %ebp on the stack

		       movl %esp, %ebp			  # makes %ebp to the new pointer to top of the stack
                       
		       movl 8(%ebp), %esi    	          # Shiftkey's value in ASCII is stored in %esi

	               movl $0x0, %ecx			  # set up counter an prep %esi for lodsb command
	                      
	   countShiftKeyDigits:
			lodsb				# load next byte into %al to be converted in hexadecimal value
							
			cmp $0x0a, %al			# if reached to newline, finish execution and stop the counting the digits
			jz locateLastDigit
							
			inc %ecx			# else, increment the digits counter and repeat loop	
			jmp countShiftKeyDigits 
					
		locateLastDigit:
           	        std  				 # changes direction to read digits from lowest order first

			lodsb  				#skip over null character since the last lodsb left pointer at a null character
		        lodsb  				#skip over new line

	        convertInt:
			movl $0x0, %eax   	       # clear out %eax, since lodsb only fills lowest byte
			
			lodsb            	       # load next byte into %al from %esi
			
                        dec %ecx        	       # decrement counter

			sub $0x30,%eax         		# convert ASCII character to corresponding integer in hex

			imul PowerOfTen, %eax           # scale up the digit, depending on place value in hex
			
			addl %eax, Conversion           # adds on the next hundreds,tens, ones group

			imul $10, PowerOfTen, %ebx      # multiply PowerOfTen by factor of 10, save to PowerOfTen label
		        movl %ebx, PowerOfTen	      

			cmp $0x0, %ecx                    # if all digits read, continue looping for the next digit
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
		
		movl %eax, PlaintextLength          # includes newline (Unclear how a newline is included)

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

		movl %eax, ShiftKeyLength           # includes newline (Unclear how a newline is included)
		
	callStringShiftKeytoInt:
		pushl $ShiftKey                      # passes the ShfitKey value to the stack
	
		call StringShiftKeytoInt  	     # calls the function to convert the string ShiftKey value to an hexadecimal value

		addl $4, %esp			     # adjust the stack pointer
		
	callCaesarCipher:
                pushl $Plaintext		     # Pushing Plaintext to stack
               
                pushl Conversion 	             # Pushing Conversion to stack

		call CaesarCipher	             # Call the Caesar Cipher funtion

                addl $8, %esp			    # adjust the stack pointer

	finish:
		# write system call 
		movl $4, %eax			   # syscall for write() 
		movl $1, %ebx			   # File descriptor for std_out
		movl $Ciphertext, %ecx		   # moves the address of the CiphertextPointer string into %ecx
		movl PlaintextLength, %edx         # moves the length of CiphertextLength var into %edx
		int $0x80			    # calls kernel		

		# Quit
                movl $1, %eax			# sys_exit
                movl $0, %ebx
                int $0x80			# calls kernel	
