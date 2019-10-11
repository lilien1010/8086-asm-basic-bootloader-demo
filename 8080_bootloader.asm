assume cs:code
 
code segment
 
get_input:
	push bx
	push es
	push ax
 
	mov ax,0b800h
	mov es,ax
 
gi_s:
	mov ah,4
	call my_boot
 
	mov ah,0
	int 16h
 
        cmp ah,3bh     ;-input is f1
        jne next0
        call change_color
next0:
	cmp ah,02H  ;--input is 1
	jne next1
 
	mov ah,0
	call my_boot
	jmp gi_s 
next1:  
	cmp ah,03H  ;--input is 2
	jne next2
 
	mov ah,1
	call my_boot
	jmp gi_s 
next2:  
	cmp ah,04H  ;--input is 3
	jne next3
 
	mov ah,2
	call my_boot
        jmp gi_s
next3:  
	cmp ah,05H  ;--input is 4
	jne next4
 
	mov ah,3
	call my_boot
	jmp gi_s 
next4:
	jmp gi_s
	
	pop es
	pop bx
	pop ax
	ret
 
;--------------------------------
my_boot:
	jmp short mb_s
 
	table dw reset_pc,star_system,clock,set_clock,show_menu 
 
mb_s:
	push ax
	push bx
	push cx
	cmp ah,4
	ja ss_end0
	mov bl,ah
	mov bh,0
	add bx,bx
	call clear_screen
	jmp word ptr table[bx]
 
;;--------------------------display menu
show_menu:
	jmp short sm_start
	m1:db "1.reset pc",0
	m2:db "2.star_system",0
	m3:db "3.show clock",0
	m4:db "4.set clock",0
sm_start:
 	mov bx,160*5+64
	mov di,0
	mov si,offset m1
	mov cx,4
sm1:	push cx
 
sm2:
	mov cl,cs:[si]
	jcxz sm_ok1
	mov byte ptr es:[bx+di],cl
	inc si
	add di,2
	jmp sm2
sm_ok1:	
	inc si
	mov di,0
	add bx,160*3
	pop cx
loop sm1
	jmp mb_end
;--------------------------------
reset_pc:		;---------------------reboot computer
 
        mov ax,0ffffh
        push ax
        mov ax,0
        push ax
        retf
ss_end0: jmp mb_end
 
;--------------------------------
star_system:	;---------------------start the existed OS 
        mov ax,0
        mov es,ax
        mov bx,7c00h
 
        mov al,1
        mov ch,0
        mov cl,1
        mov dh,0
        mov dl,80h
 
        mov ah,2
        int 13h
 
        mov ax,0
        push ax
        mov ax,7c00h
        push ax
        retf
 
;-------------------------------
clock:			;---------------------enter clock management page
 	
sc1:
	in al,60h
        cmp al,1
        je c_end
 
        cmp al,3bh     ;-input is f1
        jne next_c
        call change_color
 
next_c:
	call show_peice
	jmp sc1
c_end:
	jmp mb_end
;--------------------------------
set_clock:	;---------------------set time/date
 
	jmp short set_start
 
	now_pos db 0,1,15,2,3,15,4,5,15,6,7,15,8,9,15,10,11   
	port_pos db 9,9,8,8,7,7,4,4,2,2,0,0		
set_start:
 
 	mov dx,0
        or byte ptr es:[160*12+32*2+1],40h
ss1:	
	in al,60h
        cmp al,1
	je mb_end
 
        cmp al,3bh     ;-input is f1
        jne next_sc
        call change_color
 
next_sc:
	call myfunc
	call show_peice
	jmp ss1	
	 
mb_end:	
	mov ax,40h
	mov ds,ax
back0:
	mov ax,ds:[1ch]
	cmp ds:[1ah],ax
	je back1
        mov ah,0
	int 16h
	jmp back0
back1: 
	pop cx
	pop bx
	pop ax
	ret
;----------------------- 4B    4D
myfunc:
	push si
	push cx
	push ax
	push bx
 
	;in al,60h
	;cmp al,1
	;jne  nst1
	
nst1:
	cmp al,11
	ja  mov_zy
	jmp change_time
 
