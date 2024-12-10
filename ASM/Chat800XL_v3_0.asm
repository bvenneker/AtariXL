// special characters: https://www.youtube.com/watch?v=fOrMwNBoC7E&list=PLmzSn5Wy9uF8nTsZBtdk1yHzFI5JXoUJT&index=7

// https://www.atarimax.com/jindroush.atari.org/acarts.html
// https://atariwiki.org/wiki/Wiki.jsp?page=CartridgesexitVersions
// https://grandideastudio.com/media/pp_atari8bit_instructions.pdf
// https://grandideastudio.com/media/pp_atari8bit_schematic.pdf

// TODO LIST  
; first setup menus
; timeout when receiving
; timeout when sending
// Auto updates!
// Aantal prive berichten doorgeven
// keep last PM user on screen after sending message
// Bij onbekende user, bericht herstellen
// Kleur veranderen!

// escape moet exit menu zijn, altijd
// Shift Clear, Control clear
// Caps key geeft rare tekens (ook met shift en contrl)
// Invert key geeft rare tekens
// ESC key stuurt cursor omhoog!
// TAB key geeft rare tekens
// shift insert moet ook gewoon > geven
// Return op onderste regel moet bericht verzenden
// Control 7 geeft raar karakter
; Control 1 = pause screen output. Kunnen we dat uitzetten? 
// Control return geeft L (moet onmiddelijk verzenden)
// 
// labels camelCase
// variables ALLCAPS

putchar_ptr = $346    ; pointer to print routine

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
CHARSET   = $2F4
ROM_CHARS = $E000 
POKEY     = $D200
 
COLOR2 = $2c6
COLOR4 = $2c8

TEXTBOX = $15        // input field address $15 + $16
TEMP_I = $17 
TEMP_O = $19
TEXTBOXLEN = $1A    // length of the input field
CHARINDEX = $3f 
TEXTPOINTER = $40      // $40, $41 are a pointer. 
TEXTLEN = $83
ROWCRS = $54          ; cursor row 
COLCRS = $55          ; cursor colm
MESSAGEFIELD = $43      ; 43 and 44 hold a pointer to the main input field 
 
SLITINDEX = $46


CURSORINH = $2F0            ; cursor inhibit, cursor is invisible if value is not zero
SCREENMEMORYPOINTER = $58          ; zero page pointer to screen memory


  org $2000           ; program starts at $2000

init
  mva #0 $52             ; set left margin to zero
  lda SCREENMEMORYPOINTER             ; load the lowbyte of the pointer for screen memory
  adc #72                ; add 72
  sta MESSAGEFIELD         ; store in $43 
  lda SCREENMEMORYPOINTER+1           ; load the high byte
  adc #3                 ; add 3
  sta MESSAGEFIELD+1       ; store in $44.
  lda #0
  sta CHARINDEX  
  sta inhsend 
  sta doswitch
  sta restoreMessageLines
  sta MENU_ID
  sta SCREEN_ID
  lda SCREENMEMORYPOINTER
  sta TEXTBOX
  lda SCREENMEMORYPOINTER+1
  sta TEXTBOX+1

  
main   
  jsr are_we_in_the_matrix
  jsr startScreen  
  jsr hide_cursor
  jsr calculate_screen_addresses
  jsr clear_keyboard_and_screen
  
  jsr get_status 
  jmp main_chat_screen

// ----------------------------------------------------------------------
// Print the last used pmuser on screen to start your private message
// ----------------------------------------------------------------------
print_pm_user:
  lda SCREEN_ID
  cmp #3
  beq print_pm_continue 
  rts
print_pm_continue
  mwa MESSAGEFIELD TEMP_I
  dec TEMP_I
  ldy #0
  sty COLCRS
  lda #28                   // move the cursor out of the way
  jsr write_text             //
ploop
  lda PMUSER,y
  cmp #128
  beq exit_print_pm
  sta (TEMP_I),y
  iny
  inc COLCRS
  jmp ploop
  
exit_print_pm    
  lda #29                   // down one line
  jsr write_text             //    
  lda #32 // write the @ sign again (work around a bug)
  ldy #0
  sta (TEMP_I),y
  lda #32
  jsr write_text
  rts

// ----------------------------------------------------------------------
// toggle between private and public messaging
// ----------------------------------------------------------------------
toggle_screens:  
  jsr backup_screen                // make a backup of the current screen
  jsr sound_zipp
  lda SCREEN_ID
  cmp #3
  bne private_chat_screen
  jmp main_chat_screen

// ----------------------------------------------------------------------
// PRIVATE MESSAGING SCREEN
// ----------------------------------------------------------------------
private_chat_screen:
  mva #3 SCREEN_ID
  jmp restore_screen
  
p_chat
  jsr clear_keyboard_and_screen
  displayText DIVIDER_LINE, #0,#0    ; draw the divider line
  displayText TEXT_F5_TOGGLE, #1,#0    ; draw the menu title
  displayText DIVIDER_LINE, #2,#0    ; draw the divider line
  jmp chat_screen
 
  
// ----------------------------------------------------------------------
// PUBLIC MESSAGING SCREEN
// ----------------------------------------------------------------------
main_chat_screen:  
  mva #0 SCREEN_ID
  jmp restore_screen
m_chat
  jsr clear_keyboard_and_screen
chat_screen
  
  lda VICEMODE
  cmp #1  
  bne mc_not_vice
  lda #4
  sta COLOR4
  sta COLOR2
  jsr error_sound
  
  displayText TEXT_NO_CARTRIDGE, #5,#6
  
  
mc_not_vice

  mva #255 $2fc                       ; clear keyboard buffer
  mva #0 COLCRS                       ; set cursor row position to zero  
  displayText DIVIDER_LINE, #20,#0    ; draw the divider line

  jsr clear_input_lines
  
chat_key_input
  jsr hide_cursor
  jsr restore_message_lines  
  jsr show_cursor
  jsr print_pm_user
  jmp text_input    // jump to the text input routine



// ----------------------------------------------------------------------
// shift screen up
// ----------------------------------------------------------------------
shift_screen_up:   
  lda SCREEN_ID            // see on what screen we are
  cmp #3                   // in private screen, we must ignore the first 3 lines
  bne shift_public 
  ldx #16
  mwa SCREENMEMORYPOINTER TEMP_I        // TEMP_I points to line 0  
  mwa SCREENMEMORYPOINTER TEMP_O
  lda TEMP_I
  adc #120
  sta TEMP_I               // TEMP_I now points to line 3
  lda TEMP_O
  adc #160
  sta TEMP_O               // TEMP_O points to line 4
  jmp sh_up_d              // start shifting! 
  
shift_public    
  ldx #19                  // in public chat we shift from line 0
  mwa SCREENMEMORYPOINTER TEMP_I        // TEMP_I points to line 0
  mwa SCREENMEMORYPOINTER TEMP_O
shift_loop
  clc
  lda TEMP_O               //
  adc #40                  // add 40 to go to the next line
  sta TEMP_O               // TEXTPOINTER points to line 1
  bcs up_hb                // we there was an overflow, increase the highbyte also
  jmp sh_up_d
up_hb
  inc TEMP_O+1             // increase highbyte
sh_up_d   
  jsr shift_line
  mwa TEMP_O TEMP_I
  dex    
  bne shift_loop
  mwa STARTLINE1 TEMP_I    // clear the last line
  ldy #39
  lda #0  
line_clear_loop    
  sta (TEMP_I),y
  dey
  bne line_clear_loop

  rts


shift_line:             // this routine shifts one line up
  ldy #0               // TEMP_O is source
shift_line_loop         // TEMP_I is destination
  lda (TEMP_O),y  
  sta (TEMP_I),y
  iny
  cpy #40
  bne shift_line_loop
  rts

// ----------------------------------------------------------------------
// backup and restore screens
// ----------------------------------------------------------------------
backup_screen:
  mva ROWCRS TEMPBYTE
  jsr move_cursor_out_of_the_way
  lda MENU_ID
  cmp #0
  beq bs_c
  rts
bs_c  
  lda SCREEN_ID
  cmp #3
  beq backup_priv_screen
  jmp backup_publ_screen
  rts

backup_priv_screen
  mva COLCRS p_cursor_x
  mva TEMPBYTE p_cursor_y
  mva #1 HAVE_P_BACKUP
  mva #<SCREEN_PRIV_BACKUP TEMP_I
  mva #>SCREEN_PRIV_BACKUP TEMP_I+1
  jsr backup_the_screen 
  rts
  
backup_publ_screen
  mva COLCRS MCURSORX
  mva TEMPBYTE MCURSORY
  mva #1 HAVE_M_BACKUP  
  mva #<SCREEN_PUBL_BACKUP TEMP_I
  mva #>SCREEN_PUBL_BACKUP TEMP_I+1
  jsr backup_the_screen 
  rts
  
backup_the_screen
  mwa SCREENMEMORYPOINTER TEXTPOINTER    
  ldy #0  
backup_loop1
  lda (TEXTPOINTER),y
  sta (TEMP_I),y
  iny
  cpy #0
  bne backup_loop1
   
  inc TEXTPOINTER+1
  inc TEMP_I+1
backup_loop2
  lda (TEXTPOINTER),y
  sta (TEMP_I),y
  iny
  cpy #0
  bne backup_loop2
  
  inc TEXTPOINTER+1
  inc TEMP_I+1
backup_loop3
  lda (TEXTPOINTER),y
  sta (TEMP_I),y
  iny
  cpy #0
  bne backup_loop3
  
  inc TEXTPOINTER+1
  inc TEMP_I+1
backup_loop4
  lda (TEXTPOINTER),y
  sta (TEMP_I),y
  iny
  cpy #192
  bne backup_loop4
  rts
  
  
restore_screen:
  lda SCREEN_ID
  cmp #3
  beq restore_priv_screen
  jmp restore_publ_screen  
  
restore_priv_screen
  lda HAVE_P_BACKUP
  cmp #1
  beq do_p_restore
//  mva p_cursor_x COLCRS    // restore the cursor position
//  mva p_cursor_y ROWCRS    // restore the cursor position  
  jmp p_chat
do_p_restore
  mva #<SCREEN_PRIV_BACKUP TEMP_I
  mva #>SCREEN_PRIV_BACKUP TEMP_I+1
  jsr restore_the_screen 
  mva p_cursor_x COLCRS    // restore the cursor position
  mva p_cursor_y ROWCRS    // restore the cursor position  
  jmp chat_key_input
  
restore_publ_screen
  lda HAVE_M_BACKUP
  cmp #1
  beq do_m_restore
  jmp m_chat
do_m_restore
  mva #<SCREEN_PUBL_BACKUP TEMP_I
  mva #>SCREEN_PUBL_BACKUP TEMP_I+1
  jsr restore_the_screen 
  mva MCURSORX COLCRS   // restore the cursor position
  mva MCURSORY ROWCRS   // restore the cursor position
  
  jmp chat_key_input

