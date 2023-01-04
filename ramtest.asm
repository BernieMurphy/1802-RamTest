; *******************************************************************
; ***                    32K RAM test 
; *** Circa 2015 Written by Mike Riley to run in Diskless ROM at 0F300h
; *** 2023/01/04 Modified by Bernie Murphy to run in extended memory
; ***         on David Madole's Mini System
; ******************************************************************** 


#include bios.inc                      ;Only need BIOS routines
#include ops.inc


           org     7ffah
           dw      8000h               ; Exec header, where program loads
pgmlen:    dw      endrom-8000h        ; Length of program to load
           dw      8000h               ; exec address

stack:     equ     0f000h              ; need some stack space
startmem:  equ     0                   ; start memory to test
endmem:    equ     07fffh              ; end of memory to test 



           org     8000h

           br      entry
           DB      81h                 ; 1st month-upper bit indicates extended hdr
           DB      04                  ; the 4th day of the month
           DW      2023                ; the year
           DW      3                   ; indicate that this is build 7 of the program
           DB      'RAMTest lower 32K' ; text for the Elf OS version command 
           DB   0          

entry:     mov     r2,stack
           mov     r6,start
           lbr     f_initcall
start:     sep     scall               ; display message
           dw      f_inmsg
           db      'RAMtest v3.0',10,13,'Test 1',10,13,0
           mov     ra,hexout           ; address of hexout routine
           mov     rf,startmem
; TEST 1 write all zeros and all ones in each cell and verify
test1:     ldi     0                   ; zero memory
           phi     r7
           str     rf                  ; write it
           ldn     rf                  ; retrieve byte from memory
           plo     r7
           bnz     test1no             ; jump if byte was not valid
           ldi     0ffh                ; set all bits
           phi     r7
           str     rf                  ; store to memory
           ldn     rf                  ; read it back
           plo     r7
           smi     0ffh                ; check for proper byte
           bnz     test1no             ; jump if error
test1_2:   inc     rf                  ; next memory location
           ghi     rf                  ; check for end of ram
           shl                         ; shift high bit to df
           bnf     test1               ; loop back if not done
           lbr     test2               ; jump to next test
test1no:   sep     scall               ; display error
           dw      error
           lbr     test1_2             ; and keep going

test2:     sep     scall               ; display message for test 2
           dw      f_inmsg
           db      'Test 2',10,13,0
           mov     rf,startmem
; TEST 2 write each block number in each cell and vefiy
test2_1:   ghi     rf                  ; get block number
           adi     1                   ; +1
           str     rf                  ; store it
           inc     rf                  ; point to next memory cell
           ghi     rf                  ; need to see if done
           shl
           lbnf    test2_1             ; loop back if not
           mov     rf,startmem         ; point back to beginning of memory
test2_2:   ghi     rf                  ; get block number
           adi     1                   ; +1
           phi     r7                  ; set exptected result
           str     r2                  ; and store to stack for compare
           ldn     rf                  ; retrieve byte from memory
           sm                          ; subtract expected
           lbnz    test2no             ; jump if error
test2_3:   inc     rf                  ; point to next memory cell
           ghi     rf                  ; need to see if done
           shl
           lbnf    test2_2             ; jump if not
           lbr     test3               ; jump to test 3
test2no:   sep     scall               ; display error
           dw      error
           lbr     test2_3             ; then continue

test3:     sep     scall               ; display message for test 3
           dw      f_inmsg
           db      'Test 3',10,13,0
           mov     rf,endmem
; TEST 3 write inverted block number in each cell and verify
test3_1:   ghi     rf                  ; get block number
           adi     1                   ; +1
           xri     0ffh                ; invert it
           str     rf                  ; store it
           dec     rf                  ; point to next memory cell
           ghi     rf                  ; need to see if done
           shl
           lbnf    test3_1             ; loop back if not
           mov     rf,endmem           ; point back to end of memory
test3_2:   ghi     rf                  ; get block number
           adi     1                   ; +1
           xri     0ffh                ; invert it
           phi     r7                  ; set exptected result
           str     r2                  ; and store to stack for compare
           ldn     rf                  ; retrieve byte from memory
           sm                          ; subtract expected
           lbnz    test3no             ; jump if error
test3_3:   dec     rf                  ; point to next memory cell
           ghi     rf                  ; need to see if done
           shl
           lbnf    test3_2             ; jump if not
           lbr     test4               ; jump to test 3
test3no:   sep     scall               ; display error
           dw      error
           lbr     test3_3             ; then continue

test4:     sep     scall               ; display message for test 4
           dw      f_inmsg
           db      'Test 4',10,13,0
           mov     rf,startmem
