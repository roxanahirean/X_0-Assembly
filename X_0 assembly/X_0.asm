.386
.model flat, stdcall

;Including libraries
includelib msvcrt.lib
includelib canvas.lib

;Including procedures
extern exit: proc
extern malloc: proc
extern memset: proc
extern printf: proc
extern BeginDrawing: proc

;Starting execution
public start

;Declaring and initializing data
.data
;Window settings
window_title DB "X_O assembly", 0;Window's title
area_width EQU 400 ;Window's width
area_height EQU 300 ;Window's height
area_position_x DD 100 ;Window's start position x
area_position_y DD 100 ;Windows's start position y
area DD 0
box_width EQU 40 ;Box's width
box_height EQU 39 ;Box's height

;Matrix settings
matrix DD 0,0,0,0,0,0,0,0,0 ;Initialize matrix
matrix_row DD 0 ;Allocate memory for storing current matrix row number
matrix_column DD 0 ;Allocate memory for storing current matrix collumn number

current_player DD 0;0 - player 0, 1 - player X
possible_moves_number DD 9  ;Number of possible moves

;Declaring and initializing stack positions (relative to ebp)
arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20

;Including images
include digits.inc
include letters.inc
include X_O.inc

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - symbol
; arg2 - matrix pointer 
; arg3 - x position
; arg4 - y position 
		
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ;Getting symbol
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2];pointer to matrix
	mov eax, [ebp+arg4];y position
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ;x position
	shl eax, 2 ;Multiplying iwth 4 because each pixel sizes 1 DWORD
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:   ;stabilesc culoarea la text
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0h ;Text color
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], -1 ;Text background
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

draw_symbol proc   
	push ebp
	mov ebp,esp
	pusha

	mov eax, [ebp + arg1]  ;Get symbol
	cmp eax, 'X'
	jne try_draw_O
	;Draw X
	sub eax, 'X'
	lea esi, X_O
	jmp deseneaza_X_O
try_draw_O:
	;Draw 0
	mov eax, 1 ;Second symbol from X_O.inc
	lea esi, X_O
deseneaza_X_O:
	mov ebx, box_height
	mul ebx
	mov ebx, box_height
	mul ebx
	add esi, eax
	mov ecx, box_height
bucla_simbol_linii_X_O:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, box_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, box_height
bucla_simbol_coloane_X_O:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb_X_O
	mov edx, 000000h
	mov dword ptr [edi], edx
	jmp simbol_pixel_next_X_O
simbol_pixel_alb_X_O:
	mov dword ptr [edi], 0FFFEFFh ;fundal patrat cu simbol 
simbol_pixel_next_X_O:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane_X_O
	pop ecx
	loop bucla_simbol_linii_X_O
	popa
	mov esp, ebp
	pop ebp
	ret
draw_symbol endp

;Drawing symbol
make_text_macro_X_O macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call draw_symbol
	add esp, 16
endm

draw_vertical_line macro x, y
LOCAL keep_drawing_line, stop_drawing_line
	pusha
	xor eax, eax
	mov eax, x
	mov ebx, area_width
	mul ebx
	add eax, y
	shl eax, 2
	mov ecx, 0
keep_drawing_line:
	add eax, 1599
	mov ebx, [area]  ;colt stanga sus, de unde incepe chenarul
	add ebx, ecx
	mov dword ptr [ebx+eax], 0h ;colorez fiecare pixel de pe linia verticala cu negru
	inc ecx
	inc ecx
	cmp ecx, 120
	je stop_drawing_line
	loop keep_drawing_line
stop_drawing_line:
	popa
endm

draw_horizontal_line macro x, y
local keep_drawing_line, stop_drawing_line
	pusha
	mov eax, 0
	mov eax, x
	mov ebx, area_width
	mul ebx
	add eax, y
	shl eax, 2
	mov ecx, 0
keep_drawing_line:
	mov ebx, [area]
	add ebx, ecx
	mov dword ptr [ebx+eax], 0h
	inc ecx
	inc ecx
	cmp ecx, 480
	je stop_drawing_line
	loop keep_drawing_line
stop_drawing_line:
	popa
endm

