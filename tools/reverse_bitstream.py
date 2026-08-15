#!/usr/bin/env python3
"""Reverse bits in each byte of an RBF file for Analogue Pocket."""
import sys

# bit-reversal lookup table; bytes.translate does the file in one C-level pass
REVERSE_TABLE = bytes(int(f'{i:08b}'[::-1], 2) for i in range(256))


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} input.rbf output.rbf_r")
        sys.exit(1)

    with open(sys.argv[1], 'rb') as f:
        data = f.read()

    with open(sys.argv[2], 'wb') as f:
        f.write(data.translate(REVERSE_TABLE))

    print(f"Reversed {len(data)} bytes: {sys.argv[1]} -> {sys.argv[2]}")


if __name__ == '__main__':
    main()
