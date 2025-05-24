<?php
require_once('../dbCredent.php');
//Sven Pook v2


// Set default values
$page = 0;
$pagesize=20;
$call = "";
$listversion = "1";
$regid = "";

// Handle POST request
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $regid = test_input($_POST["regid"]);
    if (isset($_POST["page"])) $page = intval($_POST["page"]);
    if (isset($_POST["call"])) $call = test_input($_POST["call"]);
    if (isset($_POST["version"])) $listversion = test_input($_POST["version"]);
    if (isset($_POST["pagesize"])) $pagesize = test_input($_POST["pagesize"]);
} else {
	$page=0;
	$pagesize=15;
	$regid ='9be50aa7d280712f';
	}

if (strlen($regid) != 16) exit();
// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// update the lastseen column (heartbeat)
$sql = "UPDATE users SET lastseen = " . time() . " WHERE regid = '$regid'";
$conn->query($sql);


$offset = $page * $pagesize;

if ($call == "list") {
    echo get_list_of_users_in_text();
} else {
    echo get_list_of_users_in_petsci($offset, $pagesize);
}

//Functions
function get_list_of_users_in_text()
{
    global $conn;
    $list = "";
    $sql = "SELECT nickname FROM users WHERE nickname IS NOT NULL AND blocked = 0";
    $result = $conn->query($sql);
    while ($row = $result->fetch_assoc()) {
        $list .= $row['nickname'] . ';';
    }
    return strtolower($list);
}

function get_list_of_users_in_petsci($offset, $pagesize)
{
    global $conn, $regid,$pagesize;
    $sql = "SELECT nickname, lastseen, regid FROM users WHERE nickname IS NOT NULL AND blocked = 0 ORDER BY nickname LIMIT ? OFFSET ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ii", $pagesize, $offset);
    $stmt->execute();
    $result = $stmt->get_result();
    $colmwidth=10;
    $screen = "";
    $uc=0;    
    if ($pagesize == 15)$colmwidth=13;
    
    
    while ($row = $result->fetch_assoc()) {
        $nn =     $row['nickname'];
        if ((time() - $row['lastseen'] < 30) or ($regid == $row['regid'])) {// invert  online users
          $nn = invertText($nn);  
        }
        
		
        
        
        $screen .= $color . str_pad($nn, $colmwidth);
        if(++$uc % 3 == 0) $screen .= " ";
    }
    if ($screen == "") $screen = " ";
    return $screen;
}
function invertText($str)
{
	// This is only for Atari
	$nt = "";
	foreach (str_split($str) as $char) {
     $nt .= chr(128 + ord($char));
    }
    return $nt;
}
function test_input($data)
{
    $data = trim($data);
    $data = htmlspecialchars($data);
    return $data;
}
?>


