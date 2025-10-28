# MARBLE
MacOS Actions Runners Balancing Load Efficiently

MARBLE strives to work around Apples restrictions in dockerization of MacOS by automating the creation and configuration of MacOS virtual machines with the Parallels Desktop virtualization software as far as possible and instructing in the ways that could not be automated.
This approach allows the maintenance of a consistent build environment and automates the up- and download of the virtual machines to a prefconfigured S3 bucket, laying important groundwork for a scalable MacOS VM service in the SFT group, that can be used by ROOT and the parts of SPI, which don't require cvmfs (it relying on macfuse, which is a kernel - not a system - extension does not allow it to be used on mac VMs on apple silicon).
Instructions in this readme contain:
 - Configure a VM host-mac
 - Get Parallels
 - Create a VM (for debugging and CI)
 - Add a VM to CI
 - Upload a VM to the S3 bucket
 - Download a VM from the S3 bucket
 - How to debug a problem
 - Some useful prlctl commands
 - Some common problems

Configure a VM host-mac (prerequisite)
-----
1 Setup assistant
  Follow setup_assistant.txt  

2 Register to network
  https://landb.cern.ch/portal/devices/register
  Restart once the mac-address has been registered to DNS
  
3 Settings
  Enable sharing
  Disable Lock Screen

4 Naming
  macphsft[0-99], avoid duplicate names by checking this spreadsheet: https://docs.google.com/spreadsheets/d/1ZtJ8blql5M1SGsdM2nxWwjyDptfB2YRQp6V_9MHI6cA/edit?pli=1&gid=0#gid=0
  export HOST_NAME=
  scutil --set ComputerName $HOST_NAME
  scutil --set HostName $HOST_NAME

5 xcode
  Execute 'xcode-select --install' and accept the GUI popup to install xcode.

6 Pull this repo to the home directory of your user /Users/sftnight. It has to be this directory for the execution of the scripts on the VM to work.

7 Disable indexing on the whole mac to save computing ressources.
   sudo mdutil -i off /
   Check whether indexing is actually off.
   mdutil -s /

8 (FOR SPI) Add a private ssh key from one of the other machines in use to /Users/sftnight/.ssh/authorized_keys so that jenkins' public key matches it.

Get Parallels
-----
1 Enroll in mdm and follow instructions: https://devices.docs.cern.ch/devices/mac/MacSelfService/Enrolling/
  
2 Log into Self-Service with SSO.

3 Find and request Parallels Desktop in Self-Service.

4 Download s3cmd python package for interaction with macVM bucket: https://openstack.cern.ch/project/containers/container/macvmstorage
  python3 -m pip install s3cmd
  scp macphsft41:/Users/sftnight/MARBLE/.s3cfg $HOST_NAME:/Users/sftnight/MARBLE

Create a CI VM
-----
If you only want a VM for debugging, skip step 4, which makes the VM available to the respective CI manager.

Either:

1 Download an ipsw file for your desired MacOS version from a trusted online source, these are recovery files for MacOS, hosted on Apples server, for which Apple has removed the link from their App Store. Since the links to these files were removed from the developer app store, the links are now exposed on third party websites. Make sure that these links actually point to apples servers before downloading. Parallels should also not accept unsigned ipsw files.

2 Create and configure the VMs with the prlctl and prl_disktool packages uniformly for the ROOT and SPI VMs:
    Execute './HOST_VM_SETUP_WRAPPER/HOST_create_vm.sh $PATH_TO_IPSW_IMAGE $VM_NAME'
    Follow the printed instructions from that script.

3 Download and install packages to the VM:

    For ROOT:
      Execute './HOST_VM_SETUP_WRAPPER/HOST_ROOT_setup_VM.sh $VM_NAME'
      
    For SPI:
      Execute './HOST_VM_SETUP_WRAPPER/HOST_SPI_setup_VM.sh $VM_NAME'
    
    These scripts use the prlctl exec command to execute install-scripts, which are shared from the HOST to the VM, on the VM itself, installing packages there, which differ from team to team. Be sure to install the correct package versions for the correct MacOS version, they might differ too.

Or:

  Execute 'S3_DOWNLOAD.sh $VM_NAME' to download, unpack and reconfigure a prepared VM - it must still be added to the network: https://landb.cern.ch/portal/devices/register and the PAT is not stored in the uploaded VMs.

Then add the VM to CI:

