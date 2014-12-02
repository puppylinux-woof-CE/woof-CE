#!/bin/bash
# originally by Iguleder
# hacked to DEATH by 01micko
# re-hacked by stemsee to provide unattended version, which auto-builds 32bit-pae then 64bit kernels and modules consecutively.
# see /usr/share/doc/legal NO WARRANTY, NO resposibility accepted

if [ -e /tmp/64 ]; then
echo " Both 32bit-pae and 64bit kernels built."
exit

CWD=`pwd`

if [ "$1" = "" ];then
	echo -en "\033[1;35m""WARNING" #purple?
	echo -en "\033[0m" #reset
	echo ": This will delete all builds and sources but wont touch configs."
	echo "Hit CTRL+C and save your stuff manually if you don't want to clean."
	echo "Hit ENTER to clean"
	sleep 4
	#read clean
	echo "Please wait..."
	rm -rf ./{aufs*,kernel*,build.log*}
	echo "Cleaning complete"
	#exit 0
fi
if [ ! -e /tmp/32 ]; then
	if [[ -d ./aufs* ]];then
		echo "This is not a clean kit. Hit ENTER to continue"
		echo "or CTRL+C to quit and run './build.sh clean'"
		read notcleango
	fi
	[[ -f ./build.conf ]] && . ./build.conf
else
	cp /build.conf /build64.conf
	sed -i 's/pae/64/g' /build64.conf
	. ./build64.conf
fi

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
echo "Enter choice"
sleep 4
if [ -z $Chosen ]; then
	if [[ -e /tmp/32 ]]; then
	Chosen=5
	elif [[ ! -e /tmp/32 ]]; then
	Chosen=6
	fi
fi


Choice=$(grep "^$Chosen\." /tmp/kernel_configs|cut -d ' ' -f2)
    #[ ! $Choice ] && \
    #echo "\033[1;31m""ERROR: your choice is not sane ..quiting""\033[0m" \
    #&& exit
    
    #echo "You chose $Choice. If this is ok hit ENTER, 
    #if not hit CTRL|C to quit" 
    ##read oknow

    #if [[ "$Choice" = "Default" || "$Choice" = "Custom" ]];then
    #echo $Choice
    #else
cp -af configs_extra/$Choice DOTconfig
    #fi

# the aufs major version
#aufs_version=${kernel_version%.*.*} #
aufs_version=${kernel_version%%.*}

# fail-safe switch in case someone clicks the script in ROX (real story! not 
# fun at all!!!!) :p
#read -p "Press ENTER to begin" dummy

# get the major version (2.6.32 in the case of 2.6.32.40)
kernel_major_version=$kernel_version #blah, hack for 3.x
# get the kernel branch (32 in the case of 2.6.32.40; needed to download Aufs)
kernel_branch=`echo $kernel_major_version | cut -f 2 -d .` #3.x kernels

# get the minor version (40 in the case of 2.6.32.40)
#case $kernel_version in
	#*.*.*.*) kernel_minor_version=`echo $kernel_version | cut -f 4 -d .` ;;
#esac

# old 2 series info
# the package name suffix (-40 in the case of 2.6.32.40); Woof assumes the 
# package version is identical to the kernel version and uses paths that 
# contain the package version, so use $kernel_major version as the version and
# "-$kernel_minor_version" as the suffix
#case "$kernel_minor_version" in
	#*) package_name_suffix="-$kernel_minor_version";;
#esac

# create directories for the results
[ ! -d dist/sources/vanilla ] && mkdir -p dist/sources/{patches,vanilla}

# get today's date
today=`date +%d%m%y`

# delete the previous log
[ -f build.log ] && rm -f build.log
[ -f build.log.tar.bz2 ] && mv -f build.log.${today}.tar.bz2

downkern () {
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
}
downkern

