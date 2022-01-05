/*
 * Copyright (c) 2021 Valeri Ochinski <v19930312@gmail.com>
 *
 * This work is free software available under MIT License.
 *
 * TODO: port the rest of documentation
 */

[CCode (cheader_filename = "xwiimote.h", cprefix = "xwii_", lower_case_cprefix = "xwii_")]
namespace XWiimote {
	[CCode (cheader_filename = "errno.h")]
	namespace Utils {
		[CCode (cname = "EAGAIN")]
		private const int EAGAIN;

		// This is pretty stupid
		private int error_check(int ret) throws GLib.IOError {
			if (ret >= 0) return ret;
			throw new GLib.IOError.FAILED(GLib.strerror(-ret));
		}
	}

	[CCode (cname = "xwii_event_types", cprefix = "XWII_EVENT_", has_type_id = false)]
	public enum EventType {
		KEY,
		ACCEL,
		IR,
		BALANCE_BOARD,
		MOTION_PLUS,
		PRO_CONTROLLER_KEY,
		PRO_CONTROLLER_MOVE,
		WATCH,
		CLASSIC_CONTROLLER_KEY,
		CLASSIC_CONTROLLER_MOVE,
		NUNCHUK_KEY,
		NUNCHUK_MOVE,
		DRUMS_KEY,
		DRUMS_MOVE,
		GUITAR_KEY,
		GUITAR_MOVE,
		GONE
	}

	// Note: enum name differs a bit
	[CCode (cname = "xwii_event_keys", cprefix = "XWII_KEY_", has_type_id = false)]
	public enum EventKeyCode {
		LEFT,
		RIGHT,
		UP,
		DOWN,
		A,
		B,
		PLUS,
		MINUS,
		HOME,
		ONE,
		TWO,
		X,
		Y,
		TL,
		TR,
		ZL,
		ZR,

		THUMBL,
		THUMBR,

		C,
		Z,

		STRUM_BAR_UP,
		STRUM_BAR_DOWN,

		FRET_FAR_UP,
		FRET_UP,
		FRET_MID,
		FRET_LOW,
		FRET_FAR_LOW
	}

	// This one is added by binding for consistency
	[CCode (has_type_id = false, cname = "unsigned int")]
	public enum EventKeyState {
		[CCode (cname = "0")]
		UP,
		[CCode (cname = "1")]
		DOWN,
		[CCode (cname = "2")]
		AUTOREPEAT
	}

	[CCode (cname = "struct xwii_event_key", has_type_id = false)]
	public struct EventKey {
		EventKeyCode code;
		EventKeyState state;
	}

	[CCode (cname = "struct xwii_event_abs", has_type_id = false)]
	public struct EventAbs {
		int32 x;
		int32 y;
		int32 z;
	}

	[CCode (cname = "xwii_drums_abs", cprefix = "XWII_DRUMS_ABS_", has_type_id = false)]
	public enum DrumAbs {
		PAD,
		CYMBAL_LEFT,
		CYMBAL_RIGHT,
		TOM_LEFT,
		TOM_RIGHT,
		TOM_FAR_RIGHT,
		BASS,
		HI_HAT
	}

	public const size_t ABS_NUM;

	[CCode (cname = "struct xwii_event", has_type_id = false)]
	public struct Event {
		EventType type;

		// The following map to time member
		// It allows us to avoid including posix.vapi just for a single struct
		[CCode (cname = "time.tv_sec")]
		time_t time_sec;
		[CCode (cname = "time.tv_usec")]
		long time_usec;

		// The following map to xwii_event_union member
		[CCode (cname = "v.key")]
		EventKey key;
		[CCode (cname = "v.abs")]
		EventAbs abs[ABS_NUM];
	}

	bool event_ir_is_valid(EventAbs abs);

	[CCode (cname = "xwii_iface_type", cprefix = "XWII_IFACE_", has_type_id = false)]
	[Flags]
	enum IfaceType {
		CORE,
		ACCEL,
		IR,

