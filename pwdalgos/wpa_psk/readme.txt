   WPA-PSK replaces WEP keying as a method of authentication to
   home WIFI network where RADIUS server is un-necessary.

   The PMK (Pairwise Master Key) used for encrypting traffic is shared
   between the authenticator (router) and supplicant (client).

   This module is NOT for attacking the authentication data, but the actual
   PMK used to generate a PTK (Pairwise Transient Key) in a 4 way handshake.
   Whether or not module is useful in the real world remains to be seen, feedback
   is welcome.

   The algorithm itself is based on RSA PKCS#5 Version 2.0, involving
   8192 rounds of HMAC-SHA1.

   PMK = PBKDF2(passphrase, ssid, ssidLength, 4096, 32)

   Internally, the bulk of computations are carried out in the SHA-1 Transform
   routine, which is invoked a staggering 32,768 times, making PSK reasonably strong
   against offline brute force/dictionary attacks.