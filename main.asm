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

# ------------- #
# Struct agent {
#   word posX,		// 0 (base)
#   word posY,		// 4 (base)
#   word movX,		// 8 (base)
#   word movY		// 12 (base)
#   byte type,		// 16 (base)
#   byte sprite,	// 17 (base)
# }
.macro	ALLOC_AGENT (%posX, %posY, %movX, %movY, %type, %sprite)
.data
.align 2
	.word %posX, %posY, %movX, %movY
	.byte %type, %sprite
.end_macro

.eqv	STRUCT_AGENT_SIZE 	20
.eqv	TYPE_PACMAN		0
.eqv	TYPE_GHOST		1
.eqv	TYPE_SCARED_GHOST	2
.eqv	TYPE_LAST		9

# ------------- #
# agent agentsArray[] = ALLOC_AGENT(), ...
.data
agentsArray:
ALLOC_AGENT (119, 140, 0, 0, TYPE_PACMAN, 3)
ALLOC_AGENT (105, 105, 0, 1, TYPE_GHOST, 21)
#ALLOC_AGENT (105, 119, 0, 0, TYPE_GHOST, 20)
#ALLOC_AGENT (112, 112, 0, 0, TYPE_GHOST, 2)
#ALLOC_AGENT (126, 112, 0, 0, TYPE_GHOST, 2)
#ALLOC_AGENT (133, 105, 0, 0, TYPE_GHOST, 20)
#ALLOC_AGENT (133, 119, 0, 0, TYPE_GHOST, 21)
ALLOC_AGENT (000, 000, 0, 0, TYPE_LAST, 0)

# ------------- #
# struct movementBuffer {
#   word movX,		// 0(base)
#   word movY,		// 4(base)
#   byte isValid  	// 8(base)
# }
movementBuffer:
.align 2
.space 9 # 9 = 4+4+1

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
	la 	$a0, agentsArray
	la 	$a1, movementBuffer
	jal 	calculateMovements

	la 	$a0, agentsArray
	jal 	moveAgents

        # Delay (in ms)
        li $v0, 32
        li $a0, 30
        syscall

        b mainLoop

#=================================================================
# FUNCTION void calculateMovements (*agentsArray, *movementBuffer)
#=================================================================
# Brief: calculate the next movent of all agents (AI controled and used controled)
# Pseudocode
  # for each agent in agentsArray:
  #   if (agent.type == ghost){
  #     if (posX%7==0 and posY%7==0) revert movement
  #   } else if (agent.type == pacman){
  #     read movementBuffer
  #     check wall
  #     agent.posX = agent.posX + buffer.movX
  #     agent.posY = agent.posY + buffer.movY
  #   } else if (agent.type == scaredGhost){
  #     run away from pacman
  #   }
# Stack organization
  # |===========|
  # | empty     | 28 ($sp)
  # | $ra       | 24 ($sp)
  # | $s1       | 20 ($sp)
  # | $s0       | 16 ($sp)
  # | $a3       | 12 ($sp) (available to the next funtion)
  # | $a2       | 8 ($sp) (available to the next funtion)
  # | $a1       | 4 ($sp) (available to the next funtion)
  # | $a0       | 0 ($sp) (available to the next funtion)
  # |-----------|
calculateMovements:
	addi    $sp, $sp, -32 	# Create stack (8 bytes)
	sw      $a0, 0($sp)
	sw      $a1, 4($sp)
	sw      $a2, 8($sp)
	sw      $a3, 12($sp)
	sw      $s0, 16($sp)
	sw      $s1, 20($sp)
	sw      $ra, 24($sp)

	move 	$s0, $a0	# s0 = &agent
	move 	$s1, $a1	# s1 = &movementBuffer
