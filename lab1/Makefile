all:
	nasm -f bin bootloader.asm -o boot.bin
	dd if=boot.bin of=floppy_1.vfd bs=512 count=1
