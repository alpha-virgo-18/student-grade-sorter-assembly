;  Student Grade Sorter
;  Modules : User Input, Student Names, Ascending/Descending
;            Sort, Highest Score, Lowest Score, Average Score,Grade Distribution, Detailed Report

INCLUDE Irvine32.inc

MAX_STUDENTS  EQU  20
NAME_LEN      EQU  30

.DATA

; ---- arrays ------------------------------------------------
student_scores      BYTE  MAX_STUDENTS DUP(0)
names       BYTE  MAX_STUDENTS * NAME_LEN DUP(0)
temp_name    BYTE  NAME_LEN DUP(0)
total_students BYTE  0
sort_direction   BYTE  0          ; 0 = Ascending   1 = Descending


; ---- grade strings -----------------------------------------
grade_A  BYTE "A",0
grade_B  BYTE "B",0
grade_C  BYTE "C",0
grade_D  BYTE "D",0
grade_F  BYTE "F",0

; ---- messages ----------------------------------------------
title_banner   BYTE "============================================",13,10
         BYTE "    STUDENT GRADE SORTER    ",13,10
         BYTE "============================================",13,10,0

ask_count     BYTE "Enter number of students (1-20): ",0
ask_name    BYTE "  Name  : ",0
ask_score    BYTE "  Score : ",0
ask_order   BYTE 13,10,"Sort order  0=Ascending  1=Descending : ",0

err_bad_count     BYTE "  ** Please enter a value from 1 to 20 **",13,10,0
err_bad_score    BYTE "  ** Please enter a score from 0 to 100 **",13,10,0
err_bad_order   BYTE "  ** Please enter 0 or 1 **",13,10,0

report_header   BYTE 13,10,"--------------------------------------------",13,10
         BYTE "             DETAILED  REPORT               ",13,10
         BYTE "--------------------------------------------",13,10
         BYTE "Rank  Name                  Score  Grade",13,10
         BYTE "--------------------------------------------",13,10,0

stats_header    BYTE 13,10,"--------------------------------------------",13,10
         BYTE "               STATISTICS                   ",13,10
         BYTE "--------------------------------------------",13,10,0

msg_highest    BYTE "  Highest Score : ",0
msg_lowest    BYTE "  Lowest  Score : ",0
msg_average    BYTE "  Average Score : ",0
msg_ascending   BYTE "  Sort Order    : Ascending",13,10,0
msg_descending   BYTE "  Sort Order    : Descending",13,10,0
msg_student_num   BYTE "Student #",0


dot_space    BYTE ".  ",0
separator   BYTE "  ",0

.CODE

; ============================================================
; NamePtr  -  returns in EAX the byte offset for student EBX
;             (index 0-based).  Caller adds OFFSET names.
; ============================================================
NamePtr PROC
    push edx
    mov  eax, NAME_LEN
    mul  ebx          ; eax = ebx * NAME_LEN
    pop  edx
    ret
NamePtr ENDP

; Convert score into letter grade
; Score comes in AL, grade string address returned in EDX

AssignGrade PROC
    cmp  al, 90 
    jae  _A
    cmp  al, 80 
    jae  _B
    cmp  al, 70 
    jae  _C
    cmp  al, 60 
    jae  _D
    mov  edx, OFFSET grade_F
    jmp  _done
_A: mov  edx, OFFSET grade_A
    jmp  _done
_B: mov  edx, OFFSET grade_B
    jmp  _done
_C: mov  edx, OFFSET grade_C
    jmp  _done
_D: mov  edx, OFFSET grade_D
_done:
    ret
AssignGrade ENDP


; SwapNames  -  swap names[iA] and names[iB]
;               iA in EAX, iB in EBX  (0-based indices)

SwapNames PROC
    push esi
    push edi
    push ecx

    ; esi = &names[iA*NAME_LEN]
    push ebx
    mov  ebx, eax
    call NamePtr          ; eax = offset
    pop  ebx
    mov  esi, OFFSET names
    add  esi, eax         ; esi -> names[iA]

    ; edi = &names[iB*NAME_LEN]
    push eax
    mov  eax, ebx
    call NamePtr
    mov  edi, OFFSET names
    add  edi, eax
    pop  eax

    ; copy names[iA] -> temp_name
    push esi
    push edi
    mov  edi, OFFSET temp_name
    mov  ecx, NAME_LEN
