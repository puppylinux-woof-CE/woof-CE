/* 'netmon_wce' - Network monitor for system tray*/
/* fork of Barry's 'network_tray' */
/* Changes:
mcewanw 08June2016: reserve and point to required memory storage for struct iface_info char strings i_name[] and ip_address[]
*/
#define _GNU_SOURCE     /* To get defns of NI_MAXSERV and NI_MAXHOST */
#include <arpa/inet.h>
#include <sys/socket.h>
#include <netdb.h>
#include <ifaddrs.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/if_link.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <iwlib.h>
#include <netinet/in.h>
#include <string.h>
#include <gtk/gtk.h>
#include <glib/gstdio.h>
#include <errno.h>
#include <limits.h>
#include <libintl.h>
#include <locale.h>
          // mcewanw addition_start:
#ifndef   IFACE_NAMELEN
#define   IFACE_NAMELEN 32
#endif
#ifndef   INET6_ADDRSTRLEN
#define   INET6_ADDRSTRLEN 46
#endif
          // mcewanw addition end

#define _(STRING)	gettext(STRING)
#define MONTH 		_("Month")
#define GIGABYTE 	1073741824
#define PPPOE		"pppoe"
#define RXMONTHFILE	"/var/local/sns/rx_bytes_month"
#define TXMONTHFILE	"/var/local/sns/tx_bytes_month"

//wireless icons
#define icon_wi_q10		"/usr/share/pixmaps/netmon_wce/qual_10.svg"
#define icon_wi_q9		"/usr/share/pixmaps/netmon_wce/qual_9.svg"
#define icon_wi_q8		"/usr/share/pixmaps/netmon_wce/qual_8.svg"
#define icon_wi_q7		"/usr/share/pixmaps/netmon_wce/qual_7.svg"
#define icon_wi_q6		"/usr/share/pixmaps/netmon_wce/qual_6.svg"
#define icon_wi_q5		"/usr/share/pixmaps/netmon_wce/qual_5.svg"
#define icon_wi_q4		"/usr/share/pixmaps/netmon_wce/qual_4.svg"
#define icon_wi_q3		"/usr/share/pixmaps/netmon_wce/qual_3.svg"
#define icon_wi_q2		"/usr/share/pixmaps/netmon_wce/qual_2.svg"
#define icon_wi_q1		"/usr/share/pixmaps/netmon_wce/qual_1.svg"
#define icon_wi_dis		"/usr/share/pixmaps/netmon_wce/qual_0.svg"

//net icons
#define networkblank 	"/usr/share/pixmaps/netmon_wce/internet_connect.svg"
#define networkboth		"/usr/share/pixmaps/netmon_wce/internet_connect_both.svg"
#define networkdead		"/usr/share/pixmaps/netmon_wce/internet_connect_no.svg"
#define networkin 		"/usr/share/pixmaps/netmon_wce/internet_connect_yes.svg"
#define networkout 		"/usr/share/pixmaps/netmon_wce/internet_connect_yes.svg"
//cell icons
#define celldead		"/usr/share/pixmaps/netmon_wce/cell_0.svg"
#define cellblank 		"/usr/share/pixmaps/netmon_wce/cell_1.svg"
#define cellboth		"/usr/share/pixmaps/netmon_wce/cell_4.svg"
#define cellin 			"/usr/share/pixmaps/netmon_wce/cell_3.svg"
#define cellout			"/usr/share/pixmaps/netmon_wce/cell_2.svg"


GdkPixbuf *neticon[5];
GdkPixbuf *cellicon[5];
GdkPixbuf *wiconset[11];

GtkStatusIcon *tray_icon;
unsigned int interval = 600; //update interval in milliseconds
unsigned int new_interval = 600;

