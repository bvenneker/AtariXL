// special characters: https://www.youtube.com/watch?v=fOrMwNBoC7E&list=PLmzSn5Wy9uF8nTsZBtdk1yHzFI5JXoUJT&index=7

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
CHARSET   = $2F4
ROM_CHARS = $E000 
POKEY  = $D200
 
color2 = $2c6
color4 = $2c8

input_fld = $15        // input field address $15 + $16
temp_i = $17 
temp_o = $19
input_fld_len = $1A    // length of the input field
text_color = $36
character = $3f 
textPointer = $40      // $40, $41 are a pointer. 
textlen = $83
rowcrs = $54          ; cursor row 
colcrs = $55          ; cursor colm
inputfield = $43      ; 43 and 44 hold a pointer to the main input field 
start_color = $45
splitIndex = $46

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
//  sta color4
//  sta color2
  sta character  
  sta MENU_ID
  sta SCREEN_ID
  lda sm_prt
  sta input_fld
  lda sm_prt+1
  sta input_fld+1

main 
  jsr startScreen
  mva #1 curinh
  jsr beep1
  lda #$7D       ; load clear screen command
  jsr writeText  ; print it to screen
  jsr are_we_in_the_matrix
  jsr get_status 
  jmp main_chat_screen
// ----------------------------------------------------------------------
// toggle between private and public messaging
// ----------------------------------------------------------------------
toggle_screens:
  jsr backup_screen                // make a backup of the current screen
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
  displayText divider_line, #0,#0    ; draw the divider line
  displayText text_F5_toggle, #1,#0    ; draw the menu title
  displayText divider_line, #2,#0    ; draw the divider line
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
 
  displayText text_no_cartridge, #5,#6
  
mc_not_vice

  mva #255 $2fc                       ; clear keyboard buffer
  mva #0 colcrs                       ; set cursor row position to zero  
  displayText divider_line, #20,#0    ; draw the divider line
  
  jsr clearInputLines
chat_key_input
  mva #0 curinh     // show the cursor
  lda #32
  jsr writeText 
  lda #$1E                                    // step cursor left
  jsr writeText 
  jsr text_input    // jump to the text input routine


// ----------------------------------------------------------------------
// shift screen up
// ----------------------------------------------------------------------
shift_screen_up:   
  lda SCREEN_ID            // see on what screen we are
  cmp #3                   // in private screen, we must ignore the first 3 lines
  bne shift_public 
  ldx #16
  mwa sm_prt temp_i        // temp_i points to line 0  
  mwa sm_prt temp_o
  lda temp_i
  adc #120
  sta temp_i               // temp_i now points to line 3
  lda temp_o
  adc #160
  sta temp_o               // temp_o points to line 4
  jmp sh_up_d              // start shifting! 
  
shift_public    
  ldx #19                  // in public chat we shift from line 0
  mwa sm_prt temp_i        // temp_i points to line 0
  mwa sm_prt temp_o
shiftLoop
  clc
  lda temp_o               //
  adc #40                  // add 40 to go to the next line
  sta temp_o               // textPointer points to line 1
  bcs up_hb                // we there was an overflow, increase the highbyte also
  jmp sh_up_d
up_hb
  inc temp_o+1             // increase highbyte
sh_up_d   
  jsr shiftLine
  mwa temp_o temp_i
  dex    
  bne shiftLoop
  rts


shiftLine:             // this routine shifts one line up
  ldy #0               // temp_o is source
shiftLine_loop         // temp_i is destination
  lda (temp_o),y  
  sta (temp_i),y
  iny
  cpy #40
  bne shiftLine_loop
  rts

// ----------------------------------------------------------------------
// backup and restore screens
// ----------------------------------------------------------------------
backup_screen:
  lda SCREEN_ID
  cmp #3
  beq backup_priv_screen
  jmp backup_publ_screen
  rts

backup_priv_screen
  mva colcrs p_cursor_x
  mva rowcrs p_cursor_y
  mva #1 HAVE_P_BACKUP
  mva #<SCREEN_PRIV_BACKUP temp_i
  mva #>SCREEN_PRIV_BACKUP temp_i+1
  jsr backup_the_screen 
  rts
  
backup_publ_screen
  mva colcrs m_cursor_x
  mva rowcrs m_cursor_y
  mva #1 HAVE_M_BACKUP  
  mva #<SCREEN_PUBL_BACKUP temp_i
  mva #>SCREEN_PUBL_BACKUP temp_i+1
  jsr backup_the_screen 
  rts
  
backup_the_screen
  mwa sm_prt textPointer    
  ldy #0  
backuploop1
  lda (textPointer),y
  sta (temp_i),y
  iny
  cpy #0
  bne backuploop1
   
  inc textPointer+1
  inc temp_i+1
