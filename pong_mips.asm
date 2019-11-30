# Arquitetura e Organizacao de Computadores I
#
# GRUPO:
# - Alan Ferreira Leite Santos
# - Lucas Monteiro Lima
# - Lucas Rassilan Vilanova
# - Thiago Danilo Souza
#
# DEFINICOES:
# 1) As seguintes configuracoes fisicas serao usadas:
#     1.1) O jogo tem as dimensoes 640x480
#     1.2) As barras dos jogadores tem as dimensoes 1x66
#     1.3) A bola tem as dimensoes 1x1
#     1.4) A inercia da barra e de 3 frames (ciclos)
#     1.5) A inercia da bola e de 2 frames (ciclos)
#
# 2) Os dados salvos na memoria irao obedecer a seguinte ordem:
#     2.1) Buffer de imagem (307200 bytes - 300kb, 1 byte por pixel)
#     2.2) Struct da barra da esquerda (10 bytes)
#     2.3) Struct da barra da direita (10 bytes)
#     2.4) Struct da bola (10 bytes)
#     2.5) Pontuacao da barra da esquerda (2 bytes - Halfword)
#     2.6) Pontuacao da barra da direita (2 bytes - Halfword)
#
# 3) A struct de todos os objetos (barras e bola) segue a seguinte ordem de dados:
#     3.1) Posicao X (2 bytes - Halfword)
#     3.2) Posicao Y (2 bytes - Halfword)
#     3.3) Contador de inercia (2 bytes - Halfword)
#     3.4) Direcao X (2 bytes - Halfword)
#     3.5) Direcao Y (2 bytes - Halfword)
#
# 4) Um pixel aceso sera representado na memoria por 1 e um apagado sera 0.
#

# Inicio do programa
MAIN:				# void main () { }
	addi $a0, $zero, 1	# Manda pular a inicializacao do buffer de imagem
	jal START

	addi $s0, $zero, 640	# Quantidade de frames/ciclos que serao executados

# MAIN_FOR_LOOP
M_FOR:	jal UPDATE
	addi $s0, $s0, -1
	bne $s0, $zero, M_FOR

	# Chama a funcao DRAW para escrever no buffer de imagem o estado em que o jogo parou
	jal DRAW	# OBS: essa funcao demora bastante para finalizar

	j EXIT

# Inicializa o buffer de imagem, os objetos do jogo e a pontuacao
START:				# void start () { }
	# Se $a0 for diferente de zero, pula a inicializacao do buffer de imagem e assume que a memeria ja comeca zerada
	bne $a0, $zero, S_BARS

	# Inicializa buffer
	addi $t0, $zero, -1
	addi $t1, $zero, -307200

# START_FOR_LOOP
S_FOR:	add $t2, $sp, $t0	# for (int t0 = -1; t0 >= -307200; t0--)
	sb $zero, ($t2)		# 	vgaBuffer[t0] = PIXEL_OFF;
	addi $t0, $t0, -1
	slt $t3, $t0, $t1
	beq $t3, $zero, S_FOR

