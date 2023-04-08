public class ${APP_NAMESPACE}.MainWindow : Adw.ApplicationWindow {
    public MainWindow (Gtk.Application app) {
        Object (
            application: app,
        );
    }

    static construct {
        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource (Constants.APP_PATH + "app.css");
    
        Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }

    construct {
        Intl.setlocale (GLib.LocaleCategory.ALL, "");
        Intl.bindtextdomain (Constants.GETTEXT_PACKAGE, Constants.LOCALEDIR);
        Intl.bind_textdomain_codeset (Constants.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (Constants.GETTEXT_PACKAGE);


        var header = new Adw.HeaderBar ();
        var layout_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        var text_view = new Gtk.TextView () {
            text = _("Hello World");
        };

        layout_box.append (header);
        layout_box.append (text_view);

        this.set_content (layout_box);
    }
}
