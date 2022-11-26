.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern printf: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
format db "%d" ,13, 10 , 0
window_title DB "X si 0", 0
area_width EQU 400 ;dimensiunea tablei de joc
area_height EQU 300 ;dimensiunea tablei de joc
area DD 0
counter DD 0
matrice DD 9 dup(0)

X0 DD 100 ;colt stanga sus de unde incepe tabla de joc desenata
Y0 DD 100 ;colt stanga sus de unde incepe tabla de joc desenata

X_matrice DD 0
Y_matrice DD 0

X_O_width EQU 40 ;dimensiune patrat din tabel
X_O_height EQU 39 ;dimensiune patrat din tabel

verifica_afara DD 0  ;tratam ca un boolean, daca s-a dat click in afara tablei = 0
culoare_simb DD 0

verificare_X_O DD 0
numarator DD 9  ;totalul de miscari valide posibile pe tabla (9 patratele, 9 mutari), adica in total se pot desena maxim 9 simboluri
constanta_patru DD 4   ;ca sa se poata efectua operatiile de tip mul cu 4
constanta_zero EQU 0

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20

include digits.inc
include letters.inc
include X_O.inc

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
		
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
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
	mov eax, 26 ; de la 0 pana la 26 sunt litere, 27 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0ff1414h ;culoare scris
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0c1bce2h  ;fundal casute text
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

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

fa_X_O proc   
	;procedura pentru desenare simboluri
	push ebp
	mov ebp,esp
	pusha
fa_X:
	;desenam pe X in albastru
	mov eax, [ebp + arg1]  ;citim simbolul de afisat
	cmp eax, 'X'
	jne fa_O
	sub eax, 'X'
	lea esi, X_O
	mov culoare_simb, 04D79FFh ;selectam culearea pentru simbolul X
	jmp deseneaza_X_O
fa_O:
;desenam pe O in mov
	mov eax, 1   ;al doilea simbol de afisat din fisierul de X_O
	mov culoare_simb, 0B300B3h ;selectam culoarea pentru simbolul 0 
	lea esi, X_O
deseneaza_X_O:
	mov ebx, X_O_height
	mul ebx
	mov ebx, X_O_height
	mul ebx
	add esi, eax
	mov ecx, X_O_height
bucla_simbol_linii_X_O:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, X_O_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, X_O_height
bucla_simbol_coloane_X_O:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb_X_O
	mov edx, culoare_simb
	mov dword ptr [edi], edx
	jmp simbol_pixel_next_X_O
simbol_pixel_alb_X_O:
	mov dword ptr [edi], 0FFFF5Fh ;fundal patratel cu simbol 
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
fa_X_O endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro_X_O macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call fa_X_O
	add esp, 16
endm

in_tabla proc   ;se verifica daca s-a dat click in tabla, returneaza 'boolean' (returneaza_fals daca nu s-a dat click in tabla)
	;in EBX se afla X, in EDX se afla Y
	mov esi, edx
	cmp ebx, X0
	jl returneaza_fals
	mov eax, 3
	mov ecx, X_O_width
	mul ecx
	add eax, X0
	cmp ebx, eax
	jge returneaza_fals
	mov edx, esi
	cmp edx, Y0
	jl returneaza_fals
	mov eax, 3
	mov ecx, X_O_width
	mul ecx
	add eax, Y0
	mov edx, esi
	cmp edx, eax
	jge returneaza_fals
	mov eax, 1
	mov verifica_afara, eax        ; ne ajuta la pastrarea numarator(-ajuta la pastrarea nr de click-uri, in total 9 posibile pe tabla) daca click afara din casuta
	jmp afara
returneaza_fals:
	mov eax, 0
	mov verifica_afara, eax
afara:
	ret
in_tabla endp

transpunere_in_matrice proc
	push ebp
	mov ebp, esp
	push ebx
	push ecx
	mov eax, [ebp+arg1]
	mov ebx, 4
	mul ebx
	mov esi, eax			; X in coloana
	mov eax, [ebp+arg2]; !!! linia si coloa na se inverseaza mai jos, daca X=1, Y=0 atunci vom pune in 0,1
	mul ebx
	mov ebx, eax
	mov eax, 3				; Y in linie
	mul ebx
	mov ebx, eax
	mov eax, matrice[ebx+esi]	;matrice[poztitie]; pozitie = ebx * 3 + esi
	cmp eax, 0 ;VERIFICA DACA E SAU NU OCUPATA POZITIA
	jne iesire_transpunere_in_matrice
	mov ecx, [ebp+arg3] ;ia simbolul de afisat de pe stiva
	cmp ecx, 0 ;verifica ce simbol are de afisat
	jne este_X
