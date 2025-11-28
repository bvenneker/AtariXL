; http://map.tni.nl/
; https://map.grauw.nl/resources/msxbios.php
; https://map.grauw.nl/resources/msxsystemvars.php

// splitbuffer kan de bytes rechtstreeks naar de juiste 
// plek kopieren, hoeft niet via SPLITBUFFER

; -----------------------------------------------------------------------
 MACRO PrintBuffer row, col, buffer
    ld b, row      ; row
    ld c, col      ; column
    ld hl, buffer  ; pointer to string
    call putstr
 ENDM
 
 MACRO CreateInputField buffer,row, col, length
   ld hl,buffer
   ld b,length   
   ld d,col
   ld e,row  
   call TextInputField
 ENDM
; ----------------------------------------------------------------------- 
 

PSG_REG  equ 0A0h
PSG_DAT  equ 0A1h
VDP_DATA  equ 098h
VDP_CTRL  equ 099h
CARTRIDGE_IO = $60                   ; IO port address for the cartridge (01100000)
IO_RTR = $61
IO_RTS = $62

 
  org $C000
  
 
MainProgram:
  
  ld sp, $F380   ; stack goes to Safe address near top of RAM
  ld a,1
  call $005F     ;  init screen1 with width 32
  ld a,32 
  ld ($F3B0),a
  EI
  
  ld HL,cursorString
  ld a,$ff
  ld (HL),a
  inc HL
  inc a
  ld (HL),a
  
  ld HL,CharUnderCursor
  ld a,32
  ld (HL),a
  inc HL
  ld a,0
  ld (HL),a
  inc HL
  ld (HL),a
  inc HL
  ld (HL),a
  
  call ClearFunctionKeys  
  
  LD HL,FORCLR	; 
	LD (HL),15	; white forground
	INC HL		;	Change colours
	LD (HL),0	; black border
	INC HL		;
	LD (HL),0	; black screen
  call $0062 ; change color
  call custom_chars1 
  call clear_screen
  call start_screen
  call clear_screen 
  call custom_chat_chars  
  
  call KILBUF
  call are_we_in_the_matrix
  call get_status  
  jp public_chat
  
; ---------------------------------------------------------------------
; Clear Function Keys                             
; ---------------------------------------------------------------------
ClearFunctionKeys:  
  ld b,160       ; clear function key strings
  ld HL,$F87F
  ld a,BACKSPACE ; fill the stings with backspace characters
clearString:  
  ld (HL),a
  inc HL
  dec b
  jr nz,clearString
  RET
; ---------------------------------------------------------------------
; Clear screen FAST!                             
; ---------------------------------------------------------------------
clear_screen:
    ld de,1800h        ; start of SCREEN 1 name table
    call set_vram_addr_write
    ld a,' '           ; space
    ld bc,768          ; 32x24 characters
clear_loop:
    out (VDP_DATA),a
    dec c
    jr nz,clear_loop
    djnz clear_loop
    ret

clear_message_lines:
  ld HL,$1AA0    ; bottom green line
  ld BC,96
  ld a,' '
  call $0056
  ret
  
; ---------------------------------------------------------------------
; Main Menu                              
; ---------------------------------------------------------------------
draw_menu_bars:  
  call set_menu_colors
  call clear_screen
  ld HL,$1800    ; first green line
  ld BC,32
  ld a,$F8
  call $0056
  ld HL,$1840    ; second green line
  ld BC,32
  ld a,$F8
  call $0056
  ld HL,$1AC0    ; bottom green line
  ld BC,32
  ld a,$F8
  call $0056
  
  ret  
  
main_menu:
  call draw_menu_bars

  PrintBuffer 23,0,MLINE_VERSION
  PrintBuffer 1,12,text_main_menu
  PrintBuffer 5,2,MLINE_MAIN1  // display the menu item 1
  PrintBuffer 7,2,MLINE_MAIN2  // display the menu item 2
  PrintBuffer 9,2,MLINE_MAIN3  // display the menu item 3
  PrintBuffer 11,2,MLINE_MAIN4  // display the menu item 4
  PrintBuffer 13,2,MLINE_MAIN5  // display the menu item 5
  PrintBuffer 15,2, MLINE_MAIN6  // display the menu item 6
  PrintBuffer 17,2, MLINE_MAIN7  // display the menu item 7

  
MenuLoop:
  ld hl, MainMenuKeyTable   ; Select which key table is active
  call CHSNS
  jr z,MenuLoop
  call HandleMenuKeys       ; Waits until 1..7 or ESC pressed
  jp MenuLoop               ; When handler returns, wait again

  
MainMenuKeyTable:  ; setup the menu key options    
  dw main_mnu_1
  dw main_mnu_2
  dw main_mnu_3
  dw main_mnu_4
  dw main_mnu_5
  dw main_mnu_6
  dw main_mnu_7

main_mnu_1:
  call wifi_setup
  ret ;jp main_menu
main_mnu_2:
  call account_setup
  ret
main_mnu_3:
  call server_setup
  ret
main_mnu_4:
  call user_list
  ret
main_mnu_5:
  call help_screen
  ret
main_mnu_6:
  call about_chat64
  ret
main_mnu_7:
  ; exit to chat
  jp public_chat
  
  RET
  

;------------------------
; WaitMenuKey:
; - Returns 0..5 for F1..F6
; - Returns 6 for ESC
; Loops until valid key is pressed
;------------------------
WaitMenuKey:
  ld a,(KEYS + 6)
  cp %11011111 : jr z, GotF1
  cp %10111111 : jr z, GotF2
  cp %01111111 : jr z, GotF3
  cp %11011110 : jr z, GotF6
  ld a,(KEYS + 7)
  cp %11111110 : jr z, GotF4
  cp %11111101 : jr z, GotF5
  cp %11111011 : jr z, GotEsc
  
  jr WaitMenuKey

GotF1: ld a,0 : ret
GotF2: ld a,1 : ret
GotF3: ld a,2 : ret
GotF4: ld a,3 : ret
GotF5: ld a,4 : ret
GotF6: ld a,5 : ret
GotEsc:ld a,6 : ret

; -----------------------------------------
; Menu Key Handler 
; -----------------------------------------
; Waits until a valid key is pressed
; and jumps to its handler.
HandleMenuKeys:
    push hl
    call WaitMenuKey
    ld e,a
    ld d,0
    add hl,de
    add hl,de           ; HL = HL + index*2
    ld e,(hl)
    inc hl
    ld d,(hl)
    pop hl
    ex de,hl
    jp (hl)

; ---------------------------------------------------------------------
; About Menu                              
; ---------------------------------------------------------------------
about_chat64:
  call KILBUF
  call draw_menu_bars
  PrintBuffer 1,9,text_about_menu
  PrintBuffer 3,0,about_text
  PrintBuffer 23,9, MLINE_MAIN7
about_wait_for_key:
  call CHSNS
  jr z, about_wait_for_key 
  call KILBUF
  jp account_mnu_7
  RET
  
; ---------------------------------------------------------------------
; User List                              
; ---------------------------------------------------------------------
user_list:
  call draw_menu_bars
  PrintBuffer 1,12,text_user_list
  PrintBuffer 23,0,MLINE_NEXT_PAGE
  PrintBuffer 6,0,no_users
  
  call KILBUF
users_wait_for_key:
  call CHSNS
  jr z,users_wait_for_key
  call CHGET
  cp 27 ; ESC
  jp z,account_mnu_7
  cp 'f'
  jr z,user_list
  cp 'n'
  jr z,user_list  
  jr users_wait_for_key-3
  RET