FILE *fp;
int flagactive = 0;
int flagactiveprev = 0;
char infomsg[256];
char rxstr[52];
unsigned long long int rxacc = 0;
char rxaccstr[64];
char txstr[52];
unsigned long long int txacc = 0;
char txaccstr[64];
unsigned long long int rxaccprev = 0;
unsigned long long int txaccprev = 0;
int flagtransfer = 0;
int flagtransferprev = 0;
int loopcnt = 0;
int breakcnt = 0;
int flagdisconnect = 0;

//100814
char rxstrmonth[52];
unsigned long long int rxaccmonth = 0;
char txstrmonth[52];
unsigned long long int txaccmonth = 0;
unsigned long long int rxaccmonth_updated = 0;
unsigned long long int txaccmonth_updated = 0;
char ipa[20];
char command[256];
//wifi
int wireless = 0;
int enable_polling = 0;

GError *gerror;

//type to hold interface and ip address
struct iface_info {
//	char *iname; // mcewanw
//	char *ip_address; // mcewanw
	char iname[IFACE_NAMELEN];          // mcewanw
	char ip_address[INET6_ADDRSTRLEN];  // mcewanw
};

//fill the type
struct iface_info get_info();
struct iface_info get_info() {
	struct iface_info info[32]; //if more than 32 we ain't runnin' puppy on this beast~
	struct ifaddrs *addrs;
	struct ifaddrs *tmp;
	if (getifaddrs(&addrs) != 0) {
		perror("getifaddrs");
		exit(EXIT_FAILURE);
	}
	int family, s, i;
	char host[NI_MAXHOST];
	
	for (tmp = addrs, i = 0; tmp != NULL; tmp = tmp->ifa_next, i++) {
		if (tmp->ifa_addr == NULL) continue;
		family = tmp->ifa_addr->sa_family;
		if (strncmp(tmp->ifa_name, "ppp", 3) == 0) {
			if (family == AF_INET) {
				s = getnameinfo(tmp->ifa_addr,
					sizeof(struct sockaddr_in),
					host, NI_MAXHOST,
					NULL, 0, NI_NUMERICHOST);
				if (s != 0) {
					printf("getnameinfo() failed: %s\n", gai_strerror(s));
					exit(EXIT_FAILURE);
				}
			}
//			info[i].iname = tmp->ifa_name; // mcewanw
//			info[i].ip_address = host; // mcewanw
			strcpy(info[i].iname,tmp->ifa_name); // mcewanw
			strcpy(info[i].ip_address, host); // mcewanw
			freeifaddrs(addrs);
			return info[i];
			
		} else {
			if (family == AF_INET || family == AF_INET6) {
				s = getnameinfo(tmp->ifa_addr,
					(family == AF_INET) ? sizeof(struct sockaddr_in) :
											 sizeof(struct sockaddr_in6),
					host, NI_MAXHOST,
					NULL, 0, NI_NUMERICHOST);
				if (s != 0) {
					printf("getnameinfo() failed: %s\n", gai_strerror(s));
					exit(EXIT_FAILURE);
				}
			}
		}
//		info[i].iname = tmp->ifa_name; // mcewanw
//		info[i].ip_address = host;  // mcewanw
		strcpy(info[i].iname,tmp->ifa_name); // mcewanw
		strcpy(info[i].ip_address, host); //mcewanw
	}
	freeifaddrs(addrs);
	return info[i - 1]; //grab the first live one
/* mcewanw comment: but above return does not produce active interface IPv4 address if that interface also has assigned IPv6 address since the IPv6 address often comes last in list */
}

//type to hold link quality and maximum
struct link_qual {
	int my_qual;
	int my_max_qual;
};

//fill link_qual type
struct link_qual card_qual(char *interface);
struct link_qual card_qual(char *interface) {
	//http://www.linuxforums.org/forum/programming-scripting/195773-get-wireless-statistics-c.html
	struct link_qual l_qual;
	int sockfd;
	struct iw_statistics stats;
	struct iwreq req;
	struct	iw_range *i_range = malloc(sizeof(struct iw_range));
	if (!i_range) {
		perror("failed to allocate memory");
		exit (EXIT_FAILURE);
	}
	