este_0:
	mov eax, 2
	mov matrice[ebx+esi], eax
	mov eax, 0
	jmp aici
este_X:
	mov eax, 1
	mov matrice[ebx+esi], eax
	mov eax, 0
	jmp aici
iesire_transpunere_in_matrice:
	mov edx, 1				;evitam sa mai desenam o data simbolul peste altul daca e ocupata casuta
	sub edx, verificare_X_O
	mov verificare_X_O, edx
aici:
	pop ecx
	pop ebx
	mov esp, ebp
	pop ebp
	ret
transpunere_in_matrice endp	

verificare_castigator_linie proc
;se fac doua for-uri din dreapta jos pornind amandoua
	push ebp
	mov ecx, 3					; parcurgem intr-un for linia de jos in sus, si intr-unul coloana de jos in sus
	primul_for:
		mov ebp, ecx
		mov ebx, ecx			; aflam baza (ebx) a matricei; Adica X din [X,Y] defapt EBX din pozitie (ebx + esi)
		dec ebx
		mov eax, 4
		mul ebx
		mov ebx, 3
		mul ebx
		mov ebx, eax
		mov ecx, 2
		mov edi, matrice[ebx + 8]
	al_doilea_forlinie:
			mov eax, 4		; aflam index (esi) a matricei; Adica Y din [X,Y], adica ESI din pozitie (ebx+esi)
			dec ecx
			mul ecx
			inc ecx
			mov esi, eax
			mov edx, matrice[ebx + esi]
			cmp edi, edx
			jne remiza
			loop al_doilea_forlinie
		cmp edi, 0
		je remiza
		cmp edi, 1
		je castiga_X
castiga_O:
		mov eax, 2
		jmp final_verificare
castiga_X:
		mov eax, 1
		jmp final_verificare
remiza:
		mov ecx, ebp
		loop primul_for
		mov eax, 0
final_verificare:
	pop ebp
	ret
verificare_castigator_linie endp

verificare_castigator_coloana proc
	push ebp
	mov ecx, 3					; parcurgem intr-un for coloana de jos in sus, si in celalt linia de jos in sus
	primul_for:
		mov ebp, ecx
		mov ebx, ecx			; aflam baza (ebx) a matricei; Adica X din [X,Y] defapt EBX din pozitie (ebx + esi)
		dec ebx
		mov eax, 4
		mul ebx
		add eax, 24
		mov ecx, 2
		mov edi, matrice[eax]
	al_doilea_for_coloana:
			sub eax, 12
			mov edx, matrice[eax]
			cmp edi, edx
			jne remiza
			loop al_doilea_for_coloana
		cmp edi, 0
		je remiza
		cmp edi, 1
		je castiga_X
castiga_O:
		mov eax, 2
		jmp final_verificare
castiga_X:
		mov eax, 1
		jmp final_verificare
remiza:
		mov ecx, ebp
		loop primul_for
		mov eax, 0
final_verificare:
	pop ebp
	ret
verificare_castigator_coloana endp

verificare_castigator_diagonala1 proc
	mov edi, matrice[0]
	cmp edi, matrice[16]
	jne remiza
	cmp edi, matrice[32]
	jne remiza
		cmp edi, 0
		je remiza
		cmp edi, 1
		je castiga_X
castiga_O:
		mov eax, 2
		jmp final_verificare
castiga_X:
		mov eax, 1
		jmp final_verificare
remiza:
		mov eax, 0
final_verificare:
	ret
verificare_castigator_diagonala1 endp

verificare_castigator_diagonala2 proc
	mov edi, matrice[8]
	cmp edi, matrice[16]
	jne remiza
	cmp edi, matrice[24]
	jne remiza
		cmp edi, 0
		je remiza
		cmp edi, 1
		je castiga_X
castiga_O:
		mov eax, 2
		jmp final_verificare
castiga_X:
		mov eax, 1
		jmp final_verificare
remiza:
		mov eax, 0
final_verificare:
	ret
verificare_castigator_diagonala2 endp

