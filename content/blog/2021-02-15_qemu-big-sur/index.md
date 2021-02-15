+++
title = "QEMU on macOS 11 Big Sur"

[taxonomies]
categories = ["blog"]
tags = ["development"]

[extra]
comments=true
applause=true
+++

Apple releases a major version of their OS for Macs each year, but Big Sur was one of the more significant releases in the last decade. Big changes always break things, and this was no exception.

<!-- more -->

Trying to use QEMU after upgrading macOS to Big Sur or even installing an incremental update, QEMU will fail with the following error:
```
qemu-system-x86_64: Error: HV_ERROR
zsh: 'qemu-system-x86_64 \
    -machi…' terminated by signal SIGABRT (Abort)
```

This error occurs because Apple has made changes to the hypervisor entitlements. An entitlement is a right or privilege that grants an executable particular capabilities. An App stores its entitlements as key-value pairs embedded in the code signature of its binary executable. In this case, the QEMU binary isn't signed with the entitlement to create and manage virtual machines.

So far (macOS 10.15), the entitlement needed to use the Apple hypervisor was `com.apple.vm.hypervisor`, but that has deprecated and [replaced](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_hypervisor) by `com.apple.security.hypervisor`.

To fix this issue, we need to add this new entitlement to the QEMU binary. In my case, I want to run x86_64 machines, `qemu-system-x86_64`. First, create a new `entitlements.xml` file with the following content:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.hypervisor</key>
    <true/>
</dict>
</plist>
```

Then we sign QEMU with the new entitlement:
```shell
codesign -s - --entitlements entitlements.xml --force $(where qemu-system-x86_64)
```

Now the `qemu-system-x86_64` command should work as expected and be able to launch VMs. 😉

## References
- [Apple Entitlements](https://developer.apple.com/documentation/bundleresources/entitlements)
- [Apple Entitlements Hypervisor](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_hypervisor)
- [How do I resign app with entitlements?](https://stackoverflow.com/questions/36888535/how-do-i-resign-app-with-entitlements)
