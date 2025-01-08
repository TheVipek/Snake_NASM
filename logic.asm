bits 64
default rel

global init
global board
global move
global snake
global snakeSize
global BOARD_SIZE
global spawn_food

section .data

%define BOARD_SIZE 24

%define SNAKE_HEAD_STARTING_POSITION (BOARD_SIZE * BOARD_SIZE) / 2
%define START_SNAKE_SIZE 3
%define SNAKE_HEAD_VALUE 4
%define SNAKE_TAIL_VALUE 2
%define SNAKE_PosX_Offset 0
%define SNAKE_PosY_Offset 4

isDead db 0
snakeSize db 0

section .bss
; 1 byte = X, 2 byte = Y
moveDir resb 2
board resb BOARD_SIZE * BOARD_SIZE
snake resb 8 * BOARD_SIZE * BOARD_SIZE ; 8 == sizeof(PosX) + sizeof(PosY)




section .text

init:
    lea rsi, [moveDir]
    mov cl, -1
    mov dl, 0
    mov byte [rsi], cl
    mov byte [rsi + 1], dl
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
    mov r15, r10
    imul r15, BOARD_SIZE
    add r15, r11

    ;write default value for board element
    mov byte [rdi + r15], 0

    inc r11

    jmp .boardColumnLoop
.increaseRow:
    inc r10
    jmp .boardRowLoop

.prepareBoardDone:
    ret;


prepareSnake:
    push rcx
    push rbx
    push r12
    push r13

    lea rbx, snake


    mov r10, BOARD_SIZE
    dec r10
    shr r10, 1 ; middle row

    mov r11, BOARD_SIZE
    dec r11
    shr r11, 1 ; middle column

    mov r12, 0 ; idx of snake element

    mov rcx, START_SNAKE_SIZE
    mov rdx, SNAKE_HEAD_VALUE
.snake_loop:

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
    loop .snake_loop ; it will work until rcx > 0 (SNAKE_SIZE)

    pop rcx
    pop rbx
    pop r12
    pop r13
    ret


; windows 64 platform
; [Parameter1]rcx = dir Y, [Parameter2]rdx = dir X
move:
    push rbx
    push rbp

    lea rbx, [snake]
    mov rbp, [snakeSize]
    lea rsi, [moveDir]
    cmp byte [rsi], 0
    jne .validateMoveX

    cmp byte [rsi + 1], 0
    jne .validateMoveY

    ;jmp .done

    jmp .processMove


.validateMoveX:

;    ;xDir
    mov r8, rdx
    neg r8

    ;x dir check
    ;like it cant move to -1, when its already heading to 1
    cmp [rsi], r8b
    je .done

    jmp .processMove

.validateMoveY:
    ;yDir
    mov r9, rcx
    neg r9

    ;y dir check
    ;the same for it
    cmp [rsi + 1], r9b
    je .done

    jmp .processMove

.processMove:

    mov byte [rsi], dl
    mov byte [rsi + 1], cl
    ;save old pos
    mov r14d, [rbx + SNAKE_PosX_Offset]
    mov r15d, [rbx + SNAKE_PosY_Offset]



    ;update this pos
    add [rbx + SNAKE_PosX_Offset], ecx
    add [rbx + SNAKE_PosY_Offset], edx


    ; currIdx
    mov r10, 0
    ; inc by 1 beacuse head is handled
    inc r10


    ;if currIdx >= snakeSize then go to done
    cmp r10, rbp
    jge .done

.propagate_loop:

    ; addressOfSnake + currIdx * sizeOf(snakeStruc)
    lea r11, [rbx + r10 * 8]

    ; save old this val
    mov  ecx, [r11 + SNAKE_PosX_Offset]
    mov  edx, [r11 + SNAKE_PosY_Offset]

    ;update this val
    mov dword [r11 + SNAKE_PosX_Offset], r14d
    mov dword [r11 + SNAKE_PosY_Offset], r15d

    ;update old this val
    mov r14d, ecx
    mov r15d, edx
    inc r10

    cmp r10, rbp
    jl .propagate_loop

    ;jg .done

.done:
    pop rbx
    pop rbp
    ret

; windows 64 platform
; rcx = row, rdx = column
spawn_food:
    push rbx
    push rbp

    mov al, 1 ; true by default
    lea rbx, [snake]
    mov rbp, [snakeSize]


    ;currIdx
    mov r10, 0

    ;if currIdx >= snakeSize then go to done
    cmp r10, rbp

    jge .done

.check_snake_positions:
    lea r11, [rbx + r10 * 8]

    ; compare x
    mov r12d, [r11 + SNAKE_PosX_Offset]
    cmp r12d, ecx
    jne .skip_y_check

    ; if x not fail, compare y
    mov r13d, [r11 + SNAKE_PosY_Offset]
    cmp r13d, edx
    jne .skip_y_check

    ; both x and y failed
.incorrect_pos:
    mov rax, 0

    pop rbp
    pop rbx
    ret;

.skip_y_check:
    inc r10
    cmp r10, rbp
    jl .check_snake_positions ; loop while r10 < snakeSize

.done:
    lea rdi, board

    ; calculating offset
    mov r15, rdx
    imul r15, BOARD_SIZE
    add r15, rcx

    ;write food value
    mov byte [rdi + r15], 1

    pop rbp
    pop rbx
    ret;
