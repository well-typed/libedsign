#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "../lib/edsign-amalg.c"

int
main(int ac, char** av)
{
  int r = 0;
  uint8_t pk[edsign_PUBLICKEYBYTES];
  uint8_t sk[edsign_SECRETKEYBYTES];
  uint8_t sig[edsign_sign_BYTES];

  uint8_t fp1[edsign_fingerprint_BYTES];
  uint8_t fp2[edsign_fingerprint_BYTES];
  uint8_t fp3[edsign_fingerprint_BYTES];

  uint8_t* pass;
  uint64_t passlen;

  if (ac < 2) {
    pass = NULL;
    passlen = 0;
  }
  else {
    pass = (uint8_t*)av[1];
    passlen = strlen(av[1]);
  }

  uint8_t* msg = (uint8_t*)"Hello world!";
  edsign_keypair(pass, passlen, 14, 8, 1, pk, sk);
  edsign_sign(pass, passlen, sk, msg, 12, sig);

  r |= edsign_pubkey_fingerprint(pk, fp1);
  r |= edsign_secretkey_fingerprint(sk, fp2);
  r |= edsign_signature_fingerprint(sig, fp3);

  r |= memcmp(fp1, fp2, edsign_fingerprint_BYTES);
  r |= memcmp(fp2, fp3, edsign_fingerprint_BYTES);

  printf("result: %s\n", (r == 0) ? "OK" : "FAIL");
  return r;
}
