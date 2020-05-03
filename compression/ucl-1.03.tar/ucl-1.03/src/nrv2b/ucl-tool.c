/*
 * This tool is public domain (or GPL to comply with libucl licence, up to you).
 *
 * Requires libucl to compile.
*/

#include <stdio.h>
#include <string.h>

#include "ucl.h"

#define MAX_SIZE 65536

ucl_byte buffer[MAX_SIZE];

#define MAX_OVERLAP 512

int
main(int argc, char *argv[])
{
        FILE *fd_out, *fd_in;
  ucl_uint in_len = 0;
  ucl_uint out_len, overlap, tmp_len;
  ucl_byte *in;
  ucl_byte *out;
  ucl_byte with_len = 0;

  if (ucl_init() != UCL_E_OK)
  {
    fprintf(stderr, "ucl: failed to init UCL\n");
    return 1;
  }

        if (argc < 3 || argc > 4)
        {
exit_error:
            fprintf(stderr, "ucl: usage [-s] <input file> <output file>\n");
            return 1;
        }

  if (argc == 4)
        {
            if (!strncmp(argv[1], "-s", 2))
    with_len = 1;
            else
                goto exit_error;
        }

        fd_in = fopen(argv[1 + with_len], "rb");
        if (!fd_in)
        {
            fprintf(stderr, "ucl: failed to read input\n");
            return 1;
        }

  while(!feof(fd_in) && in_len < MAX_SIZE)
    buffer[in_len++] = getc(fd_in);

        if (in_len == MAX_SIZE && !feof(fd_in))
        {
            fclose(fd_in);
            fprintf(stderr, "ucl: input file is larger than 64K\n");
            return 1;
        }

        fclose(fd_in);

  in_len--;

        fd_out = fopen(argv[2 + with_len], "wb");
        if (!fd_out)
        {
            fprintf(stderr, "ucl: failed to write output\n");
            return 1;
        }

  out_len = in_len + in_len / 8 + 256;

  in = ucl_malloc(in_len + MAX_OVERLAP);
  out = ucl_malloc(out_len + MAX_OVERLAP);
  if (!in || !out)
  {
    fprintf(stderr, "ucl: out of memory\n");
    return 1;
  }

  memcpy(in, buffer, in_len);

  if (ucl_nrv2b_99_compress(in, in_len, out, &out_len, NULL, 10, NULL, NULL) != UCL_E_OK)
  {
    fprintf(stderr, "ucl: compress error\n");
    return 1;
  }

  if (out_len >= in_len)
  {
    fprintf(stderr, "ucl: content can't be compressed\n");
    return 1;
  }

  if (with_len)
    fwrite(&out_len, 2, 1, fd_out);

  fwrite(out, 1, out_len, fd_out);
  fclose(fd_out);

  /* test overlap */
  for (overlap = 0; overlap < MAX_OVERLAP; overlap++)
  {
    memcpy(in + overlap + in_len - out_len, out, out_len);
    tmp_len = in_len;
    if (ucl_nrv2b_test_overlap_8(in, overlap + in_len - out_len, out_len, &tmp_len, NULL) == UCL_E_OK && tmp_len == in_len)
      break;
  }

  ucl_free(out);
  ucl_free(in);

  if (overlap == MAX_OVERLAP)
  {
    fprintf(stderr, "ucl: no valid overlap found\n");
    return 1;
  }

  fprintf(stderr, "ucl: %i bytes compressed into %i bytes (%i bytes slop)\n", in_len, out_len, overlap);

  return 0;
}


