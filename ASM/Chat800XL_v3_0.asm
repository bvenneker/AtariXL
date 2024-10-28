// special characters: https://www.youtube.com/watch?v=fOrMwNBoC7E&list=PLmzSn5Wy9uF8nTsZBtdk1yHzFI5JXoUJT&index=7

// geheugen toevoegen aan 600XL: https://www.youtube.com/watch?v=jyWtzC96kZo


// https://www.atarimax.com/jindroush.atari.org/acarts.html
// https://atariwiki.org/wiki/Wiki.jsp?page=Cartridges
// https://grandideastudio.com/media/pp_atari8bit_instructions.pdf
// https://grandideastudio.com/media/pp_atari8bit_schematic.pdf

// https://playermissile.com/dli_tutorial/ 

  
WSYNC     = $d40a
NMIEN     = $d40e
VDSLST    = $0200
COLPF0    = $d016
NMIEN_DLI = $80
NMIEN_VBI = $40
COLPF1    = $d017
COLPF2    = $d018
COLPF3    = $d019
COLOR0    = $02c4
SDLSTL    = $0230


POKEY  = $D200
 
color2 = $2c6
color4 = $2c8
start_color = $45
text_color = $36
character = $3f 
textPointer = $40
textlen = $83
rowcrs = $54          ; cursor row 
colcrs = $55          ; cursor colm
inputfield = $43      ; 43 and 44 hold a pointer to the main input field 

putchar_ptr = $346    ; pointer to print routine
curinh = $2F0         ; cursor inhibit, cursor is invisible if value is not zero
sm_prt = $58          ; zero page pointer to screen memory


  org $2000           ; program starts at $2000

init
  mva #0 $52             ; set left margin to zero
  lda sm_prt             ; load the lowbyte of the pointer for screen memory
  adc #72                ; add 72
  sta inputfield         ; store in $43 
  lda sm_prt+1           ; load the high byte
  adc #3                 ; add 3
  sta inputfield+1       ; store in $44.
  
  lda #0  
  sta color4
  sta color2
  sta character  
  
  

main 
  jsr startScreen
  lda #$7D       ; load clear screen command
  jsr writeText  ; print it to screen
  
main_chat_screen:
  mva #255 $2fc                       ; clear keyboard buffer
  mva #0 colcrs                       ; set cursor row position to zero  
  displayText divider_line, #20,#0    ; draw the divider line
  mva #0 curinh     // show the cursor
  jsr clearInputLines
 
  jsr text_input    // jump to the text input routine

 
// ----------------------------------------------------------------------
// Main Menu
// ----------------------------------------------------------------------
main_menu:
  lda #$7D       ; load clear screen command
  jsr writeText  ; print it to screen
  displayText divider_line, #0,#0    ; draw the divider line
  displayText text_main_menu, #1,#15    ; draw the menu title
  displayText divider_line, #2,#0    ; draw the divider line
  displayText MLINE_MAIN1, #5,#3
  displayText MLINE_MAIN2, #7,#3
  displayText MLINE_MAIN3, #9,#3
  displayText MLINE_MAIN4, #11,#3
  displayText MLINE_MAIN5, #13,#3
  displayText MLINE_MAIN6, #15,#3
  displayText MLINE_MAIN7, #17,#3
  displayText divider_line, #22,#0    ; draw the divider line
  displayText version_line, #23,#0    ; draw the version line
  
main_menu_key_input:
  jsr getKey
  cmp #255
  beq main_menu_key_input
  
  cmp #$37                            // key 7 is pressed
  beq exit_main_menu
  
  cmp #$31                            // key 1 is pressed
  beq wifi_setup

  mva #255 $2fc                       ; clear keyboard buffer 
  jmp main_menu_key_input
  
exit_main_menu
  jmp restore_chat_screen


// ----------------------------------------------------------------------
// Backup and restore chat screen
// ----------------------------------------------------------------------

restore_chat_screen:
  lda #$7D       ; load clear screen command
  jsr writeText  ; print it to screen
  jmp main_chat_screen
  