; ---------------------------------------------------------------------
; account Menu                              
; ---------------------------------------------------------------------
account_setup:
  call draw_menu_bars
  PrintBuffer 1,9,text_account_menu
  PrintBuffer 4,1,MLINE_MAC  
  PrintBuffer 6,1,MLINE_REGID
  PrintBuffer 8,1,MLINE_NICKNAME
  PrintBuffer 10,0,MLINE_GREEN
  PrintBuffer 17,2,MLINE_MAIN7
  PrintBuffer 15,2,MLINE_RESET

account_input_fields:
  CreateInputField Field1Buffer,7, 10, 16   // User can input regid
  cp 7 : jr z, account_mnu_7
  cp 6 : jr z, account_mnu_6
  
  CreateInputField Field2Buffer,9, 13, 10   // User can input Nickname
  cp 7 : jr z, account_mnu_7
  cp 6 : jr z, account_mnu_6
  
  PrintBuffer 13,2,MLINE_SAVE
  jr AccountMenuLoop

SaveAccountSettings:  
  PrintBuffer 0, 0, Field1Buffer
  PrintBuffer 1, 0, Field2Buffer
  
AccountMenuLoop:
  ld hl, AccountMenuKeyTable   ; Select which key table is active
  call CHSNS
  jr z,AccountMenuLoop
  call HandleMenuKeys          ; Waits until 1..7 or ESC pressed
  jr AccountMenuLoop           ; When handler returns, wait again

AccountMenuKeyTable:  ; setup the menu key options    
  dw account_mnu_1    ; F1 key was pressed
  dw AccountMenuLoop  ; not valid, jump back to menu loop
  dw AccountMenuLoop  ; not valid, jump back to menu loop
  dw AccountMenuLoop  ; not valid, jump back to menu loop
  dw AccountMenuLoop  ; not valid, jump back to menu loop
  dw account_mnu_6    ; F6 key was pressed
  dw account_mnu_7    ; ESC key was pressed

account_mnu_1:  
  jp SaveAccountSettings
  
account_mnu_6: 
  jp reset_screen 
  ret  
account_mnu_7:  
  pop hl       ; discard return address (2 bytes)
  jp main_menu
  RET
  
  
; ---------------------------------------------------------------------
; Reset Screen                              
; ---------------------------------------------------------------------
reset_screen:
  call draw_menu_bars
  PrintBuffer 1,4,text_reset_screen
  PrintBuffer 6,0,reset_warning
reset_key_input:  
  call CHSNS
  jr z, reset_key_input 
  call CHGET
  cp 'y'
  jr z, do_reset
  cp 'n'
  jp z, account_mnu_7
  jr reset_key_input
do_reset:  
  call clear_screen 
  rst 0  
; ---------------------------------------------------------------------
; Server Menu                              
; ---------------------------------------------------------------------
server_setup:
  call draw_menu_bars
  PrintBuffer 1,11,text_server_menu
  PrintBuffer 4,1,MLINE_SERVER
  PrintBuffer 6,1,MLINE_SERVER2
  PrintBuffer 8,0,MLINE_GREEN
  PrintBuffer 17,2,MLINE_MAIN7
server_inputFields:
  CreateInputField Field1Buffer,5, 9, 23   // User can input Server url
  cp 7 : jp z, wifi_mnu_7
  PrintBuffer 15,2,MLINE_SAVE
  jr ServerMenuLoop
  
SaveServerSettings:  
  PrintBuffer 0, 0, Field1Buffer
   
ServerMenuLoop:
  ld hl, ServerMenuKeyTable   ; Select which key table is active
  call CHSNS
  jr z,ServerMenuLoop
  call HandleMenuKeys       ; Waits until 1..7 or ESC pressed
  jr ServerMenuLoop           ; When handler returns, wait again

ServerMenuKeyTable:  ; setup the menu key options    
  dw server_mnu_1
  dw ServerMenuLoop
  dw ServerMenuLoop
  dw ServerMenuLoop
  dw ServerMenuLoop
  dw ServerMenuLoop
  dw server_mnu_7
   

server_mnu_1:  
  jp SaveServerSettings
  
server_mnu_7:  
  pop hl       ; discard return address (2 bytes)
  jp main_menu
  RET

; ---------------------------------------------------------------------
; WiFi Menu                              
; ---------------------------------------------------------------------
wifi_setup:
  call draw_menu_bars
  PrintBuffer 1,12,text_wifi_menu
  PrintBuffer 17,2,MLINE_MAIN7
  PrintBuffer 4,1,MLINE_SSID
  PrintBuffer 6,1,MLINE_PASSW
  PrintBuffer 8,1,MLINE_OFFSET
  PrintBuffer 10,0,MLINE_GREEN


wifi_inputFields:  
  CreateInputField Field1Buffer,5, 8, 21   // User can input SSID
  cp 7 : jr z, wifi_mnu_7

  CreateInputField Field2Buffer,7, 11, 18   // User can input Password
  cp 7 : jr z, wifi_mnu_7
  
  CreateInputField Field3Buffer,9, 24, 3   // User can input Offset from GMT
  cp 7 : jr z, wifi_mnu_7
  
  PrintBuffer 15,2,MLINE_SAVE
  jr WifiMenuLoop
SaveWifiSettings:  
  PrintBuffer 0, 0, Field1Buffer
  PrintBuffer 1, 0, Field2Buffer
  PrintBuffer 2, 0, Field3Buffer
   
WifiMenuLoop:
  ld hl, WifiMenuKeyTable   ; Select which key table is active
  call CHSNS
  jr z,WifiMenuLoop
  call HandleMenuKeys       ; Waits until 1..7 or ESC pressed
  jr WifiMenuLoop           ; When handler returns, wait again

WifiMenuKeyTable:  ; setup the menu key options    
  dw wifi_mnu_1
  dw WifiMenuLoop
  dw WifiMenuLoop
  dw WifiMenuLoop
  dw WifiMenuLoop
  dw WifiMenuLoop
  dw wifi_mnu_7
  dw wifi_mnu_7

wifi_mnu_1:  
  jp SaveWifiSettings
  
wifi_mnu_7:  
  pop hl       ; discard return address (2 bytes)
  jp main_menu
  RET

;-----------------------------------------------------------
; fieldbuffer = HL
; b=field length
; d=column
; e=row
; 
;-----------------------------------------------------------
TextInputField:    
    push DE   
    push HL   // save the buffer location    
    push BC          
    ld a,0    // fill buffer with zeros
Loop345:
    ld (hl),a
    inc hl
    dec b
    jr nz,Loop345
    pop BC
    pop HL    // restore the buffer location   
    pop DE    // restore DE
    push HL   // save the buffer again
    ld HL,DE  // position the cursor
    call POSIT
    
    // setup function keys
    // F6 = $91
    ld a, $03
    ld ($F87F+80),a
    ld a, 0
    ld ($F87F+81),a

    call KILBUF
    pop HL    // restore the buffer again  
InputLoop1:
    call CHGET    
    cp $03                  ; F6 key
    jr z,doF6
    cp 27                   ; ESC key
    jr z,doEsc
    cp $0D                  ; RETURN key
    jr z,InputDone
    cp BACKSPACE            ; BACKSPACE key
    jr z,DoBackspace    
    cp ' '                  ; printable char? (32..126)
    jr c,InputLoop1
    cp 127
    jr nc,InputLoop1
    push AF
    push BC
    ld a,' '
ClearField:          ; clear field
    call CHPUT
    dec b
    jr nz,ClearField    
    ld a, BACKSPACE  ; walk back
    pop BC
    push BC
walkBack:
    call CHPUT
    dec b
    jr nz, walkBack
    pop BC
    pop AF