verificare_castigator proc
		call verificare_castigator_linie
		cmp eax, constanta_zero
		jne final_verificare
		call verificare_castigator_coloana
		cmp eax, constanta_zero
		jne final_verificare
		call verificare_castigator_diagonala1
		cmp eax, constanta_zero
		jne final_verificare
		call verificare_castigator_diagonala2
final_verificare:
	ret
verificare_castigator endp

player_vs_player proc
	push ecx
	mov ebx,[ebp+arg2]		;verificare daca click-ul s-a dat pe tabla de joc
	mov edx,[ebp+arg3]
	push edx
	push ebx
	call in_tabla  ;returneaza in verifica_afara 1 daca click-ul a fost pe tabla sau 0 daca a fost afara
	add esp, 8
	cmp eax, 0
	je final_player
	mov edx, 1				
	;verificam ce simbol urmeaza scris; X sau O
	sub edx, verificare_X_O
	mov verificare_X_O, edx ;in urma scaderii lui 0 sau 1 din 1 se afla daca se afiseaza X sau 0
	;aflarea coordonatei X a casutei unde s-a dat click + 1
	xor edx, edx
	mov ecx, X_O_width
	mov eax, [ebp+arg2]		
	sub eax, X0
	div ecx
	mov X_matrice, eax
	mov ecx, X_O_width
	mul ecx
	mov ebx, eax
	add ebx, X0
	add ebx, 1
	;aflarea coordonatei Y a casutei unde s-a dat click + 1
	xor edx, edx
	mov eax, [ebp+arg3]
	sub eax, Y0
	div ecx
	mov Y_matrice, eax
	mov ecx, X_O_width
	mul ecx
	add eax, Y0
	add eax, 1
	;facem tranzitia la modelul matematic al tabelei, in matricea "matrice"
	mov ecx, eax			;plus verificare accesare casuta ocupata
	push verificare_X_O
	push Y_matrice
	push X_matrice
	call transpunere_in_matrice
	add esp, 12
	cmp eax, 0				; rezultatul proc transpunere_in_matrice, 0 - casuta libera, 1 - ocupat cu X, 2- ocupat O
	jne final_player
	cmp verificare_X_O, 1 ;1-deseneaza X, 0-deseneaza 0
	jne draw_0
	make_text_macro_X_O 'X', area, ebx, ecx
	jmp final_player
draw_0:
	make_text_macro_X_O 'O', area, ebx, ecx
final_player:
	pop ecx
	ret
player_vs_player endp

play_again proc 
	cmp ebx, 280 ;verifica daca s-a dat click pe casuta "play again"
	jl afara
	cmp ebx, 380
	jg afara
	cmp edx, 110
	jl afara
	cmp edx, 130
	jg afara
	parcurgem_matrice:
	mov ecx, 9
	mov edi, 0
	bucla:
		mov esi, ecx
		dec esi
		mov matrice[esi * 4], edi ;reseteaza campurile din matrice, care e de fapt un vector
	loop bucla
	mov ebx, 0
	mov verificare_X_O, ebx ;reseteaza comtorul de X sau 0
	mov ebx, 9
	mov numarator, ebx ;reseteaza numaratorul de miscari valide ramase la 9 
	jmp final
afara:
	mov eax, 999
final:
	ret
play_again endp

deseneaza_linie_verticala macro x, y
LOCAL vf, final
	pusha
	xor eax, eax
	mov eax, x
	mov ebx, area_width
	mul ebx
	add eax, y
	shl eax, 2
	mov ecx, 0
vf:
	add eax, 1599
	mov ebx, [area]
	add ebx, ecx
	mov dword ptr [ebx+eax], 0ff1414h
	inc ecx
	inc ecx
	cmp ecx, 120
	je final
	loop vf
final:
	popa
endm

deseneaza_linie_orizontala macro x, y
local vf, final
	pusha
	mov eax, 0
	mov eax, x
	mov ebx, area_width
	mul ebx
	add eax, y
	shl eax, 2
	mov ecx, 0
vf:
	mov ebx, [area]
	add ebx, ecx
	mov dword ptr [ebx+eax], 0ff1414h
	inc ecx
	inc ecx
	cmp ecx, 480
	je final
	loop vf
final:
	popa
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
	
draw proc
	push ebp
	mov ebp, esp
	pusha
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz afisare_litere ; nu s-a efectuat click pe nimic
	;intializeaza fereastra cu pixeli gri