# START_BARS
S_BARS:	addi $sp, $sp, -307202	# Atualiza ponteiro $sp

	# Inicializa barra esquerda
	addi $t0, $zero, 5
	sh $t0, ($sp)		# Posicao X = 5
	addi $t0, $zero, 207
	sh $t0, -2($sp)		# Posicao Y = 207
	addi $t0, $zero, 3
	sh $t0, -4($sp)		# Contador de inercia = 3
	addi $t0, $zero, 0
	sh $t0, -6($sp)		# Direcao X = 0
	sh $t0, -8($sp)		# Direcao Y = 0

	# Atualiza ponteiro $sp
	addi $sp, $sp, -10

	# Inicializa barra direita
	addi $t0, $zero, 635
	sh $t0, ($sp)		# Posicao X = 635
	addi $t0, $zero, 207
	sh $t0, -2($sp)		# Posicao Y = 207
	addi $t0, $zero, 3
	sh $t0, -4($sp)		# Contador de inercia = 3
	addi $t0, $zero, 0
	sh $t0, -6($sp)		# Direcao X = 0
	sh $t0, -8($sp)		# Direcao Y = 0

	# Atualiza ponteiro $sp
	addi $sp, $sp, -10

	# Inicializa bola
	addi $t0, $zero, 320
	sh $t0, ($sp)		# Posicao X = 320
	addi $t0, $zero, 240
	sh $t0, -2($sp)		# Posicao Y = 240
	addi $t0, $zero, 2
	sh $t0, -4($sp)		# Contador de inercia = 2
	addi $t0, $zero, 1
	sh $t0, -6($sp)		# Direcao X = 1
	sh $t0, -8($sp)		# Direcao Y = 1

	# Atualiza ponteiro $sp
	addi $sp, $sp, -10

	# Inicializa pontuacoes
	add $t0, $zero, $zero
	sh $t0, ($sp)		# leftScore = 0
	sh $t0, -2($sp)		# rightScore = 0

	# Atualiza ponteiro $sp
	addi $sp, $sp, -2

	addi $sp, $sp, -6	# Pula 6 bytes pra abrir espaco para o salvamento do $ra
	sw $ra, ($sp)		# Salva $ra
	jal INITIALIZE_BALL

	lw $ra, ($sp)
	addi $sp, $sp, 6
	jr $ra

# Aplica o movimento de um dado objeto ($a0)
MOVE_OBJECT:			# void moveObject (Object * obj, int originalInertia) { }
	lh $t0, -6($a0)	# Carrega obj->inertia
	addi $t0, $t0, -1	# Subtrai 1 de obj->inertia
	sh $t0, -6($a0)		# Atualiza $a0 com a subtracao ocorrida
	bne $t0, $zero, MO_R	# Se diferente de zero da jump

	lh $t1, -2($a0)		# Carrega obj->x
	lh $t2, -8($a0)		# Carrega obj->direction.x
	add $t1, $t1, $t2	# Soma e atualiza obj->x com obj->direction.x
	sh $t1, -2($a0) 	# Salva resultado soma

	lh $t3, -4($a0)		# Carrega obj->y
	lh $t4, -10($a0)	# Carrega obj->direction.y
	sub $t3, $t3, $t4 	# Subtrai e atualiza obj->y com obj->direction.y
	sh $t3, -4($a0) 	# Salva resultado subtracao

	sh $a1, -6($a0)		# Atualiza obj->inertia com originalInertia

# MOVE_OBJECT_RETURN
MO_R:	jr $ra

# Muda a direcao do movimento da barra de acordo com a posicao da bola
CHANGE_BAR_DIRECTION:		# void changeBarDirection (Object * bar) { }
	lh $t0, 16($sp)		# Carrega ball.y
	lh $t1, -4($a0)		# Carrega bar->y
	addi $t2, $t1, 33	# bar->y + BAR_HEIGHT / 2
	slt $t3, $t0, $t2	# ball.y < bar->y + BAR_HEIGHT / 2
	bne $t3, $zero, CBD_U	# Se ball.y < bar->y + BAR_HEIGHT / 2 manda a barra subir

	slt $t3, $t2, $t0	# ball.y > bar->y + BAR_HEIGHT / 2
	bne $t2, $t0, CBD_D	# Se ball.y > bar->y + BAR_HEIGHT / 2 manda a barra descer
	jr $ra

# CHANGE_BAR_DIRECTION_UP
CBD_U:	addi $t4, $zero, 1	# Torna um registrador igual a 1
	sh $t4, -10($a0)	# bar->direction.y = 1
	jr $ra

# CHANGE_BAR_DIRECTION_DOWN
CBD_D:	addi $t4, $zero, -1	# Torna um registrador igual a -1
	sh $t4, -10($a0)	# bar->direction.y = -1
	jr $ra

