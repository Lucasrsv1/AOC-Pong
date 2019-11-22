# Arquitetura e Organização de Computadores I
#
# GRUPO:
# -
# -
# - Lucas Rassilan Vilanova
# -
#
# DEFINIÇÕES:
# 1) As seguintes configurações físicas serão usadas:
#     1.1) O jogo tem as dimensões 640x480
#     1.2) As barras dos jogadores têm as dimensões 1x66
#     1.3) A bola tem as dimensões 1x1
#     1.4) A inércia da barra é de 3 frames (ciclos)
#     1.5) A inércia da bola é de 2 frames (ciclos)
#
# 2) Os dados salvos na memória irão obedecer a seguinte ordem:
#     2.1) Buffer de imagem (307200 bytes - 300kb, 1 byte por pixel)
#     2.2) Struct da barra da esquerda (10 bytes)
#     2.3) Struct da barra da direita (10 bytes)
#     2.4) Struct da bola (10 bytes)
#
# 3) A struct de todos os objetos (barras e bola) segue a seguinte ordem de dados:
#     3.1) Posição X (2 bytes - Halfword)
#     3.2) Posição Y (2 bytes - Halfword)
#     3.3) Contador de inércia (2 bytes - Halfword)
#     3.4) Direção X (2 bytes - Halfword)
#     3.5) Direção Y (2 bytes - Halfword)
#
# 4) Um pixel aceso será representado na memória por 1 e um apagado será 0.
#

MAIN:
	addi $a0, $zero, 1	# Manda pular a inicialização do buffer de imagem
	jal START

	# Testa a função DRAW
	jal DRAW

	j EXIT

START:
	# Se $a0 for diferente de zero, pula a inicialização do buffer de imagem e assume que a memória já começa zerada
	bne $a0, $zero, S_BARS

	# Inicializa buffer
	addi $t0, $zero, -1
	addi $t1, $zero, -307200
S_FOR:	add $t2, $sp, $t0	# for (int t0 = -1; t0 >= -307200; t0--)
	sb $zero, ($t2)		# 	vgaBuffer[t0] = PIXEL_OFF;
	addi $t0, $t0, -1
	slt $t3, $t0, $t1
	beq $t3, $zero, S_FOR

	# Atualiza ponteiro $sp
S_BARS:	addi $sp, $sp, -307202

	# Inicializa barra esquerda
	addi $t0, $zero, 5
	sh $t0, ($sp)		# Posição X = 5
	addi $t0, $zero, 207
	sh $t0, -2($sp)		# Posição Y = 207
	addi $t0, $zero, 3
	sh $t0, -4($sp)		# Contador de inércia = 3
	addi $t0, $zero, 0
	sh $t0, -6($sp)		# Direção X = 0
	sh $t0, -8($sp)		# Direção Y = 0

	# Atualiza ponteiro $sp
	addi $sp, $sp, -10

	# Inicializa barra direita
	addi $t0, $zero, 635
	sh $t0, ($sp)		# Posição X = 635
	addi $t0, $zero, 207
	sh $t0, -2($sp)		# Posição Y = 207
	addi $t0, $zero, 3
	sh $t0, -4($sp)		# Contador de inércia = 3
	addi $t0, $zero, 0
	sh $t0, -6($sp)		# Direção X = 0
	sh $t0, -8($sp)		# Direção Y = 0

	# Atualiza ponteiro $sp
	addi $sp, $sp, -10

	# Inicializa bola
	addi $t0, $zero, 320
	sh $t0, ($sp)		# Posição X = 320
	addi $t0, $zero, 240
	sh $t0, -2($sp)		# Posição Y = 240
	addi $t0, $zero, 2
	sh $t0, -4($sp)		# Contador de inércia = 2
	addi $t0, $zero, 1
	sh $t0, -6($sp)		# Direção X = 1
	sh $t0, -8($sp)		# Direção Y = 1

	# Atualiza ponteiro $sp
	addi $sp, $sp, -8

	jr $ra

MOVE_OBJECT:
	lh  $t0, -6($a0)	# Carrega obj->inertia
	addi $t0, $t0, -1	# Subtrai 1  de obj->inertia
	sh $t0, -6($a0)		# Atualiza $a0 com a subtra��o ocorrida
	bne $t0, $zero, MV;	# Se diferente de zero da jump
	
	lh $t1, -2($a0)		# Carrega obj->x
	lh $t2, -10($a0)	# Carrega obj->direction.x
	add $t1, $t1, $t2	# Soma e atualiza obj->x com obj->direction.x
	sh $t1, -2($a0) 	# Salva resultado soma
	
	lh $t3, -4($a0)		# Carrega obj->y
	lh $t4, -12($a0)	# Carrega obj->direction.y
	sub $t3, $t3, $t4 	# Subtrai e atualiza obj->y com obj->direction.y
	sh $t3, -4($a0) 	# Salva resultado subtra��o
	
	sh $a1, -6($a0)		# Atualiza obj->inertia com originalinertia
		
