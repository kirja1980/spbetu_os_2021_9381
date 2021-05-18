DOSSEG
.model small
.stack 100h

.data
	EndLine EQU '$'
	; ДАННЫЕ
	PC_TYPE_MESSAGE DB 'PC type: ' , EndLine
	PC_TYPE_PC DB 'PC', 0DH, 0AH, EndLine
	PC_TYPE_PC_XT DB 'PC/XT', 0DH, 0AH, EndLine
	PC_TYPE_AT DB 'AT', 0DH, 0AH, EndLine
	PC_TYPE_PS2_mode_30 DB 'PS2 model 30', 0DH, 0AH, EndLine
	PC_TYPE_PS2_model_50_or_60 DB 'PS2 model 50 or 60', 0DH, 0AH, EndLine
	PC_TYPE_PS2_model_80 DB 'PS2 model 80', 0DH, 0AH, EndLine
	PC_TYPE_PCjr DB 'PCjr', 0DH, 0AH, EndLine
	PC_TYPE_PC_Convertible DB 'PC Convertible', 0DH, 0AH, EndLine
	PC_TYPE_UNKNOWN DB '  ', 0DH, 0AH, EndLine
	OS_VERSION_MESSAGE DB 'OS version: ' , EndLine
	OS_VERSION DB '  .  ', 0DH, 0AH, EndLine
	OEM_NUMBER_MESSAGE DB 'OEM serial number: ', EndLine
	OEM_NUMBER DB '  ', 0DH, 0AH, EndLine
	USER_NUMBER_MESSAGE DB 'User serial number: ', EndLine
	USER_NUMBER DB '      ', 0DH, 0AH, EndLine
	
.code
START: JMP BEGIN
	;ПРОЦЕДУРЫ
	;----------------------------------------------------
	TETR_TO_HEX   PROC  near
		and      AL,0Fh
		cmp      AL,09
		jbe      NEXT
		add      AL,07
NEXT:   add      AL,30h
		ret
	TETR_TO_HEX   ENDP
	;------------------------------
	BYTE_TO_HEX   PROC  near
	; байт в AL переводится в два символа шестн. числа в AX
		push     CX
		mov      AH,AL
		call     TETR_TO_HEX
		xchg     AL,AH
		mov      CL,4
		shr      AL,CL
		call     TETR_TO_HEX ;в AL старшая цифра
		pop      CX          ;в AH младшая
		ret
	BYTE_TO_HEX  ENDP 
	;-------------------------------------------------
	WRD_TO_HEX   PROC  near 
	;перевод в 16 с/с 16-ти разрядного числа 
	; в AX - число, DI - адрес последнего символа
		push     BX           
		mov      BH,AH           
		call     BYTE_TO_HEX          
		mov      [DI],AH           
		dec      DI           
		mov      [DI],AL
		dec      DI           
		mov      AL,BH 
		call     BYTE_TO_HEX        
		mov      [DI],AH
		dec      DI
		mov      [DI],AL
		pop      BX
		ret
	WRD_TO_HEX ENDP
	;-------------------------------------------------
	BYTE_TO_DEC   PROC  near
	; перевод в 10с/с, SI - адрес поля младшей цифры 
		push     CX
		push     DX
		xor      AH,AH
		xor      DX,DX
		mov      CX,10
loop_bd:div      CX
		or       DL,30h
		mov      [SI],DL
		dec      SI
		xor      DX,DX
		cmp      AX,10
		jae      loop_bd
		cmp      AL,00h
		je       end_l
		or       AL,30h
		mov      [SI],AL
end_l:  pop      DX
        pop      CX
        ret
	BYTE_TO_DEC    ENDP 
	;-------------------------------------------------
	; КОД
PRINT PROC NEAR
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP
	
