bits 64
default rel

global init
global board
global move
global snake
global snakeSize
global BOARD_SIZE
global spawn_food
global g_pick_food_callback

extern try_spawn_food

struc SnakeSegment
    .PosX resd 1        ; 4 bytes
    .PosY resd 1        ; 4 bytes
    .OldPosX resd 1        ; 4 bytes
    .OldPosY resd 1        ; 4 bytes
endstruc

section .data

%define BOARD_SIZE 24
%define BOARD_EMPTY_CELL_VALUE 0
%define BOARD_FOOD_CELL_VALUE 1

%define SNAKE_HEAD_STARTING_POSITION (BOARD_SIZE * BOARD_SIZE) / 2
%define START_SNAKE_SIZE 3

%define SNAKE_HEAD_VALUE 4
%define SNAKE_TAIL_VALUE 2

%define SNAKE_PosX_Offset 0
%define SNAKE_PosY_Offset 4

isDead db 0
snakeSize db 0
g_pick_food_callback dq 0

section .bss
; 1 byte = X, 2 byte = Y
moveDir resb 2
board resb BOARD_SIZE * BOARD_SIZE
snake resb SnakeSegment_size * BOARD_SIZE * BOARD_SIZE ;



section .text

init:
    lea rsi, [moveDir]
    mov cl, -1
    mov dl, 0
    mov byte [rsi], cl
    mov byte [rsi + 1], dl
    call prepareBoard
    call prepareSnake

;    mov rax, [g_pick_food_callback]
;    test rax, rax
;    je .done
;    call rax
    call try_spawn_food

    jmp .done

.done:
    ret
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
    mov byte [rdi + r15], BOARD_EMPTY_CELL_VALUE

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

    ;handle wrapping for head
    call wrap_row_if_required
    call wrap_column_if_required

    ;handle food
    call pick_food_if_possible
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

    ;handle wrapping for tail element
    call wrap_row_if_required
    call wrap_column_if_required

    cmp r10, rbp
    jl .propagate_loop

    ;jg .done

.done:
    pop rbx
    pop rbp

    cmp rax, 1
    je .call_try_spawn_food_from_cpp
    ret
.call_try_spawn_food_from_cpp:
    call try_spawn_food
    ret


wrap_row_if_required:
    lea r11, [rbx + r10 * 8]

    cmp dword [r11 + SNAKE_PosX_Offset], BOARD_SIZE
    je .flip_row_toTopSide

    cmp dword [r11 + SNAKE_PosX_Offset], -1
    je .flip_X_toBotSide

    jmp .done
.flip_row_toTopSide:
    mov dword [r11 + SNAKE_PosX_Offset], 0
    jmp .done
.flip_X_toBotSide:
    mov dword [r11 + SNAKE_PosX_Offset], BOARD_SIZE - 1
    jmp .done
.done:
    ret


wrap_column_if_required:
    lea r11, [rbx + r10 * 8]

    cmp dword [r11 + SNAKE_PosY_Offset], BOARD_SIZE
    je .flip_column_toLeftSide

    cmp dword [r11 + SNAKE_PosY_Offset], -1
    je .flip_column_toRightSide

    jmp .done
.flip_column_toLeftSide:
      mov dword [r11 + SNAKE_PosY_Offset], 0
      jmp .done
.flip_column_toRightSide:
    mov dword [r11 + SNAKE_PosY_Offset], BOARD_SIZE - 1
    jmp .done
.done:
    ret

;rbx <-address of snake
pick_food_if_possible:
    mov rax, $0
    push r8
    push r9

    lea r12, board
    ;head row
    mov r8d, [rbx + SNAKE_PosX_Offset]
    ;head column
    mov r9d, [rbx + SNAKE_PosY_Offset]

    imul r8d, BOARD_SIZE
    add r8d, r9d

    cmp byte [r12 + r8], BOARD_FOOD_CELL_VALUE
    jne .noFood

    mov byte [r12 + r8], BOARD_EMPTY_CELL_VALUE
    mov rax, $1

    jmp .done
.noFood:
    jmp .done
.done:
    pop r8
    pop r9

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
    mov byte [rdi + r15], BOARD_FOOD_CELL_VALUE

    pop rbp
    pop rbx
    ret;

