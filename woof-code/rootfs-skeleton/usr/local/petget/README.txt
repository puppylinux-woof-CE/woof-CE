'pkg_chooser.sh' is the script that is first started when a GUI interface is required.
'petget' is a commandline pkg install and uninstall script.

Calling hierarchy
-----------------

pkg_chooser.sh
    finduserinstalledpkgs.sh
    filterpkgs.sh
    findnames.sh
    installpreview.sh
        findmissingpkgs.sh
        dependencies.sh
        downloadpkgs.sh
            installpkg.sh
            testurls.sh
            verifypkg.sh
        fetchinfo.sh
    removepreview.sh
    configure.sh
        0setup <<<copied in by Woof

petget
    removepreview.sh
    installpkg.sh
    
    
