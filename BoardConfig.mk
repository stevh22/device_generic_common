#
# BoardConfig.mk for x86 platform
#

TARGET_BOARD_PLATFORM := android-x86

# Some framework code requires this to enable BT
BOARD_HAVE_BLUETOOTH := true
BOARD_HAVE_BLUETOOTH_LINUX := true

BOARD_USE_LEGACY_UI := true

BOARD_SYSTEMIMAGE_PARTITION_SIZE = $(if $(MKSQUASHFS),0,2147483648)

# customize the malloced address to be 16-byte aligned
BOARD_MALLOC_ALIGNMENT := 16

# Enable dex-preoptimization to speed up the first boot sequence
# of an SDK AVD. Note that this operation only works on Linux for now
ifeq ($(HOST_OS),linux)
WITH_DEXPREOPT := true
WITH_DEXPREOPT_PIC := true
endif

# the following variables could be overridden
TARGET_PRELINK_MODULE := false
TARGET_NO_KERNEL ?= false
TARGET_NO_RECOVERY ?= true
TARGET_EXTRA_KERNEL_MODULES := tp_smapi
ifneq ($(filter efi_img,$(MAKECMDGOALS)),)
TARGET_KERNEL_ARCH ?= x86_64
endif
TARGET_USES_64_BIT_BINDER := $(if $(filter x86_64,$(TARGET_ARCH) $(TARGET_KERNEL_ARCH)),true)

BOARD_USES_GENERIC_AUDIO ?= false
BOARD_USES_ALSA_AUDIO ?= true
BUILD_WITH_ALSA_UTILS ?= true
BOARD_HAS_GPS_HARDWARE ?= true

# Don't build emulator
BUILD_EMULATOR ?= false
BUILD_STANDALONE_EMULATOR ?= false
BUILD_EMULATOR_QEMUD ?= false
BUILD_EMULATOR_OPENGL ?= false
BUILD_EMULATOR_OPENGL_DRIVER ?= false
BUILD_EMULATOR_QEMU_PROPS ?= false
BUILD_EMULATOR_CAMERA_HAL ?= false
BUILD_EMULATOR_GPS_MODULE ?= false
BUILD_EMULATOR_LIGHTS_MODULE ?= false
BUILD_EMULATOR_SENSORS_MODULE ?= false

BUILD_ARM_FOR_X86 := $(WITH_NATIVE_BRIDGE)

BOARD_USE_LIBVA_INTEL_DRIVER := true
BOARD_USE_LIBVA := true
BOARD_USE_LIBMIX := true
BOARD_USES_WRS_OMXIL_CORE := true
USE_INTEL_OMX_COMPONENTS := true

USE_OPENGL_RENDERER := true
NUM_FRAMEBUFFER_SURFACE_BUFFERS ?= 3
BOARD_USES_DRM_HWCOMPOSER ?= true

USE_CAMERA_STUB ?= false

SUPERUSER_EMBEDDED := true
SUPERUSER_PACKAGE_PREFIX := com.android.settings.cyanogenmod.superuser

# This enables the wpa wireless driver
BOARD_WPA_SUPPLICANT_DRIVER ?= NL80211
BOARD_WPA_SUPPLICANT_PRIVATE_LIB ?= private_lib_driver_cmd
WPA_SUPPLICANT_VERSION ?= VER_2_1_DEVEL
WIFI_DRIVER_MODULE_PATH ?= auto

BOARD_GPU_DRIVERS ?= i915 i965 nouveau r300g r600g radeonsi swrast virgl vmwgfx
ifneq ($(strip $(BOARD_GPU_DRIVERS)),)
TARGET_HARDWARE_3D := true
BOARD_EGL_CFG ?= device/generic/common/gpu/egl_mesa.cfg
endif

BOARD_KERNEL_CMDLINE := root=/dev/ram0 androidboot.selinux=permissive
TARGET_KERNEL_DIFFCONFIG := device/generic/common/selinux_diffconfig

COMPATIBILITY_ENHANCEMENT_PACKAGE := true
PRC_COMPATIBILITY_PACKAGE := true
ZIP_OPTIMIZATION_NO_INTEGRITY := true
TARGET_HW_DISK_ENCRYPTION := false

# Add fix for common JACK issues
ANDROID_JACK_VM_ARGS := -Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx4096m

# Add needed cm tag for Bluez-x86
#INSTALL_PREFIX ?= cm-x86-14.0

# Blissful Building Options
#BLISS_AUDIO_MOD := viper
#BLISS_BUILD_BLOCK := 1
BLISSIFY := true
#BLISS_O3 := true
#BLISS_GRAPHITE := true
BLISS_STRICT := false
#BLISS_KRAIT := true
#FLOOP_NEST_OPTIMIZE := true
#ENABLE_GCCONLY := true
#BLISS_PIPE := true
#TARGET_ENABLE_UKM := true
#BLISS_PTHREAD := true
#BLISS_GOMP := true
#BLISS_EXTRAGCC := true
#BLISS_SANITIZE := true
#TARGET_USE_QCOM_BIONIC_OPTIMIZATION := true
FAST_MATH := true
#ENABLE_MODULAR_O3 := true
#ENABLE_LTO := true
#LINK_TIME_OPTIMIZATIONS := true
#TARGET_USE_ION_COMPAT := true
#TARGET_USE_KRAIT_PLD_SET := true
#WITH_LZMA_OTA := true
INSTALL_PREFIX ?= bliss-x86_7.1
#TARGET_TC_ROM := 4.9
#TARGET_TC_KERNEL := 4.9
TARGET_GCC_VERSION_EXP := $(TARGET_TC_ROM)
TARGET_KERNEL_CUSTOM_TOOLCHAIN := $(TARGET_TC_KERNEL)

#SaberMod
-include vendor/bliss/config/sm.mk