writeBuffer:      ; store character
    ld (hl),a
    inc hl
    call CHPUT
    dec b    
    jr nz, InputLoop1
    
    ld a,BACKSPACE
    ld b,1
    call CHPUT
    dec HL
    jr InputLoop1
    
DoBackspace:
    ld a,(CSRX)   // get cursor pos
    cp d          // compare with d (start of text field)
    jr z, InputLoop1
    ld a,' '
    call CHPUT
    ld a,BACKSPACE
    call CHPUT
    call CHPUT
    ld a,' '
    call CHPUT
    ld a,BACKSPACE
    call CHPUT
    inc b
    dec HL
    jr InputLoop1

InputDone:
    inc hl
    ld (hl),0
    ld a,0
    ret
doEsc:
    ld a,7
    ret
doF6:
    ld a,6
    ret
; ---------------------------------------------------------------------
; HELP Screen                             
; ---------------------------------------------------------------------
help_screen:
  call KILBUF
  call draw_menu_bars
  PrintBuffer 1, 6,text_help_screen1
  PrintBuffer 4, 0,help_private
  PrintBuffer 23, 9,MLINE_ANY_KEY
  
wait_help1:
  call CHSNS
  jr z, wait_help1 
  call KILBUF
  ld a,1 : call ClearLine
  PrintBuffer 1, 8,text_help_screen2
  PrintBuffer 4, 0,help_eliza
wait_help2:
  call CHSNS
  jr z, wait_help2 
  call KILBUF
  ld a,1 : call ClearLine
  PrintBuffer 1, 7,text_help_screen3
  ld a,10 : call ClearLine
  ld a,11 : call ClearLine
  ld a,12 : call ClearLine
  ld a,13 : call ClearLine
  PrintBuffer 4, 0,help_user_list
wait_help3:
  call CHSNS
  jr z, wait_help3 
  call KILBUF
  ld a,1 : call ClearLine
  ld a,8 : call ClearLine
  ld a,9 : call ClearLine
  PrintBuffer 1, 10,text_help_screen4
  PrintBuffer 4, 0,help_scrolling
wait_help4:
  call CHSNS
  jr z, wait_help4
  call KILBUF


  jp account_mnu_7
   

; --------------------------------------------------------
; Clear a specific line in SCREEN 1
; Input: A = line number (0-23)
; --------------------------------------------------------

ClearLine:
    ; --- Calculate VRAM address for line ---
    ld   h,0
    ld   l,a            ; HL = line number
    add  hl,hl          ; HL = line * 2
    add  hl,hl          ; HL = line * 4
    add  hl,hl          ; HL = line * 8
    add  hl,hl          ; HL = line * 16
    add  hl,hl          ; HL = line * 32   (done)

    ld   de,$1800       ; base of name table
    add  hl,de          ; HL = VRAM address of line start

    ; --- Set VRAM address (HL) for write ---
    ld   a,l
    out  ($99),a        ; low byte
    ld   a,h
    and  3Fh
    or   40h            ; write flag
    out  ($99),a

    ; --- Write 32 spaces ---
    ld   b,32
    ld   a,32           ; ASCII space

ClearLoop2:
    out  ($98),a
    djnz ClearLoop2
    ret    
    


;--------------------------------------------------------
; Main chat window
;--------------------------------------------------------
public_chat:
  call clear_screen  // clear the screen
  PrintBuffer 20,0,MLINE_GREEN // draw the divider line   
  ld h,1
  ld l,22
  call POSIT
  call KILBUF
  ld b, 21
  ld c, 0
  ld hl, cursorString
  call putstr
  ld a,(EMUMODE)
  cp 1
  jp nz, no_emu
  PrintBuffer 5,5,NO_CART_FOUND
no_emu:
chat_key_input:
  call draw_cursor
  call CHSNS
  jr z, chat_key_input
  call CHGET
  call restore_cursor
  call write_char
  
  jr chat_key_input
onzin: jr onzin

write_char:
  cp $1E 
  jr z, do_up
  cp $0D 
  jr z, do_return
  cp $08
  jr z, do_backspace
  cp $7f
  jr z, do_backspace
  cp $1D ; cursor left
  jr z, do_left  
  cp $1B
  jp z, do_esc
  cp $0B
  jp z, do_home
  cp $0C
  jp z, do_cls
  
  
  jr do_write

do_esc:
  jp main_menu
  
do_cls:  
  call clear_message_lines  
do_home:
  ld h,1
  ld l,22
  call POSIT
  call KILBUF
  jr no_write
  
do_return:  
  ld a,($F3DC)
  cp 24
  jr z, must_send_message
  ld a, $0D
  call CHPUT
  ld a,$1F
  call CHPUT
  jr no_write
  
do_up:
  ld a,($F3DC)
  cp 23
  jr c, no_write
  ld a,$1E
  call CHPUT
  jr no_write

do_left:     
  ld a,($F3DC)
  cp 22
  jr z, checkx 
  ld a,$1D
  call CHPUT
  jr no_write
checkx:
  ld a,($F3DD)
  cp 1
  jr z, no_write
  ld a,$1D
  call CHPUT
  jr no_write

do_backspace:   
  ld a,8
  call CHPUT
  ld a,($F3DC)
  cp 21
  jr nz,backsp_s
  ld a,$0D
  call CHPUT
  ld a,$1F
  jr do_write
backsp_s
  ld a,32
  call CHPUT  
  ld a,$08
  call CHPUT
  jr no_write
  
do_write:    
  ; check if the cursor is within boundries
  ld d,a
  ld a,($F3DC)
  cp 24
  jr z, checkx2 
  jr do_write2  
checkx2  
  ld a,($F3DD)  
  cp 32
  jr z, no_write
do_write2
  ld a,d
  call CHPUT
no_write:
  call KILBUF
  ret
  
must_send_message:
  jr no_write
;--------------------------------------------------------
; Restore the character under the cursor 
;--------------------------------------------------------
restore_cursor:
  push AF   
  ld a,($F3DC)
  dec a
  ld b,a  
  ld a,($F3DD)
  dec a
  ld c,a
  ld HL,CharUnderCursor+2
  call putstr
  pop AF
  ret
;--------------------------------------------------------
; create the cursor
; invert the character under the cursor
; and store that as the new cursor as character $ff
; input: CharUnderCursor
;--------------------------------------------------------
create_cursor:     
    ld HL,CharUnderCursor    
    ld a,(HL)  
    cp $ff    ; is it the cursor character?
    ret z     ; if yes, return!
    inc HL        
    inc HL
    ld (HL),a ; the character is now at CharUnderCursor[2]
    
ReverseChar:    
    ld HL,CharUnderCursor        
    ld a,(HL) 
    ; Source address in VRAM = A * 8
    ld l,a
    ld h,0
    
    add hl,hl   ; *2
    add hl,hl   ; *4
    add hl,hl   ; *8

CopyInvertChar:
    ld de,$07F8         ; destination, start from bottom byte
    ld b,8              ; loop counter (8 bytes)

.loop:
    push bc             ; save loop counter
    call $004A          ; RDVRM: A = (HL)
    cpl                 ; invert byte
    inc HL
    push hl             ; save HL
    ld HL,DE            ; HL = destination
    call $004D          ; WRTVRM: (HL)=A
    pop HL              ; restore HL
    inc de              ; move destination forwards
    pop bc              ; restore loop counter
    djnz .loop
    ret
    
;--------------------------------------------------------
; Draw a cursor 
;--------------------------------------------------------

draw_cursor: 
  call GetCharUnderCursor  ; character is stored in CharUnderCursor
  call create_cursor
  
