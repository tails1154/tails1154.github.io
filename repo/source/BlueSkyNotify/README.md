# BlueSkyNotifier

An open-source MobileSubstrate tweak for jailbroken iOS 5.1.1. It polls Bluesky unread notifications and publishes SpringBoard bulletins.

The tweak reads credentials from `/var/mobile/Library/Preferences/com.tails1154.bluesky.notify.plist` through PreferenceLoader:

- `handle`: Bluesky handle
- `appPassword`: Bluesky App Password
- `showStatus`: whether launch/login status bulletins are enabled (default: enabled)

Build with Theos and the iPhoneOS 5.1 SDK:

```sh
make THEOS=/path/to/theos SYSROOT=/path/to/iPhoneOS5.1.sdk package
```
