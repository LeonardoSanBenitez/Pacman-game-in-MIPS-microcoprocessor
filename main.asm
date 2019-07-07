# --------------------------------------- #
#  Libraries
# --------------------------------------- #
.text 0x00500000
.include "staticGraphics.asm"
.include "drawning.asm"
.include "exceptionHandler.asm"
.include "macros.asm"

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
ALLOC_AGENT (105, 105, 0, 0, TYPE_GHOST, 21)
ALLOC_AGENT (105, 119, 0, 0, TYPE_GHOST, 20)
ALLOC_AGENT (112, 112, 0, 0, TYPE_GHOST, 2)
ALLOC_AGENT (126, 112, 0, 0, TYPE_GHOST, 2)
ALLOC_AGENT (133, 105, 0, 0, TYPE_GHOST, 20)
ALLOC_AGENT (133, 119, 0, 0, TYPE_GHOST, 21)
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
# Stack organization
  # |===========|
  # | $a1       | 04 ($sp) (available to the next funtion)
  # | $a0       | 00 ($sp) (available to the next funtion)
  # |-----------|
.text 0x00400000
main:
	addi 	$sp, $sp, -8 	# Create stack (2 bytes)

        # Interrupt enable
	li	$t0, 0xffff0000	# Mars keyboard and display base addr
	li	$t1, 0x00000002	# interrupt enable
	sw	$t1, 0($t0)	# keyboard
	#sw	$t1, 8($t0)	# display

	# Draw initial grid
	li      $a0, GRID_ROWS
        li      $a1, GRID_COLS
        la      $a2, grid
        jal     drawGrid




	# la 	$t0, movementBuffer
	# li 	$t1, 1
	# sw 	$zero, 0($t0)
	# sw 	$t1, 4 ($t0)
	# sb 	$t1, 9 ($t0)

mainLoop:

	# TODO: verify FlagGameOver and goto mainFinish
	# TODO: verify flagPause and goto mainLoop

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

mainFinish:
	addi 	$sp, $sp, 8 	# Destroy stack (2 bytes)

	li	$v0, 17			# Service terminate
	li	$a0, 0			# Service parameter (termination result)
	syscall
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
  # | $a1       | 36 ($sp) (previous frame)
  # | $a0       | 32 ($sp) (previous frame)
  # |===========|
  # | empty     | 28 ($sp)
  # | $ra       | 24 ($sp)
  # | $s1       | 20 ($sp)
  # | $s0       | 16 ($sp)
  # | $a3       | 12 ($sp) (available to the next funtion)
  # | $a2       | 08 ($sp) (available to the next funtion)
  # | $a1       | 04 ($sp) (available to the next funtion)
  # | $a0       | 00 ($sp) (available to the next funtion)
  # |-----------|
# TODO: atualizar pseudo codigo
calculateMovements:
	addi    $sp, $sp, -32 	# Create stack (8 bytes)
	sw      $s0, 16($sp)
	sw      $s1, 20($sp)
	sw      $ra, 24($sp)

	move 	$s0, $a0	# s0 = &agent
	move 	$s1, $a1	# s1 = &movementBuffer
calculateMovementsLoop:
	lb 	$t9, 16($s0)	# type
	bne 	$t9, TYPE_GHOST, calculateMovementsPacman
		## Calculate Movements of Ghost
		# if (agent.movX == 0 AND agent.movY==0) go random
		lw 	$a2, 8($s0)	# a2 = agent.movX
		lw 	$a3, 12($s0)	# a3 = agent.movY
		bne	$a2, $zero, calculateMovementsGhostNormal
		bne	$a3, $zero, calculateMovementsGhostNormal
		j 	calculateMovementsGhostRandom
	calculateMovementsGhostNormal:
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

	calculateMovementsGhostVS:
		# Frontal visual search
		lw $a0, 0($s0)         # a0 = agent.x
		lw $a1, 4($s0)         # a0 = agent.y
		li 	$t0, 7#TODO
		div	$a0, $a0, $t0
		div	$a1, $a1, $t0
		lw 	$a2, 8($s0)	# a2 = agent.movX
		lw 	$a3, 12($s0)	# a3 = agent.movY
		add 	$a0, $a0, $a2
		add 	$a1, $a1, $a3



		# visualSeach (agent.x+agent.movX, agent.y+agent.movY, agent.movX, agent.movY)
		jal 	visualSearch
		move 	$s1, $v0 # s1 = type
		# if (dist==0 and type==wall) Change direction randomly
		bne 	$v1, $zero, calculateMovementsNext
		IS_WALL ($s1)
	        beq 	$v0, $zero, calculateMovementsNext     # if (checkWall == wall) Change direction

	calculateMovementsGhostRandom:
		# Change direction randomly
		# switch (rand){
		#   case 0: movX=0; movY=-1; break; // up
		#   case 1: movX=-1; movY=0; break; // left
	  	#   case 2: movX=0; movY=1; break;  // down
	  	#   case 3: movX=1; movY=0; break;  // right
	  	# }

		# impede iterações infinitas
		# 		addi 	$t8,$t8, 1
		# 		li 	$t0, 5
		# 		blt 	$t8, $t0, go_On
		# 		sw 	$zero, 8($s0)
		# 		sw 	$zero, 12($s0)
		# 		li 	$t8, 0
		# 		j 	calculateMovementsNext
		# 		go_On:

		li 	$v0, 42
		li 	$a2, 3
		syscall
		bne 	$a0, $zero, calculateMovementsGhostC1
		# rand = 0 = up
		li 	$t0, 0
		li 	$t1, -1
		sw 	$t0, 8($s0)
		sw 	$t1, 12($s0)
		j 	calculateMovementsGhostVS
	calculateMovementsGhostC1:
		addi 	$a0, $a0, -1
		bne 	$a0, $zero, calculateMovementsGhostC2
		# rand = 1 = left
		li 	$t0, -1
		li 	$t1, 0
		sw 	$t0, 8($s0)
		sw 	$t1, 12($s0)
		j 	calculateMovementsGhostVS
	calculateMovementsGhostC2:
		addi 	$a0, $a0, -1
		bne 	$a0, $zero, calculateMovementsGhostC3
		# rand = 2 = down
		li 	$t0, 0
		li 	$t1, 1
		sw 	$t0, 8($s0)
		sw 	$t1, 12($s0)
		j 	calculateMovementsGhostVS
	calculateMovementsGhostC3:
		# rand = 3 = right
		li 	$t0, 1
		li 	$t1, 0
		sw 	$t0, 8($s0)
		sw 	$t1, 12($s0)
		j 	calculateMovementsGhostVS

	calculateMovementsGhostRevert:
		# # else if (type==ghost AND dist<=3) Change revert direction
		# li 	$t0, 3
		# bgt 	$v1, $t0, calculateMovementsGhostSeek
		# IS_GHOST ($s1)
	        # beq 	$v0, $zero, calculateMovementsGhostSeek
		#
		# # Revert movement
		# lw 	$t0, 8($s0)
		# lw 	$t1, 12($s0)
		# li	$t2, -1
		# mul	$t0, $t0, $t2
		# mul	$t1, $t1, $t2
		# sw 	$t0, 8($s0)
		# sw 	$t1, 12($s0)
		# j 	calculateMovementsGhostVS
	calculateMovementsGhostSeek:
		# SEAK AND DESTROOOOYYYY

		j 	calculateMovementsNext

calculateMovementsPacman:
	bne 	$t9, TYPE_PACMAN, calculateMovementsScaredGhost
		## Calculate Movements of Pacman
		lw 	$t0, 0($s0)        	# t0 = agent.x
		lw 	$t1, 4($s0)        	# t1 = agent.y

		div 	$t2, $t0, X_SCALE	# t2 = agent.x/7
		mfhi	$t3			# t3 = agent.x%7
		div 	$t4, $t1, Y_SCALE	# t4 = agent.y/7
		mfhi	$t5			# t5 = agent.y%7

		# if (agent.x%7==0 and agent.y%7=0) Calculate movement
		bne	$t3, $zero, calculateMovementsNext
		bne	$t5, $zero, calculateMovementsNext

		## If movement is not possible, stop
		lw 	$a0, 8($s0)			# a0 = agent.movX
		lw 	$a1, 12($s0)			# a1 = agent.movY

		add 	$a0, $a0, $t2              	# a0 = agent.movX + agent.x/7
		add 	$a1, $a1, $t4              	# a1 = agent.movY + agent.y/7
		la  	$a2, grid
		jal 	gridGetID			# gridGetID (X, Y, &grid)
		IS_WALL ($v0)
		beqz 	$v0, calculateMovementsPacmanCheckBuffer     # if (checkWall == wall) stop

		sw 	$zero, 8($s0)                 	# agent.movX = 0
		sw 	$zero, 12($s0)                	# agent.movY = 0

	calculateMovementsPacmanCheckBuffer:
		## If movementBuffer is valid and possible, update agent movement vector
		lb 	$t9, 8($s1)
		beqz 	$t9, calculateMovementsNext     # if (movementBuffer.isValid == False) jump
		lw 	$a0, 0($s1)			# a0 = movementBuffer.x
		lw 	$a1, 4($s1)			# a1 = movementBuffer.y

		add 	$a0, $a0, $t2              	# a0 = movementBuffer.x + agent.x/7
		add 	$a1, $a1, $t4              	# a1 = movementBuffer.y + agent.y/7
		la  	$a2, grid
		jal 	gridGetID			# gridGetID (X, Y, &grid)
		IS_WALL ($v0)
		bnez 	$v0, calculateMovementsNext     # if (checkWall == wall) jump

		lw 	$t0, 0($s1)
		lw 	$t1, 4($s1)
		sw 	$t0, 8($s0)                 	# agent.movX = movementBuffer.x
		sw 	$t1, 12($s0)                	# agent.movY = movementBuffer.y
		sb 	$zero, 8($s1)               # clear movementBuffer.isValid
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
  # | $a0       | 32 ($sp) (previous frame)
  # |===========|
  # | empty     | 20 ($sp)
  # | $ra       | 16 ($sp)
  # | $s0       | 12 ($sp)
  # | $a2       | 08 ($sp) (available to the next funtion)
  # | $a1       | 04 ($sp) (available to the next funtion)
  # | $a0       | 00 ($sp) (available to the next funtion)
  # |-----------|
moveAgents:
	addi    $sp, $sp, -24 	# Create stack (6 bytes)
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

#===========================================
# FUNCTION int gridGetID (X,Y, *grid)
#===========================================
# Mult por linha, soma coluna, mult por 4 e soma com endere�o base
.globl gridGetID
gridGetID:
       addi $sp, $sp, -32
       sw $ra, 24($sp)
       sw $s0, 16($sp)
       sw $s1, 20($sp)

       move $s0, $a1	# s0 = Y
       move $s1, $a0	# s1 = X	#TODO: inversão zuada

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

#===========================================
# FUNCTION (type, dist) visualSeach (x, y, dirX, dirY)
#===========================================
# Brief: perform an recursive search in straigh line
# Pseudocode
  # id = gridGetID (x, y)
  # for each agent in agentsArray:
  #   if (agent.type == last) break
  #   if (agent.x%7==x AND agent.y%7==y) id=agent.sprite
  # if (id==wall OR id==ghost OR id==pacman)
  #   type = id
  #   dist = 0
  #   return (type, dist)
  # else
  #   (type, dist) = visualSeach (x+dirX, y+dirY, dirX, dirY)
  #   dist++
  #   return (type, dist)
# Variabes map
  # s0 = agent
  # s1 = ID
# Stack organization
  # | $a3       | 44 ($sp) (previous frame)
  # | $a2       | 40 ($sp) (previous frame)
  # | $a1       | 36 ($sp) (previous frame)
  # | $a0       | 32 ($sp) (previous frame)
  # |===========|
  # | empty     | 28 ($sp)
  # | $ra       | 24 ($sp)
  # | $s1       | 20 ($sp)
  # | $s0       | 16 ($sp)
  # | $a3       | 12 ($sp) (available to the next funtion)
  # | $a2       | 08 ($sp) (available to the next funtion)
  # | $a1       | 04 ($sp) (available to the next funtion)
  # | $a0       | 00 ($sp) (available to the next funtion)
  # |-----------|
#TODO: receber &grid e &agentsArray como parâmetros
visualSearch:
	addi    $sp, $sp, -32 	# Create stack (8 bytes)
	sw      $s0, 16($sp)
	sw      $s1, 20($sp)
	sw      $ra, 24($sp)

	# v0 = gridGetID (x, y)
	sw 	$a2, 40($sp)	# save a2
	la  	$a2, grid
	jal 	gridGetID
	move 	$s1, $v0	# save v0
	lw 	$a2, 40($sp)	# restore a2

	# for each agent in agentsArray:
	la 	$s0, agentsArray 	# s0 = &agent
