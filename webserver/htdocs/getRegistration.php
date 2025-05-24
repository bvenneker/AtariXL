<?php
//Sven Pook v2
require_once('../dbCredent.php');
$scriptName = 'getRegistration';
if ($_SERVER["REQUEST_METHOD"] == "POST") {
	writeLog(implode(',', $_POST));
    // Validate and sanitize input data    
    $macaddress = test_input($_POST["macaddress"]);
    $regid = test_input($_POST["regid"]);
    $nickname = test_input($_POST["nickname"]);
    $version = test_input($_POST["version"]);

    // Check if the registration status is valid
    if (get_registration_status($macaddress, $regid)) {
        // Check for a bad nickname
        if (check_bad_nick_name($regid, $nickname)) {
            echo "r105"; // Bad nickname
        } else {
            // Update user information
            if (update_user($regid, $nickname, $version)) {
                echo "r200"; // Success
            } else {
                echo "r500"; // Database error
            }
        }
    } else {
		// No post data??
        echo "r104"; // Invalid registration
    }
}

// Function to check registration status
function get_registration_status($macaddress, $regid) {
    global $conn,$nickname;

    writeLog("Nickname = $nickname, regid = $regid, mac = $macaddress");
    
    // Prepare and execute the SQL query using a prepared statement
    $sql = "SELECT * FROM users WHERE blocked = 0 AND regid = ? AND mac = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ss", $regid, $macaddress);
    $stmt->execute();
    $result = $stmt->get_result();
 
    // Check if a single row is returned
    if ($result->num_rows == 1) {
        return true;
    } else {
        return false;
    }
}

// Function to check for bad nickname
function check_bad_nick_name($regid, $nickname) {
    global $conn;
    // Prepare and execute the SQL query using a prepared statement
    $sql = "SELECT * FROM users WHERE regid <> ? AND nickname = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ss", $regid, $nickname);
    $stmt->execute();
    $result = $stmt->get_result();

    // Check if a single row is returned
    if ($result->num_rows == 1) {
        return true;
    } else {
        return false;
    }
}

// Function to update user information
function update_user($regid, $nickname, $version) {
    global $conn;

    // Prepare and execute the SQL query using a prepared statement
    $sql = "UPDATE users SET nickname = ?, version = ? WHERE regid = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("sss", $nickname, $version, $regid);
    if ($stmt->execute()) {
        return true;
    } else {
        return false;
    }
}

// Function to sanitize input data
function test_input($data) {
    $data = trim($data);
    $data = stripslashes($data);
    $data = htmlspecialchars($data);
    return $data;
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
