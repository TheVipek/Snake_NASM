bits 64
default rel

global init
global board
global move
global snake
global snakeSize
global BOARD_SIZE
global spawn_food
global snakeSqrPerSecond
global moveDir
global change_direction
global isDead
extern try_spawn_food

extern onEat
extern onDeath


struc SnakeSegment ; 16bytes
    .PosX resd 1
    .PosY resd 1
    .OldPosX resd 1
    .OldPosY resd 1
endstruc

%define BOARD_SIZE 12
%define BOARD_EMPTY_CELL_VALUE 0
%define BOARD_FOOD_CELL_VALUE 1

%define SNAKE_HEAD_STARTING_POSITION (BOARD_SIZE * BOARD_SIZE) / 2
%define START_SNAKE_SIZE 3

%define SNAKE_HEAD_VALUE 4
%define SNAKE_TAIL_VALUE 2


section .data



snakeSqrPerSecond dd 9
proceededAtLeastOnceInMoveDir db 0
isDead db 0
snakeSize db 0

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

    sub rsp, 8
    call try_spawn_food
    add rsp, 8
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
    imul rax, r12, SnakeSegment_size
    lea r13, [rbx + rax]


    mov dword [r13 + SnakeSegment.PosX], r10d
    mov dword [r13 + SnakeSegment.PosY], r11d
    mov dword [r13 + SnakeSegment.OldPosX], r10d
    mov dword [r13 + SnakeSegment.OldPosY], r11d

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


; [Parameter1]rcx = dir Y, [Parameter2]rdx = dir X
change_direction:
    cmp byte[proceededAtLeastOnceInMoveDir], 0
    je .done

    lea rsi, [moveDir]

    cmp byte [rsi], 0
    jne .validateMoveX

    cmp byte [rsi + 1], 0
    jne .validateMoveY

    jmp .applyInput
.validateMoveX:

;    ;xDir
    mov r8, rdx
    neg r8

    ;x dir check
    ;like it cant move to -1, when its already heading to 1
    cmp [rsi], r8b
    je .done

    jmp .applyInput

.validateMoveY:
    ;yDir
    mov r9, rcx
    neg r9

    ;y dir check
    ;the same for it
    cmp [rsi + 1], r9b
    je .done

    jmp .applyInput
.applyInput:
    mov byte [rsi], dl
    mov byte [rsi + 1], cl
    mov byte [proceededAtLeastOnceInMoveDir], 0


    jmp .done
.done:
    ret

move:
    push rbx
    push rbp

    cmp byte [isDead], 1
    je .exit_early

    lea rbx, [snake]
    movzx rbp, byte [snakeSize]
    lea rsi, [moveDir]

    jmp .processMove

.processMove:
    ;save old pos
    mov r14d, [rbx + SnakeSegment.PosX]
    mov r15d, [rbx + SnakeSegment.PosY]

    movsx r12d, byte [rsi]        ; Y
    movsx r13d, byte [rsi + 1]    ; X
    jmp .pre_update_positions_loop

.pre_update_positions_loop:

    ;update this pos
    add dword [rbx + SnakeSegment.PosX], r13d
    add dword [rbx + SnakeSegment.PosY], r12d
    mov dword [rbx + SnakeSegment.OldPosX], r14d
    mov dword [rbx + SnakeSegment.OldPosY], r15d


    ; currIdx
    mov r10, 0

    ;--REQUIRES R10--
    ;handle wrapping for head
    call wrap_row_if_required
    call wrap_column_if_required


    ; inc by 1 beacuse head is handled
    inc r10

    ;if currIdx >= snakeSize then go to done
    cmp r10, rbp
    jge .pre_validate_collision
    jmp .propagate_loop
.propagate_loop:

    ; addressOfSnake + currIdx * sizeOf(snakeStruc)
    imul r8, r10, SnakeSegment_size
    lea r11, [rbx + r8]

    ; save old this val
    mov  r13d, [r11 + SnakeSegment.PosX]
    mov  r12d, [r11 + SnakeSegment.PosY]

    ;update this val
    mov dword [r11 + SnakeSegment.OldPosX], r13d
    mov dword [r11 + SnakeSegment.OldPosY], r12d
    mov dword [r11 + SnakeSegment.PosX], r14d
    mov dword [r11 + SnakeSegment.PosY], r15d

    ;update old this val
    mov r14d, r13d
    mov r15d, r12d

    inc r10

    ;handle wrapping for tail element
    call wrap_row_if_required
    call wrap_column_if_required


    mov byte [proceededAtLeastOnceInMoveDir], 1


    cmp r10, rbp
    jl .propagate_loop

    ;jg .done

.pre_validate_collision:

    ;don't need to check collision when there's only head
    cmp rbp, 1
    je .done


    ; currIdx 1, because we ignore head which is 0
    mov r10, 1
    mov edi, [rbx + SnakeSegment.PosX]
    mov edx, [rbx + SnakeSegment.PosY]
    jmp .validate_collision