# Detecta se um pixel em uma dada coordenada x ($a0), y ($a1) esta aceso ($v0 = 1) ou apagado ($v0 = 0)
IS_PIXEL_ON:			# int isPixelOn (int x, int y) { }
	addi $v0, $zero, 1	# Pixel aceso

	# Detecta pixel sobre as bordas da esquerda e da direita
	beq $a0, $zero, IPO_R	# x == 0
	addi $t0, $zero, 639
	beq $a0, $t0, IPO_R	# x == 639

	# Detecta pixel sobre as bordas superior e inferior
	beq $a1, $zero, IPO_R	# y == 0
	addi $t0, $zero, 479
	beq $a1, $t0, IPO_R	# y == 479

	addi $t4, $sp, 10	# Cria um ponteiro para ball.direction.y (pula o placar e o $ra salvo pelo draw)

	# Detecta pixel sobre a bola
	lh $t0, 8($t4)		# ball.x
	slt $t1, $a0, $t0	# x < ball.x
	slt $t2, $t0, $a0	# x > ball.x
	or $t0, $t1, $t2	# x != ball.x

	lh $t1, 6($t4)		# ball.y
	slt $t2, $a1, $t1	# y < ball.y
	slt $t3, $t1, $a1	# y > ball.y
	or $t1, $t2, $t3	# y != ball.y

	or $t0, $t0, $t1	# x != ball.x || y != ball.y
	beq $t0, $zero, IPO_R

	# Detecta pixel sobre a barra direita
	lh $t0, 18($t4)		# rightBar.x
	slt $t1, $a0, $t0	# x < rightBar.x
	slt $t2, $t0, $a0	# x > rightBar.x
	or $t0, $t1, $t2	# x != rightBar.x

	lh $t1, 16($t4)		# rightBar.y
	addi $t2, $t1, 66	# rightBar.y + BAR_HEIGHT

	slt $t1, $a1, $t1	# y < rightBar.y
	slt $t2, $t2, $a1	# y > rightBar.y + BAR_HEIGHT

	or $t1, $t1, $t2	# y < rightBar.y || y > rightBar.y + BAR_HEIGHT
	or $t0, $t0, $t1	# x != rightBar.x || y < rightBar.y || y > rightBar.y + BAR_HEIGHT
	beq $t0, $zero, IPO_R

	# Detecta pixel sobre a barra esquerda
	lh $t0, 28($t4)		# leftBar.x
	slt $t1, $a0, $t0	# x < leftBar.x
	slt $t2, $t0, $a0	# x > leftBar.x
	or $t0, $t1, $t2	# x != leftBar.x

	lh $t1, 26($t4)		# leftBar.y
	addi $t2, $t1, 66	# leftBar.y + BAR_HEIGHT

	slt $t1, $a1, $t1	# y < leftBar.y
	slt $t2, $t2, $a1	# y > leftBar.y + BAR_HEIGHT

	or $t1, $t1, $t2	# y < leftBar.y || y > leftBar.y + BAR_HEIGHT
	or $t0, $t0, $t1	# x != leftBar.x || y < leftBar.y || y > leftBar.y + BAR_HEIGHT
	beq $t0, $zero, IPO_R

	add $v0, $zero, $zero	# Pixel apagado

# IS_PIXEL_ON_RETURN
IPO_R:	jr $ra

# Atualiza o buffer de imagem na memoria com o estado atual do jogo
DRAW:				# void draw () { }
	addi $s3, $sp, 307234	# Faz $s3 apontar para o byte do primeiro pixel
	addi $sp, $sp, -6	# Pula 6 bytes pra abrir espaco para o salvamento do $ra
	sw $ra, ($sp)		# Salva $ra

	add $s0, $zero, $zero	# y = 0
	add $s1, $zero, $zero	# x = 0

# DRAW_FOR_LOOP
D_FOR:	add $a0, $s1, $zero
	add $a1, $s0, $zero
	jal IS_PIXEL_ON		# isPixelOn(x, y)

	# Salva pixel no buffer de imagem
	sb $v0, ($s3)		# vgaBuffer[y][x] = $v0 == 1 ? PIXEL_ON : PIXEL_OFF
	addi $s3, $s3, -1

	addi $s1, $s1, 1	# x++
	addi $t0, $zero, 640
	slt $s2, $s1, $t0	# x < 640
	bne $s2, $zero, D_FOR	# for (int x = 0; x < 640; x++)

	add $s1, $zero, $zero	# x = 0
	addi $s0, $s0, 1	# y++
	addi $t0, $zero, 480
	slt $s2, $s0, $t0	# y < 480
	bne $s2, $zero, D_FOR	# for (int y = 0; y < 480; y++)

	lw $ra, ($sp)
	addi $sp, $sp, 6
	jr $ra