backuploop2
  lda (textPointer),y
  sta (temp_i),y
  iny
  cpy #0
  bne backuploop2
  
  inc textPointer+1
  inc temp_i+1
backuploop3
  lda (textPointer),y
  sta (temp_i),y
  iny
  cpy #0
  bne backuploop3
  
  inc textPointer+1
  inc temp_i+1
backuploop4
  lda (textPointer),y
  sta (temp_i),y
  iny
  cpy #192
  bne backuploop4
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
  jmp p_chat
do_p_restore
  mva #<SCREEN_PRIV_BACKUP temp_i
  mva #>SCREEN_PRIV_BACKUP temp_i+1
  jsr restore_the_screen 
  mva p_cursor_x colcrs    // restore the cursor position
  mva p_cursor_y rowcrs    // restore the cursor position
  jmp chat_key_input
  
restore_publ_screen
  lda HAVE_M_BACKUP
  cmp #1
  beq do_M_restore
  jmp m_chat
do_M_restore
  mva #<SCREEN_PUBL_BACKUP temp_i
  mva #>SCREEN_PUBL_BACKUP temp_i+1
  jsr restore_the_screen 
  mva m_cursor_x colcrs   // restore the cursor position
  mva m_cursor_y rowcrs   // restore the cursor position
  jmp chat_key_input

restore_the_screen
  mwa sm_prt textPointer
  ldy #0  
restoreloop1
  lda (temp_i),y
  sta (textPointer),y
  iny
  cpy #0
  bne restoreloop1
  
  inc textPointer+1
  inc temp_i+1
restoreloop2
  lda (temp_i),y
  sta (textPointer),y
  iny
  cpy #0
  bne restoreloop2

  inc textPointer+1
  inc temp_i+1
restoreloop3
  lda (temp_i),y
  sta (textPointer),y
  iny
  cpy #0
  bne restoreloop3

  inc textPointer+1
  inc temp_i+1
restoreloop4
  lda (temp_i),y
  sta (textPointer),y
  iny
  cpy #192
  bne restoreloop4
  
  rts
// ----------------------------------------------------------------------
// Get the config status and the ESP Version
// ----------------------------------------------------------------------
get_status: 
  lda VICEMODE
  cmp #1
  beq exit_gs

  lda #236                                      // ask Cartridge for the wifi credentials
  jsr send_start_byte_ff                        // the RXBUFFER now contains Configured<byte 129>Server<byte 129>SWVersion<byte 128>
  
  lda #1                                        // set the variables up for the splitbuffer command
  sta splitIndex                                // we need the first element, so store #1 in splitIndex
  jsr splitRXbuffer                             // and call spilt buffer
  lda SPLITBUFFER                               // SPLITBUFFER NOW CONTAINS THE CONFIG_STATUS
  sta CONFIG_STATUS                             // this is only one character, store it in config_status   
                                                //
  lda #2                                        // we need the second element out of the rxbuffer   
  sta splitIndex                                // so put #2 in splitIndex and jump to split buffer   
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
  sta splitIndex                                // so put #3 in splitIndex and jump to split buffer    
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
  mva #10 MENU_ID
  jsr clear_keyboard_and_screen
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
  displayBuffer SWVERSION,#23,#24
  displayBuffer version,#23,#14
main_menu_key_input:
  jsr getKey
  cmp #255
  beq main_menu_key_input
  
  cmp #$37                            // key 7 is pressed(exit)
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
  bne no_match
  jmp help_screen
  
no_match  
  mva #255 $2fc                       // clear keyboard buffer 
  jmp main_menu_key_input
  
exit_main_menu
  lda #0
  sta MENU_ID
  jmp restore_screen
  



// ----------------------------------------------------------------------
// Clear the keyboardbuffer and also clear the screen
// ----------------------------------------------------------------------
clear_keyboard_and_screen
  mva #255 $2fc                               // clear keyboard buffer
  lda #$7D                                    // load clear screen command
  jsr writeText                               // print it to screen
  rts

// ----------------------------------------------------------------------
// About screen
// ----------------------------------------------------------------------
about_screen:
  mva #15 MENU_ID
  jsr clear_keyboard_and_screen
  displayText divider_line, #0,#0             // draw the divider line
  displayText divider_line, #2,#0             // draw the divider line
  displayText text_about_screen, #1,#15       // draw the menu title and text
  displayText text_about_screen2, #10,#0       // draw the more text
  
  displayText divider_line, #22,#0            // draw the divider line
  displayText MLINE_MAIN7, #23,#1             // draw the menu on the bottom line
  jmp help_get_key_input                      // wait for user to press 7 to exit
