## About ##

**SPECK block cipher**

The functions with 'x' at the end is setkey/encrypt combined in one call.

- **speck64.c**

64-bit block size, 128-bit keys

	void speck64_setkey(const void *in, void *out);
	void speck64_encrypt(int enc, void *in, const void *keys);
	void speck64_encryptx(void *in, const void *keys);

- **speck128.c**

128-bit block size, 256-bit keys

	void speck128_setkey(const void *in, void *out);
	void speck128_encrypt(int enc, void *in, const void *keys);
	void speck128_encryptx(void *in, const void *keys);

- **spk64.asm**

x86 assembly code based on **speck64.c** using 32-bit stdcall convention.<br>
See bld32.bat for example of how to compile.

- **spk128.asm**

x86-64 assembly based on **speck128.c** using Microsoft fastcall convention.<br>
See bld64.bat for example of how to compile.
 
## Code Sizes ##

<table>
  <tr>
    <th>cpu</th>
    <th>setkey + encrypt + decrypt<br></th>
    <th>setkey + encrypt</th>
  </tr>
  <tr>
    <td>x86</td>
    <td>105</td>
    <td>64<br></td>
  </tr>
  <tr>
    <td>x86-64</td>
    <td>132</td>
    <td>86</td>
  </tr>
</table> 

