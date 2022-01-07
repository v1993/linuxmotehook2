/* MainDevice.vala
 *
 * Copyright 2022 v1993 <v19930312@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Linuxmotehook {
	sealed class MainDevice: Object, Cemuhook.AbstractPhysicalDevice {
		private XWiimote.Device dev;
		private UnixInputStream dev_stream;
		private PollableSource dev_source;

		private Cemuhook.DeviceType devtype = NO_MOTION;
		private Cemuhook.Buttons buttons = 0;
		private uint64 motion_timestamp = 0;
		private Cemuhook.MotionData accelerometer = {0f, 0f, 0f};
		private Cemuhook.MotionData gyroscope = {0f, 0f, 0f};
		private uint64 mac = 0;

		private ExtensionDevice? extension = null;

		construct {
			added.connect(on_added);
		}

		public MainDevice(owned XWiimote.Device dev) throws Error {
			this.dev = dev;
			dev.watch(true);
			mac = dev.get_mac();
			dev_stream = new UnixInputStream(dev.get_fd(), false);
			dev_source = dev_stream.create_source();
			PollableSourceFunc cb = process_incoming;
			dev_source.set_callback(cb);
			dev_source.attach();

			print(@"WiiMote $(format_mac(mac)) connected\n");
			update_interfaces(true);
		}

		~MainDevice() {
			debug("In MainDevice destructor");
			if (dev_source != null)
				dev_source.destroy();
		}

		private void update_interfaces(bool initial_call = false) throws IOError {
			var available = dev.available();
			var opened = dev.opened();
			var unopened = available & ~opened;
			// Warn if some interfaces are opened yet not available
			warn_if_fail(unopened == (available ^ opened));

			var app = new LMApplication();

			// WiiMote's own interfaces

			if (CORE in unopened && app.send_buttons) {
				try {
					info("Opening core interface");
					dev.open(CORE);
				} catch(IOError e) {
					warning("Failed to open buttons interface: %s\n", e.message);
				}
			}

			/*if (IR in unopened && app.send_ir) {
				try {
					info("Opening IR interface");
					dev.open(IR);
				} catch(IOError e) {
					warning("Failed to open IR interface: %s\n", e.message);
				}
			}*/

			if (ACCEL in unopened) {
				try {
					info("Opening accelerometer interface");
					dev.open(ACCEL);
				} catch(IOError e) {
					warning("Failed to open accelerometer interface (motion won't work!): %s\n", e.message);
				}
			}

			if (MOTION_PLUS in unopened) {
				try {
					info("Opening motion plus interface");
					dev.open(MOTION_PLUS);
				} catch(IOError e) {
					// Don't show warning here - it might happen for external MPs
				}
			}

			update_motion_status(dev.opened());

			// Clear unavailable interfaces
			if (!(CORE in opened)) {
				buttons = 0;
			}

			if ((extension != null) && !(extension.implements_interface in opened)) {
				extension.disconnected();
				extension = null;
			}

			// Extension interfaces need some time to initialize

			if (initial_call) {
				update_external_interfaces(true);
			} else {
				GLib.Timeout.add(500, update_external_interfaces_wrapper);
			}
		}

		private bool update_external_interfaces_wrapper() { return update_external_interfaces(); }

		private bool update_external_interfaces(bool initial_call = false) {
			var available = dev.available();
			var opened = dev.opened();
			var unopened = available & ~opened;

			// Since motion plus is available as pluggable extension, check for it here as well
			if (MOTION_PLUS in unopened) {
				try {
					info("Opening motion plus interface");
					dev.open(MOTION_PLUS);
				} catch(IOError e) {
					warning("Failed to open Motion Plus interface: %s\n", e.message);
				}
			}

			update_motion_status(dev.opened());

			if (NUNCHUK in unopened) {
				try {
					info("Opening nunchuck interface");
					dev.open(NUNCHUK);
					extension = new Nunchuck(this);
				} catch(IOError e) {
					warning("Failed to open nunchuck interface: %s\n", e.message);
				}
			}

			if ((!initial_call) && (extension != null) && (extension.implements_interface in unopened)) {
				unowned var server = new LMApplication().server;
				if (server != null) {
					try {
						server.add_device(extension);
					} catch(Cemuhook.ServerError.SERVER_FULL e) {
						print(@"Can't add extension to wiimote $(format_mac(mac)) - server full!\n");
					} catch(Error e) {
						warning("Error adding extension to server: %s", e.message);
					}
				}
			}

			return Source.REMOVE;
		}

		private void update_motion_status(XWiimote.IfaceType opened) {
			if (ACCEL in opened) {
				if (MOTION_PLUS in opened) {
					devtype = GYRO_FULL;
				} else {
					devtype = ACCELEROMETER_ONLY;

					gyroscope = Cemuhook.MotionData() {
						x = 0f,
						y = 0f,
						z = 0f
					};
				}
			} else {
				devtype = NO_MOTION;

				accelerometer = Cemuhook.MotionData() {
					x = 0f,
					y = 0f,
					z = 0f
				};

				gyroscope = Cemuhook.MotionData() {
					x = 0f,
					y = 0f,
					z = 0f
				};
			}
		}

		public void on_added(Cemuhook.Server server) {
			try {
				if (extension != null) {
					server.add_device(extension);
				}
			} catch(Cemuhook.ServerError.ALREADY_SERVING e) {
				// This is expected
			} catch(Cemuhook.ServerError.SERVER_FULL e) {
				print(@"Can't add extension to wiimote $(format_mac(mac)) - server full!\n");
			} catch(Error e) {
				warning("Error adding extension to server: %s", e.message);
			}
		}

		private bool process_incoming() {
			try {
				bool needs_update = false;
				bool extension_needs_update = false;
				for (var? ev = dev.poll(); ev != null; ev = dev.poll()) {
					switch (ev.type) {
						case KEY:
							process_key(ev.key.code, ev.key.state);
							needs_update = true;
							break;
						case ACCEL:
							motion_timestamp = ev.time_sec * 1000000 + ev.time_usec;
							process_accelerometer(ev.abs[0]);
							needs_update = true;
							break;
						case MOTION_PLUS:
							process_gyroscope(ev.abs[0]);
							needs_update = true;
							break;
						case NUNCHUK_KEY:
						case NUNCHUK_MOVE:
							extension.process_event(ev);
							extension_needs_update = true;
							break;
						case WATCH:
							update_interfaces();
							needs_update = true;
							break;
						case GONE:
							destroy();
							return Source.REMOVE;
						default:
							warn_if_reached();
							break;
					}
				}

				if (needs_update) {
					updated();
				}

				if (extension_needs_update) {
					extension.updated();
				}
			} catch (Error e) {
				warning("Error when reading event: %s, disconnecting!\n", e.message);
				destroy();
			}

			return Source.CONTINUE;
		}

		private void process_key(XWiimote.EventKeyCode code, XWiimote.EventKeyState state) {
			Cemuhook.Buttons btn;
			switch (code) {
				case UP:
					btn = UP;
					break;
				case RIGHT:
					btn = RIGHT;
					break;
				case DOWN:
					btn = DOWN;
					break;
				case LEFT:
					btn = LEFT;
					break;

				case A:
					btn = A;
					break;
				case B:
					btn = B;
					break;

				case HOME:
					btn = OPTIONS;
					break;
				case MINUS:
					btn = L1;
					break;
				case PLUS:
					btn = R1;
					break;
				case ONE:
					btn = L2;
					break;
				case TWO:
					btn = R2;
					break;

				default:
					warn_if_reached();
					return;
			}

			switch (state) {
				case DOWN:
					buttons |= btn;
					break;
				case UP:
					buttons &= ~btn;
					break;
				case AUTOREPEAT:
					break;
			}
		}

		private void process_accelerometer(XWiimote.EventAbs inp) {
			var app = new LMApplication();
			accelerometer = Cemuhook.MotionData() {
				x =  ((float)inp.x) / app.AccelUnitsPerG,
				y = -((float)inp.z) / app.AccelUnitsPerG,
				z = -((float)inp.y) / app.AccelUnitsPerG,
			};
		}

		private void process_gyroscope(XWiimote.EventAbs inp) {
			var app = new LMApplication();
			// TODO: apply per-device calibration (in place of zeros)
			gyroscope = Cemuhook.MotionData() {
				x =  ((float)(inp.z + 0)) / app.GyroUnitsPerDegPerSec,
				y =  ((float)(inp.x + 0)) / app.GyroUnitsPerDegPerSec,
				z =  ((float)(inp.y + 0)) / app.GyroUnitsPerDegPerSec,
			};
		}

		private void destroy() {
			if (mac != 0)
				print(@"WiiMote $(format_mac(mac)) disconnected\n");

			// TODO: signal disconnection for extension if one is present
			if (extension != null) {
				extension.disconnected();
				extension = null;
			}
			disconnected();
		}

		public Cemuhook.DeviceType get_device_type() { return devtype; }
		public Cemuhook.ConnectionType get_connection_type() { return BLUETOOTH; }
		public Cemuhook.BatteryStatus get_battery() {
			try {
				// Fully charged is about 71
				// 4 LEDs up to about 33
				var capacity = dev.get_battery();
				if (capacity >= 40) {
					return HIGH;
				} else if (capacity >= 20) {
					return MEDIUM;
				} else if (capacity >= 10) {
					return LOW;
				} else {
					return DYING;
				}
			} catch(Error e) {
				// Commonly happens right after device's addition, so don't log error
				return NA;
			}
		}

		public uint64 get_mac() { return mac; }

		public Cemuhook.BaseData get_base_inputs() {
			return Cemuhook.BaseData() {
				buttons = buttons,
				left_x = 127,
				left_y = 127,
				right_x = 127,
				right_y = 127
			};
		}

		public uint64 get_motion_timestamp() {
			return motion_timestamp;
		}

		public Cemuhook.MotionData get_accelerometer() {
			return accelerometer;
		}

		public Cemuhook.MotionData get_gyro() {
			return gyroscope;
		}
	}
}