restore_the_screen
  mwa SCREENMEMORYPOINTER TEXTPOINTER
  ldy #0  
restore_loop1
  lda (TEMP_I),y
  sta (TEXTPOINTER),y
  iny
  cpy #0
  bne restore_loop1
  
  inc TEXTPOINTER+1
  inc TEMP_I+1
restore_loop2
  lda (TEMP_I),y
  sta (TEXTPOINTER),y
  iny
  cpy #0
  bne restore_loop2

  inc TEXTPOINTER+1
  inc TEMP_I+1
restore_loop3
  lda (TEMP_I),y
  sta (TEXTPOINTER),y
  iny
  cpy #0
  bne restore_loop3

  inc TEXTPOINTER+1
  inc TEMP_I+1
restore_loop4
  lda (TEMP_I),y
  sta (TEXTPOINTER),y
  iny
  cpy #192
  bne restore_loop4
  rts

backup_message:
  jsr move_cursor_out_of_the_way
  ldy #0
  mwa MESSAGEFIELD TEMP_I
  dec TEMP_I
ml_b_loop                   // backup message lines
  lda (TEMP_I),y
  sta MESSAGE_LINES_BACKUP,y
  iny
  cpy #120
  bne ml_b_loop
  rts
  
move_cursor_out_of_the_way:
crs_up
  lda #28
  jsr write_text
  lda ROWCRS
  cmp #20  
  bne crs_up
  jsr hide_cursor
  rts
  
restore_message_lines:
  lda SCREEN_ID
  cmp #3
  bne rml_exit
  lda restoreMessageLines
  cmp #1
  bne rml_exit
  jsr move_cursor_out_of_the_way
  ldy #0
  mwa MESSAGEFIELD TEMP_I
  dec TEMP_I
rms_loop  
  lda MESSAGE_LINES_BACKUP,y
  sta (TEMP_I),y  
  iny
  cpy #120
  bne rms_loop
  lda #0
  sta restoreMessageLines
  jsr sound_zipp
  jsr sound_zipp
  jsr sound_zipp
  lda #29
  jsr write_text
  mva p_cursor_x COLCRS    
  mva p_cursor_y ROWCRS
  
rml_exit
  rts
  
// ----------------------------------------------------------------------
// Get wifi status and fill variable WIFISTATUS
// ----------------------------------------------------------------------
get_wifi_status:
  lda VICEMODE
  cmp #1
  bne get_wifi_status_cont
  rts
get_wifi_status_cont
  lda #248 
  jsr send_start_byte    // the first byte in the RXBUFFER now contains 1 or 0
  lda RXBUFFER              // get the first byte of the RXBUFFER
  sta WIFISTATUS            // store the first byte as WIFISTATUS
  rts
// ----------------------------------------------------------------------
// Get the config status and the ESP Version
// ----------------------------------------------------------------------
get_status: 
  lda VICEMODE
  cmp #1
  beq exit_gs

  lda #236                                      // ask Cartridge for the config status, server name and esp sketch version
  jsr send_start_byte                        // the RXBUFFER now contains Configured<byte 129>Server<byte 129>SWVersion<byte 128>
  
  lda #1                                        // set the variables up for the splitbuffer command
  sta SLITINDEX                                // we need the first element, so store #1 in SLITINDEX
  jsr splitRXbuffer                             // and call spilt buffer
  lda SPLITBUFFER                               // SPLITBUFFER NOW CONTAINS THE CONFIG_STATUS
  sta CONFIG_STATUS                             // this is only one character, store it in config_status   
                                                //
  lda #2                                        // we need the second element out of the rxbuffer   
  sta SLITINDEX                                // so put #2 in SLITINDEX and jump to split buffer   
  jsr splitRXbuffer                             // SPLITBUFFER NOW CONTAINS THE SERVERNAME
                                                // The servername is multiple characters so we need a loop to copy it to                                                  
  ldx #0                                        // the server name variable   
read_server_name                                // start of the loop
  lda SPLITBUFFER,x                             // load a character from the splitbuffer   
  sta SERVERNAME,x                              // store it in the servername variable   
  cmp #32                                       // see if the character was a space character   
  beq fin_server_name                           // if so, jump out of the loop   
  cmp #128                                      // see if the character was byte 128      
  beq fin_server_name                           // if so, jump out of the loop      
  inx                                           // increase x for the next character   
  jmp read_server_name                          // and repeat   
fin_server_name
  lda #128                                      // finish the servername variable with byte 128   
  sta SERVERNAME,x                              //    
  lda #3                                        // now get the third element from the rx buffer    
  sta SLITINDEX                                // so put #3 in SLITINDEX and jump to split buffer    
  jsr splitRXbuffer                             // SPLITBUFFER NOW CONTAINS THE SWVERSION
                                                // The swversion is multiple characters so we need a loop
  ldx #0                                        // to copy the text to the SWVERSION variable   
read_swversion                                  // start of the loop
  lda SPLITBUFFER,x                             // load a character from the splitbuffer    
  sta SWVERSION,x                               // store it in the SWVERSION variable    
  cmp #32                                       // see if the character was a space character    
  beq fin_swversion                             // if so, jump out of the loop   
  cmp #128                                      // see if the character was byte 128   
  beq fin_swversion                             // if so, jump out of the loop   
  inx                                           // increase x for the next character    
  jmp read_swversion                            // and repeat   
fin_swversion
  lda #128                                      //    
  sta SWVERSION,x                               // finish the SWVERSION variable with byte 128 

exit_gs 
  rts 
// ----------------------------------------------------------------------
// Main Menu
// ----------------------------------------------------------------------
main_menu:
  jsr displayUpdateScreen
  mva #10 MENU_ID
  jsr clear_keyboard_and_screen
  displayText DIVIDER_LINE, #0,#0    ; draw the divider line
  displayText text_main_menu, #1,#15    ; draw the menu title
  displayText DIVIDER_LINE, #2,#0    ; draw the divider line
  displayText MLINE_MAIN1, #5,#3
  displayText MLINE_MAIN2, #7,#3
  displayText MLINE_MAIN3, #9,#3
  displayText MLINE_MAIN4, #11,#3
  displayText MLINE_MAIN5, #13,#3
  displayText MLINE_MAIN6, #15,#3
  displayText MLINE_MAIN8, #17,#3
  displayText MLINE_MAIN7, #19,#3
  displayText DIVIDER_LINE, #22,#0    ; draw the divider line
  displayText VERSION_LINE, #23,#0    ; draw the version line
  displayBuffer SWVERSION,#23,#24,#0
  displayBuffer VERSION,#23,#14,#0

main_menu_key_input:
  jsr getKey
  cmp #255
  beq main_menu_key_input
  
  cmp #251                            // Escape is pressed(exit)
  beq exit_main_menu
  
  cmp #$31                            // key 1 is pressed (wifi)
  bne cp_2 
  jmp wifi_setup
cp_2
  cmp #$32                            // key 2 is pressed (server setup)
  bne cp_3
  jmp server_setup
cp_3
  cmp #$33                            // key 3 is pressed (account)
  bne cp_4
  jmp account_setup
cp_4
  cmp #$34                            // key 4 is pressed (user list)
  bne cp_5
  jmp user_list                    
cp_5
  cmp #$35                            // key 5 is pressed (about)
  bne cp_6
  jmp about_screen
cp_6
  cmp #$36                            // key 6 is pressed (help)
  bne cp_c  
  jmp help_screen

cp_c                                  // change color
  cmp #62                            // c
  bne cp_x
  inc COLOR4
  inc COLOR4
  inc COLOR2
  inc COLOR2
  jmp no_match
cp_x
  cmp #60
  bne no_match
  dec COLOR4
  dec COLOR4
  dec COLOR2
  dec COLOR2
  jmp no_match
  
no_match  
  mva #255 $2fc                       // clear keyboard buffer 
  jmp main_menu_key_input
  
exit_main_menu
  lda #0
  sta MENU_ID
  mva #255 $2fc                       // clear keyboard buffer

  jsr sendScreenColor // send the screen color
  jmp restore_screen
  
// ----------------------------------------------------------------------
// Send screen color
// ----------------------------------------------------------------------
sendScreenColor:
  jsr wait_for_RTR
  lda #230
  sta $D502
  jsr wait_for_RTR
  lda COLOR4
  sta $D502
  jsr wait_for_RTR
  rts
  
// ----------------------------------------------------------------------
// Update screen, shown if there is a new firmware version available
// ----------------------------------------------------------------------

displayUpdateScreen:
  lda NEWESP
  cmp #128                   // if newesp version starts with 128
  bne contUpdateScreen       // then there is no new version to show
  rts                        // so return without further action
contUpdateScreen
  mva #19 MENU_ID
  jsr clear_keyboard_and_screen
  displayText DIVIDER_LINE, #0,#0    ; draw the divider line
  displayText TEXT_UPDATE_TITLE, #1,#10    ; draw the menu title
  displayText DIVIDER_LINE, #2,#0    ; draw the divider line
  displayText TEXT_NEW_VERSIONS,#5,#0
  displayText TEXT_NEW_ROM, #8,#2
  displayText TEXT_NEW_ESP, #9,#2
  displayBuffer NEWROM, #8,#11,#0
  displayBuffer NEWESP, #9,#11,#0

  displayText DIVIDER_LINE, #22,#0    ; draw the divider line
  displayText VERSION_LINE, #23,#0    ; draw the version line
  displayBuffer SWVERSION,#23,#24,#0
  displayBuffer VERSION,#23,#14,#0
 
updateScreenKeyInput:
  jsr getKey
  cmp #255
  beq updateScreenKeyInput
  
  cmp #251                            // Escape is pressed(exit)
  beq exitUpdateScreen
  
  cmp #121                            // key y is pressed 
  bne cp_n 
  jmp doUpdate
cp_n
  cmp #110
  bne updateScreenKeyInput 
  lda #128  // key n is pressed
  sta NEWESP
  
exitUpdateScreen
  rts

doUpdate  
  displayText TEXT_INSTALLING, #11,#2
  displayBuffer UPDATEBOX, #13,#2,#0
  
  jsr WAIT_FOR_RTR
  lda #231
  sta $D502
  ldy #0
confirmUpd
  jsr WAIT_FOR_RTR
  lda CONFIRMUPDATE,y
  sta $D502
  iny
  cmp #128
  bne confirmUpd 
  jsr WAIT_FOR_RTR
updt
  lda #100
  sta DELAY
  jsr jdelay
  lda $D502
  cmp #32
  beq updRest
  sta TEMPBYTE
  
pbar    
  lda #160
  jsr write_text
  dec TEMPBYTE
  lda TEMPBYTE  
  cmp #0
  bne pbar
  
  lda #$9b // go to next line
  jsr write_text
  lda #$1c // up
  jsr write_text
  lda #$1f // right
  jsr write_text
  lda #$1f // right
  jsr write_text
  lda #$1f // right
  jsr write_text
  lda #$1f // right
  jsr write_text    
  jmp updt
  rts

