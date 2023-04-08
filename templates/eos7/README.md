# ${APP_TITLE}

${APP_SUMMARY}

## Build Instructions

### Flatpak (Recommended)

Either:

-   Use Visual Studio Code with [Flatpak extension](https://marketplace.visualstudio.com/items?itemName=bilelmoussaoui.flatpak-vscode
-   Use [GNOME Builder](https://apps.gnome.org/en-GB/app/org.gnome.Builder/)
-   Flatpak integrations for of your preferred IDE/Code Editor
-   Or use the [flatpak and flatpak-builder](https://docs.flatpak.org/en/latest/first-build.htm) commands.

### Meson

#### Dependencies

-   glib-2.0
-   gobject-2.0
-   gee-0.8
-   gtk4
-   libadwaita-1
-   granite-7

#### Build Commands

To build:

```sh
meson build --prefix=/usr
cd build
ninja
```

To test:

(Assuming you're in the project root and have already built the app)

```sh
cd build
meson test
```

To install:

(Assuming you're in project root)

```sh
cd build
sudo ninja install
```
