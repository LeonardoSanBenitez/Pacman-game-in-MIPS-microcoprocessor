# --------------------------------------- #
#  Libraries
# --------------------------------------- #
.text 0x00500000
.include "staticGraphics.asm"
.include "drawning.asm"
#.include "exceptionHandler.asm"

# --------------------------------------------------- #
# Main
# --------------------------------------------------- #
.text 0x00400000
main:
        # Interrupt enable
	#li	$t0, 0xffff0000	# Mars keyboard and display base addr
	#li	$t1, 0x00000002	# interrupt enable
	#sw	$t1, 0($t0)	# keyboard
	#sw	$t1, 8($t0)	# display

        # Check display connection
        # ?

        # Read flags
        # ?

mainLoop:
        li      $a0, GRID_ROWS
        li      $a1, GRID_COLS
        la      $a2, grid
        jal     drawGrid

        # Delay
        li $v0, 32
        li $a0, 1	# 1ms
        syscall

        b mainLoop


# ------------------------------------------------------------------------------------------------- #
# INTERRUPT SERVICE ROUTINES
# ------------------------------------------------------------------------------------------------- #
# Optimization tip: here you dont need to restore saved register, because the OS already does that

# ISR0
# Caution: you cannot keep registers beetween calls
#variables map
  # s0 = Mars keyboard and display base addr
  # s1 = char (received by keyboad)
# Stack organization
  # |===========|
  # | empty     | 12 ($sp)
  # |-----------|
  # | $ra       | 8 ($sp)
  # |-----------|
  # | $a1       | 4 ($sp) (available for the next function)
  # |-----------|
  # | $a0       | 0 ($sp) (available for the next function)
  # |-----------|
ISR0:
	addi	$sp, $sp, -16	# create stack (4 bytes)
	sw	$ra, 8($sp)	# save ra

	li	$t0, 0xffff0000	# Mars keyboard and display base addr
	lw	$s1, 4 ($t0)	# s1 = char (received by keyboad)

        li      $t0, 97         # t0 = 'a'
        li      $t1, 77         # t1 = 'w'
        li      $t2, 100        # t2 = 'd'
        li      $t3, 115        # t3 = 's'
        li      $t4, 65         # t4 = 'A'
        li      $t5, 87         # t5 = 'W'
        li      $t6, 68         # t6 = 'D'
        li      $t7, 83         # t7 = 'S'
        li      $t8, 32         # t8 = ' '

	# if (char == 'a') flagLeft = 1
	# bne	$s1, $t0, ISR0end
	# la	$t1, flags
	# li	$t0, 1
	# sw	$t0, 0($t1)	# flagLeft = 1
ISR0end:
  	lw	$ra, 8($sp)	# restore ra
  	add	$sp, $sp, 16	# destroy stack (4 bytes)
	jr	$ra
