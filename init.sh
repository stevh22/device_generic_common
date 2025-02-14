#
# Copyright (C) 2013-2018 The Android-x86 Open Source Project
#
# License: GNU Public License v2 or later
#

function set_property()
{
	setprop "$1" "$2"
	[ -n "$DEBUG" ] && echo "$1"="$2" >> /dev/x86.prop
}

function set_prop_if_empty()
{
	[ -z "$(getprop $1)" ] && set_property "$1" "$2"
}

function init_misc()
{
	# device information
	setprop ro.product.manufacturer "$(cat $DMIPATH/sys_vendor)"
	setprop ro.product.model "$PRODUCT"

	# a hack for USB modem
	lsusb | grep 1a8d:1000 && eject

	# in case no cpu governor driver autoloads
	[ -d /sys/devices/system/cpu/cpu0/cpufreq ] || modprobe acpi-cpufreq

	# enable sdcardfs if /data is not mounted on tmpfs or 9p
	mount | grep /data\ | grep -qE 'tmpfs|9p'
	[ $? -ne 0 ] && modprobe sdcardfs
}

function init_hal_audio()
{
	case "$PRODUCT" in
		VirtualBox*|Bochs*)
			[ -d /proc/asound/card0 ] || modprobe snd-sb16 isapnp=0 irq=5
			;;
		TS10*)
			set_prop_if_empty hal.audio.out pcmC0D2p
			;;
		W101SA*)
			modprobe hdmi_lpe_audio
			set_prop_if_empty hal.audio.out pcmC0D0p
			;;
	esac
	
	if grep -qi "IntelHDMI" /proc/asound/card0/id; then
		[ -d /proc/asound/card1 ] || set_property ro.hardware.audio.primary hdmi
	fi
}

function init_hal_bluetooth()
{
	for r in /sys/class/rfkill/*; do
		type=$(cat $r/type)
		[ "$type" = "wlan" -o "$type" = "bluetooth" ] && echo 1 > $r/state
	done

	case "$PRODUCT" in
		T10*TA|M80TA|HP*Omni*)
			BTUART_PORT=/dev/ttyS1
			set_property hal.bluetooth.uart.proto bcm
			;;
		MacBookPro8*)
			rmmod b43
			modprobe b43 btcoex=0
			modprobe btusb
			;;
		# FIXME
		# Fix MacBook 2013-2015 (Air6/7&Pro11/12) BCM4360 ssb&wl conflict.
		MacBookPro11* | MacBookPro12* | MacBookAir6* | MacBookAir7*)
			rmmod b43
			rmmod ssb
			rmmod bcma
			rmmod wl
			modprobe wl
			modprobe btusb
			;;
		*)
			for bt in $(busybox lsusb -v | awk ' /Class:.E0/ { print $9 } '); do
				chown 1002.1002 $bt && chmod 660 $bt
			done
			;;
	esac

	if [ -n "$BTUART_PORT" ]; then
		set_property hal.bluetooth.uart $BTUART_PORT
		chown bluetooth.bluetooth $BTUART_PORT
		start btattach
	fi

	# rtl8723bs bluetooth
	if dmesg -t | grep -qE '8723bs.*BT'; then
		TTYSTRING=`dmesg -t | grep -E 'tty.*MMIO' | awk '{print $2}' | head -1`
		if [ -n "$TTYSTRING" ]; then
			echo "RTL8723BS BT uses $TTYSTRING for Bluetooth."
			ln -sf $TTYSTRING /dev/rtk_h5
			start rtk_hciattach
		fi
	fi
}

function init_hal_camera()
{
	case "$PRODUCT" in
		e-tab*Pro)
			set_prop_if_empty hal.camera.0 0,270
			set_prop_if_empty hal.camera.2 1,90
			;;
		*)
			;;
	esac
}

function init_hal_gps()
{
	# TODO
	return
}

function set_drm_mode()
{
	case "$PRODUCT" in
		ET1602*)
			drm_mode=1366x768
			;;
		VMware*)
			[ -n "$video" ] && drm_mode=$video
			;;
		*)
			;;
	esac

	[ -n "$drm_mode" ] && set_property debug.drm.mode.force $drm_mode
}

function init_uvesafb()
{
	UVESA_MODE=${UVESA_MODE:-${video%@*}}

	case "$PRODUCT" in
		ET2002*)
			UVESA_MODE=${UVESA_MODE:-1600x900}
			;;
		*)
			;;
	esac

	modprobe uvesafb mode_option=${UVESA_MODE:-1024x768}-32 ${UVESA_OPTION:-mtrr=3 scroll=redraw}
}

function init_hal_gralloc()
{
	[ "$VULKAN" = "1" ] && GRALLOC=gbm

	case "$(cat /proc/fb | head -1)" in
		*virtiodrmfb)
			if [ "$HWACCEL" != "0" ]; then
				set_property ro.hardware.hwcomposer ${HWC:-drm}
				set_property ro.hardware.gralloc ${GRALLOC:-gbm}
				set_property debug.drm.mode.force ${video:-1280x800}
			fi
			;;
		0*inteldrmfb|0*radeondrmfb|0*nouveaufb|0*svgadrmfb|0*amdgpudrmfb)
			if [ "$HWACCEL" != "0" ]; then
				set_property ro.hardware.gralloc ${GRALLOC:-drm}
				set_drm_mode
			fi
			;;
		"")
			init_uvesafb
			;&
		0*)
			;;
	esac

	[ -n "$DEBUG" ] && set_property debug.egl.trace error
}

function init_hal_hwcomposer()
{
	# TODO
	return
}

function init_hal_vulkan()
{
	case "$(cat /proc/fb | head -1)" in
		0*inteldrmfb)
			set_property ro.hardware.vulkan android-x86
			;;
		0*amdgpudrmfb)
			set_property ro.hardware.vulkan radv
			;;
		*)
			;;
	esac
}

function init_hal_lights()
{
	chown 1000.1000 /sys/class/backlight/*/brightness
}

