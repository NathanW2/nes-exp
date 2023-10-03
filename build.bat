@echo on

utils\cc65\bin\ca65 %1 -o %1.o
utils\cc65\bin\ld65 %1.o -C nes.cfg -o %1.nes 
del %1.o

