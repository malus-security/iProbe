# iProbe
iProbe is a debugger-based introspection tool for iOS applications. It supports all iOS versions and it is fully automated. 

**It only works on jailbroken devices.**


## Description

iProbe automates the process of remote debugging by creating a reliable connection with LLDB over USB. 
**Currently, iProbe only offers support for LLDB.**
After the connection is established, a basic fuzzing tool is available in order to test the reliability of the link.

## Requirements

iProbe is only available for **MacOS** and requires a **jailbroken version of iOS**. It also automatically manages every dependency it needs.

## Usage

```bash

USAGE: ./setup.sh [-h] -os_version VERSION [-executable EXEC]


positional arguments:
  os_version                the current iOS version installed
			    on the mobile device
optional arguments:
  -help			    show this help message and exit
  -executable EXEC          name of the target executable
```

iProbe can attach to custom-made executables by using the command:

```bash
/setup.sh -os_version VERSION -executable EXEC
```

Likewise, if no executable is specified, it will automatically ask the user to provide the PID of the target running process:

```bash
/setup.sh -os_version VERSION
```

When the complete setup is done, a LLDB console will be opened and the connection to the iPhone will be made automatically:

```python
spawn lldb

(lldb) process connect connect://127.0.0.1:12345

(lldb) command script import fuzzer.py

Process 841 stopped

* thread #1, queue = 'com.apple.root.default-qos.overcommit', stop reason = signal SIGSTOP

frame #0: 0x000000018b2cf704 libsystem_kernel.dylib`__sigsuspend_nocancel + 8

libsystem_kernel.dylib`__sigsuspend_nocancel:

-> 0x18b2cf704 <+8>:  b.lo 0x18b2cf71c ; <+32>

0x18b2cf708 <+12>: stp  x29, x30, [sp, #-0x10]!

0x18b2cf70c <+16>: mov  x29, sp

0x18b2cf710 <+20>: bl 0x18b2b27d0 ; cerror_nocancel

Target 0: (online-auth-agent) stopped.

The "fuzz" command has been loaded and is ready for use.

(lldb)
```

You can subsequently use the ```fuzz``` command to start the fuzzer.

## Issue reporting

The buzzer is extremely basic and not expected to produce any valuable results. The main focus is on establishing the remote connection with the debugger.

If there are any problems within that process, please open an issue. Any recommendations or improvement ideas are also welcome.



