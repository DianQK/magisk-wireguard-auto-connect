# WireGuard AutoConnect for Android

This project toggles WireGuard's connection status by listening for ip changes using the `ip monitor` command.

## Requirements

Kernel supports WireGuard.

## Usage

1. Uninstall WireGuard apk if you installed.
2. Write your config to `/data/misc/wireguard/auto-connect.conf`.

Example:

```
home_ip_prefix="192.168.18"
ping_ip="8.8.8.8"
```

3. Put your wg config to `/data/misc/wireguard/wg0.conf`.
4. Install this module.
5. Reboot.
