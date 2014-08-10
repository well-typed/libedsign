/*
** Signature verification.
** Copyright (C) 2014 Austin Seipp, Well-Typed LLP.
** See Copyright Notice in edsign.h
**
** Design mostly inspired by signify, written for OpenBSD.
** Copyright (C) 2013 Ted Unangst <tedu@openbsd.org>. See LICENSE.txt
*/

#include "edsign-private.h"
#include "ed25519.h"
#include "sign.h"
#include "util.h"

#define PKALG "Ed"

/**
 * edsign_verify(pk, sig, msg, msglen):
 *
 * Verify the message ${msg} (of size ${msglen}) with signature ${sig}
 * was signed by the public key ${pk}. ${msg}, ${pk} and ${sig} can
 * not be NULL.
 *
 * - Returns EDSIGN_EINVAL if the arguments are invalid
 * - Returns EDSIGN_EKEY if ${pk} is an incorrect public key for the signature
 * - Returns EDSIGN_ESIG if the ${sig} and ${msg} failed to verify
 * - Returns EDSIGN_OK under normal circumstances
 */
int
edsign_verify(const uint8_t* pk, const uint8_t *sig,
              const uint8_t* msg,  const uint64_t msglen)
{
  int res = -1;
  uint64_t smsglen, tlen;
  uint8_t* smsg = NULL;
  uint8_t* temp = NULL;

  if (pk  == NULL) return EDSIGN_EINVAL;
  if (sig == NULL) return EDSIGN_EINVAL;
  if (msg == NULL) return EDSIGN_EINVAL;

  if (0 != edsign_memcmp(pk, (uint8_t*)PKALG, 2)) return EDSIGN_EINVAL;
  if (0 != edsign_memcmp(sig, (uint8_t*)PKALG, 2)) return EDSIGN_EINVAL;
  if (0 != edsign_memcmp(pk+2, sig+2, 8)) return EDSIGN_EKEY;

  smsglen = msglen+crypto_sign_ed25519_BYTES;
  temp = malloc(smsglen);
  smsg = malloc(smsglen);
  if (temp == NULL || smsg == NULL) goto exit;

  memcpy(smsg,    sig+10, 64);  /* Copy signature */
  memcpy(smsg+64, msg, msglen); /* Copy message */

  res = crypto_sign_open(temp, &tlen, smsg, smsglen, pk+10);
  if (res != 0) res = EDSIGN_ESIG; /* Signature failure */
 exit:
  free(smsg);
  free(temp);
  return res;
}

#undef PKALG
