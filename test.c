#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define FPS 30
#define WIDTH 640 / 11
#define HEIGHT 480 / 11

#define PIXEL_ON '#'
#define PIXEL_OFF ' '
#define BALL_PIXEL 'O'
#define BAR_HEIGHT 6

#define BAR_INERTIA 3
#define BALL_INERTIA 2

typedef struct vector {
	int x, y;
} Vector;

typedef struct object {
	int x, y, inertia;
	Vector direction;
} Object;

// Buffer que será representado pela memória no MIPS
char vgaBuffer[HEIGHT][WIDTH];

int leftScore = 0;
int rightScore = 0;

// Objetos da cena
Object leftBar = { 5, (HEIGHT - BAR_HEIGHT) / 2, BAR_INERTIA, (Vector) { 0, 0 } };
Object rightBar = { WIDTH - 5, (HEIGHT - BAR_HEIGHT) / 2, BAR_INERTIA, (Vector) { 0, 0 } };
Object ball = { WIDTH / 2, HEIGHT / 2, BALL_INERTIA, (Vector) { 1, 1 } };

int isPixelOn (int x, int y) {
	// Bordas da área do jogo
	if (x == 0 || x == WIDTH - 1 || y == 0 || y == HEIGHT - 1)
		return 1;

	// Valida se o pixel compoem a bola
	if (x == ball.x && y == ball.y)
		return 1;

	// Valida se o pixel compoem a barra 1
	if (x == leftBar.x && y >= leftBar.y && y <= leftBar.y + BAR_HEIGHT)
		return 1;

	// Valida se o pixel compoem a barra 2
	if (x == rightBar.x && y >= rightBar.y && y <= rightBar.y + BAR_HEIGHT)
		return 1;

	return 0;
}

void moveObject (Object * obj, int originalInertia) {
	if (--obj->inertia == 0) {
		obj->x += obj->direction.x;
		obj->y -= obj->direction.y;				// Subtrai, pois Y positivo é pra subir
		obj->inertia = originalInertia;
	}
}

void changeBarDirection (Object * bar) {
	if (ball.y < bar->y + BAR_HEIGHT / 2)
		bar->direction.y = 1;
	else if (ball.y > bar->y + BAR_HEIGHT / 2)
		bar->direction.y = -1;
}

void draw () {
	// Limpa a tela
	printf("\033c");

	printf("Left Bar Score: %d\t|\tRight Bar Score: %d\n", leftScore, rightScore);

	for (int y = 0; y < HEIGHT; y++) {
		for (int x = 0; x < WIDTH; x++)
			printf("%c", vgaBuffer[y][x]);

		printf("\n");
	}
}

void initializeBall () {
	ball.x = WIDTH / 2;
	ball.y = HEIGHT / 2;

	// Escolhe direção aleatória para a bola
	ball.direction.x = rand() % 10 >= 5 ? 1 : -1;
	ball.direction.y = rand() % 10 >= 5 ? 1 : -1;
}

void start () {
	for (int y = 0; y < HEIGHT; y++) {
		for (int x = 0; x < WIDTH; x++)
			vgaBuffer[y][x] = PIXEL_OFF;
	}

	initializeBall();
}

void update () {
	// Aplica os movimentos físicos
	if ((ball.y >= HEIGHT - 2 && ball.direction.y == -1) || (ball.y <= 1 && ball.direction.y == 1))
		ball.direction.y *= -1;

	if ((ball.y == leftBar.y - 1 && ball.x == leftBar.x && ball.direction.y == -1) || (ball.y == leftBar.y + BAR_HEIGHT + 1 && ball.x == leftBar.x && ball.direction.y == 1))
		ball.direction.y *= -1;

	if ((ball.y == rightBar.y - 1 && ball.x == rightBar.x && ball.direction.y == -1) || (ball.y == rightBar.y + BAR_HEIGHT + 1 && ball.x == rightBar.x && ball.direction.y == 1))
		ball.direction.y *= -1;

	if (ball.y >= leftBar.y && ball.y <= leftBar.y + BAR_HEIGHT && ball.x == leftBar.x + 1 && ball.direction.x == -1)
		ball.direction.x *= -1;

	if (ball.y >= rightBar.y && ball.y <= rightBar.y + BAR_HEIGHT && ball.x == rightBar.x - 1 && ball.direction.x == 1)
		ball.direction.x *= -1;

	// Atualiza posições
	moveObject(&ball, BALL_INERTIA);
	moveObject(&leftBar, BAR_INERTIA);
	moveObject(&rightBar, BAR_INERTIA);

	// Atualiza o buffer
	for (int y = 0; y < HEIGHT; y++) {
		for (int x = 0; x < WIDTH; x++)
			vgaBuffer[y][x] = isPixelOn(x, y) ? PIXEL_ON : PIXEL_OFF;
	}

	// Aplica decisão de movimento das barras
	if (ball.direction.x == -1) {
		changeBarDirection(&leftBar);   // Move barra da esquerda
		rightBar.direction.y = 0;
	} else {
		changeBarDirection(&rightBar);	// Move barra da direita
		leftBar.direction.y = 0;
	}

	// Avalia condição de fim de jogo
	if (ball.x <= 1 || ball.x >= WIDTH - 1) {
		if (ball.x <= 1) {
			rightScore++;
			ball.direction.x = 1;
		} else {
			leftScore++;
			ball.direction.x = -1;
		}

		initializeBall();
	} else {
		// Bola ainda em jogo
		vgaBuffer[ball.y][ball.x] = BALL_PIXEL;
	}
}

void main () {
	srand(time(NULL));
	start();

	while (1) {
		draw();
		update();
		nanosleep((const struct timespec[]){{0, 1000 * (double) (1000 / FPS)}}, NULL);
	}
}
//
