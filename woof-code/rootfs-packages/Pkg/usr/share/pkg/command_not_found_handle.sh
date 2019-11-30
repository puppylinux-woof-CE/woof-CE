# BASH 4 enables a `command_not_found_handle` function
# that is executed when a command is not found, which
# we can overwrite.

rm /tmp/command_not_found_lock_file &>/dev/null

if [ "${BASH_VERSINFO[0]}" = '4' ];then

  cat=$(which cat)
  grep=$(which grep)
  cut=$(which cut)

  # if user gives a command not installed in $PATH, show a
  # custom 'not found' message.
  function command_not_found_handle {

    # prevent weird error which causes a loop (make clean, lsb_release, setopt)
    # and only allow one instance (lock file)
    if [ "$1" = "" ] || [ "$1" = "lsb_release" ] || [ "$1" = "setopt" ] || [ -f /tmp/command_not_found_lock_file ]
    then
      return 1
    fi

    # exit if Pkg not installed and ready
    if [ ! -d /tmp/pkg ] || [ ! -x /usr/sbin/pkg ]
    then
      echo "Error: command '${1}' not found." >&2
      return 1
    fi

    touch /tmp/command_not_found_lock_file

    # $1 is the command given
    local cmd=$1

    # $@ is the cmd and all options
    # so use shift so $@ doesn't
    # include $cmd
    shift
    #local args="$*"
    local pkgname_example=''

    # if we are on an Ubuntu or Debian based Puppy Linux,
    # then we should first look for 'gimp_1.2.3' (underscore),
    # else we want 'gimp-1.2.3' (with dash, not underscore)

    # assume not debian/ubuntu based puppy (for now)
    local sep1='-' sep2='_'

    # Check puppy version.. if Debian/Ubuntu based, then swap
    # the separators, so we get the correct packages listed
    if [ -f /etc/DISTRO_SPECS ] && [ -z "$DISTRO_BINARY_COMPAT" ]
    then
      . /etc/DISTRO_SPECS
    fi

    case $DISTRO_BINARY_COMPAT in
      ubuntu|trisquel|debian|devuan)
        sep1='_'
        sep2='-'
        ;;
    esac

    # get parent command, exit if it is 'make', prevent weird errors
    /bin/ps -o comm= $PPID | grep 'make' && return 1

    # remove temp file
    rm -f /tmp/pkg/missing_cmd_packages &>/dev/null

    # we will look for package names matching
    # the given command (${cmd}_ on ubuntu/debian pups, else ${cmd}-)
    # and return the package name
    /usr/sbin/pkg --names-all "${cmd}${sep1}" 2>/dev/null | $grep -vE '\-help\-|_DEV|_DOC|_NLS|\-dev|\-doc|\-nls|\-locale|\-data' > /tmp/pkg/missing_cmd_packages

    # if Pkg found nothing, search for $cmd-
    if [ ! -s /tmp/pkg/missing_cmd_packages ]
    then
      /usr/sbin/pkg --names-all "${cmd}${sep2}" 2>/dev/null | $grep -vE '\-help\-|_DEV|_DOC|_NLS|\-dev|\-doc|\-nls|\-locale|\-data' > /tmp/pkg/missing_cmd_packages
    fi

    # if Pkg still found nothing, search for $cmd
    if [ ! -s /tmp/pkg/missing_cmd_packages ]
    then
      /usr/sbin/pkg --names-all "${cmd}" 2>/dev/null | $grep -vE '\-help\-|_DEV|_DOC|_NLS|\-dev|\-doc|\-nls|\-locale|\-data' > /tmp/pkg/missing_cmd_packages
    fi

    if [ -s /tmp/pkg/missing_cmd_packages ]
    then
      # if $pkgname is only one line, we got 1 package, so
      # lets add that package name into the example, else
      # it will show '<package-name>'
      wc -l /tmp/pkg/missing_cmd_packages | $grep -q '^1 ' && pkgname_example=`$cat /tmp/pkg/missing_cmd_packages | $cut -f1 -d$sep1`

      # If Pkg suggested some packages, let's print a custom
      # message, listing those packages
      echo "The '$cmd' command might be available in the following packages:" >&2
      echo >&2
      $cat /tmp/pkg/missing_cmd_packages >&2
      echo >&2
      echo "You can install it with the following command:" >&2
      echo "  pkg add ${pkgname_example:-<package-name>}"   >&2

      # also any list matching local package files
      local_files="$(ls /root/pkg/ 2>/dev/null | grep "^$cmd")"
      if [ "$local_files" != "" ];then
        echo >&2
        echo "These local packages may also be a match: "   >&2
        echo >&2
        echo "$local_files" | sed 's/^/  /g'                >&2
      fi
    else
      # Pkg found no packages, show standard message
      echo "Error: command '${cmd}' not found." >&2
    fi

    rm /tmp/command_not_found_lock_file &>/dev/null
    return 127
  }
fi
