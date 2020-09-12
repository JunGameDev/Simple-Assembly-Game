;-------------------------------------------------------------------------------------------------------------------------
; Simple Assembly game
; Copyright (c) 2020 Junyoung Kim. All rights resevered.
;
; [ How to play ]
; W = Move player character to up side
; A = Move player character to left side
; S = Move player character to down side
; D = Move player character to right side
;
; [ Game Objects ]
; G = Player character
; T = Trap
; E = Enemy AI
; X = Goal
;
; [ Notice! ]
; In order to play this game, following environment is required.
; - Windows
; - Visual Studio(2017+)
; - Developer CMD or Powershell for Visual studio 2017+
;
; [ Compilation Steps ]
; 1. Open up 'Developer CMD or Powershell for visual studio 2017+'.
; 2. Change directory to where this file located.
; 3. Type following pCommand between "".
;    "./masm.bat SimpleGame.asm"
;
; [ Launching ]
; After the compilation, you should be able to see 'SimpleGame.exe'.
; Click that file. If Windows Virus & threat Detection sent you a message, please allow it to launch the game.
;
;-------------------------------------------------------------------------------------------------------------------------

.586
.model  flat, stdcall, C
option casemap:none

; Link in the CRT.
includelib libcmt.lib
includelib libvcruntime.lib
includelib libucrt.lib
includelib legacy_stdio_definitions.lib
;includelib msvcrt.lib
;includelib kernel32.lib
extern printf:NEAR
extern scanf:NEAR
extern _getch:NEAR
extern rand:NEAR
extern srand:NEAR
extern time:NEAR

system PROTO, pCommand:PTR BYTE

.data
; TODO: Data goes here.
    g_kMapWidth EQU 8
    g_kMapHeight EQU 8
    g_kNumOfTraps EQU 3
    g_kNumOfEnemies EQU 2
    g_playerPosX dd  0 ; Initial x position of player
    g_playerPosY dd  0 ; Initial y position of player
    g_trapPosX dd ?
    g_trapPosY dd ?
    g_tempPosX dd 5
    g_tempPoxY dd 5
    g_treasureX dd 7
    g_treasureY dd 7
    g_keepPlaying dd  1
    g_wrongInputMsg db "Wrong Input!", 0Ah, 0
    g_keyMessage0 db "W,w = Moving up", 0Ah, 0
    g_keyMessage1 db "S,s = Moving down", 0Ah, 0
    g_keyMessage2 db "A,a = Moving left", 0Ah, 0
    g_keyMessage3 db "D,d = Moving right", 0Ah, 0
    g_keyMessage4 db "Esc = quit", 0Ah, 0
    g_winMessage db "You Win!", 0Ah, 0
    g_loseMessage db "You lose!", 0Ah, 0
    g_enemeisX dd 3, 3   
    g_enemeisY dd 5, 5
    g_consoleClear BYTE "cls", 0
    g_posXMsg db "X: %d", 0Ah, 0
    g_posYMsg db "Y: %d", 0Ah, 0
.code

; EAX, EBX, ECS, EDX => 32-bit
; dword, dd => 32-bit
; byte, db => 8-bit;
; word, dw => 16-bit;

FunctionPrologue MACRO
    push ebp
    mov ebp, esp
ENDM

FunctionEpilogue MACRO NumBytesToDeallocateFromStack
    mov esp, ebp
    pop ebp
    ret NumBytesToDeallocateFromStack
ENDM

main proc C
    ; Get seed
    push 0
    call time
    add esp,4

    push eax
    call srand
    add esp, 4

    call Initialize

    .WHILE g_keepPlaying != 0
        call ClearConsole
        call PrintMap
        call CheckVictoryCondition
        cmp g_keepPlaying, 0
        je ENDGAME
        call GetInput
        call MoveEnemeies
    .ENDW
ENDGAME:
    xor eax, eax
    ret
main endp
;-----------------------------------------
; Initialize the game
;-----------------------------------------
Initialize PROC
    FunctionPrologue
    push edx
    push edi

    ;int 3
    mov edi, 0
    ;int 3
    .WHILE edi < 3   
        push 4
        call GetRandomNum
        mov g_trapPosX[edi * 4], eax

        push 8
        call GetRandomNum
        mov g_trapPosY[edi * 4], eax

        inc edi
    .ENDW
    
    pop edx
    pop edi
    FunctionEpilogue
Initialize ENDP

