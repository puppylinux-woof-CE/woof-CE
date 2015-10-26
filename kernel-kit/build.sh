#!/bin/bash
# originally by Iguleder
# hacked to DEATH by 01micko
# see /usr/share/doc/legal NO WARRANTY, NO resposibility accepted

CWD=`pwd`

if [ "$1" = "clean" ];then
	echo -en "\033[1;35m""WARNING" #purple?
	echo -en "\033[0m" #reset
	echo ": This will delete all builds and sources but wont touch configs."
	echo "Hit CTRL+C and save your stuff manually if you don't want to clean."
	echo "Hit ENTER to clean"
	read clean
	echo "Please wait..."
	rm -rf ./{dist,aufs*,kernel*,build.log*,linux-*}
	echo "Cleaning complete"
	exit 0
fi

if [ -d ./dist ];then
	echo "This is not a clean kit. Hit ENTER to continue"
	echo "or CTRL+C to quit and run './build.sh clean'"
	read notcleango
fi

# read config
[ -f ./build.conf ] && . ./build.conf

FW_URL=${FW_URL:-http://distro.ibiblio.org/puppylinux/firmware}
package_name_suffix=$package_name_suffix
custom_suffix=$custom_suffix
kernel_version=$kernel_version
kernel_mirror=$kernel_mirror

# depcheck
echo "Dependency check..."
if git --version &>/dev/null
	then echo -e "\033[1;32m""git is installed" #green 
else echo -e "\033[1;31m""git is not installed""\033[0m" && exit #red
fi
if gcc --version &>/dev/null
	then echo -e "\033[1;32m""gcc is installed" 
else
   echo -e "\033[1;31m""gcc is not installed""\033[0m" && exit
fi
MKSQ="$(which mksquashfs)"
if [ "$MKSQ" ]
	then 
   echo -e "\033[1;32m""mksquashfs is installed"
else #yellow
   echo -e "\033[1;30m""mksquashfs is not installed but you can continue"
fi
echo -e "\033[0m" #reset to original

# .configs
[ -f /tmp/kernel_configs ] && rm -f /tmp/kernel_configs

CONFIGS=$(ls ./configs_extra)
# list
echo "Choose a number of the config you want to try"
NUM=1
for C in $CONFIGS
  do echo "${NUM}. $C" >> /tmp/kernel_configs
  NUM=$(($NUM + 1))
  done
echo "z. Custom DOTconfig" >> /tmp/kernel_configs
echo "d. Default DOTconfig" >> /tmp/kernel_configs  
cat /tmp/kernel_configs
echo -n "Enter choice: "
read Chosen
if [ ! $Chosen ];then 
	echo -e "\033[1;31m""ERROR: you didn't choose, start again!""\033[0m" \
	&& exit
else
    Choice=$(grep "^$Chosen\." /tmp/kernel_configs|cut -d ' ' -f2)
    [ ! $Choice ] && \
    echo -e "\033[1;31m""ERROR: your choice is not sane ..quiting""\033[0m" \
    && exit
    echo -e "You chose $Choice. If this is ok hit ENTER, \
    \nif not hit CTRL|C to quit" 
    read oknow
    if [ "$Choice" = "Default" -o "$Choice" = "Custom" ];then
    echo $Choice
    else
      cp -af configs_extra/$Choice DOTconfig
    fi
fi

[ ! -f DOTconfig ] && echo -e \
"\033[1;31m""ERROR: No DOTconfig found ..quiting""\033[0m" \
&& exit

# the aufs major version
#aufs_version=${kernel_version%.*.*} #
aufs_version=${kernel_version%%.*}

if [ "$FD" = "1" ];then
tail -n10 README
echo ""
sleep 4
x=0
	for i in CONFIG_AUFS_FS=y CONFIG_NLS_CODEPAGE_850=y;do
		if grep -q "$i" DOTconfig;then 
			echo "$i is ok"
		else
			echo -e "\033[1;31m""\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!   WARNING     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n""\033[0m"
			echo -e "\033[0m"
			echo
			if [ "$i" = "CONFIG_AUFS_FS=y" ];then
				echo "For your kernel to boot AUFS as a built in is required:"
				fs_msg="Pseudo filesystems"
			else
				echo "For NLS to work at boot some configs are required:"
				fs_msg="NLS Support"
			fi
			echo "$i"
	echo "$i"|grep -q "CONFIG_NLS_CODEPAGE_850=y" && echo "CONFIG_NLS_CODEPAGE_852=y"
	
	echo "Make sure you enable this when you are given the opportunity after
the kernel has downloaded and been patched.
Look under 'Filesystems > $fs_msg'
"		
			sleep 5
		fi
		[ $x -gt 0 ] && sleep 10
	#if grep -q CONFIG_NLS_CODEPAGE_850=m DOTconfig;then 
		#[ -z "$f" ] || sleep 10 #reading time in case the next one pops up
		#echo -e "\033[1;31m""\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!   WARNING     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n""\033[0m"
		#echo -e "\033[0m"
		#echo
		#echo "For NLS to work at boot some configs are required:
		
#CONFIG_NLS_CODEPAGE_850=y
#CONFIG_NLS_CODEPAGE_852=y

#Make sure you enable these when you are given the opportunity after
#the kernel has downloaded and been patched.
#Look under 'Filesystems > NLS Support'
#"
	#fi
	done
fi

# fail-safe switch in case someone clicks the script in ROX (real story! not 
# fun at all!!!!) :p
read -p "Press ENTER to begin" dummy

# get the major version (2.6.32 in the case of 2.6.32.40)
kernel_series=${kernel_version:0:1}
kernel_major_version=${kernel_version%.*}
kernel_minor_version=${kernel_version##*.}
# get the kernel branch (32 in the case of 2.6.32.40; needed to download Aufs)
kernel_branch=`echo $kernel_major_version | cut -f 2 -d .` #3.x kernels

# get the minor version (40 in the case of 2.6.32.40)
#case $kernel_version in
	#*.*.*.*) kernel_minor_version=`echo $kernel_version | cut -f 4 -d .` ;;
#esac

#create directories for the results
[ ! -d dist/sources/vanilla ] && mkdir -p dist/sources/{patches,vanilla}

# get today's date
today=`date +%d%m%y`

# delete the previous log
[ -f build.log ] && rm -f build.log
[ -f build.log.tar.bz2 ] && mv -f build.log.${today}.tar.bz2

# download the kernel
echo ${kernel_version##*-}|grep -q "rc"
[ "$?" -eq 0 ] && testing=testing||testing=
if [ ! -f dist/sources/vanilla/linux-$kernel_version.tar.* ]; then
	echo "Downloading the kernel sources"
	wget -P dist/sources/vanilla $kernel_mirror/$testing/linux-$kernel_version.tar.xz --no-check-certificate > build.log 2>&1
	if [ $? -ne 0 ]; then
		echo "Error: failed to download the kernel sources."
		exit 1
	fi
fi

# download Linux-libre scripts
if [ $LIBRE -eq 1 ]; then
	minor_version=${kernel_version##*.}
	for i in deblob-$kernel_major_version deblob-check; do
		if [ ! -f dist/sources/vanilla/$i ]; then
			wget -O dist/sources/vanilla/$i http://linux-libre.fsfla.org/pub/linux-libre/releases/LATEST-$kernel_major_version.N/$i
			if [ $? -ne 0 ]; then
				echo "Error: failed to download $i."
				exit 1
			fi
		fi
	done
fi

# download Aufs
if [ ! -f dist/sources/vanilla/aufs$aufs_version-$kernel_branch-git$today.tar.bz2 ]; then
	echo "Downloading the Aufs sources"
	git clone $aufs_git aufs$aufs_version-$kernel_branch-git$today >> build.log 2>&1
	if [ $? -ne 0 ]; then
		echo "Error: failed to download the Aufs sources."
		exit 1
	fi
	cd aufs$aufs_version-$kernel_branch-git$today
	if [ "$aufsv" ];then #new far for new kernels
	git checkout origin/aufs$aufsv >> ../build.log 2>&1
	else
	git checkout origin/aufs$aufs_version.$kernel_branch >> ../build.log 2>&1
	fi
	if [ $? -ne 0 ]; then
		echo "Error: failed to download the Aufs sources."
		exit 1
	fi
	rm -rf .git
	cd ..
	echo "Creating the Aufs sources tarball"
	tar -c aufs$aufs_version-$kernel_branch-git$today | bzip2 -9 > dist/sources/vanilla/aufs$aufs_version-$kernel_branch-git$today.tar.bz2
else
	echo "Extracting the Aufs sources"
	tar xf dist/sources/vanilla/aufs$aufs_version-$kernel_branch-git$today.tar.bz2 >> build.log 2>&1
	if [ $? -ne 0 ]; then
		echo "Error: failed to extract the Aufs sources."
		exit 1
	fi
fi

# patch Aufs
if [ -f aufs-allow-sfs.patch ];then #removed for K3.9 experiment
	echo "Patching the Aufs sources"
	patch -d aufs$aufs_version-$kernel_branch-git$today -p1 < aufs-allow-sfs.patch >> build.log 2>&1
	if [ $? -ne 0 ]; then
		echo "Error: failed to patch the Aufs sources."
		exit 1
	fi
	cp aufs-allow-sfs.patch dist/sources/patches
fi
if [ -f aufs-kconfig.patch ];then #special for K3.9
	echo "Patching the Aufs sources"
	patch -d aufs$aufs_version-$kernel_branch-git$today -p1 < aufs-kconfig.patch >> build.log 2>&1
	if [ $? -ne 0 ]; then
		echo "Error: failed to patch the Aufs sources for kconfig."
		exit 1
	fi
	cp aufs-kconfig.patch dist/sources/patches
fi

# extract the kernel
echo "Extracting the kernel sources"
tar xf dist/sources/vanilla/linux-$kernel_version.tar.* >> build.log 2>&1
if [ $? -ne 0 ]; then
	echo "Error: failed to extract the kernel sources."
	exit 1
fi

cd linux-$kernel_version

echo "Adding Aufs to the kernel sources"
if [ "$kernel_major_version" = "3.14" ] && [ "$kernel_minor_version" -ge 21 ];then
	# hack - Aufs adds this file in the mmap patch, but it's already in mainline
	rm -f mm/prfile.c
fi
for i in kbuild base standalone mmap; do
	patch -N -p1 < ../aufs$aufs_version-$kernel_branch-git$today/aufs$aufs_version-$i.patch >> ../build.log 2>&1
	if [ $? -ne 0 ]; then
		#echo "Error: failed to add Aufs to the kernel sources."
		#exit 1
		echo "WARNING: failed to add some Aufs patches to the kernel sources."
		echo "Check it manually and either CRTL+C to bail or hit enter to go on"
		read goon
	fi
done
cp -r ../aufs$aufs_version-$kernel_branch-git$today/{fs,Documentation} .
cp ../aufs$aufs_version-$kernel_branch-git$today/include/linux/aufs_type.h include/linux 2>/dev/null
cp ../aufs$aufs_version-$kernel_branch-git$today/include/uapi/linux/aufs_type.h include/linux 2>/dev/null
[ -d ../aufs$aufs_version-$kernel_branch-git$today/include/uapi ] && \
cp -r ../aufs$aufs_version-$kernel_branch-git$today/include/uapi/linux/aufs_type.h include/uapi/linux
#cat ../aufs$aufs_version-1-git$today/include/linux/Kbuild >> include/Kbuild
################################################################################

# deblob the kernel
if [ $LIBRE -eq 1 ]; then
	cd ..
	cp -r linux-$kernel_version linux-$kernel_version-orig
	cd linux-$kernel_version
	sh ../dist/sources/vanilla/deblob-$kernel_major_version 2>&1 | tee -a ../build.log
	cd ..
	diff -rupN linux-$kernel_version-orig linux-$kernel_version > dist/sources/patches/deblob.patch
	rm -rf linux-$kernel_version-orig
	cd linux-$kernel_version
fi

kernel_srcsfs_version=$kernel_version

echo "Resetting the minor version number"
cp Makefile Makefile-orig
if [ "$sublevel" = "yes" ];then
	sed -i "s/^SUBLEVEL =.*/SUBLEVEL = 0/" Makefile
	kernel_srcsfs_version=${kernel_major_version}.0
fi
if [ -n "$custom_suffix" ] || [ $LIBRE -eq 1 ]; then
	sed -i "s/^EXTRAVERSION =.*/EXTRAVERSION = $custom_suffix/" Makefile
fi
diff -up Makefile-orig Makefile > ../dist/sources/patches/version.patch
rm Makefile-orig

echo "Reducing the number of consoles"
if [ $kernel_series -gt 3 ] || [ $kernel_series -eq 3 -a $kernel_branch -ge 12 ];then
 if [ $kernel_series -gt 3 ] || [ $kernel_series -eq 3 -a $kernel_branch -ge 16 ];then
	 echo "Reducing the verbosity level"
	 cp -f include/linux/printk.h include/linux/printk.h.orig
	 sed -i s/'#define CONSOLE_LOGLEVEL_DEFAULT 7 \/\* anything MORE serious than KERN_DEBUG \*\/'/'#define CONSOLE_LOGLEVEL_DEFAULT 3 \/\* anything MORE serious than KERN_ERR \*\/'/ include/linux/printk.h
	 diff -up include/linux/printk.h.orig include/linux/printk.h > ../dist/sources/patches/lower-verbosity.patch
 else
	 cp kernel/printk/printk.c kernel/printk/printk.c.orig
	 sed -i s/'#define MAX_CMDLINECONSOLES 8'/'#define MAX_CMDLINECONSOLES 5'/ kernel/printk/printk.c
	 diff -up kernel/printk/printk.c.orig kernel/printk/printk.c > ../dist/sources/patches/less-consoles.patch
	
	 echo "Reducing the verbosity level"
	 cp -f kernel/printk/printk.c kernel/printk/printk.c.orig
	 sed -i s/'#define DEFAULT_CONSOLE_LOGLEVEL 7 \/\* anything MORE serious than KERN_DEBUG \*\/'/'#define DEFAULT_CONSOLE_LOGLEVEL 3 \/\* anything MORE serious than KERN_ERR \*\/'/ kernel/printk/printk.c
	 diff -up kernel/printk/printk.c.orig kernel/printk/printk.c > ../dist/sources/patches/lower-verbosity.patch
 fi
else
 cp kernel/printk.c kernel/printk.c.orig
 sed -i s/'#define MAX_CMDLINECONSOLES 8'/'#define MAX_CMDLINECONSOLES 5'/ kernel/printk.c
 diff -up kernel/printk.c.orig kernel/printk.c > ../dist/sources/patches/less-consoles.patch

 echo "Reducing the verbosity level"
 cp -f kernel/printk.c kernel/printk.c.orig
 sed -i s/'#define DEFAULT_CONSOLE_LOGLEVEL 7 \/\* anything MORE serious than KERN_DEBUG \*\/'/'#define DEFAULT_CONSOLE_LOGLEVEL 3 \/\* Puppy linux hack \*\/'/ kernel/printk.c
 diff -up kernel/printk.c.orig kernel/printk.c > ../dist/sources/patches/lower-verbosity.patch
fi

for patch in ../patches/*; do
	echo "Applying $patch"
	patch -p1 < $patch >> ../build.log 2>&1
	if [ $? -ne 0 ]; then
		echo "Error: failed to apply $patch on the kernel sources."
		exit 1
	fi
	cp $patch ../dist/sources/patches
done

echo "Cleaning the kernel sources"
make clean
make mrproper
find . -name '*.orig' -delete
find . -name '*.rej' -delete
find . -name '*~' -delete
cp ../DOTconfig .config

#pause to configure
echo -en "You now should configure your kernel. The supplied .config\nis \
already configured but you may want to make changes, plus the date \
\nshould be updated. You can choose to run \"make menuconfig\" for \
\nan ncurses based gui (recommended if you don't change stuff or\
\nfor advanced users) or run \"make gconfig\" for a gtk based gui \
\nor if you have qt installed \"make xconfig\" is nice.\
\nHit a number or s to skip\
\n1. make menuconfig\
\n2. make gconfig\
\n3. make xconfig \n"
echo
read kernelconfig
case $kernelconfig in
1)make menuconfig ;;
2)make gconfig ;;
3)make xconfig 
[ "$?" -ne "0" ] && echo "woops.. no qt? exiting" && exit ;;
s)echo "skipping" ;;
esac
echo
echo "Ok, kernel is configured. hit ENTER to continue, CTRL+C to quit"
read goon

[ ! -d ../dist/packages ] && mkdir -p ../dist/packages

echo "Creating the kernel headers package"
make headers_check >> ../build.log 2>&1
make INSTALL_HDR_PATH=kernel_headers-$kernel_version-$package_name_suffix/usr headers_install >> ../build.log 2>&1
find kernel_headers-$kernel_version-$package_name_suffix/usr/include \( -name .install -o -name ..install.cmd \) -delete
mv kernel_headers-$kernel_version-$package_name_suffix ../dist/packages

echo "Compiling the kernel"
make ${JOBS} bzImage modules >> ../build.log 2>&1
cp .config ../dist/sources/DOTconfig-$kernel_version-$today
CONFIG=../dist/sources/DOTconfig-$kernel_version-$today
# we need the arch of the system being built
if grep -q 'CONFIG_X86_64=y' ${CONFIG};then
	arch=x86_64
	karch=x86
elif grep -q 'CONFIG_X86_32=y' ${CONFIG};then
	if grep -q 'CONFIG_X86_32_SMP=y' ${CONFIG};then
		arch=i686
		karch=x86
	else
		arch=i486 #gross assumption
		karch=x86
	fi
elif grep -q 'CONFIG_ARM=y' ${CONFIG};then
	arch=arm
	karch=arm
else
	echo "Your arch is unsupported."
	arch=unknown #allow build anyway
	karch=arm
fi
if [ $karch == 'x86' ];then
	if [ ! -f arch/x86/boot/bzImage -o ! -f System.map ]; then
		echo "Error: failed to compile the kernel sources."
		exit 1
	fi
else
	if [ ! -f arch/arm/boot/zImage ]; then #needs work
		echo "Error: failed to compile the kernel sources."
		exit 1
	fi
fi
echo "Creating the kernel package"
make INSTALL_MOD_PATH=linux_kernel-$kernel_version-$package_name_suffix modules_install >> ../build.log 2>&1
rm -f linux_kernel-$kernel_version-$package_name_suffix/lib/modules/${kernel_srcsfs_version}$custom_suffix/{build,source}
#(cd linux_kernel-$kernel_version-$package_name_suffix/lib/modules/; ln -s ${kernel_major_version}$custom_suffix $kernel_major_version)
mkdir -p linux_kernel-$kernel_version-$package_name_suffix/boot
mkdir -p linux_kernel-$kernel_version-$package_name_suffix/etc/modules
cp .config linux_kernel-$kernel_version-$package_name_suffix/etc/modules/DOTconfig-$kernel_version-$today
cp arch/x86/boot/bzImage linux_kernel-$kernel_version-$package_name_suffix/boot/vmlinuz
BZIMAGE=`find . -type f -name bzImage`
cp System.map linux_kernel-$kernel_version-$package_name_suffix/boot
cp $BZIMAGE linux_kernel-$kernel_version-$package_name_suffix/boot
cp linux_kernel-$kernel_version-$package_name_suffix/lib/modules/${kernel_srcsfs_version}$custom_suffix/{modules.builtin,modules.order} \
 linux_kernel-$kernel_version-$package_name_suffix/etc/modules/
[ "$FD" = "1" ] || \
rm linux_kernel-$kernel_version-$package_name_suffix/lib/modules/${kernel_srcsfs_version}$custom_suffix/modules*
mv linux_kernel-$kernel_version-$package_name_suffix ../dist/packages

if [ "$FD" = "1" ];then #make fatdog kernel module package
	mv ../dist/packages/linux_kernel-$kernel_version-$package_name_suffix/boot/vmlinuz ../dist/packages/vmlinuz-$kernel_version-$package_name_suffix
	#gzip -9 ../dist/packages/vmlinuz-$kernel_version-$package_name_suffix
	[ -f ../dist/packages/linux_kernel-$kernel_version-$package_name_suffix/boot/bzImage ] &&
rm -f ../dist/packages/linux_kernel-$kernel_version-$package_name_suffix/boot/bzImage
	echo "Huge kernel $kernel_version-$package_name_suffix is ready in dist"
fi

echo "Cleaning the kernel sources"
make clean >> ../build.log 2>&1
make prepare >> ../build.log 2>&1

cd ..

echo "Creating a kernel sources SFS"
mkdir -p kernel_sources-$kernel_version-$package_name_suffix/usr/src
mv linux-$kernel_version kernel_sources-$kernel_version-$package_name_suffix/usr/src/linux
mkdir -p kernel_sources-$kernel_version-$package_name_suffix/lib/modules/${kernel_srcsfs_version}$custom_suffix
ln -s /usr/src/linux kernel_sources-$kernel_version-$package_name_suffix/lib/modules/${kernel_srcsfs_version}$custom_suffix/build
[ ! -f kernel_sources-${kernel_version}-$package_name_suffix/usr/src/linux/include/linux/version.h ] && \
ln -s /usr/src/linux/include/generated/uapi/linux/version.h kernel_sources-${kernel_version}-$package_name_suffix/usr/src/linux/include/linux/version.h 
ln -s /usr/src/linux kernel_sources-$kernel_version-$package_name_suffix/lib/modules/${kernel_srcsfs_version}$custom_suffix/source
mksquashfs kernel_sources-$kernel_version-$package_name_suffix dist/sources/kernel_sources-$kernel_version-$package_name_suffix.sfs $COMP
md5sum dist/sources/kernel_sources-$kernel_version-$package_name_suffix.sfs > dist/sources/kernel_sources-$kernel_version-$package_name_suffix.sfs.md5.txt

# build aufs-utils userspace modules
echo "Now to build the aufs-utils for userspace"
if [ ! -f dist/sources/vanilla/aufs-util${today}.tar.bz2 ];then
	git clone ${aufs_utils_git} aufs-util
	[ $? -ne 0 ] && echo "Failed to get aufs-util from git, do it manually. Kernel is compiled OK :)" && exit
	
	cd aufs-util
	
	git branch -a | grep "aufs$kernel_series" |grep -v 'rcN' | cut -d '.' -f2 > /tmp/aufs-util-version #we go for stable only
	while read line
	  do 
	    if [ "$kernel_branch" = "$line" ];then branch=$line
	    else
	      while [ "$kernel_branch" -gt "$line" ]
	        do branch=$line
	        echo $branch && break
	        done 
	    fi
	  done < /tmp/aufs-util-version
	git checkout origin/aufs${kernel_series}.${branch} >> ../build.log 2>&1
	
	[ $? -ne 0 ] && echo "Failed to get aufs-util from git, do it manually. Kernel is compiled OK :)" && exit
	# patch Makefile for static build
	echo "Patching aufs-util sources"
	cp Makefile Makefile.orig
	sed -i 's/-static //' Makefile
	diff -ru Makefile.orig Makefile > ../dist/sources/patches/aufs-util-dynamic.patch
	rm *.orig
	else
	echo "Extracting the Aufs-util sources"
	tar xf dist/sources/vanilla/aufs-util$today.tar.bz2 >> ../build.log 2>&1
	if [ $? -ne 0 ]; then
		echo "Error: failed to extract the aufs-util sources."
		exit 1
	fi	
	cd aufs-util	
	patch -p1 < ../dist/sources/patches/aufs-util-dynamic.patch >> ../build.log 2>&1
	[ "$?" -ne 0 ] && echo "Failed to patch the aufs-util sources, do it manually. Kernel is compiled ok" && exit
fi
# see if fhsm is enabled in kernel config
grep -q 'CONFIG_AUFS_FHSM=y' $CONFIG
[ "$?" -eq 0 ] && export MAKE=make || export MAKE="make BuildFHSM=no"
LinuxSrc=`find $CWD -type d -name 'kernel_headers*'`
export CPPFLAGS="-I $LinuxSrc/usr/include"
$MAKE >> ../build.log 2>&1
[ $? -ne 0 ] && echo "Failed to compile aufs-util, do it manually. Kernel is compiled OK :)" && exit
make DESTDIR=$CWD/dist/packages/aufs-util-$kernel_version-$arch install >> ../build.log 2>&1 #needs absolute path
make clean >> ../build.log 2>&1
if [ "$arch" = "x86_64" ];then
 mv $CWD/dist/packages/aufs-util-$kernel_version-$arch/usr/lib \
$CWD/dist/packages/aufs-util-$kernel_version-$arch/usr/lib64
fi
echo "aufs-util-$kernel_version is in dist"
cd ..
if [ "$FD" = "1" ];then #shift aufs-utils to kernel-modules.sfs
	echo "Installing aufs-utils into kernel package"
	cp -a --remove-destination dist/packages/aufs-util-$kernel_version-$arch/* \
	dist/packages/linux_kernel-$kernel_version-$package_name_suffix

	if [ $LIBRE -eq 0 ];then
		echo "Pausing here to add extra firmware."
		echo "Choose an option:"
		# download the fw or offer to copy
		tmpfw=/tmp/fw$$
		x=1
		wget -q $FW_URL -O - |\
	        sed '/href/!d; /\.tar\./!d; /md5\.txt/d; s/.*href="//; s/".*//' |\
	        while read f;do
	             [ "$f" ] && echo "$x $f" >> ${tmpfw}
	             x=$(($x + 1 ))
	        done
	    y=`cat ${tmpfw}|wc -l `
	    [ "$y" = 0 ] && echo "WARNING: no firmware at that URL" # we carry on
	    x=$(($x + $y))
	    echo "$x I'll copy in my own." >> ${tmpfw}
	    x=$(($x + 1))
	    echo "$x I'll grab the latest firmware form kernel.org. (slow)" >> ${tmpfw}
	    cat ${tmpfw}
	    echo -n "Enter a number, 1 to $x:  "
	    read fw
	    if [ "$fw" -gt "$x" ];then echo "error, wrong number" && exit
		elif [ "$fw" = "$(($x - 1))" ];then
			echo "once you have manually added firmware to "
			echo "dist/packages/linux_kernel-$kernel_version-$package_name_suffix/lib/firmware"
			echo "hit ENTER to continue"
			read firm
		elif [ "$fw" = "$x" ];then
			echo "You have chosen to get the latest firware from kernel.org"
			if [ -d ../linux-firmware ];then
				echo "'git pull' will run so it wont take long to update the"
				echo "firmware repository"
			else
				"This may take a long time as the firmware repository is around 180MB"
			fi
			# run the firmware script and re-enter here
			./fw.sh ${fw_flag} # optonal param; see fw.sh and build.conf
			ret=$?
			if [ $ret -eq 0 ];then 
				echo "Extracting firmware from the kernel.org git repo has succeeded."
			else
				echo "WARNING: Extracting firmware from the kernel.org git repo has failed."
				echo "While your kernel is built, your firmware is incomplete."
			fi
		else
			fw_pkg=`grep ^$fw ${tmpfw}`
			fw_pkg=${fw_pkg##* }
			echo "You chose ${fw_pkg}. If that isn't correct change it manually later."
			echo "downloading $FW_URL/${fw_pkg}"
			wget -t0 -c $FW_URL/${fw_pkg} -P dist/packages
			[ $? -ne 0 ] && echo "failed to download ${fw_pkg##* }" && exit 1
			tar -xjf dist/packages/${fw_pkg} -C dist/packages/linux_kernel-$kernel_version-$package_name_suffix/lib/
			[ $? -ne 0 ] && echo "failed to unpack ${fw_pkg}" && exit 1
			echo "Successfully extracted ${fw_pkg}."
		fi
	fi

	mksquashfs dist/packages/linux_kernel-$kernel_version-$package_name_suffix dist/packages/kernel-modules.sfs-$kernel_version-$package_name_suffix $COMP
	[ "$?" = 0 ] && echo "Huge compatible kernel packages are ready to package./" || exit 1
	echo "Packaging huge-$kernel_version-$package_name_suffix kernel"
	cd dist/packages/
	tar -cjvf huge-$kernel_version-${package_name_suffix}.tar.bz2 \
	vmlinuz-$kernel_version-$package_name_suffix kernel-modules.sfs-$kernel_version-$package_name_suffix
	[ "$?" = 0 ] && echo "huge-$kernel_version-${package_name_suffix}.tar.bz2 is in dist/packages" || exit 1
	md5sum huge-$kernel_version-${package_name_suffix}.tar.bz2 > huge-$kernel_version-${package_name_suffix}.tar.bz2.md5.txt
	echo
	cd -
fi
tar -c aufs-util | bzip2 -9 > dist/sources/vanilla/aufs-util$today-$arch.tar.bz2

echo "Compressing the log"
bzip2 -9 build.log
cp build.log.bz2 dist/sources

echo "Done!"
[ -f /usr/share/sounds/2barks.au ] && aplay /usr/share/sounds/2barks.au