function init_hal_power()
{
	for p in /sys/class/rtc/*; do
		echo disabled > $p/device/power/wakeup
	done

	# TODO
	case "$PRODUCT" in
		HP*Omni*|OEMB|Standard*PC*|Surface*3|T10*TA|VMware*)
			set_prop_if_empty sleep.state none
			;;
		e-tab*Pro)
			set_prop_if_empty sleep.state force
			;;
		BayTrail*)
			if [[ "$BIOSVERSION" == "H1D_S806_206" ]]; then  # Workaround for Chuwi Hi8
				# Disable false detected battery module
				rmmod_if_exist acpi_tpt10_battery
			fi
			;;
		*)
			;;
	esac
}

function init_hal_sensors()
{
	# if we have sensor module for our hardware, use it
	ro_hardware=$(getprop ro.hardware)
	[ -f /system/lib/hw/sensors.${ro_hardware}.so ] && return 0

	local hal_sensors=kbd
	local has_sensors=true
	case "$(cat $DMIPATH/uevent)" in
		*Lucid-MWE*)
			set_property ro.ignore_atkbd 1
			hal_sensors=hdaps
			;;
		*ICONIA*W5*)
			hal_sensors=w500
			;;
		*S10-3t*)
			hal_sensors=s103t
			;;
		*Inagua*)
			#setkeycodes 0x62 29
			#setkeycodes 0x74 56
			set_property ro.ignore_atkbd 1
			set_property hal.sensors.kbd.type 2
			;;
		*TEGA*|*2010:svnIntel:*)
			set_property ro.ignore_atkbd 1
			set_property hal.sensors.kbd.type 1
			io_switch 0x0 0x1
			setkeycodes 0x6d 125
			;;
		*DLI*)
			set_property ro.ignore_atkbd 1
			set_property hal.sensors.kbd.type 1
			setkeycodes 0x64 1
			setkeycodes 0x65 172
			setkeycodes 0x66 120
			setkeycodes 0x67 116
			setkeycodes 0x68 114
			setkeycodes 0x69 115
			setkeycodes 0x6c 114
			setkeycodes 0x6d 115
			;;
		*tx2*)
			setkeycodes 0xb1 138
			setkeycodes 0x8a 152
			set_property hal.sensors.kbd.type 6
			set_property poweroff.doubleclick 0
			set_property qemu.hw.mainkeys 1
			;;
		*MS-N0E1*)
			set_property ro.ignore_atkbd 1
			set_property poweroff.doubleclick 0
			setkeycodes 0xa5 125
			setkeycodes 0xa7 1
			setkeycodes 0xe3 142
			;;
		*Aspire1*25*)
			modprobe lis3lv02d_i2c
			echo -n "enabled" > /sys/class/thermal/thermal_zone0/mode
			;;
		*ThinkPad*Tablet*)
			modprobe hdaps
			hal_sensors=hdaps
			;;
		*LINX1010B*)
			set_property ro.iio.accel.z.opt_scale -1
			;&
		*i7Stylus*|*M80TA*)
			set_property ro.iio.accel.x.opt_scale -1
			;;
		*ONDATablet*)
			set_property ro.iio.accel.order 102
			set_property ro.iio.accel.x.opt_scale -1
			set_property ro.iio.accel.y.opt_scale -1
			;;
		*Venue*8*Pro*3845*)
			set_property ro.iio.accel.order 102
			;;
		*ST70416-6*)
			set_property ro.iio.accel.order 102
			;;
		*e-tabPro*|*pnEZpad*)
			set_property ro.iio.accel.quirks no-trig
			;&
		*T*0*TA*)
			set_property ro.iio.accel.y.opt_scale -1
			;;
		*)
			has_sensors=false
			;;
	esac

	# has iio sensor-hub?
	if [ -n "`ls /sys/bus/iio/devices/iio:device* 2> /dev/null`" ]; then
		busybox chown -R 1000.1000 /sys/bus/iio/devices/iio:device*/
		[ -n "`ls /sys/bus/iio/devices/iio:device*/in_accel_x_raw 2> /dev/null`" ] && has_sensors=true
		hal_sensors=iio
	elif lsmod | grep -q lis3lv02d_i2c; then
		hal_sensors=hdaps
		has_sensors=true
	elif [ "$hal_sensors" != "kbd" ]; then
		has_sensors=true
	fi

	set_property ro.hardware.sensors $hal_sensors
	set_property config.override_forced_orient ${HAS_SENSORS:-$has_sensors}
}

