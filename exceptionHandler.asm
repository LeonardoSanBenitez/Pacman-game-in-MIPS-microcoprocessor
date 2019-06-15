#-----------------------------------------------#
# Exception Handler
#-----------------------------------------------#
# Esse código tá meio assombrado
# não executa a instrução quando volta
# caga o display (no pixel da interrupção)
# aparantemente não está restarando o t0
.kdata
EcpH:	.asciiz "\nException: \n"
.align 2
EcpR:	.space 128	# space to save registers
# Jump Table
EcpJT: .word Ecp0, Ecpd, Ecpd, Ecpd, Ecp4, Ecp5, Ecp6, Ecp7, Ecp8, Ecp9, Ecp10, Ecpd, Ecp12, Ecp13, Ecpd, Ecp15
# Names of the exceptions
EcpN0: .asciiz "INT"		# hardware Interrupt
EcpN4: .asciiz "ADDRL"		# Addres error exeption caused by load or instruction fetch
EcpN5: .asciiz "ADDRS"		# Addres error exeption caused by store
EcpN6: .asciiz "IBUS"		# Bus error or instruction fetch
EcpN7: .asciiz "DBUS"		# Bus error on data load or Store
EcpN8: .asciiz "SYSCALL"	# Sistem call (caused by Syscall instruction)
EcpN9: .asciiz "BKPT"		# breakpoint (caused by Break instruction)
EcpN10: .asciiz "RI"		# Reserved Instruction
EcpN12: .asciiz "OVF"		# Arithmetic overflow
EcpN13: .asciiz "TRAP"		# Trap Exception (caused by Trap instruction)
EcpN15: .asciiz "FPE"		# Floating point exception (caused by floating point instruction)
EcpNd:	.asciiz "Unknown"	# Default state


.ktext 0x80000180
	# Save registers
	move	$k0, $at	# $k0 = $at
	la	$k1, EcpR	# $k1 = address of ExceptionRegisters
	sw	$zero, 0($k1)
	sw	$k0, 4($k1)	# save $at (register 1)
	sw	$2, 8($k1)
	sw	$3, 12($k1)
	sw	$4, 16($k1)
	sw	$5, 20($k1)
	sw	$6, 24($k1)
	sw	$7, 28($k1)
	sw	$8, 32($k1)
	sw	$9, 36($k1)
	sw	$10, 40($k1)
	sw	$11, 44($k1)
	sw	$12, 48($k1)
	sw	$13, 52($k1)
	sw	$14, 56($k1)
	sw	$15, 60($k1)
	sw	$16, 64($k1)
	sw	$17, 68($k1)
	sw	$18, 72($k1)
	sw	$19, 76($k1)
	sw	$20, 80($k1)
	sw	$21, 84($k1)
	sw	$22, 88($k1)
	sw	$23, 92($k1)
	sw	$24, 96($k1)
	sw	$25, 100($k1)
	sw	$26, 104($k1)
	sw	$27, 108($k1)
	sw	$28, 112($k1)
	sw	$29, 116($k1)
	sw	$30, 120($k1)
	sw	$31, 124($k1)

	la	$a0, EcpH	# Service print string (header)
	li	$v0, 4     	# Service parameter (address of string)
	syscall

	mfc0	$s0, $13	# Take cause register
	srl	$s0, $s0, 2
	andi	$s0, $s0, 0xf # s0 = cause

	## Swicth (s0){case 1: ...}
	#check bounds
	blt $s0, $zero Ecpd	# if read>=0, default
	addi $t0, $zero, 15
	bgt $s0, $t0, Ecpd	# if read>15, default

	#translate case
	la $t0, EcpJT		# Jump table base addr
	mul $t1, $s0, 4		# convert s0 to bytes
	add $t0, $t0, $t1	# t0 = &JumTable[cause]
	lw $t2, 0 ($t0)
	jr $t2

