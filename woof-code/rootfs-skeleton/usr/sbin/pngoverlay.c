/*

overlay png images from the command line
pngoverlay.c = pngoverlay.bac (by vovchik)

location:
	/usr/sbin/pngoverlay

compile:
	gcc -o pngoverlay pngoverlay.c -ldl
	strip pngoverlay

*/

#include <stdio.h>
#include <unistd.h>
#include <dlfcn.h>

#define GDK_INTERP_BILINEAR 2
#define GDK_INTERP_HYPER 3
#define GTK_WINDOW_TOPLEVEL 0
#define OVERALL_ALPHA 255

void (*g_object_unref)(long);
void (*gtk_init)(int*, void*);
void (*gdk_pixbuf_composite)(int, int, int, int, int, int, double, double, double, double, int, int);
int (*gdk_pixbuf_save)(long,char*,char*,void*,...);
long (*gdk_pixbuf_new_from_file)(char*,void*);
int (*gdk_pixbuf_get_width)(int);
int (*gdk_pixbuf_get_height)(int);

// ===========================================================================

int main(int argc, char **argv) {

	void* handle_libgtk;
	char *FrontImage, *BackImage, *NewImage;
	int hei_img1, wid_img1, hei_img2, wid_img2, dest_x;
	double offset_x, scale_x, scale_y;
	long img_dst, img_scr;

	if (argc < 4) {
		printf("Usage: front-png back-png output-png\n");
		return 1;
	}

	FrontImage = argv[1];
	BackImage = argv[2];
	NewImage = argv[3];

	if (access(FrontImage,0) != 0) return 1;
	if (access(BackImage,0) != 0) return 1;
	if (access(NewImage,0) == 0) unlink(NewImage);

	// -------------------------------------------------------

	handle_libgtk = dlopen("libgtk-x11-2.0.so.0", RTLD_LAZY);
	if (!handle_libgtk) {
		fprintf(stderr, "%s\n", dlerror());
		return 1;
	}

	g_object_unref = dlsym(handle_libgtk, "g_object_unref");
	gtk_init = dlsym(handle_libgtk, "gtk_init");
	gdk_pixbuf_composite = dlsym(handle_libgtk, "gdk_pixbuf_composite");
	gdk_pixbuf_save = dlsym(handle_libgtk, "gdk_pixbuf_save");
	gdk_pixbuf_new_from_file = dlsym(handle_libgtk, "gdk_pixbuf_new_from_file");
	gdk_pixbuf_get_width = dlsym(handle_libgtk, "gdk_pixbuf_get_width");
	gdk_pixbuf_get_height = dlsym(handle_libgtk, "gdk_pixbuf_get_height");

	// -------------------------------------------------------

	scale_x = 1;
	scale_y = 1;
	dest_x = 0;
	offset_x = 0;

	gtk_init(0, 0);

	img_dst = gdk_pixbuf_new_from_file(FrontImage, 0);
	img_scr = gdk_pixbuf_new_from_file(BackImage, 0);

	if (!img_dst || !img_scr) {
		printf("Error loading one of the images\n");
		if (img_dst) g_object_unref(img_dst);
		if (img_scr) g_object_unref(img_scr);
		dlclose(handle_libgtk);
		return 1;
	}

	hei_img1 = gdk_pixbuf_get_height(img_dst);
	wid_img1 = gdk_pixbuf_get_width(img_dst);
	hei_img2 = gdk_pixbuf_get_height(img_scr);
	wid_img2 = gdk_pixbuf_get_width(img_scr);

	if ((hei_img1 - hei_img2) >= 0)
		gdk_pixbuf_composite(img_scr, img_dst, dest_x, hei_img1 - hei_img2, wid_img2, hei_img2, offset_x, hei_img1 - hei_img2, scale_x, scale_y, GDK_INTERP_HYPER, OVERALL_ALPHA);
	else
		gdk_pixbuf_composite(img_scr, img_dst, dest_x, hei_img2 - hei_img1, wid_img2, hei_img2, offset_x, hei_img2 - hei_img1, scale_x, scale_y, GDK_INTERP_HYPER, OVERALL_ALPHA);

	gdk_pixbuf_save(img_dst, NewImage, "png" ,NULL, NULL);

	g_object_unref(img_dst);
	g_object_unref(img_scr);
	dlclose(handle_libgtk);

	if (access(NewImage,0) == 0) {
		printf("File %s created.\n", NewImage);
		return 0;
	}

	printf("OOPS.. %s was not created.\n", NewImage);
	return 1;

}

/* END */
