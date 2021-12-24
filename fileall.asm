			title		filealloc
			assume		cs:code, ss:s, ds:d

print		macro		string
			lea			dx, string
			mov			ah, 09
			int			21H
			endm

gtlin		macro		mes, string
			print		mes
			mov			ah, 0AH
			lea			dx, string
			int			21H
			lea			di, string+2			;DI = first symbol of msg
			mov			al,-1[di]				;AL = number of read symbols
			xor			ah, ah
			add			di, ax
			mov			[di], ah				;set null-terminator
			endm

s			segment		stack
			dw			128 dup (?)
s			ends

d			segment		
fname		db			255, 0, 255 dup (?)
inhan		dw			?
outhan		dw			?
sizebl		dw			?

msg1		db 			'Enter the name of input file: $'
msg2		db 			'Enter the name of output file: $'
ermsgo		db			'The file was not opened!$'
ermsgc		db			'The file was not created!$'
ermsgr		db			'Error reading the file$'
ermsgw		db			'Error writing the file$'
err4ah		db			'Error 4AH$'
memerr		db			'Error: Not enough memory!$'

d			ends

code		segment

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

freed: 		mov			ax, d
			mov			ds, ax

			mov			ah, 48H
			mov			bx, 0FFFFH
			int			21H				;asking how much memory we can allocate
			
			cmp			bx, 00FFFH
			ja			allocless
			cmp			bx, 0
			jz			nemem
			mov			ah, 48H
			int			21H
nemem:		print		memerr
			mov			ah, 4CH
			int			21H

allocless:	mov			bx, 00FFFH
			mov			ah, 48H
			int			21H


alloc:		mov			es, ax
			mov			cl, 4
			shl			bx, cl
			mov			sizebl, bx				;sizebl = size of block in bytes

oread:		gtlin		msg1, fname
			mov			ah, 3DH
			lea			dx, fname+2
			xor			al, al					;AL = 0 => Access mode = read
			int			21H
			Call		NewLine
			jnc			mvinhnd					;check if carry flag was set - means there was an error
			print		ermsgo
			jmp			oread

mvinhnd:	mov			inhan, ax

cwrite:		gtlin		msg2, fname
			mov			ah, 3CH
			lea			dx, fname+2
			xor			cx, cx					;CX = 0 => not read-only, not hidden, not system, not a label, not a directory, not an archive
			int			21H
			Call		NewLine
			jnc			mvothnd
			print		ermsgc
			jmp			cwrite

mvothnd:	mov			outhan, ax
			
read_han:	mov			bx, inhan
			mov			cx, word ptr sizebl
			push		ds
			push		es
			pop			ds
			mov			ah, 3FH
			lea			dx, ds:[0000H]			
			int			21H
			pop			ds
			jnc			write_han
			print		ermsgr

close_han:	mov			ah, 3EH
			mov			bx, inhan
			int			21H
			mov			ah, 3EH
			mov			bx, outhan
			int 		21H
			mov			ah, 4CH
			int			21H

write_han:	cmp			ax, 0
			jz			close_han
			push		ax

			mov			cx, ax
			xor			si, si

shift_l:	cmp			byte ptr es:[si], 'A'
			jb			skip

			cmp			byte ptr es:[si], 'Z'
			ja			skip

			mov			al, 32
			add			al, byte ptr es:[si]
			mov			byte ptr es:[si], al

skip:		inc			si
			loop		shift_l

			pop			cx
			mov			ah, 40H
			mov			bx, outhan
			push		ds
			push		es	
			pop			ds
			lea			dx, ds:[0000H]
			int			21H
			pop			ds
			jnc			read_han
			print		ermsgw
			jmp 		close_han

code		ends
z 			segment
z 			ends
			end			start