// ----------------------------------------------------------------------
// Wifi setup screen
// ----------------------------------------------------------------------
  wifi_setup:  
  lda #$7D       ; load clear screen command
  jsr writeText  ; print it to screen
  displayText divider_line, #0,#0    ; draw the divider line
  displayText text_wifi_setup, #1,#15    ; draw the menu title
  displayText divider_line, #2,#0    ; draw the divider line
  displayText text_wifi_1, #5,#3
  displayText divider_line, #9,#0    ; draw the divider line
  displayText text_wifi_2, #12,#3
  displayText divider_line, #22,#0    ; draw the divider line
  
wifi_setup_key_input:
  jsr getKey
  cmp #255
  beq wifi_setup_key_input
  
  cmp #251                            // OPTION is pressed
  beq exit_to_main_menu
  
  mva #255 $2fc                       ; clear keyboard buffer 
  jmp wifi_setup_key_input
  
exit_to_main_menu
  mva #255 $2fc                       ; clear keyboard buffer 
  jmp main_menu
  
// ----------------------------------------------------------------------
// procedure for text input
// ----------------------------------------------------------------------
text_input:
  mva #0 curinh     // show the cursor 
key_loop
  //jsr blinkCursor
  jsr getKey
  cmp #255
  beq key_loop

cpoption
  cmp #251
  bne cpdelete
  mva #255 $2fc                       ; clear keyboard buffer 
  jmp main_menu
  
cpdelete  
  cmp #8 ; delete
  beq handle_delete
   
cpreturn
  cmp #13
  beq handle_return

cpCursorKeys  
  cmp #142     
  beq handle_up
  cmp #143
  beq handle_down
  cmp #134
  beq handle_left
  cmp #135
  beq handle_right

chrout
  jsr writeText
  mva #255 $2fc                       ; clear keyboard buffer 
  jmp key_loop

handle_delete
  lda rowcrs
  cmp #21
  bne delok
  lda colcrs
  cmp #0
  bne delok  
  mva #255 $2fc                       ; clear keyboard buffer 
  jmp key_loop
delok  
  lda #$1E                    // this is to work around a bug. backspace does not always work  
  jsr writeText               // when the cursor is at column zero.. this works around that
  lda colcrs                  // in stead of using backspace, we walk the cursor back,
  cmp #39                     // write a space character and walk the cursor back again
  bne delcont                 // But if you walk the cursor back on column zero, it goes
  lda #$1C                    // to column 39 on that SAME LINE.. so we have to correct
  jsr writeText               // that too..
delcont                       // Man this is getting ugly..
  lda #32                     //
  jsr writeText               // anyway, it works now. get over it, move on, have a beer
  lda #$1E
  jsr writeText
  lda colcrs
  cmp #39
  bne delexit
  lda #$1C
  jsr writeText
delexit
  mva #255 $2fc
  jmp key_loop
         
handle_return
  lda #$9b
  jmp chrout
 
handle_up
  lda rowcrs                          // ignore this key if we are on the first line
  cmp #21
  bne upok
  mva #255 $2fc                       // clear keyboard buffer 
  jmp key_loop
upok
  lda #$1C
  jmp chrout
  
handle_down
  lda rowcrs                          // ignore this key if we are on the last line
  cmp #23
  bne downok
  mva #255 $2fc                       // clear keyboard buffer 
  jmp key_loop
downok  
  lda #$1D
  jmp chrout

handle_left
  lda #$1E
  jmp chrout

handle_right
  lda #$1F
  jmp chrout


// ----------------------------------------------------------------------
// procedure to blink the cursor
// ----------------------------------------------------------------------
blinkCursor: 
  rts  // <--- not in use!!
  dec blink  
  lda blink
  
  cmp #0
  bne exit_bc
  
  dec blink2
  lda blink2
  cmp #235
  bne exit_bc
   
  mva #0 blink2  
  lda rowcrs
  sbc #21
  tax
  lda startR,x
  sta temppos
  ldy colcrs
   
lq1  
  cpy #0  
  beq lqd
  dey
  inc temppos
  jmp lq1