	memset(&stats, 0, sizeof(stats));
	memset(&req, 0, sizeof(req));
	sprintf(req.ifr_name, "%s", interface);
	req.u.data.pointer = &stats;
	req.u.data.length = sizeof(stats);
#ifdef CLEAR_UPDATED
	req.u.data.flags = 1;
#endif

	if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) == -1) {
		perror("socket failed");
		free(i_range);
		exit (EXIT_FAILURE);
	}
	if (ioctl(sockfd, SIOCGIWSTATS, &req) == -1) {
		perror("ioctl SIOCGIWSTATS failed");
		close(sockfd);
		free(i_range);
		exit (EXIT_FAILURE);
	}
	if (iw_get_range_info(sockfd, interface, i_range) < 0) { //libiw
		l_qual.my_max_qual = 100;
	} else {
		l_qual.my_max_qual = i_range->max_qual.qual;
	}
	//cast to (int) from __u8 kernel type so we can work with
	l_qual.my_qual = (int)((char)stats.qual.qual);
	close(sockfd);
	free(i_range);
	return l_qual;
}

//finds active interface and builds tooltip
void find_active();
void find_active() {
	char *netdir = "/sys/class/net";
	char buf1[512];
	char buf2[512];
	char char1;
	//ip address
	struct iface_info now = get_info();
	sprintf(ipa, "%s", now.ip_address);
	if (strcmp(ipa, "127.0.0.1") != 0) {
		char1 = '0';
	}	
	//check if its wireless
	char wireless_dir[256];
	sprintf(wireless_dir, "%s/%s/wireless/", netdir, now.iname);
	if (access(wireless_dir, R_OK) == 0)
		wireless = 1;
	else
		wireless = 0;
    
    flagactive = 0;
    infomsg[0] = 0;
    strcat(infomsg, _("Active interface: "));
	if (strcmp(now.iname, "lo") != 0) {
	    if (char1 == '0') {
			flagactive = flagactive + 1;
			strcat(infomsg, now.iname);
			strcat(infomsg, " ");
			//accumulate bytes received...
			sprintf(buf1, "%s/%s/statistics/rx_bytes", netdir, now.iname);
			fp = fopen(buf1, "r");
			if (fp != NULL) {
				if (fgets(rxstr, 12, fp) != NULL)
					rxacc = atoll(rxstr) / 1024;
				fclose(fp);
			}
			rxaccmonth_updated = (rxaccmonth + rxacc) / 1024; //100814 in MB
			//accumulate bytes transmitted...
			sprintf(buf2, "%s/%s/statistics/tx_bytes", netdir, now.iname);
			fp = fopen(buf2, "r");
			if (fp != NULL) {
				if (fgets(txstr, 12, fp) != NULL)
					txacc = atoll(txstr)/1024;
				fclose(fp);
			}
			txaccmonth_updated = (txaccmonth+txacc) / 1024; //100814 in MB
		}
	}
	if (flagactive == 0) {
		strcat(infomsg, _("none\n"));
        strcat(infomsg, _("Click this icon for network setup"));
    } else {
        if (rxacc < 1024) {
            sprintf(rxaccstr, "%.1f", ((float)rxacc));
            strcat(infomsg, "\nRx: ");
            strcat(infomsg, rxaccstr);
            strcat(infomsg, "KB");
        }
        else {
            sprintf(rxaccstr, "%.1f", ((float)rxacc / 1024.0));
            strcat(infomsg, "\nRx: ");
            strcat(infomsg, rxaccstr);
            strcat(infomsg, "MB");
        }
        //100814 monthly acc...
        sprintf(rxaccstr, " (%s:%lluMB) ",
						MONTH, rxaccmonth_updated);
        strcat(infomsg, rxaccstr);
        if (txacc < 1024) {
            sprintf(txaccstr, "%.1f", ((float)txacc));
            strcat(infomsg, "\nTx: ");
            strcat(infomsg, txaccstr);
            strcat(infomsg, "KB");
        }
        else {
            sprintf(txaccstr, "%.1f", ((float)txacc / 1024.0));
            strcat(infomsg, "\nTx: ");
            strcat(infomsg, txaccstr);
            strcat(infomsg, "MB");
        }
        //100814 monthly acc...
        sprintf(txaccstr, " (%s:%lluMB) ",
						MONTH, txaccmonth_updated);
        strcat(infomsg, txaccstr);
		strcat(infomsg, _("\nIP address: "));
		strcat(infomsg, ipa);
	}
}

