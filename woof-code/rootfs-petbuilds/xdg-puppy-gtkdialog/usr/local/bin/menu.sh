#!/bin/sh

EDGE=${EDGE:-topleft}

###### main dialog
export M='<window  border-width="0" edge="'$EDGE'">
	<hbox space-expand="true" space-fill="false">
		<menubar has-focus="true">
			<menu label="Menu" image-name="/usr/share/pixmaps/puppy/puppy.svg" tooltip-text="Press X to close">
'$(. /etc/xdg/gtkdialog/gtkdialog_template)'
				<height>20</height>
			</menu>
			<menu label="Places" image-name="/usr/share/pixmaps/puppy/directory.svg" tooltip-text="Press X to close">
				<menuitem label="'$(gettext 'Home')'" image-name="/usr/local/lib/X11/pixmaps/home48.png">
					<height>20</height>
					<action>defaultfilemanager $HOME &</action>
					<action>exit:Quit</action>				
				</menuitem>
				<menuitem label="'$(gettext 'System')'" image-name="/usr/local/lib/X11/pixmaps/pc48.png">
					<height>20</height>
					<action>defaultfilemanager / &</action>
					<action>exit:Quit</action>				
				</menuitem>
				<menuitem label="'$(gettext 'Network')'" image-name="/usr/local/lib/X11/pixmaps/connect48.png">
					<height>20</height>
					<action>defaultfilemanager $HOME/network &</action>
					<action>exit:Quit</action>	
				</menuitem>
				<menuitemseparator>
				</menuitemseparator>
				'$(/usr/local/bin/gtkdialog_menu_build_places_drives)'
				<menuitemseparator>
				</menuitemseparator>
				<menuitem label="'$(gettext 'Web')'" image-name="/usr/local/lib/X11/pixmaps/www48.png">
					<height>20</height>
					<action>defaultbrowser &</action>
					<action>exit:Quit</action>
				</menuitem>
				<menuitem label="'$(gettext 'Help')'" image-name="/usr/local/lib/X11/pixmaps/help48.png">
					<height>20</height>
					<action>/usr/sbin/puppyhelp &</action>
					<action>exit:Quit</action>
				</menuitem>
				<height>20</height>			
			</menu>
		</menubar>
		<button tooltip-text="Close Menu" relief="2">
			<input file>/usr/share/pixmaps/puppy/close.svg</input>
			<height>12</height>
			<label>""</label>
			<action type="exit">exit</action>
		</button>
	</hbox>
</window>'
case $1 in
d) echo "$M" > /tmp/dialog_dump.xml ;;
*)gtkdialog -p M 2>/dev/null ;;
esac
