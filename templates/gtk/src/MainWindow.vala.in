[GtkTemplate (ui = "/org/gnome/${PROGRAM_NAME}/main-window.ui")]
class Starter.MainWindow : Gtk.ApplicationWindow {
  [GtkChild] unowned Gtk.Label text;

  [GtkCallback]
  private void button_clicked () {
    text.label = "clicked!";
  }
}