# Coloca a bola no meio do campo e escolhe uma direcao aleatoria para ela
INITIALIZE_BALL:		# void initializeBall () { }
	addi $t1, $sp, 10
	addi $t0, $zero, 320
	sh $t0, 8($t1)		# ball.x = WIDTH / 2
	addi $t0, $zero, 240
	sh $t0, 6($t1)		# ball.y = HEIGHT / 2

	addi $t0, $zero, 1
	addi $t2, $zero, -1

	sh $t0, 2($t1)		# ball.direction.x = 1
	li $v0, 42		# 42 e o codigo de chamada do sistema para gerar um numero aleatorio
	li $a1, 2		# $a1 guarda o limite superior da geracao do numero aleatorio
	syscall			# Gera o numero aleatorio e salva em $a0

	bne $a0, $zero, IB_MR
	sh $t2, 2($t1)		# ball.direction.x = -1

# INITIALIZE_BALL_MOVE_RIGHT
IB_MR:	sh $t0, ($t1)		# ball.direction.y = 1
	li $v0, 42		# 42 e o codigo de chamada do sistema para gerar um numero aleatorio
	li $a1, 2		# $a1 guarda o limite superior da geracao do numero aleatorio
	syscall			# Gera o numero aleatorio e salva em $a0

	bne $a0, $zero, IB_MT
	sh $t2, ($t1)		# ball.direction.y = -1

# INITIALIZE_BALL_MOVE_TOP
IB_MT:	jr $ra

# Atualiza o jogo avancando um frame/ciclo
UPDATE:				# void update () { }
	# Aplica os movimentos fisicos
	lh $t0, 10($sp)		# Carrega ball.y
	lh $t1, 4($sp)		# Carrega ball.direction.y
	addi $t2, $zero, 478
	slt $t3, $t0, $t2	# ball.y < HEIGHT - 2

	addi $t2, $zero, -1
	slt $t4, $t1, $t2	# ball.direction.y < -1
	slt $t5, $t2, $t1	# ball.direction.y > -1
	or $t2, $t4, $t5	# ball.direction.y != -1

	or $t2, $t3, $t2	# ball.y < HEIGHT - 2 || ball.direction.y != -1

	bne $t2, $zero, U_NM1	# Se !(ball.y >= HEIGHT - 2 && ball.direction.y == -1), pula para o proximo teste
	addi $t2, $zero, -1
	mul $t1, $t1, $t2
	sh $t1, 4($sp)		# ball.direction.y *= -1
	j U_NM2

# UPDATE_NEXT_MOVE_1
U_NM1:	addi $t2, $zero, 1
	slt $t3, $t2, $t0	# ball.y > 1

	slt $t4, $t1, $t2	# ball.direction.y < 1
	slt $t5, $t2, $t1	# ball.direction.y > 1
	or $t2, $t4, $t5	# ball.direction.y != 1

	or $t2, $t3, $t2	# ball.y > 1 || ball.direction.y != 1

	bne $t2, $zero, U_NM2	# Se !(ball.y <= 1 && ball.direction.y == 1), pula para o proximo teste
	addi $t2, $zero, -1
	mul $t1, $t1, $t2
	sh $t1, 4($sp)		# ball.direction.y *= -1

