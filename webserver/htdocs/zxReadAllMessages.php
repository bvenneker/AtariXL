<?php

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

require_once('../dbCredent.php');
$system_regid="666666cacacacaffff";
$scriptName="zxReadAllMessages";
// Check connection
if ($conn->connect_error) {
  die("Connection failed: " . $conn->connect_error);
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
  if (isset($_POST["sendername"])) $sendername = test_input($_POST["sendername"]);
   
  $regid = test_input($_POST["regid"]);
  $lastmessage = test_input($_POST["lastmessage"]);
  $lastprivate = test_input($_POST["lastprivate"]);

  if (isset($_POST["previousPrivate"])) 
	$previousPrivate = test_input($_POST["previousPrivate"]);
  else 
    $previousPrivate = $lastprivate;
        
  $type = test_input($_POST["type"]);
  $version = test_input($_POST["version"]);
  $eeprom =  test_input($_POST["rom"]);
  if (isset($_POST["lp"])) $lp =  test_input($_POST["lp"]);  
  if (isset($_POST["t"])) $timeoffset =  test_input($_POST["t"]);
  else $timeoffset = "+1";
  
   
} else  {	
	exit();
	$regid='8d400a1293261d09';
	$lastmessage=0;
	$lastprivate=0;
	$type='public';
	$version='3.63';
	$eeprom='3.59';
	$timeoffset="+2";
	$previousPrivate='444';

//regid=8d400a1293261d09&lastmessage=0&lastprivate=0&previousPrivate=444&type=public&version=3.75&rom=3.69&t=+2
}

// check if user is registred and get Nickname
$sql="select * from users where regid='$regid' and blocked=0";
$result = $conn->query($sql);
if ($row = $result->fetch_assoc()) {
	$yourNickName=$row["nickname"];
	if (strlen($yourNickName) <=1) $yourNickName="a user";
} else {
exit();
}

// update versions in the database the database
updateEspVersion($version,$regid);
updateRomVersion($eeprom,$regid);

// Get yourNickName
//$sql="select nickname from users where regid='".$regid."'";
//$result = $conn->query($sql);
//$yourNickName="";
//if ($row = $result->fetch_assoc()) {
//	$yourNickName=$row["nickname"];
//	if (strlen($yourNickName) <=1) $yourNickName="a user";
//}
	

// update the lastseen field in the database so we know this user is online
updateLastSeen($regid);

// Insert a message <Nickname> has joined the chat
if (intval($lastmessage) <= 1 ) {
  $theNickName = strtolower(getNickName($regid));	
  if (!str_contains('testsmd,testtht,testzx,bodger,zxbart,tinker',$theNickName)) insertWelcomeMessage($regid);		    
}

	
// Public messages: 
if ($type=='public') {

	// get all messages at once
	$sql = "select m.sendername,m.rowid,m.timestamp, m.message,m.regid,u.nickname from messages m inner join users u on u.regid=m.regid where (m.regid<>'".$system_regid."' and recipient is null and m.rowid >" . $lastmessage . ") OR (m.regid='".$system_regid."' and recipient is null and m.timestamp > DATE_SUB(NOW(),INTERVAL 5 MINUTE) and m.rowid >" . $lastmessage . ")  order by m.rowid desc limit 25";	
	if ($result = $conn->query($sql)){	
		$totlines=0;
		$targetID=0;
		$ids="";
		while($row = $result->fetch_assoc() and $totlines < 21){
			// create the header:
			$message="[151]".$row["timestamp"] . " " . $row["sendername"] .":";
			$message=str_pad($message,37,"@").$row["message"];
			// get the message length and replace the higher bytes (that contain color information)
			list($message,$len)=replace_higher_bytes($message);
			// calculate the number of lines.
			$len = ceil($len/32); 
			$totlines += $len;

			$targetID = $row["rowid"];
			$ids = $row["rowid"] . '^^' . $ids;

		}
		
		if ($ids != "") {
			$ids = substr($ids, 0, -2);
			 echo"[";
			 $ic=1;
			 foreach (explode("^^",$ids) as $i) {
			   outputMessage($i);
			   if (count(explode("^^",$ids)) > $ic++) echo ",";
				 }
			 echo"]";
		} else {
			$pm=countPrivateMessages($regid,$previousPrivate);
			echo '{"rowid":"'.$lastmessage.'","timestamp":"0","message":"0","nickname":"0","len":0,"pm":'.$pm.'}';
			}

	}
	

	$conn->close();
	flush();
	exit(0);
}