;-----------------------------------------
; Get random number
;-----------------------------------------
GetRandomNum PROC
    FunctionPrologue
    call rand
    add esp, 4

    mov dx, 0
    mov bx, [ebp+8]
    idiv bx
    mov ax, dx
    inc ax
    FunctionEpilogue 0
GetRandomNum ENDP

;-----------------------------------------
; Get input from player
;-----------------------------------------
GetInput PROC
    FunctionPrologue
    push edi
    push ecx
    push edx

    call _getch
    ;int 3
    cmp eax, 01Bh
    jne CheckInput

SetEscapeFlag:
    mov g_keepPlaying, 0
    jmp PostInput

CheckInput:
    ; if(input == 'W' || input == 'w')
    cmp eax, 057h
    je MovePlayerUp
    cmp eax, 077h
    je MovePlayerUp

    ; if(input == 'S' || input == 's')
    cmp eax, 053h
    je MovePlayerDown
    cmp eax, 073h
    je MovePlayerDown

    ; if(input == 'A' || input == 'a')
    cmp eax, 041h
    je MovePlayerLeft
    cmp eax, 061h
    je MovePlayerLeft

    ; if(input == 'D' || input == 'd')
    cmp eax, 044h
    je MovePlayerRight
    cmp eax, 064h
    je MovePlayerRight
    jmp WrongInput

MovePlayerUp:
    push g_playerPosY
    push eax
    call CheckBoundary
    cmp eax, 1
    jne PostInput
    dec g_playerPosY
    jmp PostInput

MovePlayerDown:
    push g_playerPosY
    push eax
    call CheckBoundary
    cmp eax, 1
    jne PostInput
    inc g_playerPosY
    jmp PostInput

MovePlayerRight:
    push g_playerPosX
    push eax
    call CheckBoundary
    cmp eax, 1
    jne PostInput
    inc g_playerPosX
    jmp PostInput

MovePlayerLeft:
    push g_playerPosX
    push eax
    call CheckBoundary
    cmp eax, 1
    jne PostInput
    dec g_playerPosX
    jmp PostInput
        
WrongInput:
    call PrintWrongInputMessage
PostInput:
    pop edx
    pop ecx
    pop edi

    FunctionEpilogue 0
GetInput ENDP

;------------------------------------------
; Print message when player pressed wrong
; key.
;------------------------------------------
PrintWrongInputMessage PROC
    FunctionPrologue
    push offset g_wrongInputMsg
    call printf
    add esp, 4
    push offset g_keyMessage0
    call printf
    add esp, 4
    push offset g_keyMessage1
    call printf
    add esp, 4
    push offset g_keyMessage2
    call printf
    add esp, 4
    push offset g_keyMessage3
    call printf
    add esp, 4
    push offset g_keyMessage4
    call printf
    add esp, 4
    FunctionEpilogue 0
PrintWrongInputMessage ENDP

;------------------------------------------
; Checking boundary function
;------------------------------------------
CheckBoundary PROC
    FunctionPrologue
    ; Checking moving dsirection
    ;int
    cmp dword ptr [ebp+8], 077h
    je Up
    cmp dword ptr [ebp+8], 073h
    je Down
    cmp dword ptr [ebp+8], 061h
    je Left
    cmp dword ptr [ebp+8], 064h
    je Right

Left:
    cmp dword ptr [ebp+12], 0
    jle False
    jmp True
Right:
    cmp dword ptr [ebp+12], [g_kMapWidth - 1]
    jge False
    jmp True
Up:
    cmp dword ptr [ebp+12], 0
    jg True
    jmp False    
Down:
    cmp dword ptr [ebp+12], [g_kMapHeight - 1]
    jge False
    jmp True

True:
    mov eax, 1
    jmp PostCheck
False:
    MOV eax, 0
PostCheck:

    FunctionEpilogue 0
CheckBoundary ENDP

;------------------------------------------
; Printing map
;------------------------------------------
PrintMap PROC
    ; Prologue
    FunctionPrologue
    ;[esp] <- ebp
    push ecx
    push edx

    mov ecx, 0

LoopMapHeight:  ; loop through the height of the maze
    mov edx, 0

LoopMapWidth:
    ;int 3
    push ecx
    push edx
    call CheckTile
    pop edx
    pop ecx
        
    inc edx
    cmp edx, dword ptr [g_kMapWidth]
    jnz LoopMapWidth
        
    call PrintNewline
    inc ecx
    cmp ecx, dword ptr [g_kMapWidth]
    jnz LoopMapHeight 

PostLoop:
    FunctionEpilogue 0 
PrintMap ENDP

