Simple snake game implemented in assembly language using NASM for the game logic and WinAPI for the graphical user interface.

## Prerequisites
Before you begin, ensure you have the following installed:
- **NASM**: To assemble the game logic.
- **G++** (from MinGW or similar): To compile and link the program for the Windows platform.
- **windres**: To handle resource files (e.g., `.rc` files).
## Compilation 

### Compile the resource file
```bash
windres resources.rc -O coff -o resources.o
```
### Assemble the game logic
```bash
nasm -fwin64 -o logic.obj logic.asm
```
### Compile and link 
```bash
g++ -o windowsRender.exe windowsRender.cpp logic.obj resources.o -mwindows -lwinmm -lmsimg32
```

### Run
```bash
.\windowsRender.exe
```

## Screenshots

![screenshot1](https://github.com/user-attachments/assets/36467b66-b535-431a-8a16-5a7759ff7f1a)
![screenshot2](https://github.com/user-attachments/assets/5ffcd655-7438-414e-aead-cd3bd9afbdde)
