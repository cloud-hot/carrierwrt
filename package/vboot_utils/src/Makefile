# Copyright (c) 2013 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This Makefile normally builds in a 'build' subdir, but use
#
#    make BUILD=<dir>
#
# to put the output somewhere else.

##############################################################################
# Make variables come in two flavors, immediate or deferred.
#
#   Variable definitions are parsed like this:
#
#        IMMEDIATE = DEFERRED
#    or
#        IMMEDIATE := IMMEDIATE
#
#   Rules are parsed this way:
#
#        IMMEDIATE : IMMEDIATE
#           DEFERRED
#
# So you can assign variables in any order if they're only to be used in
# actions, but if you use a variable in either the target or prerequisite of a
# rule, the rule will be constructed using only the top-down, immediate value.
#
# So we'll try to define all the variables first. Then the rules.
#

##############################################################################
# Configuration variables come first.
#
# Our convention is that we only use := for variables that will never be
# changed or appended. They must be defined before being used anywhere.

# We should only run pwd once, not every time we refer to ${BUILD}.
SRCDIR := $(shell pwd)
BUILD = $(SRCDIR)/build
export BUILD

# Stuff for 'make install'
INSTALL = install
DESTDIR = /usr/local/bin
OLDDIR = old_bins

FT_DIR=${DESTDIR}
F_DIR=${DESTDIR}
UB_DIR=${DESTDIR}/${OLDDIR}

# Verbose? Use V=1
ifeq (${V},)
Q := @
endif

# Quiet? Use QUIET=1
ifeq ($(QUIET),)
PRINTF := printf
else
PRINTF := :
endif

# Flag ordering: arch, then -f, then -m, then -W
DEBUG_FLAGS := $(if ${DEBUG},-g -O0,-Os)
COMMON_FLAGS := -nostdinc -pipe \
	-ffreestanding -fno-builtin -fno-stack-protector \
	-Werror -Wall -Wstrict-prototypes ${DEBUG_FLAGS}

# Note: FIRMWARE_ARCH is defined by the Chromium OS ebuild.
# FIRMWARE_ARCH not defined; assuming local compile.
CC ?= gcc
CFLAGS += -Wall -Werror # HEY: always want last two?

# Create / use dependency files
CFLAGS += -MMD -MF $@.d

# These are required to access large disks and files on 32-bit systems.
CFLAGS += -D_GNU_SOURCE -D_FILE_OFFSET_BITS=64

# And a few more default utilities
LD = ${CC}
CXX ?= g++ # HEY: really?

##############################################################################
# Now we need to describe everything we might want or need to build

# Everything wants these headers.
INCLUDES += \
	-Ifirmware/include \
	-Ifirmware/lib/include \
	-Ifirmware/lib/cgptlib/include \
	-Ifirmware/lib/cryptolib/include

# Firmware library. TODO: Do we still need to export this?
FWLIB = ${BUILD}/vboot_fw.a

# Firmware library sources needed by VbInit() call
VBINIT_SRCS = \
	firmware/lib/crc8.c \
	firmware/lib/utility.c \
	firmware/stub/utility_stub.c

# Additional firmware library sources needed by VbSelectFirmware() call
VBSF_SRCS = \
	firmware/lib/cryptolib/padding.c \
	firmware/lib/cryptolib/rsa.c \
	firmware/lib/cryptolib/rsa_utility.c \
	firmware/lib/cryptolib/sha1.c \
	firmware/lib/cryptolib/sha256.c \
	firmware/lib/cryptolib/sha512.c \
	firmware/lib/cryptolib/sha_utility.c \
	firmware/lib/stateful_util.c \
	firmware/lib/vboot_common.c \
	firmware/stub/vboot_api_stub_sf.c

# Additional firmware library sources needed by VbSelectAndLoadKernel() call
VBSLK_SRCS = \
	firmware/lib/utility_string.c

VBSF_SRCS += ${VBINIT_SRCS}
FWLIB_SRCS += ${VBSF_SRCS} ${VBSLK_SRCS}

VBINIT_OBJS = ${VBINIT_SRCS:%.c=${BUILD}/%.o}
VBSF_OBJS = ${VBSF_SRCS:%.c=${BUILD}/%.o}

FWLIB_OBJS = ${FWLIB_SRCS:%.c=${BUILD}/%.o}

ALL_OBJS += ${FWLIB_OBJS} ${VBINIT_OBJS} ${VBSF_OBJS}


# Library to build the utilities. "HOST" mostly means "userspace".
HOSTLIB = ${BUILD}/libvboot_host.a

HOSTLIB_SRCS = \
	host/lib/file_keys.c \
	host/lib/fmap.c \
	host/lib/host_common.c \
	host/lib/host_key.c \
	host/lib/host_keyblock.c \
	host/lib/host_misc.c \
	host/lib/host_signature.c \
	host/lib/signature_digest.c 

HOSTLIB_OBJS = ${HOSTLIB_SRCS:%.c=${BUILD}/%.o}
ALL_OBJS += ${HOSTLIB_OBJS}

# Scripts to install directly (not compiled)
UTIL_SCRIPTS = \
	utility/make_keyblock.sh \
	utility/make_pair.sh \
	utility/common.sh

UTIL_NAMES = utility/dumpRSAPublicKey \
	utility/vbutil_firmware \
	utility/vbutil_key \
	utility/vbutil_keyblock 

UTIL_BINS = $(addprefix ${BUILD}/,${UTIL_NAMES})
ALL_OBJS += $(addsuffix .o,${UTIL_BINS})


