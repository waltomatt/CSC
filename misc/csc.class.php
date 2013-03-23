<?php
	class CSC {
		private $host;
		private $password;
		private $port;
		private $id;

		/**
		 * Constructor for CSC class
		 * 
		 * @param		string	$host
		 * @param		int		$port
		 * @param		string	$password
		 * @param		string	$id
		 * @return		void
		 *
		 **/

		function __construct($host, $port, $password, $id) {
			$this->host = $host;
			$this->port = $port;
			$this->password = $password;
			$this->id = $id;
		}

		function send($name, $message) {
			if ($this->host and $this->port and $this->password and $this->id and $name) {
				$fp = fsockopen($this->host, $this->port);
				$res;
				if ($fp) {
					$str = "$this->password\n$this->id\n$name\n$message";
					fwrite($fp, $str);
					$res = fread($fp, 64);
					fclose($fp);
				} else {
					$res = "could not connect";
				}
				return $res;
			}
		}

		function setHost($host) {
			$this->host = $host;
		}

		function setPort($port) {
			$this->port = $port;
		}

		function setPassword($password) {
			$this->password = $password;
		}

		function setID($id) {
			$this->id = $id;
		}
	}
?>
