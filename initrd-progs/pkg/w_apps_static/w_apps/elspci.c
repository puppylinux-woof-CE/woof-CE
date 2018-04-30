#include <sys/types.h>
#include <dirent.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define SZ 256
char proc_dirname[SZ]; // usually = /proc

#ifndef FALSE
#define FALSE 0
#define TRUE !FALSE
#endif

#define PCI_VENDOR_ID		0x00
#define PCI_DEVICE_ID		0x02
#define PCI_CLASS_DEVICE	0x0a
#define PCI_CLASS_REVISION	0x08

typedef struct PCI_COLLATE_DATA{
	char location[50],bus[12],node[12];
	unsigned short vendor;
	unsigned short device;
	unsigned int class;
	char loaded[100];
}PCI_Collate;

int MyPci_count = 0;
PCI_Collate MyPci[50];

PCI_Collate *add_find_pci(char * loc){
	int i;
	for (i=0;i<MyPci_count;i++){
		if (strcmp(MyPci[i].location,loc)==0)
			return &MyPci[i];
	}
	if (MyPci_count == 50) return NULL;
	i = MyPci_count;
	memset(&MyPci[i], 0, sizeof(PCI_Collate));
	snprintf(MyPci[i].location, 50, "%s", loc);
	MyPci_count++;
	return &MyPci[i];
}

int split(char *src, int max, char *out, char **ptrs, char *splitchars){
	int n = 0, i;
	for(;;){
		ptrs[n] = out;
		i=0;
		while (strchr(splitchars,*src)==NULL){
			*(ptrs[n]+i) = *src;
			src++;
			out++;
			i++;
			*(ptrs[n]+i) = '\0';
			if (*src == '\0') break;
		}
		if (i>0) n++;
		if (*src == '\0') break;
		while (strchr(splitchars,*src)!=NULL){
			src++;
			if (*src == '\0') break;
		}
		if (*src == '\0') break;
		out++; //skip ending 0.
	}
	return n;
}

unsigned int getword(unsigned char *base) {
  return base[0] + ( base[1] * 256 );
}

int my_htoi(char *a){
	int k;
	unsigned long x = 0;
	if (*a == '0' && *(a+1) == 'x') a+=2;
	for (;*a != '\0'; a++){
		k = -1;
		if (*a >= '0' && *a <= '9') k = *a - '0';
		if (*a >= 'a' && *a <= 'f') k = *a - 'a' + 10;
		if (*a >= 'A' && *a <= 'F') k = *a - 'A' + 10;
		if (k == -1) break;
		x *= 0x10;
		x += k;
	}
	return x;
}

void scan_devices(void){
	char bfread[4096], *ptrs[25], bf[4096], pci[SZ];
	int n,i;
	FILE *f;
	snprintf(bf,4096,"%s/bus/pci/devices", proc_dirname);
	f = fopen(bf,"r");
	if (f==NULL) return;
	for (;;){
		if (NULL==fgets(bfread,4096,f))
			break; //end of file or error.
		if (bfread[0] == '#')
			continue; // comment line.
		n = split(bfread, 22, bf, ptrs, " \t\r\n");
		if (n>16){
			PCI_Collate *data;
			snprintf(pci,SZ,"%s/bus/pci/%02x/%02x.%01x",
				proc_dirname,
				(my_htoi( ptrs[0]) & 0xFF00)/0x100, 
				(my_htoi( ptrs[0]) & 0x00FC)/0x8, 
				(my_htoi( ptrs[0]) & 0x007));
			data = add_find_pci(pci);
			if (data != NULL) {
				int add=0,track=0;
				for (i=17;i<n && add>=0;i++){
					add = snprintf(data->loaded+track, 100-track, "%s%s", (i>17?" ":""), ptrs[i]);
					track+=add;
				}
			}
		}
	}
	fclose(f);
}

void pci_scan_node(char *path,char *bus, char *node){
	unsigned char buffer[256];
	FILE * fd;
	PCI_Collate *data;
	fd = fopen( path, "r" );
	if (fd == NULL) return;
	fread( &buffer, 1, sizeof(buffer), fd );
	fclose(fd);

	data = add_find_pci(path);
	if (data != NULL) {
		snprintf(data->bus,10,"%s", bus);
		snprintf(data->node,10,"%s", node);
		data->vendor = getword(buffer+ PCI_VENDOR_ID);
		data->device = getword(buffer+ PCI_DEVICE_ID);
		data->class = buffer[PCI_CLASS_DEVICE+1] * 0x10000 + 
				buffer[PCI_CLASS_DEVICE] * 0x100 + 
				buffer[PCI_CLASS_REVISION+1];
	}
}

int dir_scan_for_subdir_files(char *location, int lvl, char *bus, char *node){
	DIR *dir1 = NULL;
	struct dirent *dirent1 = NULL;
	char PathName[SZ];
	
	dir1 = opendir(location);
	if (dir1 == NULL) return FALSE;
  
	for (dirent1 = readdir(dir1); dirent1 != NULL; dirent1 = readdir(dir1)) {    
		if (dirent1->d_name[0] == '.')
			continue; // Skip dot files
		if (dirent1->d_name[0] == 'd')
			continue; // Skip 'devices' file
		snprintf(PathName, SZ, "%s/%s", location, dirent1->d_name);
		if (lvl==0)
			dir_scan_for_subdir_files(PathName, 1, dirent1->d_name, node);
		else
			pci_scan_node(PathName, bus, dirent1->d_name);
	}
	return TRUE;
}

int main (int argc, char *argv[]) {
	char bf[SZ];
	int i, help = FALSE;
	
	snprintf(proc_dirname, SZ, "/proc");
	
	for (i=1;i<argc;i++){
		if(!strcmp(argv[i],"--help") || !strcmp(argv[i],"-h")) 
				{ help=TRUE; continue; }
	}
	if (help){
		printf(" list pci devices (by Jesse.Liley@gmail.com)\n");
		printf(" list format: dev class vendor:device classid.classid name.name <loaded driver> (best guess driver)\n\n");
		return 0;
	}
	
	snprintf(bf, SZ, "%s/bus/pci", proc_dirname);
	dir_scan_for_subdir_files(bf,0,"",""); // find PCI devices on the PCI bus.
	scan_devices();	//exmines /proc/bus/pci/devices, obtains name of controlling device driver.

	PCI_Collate *data;
	for (i=0;i<MyPci_count;i++){
		data = &MyPci[i];
		printf("%s:%s %06X %04X:%04X <%s>\n", data->bus,data->node,
		data->class, data->vendor, data->device, data->loaded);
	}

	return 0;
}