MV:	jr $ra
	

IS_PIXEL_ON:			# $a0 = x, $a1 = y
	addi $v0, $zero, 1	# res = 1

	# Detecta pixel sobre as bordas da esquerda e da direita
	beq $a0, $zero, IPO_R	# x == 0
	addi $t0, $zero, 639
	beq $a0, $t0, IPO_R	# x == 639

	# Detecta pixel sobre as bordas superior e inferior
	beq $a1, $zero, IPO_R	# y == 0
	addi $t0, $zero, 479
	beq $a1, $t0, IPO_R	# y == 479

	# Detecta pixel sobre a bola
	lh $t0, 8($sp)		# ball.x
	slt $t1, $a0, $t0	# x < ball.x
	slt $t2, $t0, $a0	# ball.x < x
	or $t0, $t1, $t2	# x != ball.x

	lh $t1, 6($sp)		# ball.y
	slt $t2, $a1, $t1	# y < ball.y
	slt $t3, $t1, $a1	# ball.y < y
	or $t1, $t2, $t3	# y != ball.y

	or $t0, $t0, $t1	# x != ball.x || y != ball.y
	beq $t0, $zero, IPO_R

	# Detecta pixel sobre a barra direita
	lh $t0, 18($sp)		# rightBar.x
	slt $t1, $a0, $t0	# x < rightBar.x
	slt $t2, $t0, $a0	# rightBar.x < x
	or $t0, $t1, $t2	# x != rightBar.x

	lh $t1, 16($sp)		# rightBar.y
	addi $t2, $t1, 66	# rightBar.y + BAR_HEIGHT

	slt $t1, $a1, $t1	# y < rightBar.y
	slt $t2, $t2, $a1	# y > rightBar.y + BAR_HEIGHT

	or $t1, $t1, $t2	# y < rightBar.y || y > rightBar.y + BAR_HEIGHT
	or $t0, $t0, $t1	# x != rightBar.x || y < rightBar.y || y > rightBar.y + BAR_HEIGHT
	beq $t0, $zero, IPO_R

	# Detecta pixel sobre a barra esquerda
	lh $t0, 28($sp)		# leftBar.x
	slt $t1, $a0, $t0	# x < leftBar.x
	slt $t2, $t0, $a0	# leftBar.x < x
	or $t0, $t1, $t2	# x != leftBar.x

	lh $t1, 26($sp)		# leftBar.y
	addi $t2, $t1, 66	# leftBar.y + BAR_HEIGHT

	slt $t1, $a1, $t1	# y < leftBar.y
	slt $t2, $t2, $a1	# y > leftBar.y + BAR_HEIGHT

	or $t1, $t1, $t2	# y < leftBar.y || y > leftBar.y + BAR_HEIGHT
	or $t0, $t0, $t1	# x != leftBar.x || y < leftBar.y || y > leftBar.y + BAR_HEIGHT
	beq $t0, $zero, IPO_R

	add $v0, $zero, $zero	# res = 0
IPO_R:	jr $ra

DRAW:	
	addi $s3, $sp, 307230	# faz $s3 apontar para o byte do primeiro pixel
	addi $sp, $sp, -6
	sw $ra, ($sp)
	
	add $s0, $zero, $zero	# y = 0
	add $s1, $zero, $zero	# x = 0
D_FOR:	add $a0, $s1, $zero
	add $a1, $s0, $zero
	jal IS_PIXEL_ON		# isPixelOn(x, y)
	
	# Salva pixel no buffer de imagem
	sb $v0, ($s3)
	addi $s3, $s3, -1
	
	addi $s1, $s1, 1	# x++
	addi $t0, $zero, 640
	slt $s2, $s1, $t0	# x < 640
	bne $s2, $zero, D_FOR
	
	add $s1, $zero, $zero	# x = 0
	addi $s0, $s0, 1	# y++
	addi $t0, $zero, 480
	slt $s2, $s0, $t0	# y < 480
	bne $s2, $zero, D_FOR
	
	lw $ra, ($sp)
	addi $sp, $sp, 6
	jr $ra

EXIT:
