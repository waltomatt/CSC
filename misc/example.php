<?php
    require_once("csc.class.php");

	$chat = new CSC("127.0.0.1", 13375, "abc12", "WEB");
	$chat->send("Matt", "Hello world!");

    $chat->get(5); // Gets the last 5 messages
?>