downaufs () {
	# download Aufs
if [ ! -f dist/sources/vanilla/aufs$aufs_version-$kernel_branch-git$today.tar.bz2 ]; then
	echo "Downloading the Aufs sources"
	#git clone http://git.c3sl.ufpr.br/pub/scm/aufs/aufs2-standalone.git aufs$aufs_version-$kernel_branch-git$today >> build.log 2>&1
	git clone git://aufs.git.sourceforge.net/gitroot/aufs/aufs3-standalone.git aufs$aufs_version-$kernel_branch-git$today >> build.log 2>&1
	#git clone git://github.com/sfjro/aufs3-linux.git aufs$aufs_version-$kernel_branch-git$today >> build.log 2>&1
	#git clone $aufs_git aufs$aufs_version-$kernel_branch-git$today >> build.log 2>&1
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
}
downaufs

patchaufs () {
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
}
patchaufs

extractkern () {
	# extract the kernel
echo "Extracting the kernel sources"
tar xf dist/sources/vanilla/linux-$kernel_version.tar.* >> build.log 2>&1
if [ $? -ne 0 ]; then
	echo "Error: failed to extract the kernel sources."
	exit 1
fi
}
extractkern

cd linux-$kernel_version

aufspatch () {
	echo "Adding Aufs to the kernel sources"
for i in kbuild base standalone mmap; do
	patch -N -p1 < ../aufs$aufs_version-$kernel_branch-git$today/aufs$aufs_version-$i.patch >> ../build.log 2>&1
	if [ $? -ne 0 ]; then
		#echo "Error: failed to add Aufs to the kernel sources."
		#exit 1
		echo "WARNING: failed to add some Aufs patches to the kernel sources."
		echo "Check it manually and either CRTL+C to bail or hit enter to go on"
		exit 1
		#read goon
	fi
done
}
aufspatch

cp -r ../aufs$aufs_version-$kernel_branch-git$today/{fs,Documentation} .
cp ../aufs$aufs_version-$kernel_branch-git$today/include/linux/aufs_type.h include/linux 2>/dev/null
cp ../aufs$aufs_version-$kernel_branch-git$today/include/uapi/linux/aufs_type.h include/linux 2>/dev/null
[ -d ../aufs$aufs_version-$kernel_branch-git$today/include/uapi ] && \
cp -r ../aufs$aufs_version-$kernel_branch-git$today/include/uapi/linux/aufs_type.h include/uapi/linux
#cat ../aufs$aufs_version-1-git$today/include/linux/Kbuild >> include/Kbuild
################################################################################

echo "Resetting the minor version number"
cp Makefile Makefile-orig
sed -i "s/^EXTRAVERSION =/EXTRAVERSION = $custom_suffix/" Makefile
diff -up Makefile-orig Makefile > ../dist/sources/patches/extra-version.patch
rm Makefile-orig

echo "Reducing the number of consoles"
if [ "$kernel_branch" -ge 12 ];then
 if [ "${kernel_version%%.*}" -ge 3 -a "$kernel_branch" -ge 16 ];then
	 cp kernel/printk/printk.c kernel/printk/printk.c.orig
	 sed -i s/'#define MAX_CMDLINECONSOLES 8'/'#define MAX_CMDLINECONSOLES 5'/ kernel/printk/printk.c
	 diff -up kernel/printk/printk.c.orig kernel/printk/printk.c > ../dist/sources/patches/less-consoles.patch
	
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