// ----------------------------------------------------------------------
// Help screen
// ----------------------------------------------------------------------
help_screen:                                  //
  mva #16 MENU_ID                             //
  jsr clear_keyboard_and_screen               //
  displayText divider_line, #0,#0             // draw the divider line
  displayText text_help_screen, #1,#15        // draw the menu title and text
  displayText text_help_screen2, #10,#0        // draw more text
  displayText divider_line, #2,#0             // draw the divider line
  displayText divider_line, #22,#0            // draw the divider line
  displayText MLINE_MAIN7, #23,#1             // draw the menu on the bottom line
                                              //
help_get_key_input                            //
  jsr getKey                                  // wait for a key
  cmp #251
  beq hlp_exit
  cmp #$37                                    // key 7 is pressed
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
  mva #234 TEMPI
ul_start
  jsr clear_keyboard_and_screen
  displayText divider_line, #0,#0             // draw the divider line
  displayText text_user_list, #1,#1          // draw the menu title
  displayText divider_line, #2,#0             // draw the divider line
  displayText divider_line, #22,#0            // draw the divider line
  displayText text_user_list_foot, #23,#1     // draw the menu on the bottom line
  lda VICEMODE
  cmp #1
  bne ul_novice 
  jmp ul_vice 

ul_novice
  lda TEMPI
  jsr send_start_byte_ff                      // RXBUFFER now contains the first group of users, 20
  displayBuffer RXBUFFER,#4 ,#2

  lda #233
  jsr send_start_byte_ff                      // RXBUFFER now contains the second group of users, 40
  displayBuffer RXBUFFER,#9 ,#2

  lda #233
  jsr send_start_byte_ff                      // RXBUFFER now contains the second group of users, 40
  displayBuffer RXBUFFER,#14 ,#2

  displayText divider_line, #22,#0            // draw the divider line
  displayText text_user_list_foot, #23,#1     // draw the menu on the bottom line
  
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
  mva #233 TEMPI
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
  displayText divider_line, #0,#0             // draw the divider line
  displayText text_account_setup, #1,#15      // draw the menu title
  displayText divider_line, #2,#0             // draw the divider line
  displayText text_account_1, #5,#1
  displayText divider_line, #11,#0            // draw the divider line
  displayText text_option_exit, #15,#3
  displayText divider_line, #22,#0            // draw the divider line
  
  lda VICEMODE
  cmp #1
  bne acc_novice     
  jmp acc_vice
acc_novice
  lda #243                                    // ask for the mac address, registration id, nickname and regstatus
  jsr send_start_byte_ff                      // the RXBUFFER now contains: macaddress(129)regID(129)NickName(129)regStatus(128) 
  mva #1 splitIndex                           //
  jsr splitRXbuffer                           //
  displayBuffer  SPLITBUFFER,#5 ,#14          // Display the buffers on screen (Mac address)
  mva #2 splitIndex                           //
  jsr splitRXbuffer                           //
  displayBuffer  SPLITBUFFER,#7 ,#18          // Display the buffers on screen (registration id)
  mva #3 splitIndex                           //
  jsr splitRXbuffer                           //
  displayBuffer  SPLITBUFFER,#9 ,#12          // Display the buffers on screen (Nick Name)
  mva #4 splitIndex                           //
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
  mva #0 curinh                               // Show the cursor 
  mva #7 rowcrs                               // Put the cursor in the registration id field
  mva #17 colcrs                              //
  mva #19 FIELD_MIN                           //
  mva #35 FIELD_MAX                           //
  lda #32                                     //
  jsr writeText                               //
  jsr text_input                              //

  mva #255 $2fc                               // Clear keyboard buffer
  mva #9 rowcrs                               // Put the cursor in the Nick Name field
  mva #11 colcrs                              //
  mva #13 FIELD_MIN                           //
  mva #21 FIELD_MAX                           //
  lda #32                                     //
  jsr writeText                               //
  jsr text_input                              //

  mva #1 curinh                               // Hide the cursor
  lda #$1E                                    // step cursor left
  jsr writeText                               // now it becomes invisible   
  
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
  displayText text_save_settings, #23, #3
  jsr wait_for_RTR
  lda #240
  sta $D502
  mva #7 temp_i                               // Read regid and send it to cartridge
  mva #18 temp_i+1
  mva #38 input_fld_len
  jsr read_field

  mva #9 temp_i                               // Read nickname and send it to cartridge
  mva #12 temp_i+1
  mva #38 input_fld_len
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
  displayText divider_line, #0,#0             // draw the divider line
  displayText text_server_setup, #1,#15       // draw the menu title
  displayText divider_line, #2,#0             // draw the divider line
  displayText text_server_1, #5,#1
  displayText divider_line, #10,#0            // draw the divider line
  displayText text_option_exit, #15,#3
  displayText divider_line, #22,#0            // draw the divider line
  displayBuffer SERVERNAME,#5,#14
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
  jsr send_start_byte_ff
  displayBuffer  RXBUFFER,#23 ,#3             // the RX buffer now contains the server status
  
