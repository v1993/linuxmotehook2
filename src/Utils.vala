/* Utils.vala
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

internal const string mac_fstring = "0x%012llX";
internal string format_mac(uint64 mac)
requires (mac >> 48 == 0) {
	return mac_fstring.printf(mac);
}

internal uint64 xwiimote_get_mac(XWiimote.Device dev) throws GLib.Error
ensures(result >> 48 == 0) {
	// This is nowhere near fully optimized, but it really doesn't need to be
	var uevent_file = GLib.File.new_build_filename(dev.get_syspath(), "uevent");
	var uevent_bytes = uevent_file.load_bytes();

	var regex = /HID_UNIQ=([[:xdigit:]][[:xdigit:]]):([[:xdigit:]][[:xdigit:]]):([[:xdigit:]][[:xdigit:]]):([[:xdigit:]][[:xdigit:]]):([[:xdigit:]][[:xdigit:]]):([[:xdigit:]][[:xdigit:]])/;
	GLib.MatchInfo info = null;
	if (!regex.match((string)uevent_bytes.get_data(), 0, out info) || info == null) {
		throw new GLib.IOError.NOT_FOUND("HID_UNIQ record missing");
	}

	var builder = new GLib.StringBuilder.sized(12);
	var matches = info.fetch_all()[1:];

	foreach (unowned var substr in matches) {
		builder.append(substr);
	}

	return uint64.parse(builder.str, 16);
}

internal uint8 apply_stick_calibration(int32 val, int32 center, int32 range) {
	return (uint8)((val - center) * 127 / range + Cemuhook.STICK_NEUTRAL).clamp(0, 255);
}

internal uint8 apply_analog_calibration(int32 val, int32 range) {
	return (uint8)(val * 255 / range).clamp(0, 255);
}
