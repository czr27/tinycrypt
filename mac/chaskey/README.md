## About ##

**Chaskey Message Authentication Code**

- **chaskey.c**

Size optiimized functions to generate MAC from message

	void chas_setkey(void *out, void *in);
	void chas_mac(uint8_t *tag, uint8_t *msg, uint32_t msglen, uint8_t *key);

- **cx.asm**

x86 assembly code based on **chaskey.c** using stdcall convention

- **cxx.asm**

x86-64 assembly based on **chaskey.c** using Microsoft fastcall convention.
 
## Code Sizes ##

<table>
  <tr>
    <th>cpu</th>
    <th>setkey + mac<br></th>
  </tr>
  <tr>
    <td>x86</td>
    <td>229</td>
  </tr>
  <tr>
    <td>x86-64</td>
    <td>132</td>
  </tr>
</table> 

## Author ##

[@odzhancode](https://www.twitter.com/odzhancode "Follow me on Twitter")

3/10/2017 2:28:46 PM 
