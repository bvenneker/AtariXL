<?php
require_once('../dbCredent.php');

if ($_SERVER["REQUEST_METHOD"] == "POST") {
  $regid = test_input($_POST["regid"]);
}

// Check connection
if ($conn->connect_error) {
  die("Connection failed: " . $conn->connect_error);
}

// update the last seen field in the users table so we can know this user is online
if ($regid != "656b34609c") {
  $sql="update users set lastseen=".time()."  where regid='".$regid."'";
  $conn->query($sql);
}

function test_input($data) {
    $data = trim($data);
    $data = stripslashes($data);
    $data = htmlspecialchars($data);
    return $data;
}

?>
