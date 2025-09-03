#include "utils.h"

// ******************************************************************************
// translate Atari char set to Ascii
// ******************************************************************************
char Atari_to_Ascii(byte ch){
// https://www.atariarchives.org/c1bag/chap4n3a.jpg

  //                   0,  1,  2,  3,  4,  5,  6,  7,  8,  9
  byte XLtoAscii[] = {32, 33, 34, 35, 36, 37, 38, 39, 40, 41,  //  0 -  9
                      42, 43, 44, 45, 46, 47, 48, 49, 50, 51,  // 10 - 19
                      52, 53, 54, 55, 56, 57, 58, 59, 60, 61,  // 20 - 29
                      62, 63, 64, 65, 66, 67, 68, 69, 70, 71,  // 30 - 39
                      72, 73, 74, 75, 76, 77, 78, 79, 80, 81,  // 40 - 49
                      82, 83, 84, 85, 86, 87, 88, 89, 90, 91,  // 50 - 59
                      92, 93, 94, 95, 32, 32, 32, 32, 32, 32,  // 60 - 69
                      92, 93, 94, 95, 32, 32, 32, 32, 32, 32,  // 70 - 79
                      92, 93, 94, 95, 32, 32, 32, 32, 32, 32,  // 80 - 89
                      92, 93, 94, 95, 32, 32, 32, 97, 98, 99,  // 90 - 99
                     100,101,102,103,104,105,106,107,108,109,  //100 -109
                     110,111,112,113,114,115,116,117,118,119,  //110 -119
                     120,121,122, 32,124, 32, 32, 32           //120 -127
                      };

char result = char(XLtoAscii[ch]);
return result;              
}

// ******************************************************************************
// translate screen codes to ascii
// ******************************************************************************
char screenCode_to_Ascii(byte screenCode) {

  byte screentoascii[] = { 64, 97, 98, 99, 100, 101, 102, 103, 104, 105,
                           106, 107, 108, 109, 110, 111, 112, 113, 114, 115,
                           116, 117, 118, 119, 120, 121, 122, 91, 92, 93,
                           94, 95, 32, 33, 34, 125, 36, 37, 38, 39,
                           40, 41, 42, 43, 44, 45, 46, 47, 48, 49,
                           50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
                           60, 61, 62, 63, 95, 65, 66, 67, 68, 69,
                           70, 71, 72, 73, 74, 75, 76, 77, 78, 79,
                           80, 81, 82, 83, 84, 85, 86, 87, 88, 89,
                           90, 43, 32, 124, 32, 32, 32, 32, 32, 32,
                           95, 32, 32, 32, 32, 32, 32, 32, 32, 32,
                           32, 95, 32, 32, 32, 32, 32, 32, 32, 32,
                           32, 32, 32, 32, 32, 32, 32, 32, 32 };

  char result = char(screenCode);
  if (screenCode < 129) result = char(screentoascii[screenCode]);
  return result;
}


// ******************************************************************************
// translate ascii to c64 screen codes
// ******************************************************************************
byte Ascii_to_screenCode(char ascii) {

  byte asciitoscreen[] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
                           11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
                           22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32,
                           33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43,
                           44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54,
                           55, 56, 57, 58, 59, 60, 61, 62, 63, 0, 65,
                           66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76,
                           77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87,
                           88, 89, 90, 27, 92, 29, 30, 100, 39, 1, 2,
                           3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13,
                           14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
                           25, 26, 27, 93, 35, 64, 32, 32 };
  byte result = ascii;
  if (int(ascii) < 129) result = byte(asciitoscreen[int(ascii)]);
  return result;
}

// ************************************************************************************
// BASE64 encode / decode functions.
// based on https://stackoverflow.com/questions/180947/base64-decode-snippet-in-c
// ************************************************************************************
String base64_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

