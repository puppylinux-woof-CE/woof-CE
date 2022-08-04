#include <stdlib.h>
#include <glib/gprintf.h>
#include <gio/gio.h>

static void
on_property_changed(GDBusConnection *connection,
                    const gchar     *sender_name,
                    const gchar     *object_path,
                    const gchar     *interface_name,
                    const gchar     *signal_name,
                    GVariant        *parameters,
                    gpointer        user_data)
{
	gchar *k, *state;
	GVariant *v;

	g_variant_get(parameters, "(&sv)", &k, &v);
	if (g_strcmp0(k, "State") == 0) {
		g_variant_get(v, "&s", &state);
		g_printf("state|string|%s\n\n", state);
	}
}

int main(int argc, char *argv[])
{
	GDBusConnection *conn;
	GMainLoop *loop;
	guint id;
	GVariant *res;
	GVariantIter *props;
	const gchar *k;
	GVariant *v;

	setlinebuf(stdout);

	if (!(conn = g_bus_get_sync(G_BUS_TYPE_SYSTEM, NULL, NULL)))
		return EXIT_FAILURE;

	loop = g_main_loop_new(NULL, 0);
	id = g_dbus_connection_signal_subscribe(conn,
	                                        "net.connman",
	                                        "net.connman.Manager",
	                                        "PropertyChanged",
	                                        "/",
	                                        NULL,
	                                        G_DBUS_SIGNAL_FLAGS_NONE,
	                                        on_property_changed,
	                                        NULL,
	                                        NULL);

	if ((res = g_dbus_connection_call_sync(conn,
	                                       "net.connman",
	                                       "/",
	                                       "net.connman.Manager",
	                                       "GetProperties",
	                                       NULL,
	                                       NULL,
	                                       G_DBUS_CALL_FLAGS_NONE,
	                                       -1,
	                                       NULL,
	                                       NULL))) {
		g_variant_get(res, "(a{sv})", &props);
		while (g_variant_iter_loop(props, "{&sv}", &k, &v)) {
			if (g_strcmp0(k, "State") == 0) {
				g_printf("state|string|%s\n\n", g_variant_get_string(v, NULL));
				break;
			}
		}
		g_variant_iter_free(props);

		g_variant_unref(res);
	}

	g_main_loop_run(loop);
	g_dbus_connection_signal_unsubscribe(conn, id);
	g_main_loop_unref(loop);
	g_object_unref(conn);

	return EXIT_SUCCESS;
}