;------------------------------------------
; Clear console screen 
;------------------------------------------
ClearConsole PROC
    FunctionPrologue
    INVOKE system, ADDR g_consoleClear
    FunctionEpilogue
ClearConsole ENDP

;------------------------------------------
; CheckTile(int x, int y) 
;------------------------------------------
CheckTile PROC
    FunctionPrologue
    ; push all the general purpose registers this function could overwrite
    ;int 3
    push ecx
    push edx
    push edi

    mov ecx, [ebp + 12] ; y Position
    mov edx, [ebp + 8] ; x Position
    ; if(y == g_playerPosY)
    ;     jump CheckPlayerX
    cmp ecx, g_playerPosY
    jne CheckTrap
    cmp edx, g_playerPosX
    je Player
    
CheckTrap:
    ; if(y == g_tempTrapPosY)
    ;     jump CheckTrapX
    mov edi, 0
    ;int 3
    .WHILE edi < g_kNumOfTraps
        cmp ecx, g_trapPosY[edi * 4]
        jne PostCheckingTrap

        cmp edx, g_trapPosX[edi * 4]
        jne PostCheckingTrap
        jmp Trap

        PostCheckingTrap:
        inc edi   
    .ENDW
    jmp CheckTreasure

CheckTreasure:
    cmp ecx, g_treasureY
    jne CheckEnemy
    cmp edx, g_treasureX
    je Treasure

CheckEnemy:
    mov edi, 0

    .WHILE edi < g_kNumOfEnemies
        cmp ecx, g_enemeisY[edi * 4]
        jne PostCheckingEnemy

        cmp edx, g_enemeisX[edi * 4]
        jne PostCheckingEnemy
        jmp Enemy

        PostCheckingEnemy:
        inc edi   
    .ENDW
    jmp Tile

Player:
    call PrintPlayer
    jmp PostPrint

Tile:
    call PrintEmpty
    jmp PostPrint
    
Trap:
    call PrintTrap
    jmp PostPrint

Treasure:
    call PrintTreasrue
    jmp PostPrint

Enemy:
    call PrintEnemy
    jmp PostPrint

PostPrint:
    ; restore general purpose registers
    pop edi
    pop edx
    pop ecx

    FunctionEpilogue
CheckTile ENDP

;------------------------------------------
; Printing player character 
;------------------------------------------
CheckVictoryCondition PROC
    FunctionPrologue
    
    push ecx
    push edx
    push edi

    mov ecx, g_playerPosY
    mov edx, g_playerPosX

    cmp ecx, g_treasureY
    jne CheckTrap
    cmp edx, g_treasureX
    je Victory

CheckTrap:

    mov edi, 0

    .WHILE edi < g_kNumOfTraps
        cmp ecx, g_trapPosY[edi * 4]
        jne PostCheckingX

        cmp edx, g_trapPosX[edi * 4]
        jne PostCheckingX
        jmp Lose

        PostCheckingX:
        inc edi   
    .ENDW
    jmp CheckEnemyPosition

CheckEnemyPosition:
    mov edi, 0

    .WHILE edi < g_kNumOfEnemies
        cmp ecx, dword ptr g_enemeisY[edi * 4]
        jne PostCheckingEnemy

        cmp edx, dword ptr g_enemeisX[edi * 4]
        jne PostCheckingEnemy
        jmp Lose

        PostCheckingEnemy:
        inc edi   
    .ENDW

    jmp PostCheck

Victory:
    push offset g_winMessage
    call printf
    add esp, 4
    mov g_keepPlaying, 0
    jmp PostCheck

Lose:
    push offset g_loseMessage
    call printf
    add esp, 4
    mov g_keepPlaying, 0
    jmp PostCheck

PostCheck:
    pop edi
    pop edx
    pop ecx
    FunctionEpilogue
CheckVictoryCondition ENDP

;------------------------------------------
; Printing player character 
;------------------------------------------
PrintPlayer PROC
    FunctionPrologue

    sub esp, 3
    mov byte ptr[ebp-3], 047h ; G
    mov byte ptr[ebp-2], 020h ; \n
    mov byte ptr[ebp-1], 0

    ; push all the general purpose registers this function could overwrite
    push edi
    push ecx
    push edx

    ; push the address of the string to printf
    mov edi, ebp
    sub edi, 3
    push edi

    ; call printf and reset the stack
    call printf
    add esp, 4

    ; restore registers
    pop edx
    pop ecx
    pop edi

    FunctionEpilogue 0
PrintPlayer ENDP