		MOTION_PLUS,
		NUNCHUK,
		CLASSIC_CONTROLLER,
		BALANCE_BOARD,
		PRO_CONTROLLER,
		DRUMS,
		GUITAR,

		ALL,
		WRITABLE
	}

	unowned string? get_iface_name(IfaceType type);

	// Not adding xwii_led stuff since it's rather pontless

	[CCode (cname = "struct xwii_iface", lower_case_csuffix = "iface", ref_function = "xwii_iface_ref", ref_function_void = true, unref_function = "xwii_iface_unref")]
	[Compact]
	class Device {
		// Binding of internal method
		[CCode (cname = "xwii_iface_new")]
		private static int _create(out Device? device, string syspath);

		public static Device create(string syspath) throws GLib.IOError {
			Device? device = null;
			Utils.error_check(_create(out device, syspath));

			return (!)device;
		}

		public uint64 get_mac() throws GLib.Error
		ensures(result >> 48 == 0) {
			// This is nowhere near fully optimized, but it really doesn't need to be
			var uevent_file = GLib.File.new_build_filename(get_syspath(), "uevent");
			var uevent_bytes = uevent_file.load_bytes();

			var regex = /HID_UNIQ=([[:xdigit:]][[:xdigit:]]):([[:xdigit:]][[:xdigit:]]):([[:xdigit:]][[:xdigit:]]):([[:xdigit:]][[:xdigit:]]):([[:xdigit:]][[:xdigit:]]):([[:xdigit:]][[:xdigit:]])/;
			GLib.MatchInfo info = null;
			if (!regex.match((string)uevent_bytes.get_data(), 0, out info) || info == null) {
				throw new GLib.IOError.NOT_FOUND("HID_UNIQ record missing");
			}

			var builder = new GLib.StringBuilder.sized(12);
			var matches = info.fetch_all()[1:];

			foreach (var substr in matches) {
				builder.append(substr);
			}

			return uint64.parse(builder.str, 16);
		}

		public unowned string get_syspath();

		public int get_fd();

		[CCode (cname = "xwii_iface_watch")]
		private int _watch(bool watch);

		[CCode (cname = "xwii_iface_watch_vala")]
		public void watch(bool watch) throws GLib.IOError {
			Utils.error_check(_watch(watch));
		}

		[CCode (cname = "xwii_iface_open")]
		private int _open(IfaceType iface);

		[CCode (cname = "xwii_iface_open_vala")]
		public void open(IfaceType iface) throws GLib.IOError {
			Utils.error_check(_open(iface));
		}

		public void close(IfaceType iface);

		public IfaceType opened();

		public IfaceType available();

		[CCode (cname = "xwii_iface_dispatch")]
		private int _dispatch(out Event ev, size_t size);

		[CCode (cname = "xwii_iface_dispatch_vala")]
		public Event? dispatch() throws GLib.IOError {
			Event ev;
			int ret = _dispatch(out ev, sizeof(Event));
			if (ret == -Utils.EAGAIN) return null;
			Utils.error_check(ret);
			return ev;
		}

		[CCode (cname = "xwii_iface_rumble")]
		private int _rumble(bool on);

		[CCode (cname = "xwii_iface_rumble_vala")]
		public void rumble(bool on) throws GLib.IOError {
			Utils.error_check(_rumble(on));
		}

		[CCode (cname = "xwii_iface_get_led")]
		private int _get_led(uint led, out bool state);

		[CCode (cname = "xwii_iface_get_led_vala")]
		public bool get_led(uint led) throws GLib.IOError {
			bool res;
			Utils.error_check(_get_led(led, out res));
			return res;
		}

		[CCode (cname = "xwii_iface_set_led")]
		private int _set_led(uint led, bool state);

