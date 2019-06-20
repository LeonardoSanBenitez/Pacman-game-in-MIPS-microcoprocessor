.eqv FB_PTR 0x10040000
.eqv FB_XRES 256
.eqv FB_YRES 256

.eqv X_OFFSET  0
.eqv Y_OFFSET  0
.eqv X_SCALE   7
.eqv Y_SCALE   7

.eqv GRID_ROWS 35
.eqv GRID_COLS 35

.data

#===========================================
# Pacman Arena Grid
#===========================================
# grid size: 35x35 sprites
# Sprite size: 7x7 pixels
# Sprites simbols
  # @ = comida
  # A = invencibilidade
  # B = inimigo
  # C = Pacman
  # D = Cereja
  # E = Canto superior esquerdo
  # F = Canto superior direito
  # G = T inferior
  # H = T superior
  # I = Parede vertical
  # J = Canto inferior esquedo
  # K = Canto inferior direito
  # L = T dereita
  # M = T esquerda
  # N = Parede horizontal
  # O = Ponta esquerda
  # P = Ponta direita
  # Q = Ponta superior
  # R = Ponta inferior
  # S = Cruz


grid:
.ascii "ENNNNNNGNNNGNNNGF@EGNNNGNNNGNNNNNNF"
.ascii "IA@@@@@I@@@I@@@LK@JM@@@I@@@I@@@@@AI"
.ascii "I@ONNP@I@Q@I@Q@I@@@I@Q@I@Q@I@ONNP@I"
.ascii "I@@@@@@I@I@I@I@R@Q@R@I@I@I@I@@@@@@I"
.ascii "LNNNNP@R@I@I@I@@@I@@@I@I@I@R@ONNNNM"
.ascii "I@@@@@@@@I@R@LNNNSNNNM@R@I@@@@@@@@I"
.ascii "I@ENNF@Q@I@D@I@D@I@D@I@D@I@Q@ENNF@I"
.ascii "I@JNNK@I@LNGNM@I@I@I@LNGNM@I@JNNK@I"
.ascii "I@@@@@@I@IDIDI@I@I@I@IDIDI@I@@@@@@I"
.ascii "I@ONNNNM@I@I@I@I@I@I@I@I@I@LNNNNP@I"
.ascii "I@@@@@@I@I@R@R@I@R@I@R@R@I@I@@@@@@I"
.ascii "I@ENNF@I@I@@@@@I@@@I@@@@@I@I@ENNF@I"
.ascii "I@JNNK@I@JP@Q@OHP@OHP@Q@OK@I@JNNK@I"
.ascii "I@@@@@@I@@@@I@@@@@@@@@I@@@@I@@@@@@I"
.ascii "LNNNNP@I@EF@R@Q@@@@@Q@R@EF@I@ONNNNM"
.ascii "IA@@@@@I@JK@@@I@@@@@I@@@JK@I@@@@@AI"
.ascii "JNNNNNNK@@@@Q@IA@A@AI@Q@@@@JNNNNNNK"
.ascii "@@@@@@@@@OP@I@I@@@@@I@I@OP@@@@@@@@@"
.ascii "ENNNNNNF@@@@R@JNNNNNK@R@@@@ENNNNNNF"
.ascii "IA@@@@@I@EF@@@@@@@@@@@@@EF@I@@@@@AI"
.ascii "LNNNNP@I@JK@ENNNP@ONNNF@JK@I@ONNNNM"
.ascii "I@@@@@@I@@@@I@@@@@@@@@I@@@@I@@@@@@I"
.ascii "I@ENNF@I@EP@R@OGP@OGP@R@OF@I@ENNF@I"
.ascii "I@JNNK@I@I@@@@@I@@@I@@@@@I@I@JNNK@I"
.ascii "I@@@@@@I@I@Q@Q@I@Q@I@Q@Q@I@I@@@@@@I"
.ascii "I@ONNNNM@I@I@I@I@I@I@I@I@I@LNNNNP@I"
.ascii "I@@@@@@I@IDIDI@I@I@I@IDIDI@I@@@@@@I"
.ascii "I@ENNF@I@LNHNM@R@I@R@LNHNM@I@ENNF@I"
.ascii "I@JNNK@R@I@D@I@D@I@D@I@D@I@R@JNNK@I"
.ascii "I@@@@@@@@I@Q@LNNNSNNNM@Q@I@@@@@@@@I"
.ascii "LNNNNP@Q@I@I@I@@@I@@@I@I@I@Q@ONNNNM"
.ascii "I@@@@@@I@I@I@I@Q@R@Q@I@I@I@I@@@@@@I"
.ascii "I@ONNP@I@R@I@R@I@@@I@R@I@R@I@ONNP@I"
.ascii "IA@@@@@I@@@I@@@LF@EM@@@I@@@I@@@@@AI"
.ascii "JNNNNNNHNNNHNNNHK@JHNNNHNNNHNNNNNNK"