static int check_pppoe();
static int check_pppoe() {
	char pppoe_prog[64];
	sprintf(pppoe_prog, "%s %s %s", "pidof", PPPOE, "2>&1 >/dev/null");
	int success = system(pppoe_prog);
	return success;
}

//updates info
gboolean Update(gpointer ptr);
gboolean Update(gpointer ptr) {
	int wicon;
	int trans = 0;
	static char tipbuf[256];
	char *strength = _("Wireless Strength");
	//printf("interval: %d\n", new_interval); //testing; comment for production
	find_active();
	if (flagactive == 0) {
		flagtransfer = 0;
    } else {
        flagtransfer = 1;
        if (rxacc != rxaccprev) flagtransfer = 2;
        if (txacc != txaccprev) flagtransfer = 3;
        if (txacc != txaccprev && rxacc != rxaccprev) flagtransfer = 4;
        if ((txacc > (ULLONG_MAX - GIGABYTE)) || (rxacc > (ULLONG_MAX - GIGABYTE))) {
			perror ("Exiting due to imminent overflow condition");
			exit (EXIT_FAILURE);
		}
    }
	
	loopcnt = loopcnt + 1;
    //lot of trouble with this logic, so introduce breakcnt to force icon update if stuck...
    if (flagtransferprev == flagtransfer) {
		if (loopcnt != 1) { //want to update icon on first loop.
			if (flagactive == flagactiveprev && flagtransfer == flagtransferprev && flagtransfer == 1) breakcnt = breakcnt + 1; //no change.
			if (flagactive == flagactiveprev && flagtransfer == flagtransferprev && flagactive == 0) breakcnt = breakcnt + 1; //no change.
		} else {
			breakcnt = 0;
		}
		if (breakcnt != 0 && breakcnt < 8) return TRUE; //force update after 4 seconds.
    }
    breakcnt = 0;
    flagactiveprev = flagactive;
    txaccprev = txacc;
    rxaccprev = rxacc;
    flagtransferprev = flagtransfer;
    struct iface_info p_to_p = get_info(); //display cell icons if iface is pppN
    if (wireless == 0) { //no wireless
	    if ((strncmp(p_to_p.iname, "ppp", 3) == 0) && (check_pppoe() != 0))
			gtk_status_icon_set_from_pixbuf(tray_icon, cellicon[flagtransfer]);
	    else
			gtk_status_icon_set_from_pixbuf(tray_icon, neticon[flagtransfer]);
	    //update tooltip...
	    gtk_status_icon_set_tooltip_text(tray_icon, infomsg);
	    
    } else { //wireless
		if (flagtransfer == 1) trans = 0;
		if (flagtransfer > 1) trans = 5;
		if (enable_polling == 0) {
				gtk_status_icon_set_from_pixbuf(tray_icon, wiconset[4 + trans]); //arbitrary
				sprintf(tipbuf, "%s\n%s", infomsg, _("Wifi stats disabled"));
				gtk_status_icon_set_tooltip_text(tray_icon, tipbuf);
		} else { 
			//wireless test
			struct iface_info i_face = get_info();
			struct link_qual i_face_qual = card_qual(i_face.iname);
			int divisor;
			int wiQ, wiQpc;
			divisor = (int)i_face_qual.my_max_qual;
			if (divisor < 40) return FALSE; //40 is arbitrary
			wiQ = (int)i_face_qual.my_qual;
			
			//Code from Patriot's "LameWiFi"
			wiQpc = wiQ * 100 / divisor;
			if (wiQpc > 100) {
				perror("insane value for wifi stats");
				gtk_status_icon_set_from_pixbuf(tray_icon, wiconset[3 + trans]);
				sprintf(tipbuf, "%s\n%s", infomsg, _("Wifi Stats unreadable - disable polling in the menu."));
				gtk_status_icon_set_tooltip_text(tray_icon, tipbuf);
			} else {
				if (wiQpc > 89)
					wicon = 5 + trans;
				else if (wiQpc > 69)
					wicon = 4 + trans;
				else if (wiQpc > 49)
					wicon = 3 + trans;
				else if (wiQpc > 29)
					wicon = 2 + trans;
				else if (wiQpc > 9)
					wicon = 1 + trans;
				else
					wicon = 0;
		
				gtk_status_icon_set_from_pixbuf(tray_icon, wiconset[wicon]);
				sprintf(tipbuf, "%s\n%s %d%%", infomsg, strength, wiQpc);
				gtk_status_icon_set_tooltip_text(tray_icon, tipbuf);
			}
		}
	}
	//via 'ptomato' - http://stackoverflow.com/questions/2948538/variable-timeouts-in-glib
	if(new_interval) {
        g_timeout_add(new_interval, (GSourceFunc)Update, NULL);
        return FALSE;
    }
    return TRUE;
}

