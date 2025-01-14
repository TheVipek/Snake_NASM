//g++ -o windowsRender.exe windowsRender.cpp logic.obj -mwindows
//nasm -fwin64 -o logic.obj logic.asm
#include <windows.h>
#include <random>
#include <sstream>

#define BOARD_SIZE 24
#define CELL_SIZE 40
#define GAP_SIZE 1
#define SNAKE_HEAD_MARGIN 4
#define BOARD_EMPTY_CELL_VALUE 0
#define BOARD_FOOD_CELL_VALUE 1
#define TARGET_FRAMES 60
LRESULT CALLBACK WndProc( HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam );
MSG msg;
std::random_device rd;
std::mt19937 gen(rd());
UINT_PTR moveTimerID;
UINT_PTR frameTimerID;

struct SnakeElement {
    int PosX;
    int PosY;
    int OldPosX;
    int OldPosY;
};


extern "C" unsigned char board[];
extern "C" unsigned char snake[];
extern "C" int snakeSize;
extern "C" int snakeSqrPerSecond;
extern "C" bool isDead;

int frameCount = 0;
float lastMoveTime = 0;
float snakeMovePerFrame;

extern "C" void init();
extern "C" void move();
extern "C" void change_direction(int row, int column);
extern "C" bool spawn_food(int row, int column);

// I know that its probably bad practice, to have circular dependency there, although i don't have any other idea at this moment
extern "C" void try_spawn_food() {
    std::uniform_int_distribution<> genX(0, BOARD_SIZE - 1);
    std::uniform_int_distribution<> genY(0, BOARD_SIZE - 1);
    while(!spawn_food(genX(gen), genY(gen))){}
}