;------------------------------------------
; Moving enemy ai
;------------------------------------------
MoveEnemeies PROC
    FunctionPrologue

    push ecx
    push edx
    push edi

    mov ecx, g_playerPosY
    mov edx, g_playerPosX
    mov edi, 0

    ;int 3
    .WHILE edi < g_kNumOfEnemies
        cmp ecx, g_enemeisY[edi * 4]
        jne Move 

        cmp edx, g_enemeisX[edi * 4]
        jne Move
    CheckingEnemies:
        inc edi   
    .ENDW

    jmp PostMoveEnemies

Move:
    push 4
    call GetRandomNum

    cmp eax, 1
    je MoveUp

    cmp eax, 2
    je MoveDown

    cmp eax, 3
    je MoveRight

    cmp eax, 4
    je MoveLeft

    jmp CheckingEnemies
    ;int 3
MoveUp:
    ; push g_playerPosY
    ; push eax
    ; call CheckBoundary
    ; cmp eax, 1

    push dword ptr g_enemeisY[edi * 4]
    push dword ptr 077h
    call CheckBoundary
    ;int 3
    cmp eax, 1
    jne CheckingEnemies
    dec dword ptr g_enemeisY[edi * 4]
    cmp g_enemeisY[edi * 4], 0
    jle MoveUpAdjust
    jmp CheckingEnemies

MoveUpAdjust:
    mov dword ptr g_enemeisY[edi * 4], 1

    jmp CheckingEnemies

MoveDown:
    push dword ptr g_enemeisY[edi * 4]
    push dword ptr 073h
   ; int 3
    call CheckBoundary
    cmp eax, 0
   ; int 3
    je CheckingEnemies
    inc dword ptr g_enemeisY[edi * 4]
    jmp CheckingEnemies

MoveRight:

    push dword ptr g_enemeisX[edi * 4] + 1
    push dword ptr 064h
   ; int 3
    call CheckBoundary
    cmp eax, 0
    ;int 3
    je CheckingEnemies
    inc dword ptr g_enemeisX[edi * 4]
    cmp dword ptr g_enemeisX[edi * 4], g_kMapWidth 
    jmp CheckingEnemies

MoveLeft:

    push dword ptr g_enemeisX[edi * 4]
    push dword ptr 061h
   ; int 3
    call CheckBoundary
    cmp eax, 0
    ;int 3
    je CheckingEnemies
    dec g_enemeisY[edi * 4]
    jmp CheckingEnemies

PostMoveEnemies:
    call AdjustEnemyLocation

    pop edi
    pop edx
    pop ecx
    FunctionEpilogue
MoveEnemeies ENDP

AdjustEnemyLocation PROC
    FunctionPrologue
    push edi
    mov edi, 0

    .WHILE edi < g_kNumOfEnemies
        cmp g_enemeisY[edi * 4], 1
        jnl PostAdjustY
        mov g_enemeisY[edi * 4], 1
    PostAdjustY:
        cmp g_enemeisX[edi * 4], g_kMapWidth
        jl PostAdjustX
        mov g_enemeisX[edi * 4], 6
    PostAdjustX:
        inc edi   
    .ENDW

    pop edi
    FunctionEpilogue
AdjustEnemyLocation ENDP


;------------------------------------------
; Printing trap
;------------------------------------------
PrintTrap PROC
    FunctionPrologue

    sub esp, 3
    mov byte ptr[ebp-3], 054h ; T
    mov byte ptr[ebp-2], 020h ; \n
    mov byte ptr[ebp-1], 0
    
    ; push all the general purpose registers this function could overwrite
    push edi
    push ecx
    push edx

    ; push the address of the string to printf
    mov edi, ebp
    sub edi, 3
    push edi

    ; call printf and reset the stack
    call printf
    add esp, 4

    ; restore registers
    pop edx
    pop ecx
    pop edi

    FunctionEpilogue 0
PrintTrap ENDP

;------------------------------------------
; Printing Treasure
;------------------------------------------
PrintTreasrue PROC
    FunctionPrologue

    sub esp, 3
    mov byte ptr[ebp-3], 058h ; X
    mov byte ptr[ebp-2], 020h ; \n
    mov byte ptr[ebp-1], 0
    
    ;[0]
    ;[\n]
    ;[G]

    ; push all the general purpose registers this function could overwrite
    push edi
    push ecx
    push edx

    ; push the address of the string to printf
    mov edi, ebp
    sub edi, 3
    push edi

    ; call printf and reset the stack
    call printf
    add esp, 4

    ; restore registers
    pop edx
    pop ecx
    pop edi

    FunctionEpilogue 0
