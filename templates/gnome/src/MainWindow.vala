namespace ${APP_NAMESPACE} {
    [GtkTemplate (ui = "${APP_PATH}ui/MainWindow.ui")]
    class MainWindow : Adw.ApplicationWindow {
        [GtkChild]
        private unowned Gtk.Label label;
        public MainWindow (Application app) {
            Object (
                application: app
            );
        }
    }
}