// =================================================================================================================
// the same for private messages 
if ($type=='private'){

		// get all messages at once
		$sql = "select m.sendername, m.rowid,m.timestamp, m.message,m.regid,u.nickname,m.recipientname from messages m inner join users u on u.regid=m.regid where (recipient ='" . $regid  . "'  and m.rowid >" . $lastprivate . ") or (m.rowid >" . $lastprivate . " and m.regid='".$regid."' and recipient is not null)  order by m.rowid desc limit 25";
		if ($result = $conn->query($sql)){
		
		$totlines=0;
		$targetID=0;
		$ids="";
		while($row = $result->fetch_assoc() and $totlines < 21){
			// create the header:
			$message="[151]".$row["timestamp"] . " " . $row["sendername"] .":";
			$message=str_pad($message,37,"@").$row["message"];
			// get the message length and replace the higher bytes (that contain color information)
			list($message,$len)=replace_higher_bytes($message);
			// calculate the number of lines.
			$len = ceil($len/32); 
			$totlines += $len;
			$targetID = $row["rowid"];
			$ids = $row["rowid"] . '^^' . $ids;

		}
		if ($ids!=""){
			$ids = substr($ids, 0, -2);
			 echo"[";
			 $ic=1;
			 foreach (explode("^^",$ids) as $i) {
			   outputMessage($i);
			   if (count(explode("^^",$ids)) > $ic++) echo ",";
				 }
			 echo"]";
		 } else {
			$pm=countPrivateMessages($regid,$previousPrivate);
			echo '{"rowid":"'.$lastprivate.'","timestamp":"0","message":"0","nickname":"0","len":0,"pm":'.$pm.'}';
			}

		}
		$conn->close();
		flush();
		exit(0);
}

// =================================================================================================================
// =================================================================================================================
function getNickName($regid){
	global $conn;	
	global $system_regid;
	$sql="select nickname from users where regid='".$regid."'";
	$result = $conn->query($sql);
	$nickname="";
	if ($row = $result->fetch_assoc()) {
		$nickname=$row["nickname"];
		if (strlen($nickname) <=1) $nickname="a user";
	}
	return $nickname;
	}
// =================================================================================================================
function insertWelcomeMessage($regid) {
	global $conn;	
	global $system_regid;
	$sql="select nickname from users where regid='".$regid."'";
	$result = $conn->query($sql);
	$nickname="";
	if ($row = $result->fetch_assoc()) {
		$nickname=$row["nickname"];
		if (strlen($nickname) <=1) $nickname="a user";
	}
	writeLog("NAME=" . $nickname);
	$tmessage="[143][146]system: ".str_pad($nickname." joined the chat", 32, " ", STR_PAD_LEFT);

	// delete old messages that say I joined the chat.
	$sql="delete from messages where message='".$tmessage."'"  ;
	$conn->query($sql);

	// post a new message "<myname> has joined the chat"			
	$sql = "INSERT INTO messages (sendername, regid, message) VALUES ('system','" . $system_regid . "','" . $tmessage ."')";
	
	// only insert the message when the nickname is filled in
	if (strlen($nickname) > 1) $conn->query($sql);
}
// =================================================================================================================
function updateEspVersion($version,$regid){
	global $conn;
	// update the ESP32 version
	if (strlen($version) > 0) {
		$sql="update users set version='".$version."' where regid='".$regid."'";
		$conn->query($sql);
	}
}

// =================================================================================================================
function updateRomVersion($eeprom,$regid){
	global $conn;
	// Update the eeprom version
	if (strlen($eeprom) > 0) {
		$sql="update users set eeprom='".$eeprom."' where regid='".$regid."'";
		$conn->query($sql);
	}
}
// =================================================================================================================
function updateLastSeen($regid){
	global $conn;
	// update the last seen field in the users table so we can know this user is online
	$sql="update users set lastseen=".time()."  where regid='".$regid."'";
	$conn->query($sql);
	// writeLog("Update lastseen timestamp ".time());
}
// =================================================================================================================
function countPublicMessages($regid,$lastmessage) {
	global $conn;
	$sql="select * from messages where regid<>'".$system_regid."' and recipient is null and rowid >" . $lastmessage ;
	$result = $conn->query($sql);
    $pm = $result->num_rows ;
	return $pm;
}
// =================================================================================================================
function countPrivateMessages($regid,$lp) {
	global $conn;
	$sql = "select * from messages where recipient ='" . $regid  . "'  and rowid >" . $lp ;
    $result = $conn->query($sql);
    $pm = $result->num_rows ;
	return $pm;
}
// =================================================================================================================