;  ld b,0
;  ld c,0
;  ld HL,cursorString
;  call putstr
  
  ld a,($F3DC)
  dec a
  ld b,a  
  ld a,($F3DD)
  dec a
  ld c,a
  ld hl,cursorString
  call putstr
  ret

; ------------------------------------
; Get the character under the curor
; Output = CharUnderCursor
; ------------------------------------
GetCharUnderCursor:
    ld HL,CharUnderCursor ; destination buffer
    ld a,($F3DC)
    dec a
    ld b,a  
    ld a,($F3DD)
    dec a
    ld c,a
    ld d,1
    call GETSTR
    ret    
    
;--------------------------------------------------------
; Routine: GETSTR
; Reads D characters from VRAM (row, col) into HL buffer
;
; INPUT:
;   B = row (0..23)
;   C = column (0..31)
;   D = length (1..)
;   HL = destination buffer
;--------------------------------------------------------

GETSTR:
  
    push DE
    push HL             ; save HL (destination pointer)
 
    ; --- calculate VRAM address like in PUTSTR ---
    ld d, 0
    ld e, b    
    sla e : rl d        ; *2
    sla e : rl d        ; *4
    sla e : rl d        ; *8
    sla e : rl d        ; *16
    sla e : rl d        ; *32

    ld a, c             ; add column
    add a, e
    ld e, a
    jr nc, get_no_carry
    inc d
get_no_carry:
    ld hl, $1800
    add hl, de         ; HL = VRAM Address
    call set_vram_addr_read

    pop HL             ; restore HL (dest)
    pop DE
read_loop:
    in a, (VDP_DATA)
    ld (hl), a
    inc hl
    dec d
    jr nz, read_loop
    ld a,0
    ld (hl), a
   ret

;--------------------------------------------------------
; Set VRAM read address (HL = address)
;--------------------------------------------------------
set_vram_addr_read:
    ld a, L
    out (VDP_CTRL), a    
    ld a, H            ; NOTE: bit 6 = 0 -> read mode    
    out (VDP_CTRL), a  ; (no OR 040h like for write)
    ret
    
;-------------------------------------------
; PUTSTR routine
; B = row (0..23)
; C = column (0..31)
; HL = string (zero-terminated)
;-------------------------------------------

putstr:
    di
    push hl             ; save pointer

    ; ---- row*32 ----
    ld d, 0
    ld e, b
    sla e : rl d        ; *2
    sla e : rl d        ; *4
    sla e : rl d        ; *8
    sla e : rl d        ; *16
    sla e : rl d        ; *32

    ld a, c             ; add column
    add a, e
    ld e, a
    jr nc, no_carry
    inc d
no_carry:
    ld hl, 1800h
    add hl, de          ; HL = VRAM address
    ld e, l
    ld d, h             ; DE = final address
    call set_vram_addr_write
    pop hl              ; restore string pointer

.loop:
    ld a, (hl)
    or a
    jr z,exit_putstr
    out (VDP_DATA), a
    inc hl
    jr .loop
exit_putstr:
    ei
    ret

;-------------------------------------------
; Set VRAM write address (DE = address)
;-------------------------------------------
set_vram_addr_write:
    ld a, e
    out (VDP_CTRL), a
    ld a, d
    or 040h             ; write flag
    out (VDP_CTRL), a
    ret

; ---------------------------------------------------------------------
; Start Screen and all it's routines
; ---------------------------------------------------------------------

start_screen:
  ld L,1                     ; row, counting starts at 1
  ld H,1                     ; column, counting starts at 1
  call $00C6                 ; move cusror
  ld h,64
  
bars1:
  ld a,$E0
  call CHPUT
  inc h
  jr nz, bars1  
  call bigText               ; draw the big text
  ld L,18                    ; row, counting starts at 1
  ld H,1                     ; column, counting starts at 1
  call $00C6                 ; move cusror
  ld H,64
bars2:
  ld a,$E1
  call CHPUT
  inc h
  jr nz, bars2
  
stars:
  ld DE,stars_E8
  ld H,$18
E8_loop:  
  ld a,(DE)
  ld l,a
  cp L,$ff  
  jr z, E8_ext
  ld a,$E8
  call $4D  
  inc DE
  jp E8_loop  
E8_ext: 
  ld DE,stars_F0
F0_loop:  
  ld a,(DE)
  ld l,a
  cp L,$ff  
  jr z, F0_ext
  ld a,$F0
  call $4D  
  inc DE
  jp F0_loop
F0_ext:  
  ld DE,stars_E9
  ld H,$1A
E9_loop:  
  ld a,(DE)
  ld l,a
  cp L,$ff  
  jr z, E9_ext
  ld a,$E9
  call $4D  
  inc DE
  jr E9_loop  
E9_ext: 
  ld DE,stars_F1
F1_loop:  
  ld a,(DE)
  ld l,a
  cp L,$ff  
  jr z, F1_ext
  ld a,$F1
  call $4D  
  inc DE
  jp F1_loop  
F1_ext:   
  //ld hl,Song_start
  //call playSong
  
ani:  
  call animate_stars 
  call CHSNS ;
  jr z, ani ; loop until a key is pressed
  ret

bigText:  
  PrintBuffer 7,0,sc_big_text
  PrintBuffer 13,7, sc_madeby   
  ret  
  
; ---------------------------------------------------------------------
; Animation of the stars on the start screen
; ---------------------------------------------------------------------
animate_stars:                          ; animate the stars by shifting the characters
  call shift_lines
  ret

shift_lines:
    ; left lines
    ld hl,$1800
    ld b,6
shift_left_loop:
    call shift_line_L
    ld de,$20
    add hl,de
    djnz shift_left_loop

    ; right lines
    ld hl,$1A20
    ld b,6
shift_right_loop:
    call shift_line_R
    ld de,$20
    add hl,de
    djnz shift_right_loop
    ld a,100                              ; do a delay
    ld (DELAY_VALUE),a
    call delay
    ret 

shift_line_L:
  push bc
  ld DE, TEMPLINE       ; copy the line to templine 
  ld BC,32
  call $59
  ld a,(TEMPLINE)      ; copy the first character to the end of the line
  ld (TEMPLINE+32),a  
  ld BC,32             ; copy the last 32 bytes back, shifted 1 position
  ld DE, HL
  ld HL, TEMPLINE+1 
  call $5C
  pop bc
  ret
  
shift_line_R:
  push bc
  ; copy the line to templine  
  ld DE, TEMPLINE +1 
  ld BC,32
  call $59
  ; copy the last character to the start of the line
  ld a,(TEMPLINE+32)  
  ld (TEMPLINE),a
  ; copy the line back to video ram
  ld BC,32
  ld DE,HL
  ld HL,TEMPLINE 
  call $5C
  pop bc
  ret

; ---------------------------------------------------------------------
; Are we in the matrix?                 ;
; ---------------------------------------------------------------------
are_we_in_the_matrix:                   ;
                                        ; this is to check if a real cartridge is attached
  ld a,0                                ; or if we are running in a simulator
  ld (EMUMODE),a                        ;
  ld a, 245                             ; Load number #245 (to check if the esp32 is connected)
  call sendbyte                         ; write the byte to IO1
                                        ;
                                        ; Send the ROM version to the cartrdige
  ld HL,MLINE_VERSION+11                ;
  ld DE,VERSION                         ;
sendversion                             ;
  ld a,(DE)                             ;
  ld (HL),a
  call sendbyte                         ;
  cp 128                                ;
  jp z, matrix_n                        ;
  inc DE                                ;
  inc HL
  jr sendversion                        ;