//callbacks
void  view_popup_menu_onSetupNetworking (GtkWidget *menuitem, gpointer userdata);
void  view_popup_menu_onSetupNetworking (GtkWidget *menuitem, gpointer userdata) {
	/* we passed the view as userdata when we connected the signal */
	system("defaultconnect & ");
}

void  view_popup_menu_onNetworkStatus (GtkWidget *menuitem, gpointer userdata);
void  view_popup_menu_onNetworkStatus (GtkWidget *menuitem, gpointer userdata) {
	system("ipinfo & ");
}

void  view_popup_menu_onDisconnect (GtkWidget *menuitem, gpointer userdata);
void  view_popup_menu_onDisconnect (GtkWidget *menuitem, gpointer userdata) {
	flagdisconnect = 1;
	system("/usr/local/apps/Connect/AppRun --disconnect & ");
}

void  view_popup_menu_onReconnect (GtkWidget *menuitem, gpointer userdata);
void  view_popup_menu_onReconnect (GtkWidget *menuitem, gpointer userdata) {
    system("/usr/local/apps/Connect/AppRun --connect & ");
    flagactiveprev = 0; /*100703*/
}

void toggle_wireless_polling();
void toggle_wireless_polling() {
	if (enable_polling == 0) {
		enable_polling = 1;
		new_interval = 5000;
	} else if (enable_polling == 1) {
		enable_polling = 0;
		new_interval = 600;
	}
}

void quit();
void quit() {
	gtk_main_quit();
	exit(EXIT_SUCCESS);
}