lqd
  ldy temppos
  lda (inputfield),y                  ; get the character under the cursor
  adc #127                            ; invert the char
  sta (inputfield),y                  ; put it back on the screen
  cmp #127
  bcc setphase1  
  lda #0
  sta cursorphase
  jmp exit_bc
  
setphase1
  //lda #1
  inc cursorphase
  jmp exit_bc
  
  //rowcrs = $54 ; cursor row 
  //colcrs = $55 ; cursor colm ; find out where the cursor is
  //
  
exit_bc
  rts

// ----------------------------------------------------------------------
// procedure for sound
// ----------------------------------------------------------------------
beep1:
  lda #%01001000
  jsr chibiSound
  mva #10 DELAY 
  jsr jdelay
  lda #0
  jsr chibiSound

  rts

chibiSound: ; %nvpppppp  n=noise v=volume p=pitch
  cmp 0
  beq silent

  pha
  and #%10000000 ; Noise bit
  beq noNoise
  lda #%00000111
  jmp noiseDone
noNoise
  lda #%10100111
noiseDone
  sta z_as 
  lda #0
  sta POKEY+8
  pla

  pha
  and #%00111111
  asl
  asl
  sta POKEY+0
  pla
  
  and #%01000000
  lsr
  lsr
  lsr
  ora z_as
  
silent 
  sta POKEY+1
  rts
  

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
//  Clear input lines
// ----------------------------------------------------------------------
clearInputLines:  
  // fill the input lines with spaces  
  mva #21 rowcrs
  mva #0 colcrs
  lda #32 // space character
  ldy #0
  sty temppos
cl_loop  
  jsr writeText
  inc temppos
  ldy temppos
  cpy #118
  beq cl_exit
  jmp cl_loop
cl_exit
  mva #21 rowcrs
  mva #0 colcrs
  lda #32           // type a space character
  jsr writeText     //
  lda #$7e          // remove the space character
  jsr writeText     // now the cursor is visible

  rts

 
// ----------------------------------------------------------------------
//  READ CHAR FROM KEYBOARD   
//  CHAR WILL BE IN THE       
//  <A> REGISTER              
//  <X>,<Y> will be destroyed 
// ----------------------------------------------------------------------
kb2asci: 
    // see https://www.atariarchives.org/c3ba/page004.php
//       0   1   2  3 4  5   6   7   8  9 10   11 12  13  14  15  16 17 18  19 20 21  22  23  24  25  26  27 28  29  30
  .byte 'l','j',';',3,4,'k','+','*','o',9,'p','u',13,'i','-','=','v',17,'c',19,20,'b','x','z','4',25,'3','6',28,'5','2'
//          31  32   33  34  35 36 37  38  39 40  41  42  43  44  45 46  47  48  49  50  51 52  53  54  55  56  57  58 59 60
  .byte     '1',',',' ','.','n',36,'m','/',39,'r',41,'e','y', 44,'t','w','q','9',49,'0','7',8,'8','<','>','f','h','d',59,60
//          61  62   63  64  65 66  67 68 69  70  71  72  73  74  75 76  77  78  79  80 81  82 83 84  85  86  87  88 89 90
  .byte     'g','s','a','L','J',':', 3,68,'K','\','^','O',73,'P','U',76,'I','_','|','V',81,'C',83,84,'B','X','Z','$',89,'#'
//          91  92  93  94  95  96 97  98  99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 
  .byte     '&',28,'%','"','!','[',33,']','N',100,'M','?', 39,'R',105,'E','Y',108,'T','W','Q','(',113,')',96,8,'@',118,119,'F'
//          121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150  
  .byte     'H','D',123,124,'G','S','A','L','J',';',  '3',  4,'K',134,135,'O',137,'P','U', 76,'I',142,143,'V', 17,'C', 19, 20,'B','X'
//          151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180
  .byte     'Z','$',153,'#','&', 28,'%','"','!','[',161,']','N',164,'M','?', 39,'R',169,'E','Y',172,'T','W','Q','(',177,')',96,8
//          181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210
  .byte     '@',182,183,'F','H','D',187,188,'G','S','A','L','J',';',195,196,197,198,199,'O',201,'P','U', 76,'I','_','|','V',209,210
