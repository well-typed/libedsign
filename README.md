## edsign - tiny signature/verification library

[![MIT](http://b.repl.ca/v1/license-MIT-blue.png)](http://en.wikipedia.org/wiki/MIT_License)
[![C](http://b.repl.ca/v1/language-C-yellow.png)](http://en.wikipedia.org/wiki/C_(programming_language))

`libedsign` is a tiny C library that lets you do robust signature
verification, based on [ed25519][], [BLAKE2][] and [scrypt][].

[ed25519]: http://ed25519.cr.yp.to
[BLAKE2]: https://blake2.net
[scrypt]: http://www.tarsnap.com/scrypt.html

## Installation

Simply run `make install`.

Note that the Makefile also properly supports the `PREFIX=` and
`DESTDIR=` environment variables. For example:

    make                                 # creates libedsign.a and libedsign.so
    make install                         # binaries to /usr/local/lib by default
    make install PREFIX=$HOME            # install to $HOME/lib
    make install DESTDIR=tmp PREFIX=/usr # install to tmp/usr/lib

## Usage

TODO FIXME.

## Join in

Be sure to read the [contributing guidelines][contribute]. File bugs
in the GitHub [issue tracker][].

Master [git repository][gh]:

  * `git clone https://github.com/well-typed/libedsign.git`

## Authors

See [AUTHORS.txt](https://raw.github.com/well-typed/libedsign/master/AUTHORS.txt).

## License

Dual MIT/BSD2. See
[LICENSE.txt](https://raw.github.com/well-typed/libedsign/master/LICENSE.txt)
for specific terms of copyright and redistribution.

## Cryptography Notice

This distribution includes cryptographic software. The country in
which you currently reside may have restrictions on the import,
possession, use, and/or re-export to another country, of encryption
software.  BEFORE using any encryption software, please check your
country's laws, regulations and policies concerning the import,
possession, or use, and re-export of encryption software, to see if
this is permitted.  See <http://www.wassenaar.org/> for more
information.

The U.S. Government Department of Commerce, Bureau of Industry and
Security (BIS), has classified this software as Export Commodity
Control Number (ECCN) 5D002.C.1, which includes information security
software using or performing cryptographic functions with asymmetric
algorithms.  The form and manner of this distribution makes it
eligible for export under the License Exception ENC Technology
Software Unrestricted (TSU) exception (see the BIS Export
Administration Regulations, Section 740.13) for both object code and
source code.

[contribute]: https://github.com/thoughtpolice/edsign/blob/master/CONTRIBUTING.md
[issue tracker]: http://github.com/thoughtpolice/edsign/issues
[gh]: http://github.com/thoughtpolice/edsign
[bb]: http://bitbucket.org/thoughtpolice/edsign
