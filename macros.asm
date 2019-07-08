
# ==============================================================================
# GRAPHICS MACROS
# if (id>=5 and id<=19) return True
.macro IS_WALL (%id)
	blt 	%id, 5, retFalse
	bgt 	%id, 19, retFalse
	li 	$v0, 1
	j 	end
retFalse:
	li 	$v0, 0
end:
.end_macro

# if (id==2 OR id==20 OR id==21) return True
.macro IS_GHOST (%id)
	beq 	%id, 2, retTrue
	beq 	%id, 20, retTrue
	beq 	%id, 21, retTrue

	li 	$v0, 0
	j 	end
retTrue:
	li 	$v0, 1
end:
.end_macro

# if (id==3) return true
.macro IS_PACMAN (%id)
	bne 	%id, 3, retFalse
	li 	$v0, 1
	j 	end
retFalse:
	li 	$v0, 0
end:
.end_macro



# ==============================================================================
# IO MACROS
.macro exit
    li $v0, 10
    syscall
.end_macro

.macro exit (%status)
    li $v0, 17
    add $a0, $zero, %status
    syscall
.end_macro

.macro print_int (%x)
    li $v0, 1
    add $a0, $zero, %x
    syscall
.end_macro

.macro print_char (%x)
    li $v0, 11
    add $a0, $zero, %x
    syscall
.end_macro

.macro print_str (%str)
.data
mStr: .asciiz %str
.text
    li $v0, 4
    la $a0, mStr
    syscall
.end_macro

# ==============================================================================
# OTHERS MACROS
.macro FLOOR (%value, %multiple)
div 	%value, %value, %multiple
mul	%value, %value, %multiple
.end_macro
