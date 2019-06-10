#!/bin/bash
# param: <kernel_version> 
# param: 4.14.0
#
#------------------------------------------------------------------------
#-                         AUFS GIT BRANCHES
#------------------------------------------------------------------------
# aufs3: git://git.code.sf.net/p/aufs/aufs3-standalone.git
# aufs4: git://github.com/sfjro/aufs4-standalone.git
# aufs5: git://github.com/sfjro/aufs5-standalone.git
# aufs-util: git://git.code.sf.net/p/aufs/aufs-util.git
#

[ -z "$1" ] && exit 1

kernel_version=${1}

IFS=. read -r kernel_series \
		kernel_major_version \
		kernel_minor_version \
		kernel_minor_revision <<< "${kernel_version}"

kernel_major_version=${kernel_series}.${kernel_major_version} # 4.19

case ${kernel_major_version} in

	#### k3.0 #####
	3.0)
		aufsv=3.0 ;;
	3.1)
		aufsv=3.1 ;;
	3.2)
		aufsv='3.2'                #unknown actual value
		vercmp ${kernel_version} ge 3.2.30 && aufsv='3.2.x'
		;;
	3.3)
		aufsv=3.3 ;;
	3.4)
		aufsv=3.4 ;;
	3.5)
		aufsv=3.5 ;;
	3.6)
		aufsv=3.6 ;;
	3.7)
		aufsv=3.7 ;;
	3.8)
		aufsv=3.8 ;;
	3.9)
		aufsv=3.9 ;;
	3.10)
		aufsv=3.10
		vercmp ${kernel_version} ge 3.10.26 && aufsv='3.10.x'
		;;
	3.11)
		aufsv=3.11 ;;
	3.12)
		aufsv=3.12
		vercmp ${kernel_version} ge 3.12.7 && aufsv='3.12.x'
		vercmp ${kernel_version} ge 3.12.31 && aufsv='3.12.31+'
		;;
	3.13)
		aufsv=3.13 ;;
	3.14)
		aufsv=3.14
		vercmp ${kernel_version} ge 3.14.21 && aufsv='3.14.21+'
		vercmp ${kernel_version} ge 3.14.40 && aufsv='3.14.40+'
		;;
	3.15)
		aufsv=3.15 ;;
	3.16)
		aufsv=3.16 ;;
	3.17)
		aufsv=3.17 ;;
	3.18)
		aufsv='3.18'
		vercmp ${kernel_version} ge 3.18.1 && aufsv='3.18.1+'
		vercmp ${kernel_version} ge 3.18.25 && aufsv='3.18.25+'
		;;
	3.19)
		aufsv=3.19 ;;

	#### k4.0 #####
	4.0)
		aufsv=4.0 ;;
	4.1)
		aufsv=4.1
		vercmp ${kernel_version} ge 4.1.13 && aufsv='4.1.13+'
		;;
	4.2)
		aufsv=4.2 ;;
	4.3)
		aufsv=4.3 ;;
	4.4)
		aufsv=4.4 ;;
	4.5)
		aufsv=4.5 ;;
	4.6)
		aufsv=4.6 ;;
	4.7)
		aufsv=4.7 ;;
	4.8)
		aufsv=4.8 ;;
	4.9)
		aufsv=4.9
		vercmp ${kernel_version} ge 4.9.9 && aufsv='4.9.9+'
		vercmp ${kernel_version} ge 4.9.94 && aufsv='4.9.94+'
		;;
	4.10)
		aufsv=4.10 ;;
	4.11)
		aufsv=4.11.0-untested
		vercmp ${kernel_version} ge 4.11.7 && aufsv='4.11.7+'
		;;
	4.12)
		aufsv=4.12 ;;
	4.13)
		aufsv=4.13 ;;
	4.14)
		aufsv=4.14
		vercmp ${kernel_version} ge 4.14.56 && aufsv='4.14.56+'
		vercmp ${kernel_version} ge 4.14.73 && aufsv='4.14.73+'
		;;
	4.15)
		aufsv=4.15 ;;
	4.16)
		aufsv=4.16 ;;
	4.17)
		aufsv=4.17 ;;
	4.18)
		aufsv=4.18
		vercmp ${kernel_version} ge 4.18.11 && aufsv='4.18.11+'
		;;
	4.19)
		aufsv=4.19
		vercmp ${kernel_version} ge 4.19.17 && aufsv='4.19.17+'
		;;
	4.20)
		aufsv=4.20
		vercmp ${kernel_version} ge 4.20.4 && aufsv='4.20.4+'
		;;

	#### k5.0 #####
	5.0)
		aufsv=5.0 ;;
	5.1)
		aufsv=5.1 ;;
esac

#=====================================================

# aufs-util
if vercmp ${kernel_version} ge 4.14 ; then
	aufs_util_branch=4.14
elif vercmp ${kernel_version} ge 4.9  ; then
	aufs_util_branch=4.9
elif vercmp ${kernel_version} ge 4.4  ; then
	aufs_util_branch=4.4
elif vercmp ${kernel_version} ge 4.1  ; then
	aufs_util_branch=4.1
elif vercmp ${kernel_version} ge 4.0  ; then
	aufs_util_branch=4.0
elif vercmp ${kernel_version} ge 3.18 ; then
	aufs_util_branch=3.18
elif vercmp ${kernel_version} ge 3.14 ; then
	aufs_util_branch=3.14
elif vercmp ${kernel_version} ge 3.9  ; then
	aufs_util_branch=3.9
elif vercmp ${kernel_version} ge 3.2  ; then
	aufs_util_branch=3.2
elif vercmp ${kernel_version} ge 3.0 ; then
	aufs_util_branch=3.0
fi

#=====================================================

if [ "$aufsv" ] ; then
	echo -n $aufsv #git branch
	echo -n ' '
fi

if [ "$aufs_util_branch" ] ; then
	echo -n $aufs_util_branch
fi

### END ###
