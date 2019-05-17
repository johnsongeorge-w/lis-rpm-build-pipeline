#!/bin/bash

#####################################################################
#
# Install LIS 4.0 by performing the following tasks
#   - Verfiy we are running on a RHEL or CentOS distribution.
#     Note: for the preview release only CentOS is supported.
#   - Determine the version of the distribution we are running on.
#   - cd to the apporpriate subdirectory for the version.
#   - Remove the Hyper-V daemons if they are installed.
#   - Invoke the version specific install.sh script.
#
# Kernel version
#  7.6    3.10.0-957
#  7.5    3.10.0-862
#  7.4    3.10.0-693
#  7.3    3.10.0-514
#  7.2    3.10.0-327
#  7.1    3.10.0-229
#  7.0    3.10.0-123
#  6.10   2.6.32-754
#  6.9    2.6.32-696
#  6.8    2.6.32-642
#  6.7    2.6.32-573
#  6.6    2.6.32-504
#  6.5    2.6.32-431
#  6.4    2.6.32-358
#  6.3    2.6.32-279
#  6.2    2.6.32-220
#  6.1    2.6.32-131.0.15
#  6.0    2.6.32-71
#  5.11   2.6.18-398
#  5.11.1   2.6.18-408
#  5.10   2.6.18-371
#  5.9    2.6.18-348
#  5.8    2.6.18-308
#  5.7    2.6.18-274
#  5.6    2.6.18-238
#  5.5    2.6.18-194
#  5.4    2.6.18-164
#  5.3    2.6.18-128
#  5.2    2.6.18-92
#
#  Other releases are not supported.
#
#####################################################################

architecture=`uname -m`

distro_name="unknown"
distro_version="unknown"

source commonfunctions.sh

#
# Main script body
#
# Check if kernel version running is higher compared to installed kernel.
# This is important because kmod are dependent on Kernel version

GetDistroName
if [ $distro_name = "unknown" ]; then
    echo "Unsupported Linux distribution"
    exit 1
fi

GetDistroVersion
if [ $distro_version = "unknown" ]; then
    echo "Unsupported kernel version"
    exit 1
fi

if [ $distro_name = "Oracle" ]; then
	CheckSupportOracleDistro 
	if [ $? -ne 0 ]; then
		echo "Installation is not supported for Oracle distro from series 52 to 63"
		exit 1
	fi
fi

IsKernelSupported "RHEL$distro_version"
if [ $? -eq 0 ];then
	echo "Kernel version not supported, Exiting"
	exit 1
fi

if [[ $distro_version != "5"* ]]; then
 export no_initramfs=1
 latestkernel=(`rpm -q kernel | tail -n1 | cut -c 8-`)
 runningkernel=(`uname -r`)
 if [ ${latestkernel} != ${runningkernel} ] ; then
   echo "your running kernel ${runningkernel} is not your latest installed kernel, aborting installation"
   exit 1
 fi
fi

targetDir="${distro_package_name}${distro_version}"

if [ ! -e "./${targetDir}" ]; then
	echo "The distribution specific directory '${targetDir}' does not exist"
	exit 1
fi

if [[ $distro_version == "7"* ]]; then
 if [ -e /etc/modprobe.d/hyperv_pvdrivers.conf ]; then
  mv /etc/modprobe.d/hyperv_pvdrivers.conf /opt/files/
 fi
fi

cd ${targetDir}

#
# If the daemons are left installed, the new rpms will fail to install
#
RemoveHypervDaemons

#
# Hyper-V tools conflicts with installation, removing the tool
#
RemoveHypervTools

#
# Invoke the release specific install script
#
echo "Invoking release specific install file in directory ${targetDir}"
./install.sh

exit $? 

