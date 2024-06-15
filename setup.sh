#!/bin/bash

# compile c prog with xcrun -sdk iphoneos clang -arch armv7 server.c -o server



# Check parameters
if [[ $# -eq 0 || $1 == "-h" || $1 == "-help" ]]
  then
    echo "USAGE: ./setup.sh -os_version [os_version]"
    echo "OPTIONAL: -executable [executable]"
    exit 1
  elif [ $# -lt 2 ]
    then
      echo "Please provide all arguments. Use -help to see all needed arguments"
      exit 1
fi

if [ $# -eq 4 ]
  then
    exec_path=$(realpath -e $4 2>/dev/null)

    if [ $? -ne 0 ]
      then
        echo "No executable found with this name"
        exit 1
    fi
fi

read -s -p "Device root password: "$'\n' password

# Create debugserver 
echo "Creating a new folder for debugserver"
mkdir debugserver >/dev/null 2>&1
cd debugserver

# Copy the appropriate version of debugserver
echo "Copying the debugserver binary"
hdiutil attach /Applications/Xcode.app/Contents\
/Developer/Platforms/iPhoneOS.platform/DeviceSupport/$2/DeveloperDiskImage.dmg >/dev/null

cp /Volumes/DeveloperDiskImage/usr/bin/debugserver .

hdiutil detach /Volumes/DeveloperDiskImage >/dev/null

# Create new entitlements file
echo "Creating a new entitlements file"
touch entitlements.plist
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\"> 
  <dict> 
    <key>com.apple.springboard.debugapplications</key> 
    <true/> 
    <key>run-unsigned-code</key> 
    <true/> 
    <key>get-task-allow</key> 
    <true/> 
    <key>task_for_pid-allow</key> 
    <true/> 
  </dict> 
</plist>" > entitlements.plist

# Resign the binary
echo "Resigning the binary"
codesign -s - --entitlements entitlements.plist -f debugserver >/dev/null 2>&1

cd ..
directory=$(pwd)

# Install dependencies if needed
echo "Installing dependencies"
HOMEBREW_NO_AUTO_UPDATE=1 brew install libusbmuxd expect >/dev/null 2>&1


if [ $? -ne 0 ]
  then
    echo "Dependencies installation failed"
    exit 1
fi

# Open iProxy tunnel in a new terminal
echo "Opening iProxy tunnel"
iproxy 2222 22 >/dev/null 2>&1 &

# Send the debugserver binary to the iOS device
if [ -z "${exec_path}" ]
  then
    echo "Copying debugserver and executable to iOS device"
    ./scp_pid.exp $(echo -n $password | base64)
  else
    echo "Copying debugserver to iOS device"
    ./scp_exec.exp $(echo -n $password | base64) $exec_path
fi


if [ $? -ne 0 ]
  then
    echo "Failed to copy debugserver to device. Make sure the device is reachable"
    exit 1
fi


# SSH into the iOS devices and see all running processes
if [ $# -ne 4 ]
  then
    echo "Opening SSH tunnel"
    osascript -e "tell application \"Terminal\"  
        set currentTab to do script \"cd $directory; ./ssh_login.exp $(echo -n $password | base64)\"
        delay 2
        do script \"reset; ps -e\" in currentTab
      end tell" >/dev/null 2>&1

    read -p "PID of process to debug: "$'\n' PID

    osascript -e "tell application \"Terminal\"  
    set currentTab to do script \"cd $directory; ./ssh_PF_login.exp $(echo -n $password | base64)\"
    delay 2
    do script \"reset; ./debugserver 127.0.0.1:23456 --attach=$PID\" in currentTab
    end tell" >/dev/null 2>&1
  else
    osascript -e "tell application \"Terminal\"  
    set currentTab to do script \"cd $directory; ./ssh_PF_login.exp $(echo -n $password | base64)\"
    delay 2
    do script \"./debugserver 127.0.0.1:23456 $4 \" in currentTab
    end tell" >/dev/null 2>&1
fi

sleep 2
echo "Starting lldb"
./lldb.exp



