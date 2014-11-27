all:
	nasm -f bin bootloader.asm -o boot.bin
	nasm -f bin kernel.asm -o kernel.bin
	dd if=boot.bin of=floppy_2.vfd bs=512 count=1
	dd if=kernel.bin of=floppy_2.vfd bs=512 seek=1 count=1
