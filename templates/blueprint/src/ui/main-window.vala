namespace ${APP_NAMESPACE} {

    [GtkTemplate (ui = "${APP_PATH}ui/window.ui")]
    public class MainWindow : Adw.ApplicationWindow {

        public MainWindow(Gtk.Application app) {
            Object(application: app);
        }
    }
}