##############################################################################
# Finally, some targets. High-level ones first.

# Create output directories if necessary.  Do this via explicit shell commands
# so it happens before trying to generate/include dependencies.
SUBDIRS := firmware host utility
_dir_create := $(foreach d, \
	$(shell find ${SUBDIRS} -name '*.c' -exec  dirname {} \; | sort -u), \
	$(shell [ -d ${BUILD}/${d} ] || mkdir -p ${BUILD}/${d}))


# Default target.
.PHONY: all
all: fwlib host_stuff

# Host targets
.PHONY: host_stuff
host_stuff: hostlib utils
.PHONY: clean
clean:
	${Q}/bin/rm -rf ${BUILD}

.PHONY: install
install: utils_install

# Don't delete intermediate object files
.SECONDARY:


# ----------------------------------------------------------------------------
# Firmware library

# TPM-specific flags.  These depend on the particular TPM we're targeting for.
# They are needed here only for compiling parts of the firmware code into
# user-level tests.
# Disable rollback TPM when compiling locally, since otherwise
# load_kernel_test attempts to talk to the TPM.
${FWLIB_OBJS}: CFLAGS += -DDISABLE_ROLLBACK_TPM

.PHONY: fwlib
fwlib: ${FWLIB}

${FWLIB}: ${FWLIB_OBJS}
	@$(PRINTF) "    RM            $(subst ${BUILD}/,,$@)\n"
	${Q}rm -f $@
	@$(PRINTF) "    AR            $(subst ${BUILD}/,,$@)\n"
	${Q}ar qc $@ $^

# ----------------------------------------------------------------------------
# Host library

.PHONY: hostlib
hostlib: ${HOSTLIB}

${BUILD}/host/% ${HOSTLIB}: INCLUDES += \
	-Ihost/include \
	-Ihost/lib/include

# TODO: better way to make .a than duplicating this recipe each time?
${HOSTLIB}: ${HOSTLIB_OBJS} ${FWLIB_OBJS}
	@$(PRINTF) "    RM            $(subst ${BUILD}/,,$@)\n"
	${Q}rm -f $@
	@$(PRINTF) "    AR            $(subst ${BUILD}/,,$@)\n"
	${Q}ar qc $@ $^

# ----------------------------------------------------------------------------
# Utilities

# These have their own headers too.
${BUILD}/utility/%: INCLUDES += \
	-Ihost/include \
	-Ihost/lib/include \
	-Iutility/include

# Utilities for auto-update toolkits must be statically linked.
${UTIL_BINS_STATIC}: LDFLAGS += -static


.PHONY: utils
utils: ${UTIL_BINS} ${UTIL_SCRIPTS}
	${Q}cp -f ${UTIL_SCRIPTS} ${BUILD}/utility
	${Q}chmod a+rx $(patsubst %,${BUILD}/%,${UTIL_SCRIPTS})

${UTIL_BINS} ${UTIL_BINS_STATIC}: ${HOSTLIB}
${UTIL_BINS} ${UTIL_BINS_STATIC}: LIBS = ${HOSTLIB}

.PHONY: utils_install
utils_install: ${UTIL_BINS} ${UTIL_SCRIPTS}
	@$(PRINTF) "    INSTALL       UTILS\n"
	${Q}mkdir -p ${UB_DIR}
	${Q}${INSTALL} -t ${UB_DIR} ${UTIL_BINS} ${UTIL_SCRIPTS}

# ----------------------------------------------------------------------------
# Generic build rules. LIBS and OBJS can be overridden to tweak the generic
# rules for specific targets.

${BUILD}/%: ${BUILD}/%.o ${OBJS} ${LIBS}
	@$(PRINTF) "    LD            $(subst ${BUILD}/,,$@)\n"
	${Q}${LD} -o $@ ${CFLAGS} ${LDFLAGS} $< ${OBJS} ${LIBS} ${LDLIBS}

${BUILD}/%.o: %.c
	@$(PRINTF) "    CC            $(subst ${BUILD}/,,$@)\n"
	${Q}${CC} ${CFLAGS} ${INCLUDES} -c -o $@ $<

# Rules to recompile a single source file for library and test
# TODO: is there a tidier way to do this?
${BUILD}/%_for_lib.o: CFLAGS += -DFOR_LIBRARY
${BUILD}/%_for_lib.o: %.c
	@$(PRINTF) "    CC-for-lib    $(subst ${BUILD}/,,$@)\n"
	${Q}${CC} ${CFLAGS} ${INCLUDES} -c -o $@ $<

# TODO: C++ files don't belong in vboot reference at all.  Convert to C.
${BUILD}/%.o: %.cc
	@$(PRINTF) "    CXX           $(subst ${BUILD}/,,$@)\n"
	${Q}${CXX} ${CFLAGS} ${INCLUDES} -c -o $@ $<

# ----------------------------------------------------------------------------
# Here are the special tweaks to the generic rules.

# Some utilities need external crypto functions
${BUILD}/utility/dumpRSAPublicKey: LDLIBS += -lcrypto
${BUILD}/utility/vbutil_firmware: LDLIBS += -lcrypto
${BUILD}/utility/vbutil_key: LDLIBS += -lcrypto
${BUILD}/utility/vbutil_keyblock: LDLIBS += -lcrypto

# Include generated dependencies
ALL_DEPS += ${ALL_OBJS:%.o=%.o.d}
-include ${ALL_DEPS}