updRest  
  displayText UPDATEDONE,#17,#2
  lda #255
  sta DELAY
  jsr jdelay
  jsr jdelay
  jmp $E477
// ----------------------------------------------------------------------
// Clear the keyboardbuffer and also clear the screen
// ----------------------------------------------------------------------
clear_keyboard_and_screen
  mva #255 $2fc                               // clear keyboard buffer
  lda #$7D                                    // load clear screen command
  jsr write_text                               // print it to screen
  rts

// ----------------------------------------------------------------------
// About screen
// ----------------------------------------------------------------------
about_screen:
  mva #15 MENU_ID
  jsr clear_keyboard_and_screen
  displayText DIVIDER_LINE, #0,#0             // draw the divider line
  displayText DIVIDER_LINE, #2,#0             // draw the divider line
  displayText TEXT_ABOUT_SCREEN, #1,#15       // draw the menu title and text
  displayText TEXT_ABOUT_SCREEN2, #10,#0       // draw the more text
  
  displayText DIVIDER_LINE, #22,#0            // draw the divider line
  displayText MLINE_MAIN7, #23,#1             // draw the menu on the bottom line
  jmp help_get_key_input                      // wait for user to press esc to exit
// ----------------------------------------------------------------------
// Help screen
// ----------------------------------------------------------------------
help_screen:                                  //
  mva #16 MENU_ID                             //
  jsr clear_keyboard_and_screen               //
  displayText DIVIDER_LINE, #0,#0             // draw the divider line
  displayText TEXT_HELP_SCREEN, #1,#15        // draw the menu title and text
  displayText TEXT_HELP_SCREEN2, #10,#0        // draw more text
  displayText DIVIDER_LINE, #2,#0             // draw the divider line
  displayText DIVIDER_LINE, #22,#0            // draw the divider line
  displayText MLINE_MAIN7, #23,#1             // draw the menu on the bottom line
                                              //
help_get_key_input                            //
  jsr getKey                                  // wait for a key
  cmp #251                                    // wait for ESC key
  bne help_get_key_input                      // if not, wait for key again
hlp_exit
  mva #255 $2fc                               // clear keyboard buffer 
  jmp main_menu                               // exit to main menu

  
  
// ----------------------------------------------------------------------
// User list screen
// send byte 234 to reset the page number to 0 and get the first group of 20 users
// send byte 233 to get the next group of 20 users
// so we have 40 users on screen.
// at this point we support a max of 120 users per chat server.
// ----------------------------------------------------------------------
user_list:
  mva #14 MENU_ID
  mva #234 TEMPBYTE
ul_start
  jsr clear_keyboard_and_screen
  displayText DIVIDER_LINE, #0,#0             // draw the divider line
  displayText TEXT_USER_LIST, #1,#1          // draw the menu title
  displayText DIVIDER_LINE, #2,#0             // draw the divider line
  displayText DIVIDER_LINE, #22,#0            // draw the divider line
  displayText TEXT_USER_LIST_foot, #23,#1     // draw the menu on the bottom line
  lda VICEMODE
  cmp #1
  bne ul_novice 
  jmp ul_vice 

ul_novice
  lda TEMPBYTE
  jsr send_start_byte                      // RXBUFFER now contains the first group of users, 20
  displayBuffer RXBUFFER,#4 ,#2,#0

  lda #233
  jsr send_start_byte                      // RXBUFFER now contains the second group of users, 40
  displayBuffer RXBUFFER,#9 ,#2,#0

  lda #233
  jsr send_start_byte                      // RXBUFFER now contains the second group of users, 40
  displayBuffer RXBUFFER,#14 ,#2,#0

  displayText DIVIDER_LINE, #22,#0            // draw the divider line
  displayText TEXT_USER_LIST_foot, #23,#1     // draw the menu on the bottom line
  
ul_vice
ul_get_key_input  
  jsr getKey
  //cmp #$37                                  // key 7 is pressed(exit)
  cmp #251                                    // OPTION key is pressed
  beq ul_exit_main_menu
  cmp #$6E                                    // key 'n' is pressed
  beq ul_next
  cmp #$70                                    // key 'p' is pressed
  beq ul_prev  
  jmp ul_get_key_input

ul_next
  mva #233 TEMPBYTE
  jmp ul_start
  
ul_prev
  jmp user_list
  
ul_exit_main_menu
  jmp main_menu

// ----------------------------------------------------------------------
// Account_setup screen
// ----------------------------------------------------------------------
account_setup:
  mva #13 MENU_ID
  jsr clear_keyboard_and_screen
  displayText DIVIDER_LINE, #0,#0             // draw the divider line
  displayText TEXT_ACCOUNT_SETUP, #1,#15      // draw the menu title
  displayText DIVIDER_LINE, #2,#0             // draw the divider line
  displayText TEXT_ACCOUNT_1, #5,#1
  displayText DIVIDER_LINE, #11,#0            // draw the divider line
  displayText TEXT_OPTION_EXIT, #15,#3
  displayText DIVIDER_LINE, #22,#0            // draw the divider line
  
  lda VICEMODE
  cmp #1
  bne acc_novice     
  jmp acc_vice
acc_novice
  lda #243                                    // ask for the mac address, registration id, nickname and regstatus
  jsr send_start_byte                      // the RXBUFFER now contains: macaddress(129)regID(129)NickName(129)regStatus(128) 
  mva #1 SLITINDEX                           //
  jsr splitRXbuffer                           //
  displayBuffer  SPLITBUFFER,#5 ,#14,#0       // Display the buffers on screen (Mac address)
  mva #2 SLITINDEX                           //
  jsr splitRXbuffer                           //
  displayBuffer  SPLITBUFFER,#7 ,#18,#0       // Display the buffers on screen (registration id)
  mva #3 SLITINDEX                           //
  jsr splitRXbuffer                           //
  displayBuffer  SPLITBUFFER,#9 ,#12,#0       // Display the buffers on screen (Nick Name)
  mva #4 SLITINDEX                           //
  jsr splitRXbuffer                           //
  lda SPLITBUFFER
  cmp #120                                    // 120 = x  some unknown error
  bne cp_114
  displayText text_reg_x,#23 ,#6
  jmp acc_input_fields
cp_114
  cmp #114                                    // 114 = r
  bne cp_117
  displayText text_reg_r,#23 ,#5
  jmp acc_input_fields
cp_117
  cmp #117                                    // 117 = u
  bne cp_110                                  // 
  displayText text_reg_u,#23 ,#4
  jmp acc_input_fields
cp_110
  cmp #110                                    // 110 = n
  bne acc_input_fields   
  displayText text_reg_n,#23 ,#5

acc_vice                                      //
acc_input_fields                              // 
  mva #7 ROWCRS                               // Put the cursor in the registration id field
  mva #17 COLCRS                              //
  jsr show_cursor
  mva #19 FIELD_MIN                           //
  mva #35 FIELD_MAX                           //
  lda #32                                     //
  jsr write_text                               //
  jsr text_input                              //

  mva #255 $2fc                               // Clear keyboard buffer
  mva #9 ROWCRS                               // Put the cursor in the Nick Name field
  mva #11 COLCRS                              //
  mva #13 FIELD_MIN                           //
  mva #21 FIELD_MAX                           //
  lda #32                                     //
  jsr write_text                               //
  jsr text_input                              //
  jsr hide_cursor
  
  displayText text_start_save_settings, #13,#3
account_setup_key_input:
  jsr getKey
  cmp #255
  beq account_setup_key_input 
  cmp #251                                    // OPTION is pressed
  beq exit_to_main_menus
  cmp #253                                    // START is pressed
  beq account_save_settings
  mva #255 $2fc                               // clear keyboard buffer 
  jmp account_setup_key_input
  
exit_to_main_menus
  mva #255 $2fc                               // clear keyboard buffer 
  jmp main_menu

account_save_settings
  displayText TEXT_SAVE_SETTINGS, #23, #3
  jsr wait_for_RTR
  lda #240
  sta $D502
  mva #7 TEMP_I                               // Read regid and send it to cartridge
  mva #18 TEMP_I+1
  mva #38 TEXTBOXLEN
  jsr read_field

  mva #9 TEMP_I                               // Read nickname and send it to cartridge
  mva #12 TEMP_I+1
  mva #38 TEXTBOXLEN
  jsr read_field


  mva #255 DELAY
  jsr jdelay
  jsr jdelay
  jsr jdelay
  jsr jdelay  
  jsr get_status 
  jmp account_setup

// ----------------------------------------------------------------------
// Server setup screen
// ----------------------------------------------------------------------
server_setup:  
  
 
  mva #12 MENU_ID
  jsr clear_keyboard_and_screen
  displayText DIVIDER_LINE, #0,#0             // draw the divider line
  displayText TEXT_SERVER_SETUP, #1,#15       // draw the menu title
  displayText DIVIDER_LINE, #2,#0             // draw the divider line
  displayText TEXT_SERVER_1, #5,#1
  displayText DIVIDER_LINE, #10,#0            // draw the divider line
  displayText TEXT_OPTION_EXIT, #15,#3
  displayText DIVIDER_LINE, #22,#0            // draw the divider line
  displayBuffer SERVERNAME,#5,#14,#0
  lda VICEMODE
  cmp #1
  beq svr_vice      
  

  jsr wait_for_RTR
  lda #238
  sta $D502
  mva #255 DELAY
  jsr jdelay  
  jsr jdelay
  
  lda #237                                    // get server connection status
  jsr send_start_byte
  displayBuffer  RXBUFFER,#23 ,#3,#0          // the RX buffer now contains the server status
  
svr_vice 
svr_input_fields                              //
  mva #5 ROWCRS                               // Put the cursor in the Server Name field
  mva #13 COLCRS                              //
  mva #15 FIELD_MIN                           //
  mva #38 FIELD_MAX                           //
  lda #32
  jsr write_text
  jsr show_cursor
  jsr text_input
  jsr hide_cursor
  displayText text_start_save_settings, #13,#3
  
server_setup_key_input:
  jsr getKey
  cmp #255
  beq server_setup_key_input 
  cmp #251                                    // OPTION is pressed
  beq srv_exit_to_main_menu
  cmp #253                                    // START is pressed
  beq server_save_settings
  mva #255 $2fc                               // clear keyboard buffer 
  jmp server_setup_key_input
  
srv_exit_to_main_menu
  mva #255 $2fc                               // clear keyboard buffer 
  jmp main_menu

  
server_save_settings
  displayText TEXT_SAVE_SETTINGS, #23, #3
  jsr wait_for_RTR
  lda #246
  sta $D502
  mva #5 TEMP_I                               // Read servername and send it to cartridge
  mva #14 TEMP_I+1
  mva #25 TEXTBOXLEN
  jsr read_field

  mva #255 DELAY
  jsr jdelay
  jsr wait_for_RTR
  lda #238
  sta $D502
  jsr jdelay
  jsr jdelay
  jsr jdelay  
  jsr get_status 
  jmp server_setup
  
