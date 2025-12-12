# Tor Configuration

Here's how to configure Zen Browser to use the Tor network:
1. Go to [Mullvad](https://mullvad.net/en/account/wireguard-config) to download the wireguard config files
2. Place the files in `/etc/wireguard/` and rename one to `mullvad.conf` (copy first, then rename for preservation)
3. Run the [`copy_dotfiles.sh`](https://github.com/Rohan-Bjharatia/Arch-Dots/blob/master/copy_dotfiles.sh) script to copy the config files to the correct location
4. Go into Zen Browser settings and scroll down to `Network Settings`
5. Select it and change to `Manual Proxy Configuration`, leave the `HTTP Proxy + Port` & `HTTPS Proxy + Port` fields blank, and set the `SOCKS Proxy + Port` to `127.0.0.1:9050` and switch to `SOCKS v5`
6. Go to [about:config](about:config) and set `media.peerconnection.enabled` to `false`, `network.proxy.socks_remote_dns` to `true`, and `privacy.resistFingerprinting` to `true`
