#!/bin/bash
## Setting build variables
UNAME=$(uname -r)
UNRAID_V=6.8.3
DATA_DIR=/root/kernel
IMAGES_FILE_PATH=/usr/src/stock
CPU_COUNT=10
VENDOR_RESET=true

## Check if Beta build mode is enabled and throw error if no images are found
if [ "${BETA_BUILD}" == "true" ]; then
	if [ ! -f ${DATA_DIR}/stock/beta/bzroot ] || [ ! -f ${DATA_DIR}/stock/beta/bzimage ] || [ ! -f ${DATA_DIR}/stock/beta/bzmodules ] || [ ! -f ${DATA_DIR}/stock/beta/bzfirmware ]; then
		echo "----------------------------------------------------------"
		echo "-----No stock images found, please extract the stock------"
		echo "---Beta images (bzimage, bzroot, bzmodules, bzfirmware)---"
		echo "---from the preferred Unraid Beta version in the folder---"
		echo "----'/stock/beta/' and restart the Container, putting-----"
		echo "----------------Container into sleep mode!----------------"
		echo "----------------------------------------------------------"
		echo "----Now you could also put in the beta version number-----"
		echo "----that you want to build in the variable BETA_BUILD-----"
		echo "------in this format: 'beta25' and it will download-------"
		echo "---------the version and build your Kernel/Images---------"
		echo "----------------------------------------------------------"
		sleep infinity
	else
		IMAGES_FILE_PATH=${DATA_DIR}/stock/beta
	fi
elif [ -z "${BETA_BUILD}" ]; then
	## Check if images of Stock Unraid version are present or download them if default path is /usr/src/stock
	if [ "$IMAGES_FILE_PATH" == "/usr/src/stock" ]; then
		if [ ! -d ${DATA_DIR}/stock/${UNRAID_V} ]; then
			mkdir -p ${DATA_DIR}/stock/${UNRAID_V}
		fi
		if [ ! -f ${DATA_DIR}/stock/${UNRAID_V}/bzroot ] || [ ! -f ${DATA_DIR}/stock/${UNRAID_V}/bzimage ] || [ ! -f ${DATA_DIR}/stock/${UNRAID_V}/bzmodules ] || [ ! -f ${DATA_DIR}/stock/${UNRAID_V}/bzfirmware ]; then
			cd ${DATA_DIR}/stock/${UNRAID_V}
			echo "---One or more Stock Unraid v${UNRAID_V} files not found, downloading...---"
			if [ ! -f ${DATA_DIR}/unRAIDServer-${UNRAID_V}-x86_64.zip ]; then
				if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/stock/${UNRAID_V}/unRAIDServer-${UNRAID_V}-x86_64.zip "https://s3.amazonaws.com/dnld.lime-technology.com/stable/unRAIDServer-${UNRAID_V}-x86_64.zip" ; then
					echo "---Successfully downloaded Stock Unraid v${UNRAID_V}---"
				else
					echo "---Download of Stock Unraid v${UNRAID_V} failed, putting container into sleep mode!---"
					echo
					echo "--------------------------------------------------------------------------------------"
					echo "----If you want to build the Kernel/Images for a Beta version of Unraid please make---"
					echo "-------------sure to set the BETA_BUILD variable in the template to 'true'------------"
					echo "--------------------------------------------------------------------------------------"
					sleep infinity
				fi
			elif [ ${DATA_DIR}/unRAIDServer-${UNRAID_V}-x86_64.zip ]; then
				echo "---unRAIDServer-${UNRAID_V}-x86_64.zip found locally---"
				cp ${DATA_DIR}/unRAIDServer-${UNRAID_V}-x86_64.zip ${DATA_DIR}/stock/${UNRAID_V}/unRAIDServer-${UNRAID_V}-x86_64.zip
			fi
			echo "---Extracting files---"
			unzip -o ${DATA_DIR}/stock/${UNRAID_V}/unRAIDServer-${UNRAID_V}-x86_64.zip
			if [ ! -f ${DATA_DIR}/unRAIDServer-${UNRAID_V}-x86_64.zip ]; then
				mv ${DATA_DIR}/stock/${UNRAID_V}/unRAIDServer-${UNRAID_V}-x86_64.zip ${DATA_DIR}
			fi
			find . -maxdepth 1 -not -name 'bz*' -print0 | xargs -0 -I {} rm -R {} 2&>/dev/null
			rm ${DATA_DIR}/stock/${UNRAID_V}/*.sha256
		fi
		IMAGES_FILE_PATH=${DATA_DIR}/stock/${UNRAID_V}
	fi
else
	if [ ! -d ${DATA_DIR}/stock/beta ]; then
		mkdir -p ${DATA_DIR}/stock/beta
	fi
	if [ ! -f ${DATA_DIR}/stock/beta/bzroot ] || [ ! -f ${DATA_DIR}/stock/beta/bzimage ] || [ ! -f ${DATA_DIR}/stock/beta/bzmodules ] || [ ! -f ${DATA_DIR}/stock/beta/bzfirmware ]; then
		cd ${DATA_DIR}/stock/beta
		echo "---One or more Stock Unraid v${UNRAID_V}-${BETA_BUILD} files not found, downloading...---"
		if [ ! -f ${DATA_DIR}/unRAIDServer-${UNRAID_V}-${BETA_BUILD}-x86_64.zip ]; then
			if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/stock/beta/unRAIDServer-${UNRAID_V}-${BETA_BUILD}-x86_64.zip "https://s3.amazonaws.com/dnld.lime-technology.com/next/unRAIDServer-${UNRAID_V}-${BETA_BUILD}-x86_64.zip" ; then
				echo "---Successfully downloaded Stock Unraid v${UNRAID_V}-${BETA_BUILD}---"
			else
				echo "---Download of Stock Unraid v${UNRAID_V}-${BETA_BUILD} failed, putting container into sleep mode!---"
				sleep infinity
			fi
		elif [ ${DATA_DIR}/unRAIDServer-${UNRAID_V}-${BETA_BUILD}-x86_64.zip ]; then
			echo "---unRAIDServer-${UNRAID_V}-${BETA_BUILD}-x86_64.zip found locally---"
			cp ${DATA_DIR}/unRAIDServer-${UNRAID_V}-${BETA_BUILD}-x86_64.zip ${DATA_DIR}/stock/beta/unRAIDServer-${UNRAID_V}-${BETA_BUILD}-x86_64.zip
		fi
		echo "---Extracting files---"
		unzip -o ${DATA_DIR}/stock/beta/unRAIDServer-${UNRAID_V}-${BETA_BUILD}-x86_64.zip
		if [ ! -f ${DATA_DIR}/unRAIDServer-${UNRAID_V}-${BETA_BUILD}-x86_64.zip ]; then
			mv ${DATA_DIR}/stock/beta/unRAIDServer-${UNRAID_V}-${BETA_BUILD}-x86_64.zip ${DATA_DIR}
		fi
		find . -maxdepth 1 -not -name 'bz*' -print0 | xargs -0 -I {} rm -R {} 2&>/dev/null
		rm ${DATA_DIR}/stock/beta/*.sha256
	fi
	IMAGES_FILE_PATH=${DATA_DIR}/stock/beta
fi

## Create output folder
if [ ! -d ${DATA_DIR}/output-$UNAME ]; then
	mkdir ${DATA_DIR}/output-$UNAME
fi

## Decompress bzroot
echo "---Decompressing bzroot, this can take some time, please wait!---"
if [ ! -d ${DATA_DIR}/bzroot-extracted-$UNAME ]; then
	mkdir ${DATA_DIR}/bzroot-extracted-$UNAME
fi
if [ ! -f $IMAGES_FILE_PATH/bzroot ]; then
	echo "---Can't find 'bzroot', check your configuration, putting container into sleep mode---"
	sleep infinity
fi
cd ${DATA_DIR}/bzroot-extracted-$UNAME
dd if=$IMAGES_FILE_PATH/bzroot bs=512 count=$(cpio -ivt -H newc < $IMAGES_FILE_PATH/bzroot 2>&1 > /dev/null | awk '{print $1}') of=${DATA_DIR}/output-$UNAME/microcode
dd if=$IMAGES_FILE_PATH/bzroot bs=512 skip=$(cpio -ivt -H newc < $IMAGES_FILE_PATH/bzroot 2>&1 > /dev/null | awk '{print $1}') | xzcat | cpio -i -d -H newc --no-absolute-filenames

## Preparing directorys modules and firmware
if [ -d /lib/modules ]; then
	rm -R /lib/modules
fi
mkdir /lib/modules
if [ -d /lib/firmware ]; then
	rm -R /lib/firmware
fi
mkdir /lib/firmware

## Extracting Stock Unraid images to modules and firmware
if [ ! -f $IMAGES_FILE_PATH/bzmodules ]; then
	echo "---Can't find 'bzmodules', check your configuration, putting container into sleep mode---"
	sleep infinity
fi
unsquashfs -f -d /lib/modules $IMAGES_FILE_PATH/bzmodules

if [ ! -f $IMAGES_FILE_PATH/bzfirmware ]; then
	echo "---Can't find 'bzfirmware', check your configuration, putting container into sleep mode---"
	sleep infinity
fi
unsquashfs -f -d /lib/firmware $IMAGES_FILE_PATH/bzfirmware

## Check if Beta build mode is enabled
if [ "${BETA_BUILD}" == "true" ]; then
	## Get Kernel I don't care how you get em, just get em
	UNAME="$(ls ${DATA_DIR}/bzroot-extracted-$UNAME/usr/src/ | cut -d '-' -f2,3 | cut -d '/' -f1)"
	CUR_K_V="$(echo $UNAME | cut -d '-' -f 1)"
	MAIN_V="$(echo $UNAME | cut -d '.' -f 1)"
	
	if [ "${CUR_K_V##*.}" == "0" ]; then
		CUR_K_V="${CUR_K_V%.*}"
	fi
	## Download Kernel to data directory & extract it if not present
	cd ${DATA_DIR}
	if [ ! -d ${DATA_DIR}/linux-$UNAME ]; then
		mkdir ${DATA_DIR}/linux-$UNAME
	fi
	if [ ! -f ${DATA_DIR}/linux-$CUR_K_V.tar.gz ]; then
		echo "---Downloading Kernel v${UNAME%-*}---"
		if wget -q -nc --show-progress --progress=bar:force:noscroll https://mirrors.edge.kernel.org/pub/linux/kernel/v$MAIN_V.x/linux-$CUR_K_V.tar.gz ; then
			echo "---Successfully downloaded Kernel v${UNAME%-*}---"
		else
			echo "---Download of Kernel v${UNAME%-*} failed, putting container into sleep mode!---"
			sleep infinity
		fi
		echo "---Extracting Kernel v${UNAME%-*}, this can take some time, please wait!---"
		tar -C ${DATA_DIR}/linux-$UNAME --strip-components=1 -xf ${DATA_DIR}/linux-$CUR_K_V.tar.gz
	else
		echo "---Found Kernel v${UNAME%-*} locally, extracting, this can take some time, please wait!---"
		tar -C ${DATA_DIR}/linux-$UNAME --strip-components=1 -xf ${DATA_DIR}/linux-$CUR_K_V.tar.gz
	fi
	mv ${DATA_DIR}/bzroot-extracted* ${DATA_DIR}/bzroot-extracted-$UNAME
	mv ${DATA_DIR}/output-* ${DATA_DIR}/output-$UNAME
else
	## Get Kernel versions depending on manually set or not
	if [ "${UNAME}" == "stock" ]; then
		UNAME="$(ls ${DATA_DIR}/bzroot-extracted-$UNAME/usr/src/ | cut -d '-' -f2,3 | cut -d '/' -f1)"
		CUR_K_V="$(echo $UNAME | cut -d '-' -f 1)"
		MAIN_V="$(echo $UNAME | cut -d '.' -f 1)"
	else
		UNAME="$(echo $UNAME | cut -d '+' -f1)"
		CUR_K_V="$(echo $UNAME | cut -d '-' -f 1)"
		MAIN_V="$(echo $UNAME | cut -d '.' -f 1)"
	fi
	if [ "${CUR_K_V##*.}" == "0" ]; then
		CUR_K_V="${CUR_K_V%.*}"
	fi
	## Download Kernel to data directory & extract it if not present
	cd ${DATA_DIR}
	if [ ! -d ${DATA_DIR}/linux-$UNAME ]; then
		mkdir ${DATA_DIR}/linux-$UNAME
	fi
	if [ ! -f ${DATA_DIR}/linux-$CUR_K_V.tar.gz ]; then
		echo "---Downloading Kernel v${UNAME%-*}---"
		if wget -q -nc --show-progress --progress=bar:force:noscroll https://mirrors.edge.kernel.org/pub/linux/kernel/v$MAIN_V.x/linux-$CUR_K_V.tar.gz ; then
			echo "---Successfully downloaded Kernel v${UNAME%-*}---"
		else
			echo "---Download of Kernel v${UNAME%-*} failed, putting container into sleep mode!---"
			sleep infinity
		fi
		echo "---Extracting Kernel v${UNAME%-*}, this can take some time, please wait!---"
		tar -C ${DATA_DIR}/linux-$UNAME --strip-components=1 -xf ${DATA_DIR}/linux-$CUR_K_V.tar.gz
	else
		echo "---Found Kernel v${UNAME%-*} locally, extracting, this can take some time, please wait!---"
		tar -C ${DATA_DIR}/linux-$UNAME --strip-components=1 -xf ${DATA_DIR}/linux-$CUR_K_V.tar.gz
	fi
	mv ${DATA_DIR}/bzroot-extracted* ${DATA_DIR}/bzroot-extracted-$UNAME
	mv ${DATA_DIR}/output-* ${DATA_DIR}/output-$UNAME
fi

## Copy patches & config to new Kernel directory
echo "---Copying Patches and Config file to the Kernel directory---"
rsync -av ${DATA_DIR}/bzroot-extracted-$UNAME/usr/src/linux-*/ ${DATA_DIR}/linux-$UNAME

