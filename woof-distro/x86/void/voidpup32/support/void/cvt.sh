#!/bin/sh
# jamesbond 2021, public domain

AWK='gawk' # or 'gawk', or 'busybox awk', etc
SHL='/bin/sh' # or '/bin/sh' or /bin/bash' or '/bin/ash' etc
[ -z $1 ] && exec $SHL $0 $SHL

# You also need a package called xml2
[ ! `which xml2` ] && echo "**** package xml2 not found - aborting setup - sorry" && exit

# --- Performance figures ---
#
# If you run with dash and mawk (a very fast awk)
# time ./cvt.sh  > /dev/null
#real	0m0.972s
#user	0m1.571s
#sys	0m0.026s
#
# If you run with bash and gawk
# time ./cvt.sh  > /dev/null
#real	0m1.909s
#user	0m2.746s
#sys	0m0.042s
#
# If you run with busybox ash and busybox awk
# time ./cvt.sh  > /dev/null
#real	0m37.308s
#user	0m38.203s
#sys	0m0.081s

#./xml2 < pkgdb-0.38-klv.plist | $AWK -F= '
xml2 < index.plist | $AWK -F= '
BEGIN {
	pkg_key="/plist/dict/key"
	fsize_key="filename-size"
	arch_key="architecture"
	pkgver_key="pkgver"
	sourcerev_key="source-revisions"
	rundep_key="run_depends"
	#inkscape has this, causes lib to be in deps list...
	shlibprov_key="shlib-provides"
	#previously these shared libs were getting included in deps list...
	shlibreq_key="shlib-requires"
	desc_key="short_desc"
	
	int_key="/plist/dict/dict/integer"
	string_key="/plist/dict/dict/string"
	arraystr_key="/plist/dict/dict/array/string"
}

# token recognisers
$1 ~ pkg_key {
	pkgname=$2
	nextfield=""
	endpkg=0
}
$2 ~ fsize_key {
	nextfield="fsize"
}
$2 ~ arch_key {
	nextfield="arch"
}
$2 ~ pkgver_key {
	nextfield="pkgver"
}
$2 ~ rundep_key {
	nextfield="rundep"
	pkgdep=""
}
$2 ~ shlibprov_key {
	nextfield="shlibsprov"
}
$2 ~ shlibreq_key {
	nextfield="shlibsreq"
}
$2 ~ desc_key {
	nextfield="desc"
}
$2 ~ sourcerev_key {
	endpkg=1
}

# collect values
$1 ~ int_key {
	if (nextfield == "fsize") {
		fsize=$2
		pkgsize=int(fsize/1024) "K"
		nextfield=""
	}
}
$1 ~ string_key {
	if (nextfield == "arch") {
		arch=$2
		nextfield=""

	} else if (nextfield == "pkgver") {
		pkgver=$2
		pkgvver=$2
		#ex: pkgver=SDL_ttf-2.0.11_7 then pkgvver=2.0.11_7
		gsub("^" pkgname "-","",pkgvver)
		#ex: pkgvver=2.0.11_7 then pkgveronly=2.0.11
		pkgveronly=pkgvver
		gsub("_[0-9]*$","",pkgveronly)
		#ex: pkgvver=2.0.11_7 then pkgrelease=7
		pkgrelease=pkgvver
		gsub(".*_","",pkgrelease)
		nextfield=""
	} else if (nextfield == "desc") {
		pkgdesc=$2
		nextfield=""
	}
}
$1 ~ arraystr_key {
	if (nextfield == "rundep") {
		if ($2) {
			gsub(/>.*/,"",$2)
			pkgdep=pkgdep ",+" $2
		}
	}
}

# output final result
#acl-2.2.52|acl|2.2.52|1|BuildingBlock|430K|slackware/a|acl-2.2.52-i486-1.txz|+attr|tools for using POSIX Access Control Lists|void|current||
{
	if (endpkg) {
		if (pkgdep) gsub(/^,/,"",pkgdep)
		pkgfn = pkgver "." arch ".xbps"
		print pkgver "|" pkgname "|" pkgveronly "|" pkgrelease "|Uncategorized|" pkgsize "|current|" pkgfn "|" pkgdep "|" pkgdesc "|void|current||" 
		endpkg=0
	}
}
'
