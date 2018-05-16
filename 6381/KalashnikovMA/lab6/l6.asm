CODE SEGMENT
 	ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACKSEG
START: JMP BEGIN

PRINT PROC near
	push ax
	mov AH,09h
	int 21h
	pop ax
	ret
PRINT ENDP

TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT:
	add AL,30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX 
	pop CX 
	ret
BYTE_TO_HEX ENDP

FREE_MEM PROC
		mov ax,STACKSEG 
		mov bx,es
		sub ax,bx 
		add ax,32h 
		mov bx,ax

		mov ah,4Ah
		int 21h
		jnc FREE_MEM_SUCCESS
	
		mov dx,offset STR_ERR_FREE_MEM
		call PRINT
		cmp ax,7
		mov dx,offset STR_ERR_MCB_DESTROYED
		je FREE_MEM_PRINT_ERROR
		cmp ax,8
		mov dx,offset STR_ERR_NOT_ENOUGH_MEM
		je FREE_MEM_PRINT_ERROR
		cmp ax,9
		mov dx,offset STR_ERR_WRNG_MEM_BL_ADDR
		
		FREE_MEM_PRINT_ERROR:
		call PRINT
		mov dx,offset STRENDL
		call PRINT
	
		xor AL,AL
		mov AH,4Ch
		int 21H
	
	FREE_MEM_SUCCESS:
	ret
FREE_MEM ENDP

CREATE_PARAM_BLOCK PROC
	mov ax, es:[2Ch]
	mov PARMBLOCK,ax
	mov PARMBLOCK+2,es 
	mov PARMBLOCK+4,80h 
	ret
CREATE_PARAM_BLOCK ENDP

RUN_CHILD PROC
	mov dx,offset STRENDL
	call PRINT
		
		mov dx,offset STD_CHILD_PATH
		xor ch,ch
		mov cl,es:[80h]
		cmp cx,0
		je RUN_CHILD_NO_TAIL
		mov si,cx
		push si 
		RUN_CHILD_LOOP:
			mov al,es:[81h+si]
			mov [offset CHILD_PATH+si-1],al			
			dec si
		loop RUN_CHILD_LOOP
		pop si
		mov [CHILD_PATH+si-1],0
		mov dx,offset CHILD_PATH
		RUN_CHILD_NO_TAIL:
		
		push ds
		pop es
		mov bx,offset PARMBLOCK

		mov KEEP_SP, SP
		mov KEEP_SS, SS
	
		mov ax,4b00h
		int 21h
		jnc RUN_CHILD_SUCCESS
	
		push ax
		mov ax,DATA
		mov ds,ax
		pop ax
		mov SS,KEEP_SS
		mov SP,KEEP_SP
	
		cmp ax,1
		mov dx,offset STR_ERR_WRNG_FNCT_NUMB
		je RUN_CHILD_PRINT_ERROR
		cmp ax,2
		mov dx,offset STR_ERR_FL_NOT_FND
		je RUN_CHILD_PRINT_ERROR
		cmp ax,5
		mov dx,offset STR_ERR_DISK_ERR
		je RUN_CHILD_PRINT_ERROR
		cmp ax,8
		mov dx,offset STR_ERR_NOT_ENOUGH_MEM2
		je RUN_CHILD_PRINT_ERROR
		cmp ax,10
		mov dx,offset STR_ERR_WRONG_ENV_STR
		je RUN_CHILD_PRINT_ERROR
		cmp ax,11
		mov dx,offset STR_ERR_WRONG_FORMAT	
		je RUN_CHILD_PRINT_ERROR
		mov dx,offset STR_ERR_UNKNWN
        
		RUN_CHILD_PRINT_ERROR:
		call PRINT
		mov dx,offset STRENDL
		call PRINT
	
		xor AL,AL
		mov AH,4Ch
		int 21H
		
	RUN_CHILD_SUCCESS:
	mov ax,4d00h
	int 21h
		cmp ah,0
		mov dx,offset STR_NRML_END
		je RUN_CHILD_PRINT_END_RSN
		cmp ah,1
		mov dx,offset STR_CTRL_BREAK
		je RUN_CHILD_PRINT_END_RSN
		cmp ah,2
		mov dx,offset STR_DEVICE_ERROR
		je RUN_CHILD_PRINT_END_RSN
		cmp ah,3
		mov dx,offset STR_RSDNT_END
		je RUN_CHILD_PRINT_END_RSN
		mov dx,offset STR_UNKNWN
		RUN_CHILD_PRINT_END_RSN:
		call PRINT
		mov dx,offset STRENDL
		call PRINT

		mov dx,offset STR_END_CODE
		call PRINT
		call BYTE_TO_HEX
		push ax
		mov ah,02h
		mov dl,al
		int 21h
		pop ax
		xchg ah,al
		mov ah,02h
		mov dl,al
		int 21h
		mov dx,offset STRENDL
		call PRINT
	ret
RUN_CHILD ENDP
;---------------------------------------
BEGIN:
	mov ax,data
	mov ds,ax
	
	call FREE_MEM
	call CREATE_PARAM_BLOCK
	call RUN_CHILD
	
	xor AL,AL
	mov AH,4Ch
	int 21H
CODE ENDS

DATA SEGMENT

	STR_ERR_FREE_MEM	 		db 'Error when freeing memory: $'
	STR_ERR_MCB_DESTROYED 		db 'MCB is destroyed$'
	STR_ERR_NOT_ENOUGH_MEM 		db 'Not enough memory for function processing$'
	STR_ERR_WRNG_MEM_BL_ADDR 	db 'Wrong addres of memory block$'
	STR_ERR_UNKNWN				db 'Unknown error$'
	
	STR_ERR_WRNG_FNCT_NUMB		db 'Function number is wrong$'
	STR_ERR_FL_NOT_FND			db 'File is not found$'
	STR_ERR_DISK_ERR			db 'Disk error$'
	STR_ERR_NOT_ENOUGH_MEM2		db 'Not enough memory$'
	STR_ERR_WRONG_ENV_STR		db 'Wrong environment string$'
	STR_ERR_WRONG_FORMAT		db 'Wrong format$'

	STR_NRML_END		db 'Normal end$'
	STR_CTRL_BREAK		db 'End by Ctrl-Break$'
	STR_DEVICE_ERROR	db 'End by device error$'
	STR_RSDNT_END		db 'End by 31h function$'
	STR_UNKNWN			db 'End by unknown reason$'
	STR_END_CODE		db 'End code: $'
		
	STRENDL 		db 0DH,0AH,'$'

	PARMBLOCK 		dw 0
					dd 0 
					dd 0 
					dd 0

	CHILD_PATH  	db 50h dup ('$')
	STD_CHILD_PATH	db 'C:\L2.COM', 0

	KEEP_SS 		dw 0
	KEEP_SP 		dw 0

DATA ENDS

STACKSEG SEGMENT STACK
	dw 100h dup (?)
STACKSEG ENDS

END START
