<?php
// Handle POST request
$branch=1; // the default branch is 1, the stable branch

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    if (isset($_POST["branch"])) $branch = intval($_POST["branch"]);    
}

if ($branch==1) {
echo (file_get_contents('./update/c64version.txt'));
} else {
echo (file_get_contents('./update/c64version_debug.txt'));
}
?>