matrix_n                                ;
  call getbyte                          ;
  cp 128                                ;
  jp z, matrix_exit                     ;
  ld a,1                                ;
  ld (EMUMODE),a                        ;                                       ;
matrix_exit                             ;
  call delay                            ;
  ret                                   ;
                                        ;
; ---------------------------------------------------------------------
; get the config status, servername and ESP version;
; ---------------------------------------------------------------------
get_status:                             ;
  ld a, (EMUMODE)                       ;
  cp 1                                  ;
  jr nz, gs661                          ;
  ld a,'d'                              ;
  ld (CONFIGSTATUS),a                   ;
  ret                                   ;
gs661                                   ;
  ld b,236                              ;
  call send_start_byte_ff               ; after this call, the RXBUFFER contains:
                                        ; Configured<byte 129>Server<byte 129>SWVersion<byte 128>
  ld DE,RXBUFFER                        ; the first byte is the config value
  ld a,(DE)                             ;
  ld (CONFIGSTATUS),a                   ; 
                                        ; to get the servername we need the splitbuffer routine
  ld a,2                                ; Save the second part (Server name)
  ld HL,SERVERNAME                      ;
  call splitRXbuffer                    ; SPLITBUFFER now contains the servername,128
                                        ;
gs_next                                 ;
  ld a,3                                ; Save the third part (SW Version)
  ld HL,ESPVERSION                      ;
  call splitRXbuffer                    ; SPLITBUFFER now contains the esp version,128
                                        ;
gs_exit                                 ;
  ret                                   ;
; ---------------------------------------------------------------------
; Send a command byte to the cartridge and wait for response;
; command in b                          ;
; ---------------------------------------------------------------------
send_start_byte_ff:                     ;  
  waitRTR
  ld a,b
  out (CARTRIDGE_IO),a                  ; send the byte
  ld DE,RXBUFFER
ff_response_loop:                       ; now wait for the response
  call getbyte                          ; collect a byte into accumulator
  ld (DE),a                             ; put the byte in the RXBUFFER
  cp 128                                ; compare with 128 (end byte)
  jp z, ff_end_buffer                   ; break out of loop if stop byte found
  inc DE                                ; increase pointer to RXBUFFER
  jr ff_response_loop                   ; next round
ff_end_buffer:  
  ret
  
  
; ---------------------------------------------------------------------
; SUB ROUTINE TO SPLIT RXBUFFER         ;
; A = element to keep                   ;
; HL = the destination
; uses: DE,b
; ---------------------------------------------------------------------
splitRXbuffer:                          ;
  ld b,a                                ; RXBUFFER now contains FOR EXAMPLE macaddress[129]regid[129]nickname[129]regstatus[128]
  ld DE, RXBUFFER                       ;
  ld (TEMPW),HL                         ; keep HL safe for later
sb_read                                 ; read a byte from the buffer
  ld a, (DE)                            ; copy that byte to the split buffer
  ld (HL),a                             ; until we find byte 129 or 128
  cp 129                                ;
  jp z, foundEnd                        ;
  cp 128                                ;
  jp z, foundEnd                        ;
  inc DE                                ;
  inc HL                                ;
  jp sb_read                            ;
                                        ;
foundEnd                                ;
  ld a,128                              ;
  ld (HL),a                             ; load 128 (the end byte) into the destination buffer
  dec b                                 ; decrease b. b holds a number that indicates the item we need
  jp z,sb_exit                          ;
  inc DE                                ;  
  ld HL,(TEMPW)                         ; reset the destination buffer HL
  jp sb_read                            ;
                                        ;
sb_exit                                 ;
  ret                                   ;
                                        ;   
 
; ---------------------------------------------------------------------
;  Send a byte to the cartridge         ;
;  byte in A                            ;
; ---------------------------------------------------------------------
sendbyte:                               ;   
  call waitRTR                          ; wait for ready to receive  
  out (CARTRIDGE_IO),a                  ;
  ret                                   ;

;-------------------------------------------
; receive a byte from the cartridge
;-------------------------------------------
getbyte:                                ;
  call waitRTS
  in a,(CARTRIDGE_IO) 
  ret
;-------------------------------------------
; Wait for RTS 
;-------------------------------------------
waitRTS:
  push af
getrts
  in a,$62     ; ask for status RTS (ready to send) 
  and 2
  cp  2
  jr nz, getrts
  pop af
  ret
  
;-------------------------------------------
; Wait for RTR 
;-------------------------------------------
waitRTR:
  push af
getrtr
  in a,$61     ; ask for status RTR (ready to receive) 
  and 1
  cp 1
  jr nz, getrtr
  pop af
  ret                                        
  
; ---------------------------------------------------------------------
; Custom character sets
; ---------------------------------------------------------------------
custom_chars1:
  ld HL,custom_chars
  ld DE,$600
  LD BC,$190 ; (8 * 8 * 6) +16
  CALL $5C
  ld HL,sc_colors
  ld DE,$2000
  LD BC,32
  CALL $5C
  RET

custom_chat_chars:
  
  // copy the character set from VRAM to RAM
  ld HL,$100           ; source: 0x20 * 8
  ld DE, RXBUFFER
  ld bc, 96*8
  call $0059           // block copy vram to ram
  

  // now Space .. ] to vram location $80
  ld HL, RXBUFFER
  ld DE, $400
  ld BC, 62*8
  call $005C
  // now a..z for the yellow character set
  ld HL, RXBUFFER+520
  ld DE, $5f0
  ld BC, 208
  call $005C
  // copy _
  ld HL, RXBUFFER + 504
  ld DE, $05E0
  ld BC,8
  call $005C
  // now again a..z for the red character set
  ld HL, RXBUFFER+520
  ld DE, $06C0
  ld BC, 208
  call $005C
  // space for the red set
  ld HL, RXBUFFER
  ld DE, $790
  ld BC, 8
  call $005C
  // underscore for red set
  ld HL, RXBUFFER + 504
  ld DE, $0798
  ld BC,8
  call $005C
  // , for red set
  ld HL, RXBUFFER + $60
  ld DE, $07B0
  ld BC,8
  call $005C  
  // . for red set
  ld HL, RXBUFFER + $70
  ld DE, $07A8
  ld BC,8
  call $005C    
  // ! for red set
  ld HL, RXBUFFER + 8
  ld DE, $07A0
  ld BC,8
  call $005C    
  // / for red set
  ld HL, RXBUFFER + $78
  ld DE, $07B8
  ld BC,8
  call $005C    
  
  // next the green section
  ld HL,custom_chars  // first 8 bytes from custom_chars is the thick divider line
  ld DE,$7C0        ; dest offset = 0xF8*8
  LD BC,8           ;
  CALL $5C          ;  
  // cursor block at $ff  
  ld HL,cursss
  ld DE,$7F8
  ld BC,8
  CALL $5C          ;
  
  call setcolors_chat
  ret

; ------------------------------------------------------------------
;  SET COLORS
; ------------------------------------------------------------------
setcolors_chat:    
    
    // first  127 characters should be white    
    // next 88 chars should be yellow or orange
    // next 32 characters should be red
    // next 8 should be green
    ld HL,sc_colors_chat
setc:
    ld DE,$2000
    LD BC,32
    CALL $5C
    ret               
    
set_menu_colors:    
    ld HL,sc_colors_menu
    jp setc     
    
; ------------------------------------------------------------------    
    
vramcopy:
set_addr:
    ld a,e
    out (VDP_CTRL),a
    ld a,d
    or 040h           ; write mode
    out (VDP_CTRL),a

copy_loop:
    ld a,(hl)
    out (VDP_DATA),a
    inc hl
    dec bc
    ld a,b
    or c
    jr nz,copy_loop
    ret

 
