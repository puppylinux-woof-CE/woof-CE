/*BK battery charge monitor for the notification tray*/
/*(c) Copyright Barry Kauler 2010, bkhome.org*/
/*GPL license: /usr/share/doc/legal/gpl-2.0.txt*/
/*100517 BK only blink icon if not charging...*/
/*101006 BK dir name can be other than BAT0 or BAT1*/
/*110929 BK 2.6.39.4 kernel does not have /proc/acpi/info*/
/*version 2.5 (20120519) rodin.s: added gettext*/
/*version 2.6 (20131215) 01micko change to svg icons*/
/*version 3.0 (20210218) 01micko dynamic svg icons*/

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
#include <dirent.h>
#include <glob.h>
#include <libgen.h>

#define _(STRING)    gettext(STRING)
#define SVGHEAD		"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\" viewBox=\"0 0 128 128\">\n\t<defs>\n\t\t<linearGradient id=\"grad2\" x1=\"0%\" y1=\"0%\" x2=\"0%\" y2=\"100%\">\n\t\t<stop offset=\""
#define SVGDEF1		"%\" style=\"stop-color:rgb(150,150,150);stop-opacity:1\" />\n\t\t<stop offset=\""
#define SVGDEF2		"%\" style=\"stop-color:"
#define SVGDEF3		";stop-opacity:1\" />\n\t\t</linearGradient>\n\t</defs>\n\t"
#define SVGPATH1	"<path style=\"fill:#232323;stroke:none\" d=\"m 50 14 a 6 6 0 0 0 6 -6 l 16 0 a 6 6 0 0 0 6 6 z\"/>\n\t<path style=\"fill:url(#grad2);stroke:#232323;stroke-width:2\" d=\"m 42 14 44 0 a 10 10 0 0 1 10 10 l 0 80 a 10 10 0 0 1 -10 10 l -44 0  a 10 10 0 0 1 -10 -10 l 0 -80  a 10 10 0 0 1 10 -10 z\"/>\n\t"
#define SVGFOOT		"\n</svg>"
#define TEMP		"/tmp/powerapplet"
#define ICON 		"/tmp/powerapplet/bat.svg"
#define CHHIGH		"rgb(80,110,255)" 		// high charging blue
#define DISHIGH		"rgb(255,160,125)"		// high discharging orange
#define CHLOW		"rgb(204,80,255)"		// low charging purple
#define DISLOW		"rgb(255,91,71)"		// low discharging red
#define SYMBOLP		"<path style=\"fill:#FFF152;stroke:#000\" d=\"m 56 33 25 0 -13 35 11 -4 -25 38 7 -38 -11 6 z\"/>"
#define SYMBOLM		"<path style=\"fill:#BB0000;stroke:none\" d=\"m 50 60 28 0 0 8 -28 0 z\"/>"

GdkPixbuf *bat_pixbuf;

