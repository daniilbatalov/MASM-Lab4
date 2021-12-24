			title		arrayalloc
			assume		cs:code, ss:s, ds:d

s			segment		stack
			dw			128 dup (?)
s			ends

d			segment
n			dw			?

string 		db			255, 0, 255 dup (?)
errmsg		db			'Error! Invalid character!', 0DH, 0AH, '$'
negflag		dw			?

msgx		db 			'Enter the next element of array: $'
msgn		db 			'Enter the number of elements in array: $'
msgr		db			'Result: $'
msgz		db			'There was no positive elements on even positions. The result is undefined.$'
err4ah		db			'Error 4AH$'
errzer		db			'Error! The size of array cannot be zero!', 0DH, 0AH, '$'		
d			ends

code		segment

cr = 0DH
lf = 0AH

IntegerOut	proc
			xor			cx, cx
			mov			bx,	10
			cmp			ax, 0
			jge			m0
			neg			ax
			push		ax
			mov			ah,	2
			mov			dl,	'-'
			int			21H
			pop			ax

m0:			inc			cx
			xor			dx, dx
			div			bx
			push		dx
			or			ax, ax
			jnz			m0

m11:		pop 		dx
			add			dx, '0'
			mov			ah,	2
			int			21H
			loop		m11
			ret
IntegerOut	endp

IntegerIn	proc
startp:		push		dx
			push		si
			push		bx

			mov			ah, 0AH
			lea			dx, string
			int 		21H

			xor			ax, ax
			lea			si, string+2
			mov			negflag, ax
			cmp			byte ptr [si], '-'
			jne			m2

			not			negflag
			inc			si
			jmp			m
m2:			cmp			byte ptr [si], '+'
			jne			m
			inc			si
m:			cmp			byte ptr [si], cr
			je			exl
			cmp			byte ptr [si], '0'
			jb			err
			cmp			byte ptr [si], '9'
			ja			err

			mov			bx, 10
			mul			bx

			sub			byte ptr [si], '0'
			add			al, [si]
			adc			ah, 0

			inc			si
			jmp			m

err:		lea 		dx, errmsg
			mov			ah, 9
			int			21H
			jmp			startp

exl:		cmp			negflag, 0
			je 			ex
			neg			ax

ex: 		pop			bx
			pop			si
			pop			dx
			
			ret
IntegerIn	endp

NewLine		proc
			push		ax
			push		dx

			mov			ah, 02H
			mov			dl, 0AH
			int			21H

			mov			ah, 02H
			mov			dl, 0DH
			int			21H

			pop			dx
			pop			ax
			ret
NewLine		endp			

start:		mov 		bx, seg z
			mov 		ax, es
			sub			bx, ax
			mov 		ah, 4AH
			int 		21H					;free the memory after the program

			jnc			freed
			mov			ax, d
			mov			ds, ax
			mov 		ah, 9
			lea 		dx, err4ah
			int 		21h	

			mov 		ah, 4CH
			int 		21H		

freed:		mov			ax, d
			mov			ds, ax

trag:		mov 		ah, 9
			lea			dx, msgn
			int			21H

			Call		IntegerIn
			Call		NewLine
			cmp			ax, 0 				;check if AX = 0 then break
			jnz			nz

			lea			dx, errzer
			mov			ah, 9
			int			21H
			jmp			trag

nz:			mov			n, ax
			

			dec			ax
			mov			cl, 3
			shr			ax, cl
			inc			ax				
			mov			bx, ax				;BX = needed size of array in paragraphs
			mov			ah, 48H
			int			21H					;allocated memory for array

			mov			es, ax

			xor			si, si
			mov			cx, n
ent:		mov 		ah, 9
			lea			dx, msgx
			int			21H
			Call		IntegerIn
			Call		NewLine			
			mov			es:[si], ax
			add			si, 2
			loop		ent

			mov			ax, n
			test		ax, 1
			jz			evn
			inc			ax
evn:		mov			cx, 2
			cwd
			idiv		cx
			mov			cx, ax

			xor			ax, ax
			xor			dx, dx	
			xor			si, si
iter:		cmp			word ptr es:[si], 0
			jle			ng
			add			ax, es:[si]
			inc			dx
ng:			add			si, 4
			loop  		iter

			cmp			dx, 0
			je			zer
			
			mov			cx, dx
			cwd
			idiv		cx
			push		ax

			mov 		ah, 9
			lea			dx, msgr
			int			21H			
			pop			ax
			Call		IntegerOut
			jmp			exit

zer:		mov			ah, 9
			lea			dx, msgz
			int			21H

exit:		mov			ah, 49H
			int			21H			
			mov			ah, 4CH
			int			21H			
code		ends
z 			segment
z 			ends
			end			start