; ---------------------------------------------------------------------
; Delay Routines                        ;
; ---------------------------------------------------------------------
delay:                                  ;
  ld a,(DELAY_VALUE)                    ;
delay_loop0:                            ;
  ld b,255                              ;
delay_loop1:                            ;
  djnz delay_loop1                      ;
  dec a                                 ;
  jp nz,delay_loop0                     ;
  ret                                   ;
                                        ;
long_delay:                             ;
  ld a,255
  ld (DELAY_VALUE),a
  call delay                            ;
  call delay                            ;
  call delay                            ;
  ret                                   ;

; ---------------------------------------------------------------------  
; SOUND Routines
; ---------------------------------------------------------------------  


playSong:
.nextNote:
    ld e,(hl)         ; get tone period low byte
    inc hl
    ld d,(hl)         ; get tone period high byte
    inc hl    
    ld a,(hl)         ; get duration low
    ld (DELAY_VALUE),a    
    ld a,d
    or e
    jr z,.songEnd     ; if tone=0 => end of song

    push hl           ; save pointer
    ld h,d
    ld l,e
    call PlayTone     ; use your existing playTone!
    pop hl
    inc hl
    inc hl
    jr .nextNote
.songEnd:
    ret

PlayTone:
    ld a,0
    out (PSG_REG),a
    ld a,l
    out (PSG_DAT),a

    ld a,1
    out (PSG_REG),a
    ld a,h
    out (PSG_DAT),a

    ld a,7
    out(PSG_REG),a
    in a,($A2)
    and 0b11000000
    or  0b00111110
    ld b,a
    ld a,7
    out(PSG_REG),a
    ld a,b
    out (PSG_DAT),a
  
    ld a,8
    out (PSG_REG),a
    ld a,12            // volume ( 15 is max )
    out (PSG_DAT),a
        
    call delay
        
    ld a,8            // volume back to zero
    out (PSG_REG),a
    xor a
    out (PSG_DAT),a
    ret  

   
; -----------------------------------------------------------------------
; For debugging, display the character set
; -----------------------------------------------------------------------
display_character_set:
    ; --- Fill name table starting at VRAM $1800 ---
    ld   hl,32          ; First character
    ld   de,$1800       ; Name table base address
    ld   bc,224         ; 224 characters (32..255)

write_loop:
    push bc
    push hl
    push de

    ; Write HL low byte to VRAM at DE
    ld   a,e
    out  ($99),a        ; Set VRAM address low
    ld   a,d
    and  3Fh
    or   40h            ; bit 6=1 => write
    out  ($99),a

    ld   a,l            ; Character code
    out  ($98),a        ; Write to VRAM

    pop  de
    inc  de
    pop  hl
    inc  hl
    pop  bc
    dec  bc
    ld   a,b
    or   c
    jr   nz,write_loop
    ret



; -----------------------------------------------------------------------
Song_new_msg:  dw  T_A#5,40,T_C5,40,T_D#5,40,T_F#5,40,T_A#5,40,0,0 

Song_start: dw T_F3,100,T_C4,100,T_B4,100,T_A4,100,T_G5,115,T_D5,100,0,0 

Song_start2:
    dw T_C5, 20, T_E5, 20, T_G5, 40, T_C6, 40
    dw T_G5, 20, T_E5, 20, T_C5, 40, T_G5, 40
    dw T_A5, 20, T_F5, 20, T_D5, 40, T_A5, 40
    dw T_G5, 20, T_C6, 20, T_G5, 40, T_E5, 40
    dw T_C6, 20, T_G5, 20, T_E5, 40, T_C6, 40
    dw T_D6, 20, T_A5, 20, T_F5, 40, T_D6, 40
    dw T_E6, 20, T_C6, 20, T_A5, 40, T_E6, 40
    dw T_C6, 40, T_E6, 40, T_G6, 80, T_C7, 80
    dw T_G6, 80, T_C7, 70, T_G6, 60, T_C7, 50
    dw T_G6, 40, T_C7, 30, T_G6, 10, T_C7, 20
    dw T_G6, 30, T_C7, 40, T_G6, 20, T_C7, 20
    ; end marker
    dw 0,0
      
; ---------------------------------------------------------------------  
; ---------------------------------------------------------------------  
; ---------------------------------------------------------------------  
stars_F0: db $2A,$54,$9D,$82,$FF
stars_F1: db $42,$87,$B1,$7A,$FF
stars_E9: db $22,$62,$41,$43,$67,$86,$88,$A7,$91,$D1,$B2,$B0,$7B,$79,$5A,$9A,$FF
stars_E8: db $0A,$29,$2B,$4A,$34,$53,$55,$74,$7D,$BD,$9C,$9E,$81,$83,$62,$A2,$FF
message: db 'Hello World 232!',255

cursss: defs 8,255

custom_chars:                               ; these are only used in the start screen
  DB 0,0,0,255,255,0,0,0                    ; Stripe C0
  DB 3, 15, 12, 24, 24, 24, 24, 24          ; boogje links boven C1
  DB 192, 240, 48, 24, 24, 24, 24, 24       ; boogje rechts boven C2
  DB 24, 24, 24, 24, 24, 12, 15, 3          ; boogle links onder  C3
  DB 24, 24, 24, 24, 24, 48, 240, 192       ; boogje rechts onder C4
  DB 24, 24, 24, 24, 24, 24, 24, 24         ; recht opstaande streep C5
  DB 255, 255, 24, 24, 24, 24, 24, 24       ; T stuk C6
  DB 24, 24, 24, 31, 31, 24, 24, 24         ; T stuk rechtsaf C7

  DB 24, 24, 24, 248, 248, 24, 24, 24       ; T stuk linksaf C8
  DB 255, 255, 0, 0, 0, 0, 0, 0             ; dikke lijn bovenin C9
  DB 0, 0, 0, 192, 240, 48, 24, 24          ; boogje mid rechts boven CA
  DB 24, 24, 12, 15, 3, 0, 0, 0             ; boogje mid links onder CB
  DB 0, 0, 0, 0, 0, 0, 255, 255             ; Dikke streep onder CC
  DB 255,255,255,255,0,0,0,0                ; Extra bold line top CD
  DB 0,0,0,0,255,255,255,255                ; Extra bold line bottom CE 
  db 0,0,0,0,0,0,0,0 ; vulling CF

  
  DB 24, 24, 24, 24, 24, 24, 24, 24         ; recht opstaande streep  D0
  DB 24, 24, 24, 31, 31, 24, 24, 24         ; T stuk rechtsaf  D1
  DB 24, 24, 24, 248, 248, 24, 24, 24       ; T stuk linksaf  D2
  DB 192, 240, 48, 24, 24, 24, 24, 24       ; boogje rechts boven D3 
  DB 255, 255, 0, 0, 0, 0, 0, 0             ; dikke lijn bovenin  D4
  DB 0,0,0,255,255,0,0,0                    ; Stripe D5
  DB 0, 0, 0, 192, 240, 48, 24, 24          ; boogje mid rechts boven D6
  DB 24, 24, 12, 15, 3, 0, 0, 0             ; boogje mid links onder D7
  
  DB 24, 24, 24, 24, 24, 24, 24, 24         ; recht opstaande streep  D8
  DB 24, 24, 24, 24, 24, 12, 15, 3          ; boogle links onder  D9
  DB 24, 24, 24, 248, 248, 24, 24, 24       ; T stuk linksaf  DA
  DB 192, 240, 48, 24, 24, 24, 24, 24       ; boogje rechts boven DB 
  DB 255, 255, 0, 0, 0, 0, 0, 0             ; dikke lijn bovenin  DC
  DB 24, 24, 24, 24, 24, 48, 240, 192       ; boogje rechts onder DD
  DB 0, 0, 0, 0, 0, 0, 255, 255             ; Dikke streep onder DE
  DB 24, 24, 12, 15, 3, 0, 0, 0             ; boogje mid links onder DF
  
  DB 255,255,255,255,0,0,0,0                ; Extra bold line top E0
  DB 0,0,0,0,255,255,255,255                ; Extra bold line bottom E1 
  DB 255,255,255,255,0,0,0,0                ; Extra bold line top E2
  DB 0,0,0,0,255,255,255,255                ; Extra bold line bottom E3 
  DB 255,255,255,255,0,0,0,0                ; Extra bold line top E4
  DB 0,0,0,0,255,255,255,255                ; Extra bold line bottom E5 
  DB 255,255,255,255,0,0,0,0                ; Extra bold line top E6
  DB 0,0,0,0,255,255,255,255                ; Extra bold line bottom E7 
  ; for stars
  DB 255,255,255,255,0,0,0,0                ; Extra bold line top E8
  DB 0,0,0,0,255,255,255,255                ; Extra bold line bottom E9 
  DB 255,255,255,255,0,0,0,0                ; Extra bold line top EA
  DB 0,0,0,0,255,255,255,255                ; Extra bold line bottom EB 
  DB 255,255,255,255,0,0,0,0                ; Extra bold line top EC
  DB 0,0,0,0,255,255,255,255                ; Extra bold line bottom ED 
  DB 255,255,255,255,0,0,0,0                ; Extra bold line top EE
  DB 0,0,0,0,255,255,255,255                ; Extra bold line bottom F0 
  ; for stars
  DB 255,255,255,255,0,0,0,0                ; Extra bold line top F1
  DB 0,0,0,0,255,255,255,255                ; Extra bold line bottom F2 

