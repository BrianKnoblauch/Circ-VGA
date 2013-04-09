;=============================================================================
;FILE:  CIRC.ASM
;
;NOTES: Requires VGA+, 80286+, 80287+
;=============================================================================

_model          equ     <tiny>

include         MODEL.INC


.codeseg        lib
.extrn          start:auto, exit:auto, exit_ok:auto
.extrn          cput_str:auto, cget_str:auto, dec_to_words:auto
.extrn          console_init:auto
.ends


.dataseg
;----------------------------------------------------------
; Declare external library and program data here...
;----------------------------------------------------------
tmp     label   word
        dd      0
clb     label   byte
c       dw      ?
corna   dw      ?
cornb   dw      ?
side    dw      ?
i       dw      0
j       dw      0
imax    dw      639
jmax    dw      479
colors  dw      16
line1   db      0dh,0ah,"Input Corner A: ",0
line2   db      0dh,0ah,"Input Corner B: ",0
line3   db      0dh,0ah,"Input Side: ",0
inp     db      7 dup(?)
.ends


IF NOT __TINY__
.stackseg
                db      1024 dup(?)     ;define a 1024 byte stack
.ends
ENDIF


;=============================================================================
;FUNC:  MAIN
;
;DESC:  Main body of program.
;
;IN:    DX              segment address of PSP
;
;ASUMS: DS,ES           @DATASEG  (same as @CODESEG in TINY model)
;       SS              @STACKSEG (same as @CODESEG in TINY model)
;=============================================================================
.286
.287
.codeseg

IF __TINY__
assume          cs:@codeseg, ds:@dataseg, es:@dataseg, ss:@dataseg
ELSE
assume          cs:@codeseg, ds:@dataseg, es:@dataseg, ss:@stackseg
ENDIF

.public         main
.proc           main            auto
                call    console_init
                fninit
                mov     ax,0a000h
                mov     es,ax
                lea     si,line1
                call    cput_str
                fild    colors
                lea     si,inp
                mov     cx,6
                call    cget_str
                call    dec_to_words
                mov     corna,ax
                lea     si,line2
                call    cput_str
                lea     si,inp
                call    cget_str
                call    dec_to_words
                mov     cornb,ax
                lea     si,line3
                call    cput_str
                lea     si,inp
                call    cget_str
                call    dec_to_words
                mov     side,ax
                mov     ax,12h
                int     10h
                mov     dx,3ceh
                mov     ax,205h
                out     dx,ax
                mov     ax,3
                out     dx,ax
top_of_l:       mov     ax,side
                imul    i
                mov     tmp,ax
                mov     tmp+2,dx
                fild    tmp
                mov     ax,side
                fidiv   imax
                imul    j
                fiadd   corna
                mov     tmp,ax
                mov     tmp+2,dx
                fmul    st,st(0)
                fild    tmp
                fidiv   jmax
                fiadd   cornb
                fmul    st,st(0)
                faddp
again:          fprem
                fstsw   ax
                sahf
                jp      again
                fistp   c
                mov     ax,j
                mov     bx,i
                mov     cl,bl
                mov     dx,80
                mul     dx
                shr     bx,3
                add     bx,ax
                and     cl,7
                xor     cl,7
                mov     ah,1
                shl     ah,cl
                mov     dx,3ceh
                mov     al,8
                out     dx,ax
                mov     al,es:[bx]
                mov     al,clb
                mov     es:[bx],al
                inc     j
                cmp     j,479
                jbe     top_of_l
                mov     j,0
                inc     i
                cmp     i,639
                ja      finish
                jmp     top_of_l
finish:         fninit
                mov     dx,3ceh
                mov     ax,0ff08h
                out     dx,ax
                mov     ax,5
                out     dx,ax
                mov     ah,10h
                int     16h
                mov     ax,3
                int     10h
                ret                     ;exit to DOS with ERRORLEVEL=0
.endp           main

;----------------------------------------------------------
; Declare additional functions here...
;----------------------------------------------------------

.ends







;=============================================================================
; Stack normalization and memory management initialization labels
;
; NOTE: These declarations must remain after the declaration of the stack
; and anything in the stack segment. These labels define the end of the
; stack and the program, which is where the near and far heaps are placed
; by default. These declarations do not affect the size of the program and
; may be left here even if the stack is not normalized and the heaps are
; not used.
;=============================================================================

.public         nheap_default, fheap_default
IF NOT __TINY__
.stackseg
  IF __SMALL__ OR __MEDIUM__
.public         stack_end               ;used by START to normalize stack
.label          stack_end       word    ;must be defined past entire stack
  ENDIF
.label          nheap_default   word    ;used by the near heap
.label          fheap_default   word    ;used by the far heap
.ends
ELSE
_BSSEND         segment byte public 'STACK'
.label          nheap_default   word    ;used by the near heap
.label          fheap_default   word    ;used by the far heap
_BSSEND         ends
% @codeseg      group   _BSSEND
ENDIF


                end     start           ;specify START as starting address
