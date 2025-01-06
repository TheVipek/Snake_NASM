bits 64
default rel

global _start
extern ExitProcess
extern RegisterClassExA
extern CreateWindowExA
extern MessageBoxA
extern ShowWindow
extern UpdateWindow

section .data
className db 'SnakeGame', 0
text  db 'Hello World!', 0
title db 'Snake Game', 0


section .bss


section .text

_start:
    sub rsp, 28h      ; reserve shadow space and make RSP%16 == 0
    ;mov rcx, 0       ; hWnd = HWND_DESKTOP
    ;lea rdx,[text]    ; LPCSTR lpText
    ;lea r8,[title]   ; LPCSTR lpCaption
    ;mov r9d, 0       ; uType = MB_OK

    ;call MessageBoxA

    mov rcx, 0  ; dwExStyle
    lea rdx, [className] ; lpClassName
    lea r8, [title] ; lpWindowName
    mov r9, 0 ; dwStyle

     push 0              ; lpParam
    push 0              ; hInstance
    push 0              ; hMenu
    push 0              ; hWndParent
    push 480            ; nHeight
    push 640            ; nWidth
    push 100            ; Y
    push 100            ; X

    call CreateWindowExA

    test eax, eax           ; Check if window creation failed
    jz exit_program         ; Exit if failed

    ; Show and Update the Window
    mov rcx, rax            ; HWND (handle to the window)
    mov edx, 1              ; nCmdShow = SW_SHOWNORMAL
    call ShowWindow

    mov rcx, rax            ; HWND
    call UpdateWindow


exit_program:
   mov  ecx,eax        ; exit status = return value of MessageBoxA
   call ExitProcess

   add rsp, 28h       ; if you were going to ret, restore RSP

   hlt     ; privileged instruction that crashes if ever reached.
