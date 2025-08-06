#!/usr/bin/env python3

import os
import sys
import lz4.block as lb


def read_mozlz4(filename):
    with open(filename, 'rb') as f:
        header = f.read(8)
        if header != b'mozLz40\0':
            raise ValueError("Not a valid mozlz4 file.")
        compressed_data = f.read()
        json_bytes = lb.decompress(compressed_data)
        return json_bytes.decode('utf-8')


def main(filepath):
    try:
        json_data = read_mozlz4(filepath)
        print("Extract success.")
        with open('output.json', 'w') as f:
            f.write(json_data)
    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    main(sys.argv[1])
    os.system("PAUSE>NUL")