copyToTemp:
    mov  al, [esi]
    mov  [edi], al
    inc  esi
    inc  edi
    loop copyToTemp
    pop  edi
    pop  esi

    ; copy names[iB] -> names[iA]
    push esi
    push edi
    mov  ecx, NAME_LEN
copyBtoA:
    mov  al, [edi]
    mov  [esi], al
    inc  esi
    inc  edi
    loop copyBtoA
    pop  edi
    pop  esi

    ; copy temp_name -> names[iB]
    push edi
    mov  esi, OFFSET temp_name
    mov  ecx, NAME_LEN
copyTempToB:
    mov  al, [esi]
    mov  [edi], al
    inc  esi
    inc  edi
    loop copyTempToB
    pop  edi

    pop  ecx
    pop  edi
    pop  esi
    ret
SwapNames ENDP

; BubbleSort  -  sorts student_scores[] + names[] together
;               sort_direction 0=asc  1=desc
BubbleSort PROC
    movzx ecx, total_students
    dec   ecx
    jz    bsDone

outerBS:
    push  ecx
    mov   esi, 0
    movzx ecx, total_students
    dec   ecx

innerBS:
    mov   al, student_scores[esi]
    mov   bl, student_scores[esi+1]     ; Compare two adjacent scores

    cmp   sort_direction, 0
    je    chkAsc

    ; Descending: swap if al < bl
    cmp   al, bl
    jae   noSwap
    jmp   doSwap

chkAsc:
    ; Ascending: swap if al > bl
    cmp   al, bl
    jbe   noSwap

doSwap:
    mov   student_scores[esi],   bl       ; Exchange scores
    mov   student_scores[esi+1], al

      ; Also swap names so score and student remain linked
    push  ecx
    movzx eax, si
    movzx ebx, si
    inc   ebx
    call  SwapNames
    pop   ecx

noSwap:
    inc   esi
    loop  innerBS

    pop   ecx
    loop  outerBS

bsDone:
    ret
BubbleSort ENDP

; PrintPaddedName  EDX = ptr to null-term name     Pads output to 22 characters
PrintPaddedName PROC
    push esi
    push ecx
    push edx

    call WriteString

    ; measure length
    mov  esi, edx
    mov  ecx, 0
ppnMeasure:
    cmp  BYTE PTR [esi], 0
    je   ppnPad
    inc  ecx
    inc  esi
    jmp  ppnMeasure
ppnPad:
    mov  eax, 22
    sub  eax, ecx
    jle  ppnDone
    mov  ecx, eax
ppnSpaces:
    mov  al, ' '
    call WriteChar
    loop ppnSpaces
ppnDone:
    pop  edx
    pop  ecx
    pop  esi
    ret
PrintPaddedName ENDP


; InputStudents

InputStudents PROC

    ; --- student count ---
getN:
    mov  edx, OFFSET ask_count
    call WriteString
    call ReadInt
    cmp  eax, 1
    jl   badN
    cmp  eax, MAX_STUDENTS
    jg   badN
    mov  total_students, al
    jmp  gotN
badN:
    mov  edx, OFFSET err_bad_count
    call WriteString
    jmp  getN
gotN:

    ; --- sort order ---
getOrd:
    mov  edx, OFFSET ask_order
    call WriteString
    call ReadInt
    cmp  eax, 0
    je   ordAsc
    cmp  eax, 1
    je   ordDesc
    mov  edx, OFFSET err_bad_order
    call WriteString
    jmp  getOrd
ordAsc:
    mov  sort_direction, 0
    jmp  ordDone
ordDesc:
    mov  sort_direction, 1
ordDone:
    call Crlf

    ; --- per-student input ---
    mov  esi, 0
    movzx ecx, total_students

perStudent:
     ; Input information for one student
    push ecx
    push esi

    
    mov  edx, OFFSET msg_student_num
    call WriteString
    movzx eax, si
    inc  eax
    call WriteDec
    mov  edx, OFFSET dot_space
    call WriteString
    call Crlf

    ; name
    mov  edx, OFFSET ask_name
    call WriteString
    movzx ebx, si
    call NamePtr             ; eax = offset into names buffer
    mov  edx, OFFSET names
    add  edx, eax
    mov  ecx, NAME_LEN - 1
    call ReadString

    ; score
getScore:
     ; Keep asking until score is between 0 and 100
    mov  edx, OFFSET ask_score
    call WriteString
    call ReadInt
    cmp  eax, 0
    jl   badSc
    cmp  eax, 100
    jg   badSc
    pop  esi
    pop  ecx
    mov  student_scores[esi], al
    push ecx
    push esi
    jmp  gotScore