# UPDATE_NEXT_MOVE_2
U_NM2:	lh $t2, 12($sp)		# Carrega ball.x
	lh $t3, 30($sp)		# Carrega leftBar.y
	lh $t4, 32($sp)		# Carrega leftBar.x

	addi $t5, $t3, -1	# leftBar.y - 1
	slt $t6, $t0, $t5	# ball.y < leftBar.y - 1
	slt $t7, $t5, $t0	# ball.y > leftBar.y - 1
	or $t5, $t6, $t7	# ball.y != leftBar.y - 1

	slt $t6, $t2, $t4	# ball.x < leftBar.x
	slt $t7, $t4, $t2	# ball.x > leftBar.x
	or $t6, $t6, $t7	# ball.x != leftBar.x

	or $t5, $t5, $t6	# ball.y != leftBar.y - 1 || ball.x != leftBar.x

	addi $t6, $zero, -1
	slt $t7, $t1, $t6	# ball.direction.y < -1
	slt $t8, $t6, $t1	# ball.direction.y > -1
	or $t6, $t7, $t8	# ball.direction.y != -1

	or $t5, $t5, $t6	# ball.y != leftBar.y - 1 || ball.x != leftBar.x || ball.direction.y != -1

	bne $t5, $zero, U_NM3	# Se !(ball.y == leftBar.y - 1 && ball.x == leftBar.x && ball.direction.y == -1), pula para o proximo teste
	addi $t5, $zero, -1
	mul $t1, $t1, $t5
	sh $t1, 4($sp)		# ball.direction.y *= -1
	j U_NM4

# UPDATE_NEXT_MOVE_3
U_NM3:	addi $t5, $t3, 67	# leftBar.y + BAR_HEIGHT + 1
	slt $t6, $t0, $t5	# ball.y < leftBar.y + BAR_HEIGHT + 1
	slt $t7, $t5, $t0	# ball.y > leftBar.y + BAR_HEIGHT + 1
	or $t5, $t6, $t7	# ball.y != leftBar.y + BAR_HEIGHT + 1

	slt $t6, $t2, $t4	# ball.x < leftBar.x
	slt $t7, $t4, $t2	# ball.x > leftBar.x
	or $t6, $t6, $t7	# ball.x != leftBar.x

	or $t5, $t5, $t6	# ball.y != leftBar.y + BAR_HEIGHT + 1 || ball.x != leftBar.x

	addi $t6, $zero, 1
	slt $t7, $t1, $t6	# ball.direction.y < 1
	slt $t8, $t6, $t1	# ball.direction.y > 1
	or $t6, $t7, $t8	# ball.direction.y != 1

	or $t5, $t5, $t6	# ball.y != leftBar.y + BAR_HEIGHT + 1 || ball.x != leftBar.x || ball.direction.y != 1

	bne $t5, $zero, U_NM4	# Se !(ball.y == leftBar.y + BAR_HEIGHT + 1 && ball.x == leftBar.x && ball.direction.y == 1), pula para o proximo teste
	addi $t5, $zero, -1
	mul $t1, $t1, $t5
	sh $t1, 4($sp)		# ball.direction.y *= -1

# UPDATE_NEXT_MOVE_4
U_NM4:	lh $t3, 20($sp)		# Carrega rightBar.y
	lh $t4, 22($sp)		# Carrega rightBar.x

	addi $t5, $t3, -1	# rightBar.y - 1
	slt $t6, $t0, $t5	# ball.y < rightBar.y - 1
	slt $t7, $t5, $t0	# ball.y > rightBar.y - 1
	or $t5, $t6, $t7	# ball.y != rightBar.y - 1

	slt $t6, $t2, $t4	# ball.x < rightBar.x
	slt $t7, $t4, $t2	# ball.x > rightBar.x
	or $t6, $t6, $t7	# ball.x != rightBar.x

	or $t5, $t5, $t6	# ball.y != rightBar.y - 1 || ball.x != rightBar.x

	addi $t6, $zero, -1
	slt $t7, $t1, $t6	# ball.direction.y < -1
	slt $t8, $t6, $t1	# ball.direction.y > -1
	or $t6, $t7, $t8	# ball.direction.y != -1

	or $t5, $t5, $t6	# ball.y != rightBar.y - 1 || ball.x != rightBar.x || ball.direction.y != -1

	bne $t5, $zero, U_NM5	# Se !(ball.y == rightBar.y - 1 && ball.x == rightBar.x && ball.direction.y == -1), pula para o proximo teste
	addi $t5, $zero, -1
	mul $t1, $t1, $t5
	sh $t1, 4($sp)		# ball.direction.y *= -1
	j U_NM6