function create_pointercal()
{
	if [ ! -e /data/misc/tscal/pointercal ]; then
		mkdir -p /data/misc/tscal
		touch /data/misc/tscal/pointercal
		chown 1000.1000 /data/misc/tscal /data/misc/tscal/*
		chmod 775 /data/misc/tscal
		chmod 664 /data/misc/tscal/pointercal
	fi
}

function init_tscal()
{
	case "$PRODUCT" in
		ST70416-6*)
			modprobe gslx680_ts_acpi
			;&
		BayTrail*)
			if [[ "$BIOSVERSION" == "H1D_S806_206" ]]; then # Identify Chuwi Hi8
				create_pointercal
				
				# change to correct touchscreen module
				rmmod_if_exist gslx680_ts_acpi					
				modprobe silead gsl_fw_name=silead/gsl1680-chuwi-hi8.fw
				return
			fi
			;;
		T91|T101|ET2002|74499FU|945GSE-ITE8712|CF-19[CDYFGKLP]*)
			create_pointercal
			return
			;;
		*)
			;;
	esac

	for usbts in $(lsusb | awk '{ print $6 }'); do
		case "$usbts" in
			0596:0001|0eef:0001)
				create_pointercal
				return
				;;
			*)
				;;
		esac
	done
}

function init_ril()
{
	case "$(cat $DMIPATH/uevent)" in
		*TEGA*|*2010:svnIntel:*|*Lucid-MWE*)
			set_property rild.libpath /system/lib/libhuaweigeneric-ril.so
			set_property rild.libargs "-d /dev/ttyUSB2 -v /dev/ttyUSB1"
			set_property ro.radio.noril no
			;;
		*)
			set_property ro.radio.noril yes
			;;
	esac
}

function init_cpu_governor()
{
	governor=$(getprop cpu.governor)

	[ $governor ] && {
		for cpu in $(ls -d /sys/devices/system/cpu/cpu?); do
			echo $governor > $cpu/cpufreq/scaling_governor || return 1
		done
	}
}

function do_init()
{
	init_misc
	init_hal_audio
	init_hal_bluetooth
	init_hal_camera
	init_hal_gps
	init_hal_gralloc
	init_hal_hwcomposer
	init_hal_vulkan
	init_hal_lights
	init_hal_power
	init_hal_sensors
	init_tscal
	init_ril
	post_init
}

function do_netconsole()
{
	modprobe netconsole netconsole="@/,@$(getprop dhcp.eth0.gateway)/"
}

function do_bootcomplete()
{
	hciconfig | grep -q hci || pm disable com.android.bluetooth

	init_cpu_governor

	[ -z "$(getprop persist.sys.root_access)" ] && setprop persist.sys.root_access 3

	lsmod | grep -Ehq "brcmfmac|rtl8723be" && setprop wlan.no-unload-driver 1

	case "$PRODUCT" in
		1866???|1867???|1869???) # ThinkPad X41 Tablet
			start tablet-mode
			start wacom-input
			setkeycodes 0x6d 115
			setkeycodes 0x6e 114
			setkeycodes 0x69 28
			setkeycodes 0x6b 158
			setkeycodes 0x68 172
			setkeycodes 0x6c 127
			setkeycodes 0x67 217
			;;
		6363???|6364???|6366???) # ThinkPad X60 Tablet
			;&
		7762???|7763???|7767???) # ThinkPad X61 Tablet
			start tablet-mode
			start wacom-input
			setkeycodes 0x6d 115
			setkeycodes 0x6e 114
			setkeycodes 0x69 28
			setkeycodes 0x6b 158
			setkeycodes 0x68 172
			setkeycodes 0x6c 127
			setkeycodes 0x67 217
			;;
		7448???|7449???|7450???|7453???) # ThinkPad X200 Tablet
			start tablet-mode
			start wacom-input
			setkeycodes 0xe012 158
			setkeycodes 0x66 172
			setkeycodes 0x6b 127
			;;
		VMware*)
			pm disable com.android.bluetooth
			;;
		Surface*Go)
			echo on > /sys/devices/pci0000:00/0000:00:15.1/i2c_designware.1/power/control
			;;
		*)
			;;
	esac

#	[ -d /proc/asound/card0 ] || modprobe snd-dummy
	for c in $(grep '\[.*\]' /proc/asound/cards | awk '{print $1}'); do
		f=/system/etc/alsa/$(cat /proc/asound/card$c/id).state
		if [ -e $f ]; then
			alsa_ctl -f $f restore $c
		else
			alsa_ctl init $c
			alsa_amixer -c $c set Master on
			alsa_amixer -c $c set Master 100%
			alsa_amixer -c $c set Headphone on
			alsa_amixer -c $c set Headphone 100%
			alsa_amixer -c $c set Speaker 100%
			alsa_amixer -c $c set Capture 80%
			alsa_amixer -c $c set Capture cap
			alsa_amixer -c $c set PCM 100 unmute
			alsa_amixer -c $c set SPO unmute
			alsa_amixer -c $c set IEC958 on
			alsa_amixer -c $c set 'Mic Boost' 1
			alsa_amixer -c $c set 'Internal Mic Boost' 1
		fi
	done

	# check wifi setup
	FILE_CHECK=/data/misc/wifi/wpa_supplicant.conf

	if [ ! -f "$FILE_CHECK" ]; then
	    cp -a /system/etc/wifi/wpa_supplicant.conf $FILE_CHECK
            chown 1010.1010 $FILE_CHECK
            chmod 660 $FILE_CHECK
	fi

	post_bootcomplete
}

PATH=/sbin:/system/bin:/system/xbin

DMIPATH=/sys/class/dmi/id
BOARD=$(cat $DMIPATH/board_name)
PRODUCT=$(cat $DMIPATH/product_name)
BIOSVERSION=$(cat $DMIPATH/bios_version)

# import cmdline variables
for c in `cat /proc/cmdline`; do
	case $c in
		BOOT_IMAGE=*|iso-scan/*|*.*=*)
			;;
		*=*)
			eval $c
			if [ -z "$1" ]; then
				case $c in
					DEBUG=*)
						[ -n "$DEBUG" ] && set_property debug.logcat 1
						;;
				esac
			fi
			;;
	esac
done

[ -n "$DEBUG" ] && set -x || exec &> /dev/null

# import the vendor specific script
hw_sh=/vendor/etc/init.sh
[ -e $hw_sh ] && source $hw_sh

case "$1" in
	netconsole)
		[ -n "$DEBUG" ] && do_netconsole
		;;
	bootcomplete)
		do_bootcomplete
		;;
	init|"")
		do_init
		;;
esac

return 0
