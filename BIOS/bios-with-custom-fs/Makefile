all:
	nasm -f bin boot.asm -o boot.bin
	gcc fs.c -o fs_creator
	./fs_creator
	qemu-system-x86_64 -drive format=raw,file=fs.img


clean:
	rm -rf *.bin
	rm -rf fs_creator
	rm -rf *.img
