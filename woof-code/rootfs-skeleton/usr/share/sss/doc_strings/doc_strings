[general]
#this is different from the other SSS domains, they have simple sed expressions to translate
#blocks of english text within a file -- XML, script, configuration, etc.
#however, we do have the situation, mostly documentation files, where we need to translate
#the entire file, and create a translated copy. For example, /usr/local/petget/help.htm is a
#English help file for the Puppy Package Manager. The scripts ui_Classic and ui_Ziggy will
#recognise a translated file if it exists, for example /usr/local/petget/help-de.htm.
#however, if translated filename is same as original en filename, then former replaces latter.
#Note, files with "-raw" are created by rootfs-skeleton/pinstall.sh in Woof.
#variables SSS_HANDLER_EDITOR, SSS_TRANSLATION_RULE, SSS_HANDLER_VIEWER must be specified, SSS_POST_EXEC is optional.
#THERE IS NOTHING TO EDIT IN THIS FILE -- MoManager reads this file and does all that is needed.
#I REPEAT, PLEASE DO NOT CHANGE THIS FILE, use MoManager.

[_usr_local_petget_help.htm]
#the English help file is /usr/local/petget/help.htm.
#note, /usr/local/petget/ui_Classic and ui_Ziggy look for a translated file, if not exist fall back to help.htm.
#this identifies the name and location of the translated file, ex: the German translation would be file /usr/local/petget/help-de.htm...
SSS_TRANSLATION_RULE='/usr/local/petget/help-SSSLANG1MARKER.htm'
#this identifies the editor to be used...
SSS_HANDLER_EDITOR='defaulthtmleditor'
#for just viewing the file...
SSS_HANDLER_VIEWER='basichtmlviewer'

[#usr#share#doc#cups_shell.htm]
#the English help file for script /usr/sbin/cups_shell is /usr/share/doc/cups_shell.htm
SSS_TRANSLATION_RULE='/usr/share/doc/cups_shell-SSSLANG1MARKER.htm'
SSS_HANDLER_EDITOR='defaulthtmleditor'
SSS_HANDLER_VIEWER='basichtmlviewer'

[_usr_share_doc_HOWTO-fattenpuppy.htm]
#when the translation file is same name as the en file, then former replaces latter.
SSS_TRANSLATION_RULE='/usr/share/doc/HOWTO-fattenpuppy.htm'
SSS_HANDLER_EDITOR='defaulthtmleditor'
SSS_HANDLER_VIEWER='basichtmlviewer'

[_usr_share_doc_HOWTO-internationalization.htm]
SSS_TRANSLATION_RULE='/usr/share/doc/HOWTO-internationalization.htm'
SSS_HANDLER_EDITOR='defaulthtmleditor'
SSS_HANDLER_VIEWER='basichtmlviewer'

[#usr#share#doc#HOWTO_Internet.htm]
SSS_TRANSLATION_RULE='/usr/share/doc/HOWTO_Internet.htm'
SSS_HANDLER_EDITOR='defaulthtmleditor'
SSS_HANDLER_VIEWER='basichtmlviewer'

[_usr_share_doc_HOWTO-microsoft.htm]
SSS_TRANSLATION_RULE='/usr/share/doc/HOWTO-microsoft.htm'
SSS_HANDLER_EDITOR='defaulthtmleditor'
SSS_HANDLER_VIEWER='basichtmlviewer'

[#usr#share#doc#HOWTO_modem.htm]
SSS_TRANSLATION_RULE='/usr/share/doc/HOWTO_modem.htm'
SSS_HANDLER_EDITOR='defaulthtmleditor'
SSS_HANDLER_VIEWER='basichtmlviewer'

[_usr_share_doc_HOWTO-multimedia.htm]
SSS_TRANSLATION_RULE='/usr/share/doc/HOWTO-multimedia.htm'
SSS_HANDLER_EDITOR='defaulthtmleditor'
SSS_HANDLER_VIEWER='basichtmlviewer'

[_usr_share_doc_HOWTO-regexps.htm]
SSS_TRANSLATION_RULE='/usr/share/doc/HOWTO-regexps.htm'
SSS_HANDLER_EDITOR='defaulthtmleditor'
SSS_HANDLER_VIEWER='basichtmlviewer'

[_usr_share_doc_index.html.bottom-raw]
SSS_TRANSLATION_RULE='/usr/share/doc/index.html.bottom-raw'
SSS_HANDLER_EDITOR='defaulttexteditor'
SSS_HANDLER_VIEWER='defaulttextviewer'
#MoManager will run this after translation edit...
#this will regenerate index.html.bottom and index.html...
SSS_POST_EXEC='/usr/sbin/indexgen.sh'

[_usr_share_doc_index.html.top-raw]
SSS_TRANSLATION_RULE='/usr/share/doc/index.html.top-raw'
SSS_HANDLER_EDITOR='defaulttexteditor'
SSS_HANDLER_VIEWER='defaulttextviewer'
#this will regenerate index.html.top and index.html...
SSS_POST_EXEC='/usr/sbin/indexgen.sh'

[_usr_share_doc_home-raw.htm]
SSS_TRANSLATION_RULE='/usr/share/doc/home-raw.htm'
SSS_HANDLER_EDITOR='defaulthtmleditor'
SSS_HANDLER_VIEWER='basichtmlviewer'
#this will regenerate home.htm...
SSS_POST_EXEC='/usr/sbin/indexgen.sh'

[_usr_share_doc_Pudd.htm]
SSS_TRANSLATION_RULE='/usr/share/doc/Pudd.htm'
SSS_HANDLER_EDITOR='defaulthtmleditor'
SSS_HANDLER_VIEWER='basichtmlviewer'

[_usr_share_doc_samba-printing.htm]
SSS_TRANSLATION_RULE='/usr/share/doc/samba-printing.htm'
SSS_HANDLER_EDITOR='defaulthtmleditor'
SSS_HANDLER_VIEWER='basichtmlviewer'

[_usr_share_doc_yaf-splash-new.htm]
SSS_TRANSLATION_RULE='/usr/share/doc/yaf-splash-new.htm'
SSS_HANDLER_EDITOR='defaulthtmleditor'
SSS_HANDLER_VIEWER='basichtmlviewer'

[_usr_local_apps_Trash_Help_help.html]
SSS_TRANSLATION_RULE='/usr/local/apps/Trash/Help/help.html'
SSS_HANDLER_EDITOR='defaulthtmleditor'
SSS_HANDLER_VIEWER='basichtmlviewer'

[_usr_share_doc_root.htm]
SSS_TRANSLATION_RULE='/usr/share/doc/root.htm'
SSS_HANDLER_EDITOR='defaulthtmleditor'
SSS_HANDLER_VIEWER='basichtmlviewer'

[_usr_share_doc_legal_puppy.htm]
SSS_TRANSLATION_RULE='/usr/share/doc/legal/puppy.htm'
SSS_HANDLER_EDITOR='defaulthtmleditor'
SSS_HANDLER_VIEWER='basichtmlviewer'

