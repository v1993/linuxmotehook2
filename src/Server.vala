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

		private IOSource monitor_source;

		public Server(uint16 port = 26760, MainContext? context = null) throws GLib.Error {
			base(port, context);
			new LMApplication().hold();
			monitor = XWiimote.Monitor.create(true);
			if (monitor == null) {
				monitor = XWiimote.Monitor.create(true, true);
			}
			assert_nonnull(monitor);
			monitor_source = new IOSource(new IOChannel.unix_new(monitor.get_fd()), IN);
			// The following produces a warning, and it is intended
			IOFunc cb = add_available_wiimotes;
			monitor_source.set_callback(cb);
			monitor_source.attach(context);

			add_available_wiimotes();
		}

		~Server() {
			if (monitor_source != null)
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
				if (dev.get_devtype() == "unknown") {
					// This commonly happens for hotplug, so retry once device is ready
					// Note: these callbacks hold owning reference
					GLib.Timeout.add(1000, () => {
						add_wiimote(path);
						return Source.REMOVE;
					});
					return;
				}

				var mac = xwiimote_get_mac(dev);
				var conf = new Config();

				var? devconf = conf.get_device_config(mac);
				if (devconf != null) {
					print(@"Found wiimote $(format_mac(mac)) - connecting... ");
					add_device(new MainDevice((owned)dev, (owned)devconf));
					print("done!\n");
				} else {
					print(@"Wiimote $(format_mac(mac)) not in config - skipping\n");
				}
			} catch(Error e) {
				warning("Failed to setup wiimote: %s", e.message);
			}
		}
	}
}