//          211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240
  .byte     211,212,213,214,215,'$',217,'#','&',220,'%','"','!','[',225,']','N',228,'M','?',231,'R',233,'E','Y',236,'T','W','Q','('
//          241 242 243 244 245 246 247 248 249 250 251 252 253 254 255
  .byte     241,')' ,96,  8,'@',246,247,'F','H','D',251, 60,'G','S','A'
  //   3 = f1
  //   4 = f2
  //   8 = backspace
  //   9 = tab
  //  13 = return
  //  17 = HELP
  //  19 = F3
  //  20 = F4
  //  28 = ESCAPE
  //  39 = logo key
  //  44 = TAB
  //  52 = Delete
  //  60 = caps/lowr
  //  67 = Shift F1 is now 3 (normal F1)
  //  68 = shift F2 
  //  76 = shift Return
  //  81 = shift HELP
  //  83 = Shift F3
  //  84 = Shift F4
  //  92 = Shift Escape. is now 28 (normal escape)
  // 103 = shift logo key, is nu 39 (normal logo)
  // 108 = shift TAB
  // 116 = shift delete  
  // 118 = clear
  // 119 = insert
  // 124 = shift caps/lowr
  // 131 = Control F1 is now 3 (normal F1)
  // 132 = Control F2 is now 4 (normal F2)
  // 134 = LEFT
  // 135 = RIGHT
  // 140 = Control Return is now 76 (shift return)
  // 142 = UP
  // 143 = DOWN
  // 145 = Control HELP, is now 17 (normal help)
  // 147 = Control F3, is now 19 (normal f3)
  // 148 = Control F4, is now 20 (normal f4)
  // 156 = Control ESC, is nu 28 (normal escape)
  // 167 = Control Logo, is nu 39 (normal logo)
  // 204 = shift control Return, is now 76 (shift return)

getKey:   
  jsr readRTS                           // check for incomming data or reset request   
  lda $D01F  // is one of the 'function keys' pressed?
  and #7
  cmp #6
  beq prSTART
  cmp #5
  beq prSELECT
  cmp #3
  beq prOPTION
  
  lda $02DC  // is the HELP key pressed ?
  and #1
  cmp #1
  beq prHELP
  
  lda $2FC  // is there a key in the keyboard buffer?
  cmp #255
  beq exit_getkey

keyConvert
  tay
  lda kb2asci,y
exit_getkey
  rts
  
prOPTION
  // wait until the key is released
  lda $D01F
  and #4
  cmp #0
  beq prOPTION
  lda #251
  rts
prSELECT
  // wait until the key is released
  lda $D01F
  and #2
  cmp #0
  beq prSELECT
  lda #252
  rts
prSTART
  // wait until the key is released
  lda $D01F
  and #1
  cmp #0
  beq prSTART
  lda #253
  rts
prHelp
  lda #0     // 
  sta $02DC  // This address is latched and must be reset to zero after being read
  lda #254
  rts
  

// ----------------------------------------------------------------------
// Start Screen
// ----------------------------------------------------------------------


startScreen:
  mwa VDSLST dVDSLST   
  ; load display list interrupt address
  ldx #>dli
  ldy #<dli
  jsr init_dli
                                        // store zero in last key pressed
  mwa $230 ddlist                       // save the default display list
  mwa #dl $230                          // set our own display list pointer
                                        // the start screen is now displayed
wkey1  
  jsr readRTS                           // check for incomming data or reset request
  lda $02FC                             // wait for any key
  cmp #255                              // see if last key equals zero
  beq wkey1                             //

  mva #255 $02FC
  mwa ddlist $230                       // restore the display list 
  mwa dVDSLST VDSLST   
  lda #0  
  sta color4
  sta color2
  rts                                   // and return


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

init_dli
        ; load display list interrupt address
        sty VDSLST
        stx VDSLST+1

        ; activate display list interrupt
        lda #NMIEN_VBI | NMIEN_DLI
        sta NMIEN
        rts

