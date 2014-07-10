#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include "../lib/edsign-amalg.c"
#include "bench.h"

int
main(int ac, char** av)
{
  static size_t lengths[] = {16, 64, 256, 1024, 8192, 0};
  size_t i, j;
  uint64_t ticks, minticks;

  static uint8_t buf[8192] = {255};
  static uint8_t out[8192] = {0};

  uint8_t pk[edsign_PUBLICKEYBYTES];
  uint8_t sk[edsign_SECRETKEYBYTES];
  uint8_t sig[edsign_sign_BYTES];

  uint64_t warmup = 4096*4;
  uint64_t repeat = 2048;

  if (ac >= 2) warmup = atoll(av[1]);
  if (ac >= 3) repeat = atoll(av[2]);

  edsign_keypair(NULL, 0, 0, 0, 0, pk, sk);

  /* warm up */
  printf("Clock frequency: %.1fgHz\n", osfreq()/1000000000);
  printf("Warming up (factor=%lu)... ", warmup); fflush(stdout);
  for (i = 0; i < warmup; i++) {
    edsign_sign(NULL, 0, sk, buf, 8192, sig);
    buf[i & 8191] += sig[i & (edsign_sign_BYTES-1)];
  }

  printf("ok\nBenchmarking (factor=%lu)\n", repeat);
  for (i = 0; lengths[i]; i++) {
    minticks = maxticks;
    for (j = 0; j < repeat; j++) {
      timeit(edsign_sign(NULL, 0, sk, buf, lengths[i], sig), minticks);
      buf[i & 8191] += sig[i & (edsign_sign_BYTES-1)];
    }
    if (lengths[i] <= 256)
      printf("%u bytes, %.0f cycles\n", (uint32_t)lengths[i], (double)minticks);
    else
      printf("%u bytes, %.2f cycles/byte\n", (uint32_t)lengths[i], (double)minticks / lengths[i]);
  }
  return 0;
}