#===========================================
# Colors
#===========================================
.eqv BLACK  0x00000000  # 0
.eqv BLUE   0x001111ff  # 1
.eqv PURPLE 0x00b711ff  # 2
.eqv YELLOW 0x00fffc60  # 3
.eqv RED    0x00ff0000  # 4
.eqv GREEN  0x00007000  # 5
.eqv GRAY   0x00a0a0a0  # 6
.eqv WHITE  0x00ffffff  # 7

colors: .word BLACK, BLUE, PURPLE, YELLOW
        .word RED, GREEN, GRAY, WHITE

#===========================================
# Sprites
#===========================================
.eqv SPRITE_SIZE 49
sprites:
# @ = 0 = comida
.byte 0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0
.byte 0,0,0,6,0,0,0
.byte 0,0,6,6,6,0,0
.byte 0,0,0,6,0,0,0
.byte 0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0
# A = 1 = invencibilidade
.byte 0,0,0,0,0,0,0
.byte 0,0,0,1,0,0,0
.byte 0,0,1,1,1,0,0
.byte 0,1,1,1,1,1,0
.byte 0,0,1,1,1,0,0
.byte 0,0,0,1,0,0,0
.byte 0,0,0,0,0,0,0
# B = 2 = inimigo
.byte 0,0,0,0,0,0,0
.byte 0,0,2,2,2,0,0
.byte 0,2,0,2,0,2,0
.byte 0,2,2,2,2,2,0
.byte 0,2,2,2,2,2,0
.byte 0,2,0,2,0,2,0
.byte 0,0,0,0,0,0,0
# C = 3 = Pacman
.byte 0,0,0,0,0,0,0
.byte 0,0,3,3,3,0,0
.byte 0,3,3,3,3,3,0
.byte 0,3,3,3,3,3,0
.byte 0,3,3,3,3,3,0
.byte 0,0,3,3,3,0,0
.byte 0,0,0,0,0,0,0
# D = 4 = Cereja
.byte 0,0,0,0,0,0,0
.byte 0,0,0,0,5,5,0
.byte 0,0,0,5,5,0,0
.byte 0,4,4,4,0,0,0
.byte 0,4,4,4,0,0,0
.byte 0,4,4,4,0,0,0
.byte 0,0,0,0,0,0,0
# E = 5 = Canto Sup. Esq.
.byte 0,0,0,0,0,0,0
.byte 0,0,0,6,6,6,6
.byte 0,0,6,6,6,6,6
.byte 0,6,6,6,6,6,6
.byte 0,6,6,6,6,6,6
.byte 0,6,6,6,6,6,6
.byte 0,6,6,6,6,6,0
# F = 6 =Canto Sup. Dir.
.byte 0,0,0,0,0,0,0
.byte 6,6,6,6,0,0,0
.byte 6,6,6,6,6,0,0
.byte 6,6,6,6,6,6,0
.byte 6,6,6,6,6,6,0
.byte 6,6,6,6,6,6,0
.byte 0,6,6,6,6,6,0
# G = 7 = Tee Inferior
.byte 0,0,0,0,0,0,0
.byte 6,6,6,6,6,6,6
.byte 6,6,6,6,6,6,6
.byte 6,6,6,6,6,6,6
.byte 6,6,6,6,6,6,6
.byte 6,6,6,6,6,6,6
.byte 0,6,6,6,6,6,0
# H = 8 = Tee Superior
.byte 0,6,6,6,6,6,0
.byte 6,6,6,6,6,6,6
.byte 6,6,6,6,6,6,6
.byte 6,6,6,6,6,6,6
.byte 6,6,6,6,6,6,6
.byte 6,6,6,6,6,6,6
.byte 0,0,0,0,0,0,0
# I = 9 = Parede Vertical
.byte 0,6,6,6,6,6,0
.byte 0,6,6,6,6,6,0
.byte 0,6,6,6,6,6,0
.byte 0,6,6,6,6,6,0
.byte 0,6,6,6,6,6,0
.byte 0,6,6,6,6,6,0
.byte 0,6,6,6,6,6,0
# J = 10 = Canto Inf. Esq.
.byte 0,6,6,6,6,6,0
.byte 0,6,6,6,6,6,6
.byte 0,6,6,6,6,6,6
.byte 0,6,6,6,6,6,6
.byte 0,0,6,6,6,6,6
.byte 0,0,0,6,6,6,6
.byte 0,0,0,0,0,0,0
# K = 11 = Canto Inf. Dir.
.byte 0,6,6,6,6,6,0
.byte 6,6,6,6,6,6,0
.byte 6,6,6,6,6,6,0
.byte 6,6,6,6,6,6,0
.byte 6,6,6,6,6,0,0
.byte 6,6,6,6,0,0,0
.byte 0,0,0,0,0,0,0
# L = 12 = Tee Direita
.byte 0,6,6,6,6,6,0
.byte 0,6,6,6,6,6,6
.byte 0,6,6,6,6,6,6
.byte 0,6,6,6,6,6,6
.byte 0,6,6,6,6,6,6
.byte 0,6,6,6,6,6,6
.byte 0,6,6,6,6,6,0
# M = 13 = Tee Esquerda
.byte 0,6,6,6,6,6,0
.byte 6,6,6,6,6,6,0
.byte 6,6,6,6,6,6,0
.byte 6,6,6,6,6,6,0
.byte 6,6,6,6,6,6,0
.byte 6,6,6,6,6,6,0
.byte 0,6,6,6,6,6,0
# N = 14 = Parede Horizontal
.byte 0,0,0,0,0,0,0
.byte 6,6,6,6,6,6,6
.byte 6,6,6,6,6,6,6
.byte 6,6,6,6,6,6,6
.byte 6,6,6,6,6,6,6
.byte 6,6,6,6,6,6,6
.byte 0,0,0,0,0,0,0
# O = 15 = Ponta Esq.
.byte 0,0,0,0,0,0,0
.byte 0,0,6,6,6,6,6
.byte 0,6,6,6,6,6,6
.byte 0,6,6,6,6,6,6
.byte 0,6,6,6,6,6,6
.byte 0,0,6,6,6,6,6
.byte 0,0,0,0,0,0,0
# P = 16 = Ponta Dir.
.byte 0,0,0,0,0,0,0
.byte 6,6,6,6,6,0,0
.byte 6,6,6,6,6,6,0
.byte 6,6,6,6,6,6,0
.byte 6,6,6,6,6,6,0
.byte 6,6,6,6,6,0,0
.byte 0,0,0,0,0,0,0
# Q = 17 = Ponta Sup.
.byte 0,0,0,0,0,0,0
.byte 0,0,6,6,6,0,0
.byte 0,6,6,6,6,6,0
.byte 0,6,6,6,6,6,0
.byte 0,6,6,6,6,6,0
.byte 0,6,6,6,6,6,0
.byte 0,6,6,6,6,6,0
# R = 18 = Ponta Inf.
.byte 0,6,6,6,6,6,0
.byte 0,6,6,6,6,6,0
.byte 0,6,6,6,6,6,0
.byte 0,6,6,6,6,6,0
.byte 0,6,6,6,6,6,0
.byte 0,0,6,6,6,0,0
.byte 0,0,0,0,0,0,0
# S = 19 = Cruz
.byte 0,6,6,6,6,6,0
.byte 6,6,6,6,6,6,6
.byte 6,6,6,6,6,6,6
.byte 6,6,6,6,6,6,6
.byte 6,6,6,6,6,6,6
.byte 6,6,6,6,6,6,6
.byte 0,6,6,6,6,6,0
# T = 20 = Fantasma2
.byte 0,0,0,0,0,0,0
.byte 0,0,1,1,1,0,0
.byte 0,1,0,1,0,1,0
.byte 0,1,1,1,1,1,0
.byte 0,1,1,1,1,1,0
.byte 0,1,0,1,0,1,0
.byte 0,0,0,0,0,0,0
# U = 21 = Fantasma3
.byte 0,0,0,0,0,0,0
.byte 0,0,5,5,5,0,0
.byte 0,5,0,5,0,5,0
.byte 0,5,5,5,5,5,0
.byte 0,5,5,5,5,5,0
.byte 0,5,0,5,0,5,0
.byte 0,0,0,0,0,0,0
