class Starter.App : Gtk.Application {
  public App () {
    Object (application_id: "org.gnome.${PROGRAM_NAME}",
                     flags: ApplicationFlags.FLAGS_NONE);
  }

  public override void activate () {
    base.activate ();

    if (this.get_active_window () == null) {
      var window = new MainWindow ();
      this.add_window (window);
    }

    this.active_window.present ();
  }
}

int main(string[] args) {
  return new Starter.App ().run (args);
}