add_values_to_matrix proc
	push ebp
	mov ebp, esp
	push ebx
	push ecx
	mov eax, [ebp+arg1]
	mov ebx, 4
	mul ebx
	mov esi, eax			
	mov eax, [ebp+arg2]
	mul ebx
	mov ebx, eax
	mov eax, 3				
	mul ebx
	mov ebx, eax
	mov eax, matrix[ebx+esi]	; matrix[poztitie]
	cmp eax, 0 ; verifica daca pozitia este ocupata sau nu
	jne jump
	mov ecx, [ebp+arg3] 
	cmp ecx, 0 ;verifica ce simbol are de afisat
	jne este_X
este_0:
	mov eax, 2
	mov matrix[ebx+esi], eax
	mov eax, 0
	jmp jump
este_X:
	mov eax, 1
	mov matrix[ebx+esi], eax
	mov eax, 0
	jmp jump
jump:
	pop ecx
	pop ebx
	mov esp, ebp
	pop ebp
	ret
add_values_to_matrix endp	


check_line_win proc

	push ebp
	mov ecx, 3					; parcurgem intr-un for coloana de jos in sus, si in celalalt for linia de jos in sus
	for1:
		mov ebp, ecx
		mov ebx, ecx			; aflam baza (ebx) a matricei; Adica X din [X,Y] defapt EBX din pozitie [ebx + esi]
		dec ebx
		mov eax, 4
		mul ebx
		mov ebx, 3
		mul ebx
		mov ebx, eax
		mov ecx, 2
		mov edi, matrix[ebx + 8]
			for2:
			mov eax, 4		; aflam index-ul- esi a matricei
			dec ecx
			mul ecx
			inc ecx
			mov esi, eax
			mov edx, matrix[ebx + esi]
			cmp edi, edx
			jne draw_XO
			loop for2
		
			
		cmp edi, 0
		je draw_XO
		cmp edi, 1
		je won_X
won_o:
		mov eax, 2
		jmp final_verification
won_X:
		mov eax, 1
		jmp final_verification
draw_XO:
		mov ecx, ebp
		loop for1
		mov eax, 0
final_verification:
	pop ebp
	ret
check_line_win endp


check_column_win proc
	push ebp
	mov ecx, 3					; parcurgem intr-un for coloana de jos in sus, si in celalalt for linia de jos in sus
		for1:
		mov ebp, ecx
		mov ebx, ecx			; aflam baza- edx a matricei
		dec ebx
		mov eax, 4
		mul ebx
		add eax, 24
		mov ecx, 2
		mov edi, matrix[eax]
			for2:
			sub eax, 12
			mov edx, matrix[eax]
			cmp edi, edx
			jne draw_XO
			loop for2
		cmp edi, 0
		je draw_XO
		cmp edi, 1
		je won_X
won_o:
		mov eax, 2
		jmp final_verification
won_X:
		mov eax, 1
		jmp final_verification
draw_XO:
		mov ecx, ebp
		loop for1
		mov eax, 0
final_verification:
	pop ebp
	ret
check_column_win endp

check_main_diagonal_win proc
	mov edi, matrix[0]
	cmp edi, matrix[16]
	jne draw_XO
	cmp edi, matrix[32]
	jne draw_XO
		cmp edi, 0
		je draw_XO
		cmp edi, 1
		je won_X
won_o:
		mov eax, 2
		jmp final_verification
won_X:
		mov eax, 1
		jmp final_verification
draw_XO:
		mov eax, 0
final_verification:
	ret
check_main_diagonal_win endp

check_secondary_diagonal_win proc
	mov edi, matrix[8]
	cmp edi, matrix[16]
	jne draw_XO
	cmp edi, matrix[24]
	jne draw_XO
		cmp edi, 0
		je draw_XO
		cmp edi, 1
		je won_X
won_o:
		mov eax, 2
		jmp final_verification
won_X:
		mov eax, 1
		jmp final_verification
draw_XO:
		mov eax, 0
final_verification:
	ret
check_secondary_diagonal_win endp

check_winner proc
		call check_line_win
		cmp eax, 0
		jne final_verification
		call check_column_win
		cmp eax, 0
		jne final_verification
		call check_main_diagonal_win
		cmp eax, 0
		jne final_verification
		call check_secondary_diagonal_win
final_verification:
	ret
check_winner endp