For ROOT:
  Execute './HOST_VM_SETUP_WRAPPER/HOST_ROOT_setup_runner.sh $VM_NAME $PAT'
  The PAT is very important, without it, the runner will not be registered to the ROOT repo. PAT stands for personal access token, please refer to githubs documentation for more detailed information: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
  To create your own, you need valid permissions in the ROOT repo, please ask your supervisor or the repo owner for the token if you do not have permissions yourself.
  The token needs the follwing permission: 
  https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens?apiVersion=2022-11-28#organization-permissions-for-self-hosted-runners
  A daemon and a matching script will be copied from ~/MARBLE to the VM and launch an ephemeral runner whenever the VM is started.
  To start cycling between the VMs, execute './start_vm_cycler.sh', to stop it './stop_vm_cycler.sh'
    
For SPI:
  Go to https://lcgapp-services.cern.ch/spi-jenkins/computer/new and copy one of the existing mac nodes, rename it and follow the naming scheme <host-name>-SPI-VM-macOS-<macos-version>, for example: macphsft41-SPI-VM-macOS-15.
  The node-name should match your VMs name

Replace a VM on a host
-----
1 ./stop_vm_cycler.sh

2 check whether there are running VMs with prlctl list, if not, jump to step 4

3 If there are running VMs, check whether they are busy running a process for Jenkins with `prlctl exec $VM_NAME "ps -ef | grep jenkins | grep -v 'grep' >/dev/null 2>&1 && echo 1 || echo 0"` and check whether busy running the Runner.Worker process for GitHub actions with `prlctl exec $VM_NAME "pgrep -f 'Runner.Worker' >/dev/null 2>&1 && echo 1 || echo 0"`. If both of those commands return 0, turn off the virtual machines with `prlctl stop $VM_NAME --kill`. If either of those commands does not return 0, do not turn off the VM - if you do, you will cancel or interrupt a CI run - wait until the command that returned 1 returns 0 as well, then turn it off with `prlctl stop $VM_NAME --kill`.

4 When no more virtual machines are running on the host, unlock all VMs, by executing `./.unlock_all_vms.sh`.

5 Lock all VMs except the one you want to work on by executing `./LOCK_ALL_EXCEPT.sh $VM_NAME`.

6 Check which VMs are available in the S3 bucket by executing `s3cmd ls s3://macvmstorage/SPI/` or `s3cmd ls s3://macvmstorage/ROOT/` and pick a VM image.

7 Pick a VM and download it from the bucket by following the steps in "Download a VM from an S3 bucket".

8 Return the host back to its previous working state by running `./.unlock_all_vms.sh` or `./start_vm_cycler.sh`.

Upload a VM to the S3 bucket
-----
1 Execute './S3_UPLOAD.sh $VM_NAME'

Download a VM from an S3 bucket
-----
1 Execute './S3_DOWNLOAD.sh $VM_NAME' (omit the .zip ending from the $VM_NAME, example: `./S3_DOWNLOAD.sh 2025-09-18-SPI-VM-macOS-13`)

2 Read the print from executing this script and follow the instructions.

3 (optional) If you want to add this VM to the CI pool for ROOT or SPI, follow the respective instruction sets, printed by the script and enter the new host-mac to the excel sheet.

Offer VMs to CI services (to be clear: you can offer both kinds of VMs on the same host-mac)
  For ROOT: 
    1 Start the vm_cycler.sh on the host-mac 
    2 Double-check that you executed optional step 4 in "Create a VM" and actually bootstrapped the runner.plist
  For SPI: 
    1 Go to https://lcgapp-services.cern.ch/spi-jenkins/computer/new
    2 Choose 'Copy Existing Node', enter the name of your new node and enter the name of another node that shares the same naming convention (macphsft[0-99]-SPI-macOS-[0-99]).
    3 Double-check the labels, they should include 'macVM' and 'mac[0-99]arm'. Make sure the correct version is specified on each node.
    4 Double-check that you executed optional step 4 in "Create a VM" and actually bootstrapped the timeout.plist

How to debug a problem
-----
1 On your mac
  - Get Parallels: follow steps 6-10 of 'Configure a VM host-mac'
  - Follow 'Download a VM from an S3 bucket'

2 On a CI host-mac
  - ssh host-mac (host-macs are listed in spreadsheet)
  - Disable the vm_cycler.sh to stop cycling the VMs ( ./MARBLE/stop_vm_cycler.sh )
  - Lock all other VMs from starting by executing 'LOCK_ALL_EXCEPT.sh $VM_NAME' where VM_NAME is the mac you want to work on.
  - If you are from SPI and want to work on an SPI mac
    - Remove the macXXarm label from the SPI mac you want to work on in Jenkins
    - Overview of jenkins mac-vm nodes: https://lcgapp-services.cern.ch/spi-jenkins/label/macVM/
  IMPORTANT once you are done working on the CI host-mac:
  - Launch 'vm_cycler.sh' ( ./MARBLE/start_vm_cycler.sh )
  - If you removed the Jenkins label, return it

