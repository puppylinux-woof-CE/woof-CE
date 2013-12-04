#!/bin/sh
# originally by Iguleder
# hacked to DEATH by 01micko
# see /usr/share/doc/legal NO WARRANTY, NO resposibility accepted

# read config
[ -f ./build.conf ] && . ./build.conf

package_name_suffix=$package_name_suffix
custom_suffix=$custom_suffix
kernel_version=$kernel_version
kernel_mirror=$kernel_mirror

# depcheck
echo "Dependency check..."
if git --version &>/dev/null
 then echo -e "\033[1;34m""git is installed" #green 
 else echo -e "\033[1;31m""git is not installed""\033[0m" && exit #red
fi
if gcc --version &>/dev/null
 then echo -e "\033[1;34m""gcc is installed" 
 else
   echo -e "\033[1;31m""gcc is not installed""\033[0m" && exit
fi
MKSQ="$(which mksquashfs)"
if [ "$MKSQ" ]
 then 
   echo -e "\033[1;34m""mksquashfs is installed"
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
    Choice=$(grep ^$Chosen /tmp/kernel_configs|cut -d ' ' -f2)
    [ ! $Choice ] && \
    echo -e "\033[1;31m""ERROR: your choice is not sane ..quiting""\033[0m" \
    && exit
    echo -e "You chose $Choice. If this is ok hit ENTER, \
    \nif not hit CTRL|C to quit" 
    read oknow
    if [[ "$Choice" = "Default" || "$Choice" = "Custom" ]];then
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

# fail-safe switch in case someone clicks the script in ROX (real story! not 
# fun at all!!!!) :p
read -p "Press ENTER to begin" dummy

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


# download Aufs
if [ ! -f dist/sources/vanilla/aufs$aufs_version-$kernel_branch-git$today.tar.bz2 ]; then
	echo "Downloading the Aufs sources"
	#git clone http://git.c3sl.ufpr.br/pub/scm/aufs/aufs2-standalone.git aufs$aufs_version-$kernel_branch-git$today >> build.log 2>&1
	#git clone git://aufs.git.sourceforge.net/gitroot/aufs/aufs3-standalone.git aufs$aufs_version-$kernel_branch-git$today >> build.log 2>&1
	#git clone git://github.com/sfjro/aufs3-linux.git aufs$aufs_version-$kernel_branch-git$today >> build.log 2>&1
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

##download unionfs
#if [ ! -f dist/sources/vanilla/unionfs-2.5.11_for_${kernel_version}.diff.gz ]; then
	#echo "downloading unionfs patches"
	#wget -P dist/sources/vanilla http://download.filesystems.org/unionfs/unionfs-2.x-latest/unionfs-2.5.11_for_${kernel_version}.diff.gz >> build.log 2>&1
	#if [ $? -ne 0 ]; then
		#echo "Error: failed to download the unionfs patch."
		#exit 1
	#fi
	#gunzip dist/sources/vanilla/unionfs-2.5.11_for_${kernel_version}.diff.gz
	#if [ $? -ne 0 ]; then
		#echo "Error: failed to extract the unionfs patch."
		#exit 1
	#fi
	#mv dist/sources/vanilla/unionfs-2.5.11_for_${kernel_version}.diff patches/unionfs-2.5.11_for_${kernel_version}.patch
#fi

#read #remove!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

# extract the kernel
echo "Extracting the kernel sources"
tar xf dist/sources/vanilla/linux-$kernel_version.tar.* >> build.log 2>&1
if [ $? -ne 0 ]; then
	echo "Error: failed to extract the kernel sources."
	exit 1
fi

cd linux-$kernel_version

echo "Adding Aufs to the kernel sources"
for i in kbuild base standalone mmap; do
	patch -p1 < ../aufs$aufs_version-$kernel_branch-git$today/aufs$aufs_version-$i.patch >> ../build.log 2>&1
	if [ $? -ne 0 ]; then
		echo "Error: failed to add Aufs to the kernel sources."
		exit 1
	fi
done
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
 cp kernel/printk/printk.c kernel/printk/printk.c-orig
 sed -i s/'#define MAX_CMDLINECONSOLES 8'/'#define MAX_CMDLINECONSOLES 5'/ kernel/printk/printk.c
 diff -up kernel/printk/printk.c-orig kernel/printk/printk.c > ../dist/sources/patches/less-consoles.patch

 echo "Reducing the verbosity level"
 cp -f kernel/printk/printk.c kernel/printk/printk.c-orig
 sed -i s/'#define DEFAULT_CONSOLE_LOGLEVEL 7 \/\* anything MORE serious than KERN_DEBUG \*\/'/'#define DEFAULT_CONSOLE_LOGLEVEL 3 \/\* anything MORE serious than KERN_ERR \*\/'/ kernel/printk/printk.c
 diff -up kernel/printk/printk.c-orig kernel/printk/printk.c > ../dist/sources/patches/lower-verbosity.patch