svr_vice 
svr_input_fields                              //
  mva #0 curinh                               // Show the cursor 
  mva #5 rowcrs                               // Put the cursor in the Server Name field
  mva #13 colcrs                              //
  mva #15 FIELD_MIN                           //
  mva #38 FIELD_MAX                           //
  lda #32
  jsr writeText
  jsr text_input
  mva #1 curinh                               // Hide the cursor
  lda #$1E                                    // step cursor left
  jsr writeText                               // now it becomes invisible   

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
  displayText text_save_settings, #23, #3
  jsr wait_for_RTR
  lda #246
  sta $D502
  mva #5 temp_i                               // Read servername and send it to cartridge
  mva #14 temp_i+1
  mva #25 input_fld_len
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
  displayText divider_line, #0,#0             // draw the divider line
  displayText text_wifi_setup, #1,#15         // draw the menu title
  displayText divider_line, #2,#0             // draw the divider line
  displayText text_wifi_1, #5,#3
  displayText divider_line, #11,#0            // draw the divider line
  displayText text_option_exit, #15,#3
  displayText divider_line, #22,#0            // draw the divider line
  lda VICEMODE
  cmp #1
  beq wf_vice  
  
wifi_get_cred
  lda #248                                    // ask Cartridge for the wifi credentials
  jsr send_start_byte_ff
  displayBuffer  RXBUFFER,#23 ,#3             // the RX buffer now contains the wifi status
  lda #251                                    // ask Cartridge for the wifi credentials
  jsr send_start_byte_ff                      // the RXBUFFER now contains ssid[32]password[32]timeoffset[128]
  mva #1 splitIndex                           //
  jsr splitRXbuffer                           //
  displayBuffer  SPLITBUFFER,#5 ,#9           // Display the buffers on screen (SSID name)
  mva #2 splitIndex
  jsr splitRXbuffer
  displayBuffer  SPLITBUFFER,#7 ,#13          // Display the buffers on screen (SSID name)
  mva #3 splitIndex
  jsr splitRXbuffer
  displayBuffer  SPLITBUFFER,#9 ,#25          // Display the buffers on screen (SSID name)
                                              //
wf_vice                                       //
wifi_input_fields                             //
  mva #0 curinh                               // Show the cursor 
  mva #5 rowcrs                               // Put the cursor in the SSID field
  mva #8 colcrs                               //
  mva #10 FIELD_MIN                           //
  mva #35 FIELD_MAX                           //
  lda #32
  jsr writeText
  jsr text_input
  mva #1 curinh                               // Hide the cursor
  lda #$1E                                    // step cursor left
  jsr writeText                               // now it becomes invisible  
  
  mva #255 $2fc                               // Clear keyboard buffer
  mva #0 curinh                               // Show the cursor 
  mva #7 rowcrs                               // Put the cursor in the password field
  mva #12 colcrs 
  mva #14 FIELD_MIN
  mva #35 FIELD_MAX
  lda #32
  jsr writeText
  jsr text_input
  mva #1 curinh                               // hide the cursor
  lda #$1E
  jsr writeText
  
  mva #255 $2fc                               // clear keyboard buffer
  mva #0 curinh                               // show the cursor 
  mva #9 rowcrs                               // put the cursor in the time-offset field
  mva #24 colcrs 
  mva #26 FIELD_MIN
  mva #32 FIELD_MAX
  lda #32
  jsr writeText
  jsr text_input
  mva #1 curinh                               // hide the cursor
  lda #$1E
  jsr writeText

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
  displayText text_save_settings, #23, #3
  jsr wait_for_RTR
  lda #252
  sta $D502
  mva #5 temp_i                               // Read SSID and send it to cartridge
  mva #9 temp_i+1                             // temp_i (2 bytes) holds the row and column of the field
  mva #27 input_fld_len                       // input_fld_len is the length of the field
  jsr read_field                              // jump to the read_field sub routine
  mva #7 temp_i                               // Read password and send it to cartridge
  mva #13 temp_i+1
  mva #23 input_fld_len
  jsr read_field
  mva #9 temp_i                               // Read password and send it to cartridge
  mva #25 temp_i+1
  mva #10 input_fld_len
  jsr read_field

  mva #255 DELAY
  jsr jdelay
  jsr jdelay
  jsr jdelay
  jsr jdelay
  jmp wifi_get_cred

// ---------------------------------------------------------------------
// read a field and send it to the cartridge
// input row and column in temp_i and temp_i+1
// ---------------------------------------------------------------------
read_field:
  lda sm_prt          // reset the input field pointer
  sta input_fld       // reset the input field pointer
  lda sm_prt+1        // reset the input field pointer
  sta input_fld+1     // reset the input field pointer
  jsr open_field      // get a pointer to the start adres of the field
  ldy #0