// ----------------------------------------------------------------------
// Wifi setup screen
// ----------------------------------------------------------------------
wifi_setup:  
  mva #12 MENU_ID
  jsr clear_keyboard_and_screen
  displayText DIVIDER_LINE, #0,#0             // draw the divider line
  displayText TEXT_WIFI_SETUP, #1,#15         // draw the menu title
  displayText DIVIDER_LINE, #2,#0             // draw the divider line
  displayText TEXT_WIFI_1, #5,#3
  displayText DIVIDER_LINE, #11,#0            // draw the divider line
  displayText TEXT_OPTION_EXIT, #15,#3
  displayText DIVIDER_LINE, #22,#0            // draw the divider line
  lda VICEMODE
  cmp #1
  beq wf_vice  
  
wifi_get_cred
  lda #248                                    // ask Cartridge for the wifi credentials
  jsr send_start_byte
  displayBuffer  RXBUFFER,#23 ,#3,#1          // the RX buffer now contains the wifi status
  lda #251                                    // ask Cartridge for the wifi credentials
  jsr send_start_byte                           // the RXBUFFER now contains ssid[32]password[32]timeoffset[128]
  mva #1 SLITINDEX                           //
  jsr splitRXbuffer                           //
  displayBuffer  SPLITBUFFER,#5 ,#9,#0        // Display the buffers on screen (SSID name)
  mva #2 SLITINDEX
  jsr splitRXbuffer
  displayBuffer  SPLITBUFFER,#7 ,#13,#0       // Display the buffers on screen (SSID name)
  mva #3 SLITINDEX
  jsr splitRXbuffer
  displayBuffer  SPLITBUFFER,#9 ,#25,#0       // Display the buffers on screen (SSID name)
                                              //
wf_vice                                       //
wifi_input_fields                             //
  mva #5 ROWCRS                               // Put the cursor in the SSID field
  mva #8 COLCRS                               //
  mva #10 FIELD_MIN                           //
  mva #35 FIELD_MAX                           //
  lda #32
  jsr write_text
  jsr show_cursor
  jsr text_input
  jsr hide_cursor  
  
  mva #255 $2fc                               // Clear keyboard buffer
  mva #7 ROWCRS                               // Put the cursor in the password field
  mva #12 COLCRS 
  mva #14 FIELD_MIN
  mva #35 FIELD_MAX
  lda #32
  jsr write_text
  jsr show_cursor
  jsr text_input
  jsr hide_cursor
  
  mva #255 $2fc                               // clear keyboard buffer
  mva #9 ROWCRS                               // put the cursor in the time-offset field
  mva #24 COLCRS 
  mva #26 FIELD_MIN
  mva #32 FIELD_MAX
  lda #32
  jsr write_text
  jsr show_cursor
  jsr text_input
  jsr hide_cursor

  displayText text_start_save_settings, #13,#3
wifi_setup_key_input:
  jsr getKey
  cmp #255
  beq wifi_setup_key_input 
  cmp #251                                    // OPTION is pressed
  beq exit_to_main_menu
  cmp #253                                    // START is pressed
  beq wifi_save_settings
  mva #255 $2fc                               // clear keyboard buffer 
  jmp wifi_setup_key_input
  
exit_to_main_menu
  mva #255 $2fc                               // clear keyboard buffer 
  jmp main_menu

wifi_save_settings
  displayText TEXT_SAVE_SETTINGS, #23, #3
  jsr wait_for_RTR
  lda #252
  sta $D502
  mva #5 TEMP_I                               // Read SSID and send it to cartridge
  mva #9 TEMP_I+1                             // TEMP_I (2 bytes) holds the row and column of the field
  mva #27 TEXTBOXLEN                       // TEXTBOXLEN is the length of the field
  jsr read_field                              // jump to the read_field sub routine
  mva #7 TEMP_I                               // Read password and send it to cartridge
  mva #13 TEMP_I+1
  mva #23 TEXTBOXLEN
  jsr read_field
  mva #9 TEMP_I                               // Read password and send it to cartridge
  mva #25 TEMP_I+1
  mva #10 TEXTBOXLEN
  jsr read_field

  mva #255 DELAY
  jsr jdelay
  jsr jdelay
  jsr jdelay
  jsr jdelay
  jmp wifi_get_cred

// ---------------------------------------------------------------------
// read a field and send it to the cartridge
// input row and column in TEMP_I and TEMP_I+1
// ---------------------------------------------------------------------
read_field:
  lda SCREENMEMORYPOINTER          // reset the input field pointer
  sta TEXTBOX       // reset the input field pointer
  lda SCREENMEMORYPOINTER+1        // reset the input field pointer
  sta TEXTBOX+1     // reset the input field pointer
  jsr open_field      // get a pointer to the start adres of the field
  ldy #0
loopr                 //
  cpy TEXTBOXLEN   // compare y (our index) with the field length
  beq loopr_exit      // if we reach the end of the field, exit
  lda (TEXTBOX),y   // read the field with index y
  jsr wait_for_RTR    // wait for ready to receive on the cartridge
  sta $D502           // write the data to the cartridge
  iny                 // increase our index
  jmp loopr           // loop to read the next character
loopr_exit            //
  jsr wait_for_RTR    // after the field data has been send, we need
  lda #128            // to close the transmission with byte 128
  sta $D502           // send 128 to the cartridge
  rts                 // return

// ---------------------------------------------------------------------
// Open a field to read                  
// input row and column in TEMP_I and TEMP_I+1               
// this procedure creates a pointer to the field in TEXTBOX (2 bytes)               ;
// ---------------------------------------------------------------------
open_field:   
  ldx TEMP_I                   // get the row (TEMP_I holds the rown number)
sm_lineadd                     // SCREENMEMORYPOINTER is the start of screen memory
  clc                          // clear carry
  lda TEXTBOX                // start at the start of screen memory
  adc #40                      // add 40 chars (one row) 
  sta TEXTBOX                // store TEXTBOX (this is the low byte of the pointer)
  bcc sm_ld_done               // if carry is set (overflow), we need to increase the high byte
  inc TEXTBOX+1              // increase the high byte if needed
sm_ld_done                     // one row added, done
  dex                          // decrease x
  bne sm_lineadd               // repeat the above if x is not zero
                               // now we are on the right row, next skip to the right column
  ldx TEMP_I+1                 // get the column 
sm_rowadd                      //
  clc                          // 
  lda TEXTBOX                //
  adc #1                       // add one..
  sta TEXTBOX                // if we overflow, increase the high byte also
  bcc sm_rd_done               //
  inc TEXTBOX+1              //
sm_rd_done                     //
  dex                          // decrease x and repeat if needed
  bne sm_rowadd                //
  rts                          // return to sender, just like Elvis baby!

//=========================================================================================================
//  Vice Simulation check
//=========================================================================================================
are_we_in_the_matrix:                             // 
  mva #0 VICEMODE                                 // this is to check if a real cartridge is attached
                                                  // or if we are running in the a simulator
                                                  // 
  jsr wait_for_RTR                                // 
  lda #245                                        // Load number #245 (to check if the esp32 is connected)
  sta $D502                                       // write the byte to IO1
                                                  // 
                                                  // Send the ROM version to the cartrdige
  ldx #0                                          // x will be our index when we loop over the version text
sendversion                                       // 
  jsr wait_for_RTR                                // wait for ready to receive (bit D7 goes high)
  lda VERSION,x                                   // load a byte from the version text with index x
  
  sta $D502                                       // send it to IO1
  cmp #128                                        // if the last byte was 128, the buffer is finished
  beq check_matrix                                // exit in that case
  inx                                             // increase the x index
  jmp sendversion                                 // jump back to send the next byte

check_matrix                                      // 
  lda #100                                        // Delay 100... hamsters
  sta DELAY                                       // Store 100 in the DELAY variable
  jsr jdelay                                      // and call the delay subroutine
//  jsr wait_for_RTS
//  lda $D502
//  sta COLOR4
//  sta COLOR2
//  jsr jdelay
  jsr wait_for_RTS                                // 
  lda $D502                                       // read from cartridge
  cmp #128                                        // 
                                                  // 
  beq exitSimCheck                                // if vice mode, we do not try to communicate with the
  lda #1                                          // cartridge because it will result in error
  sta VICEMODE                                    //  
                                                  //
exitSimCheck                                      // 
  lda #100                                        // Delay 100... hamsters
  sta DELAY                                       // Store 100 in the DELAY variable
  jsr jdelay                                      // and call the delay subroutine
  rts    
    
// ---------------------------------------------------------------------
// Send a command byte to the cartridge and wait for response;
// ---------------------------------------------------------------------
send_start_byte:                          //
  jsr wait_for_RTR
  sta $D502                             // send the command byte
  ldx #0
  lda $14
  sta tempt
  lda #200                              // set a timeout
  sta $14                               // $14 is one of the clocks
ff_response_loop                        // now wait for a response
  jsr wait_for_RTS
  lda $D502
  sta RXBUFFER,x
  cmp #128
  beq ff_end_buffer
  inx
  lda $14
  cmp #0
  beq ssb_timeout
  jmp ff_response_loop
  
ff_end_buffer
  inx
  lda #128
  sta RXBUFFER,x
  lda tempt
  sta $14
  rts

ssb_timeout  
  lda #128                                 // we did get a response in time (byte 128 was not received)  
  sta RXBUFFER
  lda tempt
  sta $14
  rts
// ----------------------------------------------------------------------
// Wait until the cartridge is ready to receive data (RTR)
// ----------------------------------------------------------------------
wait_for_RTR:
  pha
wait_for_RTR2  
  lda $D500       // check RTR
  and #%00000001
  cmp #%00000001
  bne wait_for_RTR2
  pla
  rts
  
// ----------------------------------------------------------------------
// Wait until the cartridge is ready to send data (RTS)
// ----------------------------------------------------------------------
wait_for_RTS:
  lda $D501       // check RTS
  and #%00000010
  cmp #%00000010
  bne wait_for_RTS
  rts

// ----------------------------------------------------------------------
// Check for messages
// ----------------------------------------------------------------------
check_for_messages:
  lda MENU_ID
  cmp #0
  beq check_cont
  jmp check_exit
check_cont  
  lda $14
  cmp #80
  bcs check_cont2
  jmp check_exit    
check_cont2
  lda #0
  sta $14
  ldy #0

  lda VICEMODE
  cmp #1
  bne check_wifi 
  jmp check_exit
check_wifi
  lda WIFISTATUS
  cmp #49
  beq check_priv_or_pub
  jsr get_wifi_status
  lda WIFISTATUS
  cmp #1
  beq check_priv_or_pub
  jmp check_exit
check_priv_or_pub
  lda SCREEN_ID  
  cmp #3  
  bne check_is_publ  
  lda #247
  jmp check_ff 
check_is_publ
  lda #254
