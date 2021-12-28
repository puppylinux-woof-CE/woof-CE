/**
 * synopsis: Generates an gtkdialog menu xml segment based on an XDG menu structure
 * purpose: The purpose of this utility is to keep the new gtkdialog menu
 *          synchronized with the XDG configuration
 * usage: gtkdialog-xdgmenu <xdgMenuFile>
 * author: Raul Suarez (rarsa at yahoo dot com)
 * Licence: GPL
 *
 * ammended: 01micko for gtkdialog
 * 
 * Dependencies:
 *   gnome-menus 2.12
 *   glib
 */

#include <string.h>
#include <glib.h>
#include <glib/gprintf.h>
#include <gnome-menus/gmenu-tree.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>


/*=============================================================================
 * Declarations
 */
static void show_help();
static void process_directory(GMenuTreeDirectory *directory, char *menheight);
static void process_entry(GMenuTreeEntry *entry, char *menheight);
static void process_separator(GMenuTreeSeparator *entry);
char *menheight;
static char *find_icon(char *icon);

/*=============================================================================
 * Main Function
 */
int
main (int argc, char **argv)
{

  if ((argc != 2)
      || (strcmp (argv[1], "-h") == 0)
      || (strcmp (argv[1], "-help") == 0)
      || (strcmp (argv[1], "--help") == 0))
  {
    show_help();
    return (1);
  }
  if ((argc == 3))
  {
	  if (strcmp (argv[2], "24") == 0)
	  { 
		  menheight = "24";
	  }
	  else if (strcmp (argv[2], "32") == 0)
	  { 
		  menheight = "32";
	  }
	  else if (strcmp (argv[2], "40") == 0)
	  { 
		  menheight = "40";
	  }
	  else if (strcmp (argv[2], "48") == 0)
	  { 
		  menheight = "48";
	  }
	  else
	  {
		  show_help();
		  return (1);
	  }
  }
  else
  {
	  menheight = "20";
  }

  GMenuTree *menuTree = gmenu_tree_lookup (argv[1],  GMENU_TREE_FLAGS_NONE );

  GMenuTreeDirectory *rootDirectory = gmenu_tree_get_root_directory(menuTree);

  process_directory(rootDirectory, menheight);

  gmenu_tree_item_unref (rootDirectory);

  return 0;

}

/*=============================================================================
 * Shows usage parameters
 */
void
show_help()
{
  printf ("Creates a gtkdialog menu from an XDG menu structure.\n");
  printf ("Usage:\n");
  printf ("  gtkdialog-xdgmenu xdgmenufile\n");
  printf ("\n");
  printf ("  xdgmenufile: Fully qualified path to the XDG menu file. This is a mandatory parameter\n");
  printf ("\n");
  printf ("For example:\n");
  printf ("  gtkdialog-xdgmenu \"/etc/xdg/menus/applications.menu\"\n\n");
}

/*=============================================================================
 * This function processes a directory entry and all it's child nodes
 */
void
process_directory(GMenuTreeDirectory *directory, char *menheight)
{
	int hasSeparator = 0;

  if (g_strrstr(gmenu_tree_directory_get_name(directory), "Sub")) {
	  goto out;
  }
  char *icon = find_icon((char*)gmenu_tree_directory_get_icon(directory));
  g_printf("<menu label=\"%s\" image-name=\"%s\">\n",
            gmenu_tree_directory_get_name(directory),
            icon);

  GMenuTreeItemType entryType;

  GSList *entryList = gmenu_tree_directory_get_contents (directory);

  GSList *l;

  for (l = entryList; l; l = l->next)
  {

    GMenuTreeItem *item = l->data;

    entryType = gmenu_tree_item_get_type (GMENU_TREE_ITEM(item));

	switch (entryType)
	{
		case GMENU_TREE_ITEM_DIRECTORY:
		  if (hasSeparator)
		  {
				process_separator(GMENU_TREE_SEPARATOR(item));
				hasSeparator = 0;
		  }
			process_directory(GMENU_TREE_DIRECTORY(item), menheight);
			break;
		case GMENU_TREE_ITEM_ENTRY:
		  if (hasSeparator)
		  {
				process_separator(GMENU_TREE_SEPARATOR(item));
				hasSeparator = 0;
		  }
			process_entry(GMENU_TREE_ENTRY(item), menheight);
			break;
		case GMENU_TREE_ITEM_SEPARATOR:
			hasSeparator = 1;
			break;
	}

    gmenu_tree_item_unref (item);

  }
  g_printf("\t<height>%s</height>\n</menu>\n", menheight);
  g_slist_free (entryList);
out:
}