loopr                 //
  cpy input_fld_len   // compare y (our index) with the field length
  beq loopr_exit      // if we reach the end of the field, exit
  lda (input_fld),y   // read the field with index y
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
// input row and column in temp_i and temp_i+1               
// this procedure creates a pointer to the field in input_fld (2 bytes)               ;
// ---------------------------------------------------------------------
open_field:   
  ldx temp_i                   // get the row (temp_i holds the rown number)
sm_lineadd                     // sm_prt is the start of screen memory
  clc                          // clear carry
  lda input_fld                // start at the start of screen memory
  adc #40                      // add 40 chars (one row) 
  sta input_fld                // store input_fld (this is the low byte of the pointer)
  bcc sm_ld_done               // if carry is set (overflow), we need to increase the high byte
  inc input_fld+1              // increase the high byte if needed
sm_ld_done                     // one row added, done
  dex                          // decrease x
  bne sm_lineadd               // repeat the above if x is not zero
                               // now we are on the right row, next skip to the right column
  ldx temp_i+1                 // get the column 
sm_rowadd                      //
  clc                          // 
  lda input_fld                //
  adc #1                       // add one..
  sta input_fld                // if we overflow, increase the high byte also
  bcc sm_rd_done               //
  inc input_fld+1              //
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
  lda version,x                                   // load a byte from the version text with index x
  
  sta $D502                                       // send it to IO1
  cmp #128                                        // if the last byte was 128, the buffer is finished
  beq check_matrix                                // exit in that case
  inx                                             // increase the x index
  jmp sendversion                                 // jump back to send the next byte

check_matrix                                      // 
  lda #100                                        // Delay 100... hamsters
  sta DELAY                                       // Store 100 in the DELAY variable
  jsr jdelay                                      // and call the delay subroutine
  jsr wait_for_RTS                                                // 
  lda $D502                                       // read from cartridge
  cmp #128                                        // 
                                                  // 
  beq exit_sim_check                              // if vice mode, we do not try to communicate with the
  lda #1                                          // cartridge because it will result in error
  sta VICEMODE                                    //  
                                                  //
exit_sim_check                                    // 
  lda #100                                        // Delay 100... hamsters
  sta DELAY                                       // Store 100 in the DELAY variable
  jsr jdelay                                      // and call the delay subroutine
  rts    
    
// ---------------------------------------------------------------------
// Send a command byte to the cartridge and wait for response;
// command in b                          ;
// ---------------------------------------------------------------------
send_start_byte_ff:                     //
  jsr wait_for_RTR
  sta $D502                             // send the command byte
  ldx #0
ff_response_loop                        // now wait for a response
  jsr wait_for_RTS
  lda $D502
  sta RXBUFFER,x
  cmp #128
  beq ff_end_buffer
  inx
  jmp ff_response_loop
  
ff_end_buffer
  inx
  lda #128
  sta RXBUFFER,x
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
  cmp #128
  bcc check_exit
  jsr beep1  
  lda #0
  sta $14
  ldy #0
  sta (sm_prt),y
  
  lda #254
  jsr send_start_byte_ff  // RX buffer now contains a message or 128
  lda RXBUFFER
  cmp #128
  beq check_exit
  jmp display_message
  
check_exit  
  rts

LINEC .byte 0
display_message:
  // the RXBUFFER contains a message.
  // the first
  ldx #0
make_room_loop
  lda RXBUFFER,x
  cmp #1
  bne do_display
  jsr shift_screen_up
  inx
  jmp make_room_loop
  
do_display
  displayBuffer RXBUFFER,#19,#0
  
  rts
// ----------------------------------------------------------------------
// procedure for text input
// ----------------------------------------------------------------------
text_input:
  mva #0 curinh                        // show the cursor 
key_loop
  jsr check_for_messages
  jsr getKey
  cmp #255
  beq key_loop

cpselect
  cmp #252
  bne cpoption
  mva #255 $2fc                       // clear keyboard buffer 
  jmp toggle_screens
  
cpoption
  cmp #251
  bne cpdelete
  mva #255 $2fc                       // clear keyboard buffer   
  jmp main_menu
  
cpdelete  
  cmp #8 ; delete
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
  lda rowcrs
  cmp #23
  bne rp
  lda colcrs
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
  jsr writeText
out_exit
  mva #255 $2fc                      // clear keyboard buffer 
  jmp key_loop
in_field  
  lda colcrs
  cmp FIELD_MAX
  bcc out_ok
  pla
  jsr writeText
  lda #$1E
  jsr writeText
  jmp out_exit  

