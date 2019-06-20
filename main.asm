# --------------------------------------- #
#  Libraries
# --------------------------------------- #
.text 0x00500000
.include "staticGraphics.asm"
.include "drawning.asm"
.include "exceptionHandler.asm"

# --------------------------------------- #
#  Global data
# --------------------------------------- #

##################
# Struct agent {
#   word posX,		// 0 (base)
#   word posY,		// 4 (base)
#   word movX,		// 8 (base)
#   word movY		// 12 (base)
#   byte type,		// 16 (base)
#   byte sprite,	// 17 (base)
# }
.eqv	STRUCT_AGENT_SIZE 20
.eqv	TYPE_PACMAN	15
.eqv	TYPE_GHOST	1
.eqv	TYPE_LAST	2

.macro	ALLOC_AGENT (%posX, %posY, %movX, %movY, %type, %sprite)
.data
.align 2
	.word %posX, %posY, %movX, %movY
	.byte %type, %sprite
.end_macro


.data
agentsArray:
.align 0
ALLOC_AGENT (100, 100, 0, 1, TYPE_PACMAN, 3)
ALLOC_AGENT (100, 107, 0, 1, TYPE_GHOST, 2)
ALLOC_AGENT (100, 114, 0, 1, TYPE_GHOST, 20)
ALLOC_AGENT (100, 121, 0, 1, TYPE_GHOST, 2)
ALLOC_AGENT (100, 128, 0, 1, TYPE_GHOST, 21)
ALLOC_AGENT (100, 135, 0, 1, TYPE_GHOST, 20)
ALLOC_AGENT (100, 142, 0, 1, TYPE_GHOST, 21)
ALLOC_AGENT (000, 000, 0, 0, TYPE_LAST, 0)

# --------------------------------------------------- #
# Main
# --------------------------------------------------- #
# TODO: main stack
.text 0x00400000
main:
        # Interrupt enable
	li	$t0, 0xffff0000	# Mars keyboard and display base addr
	li	$t1, 0x00000002	# interrupt enable
	sw	$t1, 0($t0)	# keyboard
	#sw	$t1, 8($t0)	# display

        # Check display connection
        # ?

        # Read flags
        # ?

	# Draw initial grid
	li      $a0, GRID_ROWS
        li      $a1, GRID_COLS
        la      $a2, grid
        jal     drawGrid

mainLoop:

	# calculateMovements
	la 	$s0, agentsArray # s0 = agent
calculateMovementsLoop:
	lb 	$s1, 16($s0)	# type
	beq 	$s1, TYPE_LAST, calculateMovementsEnd


	lw 	$t0, 4($s0)	# just in grid
	li	$t1, Y_SCALE
	div	$t0, $t1
	mfhi	$t0
	bne	$t0, $zero, calculateMovementsEnd

	lw 	$t0, 8($s0)
	lw 	$t1, 12($s0)
	li	$t2, -1
	mul	$t0, $t0, $t2
	mul	$t1, $t1, $t2

	sw 	$t0, 8($s0)
	sw 	$t1, 12($s0)


	addi 	$s0, $s0, STRUCT_AGENT_SIZE
	j 	calculateMovementsLoop
calculateMovementsEnd:



# moveAgents
# Brief: update positions and draw all the agents
# Pseudocode
  # for each agent in agentsArray:
  #   agent.posX = agent.posX + agent.movX
  #   agent.posX = agent.posX + agent.movX
  #   draw (agent.posX, agent.posY, agent.sprite)
	la 	$s0, agentsArray # s0 = agent
moveAgentsLoop:
	lb 	$t0, 16($s0)	# type
	beq 	$t0, TYPE_LAST, moveAgentsEnd
	lb 	$a2, 17($s0)	# sprite
	lw 	$a0, 0($s0)
	lw 	$a1, 4($s0)
	lw 	$t0, 8($s0)
	lw 	$t1, 12($s0)
	add 	$a0, $a0, $t0
	add 	$a1, $a1, $t1
	sw 	$a0, 0($s0)
	sw 	$a1, 4($s0)

	jal 	drawSprite
	addi 	$s0, $s0, STRUCT_AGENT_SIZE

	j 	moveAgentsLoop
moveAgentsEnd:

        # Delay (in ms)
        li $v0, 32
        li $a0, 30
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
	# sw	$t0, 0($t1)	# flagLeft = 1m
ISR0end:
  	lw	$ra, 8($sp)	# restore ra
  	add	$sp, $sp, 16	# destroy stack (4 bytes)
	jr	$ra
