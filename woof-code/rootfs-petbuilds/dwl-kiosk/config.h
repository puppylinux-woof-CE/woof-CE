/* appearance */
static const int sloppyfocus               = 0;  /* focus follows mouse */
static const int bypass_surface_visibility = 0;  /* 1 means idle inhibitors will disable idle tracking even if it's surface isn't visible  */
static unsigned int borderpx         = 1;  /* border pixel of windows */
static float rootcolor[]             = {0.0, 0.0, 0.0, 1.0};
static float bordercolor[]           = {0.266667, 0.266667, 0.266667, 1.0};
static float focuscolor[]            = {0.0, 0.333333, 0.466667, 1.0};
/* To conform the xdg-protocol, set the alpha to zero to restore the old behavior */
static const float fullscreen_bg[]         = {0.1, 0.1, 0.1, 1.0};

/* tagging - tagcount must be no greater than 31 */
static const int tagcount = 9;

static const Rule rules[0] = {
	/* app_id     title       tags mask     isfloating   monitor */
	/* examples:
	{ "Gimp",     NULL,       0,            1,           -1 },
	{ "firefox",  NULL,       1 << 8,       0,           -1 },
	*/
};

/* layout(s) */
static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },
	{ "><>",      NULL },    /* no layout function means floating behavior */
	{ "[M]",      monocle },
	{ "@|@",      snail },
};

