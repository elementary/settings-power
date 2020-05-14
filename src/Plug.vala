/*
 * Copyright (c) 2011-2018 elementary, Inc. (https://elementary.io)
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
    private GLib.Settings settings;

    public class Plug : Switchboard.Plug {
        private DisplayView display_view;
        private HardwareView hardware_view;
        private SuspendView suspend_view;
        private Gtk.Stack stack;
        private Gtk.Paned hpaned;

        public Plug () {
            var supported_settings = new Gee.TreeMap<string, string?> (null, null);
            supported_settings["power"] = null;

            Object (category: Category.HARDWARE,
                code_name: "io.elementary.switchboard.power",
                display_name: _("Power"),
                description: _("Configure display brightness, power buttons, and suspend behavior"),
                icon: "preferences-system-power",
                supported_settings: supported_settings);
        }

        public override Gtk.Widget get_widget () {
            if (hpaned == null) {
                display_view = new DisplayView ();
                hardware_view = new HardwareView ();
                suspend_view = new SuspendView ();

                stack = new Gtk.Stack ();
                stack.add_named (display_view, "display");
                stack.add_named (hardware_view, "hardware");
                stack.add_named (suspend_view, "suspend");

                var switcher = new Granite.SettingsSidebar (stack);

                hpaned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
                hpaned.pack1 (switcher, false, false);
                hpaned.add (stack);
                hpaned.show_all ();
            }

            return hpaned;
        }

        public override void shown () {
            if (hardware_view.battery.is_present ()) {
                hardware_view.stack.visible_child_name = "battery";
            } else {
                hardware_view.stack.visible_child_name = "ac";
            }
        }

        public override void hidden () {

        }

        public override void search_callback (string location) {

        }

        // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
        public override async Gee.TreeMap<string, string> search (string search) {
            var search_results = new Gee.TreeMap<string, string> ((GLib.CompareDataFunc<string>)strcmp, (Gee.EqualDataFunc<string>)str_equal);
            search_results.set ("%s → %s".printf (display_name, _("Suspend button")), "");
            search_results.set ("%s → %s".printf (display_name, _("Power button")), "");
            search_results.set ("%s → %s".printf (display_name, _("Display inactive")), "");
            search_results.set ("%s → %s".printf (display_name, _("Dim display")), "");
            search_results.set ("%s → %s".printf (display_name, _("Lid close")), "");
            search_results.set ("%s → %s".printf (display_name, _("Display brightness")), "");
            search_results.set ("%s → %s".printf (display_name, _("Automatic brightness adjustment")), "");
            search_results.set ("%s → %s".printf (display_name, _("Inactive display off")), "");
            search_results.set ("%s → %s".printf (display_name, _("Docked lid close")), "");
            search_results.set ("%s → %s".printf (display_name, _("Suspend inactive")), "");
            return search_results;
        }
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Power plug");
    var plug = new Power.Plug ();
    return plug;
}