//menu
void tray_icon_on_menu(GtkStatusIcon *status_icon, guint button, guint activate_time, gpointer user_data);
void tray_icon_on_menu(GtkStatusIcon *status_icon, guint button, guint activate_time, gpointer user_data) {
	GtkWidget *menu, *menuitem, *icon;
	menu = gtk_menu_new();
	menuitem = gtk_image_menu_item_new_with_label(_("Quit"));
	icon = gtk_image_new_from_stock(GTK_STOCK_QUIT, GTK_ICON_SIZE_MENU);
	gtk_image_menu_item_set_image(GTK_IMAGE_MENU_ITEM(menuitem), icon);
	g_signal_connect(menuitem, "activate", (GCallback) quit, status_icon);
	gtk_menu_shell_append(GTK_MENU_SHELL(menu), menuitem);
	if (wireless != 0) {
		if (enable_polling == 0) {
			menuitem = gtk_image_menu_item_new_with_label(_("Enable wireless device polling"));
			icon = gtk_image_new_from_stock(GTK_STOCK_APPLY, GTK_ICON_SIZE_MENU);
		} else {
			menuitem = gtk_image_menu_item_new_with_label(_("Disable wireless device polling"));
			icon = gtk_image_new_from_stock(GTK_STOCK_CANCEL, GTK_ICON_SIZE_MENU);
		}
		gtk_image_menu_item_set_image(GTK_IMAGE_MENU_ITEM(menuitem), icon);
		g_signal_connect(menuitem, "activate", (GCallback) toggle_wireless_polling, status_icon);
		gtk_menu_shell_append(GTK_MENU_SHELL(menu), menuitem);
	}
	menuitem = gtk_image_menu_item_new_with_label(_("Setup networking"));
	icon = gtk_image_new_from_stock(GTK_STOCK_PREFERENCES, GTK_ICON_SIZE_MENU);
	gtk_image_menu_item_set_image(GTK_IMAGE_MENU_ITEM(menuitem), icon);
	g_signal_connect(menuitem, "activate", (GCallback) view_popup_menu_onSetupNetworking, status_icon);
	gtk_menu_shell_append(GTK_MENU_SHELL(menu), menuitem);
	menuitem = gtk_image_menu_item_new_with_label(_("Network status information"));
	icon = gtk_image_new_from_stock(GTK_STOCK_DIALOG_INFO, GTK_ICON_SIZE_MENU);
	gtk_image_menu_item_set_image(GTK_IMAGE_MENU_ITEM(menuitem), icon);
	g_signal_connect(menuitem, "activate", (GCallback) view_popup_menu_onNetworkStatus, status_icon);
	gtk_menu_shell_append(GTK_MENU_SHELL(menu), menuitem);
	if (flagactive != 0) {
		flagdisconnect = 0;
		menuitem = gtk_image_menu_item_new_with_label(_("Disconnect from network"));
		icon = gtk_image_new_from_stock(GTK_STOCK_DISCONNECT, GTK_ICON_SIZE_MENU);
		gtk_image_menu_item_set_image(GTK_IMAGE_MENU_ITEM(menuitem), icon);
		g_signal_connect(menuitem, "activate", (GCallback) view_popup_menu_onDisconnect, status_icon);
		gtk_menu_shell_append(GTK_MENU_SHELL(menu), menuitem);
	}
	if (flagdisconnect == 1) {
		menuitem = gtk_image_menu_item_new_with_label(_("Reconnect to network"));
		icon = gtk_image_new_from_stock(GTK_STOCK_CONNECT, GTK_ICON_SIZE_MENU);
		gtk_image_menu_item_set_image(GTK_IMAGE_MENU_ITEM(menuitem), icon);
		g_signal_connect(menuitem, "activate", (GCallback) view_popup_menu_onReconnect, status_icon);
		gtk_menu_shell_append(GTK_MENU_SHELL(menu), menuitem);
	}
	gtk_widget_show_all(menu);
	gtk_menu_popup(GTK_MENU(menu), NULL, NULL, NULL, NULL, button, gdk_event_get_time(NULL));
}

//left click callback
void tray_icon_on_click(GtkStatusIcon *status_icon, gpointer user_data);
void tray_icon_on_click(GtkStatusIcon *status_icon, gpointer user_data) {
	char *msg_string = _("Note: right-click icon for network menu");
	sprintf(command, "gtkdialog-splash -placement bottom -bg purple -timeout 10 -text \"%s\" &", msg_string);
	if (flagactive == 0) {
		system("defaultconnect & ");
	} else {
		system(command);
		system("ipinfo & ");
	}
}

