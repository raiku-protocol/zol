# ZOL

Build solana programs in zig, using _only_ zig 0.16

no external toolchains needed.

## PERFORMANCE FIRST

The library is focused on cu performance, and thus removes any runtime borrow checks or similar safety features, safety should be ensured in testing or tooling and not on-chain where they have real costs.

## rationale

This is basically a stripped-down version of https://github.com/vitorpy/zignocchio with opinionated API changes and better zig build integration.

## license

License MIT
