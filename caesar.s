.data

        HelloWorld:
                .asciz "Hello World!\n"
		lenHelloWorld = .-HelloWorld
.text

        .globl _start

        _start:

                movl $4, %eax
                movl $1, %ebx
                movl $HelloWorld, %ecx
                movl $lenHelloWorld, %edx
                int $0x80


                movl $1, %eax
                movl $0, %ebx
                int $0x80
