/* Copyright (c) 2011 The Chromium OS Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file.
 *
 * Verified boot key utility
 */

#include <getopt.h>
#include <inttypes.h>  /* For PRIu64 */
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cryptolib.h"
#include "host_common.h"
#include "vboot_common.h"


/* Command line options */
enum {
  OPT_INKEY = 1000,
  OPT_KEY_VERSION,
  OPT_ALGORITHM,
  OPT_MODE_PACK,
  OPT_MODE_UNPACK,
  OPT_COPYTO,
};

static struct option long_opts[] = {
  {"key", 1, 0,                       OPT_INKEY                   },
  {"version", 1, 0,                   OPT_KEY_VERSION             },
  {"algorithm", 1, 0,                 OPT_ALGORITHM               },
  {"pack", 1, 0,                      OPT_MODE_PACK               },
  {"unpack", 1, 0,                    OPT_MODE_UNPACK             },
  {"copyto", 1, 0,                    OPT_COPYTO                  },
  {NULL, 0, 0, 0}
};


/* Print help and return error */
static int PrintHelp(char *progname) {
  int i;

  fprintf(stderr,
          "This program wraps RSA keys with verified boot headers\n");
  fprintf(stderr,
          "\n"
          "Usage:  %s --pack <outfile> [PARAMETERS]\n"
          "\n"
          "  Required parameters:\n"
          "    --key <infile>              RSA key file (.keyb or .pem)\n"
          "    --version <number>          Key version number "
          "(required for .keyb, ignored for .pem)\n"
          "    --algorithm <number>        Signing algorithm to use with key:\n",
          progname);

  for (i = 0; i < kNumAlgorithms; i++) {
    fprintf(stderr,
            "                                  %d = (%s)\n",
            i, algo_strings[i]);
  }

  fprintf(stderr,
          "\nOR\n\n"
          "Usage:  %s --unpack <infile>\n"
          "\n"
          "  Optional parameters:\n"
          "    --copyto <file>             "
          "Write a copy of the key to this file.\n"
          "\n",
          progname);

  return 1;
}

/* Pack a .keyb file into a .vbpubk, or a .pem into a .vbprivk */
static int Pack(const char *infile, const char *outfile, uint64_t algorithm,
                uint64_t version) {
  VbPublicKey* pubkey;
  VbPrivateKey* privkey;

  if (!infile || !outfile) {
    fprintf(stderr, "vbutil_key: Must specify --in and --out\n");
    return 1;
  }

  if ((pubkey = PublicKeyReadKeyb(infile, algorithm, version))) {
    if (0 != PublicKeyWrite(outfile, pubkey)) {
      fprintf(stderr, "vbutil_key: Error writing key.\n");
      return 1;
    }
    free(pubkey);
    return 0;
  }

  if ((privkey = PrivateKeyReadPem(infile, algorithm))) {
    if (0 != PrivateKeyWrite(outfile, privkey)) {
      fprintf(stderr, "vbutil_key: Error writing key.\n");
      return 1;
    }
    free(privkey);
    return 0;
  }

  printf("Unable to parse either .keyb or .pem from %s\n", infile);
  return 1;
}


/* Unpack a .vbpubk or .vbprivk */
static int Unpack(const char *infile, const char *outfile) {
  VbPublicKey* pubkey;
  VbPrivateKey* privkey;

  if (!infile) {
    fprintf(stderr, "Need file to unpack\n");
    return 1;
  }

  if ((pubkey = PublicKeyRead(infile))) {
    printf("Public Key file:   %s\n", infile);
    printf("Algorithm:         %" PRIu64 " %s\n", pubkey->algorithm,
           (pubkey->algorithm < kNumAlgorithms ?
            algo_strings[pubkey->algorithm] : "(invalid)"));
    printf("Key Version:       %" PRIu64 "\n", pubkey->key_version);
    printf("Key sha1sum:       ");
    PrintPubKeySha1Sum(pubkey);
    printf("\n");
    if (outfile) {
      if (0 != PublicKeyWrite(outfile, pubkey)) {
        fprintf(stderr, "vbutil_key: Error writing key copy.\n");
        free(pubkey);
        return 1;
      }
    }
    free(pubkey);
    return 0;
  }

  if ((privkey = PrivateKeyRead(infile))) {
    printf("Private Key file:  %s\n", infile);
    printf("Algorithm:         %" PRIu64 " %s\n", privkey->algorithm,
           (privkey->algorithm < kNumAlgorithms ?
            algo_strings[privkey->algorithm] : "(invalid)"));
    if (outfile) {
      if (0 != PrivateKeyWrite(outfile, privkey)) {
        fprintf(stderr, "vbutil_key: Error writing key copy.\n");
        free(privkey);
        return 1;
      }
    }
    free(privkey);
    return 0;
  }

  printf("Unable to parse either .vbpubk or vbprivk from %s\n", infile);
  return 1;
}


int main(int argc, char* argv[]) {

  char *infile = NULL;
  char *outfile = NULL;
  int mode = 0;
  int parse_error = 0;
  uint64_t version = 1;
  uint64_t algorithm = kNumAlgorithms;
  char* e;
  int i;

  char *progname = strrchr(argv[0], '/');
  if (progname)
    progname++;
  else
    progname = argv[0];

  while ((i = getopt_long(argc, argv, "", long_opts, NULL)) != -1) {
    switch (i) {
      case '?':
        /* Unhandled option */
        printf("Unknown option\n");
        parse_error = 1;
        break;

      case OPT_INKEY:
        infile = optarg;
        break;

      case OPT_KEY_VERSION:
        version = strtoul(optarg, &e, 0);
        if (!*optarg || (e && *e)) {
          printf("Invalid --version\n");
          parse_error = 1;
        }
        break;

      case OPT_ALGORITHM:
        algorithm = strtoul(optarg, &e, 0);
        if (!*optarg || (e && *e)) {
          printf("Invalid --algorithm\n");
          parse_error = 1;
        }
        break;

      case OPT_MODE_PACK:
        mode = i;
        outfile = optarg;
        break;

      case OPT_MODE_UNPACK:
        mode = i;
        infile = optarg;
        break;

      case OPT_COPYTO:
        outfile = optarg;
        break;
    }
  }

  if (parse_error)
    return PrintHelp(progname);

  switch(mode) {
    case OPT_MODE_PACK:
      return Pack(infile, outfile, algorithm, version);
    case OPT_MODE_UNPACK:
      return Unpack(infile, outfile);
    default:
      printf("Must specify a mode.\n");
      return PrintHelp(progname);
  }
}
