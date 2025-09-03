#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <freertos/message_buffer.h>
#include <WiFi.h>
#include <HTTPUpdate.h>
#include "common.h"
#include "utils.h"
#include "wifi_core.h"
volatile long topMes = 0;
volatile long botMes = 0;
volatile int gotScrollMessage;
volatile int systemLineCount;
volatile int pageSize = 5;
volatile int scrollDirection = 1;
String regID = "";       // String variale for your regID (leave it empty!)
String macaddress = "";  // variable for the mac address (leave it empty!)
String myNickName = "";  // variable for your nickname (leave it empty!)
String ServerConnectResult ;
int pmCount = 0;       // counter for the number of unread private messages
String pmSender = "";  // name of the personal message sender
unsigned long lastWifiBegin;
// You do NOT need to change any of these settings!
String ssid = "empty";      // do not change this!
String password = "empty";  // do not change this!
String timeoffset = "empty";
String server = "empty";  // do not change this!
String configured = "empty";  // do not change this!
String myLocalIp = "0.0.0.0";
volatile unsigned long messageIds[] = { 0, 0 };
volatile unsigned long tempMessageIds[] = { 0, 0 };
volatile unsigned long lastprivmsg = 0;
String msgtype = "public";  // do not change this!
String users = "";          // a list of all users on this server.
volatile bool updateUserlist = false; // user list to check existing users
volatile bool refreshUserPages = true; // user list for 'who is online'
char msgbuffer[500];  // a character buffer for a chat message
volatile int msgbuffersize = 0;
volatile bool getMessage = false;
volatile bool pastMatrix = false;
volatile bool aboutToReset = false;
volatile bool sendingMessage = false;
String userPages[16];
String romVersion = "0.0";
String newVersions ="";
MessageBufferHandle_t commandBuffer;
MessageBufferHandle_t responseBuffer;
bool isWifiCoreConnected = false;
int lastp = 0;
String onLineUsers = "";
String offLineUsers = "";
int updateCount=0;

// ****************************************************
//  get response from HTTP Server
// ****************************************************
String getHttpResponse(String pagename, String httpRequestData, int* httpResponseCode) {
  String result = "";
  String serverName = "http://" + server + "/" + pagename;
  WiFiClient client;
  HTTPClient http;
  http.begin(client, serverName);                                       // Connect to configured server
  http.addHeader("Content-Type", "application/x-www-form-urlencoded");  // Specify content-type header
  unsigned long responseTime = millis();
  *httpResponseCode = http.POST(httpRequestData);
  responseTime = millis() - responseTime;
  if (responseTime > 10000) softReset();
  result = http.getString();
  result.trim();
  http.end();
  client.stop();
  return result;
}

// ***************************************************************
//   Scroll up / down routine
// ***************************************************************
void scrolling() {
  int lm = 21 - systemLineCount;
  int httpResponseCode = 0;
  if (scrollDirection == 1 and topMes == 0) botMes = messageIds[0];  // direction 1 = up
  //if (scrollDirection==0 and botMes == 0) botMes = messageIds[0];  // direction 0 = down
  String httpRequestData = "regid=" + regID + "&bm=" + botMes + "&tm=" + topMes + "&d=" + scrollDirection + "&p=" + pageSize + "&lm=" + lm + "&t=" + timeoffset;
  String result = getHttpResponse("scrollUp.php", httpRequestData, &httpResponseCode);
  if (httpResponseCode == 200) {
    msgbuffersize = result.length() + 1;
    result.toCharArray(multiMessageBufferPub, msgbuffersize);
    multiMessageBufferPub[msgbuffersize] = 128;
  } else {
    Serial.print("response = ");
    Serial.println(httpResponseCode);
  }
  gotScrollMessage = 1;  // unconditional, prevent endless loop
}

// ***************************************************************
//   get the list of users from the webserver
// ***************************************************************
void fill_userlist() {
  // we get a list of users.
  // the list starts with on-line users,
  // followed by "_sep_", followed by off line users.
  String oldusers1 = onLineUsers;
  String oldusers2 = offLineUsers;

  int httpResponseCode = 0;
  String users = getHttpResponse("listUsers.php", "regid=" + regID + "&system=Atari&call=list2", &httpResponseCode);
  if (httpResponseCode == 200) {
    int sepindex = users.indexOf("_sep_");
    onLineUsers = users.substring(0, sepindex);
    offLineUsers = users.substring(sepindex + 6);
    get_full_userlist();
  } else {
    onLineUsers = oldusers1;
    offLineUsers = oldusers2;
  }
}

