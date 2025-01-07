bits 64
default rel

global init
global board
global move
global snake
global snakeSize
global BOARD_SIZE


struc SnakeElement
    PosX resd 1
    PosY resd 1
endstruc

section .data

%define BOARD_SIZE 64

%define SNAKE_HEAD_STARTING_POSITION (BOARD_SIZE * BOARD_SIZE) / 2
%define START_SNAKE_SIZE 3
%define SNAKE_HEAD_VALUE 4
%define SNAKE_TAIL_VALUE 2
%define SNAKE_PosX_Offset 0
%define SNAKE_PosY_Offset 4

isDead db 0
snakeSize db 0


section .bss
board resb BOARD_SIZE * BOARD_SIZE
snake resb 8 * BOARD_SIZE * BOARD_SIZE ; 8 == sizeof(PosX) + sizeof(PosY)


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
    lea rbx, snake
    ;lea r15, snakeSize

    mov r10, BOARD_SIZE
    dec r10
    shr r10, 1 ; middle row

    mov r11, BOARD_SIZE
    dec r11
    shr r11, 1 ; middle column

    mov r12, 0 ; idx of snake element

    mov rcx, START_SNAKE_SIZE
    mov rdx, SNAKE_HEAD_VALUE
snake_loop:

    ; adress for target struc
    lea r13, [rbx + r12 * 8]

    mov dword [r13 + SNAKE_PosX_Offset], r10d
    mov dword [r13 + SNAKE_PosY_Offset], r11d

    ;increase column
    inc r11

    ;increase count of snake element
    inc r12

    inc byte [snakeSize]
    mov rdx, SNAKE_TAIL_VALUE
    loop snake_loop ; it will work until rcx > 0 (SNAKE_SIZE)
    ret


; rdi = dir X, rsi = dir Y
move:
    lea rbx, [snake]
    lea rbp, [snakeSize]

    ;save old pos
    mov  r14, [rbx + SNAKE_PosX_Offset]
    mov  r15, [rbx + SNAKE_PosX_Offset]

    ;update this pos
    add dword [rbx + SNAKE_PosX_Offset], ecx
    add dword [rbx + SNAKE_PosY_Offset], edx

    ret

    ; currIdx
    mov r10, 0
    ; inc by 1 beacuse head is handled
    inc r10


    ;if currIdx >= snakeSize then go to done
    cmp r10, rbp
    jge done

propagate_loop:

    ; addressOfSnake + currIdx * sizeOf(snakeStruc)
    lea r11, [rbx + r10 * 8]

    ; save old this val
    mov ecx, [r11 + SNAKE_PosX_Offset]
    mov edx, [r11 + SNAKE_PosY_Offset]

    ;update this val
    mov [r11 + SNAKE_PosX_Offset], r14
    mov [r11 + SNAKE_PosY_Offset], r15

    ;update old this val
    mov ecx, r14d
    mov edx, r15d
    inc r10

    ret
    cmp r10, rbp
    jge propagate_loop

done:
    ret
