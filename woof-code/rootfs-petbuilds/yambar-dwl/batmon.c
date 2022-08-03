#include <stdlib.h>
#include <glob.h>
#include <libgen.h>
#include <math.h>
#include <glib/gprintf.h>
#include <gio/gio.h>

// copy-paste of powerapplet_tray from 3e8f8e2
static void
get(float *batpercentf, int *charging)
{
	glob_t g = {0};
	char type[sizeof("Battery\n")], scope[sizeof("System\n")], status[sizeof("Discharging\n")];
	FILE *fp;
	long full, now;
	int energy = 0;

	if ((glob("/sys/class/power_supply/*/*_full", 0, NULL, &g) == 0) && (g.gl_pathc > 0)) {
		for (size_t i = 0; i < g.gl_pathc; ++i) {
			if (chdir(dirname(g.gl_pathv[i])) < 0) continue;

			if (!(fp = fopen("type","r"))) continue;
			fscanf(fp, "%8s", type);
			fclose(fp);
			if (strcmp(type, "Battery") != 0) continue;

			if ((fp = fopen("scope","r"))) {
				fscanf(fp, "%7s", scope);
				fclose(fp);
				if (strcmp(scope, "System") != 0) continue;
			}

			if (!(fp = fopen("charge_full","r"))) {
				if (!(fp = fopen("energy_full","r"))) continue;
				energy = 1;
			}
			fscanf(fp," %ld", &full);
			fclose(fp);

			if (!(fp = fopen("status", "r"))) continue;
			fscanf(fp, "%12s", status);
			fclose(fp);

			if (strcmp(status, "Full") == 0) {
				*batpercentf = 100;
				*charging = 1;
			} else {
				*charging = (g_strcmp0(status, "Charging") == 0);

				if (!(fp = fopen(energy ? "energy_now" : "charge_now", "r"))) continue;
				fscanf(fp, "%ld", &now);
				fclose(fp);

				*batpercentf = (((float)now * 100) / full);
			}

			break;
		}
	}

	globfree(&g);
}

static float
print(void)
{
	float batpercentf = -1;
	int charging = 0;
	get(&batpercentf, &charging);
	g_printf("capacity|int|%d\n", batpercentf <= 20 ? (int)floorf(batpercentf) : (int)roundf(batpercentf));
	g_printf("charging|bool|%s\n", charging ? "true" : "false");
	g_printf("\n\n");
	return batpercentf;
}

static gboolean
update(gpointer user_data)
{
	print();
	return TRUE;
}

int main(int argc, char *argv[])
{
	GMainLoop *loop;
	guint tag;

	setlinebuf(stdout);

	loop = g_main_loop_new(NULL, 0);
	if (print() != -1)
		tag = g_timeout_add(15000, update, NULL);
	g_main_loop_run(loop);
	g_source_remove(tag);
	g_main_loop_unref(loop);

	return EXIT_SUCCESS;
}