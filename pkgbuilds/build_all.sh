#!/bin/sh

# packages can be built individually if you wish

export MWD=`pwd`

. ./build.conf

usage() {
	echo
	echo "Usage:-"
	echo
	echo "Just run ${0##*/}"
	echo "All petbuilds in the queue will be run and hopefully built"
	echo
	echo "If you only want to build a single package, then use"
	echo "the generic  package name as the argument to ${0##*/}"
	echo
	echo "eg; 	${0##*/} rox-filer"
	
	echo
	echo "	Licenced under the GPLv2"
	echo "	report bugs to https://github.com/puppylinux-woof-CE/petbuilds"
	exit 0
}

get_specs() {
	[ -f 0pets_out.specs ] && rm 0pets_out.specs
	cd 0pets_out
	for pet in *.pet; do 
		echo -n "$pet "
		specs=`tar -xvJf "$pet" --no-anchored 'pet.specs' 2>/dev/null`
		cat $specs >> ../0pets_out.specs
		rm -rf ${pet%.*}
	done
	cd -
}

OLD_PATH=$PATH 

petbuilds_trap_exit() {    
   export PATH=$OLD_PATH 
} 

trap petbuilds_trap_exit EXIT 

petbuilds_bootstrap() { 
	# Get this scripts path so we use our modified scripts rather than the 
	# original ones 
	SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" 
	echo "\$SDIR:=$SDIR" 
	if [[ $PATH != *$SDIR* ]]; then 
		export PATH=$SDIR:$PATH 
		DIRTOPET=`which dir2pet` 
		AGE=$(date +%s -r  $DIRTOPET) # =1413022441 is current verion 
		if [ "$AGE" -lt  1413022441 ];then 
			echo "dir2pet  is built before $(date -r $DIRTOPET) ." 
			echo "Get the corresponding one from ..."
			echo "http://distro.ibiblio.org/puppylinux/pet_packages-noarch/dir2pet-0.0.1-noarch.pet"
			exit 1
		fi      
	fi 

} 
petbuilds_bootstrap

build_it() {
	pkg=${1/\//} # remove trailing slash if using bash completion
	case "$1" in
		-h|-help|--help) usage ;;
	esac
	[ -d "$1" ] || usage
	echo "
+=============================================================================+

building $pkg"
	cd pkgs/$pkg
	sh ${pkg}.petbuild 2>&1 | tee ../../0logs/${pkg}build.log
	cd -
	echo "done building $pkg"
	exit
}

build_all() {
	for pkg in `cat ORDER`; do
		pkg_exits=`ls ./0pets_out|grep "^$pkg"|grep "pet$"`
		if [ "$pkg_exits" ];then
			echo "$pkg exists ... skipping"
			sleep 0.5
			continue
		fi
		echo
		cd pkgs/$pkg
		echo "
+=============================================================================+

building $pkg"
		sleep 1 
		sh ${pkg}.petbuild 2>&1 | tee ../../0logs/${pkg}build.log
		if [ "$?" -eq 1 ];then 
			echo "$pkg build failure"
			case $HALT_ERRS in
				0)cd - ; exit 1 ;;
			esac
		fi
		cd -
	done
}

[ "$1" ] && build_it "$1" || build_all

echo "
+=============================================================================+

getting specs"
# get the specs
get_specs
echo


echo "all done!" && exit 0
