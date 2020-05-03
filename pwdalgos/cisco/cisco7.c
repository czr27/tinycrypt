

// Cisco Type 7 password algorithm
// Odzhan

#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#define MAX_PWD 25

#define BIN2HEX(x) (x < 10) ? (x + '0') : (x + '7')
#define HEX2BIN(x) (x - '0' < 10) ? (x - '0') : (x - '7')

char static_key[]="dsfd;kfoA,.iyewrkldJKDHSUBsgvca69834ncxv";

int main (int argc, char *argv[])
{
  size_t   i, len;
  char     *pwd, *salt;
  int      idx;
  uint32_t x, c;
  char     r[128];
  
  if (argc < 2) {
    printf ("\n  usage: cisco7 <password> <2 byte salt>\n");
    return 0;
  }
  
  memset (r, 0, sizeof r);
  
  if (argc==3) {
    x=atoi (argv[2]) % 16;
  } else {
    srand (time (0));
    x=rand () % 16;
  }
  r[0]= (x / 10) + '0';
  r[1]= (x % 10) + '0';

  pwd=argv[1];
  len=strlen (pwd);
  len=(len > MAX_PWD) ? MAX_PWD : len;
  
  for (i=2; i<=len*2; i+=2) {
    c=pwd[i/2-1] ^ static_key[x++];
    r[i+0] = BIN2HEX((c >> 4));
    r[i+1] = BIN2HEX((c & 15));
  }
  printf ("\n  Cisco Type 7 : %s\n", r);
  return 0;
}

