;Matrix asm : Shlomi Avni
.model small                
.stack 100h                

.data
N DB 3                     ; Matrix size (3x3 matrix)

; Example 3x3 matrix: determinant should be 27
MAT DB 1, 2, 3, 4, 5, 6, 7, 8, 0

; Buffer to store minor matrix (5x5 max = 25 bytes)
MINOR_BUF DB 25 DUP(?)
; Result 
RLT DW 0
.code
start:
    mov ax, @data          ; Initialize data segment
    mov ds, ax

    mov si, offset MAT     ; SI points to the matrix
    mov di, offset MINOR_BUF ; DI points to the minor buffer
	mov bp, offset RLT     ; BP points to result
    xor bx, bx             ; Clear BX
    mov bl, N              ; Load matrix size (3)

    call calcDet           ; Call recursive determinant function
	
    call PrintDet          ; Print the result

    mov ax, 4C00h          ; Terminate program
    int 21h

;----------------------------------------------------------
; getMinor: Generates the minor matrix excluding row 0 and column j
; Inputs:
;   SI - pointer to source matrix
;   DI - pointer to destination buffer
;   BL - size of source matrix (N)
;   BH - column to exclude (j)
;----------------------------------------------------------
getMinor PROC NEAR
    push ax
    push bx
    push cx
    push si
    push di

    xor cx, cx             ; Clear CX (row i and column k counter)
    mov ch, 1              ; Start from row i = 1 (skip first row)

row_loop:
    cmp ch, bl             ; If i >= N, we're done
    jge minor_done

    xor cl, cl             ; Reset column counter k = 0

col_loop:
    cmp cl, bl             ; If k >= N, go to next row
    jge next_row

    cmp cl, bh             ; If k == j (column to skip), skip it
    je skip_col

    push bx                ; Save BX temporarily
    mov al, bl             ; AL = N
    mul ch                 ; AX = i * N
    add al, cl             ; AX = i * N + k
    mov bx, ax             ; BX = offset of matrix[i][k]
    mov dl, [si+bx]        ; DL = source[i][k]
    mov [di], dl           ; Store value in destination buffer
    inc di                 ; Move to next destination byte
    pop bx                 ; Restore BX

skip_col:
    inc cl                 ; k++
    jmp col_loop

next_row:
    inc ch                 ; i++
    jmp row_loop

minor_done:
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret
getMinor ENDP

;----------------------------------------------------------
; calcDet: Recursively computes the determinant
; Inputs:
;   SI - pointer to matrix
;   BL - size of matrix (N)
; Output:
;   AX - determinant
;----------------------------------------------------------
calcDet PROC NEAR
    push bx
    push si
    push di

    cmp bl, 2              ; Base case: if N == 2
    je base_case

    xor di, di             ; DI will store final result
    xor ch, ch             ; CX = column index j
	xor cl,cl 

sum_loop:
    cmp cl, bl             ; If j >= N, finish
    jge sum_done

    push ax
    push bx
    mov di, offset MINOR_BUF ; DI = destination for minor
    mov bh, cl             ; BH = column to skip
    call getMinor          ; Generate minor
    pop bx
    pop ax

    push di                ; Save accumulated sum
    push si                ; Save original matrix pointer
    push cx                ; Save current column index

    mov si, offset MINOR_BUF ; SI = pointer to minor
    dec bl                 ; Size = N - 1
    call calcDet           ; Recursive call0.
    inc bl                 ; Restore N

    mov dx, ax             ; Save returned determinant in DX

    pop cx                 ; Restore j
    pop si                 ; Restore original matrix pointer
    pop di                 ; Restore accumulated sum

    push bx
    mov bx, cx             ; BX = j
    mov dl, [si+bx]        ; AL = matrix[0][j]
    imul dl                ; AX = a(0,j) * det(minor)
    pop bx

    test cl, 1             ; Check if j is odd
    jz is_even             ; If even, skip negation
    neg ax                 ; If odd, negate the term

is_even:
    add [RLT],ax             ; Add term to result

    inc cl                 ; j++
    jmp sum_loop

sum_done:
    mov ax, [RLT]             ; AX = final result
    jmp calc_done

base_case:
    mov al, [si]           ; a
    mov cl, [si+3]         ; d
    imul cl                ; AX = a*d
    mov bx, ax             ; Store in BX

    mov al, [si+1]         ; b
    mov cl, [si+2]         ; c
    imul cl                ; AX = b*c
    sub bx, ax             ; BX = ad - bc
    mov ax, bx             ; AX = determinant

calc_done:
    pop di
    pop si
    pop bx
    ret
calcDet ENDP

;----------------------------------------------------------
; PrintDet: Prints the value in AX (supports negative numbers)
;----------------------------------------------------------
PrintDet PROC NEAR
    push ax
    push bx
    push cx
    push dx

    cmp ax, 0
    jge print_num

    push ax               ; Save value
    mov dl, '-'           ; Print minus sign
    mov ah, 02h
    int 21h
    pop ax                ; Restore and negate value
    neg ax

print_num:
    xor cx, cx            ; CX = digit counter
next_digit:
    xor dx, dx
    mov bx, 10
    div bx                ; AX / 10
    push dx               ; Store remainder
    inc cx                ; Count digit
    test ax, ax           ; If AX != 0, keep dividing
    jnz next_digit

print_loop:
    pop dx
    add dl, '0'           ; Convert to ASCII
    mov ah, 02h
    int 21h               ; Print digit
    loop print_loop

    mov dl, 0Dh           ; Carriage return
    mov ah, 02h
    int 21h
    mov dl, 0Ah           ; Line feed
    mov ah, 02h
    int 21h

    pop dx
    pop cx
    pop bx
    pop ax
    ret
PrintDet ENDP

END start
