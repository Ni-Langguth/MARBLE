#  This script is meant to be run on the hostmac after downloading an .ipsw file from https://mrmacintosh.com/apple-silicon-m1-full-macos-restore-ipsw-firmware-files-database

if [ -z "$2" ]; then
  read -p "Enter the full path to your ipsw image: " PATH_TO_IPSW
  read -p "Enter the desired name of the VM: " VM_NAME
else
  PATH_TO_IPSW=$1
  VM_NAME=$2
fi
echo $PATH_TO_IPSW
echo $VM_NAME
# Create build_drive.hdd - This drive is added to all VMs on this host and acts as a central build directory to keep the VMs themselves small and closer to stateless
# This drive could be mounted to the host system in previous versions of Parallels by using /Applications/Parallels\ Desktop.app/Contents/Applications/Parallels\ Mounter.app
# It seems that this functionality has been removed in Parallels 19 but as long as developers have access to a VM that mounts this build_drive, they can look at any of the recent builds performed by on this host

prl_disk_tool create --hdd /Users/sftnight/Parallels/build_drive.hdd --size 262144 > /dev/null
ls /Users/sftnight/Parallels/build_drive.hdd

# Create a VM with: max CPU cores, max recommended RAM (sys RAM - 6GB), a virtual drive with 64 GB, and bridged network (to allow ssh via CERN network), then turns isolation off to allow 'prlctl exec', adds build_drive to VM, and starts VM
prlctl create ${VM_NAME} -o macos --no-hdd --restore-image $PATH_TO_IPSW
prlctl set ${VM_NAME} --cpus $(sysctl -n hw.ncpu)
prlctl set ${VM_NAME} --memsize $(bc <<< "($(sysctl -n hw.memsize)-4*1073741824)/1024/1024")
prlctl set ${VM_NAME} --device-add hdd --type plain --size 65536
prlctl set ${VM_NAME} --device-set net0 --type bridged --iface default
prlctl set ${VM_NAME} --isolate-vm off
prlctl set ${VM_NAME} --device-add hdd --image /Users/sftnight/Parallels/build_drive.hdd/
prlctl start ${VM_NAME}

# Set and print instrucion message
# Due to limitations in Apple's Operating System and the CERN network, some setup steps could not be automated, the following message contains instructions to the maintainer on how to perform these steps manually.
MSG="
After executing this script, the following steps must be performed manually: \n
\t - Register the VM to the CERN network at https://landb.cern.ch/portal/devices/register \n
\t\t  - mac-address: $(prlctl list -i ${VM_NAME} | grep net | sed -n 's/.*mac=\([^ ]*\).*/\1/p') \n
\t\t  - name: ${VM_NAME} \n
\t\t  - opt out of IPV6, it can lead to problems \n
\t - Go through apples setup assistant in the VMs GUI, selecting: \n
\t\t  - Language: English \n
\t\t  - Select your country or region: Switzerland \n
\t\t  - Dictation (should be preset with region): English (United States) \n
\t\t  - Input Sources (should be preset with region): U.S., Swiss German, Swiss French, Italian \n
\t\t  - Preferred Languages (should be preset with region): English (US), German, French, Italian \n
\t\t  - Migration Assistant / Transfer data to this mac: Not now / Set up as new \n
\t\t  - Accessibility: Not Now \n
\t\t  - Data & Privacy - Continue \n
\t\t  - Create a Computer Account \n
\t\t\t  - Full name: sftnight \n
\t\t\t  - Account name: sftnight \n
\t\t\t  - Password: (the usual one for root or SPI…) \n 
\t\t  - Sign In with Your Apple ID: Set up later \n
\t\t  - Terms and Conditions: Agree \n
\t\t  - Enable Location Services: continue without enabling \n
\t\t  - Select your time zone: Geneva - Switzerland \n
\t\t  - Analytics: disable/click off any boxes and continue \n
\t\t  - Screen Time: Set up later \n
\t\t  - Siri: disable and continue \n
\t\t  - Update mac automatically : continue \n
\t - The following settings must be configured manually: \n
\t\t - Lock Screen must be set to 'Never' in these three options: \n
\t\t\t  - Start screen Saver when inactive : Never \n
\t\t\t  - Turn display off when inactive : Never \n
\t\t\t  - Require password after screen saver begins or display is turned off : Never \n
\t\t - Sharing must be enabled (at the very bottom of the 'Sharing' settings page): \n
\t\t\t  - Enable Remote Management (enable all sub-options of Remote-Management after clicking the little 'i' icon, do not set a password) \n
\t\t\t  - Enable Remote Login (select 'All users', instead of 'Only these users') \n
\t - .ipsw files are not always available for the latest macos version, check for updates BEFORE trying to install xcode or it will install the wrong version \n
\n
Once the registration of the network mac-address is finished: \n
\t - restart the VM \n
\t - run this line from the host-mac to confirm that the VM is ready to be sshed to: \n
\t\t ssh $VM_NAME 'echo test' \n
\t - log into the GUI and run this next line from the host-mac to install xcode: \n
\t\t ssh $VM_NAME 'xcode-select --install' \n
\t - check the spreadsheet whether the correct version of xcode was installed for that OS version. \n
\t - Use the sft Apple ID to download the correct version of xcode from https://developer.apple.com/download/all/ \n
\t - log into the GUI and run this next line from the host-mac to install the parallels-toolbox: \n
\t\t prlctl installtools $VM_NAME \n
\t - use the GUI to accept the license-agreement and go through with the toolbox installation. \n
\t - restart the VM once the installations are finished, then move on to the HOST_<YOUR_TEAM>_configure.sh \n
"

echo $MSG
