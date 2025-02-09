### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# global properties
properties() { '
kernel.string=QuartiX GKI DUMMY1 (DATE) KSUDUMMY2
do.devicecheck=0
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=0
device.name1=
device.name2=
device.name3=
device.name4=
device.name5=
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties

### AnyKernel install
## boot shell variables
BLOCK=boot;
IS_SLOT_DEVICE=auto;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh

kernel_version=$(cat /proc/version | awk -F '-' '{print $1}' | awk '{print $3}')
case "$kernel_version" in
    5.10.*) supp=true ;;
    *) supp=false ;;
esac

ui_print " " "-> 5.10 Kernel: $supp"
$supp || exit 1

# Variant Selector
get_keycheck_result() {
	# Default behavior:
	# - press Vol+: return true (0)
	# - press Vol-: return false (1)

	local rc_1 rc_2
        local KEYCODE_UP=42
        local KEYCODE_DOWN=41
	
	while true; do
		# The first execution responds to the button press event,
		# the second execution responds to the button release event.
		${BIN}/keycheck; rc_1=$?
		${BIN}/keycheck; rc_2=$?
		[ "$rc_1" == "$rc_2" ] || continue
		case "$rc_2" in
			"$KEYCODE_UP") return 0;;
			"$KEYCODE_DOWN") return 1;;
		esac
	done
}

keycode_select() {
	local r_keycode
	if [ -z "$msg1" ]; then
	    msg1="Yes"
	    msg2="No"
	else
        msg1="$2"
        msg2="$3"
    fi
	ui_print " "
	while [ $# != 0 ]; do
		ui_print "# $1"
		shift
	done
	ui_print "#"
	ui_print "# Vol+ = $msg1, Vol- = $msg2."
	ui_print "# Please press the key..."
	get_keycheck_result
	r_keycode=$?
	ui_print "#"
	if [ "$r_keycode" -eq "0" ]; then

		ui_print "- You chose $msg1."
	else
		ui_print "- You chose $msg2."
	fi
	ui_print " "
	return $r_keycode
}


# KernelSU
if [ -f "${AKHOME}/bs_patches/ksun.p" ] || [ -f "${AKHOME}/bs_patches/ksu.p" ]; then
	if keycode_select "Do you want to install KernelSU support??"; then
	    use_ksu=true
	fi
fi


if [ -f "${AKHOME}/bs_patches/ksu.p" ] && [ -f "${AKHOME}/bs_patches/ksun.p" ]; then
	# KernelSU
	if keycode_select "Which variant of KernelSU do you want to Install?" "OG KernelSU" "KernelSU-Next"; then
		ui_print "- Patching Kernel image with OG KernelSU..."
		${BIN}/bspatch ${AKHOME}/Image ${AKHOME}/Image ${AKHOME}/bs_patches/ksu.p
	else
		ui_print "- Patching Kernel image with KernelSU-Next..."
		${BIN}/bspatch ${AKHOME}/Image ${AKHOME}/Image ${AKHOME}/bs_patches/ksun.p
	fi
elif [ -f "${AKHOME}/bs_patches/ksun.p" ]; then
	# KernelSU
	if keycode_select "Install OG KernelSU"; then
		ui_print "- Patching Kernel image..."
		${BIN}/bspatch ${AKHOME}/Image ${AKHOME}/Image ${AKHOME}/bs_patches/ksun.p
	fi
elif [ -f "${AKHOME}/bs_patches/ksun.p" ]; then
	# KernelSU-Next
	if keycode_select "Install KernelSU?-Next"; then
		ui_print "- Patching Kernel image..."
		${BIN}/bspatch ${AKHOME}/Image ${AKHOME}/Image ${AKHOME}/bs_patch/ksun.p
	fi
fi

# boot install
if [ -L "/dev/block/bootdevice/by-name/init_boot_a" -o -L "/dev/block/by-name/init_boot_a" ]; then
    split_boot # for devices with init_boot ramdisk
    flash_boot # for devices with init_boot ramdisk
else
    dump_boot # use split_boot to skip ramdisk unpack, e.g. for devices with init_boot ramdisk
    write_boot # use flash_boot to skip ramdisk repack, e.g. for devices with init_boot ramdisk
fi