String my_base64_encode(char* buf, int bufLen) {
  String ret;
  int i = 0;
  int j = 0;

  unsigned char char_array_4[4], char_array_3[3];
  while (bufLen--) {
    char_array_3[i++] = *(buf++);

    if (i == 3) {
      char_array_4[0] = (char_array_3[0] & 0xfc) >> 2;
      char_array_4[1] = ((char_array_3[0] & 0x03) << 4) + ((char_array_3[1] & 0xf0) >> 4);
      char_array_4[2] = ((char_array_3[1] & 0x0f) << 2) + ((char_array_3[2] & 0xc0) >> 6);
      char_array_4[3] = char_array_3[2] & 0x3f;

      for (i = 0; (i < 4); i++)
        ret += base64_chars[char_array_4[i]];
      i = 0;
    }
  }

  if (i) {
    for (j = i; j < 3; j++)
      char_array_3[j] = '\0';

    char_array_4[0] = (char_array_3[0] & 0xfc) >> 2;
    char_array_4[1] = ((char_array_3[0] & 0x03) << 4) + ((char_array_3[1] & 0xf0) >> 4);
    char_array_4[2] = ((char_array_3[1] & 0x0f) << 2) + ((char_array_3[2] & 0xc0) >> 6);
    char_array_4[3] = char_array_3[2] & 0x3f;

    for (j = 0; (j < i + 1); j++)
      ret += base64_chars[char_array_4[j]];

    while ((i++ < 3))
      ret += '=';
  }
  return ret;
}

String my_base64_decode(String const& encoded_string) {
  int inlen = encoded_string.length();
  int i = 0;
  int j = 0;
  int k = 0;
  unsigned char char_array_4[4], char_array_3[3];
  String ret;

  while (inlen-- && (encoded_string[k] != '=') && is_base64(encoded_string[k])) {
    char_array_4[i++] = encoded_string[k];
    k++;
    if (i == 4) {
      for (i = 0; i < 4; i++) {
        char_array_4[i] = (char)base64_chars.indexOf(char_array_4[i]);
      }

      char_array_3[0] = (char_array_4[0] << 2) + ((char_array_4[1] & 0x30) >> 4);
      char_array_3[1] = ((char_array_4[1] & 0xf) << 4) + ((char_array_4[2] & 0x3c) >> 2);
      char_array_3[2] = ((char_array_4[2] & 0x3) << 6) + char_array_4[3];
      for (i = 0; (i < 3); i++) {
        ret += (char)char_array_3[i];
      }
      i = 0;
    }
  }

  if (i) {
    for (j = 0; j < i; j++) {
      char_array_4[j] = (char)base64_chars.indexOf(char_array_4[j]);
    }

    char_array_3[0] = (char_array_4[0] << 2) + ((char_array_4[1] & 0x30) >> 4);
    char_array_3[1] = ((char_array_4[1] & 0xf) << 4) + ((char_array_4[2] & 0x3c) >> 2);
    for (j = 0; (j < i - 1); j++) {
      ret += (char)char_array_3[j];
    }
  }
  return ret;
}

byte checksum(byte data[], int datasize) {
  byte sum = 0;
  for (int i = 0; i < datasize; i++) {
    sum += data[i];
  }
  return -sum;
}

int x2i(char* s) {
  int x = 0;
  for (;;) {
    char c = *s;
    if (c >= '0' && c <= '9') {
      x *= 16;
      x += c - '0';
    } else if (c >= 'a' && c <= 'f') {
      x *= 16;
      x += (c - 'a') + 10;
    } else break;
    s++;
  }
  return x;
}

