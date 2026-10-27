/*
 * Copyright 2026 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Authored by: Denis Garaev <garaevdi@outlook.com>
 */

public class Power.ScreenBrightnessRow : Granite.ListItem {
    private const double BRIGHTNESS_STEP = 0.005;

    private BrightnessManager brightness_manager;
    private Gtk.Scale brightness_slider;
    private ulong slider_signal;
    private ulong bm_signal;

    private double total_y_delta = 0;
    private double total_x_delta = 0;

    public int index { get; construct; }

    public ScreenBrightnessRow (int index) {
        Object (index: index);
    }

    construct {
        brightness_manager = BrightnessManager.get_default ();

        var scroll_controller = new Gtk.EventControllerScroll (BOTH_AXES);
        scroll_controller.scroll.connect (on_scroll);
        add_controller (scroll_controller);

        var monitor_label = new Gtk.Label (brightness_manager.get_monitor_name (index)) {
            margin_start = 2,
            margin_top = 2,
            halign = Gtk.Align.START
        };

        text = brightness_manager.get_monitor_name (index);

        if (index == 0) {
            description = _("Primary");
        }

        var text_box = child;
        child = null;

        brightness_slider = new Gtk.Scale.with_range (HORIZONTAL, 0, 1, 0.1) {
            margin_start = 2,
            margin_end = 2,
            hexpand = true,
            draw_value = false,
            width_request = 175
        };

        var box = new Granite.Box(HORIZONTAL, SINGLE);
        box.append (text_box);
        box.append (brightness_slider);
        child = box;

        slider_signal = brightness_slider.value_changed.connect (on_value_changed_internally);
        bm_signal = brightness_manager.monitor_brightness_changed.connect (on_value_changed_externally);

        brightness_slider.set_value (brightness_manager.get_monitor_brightness (index));
    }

    // We'd need to disable signals temporary here, so there wouldn't be a vicious signal loop
    private void on_value_changed_internally (Gtk.Range value) {
        SignalHandler.block (brightness_manager, bm_signal);
        brightness_manager.set_monitor_brightness (index, value.get_value ());
        SignalHandler.unblock (brightness_manager, bm_signal);
    }

    private void on_value_changed_externally (int ch_index, double value) {
        if (index != ch_index) {
            return;
        }

        SignalHandler.block (brightness_slider, slider_signal);
        brightness_slider.set_value (value);
        SignalHandler.unblock (brightness_slider, slider_signal);
    }

    private bool on_scroll (Gtk.EventControllerScroll controller, double dx, double dy) {
        var event = (Gdk.ScrollEvent) controller.get_current_event ();
        var event_device = event.get_device ();
        bool natural_scroll;
        var mouse_settings = new GLib.Settings ("org.gnome.desktop.peripherals.mouse");
        var touchpad_settings = new GLib.Settings ("org.gnome.desktop.peripherals.touchpad");

        var dir = 0.0;

        if (event.get_device () == null) {
            return false;
        }


        if (event_device.source == Gdk.InputSource.MOUSE) {
            natural_scroll = mouse_settings.get_boolean ("natural-scroll");
        } else if (event_device.source == Gdk.InputSource.TOUCHPAD) {
            natural_scroll = touchpad_settings.get_boolean ("natural-scroll");
        } else {
            natural_scroll = true;
        }

        double delta_x, delta_y;
        event.get_deltas (out delta_x, out delta_y);

        switch (event.get_direction ()) {
        case Gdk.ScrollDirection.SMOOTH:
            var abs_x = double.max (delta_x.abs (), 0.0001);
            var abs_y = double.max (delta_y.abs (), 0.0001);

            if (abs_y / abs_x > 2.0) {
                total_y_delta += delta_y;
            } else if (abs_x / abs_y > 2.0) {
                total_x_delta += delta_x;
            }

            break;
        case Gdk.ScrollDirection.UP:
            total_y_delta = -1.0;
            break;
        case Gdk.ScrollDirection.DOWN:
            total_y_delta = 1.0;
            break;
        case Gdk.ScrollDirection.LEFT:
            total_x_delta = -1.0;
            break;
        case Gdk.ScrollDirection.RIGHT:
            total_x_delta = 1.0;
            break;
        default:
            break;
        }

        if (total_y_delta.abs () * BRIGHTNESS_STEP > 0.001) {
            dir = natural_scroll ? total_y_delta : -total_y_delta;
        } else if (total_x_delta.abs () * BRIGHTNESS_STEP > 0.001) {
            dir = natural_scroll ? -total_x_delta : total_x_delta;
        }

        if (dir.abs () > 0.0) {
            total_y_delta = 0.0;
            total_x_delta = 0.0;
            var delta = (brightness_manager.get_monitor_brightness (index) + dir * BRIGHTNESS_STEP);
            brightness_manager.set_monitor_brightness (index, delta);
        }

        return Gdk.EVENT_STOP;
    }
}