check_ff
  jsr send_start_byte  // RX buffer now contains a message or 128
  lda RXBUFFER
  cmp #128
  beq getNumberOfPrivateMessages
  jmp display_message
  
getNumberOfPrivateMessages  
  jsr checkForUpdates    // first check for updates (new firmware) 
  lda SCREEN_ID
  cmp #3 
  beq check_exit
  lda #241
  jsr send_start_byte
  mva COLCRS savecc
  mva ROWCRS savecr
  lda RXBUFFER
  cmp #$2d
  bne displayPMnumber
  displayBuffer NOPMS, #20,#30,#0
  jmp check_exit0
displayPMnumber
  displayBuffer RXBUFFER, #20,#30,#0
check_exit0
  mva savecc COLCRS 
  mva savecr ROWCRS 
  jsr show_cursor
check_exit  
  rts

//LINEC .byte 0
savex .byte 0
savecr .byte 0
savecc .byte 0
display_message:
  // the RXBUFFER contains a message.
  
  mva COLCRS savecc
  mva ROWCRS savecr
  ldx #0 
make_room_loop
  lda RXBUFFER,x
  cmp #1
  bne get_display_start_address
  stx savex
  jsr shift_screen_up
  ldx savex
  inx
  jmp make_room_loop
  
get_display_start_address  
  // determine start address in screen memory
  mwa STARTLINE1 TEMP_I  
  lda savex
  cmp #0
  beq do_display
  mwa STARTLINE2 TEMP_I  
  lda savex
  cmp #1
  beq do_display
  mwa STARTLINE3 TEMP_I  
  lda savex
  cmp #2
  beq do_display
  mwa STARTLINE4 TEMP_I  
  
do_display     
  // loop the RX buffer
  ldx savex
  inx
  ldy #0
rxb_loop
  lda RXBUFFER,x  
  cmp #128
  beq get_m_exit
  cmp #254        // we use this as inverted space
  bne write_char
  lda #128        // this is a real inverted space
write_char
  sta (TEMP_I),y
  iny
  inx
  jmp rxb_loop
  
get_m_exit  
  jsr bell1  
  mva savecc COLCRS 
  mva savecr ROWCRS  
  mva #80 $14 
  rts

// ----------------------------------------------------------------------
// Check for updates
// ----------------------------------------------------------------------
checkForUpdates
  lda NEWROM         // if we allready know there is a new version, skip the check
  cmp #128
  bne exitVersions
  lda #239
  jsr send_start_byte
  lda RXBUFFER        // if there is a new version, RXBUFFER contains the new version numbers 
  cmp #128            // or it could contain nothing, just 128 if there is no new version
  bne getVersions 
  rts


getVersions
  ldy #0  
getRom
  lda RXBUFFER,y
  sta NEWROM,y  
  cmp #32
  beq getVersionEsp
  iny
  jmp getRom
getVersionEsp
  lda #128
  sta NEWROM,y  
  ldx #0
  iny
getEsp  
  lda RXBUFFER,y
  sta NEWESP,x
  cmp #128
  beq exitVersions
  iny
  inx
  jmp getEsp
exitVersions:
  rts

// ----------------------------------------------------------------------
// procedure for text input
// ----------------------------------------------------------------------
text_input:
  mva #0 CURSORINH                        // show the cursor 
key_loop
  jsr check_for_messages
  jsr getKey
  cmp #255
  beq key_loop

cpClear
  cmp #1
  bne cpselect 
  jsr clear_input_lines
  mva #255 $2fc                       // clear keyboard buffer
  jmp key_loop
  
  
cpselect
  cmp #252
  bne cpoption
  lda MENU_ID
  cmp #10
  bcs key_loop
  mva #255 $2fc                       // clear keyboard buffer 
  jmp toggle_screens
  
cpoption
  cmp #251
  bne cpstart
  mva #255 $2fc                       // clear keyboard buffer   
  jsr backup_screen
  jmp main_menu

cpstart  
  cmp #253
  bne cpdelete
  lda MENU_ID
  cmp #10
  bcs key_loop
  mva #255 $2fc                       // clear keyboard buffer   
  jsr check_private                  // check if users tries to send a private message
  jsr send_message
  mva #0 inhsend
  lda doswitch
  cmp #1
  bne cpstart_exit
  mva #255 $2fc                       // clear keyboard buffer 
  jsr clear_input_lines
  mva #0 doswitch
  jmp toggle_screens
cpstart_exit  
  jmp key_loop
  
cpdelete  
  cmp #8                           // delete key is pressed
  beq handle_delete
   
cpreturn
  cmp #13
  bne cp_up 
  jmp handle_return

cp_up                               // check the cursor keys up down left right
  cmp #142     
  bne cp_down 
  jmp handle_up
cp_down
  cmp #143
  bne cp_left 
  jmp handle_down  
cp_left
  cmp #134  
  bne cp_right
  jmp handle_left
cp_right
  cmp #135
  bne check_end_pos
  jmp handle_right

check_end_pos
  pha
  lda ROWCRS
  cmp #23
  bne rp
  lda COLCRS
  cmp #39
  bne rp      
  pla  
  lda #$1E
  jmp chrout
rp pla 
  
chrout                               // output the key to screen
  pha
  lda MENU_ID
  cmp #10
  bcs in_field  
  
out_ok    
  pla  
  jsr write_text
out_exit
  mva #255 $2fc                      // clear keyboard buffer 
  jmp key_loop
in_field  
  lda COLCRS
  cmp FIELD_MAX
  bcc out_ok
  pla
  jsr write_text
  lda #$1E
  jsr write_text
  jmp out_exit  

handle_delete
  
  lda MENU_ID
  cmp #10
  bcs del_in_field
hd_ok  
  lda ROWCRS
  cmp #21
  bne delok
  lda COLCRS
  cmp #0
  bne delok  
  mva #255 $2fc                       // clear keyboard buffer 
  jmp key_loop
delok  
  
  lda #$1E                    // this is to work around a bug. backspace does not always work  
  jsr write_text               // when the cursor is at column zero.. this works around that
  lda COLCRS                  // in stead of using backspace, we walk the cursor back,
  cmp #39                     // write a space character and walk the cursor back again
  bne delcont                 // But if you walk the cursor back on column zero, it goes
  lda #$1C                    // to column 39 on that SAME LINE.. so we have to correct
  jsr write_text               // that too..
delcont                       // Man this is getting ugly..
  lda #32                     //
  jsr write_text               // anyway, it works now. get over it, move on, have a beer
  lda #$1E
  jsr write_text
  lda COLCRS
  cmp #39
  bne delexit
  lda #$1C
  jsr write_text
delexit
  mva #255 $2fc
  jmp key_loop

del_in_field         
  lda COLCRS         
  cmp FIELD_MIN
  bcc delexit
  lda #$7E
  jsr write_text
  jmp delexit
  
         
handle_return
  lda MENU_ID
  cmp #10
  bcs exit_on_return 
  lda ROWCRS                          // ignore this key if we are on the last line
  cmp #23
  beq handle_return_send 
  lda #$9b
  jmp chrout
exit_on_return 
  rts 

handle_return_send
  mva #255 $2fc
  jsr send_message
  jmp key_loop
  
handle_up
  lda MENU_ID
  cmp #10
  bcs up_exit
  lda ROWCRS                          // ignore this key if we are on the first line
  cmp #21
  bne upok
up_exit
  mva #255 $2fc                       // clear keyboard buffer 
  jmp key_loop
upok
  lda #$1C
  jmp chrout
  
handle_down
  lda MENU_ID
  cmp #10
  bcs up_exit
  lda ROWCRS                          // ignore this key if we are on the last line
  cmp #23
  bne downok
  mva #255 $2fc                       // clear keyboard buffer 
  jmp key_loop
downok  
  lda #$1D
  jmp chrout

handle_left
  lda MENU_ID
  cmp #10
  bcs lf_limit 
hl_ok
  lda #$1E
  jmp chrout
lf_limit
  lda COLCRS
  cmp FIELD_MIN
  bcs hl_ok
  jmp hr_ng
  
handle_right
  lda MENU_ID
  cmp #10
  bcs rf_limit
hr_ok
  lda #$1F
  jmp chrout
rf_limit  
  lda COLCRS  
  cmp FIELD_MAX
  bcc hr_ok
hr_ng
  mva #255 $2fc                       // clear keyboard buffer 
  jmp key_loop


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
  lda ROWCRS
  sbc #21
  tax
  lda startR,x
  sta temppos
  ldy COLCRS
   
lq1  
  cpy #0  
  beq lqd
  dey
  inc temppos
  jmp lq1
lqd
  ldy temppos
  lda (MESSAGEFIELD),y                  ; get the character under the cursor
  adc #127                            ; invert the char
  sta (MESSAGEFIELD),y                  ; put it back on the screen
  cmp #127
  bcc setphase1  
  lda #0
  sta cursorphase
  jmp exit_bc
  
setphase1
  //lda #1
  inc cursorphase
  jmp exit_bc
  
  //ROWCRS = $54 ; cursor row 
  //COLCRS = $55 ; cursor colm ; find out where the cursor is
  //
  
exit_bc
  rts

// ----------------------------------------------------------------------
// procedure for sound
// ----------------------------------------------------------------------



ttone .byte 0
playTone:
  // a = 1 to 63 (pitch)
  // x = length
  sta ttone
  stx DELAY
  lda #%01000000
  ora ttone
  jsr chibiSound
  jsr jdelay
  lda #0
  jsr chibiSound
  rts

updateSound:  
  ldx #55
  lda #35
  jsr playTone
  ldx #2
  lda #0
  jsr playTone  
  ldx #50
  lda #35
  jsr playTone
  lda #25
  jsr playTone
  lda #35  
  jsr playTone
  lda #30  
  jsr playTone
  ldx #90
  lda #20  
  jsr playTone
  rts
  
sound_zipp:
  ldx #5
  lda #20  
  jsr playTone
  lda #18  
  jsr playTone
  lda #16
  jsr playTone
  lda #14
  jsr playTone
  lda #12
  jsr playTone
  lda #10
  jsr playTone
  lda #8
  jsr playTone
  lda #6
  jsr playTone
  lda #4
  jsr playTone
  rts
  
bell1:  
  ldx #10
  lda #25
  jsr playTone
  lda #25
  jsr playTone
  lda #22
  jsr playTone    
  lda #19
  jsr playTone
  lda #14
  jsr playTone
  rts
  
error_sound:
  ldx #30
  lda #63
  jsr playTone
  lda #61
  jsr playTone
  lda #63
  jsr playTone
  lda #62
  jsr playTone
  lda #61
  jsr playTone
  rts
  
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
    pha                                           // Backup a,x,y registers to the stack
    txa                                           //
    pha                                           // Backup a,x,y registers to the stack
    tya                                           //
    pha                                           // Backup a,x,y registers to the stack
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
    iny                                           // 
    jmp dodelay                                   // 
                                                  // 
