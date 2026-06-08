/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2026 elementary, Inc. (https://elementary.io)
 */

public class Power.AccessibleDropDown : Gtk.Box {
    public signal void selection_changed ();

    public string[] strings { get; construct; }
    public uint selected {
        get {
            return dropdown.selected;
        }

        set {
            dropdown.selected = value;
        }
    }

    public Gtk.DropDown dropdown { get; private set; }
    public bool show_selected_icon { get; construct; }
    private ListStore model;

    // Array parameter can contain strings with a mnenomic character specified by a preceding underscore
    public AccessibleDropDown (string[] mnemonic_strings, bool show) {
        Object (
            strings: mnemonic_strings,
            show_selected_icon: show
        );
    }

    construct {
        model = new ListStore (typeof (Gtk.StringObject));
        foreach (string s in strings) {
            model.append (new Gtk.StringObject (s));
        }

        var f = new Gtk.SignalListItemFactory ();
        f.setup.connect ((obj) => {
            var li = (Gtk.ListItem)obj;
            var widget = new ItemWidget ("", this);
            li.set_child (widget);
            li.bind_property ("selected", widget, "selected", DEFAULT);
            li.bind_property ("position", widget, "pos", DEFAULT);
        });
        f.bind.connect ((obj) => {
            var li = (Gtk.ListItem)obj;
            var widget = (ItemWidget)(li.child);
            var text = ((Gtk.StringObject)(li.get_item ())).get_string ();
            widget.label.set_text_with_mnemonic (text);
        });
        f.unbind.connect ((obj) => {
            // No action required
        });
        f.teardown.connect ((obj) => {
            // Do we need to reverse the property bindings created in setup?
            // Probably not because in this usage teardown only occurs when the dropdown closes
        });

        dropdown = new Gtk.DropDown (model, null) {
            factory = f
        };

        dropdown.notify["selected"].connect (() => {
            selection_changed ();
        });

        dropdown.mnemonic_activate.connect ((group_cycling) => {
            warning ("dropdown mnemonic activate - group cycling %s", group_cycling.to_string ());
            warning ("selected is %u", selected);
        });

        append (dropdown);
        bind_property ("hexpand", dropdown, "hexpand");
    }

    public void activate () {
        dropdown.activate ();
    }

    private class ItemWidget : Gtk.Grid {
        public Gtk.Label label { get; construct; }
        public AccessibleDropDown md { get; construct; }
        public bool selected { get; set; }
        public uint pos { get; set; }

        private Gtk.Button mnemonic_widget;
        private Gtk.Image icon;

        public ItemWidget (string text, AccessibleDropDown md) {
            Object (
                label: new Gtk.Label (text) {
                    use_underline = true,
                    halign = START,
                    hexpand = true
                },
                md: md
            );

            mnemonic_widget = new Gtk.Button () {
                halign = END
            };

            label.set_mnemonic_widget (this.mnemonic_widget);
            mnemonic_widget.mnemonic_activate.connect (() => {
                md.selected = pos;
                md.activate ();
                return false;
            });

            attach (label, 0, 0);
            if (md.show_selected_icon) {
                icon = new Gtk.Image.from_icon_name ("emblem-default") {
                    visible = selected
                };

                icon.add_css_class ("flat");
                attach (icon, 1, 0);
                bind_property ("selected", icon, "visible");
            }
        }

        construct {
            hexpand = md.hexpand;
        }
    }
}
