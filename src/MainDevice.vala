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

		public MainDevice(owned XWiimote.Device dev) throws Error {
			this.dev = dev;
			dev.watch(true);
			mac = dev.get_mac();
			dev_stream = new UnixInputStream(dev.get_fd(), false);
			dev_source = dev_stream.create_source();
			PollableSourceFunc cb = process_incoming;
			dev_source.set_callback(cb);
			dev_source.attach();

			update_interfaces();
		}

		~MainDevice() {
			print("Device disconnected!\n");
			if (dev_source != null)
				dev_source.destroy();
		}

		private void update_interfaces() throws IOError {
			var available = dev.available();
			var opened = dev.opened();
			var unopened = available & ~opened;
			// Warn if some interfaces are opened yet not available
			warn_if_fail(unopened == (available ^ opened));

			var app = new LMApplication();

			// WiiMote's own interfaces

			if (CORE in unopened && app.send_buttons) {
				try {
					debug("Opening core interface");
					dev.open(CORE);
				} catch(IOError e) {
					print("Failed to open buttons interface: %s\n", e.message);
				}
			}

			if (IR in unopened && app.send_ir) {
				try {
					debug("Opening IR interface");
					dev.open(IR);
				} catch(IOError e) {
					print("Failed to open IR interface: %s\n", e.message);
				}
			}

			if (ACCEL in unopened) {
				try {
					debug("Opening accelerometer interface");
					dev.open(ACCEL);
				} catch(IOError e) {
					print("Failed to open accelerometer interface (motion won't work!): %s\n", e.message);
				}
			}

			if (MOTION_PLUS in unopened) {
				try {
					debug("Opening motion plus interface");
					dev.open(MOTION_PLUS);
				} catch(IOError e) {
					print("Failed to open Motion Plus interface: %s\n", e.message);
				}
			}

			opened = dev.opened();

			// Update motion status

			if (ACCEL in opened) {
				if (MOTION_PLUS in opened) {
					devtype = GYRO_FULL;
				} else {
					devtype = ACCELEROMETER_ONLY;
				}
			} else {
				devtype = NO_MOTION;
			}

			// Clear unavailable interfaces
			if (!(CORE in opened)) {
				buttons = 0;
			}

			// TODO: clear other interfaces if they are no longer opened

			// Extension interfaces - those are mutally exclusive
			// TODO: support them!
		}

		private bool process_incoming() {
			try {
				bool needs_update = false;
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
						case WATCH:
							update_interfaces();
							needs_update = true;
							break;
						case GONE:
							destroy();
							return Source.REMOVE;
					}
				}

				if (needs_update) {
					updated();
				}
			} catch (Error e) {
				print("Error when reading event: %s, disconnecting!\n", e.message);
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
			// TODO: signal disconnection for extension if used
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
				buttons = buttons
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
