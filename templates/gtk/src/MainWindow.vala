public class ${NAMESPACE}.MainWindow : Gtk.ApplicationWindow {
    // GLib.ListStore clocks_list_store;
    public MainWindow (Gtk.Application app) {
        Object (application: app);

        this.default_height = 400;
        this.default_width = 600;

        var header = new Gtk.HeaderBar ();
        this.set_titlebar (header);

        var label = new Gtk.Label ("Hello World!");
        label.hexpand = label.vexpand = true;
        
        var button = new Gtk.Button.with_label ("Click Me!");

        button.clicked.connect (() => {
          var str = label.label;
          var temp_str = str.reverse ();
          label.label = temp_str;
        });

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
        box.append (label);
        box.append (button);

        this.child = box;
    }
}
