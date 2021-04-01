.Model small

.DATA
HELLO db "Message:$"
IDENTSTR db 13, 10, "Resident loaded$", 13, 10
RESUNSTR db 13, 10, "Resident Unloaded$"
RESLSTR db 13, 10, "Resident is already loaded$"
PSP dw ?
isUd db ?
isloaded db ?
count db 0
KEEP_CS DW ? ; для хранения сегмента
KEEP_IP DW ? ; и смещения вектора прерывания

.STACK 400h

.CODE
int_vect dd ?
ID dw 0ff00h
;---------------------
HANDLER PROC FAR
	push ax
	push es
	inc count
	cmp count, 10
	jne ifn
	mov count, 0
	ifn:
		mov al, count
		or al, 30h
		
		; curs actions
		push ax
		; get current curs position
		push ax
		push bx
		push cx
		push dx
		
		mov ah, 03
		mov bh, 00
		int 10h
		mov es, dx
		
		pop dx
		pop cx
		pop bx 
		pop ax
		
		;set curs
		mov ah, 02
		mov bh, 00
		mov dh, 1
		mov dl, 40
		int 10h
		
		call OutputCymbol
		
		;return curs postition
		mov ah, 02
		mov bh, 00
		mov dx, es
		int 10h
		pop ax
		; end of curs actions
	pop es
	pop ax
	mov al, 20h
	out  20h, al
	iret			
HANDLER  ENDP  
;---------------------
IsUnload PROC
	push es
	push ax
	mov ax, PSP
	mov es, ax
	mov cl, es:[80h]
	mov dl, cl
	xor ch, ch
	test cl, cl	
	jz ex2
	xor di, di
	readChar:
	inc di
	mov al, es:[81h+di]
	inc di

	cmp al, '/'
	jne ex2
	mov al, es:[81h+di]
	inc di
	cmp al, 'u'
	jne ex2
	mov al, es:[81h+di]
	cmp al, 'n'
	jne ex2
	mov isUd, 1 ; if is Unloading IDent

	ex2:
	pop ax
	pop es
	ret
IsUnload ENDP
;---------------------
OutputCymbol PROC
	;call setCurs
	push ax
	push bx
	push cx
	mov ah, 09h   ;писать символ в текущей позиции курсора
	mov bh, 0     ;номер видео страницы
	mov cx, 1     ;число экземпляров символа для записи
	int 10h      ;выполнить функцию
	pop cx
	pop bx
	pop ax
	ret
OutputCymbol ENDP
;---------------------
OutputCymbols PROC
	push ax
	push bx
	push dx
	push cx
	mov cx, 8
	mov ah, 13h
	mov al, 1
	mov bh, 0
	mov dh, 22
	mov dl, 0
	int 10h
	pop cx
	pop dx
	pop bx
	pop ax
	ret
OutputCymbols  ENDP
;---------------------
isLoad PROC
	push es
	mov ax, 351Ch ; функция получения вектора
	int  21h
	mov  dx, es:[bx-2]
	pop es
	cmp dx, ID
	je ad
	jmp exd
	ad:
		mov isloaded, 1
	exd:
		ret
isLoad ENDP
;---------------------
Unload PROC
	push es
	mov ax, 351Ch ; функция получения вектора
	int  21H
	mov dx, word ptr es:int_vect
	mov ax, word ptr es:int_vect+2
	mov KEEP_IP, dx
	mov KEEP_CS, ax
	pop es
	cli
	push ds
	mov  dx, KEEP_IP
	mov  ax, KEEP_CS
	mov  ds, ax
	mov  AH, 25H
	mov  AL, 1CH
	int  21H          ; восстанавливаем вектор
	pop  ds
	sti
	ret
Unload ENDP
;---------------------
UpResident PROC
	mov dx, offset IDENTSTR
	call WRITE
	mov dx, offset temp
	sub dx, PSP
	mov cl, 4
	shr dx, cl
	mov ax, 3100h
	int 21h
	ret
UpResident ENDP
;---------------------
WRITE   PROC
        push ax
        mov ah, 09h
        int 21h
        pop ax
        ret
WRITE   ENDP
;---------------------
BEGIN   PROC  FAR 
	mov ax, ds
	mov ax, @DATA		  
	mov ds, ax
	mov ax, es
	mov PSP, ax ; save PSP addr to var

	call isLoad

	call IsUnload

	mov dx, offset HELLO
	call WRITE

	cmp isloaded, 1
	je a
	mov ax, 351Ch ; функция получения вектора
	int  21H
	mov  KEEP_IP, bx  ; запоминание смещения
	mov  KEEP_CS, es  ; и сегмента вектора прерывания
	mov word ptr int_vect+2, es
	mov word ptr int_vect, bx

	push ds
	mov dx, OFFSET HANDLER ; смещение для процедуры в dx
	mov ax, SEG HANDLER    ; сегмент процедуры
	mov ds, ax          ; помещаем в ds
	mov ax, 251Ch         ; функция установки вектора
	int 21h             ; меняем прерывание
	pop  ds
	call UpResident
	a:
		cmp isud, 1
		jne b
		call Unload
		mov dx, offset RESUNSTR
		call WRITE
		mov ah, 4Ch                        
		int 21h   
	b:
		mov dx, offset RESLSTR
		call WRITE
		mov ah, 4Ch                        
		int  21h
BEGIN      ENDP
;---------------------
TEMP PROC
TEMP ENDP
;---------------------
END BEGIN
		  
