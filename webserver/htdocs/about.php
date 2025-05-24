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

#table1 tr td:nth-child(1) {
    text-align: center;  
    width:500px;
}
#table1 tr td:nth-child(2) {
    text-align: left;  
    color: white; 
    font-size: 20px;
    
}
h2,h1,h3 {
	color: #ff66c4;
	}

h3 {
	color: cyan;
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

#imgMega65{
	position: relative;
	top:-200px;
	left:470px;
	z-index:-1;
	}

#mk2{
	position: relative;
	top:-300px;
	}
#imgMk2{
	position: relative;
	top:-20px;
	left:470px;
	z-index:-1;
	}	
#u64{
	position: relative;
	top:-250px;
	}
#imgU64{
	position: relative;
	top:-180px;
	z-index:-1;
	}
#ZX48{
	position: relative;
	top:-250px;
	}
#imgZX48{
	position: relative;
	top:-280px;
	z-index:-1;
}
#media{
	position: relative;
	top:-300px;
	}
a:link {color: white;}
a:visited {color: white;}
a:hover {color: #cb6ce6;}

</style>

</head>
  <body>
	<div id="page">
		<div id="header"><img src="img\p1.png" alt="chat64.nl" title="chat64"></div>
		<div id="stripes"></div>
		<div id="homebutton" onclick="location.href='index.html';"></div>		 
		<table id="table1" border=0>
			<tr>
				<td>
					<table id="menutable">
						<tr><td><a href="regpagex.php"><img id="m1" src="img/m1.jpg" alt="register your cartridge"></a></td></tr>
						<tr><td><a href="about.php"><img id="m2" src="img/m2.jpg" alt="About"></a></td></tr>
						<tr><td><a href="whoisonline.php"><img id="m3" src="img/m3.jpg" alt="Who is online"></a></td></tr>
						<tr><td><a href="downloads.php"><img id="m4" src="img/m4.jpg" alt="Downloads"></a></td></tr>
						<tr><td><a href="manuals.php"><img id="m7" src="img/m7.jpg" alt="Manuals"></a></td></tr>
						<tr><td><a href="shops.php" Target="_BLANK"><img id="m6" src="img/m6.jpg" alt="Shop"></a></td></tr>
						<tr><td height="100px;">&nbsp;</td></tr>
						<tr><td style="text-align:right;"><img src="img\p7.png" alt="chat cartridge"></td></tr>
					</table>
				</td><td> 
				<div id="story" class="story">
				<p>
				<h2>How it started</h2>
				Back in 2019 Bart created the first chat cartridge as a proof of concept.<br>
				Unlike today's cartridge, this first version did not use the ESP32, it used an Arduino Nano with an ESP8266 Serial module for the WiFi communication.
				The project evolved, and in 2021 it was ready for larger-scale testing. Bart crafted 10 cartridges and distributed them freely to anyone eager to partake in the experiment.<br>
				A few successful chat sessions were done, but it was quite a slow process.<br>
				Here is a picture of what it looked like back then:<br>
				<img src="img/2021_chat.png" width="700px" alt="Start screen in 2021">
				<br>
				The start screen was in black and white, but the chat screen was nice and colorful.<br>
				<br>
				<h2>Version 2.0, a fresh start</h2><br>
				In 2023, Theo got in touch with Bart and convinced him to revive the Chat64 project. 
				They teamed up to redesign the hardware and rewrite the software from scratch.<br>				
				They introduced new functionality such as private chat and even an A.I. Chatbot.<br>
				The hardware and all software is now open source and available on Github.<br>
				<table style="text-align: center;font-style: italic;font-size:12px;">
				<tr>
					<td>
						<img src="img/BartandTheo.png" width="350px" alt="Bart and Theo">
					</td>
					<td>
						<img src="img/theo.png" width="350px" alt="Theo">
					</td>
				</tr>
				<tr><td style="text-align: center;font-style: italic;font-size:15px;">Bart and Theo testing software</td>
				<td style="text-align: center;font-style: italic;font-size:15px;">Theo soldering a proto type</td></tr>
				</table>
				<h2>Features</h2><br>
                The main feature of the cartridge is communications, users from various 8-bit computers can chat in a single room. Additionally, users can send private messages to each other for one-on-one conversations. 
                And if there’s no one around to chat with, don’t worry—Eliza, our A.I. chatbot, is always available. Ask her anything and enjoy an engaging conversation!<br><br>
                &nbsp;&nbsp;> Chat with other 8-bit enthusiasts across multiple platforms.<br>
                &nbsp;&nbsp;> Unlock the power of A.I. with Eliza, our interactive chatbot.<br>
                &nbsp;&nbsp;> The cartridge get automatic updates from our webserver, it stays up to date!<br>                

                <h2>Eliza</h2><br>
                Eliza is our A.I. chatbot, unlike the old Eliza you may remember from back in the day. This is true A.I.—Eliza on steroids, if you will.<br>
                Here is a bit of conversation with Eliza:<br>
                <img id="elizachat2" src="img/ElizaChat2.png" width="550px" alt="eliza screenshot">
				<h2>Tested platforms</h2><br>
				The Chat64 cartridge was developed for the original C64 hardware but can be used on modern C64 compatible platforms as well.<br>
				We know the cartridge works well on the following systems:<br>
				<div id="orghw">
				<h3>Original Hardware</h3>
				The Cartridge has been tested on most revisions of the original Commodore 64 and Commodore 64c.<br><br>
				<img id="breadbin" src="img/c64_breadbox.png" width="350px" alt="c64"><br>
				</div>
				<div id="c128">
					<h3>The C128 and C128D</h3>
					Users have reported full functionality on the C128 and C128D.<br>
					<img id="imgc128" src="img/Commodore128small.png" width="350px" alt="c128"><br>
				</div>
				<div id="mega65">
				<h3>The Mega65</h3>
				Users have reported mixed results on the Mega65.<br>
				<br>
				The bus timing of the Mega65 is not fully compatible<br>with the real hardware.<br>
				We are investigating a solution for that.<br>
				<br>
				<br>
				For more info about the Mega65, goto: <a href="https://mega65.org/" target="_BLANK">mega65.org</a><br>
				<img id="imgMega65" src="img/mega65.png" width="350px" alt="mega65"><br>
				</div>
				
				<div id="mk2">
				<h3>The C64 Reloaded MK2</h3>
				Users have reported full functionality on the C64 Reloaded MK2.<br>
				More info about the Reloaded MK2:<br> <a href="http://wiki.icomp.de/wiki/C64_reloaded_mk2" target="_BLANK">http://wiki.icomp.de/wiki/C64_reloaded_mk2</a><br>
				<img id="imgMk2" src="img/mk2.png" width="250px" alt="C64reloadedMk2">
				</div>
				
				<div id="u64">
				<h3>The Ultimate64</h3>
				Users have reported full functionality on different versions of the Ultimate64 (elite).<br>
				Note that the cartridge uses its own Wi-Fi connection and does not utilize the Ultimate64's network capabilities.<br><br>
				<br>
				<br>
				<br>
				<br>
				<br>
				<br>
				More info: <a href="https://ultimate64.com/" target="_BLANK">https://ultimate64.com/</a><br>
				<img id="imgU64" src="img/Ultimate64.png" width="750px" alt="Ultimate64">
				</div>

				<div id="ZX48">
				<h3>ZX Spectrum 48k</h3>
				The ZX Spectrum cartridge has been develloped for the 48k version of the original ZX Spectrum<br>
                We have tested this cartridge on several version 3 mainboards and a version 1 mainboard without issues.<br>
                <br>The 16k spectrum model will not work, we need the extra memory for fast switching between the chats and from chat to menu and back<br>
                <br>
				<br>

				
				<img id="imgzx48" src="img/SinclairZX48.png" width="350px" alt="48k ZX Spectrum">
                <br><br>
                <h3>ZX Spectrum 128k (toastrack)</h3>
                We have not tested this personally but other users have reported full functionality on the ZX Spectrum 128k<br>
                <img id="imgzx128" src="img/ZX_Spectrum128K.png" width="450px" alt="ZX Spectrum 128k">

                <h3>Harlequin 128k</h3>
                We have not tested this personally but other users have reported full functionality on the Harlequin 128k<br>
                <img id="imgzx128" src="img/Harlequin.jpg" width="350px" alt="Harlequin 128k">
                <br><br><br>
				</div>


				<div id="media">
				<h1>Media</h1>
				<h2>Retro Recipes</h2>
				In 2024 the Chat cartridge got featured on Perifractic's Retro Recipes:<br>
				<iframe width="560" height="315" src="https://www.youtube.com/embed/dWEfEXVNXZk?si=x8Y0YeKzSV82fm91" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
				<br><br><h2>Zapp!64</h2>
				<table>
				<tr><td>Chat64 was covered as a new flash article in Zapp!64, issue 19 Mar-Apr 2024</td><td><img id="zapp64" src="img/zapp!64.jpg"></td></tr>
				</table>
				</div>
				</p>
				  
				</div>
				
				</td>
			</tr>
		</table>
</body>
</html>