patches () {
for patch in ../patches/*; do
	echo "Applying $patch"
	patch -p1 < $patch >> ../build.log 2>&1
	if [ $? -ne 0 ]; then
		echo "Error: failed to apply $patch on the kernel sources."
		exit 1
	fi
	cp $patch ../dist/sources/patches
done
}
patches

cleaningsrc () {
echo "Cleaning the kernel sources"
make clean
make mrproper
find . -name '*.orig' -delete
find . -name '*.rej' -delete
find . -name '*~' -delete
cp ../DOTconfig .config
}
cleaningsrc

##echo "exiting for config" #uncomment this to change .config #nah, pause routine
##exit #uncomment this to change .config
##pause to configure
#echo "You now should configure your kernel. The supplied .config\nis \
#already configured but you may want to make changes, plus the date \
#\nshould be updated. You can choose to run \"make menuconfig\" for \
#\nan ncurses based gui (recommended if you don't change stuff or\
#\nfor advanced users)
#\n1. make menuconfig\
#echo
#sleep 4
#kernelconfig=1
#case $kernelconfig in
#~1)make menuconfig ;;
##2)make gconfig ;;
##3)make xconfig 
##[ "$?" -ne "0" ] && echo "woops.. no qt? exiting" && exit ;;
#s)echo "skipping" ;;
#esac
#echo
#echo "Ok, kernel is configured. hit ENTER to continue, CTRL+C to quit"
#sleep 4
##read goon

[ ! -d ../dist/packages ] && mkdir -p ../dist/packages

krnheads () {
	echo "Creating the kernel headers package"
make headers_check >> ../build.log 2>&1
make INSTALL_HDR_PATH=kernel_headers-$kernel_major_version-$package_name_suffix/usr headers_install >> ../build.log 2>&1
find kernel_headers-$kernel_major_version-$package_name_suffix/usr/include \( -name .install -o -name ..install.cmd \) -delete
mv kernel_headers-$kernel_major_version-$package_name_suffix ../dist/packages
}
krnheads

krncompile () {
	echo "Compiling the kernel"
time make ${JOBS} bzImage modules >> ../build.log 2>&1
if [[ ! -f arch/x86/boot/bzImage || ! -f System.map ]]; then
	echo "Error: failed to compile the kernel sources."
	exit 1
fi
cp .config ../dist/sources/DOTconfig-$kernel_version-$today
}
krncompile

echo "Creating the kernel package"
make INSTALL_MOD_PATH=linux_kernel-$kernel_major_version-$package_name_suffix modules_install >> ../build.log 2>&1
rm -f linux_kernel-$kernel_major_version-$package_name_suffix/lib/modules/${kernel_major_version}$custom_suffix/{build,source}
#(cd linux_kernel-$kernel_major_version-$package_name_suffix/lib/modules/; ln -s ${kernel_major_version}$custom_suffix $kernel_major_version)
mkdir -p linux_kernel-$kernel_major_version-$package_name_suffix/boot
mkdir -p linux_kernel-$kernel_major_version-$package_name_suffix/etc/modules
cp .config linux_kernel-$kernel_major_version-$package_name_suffix/etc/modules/DOTconfig-$kernel_version-$today
cp arch/x86/boot/bzImage linux_kernel-$kernel_major_version-$package_name_suffix/boot/vmlinuz
BZIMAGE=`find . -type f -name bzImage`
cp System.map linux_kernel-$kernel_major_version-$package_name_suffix/boot/
#cp $BZIMAGE linux_kernel-$kernel_major_version-$package_name_suffix/boot/
cp linux_kernel-$kernel_major_version-$package_name_suffix/lib/modules/${kernel_major_version}$custom_suffix/{modules.builtin,modules.order} \
 linux_kernel-$kernel_major_version-$package_name_suffix/etc/modules/
[ "$FD" = "1" ] || \
mv linux_kernel-$kernel_major_version-$package_name_suffix/lib/modules/${kernel_major_version}$custom_suffix/modules* ../dist/packages/
mv linux_kernel-$kernel_major_version-$package_name_suffix ../dist/packages/

if [ "$FD" = "1" ];then #make fatdog kernel module package
	mv ../dist/packages/linux_kernel-$kernel_major_version-$package_name_suffix/boot/vmlinuz ../dist/packages/vmlinuz-$kernel_major_version-$package_name_suffix/vmlinuz-${kernel-major-version}$custom_suffix
	#gzip -9 ../dist/packages/vmlinuz-$kernel_major_version-$package_name_suffix
	[ -f ../dist/packages/linux_kernel-$kernel_major_version-$package_name_suffix/boot/bzImage ] &&
rm -f ../dist/packages/linux_kernel-$kernel_major_version-$package_name_suffix/boot/bzImage
	echo "Huge kernel $kernel_major_version-$package_name_suffix is ready in dist"
fi

echo "Cleaning the kernel sources"
make clean >> ../build.log 2>&1
make prepare >> ../build.log 2>&1

cd ..

echo "Creating a kernel sources SFS"
mkdir -p kernel_sources-$kernel_major_version-$package_name_suffix/usr/src
mv linux-$kernel_version kernel_sources-$kernel_major_version-$package_name_suffix/usr/src/linux
mkdir -p kernel_sources-$kernel_major_version-$package_name_suffix/lib/modules/${kernel_major_version}$custom_suffix
ln -s /usr/src/linux kernel_sources-$kernel_major_version-$package_name_suffix/lib/modules/${kernel_major_version}$custom_suffix/build
[ ! -f kernel_sources-${kernel_major_version}-$package_name_suffix/usr/src/linux/include/linux/version.h ] && \
ln -s /usr/src/linux/include/generated/uapi/linux/version.h kernel_sources-${kernel_major_version}-$package_name_suffix/usr/src/linux/include/linux/version.h 
ln -s /usr/src/linux kernel_sources-$kernel_major_version-$package_name_suffix/lib/modules/${kernel_major_version}$custom_suffix/source
mksquashfs kernel_sources-$kernel_major_version-$package_name_suffix dist/sources/kernel_sources-$kernel_major_version-$package_name_suffix.sfs $COMP

# build aufs-utils userspace modules
echo "Now to build the aufs-utils for userspace"
if [ ! -f dist/sources/vanilla/aufs-util${today}.tar.bz2 ];then
	git clone git://aufs.git.sourceforge.net/gitroot/aufs/aufs-util.git aufs-util >> build.log 2>&1
	#git clone git://git.code.sf.net/p/aufs/aufs-util aufs-util
	[ $? -ne 0 ] && echo "Failed to get aufs-util from git, do it manually. Kernel is compiled OK :)" && exit
	
	cd aufs-util
	
	git branch -a | grep 'aufs3' |grep -v 'rcN' | cut -d '.' -f2 > /tmp/aufs-util-version #we go for stable only
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
	git checkout origin/aufs3.${branch} >> ../build.log 2>&1
	
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
arch=`uname -m`
#LinuxSrc=../dist/packages/kernel_headers*
# see if fhsm is enabled in kernel config
CONFIG=`find $CWD/dist/sources -type f -name 'DOTconfig*'`
grep -q 'CONFIG_AUFS_FHSM=y' $CONFIG
[ "$?" -eq 0 ] && export MAKE=make || export MAKE="make BuildFHSM=no"
LinuxSrc=`find $CWD -type d -name 'kernel_headers*'`
export CPPFLAGS="-I $LinuxSrc/usr/include"
$MAKE >> ../build.log 2>&1
[ $? -ne 0 ] && echo "Failed to compile aufs-util, do it manually. Kernel is compiled OK :)" && exit
make DESTDIR=$CWD/dist/packages/aufs-util-$kernel_version-$arch install >> ../build.log 2>&1 #maybe needs absolute path
make clean >> ../build.log 2>&1
if [ "$arch" = "x86_64" ];then
 mv $CWD/dist/packages/aufs-util-$kernel_version-$arch/usr/lib \
$CWD/dist/packages/aufs-util-$kernel_version-$arch/usr/lib64
fi
echo "aufs-util-$kernel_version is in dist"
cd ..
if [ "$FD" = "1" ];then #shift aufs-utils to kernel-modules.sfs
	echo "Installing aufs-utils into kernel package"
	cp -a dist/packages/aufs-util-$kernel_version-$arch/* \
	dist/packages/linux_kernel-$kernel_major_version-$package_name_suffix
	#echo "Pausing hereto add extra firmware."
	#echo "Choose an option:"
	# download the fw or offer to copy
	#tmpfw=/tmp/fw$$
	#x=1
	#wget -q $FW_URL -O - |\
        #sed '/href/!d; /\.tar\./!d; /md5\.txt/d; s/.*href="//; s/".*//' |\
        #while read f;do
             #[ "$f" ] && echo "$x $f" >> ${tmpfw}
             #x=$(($x + 1 ))
        #done
    #y=`cat ${tmpfw}|wc -l `
    #[ "$y" = 0 ] && echo "error, no firmware at that URL" && exit 1
    #x=$(($x + $y))
    #echo "$x I'll copy in my own." >> ${tmpfw}
    #cat ${tmpfw}
    #echo -n "Enter a number, 1 to $x:  "
    #read fw
    #if [ "$fw" -gt "$x" ];then "error, wrong number" && exit
	#elif [ "$fw" = "$x" ];then
		#echo "once you have manually added firmware to "
		#echo "dist/packages/linux_kernel-$kernel_major_version-$package_name_suffix/lib/firmware"
		#echo "hit ENTER to continue"
		#read firm
	#else
		#fw_pkg=`grep ^$fw ${tmpfw}`
		#fw_pkg=${fw_pkg##* }
		#echo "You chose ${fw_pkg}. If that isn't correct change it manually later."
		#echo "downloading $FW_URL/${fw_pkg}"
		#wget -t0 -c $FW_URL/${fw_pkg} -P dist/packages
		#[ $? -ne 0 ] && echo "failed to download ${fw_pkg##* }" && exit 1
		#tar -xjf dist/packages/${fw_pkg} -C dist/packages/linux_kernel-$kernel_major_version-$package_name_suffix/lib/
		#[ $? -ne 0 ] && echo "failed to unpack ${fw_pkg}" && exit 1
		#echo "Successfully extracted ${fw_pkg}."
	cp -r /lib/firmware dist/packages/linux_kernel-$kernel_major_version-$package_name_suffix/lib/
	#rm ${tmpfw}
	mksquashfs dist/packages/linux_kernel-$kernel_major_version-$package_name_suffix dist/packages/kernel-modules.sfs-$kernel_major_version-$package_name_suffix $COMP
	[ "$?" = 0 ] && echo "Huge compatible kernel packages are ready to package./" || exit 1
	echo "Packaging huge-$kernel_major_version-$package_name_suffix kernel"
	cd dist/packages/
	tar -cjvf huge-$kernel_major_version-${package_name_suffix}.tar.bz2 \
	vmlinuz-$kernel_major_version-$package_name_suffix kernel-modules.sfs-$kernel_major_version-$package_name_suffix
	[ "$?" = 0 ] && echo "huge-$kernel_major_version-${package_name_suffix}.tar.bz2 is in dist/packages" || exit 1
	md5sum huge-$kernel_major_version-${package_name_suffix}.tar.bz2 > huge-$kernel_major_version-${package_name_suffix}.tar.bz2.md5.txt
	echo
	cd -
	
fi

tar -c aufs-util | bzip2 -9 > dist/sources/vanilla/aufs-util$today-$arch.tar.bz2

echo "Compressing the log"
bzip2 -9 build.log
cp build.log.bz2 dist/sources

echo "Done!"
if [ -e /tmp/32 ]; then
mv /tmp/32 /tmp/64
else
touch /tmp/32
fi
[ -f /usr/share/sounds/2barks.au ] && aplay /usr/share/sounds/2barks.au
rename packages packages32 dist/packages
mkdir dist/packages
cd $CWD
./build.sh
exit