## Copy user patches if enabled
if [ "${USER_PATCHES}" == "true" ]; then
	echo "---Copying patches from directory 'user_patches' to the Kernel directory---"
	rsync -av ${DATA_DIR}/user_patches/ ${DATA_DIR}/linux-$UNAME
fi

## Apply changes to .config
if [ "${BUILD_DVB}" == "true" ]; then
	cd ${DATA_DIR}/linux-$UNAME
	echo "---Patching necessary files for 'dvb', this can take some time, please wait!---"
	while read -r line
	do
		line_conf=${line//# /}
		line_conf=${line_conf%%=*}
		line_conf=${line_conf%% *}
		sed -i "/$line_conf/d" "${DATA_DIR}/linux-$UNAME/.config"
		echo "$line" >> "${DATA_DIR}/linux-$UNAME/.config"
	done < "${DATA_DIR}/deps/dvb.list"
fi

if [ "${BUILD_ISCSI}" == "true" ]; then
	cd ${DATA_DIR}/linux-$UNAME
	echo "---Patching necessary files for 'joydev', this can take some time, please wait!---"
	while read -r line
	do
		line_conf=${line//# /}
		line_conf=${line_conf%%=*}
		line_conf=${line_conf%% *}
		sed -i "/$line_conf/d" "${DATA_DIR}/linux-$UNAME/.config"
		echo "$line" >> "${DATA_DIR}/linux-$UNAME/.config"
	done < "${DATA_DIR}/deps/iscsi.list"
fi

if [ "${BUILD_JOYDEV}" == "true" ]; then
	cd ${DATA_DIR}/linux-$UNAME
	echo "---Patching necessary files for 'joydev', this can take some time, please wait!---"
	while read -r line
	do
		line_conf=${line//# /}
		line_conf=${line_conf%%=*}
		line_conf=${line_conf%% *}
		sed -i "/$line_conf/d" "${DATA_DIR}/linux-$UNAME/.config"
		echo "$line" >> "${DATA_DIR}/linux-$UNAME/.config"
	done < "${DATA_DIR}/deps/joydev.list"
fi

if [ "${VENDOR_RESET}" == "true" ]; then
	cd ${DATA_DIR}/linux-$UNAME
	echo "---Patching necessary files for 'vendor_reset', this can take some time, please wait!---"
	echo "CONFIG_FTRACE=y">> "${DATA_DIR}/linux-$UNAME/.config"
        echo "CONFIG_KPROBES=y" >> "${DATA_DIR}/linux-$UNAME/.config"
        echo "CONFIG_PCI_QUIRKS=y" >> "${DATA_DIR}/linux-$UNAME/.config"
        echo "CONFIG_KALLSYMS=y" >> "${DATA_DIR}/linux-$UNAME/.config"
        echo "CONFIG_KALLSYMS_ALL=y" >> "${DATA_DIR}/linux-$UNAME/.config"
        echo "CONFIG_FUNCTION_TRACER=y" >> "${DATA_DIR}/linux-$UNAME/.config"
fi

if [ "${CUSTOM_MODE}" == "stopbevorkernelbuild" ]; then
	echo "---Everything prepared, stopping---"
	sleep infinity
fi

## Apply patches
echo "---Applying patches to Kernel, please wait!---"
cd ${DATA_DIR}/linux-$UNAME
find ${DATA_DIR}/linux-$UNAME -type f -iname '*.patch' -print0|xargs -n1 -0 patch -p 1 -i

## Make oldconfig
cd ${DATA_DIR}/linux-$UNAME
make oldconfig

echo "---Starting to build Kernel v${UNAME%-*}, this can take some time, please wait!---"
if [ "${DONTWAIT}" != "true" ]; then
	echo "---Starting to build Kernel v${UNAME%-*} in 10 seconds, this can take some time, please wait!---"
	sleep 10
fi
cd ${DATA_DIR}/linux-$UNAME
make -j${CPU_COUNT}

echo "---Starting to install Kernel Modules, please wait!---"
if [ "${DONTWAIT}" != "true" ]; then
	echo "---Starting to install Kernel Modules in 10 seconds, please wait!---"
	sleep 10
fi
cd ${DATA_DIR}/linux-$UNAME
make modules_install

## Copy Kernel image to output folder
echo "---Copying Kernel Image to output folder---"
cp ${DATA_DIR}/linux-$UNAME/arch/x86_64/boot/bzImage ${DATA_DIR}/output-$UNAME/bzimage

if [ "${CUSTOM_MODE}" == "stopafterkernelbuild" ]; then
	echo "---Kernel built, stopping---"
	sleep infinity
fi

if [ "${BUILD_DVB}" == "true" ]; then
	if [ "${DVB_TYPE}" == "digitaldevices" ]; then
		## Download and install DigitalDevices drivers
		echo "---Downloading DigitalDevices drivers v${DD_DRV_V}, please wait!---"
		cd ${DATA_DIR}
		if [ ! -d ${DATA_DIR}/dd-v${DD_DRV_V} ]; then
			mkdir ${DATA_DIR}/dd-v${DD_DRV_V}
		fi
		if [ ! -f ${DATA_DIR}/dd-v${DD_DRV_V}.tar.gz ]; then
			echo "---Downloading DigitalDevices driver v${DD_DRV_V}, please wait!---"
			if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/dd-v${DD_DRV_V}.tar.gz https://github.com/DigitalDevices/dddvb/archive/${DD_DRV_V}.tar.gz ; then
				echo "---Successfully downloaded DigitalDevices drivers v${DD_DRV_V}---"
			else
				echo "---Download of DigitalDevices driver v${DD_DRV_V} failed, putting container into sleep mode!---"
				sleep infinity
			fi
		else
			echo "---DigitalDevices driver v${DD_DRV_V} found locally---"
		fi
		tar -C ${DATA_DIR}/dd-v${DD_DRV_V} --strip-components=1 -xf ${DATA_DIR}/dd-v${DD_DRV_V}.tar.gz
		cd ${DATA_DIR}/dd-v${DD_DRV_V}
		make -j${CPU_COUNT}
		make install
	elif [ "${DVB_TYPE}" == "xboxoneusb" ]; then
		## Download and install Xbox One Digital TV Tuner firwmare
		## https://www.linuxtv.org/wiki/index.php/Xbox_One_Digital_TV_Tuner
		cd /lib/firmware
		if wget -q -nc --show-progress --progress=bar:force:noscroll "http://linuxtv.org/downloads/firmware/dvb-usb-dib0700-1.20.fw" ; then
				echo "---Successfully downloaded Xbox One Digital TV Tuner firmware 'dvb-usb-dib0700-1.20.fw'---"
		else
			echo "---Download of Xbox One Digital TV Tuner firmware 'dvb-usb-dib0700-1.20.fw' failed, putting container into sleep mode!---"
			sleep infinity
		fi
		if wget -q -nc --show-progress --progress=bar:force:noscroll "http://palosaari.fi/linux/v4l-dvb/firmware/MN88472/02/latest/dvb-demod-mn88472-02.fw" ; then
				echo "---Successfully downloaded Xbox One Digital TV Tuner firmware 'dvb-demod-mn88472-02.fw'---"
		else
			echo "---Download of Xbox One Digital TV Tuner firmware 'dvb-demod-mn88472-02.fw' failed, putting container into sleep mode!---"
			sleep infinity
		fi
	elif [ "${DVB_TYPE}" == "libreelec" ]; then
		## Download and install LibreELEC drivers
		## https://github.com/LibreELEC/dvb-firmware
		echo "---Downloading LibreELEC drivers v${LE_DRV_V}, please wait!---"
		cd ${DATA_DIR}
		if [ ! -d ${DATA_DIR}/lE-v${LE_DRV_V} ]; then
			mkdir ${DATA_DIR}/lE-v${LE_DRV_V}
		fi
		if [ ! -f ${DATA_DIR}/lE-v${LE_DRV_V}.tar.gz ]; then
			echo "---Downloading LibreELEC driver v${LE_DRV_V}, please wait!---"
			if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/lE-v${LE_DRV_V}.tar.gz https://github.com/LibreELEC/dvb-firmware/archive/${LE_DRV_V}.tar.gz ; then
				echo "---Successfully downloaded LibreELEC drivers v${LE_DRV_V}---"
			else
				echo "---Download of LibreELEC driver v${LE_DRV_V} failed, putting container into sleep mode!---"
				sleep infinity
			fi
		else
			echo "---LibreELEC driver v${LE_DRV_V} found locally---"
		fi
		tar -C ${DATA_DIR}/lE-v${LE_DRV_V} --strip-components=1 -xf ${DATA_DIR}/lE-v${LE_DRV_V}.tar.gz
		rsync -av ${DATA_DIR}/lE-v${LE_DRV_V}/firmware/ /lib/firmware/
	elif [ "${DVB_TYPE}" == "tbsos" ]; then
		## Downloading and compiling TBS OpenSource drivers
		## https://github.com/tbsdtv
		echo "---Downloading TBS OpenSource drivers, please wait!---"
		cd ${DATA_DIR}
		if [ ! -d ${DATA_DIR}/media_build-${TBS_MEDIA_BUILD_V} ]; then
			mkdir ${DATA_DIR}/media_build-${TBS_MEDIA_BUILD_V}
		fi
		if [ ! -f ${DATA_DIR}/media_build-v${TBS_MEDIA_BUILD_V}.tar.bz2 ]; then
			echo "---Downloading 'media_build' drivers v${TBS_MEDIA_BUILD_V}, please wait!---"
			if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/media_build-v${TBS_MEDIA_BUILD_V}.tar.bz2 http://www.tbsdtv.com/download/document/linux/media_build-${TBS_MEDIA_BUILD_V}.tar.bz2 ; then
				echo "---Successfully downloaded 'media_build' drivers v${TBS_MEDIA_BUILD_V}---"
			else
				echo "---Download of 'media_build' drivers v${TBS_MEDIA_BUILD_V} failed, putting container into sleep mode!---"
				sleep infinity
			fi
		else
			echo "---'media_build' drivers v${TBS_MEDIA_BUILD_V} found locally---"
		fi
		rm -rf /lib/modules/${UNAME}/kernel/drivers/media/
		tar -C ${DATA_DIR}/media_build-${TBS_MEDIA_BUILD_V} --strip-components=1 -xf ${DATA_DIR}/media_build-v${TBS_MEDIA_BUILD_V}.tar.bz2
		cd ${DATA_DIR}/media_build-${TBS_MEDIA_BUILD_V}
		${DATA_DIR}/media_build-${TBS_MEDIA_BUILD_V}/patch-kernel.sh
		make distclean
		make stagingconfig
		make -j${CPU_COUNT}
		rm -rf /lib/modules/${UNAME}/kernel/drivers/media
		rm -rf /lib/modules/${UNAME}/kernel/drivers/staging/media
		rm -rf /lib/modules/${UNAME}/extra
		make install
		## Download and install TBS Tuner Firmwares
		## https://github.com/tbsdtv/linux_media/wiki#firmware
		cd ${DATA_DIR}
		if [ ! -f ${DATA_DIR}/tbs-tuner-firmwares_v1.0.tar.bz2 ]; then
			echo "---Downloading TBS Tuner Firmwares v1.0, please wait!---"
			if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/tbs-tuner-firmwares_v1.0.tar.bz2 http://www.tbsdtv.com/download/document/linux/tbs-tuner-firmwares_v1.0.tar.bz2 ; then
				echo "---Successfully downloaded TBS Tuner Firmwares v1.0---"
			else
				echo "---Download of TBS Tuner Firmwares v1.0 failed, putting container into sleep mode!---"
				sleep infinity
			fi
		else
			echo "---TBS Tuner Firmwares v1.0 found locally---"
		fi
		tar jxvf ${DATA_DIR}/tbs-tuner-firmwares_v1.0.tar.bz2 -C /lib/firmware/
	fi
fi

if [ "${BUILD_ZFS}" == "true" ]; then
	## Download and install ZFS
	if [ "${ZFS_V}" == "latest" ]; then
		echo "---Downloading ZFS v${ZFS_V}, please wait!---"
		cd ${DATA_DIR}
		if [ ! -d ${DATA_DIR}/zfs-v${ZFS_V} ]; then
			mkdir ${DATA_DIR}/zfs-v${ZFS_V}
		fi
		if [ ! -f ${DATA_DIR}/zfs-v${ZFS_V}.tar.gz ]; then
			echo "---Downloading ZFS v${ZFS_V}, please wait!---"
			if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/zfs-v${ZFS_V}.tar.gz https://github.com/openzfs/zfs/releases/download/zfs-${ZFS_V}/zfs-${ZFS_V}.tar.gz ; then
				echo "---Successfully downloaded ZFS v${ZFS_V}---"
			else
				echo "---Download of ZFS v${ZFS_V} failed, putting container into sleep mode!---"
				sleep infinity
			fi
		else
			echo "---ZFS v${ZFS_V} found locally---"
		fi
		tar -C ${DATA_DIR}/zfs-v${ZFS_V} --strip-components=1 -xf ${DATA_DIR}/zfs-v${ZFS_V}.tar.gz
		echo "---Compiling ZFS v$ZFS_V, this can take some time, please wait!---"
		cd ${DATA_DIR}/zfs-v${ZFS_V}
		${DATA_DIR}/zfs-v${ZFS_V}/configure --prefix=${DATA_DIR}/bzroot-extracted-$UNAME/usr
		make -j${CPU_COUNT}
		make install
	elif [ "${ZFS_V}" == "master" ]; then
		echo "---ZFS will be builded from latest OpenZFS branch on Github---"
		cd ${DATA_DIR}
		git clone https://github.com/openzfs/zfs
		cd ${DATA_DIR}/zfs
		git checkout master
		${DATA_DIR}/zfs/autogen.sh
		${DATA_DIR}/zfs/configure --prefix=${DATA_DIR}/bzroot-extracted-$UNAME/usr
		make -j${CPU_COUNT}
		make install
	else
		echo "---ZFS manually set to v${ZFS_V}---"
		cd ${DATA_DIR}
		if [ ! -d ${DATA_DIR}/zfs-v${ZFS_V} ]; then
			mkdir ${DATA_DIR}/zfs-v${ZFS_V}
		fi
		if [ ! -f ${DATA_DIR}/zfs-v${ZFS_V}.tar.gz ]; then
			echo "---Downloading ZFS v${ZFS_V}, please wait!---"
			if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/zfs-v${ZFS_V}.tar.gz https://github.com/openzfs/zfs/releases/download/zfs-${ZFS_V}/zfs-${ZFS_V}.tar.gz ; then
				echo "---Successfully downloaded ZFS v${ZFS_V}---"
			else
				echo "---Download of ZFS v${ZFS_V} failed, putting container into sleep mode!---"
				sleep infinity
			fi
		else
			echo "---ZFS v${ZFS_V} found locally---"
		fi
		tar -C ${DATA_DIR}/zfs-v${ZFS_V} --strip-components=1 -xf ${DATA_DIR}/zfs-v${ZFS_V}.tar.gz
		echo "---Compiling ZFS v$ZFS_V, this can take some time, please wait!---"
		cd ${DATA_DIR}/zfs-v${ZFS_V}
		${DATA_DIR}/zfs-v${ZFS_V}/configure --prefix=${DATA_DIR}/bzroot-extracted-$UNAME/usr
		make -j${CPU_COUNT}
		make install
	fi
	## Load Kernel Module and patch files to load all existing ZFS Pools and Kernel Modules
	echo '
# Load ZFS Kernel Module
/sbin/modprobe zfs' >> ${DATA_DIR}/bzroot-extracted-$UNAME/etc/rc.d/rc.modules.local
	echo "
# Import all existing ZFS Pools on Array start
echo 'Importing all ZFS Pools in background'
zpool import -a &" >> ${DATA_DIR}/bzroot-extracted-$UNAME/usr/local/emhttp/plugins/dynamix/event/disks_mounted/local_syslog_start
	echo "
# Export all existing ZFS Pools on Array stop
echo 'Exporting all ZFS Pools in background'
zpool export -a &" >> ${DATA_DIR}/bzroot-extracted-$UNAME/usr/local/emhttp/plugins/dynamix/event/unmounting_disks/local_syslog_stop
fi

if [ "${BUILD_ISCSI}" == "true" ]; then
	## Install custom Python build v3.8.5
	if [ ! -f /bin/du ]; then
		cp ${DATA_DIR}/bzroot-extracted-$UNAME/bin/du /bin/
	fi
	echo "---Installing Python v3.8.5---"
	${DATA_DIR}/bzroot-extracted-$UNAME/sbin/installpkg --root ${DATA_DIR}/bzroot-extracted-$UNAME /tmp/python-3.8.5-x86_64-1.tgz

	## Install required libraries 'gobject-introspection'
	if [ ! -f /bin/du ]; then
		cp ${DATA_DIR}/bzroot-extracted-$UNAME/bin/du /bin/
	fi
	echo "---Installing 'gobject-introspection'---"
	${DATA_DIR}/bzroot-extracted-$UNAME/sbin/installpkg --root ${DATA_DIR}/bzroot-extracted-$UNAME /tmp/gobject-introspection-1.46.0-x86_64-1.txz

	## Download, compile and install 'targetcli-fb', 'trslib-fb' & 'configshell-fb'
	export PYTHONUSERBASE=${DATA_DIR}/bzroot-extracted-$UNAME/usr

	cd ${DATA_DIR}
	if [ ! -d ${DATA_DIR}/targetcli-fb-v${TARGETCLI_FB_V} ]; then
		mkdir ${DATA_DIR}/targetcli-fb-v${TARGETCLI_FB_V}
	fi
	if [ ! -f ${DATA_DIR}/targetcli-fb-v${TARGETCLI_FB_V}.tar.gz ]; then
		echo "---Downloading 'targetcli-fb' v${TARGETCLI_FB_V}, please wait!---"
		if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/targetcli-fb-v${TARGETCLI_FB_V}.tar.gz https://github.com/open-iscsi/targetcli-fb/archive/v${TARGETCLI_FB_V}.tar.gz ; then
			echo "---Successfully downloaded 'targetcli-fb' v${TARGETCLI_FB_V}---"
		else
			echo "---Download of 'targetcli-fb' v${TARGETCLI_FB_V} failed, putting container into sleep mode!---"
			sleep infinity
		fi
	else
		echo "---'targetcli-fb' v${TARGETCLI_FB_V} found locally---"
	fi
	tar -C ${DATA_DIR}/targetcli-fb-v${TARGETCLI_FB_V} --strip-components=1 -xf ${DATA_DIR}/targetcli-fb-v${TARGETCLI_FB_V}.tar.gz
	cd ${DATA_DIR}/targetcli-fb-v${TARGETCLI_FB_V}
	python3 setup.py build
	python3 setup.py install --user

	cd ${DATA_DIR}
	if [ ! -d ${DATA_DIR}/rtslib-fb-v${RTSLIB_FB_V} ]; then
		mkdir ${DATA_DIR}/rtslib-fb-v${RTSLIB_FB_V}
	fi
	if [ ! -f ${DATA_DIR}/rtslib-fb-v${RTSLIB_FB_V}.tar.gz ]; then
		echo "---Downloading 'rtslib-fb' v${RTSLIB_FB_V}, please wait!---"
		if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/rtslib-fb-v${RTSLIB_FB_V}.tar.gz https://github.com/open-iscsi/rtslib-fb/archive/v${RTSLIB_FB_V}.tar.gz ; then
			echo "---Successfully downloaded 'rtslib-fb' v${RTSLIB_FB_V}---"
		else
			echo "---Download of 'rtslib-fb' v${RTSLIB_FB_V} failed, putting container into sleep mode!---"
			sleep infinity
		fi
	else
		echo "---'rtslib-fb' v${RTSLIB_FB_V} found locally---"
	fi
	tar -C ${DATA_DIR}/rtslib-fb-v${RTSLIB_FB_V} --strip-components=1 -xf ${DATA_DIR}/rtslib-fb-v${RTSLIB_FB_V}.tar.gz
	cd ${DATA_DIR}/rtslib-fb-v${RTSLIB_FB_V}
	python3 setup.py build
	python3 setup.py install --user

	cd ${DATA_DIR}
	if [ ! -d ${DATA_DIR}/configshell-fb-v${CONFIGSHELL_FB_V} ]; then
		mkdir ${DATA_DIR}/configshell-fb-v${CONFIGSHELL_FB_V}
	fi
	if [ ! -f ${DATA_DIR}/configshell-fb-v${CONFIGSHELL_FB_V}.tar.gz ]; then
		echo "---Downloading 'configshell-fb' v${CONFIGSHELL_FB_V}, please wait!---"
		if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/configshell-fb-v${CONFIGSHELL_FB_V}.tar.gz https://github.com/open-iscsi/configshell-fb/archive/v${CONFIGSHELL_FB_V}.tar.gz ; then
			echo "---Successfully downloaded 'configshell-fb' v${CONFIGSHELL_FB_V}---"
		else
			echo "---Download of 'configshell-fb' v${CONFIGSHELL_FB_V} failed, putting container into sleep mode!---"
			sleep infinity
		fi
	else
		echo "---'configshell-fb' v${CONFIGSHELL_FB_V} found locally---"
	fi
	tar -C ${DATA_DIR}/configshell-fb-v${CONFIGSHELL_FB_V} --strip-components=1 -xf ${DATA_DIR}/configshell-fb-v${CONFIGSHELL_FB_V}.tar.gz
	cd ${DATA_DIR}/configshell-fb-v${CONFIGSHELL_FB_V}
	python3 setup.py build
	python3 setup.py install --user

	## Create config directory in bzroot image
	mkdir -p ${DATA_DIR}/bzroot-extracted-$UNAME/etc/target

	## Create .targetcli directory in /root/.targetcli in bzroot image
	mkdir -p ${DATA_DIR}/bzroot-extracted-$UNAME/root/.targetcli

	## Create iscsi & .targetcli directory at boot on Boot Device if does not exist and link it to /root/.targetcli/prefs.bin
	echo '
# Create iscsi & .targetcli directory at boot on Boot Device if does not exist and link it to /root/.targetcli/prefs.bin
if [ ! -d /boot/config/iscsi/.targetcli ]; then
  mkdir -p /boot/config/iscsi/.targetcli
fi
ln -s /boot/config/iscsi/saveconfig.json /etc/target/saveconfig.json
ln -s /boot/config/iscsi/.targetcli/prefs.bin /root/.targetcli/prefs.bin' >> ${DATA_DIR}/bzroot-extracted-$UNAME/etc/rc.d/rc.S

	## Load/unload iSCSI configuration on array start/stop
	echo "
# Load iSCSI configuration
echo 'Loading iSCSI configuration'
targetcli restoreconfig &" >> ${DATA_DIR}/bzroot-extracted-$UNAME/usr/local/emhttp/plugins/dynamix/event/disks_mounted/local_syslog_start
	echo "
# Unload iSCSI configuration
echo 'Unloading iSCSI configuration'
targetcli clearconfig confirm=True &" >> ${DATA_DIR}/bzroot-extracted-$UNAME/usr/local/emhttp/plugins/dynamix/event/unmounting_disks/local_syslog_stop
fi

if [ "${BUILD_MLX_MFT}" == "true" ]; then
	cd ${DATA_DIR}
	if [ ! -d ${DATA_DIR}/mlx-v${MLX_MFT_V} ]; then
		mkdir ${DATA_DIR}/mlx-v${MLX_MFT_V}
	fi
	if [ ! -f ${DATA_DIR}/mlx-v${MLX_MFT_V}.tar.gz ]; then
		echo "---Downloading Mellanox Firmware Tools v${MLX_MFT_V}, please wait!---"
		if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/mlx-v${MLX_MFT_V}.tar.gz https://github.com/Mellanox/mstflint/releases/download/v${MLX_MFT_V}/mstflint-${MLX_MFT_V}.tar.gz ; then
			echo "---Successfully downloaded Mellanox Firmware Tools v${MLX_MFT_V}---"
		else
			echo "---Download of Mellanox Firmware Tools v${MLX_MFT_V} failed, putting container into sleep mode!---"
			sleep infinity
		fi
	else
		echo "---Mellanox Firmware Tools v${MLX_MFT_V} found locally---"
	fi
	tar -C ${DATA_DIR}/mlx-v${MLX_MFT_V} --strip-components=1 -xf ${DATA_DIR}/mlx-v${MLX_MFT_V}.tar.gz
	echo "---Compiling Mellanox Firmware Tools v${MLX_MFT_V}, this can take some time, please wait!---"
	cd ${DATA_DIR}/mlx-v${MLX_MFT_V}
	${DATA_DIR}/mlx-v${MLX_MFT_V}/configure --enable-openssl --prefix=/usr
	make -j${CPU_COUNT}
	DESTDIR=${DATA_DIR}/bzroot-extracted-$UNAME make install

	# Download 'mget_temp' and copy all files to destination directory
	echo "---Downloading 'mget_temp'---"
	cd ${DATA_DIR}
	if [ ! -f ${DATA_DIR}/mlx_temp.zip ]; then
		if wget -q -nc --show-progress --progress=bar:force:noscroll https://github.com/ich777/docker-unraid-kernel-helper/raw/6.9.0/mlx_temp.zip ; then
			echo "---Successfully downloaded 'mget_temp'---"
		else
			echo "---Download of 'mget_temp' failed, if you are using the Unraid-Kernel-Helper Plugin the temperature reading will not work!---"
			sleep 10
		fi
	else
		echo "---'mget_temp' found locally---"
	fi
	unzip ${DATA_DIR}/mlx_temp.zip -d ${DATA_DIR}/bzroot-extracted-$UNAME/usr/bin
fi

if [ "${ENABLE_i915}" == "true" ]; then
	echo "---Load Kernel Module i915 on Startup enabled---"
	echo '
# Load i915 Kernel Module
/sbin/modprobe i915
sleep 5
chmod -R 777 /dev/dri' >> ${DATA_DIR}/bzroot-extracted-$UNAME/etc/rc.d/rc.modules.local
fi

if [ "${BUILD_NVIDIA}" == "true" ]; then
	if [ "${NV_DRV_V}" == "440.82" ]; then
		echo "---Installing and applying nVidia driver patch v440.82---"
		cd ${DATA_DIR}
		if [ ! -f ${DATA_DIR}/NVIDIA_v${NV_DRV_V}.run ]; then
			echo "---Downloading nVidia driver v${NV_DRV_V}, please wait!---"
			if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/NVIDIA_v${NV_DRV_V}.run http://download.nvidia.com/XFree86/Linux-x86_64/${NV_DRV_V}/NVIDIA-Linux-x86_64-${NV_DRV_V}.run ; then
				echo "---Successfully downloaded nVidia driver v${NV_DRV_V}---"
			else
				echo "---Download of nVidia driver v${NV_DRV_V} failed, putting container into sleep mode!---"
				sleep infinity
			fi
		else
			echo "---nVidia driver v${NV_DRV_V} found locally---"
		fi
		chmod +x ${DATA_DIR}/NVIDIA_v${NV_DRV_V}.run
		wget -nc -O kernel-5.7.patch https://gitlab.com/snippets/1965550/raw
		${DATA_DIR}/NVIDIA_v440.82.run -x
		cd ${DATA_DIR}/NVIDIA-Linux-x86_64-440.82
		patch -p1 -i ../kernel-5.7.patch
		${DATA_DIR}/NVIDIA_v${NV_DRV_V}.run --kernel-name=$UNAME \
		--no-precompiled-interface \
		--disable-nouveau \
		--x-library-path=${DATA_DIR}/bzroot-extracted-$UNAME/usr \
		--x-module-path=${DATA_DIR}/bzroot-extracted-$UNAME/usr \
		--opengl-prefix=${DATA_DIR}/bzroot-extracted-$UNAME/usr \
		--installer-prefix=${DATA_DIR}/bzroot-extracted-$UNAME/usr \
		--utility-prefix=${DATA_DIR}/bzroot-extracted-$UNAME/usr \
		--documentation-prefix=${DATA_DIR}/bzroot-extracted-$UNAME/usr \
		--application-profile-path=${DATA_DIR}/bzroot-extracted-$UNAME/usr/share \
		--proc-mount-point=${DATA_DIR}/bzroot-extracted-$UNAME/proc \
		--compat32-libdir=${DATA_DIR}/bzroot-extracted-$UNAME/usr/lib \
		--no-x-check \
		--j${CPU_COUNT} \
		--silent
	else
		## Nvidia Drivers & Kernel module installation
		cd ${DATA_DIR}
		if [ ! -f ${DATA_DIR}/NVIDIA_v${NV_DRV_V}.run ]; then
			echo "---Downloading nVidia driver v${NV_DRV_V}, please wait!---"
			if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/NVIDIA_v${NV_DRV_V}.run http://download.nvidia.com/XFree86/Linux-x86_64/${NV_DRV_V}/NVIDIA-Linux-x86_64-${NV_DRV_V}.run ; then
				echo "---Successfully downloaded nVidia driver v${NV_DRV_V}---"
			else
				echo "---Download of nVidia driver v${NV_DRV_V} failed, putting container into sleep mode!---"
				sleep infinity
			fi
		else
			echo "---nVidia driver v${NV_DRV_V} found locally---"
		fi
		chmod +x ${DATA_DIR}/NVIDIA_v${NV_DRV_V}.run
		echo "---Installing nVidia Driver and Kernel Module v${NV_DRV_V}, please wait!---"
		${DATA_DIR}/NVIDIA_v${NV_DRV_V}.run --kernel-name=$UNAME \
		--no-precompiled-interface \
		--disable-nouveau \
		--x-library-path=${DATA_DIR}/bzroot-extracted-$UNAME/usr \
		--x-module-path=${DATA_DIR}/bzroot-extracted-$UNAME/usr \
		--opengl-prefix=${DATA_DIR}/bzroot-extracted-$UNAME/usr \
		--installer-prefix=${DATA_DIR}/bzroot-extracted-$UNAME/usr \
		--utility-prefix=${DATA_DIR}/bzroot-extracted-$UNAME/usr \
		--documentation-prefix=${DATA_DIR}/bzroot-extracted-$UNAME/usr \
		--application-profile-path=${DATA_DIR}/bzroot-extracted-$UNAME/usr/share \
		--proc-mount-point=${DATA_DIR}/bzroot-extracted-$UNAME/proc \
		--compat32-libdir=${DATA_DIR}/bzroot-extracted-$UNAME/usr/lib \
		--no-x-check \
		--j${CPU_COUNT} \
		--silent
	fi

	## Copying 'nvidia-modprobe' and OpenCL icd
	cp /usr/bin/nvidia-modprobe ${DATA_DIR}/bzroot-extracted-$UNAME/usr/bin/
	cp -R /etc/OpenCL ${DATA_DIR}/bzroot-extracted-$UNAME/etc/

	if [ "$BUILD_FROM_SOURCE" == "true" ]; then
		## Compile 'libnvidia-container'
		echo "---Compiling 'libnvidia-container', this can take some time, please wait!---"
		cd ${DATA_DIR}
		git clone https://github.com/NVIDIA/libnvidia-container.git
		cd ${DATA_DIR}/libnvidia-container
		git checkout v$LIBNVIDIA_CONTAINER_V
		sed -i '/if (syscall(SYS_pivot_root, ".", ".") < 0)/,+1 d' ${DATA_DIR}/libnvidia-container/src/nvc_ldcache.c
		sed -i '/if (umount2(".", MNT_DETACH) < 0)/,+1 d' ${DATA_DIR}/libnvidia-container/src/nvc_ldcache.c
		until DESTDIR=${DATA_DIR}/bzroot-extracted-$UNAME make install prefix=/usr; do
			echo Something went wrong, retrying in 5 seconds...
			sleep 5
		done

		## Create Docker daemon config file
		mkdir -p ${DATA_DIR}/bzroot-extracted-$UNAME/etc/docker
		tee ${DATA_DIR}/bzroot-extracted-$UNAME/etc/docker/daemon.json <<EOF
{
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
EOF

		## Select build process for 'nvidia-container-runtime' & 'nvidia-container-toolkit'
		if [ "${NVIDIA_CONTAINER_RUNTIME_V//./}" -le "314" ]; then
			## Compile 'nvidia-container-toolkit' v3.1.4 and lower
			echo "---Compiling 'nvidia-container-toolkit', this can take some time, please wait!---"
			mkdir -p ${DATA_DIR}/go/src/github.com/NVIDIA
			cd ${DATA_DIR}/go/src/github.com/NVIDIA
			git clone https://github.com/NVIDIA/nvidia-container-runtime.git
			cd ${DATA_DIR}/go/src/github.com/NVIDIA/nvidia-container-runtime
			git checkout v$NVIDIA_CONTAINER_RUNTIME_V
			go build -ldflags "-s -w" -v github.com/NVIDIA/nvidia-container-runtime/toolkit/nvidia-container-toolkit
			cp ${DATA_DIR}/go/src/github.com/NVIDIA/nvidia-container-runtime/nvidia-container-toolkit ${DATA_DIR}/bzroot-extracted-$UNAME/usr/bin
			cd ${DATA_DIR}/bzroot-extracted-$UNAME/usr/bin
			ln -s /usr/bin/nvidia-container-toolkit nvidia-container-runtime-hook
			mkdir -p ${DATA_DIR}/bzroot-extracted-$UNAME/etc/nvidia-container-runtime
			cp ${DATA_DIR}/go/src/github.com/NVIDIA/nvidia-container-runtime/toolkit/config.toml.debian ${DATA_DIR}/bzroot-extracted-$UNAME/etc/nvidia-container-runtime/config.toml
			sed -i '/#path/c\path = "/usr/bin/nvidia-container-cli"' ${DATA_DIR}/bzroot-extracted-$UNAME/etc/nvidia-container-runtime/config.toml
			sed -i '/#ldcache/c\ldcache = "/etc/ld.so.cache"' ${DATA_DIR}/bzroot-extracted-$UNAME/etc/nvidia-container-runtime/config.toml

			### Compile 'nvidia-container-runtime' v3.1.4 and lower
			echo "---Compiling 'nvidia-container-runtime', this can take some time, please wait!---"
			cd ${DATA_DIR}/go/src/github.com/NVIDIA/nvidia-container-runtime/runtime/src
			until make; do
				echo Something went wrong, retrying in 5 seconds...
				sleep 5
			done
			cp ${DATA_DIR}/go/src/github.com/NVIDIA/nvidia-container-runtime/runtime/src/nvidia-container-runtime ${DATA_DIR}/bzroot-extracted-$UNAME/usr/bin
		else
			### Compile 'nvidia-container-runtime' v3.2.0 and up
			echo "---Compiling 'nvidia-container-runtime', this can take some time, please wait!---"
			mkdir -p ${DATA_DIR}/go/src/github.com/NVIDIA
			cd ${DATA_DIR}/go/src/github.com/NVIDIA
			git clone https://github.com/NVIDIA/nvidia-container-runtime.git
			cd ${DATA_DIR}/go/src/github.com/NVIDIA/nvidia-container-runtime
			git checkout v$NVIDIA_CONTAINER_RUNTIME_V
			cd ${DATA_DIR}/go/src/github.com/NVIDIA/nvidia-container-runtime/src
			until make build; do
				echo Something went wrong, retrying in 5 seconds...
				sleep 5
			done
			cp ${DATA_DIR}/go/src/github.com/NVIDIA/nvidia-container-runtime/src/nvidia-container-runtime ${DATA_DIR}/bzroot-extracted-$UNAME/usr/bin

			### Compile 'nvidia-container-toolkit' v3.2.0 and up
			echo "---Compiling 'container-toolkit', this can take some time, please wait!---"
			cd ${DATA_DIR}/go/src/github.com/NVIDIA
			git clone https://github.com/NVIDIA/nvidia-container-toolkit
			cd ${DATA_DIR}/go/src/github.com/NVIDIA/nvidia-container-toolkit
			git checkout v$CONTAINER_TOOLKIT_V
			until make binary; do
				echo Something went wrong, retrying in 5 seconds...
				sleep 5
			done
			cp ${DATA_DIR}/go/src/github.com/NVIDIA/nvidia-container-toolkit/nvidia-container-toolkit ${DATA_DIR}/bzroot-extracted-$UNAME/usr/bin
			cd ${DATA_DIR}/bzroot-extracted-$UNAME/usr/bin
			ln -s /usr/bin/nvidia-container-toolkit nvidia-container-runtime-hook
			mkdir -p ${DATA_DIR}/bzroot-extracted-$UNAME/etc/nvidia-container-runtime
			cp ${DATA_DIR}/go/src/github.com/NVIDIA/nvidia-container-toolkit/config/config.toml.debian ${DATA_DIR}/bzroot-extracted-$UNAME/etc/nvidia-container-runtime/config.toml
			sed -i '/#path/c\path = "/usr/bin/nvidia-container-cli"' ${DATA_DIR}/bzroot-extracted-$UNAME/etc/nvidia-container-runtime/config.toml
			sed -i '/#ldcache/c\ldcache = "/etc/ld.so.cache"' ${DATA_DIR}/bzroot-extracted-$UNAME/etc/nvidia-container-runtime/config.toml
		fi
	else
		## Downloading prebuilt 'libnvidia-container'
		echo "---Downloading prebuilt 'libnvidia-container', please wait!---"
		cd ${DATA_DIR}
		if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/libnvidia-container-v${LIBNVIDIA_CONTAINER_V}.tar.gz https://github.com/ich777/libnvidia-container/releases/download/${LIBNVIDIA_CONTAINER_V}/libnvidia-container-v${LIBNVIDIA_CONTAINER_V}.tar.gz ; then
			echo "---Successfully downloaded 'libnvidia-container' v${LIBNVIDIA_CONTAINER_V}---"
		else
			echo "---Download of 'libnvidia-container' v${LIBNVIDIA_CONTAINER_V} failed, putting container into sleep mode!---"
			sleep infinity
		fi
		tar -C ${DATA_DIR}/bzroot-extracted-$UNAME -xf ${DATA_DIR}/libnvidia-container-v${LIBNVIDIA_CONTAINER_V}.tar.gz

		## Downloading prebuilt 'nvidia-container-runtime'
		echo "---Downloading prebuilt 'nvidia-container-runtime', please wait!---"
		cd ${DATA_DIR}
		if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/nvidia-container-runtime-v${NVIDIA_CONTAINER_RUNTIME_V}.tar.gz https://github.com/ich777/nvidia-container-runtime/releases/download/${NVIDIA_CONTAINER_RUNTIME_V}/nvidia-container-runtime-v${NVIDIA_CONTAINER_RUNTIME_V}.tar.gz ; then
			echo "---Successfully downloaded 'nvidia-container-runtime' v${NVIDIA_CONTAINER_RUNTIME_V}---"
		else
			echo "---Download of 'nvidia-container-runtime' v${NVIDIA_CONTAINER_RUNTIME_V} failed, putting container into sleep mode!---"
			sleep infinity
		fi
		tar -C ${DATA_DIR}/bzroot-extracted-$UNAME -xf ${DATA_DIR}/nvidia-container-runtime-v${NVIDIA_CONTAINER_RUNTIME_V}.tar.gz

		## Downloading prebuilt 'nvidia-container-toolkit'
		echo "---Downloading prebuilt 'nvidia-container-toolkit', please wait!---"
		cd ${DATA_DIR}
		if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/nvidia-container-toolkit-v${CONTAINER_TOOLKIT_V}.tar.gz https://github.com/ich777/nvidia-container-toolkit/releases/download/${CONTAINER_TOOLKIT_V}/nvidia-container-toolkit-v${CONTAINER_TOOLKIT_V}.tar.gz ; then
			echo "---Successfully downloaded 'nvidia-container-toolkit' v${CONTAINER_TOOLKIT_V}---"
		else
			echo "---Download of 'nvidia-container-toolkit' v${CONTAINER_TOOLKIT_V} failed, putting container into sleep mode!---"
			sleep infinity
		fi
		tar -C ${DATA_DIR}/bzroot-extracted-$UNAME -xf ${DATA_DIR}/nvidia-container-toolkit-v${CONTAINER_TOOLKIT_V}.tar.gz
	fi


	### Install Seccomp
	cd ${DATA_DIR}
	if [ ! -d ${DATA_DIR}/seccomp-v${SECCOMP_V} ]; then
		mkdir ${DATA_DIR}/seccomp-v${SECCOMP_V}
	fi
	if [ ! -f ${DATA_DIR}/seccomp-v${SECCOMP_V}.tar.gz ]; then
		echo "---Downloading Seccomp v${SECCOMP_V}, please wait!---"
		if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/seccomp-v${SECCOMP_V}.tar.gz https://github.com/seccomp/libseccomp/releases/download/v$SECCOMP_V/libseccomp-${SECCOMP_V}.tar.gz ; then
			echo "---Successfully downloaded Seccomp v${SECCOMP_V}---"
		else
			echo "---Download of Seccomp v${SECCOMP_V} failed, putting container into sleep mode!---"
			sleep infinity
		fi
	else
		echo "---Seccomp found locally---"
	fi
	tar -C ${DATA_DIR}/seccomp-v${SECCOMP_V} --strip-components=1 -xf ${DATA_DIR}/seccomp-v${SECCOMP_V}.tar.gz
	cd ${DATA_DIR}/seccomp-v${SECCOMP_V}
	${DATA_DIR}/seccomp-v${SECCOMP_V}/configure --prefix=/usr --disable-static
	make -j${CPU_COUNT}
	DESTDIR=${DATA_DIR}/bzroot-extracted-$UNAME make install
fi

## add vendor reset patch
echo "---Doing an incredibly hacky vendor reset patch---"
cd ${DATA_DIR}
git clone git://github.com/gnif/vendor-reset
cd vendor-reset
make
make install

## Create bzmodules
echo "---Generating bzmodules in output folder---"
mksquashfs /lib/modules/$UNAME/ ${DATA_DIR}/output-$UNAME/bzmodules -keep-as-directory -noappend

## Create bzfirmware
#echo "---Generating bzfirmware in output folder---"
mksquashfs /lib/firmware ${DATA_DIR}/output-$UNAME/bzfirmware -noappend

## Compress bzroot image
echo "---Creating 'bzroot', this can take some time, please wait!---"
cd ${DATA_DIR}/bzroot-extracted-$UNAME
find . | cpio -o -H newc | xz --check=crc32 --ia64 --lzma2=preset=9e --threads=${CPU_COUNT} >> ${DATA_DIR}/output-$UNAME/bzroot.part
cat ${DATA_DIR}/output-$UNAME/microcode ${DATA_DIR}/output-$UNAME/bzroot.part > ${DATA_DIR}/output-$UNAME/bzroot
rm ${DATA_DIR}/output-$UNAME/microcode
rm ${DATA_DIR}/output-$UNAME/bzroot.part

## Generate checksums
echo "---Generationg checksums---"
if [ -f ${DATA_DIR}/output-$UNAME/bzimage ]; then
	sha256sum ${DATA_DIR}/output-$UNAME/bzimage > ${DATA_DIR}/output-$UNAME/bzimage.sha256
fi
if [ -f ${DATA_DIR}/output-$UNAME/bzmodules ]; then
	sha256sum ${DATA_DIR}/output-$UNAME/bzmodules > ${DATA_DIR}/output-$UNAME/bzmodules.sha256
fi
if [ -f ${DATA_DIR}/output-$UNAME/bzfirmware ]; then
	sha256sum ${DATA_DIR}/output-$UNAME/bzfirmware > ${DATA_DIR}/output-$UNAME/bzfirmware.sha256
fi
if [ -f ${DATA_DIR}/output-$UNAME/bzroot ]; then
	sha256sum ${DATA_DIR}/output-$UNAME/bzroot > ${DATA_DIR}/output-$UNAME/bzroot.sha256
fi

## Make backup of Stock Beta files if Beta build is enabled
if [ "${BETA_BUILD}" == "true" ]; then
	echo "---Generating zip file of Stock Beta image files---"
	cd ${DATA_DIR}/stock/beta
	if [ -f ${DATA_DIR}/stock_beta_images.zip ]; then
		echo "---Found file 'stock_beta_images.zip', removing and creating new---"
		rm ${DATA_DIR}/stock_beta_images.zip
	fi
	zip -D ${DATA_DIR}/stock_beta_images.zip bzimage bzroot bzmodules bzfirmware
fi

## Cleanup
if [ "$CLEANUP" == "full" ]; then
	echo "---Cleaning up, only output folder will be not deleted---"
	cd ${DATA_DIR}
	find . -maxdepth 1 -not -name 'output*' -print0 | xargs -0 -I {} rm -R {} 2&>/dev/null
	rm /etc/modprobe.d/nvidia-installer-disable-nouveau.conf
	rm /usr/du
	rm -R /lib/modules
	rm -R /lib/firmware
elif [ "$CLEANUP" == "moderate" ]; then
	echo "---Cleaning up, downloads are not deleted---"
	cd ${DATA_DIR}
	find . -maxdepth 1 -type d -not -name 'output*' -print0 | xargs -0 -I {} rm -R {} 2&>/dev/null
	rm /etc/modprobe.d/nvidia-installer-disable-nouveau.conf
	rm /usr/du
	rm -R /lib/modules
	rm -R /lib/firmware
else
	echo "---Nothing to clean, no cleanup selected---"
	rm /etc/modprobe.d/nvidia-installer-disable-nouveau.conf
	rm /usr/du
	rm -R /lib/modules
	rm -R /lib/firmware
fi

## Creating backup from now installed images if selected
if [ "$CREATE_BACKUP" == "true" ]; then
	if [ ! -d ${DATA_DIR}/backup-$UNAME ]; then
		mkdir ${DATA_DIR}/backup-$UNAME
	fi
	echo "---Creating backup of now installed image files to backup folder, please wait!---"
	cp /host/boot/bzimage ${DATA_DIR}/backup-$UNAME/bzimage
	cp /host/boot/bzmodules ${DATA_DIR}/backup-$UNAME/bzmodules
	cp /host/boot/bzfirmware ${DATA_DIR}/backup-$UNAME/bzfirmware
	cp /host/boot/bzroot ${DATA_DIR}/backup-$UNAME/bzroot
	cp /host/boot/bzroot-gui ${DATA_DIR}/backup-$UNAME/bzroot-gui
	cp /host/boot/*.sha256 ${DATA_DIR}/backup-$UNAME/
else
	echo "---No backup creation selected, please be sure to backup your images!---"
fi

## Fixing permissions
echo "---Fixing permissions, please wait---"
chown -R ${UID}:${GID} ${DATA_DIR}
chmod -R ${DATA_PERM} ${DATA_DIR}

## End message
echo
echo
echo
echo "-----------------------------------------------"
echo "-----The built images are located in your------"
echo "----output folder: 'output-$UNAME'----"
echo "-----------------------------------------------"
if [ "${CUSTOM_MODE}" == "true" ]; then
	echo "-----The images were built with CUSTOM_MODE----"
	echo "-------------------enabled!--------------------"
else
	echo "---The images were built with the following----"
	echo "------build options and version numbers:-------"
	if [ "${ENABLE_i915}" == "true" ]; then
		echo "----Load Kernel Module i915 on boot enabled----"
	fi
	if [ "${BUILD_NVIDIA}" == "true" ]; then
		echo "--------nVidia driver version: $NV_DRV_V----------"
		echo "------lib-nvidia-container version: $LIBNVIDIA_CONTAINER_V------"
		echo "----nvidia-container-runtime version: $NVIDIA_CONTAINER_RUNTIME_V----"
		if [ "${NVIDIA_CONTAINER_RUNTIME_V//./}" -ge "320" ]; then
			echo "--------container-toolkit version: $CONTAINER_TOOLKIT_V-------"
		fi
		echo "------------Seccomp version: $SECCOMP_V-------------"
	fi
	if [ "${BUILD_DVB}" == "true" ]; then
		if [ "${DVB_TYPE}" == "digitaldevices" ]; then
			echo "-----DigitalDevices driver version: $DD_DRV_V-----"
		elif [ "${DVB_TYPE}" == "libreelec" ]; then
			echo "--------LibreELEC driver version: $LE_DRV_V--------"
		elif [ "${DVB_TYPE}" == "xboxoneusb" ]; then
			echo "------Xbox One Digital TV Tuner firwmare-------"
		elif [ "${DVB_TYPE}" == "tbsos" ]; then
			echo "-----------TBS Open Source drivers-------------"
		fi
	fi
	if [ "${BUILD_ZFS}" == "true" ]; then
		if [ "${ZFS_V}" == "latest" ]; then
			echo "-------------ZFS version: $ZFS_V----------------"
		elif [ "${ZFS_V}" == "master" ]; then
			echo "---ZFS builded from latest OpenZFS branch on---"
			echo "--------Github. Build date: $(date +'%Y-%m-%d')---------"
		fi
	fi

	if [ "${BUILD_ISCSI}" == "true" ]; then
		echo "----iSCSI is built with the follwing versions:----"
		echo "------------------Python v3.8.5-------------------"
		echo "-----------GObject-Introspection v1.46.0----------"
		echo "-------------'targetcli-fb' v${TARGETCLI_FB_V}--------------"
		echo "--------------'trslib-fb' v${RTSLIB_FB_V}----------------"
		echo "------------'configshell-fb' v${CONFIGSHELL_FB_V}-------------"
	fi
	if [ "${BUILD_MLX_MFT}" == "true" ]; then
		echo "-------Mellanox Firmware Tools version:--------"
		echo "-------------------$MLX_MFT_V--------------------"
	fi
fi
echo "-----------------------------------------------"
echo
echo
echo
echo
echo "-----------------------------------------------"
echo "----------------A L L   D O N E----------------"
echo "---Please copy the generated files from the----"
echo "----output folder to your Unraid USB Stick-----"
echo "-----------------------------------------------"
echo "----MAKE SURE TO BACKUP YOUR OLD FILES FROM----"
echo "----YOUR UNRAID USB STICK IN CASE SOMETHING----"
echo "------WENT WRONG WITH THE KERNEL COMPILING-----"
echo "-----------------------------------------------"
if [ "${BEEP}" == "true" ]; then
	beep -f 933 -l 300 -n -f 933 -l 100 -n -f 933 -l 100 -n -f 933 -l 100 -n -f 1047 -l 400
fi
