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
#ALLOC_AGENT (112, 112, 0, 0, TYPE_GHOST, 2)
#ALLOC_AGENT (126, 112, 0, 0, TYPE_GHOST, 2)
#ALLOC_AGENT (133, 105, 0, 0, TYPE_GHOST, 20)
#ALLOC_AGENT (133, 119, 0, 0, TYPE_GHOST, 21)
ALLOC_AGENT (007, 007, 0, 0, TYPE_LAST, 0)

# ------------- #
# struct movementBuffer {
#   word movX,		// 0(base)
#   word movY,		// 4(base)
#   byte isValid  	// 8(base)
# }
movementBuffer:
.align 2
.space 9 # 9 = 4+4+1

# ------------- #
# Global flags {
#   byte gamePaused,	// 0(base)
#   byte gameOver	// 1(base)
#   byte invencible 	// 2(base)
# }
globalFlags:
.space 3

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

mainLoop:
	# Check flag: gamePaused
	la 	$s0, globalFlags
	lb 	$t0, 0($s0)
	bne 	$t0, $zero, mainLoop # if (globalFlags.gamePaused == True) Jump

	# Check flag: gameOver
	lb 	$t0, 1($s0)
	bne 	$t0, $zero, mainFinish # if (globalFlags.gameOver == True) Jump

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
	# Draw final grid
	li      $a0, GRID_ROWS
	li      $a1, GRID_COLS
	la      $a2, grid2
	jal     drawGrid

	addi 	$sp, $sp, 8 	# Destroy stack (2 bytes)

	li	$v0, 17		# Service terminate
	li	$a0, 0		# Service parameter (termination result)
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
	move 	$a0, $s0
	jal 	agentCheckBounds

	lb 	$t9, 16($s0)	# type
	bne 	$t9, TYPE_GHOST, calculateMovementsPacman
		## Calculate Movements of Ghost

		# if (agent.x==pacman.x and agent.y==pacman.y) KILL PACMAN
		lw 	$t0, 0($s0)
		li	$t9, X_SCALE
		div	$t0, $t9	# t0 = agent.x
		lw 	$t1, 4($s0)
		li	$t9, Y_SCALE
		div	$t1, $t9	# t1 = agent.y
		la 	$s1, agentsArray
		lw 	$t2, 0($s1)
		li	$t9, X_SCALE
		div	$t2, $t9	# t2 = pacman.x
		lw 	$t3, 4($s1)
		li	$t9, Y_SCALE
		div	$t3, $t9	# t3 = pacman.y

		bne 	$t0, $t2, calculateMovementsGhostCheckMotion
		bne 	$t1, $t3, calculateMovementsGhostCheckMotion
		la 	$t0, globalFlags
		li 	$t1, 1
		sb 	$t1, 1($t0)

	calculateMovementsGhostCheckMotion:
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
		li 	$t0, X_SCALE
		div	$a0, $a0, $t0
		li 	$t0, Y_SCALE
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

	calculateMovementsPacmanAlive:
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
# FUNCTION void agentCheckBounds (&agent)
#===========================================
# Brief: used to allow "teletransportation"
# Pseudocode
  # if (agent.x<0) agent.x=245; redraw(agent.x, agent.y, gridGetID(agent.x, agent.y, &grid))
  # if (agent.x>245) agent.x=0; redraw(agent.x, agent.y, gridGetID(agent.x, agent.y, &grid))
  # if (agent.y<0) agent.y=245; redraw(agent.x, agent.y, gridGetID(agent.x, agent.y, &grid))
  # if (agent.y>245) agent.y=0; redraw(agent.x, agent.y, gridGetID(agent.x, agent.y, &grid))
# Stack organization
  # | $ra       | 20 ($sp)
  # | $t1       | 16 ($sp)
  # | $t0       | 12 ($sp)
  # | $a2       | 08 ($sp) (available to the next funtion)
  # | $a1       | 04 ($sp) (available to the next funtion)
  # | $a0       | 00 ($sp) (available to the next funtion)
  # |-----------|
agentCheckBounds:
	lw 	$t0, 0($a0)	# x
	lw 	$t1, 4($a0)	# y
	li 	$t2, 238

	ble 	$t0, $zero, agentCheckBoundsX1
	bge 	$t0, $t2, agentCheckBoundsX2
	ble 	$t1, $zero, agentCheckBoundsY1
	bge 	$t1, $t2, agentCheckBoundsY2
	j 	agentCheckBoundsEnd
agentCheckBoundsX1:
	sw 	$t2, 0($a0)
	j 	agentCheckBoundsRedraw
agentCheckBoundsX2:
	sw 	$zero, 0($a0)
	j 	agentCheckBoundsRedraw
agentCheckBoundsY1:
	sw 	$t2, 4($a0)
	j 	agentCheckBoundsRedraw
agentCheckBoundsY2:
	sw 	$zero, 4($a0)
	j 	agentCheckBoundsRedraw
