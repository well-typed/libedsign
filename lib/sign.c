/*
** Signature generation.
** Copyright (C) 2014 Austin Seipp, Well-Typed LLP.
** See Copyright Notice in edsign.h
**
** Design mostly inspired by signify, written for OpenBSD.
** Copyright (C) 2013 Ted Unangst <tedu@openbsd.org>. See LICENSE.txt
*/

#include "edsign-private.h"
#include "randombytes.h"
#include "ed25519.h"
#include "scrypt.h"
#include "blake2.h"
#include "keypair.h"
#include "util.h"

#define PKALG "Ed"
#define KDFALG "SK"

int
edsign_sign(const uint8_t* pass, const uint64_t passlen,
            const uint8_t* sk,
            const uint8_t* msg, const uint64_t msglen,
            uint8_t* out)
{
  uint32_t N, r, p;
  uint8_t* pp;
  uint8_t* pout;
  uint8_t* salt;
  uint8_t* digest;
  uint8_t* fp; /* fingerprint */
  uint8_t* enckey;
  uint8_t key[crypto_sign_ed25519_SECRETKEYBYTES];
  uint8_t hash[crypto_hash_blake2b_BYTES];
  uint8_t* sig = NULL;
  uint64_t siglen;
  uint64_t i;
  int res = EDSIGN_ERROR;

  if (msg == NULL) return EDSIGN_EINVAL;
  if (out == NULL) return EDSIGN_EINVAL;
  if (sk  == NULL) return EDSIGN_EINVAL;

  pp = (uint8_t*)sk;

  /* Basics: verification, decoding parameters */
  if (0 != edsign_memcmp(pp, (uint8_t*)PKALG, 2)) return EDSIGN_EINVAL;
  pp += 2;

  if (0 != edsign_memcmp(pp, (uint8_t*)KDFALG, 2)) return EDSIGN_EINVAL;
  pp += 2;

  N = edsign_le32dec(pp); pp += 4;
  r = edsign_le32dec(pp); pp += 4;
  p = edsign_le32dec(pp); pp += 4;

  salt   = pp; pp += 16;
  digest = pp; pp += 8;
  fp     = pp; pp += 8;
  enckey = pp;

  /* Derive key */
  if (pass != NULL) {
    uint64_t pow2N = ((uint64_t)1) << N;
    res = crypto_scrypt(pass, passlen, salt, 16, pow2N, r, p,
                        key, sizeof(key));
    if (res != 0) {
      res = EDSIGN_EINVAL;
      goto exit;
    }
  }
  else {
    edsign_bzero(key, sizeof(key));
  }

  /* Compute key hash */
  for (i = 0; i < sizeof(key); ++i) key[i] ^= enckey[i];
  crypto_hash_blake2b(hash, key, sizeof(key));

  if (0 != edsign_memcmp(hash, digest, 8)) {
    res = EDSIGN_EPASSWD;
    goto exit;
  }

  /* Sign */
  sig = malloc(msglen+crypto_sign_ed25519_BYTES);
  if (sig == NULL) goto exit;

  /* Note: the first 64 bytes of a signed Ed25519 message constitute
  ** the signature by itself. See memcpy below. */
  crypto_sign_ed25519(sig, &siglen, msg, msglen, key);

  /* Write signature */
  pout = out;
  memcpy(pout, PKALG, 2); pout += 2;
  memcpy(pout, fp, 8);    pout += 8;
  memcpy(pout, sig, 64);

  edsign_bzero(sig, msglen+crypto_sign_ed25519_BYTES);
  res = EDSIGN_OK;
 exit:
  free(sig);
  edsign_bzero(key, sizeof(key));
  edsign_bzero(hash, sizeof(hash));
  return res;
}

int
edsign_signature_fingerprint(const uint8_t* sig, uint8_t* out)
{
  if (sig == NULL) return EDSIGN_EINVAL;
  if (out == NULL) return EDSIGN_EINVAL;
  if (0 != edsign_memcmp(sig, (uint8_t*)PKALG, 2)) return EDSIGN_EINVAL;

  memcpy(out,sig+2 , edsign_fingerprint_BYTES);
  return EDSIGN_OK;
}

#undef PKALG
#undef KDFALG