sc_big_text:        
  DB 32,32,32,32,$C1,$C9,$C9,$C2,$C5,$20,$20,$C5,$C1,$C9,$C9,$C2,$C9,$C6,$C9,$20,$C1,$C9,$C9,$C2,$C5,32,32,32,32,32,32,32
  DB 32,32,32,32,$C5,32,32,32,$C5,32,32,$C5,$C5,32,32,$C5,32,$C5,32,32,$C5,32,32,32,$C5,32,32,$C5,32,32,32,32
  DB 32,32,32,32,$D0,32,32,32,$D1,$D5,$D5,$D2,$D1,$D5,$D5,$D2,32,$D0,32,32,$D1,$D5,$D5,$D6,$D7,$D5,$D5,$D2,32,32,32,32
  DB 32,32,32,32,$D8,32,32,32,$D8,32,32,$D8,$D8,32,32,$D8,32,$D8,32,32,$D8,32,32,$D8,32,32,32,$D8,32,32,32,32
  DB 32,32,32,32,$D9,$DE,$DE,$DD,$D8,$20,$20,$D8,$D8,$20,$20,$D8,$20,$D8,32,32,$D9,$DE,$DE,$DD,32,32,32,$D8,0
  

sc_madeby:
  db 'for the MSX system': defs 42,32 : db 'Made by Bart & Theo in 2025',0
sc_colors:
  db 240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,224,80,80,208,160,224,160,128,224
sc_colors_chat:
    defs 16,0F0h     ; 16 bytes: white on black
    defs 11,00Ah     ; 11 bytes: yellow on black
    defs  4,009h     ; 4 bytes: black on red
    defs  1,020h     ; 1 byte:  green on black
sc_colors_menu:
    defs 16,0F0h     ; 16 bytes: white on black
    defs 11,50h     ; 11 bytes: yellow on black
    defs  4,009h     ; 4 bytes: black on red
    defs  1,020h     ; 1 byte:  green on black

VERSION:       DB '2.01',128
MLINE_GREEN:   defs 32,$F8 : DB 0 
MLINE_MAIN1:   DB '[F1]  WiFi Setup',0
MLINE_MAIN2:   DB '[F2]  Account Setup',0
MLINE_MAIN3:   DB '[F3]  Server Setup',0
MLINE_MAIN4:   DB '[F4]  User List',0
MLINE_MAIN5:   DB '[F5]  Help',0
MLINE_MAIN6:   DB '[F6]  About this software',0
MLINE_MAIN7:   DB '[ESC] Exit',0
MLINE_SAVE:    DB '[F1]  Save Settings  ',0
MLINE_RESET:   DB '[F6]  Reset Cartridge',0
MLINE_VERSION: DB 'Version ROM    , ESP3.80 '
VERSION_DATE:  DB '08/2025',0
MLINE_OFFSET:  DB 'Time offset from GMT:',0
MLINE_SSID:    DB 'SSID:',0
MLINE_PASSW:   DB 'Password:',0
MLINE_MAC:      DB 'MAC Address:',0
MLINE_REGID:    DB 'Reg ID:',0
MLINE_NICKNAME: DB 'Nick Name:',0
MLINE_SERVER:   DB 'Server:',0
MLINE_SERVER2:  DB 'Example: www.chat64.nl',0
MLINE_ANY_KEY:  DB 'Press any key',0
MLINE_NEXT_PAGE:DB '[f]first    [ESC]exit    [n]next',0
no_users:       DB 'Sync has not run yet,           '
                DB 'sync happens during chat',0
NO_CART_FOUND:  DB 'Cartridge not found!',0                

reset_warning:  DB 'This will reset your cartridge  to factory defaults.            ' 
                defs 32,32                
                DB 'You will need to go through the setup and registration process  again' 
                defs 64,32
                DB 'ARE YOU SURE?  (Y/N)',0                  

about_text: DB 'Initially developed by Bart as a'
            DB 'proof of concept on Commodore 64' 
            DB 'A new version of CHAT64 is now  '
            DB 'available to everyone.          '
            DB '                                '
            DB 'We proudly bring you Chat64 on  '  
            DB 'the MSX System!                 '
            DB 'Made by Bart Venneker and Theo  '
            DB 'van den Belt in 2025            '
            DB '                                '
            DB 'Hardware, software and manuals  '
            DB 'are available on Github         '
            DB 'github.com/bvenneker/Chat64-MSX ',0

help_private: DB 'Switch to private message screen'
              DB 'by pressing F5                  '
              DB '                                '
              DB 'To send a private message to    '
              DB 'someone, type ', 96+'@',210,208,194,207,203,190,202,194, ' at the  '
              DB 'start of your message           ',0

help_eliza: DB 'Try our A.I. Chat Bot Eliza!    '
            DB '                                '
            DB 'Switch to private messaging and '
            DB 'start your message with ' ,96+'@',165,201,198,215,190,'  '
            DB '                                '
            DB 'Eliza is a true A.I. chatbot    '
            DB 'that uses natural language      '
            DB 'processing to create humanlike  ' 
            DB 'dialogue                        '
            DB 'Try it! its a lot of fun!       ',0

help_user_list:
            DB 'To see who else is online and   '
            DB 'available to chat, press F3 from'
            DB 'the chat window                 '            
            DB '                                '
            DB 'Online users will show up green '
            DB 'in the list                     ',0

help_scrolling:            
            DB 'Missed a few messages?          '
            DB 'You can scroll up and down by   '
            DB 'pressing CTRL-u and CTRL-d      ',0          
                            
