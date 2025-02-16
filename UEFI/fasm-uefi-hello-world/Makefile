.PHONY: all clean build_dir assemble qemu

all: build_dir assemble

build_dir:
	mkdir -p build
	cp /usr/share/ovmf/OVMF.fd build/

assemble:
	fasm hello.asm build/hello.efi

qemu:
	qemu-system-x86_64 \
		-bios build/OVMF.fd \
		-net none \
		-drive format=raw,file=fat:rw:build/

clean:
	rm -rf output