enddelay                                          // 
    pla                                           // Pull a,x,y registers from the stack
	tay                                           //
	pla                                           //
	tax                                           //
	pla                                           //
    rts                                           // 
                                                  // 
                                                  
// ----------------------------------------------------------------------
//  Clear input lines
// ----------------------------------------------------------------------
clear_input_lines:  
  // fill the input lines with spaces  
  mva #21 ROWCRS
  mva #0  COLCRS
  lda #32 // space character
  ldy #0
  sty temppos
cl_loop  
  jsr write_text
  inc temppos
  ldy temppos
  cpy #119
  beq cl_exit
  jmp cl_loop
cl_exit
  lda #0
  sta CURSORINH
  mva #20 ROWCRS
  mva #0 COLCRS
  lda #29 
  jsr write_text
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
  .byte 'l','j',';',3,4,'k','+','*','o',9,'p','u',13,'i','-','=','v',17,'c',19,20,'b','x','z','4',25,'3','6',251,'5','2'
//          31  32   33  34  35 36 37  38  39 40  41  42  43  44  45 46  47  48  49  50  51 52  53  54  55  56  57  58 59 60
  .byte     '1',',',' ','.','n',36,'m','/',' ','r',41,'e','y', ' ','t','w','q','9',49,'0','7',8,'8','<','>','f','h','d',59,' '
//          61  62   63  64  65 66  67 68 69  70  71  72  73  74  75 76  77  78  79  80 81  82 83 84  85  86  87  88 89 90
  .byte     'g','s','a','L','J',':', 3,68,'K','\','^','O',73,'P','U',253,'I','_','|','V',81,'C',83,84,'B','X','Z','$',89,'#'
//          91  92  93  94  95  96 97  98  99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 
  .byte     '&',251,'%','"','!','[',33,']','N',100,'M','?',' ','R',105,'E','Y',' ','T','W','Q','(',113,')','''',8,'@',1,'>','F'
//          121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150  
  .byte     'H','D',123,' ','G','S','A','L','J',';','3',  4,'K',134,135,'O',137,'P','U',253,'I',142,143,'V', 17,'C', 19, 20,'B','X'
//          151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180
  .byte     'Z','$',153,'#','&',251,'%','"',255,'[',161,']','N',164,'M','?',' ','R',169,'E','Y',' ','T','W','Q','(',177,')','''',8
//          181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210
  .byte     '@',1,'>','F','H','D',187,' ','G','S','A','L','J',';',195,196,197,198,199,'O',201,'P','U',253,'I','_','|','V',209,210
//          211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240
  .byte     211,212,213,214,215,'$',217,'#','&',251,'%','"','!','[',225,']','N',228,'M','?',' ','R',233,'E','Y',' ','T','W','Q','('
