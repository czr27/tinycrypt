

* RAW-SHA-1($password) - Mac OS 10.3 'Panther'
* SHA-1(UNICODE($password).$salt) - MS SQL 2000/2005 (2000 uses uppercase passwd!)
* SHA-1($password.$salt) - ORACLE 11g (the salt is currently 10 bytes)
* SHA-1($username.$password) - PHP
* SHA-1($salt.$password) - Mac OS 10.4 'Tiger'