xo_algorithm proc
	;Change player's turn
	mov edx, 1				
	sub edx, current_player
	mov current_player, edx 
	
	;Get clicked matrix box's column number    ; ca sa aflu pe ce coloana din cutie sunt
	mov edx, 0
	mov ecx, box_width
	mov eax, [ebp+arg2]		
	sub eax, area_position_x
	div ecx
	mov matrix_column, eax
	
	;Get clicked matrix box's row number
	mov edx, 0
	mov ecx, box_width
	mul ecx
	mov ebx, eax
	add ebx, area_position_x
	add ebx, 1
	mov eax, [ebp+arg3]
	sub eax, area_position_y
	div ecx
	mov matrix_row, eax
	mov ecx, box_width
	mul ecx
	add eax, area_position_y
	add eax, 1
	
	;Adding values to matrix
	mov ecx, eax   ; in eax am prima coord a casetei in care apas click 			
	push current_player
	push matrix_row
	push matrix_column
	call add_values_to_matrix
	add esp, 12
	cmp eax, 0				
	je mark_box
	mov edx, 1				
	sub edx, current_player
	mov current_player, edx
	jmp end_player_turn
mark_box:
	cmp current_player, 1 ;1-player X, 0-player 0
	jne draw_0
	make_text_macro_X_O 'X', area, ebx, ecx
	jmp end_player_turn
draw_0:
	make_text_macro_X_O 'O', area, ebx, ecx
end_player_turn:
	ret
xo_algorithm endp

; Drawing function - applies to each click or at each 200 ms
; arg1 - evt (0 - initialization, 1 - click, 2 - no event)
; arg2 - x position
; arg3 - y position
	
draw proc
	push ebp
	mov ebp, esp
	pusha
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz print_window_text ; nu s-a efectuat click pe nimic
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255   
	push area
	call memset
	add esp, 12
	draw_horizontal_line 100, 100
	draw_horizontal_line 140, 100
	draw_horizontal_line 180, 100
	draw_horizontal_line 220, 100
	draw_vertical_line 100, 100
	draw_vertical_line 100, 140
	draw_vertical_line 100, 180
	draw_vertical_line 100, 220
	jmp print_window_text
	
evt_click:
	pusha
	;Lock completion the game was finished
	mov eax, [possible_moves_number]
	cmp eax, 0
	je print_window_text
	
	mov ebx,[ebp+arg2]  ;x
	mov edx,[ebp+arg3]  ;y
	
	;Lock selecting boxes outside the table
	cmp ebx, 100
	jl print_window_text
	cmp ebx, 220
	jg print_window_text
	cmp edx, 100
	jl print_window_text
	cmp edx, 220
	jg print_window_text
	
	mov ecx, possible_moves_number ; possible_moves_number e 9 la inceput, pentru ca sunt 9 casute
	call xo_algorithm ; use xo_algorithm
	cmp eax, 0 ; 0 - box was empty, 1 - box had X, 2 - box had 0
	jne keep_completed_boxes_number ; keep the number of completed boxes
	dec possible_moves_number
	jmp check_winner_label
	keep_completed_boxes_number:
		mov ecx, possible_moves_number ; ca sa nu se decrementeze ecx
	check_winner_label:
		call check_winner
		cmp eax, 1
		je won_X
		cmp eax ,2
		je won_o
		jmp print_window_text
	 
			
	won_o:	
		make_text_macro 'O', area, 130, 230
		make_text_macro ' ', area, 140, 230
		make_text_macro 'W', area, 150, 230
		make_text_macro 'O', area, 160, 230
		make_text_macro 'N', area, 170, 230
		mov possible_moves_number, 0
		jmp print_window_text
	
	won_X:
		make_text_macro 'X', area, 130, 230
		make_text_macro ' ', area, 140, 230
		make_text_macro 'W', area, 150, 230
		make_text_macro 'O', area, 160, 230
		make_text_macro 'N', area, 170, 230
		mov possible_moves_number, 0
		jmp print_window_text
		
		
print_window_text:	
	make_text_macro 'X', area, 130, 50
	make_text_macro ' ', area, 140, 50
	make_text_macro 'A', area, 150, 50
	make_text_macro 'N', area, 160, 50
	make_text_macro 'D', area, 170, 50
	make_text_macro ' ', area, 180, 50
	make_text_macro 'O', area, 190, 50
	
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	; Allocating memory for drawing area
	mov eax, area_width
	mov ebx, area_height
	mul ebx ; Got number of pixels
	shl eax, 2 ; Multiply by 4 because each pixel sizes 1 DWORD
	push eax
	call malloc ; Allocate memory
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	;terminarea programului
	push 0
	call exit
end start