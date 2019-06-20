#===========================================
# FUNCTION void drawGrid (int width, int height, *gridTable)
#===========================================
# Variables map
  # s0 = x
  # s1 = width (x max)
  # s2 = y
  # s3 = height (y max)
  # s4 = i (grid inner counter)
# Pseudo code
  # i = gridTable
  # for (y=0; y<height; y++)
  #   for (x=0, x<width; x++)
  #     sprite = *(i++)
  #     drawSprite (x*7, y*7, sprite)
.text
.globl drawGrid
drawGrid:
        # Init stack
        addi    $sp, $sp, -40 # Create stack (10 bytes)
        sw      $a0, 0($sp)
        sw      $a1, 4($sp)
        sw      $a2, 8($sp)
        sw      $s0, 12($sp)
        sw      $s1, 16($sp)
        sw      $s2, 20($sp)
        sw      $s3, 24($sp)
        sw      $s4, 28($sp)
        sw      $ra, 32($sp)

        # Init local variables
        move    $s1, $a0
        li      $s2, 0
        move    $s3, $a1
        move    $s4, $a2
drawGridForY:
        bge     $s2, $s3, drawGridForYend
        li      $s0, 0
drawGridForX:
	# Read and translate sprite
	lb	$t0, 0($s4)
	addi	$a2, $t0, -64

	# call drawSprite
        bge     $s0, $s1, drawGridForXend
        mul	$a0, $s0, X_SCALE
        mul	$a1, $s2, Y_SCALE
        jal	drawSprite      # drawSprite (x*7, y*7, sprite)

        addi    $s0, $s0, 1     # x++
        addi	$s4, $s4, 1	# i++
        j       drawGridForX
drawGridForXend:
        addi    $s2, $s2, 1     # y++
        j       drawGridForY
drawGridForYend:
        # Restore stack
        lw      $a0, 0($sp)
        lw      $a1, 4($sp)
        lw      $a2, 8($sp)
        lw      $s0, 12($sp)
        lw      $s1, 16($sp)
        lw      $s2, 20($sp)
        lw      $s3, 24($sp)
        lw      $s4, 28($sp)
        lw      $ra, 32($sp)
        addi    $sp, $sp, 40    # Destroy stack (10 bytes)

        jr	$ra

#===========================================
# FUNCTION void drawSprite (x0, y0, sprite_id)
#===========================================
# Variables map
  # s0 = x
  # s1 = xMax
  # s2 = y
  # s3 = yMax
  # s4 = i (sprite inner counter)
# Pseudo code
  # i = &sprites + sprite_id*SPRITE_SIZE
  # for (y = y0; y < (y0+7); y++)
  #   for (x = x0; x < (x0+7); x++)
  #      color = translateColor (*i)
  #      drawPixel (x, y, color)
  #      i++
# Stack organization
  # |===========|
  # | empty     | 36 ($sp)
  # | $ra       | 32 ($sp)
  # | $s4       | 28 ($sp)
  # | $s3       | 24 ($sp)
  # | $s2       | 20 ($sp)
  # | $s1       | 16 ($sp)
  # | $s0       | 12 ($sp)
  # | $a2       | 8 ($sp)
  # | $a1       | 4 ($sp)
  # | $a0       | 0 ($sp)
  # |-----------|
.globl drawSprite
drawSprite:
        # Init stack
        addi    $sp, $sp, -40 # Create stack (10 bytes)
        sw      $a0, 0($sp)
        sw      $a1, 4($sp)
        sw      $a2, 8($sp)
        sw      $s0, 12($sp)
        sw      $s1, 16($sp)
        sw      $s2, 20($sp)
        sw      $s3, 24($sp)
        sw      $s4, 28($sp)
        sw      $ra, 32($sp)

        # Init local variables
        add     $s0, $a0, $zero
        addi    $s1, $s0, 7
        add     $s2, $a1, $zero
        addi    $s3, $s2, 7
        la	$t0, sprites
        mul	$t1, $a2, SPRITE_SIZE
        add 	$s4, $t0, $t1		# i = &sprites + sprite_id*SPRITE_SIZE
drawSpriteForY:
        bge     $s2, $s3, drawSpriteForYend

drawSpriteForX:
        bge     $s0, $s1, drawSpriteForXend

        # Read and translate color
        lb	$a0, 0 ($s4)
        jal	translateColor

        # Call drawPixel
        add     $a0, $s0, $zero
        add     $a1, $s2, $zero
        add     $a2, $v0, $zero
        jal     drawPixel       # drawPixel (x, y, color)

        addi    $s0, $s0, 1     # x++
        addi	$s4, $s4, 1	# i++
        j       drawSpriteForX
drawSpriteForXend:
        addi    $s0, $s0, -7    # x = x0
        addi    $s2, $s2, 1     # y++
        j       drawSpriteForY
drawSpriteForYend:
        # Restore stack
        lw      $a0, 0($sp)
        lw      $a1, 4($sp)
        lw      $a2, 8($sp)
        lw      $s0, 12($sp)
        lw      $s1, 16($sp)
        lw      $s2, 20($sp)
        lw      $s3, 24($sp)
        lw      $s4, 28($sp)
        lw      $ra, 32($sp)
        addi    $sp, $sp, 40    # Destroy stack (10 bytes)

        jr	$ra

#===========================================
# FUNCTION void drawPixel(int x0, int y0, int color)
#===========================================
# Brief: store word Color in the frame buffer
# Pseudocode: *((a1*256 + a0)*4 + FB_PTR) = color
drawPixel:
   la  $t0, FB_PTR        # t0 = FB_PTR
   mul $a1, $a1, FB_XRES  # a1 *= 256
   add $a0, $a0, $a1
   sll $a0, $a0, 2        # (a1*256 + a0)*4
   add $a0, $a0, $t0
   sw  $a2, 0($a0)        # *((a1*256 + a0)*4 + FB_PTR) = color
   jr  $ra

#===========================================
# FUNCTION int translateColor(byte color)
#===========================================
# Brief: convert the color from byte to word representation
# Pseudocode: return *(&colors color*4)
translateColor:
	sll	$t0, $a0, 2
	la	$t1, colors
	add	$t2, $t0, $t1
	lw	$v0, 0($t2)
	# li	$v0, 0x00b711ff # debug (print always purple)
	jr	$ra