/* monitors */
static const MonitorRule monrules[] = {
	/* name       mfact nmaster scale layout       rotate/reflect                x    y */
	/* example of a HiDPI laptop monitor:
	{ "eDP-1",    0.5,  1,      2,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
	*/
	/* defaults */
	{ NULL,       0.64, 1,     -1,    &layouts[3], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
};

/* keyboard */
static const struct xkb_rule_names xkb_rules = {
	/* can specify fields: rules, model, layout, variant, options */
	/* example:
	.options = "ctrl:nocaps",
	*/
	.options = NULL,
};

static const int repeat_rate = 25;
static const int repeat_delay = 600;

/* Trackpad */
static const int tap_to_click = 1;
static const int tap_and_drag = 1;
static const int drag_lock = 1;
static const int natural_scrolling = 0;
static const int disable_while_typing = 1;
static const int left_handed = 0;
static const int middle_button_emulation = 0;
/* You can choose between:
LIBINPUT_CONFIG_SCROLL_NO_SCROLL
LIBINPUT_CONFIG_SCROLL_2FG
LIBINPUT_CONFIG_SCROLL_EDGE
LIBINPUT_CONFIG_SCROLL_ON_BUTTON_DOWN
*/
static const enum libinput_config_scroll_method scroll_method = LIBINPUT_CONFIG_SCROLL_2FG;

/* You can choose between:
LIBINPUT_CONFIG_CLICK_METHOD_NONE       
LIBINPUT_CONFIG_CLICK_METHOD_BUTTON_AREAS       
LIBINPUT_CONFIG_CLICK_METHOD_CLICKFINGER 
*/
static const enum libinput_config_click_method click_method = LIBINPUT_CONFIG_CLICK_METHOD_BUTTON_AREAS;

/* You can choose between:
LIBINPUT_CONFIG_SEND_EVENTS_ENABLED
LIBINPUT_CONFIG_SEND_EVENTS_DISABLED
LIBINPUT_CONFIG_SEND_EVENTS_DISABLED_ON_EXTERNAL_MOUSE
*/
static const uint32_t send_events_mode = LIBINPUT_CONFIG_SEND_EVENTS_ENABLED;

/* You can choose between:
LIBINPUT_CONFIG_ACCEL_PROFILE_FLAT
LIBINPUT_CONFIG_ACCEL_PROFILE_ADAPTIVE
*/
static const enum libinput_config_accel_profile accel_profile = LIBINPUT_CONFIG_ACCEL_PROFILE_ADAPTIVE;
static const double accel_speed = 0.0;
/* You can choose between:
LIBINPUT_CONFIG_TAP_MAP_LRM -- 1/2/3 finger tap maps to left/right/middle
LIBINPUT_CONFIG_TAP_MAP_LMR -- 1/2/3 finger tap maps to left/middle/right
*/
static const enum libinput_config_tap_button_map button_map = LIBINPUT_CONFIG_TAP_MAP_LRM;

/* If you want to use the windows key for MODKEY, use WLR_MODIFIER_LOGO */
#define MODKEY WLR_MODIFIER_LOGO

#define TAGKEYS(KEY,SKEY,TAG) \
	{ WLR_MODIFIER_LOGO,                    KEY,            view,            {.ui = 1 << TAG} }, \
	{ WLR_MODIFIER_LOGO|WLR_MODIFIER_CTRL,  KEY,            toggleview,      {.ui = 1 << TAG} }, \
	{ WLR_MODIFIER_LOGO|WLR_MODIFIER_SHIFT, SKEY,           tag,             {.ui = 1 << TAG} }, \
	{ WLR_MODIFIER_LOGO|WLR_MODIFIER_CTRL|WLR_MODIFIER_SHIFT,SKEY,toggletag, {.ui = 1 << TAG} }

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static const char *termcmd[] = { "defaultterminal", NULL };
static const char *runcmd[] = { "defaultrun", NULL };
static const char *lockcmd[] = { "puplock", NULL };
static const char *menucmd[] = { "tofi-exec", NULL };
static const char *brightnessupcmd[] = { "brightnessctl", "set", "+10%", NULL };
static const char *brightnessdowncmd[] = { "brightnessctl", "set", "10%-", NULL };
static const char *volumeupcmd[] = { "wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "1%+", NULL };
static const char *volumedowncmd[] = { "wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "1%-", NULL };
static const char *mutecmd[] = { "wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle", NULL };
static const char *screenshotcmd[] = { "defaultscreenshot", NULL };
static const char *regionscreenshotcmd[] = { "slurp-screenshot", NULL };
static const char *browsercmd[] = { "defaultbrowser", NULL };

static const Key keys[] = {
	/* Note that Shift changes certain key codes: c -> C, 2 -> at, etc. */
	/* modifier                  key                 function        argument */
	{ MODKEY,                    XKB_KEY_p,          spawn,          {.v = menucmd} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_Return,     spawn,          {.v = termcmd} },
	{ MODKEY,                    XKB_KEY_j,          focusstack,     {.i = +1} },
	{ MODKEY,                    XKB_KEY_k,          focusstack,     {.i = -1} },
	{ MODKEY,                    XKB_KEY_i,          incnmaster,     {.i = +1} },
	{ MODKEY,                    XKB_KEY_d,          incnmaster,     {.i = -1} },
	{ MODKEY,                    XKB_KEY_h,          setmfact,       {.f = -0.05} },
	{ MODKEY,                    XKB_KEY_l,          setmfact,       {.f = +0.05} },
	{ MODKEY,                    XKB_KEY_Return,     zoom,           {0} },
	{ MODKEY,                    XKB_KEY_Tab,        view,           {0} },
	{ MODKEY,                    XKB_KEY_x,          killclient,     {0} },
	{ MODKEY,                    XKB_KEY_t,          setlayout,      {.v = &layouts[0]} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_f,          setlayout,      {.v = &layouts[1]} },
	{ MODKEY,                    XKB_KEY_m,          setlayout,      {.v = &layouts[2]} },
	{ MODKEY,                    XKB_KEY_s,          setlayout,      {.v = &layouts[3]} },
	{ MODKEY,                    XKB_KEY_space,      setlayout,      {0} },
	{ MODKEY,                    XKB_KEY_f,          togglefloating, {0} },
	{ MODKEY,                    XKB_KEY_e,         togglefullscreen, {0} },
	{ MODKEY,                    XKB_KEY_0,          view,           {.ui = ~0} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_0,          tag,            {.ui = ~0} },
	{ MODKEY,                    XKB_KEY_comma,      focusmon,       {.i = WLR_DIRECTION_LEFT} },
	{ MODKEY,                    XKB_KEY_period,     focusmon,       {.i = WLR_DIRECTION_RIGHT} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_comma,      tagmon,         {.i = WLR_DIRECTION_LEFT} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_period,    tagmon,         {.i = WLR_DIRECTION_RIGHT} },
	TAGKEYS(          XKB_KEY_1, XKB_KEY_1,                          0),
	TAGKEYS(          XKB_KEY_2, XKB_KEY_2,                          1),
	TAGKEYS(          XKB_KEY_3, XKB_KEY_3,                          2),
	TAGKEYS(          XKB_KEY_4, XKB_KEY_4,                          3),
	TAGKEYS(          XKB_KEY_5, XKB_KEY_5,                          4),
	TAGKEYS(          XKB_KEY_6, XKB_KEY_6,                          5),
	TAGKEYS(          XKB_KEY_7, XKB_KEY_7,                          6),
	TAGKEYS(          XKB_KEY_8, XKB_KEY_8,                          7),
	TAGKEYS(          XKB_KEY_9, XKB_KEY_9,                          8),
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_q,          quit,           {0} },

	/* Ctrl-Alt-Backspace and Ctrl-Alt-Fx used to be handled by X server */
	{ WLR_MODIFIER_CTRL|WLR_MODIFIER_ALT,XKB_KEY_Terminate_Server, quit, {0} },
#define CHVT(n) { WLR_MODIFIER_CTRL|WLR_MODIFIER_ALT,XKB_KEY_F##n, chvt, {.ui = (n)} }
	CHVT(1), CHVT(2), CHVT(3), CHVT(4), CHVT(5), CHVT(6),
	CHVT(7), CHVT(8), CHVT(9), CHVT(10), CHVT(11), CHVT(12),

	{ MODKEY,                    XKB_KEY_w,          spawn,          {.v = browsercmd} },

	{ WLR_MODIFIER_ALT|WLR_MODIFIER_CTRL,  XKB_KEY_t,          spawn,          {.v = termcmd} },

	{ WLR_MODIFIER_ALT,          XKB_KEY_Tab,        focusstack,     {.i = +1} },
	{ WLR_MODIFIER_ALT,          XKB_KEY_F2,         spawn,          {.v = runcmd} },
	{ WLR_MODIFIER_ALT,          XKB_KEY_F4,         killclient,     {0} },
	{ MODKEY,                    XKB_KEY_r,          spawn,          {.v = runcmd} },
	{ MODKEY,                    XKB_KEY_Up,         togglemaximizesel,          {0} },
	{ MODKEY,                    XKB_KEY_Down,       toggleminimizesel,          {0} },

	{ MODKEY|WLR_MODIFIER_SHIFT,                    XKB_KEY_l,          spawn,          {.v = lockcmd} },

	{ 0,                         XKB_KEY_XF86MonBrightnessUp,        spawn,          {.v = brightnessupcmd} },
	{ 0,                         XKB_KEY_XF86MonBrightnessDown,      spawn,          {.v = brightnessdowncmd} },
	{ 0,                         XKB_KEY_XF86AudioRaiseVolume,       spawn,          {.v = volumeupcmd} },
	{ 0,                         XKB_KEY_XF86AudioLowerVolume,       spawn,          {.v = volumedowncmd} },
	{ 0,                         XKB_KEY_XF86AudioMute,              spawn,          {.v = mutecmd} },
	{ 0,                         XKB_KEY_Print,                      spawn,          {.v = screenshotcmd} },
	{ WLR_MODIFIER_SHIFT,        XKB_KEY_Print,                      spawn,          {.v = regionscreenshotcmd} },
};

static const Button buttons[] = {
	{ WLR_MODIFIER_ALT, BTN_LEFT,   moveresize,     {.ui = CurMove} },
	{ WLR_MODIFIER_ALT, BTN_MIDDLE, togglefloating, {0} },
	{ WLR_MODIFIER_ALT, BTN_RIGHT,  moveresize,     {.ui = CurResize} },
};
