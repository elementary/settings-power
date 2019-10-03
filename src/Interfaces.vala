/*
 * Copyright (c) 2011-2016 elementary LLC. (https://launchpad.net/switchboard-plug-power)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA  02110-1301, USA.
 */

namespace Power {
    public const string DBUS_UPOWER_NAME = "org.freedesktop.UPower";
    public const string DBUS_UPOWER_PATH = "/org/freedesktop/UPower";
    public const string LOGIND_HELPER_NAME = "io.elementary.logind.helper";
    public const string LOGIND_HELPER_OBJECT_PATH = "/io/elementary/logind/helper";

    [DBus (name = "org.freedesktop.DBus")]
    public interface DBus : Object {
        [DBus (name = "GetConnectionUnixProcessID")]
        public abstract uint32 get_connection_unix_process_id (string name) throws IOError;

        public abstract uint32 get_connection_unix_user (string name) throws IOError;
    }

    [DBus (name = "io.elementary.logind.helper")]
    public interface LogindHelperIface : Object {
        public abstract bool present { get; }
        public abstract void set_key (string key, string value) throws IOError;
        public abstract string get_key (string key) throws IOError;
        public signal void changed ();
    }

    [DBus (name = "org.gnome.SettingsDaemon.Power.Screen")]
    interface PowerSettings : GLib.Object {
        public abstract int brightness {get; set; }
    }

    [DBus (name = "org.freedesktop.UPower.Device")]
    interface UpowerDevice : Object {
        public signal void changed ();
        public abstract void refresh () throws IOError;
        public abstract bool online { owned get; }
        public abstract bool power_supply { owned get; }
        public abstract bool is_present { owned get; }
        [DBus (name = "Type")]
        public abstract uint device_type { owned get; }
    }


    [DBus (name = "org.freedesktop.UPower")]
    interface Upower : Object {
        public signal void changed ();
        public abstract bool on_battery { owned get; }
        public abstract bool low_on_battery { owned get; }
        public abstract ObjectPath[] enumerate_devices () throws IOError;
    }
}
