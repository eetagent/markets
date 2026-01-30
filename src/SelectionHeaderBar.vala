[GtkTemplate (ui = "/biz/zaxo/Markets/SelectionHeaderBar.ui")]
public class Markets.SelectionHeaderBar : Gtk.Widget {

    [GtkChild]
    private unowned Gtk.Button delete_button;

    [GtkChild]
    private unowned Gtk.Button cancel_button;

    private State state;

    public SelectionHeaderBar (MainWindow window, State state) {
        this.state = state;
        this.set_layout_manager (new Gtk.BinLayout ());

        this.state.notify["has-selected"].connect (this.on_has_selected_updated);

        this.on_has_selected_updated ();

        var controller = new Gtk.ShortcutController ();
        var trigger = Gtk.ShortcutTrigger.parse_string ("Escape");
        var action = new Gtk.CallbackAction ((widget, args) => {
            this.on_cancel_clicked ();
            return true;
        });
        controller.add_shortcut (new Gtk.Shortcut (trigger, action));
        this.add_controller (controller);
    }

    [GtkCallback]
    private void on_cancel_clicked () {
        this.state.view_mode = State.ViewMode.PRESENTATION;
    }

    [GtkCallback]
    private void on_delete_clicked () {
        Gee.ArrayList<string> ids = new Gee.ArrayList<string> ();
        foreach (Symbol symbol in this.state.symbols) {
            if (symbol.selected) {
                ids.add (symbol.id);
            }
        }

        this.state.remove_symbols (ids);
    }

    private void on_has_selected_updated () {
        this.delete_button.sensitive = this.state.has_selected;
    }
}
