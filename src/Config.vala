/* Config.vala
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
	public class WiimoteConfig: Object {
		public int gyro_calibration[3];
		public Cemuhook.DeviceOrientation orientation;
		public bool send_buttons;
		public int nunchuck_stick_calibration[4];
		public int classic_controller_stick_calibration[8];

		// TODO: initialize fields directly once initializing from arrays is fixed
		// Also don't incherit from Object once that's done
		construct {
			gyro_calibration = {0, 0, 0};
			orientation = NORMAL;
			send_buttons = false;
			nunchuck_stick_calibration = {0, 0, 80, 80};
			classic_controller_stick_calibration = {0, 0, 25, 25, 0, 0, 25, 25};
		}
	}

	private int[] kfile_get_integer_list_checked(KeyFile kfile, string group, string key, size_t length) throws KeyFileError {
		var arr = kfile.get_integer_list(group, key);
		if (arr.length != length) {
			throw new KeyFileError.INVALID_VALUE("group `%s', key `%s': expected integer array of length %zu, got %zu", group, key, length, arr.length);
		}
		return arr;
	}

	[SingleInstance]
	public class Config: Object {
		private const string MAIN_GROUP = "Linuxmotehook";

		public KeyFile kfile { get; construct; }

		private Gee.HashMap<uint64?, WiimoteConfig> wiimote_configs;

		private uint16 port_ = 26760;
		public uint16 port {
			get { return port_; }
			set {
				port_ = value;
				kfile.set_uint64(MAIN_GROUP, "Port", value);
			}
		}

		private Cemuhook.DeviceOrientation orientation_;
		public Cemuhook.DeviceOrientation orientation {
			get { return orientation_; }
			set {
				orientation_ = value;
				kfile.set_uint64(MAIN_GROUP, "Orientation", value);
			}
		}

		private bool send_buttons_ = false;
		public bool send_buttons {
			get { return send_buttons_; }
			set {
				send_buttons_ = value;
				kfile.set_boolean(MAIN_GROUP, "SendButtons", value);
			}
		}

		private int gyro_normalization_factor_ = 50;
		public int gyro_normalization_factor {
			get { return gyro_normalization_factor_; }
			set {
				gyro_normalization_factor_ = value;
				kfile.set_integer(MAIN_GROUP, "GyroNormalizationFactor", value);
			}
		}

		construct {
			kfile = new KeyFile();
			kfile.set_list_separator(',');
			// Note: this likely creates a circular reference because of lambdas
			// Nobody really cares because we're single instance, but still
			wiimote_configs = new Gee.HashMap<uint64?, WiimoteConfig>(
				(key) => { return (uint)((key >> 32) ^ key); },
				(key1, key2) => { return key1 == key2; }
			);
		}

		public void init_from_keyfile() throws KeyFileError {
			if (kfile.has_group(MAIN_GROUP)) {
				foreach (unowned string key in kfile.get_keys(MAIN_GROUP)) {
					switch(key) {
						case "Port":
							port_ = (uint16)kfile.get_uint64(MAIN_GROUP, key);
							break;
						case "Orientation":
							var orient = kfile.get_string(MAIN_GROUP, key);
							if (!Cemuhook.DeviceOrientation.try_parse(orient, out orientation_)) {
								warning("Unknown orientation %s", orient);
							}
							break;
						case "SendButtons":
							send_buttons_ = kfile.get_boolean(MAIN_GROUP, key);
							break;
						case "GyroNormalizationFactor":
							gyro_normalization_factor_ = kfile.get_integer(MAIN_GROUP, key);
							break;
						default:
							warning("Unknown configuration key %s", key);
							break;
					}
				}
			}

			// Load per-wiimote configuration
			foreach (unowned string group in kfile.get_groups()) {
				if (group == MAIN_GROUP) {
					// Main configuration - already handled
					continue;
				}

				var regex = /^0x([[:xdigit:]][[:xdigit:]][[:xdigit:]][[:xdigit:]][[:xdigit:]][[:xdigit:]][[:xdigit:]][[:xdigit:]][[:xdigit:]][[:xdigit:]][[:xdigit:]][[:xdigit:]])$/;
				MatchInfo minfo;
				if (!regex.match(group, 0, out minfo)) {
					warning("Unidentified configuration group %s", group);
					continue;
				}

				var mac = uint64.parse(minfo.fetch(1), 16);
				assert(mac != 0);
				assert((mac >> 48) == 0);

				var conf = new WiimoteConfig();
				conf.orientation = orientation;
				conf.send_buttons = send_buttons;

				foreach (unowned string key in kfile.get_keys(group)) {
					switch(key) {
						case "GyroCalibration":
							conf.gyro_calibration = kfile_get_integer_list_checked(kfile, group, key, 3);
							break;
						case "Orientation":
							var orient = kfile.get_string(group, key);
							if (!Cemuhook.DeviceOrientation.try_parse(orient, out conf.orientation)) {
								warning("Unknown orientation %s", orient);
							}
							break;
						case "SendButtons":
							conf.send_buttons = kfile.get_boolean(group, key);
							break;
						case "NunchuckStickCalibration":
							conf.nunchuck_stick_calibration = kfile_get_integer_list_checked(kfile, group, key, 4);
							break;
						case "ClassicControllerStickCalibration":
							conf.classic_controller_stick_calibration = kfile_get_integer_list_checked(kfile, group, key, 8);
							break;
						default:
							warning("Unknown configuration key %s", key);
							break;
					}
				}

				wiimote_configs[mac] = conf;
			}
		}

		public WiimoteConfig? get_device_config(uint64 mac)
		requires (mac >> 48 == 0) {
			if (wiimote_configs.has_key(mac)) {
				return wiimote_configs[mac];
			}

			return null;
		}

		public void set_device_config(uint64 mac, WiimoteConfig conf)
		requires (mac >> 48 == 0) {
			wiimote_configs[mac] = conf;

			var group = format_mac(mac);
			kfile.set_integer_list(group, "GyroCalibration", conf.gyro_calibration);
			kfile.set_string(group, "Orientation", conf.orientation.to_string());
			kfile.set_boolean(group, "SendButtons", conf.send_buttons);
			kfile.set_integer_list(group, "NunchuckStickCalibration", conf.nunchuck_stick_calibration);
			kfile.set_integer_list(group, "ClassicControllerStickCalibration", conf.classic_controller_stick_calibration);
		}
	}
}
