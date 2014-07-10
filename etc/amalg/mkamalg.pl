#!/usr/bin/env perl
# Copyright (c) 2014 Austin Seipp, Well-Typed LLP. All rights reserved.

use feature 'say';
use feature 'switch';
use warnings;
use strict;
use Getopt::Long;
use File::Find;
use Pod::Usage;
use List::MoreUtils qw(uniq any);

## -- Options ------------------------------------------------------------------

my %opts;
$opts{verbose} = 0;

## -- Get file listings

# Note: order is important
my @cfiles =
    (
      "lib/util.h",
      "lib/util.c",
      "lib/randombytes.h",
      "lib/randombytes.c",
      "lib/ed25519.h",
      "lib/ed25519.c",
      "lib/scrypt.h",
      "lib/scrypt.c",
      "lib/blake2.h",
      "lib/blake2.c",
      "lib/keypair.h",
      "lib/keypair.c",
      "lib/sign.h",
      "lib/sign.c",
      "lib/verify.h",
      "lib/verify.c",
    );

## -- Parse files

sub prelude {
    my $ver = `cat VERSION`;
    chomp $ver;

    say "/*";
    say "** libedsign, version ".$ver;
    say "**";
    say "** This file is an amalgamation of many separate C source files from";
    say "** libedsign. By combining all the individual C code files into this";
    say "** single large file, the entire code can be compiled as a single";
    say "** translation unit.  This allows many compilers to do optimizations";
    say "** that would not be possible if the files were compiled separately";
    say "** (or otherwise would require link-time optimization).";
    say "**";
    say "** This file is all you need to compile libedsign. To use edsign in";
    say "** other programs, you need this file and the \"edsign.h\" header file";
    say "** that defines the programming interface to the edsign library. (If";
    say "** you do not have the \"edsign.h\" header file at hand, you will find a";
    say "** copy embedded within the text of this file.  Search for \"Begin file";
    say "** lib/edsign.h\" to find the start of the embedded edsign.h header";
    say "** file.)";
    say "**";
    say "** Copyright (C) 2014 Austin Seipp. See Copyright Notice in edsign.h";
    say "*/";
    say "";
};

my (@sysinc, @myinc);
sub slurp_includes {
    my (@sysincludes, @myincludes);
    my @files = @cfiles;
    push(@files, 'lib/edsign-private.h');
    foreach (@files) {
        open CFILE, $_;
        while (<CFILE>) {
            chomp;
            next unless $_ =~ /^\#include\s(<|")/;
            if ($1 eq "<")  { push @sysincludes, $_; }
            if ($1 eq "\"") { push @myincludes, $_; }
        }
        close CFILE;
    }

    @sysinc = grep { $_ !~ /(fcntl|stdint|windows|wincrypt|sys\/endian|sys\/stat|sys\/mman|sys\/types|unistd)/ } sort(uniq(@sysincludes));
    foreach (@sysinc) { say; }

    # Special case some headers
    say "#if defined(_WIN32) || defined(_WIN64) || defined(__TOS_WIN__) || defined(__WINDOWS__)";
    say "#include <windows.h>";
    say "#include <wincrypt.h>";
    say "#else";
    say "#include <fcntl.h>";
    say "#include <stdint.h>";
    say "#include <sys/stat.h>";
    say "#include <sys/types.h>";
    say "#include <sys/mman.h>";
    say "#include <unistd.h>";
    say "#endif /* !WINDOWS */\n";

    # Ensure we notify that we're using the amalgamation.
    say "#define EDSIGN_AMALGAMATION 1\n";
};

my @csource;

sub process_cfile {
    my $file = shift || $_;
    return unless ($file =~ /\.(h|c)$/);

    open CFILE, $file;
    my $prel = "\n/* -- Begin file $file ";
    $prel .= "-" x (78-length($prel));
    $prel .= " */";
    push @csource, $prel;
    push @csource, "/* -------------------------------------------------------------------------- */\n";

    while (<CFILE>) {
        chomp;
        next if $_ =~ /^\#include\s(<|").*/;
        push @csource, $_;
    }
    close CFILE;
}

sub slurp_code {
    process_cfile "lib/edsign.h";
    process_cfile "lib/edsign-private.h";

    foreach (@cfiles) { process_cfile; }
    foreach (@csource) { say; }
}

## -- Main entry point ---------------------------------------------------------

GetOptions(\%opts, 'help|?', 'verbose+', 'man', 'output=s');

pod2usage(1), exit if defined($opts{help});
pod2usage(-verbose => 2), exit if defined($opts{man});

if (defined($opts{output})) {
    open(STDOUT, ">".$opts{output});
}

prelude;
slurp_includes;
slurp_code;

## -- Documentation ------------------------------------------------------------
__END__

=head1 edsign-amalg.pl

edsign-amalg.pl -- build an amalgamation of the Quiet source code

=head1 SYNOPSIS

edsign-amalg.pl [-o <output file>]

Create a single-file C distribution out of the libedsign source code,
applicable for distribution and easy compilation.

=head1 OPTIONS

   --help, -?

     This help message.

   --verbose

     Increase verbosity.

   --output, -o

     Output file. If unspecified, output is sent to stdout.

=head1 DESCRIPTION

edsign-amalg.pl will take all the Quiet source code, and push it into a
single file that's suitable for global optimisation and easy inclusion
in any source project. The perl script doesn't use a direct parser,
but instead simply hacks the source together automatically.

=head1 BUGS

Plenty, most likely.

=head1 CONTACT/PATCHES/AUTHOR DOSSIER

Author and target of blame: Austin Seipp <aseipp@pobox.com>
=cut
