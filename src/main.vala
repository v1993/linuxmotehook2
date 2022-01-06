/* main.vala
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

using Linuxmotehook;

extern const string LM_VERSION;

/*
// To be implemented in gcemuhook
enum DeviceOrientation {
	NORAML,
	SIDEWAYS,
	NORMAL_INVERTED
}*/

[SingleInstance]
class LMApplication : Application {
	private bool exit_scheduled = false;
	public Server? server;

	public bool send_buttons { get; private set; default = true; } // FIXME: defualt false
	public bool send_ir { get; private set; default = true; } // FIXME: defualt false

	public float AccelUnitsPerG { get; private set; default = 103f; }
	public float GyroUnitsPerDegPerSec { get; private set; default = 335160f/1860f; }

	construct {
		application_id = "org.v1993.linuxmotehook2";
		flags = ApplicationFlags.NON_UNIQUE/* | ApplicationFlags.HANDLES_COMMAND_LINE*/;
	}

	public override void activate() {
		hold();
	}

	public override int handle_local_options(VariantDict options) {
		print("Version: %s\n", LM_VERSION);
		return -1;
	}

	public bool handle_shutdown_signal() {
		if (!exit_scheduled) {
			exit_scheduled = true;
			print("Exiting (press Ctrl+C again to force-exit)\n");
			server = null;
			release();
			return true;
		} else {
			print("Force quitting!\n");
			quit();
			return false;
		}
	}
}

int main(string[] args) {
	try {
		var app = new LMApplication();
		app.server = new Server();
		GLib.Unix.signal_add(2, app.handle_shutdown_signal);
		GLib.Unix.signal_add(15, app.handle_shutdown_signal);
		app.run(args);
	} catch(Error e) {
		print(@"Runtime error: $(e.message)\n");
		return 1;
	}

	return 0;
}
