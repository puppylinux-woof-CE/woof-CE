/*BK battery charge monitor for the notification tray*/
/*(c) Copyright Barry Kauler 2010, bkhome.org*/
/*GPL license: /usr/share/doc/legal/gpl-2.0.txt*/
/*100517 BK only blink icon if not charging...*/
/*101006 BK dir name can be other than BAT0 or BAT1*/
/*110929 BK 2.6.39.4 kernel does not have /proc/acpi/info*/
/*version 2.5 (20120519) rodin.s: added gettext*/
/*version 2.6 (20131215) 01micko change to svg icons*/

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

#define _(STRING)    gettext(STRING)

GdkPixbuf *blank_pixbuf;
GdkPixbuf *emptychg_pixbuf;
GdkPixbuf *twentychg_pixbuf;
GdkPixbuf *fortychg_pixbuf;
GdkPixbuf *sixtychg_pixbuf;
GdkPixbuf *eightychg_pixbuf;
GdkPixbuf *fullchg_pixbuf;
GdkPixbuf *emptydis_pixbuf;
GdkPixbuf *twentydis_pixbuf;
GdkPixbuf *fortydis_pixbuf;
GdkPixbuf *sixtydis_pixbuf;
GdkPixbuf *eightydis_pixbuf;
GdkPixbuf *fulldis_pixbuf;

GtkStatusIcon *tray_icon;
unsigned int interval = 15000; /*update interval in milliseconds*/
int batpercent = 100;
int batpercentprev = 0;
int charged;
int pmtype = 0;
FILE *fp;
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

gboolean Update(gpointer ptr);

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
    else { //apm
        if((fp = fopen("/proc/apm","r")) == NULL) return TRUE;
        fscanf(fp,"%*s %*s %*s %*s %*s %*s %7s %d %7s",strpercent,&num,time);
        num = num/(strcmp(time,"sec") == 0?60:1);
        sprintf(time,"%d:%02d",(num/60)%100,num%60);
        fclose(fp);
        batpercent=atoi(strpercent);
    }
    
    //check for mad result...
    if (batpercent < 0) return FALSE;
    if (batpercent > 100) return FALSE;
    
    if (batpercent==batpercentprev) return TRUE; //unchanged.
    batpercentprev=batpercent;
    
    //update icon...
    if (charging==1) {
        if (batpercent < 10) gtk_status_icon_set_from_pixbuf(tray_icon,emptychg_pixbuf);
        else if (batpercent < 21) gtk_status_icon_set_from_pixbuf(tray_icon,twentychg_pixbuf);
        else if (batpercent < 41) gtk_status_icon_set_from_pixbuf(tray_icon,fortychg_pixbuf);
        else if (batpercent < 61) gtk_status_icon_set_from_pixbuf(tray_icon,sixtychg_pixbuf);
        else if (batpercent < 81) gtk_status_icon_set_from_pixbuf(tray_icon,eightychg_pixbuf);
        else gtk_status_icon_set_from_pixbuf(tray_icon,fullchg_pixbuf);
    }
    else {
        if (batpercent < 10) gtk_status_icon_set_from_pixbuf(tray_icon,emptydis_pixbuf);
        else if (batpercent < 21) gtk_status_icon_set_from_pixbuf(tray_icon,twentydis_pixbuf);
        else if (batpercent < 41) gtk_status_icon_set_from_pixbuf(tray_icon,fortydis_pixbuf);
        else if (batpercent < 61) gtk_status_icon_set_from_pixbuf(tray_icon,sixtydis_pixbuf);
        else if (batpercent < 81) gtk_status_icon_set_from_pixbuf(tray_icon,eightydis_pixbuf);
        else gtk_status_icon_set_from_pixbuf(tray_icon,fulldis_pixbuf);
        /*100517 BK only blink icon if not charging...*/
    }
    
    //update tooltip...
    memdisplaylong[0]=0;
    if (charging==0) strcat(memdisplaylong,_("Battery discharging, capacity "));
    else strcat(memdisplaylong,_("Battery charging, capacity "));
    sprintf(strpercent,"%d",batpercent);
    strcat(memdisplaylong,strpercent);
    strcat(memdisplaylong,"%");
    gtk_status_icon_set_tooltip_text(tray_icon, memdisplaylong);
}

void tray_icon_on_click(GtkStatusIcon *status_icon, gpointer user_data)
{
    //printf("Clicked on tray icon\n");
    if (pmtype == 2) {
	    system("yaf-splash -display :0 -bg thistle -placement center -close box -text \"`cat /proc/acpi/battery/*/info /proc/acpi/battery/*/state | sort -u`\" & ");
    }
}

void tray_icon_on_menu(GtkStatusIcon *status_icon, guint button, guint activate_time, gpointer user_data)
{
    printf("Popup menu\n");
}

static GtkStatusIcon *create_tray_icon() {

    tray_icon = gtk_status_icon_new();
    g_signal_connect(G_OBJECT(tray_icon), "activate", G_CALLBACK(tray_icon_on_click), NULL);
    g_signal_connect(G_OBJECT(tray_icon), "popup-menu", G_CALLBACK(tray_icon_on_menu), NULL);

    
    blank_pixbuf=gdk_pixbuf_new_from_file("/usr/share/pixmaps/powerapplet/not.svg",&gerror);
    emptychg_pixbuf=gdk_pixbuf_new_from_file("/usr/share/pixmaps/powerapplet/emptychg.svg",&gerror);
    twentychg_pixbuf=gdk_pixbuf_new_from_file("/usr/share/pixmaps/powerapplet/twentychg.svg",&gerror);
    fortychg_pixbuf=gdk_pixbuf_new_from_file("/usr/share/pixmaps/powerapplet/fortychg.svg",&gerror);
    sixtychg_pixbuf=gdk_pixbuf_new_from_file("/usr/share/pixmaps/powerapplet/sixtychg.svg",&gerror);
    eightychg_pixbuf=gdk_pixbuf_new_from_file("/usr/share/pixmaps/powerapplet/eightychg.svg",&gerror);
    fullchg_pixbuf=gdk_pixbuf_new_from_file("/usr/share/pixmaps/powerapplet/fullchg.svg",&gerror);
    emptydis_pixbuf=gdk_pixbuf_new_from_file("/usr/share/pixmaps/powerapplet/emptydis.svg",&gerror);
    twentydis_pixbuf=gdk_pixbuf_new_from_file("/usr/share/pixmaps/powerapplet/twentydis.svg",&gerror);
    fortydis_pixbuf=gdk_pixbuf_new_from_file("/usr/share/pixmaps/powerapplet/fortydis.svg",&gerror);
    sixtydis_pixbuf=gdk_pixbuf_new_from_file("/usr/share/pixmaps/powerapplet/sixtydis.svg",&gerror);
    eightydis_pixbuf=gdk_pixbuf_new_from_file("/usr/share/pixmaps/powerapplet/eightydis.svg",&gerror);
    fulldis_pixbuf=gdk_pixbuf_new_from_file("/usr/share/pixmaps/powerapplet/fulldis.svg",&gerror);

    gtk_status_icon_set_from_pixbuf(tray_icon,blank_pixbuf);
    
    gtk_status_icon_set_tooltip_text(tray_icon, _("Battery charge"));
    gtk_status_icon_set_visible(tray_icon, TRUE);

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
            while (ep = readdir (dp)) {
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

    GtkStatusIcon *tray_icon;

    gtk_init(&argc, &argv);
    tray_icon = create_tray_icon();
    
    g_timeout_add(interval, Update, NULL);
    Update(NULL);

    gtk_main();

    return 0;
}
