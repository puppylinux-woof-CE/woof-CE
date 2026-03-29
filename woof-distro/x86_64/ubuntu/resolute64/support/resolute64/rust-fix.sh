cd usr/bin
list=`ls *-FULL | sed 's/-FULL//g'`

for ii in $list
do
  case $ii in
    logger|more|mount|ps|su|umount) continue ;;
  esac
  mv $ii-FULL ../lib/cargo/bin/coreutils/$ii
  echo "exec /lib/cargo/bin/coreutils/$ii \"\$@\"" > $ii-FULL
  chmod 755 $ii-FULL
done
cd ../../