//build status icon
static GtkStatusIcon *create_tray_icon();
static GtkStatusIcon *create_tray_icon() {
	tray_icon = gtk_status_icon_new();
	g_signal_connect(G_OBJECT(tray_icon), "activate", G_CALLBACK(tray_icon_on_click), NULL);
	g_signal_connect(G_OBJECT(tray_icon), "popup-menu", G_CALLBACK(tray_icon_on_menu), NULL);
	
	//wired icons
	neticon[0] = gdk_pixbuf_new_from_file(networkdead, &gerror);
	neticon[1] = gdk_pixbuf_new_from_file(networkblank, &gerror);
	neticon[2] = gdk_pixbuf_new_from_file(networkin, &gerror);
	neticon[3] = gdk_pixbuf_new_from_file(networkout, &gerror);
	neticon[4] = gdk_pixbuf_new_from_file(networkboth, &gerror);
	//cell icons
	cellicon[0] = gdk_pixbuf_new_from_file(celldead, &gerror);
	cellicon[1] = gdk_pixbuf_new_from_file(cellblank, &gerror);
	cellicon[2] = gdk_pixbuf_new_from_file(cellin, &gerror);
	cellicon[3] = gdk_pixbuf_new_from_file(cellout, &gerror);
	cellicon[4] = gdk_pixbuf_new_from_file(cellboth, &gerror);
	//wireless icons
	wiconset[0] = gdk_pixbuf_new_from_file(icon_wi_dis, &gerror);
	wiconset[1] = gdk_pixbuf_new_from_file(icon_wi_q1, &gerror);
	wiconset[2] = gdk_pixbuf_new_from_file(icon_wi_q2, &gerror);
	wiconset[3] = gdk_pixbuf_new_from_file(icon_wi_q3, &gerror);
	wiconset[4] = gdk_pixbuf_new_from_file(icon_wi_q4, &gerror);
	wiconset[5] = gdk_pixbuf_new_from_file(icon_wi_q5, &gerror);
	wiconset[6] = gdk_pixbuf_new_from_file(icon_wi_q6, &gerror);
	wiconset[7] = gdk_pixbuf_new_from_file(icon_wi_q7, &gerror);
	wiconset[8] = gdk_pixbuf_new_from_file(icon_wi_q8, &gerror);
	wiconset[9] = gdk_pixbuf_new_from_file(icon_wi_q9, &gerror);
	wiconset[10] = gdk_pixbuf_new_from_file(icon_wi_q10, &gerror);
	
	if (wireless == 0 ) { //not wireless
		gtk_status_icon_set_from_pixbuf(tray_icon, neticon[0]);
	} else { //wireless	
		gtk_status_icon_set_from_pixbuf(tray_icon, wiconset[0]);
	}
	
	gtk_status_icon_set_tooltip_text(tray_icon,_("No active network interfaces"));
	gtk_status_icon_set_visible(tray_icon, TRUE);
	return tray_icon;
}

int main(int argc, char **argv) {
	
	if (strcmp(argv[0], "netmon_wpoll") == 0) { //start in polling mode w/symlink
		printf("%s: polling enabled\n", argv[0]);
		enable_polling = 1;
		new_interval = 5000;
	}
	
	gtk_init(&argc, &argv);
	
	setlocale( LC_ALL, "" );
	bindtextdomain( "netmon_wce", "/usr/share/locale" );
	textdomain( "netmon_wce" );
	
	//100814 monthly acc (see also /usr/local/simple_network_setup/rc.network and rc.shutdown)...
	fp = fopen(RXMONTHFILE,"r");
	if (fp != NULL) {
		if (fgets(rxstrmonth, 12, fp) != NULL)
			rxaccmonth = atoll(rxstrmonth) / 1024; //in KB.
		fclose(fp);
	}
	fp = fopen(TXMONTHFILE,"r");
	if (fp != NULL) {
		if (fgets(txstrmonth, 12, fp) != NULL)
			txaccmonth = atoll(txstrmonth) / 1024;
		fclose(fp);
	}
	
	tray_icon = create_tray_icon();
		
	g_timeout_add(interval, Update, NULL);
	
	gtk_main();
	return 0;
}
