#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <gtk/gtk.h>
#include <gdk/gdk.h>
#include <gdk/gdkkeysyms.h>
#include <glib/gstdio.h>
#define THIS_VERSION "0.7"
#include <libintl.h>
#include <locale.h>
#define _(STRING)    gettext(STRING)
#define STARTUP "/.config/autostart/firewallstatus.desktop"

FILE *fp;
char my_home_dir[256];
char my_home_startup[256];

GtkStatusIcon *tray_icon;
void quit(GtkWidget *w, gpointer dummy);
void showme_window(GtkWidget *w, gpointer dummy);

unsigned int interval = 2000; /*update interval in milliseconds */

int fw_status = 1;

gboolean Firestate(gpointer ptr) {    /* This is the constantly updated routine */

/* Firewall test check and set icon in tray  */ 
  
    fw_status = system("[ `iptables -L -n |wc -l` -gt 10 ]");
	if (fw_status == 0) {
		gtk_status_icon_set_from_file(tray_icon,"/usr/share/pixmaps/puppy/shield_yes.svg" );
		gtk_status_icon_set_tooltip_text(tray_icon,_("Firewall On") );
	}
	else {
		gtk_status_icon_set_from_file(tray_icon,"/usr/share/pixmaps/puppy/shield_no.svg" );
		gtk_status_icon_set_tooltip_text(tray_icon, _("Firewall Off, Right click for menu") );
	} 
	return TRUE;
}

/* find the home dir */
char *find_home() {
	char *my_home = getenv("HOME");
	return my_home;
}

/* Firewall OFF */
void off_window(GtkWidget *w, gpointer dummy) {
	system("/etc/init.d/rc.firewall stop &");
}

/* Firewall ON */
void on_window(GtkWidget *w, gpointer dummy) {
	system("/etc/init.d/rc.firewall start &");
}

/* Firewall REMOVE */
void remove_window(GtkWidget *w, gpointer dummy) {
	system("rm /etc/init.d/rc.firewall");
}

/* Runs Firewall Setup */
void showme_window(GtkWidget *w, gpointer dummy) {
    system("firewall_ng &");
}

/* adds startup */
void add_start() {
	sprintf(my_home_dir, "%s/%s", find_home(), "/.config/autostart");
	if (access(my_home_dir, R_OK) != 0) {
		fprintf(stderr, "Can not access %s\n", my_home_dir);
		return;
	}
	sprintf(my_home_startup, "%s%s", find_home(), STARTUP);
	fp = fopen(my_home_startup, "w");
	if (fp != NULL) {
		fprintf(fp, "[Desktop Entry]\nEncoding=UTF-8\n"
				"Type=Application\nNoDisplay=true\n"
				"Name=firewallstatus\nExec=firewallstatus\n");
		fclose(fp);
	} else {
		fprintf(stderr, "Can not open %s for writing\n", my_home_startup);
		return;
	}
}

/* Quit and remove from starting */
void quit(GtkWidget *w, gpointer dummy) {
    int r = 0;
    char my_startup[256];
    sprintf(my_startup, "%s%s", find_home(), STARTUP);
    r = remove(my_startup); /*  removes applet from Startup */
    if (r != 0) {
		fprintf(stderr, "Failed to remove %s\n", my_startup); 
	}
    gtk_main_quit();
}


