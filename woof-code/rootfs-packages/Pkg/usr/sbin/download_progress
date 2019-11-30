#!/bin/bash
# original script by technosaurus
#18012012: fixed to work on akita: no busybox, wget -c, added some translations, error checking, etc
 
#usage, cli options
{ 
	[ "$1" = "" ] && echo "Usage: $(basename $0) URL [output file]" && exit 1
if [ "$2" != "" ];then # add output file or dir, if given
	OUTPUTFILE="-O$2"
else 
	OUTPUTFILE=''
fi
export OUTPUTFILE
}
# i18n, translations
{
[ $myLANG ] || myLANG=${LANGUAGE%% *}
[ $myLANG ] || myLANG=${LANG%_*}
case $myLANG in
   de*)
		Loc_downloading_file="Download der Datei"
		Loc_download_progess="Download-Fortschritt"
		Loc_files_remaining="Dateien übrig"
		Loc_current_file_is="Aktuelle Datei ist"
      ;; 
  es*)
		Loc_downloading_file="Descargar el fichero"
		Loc_download_progess="El progreso de descarga"
		Loc_files_remaining="archivos restantes"
		Loc_current_file_is="Archivo actual es"
      ;; 
  fr*)
		Loc_downloading_file="Fichiers en cours de téléchargement"
		Loc_download_progess="Progression du téléchargement en cours"
		Loc_files_remaining="Fichier(s) restant(s)"
		Loc_current_file_is="Le fichier actuellement en téléchargement est"
      ;; 
  nl*)
		Loc_downloading_file="Downloaden bestand"
		Loc_download_progess="Download vooruitgang"
		Loc_files_remaining="bestanden over"
		Loc_current_file_is="De huidige bestand is"
      ;; 
  ru*)
		Loc_downloading_file="Загрузка файла"
		Loc_download_progess="Прогресс загрузки"
		Loc_files_remaining="файл. осталось"
		Loc_current_file_is="Текущий файл"
      ;; 
	*);;
esac
}

download_progress(){ #pass a file as $1 to download with a GUI progress bar
while ([ $# -gt 0 ]) do
   LANG=C # should avoid wget returning weird values
   wget "$OUTPUTFILE" -4 -c "$1" 2>&1 | while read LINE; do
      case $LINE in
         *%*)LINE=${LINE##*..};echo ${LINE%%%*};;
      esac
   done |Xdialog --wm-class "button" --title "${Loc_downloading_file:-Downloading File}" --gauge "${Loc_download_progess:-Download progress} ($# ${Loc_files_remaining:-files remaining}.)
${Loc_current_file_is:-Current file is}:
$1" 0 0
   shift
done
}

download_progress "${1}"
