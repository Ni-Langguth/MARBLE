# MARBLE
MacOS Actions Runners Balancing Load Efficiently

MARBLE strives to work around Apples restrictions in dockerization of MacOS by automating the creation and configuration of MacOS virtual machines with the Parallels Desktop virtualization software as far as possible and instructing in the ways that could not be automated.
This approach allows the maintenance of a consistent build environment and automates the up- and download of the virtual machines to a prefconfigured S3 bucket, laying important groundwork for a scalable MacOS VM service in the SFT group, that can be used by ROOT and the parts of SPI, which don't require cvmfs (it relying on macfuse, which is a kernel - not a system - extension does not allow it to be used on mac VMs on apple silicon).
Instructions in this readme contain:
 - Configure a VM host-mac
 - Create a VM (for debugging and CI)
 - Add a VM to CI
 - Upload a VM to the S3 bucket
 - Download a VM from the S3 bucket
 - Some useful prlctl commands

Configure a VM host-mac (mandatory)
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

6 Enroll in mdm and follow instructions: https://devices.docs.cern.ch/devices/mac/MacSelfService/Enrolling/
  
7 Log into Self-Service with SSO.

8 Find and request Parallels Desktop in Self-Service.

9 Download s3cmd python package for interaction with macVM bucket: https://openstack.cern.ch/project/containers/container/macvmstorage
  python3 -m pip install s3cmd
  scp macphsft41:/Users/sftnight/MARBLE/.s3cfg $HOST_NAME:/Users/sftnight/MARBLE

10 Add a private ssh key so that jenkins' public key matches it. (This is horrible practice and we should change it)

11 Pull this repo to the home directory of your user /Users/sftnight. It has to be this directory for the execution of the scripts on the VM to work.

12 Disable indexing on the whole mac to save computing ressources.
   sudo mdutil -i off /
   Check whether indexing is actually off.
   mdutil -s /

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
      Execute 'HOST_SPI_setup_VM.sh $VM_NAME'
    These scripts use the prlctl exec command to execute install-scripts, which are shared from the HOST to the VM, on the VM itself, installing packages there, which differ from team to team. Be sure to install the correct package versions for the correct MacOS version, they might differ too.

Or:

  Execute 'S3_DOWNLOAD.sh $VM_NAME' to download, unpack and reconfigure a prepared VM - it must still be added to the network: https://landb.cern.ch/portal/devices/register and the PAT is not stored in the uploaded VMs.

Then add the VM to CI:

  Bootstrap a daemon on the VM to perform automated tasks once the VM is launched:
    For ROOT:
      Execute './HOST_VM_SETUP_WRAPPER/HOST_ROOT_setup_runner.sh $VM_NAME $PAT'
      The PAT is very important, without it, the runner will not be registered to the ROOT repo. PAT stands for personal access token, please refer to githubs documentation for more detailed information: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
      To create your own, you need valid permissions in the ROOT repo, please ask your supervisor or the repo owner for the token.
      The token itself needs the follwing permission: 
      https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens?apiVersion=2022-11-28#organization-permissions-for-self-hosted-runners
      A daemon and a matching script will be copied from ~/MARBLE to the VM and launch an ephemeral runner whenever the VM is started.
    For SPI:
      Execute 'HOST_SPI_03_configure_daemon.sh $VM_NAME'
      The daemon executes a script, which checks once after 60 seconds, then in 10 second intervals, whether the VM is running the jenkins-agent - if not, the VM is stopped by the script, because it does not appear to be busy.
      Go to https://lcgapp-services.cern.ch/spi-jenkins/computer/new and copy one of the existing mac nodes, rename it and follow the naming scheme <host-name>-SPI-VM-macOS-<macos-version>, for example: macphsft41-SPI-VM-macOS-15.
      The node-name should match your VMs name

Upload a VM to the S3 bucket
-----
1 Execute './S3_UPLOAD.sh $VM_NAME'

Download a VM from an S3 bucket
-----
1 Execute './S3_DOWNLOAD.sh $VM_NAME'

2 Read the print from executing this script and follow the instructions in it to do those things manually, which I was unable to automate.

3 (optional) If you want to add this VM to the CI pool for ROOT or SPI, follow the respective instruction sets, printed by the script and enter the new host to the excel sheet.

Offer VMs to CI services (to be clear: you can offer both kinds of VMs on the same host)
  For ROOT: 
    1 Start the vm_cycler.sh on the host-mac 
    2 Double-check that you executed optional step 4 in "Create a VM" and actually bootstrapped the runner.plist
  For SPI: 
    1 Go to https://lcgapp-services.cern.ch/spi-jenkins/computer/new
    2 Choose 'Copy Existing Node', enter the name of your new node and enter the name of another node that shares the same naming convention (macphsft[0-99]-SPI-macOS-[0-99]).
    3 Double-check the labels, they should include 'macVM' and 'mac[0-99]arm'. Make sure the correct version is specified on each node.
    4 Double-check that you executed optional step 4 in "Create a VM" and actually bootstrapped the timeout.plist

Some useful prlctl commands
-----
1 To start a VM
prlctl start $VM_NAME

2 To stop a VM
prlctl stop $VM_NAME
or
prlctl stop $VM_NAME --kill

3 To list all VMs on a host
prlctl list -a

4 To list all information about a VM
prlctl list -i $VM_NAME

5 To execute a command on a VM
prlctl exec $VM_NAME "$COMMAND"

6 All prlctl commands are documented here as well
https://download.parallels.com/desktop/v20/docs/en_US/Parallels%20Desktop%20Command-Line%20Reference.pdf
