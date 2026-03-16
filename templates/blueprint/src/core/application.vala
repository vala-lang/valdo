namespace ${APP_NAMESPACE} {

    public class Application : Adw.Application {

        public Application() {
            Object(
                application_id: "${APP_ID}",
                flags: ApplicationFlags.FLAGS_NONE
            );
        }

        public override void activate() {
            base.activate();
            var win = active_window ?? new MainWindow(this);

            win.present();
        }
    }
}