PC_TYPE PROC NEAR
	; Сохраняем значения регистров
	push ax
	push bx
	push dx
	push es
	; Получаем байт, содержащий информацию о типе ПК
	mov ax, 0F000h
	mov es, ax
	mov al, es:[0FFFEh]
	; Выводим на экран первую часть строки с информацией о типе ПК
	mov dx, offset PC_TYPE_MESSAGE
	call PRINT
	; Сравниваем значение байта со значениями известных типов ПК
	cmp al, 0FFh
	je type_PC
	cmp al, 0FEh
	je type_PC_XT
	cmp al, 0FDh
	je type_PC_XT
	cmp al, 0FCh
	je type_AT
	cmp al, 0FAh
	je type_PS2_mode_30
	cmp al, 0FCh
	je type_PS2_model_50_or_60
	cmp al, 0F8h
	je type_PS2_model_80
	cmp al, 0FDh
	je type_PCjr
	cmp al, 0F9h
	je type_PC_Convertible
	jmp type_unknown ; В случае, если значения байта не совпадает со значениями известных типов ПК
	; Помещаем смещение строки с соотвествующим типом в регист dx
type_PC:
	mov dx, offset PC_TYPE_PC
	jmp print_type
type_PC_XT:
	mov dx, offset PC_TYPE_PC_XT
	jmp print_type
type_AT:
	mov dx, offset PC_TYPE_AT
	jmp print_type
type_PS2_mode_30:
	mov dx, offset PC_TYPE_PS2_mode_30
	jmp print_type
type_PS2_model_50_or_60:
	mov dx, offset PC_TYPE_PS2_model_50_or_60
	jmp print_type
type_PS2_model_80:
	mov dx, offset PC_TYPE_PS2_model_80
	jmp print_type
type_PCjr:
	mov dx, offset PC_TYPE_PCjr
	jmp print_type
type_PC_Convertible:
	mov dx, offset PC_TYPE_PC_Convertible
	jmp print_type
type_unknown:
	; Получаем значение байта в виде символов и записываем их в строку PC_TYPE_UNKNOWN
	call BYTE_TO_HEX
	mov bx, offset PC_TYPE_UNKNOWN
	mov [bx], al
	mov [bx+1], ah
	mov dx, bx
print_type:
	call PRINT
	; Восстанавливаем значения регистров
	pop es
	pop dx
	pop bx
	pop ax
	ret
PC_TYPE ENDP

; Выводит на экран версию ОС, серийные номера OEM и пользователя
PC_VERSION PROC NEAR
	; Сохраняем значения регистров
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	; Получаем версию ОС и серийные номера OEM и пользователя при помощи функции 30h прерывания 21h
	mov ah, 30h
	int 21h
	; Переводим значения байтов AH и AL в 10-ичную СС в виде символов и сохраняем их в строке OS_VERSION
	mov si, offset OS_VERSION + 1
	mov dl, ah
	call BYTE_TO_DEC
	mov al, dl
	add si, 3
	call BYTE_TO_DEC
	; Выводим на экран версию ОС
	mov dx, offset OS_VERSION_MESSAGE
	call PRINT
	mov dx, offset OS_VERSION
	call PRINT
	; Переводим значение байта BH в 16-ичную СС в виде символов и сохраняем их в строке OEM_NUMBER
	mov al, bh
	call BYTE_TO_HEX
	mov di, offset OEM_NUMBER
	mov [di], al
	mov [di+1], ah
	; Выводим на экран серийный номер OEM
	mov dx, offset OEM_NUMBER_MESSAGE
	call PRINT
	mov dx, offset OEM_NUMBER
	call PRINT
	; Переводим значения байтов BL:CX в 16-ичную СС в виде символов и сохраняем их в строке USER_NUMBER
	mov al, bl
	call BYTE_TO_HEX
	mov di, offset USER_NUMBER
	mov [di], al
	mov [di+1], ah
	mov ax, cx
	add di, 5
	call WRD_TO_HEX
	; Выводим на экран серийный номер пользователя
	mov dx, offset USER_NUMBER_MESSAGE
	call PRINT
	mov dx, offset USER_NUMBER
	call PRINT
	; Восстанавливаем значения регистров
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
PC_VERSION ENDP
		
BEGIN:
		mov ax, @data
		mov ds, ax
		call PC_TYPE
		call PC_VERSION
		;        . . . . . . . . . . . .
		; Вывод строки текста из поля STRING
		;mov     DX,offset STRING
		;mov     AH,09h
		;int     21h
		;        . . . . . . . . . . . .
		; Выход в DOS
		xor     AL,AL
		mov     AH,4Ch
		int     21H
END     START     ;конец модуля, START - точка входа