function replace_higher_bytes($str){
  // this function replaces the [145] for byte value 145 en returns also the length of the message excluding those bytes.
  $pattern = "/\[\d\d\d\]/";
  preg_match_all($pattern, $str,$out);
    $c=0;
    foreach ($out[0] as $o) {
      $v=intval(substr($o,1,-1));
      $str = str_replace($o,chr($v),$str);
      $c++;
    }
  return array($str,strlen($str)-$c);
}

// =================================================================================================================
function test_input($data) {
    $data = trim($data);
    $data = stripslashes($data);
    $data = htmlspecialchars($data);
    return $data;
}
// =================================================================================================================
function trimMessage($message){
  $message=trim($message);

  // sometimes, for some reason, there are extra bytes at the end of the message.
  // They are formatted like this [nnn]. We need to delete those.
  
  while (preg_match("/^\[\d\d\d\]$/",substr($message,-5))) {
      $message=substr($message,0,-5);
      $message=trim($message);      
  }
  return $message;
}
// =================================================================================================================
function trim_40_to_32($message,$len){
	// the zx spectrum has a screen width of 32 chars,
	// the c64 has a screen width of 40 chars.
	// Messages in the database are always with line length 40, even from the ZX Spectrum
	// So the C64 displays it correctly.
	// But for the ZX spectrum we need to reduce the line length (if possible) from 40 to 32.
	// So if a line ends with 8 space characters, we trim those for the ZX spectrum
	
	// we need to find out if characters 33 to 40 are spaces, but there may be extra bytes in there for color information
	
	$L1=0;
	$newMessage="";
	$chars = str_split($message); 
	foreach ($chars as $char) { 
		if (ord($char) < 128) {
		  $L1++ ;
		}  
		$newMessage = $newMessage . $char;
	  
		if ($L1 == 40 | $L1 == 80 | $L1== 120) {
			if (str_ends_with($newMessage, '        ')){
				//echo ($newMessage."|");
				
				$newMessage = substr_replace($newMessage, "", -8, 8);
				//echo ($newMessage."|");		
				}
			}		
	}
	$newMessage = trim($newMessage)	;
	
	while (ord(substr($newMessage, -1)) >127) {
		$newMessage = substr_replace($newMessage, '', -1);
	    $newMessage = trim($newMessage)	;	
		}
    
    // the message : 'system: bart joined the chat' is a bit too long for the zx spectum,
    // It should fit on one line so lets remove some spaces and change one word.
    if (str_contains($newMessage,"system:") and str_contains($newMessage,"joined")) {
		$newMessage = str_replace("system:       ","system:",$newMessage);
		$newMessage = str_replace("joined","joins",$newMessage);
		}
		
    // count the new length
    $L1=0;
    $chars = str_split($newMessage); 
	foreach ($chars as $char) { 
		if (ord($char) < 128) {
		  $L1++ ;
		}
	}
    return array($newMessage,$L1);
	}
// =================================================================================================================
function cutAtName($message){
  // save the color byte for later
  if (substr($message,0,1)==="[" )  $colorBytes = substr($message,0,5);
  
  $backupMessage=$message;
  // find the first space or colon or semicolon
  $p=0;
  while (1) {
    if (substr( $message, 0, 1 ) === " " or substr($message,0,1)===":" or substr($message,0,1)===";") break ;
      $message = substr($message,1);
      # prevent never ending loop (It does seem to happen some how)
      if ( $p++ > 20 ) {
		  #something is wrong here. restore the message
		  $message = $backupMessage;
		  break;
		  }
      }

    $message = $colorBytes . substr($message,1);
    return $message;
}

