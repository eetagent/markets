[GtkTemplate (ui = "/biz/zaxo/Markets/MainHeaderBar.ui")]
public class Markets.MainHeaderBar : Gtk.Widget {
    private Markets.MainWindow window;
    private Markets.State state;

    [GtkChild]
    private unowned Gtk.MenuButton menu_button;

    [GtkChild]
    private unowned Gtk.Spinner spinner;

    public MainHeaderBar (MainWindow window, State state) {
        this.window = window;
        this.state = state;
        this.set_layout_manager (new Gtk.BinLayout ());

        this.state.notify["network-status"].connect (this.on_network_status_updated);
    }

    [GtkCallback]
    private void on_add_clicked () {
        var dialog = new NewSymbolDialog (this.window, this.state);
        dialog.present ();
    }

    [GtkCallback]
    private void on_select_clicked () {
        this.state.view_mode = State.ViewMode.SELECTION;
    }

    private void on_network_status_updated () {
        this.spinner.visible =
            this.state.network_status == State.NetworkStatus.IN_PROGRESS;
    }
}
