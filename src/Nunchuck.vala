/* Nunchuck.vala
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
	class Nunchuck : ExtensionDevice {
		private const float ACCEL_UNITS_PER_G = 205f;

		private uint8 stick_x = 127;
		private uint8 stick_y = 127;
		private Cemuhook.Buttons buttons = 0;
		private uint64 motion_timestamp = 0;
		private Cemuhook.MotionData accel = {0f, 0f, 0f};

		construct {
			implements_interface = NUNCHUK;
			mac_bitmask = uint64.parse("NUNCHUK", 36);
		}

		public Nunchuck(MainDevice parent) {
			base(parent);
			debug("Nunchuck created\n");
		}

		~Nunchuck() {
			debug("Nunchuck destroyed\n");
		}

		public override Cemuhook.DeviceType get_device_type() {
			return ACCELEROMETER_ONLY;
		}

		public override Cemuhook.BaseData get_base_inputs() {
			return Cemuhook.BaseData() {
				buttons = buttons,
				left_x = stick_x,
				left_y = stick_y,
				right_x = 127,
				right_y = 127
			};
		}

		public override uint64 get_motion_timestamp() {
			return motion_timestamp;
		}

		public override Cemuhook.MotionData get_accelerometer() {
			return accel;
		}

		public override void process_event(XWiimote.Event ev) {
			switch (ev.type) {
				case NUNCHUK_KEY:
					if (parent.conf.send_buttons) {
						Cemuhook.Buttons btn;
						switch(ev.key.code) {
							case C:
								btn = L1;
								break;
							case Z:
								btn = L2;
								break;
							default:
								warn_if_reached();
								return;
						}

						switch (ev.key.state) {
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
					break;
				case NUNCHUK_MOVE:
					if (parent.conf.send_buttons) {
						var st = ev.abs[0];
						unowned var calibr = parent.conf.nunchuck_stick_calibration;
						stick_x = (uint8)((st.x - calibr[0]) * 127 / calibr[2] + 127).clamp(0, 255);
						stick_y = (uint8)((st.y - calibr[1]) * 127 / calibr[3] + 127).clamp(0, 255);
					}

					motion_timestamp = ev.time_sec * 1000000 + ev.time_usec;
					var motion = ev.abs[1];
					accel = Cemuhook.MotionData() {
						x =  (float)motion.x / ACCEL_UNITS_PER_G,
						y = -(float)motion.z / ACCEL_UNITS_PER_G,
						z = -(float)motion.y / ACCEL_UNITS_PER_G
					};
					break;
				default:
					warn_if_reached();
					break;
			}
		}
	}
}