// *******************************************************
//  String function to get the userlist from the database
// *******************************************************
void get_full_userlist() {
  // this is for the user list in the menu (Who is on line?)
  // invert the online users (add 128 to the byte)
  String input=onLineUsers;
  String allUsers;
  for (int i = 0; i < input.length(); i++) {
     char c = input[i];
     if (c != ' ' && c != ';')  c = c + 128; // Add 128 to non-space characters
     allUsers += c; // Append to output string
   }
  // now add the offline users. 
  allUsers += ";" + offLineUsers + ";";
  int start=0;
  int pageIndex = 0;
  int nameCount = 0;
  int maxNamesPerGroup = 15;
  int end = allUsers.indexOf(';');
  // empty all userpages first
  for (int x = 0; x < 16; x++) userPages[x] = "";
  while (end != -1) {
    String name = allUsers.substring(start, end);
    name.trim();
    if (name.length() > 0) {
      if (nameCount >= maxNamesPerGroup) {
        pageIndex++;
        nameCount = 0;
      }
      int pad=13;
      if ((nameCount + 1) % 3 == 0) pad=14; 
      name.trim();
      name = (name + "                  ").substring(0, pad);  // pad the name to 13 or 14 characters
      userPages[pageIndex] += name;
      nameCount++;
    }
    start = end + 1;
    end = allUsers.indexOf(';', start);
  }
}

// *************************************************
//  void to send a message to the server
// *************************************************
bool SendMessageToServer(String Encoded, String RecipientName, int retryCount, bool heartbeat) {
  // Prepare your HTTP POST request data
  String httpRequestData = "";
  int httpResponseCode = 0;
  if (heartbeat) httpRequestData = "regid=" + regID + "&call=heartbeat";
  else httpRequestData = "sendername=" + myNickName + "&retryCount=" + retryCount + "&regid=" + regID + "&recipientname=" + RecipientName + "&message=" + Encoded;
  String resultstr = getHttpResponse("insertMessage.php", httpRequestData, &httpResponseCode);
  if (httpResponseCode == 200) return true;
  return false;
}

// ****************************************************
//  char function that returns the registration status
// ****************************************************
char getRegistrationStatus() {
  int i = 0;
  String HttpResult = getHttpResponse("getRegistration.php", "macaddress=" + macaddress + "&regid=" + regID + "&nickname=" + myNickName + "&version=" + SwVersion, &i);
  if (HttpResult.indexOf("r200") != -1) return 'r';
  if (HttpResult.indexOf("r105") != -1) return 'n';
  if (HttpResult.indexOf("r104") != -1) return 'u';
  return 'x';
}

// *************************************************
//  void to check connectivity to the server
// *************************************************
void ConnectivityCheck() {
  int httpResponseCode = 0;
  ServerConnectResult = getHttpResponse("connectivity.php", "checkcon=1", &httpResponseCode);
  if (httpResponseCode != 200) {
    ServerConnectResult = "Error, check server name!";
    return;
  }
  if (ServerConnectResult.indexOf("Not connected") != -1) {
    ServerConnectResult = "Server found but failed to connect";
    return;
  }
  if (ServerConnectResult.indexOf("Connected") != -1) {
    ServerConnectResult = "Connected to chat server!";
    return;
  }
}

