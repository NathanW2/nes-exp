# Create a empty rom.chr file 8K long
import sys; 

with open("rom.chr", 'wb') as binfile:
    binfile.write(b'\x00' * 8192)