test4_1:   glo     rf                  ; get byte number
           str     rf                  ; store it
           inc     rf                  ; point to next memory cell
           ghi     rf                  ; need to see if done
           shl
           lbnf    test4_1             ; loop back if not
           mov     rf,startmem         ; point back to beginning of memory
test4_2:   glo     rf                  ; get byte number
           phi     r7                  ; set exptected result
           str     r2                  ; and store to stack for compare
           ldn     rf                  ; retrieve byte from memory
           sm                          ; subtract expected
           lbnz    test4no             ; jump if error
test4_3:   inc     rf                  ; point to next memory cell
           ghi     rf                  ; need to see if done
           shl
           lbnf    test4_2             ; jump if not
           lbr     test5               ; jump to test 3
test4no:   sep     scall               ; display error
           dw      error
           lbr     test4_3             ; then continue

test5:     sep     scall               ; display message for test 5
           dw      f_inmsg
           db      'Test 5',10,13,0
           ldi     0                   ; start with zero byte
           plo     r9                  ; store here
; TEST 5 write all values in all tested memory cells
test5_1:   mov     rf,startmem         ; start at beginning of memory
           ldi     '.'                 ; display something to show not hung
           sep     scall
           dw      f_type
test5_2:   glo     r9                  ; get test byte
           phi     r7                  ; store as expected byte
           str     rf                  ; write to memory
           sex     rf                  ; point x to memory
           sm
           sex     r2                  ; point x back
           lbnz    test5no             ; jump on error
test5_3:   inc     rf                  ; point to next memory cell
           ghi     rf                  ; need to see if done
           shl
           lbnf    test5_2             ; loop back if not
           glo     r9                  ; get test byte
           adi     1                   ; increment it
           plo     r9                  ; put it back
           lbnz    test5_1             ; loop for next pass if not done
           lbr     done                ; done with testing
test5no:   ldn     rf                  ; get byte from memory
           plo     r7                  ; store for error display
           sep     scall               ; display error
           dw      error
           lbr     test5_3             ; continue test

done:      sep     scall               ; display conclusion message
           dw      f_inmsg
           db      10,13,10,13,'Tests complete. Reboot system',10,13,0
           lbr     f_boot             ; boot the system




; ********************************
; ***** Ascii hex of D in R8 *****
; ********************************
hexoutret: sep     r3                  ; return to caller
hexout:    plo     r8                  ; save value for now
           shr                         ; move hi nybble to low
           shr
           shr
           shr
           adi     '0'                 ; convert to ascii
           phi     r8                  ; put high byte r8.1
           smi     '9'+1               ; did we go past numbers
           lbnf    hexout2             ; jump if not
           ghi     r8                  ; need to move up to letters
           adi     7                   ; convert to letter
           phi     r8                  ; and put it back
hexout2:   glo     r8                  ; retrieve original number
           ani     0fh                 ; keep only low nybble
           adi     '0'                 ; convert to ascii
           plo     r8                  ; put into r8.0
           smi     '9'+1               ; did we go past numbers
           lbnf    hexoutret           ; return if not
           glo     r8                  ; retrieve number
           adi     7                   ; convert to a letter
           plo     r8                  ; put it back
           lbr     hexoutret           ; and return
           
error:     ghi     rf                  ; high byte of address
           sep     ra                  ; convert to hex
           ghi     r8                  ; high nybble
           sep     scall               ; output it
           dw      f_type
           glo     r8                  ; get low nybble
           sep     scall               ; output it
           dw      f_type
           glo     rf                  ; low byte of address
           sep     ra                  ; convert to hex
           ghi     r8                  ; high nybble
           sep     scall               ; output it
           dw      f_type
           glo     r8                  ; get low nybble
           sep     scall               ; output it
           dw      f_type
           ldi     ':'
           sep     scall
           dw      f_type
           ldi     ' '
           sep     scall
           dw      f_type
           ghi     r7                  ; get expected value
           sep     ra                  ; convert to hex
           ghi     r8                  ; high nybble
           sep     scall               ; output it
           dw      f_type
           glo     r8                  ; get low nybble
           sep     scall               ; output it
           dw      f_type
           ldi     '<'
           sep     scall
           dw      f_type
           ldi     '>'
           sep     scall
           dw      f_type
           glo     r7                  ; get returned value
           sep     ra                  ; convert to hex
           ghi     r8                  ; high nybble
           sep     scall               ; output it
           dw      f_type
           glo     r8                  ; get low nybble
           sep     scall               ; output it
           dw      f_type
           ldi     10
           sep     scall
           dw      f_type
           ldi     13
           sep     scall
           dw      f_type
           sep     sret                ; return to caller
endrom:    equ     $
           end     start


 



           

 