Some useful prlctl commands
-----
1 To start a VM
prlctl start $VM_NAME

2 To stop a VM
prlctl stop $VM_NAME or prlctl stop $VM_NAME --kill

3 To list all VMs on a host
prlctl list -a

4 To list all information about a VM
prlctl list -i $VM_NAME

5 To execute a command on a VM
prlctl exec $VM_NAME "$COMMAND"

6 All prlctl commands are documented here as well
https://download.parallels.com/desktop/v20/docs/en_US/Parallels%20Desktop%20Command-Line%20Reference.pdf

Connecting to a host via Remmina
-----
INFO: first of all, this is only possible after the "Sharing" settings for the host are applied, this can technically be done through CLI as long as there are no additional barriers in place. If the command to set those settings through CLI is found, please add them here. Otherwise, configure the settings through the hosts GUI.

On Linux:
1 Download Remmina https://remmina.org/how-to-install-remmina/

2 Start Remmina

3 Click the little + in the top left

4 In the dropdown menu "Protocol", choose "Remmina VNC listener Plugin"

5 Fill "Server" in with VM_NAME and "Username" with "sftnight".

6 Save and Connect

Some common problems
-----
1 Slow DNS
When launching a VM, it sometimes takes up to multiple minutes to connect with the CERN network, even though the network connection to the host is fine.
This can occur on just one host-mac or multiple at once, it usually goes away until the next day. All macs are connected via Ethernet to the SFT Serverrack switch, maybe this is slow in registering virtual devices.
On the virtualization end, the VMs are connected via 'Bridged Network - Default Adapter', so that it exposes the VMs WiFi and Ethernet.
The VMs themselves show that they are connected via Ethernet, ipv4.

General information
-----
1 Sharing
Since VM hosts can be shared between SPI and ROOT, there has to be some kind of lockout function - if the host is in use by one of the Teams, the other Team can not access their VMs on it.
ROOTs VMs are started by the vm_cycler.sh script from the MARBLE repo, which cycles between ROOT VMs, leaving enough time before starting the next VM for jenkins to start an SPI VM. If a VM is running, the vm_cycler.sh is able to determine, whether that VM is currently busy - if the VM is running a Runner.Listener process or a Jenkins agent, it is left alone and the script to cycle again after ten seconds. 
In ROOTs case, the hosts state can be accessed by sshing to the host-mac and accessing /Users/sftnight/MARBLE/.vm_cycler.log.
SPIs Jenkins starts VMs with this script, which checks, whether a Runner.Listener process is running on the VM that is currently active or whether the jenkins master has an active connection to that VM - if there is one, the script exits and Jenkins tries to launch a different node: https://gitlab.cern.ch/ai/it-puppet-hostgroup-lcgapp/-/blob/master/code/files/jenkins/sftnight/.ssh/start_vm.sh?ref_type=heads
In Jenkins' case, the nodestate is visible on the Jenkins-webinterface. 
"Failed to start the VM: Access denied. You do not have enough rights to use this virtual machine." means, that the vm_cycler.sh has locked down the VMs, because it is currently running a ROOT VM.

2 build_drive.hdd
This is a build drive, which is shared by all the VMs on that host to reduce storage overhead in builds. It is stored in /Users/sftnight/Parallels/build_drive.hdd. I was unable to mount it from the host directly, although this used to be possible and might still be, by using Parallels Mounter.

3 Only one VM at a time
Because of the build_drive that is being mounted by each VM on a host, only one VM can be on on a single host at a time.

Some explanations about what the different scripts do
-----
vm_cycler.sh turns ROOT vms on and off in 60s+random intervals.
Whenever a ROOT VM is turned off, 60s are spent waiting if spi jenkins starts any VMs on the host - vm_cycler can turn off jenkins VMs and jenkins can turn off ROOT VMs, as long as they are not running CI jobs.
When this timer is run out, a ROOT VM is started, cycling between all ROOT VMs on the system.
start_vm_cycler.sh starts and stop_vm_cycler.sh stops the vm_cycler.

HOST_create_vm.sh  creates a VM from an ipsw file in the first place
HOST_ROOT_setup_VM.sh installs packages for ROOT onto VM
HOST_SPI_setup_VM.sh installs packages for SPI onto VM

S3_UPLOAD_VM.sh uploads a VM from a host to the bucket - and removes the secret github PAT from the VM, without which the VM can not register a runner to the CI 
S3_DOWNLOAD_VM.sh downloads a VM from the bucket to a host
HOST_ROOT_setup_runner.sh copies the necessary script and daemon to a freshly created or downloaded VM and writes the github PAT onto it, so that the VM can register a runner automatically
AUTO_RUNNER contains the daemon and the script that the VM uses to launch the runner by itself