# UPDATE_NEXT_MOVE_5
U_NM5:	addi $t5, $t3, 67	# rightBar.y + BAR_HEIGHT + 1
	slt $t6, $t0, $t5	# ball.y < rightBar.y + BAR_HEIGHT + 1
	slt $t7, $t5, $t0	# ball.y > rightBar.y + BAR_HEIGHT + 1
	or $t5, $t6, $t7	# ball.y != rightBar.y + BAR_HEIGHT + 1

	slt $t6, $t2, $t4	# ball.x < rightBar.x
	slt $t7, $t4, $t2	# ball.x > rightBar.x
	or $t6, $t6, $t7	# ball.x != rightBar.x

	or $t5, $t5, $t6	# ball.y != rightBar.y + BAR_HEIGHT + 1 || ball.x != rightBar.x

	addi $t6, $zero, 1
	slt $t7, $t1, $t6	# ball.direction.y < 1
	slt $t8, $t6, $t1	# ball.direction.y > 1
	or $t6, $t7, $t8	# ball.direction.y != 1

	or $t5, $t5, $t6	# ball.y != rightBar.y + BAR_HEIGHT + 1 || ball.x != rightBar.x || ball.direction.y != 1

	bne $t5, $zero, U_NM6	# Se !(ball.y == rightBar.y + BAR_HEIGHT + 1 && ball.x == rightBar.x && ball.direction.y == 1), pula para o proximo teste
	addi $t5, $zero, -1
	mul $t1, $t1, $t5
	sh $t1, 4($sp)		# ball.direction.y *= -1

# UPDATE_NEXT_MOVE_6
U_NM6:	lh $t1, 6($sp)		# Carrega ball.direction.x
	lh $t3, 30($sp)		# Carrega leftBar.y
	lh $t4, 32($sp)		# Carrega leftBar.x

	slt $t5, $t0, $t3	# ball.y < leftBar.y

	addi $t6, $t3, 66	# leftBar.y + BAR_HEIGHT
	slt $t6, $t6, $t0	# ball.y > leftBar.y + BAR_HEIGHT

	or $t5, $t5, $t6	# ball.y < leftBar.y || ball.y > leftBar.y + BAR_HEIGHT

	addi $t6, $t4, 1	# leftBar.x + 1
	slt $t7, $t2, $t6	# ball.x < leftBar.x + 1
	slt $t8, $t6, $t2	# ball.x > leftBar.x + 1
	or $t6, $t7, $t8	# ball.x != leftBar.x + 1

	or $t5, $t5, $t6	# ball.y < leftBar.y || ball.y > leftBar.y + BAR_HEIGHT || ball.x != leftBar.x + 1

	addi $t6, $zero, -1
	slt $t7, $t1, $t6	# ball.direction.x < -1
	slt $t8, $t6, $t1	# ball.direction.x > -1
	or $t6, $t7, $t8	# ball.direction.x != -1

	or $t5, $t5, $t6	# ball.y < leftBar.y || ball.y > leftBar.y + BAR_HEIGHT || ball.x != leftBar.x + 1 || ball.direction.x != -1

	bne $t5, $zero, U_NM7	# Se !(ball.y >= leftBar.y && ball.y <= leftBar.y + BAR_HEIGHT && ball.x == leftBar.x + 1 && ball.direction.x == -1), pula para o proximo teste
	addi $t5, $zero, -1
	mul $t1, $t1, $t5
	sh $t1, 6($sp)		# ball.direction.x *= -1