visualSearchFor:
	lb 	$t0, 16 ($s0)
	beq 	$t0, TYPE_LAST, visualSearchForEnd
	#if (agent.x%7==x AND agent.y%7==y) id=agent.sprite
	lw 	$t0, 0($s0)
	li 	$t3, X_SCALE
	div 	$t0, $t0, $t3	# t0 = agent.x%7
	lw 	$t1, 4($s0)
	li 	$t4, Y_SCALE
	div 	$t1, $t1, $t4	# t1 = agent.x%7

	bne 	$t0, $a0, visualSearchForNext
	bne 	$t1, $a1, visualSearchForNext
	lb 	$s1, 17($s0)
	j 	visualSearchForEnd
visualSearchForNext:
	addi 	$s0, $s0, STRUCT_AGENT_SIZE
	j 	visualSearchFor
visualSearchForEnd:

	# if (id==wall OR id==ghost OR id==pac) goto stopCondition
	IS_WALL ($s1)
	bne  	$v0, $zero, visualSearchStopCondition
	IS_GHOST ($s1)
	bne  	$v0, $zero, visualSearchStopCondition
	IS_PACMAN ($s1)
	bne  	$v0, $zero, visualSearchStopCondition

	# visualSearchElse
	add 	$a0, $a0, $a2
	add 	$a1, $a1, $a3
	jal 	visualSearch
	addi 	$v1, $v1, 1
	j 	visualSearchReturn

visualSearchStopCondition:
	li 	$v1, 0
	move 	$v0, $s1

visualSearchReturn:
	lw      $s0, 16($sp)
	lw      $s1, 20($sp)
	lw      $ra, 24($sp)
	addi    $sp, $sp, 32 	# Destroy stack (8 bytes)

	jr 	$ra

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
  # | $ra       | 08 ($sp)
  # |-----------|
  # | $a1       | 04 ($sp) (available for the next function)
  # |-----------|
  # | $a0       | 00 ($sp) (available for the next function)
  # |-----------|
ISR0:
	addi	$sp, $sp, -16	# create stack (4 bytes)
	sw	$ra, 8($sp)	# save ra

	la 	$s0, movementBuffer
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

	# PROCESS KEYBOARD
	# if (char == 'a' or char == 'A'){
	#   movementBuffer.movX = -1
	#   movementBuffer.movY = 0
	#   movementBuffer.isValid = 1
	# }
	# if (char == 'w' or char == 'W') ...
	beq 	$s1, $t0, ISR0A
	beq 	$s1, $t4, ISR0A
	beq 	$s1, $t1, ISR0W
	beq 	$s1, $t5, ISR0W
	beq 	$s1, $t2, ISR0D
	beq 	$s1, $t6, ISR0D
	beq 	$s1, $t3, ISR0S
	beq 	$s1, $t7, ISR0S
	beq 	$s1, $t8, ISR0Space
	j 	ISR0end
ISR0A:
	li 	$t0, -1
	sw 	$t0, 0($s0)
	sw 	$zero, 4($s0)
	li 	$t2, 1
	sb 	$t2, 8($s0)
	j 	ISR0end
ISR0W:
	li 	$t1, -1
	sw 	$zero, 0($s0)
	sw 	$t1, 4($s0)
	li 	$t2, 1
	sb 	$t2, 8($s0)
	j 	ISR0end
ISR0D:
	li 	$t0, 1
	sw 	$t0, 0($s0)
	sw 	$zero, 4($s0)
	li 	$t2, 1
	sb 	$t2, 8($s0)
	j 	ISR0end
ISR0S:
	li 	$t1, 1
	sw 	$zero, 0($s0)
	sw 	$t1, 4($s0)
	li 	$t2, 1
	sb 	$t2, 8($s0)
	j 	ISR0end
ISR0Space:
	# TODO: set flag

ISR0end:
  	lw	$ra, 8($sp)	# restore ra
  	add	$sp, $sp, 16	# destroy stack (4 bytes)
	jr	$ra