else
 cp kernel/printk.c kernel/printk.c-orig
 sed -i s/'#define MAX_CMDLINECONSOLES 8'/'#define MAX_CMDLINECONSOLES 5'/ kernel/printk.c
 diff -up kernel/printk.c-orig kernel/printk.c > ../dist/sources/patches/less-consoles.patch

 echo "Reducing the verbosity level"
 cp -f kernel/printk.c kernel/printk.c-orig
 sed -i s/'#define DEFAULT_CONSOLE_LOGLEVEL 7 \/\* anything MORE serious than KERN_DEBUG \*\/'/'#define DEFAULT_CONSOLE_LOGLEVEL 3 \/\* anything MORE serious than KERN_ERR \*\/'/ kernel/printk.c
 diff -up kernel/printk.c-orig kernel/printk.c > ../dist/sources/patches/lower-verbosity.patch
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

#echo "exiting for config" #uncomment this to change .config #nah, pause routine
#exit #uncomment this to change .config
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

[ ! -d ../dist/packages ] && mkdir ../dist/packages

echo "Creating the kernel headers package"
make headers_check >> ../build.log 2>&1
make INSTALL_HDR_PATH=kernel_headers-$kernel_major_version-$package_name_suffix/usr headers_install >> ../build.log 2>&1
find kernel_headers-$kernel_major_version-$package_name_suffix/usr/include \( -name .install -o -name ..install.cmd \) -delete
mv kernel_headers-$kernel_major_version-$package_name_suffix ../dist/packages

echo "Compiling the kernel"
make ${JOBS} bzImage modules >> ../build.log 2>&1
if [[ ! -f arch/x86/boot/bzImage || ! -f System.map ]]; then
	echo "Error: failed to compile the kernel sources."
	exit 1
fi
cp .config ../dist/sources/DOTconfig-$kernel_version-$today

echo "Creating the kernel package"
make INSTALL_MOD_PATH=linux_kernel-$kernel_major_version-$package_name_suffix modules_install >> ../build.log 2>&1
rm -f linux_kernel-$kernel_major_version-$package_name_suffix/lib/modules/${kernel_major_version}$custom_suffix/{build,source}
#(cd linux_kernel-$kernel_major_version-$package_name_suffix/lib/modules/; ln -s ${kernel_major_version}$custom_suffix $kernel_major_version)
mkdir linux_kernel-$kernel_major_version-$package_name_suffix/boot
mkdir -p linux_kernel-$kernel_major_version-$package_name_suffix/etc/modules
cp .config linux_kernel-$kernel_major_version-$package_name_suffix/etc/modules/DOTconfig-$kernel_version-$today
cp arch/x86/boot/bzImage linux_kernel-$kernel_major_version-$package_name_suffix/boot/vmlinuz
cp System.map linux_kernel-$kernel_major_version-$package_name_suffix/boot
cp linux_kernel-$kernel_major_version-$package_name_suffix/lib/modules/${kernel_major_version}$custom_suffix/{modules.builtin,modules.order} \
 linux_kernel-$kernel_major_version-$package_name_suffix/etc/modules/
rm linux_kernel-$kernel_major_version-$package_name_suffix/lib/modules/${kernel_major_version}$custom_suffix/modules*
mv linux_kernel-$kernel_major_version-$package_name_suffix ../dist/packages

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
mksquashfs kernel_sources-$kernel_major_version-$package_name_suffix dist/sources/kernel_sources-$kernel_major_version-$package_name_suffix.sfs -comp xz

# build aufs-utils userspace modules
echo "Now to build the aufs-utils for userspace"
if [ ! -f dist/sources/vanilla/aufs-util${today}.tar.bz2 ];then
	#git clone git://aufs.git.sourceforge.net/gitroot/aufs/aufs-util.git aufs-util >> build.log 2>&1
	git clone git://git.code.sf.net/p/aufs/aufs-util aufs-util
	[ $? -ne 0 ] && echo "Failed to get aufs-util from git, do it manually. Kernel is compiled OK :)" && exit
	
	cd aufs-util
	
	git branch -a | grep '3' |grep -v 'rcN' | cut -d '.' -f2 > /tmp/aufs-util-version #we go for stable only
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
LinuxSrc=../dist/packages/kernel_headers*
export CPPFLAGS="-I $LinuxSrc/usr/include"
make >> ../build.log 2>&1
[ $? -ne 0 ] && echo "Failed to compile aufs-util, do it manually. Kernel is compiled OK :)" && exit
make DESTDIR=../dist/packages/aufs-util-$kernel_version install >> ../build.log 2>&1
make clean >> ../build.log 2>&1
echo "aufs-util-$kernel_version is in dist"
cd ..
tar -c aufs-util | bzip2 -9 > dist/sources/vanilla/aufs-util$today.tar.bz2

echo "Compressing the log"
bzip2 -9 build.log
cp build.log.bz2 dist/sources

echo "Done!"
aplay /usr/share/sounds/2barks.au