// =================================================================================================================
function outputMessage($rowid){
	global $conn;
	global $lastprivate;
	global $regid;
	global $system_regid;
	global $timeoffset;
	global $previousPrivate;
	global $yourNickName;
	
	
	$private=true;
	$sql = "select * from messages where rowid='".$rowid."'";
	 
	$result = $conn->query($sql);
	
	if ($row = $result->fetch_assoc()) {
		 
		$messageLine = trim($row["message"]);
		$messageLine = ltrim($messageLine);
		$messageLine = str_replace("                                        ", "", $messageLine);
        $senders_regid=$row["regid"];
	    $localtime = $row["timestamp"];
	    
	    
	    // Get the offset of this server from UTC	    
	    date_default_timezone_set("GMT");	    	// this is UTC timezone
		$dateTimeGMT = date('Y-m-d H:i:s'); 
		
		date_default_timezone_set("CET");		    // this is the locals servers timezone   
		$dateTimeLocal = date('Y-m-d H:i:s');  		 
		    
		$date1 = strtotime($dateTimeGMT);
		$date2 = strtotime($dateTimeLocal);
		$diff = $date2 - $date1;					// diff is the offset in seconds
		
		
		date_default_timezone_set("CET"); 			// restore our timezone
		
		// calculate UTC time from the value in the database
		$timeoffset = str_replace(",", ".", $timeoffset);
		$timeoffset = floatval($timeoffset);
		$localtime = strtotime($row["timestamp"]) - $diff + ($timeoffset * 3600);
		$localtime =  date('y-m-d H:i',$localtime);
		$channel='private';
		// system message
		if ($row["regid"] == $system_regid){
			// this is a system message	
			writeLog(">>>>>>>>>> SYSTEM");
			$channel='public';
			$message=trimMessage($messageLine); 	
			writeLog($message);
		} elseif (($row["recipient"] ==  $regid) or ($row["regid"]==$regid and is_null($row["recipient"])==false )) {
			// private message
			$channel='private';
			$messageLine = cutAtName($messageLine);
			
			# remove point or comma from sendername
			$senderName= $row["sendername"];
			$senderName= str_replace(".", "", $senderName);
			$senderName= str_replace(",", "", $senderName);
			
			# remove point or comma from recipientname
			$recipName= $row["recipientname"];
			$recipName= str_replace(",", "", $recipName);
			$recipName= str_replace(".", "", $recipName);
			
			$senderRegId=$row["regid"];
			if (str_contains($messageLine, "^c^")){
				// Skip the header so the messages are stiched together
				$message=trimMessage($messageLine);
				$message=str_replace("^c^","",$message);
			}
			else {
				// create the header text for a private message:
				// On the ZX Spectrum the line length is to short so we need to cut some data
				if (strtolower($senderName)==strtolower($yourNickName)) { // If the message is FROM you
					$message="[151]" . $localtime . " @" . $recipName ;
			    } else {  // Message if TO you
					$message="[151]" . $localtime . " from " . $senderName ;
			    }
			    				
				$message=str_pad($message,45).$messageLine;				
				$message=trimMessage($message);
				 
			}
			
		} else {
			// public message
			$channel='public';
			// create the header text for a public message:
			$message="[151]". $localtime . " " . $row["sendername"] .":";			
			
			$message=str_pad($message,45).$messageLine;
			
			$message=trimMessage($message);
			
		}
		
		// get the message length and replace the higher bytes (that contain color information)
		list($message,$len)=replace_higher_bytes($message); 
	    
	    // reduce line length to 32 (if possible), and return the new length
	    list($message,$len) = trim_40_to_32($message,$len);
	    
	    
		// calculate the number of lines.
		$len = ceil($len/32); 
		// build the json encoded string for output
		$message=base64_encode($message);
		
		// count the number of available private messages. We can not use $lastprivate for this because that will be zero at the start of every session
		// $previousPrivate is stored in eeprom so that contains the last private message id, even from the previous session.
		
		$pm=countPrivateMessages($regid,$previousPrivate); 
		
		$out=array('rowid' => $row["rowid"] , 'timestamp'=> $localtime, 'message' => $message, 'regid' => $regid ,'nickname'=>$row["sendername"] ,'lines'=>$len,'pm'=>$pm,'channel'=> $channel);
		 
 
		// output the row
		if (count($out) > 0 ) {
			echo json_encode($out);
			writeLog(json_encode($out));
		}
	}
	
}
// =================================================================================================================
function writeLog($log_msg) {
    global $scriptName;
    date_default_timezone_set("CET");
    $date = date('d-m-y H:i:s');
    $log_msg = $date . " " . $log_msg;

    $log_filename = $_SERVER['DOCUMENT_ROOT']."/log";
    if (!file_exists($log_filename))
    {
        // create directory/folder log.
        mkdir($log_filename, 0777, true);
    } 
     
    $log_file_data = $log_filename.'/log_'.$scriptName.'_'. date('d-M-Y') . '.log';
    file_put_contents($log_file_data, $log_msg . "\n", FILE_APPEND);
}

?>