.validate_collision:
    inc r10
    cmp r10, rbp
    jge .done

    imul r8, r10, SnakeSegment_size
    lea r11, [rbx + r8]

    ; compare PosX and PosY, if both are equal then set isDead flag to true
    cmp edi, [r11 + SnakeSegment.PosX]
    jne .validate_collision

    cmp edx, [r11 + SnakeSegment.PosY]
    jne .validate_collision

    jmp .mark_as_dead


.mark_as_dead:
    mov byte [isDead], 1

    sub rsp, 8
    call onDeath ; method from cpp side
    add rsp, 8

    jmp .exit_early

.done:
 ;handle food
    call pick_food_if_possible

    pop rbx
    pop rbp



    cmp rax, 1
    je .call_try_spawn_food_from_cpp
    ret

.exit_early:
    pop rbx
    pop rbp
    ret
.call_try_spawn_food_from_cpp:
    sub rsp, 8
    call try_spawn_food
    add rsp, 8
    ret


wrap_row_if_required:
    push r15
    imul r15, r10, SnakeSegment_size
    lea r11, [rbx + r15]
    pop r15
    cmp dword [r11 + SnakeSegment.PosX], BOARD_SIZE
    je .flip_row_toTopSide

    cmp dword [r11 + SnakeSegment.PosX], -1
    je .flip_X_toBotSide

    jmp .done
.flip_row_toTopSide:
    mov dword [r11 + SnakeSegment.PosX], 0
    jmp .done
.flip_X_toBotSide:
    mov dword [r11 + SnakeSegment.PosX], BOARD_SIZE - 1
    jmp .done
.done:
    ret


wrap_column_if_required:
    push r15
    imul r15, r10, SnakeSegment_size
    lea r11, [rbx + r15]
    pop r15
    cmp dword [r11 + SnakeSegment.PosY], BOARD_SIZE
    je .flip_column_toLeftSide

    cmp dword [r11 + SnakeSegment.PosY], -1
    je .flip_column_toRightSide

    jmp .done
.flip_column_toLeftSide:
      mov dword [r11 + SnakeSegment.PosY], 0
      jmp .done
.flip_column_toRightSide:
    mov dword [r11 + SnakeSegment.PosY], BOARD_SIZE - 1
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
    mov r8d, [rbx + SnakeSegment.PosX]
    ;head column
    mov r9d, [rbx + SnakeSegment.PosY]

    imul r8d, BOARD_SIZE
    add r8d, r9d

    cmp byte [r12 + r8], BOARD_FOOD_CELL_VALUE
    jne .noFood

    mov byte [r12 + r8], BOARD_EMPTY_CELL_VALUE
    mov rax, $1
    jmp .foodPicked
.noFood:
    jmp .done
.foodPicked:
    push rax


    movzx rax, byte [snakeSize]
    ;to get last element
    dec rax

    ;last tail element
    imul r13, rax, SnakeSegment_size
    lea r14, [rbx + r13]

    ;new tail element address
    ;mov rax, [snakeSize]
    ;imul rax, rax, SnakeSegment_size
    lea r15, [rbx + r13 + SnakeSegment_size]

    ;fill new tail element x data
    mov dword eax, [r14 + SnakeSegment.OldPosX]
    mov dword [r15 + SnakeSegment.PosX], eax
    mov dword [r15 + SnakeSegment.OldPosX], eax

    ;fill new tail element y data
    mov dword eax, [r14 + SnakeSegment.OldPosY]
    mov dword [r15 + SnakeSegment.PosY], eax
    mov dword [r15 + SnakeSegment.OldPosY], eax

    ;increase snake size
    inc byte [snakeSize]


    sub rsp, 8
    call onEat ; method from cpp side
    add rsp, 8


    pop rax

    jmp .done
.done:
    pop r8
    pop r9

    ret
; windows 64 platform
; rcx = row, rdx = column
spawn_food:
    push  rbx
    push  rbp
    push  r12
    push  r13
    push  r14
    push  r15

    lea rbx, [snake]
    movzx rbp, byte [snakeSize]


    ;currIdx
    mov r10, 0

    ;if currIdx >= snakeSize then go to done
    cmp r10, rbp

    jge .add_food

.check_snake_positions:
    imul r14, r10, SnakeSegment_size
    lea r11, [rbx + r14]

    ; compare x
    mov r12d, [r11 + SnakeSegment.PosX]
    cmp r12d, ecx
    jne .next_element

    ; if x not fail, compare y
    mov r13d, [r11 + SnakeSegment.PosY]
    cmp r13d, edx
    jne .next_element

    jmp .incorrect_pos
    ; both x and y failed
.incorrect_pos:
    mov rax, 0 ; mark as failed
    jmp .done

.next_element:
    inc r10
    cmp r10, rbp
    jl .check_snake_positions ; loop while r10 < snakeSize

.add_food:
    lea rdi, board

    ; calculating offset
    mov r15, rcx
    imul r15, BOARD_SIZE
    add r15, rdx

    cmp r15, BOARD_SIZE * BOARD_SIZE
    jge .incorrect_pos

    ;write food value
    mov byte [rdi + r15], BOARD_FOOD_CELL_VALUE

    mov rax, 1 ; mark as success
    jmp .done
.done:
    pop  rbx
    pop  rbp
    pop  r12
    pop  r13
    pop  r14
    pop  r15
    ret