# Case 0 (interrupt handler)
# To change the interrupt priority, change the order on the code
# Disable nested interrupts???
Ecp0:
	addi	$v0, $zero, 4	# print string service
	la	$a0, EcpN0	# service parameter
	syscall
	mfc0	$s0, $13	# Take cause register

	Ecp0a: # Exception 0 (keyboard, in Mars)
		andi	$s1, $s0, 0x00000100	# take interrupt bit
		beq	$s1, $zero, Ecp0b
		andi	$s1, $s0, 0xfffffeff	# clear interrupt bit
		mtc0	$s1, $13		# store cleared bit in $cause
		la	$t3, ISR0
		jalr	$t3			# void ISRn()
		j	EcpOut
	Ecp0b: # Exception 1 (display, in Mars)
		# andi	$s1, $s0, 0x00000200 # take interrupt bit
		# beq	$s1, $zero, Ecp0c
		# andi	$s1, $s0, 0xfffffdff	# clear interrupt bit
		# mtc0	$s1, $13	# store cleared bit in $cause
		# la	$t3, ISR1
		# jalr	$t3				# void ISRn()
		j	EcpOut
	Ecp0c:
		j	EcpOut
# Case 4
Ecp4:
	addi	$v0, $zero, 4	# print string service
	la	$a0, EcpN4	# service parameter
	syscall

	j	EcpFinish
# Case 5
Ecp5:
	addi	$v0, $zero, 4	# print string service
	la	$a0, EcpN5	# service parameter
	syscall

	j	EcpFinish
# Case 6
Ecp6:
	addi	$v0, $zero, 4	# print string service
	la	$a0, EcpN6	# service parameter
	syscall

	j	EcpFinish
# Case 7
Ecp7:
	addi	$v0, $zero, 4	# print string service
	la	$a0, EcpN7	# service parameter
	syscall

	j	EcpFinish
# Case 8
Ecp8:
	addi	$v0, $zero, 4	# print string service
	la	$a0, EcpN8	# service parameter
	syscall

	j	EcpFinish
# Case 9
Ecp9:
	addi	$v0, $zero, 4	# print string service
	la	$a0, EcpN9	# service parameter
	syscall

	j	EcpFinish
# Case 10
Ecp10:
	addi	$v0, $zero, 4	# print string service
	la	$a0, EcpN10	# service parameter
	syscall

	j	EcpFinish
# Case 12
Ecp12:
	addi	$v0, $zero, 4	# print string service
	la	$a0, EcpN12	# service parameter
	syscall

	j	EcpFinish
# Case 13
Ecp13:
	addi	$v0, $zero, 4	# print string service
	la	$a0, EcpN13	# service parameter
	syscall

	j	EcpFinish
# Case 15
Ecp15:
	addi	$v0, $zero, 4	# print string service
	la	$a0, EcpN15	# service parameter
	syscall

	j	EcpFinish
# Case default
Ecpd:
	addi	$v0, $zero, 4	# print string service
	la	$a0, EcpNd	# service parameter
	syscall
# End of Switch case

EcpFinish:
	# Finish program
	li	$v0, 17			# Service terminate
	li	$a0, 0			# Service parameter (termination result)
	syscall

EcpOut:
	# Restore registers
	la	$k1, EcpR # $k1 = address of ExceptionRegisters
	lw	$0, 0($k1)
	lw	$1, 4($k1)
	lw	$2, 8($k1)
	lw	$3, 12($k1)
	lw	$4, 16($k1)
	lw	$5, 20($k1)
	lw	$6, 24($k1)
	lw	$7, 28($k1)
	lw	$8, 32($k1)
	lw	$9, 36($k1)
	lw	$10, 40($k1)
	lw	$11, 44($k1)
	lw	$12, 48($k1)
	lw	$13, 52($k1)
	lw	$14, 56($k1)
	lw	$15, 60($k1)
	lw	$16, 64($k1)
	lw	$17, 68($k1)
	lw	$18, 72($k1)
	lw	$19, 76($k1)
	lw	$20, 80($k1)
	lw	$21, 84($k1)
	lw	$22, 88($k1)
	lw	$23, 92($k1)
	lw	$24, 96($k1)
	lw	$25, 100($k1)
	lw	$26, 104($k1)
	lw	$27, 108($k1)
	lw	$28, 112($k1)
	lw	$29, 116($k1)
	lw	$30, 120($k1)
	lw	$31, 124($k1)

	# Exception Return
 	mfc0	$k0, $14 	# $k0 = EPC
 	addiu	$k0, $k0, 4	# Increment $k0 by 4
 	mtc0	$k0, $14	# EPC = point to next instruction
 	eret