/*=============================================================================
 * This function adds an application entry
 */
void
process_entry(GMenuTreeEntry *entry, char *menheight)
{
    char *name = g_strdup (gmenu_tree_entry_get_name(entry));
    char *exec = g_strdup (gmenu_tree_entry_get_exec(entry));
    char *cmd = exec;
    int i;

    for (i = 0; i < strlen(exec) - 1; i++) {
        if (exec[i] == '%')
        {
            switch (exec[i+1]) {
                case 'f': case 'F':
                case 'u': case 'U':
                case 'd': case 'D':
                case 'n': case 'N':
                case 'i': case 'c': case 'k': case 'v': case 'm':
                    exec[i] = ' ';
                    exec[i+1] = ' ';
                    i++;
                    break;
            }
        }
    }

    if (gmenu_tree_entry_get_launch_in_terminal(entry))
    {
        cmd = g_strdup_printf("defaultterminal -e sh -c '%s'", exec);
    }

  char *icon = find_icon((char*)gmenu_tree_entry_get_icon(entry));
  
  g_printf("<menuitem label=\"%s\" image-name=\"%s\">\n\t<height>%s</height>\n\t<action>%s &</action>\n\t<action>exit:Quit</action>\n</menuitem>\n",
            g_strjoinv("&amp;", g_strsplit(name,"&",0)),
            icon,
            menheight,
            cmd);

    g_free(name);
    g_free(exec);
    if (cmd != exec)
    {
        free(cmd);
    }
}

/*=============================================================================
 * This function adds a separator
 */
void
process_separator(GMenuTreeSeparator *entry)
{

  g_printf("\t<menuitemseparator>\n\t</menuitemseparator>\n");
}

/*=============================================================================
 */
/*=============================================================================
 * Given an icon name (or path), this function returns the full path
 * to the icon image file, if it can be found. If not, "" is returned.
 * Must free the string with with g_free.
 */
char *find_icon(char *icon)
{	
	char *tmp;
	struct stat sb;
	char *icon_extensions[] = { ".png", ".xpm", ".svg", "", 0 }; // supported icon types
	char *icon_dirs[] = {
		"/usr/share/pixmaps",
		"/usr/share/pixmaps/puppy",
		"/usr/share/icons",
		"/usr/local/lib/X11/pixmaps",
		"/usr/share/icons/hicolor/48x48/apps",
		0
	};
	char **dir, **ext;	
	int icon_sizes[] = { 48, 32, 24, 16, 0 }; // GTK icon sizes
	int *size;

	// no icon
	if (!icon) return g_strdup("");
	
	// if full path already given and it exists, return it
	if (stat(icon,&sb)==0 && !S_ISDIR(sb.st_mode)) return g_strdup(icon);
	
	// drop all before search		
	if ((tmp = strrchr(icon, '/'))) icon = tmp++;
	
	// find in pixmap dirs
	for (dir = icon_dirs; *dir; dir++) 
	{
		for (ext = icon_extensions; *ext; ext++) 
		{
			tmp = g_strdup_printf("%s/%s%s",*dir, icon, *ext);
			//g_print("%s\n",tmp);
			if (stat(tmp,&sb)==0 && !S_ISDIR(sb.st_mode)) return tmp;
			g_free(tmp);
		}
	}
		
	return g_strdup("");
} 

/*=============================================================================
 */
