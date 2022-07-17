/*BK battery charge monitor for the notification tray*/
/*(c) Copyright Barry Kauler 2010, bkhome.org*/
/*GPL license: /usr/share/doc/legal/gpl-2.0.txt*/
/*100517 BK only blink icon if not charging...*/
/*101006 BK dir name can be other than BAT0 or BAT1*/
/*110929 BK 2.6.39.4 kernel does not have /proc/acpi/info*/
/*version 2.5 (20120519) rodin.s: added gettext*/
/*version 2.6 (20131215) 01micko change to svg icons*/
/*version 3.0 (20210218) 01micko dynamic svg icons*/
/*version 3.1 (20120404) fix for linux >=5.9*/

#include <stddef.h>
#include <string.h>
#include <libintl.h>
#include <locale.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <gtk/gtk.h>
#include <gdk/gdk.h>
#include <gdk/gdkkeysyms.h>
#include <glib/gstdio.h>
#include <sys/types.h>
#include <glob.h>
#include <libgen.h>
#include <math.h>

#define _(STRING)    gettext(STRING)
#define SVGHEAD		"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\" viewBox=\"0 0 128 128\">\n\t<defs>\n\t\t<linearGradient id=\"grad2\" x1=\"0%\" y1=\"0%\" x2=\"0%\" y2=\"100%\">\n\t\t<stop offset=\""
#define SVGDEF1		"%\" style=\"stop-color:rgb(150,150,150);stop-opacity:1\" />\n\t\t<stop offset=\""
#define SVGDEF2		"%\" style=\"stop-color:"
#define SVGDEF3		";stop-opacity:1\" />\n\t\t</linearGradient>\n\t</defs>\n\t"
#define SVGPATH1	"<path style=\"fill:#232323;stroke:none\" d=\"m 50 14 a 6 6 0 0 0 6 -6 l 16 0 a 6 6 0 0 0 6 6 z\"/>\n\t<path style=\"fill:url(#grad2);stroke:#232323;stroke-width:2\" d=\"m 42 14 44 0 a 10 10 0 0 1 10 10 l 0 80 a 10 10 0 0 1 -10 10 l -44 0  a 10 10 0 0 1 -10 -10 l 0 -80  a 10 10 0 0 1 10 -10 z\"/>\n\t"
#define SVGFOOT		"\n</svg>"
#define ICON 		"bat.svg"
#define CHHIGH		"rgb(80,110,255)" 		// high charging blue
#define DISHIGH		"rgb(255,160,125)"		// high discharging orange
#define CHLOW		"rgb(204,80,255)"		// low charging purple
#define DISLOW		"rgb(255,91,71)"		// low discharging red
#define SYMBOLP		"<path style=\"fill:#FFF152;stroke:#000\" d=\"m 56 33 25 0 -13 35 11 -4 -25 38 7 -38 -11 6 z\"/>"
#define SYMBOLM		"<path style=\"fill:#BB0000;stroke:none\" d=\"m 50 60 28 0 0 8 -28 0 z\"/>"

GdkPixbuf *bat_pixbuf;

GtkStatusIcon *tray_icon;
gchar *icon_path;
unsigned int interval = 15000; /*update interval in milliseconds*/
int batpercent = 100;
int batpercentprev = -1;
int chargingprev = -1;
int charged = -1;
FILE *fp;
FILE *fx;
int charging = -1;
char memdisplaylong[64];
char batname[16]="";

GError *gerror = NULL;

/* makes the tray icon image to be displayed */
int paint_icon(int state, int showpercent) {
	char colour[20];
	char symbol[110]; // + or -
	if ( state == 1 ) {
		if ( showpercent <= 15 ) {
			strcpy(colour, CHLOW);
		} else {
			strcpy(colour,CHHIGH);
		}
		strcpy(symbol, SYMBOLP); // '+'
	} else {
		if ( showpercent <= 20 ) {
			strcpy(colour, DISLOW);
		} else {
			strcpy(colour, DISHIGH);
		}
		strcpy(symbol, SYMBOLM); // '-'
	}
	int gradpc1 = 90 - showpercent ;
	int gradpc2 = 100 - showpercent ;
	if ( gradpc1 <= 0 )
		gradpc1 = 0;
		
	fx = fopen(icon_path, "w");
	if (!fx) {
		fprintf(stderr, "Couldn't open %s for writing\n", icon_path);
		exit(1); 
	}
	
	fprintf(fx, "%s%d%s%d%s%s%s%s%s%s", SVGHEAD, gradpc1, SVGDEF1, gradpc2, SVGDEF2, colour, SVGDEF3, SVGPATH1, symbol, SVGFOOT);
	
	fclose(fx);

	return 0;
}

