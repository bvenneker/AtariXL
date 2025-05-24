<?php
//Sven Pook v2
//may 7, 2024 BV added retry count


require_once('../dbCredent.php');

$scriptName="insertMessage";

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {

    // Sanitize input data
    $regid = test_input($_POST["regid"]);
    $call="";
    if (isset($_POST["call"])) $call = test_input($_POST["call"]);
    
    if ($call == "heartbeat") {
        // Update last seen field for the user
        $sql = "UPDATE users SET lastseen = " . time() . " WHERE regid = '$regid'";
        if ($conn->query($sql) === TRUE) {
            echo "0";
        } else {
            echo "1"; // Error updating last seen
        }
        $conn->close();
        exit();
    }
    
    $retryCount=0;
    if (isset($_POST["retryCount"])) $retryCount = test_input($_POST["retryCount"]); 
    if (isset($_POST["sendername"])) $sendername = test_input($_POST["sendername"]);    
    if (isset($_POST["recipientname"])) { 
		$recipientname = test_input($_POST["recipientname"]);
		$recipientname = mb_convert_case($recipientname, MB_CASE_TITLE, "UTF-8");
	}
    $message = test_input($_POST["message"]);

    // Decode base64 encoded message
    $message = base64_decode($message);
	
	
    // delete the last char if it is not printable
    if (ctype_print(substr($message, -1))==False){
        $message = substr_replace($message, '', -1);
    }
		
    // Escape special characters to prevent SQL injection
    $sendername = $conn->real_escape_string($sendername);
    $recipientname = $conn->real_escape_string($recipientname);
    $message = $conn->real_escape_string($message);
	writeLog("sendername    = " . $sendername);
	writeLog("recipientname = " . $recipientname);
	writeLog("message       = " . $message);
	writeLog("retrycount    = " . $retryCount);
	
    // Prepare recipient ID
    $recipientID = "";

    // Insert message
    // if retryCount > 0, check if the message is allready in the database, not older that 10 seconds
    if ($retryCount>0){
		$sql="select * from messages where timestamp > DATE_SUB(NOW(),INTERVAL 10 SECOND) and regid='$regid' and message='$message' limit 1";
		$result = $conn->query($sql);
		$rc = $result->num_rows;
        if ($rc > 0) {
            echo "0"; // Message sent successfully (allready in database)
            $conn->close();
            exit();
        }
    }
		
		
    if (empty($recipientname)) {		
        $sql = "INSERT   INTO messages (sendername, regid, message, retry) VALUES ('$sendername', '$regid', '$message',$retryCount)";
    } else {
        $sql = "SELECT regid FROM users WHERE nickname = '$recipientname'";
        $result = $conn->query($sql);
        if ($result->num_rows > 0) {
            $row = $result->fetch_assoc();
            $recipientID = $row["regid"];
        }
        if ($recipientID != "") {
            $sql = "INSERT INTO messages (sendername, regid, recipientname, recipient, message,retry) VALUES ('$sendername', '$regid', '$recipientname', '$recipientID', '$message',$retryCount)";
        } else {
            echo "3"; // Recipient not found
            $conn->close();
            exit();
        }
    }

    if ($conn->query($sql) === TRUE) {		
        echo "0"; // Message sent successfully
        writeLog("Message inserted successfully");
    } else {
        echo "1"; // Error inserting message
        writeLog("Error inserting message");
    }
    $conn->close();
}

function test_input($data)
{
    $data = trim($data);
    $data = stripslashes($data);
    $data = htmlspecialchars($data);
    return $data;
}

// =================================================================================================================
function writeLog($log_msg) {
    global $scriptName;
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