calculateMovementsLoop:
	lb 	$t9, 16($s0)	# type
	bne 	$t9, TYPE_GHOST, calculateMovementsPacman
		## Calculate Movements of Ghost
		# if (posX%7==0 and posY%7==0) Calculate movement
		lw 	$t0, 4($s0)
		li	$t1, Y_SCALE
		div	$t0, $t1
		mfhi	$t0
		bne	$t0, $zero, calculateMovementsNext
		lw 	$t0, 0($s0)
		li	$t1, X_SCALE
		div	$t0, $t1
		mfhi	$t0
		bne	$t0, $zero, calculateMovementsNext

		# checkWall
		lw $a0, 0($s0)         # a0 = agent.x
		lw $a1, 4($s0)         # a0 = agent.y
		li 	$t0, 7
		div	$a0, $a0, $t0
		div	$a1, $a1, $t0
		la  $a2, grid
	        jal return_wall
	        beq $v0, $zero, calculateMovementsNext     # if (checkWall == wall) keep running; else revert

		# Revert movement
		lw 	$t0, 8($s0)
		lw 	$t1, 12($s0)
		li	$t2, -1
		mul	$t0, $t0, $t2
		mul	$t1, $t1, $t2
		sw 	$t0, 8($s0)
		sw 	$t1, 12($s0)

		# future AI:
		# call visualSearch (agent.posX, agent.posY, 0, 1) ...
		# call visualSearch (agent.posX, agent.posY, 0, -1) ...
		# call visualSearch (agent.posX, agent.posY, 1, 0) ...
		# call visualSearch (agent.posX, agent.posY, -1, 0) ...

		j 	calculateMovementsNext

calculateMovementsPacman:
	bne 	$t9, TYPE_PACMAN, calculateMovementsScaredGhost
		#### <doesNotTested>
		## PACMAN MOVEMENT HERE
		# la $t0, mov_buf
		# lw $t1, 0($t0)
		# beqz $t1, skip_update_move     # if (mov_buf.isValid == False) jump
		# lw $a0, 4($t0)         # a0 = mov_buf.x
		# lw $a1, 8($t0)         # a1 = mov_buf.y
		#
		# lw $t1, 4($s0)         # t1 = agent.x
		# lw $t2, 8($s0)         # t2 = agent.y
		#
		# div $t3, $t1, 7        # t3 = agent.x/7 (integer)
		# mfhi $t4
		# div $t5, $t2, 7        # t5 = agent.y/7 (integer)
		# mfhi $t6
		#
		# bnez $t4, skip_update_move     # if (agent.x%7 != 0 || agent.y%7 != 0) jump
		# bnez $t6, skip_update_move
		# add $a0, $a0, $t3              # a0 = mov_buf.x + agent.x/7 (integer)
		# add $a1, $a1, $t5              # a1 = mov_buf.y + agent.y/7 (integer)
		# la  $a2, grid
		# jal return_wall
		# bnez $v0, skip_update_move     # if (checkWall == wall) jump
		# la $t0, mov_buf
		# lw $a0, 4($t0)
		# lw $a1, 8($t0)
		# sw $a0, 12($s0)                # agent.movX = mov_buf.x
		# sw $a1, 16($s0)                # agent.movY = mov_buf.y
		# sw $zero, 0($t0)               # clear mov_buf.isValid
		#
		# skip_update_move:

		#### </doesNotTested>
		j 	calculateMovementsNext
calculateMovementsScaredGhost:
	bne 	$t9, TYPE_SCARED_GHOST, calculateMovementsEnd
		####
		## SCARED GHOST MOVEMENT HERE
		## The ghost will be scared when Pacman is invencible
		####
calculateMovementsNext:
	addi 	$s0, $s0, STRUCT_AGENT_SIZE
	j 	calculateMovementsLoop

calculateMovementsEnd:
	lw      $a0, 0($sp)
	lw      $a1, 4($sp)
	lw      $a2, 8($sp)
	lw      $a3, 12($sp)
	lw      $s0, 16($sp)
	lw      $s1, 20($sp)
	lw      $ra, 24($sp)
	addi    $sp, $sp, 32 	# Destroy stack (8 bytes)

	jr 	$ra