handle_delete
  lda MENU_ID
  cmp #10
  bcs del_in_field
hd_ok  
  lda rowcrs
  cmp #21
  bne delok
  lda colcrs
  cmp #0
  bne delok  
  mva #255 $2fc                       // clear keyboard buffer 
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

del_in_field         
  lda colcrs         
  cmp FIELD_MIN
  bcc delexit
  lda #$7E
  jsr writeText
  jmp delexit
  
         
handle_return
  lda MENU_ID
  cmp #10
  bcs exit_on_return 
  lda rowcrs                          // ignore this key if we are on the last line
  cmp #23
  beq up_exit 
  lda #$9b
  jmp chrout
exit_on_return 
  rts 

handle_up
  lda MENU_ID
  cmp #10
  bcs up_exit
  lda rowcrs                          // ignore this key if we are on the first line
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
  lda rowcrs                          // ignore this key if we are on the last line
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
  lda colcrs
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
  lda colcrs  
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
    pha
    txa
    pha
    tya
    pha
	
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
    pla
	tay
	pla
	tax
	pla
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


getKey:   
  jsr readRTS                           // check for incomming data or reset request   
  lda $D01F                             // is one of the console keys pressed?
  and #7
  cmp #6
  beq prSTART
  cmp #5
  beq prSELECT
  cmp #3
  beq prOPTION
  
  lda $02DC                             // is the HELP key pressed ?
  and #1
  cmp #1
  beq prHELP
  
  lda $2FC                              // is there a key in the keyboard buffer?
  cmp #255                              // 255 means no key
  beq exit_getkey                       // exit if no key

keyConvert                              // convert the key code to ascii
  tay                                   //
  lda kb2asci,y                         //
exit_getkey                             //
  rts                                   //
  
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
    dec splitIndex                               // decrease $02. This address holds a number that indicates   
    lda splitIndex                               // which word we need from the RXBUFFER   
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
  displayText text_forAtari800xl, #14,#12
  displayText text_madeBy, #16,#5
  mwa CHARSET temppos                  // make a backup of the pointer to the character set
  mva #1 curinh
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
  mva  custom_chars,x  SCREEN_PUBL_BACKUP,x
  inx
  cpx #128
  bne cust_loop
  mva #>SCREEN_PUBL_BACKUP CHARSET    // set the char pointer to the new location
  lda sm_prt                          // create a pointer to the start of the screen
  sta temp_i                          // and to the end of the screen
  lda sm_prt+1
  sta temp_i+1
  inc temp_i+1
  inc temp_i+1
  inc temp_i+1  
  lda #16
  sta temp_i
  
  ldy #239                            // draw the main strips 
ss2
  lda #8 //#85 
  sta (temp_i),y
  lda #9 
  sta (sm_prt),y
  dey
  cpy #255
  bne ss2

  lda sm_prt               // make a new pointer that points to the 
  sta temp_i               // start line of the big letters
  sta temp_i
  lda sm_prt+1
  sta temp_i+1
  inc temp_i+1
  lda #128
  sta temp_i
   
  ldy #0                    // draw the big letters
ss_big_letters
  lda sc_big_text,y
  cmp #255
  beq stars 
  sta (temp_i),y
  iny
  jmp ss_big_letters
  
stars                         // draw the stars
  ldx #0
  inc temp_i+1
  inc temp_i+1
  lda #56
  sta temp_i
  sta textPointer             // we need this later for animating the stars
  sta TEMPB 
  mva temp_i+1 textPointer+1  // we need this later for animating the stars
  
  lda #15
stars_lp
  ldy sc_stars1,x
  cpy #255
  beq wkey2
  sta (sm_prt),y
  ldy sc_stars2,x  
  sta (temp_i),y 
  inx
  jmp stars_lp

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
  mwa sm_prt temp_i
  jsr shift_line_to_left
  lda temp_i
  adc #39
  sta temp_i
  jsr shift_line_to_left
  lda temp_i
  adc #39
  sta temp_i
  jsr shift_line_to_left
  lda temp_i
  adc #39
  sta temp_i
  jsr shift_line_to_left
  lda temp_i
  adc #39
  sta temp_i
  jsr shift_line_to_left
  
  lda TEMPB
  sta textPointer
  jsr shift_line_to_right  
  lda textPointer
  adc #39
  sta textPointer
  jsr shift_line_to_right
  lda textPointer
  adc #39
  sta textPointer
  jsr shift_line_to_right
  lda textPointer
  adc #39
  sta textPointer
  jsr shift_line_to_right
  lda textPointer
  adc #39
  sta textPointer
  jsr shift_line_to_right
  
  lda #40
  sta DELAY
  jsr jdelay
  pla
  tax
  pla
  tay
  rts
  
