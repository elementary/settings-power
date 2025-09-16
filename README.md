# Power Settings
[![Packaging status](https://repology.org/badge/tiny-repos/switchboard-plug-power.svg)](https://repology.org/metapackage/switchboard-plug-power)
[![Translation status](https://l10n.elementaryos.org/widget/settings/power/svg-badge.svg)](https://l10n.elementaryos.org/engage/settings/)

![screenshot](data/screenshot.png?raw=true)

## Building and Installation

You'll need the following dependencies:

* gio-2.0 (>=2.74)
* libadwaita-1-dev
* libdbus-1-dev
* libswitchboard-3-dev
* libgranite-7-dev
* libpolkit-gobject-1-dev
* meson
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    ninja install