//          241 242 243 244 245 246 247 248 249 250 251 252 253 254 255
  .byte     241,')' ,'''',  8,'@',246,'>','F','H','D',251, ' ','G','S','A'


getKey:   
  jsr readRTS                           // check for incomming data or reset request   
  lda $D01F                             // is one of the console keys pressed?
  and #7                                //
  cmp #6                                //
  beq prSTART                           //
  cmp #5                                //
  beq prSELECT                          //
  cmp #3                                //
  beq prOPTION                          //
                                        //
chkBreak                                //
  lda $0011                             // is the break key pressed?
  cmp #0                                //
  bne chkHelp                           //
  rts                                   // return with zero
                                        //
chkHelp                                 //
  lda $02DC                             // is the HELP key pressed ?
  and #1                                //
  cmp #1                                //
  beq prHELP                            //

  
readKeyboardBuffer
  lda $2FC                              // is there a key in the keyboard buffer?
  cmp #255                              // 255 means no key
  beq exit_getkey                       // exit if no key

keyConvert                              // convert the key code to ascii
  tay                                   //
  lda kb2asci,y                         //
exit_getkey                             //
  rts                                   //
                                        //
prOPTION                                //
  lda $D01F                             // wait until the key is released
  and #4                                //
  cmp #0                                //
  beq prOPTION                          //
  lda #251                              //
  rts                                   //
                                        //
prSELECT                                //
  lda $D01F                             // wait until the key is released
  and #2                                //
  cmp #0                                //
  beq prSELECT                          //
  lda #252                              //
  rts                                   //
                                        //
prSTART                                 //
  lda $D01F                             // wait until the key is released
  and #1                                //
  cmp #0                                //
  beq prSTART                           //
  lda #253                              //
  rts                                   //
                                        //
prHelp                                  //
  lda #0                                // 
  sta $02DC                             // This address is latched and must be 
  lda #254                              // reset to zero after being read
  rts                                   //
  
//=========================================================================================================
//    SUB ROUTINE TO SPLIT RXBUFFER
//=========================================================================================================
splitRXbuffer:                                   //
                                                 // RXBUFFER now contains FOR EXAMPLE macaddress[129]regid[129]nickname[129]regstatus[128]
    ldx #0                                       // load zero into x and y    
    ldy #0                                       //   
sp_read:                                         // read a byte from the index buffer   
    lda RXBUFFER,x                               // copy that byte to the split buffer   
    sta SPLITBUFFER,y                            // until we find byte 129   
    cmp #129                                     //    
    beq sp_n                                     //    
    cmp #128                                     // or the end of line character   
    beq sp_n                                     //    
    inx                                          // increase the x index   
    iny                                          // and also the y index   
    jmp sp_read                                  // back to the start to get the next character   
sp_n:                                            //    
    lda #128                                     //     
    sta SPLITBUFFER,y                            // load 128 (the end byte) into the splitbuffer   
    dec SLITINDEX                               // decrease $02. This address holds a number that indicates   
    lda SLITINDEX                               // which word we need from the RXBUFFER   
    cmp #0                                       // so if $02 is equal to zero, we have the right word   
    beq sp_exit                                  // exit in that case   
    ldy #0                                       // if we need the next word   
    inx                                          // we reset the y index,   
    jmp sp_read                                  // increase the x index   
                                                 // and get the next word from the RX buffer
sp_exit:                                         // 
    rts                                          // return.   
                                                 // 
// ----------------------------------------------------------------------
// Start Screen
// ----------------------------------------------------------------------            
startScreen:
  jsr clear_keyboard_and_screen
  displayText TEXT_FOR_ATARI_800XL, #14,#12
  displayText TEXT_MADE_BY, #16,#5
  mwa CHARSET temppos                  // make a backup of the pointer to the character set
  mva #1 CURSORINH
  ldx #0
cp_char_loop                           // copy charactre set
  mva ROM_CHARS,x SCREEN_PUBL_BACKUP,x
  mva ROM_CHARS+$100,x SCREEN_PUBL_BACKUP+$100,x
  mva ROM_CHARS+$200,x SCREEN_PUBL_BACKUP+$200,x
  mva ROM_CHARS+$300,x SCREEN_PUBL_BACKUP+$300,x
  inx
  bne cp_char_loop 
  

  // copy custom chars
  ldx #0
cust_loop  
  mva  CUSTOM_CHARS,x  SCREEN_PUBL_BACKUP,x
  inx
  cpx #128
  bne cust_loop
  mva #>SCREEN_PUBL_BACKUP CHARSET    // set the char pointer to the new location
  lda SCREENMEMORYPOINTER                          // create a pointer to the start of the screen
  sta TEMP_I                          // and to the end of the screen
  lda SCREENMEMORYPOINTER+1
  sta TEMP_I+1
  inc TEMP_I+1
  inc TEMP_I+1
  inc TEMP_I+1  
  lda #16
  sta TEMP_I
  
  ldy #239                            // draw the main strips 
ss2
  lda #8 //#85 
  sta (TEMP_I),y
  lda #9 
  sta (SCREENMEMORYPOINTER),y
  dey
  cpy #255
  bne ss2

  lda SCREENMEMORYPOINTER               // make a new pointer that points to the 
  sta TEMP_I               // start line of the big letters
  sta TEMP_I
  lda SCREENMEMORYPOINTER+1
  sta TEMP_I+1
  inc TEMP_I+1
  lda #128
  sta TEMP_I
   
  ldy #0                    // draw the big letters
ssBigLetters
  lda SCBIGTEXT,y
  cmp #255
  beq stars 
  sta (TEMP_I),y
  iny
  jmp ssBigLetters
  
stars                         // draw the stars
  ldx #0
  inc TEMP_I+1
  inc TEMP_I+1
  lda #56
  sta TEMP_I
  sta TEXTPOINTER             // we need this later for animating the stars
  sta TEMPB 
  mva TEMP_I+1 TEXTPOINTER+1  // we need this later for animating the stars
  
  lda #15
stars_lp
  ldy SC_STARS1,x
  cpy #255
  beq startupSound
  sta (SCREENMEMORYPOINTER),y
  ldy SC_STARS2,x  
  sta (TEMP_I),y 
  inx
  jmp stars_lp

startupSound:
  lda #20
  jsr playTone_startup
  lda #15
  jsr playTone_startup
  lda #20
  jsr playTone_startup
  lda #15
  jsr playTone_startup
  lda #12
  jsr playTone_startup
  lda #12
  jsr playTone_startup
   
  
wkey2  
  jsr animate_stars
  jsr readRTS                           // check for incomming data or reset request
  lda $02FC                             // wait for any key
  cmp #255                              // see if last key equals zero
  beq wkey2   


  mwa temppos CHARSET
  rts

animate_stars
  tya
  pha
  txa
  pha
  mwa SCREENMEMORYPOINTER TEMP_I
  jsr shift_line_to_left
  lda TEMP_I
  adc #39
  sta TEMP_I
  jsr shift_line_to_left
  lda TEMP_I
  adc #39
  sta TEMP_I
  jsr shift_line_to_left
  lda TEMP_I
  adc #39
  sta TEMP_I
  jsr shift_line_to_left
  lda TEMP_I
  adc #39
  sta TEMP_I
  jsr shift_line_to_left
  
  lda TEMPB
  sta TEXTPOINTER
  jsr shift_line_to_right  
  lda TEXTPOINTER
  adc #39
  sta TEXTPOINTER
  jsr shift_line_to_right
  lda TEXTPOINTER
  adc #39
  sta TEXTPOINTER
  jsr shift_line_to_right
  lda TEXTPOINTER
  adc #39
  sta TEXTPOINTER
  jsr shift_line_to_right
  lda TEXTPOINTER
  adc #39
  sta TEXTPOINTER
  jsr shift_line_to_right
  
  lda #40
  sta DELAY
  jsr jdelay
  pla
  tax
  pla
  tay
  rts

playTone_startup:
  // a = 1 to 63 (pitch)
  sta ttone
  stx DELAY
  lda #%01000000
  ora ttone
  jsr chibiSound
  jsr animate_stars
  lda #0
  jsr chibiSound
  rts
  
//=========================================================================================================
//  SUB ROUTINE TO SHIFT THE COLORS IN THE STAR LINES TO LEFT
//=========================================================================================================
shift_line_to_left:                               // a pointer to the screen memory address where the line we want to shift starts
                                                  // is stored in zero page address TEMP_I, TEMP_I+1
    ldy #0                                        // before we start the loop we need to store the very first character
    lda (TEMP_I),y                                // so load the character on the first position of the line
    pha                                           // push it to the stack, for later use
    iny                                           // y is our index for the loop, it starts at 1 this time.
                                                  // 
shift_l_loop:                                     // start the loop
                                                  // the loop works like this:
    lda (TEMP_I),y                                // 1) load the character at postion y in the accumulator
    dey                                           // 2) decrease y
    sta (TEMP_I),y                                // 3) store the char on position y. So now the character has shifted left
    cpy #39                                       // 4) see if we are at the end of the line
    beq shift_l_exit                              // and exit if we are
    iny                                           // 5) if not, increase y
    iny                                           // twice (because we decreased it in step 2
    jmp shift_l_loop                              // 6) back to step 1
                                                  // 
shift_l_exit                                      // here we exit the loop
                                                  // 
    pla                                           // 7) we need to store the very first character (the most left)
    sta (TEMP_I),y                                // on the most right position, so the line goes round and round
    rts                                           // now this line have shifted 1 position to the left
                                                  // 
//=========================================================================================================
//  SUB ROUTINE TO SHIFT THE STAR LINES TO RIGHT
//=========================================================================================================
TempCharR .byte 0                                 //
TEMPB .byte 0                                     //
shift_line_to_right:                              // a pointer to the memory address where the line we want to shift starts
                                                  // is stored in zero page address TEXTPOINTER (2 bytes)
                                                  // shifting a line to the right is a bit more complicated as to shifting to the left.
                                                  // to better explain we have this line as example ABCDEFGH
                                                  // 
    ldy #0                                        // start at postion zero (A in our line)
    lda (TEXTPOINTER),y                           // read the characters color (the zero page address $f7,$f8
    sta TEMP_O                                    // store it temporary in memory address 'TEXTPOINTER', so now A is stored in 'TEXTPOINTER'
                                                  // 
shift_r_loop:                                     // 
    iny                                           // increase our index, y
    lda (TEXTPOINTER),y                           // read the character at the next postion (B in our line of data)
    sta TempCharR                                 // store color B temporary in memory address 'TempCharR', so now B is stored in 'TempCharR'
    lda TEMP_O                                    // now load 'TEXTPOINTER' (that contains A) back into the accumulator
    sta (TEXTPOINTER),y                           // and store it where B was. The Data line looks like this now AACDEFGH (A has shifted to the right and B is in temporary storage at $ff)
    iny                                           // increase y again
    lda (TEXTPOINTER),y                           // Read the color on the next position (C in our line of data)
    sta TEMP_O                                    // Store it it temporary in memory address TEXTPOINTER, so now B is stored in TEXTPOINTER
    lda TempCharR                                 // now load TempCharR (that contains B) back into the accumulator
    sta (TEXTPOINTER),y                           // and put that where C was. The data line now look like this: AABDEFGH (A and B have shifted and C is in temporary storage at $fe)
    cpy #38                                       // see if we are at the end of the line 
    bne shift_r_loop                              // if not, jump back to the start of the loop
                                                  // after the loop we have processed 39 positions, but the line is 40 long
                                                  // At this point G is in memory storage TEXTPOINTER and H is in storage at TempCharR
    iny                                           // increase y
    lda TEMP_O                                    // load G
    sta (TEXTPOINTER),y                           // put it in position H
                                                  // 
                                                  // NOW the data looks like this: AABCDEFG (all characters have shifted except for H which is in storeage at TEXTPOINTER)
    ldy #0                                        // set the index back to zero
    lda TempCharR                                 // load TempCharR (H) into the accumulator
    sta (TEXTPOINTER),y                           // and store it at the first position.
    rts                                           // Now our line looks like this: HABCDEFG all characters have shifted to the right one position.
                                                  // 
// ----------------------------------------------------------------------
// displayBuffer, used in macro displayRXBuffer
// ----------------------------------------------------------------------
displayBufferk:                                   // 
  mva #1 CURSORINH                                   // 
db_next_char                                      // 
  ldy CHARINDEX                                   // 
  lda (TEXTPOINTER),y                             //   
  cmp #128                                        // 
  beq db_exit                                     // 
write_it                                          // 
  jsr write_text                                   // 
  inc CHARINDEX                                   // 
  jmp db_next_char                                // 
db_exit                                           // 
  rts                                             // 
                                                  // 
// ----------------------------------------------------------------------
// displayTextk, used in macro displayText
// ----------------------------------------------------------------------
displayTextk:  
  mva #1 CURSORINH
next_char
  ldy CHARINDEX
  cpy TEXTLEN
  beq exit_dpt
  lda (TEXTPOINTER),y

  jsr write_text
  inc CHARINDEX
  jmp next_char
exit_dpt
  rts
  
write_text:
  tax
  lda putchar_ptr+1
  pha
  lda putchar_ptr
  pha
  txa
  rts



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

// ----------------------------------------------------------------------
// Reset the Atari
// ----------------------------------------------------------------------
resetAtari:  
   jmp $E477            // jump to reboot vector to restart the Atari.

//----------------------------------------------------------------------
// Hide or show the cursor
//----------------------------------------------------------------------
hide_cursor:                //
  mva #1 CURSORINH             // hide the cursor
  jmp move_cursor           //
                            //
show_cursor:                //
  mva #0 CURSORINH             // show the cursor
move_cursor                 // move the cursor so it will actually become (in)visible
  lda #28                   // up one line
  jsr write_text             //
  lda #29                   // down one line
  jsr write_text             //
  rts                       //
                            //
//----------------------------------------------------------------------
// Send the message
// ----------------------------------------------------------------------
send_message: 
  lda inhsend
  cmp #1
  bne sm_waitrtr
  rts
sm_waitrtr
  lda VICEMODE
  cmp #1
  beq sendWasGood
  jsr wait_for_RTR
  lda #253
  sta $D502
  
  jsr beep1
  jsr hide_cursor
  mwa MESSAGEFIELD TEMP_I
  dec TEMP_I  
  ldy #0
sendLines
  jsr wait_for_RTR
  lda (TEMP_I),y  
  sta MESSAGE_LINES_BACKUP,y
  sta $D502
  iny
  cpy #120
  bne sendLines 
  
  jsr wait_for_RTR
  lda #128
  sta $D502
    
  lda #249 
  jsr send_start_byte   // get the result of the send action
  lda RXBUFFER
  cmp #0
  beq sendWasGood 
  jsr show_cursor
  jsr cl_exit
  rts
sendWasGood  
  mva #0 CURSORINH               // enable the cursor again
  jsr clear_input_lines
  jsr print_pm_user  // print pmuser if we are on screen #3
  rts

// ----------------------------------------------------------------------
// check if the message is private  
// ----------------------------------------------------------------------
check_private:                                       
  lda SCREEN_ID             // private messages start with @ and should only
  cmp #3                    // be send from the private screen (Screen_id==3)
  bne on_publ_screen  
  jmp on_priv_screen          
on_publ_screen                               
  ldy #0                    // we are on the public screen, the message should
  mwa MESSAGEFIELD TEMP_I     // not start with @ 
  lda VICEMODE
  cmp #1
  beq t11
  dec TEMP_I
t11
  lda (TEMP_I),y           
  cmp #32                   // 32 is the screen code for @
  beq ch_go 
  jmp check_p_exit
ch_go
  lda #1 
  sta inhsend
  sta doswitch
  jsr error_sound
  mva ROWCRS p_cursor_y
  mva COLCRS p_cursor_x
  jsr backup_screen
  jsr clear_keyboard_and_screen
  displayText ERROR_PUB_PRIV, #8, #0
  jsr bigdelay  
  mva #<SCREEN_PUBL_BACKUP TEMP_I
  mva #>SCREEN_PUBL_BACKUP TEMP_I+1
  jsr restore_the_screen 
  lda #1 
  sta restoreMessageLines
  jsr backup_message
  jmp check_p_exit

on_priv_screen
  ldy #0                    // we are on the private screen, the message should
  mwa MESSAGEFIELD TEMP_I     // start with @
  lda VICEMODE
  cmp #1
  beq t12
  dec TEMP_I
t12
  lda (TEMP_I),y            
  cmp #32           // yes, it starts with @ as it should
 
  bne doNotSend 
  jsr getPmUser    // store the name of the @user in a variable
  jmp check_p_exit
doNotSend
  mva #1 inhsend
  jsr error_sound
  mva ROWCRS p_cursor_y
  mva COLCRS p_cursor_x
  jsr backup_screen
  jsr clear_keyboard_and_screen
  displayText ERROR_PRIV, #8, #0
  jsr bigdelay
  mva #<SCREEN_PRIV_BACKUP TEMP_I
  mva #>SCREEN_PRIV_BACKUP TEMP_I+1
  jsr restore_the_screen
  mva p_cursor_y ROWCRS
  mva p_cursor_x COLCRS
  jsr show_cursor
check_p_exit
  rts

bigdelay
  lda #255
  sta DELAY
  jsr jdelay
  jsr jdelay
  jsr jdelay
  jsr jdelay
  jsr jdelay
  jsr jdelay
  jsr jdelay
  rts

getPmUser: // read the pm user from screen
  lda (TEMP_I),y
  sta PMUSER,y
  cmp #0  // space
  beq fin_pmuser
  cmp #12  // comma
  beq fin_pmuser
  cmp #14  // full stop
  beq fin_pmuser
  cmp #26 // :
  beq fin_pmuser
  cmp #27 // ;
  beq fin_pmuser
  iny
  jmp getPmUser
fin_pmuser
  iny
  lda #128
  sta PMUSER,y
rts

// ----------------------------------------------------------------------
// Calculate the addresses of where the messages will start
// ----------------------------------------------------------------------
calculate_screen_addresses:  
  mwa SCREENMEMORYPOINTER TEMP_I   // calculate some adresses from the start of screen memory (SCREENMEMORYPOINTER)
  lda TEMP_I
  clc
  adc #$80
  sta STARTLINE4  // C0
  adc #$28
  sta STARTLINE3  // E8
  adc #$28
  clc
  sta STARTLINE2  // 10
  adc #$28
  sta STARTLINE1  // 38
  
  lda TEMP_I+1
  adc #2
  sta STARTLINE4+1
  sta STARTLINE3+1
  lda TEMP_I+1
  adc #3
  sta STARTLINE2+1
  sta STARTLINE1+1
//  sta $BF38  // start adres bij 1 regel (system message ofzo)
//  sta $BF10  // start adres bij 2 regels
//  sta $BEE8  // start adres bij 3 regels
//  sta $BEC0  // start adres bij 4 regels
  rts

// ----------------------------------------------------------------
// Constants
// ----------------------------------------------------------------
VERSION .byte '3.76',128
VERSION_DATE .byte '12/2024',128
.local VERSION_LINE
.byte ' Version  ROM x.xx  ESP x.xx    12/2024'
.endl
NEWROM: .byte 128,128,128,128,128,128
NEWESP: .byte 128,128,128,128,128,128


NOPMS .byte 18,18,18,18,18,18,18,18,128
HAVE_M_BACKUP:                .byte 0             // 
HAVE_P_BACKUP:                .byte 0             //
HAVE_ML_BACKUP:               .byte 0             //

// data for big letters on the start screen
SCBIGTEXT:                                 
	.byte 0,0,0,0,0,0,0,0
	.byte 3,5,5,2,10,0,0,10
	.byte 3,5,5,2,11,12,11,0
	.byte 3,5,5,2,10,0,0,0
	.byte 0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0
	.byte 7,0,0,0,10,0,0,10
	.byte 10,0,0,10,0,10,0,0
	.byte 7,0,0,0,10,0,0,10
	.byte 0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0
	.byte 7,0,0,0,13,11,11,14
	.byte 13,11,11,14,0,10,0,0
	.byte 7,5,5,2,4,11,11,14
	.byte 0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0
	.byte 7,0,0,0,10,0,0,10
	.byte 10,0,0,10,0,10,0,0
	.byte 7,0,0,10,0,0,0,10
	.byte 0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0
	.byte 4,6,6,1,10,0,0,10
	.byte 10,0,0,10,0,10,0,0
	.byte 4,6,6,1,0,0,0,10
	.byte 0,0,0,0,0,0,0,0
	.byte 255 
	   
CUSTOM_CHARS:                          // custom chars for big letters and stars            
  .byte 0,0,0,0,0,0,0,0                // #0  space
  .byte 24,24,56,240,224,0,0,0         // #1  arc 1 
  .byte 0,0,0,224,240,56,24,24         // #2  arc 2
  .byte 0,0,0,7,15,28,24,24            // #3  arc 3
  .byte 24,24,28,15,7,0,0,0            // #4  arc 4
  .byte 0,255,255,0,0,0,0,0            // #5  high line horizontal
  .byte 0,0,0,0,0,255,255,0            // #6  low line horizontal
  .byte 48,48,48,48,48,48,48,48        // #7  line left vertical
  .byte 0,0,0,0,255,255,255,255        // #8  line bottom horizontal
  .byte 255,255,255,255,0,0,0,0        // #9  line top horizontal
  .byte 24,24,24,24,24,24,24,24        // #10 line mid vertical
  .byte 0,0,0,255,255,0,0,0            // #11 line mid horizontal
  .byte 0,0,0,255,255,24,24,24         // #12 T 
  .byte 24,24,24,31,31,24,24,24        // #13 T to right
  .byte 24,24,24,248,248,24,24,24      // #14 T to left
  .byte 170,127,222,117,234,119,234,85 // #15 stardust
  
SC_STARS1 .byte 35,74,75,76,115,52,91,92,93,132,105,144,145,146,185,82,121,122,123,162,255
SC_STARS2 .byte 6,45,46,47,86, 25,65,64,66,105, 93,132,133,134,173, 76,115,116,117,156,255  

CONFIRMUPDATE: .byte "UPDATE!",128

UPDATEBOX: .byte $11,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12
           .byte $12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12,$12,5,$9b
           .byte $20,$20,$7c
           :32 .byte $20
           .byte $7c,$9b,$20,$20,$1A
           :32 .byte $12
           .byte 3,$9b,$1f,$1f,$1f,$1c,$1c           
           .byte 128
  .local UPDATEDONE
  .byte 'Update complete!'
  .endl
  
  .local TEXT_INSTALLING
  .byte 'Installing firmware'
  .lend
  
  .local TEXT_USER_LIST
  .byte 'USER LIST, inverted users are online'
  .endl
  .local TEXT_USER_LIST_foot
  .byte '[p] previous  [n] next  [ESC] Exit'
  .endl
  
  .local TEXT_F5_TOGGLE
  .byte 'Private Messaging      [SEL] Main Chat'
  .endl
  
  .local TEXT_NO_CARTRIDGE
  .byte 'Cartridge Not Installed!'
  .endl
  .local TEXT_WIFI_SETUP
  .byte 'WIFI SETUP'
  .endl
  
  .local TEXT_WIFI_1
  .byte 'SSID:'
  .byte  $9b,$9b,'   '
  .byte 'PASSWORD:'
  .byte  $9b,$9b,'   '
  .byte 'Time Offset from GMT: +0'
  .endl

  .local TEXT_OPTION_EXIT 
  .byte '[ESC] Exit'
  .endl  

  .local text_start_save_settings
  .byte '[START]  Save Settings'
  .endl  
  
  .local text_main_menu
  .byte 'MAIN MENU'
  .endl
  
  .local TEXT_SERVER_SETUP
  .byte 'SERVER SETUP'
  .endl
  
  .local TEXT_SERVER_1
  .byte 'Server name:'
  .byte  $9b,$9b,' '
  .byte 'Example: www.chat64.nl'  
  .endl

  .local TEXT_ACCOUNT_SETUP
  .byte 'ACCOUNT SETUP'
  .endl
  
  .local TEXT_ACCOUNT_1
  .byte 'MAC Address:'
  .byte  $9b,$9b,' '
  .byte 'Registration ID:'
  .byte  $9b,$9b,' '
  .byte 'Nick Name:'
  .endl
  
  .local TEXT_SAVE_SETTINGS
  .byte 'Saving Settings, please wait..     '
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
  .byte '[ESC] Exit Menu'
  .endl
  .local MLINE_MAIN8
  .byte '[< >] Change Color'
  .endl
  
  .local TEXT_HELP_SCREEN
  .byte 'HELP',$9b,$9b
  .byte 'Use Ctrl-Return to send your message immediately',$9b
  .byte 'Use SELECT to switch between public and private messaging. To send a private message to someone:'
  .byte ' start your message with @username'

  .endl
  
  .local TEXT_HELP_SCREEN2
  .byte 'To talk to Eliza (our AI Chatbot), switch to private messaging and start your message with'
  .endl
  
  .local TEXT_ABOUT_SCREEN
  .byte 'ABOUT CHAT64',$9b,$9b
  .byte 'Initially developed by Bart as a proof  of concept on Commodore 64',$9B,$9B
  .byte 'A new version of CHAT64 is now availableto everyone.',$9B
  .byte 'We proudly bring you Chat64 on Atari XL',$9B,$9B
  .endl  
  .local TEXT_ABOUT_SCREEN2
  .byte 'Made by Bart Venneker and Theo van den  Belt in 2024',$9B,$9B
  .byte 'Hardware, software and manuals are available on Github',$9B,$9B
  .byte 'github.com/bvenneker/Chat64-Atari800'
  .endl  
  
  .local TEXT_MADE_BY 
  .byte 'Made by Bart and Theo in 2024'  
  .endl
  
   .local TEXT_FOR_ATARI_800XL
   .byte 'For Atari 800XL'
   .endl
   
  .local DIVIDER_LINE
  :40 .byte 18 ; 40 x byte 18
  .endl
  
  .local ERROR_PUB_PRIV //1234567890123456789012345678901234567890
  .byte  '    Don''t send private messages from ',31,31,31,29
  .byte  '           the public screen'
  .endl
  
  .local ERROR_PRIV //1234567890123456789012345678901234567890
  .byte             ' Private messages should start with:',155
  .byte             '         @[username]'
  .endl
  
  
  .local startR 
     .byte 0,40,80
  .endl
  
  .local text_reg_u
  .byte 'Error: Unregistered Cartridge'
  .endl
  
  .local text_reg_n
  .byte 'Error: Nick Name is Taken!'
  .endl
  
  .local text_reg_r
  .byte 'Registration was successful'
  .endl
  
  .local text_reg_x
  .byte 'Error: Server unreachable'
  .endl
  
  .local TEXT_UPDATE_TITLE
  .byte 'UPDATE AVAILABLE'
  .endl
  
  .local TEXT_NEW_VERSIONS
  .byte 'There is a new version available',155
  .byte 'Do you want to upgrade? (Y/N)'

  .endl
  .local TEXT_NEW_ROM
  .byte 'New ROM: '
  .endl

  .local TEXT_NEW_ESP
  .byte 'New ESP: '
  .endl

// ----------------------------------------------------------------
// Variables
// ----------------------------------------------------------------
inhsend  .byte 0
doswitch .byte 0
restoreMessageLines .byte 0
tempt    .byte 0
blink    .byte 0,0
blink2   .byte 0,0
ddlist   .word 0,0
DELAY    .byte 0,0    
z_as     .byte 0,0
cursorphase  .byte 0,0
temppos  .byte 0,0   
MENU_ID .byte 0
SCREEN_ID .byte 0
FIELD_MAX .byte 0
FIELD_MIN .byte 0
VICEMODE .byte 0
CONFIG_STATUS .byte 0,128
SWVERSION .byte '9.99',128
SERVERNAME .byte 'www.chat64.nl          ',128
TEMPBYTE .byte 0
WIFISTATUS .byte 0
p_cursor_x .byte 0
p_cursor_y .byte 0
MCURSORX .byte 0
MCURSORY .byte 0
STARTLINE4 .byte 0,0   // start address when message is 4 lines
STARTLINE3 .byte 0,0   // start address when message is 3 lines
STARTLINE2 .byte 0,0   // start address when message is 2 lines
STARTLINE1 .byte 0,0   // start address when message is 1 lines
PMUSER   .byte 32,37,'liza',0,128,128,128,128,128,128,128,128,128,128,128,128
RXBUFFER :150 .byte 128        
SPLITBUFFER :40 .byte 128 

  
// -----------------------------------
// Print the RX Buffer on screen
// line = 0 - 23
// column = 0,39
// -----------------------------------
.macro displayBuffer buffer,line,column,offset
  mva :line ROWCRS 
  mva :column COLCRS  
  mva :offset CHARINDEX
  lda #<(:buffer) 
  sta TEXTPOINTER
  lda #>(:buffer)
  sta TEXTPOINTER+1
  jsr displayBufferk  
.endm  


// -----------------------------------
// text = the text
// line = 0 - 23
// column = 0,39
// -----------------------------------
.macro displayText text,line,column
  mva :line ROWCRS
  mva :column COLCRS
  mva #0 CHARINDEX
  lda #.len :text
  sta TEXTLEN
  lda #<(:text) 
  sta TEXTPOINTER
  lda #>(:text)
  sta TEXTPOINTER+1
  jsr displayTextk  
.endm  



.align $400           
SCREEN_PUBL_BACKUP:
  
  org SCREEN_PUBL_BACKUP + 1024
SCREEN_PRIV_BACKUP:
 
  org SCREEN_PRIV_BACKUP + 1024
MESSAGE_LINES_BACKUP:
   
        
 run init
  
