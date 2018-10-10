<?php
$host = "127.0.0.1";
$port = 8080;
$message = "Hello Server";
echo "Message To server :\n" . $message;
$socket = null;
$sockets = [];
// create socket
for ($i = 0; $i <= 1000; $i++) {
    $socket = socket_create(AF_INET, SOCK_STREAM, 0) or die("Could not create socket\n");
// connect to server
    $result = socket_connect($socket, $host, $port) or die("Could not connect to server\n");  
// send string to server
    socket_write($socket, $message, strlen($message)) or die("Could not send data to server\n");
    socket_close($socket);
    echo "sending request ".$i;
    sleep(1000);
    $sockets[$i] = $socket;
}
for ($x = 1000; $x >= 0; $x--) {
// get server response
    $result = socket_connect($socket[$x],$host,$port) or die("could not connect to the server");
    $result = socket_read($sockets[$x], 1024) or die("Could not read server response\n");
    echo "Reply From Server  :" . $result . "" . $x . "\n";
// close socket
    socket_close($sockets[$x]);
}
?>