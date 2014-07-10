SRCS=util.c randombytes.c ed25519.c scrypt.c blake2.c keypair.c sign.c verify.c

$(eval $(call c-objs,lib,$(SRCS)))