dli     pha             ; save A & X registers to stack
        txa
        pha
        ldx #16         ; make 16 color changes
        lda start_color ; initial color
        sta WSYNC       ; first WSYNC gets us to start of scan line we want
?loop   sta COLPF0      ; change text color for UPPERCASE characters in gr2
        clc
        adc #$1         ; change color value, making brighter
        dex             ; update iteration count
        sta WSYNC       ; sta doesn't affect processor flags
        bne ?loop       ; we are still checking result of dex
        lda #text_color ; reset text color to normal color
        sta COLPF0
        dec start_color ; change starting color for next time
        pla             ; restore X & A registers from stack
        tax
        pla
        rti             ; always end DLI with RTI!

// ----------------------------------------------------------------------
// Check incomming data
// ----------------------------------------------------------------------
readRTS:
  lda $D501       // check RTS 
  and #%00000010
  cmp #%00000010
  bne exitRTS
  lda $D502
  cmp #232
  beq resetAtari   
exitRTS
  rts
  
resetAtari:  
   jmp $E477      // jump to reboot vector to restart the Atari.
// ----------------------------------------------------------------
// Constants
// ----------------------------------------------------------------
version .byte '3.77'
version_date .byte '10/2024'

  .local text_wifi_setup
  .byte 'WIFI SETUP'
  .endl
  
  .local text_wifi_1
  .byte 'SSID:'
  .byte  $9b,$9b,'   '
  .byte 'PASSWORD:'
  .endl

  .local text_wifi_2
  .byte '[START]  Safe Settings'
  .byte  $9b,$9b,'   '
  .byte '[OPTION] Exit'
  .endl  
  
  .local text_main_menu
  .byte 'MAIN MENU'
  .endl
  
  .local version_line
  .byte ' Version  ROM x.xx  ESP x.xx    10/2024'
  .endl
  
  .local MLINE_MAIN1
  .byte '[1] Wifi Setup'
  .endl
  .local MLINE_MAIN2
  .byte '[2] Server Setup'
  .endl
  .local MLINE_MAIN3
  .byte '[3] Account Setup'
  .endl
  .local MLINE_MAIN4
  .byte '[4] List Users'
  .endl
  .local MLINE_MAIN5
  .byte '[5] About This Software'
  .endl
  .local MLINE_MAIN6
  .byte '[6] Help'
  .endl
  .local MLINE_MAIN7
  .byte '[7] Exit Menu'
  .endl
  
  .local t1 
  .byte 'Ontvangen: '
  .endl

  .local t2
  .byte '153'
  .endl

  .local t3 
  .byte 'RTS = 0'
  .endl

  .local t4
  .byte 'RTS = 1'
  .endl
  
  .local t5 
  .byte 'RTR = 0'
  .endl

  .local t6
  .byte 'RTR = 1'
  .endl
  
  .local text_madeBy 
  .byte 'Made by Bart and Theo in 2024'  
  .endl
  
  .local divider_line
  :40 .byte 18 ; 40 x byte 18
  .endl
  
  .local text_startScreen
  .byte "       BART       "
  .byte "      atari 800xl  "
  .byte "         Input Output Test Program         "
  .endl
  
  .local dl ; display list for the start screen
     .byte $70,$70,$70,$70,$70,$70,$70   
     .byte $f0          ; 8 blank lines + DLI on next scan line
     .byte $47,a(text_startScreen) ; Mode 6 + LMS, setting screen memory to text
     .byte $70,$70      ; 16 blank lines
     .byte 6            ; Mode 6
     .byte $70,$70      ; 16 blank lines
     .byte 2            ; 3 lines of Mode 7
     .byte $41,a(dl)   
  .endl
  
  .local startR 
     .byte 0,40,80
  .endl
  
  
// ----------------------------------------------------------------
// Variables
// ----------------------------------------------------------------
blink   .byte 0,0
blink2  .byte 0,0
ddlist  .word 0,0
dVDSLST  .word 0,0
DELAY  .byte 0,0    
z_as .byte 0,0
cursorphase  .byte 0,0
temppos  .byte 0,0   
        
   
       
        
 run init
  

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
  