//=========================================================================================================
//  SUB ROUTINE TO SHIFT THE COLORS IN THE STAR LINES TO LEFT
//=========================================================================================================
shift_line_to_left:                               // a pointer to the screen memory address where the line we want to shift starts
                                                  // is stored in zero page address temp_i, temp_i+1
    ldy #0                                        // before we start the loop we need to store the very first character
    lda (temp_i),y                                // so load the character on the first position of the line
    pha                                           // push it to the stack, for later use
    iny                                           // y is our index for the loop, it starts at 1 this time.
                                                  // 
shift_l_loop:                                     // start the loop
                                                  // the loop works like this:
    lda (temp_i),y                                // 1) load the character at postion y in the accumulator
    dey                                           // 2) decrease y
    sta (temp_i),y                                // 3) store the char on position y. So now the character has shifted left
    cpy #39                                       // 4) see if we are at the end of the line
    beq shift_l_exit                              // and exit if we are
    iny                                           // 5) if not, increase y
    iny                                           // twice (because we decreased it in step 2
    jmp shift_l_loop                              // 6) back to step 1
                                                  // 
shift_l_exit                                      // here we exit the loop
                                                  // 
    pla                                           // 7) we need to store the very first character (the most left)
    sta (temp_i),y                                // on the most right position, so the line goes round and round
    rts                                           // now this line have shifted 1 position to the left
                                                  // 
//=========================================================================================================
//  SUB ROUTINE TO SHIFT THE STAR LINES TO RIGHT
//=========================================================================================================
TempCharR .byte 0
TEMPB .byte 0
shift_line_to_right:                              // a pointer to the memory address where the line we want to shift starts
                                                  // is stored in zero page address textPointer (2 bytes)
                                                  // shifting a line to the right is a bit more complicated as to shifting to the left.
                                                  // to better explain we have this line as example ABCDEFGH
                                                  // 
    ldy #0                                        // start at postion zero (A in our line)
    lda (textPointer),y                           // read the characters color (the zero page address $f7,$f8
    sta temp_o                                    // store it temporary in memory address 'textPointer', so now A is stored in 'textPointer'
                                                  // 
shift_r_loop:                                     // 
    iny                                           // increase our index, y
    lda (textPointer),y                           // read the character at the next postion (B in our line of data)
    sta TempCharR                                 // store color B temporary in memory address 'TempCharR', so now B is stored in 'TempCharR'
    lda temp_o                                    // now load 'textPointer' (that contains A) back into the accumulator
    sta (textPointer),y                           // and store it where B was. The Data line looks like this now AACDEFGH (A has shifted to the right and B is in temporary storage at $ff)
    iny                                           // increase y again
    lda (textPointer),y                           // Read the color on the next position (C in our line of data)
    sta temp_o                                    // Store it it temporary in memory address textPointer, so now B is stored in textPointer
    lda TempCharR                                 // now load TempCharR (that contains B) back into the accumulator
    sta (textPointer),y                           // and put that where C was. The data line now look like this: AABDEFGH (A and B have shifted and C is in temporary storage at $fe)
    cpy #38                                       // see if we are at the end of the line 
    bne shift_r_loop                              // if not, jump back to the start of the loop
                                                  // after the loop we have processed 39 positions, but the line is 40 long
                                                  // At this point G is in memory storage textPointer and H is in storage at TempCharR
    iny                                           // increase y
    lda temp_o                                    // load G
    sta (textPointer),y                           // put it in position H
                                                  // 
                                                  // NOW the data looks like this: AABCDEFG (all characters have shifted except for H which is in storeage at textPointer)
    ldy #0                                        // set the index back to zero
    lda TempCharR                                 // load TempCharR (H) into the accumulator
    sta (textPointer),y                           // and store it at the first position.
    rts                                           // Now our line looks like this: HABCDEFG all characters have shifted to the right one position.
                                                  // 
// ----------------------------------------------------------------------
// displayBuffer, used in macro displayRXBuffer
// ----------------------------------------------------------------------
displayBufferk:
  mva #1 curinh  
db_next_char  
  ldy character
  lda (textPointer),y  
  cmp #128
  beq db_exit
  cmp #1
  bne write_it
  lda #$1C // replace 1 with the line up command
write_it
  jsr writeText
  inc character
  jmp db_next_char
db_exit
  rts

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

  
// ----------------------------------------------------------------
// Constants
// ----------------------------------------------------------------
version .byte '3.77',128
version_date .byte '10/2024',128

HAVE_M_BACKUP:                .byte 0             // 
HAVE_P_BACKUP:                .byte 0             //
HAVE_ML_BACKUP:               .byte 0             //

// data for big letters on the start screen
sc_big_text:                                 
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
	   
custom_chars:                          // custom chars for big letters and stars            
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
  
