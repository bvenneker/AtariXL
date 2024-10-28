// Bootloader for chat cartridge on Atari 800XL
// Assembler: MADS

  opt h-      ;Disable Atari COM/XEX file headers
  opt f+      ;Activate fill mode 
  
character   = $80
textPointer = $81
textlen     = $83
rowcrs      = $54     ; cursor row 
colcrs      = $55     ; cursor colm
putchar_ptr = $346    ; pointer to print routine
curinh      = $2F0    ; cursor inhibit, cursor is invisible if value is not zero
targetLow   = $3F
targetHi    = $40
sizeLow     = $41
sizeHi      = $42
DELAY       = $43

  org $A000      ; start address of RD5 Cartridge
  
init
  rts            ; cartridge init routine needs a rts

main 

sendInit:
  lda $D500       // check RTR
  and #%00000001
  cmp #%00000001
  bne sendInit
  lda #232
  sta $D502
  

  displayText t1, #0,#0 
  lda #200
  sta DELAY
  jsr jdelay
  jsr jdelay
  jsr jdelay
  
  
  // wait for RTR
readRTR  
  lda $D500       // check RTR
  and #%00000001
  cmp #%00000001  
  beq send100 
  lda $D501       // check RTS 
  and #%00000010
  cmp #%00000010
  bne readRTR
  lda $D502       // read data from cartridge output buffer
  cmp #232
  bne readRTR
  jmp resetAtari

send100  
  // Send 232 when RTR is high
  lda #100
  sta $D502

  displayText t2, #2,#0
  
// receive file size low byte
  jsr waitRTS
  lda $D502
  sta sizeLow
//  displayText t3, #3,#0
// receive file size high byte
  jsr waitRTS
  lda $D502
  sta sizeHi
//  displayText t4, #3,#0
  lda #00
  sta targetLow
  lda #32
  sta targetHi
  
receiveBytes
  jsr waitRTS
  lda $D502
  ldy #0
  sta (targetLow),y 
  
  dec sizeLow
  lda sizeLow
  cmp #255
  bne cont
  dec sizeHi
    
cont  
  lda sizeLow
  ora sizeHi
  cmp #0
  beq done
  inc targetLow
  lda targetLow
  cmp #0
  bne receiveBytes
  inc targetHi
  jmp receiveBytes
  
done 
  jmp $2000 


waitRTS:
  lda $D501             ; ask for status RTS (ready to send) 
  and #%00000010
  cmp #%00000010
  bne waitRTS
  rts
  
resetAtari:  
   jmp $E477 

//=========================================================================================================
// SUB ROUTINE, DELAY
//=========================================================================================================
jdelay:                                           // the delay sub routine is just a loop inside a loop
                                                  // 
    ldx #00                                       // the inner loop counts up to 255
                                                  // 
loop_d1                                           // the outer loop repeats that 255 times
                                                  // 
    cpx DELAY                                     // 
    beq enddelay                                  // 
    inx                                           // 
    ldy #00                                       // 
                                                  // 
dodelay                                           // 
                                                  // 
    cpy #255                                      // 
    beq loop_d1                                   // 
    nop                                           // 
    nop                                           // 
    iny                                           // 
    jmp dodelay                                   // 
                                                  // 
enddelay                                          // 
    rts                                           // 
                                                  // 
                                                 
// ----------------------------------------------------------------------
// displayTextk, used in macro displayText
// ----------------------------------------------------------------------
displayTextk:  
  mva #1 curinh
next_char
  ldy character
  cpy textLen
  beq exit_dpt
  lda (textPointer),y

  jsr writeText
  inc character
  jmp next_char


exit_dpt
  rts
  
writeText:
  tax
  lda putchar_ptr+1
  pha
  lda putchar_ptr
  pha
  txa
  rts


  
// ----------------------------------------------------------------
// Constants
// ----------------------------------------------------------------
  .local t1 
  .byte 'Bootloader, loading from ESP32'
  .endl

  .local t2
  .byte 'Receiving xex file'
  .endl

  .local t3 
  .byte 'File size Low'
  .endl

  .local t4
  .byte 'File size High'
  .endl
  
        
        
; $A000 - $BFFF        
; ************************ CARTRIDGE CONTROL BLOCK *****************
  org $bffa             ;Cartridge control block
  .word main             
  .byte 0                
  .byte $04
  .word init       
        

 ; run init
  

// -----------------------------------
// text = the text
// line = 0 - 23
// column = 0,39
// -----------------------------------
.macro displayText text,line,column
  mva :line rowcrs
  mva :column colcrs
  mva #0 character
  lda #.len :text
  sta textLen
  lda #<(:text) 
  sta textPointer
  lda #>(:text)
  sta textPointer+1
  jsr displayTextk  
.endm  
  