gboolean Update(gpointer ptr) {
    char strpercent[8];
    char time[8];
    int num;
    int energy = 0;

    glob_t g = {0};
    if ((glob("/sys/class/power_supply/*/*_full", 0, NULL, &g) == 0) && (g.gl_pathc > 0)) {
        for (size_t i = 0; i < g.gl_pathc; ++i) {
            if (chdir(dirname(g.gl_pathv[i])) < 0)
                continue;

            if((fp = fopen("type","r")) == NULL) continue;
            char type[sizeof("Battery\n")];
            fscanf(fp,"%8s",type);
            fclose(fp);
            if (strcmp(type, "Battery") != 0) continue;

            if((fp = fopen("scope","r")) != NULL) {
                char scope[sizeof("System\n")];
                fscanf(fp,"%7s",scope);
                fclose(fp);
                if (strcmp(scope, "System") != 0) continue;
            }

            long full;
            fp = fopen("charge_full","r");
            if (!fp) {
                fp = fopen("energy_full","r");
                energy = 1;
            }
            if (!fp) continue;
            fscanf(fp,"%ld",&full);
            fclose(fp);

            char status[sizeof("Discharging\n")];
            status[0] = '\0';
            if((fp = fopen("status","r")) == NULL) continue;
            fscanf(fp,"%12s",status);
            fclose(fp);
            if (strcmp(status, "Full") == 0) {
                 batpercent = 100;
                 charging = 1;
                 charged = 1;
            } else {
                charging = (strcmp(status, "Charging") == 0);
                charged = 0;

                long now;
                if (energy) {
                    fp = fopen("energy_now","r");
                } else {
                    fp = fopen("charge_now","r");
                }
                if (!fp) continue;
                fscanf(fp,"%ld",&now);
                fclose(fp);

                float batpercentf = (((float)now*100)/full);
                if (batpercentf <= 20) {
                    batpercent=(int)floorf(batpercentf);
                } else {
                    batpercent=(int)roundf(batpercentf);
                }
            }

            break;
        }
    } else {
		fprintf(stderr,"No battery present\n");
		exit (1);
	}
    globfree(&g);

    //check for mad result...
    if (batpercent < 0) return FALSE;
    if (batpercent > 100) return FALSE;
    
    if ((batpercent==batpercentprev) && (charging==chargingprev)) return TRUE; //unchanged.
    batpercentprev=batpercent;
    chargingprev=charging;
    
    //update icon...
    int icon_success = paint_icon(charging, batpercent);
    if ( icon_success != 0 ) {
        printf("Error: couldn't build icon.\n");
        exit(1);
    }

    //update tooltip...
    memdisplaylong[0]=0;
    if (charging==0) {
        strcat(memdisplaylong,_("Battery discharging, capacity "));
    }
    else if (charging == 1) {
        if (charged == 1) {
            strcat(memdisplaylong,_("Battery charged, capacity "));
        } else {
            strcat(memdisplaylong,_("Battery charging, capacity "));
        }
    }
    sprintf(strpercent,"%d",batpercent);
    strcat(memdisplaylong,strpercent);
    strcat(memdisplaylong,"%");
    gtk_status_icon_set_tooltip_text(tray_icon, memdisplaylong);
    bat_pixbuf = gdk_pixbuf_new_from_file(icon_path,&gerror);
	gtk_status_icon_set_from_pixbuf(tray_icon,bat_pixbuf);
    return TRUE;
}


void tray_icon_on_click(GtkStatusIcon *status_icon, gpointer user_data) {
    int success = 0;
    success = system("batinfo");
    if (success != 0) {printf("system gxmessage call failed with %d\n", success);}
}

static GtkStatusIcon *create_tray_icon() {

    tray_icon = gtk_status_icon_new();
    g_signal_connect(G_OBJECT(tray_icon), "activate", G_CALLBACK(tray_icon_on_click), NULL);

    
    bat_pixbuf=gdk_pixbuf_new_from_file(icon_path,&gerror);

    gtk_status_icon_set_from_pixbuf(tray_icon,bat_pixbuf);
    
    gtk_status_icon_set_tooltip_text(tray_icon, _("Battery charge"));
    gtk_status_icon_set_visible(tray_icon, TRUE);
    g_object_unref(bat_pixbuf);

    return tray_icon;
}

int main(int argc, char **argv) {
    setlocale( LC_ALL, "" );
    bindtextdomain( "powerapplet_tray", "/usr/share/locale" );
    textdomain( "powerapplet_tray" );

    icon_path = g_build_filename(g_get_user_runtime_dir(), ICON, NULL);

	paint_icon(0,0); //needed to kick it off
    gtk_init(&argc, &argv);
    tray_icon = create_tray_icon();
    g_timeout_add(interval, Update, NULL);
    Update(NULL);

    gtk_main();

    return 0;
}
