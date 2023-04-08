public class ${APP_NAMESPACE}.Application : Gtk.Application {
    public Application () {
        Object (application_id: Constants.APP_ID);
    }

    protected override void activate () {
        var main_window = this.get_active_window ();

        if (main_window == null) {
            main_window = new MainWindow (this) {
                title = _("${APP_TITLE}")
            };

            // Enable elementary OS Libadwaita styling special case
            Granite.Settings.get_default ();

            // Initialise Libadwaita
            Adw.init ();

            // Light/Dark Theme handling
            Adw.StyleManager.get_default ().color_scheme = Adw.ColorScheme.PREFER_LIGHT;
        }

        main_window.present ();

        // Remember window state
        var settings = new Settings (Constants.APP_ID);
        settings.bind ("window-height", main_window, "default-height", SettingsBindFlags.DEFAULT);
        settings.bind ("window-width", main_window, "default-width", SettingsBindFlags.DEFAULT);

        if (settings.get_boolean ("window-maximized")) {
            main_window.maximize ();
        }

        settings.bind ("window-maximized", main_window, "maximized", SettingsBindFlags.SET);
    }

}

int main (string[] args) {
    var my_app = new ${APP_NAMESPACE}.Application ();
    return my_app.run (args);
}
