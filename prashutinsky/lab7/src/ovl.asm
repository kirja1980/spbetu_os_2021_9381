CODE segment
	assume cs:CODE, ds:nothing, ss:nothing

	MAIN proc far
		push ax
		push dx
		push ds
		push di

		mov ax, cs
		mov ds, ax
		mov di, offset ovl
		add di, 23
		call WORD_TO_HEX
		mov dx, offset ovl
		call print

		pop di
		pop ds
		pop dx
		pop ax
		retf
	MAIN endp

ovl db 13, 10, "OVERL1 address:         ", 13, 10, '$'

PRINT proc
		push dx
		push ax

		mov ah, 09h
		int 21h

		pop ax
		pop dx
		ret
PRINT endp

TETR_TO_HEX proc
		and al,0fh
		cmp al,09
		jbe next
		add al,07
next:
		add al,30h
		ret
TETR_TO_HEX endp

WORD_TO_HEX proc
		push	bx
		mov	bh,ah
		call BYTE_TO_HEX
		mov	[di],ah
		dec	di
		mov	[di],al
		dec	di
		mov	al,bh
		xor	ah,ah
		call BYTE_TO_HEX
		mov	[di],ah
		dec	di
		mov	[di],al
		pop	bx
		ret
WORD_TO_HEX endp

BYTE_TO_HEX proc
		push 	cx
		mov 	ah, al
		call TETR_TO_HEX
		xchg 	al, ah
		mov 	cl, 4
		shr 	al, cl
		call TETR_TO_HEX
		pop 	cx
		ret
BYTE_TO_HEX endp

CODE ends
end MAIN