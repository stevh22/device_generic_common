obj-m += intel-ipts.o

intel-ipts-objs += ipts-mei.o
intel-ipts-objs += ipts-hid.o
intel-ipts-objs += ipts-msg-handler.o
intel-ipts-objs += ipts-kernel.o
intel-ipts-objs += ipts-resource.o
intel-ipts-objs += ipts-gfx.o
intel-ipts-$(CONFIG_DEBUG_FS) += ipts-dbgfs.o

all:
	make -C $(KERNEL_BUILD_DIR) M=$(PWD) modules

clean:
	make -C $(KERNEL_BUILD_DIR) M=$(PWD) clean
