# -- Configuration -------------------------------------------------------------

CC?=cc
OPTIMIZATION?=-O3 -g -ggdb

STD       = -std=c99
WARN      = -Wall -Wextra -Wno-sign-compare #-Werror
OPT       = $(OPTIMIZATION)
ANTIHAX   = -D_FORTIFY_SOURCE=2 -fno-strict-overflow -fstack-protector-all -fPIC
ANTIHAXLD = -pie -z now

INSTALLPREFIX?=/usr/local
PREFIX?=$(INSTALLPREFIX)
DPREFIX=$(DESTDIR)$(PREFIX)
INSTALL_LIB=$(DPREFIX)/lib
INSTALL_INCLUDE=$(DPREFIX)/include
INSTALL_MAN=$(DPREFIX)/share/man
INSTALL=install

MAN3DIR=$(INSTALL_MAN)/man3

PERL?=perl

# -- Setup ---------------------------------------------------------------------

USING_COMPCERT=$(shell sh -c '(($(CC) --help | grep CompCert) > /dev/null && echo YES) || echo NO')

IS_DARWIN=$(shell sh -c '((uname | grep Darwin) > /dev/null && echo YES) || echo NO')
IS_LINUX=$(shell sh -c '((uname | grep Linux) > /dev/null && echo YES) || echo NO')

ifeq ($(IS_DARWIN),YES)
SOEXT=dylib
endif
ifeq ($(IS_LINUX),YES)
SOEXT=so
endif

ifdef DEBUG
DEBUGOPT=-g

ifneq ($(USING_COMPCERT),YES)
DEBUGOPT+=-ggdb
endif

ifdef ASAN
DEBUGOPT+=-fsanitize=address
endif
ifdef UBSAN
DEBUGOPT+=-fsanitize=undefined
endif

# If we're debugging, we just override OPTIMIZATION above, since we
# don't want it anyway.
CFLAGS+=-DDEBUG
OPT=$(DEBUGOPT)
else
# Turn off assertions
CFLAGS+=-DNDEBUG
endif

ifeq ($(USING_COMPCERT),YES)
# CompCert has pretty non-standard flags - we're careful to only use
# DEBUGOPT here, because OPT flags might not work!
MY_CFLAGS=$(DEBUGOPT) -finline-asm
MY_LDFLAGS=
else
MY_CFLAGS=$(STD) $(WARN) $(OPT) $(ANTIHAX) $(CFLAGS)
MY_LDFLAGS=$(ANTIHAXLD)
endif

ifdef LTO
OPT+=-flto -fuse-linker-plugin
endif

CCCOLOR="\033[34m"
LINKCOLOR="\033[34;1m"
SRCCOLOR="\033[33m"
BINCOLOR="\033[37;1m"
MAKECOLOR="\033[32;1m"
ENDCOLOR="\033[0m"

ifndef V
EDSIGN_CC = @printf '    %b         %b\n' $(CCCOLOR)CC$(ENDCOLOR) $(SRCCOLOR)$@$(ENDCOLOR) 1>&2;
EDSIGN_LINK = @printf '    %b       %b\n' $(LINKCOLOR)LINK$(ENDCOLOR) $(BINCOLOR)$@$(ENDCOLOR) 1>&2;
EDSIGN_AR = @printf '    %b         %b\n' $(CCCOLOR)AR$(ENDCOLOR) $(SRCCOLOR)$@$(ENDCOLOR) 1>&2;
EDSIGN_RANLIB = @printf '    %b     %b\n' $(LINKCOLOR)RANLIB$(ENDCOLOR) $(BINCOLOR)$@$(ENDCOLOR) 1>&2;
EDSIGN_INSTALL = @printf '    %b    %b\n' $(LINKCOLOR)INSTALL$(ENDCOLOR) $(BINCOLOR)$@$(ENDCOLOR) 1>&2;

EDSIGN_FRAMAC = @printf '    %b    %b\n' $(LINKCOLOR)FRAMA-C$(ENDCOLOR) $(BINCOLOR)$@$(ENDCOLOR) 1>&2;
EDSIGN_MKAMALG         = @printf '    %b       %b -> %b\n' $(CCCOLOR)PERL$(ENDCOLOR) $(SRCCOLOR)$<$(ENDCOLOR) $(BINCOLOR)$@$(ENDCOLOR) 1>&2;
endif

