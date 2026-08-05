# ZOL

Build solana programs in zig, using _only_ zig 0.16

no external linkers or toolchains needed.

## PERFORMANCE FIRST

The library is focused on cu performance, and thus removes any runtime borrow checks or similar safety features, safety should be ensured in testing or tooling and not on-chain where they have real costs.

The builds also default to 'ReleaseFast' which cuts cu usage, with usually negligable size increase.

## rationale

This is basically a stripped-down version of https://github.com/vitorpy/zignocchio with better zig build integration, and no external dependencies.

## license

License MIT
