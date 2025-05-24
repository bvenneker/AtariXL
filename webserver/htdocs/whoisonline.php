<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);
  require_once('../dbCredent.php');
  // Check db connection
  if ($conn->connect_error) { die("Connection failed: " . $conn->connect_error);}
?>
<!DOCTYPE html> 
<html lang="en">
  <head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8">
    <title>Chat64</title>
	<style type="text/css">
	
	html{color:#FFF;background:#000;}
    
    @font-face { font-family: Kollektif; src: url('fonts/Kollektif-Bold.ttf'); } 
      
#page{
	font-family: Kollektif, monospace; 
	margin: auto;
	width: 1500px;	 
	position: relative;
	}
	
#header{
	text-align: center;
	position: relative;
	top:20px;
	}
	
#stripes{
	text-align: center;
	position: relative;
	background-image: url("img/p2.png");
	height: 70px;
	width: 1500px;
	top:20px;
	}
#homebutton{
	position: relative;
	
	background-image: url("img/homeb.jpg");
	height:44px;
	width:166px;
	top:-100px;
	}	
#homebutton:hover{
		background-image: url("img/homea.jpg") !important;
		cursor:pointer; 
	}
#table1,#table2,#table3{		
	width:100%;
	font-family: Kollektif, monospace; 
	font-size: 25px;
	color:#ff66c4;
	 
	}
	
#table1 tr td,#table2 tr td, #table3 tr td{vertical-align: top; text-align: left}
#table1 th,#table2 th, #table3 th {font-size: 40px; text-align: left}
#table1  tr td:nth-child(3),#table2 tr td:nth-child(3), #table3 tr td:nth-child(3) {
    text-align: right;  
}


.mylinks{
	border-bottom:4px solid black;	 
	}
.mylinks:hover{
	border-bottom:4px solid #ff66c4;	
	cursor:pointer; 
	}

#table1 tr td:nth-child(2) {
    text-align: center;  
}

#smdinfo, #thtinfo, #devinfo{
	font-size: 18px;
	display: none;
	border:0px solid white;	
	width: 1000px; 
	position:relative;
}
#smdinfo{
	left:0px;
	}

#thtinfo{
	left:0px;;
	}

#devinfo{
	left:0px;
	}

#menutable td {
	padding: 0px;
	line-height: 1px; 
	overflow:hidden;
	}


#m1:hover{
	content: url("img/m1a.jpg")
	}
#m2:hover{
	content: url("img/m2a.jpg")
	}
#m3:hover{
	content: url("img/m3a.jpg")
	}
#m4:hover{
	content: url("img/m4a.jpg")
	}
#m6:hover{
	content: url("img/m6a.jpg")
	}
#m7:hover{
	content: url("img/m7a.jpg")
	}
#c64{
	position:relative;
	top:-160px;
	}
#gif1{
	position:relative;
	left:-160px;
	}

	.usertable1{
		position: relative;
        width:800px;
		font-family: Kollektif, monospace; 
		font-size: 30px;
		color: #cb6ce6;
		border-style: solid;
		border-color: #cb6ce6;;
		
	}
#menutable{
	position: relative;
	top:-25px;
	}	
	
	
.offline {color:white;}

.online {color:#7aad5c;}

</style>

</head>
  <body>
	<div id="page">
		<div id="header"><img src="img\p1.png" alt="chat64.nl" title="chat64"></div>
		<div id="stripes"></div>
		<div id="homebutton" onclick="location.href='index.html';"></div>		 
		<table id="table1">
			<tr>
				<td>
					<table id="menutable">
						<tr><td><a href="regpagex.php"><img id="m1" src="img/m1.jpg" alt="register your cartridge"></a></td></tr>
						<tr><td><a href="about.php"><img id="m2" src="img/m2.jpg" alt="About Chat64"></a></td></tr>
						<tr><td><a href="whoisonline.php"><img id="m3" src="img/m3.jpg" alt="Who is on line"></a></td></tr>
						<tr><td><a href="downloads.php"><img id="m4" src="img/m4.jpg" alt="Downloads"></a></td></tr>
						<tr><td><a href="manuals.php"><img id="m7" src="img/m7.jpg" alt="Manuals"></a></td></tr>
						<tr><td><a href="shops.php" Target="_BLANK"><img id="m6" src="img/m6.jpg" alt="Shop"></a></td></tr>
						<tr><td height="100px;">&nbsp;</td></tr>
						<tr><td style="text-align:right;"><img src="img\p7.png" alt="chat cartridge"></td></tr>
					</table>
				</td><td> 
				<div id="usertable" class="usertable1">
				  <table style="width:100%;">
					<tr><td colspan=2 style="text-align:center;">WHO IS ONLINE?</td></tr>
					<tr><td colspan=2 style="text-align:center;font-size: 20px;">Green users are online, white users are offline</td></tr>
					<?php
					$c=1;
					$limit=2;
					$offset=0;
					$theclass='offline';
					while($c==1){
						echo '<tr>';
						$sql="select nickname ,lastseen  from users where nickname is not null and blocked=0 order by nickname LIMIT ".$limit." OFFSET ". $offset;
						$result=$conn->query($sql);
						$c=0;
						while($row=mysqli_fetch_assoc($result)) {
							if ( time() - $row['lastseen'] < 30 )  $theclass="online"; else $theclass="offline";
							echo '<td class="'.$theclass.'" style="text-align:center;">'.$row['nickname'].'</td>';	
							$c=1;
						}
						$offset = $offset + $limit;
						echo '</tr>';
					}
					?>

				  </table>
      </div>
				
				</td>
			</tr>
		</table>
</body>
</html>
