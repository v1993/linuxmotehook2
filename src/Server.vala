/* Server.vala
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
	sealed class Server: Cemuhook.Server {
		private XWiimote.Monitor monitor;

		private UnixInputStream monitor_stream;
		private PollableSource monitor_source;

		public Server(uint16 port = 26760, MainContext? context = null) throws GLib.Error {
			base(port, context);
			new LMApplication().hold();
			monitor = XWiimote.Monitor.create(true);
			if (monitor == null) {
				monitor = XWiimote.Monitor.create(true, true);
			}
			assert_nonnull(monitor);
			monitor_stream = new UnixInputStream(monitor.get_fd(), false);
			monitor_source = monitor_stream.create_source();
			// The following produces a warning, and it is intended
			PollableSourceFunc cb = add_available_wiimotes;
			monitor_source.set_callback(cb);
			monitor_source.attach(context);

			add_available_wiimotes();
		}

		~Server() {
			monitor_source.destroy();
			new LMApplication().release();
		}

		private bool add_available_wiimotes() {
			for (var? path = monitor.poll(); path != null; path = monitor.poll()) {
				add_wiimote(path);
			}
			return Source.CONTINUE;
		}

		private void add_wiimote(string path) {
			try {
				var dev = XWiimote.Device.create(path);
				add_wiimote_device(dev);
			} catch(Error e) {
				warning("Failed to open wiimote: %s", e.message);
			}
		}

		private void add_wiimote_device(XWiimote.Device dev) {
			try {
				if (dev.get_devtype() == "unknown") {
					// This commonly happens for hotplug, so retry once device is ready
					// Note: these callbacks hold owning reference
					GLib.Timeout.add(500, () => {
						add_wiimote_device(dev);
						return Source.REMOVE;
					});
					return;
				}

				// TODO: code for actually adding wiimote to server
				print("Device MAC: 0x%llX\n", dev.get_mac());
				print("Device type: %s\n", dev.get_devtype());
				print("Extension type: %s\n", dev.get_extension());
				print("Battery: %d\n", dev.get_battery());
			} catch(Error e) {
				warning("Failed to add wiimote: %s", e.message);
			}
		}
	}
}