mov_zy:
	cmp al,4Dh	;----right
	jne  nst2
	mov bx,dx
	
	cmp bx,16
	je nst2
	add bx,bx
        and byte ptr es:[bx+1+160*12+32*2],0fh
	add  dx,1
        or byte ptr es:[bx+3+160*12+32*2],40h
 
nst2:
 
	cmp al,4bh	;----left
	jne  nst3
	mov bx,dx
	
	cmp bx,0
	je nst3
 
	add bx,bx
        and byte ptr es:[bx+1+160*12+32*2],0fh
	sub  dx,1
        or  byte ptr es:[bx-1+160*12+32*2],40h
nst3:
	jmp st_out
change_time:
	cmp al,11
	jne  alnot_0
	mov al,1
 
alnot_0:
	sub al,1
	mov bx,dx
	mov si,bx
	add si,si
 
	cmp byte ptr es:[si+160*12+32*2],39h
	ja st_out	
	cmp  byte ptr es:[si+160*12+32*2],30h
	jb st_out
 
	mov ch,al
	cmp byte ptr now_pos[bx+1],15
	je in_low	;--if next now_pos is 15,is changing low_pos 
 
	mov ah,es:[si+160*12+32*2+2]
	and ah,0Fh
	mov cl,4
	shl ch,cl
	jmp s_deal
in_low:
	mov ah,es:[si+160*12+32*2-2]
	mov cl,4
	shl ah,cl
s_deal:
	or ah,ch	
	mov bl, now_pos[bx]
	mov al, port_pos[bx]
	out 70h,al
	mov al,ah
	out 71h,al
 
st_out:	
	mov al,0d2h
	out 64h,al
	out 60h,al
 
	pop bx
	pop ax
	pop cx
	pop si
ret
;--------------------------------
show_peice:	;------------------show current time
	push cx
	push ax
	jmp short sc_start
	clock_p db 9,8,7,4,2,0
	clock_t db '  /  /     :  :  '
sc_start:
	mov byte ptr es:[160*12+31*2],'0'
	mov byte ptr es:[160*12+30*2],'2'
	mov di,0
	mov si,0
	mov cx,6
sc2:	push cx
 	mov al,clock_p[si] 
	out 70h,al
	in al,71h
	mov ah,al
 
	mov cl,4
	shr ah,cl
	and al,0fh
 
	add ah,30h
	add al,30h
	mov byte ptr clock_t[di],ah
	mov byte ptr clock_t[di+1],al
 	
	add di,3
	inc si
	pop cx
loop sc2
 
	mov di,0
	mov si,160*12+32*2
	mov ah,10
	mov cx,17
sc3:	
	mov al,clock_t[di]
	mov byte ptr es:[si],al
	inc di
	add si,2
loop sc3
 
	pop ax
	pop cx
	ret
;--------------------------------
clear_screen:	;--清屏
	push cx
	push bx
	mov bx,0
	mov cx,2000
 
clear_s1:	
	mov byte ptr es:[bx],' '
        and byte ptr es:[bx+1],0fh
	add bx,2
	loop clear_s1
	pop bx
	pop cx
        ret
 
change_color:
	push cx
	push bx
	mov bx,0
	mov cx,2000
cc1:        
        inc byte ptr es:[bx+1]
        and byte ptr es:[bx+1],0fh
        add bx,2
        loop cc1
	pop bx
	pop cx
	ret
all_end:nop
 
 
start:
        push cs      ;copy a function to section 1
        pop  es
        mov bx,offset copy_start
       
        mov al,1
        mov ch,0
        mov cl,1
        mov dh,0
        mov dl,0
 
        mov ah,3
        int 13h
 
       ;call get_input   ;------------do not use
 
        mov bx,0
       
        mov al,2
        mov ch,0
        mov cl,2
        mov dh,0
        mov dl,0
 
        mov ah,3
        int 13h
 
p_end:	mov ax,4c00h
	int 21h
copy_start:
        mov ax,7c00h
        mov es,ax
        mov bx, 0
 
        mov al,2
        mov ch,0
        mov cl,2
        mov dh,0
        mov dl,0
 
        mov ah,2
        int 13h
 
        mov ax,7c00h
        push ax
        mov ax,0
        push ax
        retf
copy_end:nop
		;----------------------start load
code ends
end start
	