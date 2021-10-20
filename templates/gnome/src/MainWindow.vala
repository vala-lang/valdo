namespace ${APP_NAMESPACE} {
    [GtkTemplate (ui = "${APP_PATH}ui/MainWindow.ui")]
    class MainWindow : Adw.ApplicationWindow {
        public MainWindow (Application app) {
            Object (
                application: app
            );
        }
    }
}
