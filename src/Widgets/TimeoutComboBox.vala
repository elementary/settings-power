/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2011-2025 elementary, Inc. (https://elementary.io)
 */

class Power.TimeoutComboBox : Granite.Bin {
    private Greeter.AccountsService? greeter_act = null;

    private string? _enum_property = null;
    public string? enum_property {
        get {
            return _enum_property;
        }
        set {
            if (value != _enum_property) {
                _enum_property = value;
                update_combo ();
            }
        }
    }

    private int _enum_never_value = -1;
    public int enum_never_value {
        get {
            return _enum_never_value;
        }
        set {
            if (value != _enum_never_value) {
                _enum_never_value = value;
                update_combo ();
            }
        }
    }

    private int _enum_normal_value = -1;
    public int enum_normal_value {
        get {
            return _enum_normal_value;
        }
        set {
            if (value != _enum_normal_value) {
                _enum_normal_value = value;
                update_combo ();
            }
        }
    }

    public GLib.Settings schema { get; construct; }
    public string key { get; construct; }
    private VariantType key_type;
    private Gtk.DropDown dropdown;

    private const int SECS_IN_MINUTE = 60;
    private const int[] TIMEOUT = {
        0,
        5 * SECS_IN_MINUTE,
        10 * SECS_IN_MINUTE,
        15 * SECS_IN_MINUTE,
        30 * SECS_IN_MINUTE,
        45 * SECS_IN_MINUTE,
        60 * SECS_IN_MINUTE,
        120 * SECS_IN_MINUTE
    };

    public TimeoutComboBox (GLib.Settings schema, string key) {
        Object (key: key, schema: schema);

        update_combo ();
    }

    construct {
        key_type = schema.get_value (key).get_type ();

        var liststore = new GLib.ListStore (typeof (Timeout));
        liststore.append (new Timeout (_("Never"), 0, _("(Results in higher energy usage)")));
        liststore.append (new Timeout (_("5 min"), 5 * SECS_IN_MINUTE));
        liststore.append (new Timeout (_("10 min"), 10 * SECS_IN_MINUTE));
        liststore.append (new Timeout (_("15 min"), 15 * SECS_IN_MINUTE));
        liststore.append (new Timeout (_("30 min"), 30 * SECS_IN_MINUTE));
        liststore.append (new Timeout (_("45 min"), 45 * SECS_IN_MINUTE));
        liststore.append (new Timeout (_("1 hour"), 60 * SECS_IN_MINUTE));
        liststore.append (new Timeout (_("2 hours"), 120 * SECS_IN_MINUTE));

        var factory = new Gtk.SignalListItemFactory ();
        factory.bind.connect (bind_factory);

        dropdown = new Gtk.DropDown (liststore, null) {
            factory = factory
        };

        child = dropdown;

        setup_accountsservice.begin ();

        dropdown.notify["selected"].connect (update_settings);
        schema.changed[key].connect (update_combo);
    }

    private async void setup_accountsservice () {
        try {
            var accounts_service = yield GLib.Bus.get_proxy<FDO.Accounts> (GLib.BusType.SYSTEM,
                                                                           "org.freedesktop.Accounts",
                                                                           "/org/freedesktop/Accounts");
            var user_path = accounts_service.find_user_by_name (GLib.Environment.get_user_name ());

            greeter_act = yield GLib.Bus.get_proxy (GLib.BusType.SYSTEM,
                                                    "org.freedesktop.Accounts",
                                                    user_path,
                                                    GLib.DBusProxyFlags.GET_INVALIDATED_PROPERTIES);
        } catch (Error e) {
            warning ("Unable to get AccountsService proxy, greeter power settings may be incorrect");
        }
    }

    private void update_settings () {
        if (enum_property != null && enum_never_value != -1 && enum_normal_value != -1) {
            if (dropdown.selected == 0) {
                schema.set_enum (enum_property, enum_never_value);
            } else {
                schema.set_enum (enum_property, enum_normal_value);
            }
        }

        schema.changed[key].disconnect (update_combo);

        if (key_type.equal (VariantType.UINT32)) {
            schema.set_uint (key, (uint) ((Timeout) dropdown.selected_item).seconds);
        } else if (key_type.equal (VariantType.INT32)) {
            schema.set_int (key, ((Timeout) dropdown.selected_item).seconds);
        } else {
            critical ("Unsupported key type in schema");
        }

        schema.changed[key].connect (update_combo);

        if (greeter_act != null) {
            if (key == "sleep-inactive-ac-timeout") {
                greeter_act.sleep_inactive_ac_timeout = ((Timeout) dropdown.selected_item).seconds;
                greeter_act.sleep_inactive_ac_type = schema.get_enum (enum_property);
            } else if (key == "sleep-inactive-battery-timeout") {
                greeter_act.sleep_inactive_battery_timeout = ((Timeout) dropdown.selected_item).seconds;
                greeter_act.sleep_inactive_battery_type = schema.get_enum (enum_property);
            }
        }
    }

    // find closest timeout to our level
    private int find_closest (int second) {
        int key = 0;

        foreach (int i in TIMEOUT) {
            if (second > i)
                key++;
            else
                break;
        }

        return key;
    }

    private void update_combo () {
        int val = 0;

        if (key_type.equal (VariantType.UINT32)) {
            val = (int)schema.get_uint (key);
        } else if (key_type.equal (VariantType.INT32)) {
            val = schema.get_int (key);
        } else {
            critical ("Unsupported key type in schema");
        }

        if (enum_property != null && enum_never_value != -1 && enum_normal_value != -1) {
            var enum_value = schema.get_enum (enum_property);
            if (enum_value == enum_never_value) {
                dropdown.selected = 0;
                return;
            }
        }

        // need to process value to comply our timeout level
        dropdown.notify["selected"].disconnect (update_settings);
        dropdown.selected = find_closest (val);
        dropdown.notify["selected"].connect (update_settings);
    }

    private void bind_factory (Object object) {
        var list_item = (Gtk.ListItem) object;
        var timeout = (Timeout) list_item.item;
        list_item.child = timeout.get_widget ();
    }

    private class Timeout : Object {
        public string label { get; construct; }
        public string description { get; construct; }
        public int seconds { get; construct; }

        public Timeout (string label, int seconds, string description = "") {
            Object (
                label: label,
                seconds: seconds,
                description: description
            );
        }

        public Gtk.Widget get_widget () {
            var title = new Gtk.Label (label) {
                valign = BASELINE,
                xalign = 0
            };

            var box = new Granite.Box (HORIZONTAL, HALF);
            box.append (title);

            if (description != "") {
                var description = new Gtk.Label (description) {
                    valign = BASELINE,
                    xalign = 0,
                    wrap = true
                };
                description.add_css_class (Granite.CssClass.SMALL);
                description.add_css_class (Granite.CssClass.WARNING);

                box.append (description);
            }

            return box;
        }
    }
}
