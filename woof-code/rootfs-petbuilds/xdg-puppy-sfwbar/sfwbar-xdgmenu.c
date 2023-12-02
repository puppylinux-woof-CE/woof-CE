/**
 * sfwbar-xdgmenu
 *
 * This command line application generates an OpenBox menu XML segment based on
 * an Xdg menu structure. Adapted for sfwbar <https://github.com/LBCrion/sfwbar>
 *
 * Usage: sfwbar-xdgmenu <Xdg menu file>
 *
 * Copyright (C) Nathan Fisher <nfisher@grafpup.com>
 * Copyright (C) 2008 Siegfried-A. Gevatter <rainct@ubuntu.com>
 * Copyright (C) 2011 Kévin Joly <joly.kevin25@gmail.com>
 * Copyright (C) 2016 James Budiono <jamesbond3142@gmail.com>
 * Copyright (C) 2023 Michael Amadio <01micko@gmail.com>
 * Originally based upon code by Raul Suarez <rarsa@yahoo.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Dependencies:
 *   gnome-menus
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
static void process_directory(GMenuTreeDirectory *directory);
static void process_entry(GMenuTreeEntry *entry);
static void process_separator(GMenuTreeSeparator *entry);

/*=============================================================================
 * Main Function
 */
int main (int argc, char **argv)
{
    if ((argc < 2)
      || (strcmp (argv[1], "-h") == 0)
      || (strcmp (argv[1], "-help") == 0)
      || (strcmp (argv[1], "--help") == 0))
  {
    show_help();
    return (1);
  }

    GMenuTree *menuTree = gmenu_tree_lookup (argv[1],  GMENU_TREE_FLAGS_NONE );

    GMenuTreeDirectory *rootDirectory = gmenu_tree_get_root_directory(menuTree);

    process_directory(rootDirectory);

    gmenu_tree_item_unref (rootDirectory);

    return 0;
}

/*=============================================================================
 * Shows usage parameters
 */
void show_help()
{
    g_printf ("Creates a sfwbar menu from an Xdg menu structure.\n");
    g_printf ("\n");
    g_printf ("Usage:\n");
    g_printf ("  sfwbar-xdgmenu <Xdg menu file>\n");
    g_printf ("\n");
    g_printf ("For example:\n");
    g_printf ("  sfwbar-xdgmenu \"/etc/xdg/menus/applications.menu\"\n\n");
}

/*=============================================================================
 * This function processes a directory entry and all it's child nodes
 */
void process_directory(GMenuTreeDirectory *directory)
{
    int hasSeparator = 0; int first = 1; int hadSeparator = 0;
    GSList *entryList = gmenu_tree_directory_get_contents (directory);
    GSList *l;

    for (l = entryList; l; l = l->next)
    {
        GMenuTreeItem *item = l->data;

        if (gmenu_tree_item_get_type (GMENU_TREE_ITEM(item)) == GMENU_TREE_ITEM_ENTRY)
        {
            goto start;
        }
    }

    return;

start:
   g_printf(
		  "\tsubmenu(\" %s%%/usr/local/lib/X11/pixmaps/%s\",\"%s\") {\n",
		  gmenu_tree_directory_get_name(directory),
		  gmenu_tree_directory_get_icon(directory),
		  gmenu_tree_directory_get_name(directory));

    GMenuTreeItemType entryType;
    GMenuTreeEntry *entry;
    const char *path;
    GHashTable *history = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, NULL);

     for (l = entryList; l; l = l->next)
    {
        GMenuTreeItem *item = l->data;

        entryType = gmenu_tree_item_get_type (GMENU_TREE_ITEM(item));

        switch (entryType)
        {
            case GMENU_TREE_ITEM_DIRECTORY:
				if (hasSeparator)
				{
					if (!first && !hadSeparator)
					{
						process_separator(GMENU_TREE_SEPARATOR(item));
						hadSeparator = 1;
					}
 				hasSeparator = 0;
 
				}
				process_directory(GMENU_TREE_DIRECTORY(item));
				first = 0;
				hadSeparator = 0;
                break;
            case GMENU_TREE_ITEM_ENTRY:
                entry = GMENU_TREE_ENTRY(item);
                path = gmenu_tree_entry_get_desktop_file_path(entry);
                if (g_hash_table_lookup(history, path))
                {
                    continue;
                }
				if (hasSeparator)
				{
					if (!first && !hadSeparator)
	 				{
	 					process_separator(GMENU_TREE_SEPARATOR(item));
						hadSeparator = 1;
	 				}
					hasSeparator = 0;
				}
                process_entry(entry);
                g_hash_table_insert(history, g_strdup(path), (gpointer)1);
				first = 0;
				hadSeparator = 0;
                break;
			case GMENU_TREE_ITEM_SEPARATOR:
				hasSeparator = 1;
				break;
        }

        gmenu_tree_item_unref (item);
    }

    g_hash_table_destroy(history);
    g_printf("\t}\n");
    g_slist_free (entryList);
}

/*=============================================================================
 * This function adds an application entry
 */
void process_entry(GMenuTreeEntry *entry)
{
    char *name = g_strdup (gmenu_tree_entry_get_name(entry));
    char *exec = g_strdup (gmenu_tree_entry_get_exec(entry));
    char *icon = g_strdup (gmenu_tree_entry_get_icon(entry));
    char *cmd = exec;
    char *iconmod = icon;
    int i;
    size_t len;

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

    if (icon[0] != '/' && (len = strlen(icon)) > 4)
    {
        if (icon[len - 4] == '.')
        {
            iconmod = g_strndup(icon, len - 4);
        }
    }

    g_printf("\t\titem(\" %s%%%s\",Exec \"%s\")\n", g_strjoinv("&amp;", g_strsplit(name, "&" ,0)), iconmod, cmd);

    g_free(name);
    g_free(exec);
    if (cmd != exec)
    {
        free(cmd);
    }
    if (iconmod != icon)
    {
        free(iconmod);
    }
}

/*=============================================================================
 * This function adds a separator
 */
void
process_separator(GMenuTreeSeparator *entry)
{

  g_printf("\t\tseparator\n");
}
/*=============================================================================
 */