agentCheckBoundsRedraw:
	# The stack is done only here for optimization pourpouses
	addi 	$sp, $sp, -24
	sw 	$t0, 12($sp)
	sw 	$t1, 16($sp)
	sw 	$ra, 20($sp)

	li 	$t9, X_SCALE
	div 	$a0, $t0, $t9
	li 	$t9, Y_SCALE
	div 	$a1, $t1, $t9
	la 	$a2, grid
	jal 	gridGetID
	lw 	$a0, 12($sp)
	lw 	$a1, 16($sp)
	move 	$a2, $v0
	jal 	drawSprite
	lw 	$ra, 20($sp)
	addi 	$sp, $sp, 24
agentCheckBoundsEnd:
	jr 	$ra

#===========================================
# FUNCTION void moveAgents (&agentsArray)
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
	# TODO: preciso redesenhar o sprite atual antes de move-lo para a proxima posição
	lb 	$t0, 16($s0)	# load type
	beq 	$t0, TYPE_LAST, moveAgentsEnd

	lw 	$a0, 0($s0)	# load posX
	lw 	$a1, 4($s0)	# load posY
	li 	$t9, X_SCALE
	div 	$a0, $a0, $t9
	li 	$t9, Y_SCALE
	div 	$a1, $a1, $t9
	la 	$a2, grid
	jal 	gridGetID
	lw 	$a0, 0($s0)	# load posX
	lw 	$a1, 4($s0)	# load posY
	lw 	$t0, 8($s0)	# load movX
	lw 	$t1, 12($s0)	# load movY

	FLOOR($a0, X_SCALE)
	FLOOR($a1, X_SCALE)
	move 	$a2, $v0
	blt 	$t0, $zero, moveAgentsDrawBackgroundLeft 	# agent moving to the left
	bgt 	$t0, $zero, moveAgentsDrawBackgroundRight	# agent moving to the right
	blt 	$t1, $zero, moveAgentsDrawBackgroundUp		# agent moving to the top
	bgt 	$t1, $zero, moveAgentsDrawBackgroundDown	# agent moving to the bottom
	j 	moveAgentsDrawAgent				# not moving

moveAgentsDrawBackgroundLeft:
	addi 	$a0, $a0, 7
	jal 	drawSprite
	j 	moveAgentsDrawAgent
moveAgentsDrawBackgroundUp:
	addi 	$a1, $a1, 7
	jal 	drawSprite
	j 	moveAgentsDrawAgent
moveAgentsDrawBackgroundRight:
	jal 	drawSprite
	j 	moveAgentsDrawAgent
moveAgentsDrawBackgroundDown:
	jal 	drawSprite
	j 	moveAgentsDrawAgent

moveAgentsDrawAgent:
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
# Brief: return the element (X,Y) from the grid
.globl gridGetID
gridGetID:
        mulu 	$a1, $a1, GRID_COLS 	# y *= 35
        add 	$a0, $a0, $a1		# a0 = X + 35Y
        add  	$a0,$a0, $a2		# a0 = &grid + X + 35Y
        lb   	$a0, 0($a0)		# load from (&grid + X + 35Y)
        addi 	$v0, $a0, -64		# convert ascii to ID
        jr 	$ra			# return ID

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
	sw 	$a0, 32($sp)	# save a0
	sw 	$a1, 36($sp)	# save a1
	sw 	$a2, 40($sp)	# save a2
	la  	$a2, grid
	jal 	gridGetID
	move 	$s1, $v0	# save v0
	lw 	$a0, 32($sp)	# restore a0
	lw 	$a1, 36($sp)	# restore a1
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
# Pseudocode
  # char = readKeyboard()
  # if (char == 'a' or char == 'A'){
  #   movementBuffer.movX = -1
  #   movementBuffer.movY = 0
  #   movementBuffer.isValid = 1
  # }
  # if (char == 'w' or char == 'W') ...
ISR0:
	addi	$sp, $sp, -16	# create stack (4 bytes)
	sw	$ra, 8($sp)	# save ra

	la 	$s0, movementBuffer
	li	$t0, 0xffff0000	# Mars keyboard and display base addr
	lw	$s1, 4 ($t0)	# s1 = char (received by keyboad)

        li      $t0, 97         # t0 = 'a'
        li      $t1, 119         # t1 = 'w'
        li      $t2, 100        # t2 = 'd'
        li      $t3, 115        # t3 = 's'
        li      $t4, 65         # t4 = 'A'
        li      $t5, 87         # t5 = 'W'
        li      $t6, 68         # t6 = 'D'
        li      $t7, 83         # t7 = 'S'
        li      $t8, 32         # t8 = ' '

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
	la 	$t0, globalFlags
	lb 	$t1, 0($t0)
	not	$t1, $t1
	sb 	$t1, 0($t0) # globalFlags.gamePaused = ~globalFlags.gamePaused
ISR0end:
  	lw	$ra, 8($sp)	# restore ra
  	add	$sp, $sp, 16	# destroy stack (4 bytes)
	jr	$ra
