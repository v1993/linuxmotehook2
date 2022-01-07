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
			print("Nunchuck created\n");
		}

		~Nunchuck() {
			print("Nunchuck destroyed\n");
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
			var app = new LMApplication();
			switch (ev.type) {
				case NUNCHUK_KEY:
					if (app.send_buttons) {
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
					if (app.send_buttons) {
						// TODO: apply calibration
						var st = ev.abs[0];
						stick_x = (uint8)(st.x + 127).clamp(0, 255);
						stick_y = (uint8)(st.y + 127).clamp(0, 255);
					}
					// TODO: apply scaling, fix directions
					motion_timestamp = ev.time_sec * 1000000 + ev.time_usec;
					var motion = ev.abs[1];
					accel = Cemuhook.MotionData() {
						x =  (float)motion.x / app.NunchuckAccelUnitsPerG,
						y = -(float)motion.z / app.NunchuckAccelUnitsPerG,
						z = -(float)motion.y / app.NunchuckAccelUnitsPerG
					};
					break;
				default:
					warn_if_reached();
					break;
			}
		}
	}
}
