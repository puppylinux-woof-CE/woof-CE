ROX-Filer source package does not have .pot file!

However, it does have lots of .po files, ex de.po.

However, Puppy Forum member LaRioja has done some work on de.po, improved it:
http://www.murga-linux.com/puppy/viewtopic.php?t=76281

However, i need a .pot file, to put here:
/usr/share/doc/nls/ROX-Filer/ROX-Filer.pot

...MoManager will find this and a translator can then create a .po hence .mo file.

I found some info how to convert po to pot:
http://www.commandlinefu.com/commands/view/10042/empty-a-gettext-po-file-or-po2pot

This line does it (plus a bit of editing by me):

# msgfilter --keep-header  -i ROX-Filer.po  -o ROX-Filer.pot  awk -e '{}'

Extract from the User Manual is below. It states that src/messages.pot exists in source,
but it doesn't.
The gist of the docs is that a .mo file has to be in a special location, for example:
/usr/local/apps/ROX-Filer/Messages/de/LC_MESSAGES/ROX-Filer.mo

The docs also state that /usr/local/apps/ROX-Filer/Options.xml has to be edited:

"so that your language is listed, restart the filer and select it from the Options box
       (see the <xref linkend="LANG"/> section)"

Barry Kauler
March 7, 2012

INSTRUCTIONS FROM ROX-FILER USER MANUAL
---------------------------------------

 <chapter id="i18n">
  <title>Internationalisation</title>
  <para>

  </para>

  <sect1>
   <title><anchor id="LANG" xreflabel="Translations"/>
    Selecting a translation
   </title>
   <para>

    <application>ROX-Filer</application> is able to translate many of its messages,
    provided suitable translation files are provided:

    <orderedlist>
     <listitem><para>Open the Options box from the menu,</para></listitem>
     <listitem><para>Select a language from the list,</para></listitem>
     <listitem><para>Click on <guibutton>OK</guibutton> and restart the filer
       for the new setting to take full effect.</para></listitem>
    </orderedlist>

   </para>
  </sect1>

  <sect1>
   <title>Creating a new translation</title>
   <para>

    <orderedlist>
     <listitem><para>Go into the <filename>src/po</filename> directory and create
       the file <filename>src/messages.pot</filename>:

       <screen>
        $ cd ROX-Filer/src/po
        $ ./update-po</screen>

     </para></listitem>

     <listitem><para>Copy the file into the <filename>src/po</filename>
       directory as <filename>&lt;name&gt;.po</filename>. Eg, if your
       language is referred to as `ml' (`my language'):

       <screen>$ cp ../messages.pot ml.po</screen>
     </para></listitem>

     <listitem><para>Load the copy into a text editor.</para></listitem>

     <listitem><para>Fill in the translations, which are all blank to start with.
     </para></listitem>

     <listitem><para>Run the <filename>make-mo</filename> script to create the
       binary file which <application>ROX-Filer</application> can use.
       You will need the GNU gettext package for this.

       <screen>
        $ cd ROX-Filer/src/po
        $ ./make-mo ml
        Created file ../../Messages/ml.gmo OK</screen>
     </para></listitem>

     <listitem><para>Edit <filename>ROX-Filer/Options.xml</filename> so that
       your language is listed, restart the filer and select it from the Options box
       (see the <xref linkend="LANG"/> section).
     </para></listitem>

     <listitem><para>Submit the <filename>.po</filename> file to the ROX
     patch tracker so that we can include it in future releases of the filer.
     </para></listitem>

    </orderedlist>
   </para>
  </sect1>

  <sect1>
   <title>Updating an existing translation</title>
   <para>

    <orderedlist>
     <listitem><para>Go into the directory containing the <filename>.po</filename>
       files and run the <filename>update-po</filename> script.
       This checks the source code for new and changed strings and updates all
       the translation files.

       <screen>
        $ cd ROX-Filer/src/po
        $ ./update-po</screen>
     </para></listitem>

     <listitem><para>Edit the file by hand as before, filling in the new blanks
       and updating out-of-date translations.
       Look out for <computeroutput>fuzzy</computeroutput> entries where
       <command>update-po</command> has made a guess; check it's correct and
       remove the <computeroutput>fuzzy</computeroutput> line.
     </para></listitem>

     <listitem><para>Run <command>make-mo</command> as before.</para></listitem>

     <listitem><para>Submit the updated file to us.</para></listitem>

    </orderedlist>

    See the <command>gettext</command> info page for more instructions on creating
    a translation.

   </para>
  </sect1>
 </chapter>
 
 ROX-FILER SCRIPTS
 -----------------
 
 The script src/po/make-mo:
 
 #!/bin/sh

if [ "$#" != 1 ]; then
	cat << HERE
Usage: 'make-mo <LANG>'
Eg:    'make-mo fr' to compile the French translation, fr.po, ready for use.
HERE
	exit 1
fi

OUT_DIR=../../Messages
LOCALE_DIR="$OUT_DIR/$1/LC_MESSAGES"
OUT="$LOCALE_DIR/ROX-Filer.mo"
mkdir -p "$LOCALE_DIR"

# This code converts to UTF-8 format. Needed by Gtk+-2.0 at
# least, and may help with other versions.
charset=`grep "charset=" $1.po | head -1 | sed 's/^.*charset=\(.*\)\\\n.*/\1/'`
echo Using charset \'$charset\'
iconv -f $charset -t utf-8 $1.po | \
	sed 's/; charset=\(.*\)\\n"/; charset=utf-8\\n"/' | \
	msgfmt --statistics - -o $OUT && echo Created file $OUT OK


