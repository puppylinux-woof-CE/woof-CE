#!/bin/bash

# Desktop file Icon entries with absolute paths are not supported.
# Desktop file Path and Terminal keys are not implemented, 
#  but probably could be.

#exec &>/tmp/owmi.log

[ -z $GTKDIALOG ] && GTKDIALOG=gtkdialog

while [ "$1" != "" ]
do
	case $1 in
		-f|--file)
			shift
			filename=$1
			shift
			continue
			;;
		-m|--mimetype)
			shift
			mimetype=$1
			shift
			continue
			;;
		*)
			if [ -f "$1" ]; then
				filename=$1
				shift
				continue
			else
				echo "Unrecognized option $1"
				exit
			fi
			;;
	esac
done

if [ ! -f "$filename" ]; then
	echo "${0}: $filename does not exist."
	exit
fi

! [ "$XDG_DATA_HOME" ] && XDG_DATA_HOME="$HOME/.local/share"
! [ "$XDG_DATA_DIRS" ] && XDG_DATA_DIRS="/usr/local/share:/usr/share"
desktop_files=""

#====================================================================
#                        FUNCTIONS
#====================================================================

look_in_mimeinfo_cache() {
	# look in mimeinfo.cache and get .desktop files
	for xdg_path in ${XDG_DATA_HOME//:/ } ${XDG_DATA_DIRS//:/ }
	do
		mimeinfo_cache="$xdg_path"/applications/mimeinfo.cache
		if ! [ -e "$mimeinfo_cache" ] ; then
			continue
		fi
		matches=$(grep "^${mimetype}=" "$mimeinfo_cache") #x-scheme-handler/magnet=transmission-gtk.desktop;
		if [ "$matches" ] ; then
			matches=${matches##*=}  # transmission-gtk.desktop;
			matches=${matches//;/ } # transmission-gtk.desktop
			for i in $matches ; do
				desktop_files="$desktop_files
$xdg_path/applications/${i}"
			done
		fi
		if [ "$desktop_files" ] ; then
			FRAME_APP_LABEL='Applications that list the file type (in mimeinfo.cache)'
		fi
	done
}

mime_info_get_all() {
	# all .desktop files listed in mieminfo.cache
	for xdg_path in ${XDG_DATA_HOME//:/ } ${XDG_DATA_DIRS//:/ }
	do
		xdg_dir="$xdg_path"/applications/
		mimeinfo_cache="$xdg_path"/applications/mimeinfo.cache
		[ -e "$mimeinfo_cache" ] || continue
		df1=$(sed "s%.*=%% ; /\[.*/d ; " $mimeinfo_cache | tr ';' '\n' | \
			grep desktop | sed "s%^%${xdg_dir}%" | sort -u)
		desktop_files="$desktop_files
$df1"
	done
	if [ "$desktop_files" ] ; then
		FRAME_APP_LABEL='Applications listed in mimeinfo.cache'
	fi
}

get_info_from_desktop_files() {
	# read info from .desktop files
	shopt -s extglob
	for one_file in ${desktop_files}
	do
		desktop_name=""
		desktop_icon=""
		desktop_exec=""
		desktop_nodisplay=""
		while IFS="=" read field desc
		do
			case $field in
				Name)
					desktop_name=${desc}
					;;
				Icon)
					desktop_icon=${desc}
					# Remove icon extension.
					# xpm png and svg are supported, but not paths.
					desktop_icon=${desktop_icon%%.*}
					desktop_icon=${desktop_icon##*/}
					;;
				Exec)
					desktop_exec=${desc}
					;;
				NoDisplay)
					desktop_nodisplay=${desc}
					if [ "$desktop_nodisplay" = "true" ] ; then
						break
					fi
					;;
			esac
		done < "${one_file}"

		if [ "$desktop_nodisplay" = "true" ] ; then
			continue # next file
		fi

		if [ "$desktop_name" != "" -a "$desktop_exec" != "" ]; then
			ENTRY_LIST="${ENTRY_LIST}${desktop_icon}|${desktop_name}|${desktop_exec}
	"
		fi
	done
	shopt -u extglob
	export ENTRY_LIST
}

show_dialog() {
	export MAIN_DIALOG='
<window title="Choose Application" image-name="/usr/share/pixmaps/Filesystem-filemanager.svg" resizable="false">
	<vbox>
		<hbox space-expand="true" space-fill="false">
			<text use-markup="true">
				<label>"Select app to open <b>'${mimetype}'</b> files"</label>
			</text>
		</hbox>
		<hbox>
			<frame '${FRAME_APP_LABEL}'>
				<tree headers-visible="false" column-visible ="1|0" exported-column="1">
					<variable>TREE</variable>
					<height>300</height>
					<width>200</width>
					<label>0 | 1 </label>
					<input icon-column="0">echo "$ENTRY_LIST"</input>
				</tree>
			</frame>
		</hbox>
		<hbox>
			<checkbox space-expand="true" space-fill="true">
				<label>'$(gettext 'Set selected application as the default action for this file type')'</label>
				<variable>CHK_SET_DEFAULT</variable>
			</checkbox>
		</hbox>
		<hbox space-expand="false" space-fill="true" homogeneous="true">
			'${BTN_MORE_APPS}'
			<button cancel></button>
			<button ok></button>
		</hbox>
	</vbox>
</window>
'
	res="$($GTKDIALOG --program=MAIN_DIALOG --center)"
	eval "$res"
	#echo "$res" > /tmp/zzzzz.1 #debug
	exec_command="$TREE"
	
	if [ "$EXIT" = "MOAR" ] ; then
		return 5
	fi

	if [ "$EXIT" = "OK" -a "$exec_command" != "" ]; then

		if [ "$CHK_SET_DEFAULT" = "true" ] ; then
			#mt=.${mimetype//\//_} # application/pet -> .application_pet
			#mtdir=$HOME/.config/rox.sourceforge.net/OpenWith/${mt}
			# > "${mtdir}/${exec_command##*/}"
			mtdir=$HOME/Choices/MIME-types
			mtfile=${mtdir}/${mimetype//\//_} # application/pet -> application_pet
			mkdir -p "$mtdir"
			echo '#!/bin/sh
exec '${exec_command}' "$@"' > "${mtfile}"
			chmod +x "${mtfile}"
		fi

		if [ "${exec_command}" != "${exec_command%\%f*}" ]; then
			# Support %f in desktop files.
			declare -a "exec_begin=(${exec_command%\%f*})"
			declare -a "exec_end=(${exec_command#*\%f})"
			exec "${exec_begin[@]}" "$filename" "${exec_end[@]}"

		elif [ "${exec_command}" != "${exec_command%\%F*}" ]; then
			# Support %F in desktop files.
			declare -a "exec_begin=(${exec_command%\%F*})"
			declare -a "exec_end=(${exec_command#*\%F})"
			exec "${exec_begin[@]}" "$filename" "${exec_end[@]}"

		else
			# Desktop files without %f or %F.
			declare -a "exec_array=(${exec_command})"
			exec "${exec_array[@]}" "$filename"
		fi

	fi
}

#====================================================================
#                            MAIN
#====================================================================

look_in_mimeinfo_cache
if [ "$desktop_files" ] ; then
	BTN_MORE_APPS='			<button space-expand="true" space-fill="false">
				<label>'$(gettext 'More applications...')'</label>
				<action>exit:MOAR</action>
			</button>'
else
	# no matches in mimeinfo.cache.. read all .desktop files in /usr/share
	BTN_MORE_APPS='			<text space-expand="true" space-fill="false"><label>"  "</label></text>
				<text space-expand="true" space-fill="false"><label>"  "</label></text>
				<text space-expand="true" space-fill="false"><label>"  "</label></text>'
	desktop_files="$(echo /usr/share/applications/*.desktop)"
	FRAME_APP_LABEL='Installed applications'
fi

get_info_from_desktop_files
show_dialog
if [ $? -eq 5 ] ; then #more apps
	BTN_MORE_APPS='			<text space-expand="true" space-fill="false"><label>"  "</label></text>
				<text space-expand="true" space-fill="false"><label>"  "</label></text>
				<text space-expand="true" space-fill="false"><label>"  "</label></text>'
	desktop_files="$(echo /usr/share/applications/*.desktop)"
	FRAME_APP_LABEL='Installed applications'
	get_info_from_desktop_files
	show_dialog
fi

### END ###