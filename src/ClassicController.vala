/* ClassicController.vala
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
	class ClassicController : ExtensionDevice {
		Cemuhook.BaseData data = Cemuhook.BaseData() {
			buttons = 0,
			left_x = Cemuhook.STICK_NEUTRAL,
			left_y = Cemuhook.STICK_NEUTRAL,
			right_x = Cemuhook.STICK_NEUTRAL,
			right_y = Cemuhook.STICK_NEUTRAL
		};

		uint8 tl_analog = 0;
		uint8 tr_analog = 0;

		construct {
			implements_interface = CLASSIC_CONTROLLER;
			mac_bitmask = uint64.parse("CLASSIC", 36);
		}

		public ClassicController(MainDevice parent) {
			base(parent);
			debug("ClassicController created\n");
		}

		~ClassicController() {
			debug("ClassicController destroyed\n");
		}

		public override Cemuhook.DeviceType get_device_type() {
			return NO_MOTION;
		}

		public override Cemuhook.BaseData get_base_inputs() {
			return data;
		}

		public override void get_analog_inputs(ref Cemuhook.AnalogButtonsData abdata) {
			abdata.L1 = tl_analog;
			abdata.R1 = tr_analog;
		}

		public override void process_event(XWiimote.Event ev) {
			switch (ev.type) {
				case CLASSIC_CONTROLLER_KEY:
					process_key(ev.key.code, ev.key.state);
					break;
				case CLASSIC_CONTROLLER_MOVE:
					var left =     ev.abs[0];
					var right =    ev.abs[1];
					var triggers = ev.abs[3];

					unowned var calibr = parent.conf.classic_controller_stick_calibration;
					data.left_x = apply_stick_calibration(left.x, calibr[0], calibr[2]);
					data.left_y = apply_stick_calibration(left.y, calibr[1], calibr[3]);
					data.right_x = apply_stick_calibration(right.x, calibr[4], calibr[6]);
					data.right_y = apply_stick_calibration(right.y, calibr[5], calibr[7]);

					tl_analog = apply_analog_calibration(triggers.x, 55);
					tr_analog = apply_analog_calibration(triggers.y, 55);
					break;
				default:
					warn_if_reached();
					break;
			}
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
				case X:
					btn = X;
					break;
				case Y:
					btn = Y;
					break;

				case TR:
					btn = R1;
					break;
				case TL:
					btn = L1;
					break;
				case ZR:
					btn = R2;
					break;
				case ZL:
					btn = L2;
					break;

				case HOME:
					btn = PS;
					break;
				case MINUS:
					btn = SHARE;
					break;
				case PLUS:
					btn = OPTIONS;
					break;

				default:
					warn_if_reached();
					return;
			}

			switch (state) {
				case DOWN:
					data.buttons |= btn;
					break;
				case UP:
					data.buttons &= ~btn;
					break;
				case AUTOREPEAT:
					break;
			}
		}
	}
}
