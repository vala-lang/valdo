public class ${APP_NAMESPACE}.MainWindow : Gtk.ApplicationWindow {
    public MainWindow (Gtk.Application app) {
        Object (
            application: app
        );
    }

    static construct {
        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource (Constants.APP_PATH + "style.css");

        Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }

    construct {
        var label = new Gtk.Label (_("Hello World"));
        label.vexpand = true;
        label.valign = Gtk.Align.CENTER;
        label.hexpand = true;
        label.halign = Gtk.Align.CENTER;

        var layout_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        layout_box.append (label);

        this.set_child (layout_box);
    }
}