// TEXT in blue:    
text_main_menu: db 0ADh,0A1h,0A9h,0AEh,080h,0ADh,0A5h,0AEh,0B5h,0 // main_menu    
text_wifi_menu: db 0B7h,0C6h,0A6h,0C6h,080h,0ADh,0A5h,0AEh,0B5h,0  
text_server_menu: db 0B3h,0A5h,0B2h,0B6h,0A5h,0B2h,080h,0B3h,0A5h,0B4h,0B5h,0B0h,0
text_account_menu: db 0A1h,0A3h,0A3h,0AFh,0B5h,0AEh,0B4h,080h,0B3h,0A5h,0B4h,0B5h,0B0h,0
text_user_list: db 0B5h,0B3h,0A5h,0B2h,080h,0ACh,0A9h,0B3h,0B4h,0
text_about_menu: db 0A1h,0A2h,0AFh,0B5h,0B4h,080h,0A3h,0A8h,0A1h,0B4h,096h,094h,0
text_help_screen1: db 176,207,198,211,190,209,194,32,163,197,190,209,32,173,194,208,208,190,196,194,208,0
text_help_screen2: db 163,197,190,209,32,212,198,209,197,32,165,201,198,215,190,0
text_help_screen3: db 179,194,194,32,212,197,204,32,198,208,32,204,203,201,198,203,194,0
text_help_screen4: db 179,192,207,204,201,201,198,203,196,0
text_reset_screen: db 'R'+96,165,179,165,180,128,180,175,128,166,161,163,180,175,178,185,128,164,165,166,161,181,172,180,0 
SERVERNAME:      DB "www.chat64.nl",128 
                 DB "                                ",128

end_of_code: db 'END OF CODE.   EOC    EOC '
  
TEMPLINE: db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
RXINDEX: db 0
RXFULL: db 0
DELAY_VALUE: db 0    
EMUMODE: db 0  
CONFIGSTATUS: db 0
tone_idx:  db 0
tone_freq: dw 0  
SPLITBUFFER: defs 42,0
TEMPB_H : db 0
TEMPB_L : db 0
TEMPW   : db 0,0
ESPVERSION: db "9.99",0
RXBUFFER: defs 300,0
TXBUFFER: defs 300,0
SCREEN_PRIV_BACKUP: defs 300,0 // aanpassen!
FIELDLEN: db 0
TextFieldBuffer: defs 40,0
Field1Buffer: defs 25,0
Field2Buffer: defs 25,0
Field3Buffer: defs 25,0
CursorAddr: dw 0
; CharUnderCursor = 
; [0] = the character currently under the cursor
; [1] = the previous
CharUnderCursor: db 255,0,0,0
cursorString: db $ff,0
 
; --- BIOS routine ---
CHPUT      equ $00A2
CLS        equ $00C3
FORCLR     equ $f3e9
VRAMCOPY   equ $0059 
CHSNS      equ $009C          
CHGET      equ $009F
KILBUF     equ $0156   ; clear keyboard type ahead buffer
POSIT      equ $00C6
CSRX       equ $F3DD
CSRY       equ $F3DC
BACKSPACE  equ $08
KEYS       equ $FBE5
; --- Music Notes ---
T_C0  equ 12288   ; 0
T_C#0 equ 11507   ; 1
T_D0  equ 10880   ; 2
T_D#0 equ 10272   ; 3
T_E0  equ 9720    ; 4
T_F0  equ 9150    ; 5
T_F#0 equ 8630    ; 6
T_G0  equ 8160    ; 7
T_G#0 equ 7705    ; 8
T_A0  equ 7280    ; 9
T_A#0 equ 6860    ; 10
T_B0  equ 6480    ; 11
T_C1  equ 6080    ; 12
T_C#1 equ 5740    ; 13
T_D1  equ 5400    ; 14
T_D#1 equ 5100    ; 15
T_E1  equ 4820    ; 16
T_F1  equ 4550    ; 17
T_F#1 equ 4300    ; 18
T_G1  equ 4050    ; 19
T_G#1 equ 3830    ; 20
T_A1  equ 3610    ; 21
T_A#1 equ 3410    ; 22
T_B1  equ 3220    ; 23
T_C2  equ 3040    ; 24
T_C#2 equ 2870    ; 25
T_D2  equ 2700    ; 26
T_D#2 equ 2550    ; 27
T_E2  equ 2410    ; 28
T_F2  equ 2280    ; 29
T_F#2 equ 2150    ; 30
T_G2  equ 2020    ; 31
T_G#2 equ 1910    ; 32
T_A2  equ 1805    ; 33
T_A#2 equ 1705    ; 34
T_B2  equ 1610    ; 35
T_C3  equ 1520    ; 36
T_C#3 equ 1435    ; 37
T_D3  equ 1350    ; 38
T_D#3 equ 1275    ; 39
T_E3  equ 1205    ; 40
T_F3  equ 1140    ; 41
T_F#3 equ 1075    ; 42
T_G3  equ 1010    ; 43
T_G#3 equ 955     ; 44
T_A3  equ 903     ; 45
T_A#3 equ 852     ; 46
T_B3  equ 805     ; 47
T_C4  equ 761     ; 48
T_C#4 equ 718     ; 49
T_D4  equ 675     ; 50
T_D#4 equ 638     ; 51
T_E4  equ 603     ; 52
T_F4  equ 570     ; 53
T_F#4 equ 538     ; 54
T_G4  equ 507     ; 55
T_G#4 equ 478     ; 56
T_A4  equ 452     ; 57
T_A#4 equ 426     ; 58
T_B4  equ 403     ; 59
T_C5  equ 381     ; 60
T_C#5 equ 359     ; 61
T_D5  equ 338     ; 62
T_D#5 equ 319     ; 63
T_E5  equ 302     ; 64
T_F5  equ 285     ; 65
T_F#5 equ 269     ; 66
T_G5  equ 254     ; 67
T_G#5 equ 239     ; 68
T_A5  equ 226     ; 69
T_A#5 equ 213     ; 70
T_B5  equ 201     ; 71
T_C6  equ 190     ; 72
T_C#6 equ 179     ; 73
T_D6  equ 169     ; 74
T_D#6 equ 159     ; 75
T_E6  equ 151     ; 76
T_F6  equ 143     ; 77
T_F#6 equ 135     ; 78
T_G6  equ 127     ; 79
T_G#6 equ 120     ; 80
T_A6  equ 113     ; 81
T_A#6 equ 107     ; 82
T_B6  equ 101     ; 83
T_C7  equ 95      ; 84
T_C#7 equ 89      ; 85
T_D7  equ 84      ; 86
T_D#7 equ 79      ; 87
T_E7  equ 76      ; 88
T_F7  equ 71      ; 89
T_F#7 equ 67      ; 90
T_G7  equ 63      ; 91
T_G#7 equ 60      ; 92
T_A7  equ 57      ; 93
T_A#7 equ 53      ; 94
T_B7  equ 51      ; 95
T_C8  equ 47      ; 96
T_C#8 equ 44      ; 97
T_D8  equ 42      ; 98
T_D#8 equ 39      ; 99
T_E8  equ 38      ; 100
T_F8  equ 36      ; 101
T_F#8 equ 34      ; 102
T_G8  equ 32      ; 103
T_G#8 equ 30      ; 104
T_A8  equ 28      ; 105
T_A#8 equ 27      ; 106
T_B8  equ 25      ; 107
T_C9  equ 23      ; 108
T_C#9 equ 22      ; 109
T_D9  equ 21      ; 110
T_D#9 equ 19      ; 111
T_E9  equ 19      ; 112
T_F9  equ 18      ; 113
T_F#9 equ 17      ; 114
T_G9  equ 16      ; 115
T_G#9 equ 15      ; 116
T_A9  equ 14      ; 117
T_A#9 equ 13      ; 118
T_B9  equ 13      ; 119