int WINAPI WinMain( HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow )
{
    //from assembly
    init();
    snakeMovePerFrame = snakeSqrPerSecond / TARGET_FRAMES;
    //Register class
    WNDCLASSEX wc;

    wc.cbSize = sizeof( WNDCLASSEX );
    wc.style = 0;
    wc.lpfnWndProc = WndProc;
    wc.cbClsExtra = 0;
    wc.cbWndExtra = 0;
    wc.hInstance = hInstance;
    wc.hIcon = LoadIcon( NULL, IDI_APPLICATION );
    wc.hCursor = LoadCursor( NULL, IDC_ARROW );
    wc.hbrBackground =( HBRUSH )( COLOR_WINDOW + 1 );
    wc.lpszMenuName = NULL;
    wc.lpszClassName = "SnakeGame";
    wc.hIconSm = LoadIcon( NULL, IDI_APPLICATION );

    if (!RegisterClassEx(&wc)) {
        MessageBox(NULL, "Failed to register window class!", "Error", MB_ICONERROR);
        return 0;
    }

    //Create window
    HWND hwnd;

    hwnd = CreateWindowEx(
        WS_EX_CLIENTEDGE,
        "SnakeGame",
        "SnakeGame",
        WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX | WS_MAXIMIZEBOX,
        CW_USEDEFAULT,
        CW_USEDEFAULT,
        (BOARD_SIZE * CELL_SIZE) + ((BOARD_SIZE - 1) * GAP_SIZE) + 100,
        (BOARD_SIZE * CELL_SIZE) + ((BOARD_SIZE - 1) * GAP_SIZE) + 100,
        NULL,
        NULL,
        hInstance,
        NULL );

    if( hwnd == NULL )
    {
        MessageBox( NULL, "ERROR", "Failed to spawn window", MB_ICONEXCLAMATION );
        return 1;
    }


    //disable maximizing
    SetWindowLong(hwnd, GWL_STYLE,
                   GetWindowLong(hwnd, GWL_STYLE) & ~WS_MAXIMIZEBOX);

    ShowWindow( hwnd, nCmdShow );
    UpdateWindow( hwnd );

    frameTimerID = SetTimer(hwnd, 999, TARGET_FRAMES / 1000, NULL);
    moveTimerID = SetTimer(hwnd, 1000, (1000 / snakeSqrPerSecond), NULL);
    while (GetMessage(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }



    return(int)msg.wParam;
}
LRESULT CALLBACK WndProc( HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam )
{
    switch( msg )
    {
        case WM_KEYDOWN:
            switch (wParam) {
                case VK_UP: {
                  change_direction(-1, 0);
                }

                // InvalidateRect(hwnd, NULL, FALSE);
                //   UpdateWindow(hwnd);
                break;
                case VK_DOWN: {
                    change_direction(1, 0);
                }
                // InvalidateRect(hwnd, NULL, FALSE);
                // UpdateWindow(hwnd);

                break;
                case VK_LEFT: {
                    change_direction(0, -1);
                }

                // InvalidateRect(hwnd, NULL, FALSE);
                // UpdateWindow(hwnd);
                break;
                case VK_RIGHT: {
                    change_direction(0, 1);
                }
                 // InvalidateRect(hwnd, NULL, FALSE);
                 //  UpdateWindow(hwnd);
                break;
                default:
                break;
            }

        break;
        case WM_PAINT: {
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hwnd, &ps);

            HDC memDC = CreateCompatibleDC(hdc);
            int width = ps.rcPaint.right - ps.rcPaint.left;
            int height = ps.rcPaint.bottom - ps.rcPaint.top;
            HBITMAP memBitmap = CreateCompatibleBitmap(hdc, width, height);
            HBITMAP oldBitmap = (HBITMAP)SelectObject(memDC, memBitmap);

            FillRect(memDC, &ps.rcPaint, (HBRUSH)(COLOR_WINDOW+1));

            int gridWidth = (BOARD_SIZE * CELL_SIZE) + ((BOARD_SIZE - 1) * GAP_SIZE);
            int gridHeight = (BOARD_SIZE * CELL_SIZE) + ((BOARD_SIZE - 1) * GAP_SIZE);

            RECT clientRect;
            GetClientRect(hwnd, &clientRect);
            int clientWidth = clientRect.right - clientRect.left;
            int clientHeight = clientRect.bottom - clientRect.top;

            int offsetX = (clientWidth - gridWidth) / 2;
            int offsetY = (clientHeight - gridHeight) / 2;

            //Background
            HBRUSH backgroundBrush = CreateSolidBrush(RGB(232, 232, 232));
            RECT backgroundRect = { 0, 0, ps.rcPaint.right, ps.rcPaint.bottom };
            FillRect(memDC, &backgroundRect, backgroundBrush);
            DeleteObject(backgroundBrush);
            //Grid
            for (int i = 0; i < BOARD_SIZE; i++) {
                for (int j = 0; j < BOARD_SIZE; j++) {
                    int value = board[i * BOARD_SIZE + j];
                    HBRUSH brush;

                    if(value == BOARD_FOOD_CELL_VALUE)  // food
                        brush = CreateSolidBrush(RGB(255, 46, 46));
                    else if (value == BOARD_EMPTY_CELL_VALUE) // Empty cell
                        brush = CreateSolidBrush(RGB(255, 255, 255));


                    RECT cell = {
                        offsetX + j * (CELL_SIZE + GAP_SIZE) ,
                        offsetY + i * (CELL_SIZE + GAP_SIZE) ,
                        offsetX + j * (CELL_SIZE + GAP_SIZE) + CELL_SIZE,
                        offsetY + i * (CELL_SIZE + GAP_SIZE) + CELL_SIZE
                    };
                    FillRect(memDC, &cell, brush);
                    DeleteObject(brush);
                }
            }

            SnakeElement* snakeArray = reinterpret_cast<SnakeElement*>(snake);


            for (int i = snakeSize - 1; i >= 0; i--)
            {
                SnakeElement& elem = snakeArray[i];
                HBRUSH brush;
                RECT cell;
                if (i == 0) {
                    brush = CreateSolidBrush(RGB(0, 255, 0));
                    cell = {
                        offsetX + elem.PosY * (CELL_SIZE + GAP_SIZE) + SNAKE_HEAD_MARGIN ,
                        offsetY + elem.PosX * (CELL_SIZE + GAP_SIZE) + SNAKE_HEAD_MARGIN ,
                        offsetX + elem.PosY * (CELL_SIZE + GAP_SIZE) + CELL_SIZE - SNAKE_HEAD_MARGIN,
                        offsetY + elem.PosX * (CELL_SIZE + GAP_SIZE) + CELL_SIZE - SNAKE_HEAD_MARGIN
                    };
                }
                else {
                    brush = CreateSolidBrush(RGB(0, 200, 0));
                    cell = {
                        offsetX + elem.PosY * (CELL_SIZE + GAP_SIZE) ,
                        offsetY + elem.PosX * (CELL_SIZE + GAP_SIZE) ,
                        offsetX + elem.PosY * (CELL_SIZE + GAP_SIZE) + CELL_SIZE,
                        offsetY + elem.PosX * (CELL_SIZE + GAP_SIZE) + CELL_SIZE
                    };
                }
                FillRect(memDC, &cell, brush);
                DeleteObject(brush);
            }

            BitBlt(hdc,
                ps.rcPaint.left,
                ps.rcPaint.top,
                width,
                height,
                memDC,
                ps.rcPaint.left,
                ps.rcPaint.top,
                SRCCOPY);

            SelectObject(memDC, oldBitmap);
            DeleteObject(memBitmap);
            DeleteDC(memDC);

            EndPaint(hwnd, &ps);
        } break;
        case WM_ERASEBKGND:
            return 1;
        case WM_TIMER:
        {
            if (frameTimerID == wParam) {
                InvalidateRect(hwnd, NULL, FALSE);
                frameCount++;
            }
            else if (moveTimerID == wParam) {

                //asm won't update its position when it's dead, although i think that there's no need to call it if it will exit early every time
                if (!isDead) {
                    move();
                    lastMoveTime = frameCount;
                }
            }
            return 0;
        }
        case WM_CLOSE:
            DestroyWindow( hwnd );
        break;

        case WM_DESTROY:
            PostQuitMessage( 0 );
        break;

        default:
            return DefWindowProc( hwnd, msg, wParam, lParam );
    }

    return 0;
}
