bits 64
default rel

section .data
    className db "MyWindowClass", 0       ; Null-terminated string
    windowTitle db "Hello, NASM Window!", 0
    hInstance dq 0                        ; Initialized variable for application instance handle

section .bss
    msg resb 48                           ; Buffer for MSG structure (uninitialized)

section .text
global _start
extern GetModuleHandleA
extern RegisterClassExA
extern CreateWindowExA
extern ShowWindow
extern DefWindowProcA
extern ExitProcess

_start:
    ; Get the module handle
    xor rcx, rcx                          ; NULL for current process
    call GetModuleHandleA                 ; hInstance = GetModuleHandleA(NULL)
    mov [hInstance], rax                  ; Store the instance handle

    ; Register the window class
    sub rsp, 56                           ; Allocate space for WNDCLASSEX structure
    mov rax, rsp                          ; rax = pointer to WNDCLASSEX structure
    mov dword [rax], 48                   ; cbSize = sizeof(WNDCLASSEX)
    mov dword [rax + 4], 0x0003           ; style = CS_HREDRAW | CS_VREDRAW
    lea rdx, [windowProc]                 ; lpfnWndProc = address of window procedure
    mov [rax + 8], rdx
    mov [rax + 16], 0                     ; cbClsExtra = 0
    mov [rax + 20], 0                     ; cbWndExtra = 0
    mov rdx, [hInstance]                  ; hInstance = application instance handle
    mov [rax + 24], rdx
    mov [rax + 32], 0                     ; hIcon = NULL
    mov [rax + 40], 0                     ; hCursor = NULL
    mov [rax + 48], 6                     ; hbrBackground = COLOR_WINDOW+1
    lea rdx, [className]                  ; lpszClassName = address of className
    mov [rax + 56], rdx
    xor rdx, rdx                          ; lpszMenuName = NULL
    mov [rax + 64], rdx
    call RegisterClassExA                 ; Call WinAPI function

    ; Create the window
    xor rcx, rcx                          ; dwExStyle = 0
    lea rdx, [className]                  ; lpClassName = address of className
    lea r8, [windowTitle]                 ; lpWindowName = address of windowTitle
    mov r9d, 0xcf0000                     ; dwStyle = WS_OVERLAPPEDWINDOW
    sub rsp, 40                           ; Align stack and reserve shadow space
    mov qword [rsp + 0], 0                ; X = CW_USEDEFAULT
    mov qword [rsp + 8], 0                ; Y = CW_USEDEFAULT
    mov qword [rsp + 16], 800             ; nWidth = 800
    mov qword [rsp + 24], 600             ; nHeight = 600
    mov qword [rsp + 32], 0               ; hWndParent = NULL
    mov qword [rsp + 40], 0               ; hMenu = NULL
    mov rdx, [hInstance]                  ; hInstance = application instance handle
    mov qword [rsp + 48], rdx
    mov qword [rsp + 56], 0               ; lpParam = NULL
    call CreateWindowExA                  ; Call CreateWindowExA

    ; Show the window
    mov rcx, rax                          ; hWnd = return value of CreateWindowExA
    mov rdx, 1                            ; nCmdShow = SW_SHOWNORMAL
    call ShowWindow                       ; Call ShowWindow

    ; Exit process
    xor rcx, rcx                          ; Exit code = 0
    call ExitProcess                      ; Call ExitProcess

; Minimal Window Procedure
section .text
global windowProc
windowProc:
    ; Call DefWindowProcA for unhandled messages
    mov rcx, rdi                         ; HWND
    mov rdx, rsi                         ; Message
    mov r8, rdx                          ; wParam
    mov r9, rcx                          ; lParam
    call DefWindowProcA
    ret