		[CCode (cname = "xwii_iface_set_led_vala")]
		void set_led(uint led, bool state) throws GLib.IOError {
			Utils.error_check(_set_led(led, state));
		}

		[CCode (cname = "xwii_iface_get_battery")]
		private int _get_battery(out uint8 capacity);

		[CCode (cname = "xwii_iface_get_battery_vala")]
		public uint8 get_battery() throws GLib.IOError {
			uint8 capacity;
			Utils.error_check(_get_battery(out capacity));
			return capacity;
		}

		[CCode (cname = "xwii_iface_get_devtype")]
		private int _get_devtype(out string? devtype);

		[CCode (cname = "xwii_iface_get_devtype_vala")]
		public string get_devtype() throws GLib.IOError {
			string? res = null;
			Utils.error_check(_get_devtype(out res));
			return (!)res;
		}

		[CCode (cname = "xwii_iface_get_extension")]
		private int _get_extension(out string? extension);

		[CCode (cname = "xwii_iface_get_extension_vala")]
		public string get_extension() throws GLib.IOError {
			string? res = null;
			Utils.error_check(_get_extension(out res));
			return (!)res;
		}

		public void set_mp_normalization(int32 x, int32 y, int32 z, int32 factor);

		public void get_mp_normalization(out int32 x, out int32 y, out int32 z, out int32 factor);
	}

	/**
	 * Monitor system for new wiimote devices.
	 *
	 * This monitor can be used to enumerate all connected wiimote devices and also
	 * monitoring the system for hotplugged wiimote devices.
	 * This is a simple wrapper around libudev and should only be used if your
	 * application does not use udev on its own.
	 *
	 * A single monitor must not be
	 * used from multiple threads without locking. Different monitors are
	 * independent of each other and can be used simultaneously.
	 */

	[CCode (cname = "struct xwii_monitor", lower_case_csuffix = "monitor", ref_function = "xwii_monitor_ref", unref_function = "xwii_monitor_unref")]
	[Compact]
	class Monitor {
		/**
		 * Create a new monitor
		 *
		 * Creates a new monitor and returns a pointer to the opaque object. null is
		 * returned on failure.
		 *
		 * @param poll True if this monitor should watch for hotplug events
		 * @param direct True if kernel uevents should be used instead of udevd
		 *
		 * A monitor always provides all devices that are available on a system. If
		 * @p poll is true, the monitor also sets up a system-monitor to watch the
		 * system for new hotplug events so new devices can be detected.
		 */
		[CCode (cname = "xwii_monitor_new")]
		public static Monitor? create(bool poll = false, bool direct = false);

		/**
		 * Return internal fd
		 *
		 * @param blocking True to set the monitor in blocking mode
		 *
		 * Returns the file-descriptor used by this monitor. If @p blocking is true,
		 * the FD is set into blocking mode. If false, it is set into non-blocking mode.
		 * Only one file-descriptor exists, that is, this function always returns the
		 * same descriptor.
		 *
		 * This returns -1 if this monitor was not created with a hotplug-monitor. So
		 * you need this function only if you want to watch the system for hotplug
		 * events. Whenever this descriptor is readable, you should call
		 * xwii_monitor_poll() to read new incoming events.
		 */
		public int get_fd(bool blocking = false);

		/**
		 * Read incoming events
		 *
		 * This returns a single device-name on each call. A device-name is actually
		 * an absolute sysfs path to the device's root-node. You can use this path
		 * to create a new @{link XWiimote.Device}.
		 *
		 * After a monitor was created, this function returns all currently available
		 * devices. After all devices have been returned, this function returns null
		 * _once_. After that, this function polls the monitor for hotplug events and
		 * returns hotplugged devices, if the monitor was opened to watch the system for
		 * hotplug events.
		 *
		 * Use xwii_monitor_get_fd() to get notified when a new event is available. If
		 * the fd is in non-blocking mode, this function never blocks but returns null
		 * if no new event is available.
		 */
		public string? poll();
	}
}