#===========================================
# FUNCTION void moveAgents (agentsArray)
#===========================================
# Brief: update positions and draw all the agents
# Pseudocode
  # for each agent in agentsArray:
  #   agent.posX = agent.posX + agent.movX
  #   agent.posX = agent.posX + agent.movX
  #   draw (agent.posX, agent.posY, agent.sprite)
# Stack organization
  # |===========|
  # | empty     | 20 ($sp)
  # | $ra       | 16 ($sp)
  # | $s0       | 12 ($sp)
  # | $a2       | 8 ($sp) (available to the next funtion)
  # | $a1       | 4 ($sp) (available to the next funtion)
  # | $a0       | 0 ($sp) (available to the next funtion)
  # |-----------|
moveAgents:
	addi    $sp, $sp, -24 	# Create stack (6 bytes)
	sw      $a0, 0($sp)
	sw      $a1, 4($sp)
	sw      $a2, 8($sp)
	sw      $s0, 12($sp)
	sw      $ra, 16($sp)

	move 	$s0, $a0	# s0 = &agent
moveAgentsLoop:
	# TODO: para os fantasas, preciso redesenhar o sprite atual antes de move-lo para a proxima posição
	lb 	$t0, 16($s0)	# load type
	beq 	$t0, TYPE_LAST, moveAgentsEnd
	lb 	$a2, 17($s0)	# load sprite
	lw 	$a0, 0($s0)	# load posX
	lw 	$a1, 4($s0)	# load posY
	lw 	$t0, 8($s0)	# load movX
	lw 	$t1, 12($s0)	# load movY
	add 	$a0, $a0, $t0
	add 	$a1, $a1, $t1
	sw 	$a0, 0($s0)	# agent.posX = agent.posX + agent.movX
	sw 	$a1, 4($s0)	# agent.posX = agent.posX + agent.movX

	jal 	drawSprite	# draw (agent.posX, agent.posY, agent.sprite)
	addi 	$s0, $s0, STRUCT_AGENT_SIZE	# agent++
	j 	moveAgentsLoop
moveAgentsEnd:
	sw      $a0, 0($sp)
	sw      $a1, 4($sp)
	sw      $a2, 8($sp)
	lw      $s0, 12($sp)
	lw      $ra, 16($sp)
	addi    $sp, $sp, 24 	# Destroy stack (6 bytes)

	jr 	$ra

####### <doesNotTested>
# (X,Y, *gride)
# Mult por linha, soma coluna, mult por 4 e soma com endere�o base
.globl return_id
return_id:
       addi $sp, $sp, -32
       sw $ra, 24($sp)
       sw $s0, 16($sp)
       sw $s1, 20($sp)

       move $s0, $a1	# s0 = Y
       move $s1, $a0	# s1 = X

       mulu $s0, $s0, GRID_COLS # s0 *= 35
       add $s1, $s1, $s0
       add  $s1,$s1, $a2
       lb   $s1, 0($s1)		# load from (&grid + X + 35Y)
       addi $v0, $s1, -64

       lw $ra, 24($sp)
       lw $s0, 16($sp)
       lw $s1, 20($sp)

       addi $sp, $sp, 32
       jr $ra
#---------------------------------------------------
#Return_wall
# (X,Y, *gride)
# return true if that position is a wall
.globl return_wall
return_wall:
       addi $sp, $sp, -24
       sw $ra, 16($sp)

       jal return_id
       bge $v0, 5, ret_true
ret_11:
       li $v0, 0
       b endd

ret_true:
      # beq $v0, 20, ret_11
       li $v0, 1
endd:
       lw $ra, 16($sp)



       addi $sp, $sp, 24
       jr $ra
####### </doesNotTested>

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

	# PROCESS KEYBOARD HERE
	# if (char == 'a' or char == 'A'){
	#   movementBuffer.movX = -1
	#   movementBuffer.movY = 0
	#   movementBuffer.isValid = 1
	# }
	# if (char == 'w' or char == 'W') ...
ISR0end:
  	lw	$ra, 8($sp)	# restore ra
  	add	$sp, $sp, 16	# destroy stack (4 bytes)
	jr	$ra