String getValue(String data, char separator, int index) {
  int found = 0;
  int strIndex[] = { 0, -1 };
  int maxIndex = data.length() - 1;
  String r;
  for (int i = 0; i <= maxIndex && found <= index; i++) {
    if (data.charAt(i) == separator || i == maxIndex) {
      found++;
      strIndex[0] = strIndex[1] + 1;
      strIndex[1] = (i == maxIndex) ? i + 1 : i;
    }
  }
   
  if (found > index){
    r= data.substring(strIndex[0], strIndex[1]);
    // delete last character if string ends with garbage (happens on Atari)    
    int lc = r.charAt(r.length()-1);
    if ( lc > 126  or lc < 32) r.remove(r.length()-1);
    } else r="";   
  return r;
}
// ******************************************************************************
// get one message from the big message buffer
// ******************************************************************************
bool getMessageFromMMBuffer(char *sourceBuffer, int *bufferIndex, bool isPrivate) {
  // do we have any messages in the page buffer?
  // find the first '{' in the page buffer
  int p = 0;
  char cc = 0;
  bool found = false;
  while (cc != '{' and p++ < 10) {  // find first {
    cc = sourceBuffer[(*bufferIndex)++];
  }
  if (cc == '{') {  // copy to message buffer until we find '}'
    msgbuffer[0] = cc;
    found = true;
    getMessage = false;
    p = 1;
    while (cc != '}') {
      cc = sourceBuffer[(*bufferIndex)++];
      if (cc != 10) msgbuffer[p++] = cc;  // put this line into the msgbuffer buffer
    }
  }
  if (!found) {
    for (int y = 0; y < 3500; y++) sourceBuffer[y] = 0;  // clear the buffer
    *bufferIndex = 0;    
  }

  return found;
}
// ******************************************************************************
// Deserialize the json encoded messages
// ******************************************************************************
int Deserialize() {
  int haveMessage = 0;
  msgbuffersize = 0;
  DynamicJsonDocument doc(512);                                  // next we want to analyse the json data
  DeserializationError error = deserializeJson(doc, msgbuffer);  // deserialize the json document
  if (!error) {    
    unsigned long newMessageId = doc["rowid"];
    // if we get a new message id back from the database, that means we have a new message
    // if the database returns the same message id, there is no new message for us..
    bool newid = false;
    String channel = doc["channel"];
    if ((channel == "private") and (newMessageId != messageIds[1])) {
      newid = true;
      tempMessageIds[1] = newMessageId;
      String nickname = doc["nickname"];
    }

    if ((channel == "public") and (newMessageId != messageIds[0])) {
      newid = true;
      tempMessageIds[0] = newMessageId;
    }
    if (newid) {
      int lines = doc["lines"];      
      String message = doc["message"];
      String decoded_message = ' ' + my_base64_decode(message);
      int msize = decoded_message.length() + 1;
      decoded_message.toCharArray(msgbuffer, msize);
      int outputLength = decoded_message.length();
      msgbuffersize = (int)outputLength;
      msgbuffer[0] = lines;
      msgbuffersize += 1;

      pmCount = doc["pm"];
      haveMessage = 1;
      if (msgtype == "private") haveMessage = 2;

    } else {  // we got the same message id back, so no new messages:
      pmCount = doc["pm"];
      msgbuffersize = 0;
      haveMessage = 0;
    }
    doc.clear();
  } // else {error is deserialize}
  return haveMessage;
}

void loadPrgfile() {
  int delayTime = 150;
  //delay(2000);  // give the computer some time to boot
  ch = 0;
  ready_to_receive(true);
  Serial.println("Waiting for start signal");
  int i = 0;
  while (ch != 100) {  // wait for the computer to send byte 100
    ready_to_receive(true);
  }
  Serial.println("------ LOAD PRG FILE ------");
  delayMicroseconds(delayTime);
  sendByte(screenColor);
  delayMicroseconds(delayTime);
  sendByte(lowByte(sizeof(prgfile) - 6));
  delayMicroseconds(delayTime);
  sendByte(highByte(sizeof(prgfile) - 6));

  for (int x = 6; x < sizeof(prgfile); x++) {  // Now send all the rest of the bytes
    delayMicroseconds(delayTime);
    sendByte(prgfile[x]);
  }

  Serial.println("------ PRG FILE DONE ------");
  ch = 0;
  ready_to_receive(false);
  io2 = false;
  dataFromHost = false;
}
