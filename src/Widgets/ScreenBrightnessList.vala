/*
 * Copyright 2026 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Power.ScreenBrightnessList : Granite.Box {
    private BrightnessManager brightness_manager;
    private Gtk.ListBox list_box;

    public ScreenBrightnessList () {
        Object (
            orientation: Gtk.Orientation.VERTICAL,
            child_spacing: Granite.Box.Spacing.HALF
        );
    }

    construct {
        brightness_manager = BrightnessManager.get_default ();

        list_box = new Gtk.ListBox () {
            selection_mode = Gtk.SelectionMode.NONE,
            show_separators = true
        };
        list_box.add_css_class (Granite.STYLE_CLASS_RICH_LIST);
        list_box.add_css_class (Granite.STYLE_CLASS_FRAME);

        var header = new Granite.HeaderLabel (_("Monitors brightness")) {
            mnemonic_widget = list_box
        };
        append (header);
        append (list_box);

        populate_list ();

        brightness_manager.monitors_changed.connect (populate_list);
    }

    private void populate_list () {
        list_box.remove_all ();
        for (int i = 0; i < brightness_manager.get_n_monitors (); i++) {
            list_box.append (new ScreenBrightnessRow (i));
        }
    }
}
