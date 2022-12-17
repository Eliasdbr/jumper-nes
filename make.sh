#!/bin/sh
wine asm6.exe src/main.asm bin/jumper.nes -L bin/listing.txt
echo "-- Finished --"