clear:
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 0c1bce2h   ;culoare fundal
	push area
	call memset
	add esp, 12
	deseneaza_linie_orizontala 100, 100
	deseneaza_linie_orizontala 140, 100
	deseneaza_linie_orizontala 180, 100
	deseneaza_linie_orizontala 220, 100
	deseneaza_linie_verticala 100, 100
	deseneaza_linie_verticala 100, 140
	deseneaza_linie_verticala 100, 180
	deseneaza_linie_verticala 100, 220
	jmp afisare_litere
	
evt_click:
	mov ebx,[ebp+arg2]
	mov edx,[ebp+arg3]	
	push edx
	push ebx
	add esp, 8
	mov eax, 99
	cmp eax, 99
	jne clear
	mov ecx, numarator ;numarator e 9 la inceput, pentru ca sunt 9 casute
	jecxz label_play_again ;daca ecx ii 0 se asteapta PLAY AGAIN, daca nu, se intra in bucla
	buclisoara:
		call player_vs_player ;procesul de joc
		cmp eax, 0
		jne pastram_numarator				;daca am apasat in casuta ocupata, numarator se pastreaza
		cmp verifica_afara, constanta_zero	;daca click s-a efectuat afara din tabela, la fel pastram
		je pastram_numarator
		dec numarator
		jmp verifica_castigator
	pastram_numarator:
		mov ecx, numarator
	verifica_castigator:
		call verificare_castigator
		cmp eax, 1
		je castiga_X
		cmp eax ,2
		je castiga_O
		cmp numarator, constanta_zero
		je egalitate
	iesi:	
		jmp afisare_litere
	 
	label_play_again:
		mov ebx,[ebp+arg2]	;unde dai click pe play again
		mov edx,[ebp+arg3]
		push edx
		push ebx
		call play_again ;se reseteaza tabla de joc
		add esp, 8
		cmp eax, 999
		jne clear
		jmp afisare_litere
		
	egalitate:
	;remiza
		make_text_macro 'D', area, 260, 190
		make_text_macro 'R', area, 270, 190
		make_text_macro 'A', area, 280, 190
		make_text_macro 'W', area, 290, 190
		jmp afisare_litere
			
	castiga_O:
		;castiga O
		make_text_macro 'O', area, 260, 190
		make_text_macro ' ', area, 270, 190
		make_text_macro 'W', area, 280, 190
		make_text_macro 'O', area, 290, 190
		make_text_macro 'N', area, 300, 190
		mov numarator, constanta_zero
		jmp afisare_litere
	
	castiga_X:
	;castiga X 
		make_text_macro 'X', area, 260, 190
		make_text_macro ' ', area, 270, 190
		make_text_macro 'W', area, 280, 190
		make_text_macro 'O', area, 290, 190
		make_text_macro 'N', area, 300, 190
		mov numarator, constanta_zero

afisare_litere:	
	make_text_macro 'T', area, 120, 40
	make_text_macro 'I', area, 130, 40
	make_text_macro 'C', area, 140, 40
	make_text_macro ' ', area, 150, 40
	make_text_macro 'T', area, 160, 40
	make_text_macro 'A', area, 170, 40
	make_text_macro 'C', area, 180, 40
	make_text_macro ' ', area, 190, 40
	make_text_macro 'T', area, 200, 40
	make_text_macro 'O', area, 210, 40
	make_text_macro 'E', area, 220, 40

	make_text_macro 'P', area, 260, 110
	make_text_macro 'L', area, 270, 110
	make_text_macro 'A', area, 280, 110
	make_text_macro 'Y', area, 290, 110
	make_text_macro ' ', area, 300, 110
	make_text_macro 'A', area, 310, 110
	make_text_macro 'G', area, 320, 110
	make_text_macro 'A', area, 330, 110
	make_text_macro 'I', area, 340, 110
	make_text_macro 'N', area, 350, 110
	
final_draw:

	make_text_macro 'B', area, 270, 270
	make_text_macro 'A', area, 280, 270
	make_text_macro 'N', area, 290, 270
	make_text_macro 'E', area, 310, 270
	make_text_macro 'M', area, 320, 270
	make_text_macro 'M', area, 330, 270
	make_text_macro 'A', area, 340, 270
	make_text_macro 'N', area, 350, 270
	make_text_macro 'U', area, 360, 270
	make_text_macro 'E', area, 370, 270
	make_text_macro 'L', area, 380, 270

	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
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
