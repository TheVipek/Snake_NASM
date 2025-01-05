bits 64
default rel

global init

section .data

%define BOARD_SIZE 64
%define START_SNAKE_SIZE 3
%define SNAKE_HEAD_VALUE 4
%define SNAKE_TAIL_VALUE 2
isDead DB 0

section .bss
board RESB BOARD_SIZE * BOARD_SIZE


section .text
init:
    call prepareBoard
    call prepareSnake
    ret;





prepareBoard:
    lea rdi, board
    mov byte [rdi], 0
    mov r10, $0   ;entry value of board ROW
.boardRowLoop:
    cmp r10, BOARD_SIZE
    jge .prepareBoardDone
    mov r11, $0   ;entry value of board COLUMN
.boardColumnLoop:
    cmp r11, BOARD_SIZE
    jge .increaseRow

    ; calculating offset
    mov rax, r10
    imul rax, BOARD_SIZE
    add rax, r11

    ;write default value for board element
    mov byte [rdi + rax], 0

    inc r11

    jmp .boardColumnLoop
.increaseRow:
    inc r10
    jmp .boardRowLoop

.prepareBoardDone:
    ret;


prepareSnake:
    lea rdi, board

    mov r10, BOARD_SIZE
    dec r10
    shr r10, 1 ; middle row

    mov r11, BOARD_SIZE
    dec r11
    shr r11, 1 ; middle column

    mov rcx, START_SNAKE_SIZE
    mov rdx, SNAKE_HEAD_VALUE
snake_loop:
    mov rax, r10
    imul rax, BOARD_SIZE
    add rax, r11 ; offset (column)

    mov byte [rdi + rax], dl ;

    inc r11

    mov rdx, SNAKE_TAIL_VALUE
    loop snake_loop ; it will work until rcx > 0 (SNAKE_SIZE)
    ret