GtkStatusIcon *tray_icon;
unsigned int interval = 15000; /*update interval in milliseconds*/
int batpercent = 100;
int batpercentprev = 0;
int charged;
int pmtype = 0;
FILE *fp;
FILE *fx;
char inbuf1[200];
char inbuf2[200];
char powerdesign[20]="5500";
int ndesigncapacity=5500;
int nlastfullcapacity=5500;
int charging;
char powerremaining[20];
int npowerremaining;
char memdisplaylong[64];
char batname[16]="";
char batpathinfo[64]="/proc/acpi/battery/";
char batpathstate[64]="/proc/acpi/battery/";

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
		
	int access_ok = access(TEMP, W_OK);
	if (access_ok != 0) {
		if (mkdir(TEMP, 01777) != 0 ) {
			fprintf(stderr, "Couldn't create %s for writing\n", TEMP);
			exit(1);
		}
	}
	fx = fopen(ICON, "w");
	if (!fx) {
		fprintf(stderr, "Couldn't open %s for writing\n", ICON);
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

    charging=1; //charging.
    charged=0; //not full charged.
    
    if (pmtype == 2) {
        fp = fopen(batpathinfo,"r");
        while(!feof(fp)) {
            fgets(inbuf1,sizeof inbuf1,fp);
            if (strncmp("design capacity",inbuf1,14) == 0) {
                sscanf(inbuf1,"%*s %*s %s",powerdesign);
                ndesigncapacity=atoi(powerdesign);
            }
            if (strncmp("last full capacity",inbuf1,16) == 0)   {
                sscanf(inbuf1,"%*s %*s %*s %s",powerdesign);
                nlastfullcapacity=atoi(powerdesign);
                break;
            }
        }
        fclose(fp);

        fp = fopen(batpathstate,"r");
        while(!feof(fp)) {
            fgets(inbuf1,sizeof inbuf1,fp);
            if (strncmp("remaining capacity:",inbuf1,16) == 0)  {
                sscanf(inbuf1,"%*s %*s %s",powerremaining);
                npowerremaining=atoi(powerremaining);
            }
            if (strncmp("charging state:",inbuf1,14) == 0) {
                sscanf(inbuf1, "%*s %*s %s", inbuf2);
                if (strncmp("charged",inbuf2,7) == 0) charged=1;
                if (strncmp("discharging",inbuf2,11) == 0) charging=0;
            }
        }
        fclose(fp);
        
        //calc percentage charged... check nlastfullcapacity has a sane value...
        if (nlastfullcapacity > 400 && nlastfullcapacity < ndesigncapacity) batpercent=(npowerremaining*100)/nlastfullcapacity;
        else batpercent=(npowerremaining*100)/ndesigncapacity;
        
        if (charged == 1) batpercent=100; /*101006*/

    }
    else if (pmtype == 1) { //apm
        if((fp = fopen("/proc/apm","r")) == NULL) return TRUE;
        fscanf(fp,"%*s %*s %*s %*s %*s %*s %7s %d %7s",strpercent,&num,time);
        num = num/(strcmp(time,"sec") == 0?60:1);
        sprintf(time,"%d:%02d",(num/60)%100,num%60);
        fclose(fp);
        batpercent=atoi(strpercent);
        if (batpercent < 0) // APM emulation says charge is -1%
            pmtype = 3;
    }
    if (pmtype == 3) { // /sys/class/power_supply
        glob_t g = {0};
        if ((glob("/sys/class/power_supply/*/charge_full", 0, NULL, &g) == 0) && (g.gl_pathc > 0)) {
            for (size_t i = 0; i < g.gl_pathc; ++i) {
                if (chdir(dirname(g.gl_pathv[i])) < 0)
                    continue;

                int full;
                if((fp = fopen("charge_full","r")) == NULL) continue;
                fscanf(fp,"%d",&full);
                fclose(fp);

                char status[sizeof("Discharging\n")];
                status[0] = '\0';
                if((fp = fopen("status","r")) == NULL) continue;
                fscanf(fp,"%12s",status);
                fclose(fp);
                if (strcmp(status, "Full") == 0) {
                    batpercent = 100;
                    charging = 0;
                } else {
                    charging = (strcmp(status, "Charging") == 0);

                    int now;
                    if((fp = fopen("charge_now","r")) == NULL) continue;
                    fscanf(fp,"%d",&now);
                    fclose(fp);

                    batpercent=(now*100)/full;
                }

                break;
            }
        }
        globfree(&g);
    }
    
    //check for mad result...
    if (batpercent < 0) return FALSE;
    if (batpercent > 100) return FALSE;
    
    if (batpercent==batpercentprev) return TRUE; //unchanged.
    batpercentprev=batpercent;
    
    //update icon...
	int icon_success = paint_icon(charging, batpercent);
	if ( icon_success != 0 ) {
		printf("Error: couldn't build icon.\n");
		exit(1);
	}
	
    //update tooltip...
    memdisplaylong[0]=0;
    if (charging==0) strcat(memdisplaylong,_("Battery discharging, capacity "));
    else strcat(memdisplaylong,_("Battery charging, capacity "));
    sprintf(strpercent,"%d",batpercent);
    strcat(memdisplaylong,strpercent);
    strcat(memdisplaylong,"%");
    gtk_status_icon_set_tooltip_text(tray_icon, memdisplaylong);
    bat_pixbuf = gdk_pixbuf_new_from_file(ICON,&gerror);
	gtk_status_icon_set_from_pixbuf(tray_icon,bat_pixbuf);
    return TRUE;
}


