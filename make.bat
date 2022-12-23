rgbasm -L -o main.o main.asm
rgblink -o main.gb main.o -n main.sym -m main.map
rgbfix -v -p 0xFF main.gb