// **************************************************
//  Task1 runs on the second core of the esp32
//  it receives messages from the web site
//  this process can be a bit slow so we run it on
//  the second core and the main program can continue
// **************************************************
void WifiCoreLoop(void* parameter) {
  WiFiCommandMessage commandMessage;
  WiFiResponseMessage responseMessage;
  unsigned long last_up_refresh = millis() + 5000;
  unsigned long heartbeat = millis();
  

  for (;;) {  // this is an endless loop

    // check for any command comming from app core for at most 1 sec.
    size_t ret = xMessageBufferReceive(commandBuffer, &commandMessage, sizeof(commandMessage), pdMS_TO_TICKS(1000));

    if (ret != 0) {
      switch (commandMessage.command) {
        case WiFiBeginCommand:
          WiFi.mode(WIFI_STA);
          WiFi.config(INADDR_NONE, INADDR_NONE, INADDR_NONE, INADDR_NONE);
          WiFi.begin(ssid, password);
          break;
        case ConnectivityCheckCommand:
          ConnectivityCheck();
          break;
        case GetRegistrationStatusCommand:
          {
            responseMessage.command = GetRegistrationStatusCommand;
            char regStatus = getRegistrationStatus();
            responseMessage.response.str[0] = regStatus;
            xMessageBufferSend(responseBuffer, &responseMessage, sizeof(responseMessage), portMAX_DELAY);
          }
          break;
        case SendMessageToServerCommand:
          responseMessage.command = SendMessageToServerCommand;
          responseMessage.response.boolean =
            SendMessageToServer(commandMessage.data.sendMessageToServer.encoded,
                                commandMessage.data.sendMessageToServer.recipientName,
                                commandMessage.data.sendMessageToServer.retryCount,
                                false);
          xMessageBufferSend(responseBuffer, &responseMessage, sizeof(responseMessage), portMAX_DELAY);
          break;
        case GetWiFiMacAddressCommand:
          responseMessage.command = GetWiFiMacAddressCommand;
          Network.macAddress().toCharArray(responseMessage.response.str, sizeof(responseMessage.response.str));
          xMessageBufferSend(responseBuffer, &responseMessage, sizeof(responseMessage), portMAX_DELAY);
          break;
        //case GetWiFiLocalIpCommand:
        //  responseMessage.command = GetWiFiLocalIpCommand;
        //  WiFi.localIP().toString().toCharArray(responseMessage.response.str, sizeof(responseMessage.response.str));
        //  xMessageBufferSend(responseBuffer, &responseMessage, sizeof(responseMessage), portMAX_DELAY);
        //  break;
        case DoUpdateCommand:
          doUpdate();
          break;
        case ScrollUpDown:
          scrolling();
          break;
        default:
          Serial.print("Invalid Command Message: ");
          Serial.println(commandMessage.command);
          break;
      }
    }

    isWifiCoreConnected = WiFi.isConnected();
    if (!isWifiCoreConnected) {
      myLocalIp="0.0.0.0";
      if (millis() > lastWifiBegin + 7000) {
        lastWifiBegin=millis();
        Serial.print("Connecting to WiFi again");         
        WiFi.mode(WIFI_STA);
        WiFi.config(INADDR_NONE, INADDR_NONE, INADDR_NONE, INADDR_NONE);
        WiFi.begin(ssid, password);  
      }
      continue;
    } 
    myLocalIp=WiFi.localIP().toString();

    if (!getMessage) {                     // this is a wait loop
      if (millis() > last_up_refresh + 30000 and pastMatrix and !sendingMessage) {
        refreshUserPages = true;
      }
      if (updateUserlist and !getMessage and pastMatrix and !sendingMessage) {
        updateUserlist = false;
        fill_userlist();
      }      
      continue;
    }

    // when the getMessage variable goes True, we drop out of the wait loop
    getMessage = false;                                                 // first reset the getMessage variable back to false.
    int httpResponseCode = 0;
    String httpRequestData = "regid=" + regID + "&lastmessage=" + messageIds[0] + "&lastprivate=" + messageIds[1] + "&previousPrivate=" + lastprivmsg + "&type=" + msgtype + "&version=" + SwVersion + "&rom=" + romVersion + "&t=" + timeoffset;
    String result = getHttpResponse("XLReadAllMessages.php", httpRequestData, &httpResponseCode);   
    if (httpResponseCode == 200) {  // httpResponseCode should be 200
      String textOutput = result;      
      msgbuffersize = textOutput.length() + 1;
      if (msgtype == "private") {
        textOutput.toCharArray(multiMessageBufferPriv, msgbuffersize);
      }
      if (msgtype == "public") {
        textOutput.toCharArray(multiMessageBufferPub, msgbuffersize);
      }
      
      
      textOutput = "";
      heartbeat = millis();  // readAllMessages also updates the 'last seen' timestamp, so no need for a heartbeat for the next 25 seconds.
    }    
    if (updateCount++ > 3) {
      newVersions = UpdateAvailable();
      updateCount=0;
    }
  }
}

void softReset() {
  settings.begin("mysettings", false);
  settings.putInt("doReset", 157);
  settings.putULong("lastPubMessage", messageIds[0]);
  settings.putULong("lastPrivMessage", messageIds[1]);
  settings.end();
  delay(100);
  ESP.restart();
}

String UpdateAvailable(){
  String httpRequestData = "regid=" + regID ;
  int httpResponseCode = 0;
  String result = getHttpResponse("checkUpdateForAtari.php", httpRequestData, &httpResponseCode);
  String thisVersion = String(uromVersion) + " " + String(SwVersion);
  if (result != thisVersion) {   
    return result;
  }
  return "";
}

void doUpdate(){
    ready_to_receive(true);
    updateProgress(1);
    NetworkClient client;
    httpUpdate.onStart(update_started);
    httpUpdate.onEnd(update_finished);
    httpUpdate.onProgress(update_progress);
    httpUpdate.onError(update_error);
    httpUpdate.update(client, "http://www.chat64.nl/update/AtariXL_Chat.bin");
}

void update_started() {
  updateProgress(1);
  Serial.println("CALLBACK:  HTTP update process started");
}

void update_finished() {
  Serial.println("CALLBACK:  HTTP update process finished");
}

void update_progress(int cur, int total) {
  int p = map(cur,1,total,1,32);
  updateProgress(p);
  if (p==32) delay(500);
}

void update_error(int err) {
  Serial.printf("CALLBACK:  HTTP update fatal error code %d\n", err);
}


void updateProgress(int p){   
  if (lastp == p) return;
  lastp = p;
  // send the byte
  Serial.println(p);
  digitalWrite(RCLK,LOW);
  shiftOut(oSdata,sclk2,MSBFIRST,p) ; 
  digitalWrite(RCLK,HIGH);
}

