#!/bin/sh
wine asm6.exe src/main.asm bin/jumper.nes -L bin/listing.txt
echo "-- Assembly Finished --"
echo "-- Running jumper.nes --"
fceux bin/jumper.nes