sc_stars1 .byte 35,74,75,76,115,52,91,92,93,132,105,144,145,146,185,82,121,122,123,162,255
sc_stars2 .byte 6,45,46,47,86, 25,65,64,66,105, 93,132,133,134,173, 76,115,116,117,156,255  

  .local text_user_list
  .byte 'USER LIST, inverted users are online'
  .endl
  .local text_user_list_foot
  .byte '[p] previous  [n] next  [OPT] Exit'
  .endl
  
  .local text_F5_toggle
  .byte 'Private Messaging      [SEL] Main Chat'
  .endl
  
  .local text_no_cartridge
  .byte 'Cartridge Not Installed!'
  .endl
  .local text_wifi_setup
  .byte 'WIFI SETUP'
  .endl
  
  .local text_wifi_1
  .byte 'SSID:'
  .byte  $9b,$9b,'   '
  .byte 'PASSWORD:'
  .byte  $9b,$9b,'   '
  .byte 'Time Offset from GMT: +0'
  .endl

  .local text_option_exit  
  .byte '[OPTION] Exit'
  .endl  

  .local text_start_save_settings
  .byte '[START]  Save Settings'
  .endl  
  
  .local text_main_menu
  .byte 'MAIN MENU'
  .endl
  
  .local text_server_setup
  .byte 'SERVER SETUP'
  .endl
  
  .local text_server_1
  .byte 'Server name:'
  .byte  $9b,$9b,' '
  .byte 'Example: www.chat64.nl'  
  .endl

  .local text_account_setup
  .byte 'ACCOUNT SETUP'
  .endl
  
  .local text_account_1
  .byte 'MAC Address:'
  .byte  $9b,$9b,' '
  .byte 'Registration ID:'
  .byte  $9b,$9b,' '
  .byte 'Nick Name:'
  .endl
  
  .local version_line
  .byte ' Version  ROM x.xx  ESP x.xx    10/2024'
  .endl
  
  .local text_save_settings
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
  .byte '[7] Exit Menu'
  .endl
  
  .local text_help_screen
  .byte 'HELP',$9b,$9b
  .byte 'Use Ctrl-Return to send your message immediately',$9b
  .byte 'Use SELECT to switch between public and private messaging. To send a private message to someone:'
  .byte ' start your message with @username'

  .endl
  
  .local text_help_screen2
  .byte 'To talk to Eliza (our AI Chatbot), switch to private messaging and start your message with @Eliza'
  .endl
  
  .local text_about_screen
  .byte 'ABOUT CHAT64',$9b,$9b
  .byte 'Initially developed by Bart as a proof  of concept on Commodore 64',$9B,$9B
  .byte 'A new version of CHAT64 is now availableto everyone.',$9B
  .byte 'We proudly bring you Chat64 on Atari XL',$9B,$9B
  .endl  
  .local text_about_screen2
  .byte 'Made by Bart Venneker and Theo van den  Belt in 2024',$9B,$9B
  .byte 'Hardware, software and manuals are available on Github',$9B,$9B
  .byte 'github.com/bvenneker/Chat64-Atari800'
  .endl  
  
  .local text_madeBy 
  .byte 'Made by Bart and Theo in 2024'  
  .endl
  
   .local text_forAtari800xl
   .byte 'For Atari 800XL'
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
// ----------------------------------------------------------------
// Variables
// ----------------------------------------------------------------
blink   .byte 0,0
blink2  .byte 0,0
ddlist  .word 0,0
DELAY   .byte 0,0    
z_as    .byte 0,0
cursorphase  .byte 0,0
temppos  .byte 0,0   
RXBUFFER :250 .byte 128        
SPLITBUFFER :40 .byte 128   
MENU_ID .byte 0
SCREEN_ID .byte 0
FIELD_MAX .byte 0
FIELD_MIN .byte 0
VICEMODE .byte 0
CONFIG_STATUS .byte 0,128
SWVERSION .byte '9.99',128
SERVERNAME .byte 'www.chat64.nl          ',128
TEMPI .byte 0
p_cursor_x .byte 0
p_cursor_y .byte 0
m_cursor_x .byte 0
m_cursor_y .byte 0
  
// -----------------------------------
// Print the RX Buffer on screen
// line = 0 - 23
// column = 0,39
// -----------------------------------
.macro displayBuffer buffer,line,column
  mva :line rowcrs 
  mva :column colcrs  
  mva #0 character
  lda #<(:buffer) 
  sta textPointer
  lda #>(:buffer)
  sta textPointer+1
  jsr displayBufferk  
.endm  


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



.align $400        
SCREEN_PUBL_BACKUP:
   

  org SCREEN_PUBL_BACKUP + 1024
SCREEN_PRIV_BACKUP:
   
        
 run init
  