/* What right click does, calls gtk menu with "items" */
void tray_icon_on_menu(GtkStatusIcon *status_icon,  
		guint button, guint activate_time, gpointer user_data) {

	int fw_exists = 0;	
	
	GtkWidget *menu, *label, *iconw;
	menu = gtk_menu_new();

	label = gtk_image_menu_item_new_with_label(_("Quit & Remove Firewall Status"));
    iconw = gtk_image_new_from_stock(GTK_STOCK_QUIT, GTK_ICON_SIZE_MENU);
    gtk_image_menu_item_set_image(GTK_IMAGE_MENU_ITEM(label), iconw);
    gtk_menu_shell_append(GTK_MENU_SHELL(menu), label);
    g_signal_connect(label, "activate", (GCallback) quit, status_icon);	    

	label = gtk_image_menu_item_new_with_label(_("Firewall Setup"));
    iconw = gtk_image_new_from_stock(GTK_STOCK_EXECUTE, GTK_ICON_SIZE_MENU);
    gtk_image_menu_item_set_image(GTK_IMAGE_MENU_ITEM(label), iconw);
    gtk_menu_shell_append(GTK_MENU_SHELL(menu), label);
    g_signal_connect(label, "activate", (GCallback) showme_window, status_icon); 
    
    fw_exists = system("test -f /etc/init.d/rc.firewall");
    if (fw_exists == 0) {
	    label = gtk_image_menu_item_new_with_label(_("Remove Firewall"));
	    iconw = gtk_image_new_from_stock(GTK_STOCK_CLEAR, GTK_ICON_SIZE_MENU);
	    gtk_image_menu_item_set_image(GTK_IMAGE_MENU_ITEM(label), iconw);
	    gtk_menu_shell_append(GTK_MENU_SHELL(menu), label);
	    g_signal_connect(label, "activate", (GCallback) off_window, status_icon);
	    g_signal_connect(label, "activate", (GCallback) remove_window, status_icon);
	}
     
    fw_status = system("[ `iptables -L -n |wc -l` -gt 10 ]");
	if (fw_status == 0) {
		label = gtk_image_menu_item_new_with_label(_("Turn Firewall OFF"));
		iconw = gtk_image_new_from_stock(GTK_STOCK_NO, GTK_ICON_SIZE_MENU);
		gtk_image_menu_item_set_image(GTK_IMAGE_MENU_ITEM(label), iconw);
		gtk_menu_shell_append(GTK_MENU_SHELL(menu), label);
		g_signal_connect(label, "activate", (GCallback) off_window, status_icon);
	}
	else {
		if (fw_exists == 0) {
			label = gtk_image_menu_item_new_with_label(_("Turn Firewall ON"));
			iconw = gtk_image_new_from_stock(GTK_STOCK_YES, GTK_ICON_SIZE_MENU);
			gtk_image_menu_item_set_image(GTK_IMAGE_MENU_ITEM(label), iconw);
			gtk_menu_shell_append(GTK_MENU_SHELL(menu), label);
			g_signal_connect(label, "activate", (GCallback) on_window, status_icon);
		}
	}
	char startup_exists[256];
	sprintf(startup_exists, "%s%s", find_home(), STARTUP);
    if (access(startup_exists, R_OK) != 0) {
		label = gtk_image_menu_item_new_with_label(_("Add to start up"));
		iconw = gtk_image_new_from_stock(GTK_STOCK_ADD, GTK_ICON_SIZE_MENU);
		gtk_image_menu_item_set_image(GTK_IMAGE_MENU_ITEM(label), iconw);
		gtk_menu_shell_append(GTK_MENU_SHELL(menu), label);
		g_signal_connect(label, "activate", (GCallback) add_start, status_icon);
	}
    
	gtk_widget_show_all(menu);
	gtk_menu_popup(GTK_MENU(menu), NULL, NULL, NULL, NULL, button, gdk_event_get_time(NULL));
}

/* -create icon and 'click' properties */
static GtkStatusIcon *create_tray_icon() {

	tray_icon = gtk_status_icon_new();

	g_signal_connect(G_OBJECT(tray_icon), "popup-menu", G_CALLBACK(tray_icon_on_menu), NULL);

	gtk_status_icon_set_from_file(tray_icon,"/usr/share/pixmaps/puppy/shield_no.svg" );
	gtk_status_icon_set_tooltip_text(tray_icon, _("Firewall Off, Right click for menu") );
	
	gtk_status_icon_set_visible(tray_icon, TRUE);

	return tray_icon;
}

int main(int argc, char **argv) {
	
	setlocale( LC_ALL, "" );
	bindtextdomain( "firewallstatus", "/usr/share/locale" );
	textdomain( "firewallstatus" );

	gtk_init(&argc, &argv);
		
	tray_icon = create_tray_icon();
                        
	g_timeout_add(interval, Firestate, NULL);
	gtk_main();

	return 0;
}

