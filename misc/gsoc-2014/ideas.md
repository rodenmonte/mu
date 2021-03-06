# Ideas for Perl 6 Google Summer of Code projects


## Rakudo

### Implement missing regex/grammar features

Perl 6 has a fairly comprehensive regex and grammar engine. Rakudo's
implementation is fairly complete, but some features are still missing,
most notably various backtracking control constructs (`::`, `:::`, `<cut>`
`<commit>`) and a few more esoteric features, like `<*foo>` and recursion
into rules associated with submatches (`<~~0>` and the likes).
[S05](http://design.perl6.org/S05.html) has the gory details.

A student interested in regex compilers could implement those missing
features.

Possible mentors: ???

### Make rakudo manage precompilation of modules

Possible mentors: ???

### NFG Strings

The Perl 6 specification contains a feature that hasn't been implemented in
any backend yet: The ability to treat strings not as a collection of bytes or
codepoints, but as a collection of grapheme clusters.

A proposal to implement this is to store a string as a series of integers,
with negative integers being indexes into a table that maps the numbers to
grapheme clusters for those that do not a have an NFC representation.

A student interested in Unicode could implement this in the JVM or the MoarVM
backend.

Possible mentors: moritz, ???

### Allomorphic Types

Implement allomorphic types (IntStr, RatStr, etc.), val(), proper handling
in MAIN(), and fix everywhere that assumes a single value cannot be both a
Numeric type and a Stringy type at the same time.

Possible mentors: ???


## MoarVM

### Break the VM

MoarVM has an existing GC torture test which allowed us to significantly
reduce the number of stability/correctness bugs in the memory management
systems.  However, we need similar torture testing (and fuzzers, etc.) for
other MoarVM subsystems, such as IO, concurrency, and native code interop.

Implement one (or more!) such torture tools and diagnose and/or fix the
issues it uncovers.

Possible mentors: ???

### JIT

MoarVM has a relatively efficient bytecode interpreter, but as yet no JIT.
Create a working (though not necessarily complete) JIT for at least one
CPU on at least one supported OS, refactoring the interpreter as needed to
allow the JIT to work seamlessly, efficiently, and correctly. 

Possible mentors: ???

### Peephole Optimizer

After the bytecode has been created, no further post-processing is done so
far, even though there's most probably lots of redundancy and unnecessary
complexity. Peephole Optimizers operate on small sections of bytecode,
usually any amount of code between jump instructions, and apply pattern
matching to the bytecode to find common cases of unoptimal bytecode and
replacing them.

Since MoarVM is, at heart, a register VM, many common peephole optimizations
such as turning redundant loads into load + dup are not applicable. There are
still optimizations that can definitely be worth it, such as strength
reduction of arithmetic operations.

Possible mentors: ???

## Test suite

### Test Rosetta Code

Implement a testing framework that works with Perl 6's roast that tests all
existing Rosetta Code examples to verify they still work.

Possible mentors: Coke, moritz, ???


## Native library bindings

### SSL/TLS bindings

Create a complete NativeCall binding for an existing SSL/TLS library.
Provide working example code (or better yet, modules) for HTTPS and one or
more other secure protocols.  Test that it works with at least the JVM or
MoarVM backend.

Possible mentors: ???

### OpenGL bindings

Create a complete (or mostly complete) NativeCall binding for OpenGL and/or
OpenGL ES.  Create or translate example code for at least 2.x-style GL.
Test that it works for at least the JVM or MoarVM backend.

Possible mentors: ???

### GUI toolkit bindings

Create NativeCall bindings for a cross-platform windowing toolkit such as Qt
or GTK+.  Create or translate example code for a simple program that can be
easily extended by programmers learning how to use the toolkit for their own
applications.  Test that it works for at least the JVM or MoarVM backend.

Possible mentors: ???


## Ecosystem

Create an "are we fast yet?" site for Perl 6, similar to
[arewefastyet.com](http://arewefastyet.com/) or [speed.pypy.org](http://speed.pypy.org/)
featuring colorful plots, possibly utilizing the
[perl6/bench-scripts](https://github.com/perl6/bench-scripts)
and/or [japhb/perl6-bench](https://github.com/japhb/perl6-bench).
Would track performance of the major Perl 6 implementations.

Possible mentors: ???

### Create a rock-solid HTTP client and server modules

Possible mentors: ???