PrintTreasrue ENDP

;------------------------------------------
; Printing Enemy
;------------------------------------------
PrintEnemy PROC
    FunctionPrologue
    sub esp, 3
    mov byte ptr[ebp-3], 045h ; E
    mov byte ptr[ebp-2], 020h ; \n
    mov byte ptr[ebp-1], 0

    ; push all the general purpose registers this function could overwrite
    push edi
    push ecx
    push edx

    ; push the address of the string to printf
    mov edi, ebp
    sub edi, 3
    push edi

    ; call printf and reset the stack
    call printf
    add esp, 4

    ; restore registers
    pop edx
    pop ecx
    pop edi

    FunctionEpilogue
PrintEnemy ENDP


;------------------------------------------
; Printing Tile
;------------------------------------------
PrintEmpty PROC
    FunctionPrologue

    sub esp, 3
    mov byte ptr[ebp-3], 02eh ; .
    mov byte ptr[ebp-2], 020h ; \n
    mov byte ptr[ebp-1], 0
    
    ;[0]
    ;[\n]
    ;[.]

    ; push all the general purpose registers this function could overwrite
    push edi
    push ecx
    push edx

    ; push the address of the string to printf
    mov edi, ebp
    sub edi, 3
    push edi

    ; call printf and reset the stack
    call printf
    add esp, 4

    ; restore registers
    pop edx
    pop ecx
    pop edi

    FunctionEpilogue 0
PrintEmpty ENDP

;======================================================================================================================
; Helper Functions

; Prints the value of EAX as a decimal number.  EAX is not modified by this call.
PrintEax PROC
        ; set the up the stack
        push ebp
        mov ebp, esp

        ; string to print: "%d\n"
        sub esp, 4
        mov byte ptr[ebp-4], 25h
        mov byte ptr[ebp-3], 64h
        mov byte ptr[ebp-2], 0Ah
        mov byte ptr[ebp-1], 0

        ; push all the general purpose registers this function could overwrite
        push edi
	push ecx
	push edx

        ; push the eax parameter to printf
        push eax

        ; push the address of the string to printf
        mov edi, ebp
        sub edi, 4
        push edi

        ; call printf
	call printf

        ; Only reset the stack by one parameter manually, then pop off the eax parameter so it remains the 
        ; same.  printf often changes it.
        add esp, 4
        pop eax

        ; restore registers
	pop edx
	pop ecx
        pop edi

        ; fully reset the stack and base pointers to whatever they were
        mov esp, ebp
        pop ebp

	ret
PrintEax ENDP


; Prints a single newline character.
PrintNewline PROC
        ; set the up the stack
        push ebp
        mov ebp, esp

        ; string to print: "\n"
        sub esp, 2
        mov byte ptr[ebp-2], 0Ah
        mov byte ptr[ebp-1], 0

        ; push all the general purpose registers this function could overwrite
        push edi
	push ecx
	push edx

        ; push the address of the string to printf
        mov edi, ebp
        sub edi, 2
        push edi

        ; call printf and reset the stack
	call printf
        add esp, 4

        ; restore registers
	pop edx
	pop ecx
        pop edi

        ; fully reset the stack and base pointers to whatever they were
        mov esp, ebp
        pop ebp

	ret
PrintNewline ENDP

; Calls scanf to get a number from the user.  This will be saved in eax.
GetNumber PROC
        ; set the up the stack
        push ebp
        mov ebp, esp
		
	; seven bytes worth of local data
        sub esp, 7

        ; string sent to scanf: "%d"
        mov byte ptr[ebp-3], 25h
        mov byte ptr[ebp-2], 64h
        mov byte ptr[ebp-1], 0
		
        ; push all the general purpose registers this function could overwrite
	push ecx
	push edx
        push edi
		
	; push the address of output variable
        mov edx, ebp
        sub edx, 7
	mov dword ptr[edx], 0  ; initialize the output
        push edx
		
	; push the address of the scanf string
        mov edi, ebp
        sub edi, 3
        push edi

        ; call printf
	call scanf

        ; Reset the stack after the call to scanf
        add esp, 4
	pop edx  ; we need to pop this off the stack because it was likely overwritten
		
	; Our local contains the input, so set eax
	mov eax, [edx]

        ; restore general purpose registers
        pop edi
	pop edx
	pop ecx

        ; fully reset the stack and base pointers to whatever they were
        mov esp, ebp
        pop ebp

	ret
GetNumber ENDP

;======================================================================================================================
END
