//g++ -o windowsRender.exe windowsRender.cpp logic.obj -mwindows
//nasm -fwin64 -o logic.obj logic.asm
#include <windows.h>
#include <random>

LRESULT CALLBACK WndProc( HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam );
MSG Msg;
std::random_device rd;

extern "C" void init();
extern "C" unsigned char board[];

extern "C" void move(int x, int y);

#define BOARD_SIZE 64
#define CELL_SIZE 16
#define GAP_SIZE 1
int WINAPI WinMain( HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow )
{
    std::mt19937 gen(rd());
    //from assembly
    init();



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

    //Msg loop
    while( GetMessage( & Msg, NULL, 0, 0 ) )
    {
        TranslateMessage( & Msg );
        DispatchMessage( & Msg );
    }
    return Msg.wParam;
}
LRESULT CALLBACK WndProc( HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam )
{
    switch( msg )
    {
        case WM_KEYDOWN:
            switch (wParam) {
                case VK_UP:
                  move(0, 1);
                break;
                case VK_DOWN:
                    move(0, -1);
                break;
                case VK_LEFT:
                    move(-1, 0);
                break;
                case VK_RIGHT:
                      move(1, 0);
                break;
                default:
                break;
            }
        break;
        case WM_PAINT: {
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hwnd, &ps);

            //Background
            HBRUSH backgroundBrush = CreateSolidBrush(RGB(232, 232, 232));
            RECT backgroundRect = { 0, 0, ps.rcPaint.right, ps.rcPaint.bottom };
            FillRect(hdc, &backgroundRect, backgroundBrush);
            DeleteObject(backgroundBrush);

            int gridWidth = (BOARD_SIZE * CELL_SIZE) + ((BOARD_SIZE - 1) * GAP_SIZE);
            int gridHeight = (BOARD_SIZE * CELL_SIZE) + ((BOARD_SIZE - 1) * GAP_SIZE);

            RECT clientRect;
            GetClientRect(hwnd, &clientRect);
            int clientWidth = clientRect.right - clientRect.left;
            int clientHeight = clientRect.bottom - clientRect.top;

            int offsetX = (clientWidth - gridWidth) / 2;
            int offsetY = (clientHeight - gridHeight) / 2;

            //Grid
            for (int i = 0; i < BOARD_SIZE; i++) {
                for (int j = 0; j < BOARD_SIZE; j++) {
                    int value = board[i * BOARD_SIZE + j];
                    HBRUSH brush;

                    if(value == 1) // food
                        brush = CreateSolidBrush(RGB(255, 46, 46));
                    else // Empty cell
                        brush = CreateSolidBrush(RGB(255, 255, 255));

                    RECT cell = {
                        offsetX + j * (CELL_SIZE + GAP_SIZE) ,
                        offsetY + i * (CELL_SIZE + GAP_SIZE) ,
                        offsetX + j * (CELL_SIZE + GAP_SIZE) + CELL_SIZE,
                        offsetY + i * (CELL_SIZE + GAP_SIZE) + CELL_SIZE
                    };
                    FillRect(hdc, &cell, brush);
                    DeleteObject(brush);
                }
            }

            //Snake
            for (int i = 0; i < BOARD_SIZE; i++) {
                for (int j = 0; j < BOARD_SIZE; j++) {
                    int value = board[i * BOARD_SIZE + j];
                    HBRUSH brush;

                    if (value == 4) // Snake head
                        brush = CreateSolidBrush(RGB(0, 255, 0));
                    else if (value == 2) // Snake tail
                        brush = CreateSolidBrush(RGB(0, 200, 0));

                    RECT cell = {
                        offsetX + j * (CELL_SIZE + GAP_SIZE) ,
                        offsetY + i * (CELL_SIZE + GAP_SIZE) ,
                        offsetX + j * (CELL_SIZE + GAP_SIZE) + CELL_SIZE,
                        offsetY + i * (CELL_SIZE + GAP_SIZE) + CELL_SIZE
                    };
                    FillRect(hdc, &cell, brush);
                    DeleteObject(brush);
                }
            }

            EndPaint(hwnd, &ps);
        } break;
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