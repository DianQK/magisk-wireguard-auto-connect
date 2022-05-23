if [ -e /sys/module/wireguard ]
then
    set_perm ${MODPATH}/system/bin/wg-quick  0  0  0755
    set_perm ${MODPATH}/system/bin/wg  0  0  0755
else
    abort "error: kernel does not support wireguard."
fi
