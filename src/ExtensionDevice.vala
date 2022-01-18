/* ExtensionDevice.vala
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
	/*
	 * Main device takes care of disconnecting and updating extensions.
	 *
	 * As such, they only need to implement reporting relevant data.
	 */
	abstract class ExtensionDevice : Object, Cemuhook.AbstractPhysicalDevice {
		public XWiimote.IfaceType implements_interface { get; protected construct set; }
		public uint64 mac_bitmask { get; protected construct set; }
		public weak MainDevice parent { get; private construct set; }

		public uint64 get_mac() {
			return parent.get_mac() ^ mac_bitmask;
		}

		public Cemuhook.DeviceOrientation orientation { get { return NORMAL; } }

		public abstract Cemuhook.DeviceType get_device_type();
		public abstract Cemuhook.BaseData get_base_inputs();
		public abstract void process_event(XWiimote.Event ev);

		public virtual uint64 get_motion_timestamp() { assert_not_reached(); }
		public virtual Cemuhook.MotionData get_accelerometer() { assert_not_reached(); }
		public virtual Cemuhook.MotionData get_gyro() { assert_not_reached(); }

		protected ExtensionDevice(MainDevice parent) {
			this.parent = parent;
		}
	}
}
