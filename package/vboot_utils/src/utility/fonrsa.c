#include <getopt.h>
#include <inttypes.h>  /* For PRIu64 */
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "cryptolib.h"
#include "host_common.h"
#include "vboot_common.h"

int Verify(const char* infile, const char* signpubkey,
                  const char* fv_file, const char* kernelkey_file,
                  const char* fv_out_file) {

  VbKeyBlockHeader* key_block;
  VbFirmwarePreambleHeader* preamble;
  VbPublicKey* data_key;
  VbPublicKey* sign_key;
  VbPublicKey* kernel_subkey;
  RSAPublicKey* rsa;
  uint8_t* blob;
  uint64_t blob_size;
  uint8_t* fv_data;
  uint64_t fv_size;
  uint64_t now = 0;
  uint32_t flags;

  if (!infile || !signpubkey) {
    printf("Must specify filename, signpubkey\n");
    return 1;
  }

  /* Read public signing key */
  sign_key = PublicKeyRead(signpubkey);
  if (!sign_key) {
    printf("Error reading signpubkey.\n");
    return 1;
  }

  /* Read blob */
  blob = ReadFile(infile, &blob_size);
  if (!blob) {
    printf("Error reading input file\n");
    return 1;
  }

  /* Verify key block */
  key_block = (VbKeyBlockHeader*)blob;
  if (0 != KeyBlockVerify(key_block, blob_size, sign_key, 0)) {
    printf("Error verifying key block.\n");
    return 1;
  }
  free(sign_key);
  now += key_block->key_block_size;

  printf("Key block:\n");
  data_key = &key_block->data_key;
  printf("  Size:                %" PRIu64 "\n", key_block->key_block_size);
  printf("  Flags:               %" PRIu64 " (ignored)\n",
         key_block->key_block_flags);
  printf("  Data key algorithm:  %" PRIu64 " %s\n", data_key->algorithm,
         (data_key->algorithm < kNumAlgorithms ?
          algo_strings[data_key->algorithm] : "(invalid)"));
  printf("  Data key version:    %" PRIu64 "\n", data_key->key_version);
  printf("  Data key sha1sum:    ");
  PrintPubKeySha1Sum(data_key);
  printf("\n");

  rsa = PublicKeyToRSA(&key_block->data_key);
  if (!rsa) {
    printf("Error parsing data key.\n");
    return 1;
  }

  /* Verify preamble */
  preamble = (VbFirmwarePreambleHeader*)(blob + now);
  if (0 != VerifyFirmwarePreamble(preamble, blob_size - now, rsa)) {
    printf("Error verifying preamble.\n");
    return 1;
  }
  now += preamble->preamble_size;

  flags = VbGetFirmwarePreambleFlags(preamble);
  printf("Preamble:\n");
  printf("  Size:                  %" PRIu64 "\n", preamble->preamble_size);
  printf("  Header version:        %" PRIu32 ".%" PRIu32"\n",
         preamble->header_version_major, preamble->header_version_minor);
  printf("  Firmware version:      %" PRIu64 "\n", preamble->firmware_version);
  kernel_subkey = &preamble->kernel_subkey;
  printf("  Kernel key algorithm:  %" PRIu64 " %s\n",
         kernel_subkey->algorithm,
         (kernel_subkey->algorithm < kNumAlgorithms ?
          algo_strings[kernel_subkey->algorithm] : "(invalid)"));
  printf("  Kernel key version:    %" PRIu64 "\n",
         kernel_subkey->key_version);
  printf("  Kernel key sha1sum:    ");
  PrintPubKeySha1Sum(kernel_subkey);
  printf("\n");
  printf("  Firmware body size:    %" PRIu64 "\n",
         preamble->body_signature.data_size);
  printf("  Preamble flags:        %" PRIu32 "\n", flags);

  /* TODO: verify body size same as signature size */

  /* Verify body */
  /* Read firmware volume */
  if (fv_file) {
    fv_data = ReadFile(fv_file, &fv_size);
    if (!fv_data) {
      printf("Error reading firmware volume\n");
      return 1;
    }
  } else {
    fv_data = blob + now;
    fv_size = blob_size - now;
  }

  if (flags & VB_FIRMWARE_PREAMBLE_USE_RO_NORMAL) {
    printf("Preamble requests USE_RO_NORMAL; skipping body verification.\n");
  } else {
    if (0 != VerifyData(fv_data, fv_size, &preamble->body_signature, rsa)) {
      printf("Error verifying firmware body.\n");
      return 1;
    }
    printf("Body verification succeeded.\n");
  }

  if (kernelkey_file) {
    if (0 != PublicKeyWrite(kernelkey_file, kernel_subkey)) {
      fprintf(stderr,
              "vbutil_firmware: unable to write kernel subkey\n");
      return 1;
    }
  }
  /* Write the copy, then free it */
  if (fv_out_file) {
    if (0 != WriteFile(fv_out_file, fv_data, fv_size)) {
      fprintf(stderr,
              "vbutil_firmware: unable to write verified firmware\n");
      return 1;
    }
  }

  return 0;
}

int Fon_Verify(const char* infile, const char* signpubkey,
                  const char* fv_out_file) {
	return Verify(infile, signpubkey, NULL, NULL, fv_out_file);
}
