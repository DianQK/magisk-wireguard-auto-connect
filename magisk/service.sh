#!/system/bin/sh

until [ $(getprop init.svc.bootanim) = "stopped" ] ; do
    sleep 2
done

service_path=`realpath $0`
module_dir=`dirname ${service_path}`

/system/bin/echo "" > $module_dir/log.txt
write_log() {
    /system/bin/echo "log: $*" >> $module_dir/log.txt
}

notif() {
  su -lp 2000 -c "/system/bin/cmd notification post -S bigtext -t 'WireGuard AutoConnect Service' 'Tag' \"$*\"" < /dev/null > /dev/null 2>&1
}

stop_wg() {
    write_log "try to disconnect the wg0"
    if [ -z $(/system/xbin/wg show) ]; then
        return
    fi
    write_log "run wg-quick down wg0"
    /system/xbin/wg-quick down wg0
}

start_wg() {
    write_log "try to connect the wg0"
    if [ -z $(/system/xbin/wg show) ]; then
        write_log "run wg-quick up wg0"
        up_result=$(/system/xbin/wg-quick up wg0)
        if [[ $? != '0' ]]; then
            notif $up_result
        fi
    fi
}

home_ip_prefix="192.168.18"
ping_ip="8.8.8.8"

if [ -e /data/misc/wireguard/auto-connect.conf ]
then
    write_log "use /data/misc/wireguard/auto-connect.conf"
    . /data/misc/wireguard/auto-connect.conf
else
    write_log "/data/misc/wireguard/auto-connect.conf not found, use default config"
fi

write_log "home_ip_prefix: $home_ip_prefix"
write_log "ping_ip: $ping_ip"

wait_connection_available() {
    sleep 10
    retry_count=0
    while [ $retry_count -le 5 ]; do
        write_log "checking network availabilty, ping $ping_ip"
        /system/bin/ping -c1 -w3 $ping_ip
        if [[ $? = '0' ]]; then
            home_ip_matched=$(/system/bin/ip address show dev wlan0 | /system/bin/grep $home_ip_prefix)
            write_log "$home_ip_prefix matched $home_ip_matched"
            if [[ $? != '0' ]]; then
                write_log "wifi off"
                start_wg
            elif [ -z $home_ip_matched ]; then
                write_log "not connected to home network"
                start_wg
            fi
            return
        fi
        retry_count=$((retry_count+1))
        write_log "retry $retry_count"
        sleep 2
    done
    notif "Connection failure!"
}

wait_connection_available

switch_wg() {
    home_ip_matched=$(/system/bin/ip address show dev wlan0 | /system/bin/grep $home_ip_prefix)
    write_log "$home_ip_prefix matched $home_ip_matched"
    if [ -z $home_ip_matched ]; then
        write_log "not connected to home network"
        sleep 2
        start_wg
    else
        write_log "connected to home network"
        stop_wg
    fi
    while read msg; do
        if [[ "$msg" = *"$home_ip_prefix"* && "$msg" = *wlan0* ]]; then
            if [[ "$msg" = Deleted* ]]; then
                sleep 2
                start_wg
            else
                stop_wg
            fi
        fi
    done < /dev/stdin
    notif "WireGuard AutoConnect Service Stopped!"
}

wait_wlan0() {
    while read msg; do
        break
    done < /dev/stdin
}
/system/bin/ip monitor | /system/bin/grep wlan0 | wait_wlan0

/system/bin/nohup /system/bin/ip monitor address dev wlan0 2>&1 | /system/bin/grep $home_ip_prefix | switch_wg &