badSc:
    mov  edx, OFFSET err_bad_score
    call WriteString
    jmp  getScore
gotScore:
    call Crlf
    pop  esi
    pop  ecx
    inc  esi
    dec  ecx
    jnz  perStudent

    ret
InputStudents ENDP

; ============================================================
; PrintReport
; ============================================================
PrintReport PROC
    mov  edx, OFFSET report_header
    call WriteString

    mov  esi, 0
    movzx ecx, total_students
    mov  ebx, 0          ; 0-based rank index

prLoop:
    push ecx

    ; rank number
    mov  eax, ebx
    inc  eax
    call WriteDec
    mov  al, '.'
    call WriteChar
    mov  al, ' '
    call WriteChar
    cmp  eax, 9          ; single digit gets extra space (eax already inc'd above
                          ; but WriteDec doesn't change it - use original ebx)
    push eax
    movzx eax, BYTE PTR student_scores[esi]   ; reuse eax safely
    pop  eax
    mov  eax, ebx
    inc  eax
    cmp  eax, 10
    jge  noExSp
    mov  al, ' '
    call WriteChar
noExSp:

    ; name padded to 22
    call NamePtr         ; ebx already = esi (index)  -- wait, ebx=rank, esi=index
    push ebx
    movzx ebx, si        ; index for NamePtr
    call NamePtr
    pop  ebx
    mov  edx, OFFSET names
    add  edx, eax
    call PrintPaddedName

    ; score
    movzx eax, student_scores[esi]
    call WriteDec
    ; pad score field to 5 chars (3 digits + 2 spaces handled manually)
    cmp  eax, 100
    jge  sc3d
    cmp  eax, 10
    jge  sc2d
    mov  al, ' '         ; 2 extra spaces for 1-digit
    call WriteChar
    mov  al, ' '
    call WriteChar
    jmp  scPadDone
sc2d:
    mov  al, ' '         ; 1 extra space for 2-digit
    call WriteChar
    jmp  scPadDone
sc3d:
scPadDone:
    mov  al, ' '
    call WriteChar
    mov  al, ' '
    call WriteChar

    ; grade
    mov  al, student_scores[esi]
    call AssignGrade
    call WriteString
    call Crlf

    pop  ecx
    inc  esi
    inc  ebx
    dec  ecx
    jnz  prLoop

    ret
PrintReport ENDP

; ============================================================
; PrintStats
PrintStats PROC
    mov  edx, OFFSET stats_header
    call WriteString

    movzx esi, total_students
    dec   esi                ; index of last element

    cmp   sort_direction, 0
    je    statsAsc

    ; Descending: [0]=highest  [esi]=lowest
    mov  edx, OFFSET msg_highest
    call WriteString
    movzx eax, student_scores[0]
    call WriteDec
    call Crlf

    mov  edx, OFFSET msg_lowest
    call WriteString
    movzx eax, student_scores[esi]
    call WriteDec
    call Crlf
    jmp  calcAvg

statsAsc:
    ; Ascending: [0]=lowest  [esi]=highest
    mov  edx, OFFSET msg_lowest
    call WriteString
    movzx eax, student_scores[0]
    call WriteDec
    call Crlf

    mov  edx, OFFSET msg_highest
    call WriteString
    movzx eax, student_scores[esi]
    call WriteDec
    call Crlf

calcAvg:
    mov  eax, 0
    mov  esi, 0
    movzx ecx, total_students
sumLp:
    movzx ebx, student_scores[esi]
    add  eax, ebx
    inc  esi
    loop sumLp

    movzx ebx, total_students
    mov  edx, 0
    div  ebx
    mov  edx, OFFSET msg_average
    call WriteString
    call WriteDec
    call Crlf

    cmp  sort_direction, 0
    je   prtAsc2
    mov  edx, OFFSET msg_descending
    call WriteString
    jmp  statsDone
prtAsc2:
    mov  edx, OFFSET msg_ascending
    call WriteString
statsDone:
    ret
PrintStats ENDP

; main
; ============================================================
main PROC

    mov  edx, OFFSET title_banner
    call WriteString
    call Crlf

    call InputStudents
    call BubbleSort
    call PrintReport
    call PrintStats
    call Crlf
    exit

main ENDP
END main