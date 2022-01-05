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

		private Cemuhook.DeviceType devtype = NO_MOTION;
		private uint64 mac = 0;

		public MainDevice(owned XWiimote.Device dev) throws Error {
			this.dev = dev;
			mac = dev.get_mac(); //< Commenting this out prevents segfault
		}

		public Cemuhook.DeviceType get_device_type() { return devtype; }
		public Cemuhook.ConnectionType get_connection_type() { return BLUETOOTH; }
		public Cemuhook.BatteryStatus get_battery() {
			try {
				var capacity = dev.get_battery();
				return NA;
			} catch(Error e) {
				return NA;
			}
		}

		public Cemuhook.BaseData get_base_inputs() { return {}; }
	}
}