QCC=$(EDSIGN_CC) $(CC)
QLINK=$(EDSIGN_LINK) $(CC)
QINSTALL=$(EDSIGN_INSTALL) $(INSTALL)
QAR=$(EDSIGN_AR) ar
QRANLIB=$(EDSIGN_RANLIB) ranlib

QFRAMAC=$(EDSIGN_FRAMAC) frama-c
QAMALG=$(EDSIGN_MKAMALG) $(PERL) etc/amalg/mkamalg.pl

E=@echo
ifndef V
Q=@
else
Q=
endif

MY_INCLUDES=-Ilib

# -- Primary build, tagging, etc -----------------------------------------------

VERSION=$(shell cat VERSION)
MY_CFLAGS+=$(MY_INCLUDES)

all:   lib/libedsign.a lib/libedsign.$(SOEXT)
world: all check framalyze
tag:
	$(Q)git tag -u $(GPGID) -sam 'Version $(VERSION)' $(VERSION)

## -- Rules

include rules.mk
include lib/rules.mk
include t/rules.mk

framalyze: $(FRAMAC_ANALYSIS)
check: $(TEST_EXES)
	$(Q)for d in $(TEST_EXES); do ($$d > /dev/null); done

# If we ask to build the the amalgamation, *or* we are in the source
# distribution (which already contains it), then we perform a slight
# hack: clear the set of object files to build, and initialize them to
# point only to the amalgamation
ifneq ($(filter amalg, $(MAKECMDGOALS)),)
# Slight hack - reset STATIC and DYNAMIC objs to only contain amalg
STATIC_OBJS=
DYNAMIC_OBJS=
$(eval $(call c-objs,lib,edsign-amalg.c))
endif

amalg: lib/libedsign.a lib/libedsign.$(SOEXT)
amalg-src: lib/edsign-amalg.c
lib/edsign-amalg.c: etc/amalg/mkamalg.pl
	$(QAMALG) -o $@

lib/libedsign.$(SOEXT): $(DYNAMIC_OBJS)
	$(QLINK) -shared -o $@ $(DYNAMIC_OBJS)
lib/libedsign.a: $(STATIC_OBJS)
	$(QAR) -rc $@ $(STATIC_OBJS)
	$(QRANLIB) $@

sdistprep: amalg-src

# -- Cleanup -------------------------------------------------------------------

distclean: clean
	$(Q)rm -f lib/edsign-amalg.c

clean:
	$(Q)rm -f *.xz $(DYNAMIC_OBJS) $(STATIC_OBJS)
	$(Q)rm -f lib/*.$(SOEXT) lib/*.a lib/*.o lib/*.dyn_o
	$(Q)rm -rf $(AIGFILES) $(BCFILES) $(CHECKFILES) $(PROVEFILES)
	$(Q)rm -rf $(FRAMAC_ANALYSIS) $(TEST_EXES) $(TEST_OBJS)
	$(Q)rm -rf $(KATFILES) cryptol/specs/*.aig
	$(Q)rm -rf cov-int
	$(Q)rm -f result

# -- Install rules -------------------------------------------------------------

install:        $(INSTALL_LIB)/libedsign.a \
                $(INSTALL_LIB)/libedsign.$(SOEXT) \
                $(INSTALL_INCLUDE)/edsign.h

$(INSTALL_INCLUDE)/edsign.h: lib/edsign.h
	$(Q)mkdir -p $(INSTALL_INCLUDE)
	$(QINSTALL) $< $(INSTALL_INCLUDE)

$(INSTALL_LIB)/libedsign.a: lib/libedsign.a
	$(Q)mkdir -p $(INSTALL_LIB)
	$(QINSTALL) $< $(INSTALL_LIB)

$(INSTALL_LIB)/libedsign.$(SOEXT): lib/libedsign.$(SOEXT)
	$(Q)mkdir -p $(INSTALL_LIB)
	$(QINSTALL) $< $(INSTALL_LIB)

uninstall:
	$(Q)rm -f $(INSTALL_LIB)/libedsign.a
	$(Q)rm -f $(INSTALL_LIB)/libedsign.$(SOEXT)
	$(Q)rm -f $(INSTALL_INCLUDE)/edsign.h
