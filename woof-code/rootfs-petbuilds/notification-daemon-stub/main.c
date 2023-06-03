#include <stdio.h>
#include "generated-code.h"


/* for < 2.68 */
#ifndef G_DBUS_METHOD_INVOCATION_HANDLED
#	define G_DBUS_METHOD_INVOCATION_HANDLED TRUE
#endif


static gboolean
on_get_server_information (OrgFreedesktopNotifications *object,
                           GDBusMethodInvocation       *invocation,
                           gpointer                    user_data)
{
  org_freedesktop_notifications_complete_get_server_information (object, invocation, "Notification Daemon Stub", "Nobody", "0.1", "1.2");
  return G_DBUS_METHOD_INVOCATION_HANDLED;
}


static gboolean
on_get_capabilities (OrgFreedesktopNotifications *object,
                     GDBusMethodInvocation       *invocation,
                     gpointer                    user_data)
{
  static const gchar *capabilities[] = {"body", NULL};
  org_freedesktop_notifications_complete_get_capabilities (object, invocation, capabilities);
  return G_DBUS_METHOD_INVOCATION_HANDLED;
}


static gboolean
on_notify (OrgFreedesktopNotifications *object,
           GDBusMethodInvocation       *invocation,
           const gchar                 *app_name,
           guint                        replaces_id,
           const gchar                 *app_icon,
           const gchar                 *summary,
           const gchar                 *body,
           const gchar *const          *actions,
           GVariant                    *hints,
           gint                         expire_timeout,
           gpointer                     user_data)
{
  org_freedesktop_notifications_complete_notify (object, invocation, 0);
  return G_DBUS_METHOD_INVOCATION_HANDLED;
}


static void
on_bus_acquired (GDBusConnection *connection,
                 const gchar     *name,
                 gpointer         user_data)
{
  OrgFreedesktopNotifications *object;
  gboolean exported;

  object = org_freedesktop_notifications_skeleton_new();

  g_signal_connect (object,
                    "handle-get-server-information",
                    G_CALLBACK (on_get_server_information),
                    NULL);
  g_signal_connect (object,
                    "handle-get-capabilities",
                    G_CALLBACK (on_get_capabilities),
                    NULL);
  g_signal_connect (object,
                    "handle-notify",
                    G_CALLBACK (on_notify),
                    NULL);

  exported = g_dbus_interface_skeleton_export (G_DBUS_INTERFACE_SKELETON (object),
                                               connection,
                                               "/org/freedesktop/Notifications",
                                               NULL);
  if (!exported)
    {
      g_main_loop_quit((GMainLoop *)user_data);
    }
}


static void
on_name_lost (GDBusConnection *connection,
              const gchar     *name,
              gpointer         user_data)
{
  g_main_loop_quit((GMainLoop *)user_data);
}


gint
main (gint argc, gchar *argv[])
{
  GMainLoop *loop;
  guint id;

  loop = g_main_loop_new (NULL, FALSE);

  id = g_bus_own_name (G_BUS_TYPE_SESSION,
                       "org.freedesktop.Notifications",
                       G_BUS_NAME_OWNER_FLAGS_ALLOW_REPLACEMENT |
                       G_BUS_NAME_OWNER_FLAGS_REPLACE,
                       on_bus_acquired,
                       NULL,
                       on_name_lost,
                       loop,
                       NULL);

  g_main_loop_run (loop);

  g_bus_unown_name (id);
  g_main_loop_unref (loop);

  return 0;
}