# UPDATE_NEXT_MOVE_7
U_NM7:	lh $t3, 20($sp)		# Carrega rightBar.y
	lh $t4, 22($sp)		# Carrega rightBar.x

	slt $t5, $t0, $t3	# ball.y < rightBar.y

	addi $t6, $t3, 66	# rightBar.y + BAR_HEIGHT
	slt $t6, $t6, $t0	# ball.y > rightBar.y + BAR_HEIGHT

	or $t5, $t5, $t6	# ball.y < rightBar.y || ball.y > rightBar.y + BAR_HEIGHT

	addi $t6, $t4, -1	# rightBar.x - 1
	slt $t7, $t2, $t6	# ball.x < rightBar.x - 1
	slt $t8, $t6, $t2	# ball.x > rightBar.x - 1
	or $t6, $t7, $t8	# ball.x != rightBar.x - 1

	or $t5, $t5, $t6	# ball.y < rightBar.y || ball.y > rightBar.y + BAR_HEIGHT || ball.x != rightBar.x - 1

	addi $t6, $zero, 1
	slt $t7, $t1, $t6	# ball.direction.x < 1
	slt $t8, $t6, $t1	# ball.direction.x > 1
	or $t6, $t7, $t8	# ball.direction.x != 1

	or $t5, $t5, $t6	# ball.y < rightBar.y || ball.y > rightBar.y + BAR_HEIGHT || ball.x != rightBar.x - 1 || ball.direction.x != 1

	bne $t5, $zero, U_POS	# Se !(ball.y >= rightBar.y && ball.y <= rightBar.y + BAR_HEIGHT && ball.x == rightBar.x - 1 && ball.direction.x == 1), pula para o proximo teste
	addi $t5, $zero, -1
	mul $t1, $t1, $t5
	sh $t1, 6($sp)		# ball.direction.x *= -1

# UPDATE_POSITIONS
U_POS:	addi $sp, $sp, -6	# Pula 6 bytes pra abrir espaco para o salvamento do $ra
	sw $ra, ($sp)		# Salva $ra

	# Move a bola
	addi $a0, $sp, 20	# &ball
	addi $a1, $zero, 2	# BALL_INERTIA
	jal MOVE_OBJECT

	# Move a barra da esquerda
	addi $a0, $sp, 40	# &leftBar
	addi $a1, $zero, 3	# BAR_INERTIA
	jal MOVE_OBJECT

	# Move a barra da direita
	addi $a0, $sp, 30	# &rightBar
	addi $a1, $zero, 3	# BAR_INERTIA
	jal MOVE_OBJECT

	lh $t0, 12($sp)		# Carrega ball.direction.x

	# Aplica decisao de movimento das barras
	addi $t1, $zero, 1
	slt $t2, $t0, $t1	# ball.direction.x < 1
	slt $t3, $t1, $t0	# ball.direction.x > 1
	or $t1, $t2, $t3	# ball.direction.x != 1

	bne $t1, $zero, U_CMRB	# Se !(ball.direction.x == -1), move a barra da direita
	# Decide movimento da barra da esquerda
	addi $a0, $sp, 40	# &leftBar
	jal CHANGE_BAR_DIRECTION
	sh $zero, 20($sp)	# rightBar.direction.y = 0
	j U_CG

# UPDATE_CHANGE_MOVEMENT_RIGHT_BAR
U_CMRB: # Decide movimento da barra da direita
	addi $a0, $sp, 30	# &rightBar
	jal CHANGE_BAR_DIRECTION
	sh $zero, 30($sp)	# leftBar.direction.y = 0

# UPDATE_CHECK_GOAL
U_CG: 	# Avalia condicao de gol
	lh $t0, 18($sp)		# Carrega ball.x

	addi $t1, $zero, 1
	slt $t1, $t1, $t0	# ball.x > 1

	bne $t1, $zero, U_GTLB	# Se !(ball.x <= 1), testa gol da barra da esquerda
	lh $t0, 6($sp)		# Carrega rightScore
	addi $t0, $t0, 1	# rightScore + 1
	sh $t0, 6($sp)		# rightScore++
	jal INITIALIZE_BALL
	j U_R

# UPDATE_GOAL_TEST_LEFT_BAR
U_GTLB:	lh $t0, 18($sp)		# Carrega ball.x
	addi $t1, $zero, 639	# WIDTH - 1
	slt $t1, $t0, $t1	# ball.x < WIDTH - 1

	bne $t1, $zero, U_R	# Se !(ball.x >= WIDTH - 1), nenhum gol
	lh $t0, 8($sp)		# Carrega leftScore
	addi $t0, $t0, 1	# leftScore + 1
	sh $t0, 8($sp)		# leftScore++
	jal INITIALIZE_BALL

# UPDATE_RETURN
U_R:	lw $ra, ($sp)
	addi $sp, $sp, 6
	jr $ra

EXIT:
