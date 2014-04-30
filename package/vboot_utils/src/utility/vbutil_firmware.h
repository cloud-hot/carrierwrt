/* Copyright (c) 2011 The Chromium OS Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file.
 *
 * Verified boot firmware utility
 */
#ifndef _VBUTIL_FIRMWARE_H
#define _VBUTIL_FIRMWARE_H

extern int Verify(const char* infile, const char* signpubkey,
                  const char* fv_file, const char* kernelkey_file,
                  const char* fv_out_file);
#endif
