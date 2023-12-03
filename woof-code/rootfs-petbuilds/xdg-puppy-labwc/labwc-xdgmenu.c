/**
 * labwc-xdgmenu
 *
 * This command line application generates an OpenBox menu XML segment based on
 * an Xdg menu structure. Adapted for labwc <https://github.com/johanmalm/labwc>
 *
 * Usage: labwc-xdgmenu <Xdg menu file>
 *
 * Copyright (C) Nathan Fisher <nfisher@grafpup.com>
 * Copyright (C) 2008 Siegfried-A. Gevatter <rainct@ubuntu.com>
 * Copyright (C) 2011 Kévin Joly <joly.kevin25@gmail.com>
 * Copyright (C) 2016 James Budiono <jamesbond3142@gmail.com>
 * Copyright (C) 2021 Michael Amadio <01micko@gmail.com>
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
#include <gnome-menus-3.0/gmenu-tree.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

/*=============================================================================
 * Declarations
 */
static void show_help();
static void process_directory(GMenuTreeDirectory *directory, int root);
static void process_entry(GMenuTreeEntry *entry);

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

    GMenuTree *menuTree = gmenu_tree_new_for_path (argv[1],  GMENU_TREE_FLAGS_SHOW_ALL_SEPARATORS );
    GError *error = NULL;
    if (!gmenu_tree_load_sync (menuTree, &error))
    {
      g_error ("%s\n", error->message);
      g_error_free (error);
      return (1);
    }

    GMenuTreeDirectory *rootDirectory = gmenu_tree_get_root_directory(menuTree);

    process_directory(rootDirectory, 1);

    gmenu_tree_item_unref (rootDirectory);

    return 0;
}

/*=============================================================================
 * Shows usage parameters
 */
void show_help()
{
    g_printf ("Creates a labwc menu from an Xdg menu structure.\n");
    g_printf ("\n");
    g_printf ("Usage:\n");
    g_printf ("  labwc-xdgmenu <Xdg menu file>\n");
    g_printf ("\n");
    g_printf ("For example:\n");
    g_printf ("  labwc-xdgmenu \"/etc/xdg/menus/applications.menu\"\n\n");
}

/*=============================================================================
 * This function processes a directory entry and all it's child nodes
 */
void process_directory(GMenuTreeDirectory *directory, int root)
{
    int hasSeparator = 0; int first = 1; int hadSeparator = 0;
    GMenuTreeIter *entryList = gmenu_tree_directory_iter (directory);
    GMenuTreeItemType entryType;

    while ((entryType = gmenu_tree_iter_next (entryList)) != GMENU_TREE_ITEM_INVALID)
    {
        if (entryType == GMENU_TREE_ITEM_ENTRY)
        {
            gmenu_tree_iter_unref (entryList);
            goto start;
        }
    }

    gmenu_tree_iter_unref (entryList);
    return;

start:
   if (root)
   {
      g_printf(
   		  "<menu id=\"xdg-menu-%s\" label=\"%s\">\n",
   		  gmenu_tree_directory_get_name(directory),
   		  gmenu_tree_directory_get_name(directory));
   }

    GMenuTreeEntry *entry;
    const char *path;
    GHashTable *history = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, NULL);

     entryList = gmenu_tree_directory_iter(directory);
     while ((entryType = gmenu_tree_iter_next(entryList)) != GMENU_TREE_ITEM_INVALID)
    {
        switch (entryType)
        {
            case GMENU_TREE_ITEM_DIRECTORY:
				if (hasSeparator)
				{
					if (!first && !hadSeparator)
					{
						g_printf(" <separator/> \n");
						hadSeparator = 1;
					}
 				hasSeparator = 0;
 
				}
				process_directory(gmenu_tree_iter_get_directory(entryList), 0);
				first = 0;
				hadSeparator = 0;
                break;
            case GMENU_TREE_ITEM_ENTRY:
                entry = gmenu_tree_iter_get_entry(entryList);
                path = gmenu_tree_entry_get_desktop_file_path(entry);
                if (g_hash_table_lookup(history, path))
                {
                    gmenu_tree_item_unref(entry);
                    continue;
                }
				if (hasSeparator)
				{
					if (!first && !hadSeparator)
	 				{
	 					g_printf(" <separator/> \n");
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
    }

    g_hash_table_destroy(history);
    if (root)
    {
        g_printf("</menu>\n");
    }
    gmenu_tree_iter_unref (entryList);
}

/*=============================================================================
 * This function adds an application entry
 */
void process_entry(GMenuTreeEntry *entry)
{
    GDesktopAppInfo *app = gmenu_tree_entry_get_app_info(entry);
    char *name = g_strdup (g_app_info_get_name(G_APP_INFO(app)));
    char *exec = g_strdup (g_app_info_get_executable(G_APP_INFO(app)));
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

    if (g_desktop_app_info_get_boolean(app, "Terminal"))
    {
        cmd = g_strdup_printf("defaultterminal -e sh -c '%s'", exec);
    }

    g_printf("  <item label=\"%s\">\n", g_strjoinv("&amp;", g_strsplit(name,"&",0))),
    g_printf("    <action name=\"Execute\"><command>%s</command></action>\n", cmd),
    g_printf("  </item>\n");

    g_free(name);
    g_free(exec);
    if (cmd != exec)
    {
        free(cmd);
    }
    gmenu_tree_item_unref(entry);
}

/*=============================================================================
 */
