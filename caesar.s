.data

        HelloWorld:
                .asciz "Hello World!\n"
		lenHelloWorld = .-HelloWorld

	# plaintext prompt
	# plaintext prompt length

	# shift key prompt
	# shift key prompt length

.bss
	.comm ShiftKeyPointer, 4
	.comm ShiftKeyLength, 4

	.comm ShiftKeyInteger, 4
	.comm ShiftKeySize, 4	

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
			
		movl $4, %eax
		movl $1, %ebx
		movl $ShiftKeyPointer, %ecx
		movl $ShiftKeyLength, %edx
		int $0x80
		
		movl $0x0, %ecx
		movl $ShiftKeyPointer, %esi
	findEnd:
		lodsb    # into %al
		cmp $0x0a, %al
		jz done
		
		inc %ecx
		jmp findEnd 

	done:
		dec %esi  # off by one 
		std  # change direction
		lodsb  # skip over newline

	convertInt:
		lodsb   # into %al
		dec %ecx
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