void tray_icon_on_click(GtkStatusIcon *status_icon, gpointer user_data)
{
    //printf("Clicked on tray icon\n");
    if (pmtype == 2) {
	    system("yaf-splash -display :0 -bg thistle -placement center -close box -text \"`cat /proc/acpi/battery/*/info /proc/acpi/battery/*/state | sort -u`\" & ");
    }
}

static GtkStatusIcon *create_tray_icon() {

    tray_icon = gtk_status_icon_new();
    g_signal_connect(G_OBJECT(tray_icon), "activate", G_CALLBACK(tray_icon_on_click), NULL);

    
    bat_pixbuf=gdk_pixbuf_new_from_file(ICON,&gerror);

    gtk_status_icon_set_from_pixbuf(tray_icon,bat_pixbuf);
    
    gtk_status_icon_set_tooltip_text(tray_icon, _("Battery charge"));
    gtk_status_icon_set_visible(tray_icon, TRUE);
    g_object_unref(bat_pixbuf);

    return tray_icon;
}

int main(int argc, char **argv) {
  DIR *dp;
  struct dirent *ep;
  int cntbats;
  
  setlocale( LC_ALL, "" );
  bindtextdomain( "powerapplet_tray", "/usr/share/locale" );
  textdomain( "powerapplet_tray" );
	
    //apm or acpi?...
    pmtype=2; /*110929 2.6.39.4 kernel does not have /proc/acpi/info*/
    if((fp = fopen("/proc/apm","r")) != NULL) { pmtype=1; fclose(fp); }
    /*110929 if((fp = fopen("/proc/acpi/info","r")) != NULL) { pmtype=2; fclose(fp); }
    if (pmtype == 0) { system("logger -t powerapplet 'Abort, no /proc/apm or acpi/info'"); return 1; }*/

    if (pmtype == 2) {
        cntbats=0;
        dp = opendir ("/proc/acpi/battery");
        if (dp != NULL) {
            while ((ep = readdir (dp))) {
                if (strcmp(ep->d_name,".") == 0) continue;
		        if (strcmp(ep->d_name,"..") == 0) continue;
		        if (strcmp(ep->d_name,"") == 0) continue;
		        cntbats=cntbats+1;
		        if (cntbats > 1) continue;
		        strcpy(batname,ep->d_name);
		        strcat(batpathinfo,batname);
		        strcat(batpathinfo,"/info"); /*ex: /proc/acpi/battery/BAT0/info*/
		        strcat(batpathstate,batname);
		        strcat(batpathstate,"/state");
            }
            (void) closedir(dp);
        }
        else {
            system("logger -t powerapplet 'Abort, unable to open /proc/acpi/battery'");
            return 1;
        }
        if (cntbats == 0) {
            system("logger -t powerapplet 'Abort, unable to find anything in /proc/acpi/battery'");
            return 1;
        }
        if((fp = fopen(batpathinfo,"r")) != NULL) fclose(fp);
        else {
            system("logger -t powerapplet 'Abort, unable to find info file in /proc/acpi/battery'");
            return 1;
        }
    }
	paint_icon(0,0); //needed to kick it off
    gtk_init(&argc, &argv);
    tray_icon = create_tray_icon();
    g_timeout_add(interval, Update, NULL);
    Update(NULL);

    gtk_main();

    return 0;
}
