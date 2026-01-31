[GtkTemplate (ui = "/biz/zaxo/Markets/MainHeaderBar.ui")]
public class Markets.MainHeaderBar : Gtk.Widget {
    private Markets.MainWindow window;
    private Markets.State state;

    [GtkChild]
    private unowned Gtk.MenuButton menu_button;

    [GtkChild]
    private unowned Gtk.Button refresh_button;

    [GtkChild]
    public unowned Gtk.ToggleButton search_button;

    [GtkChild]
    private unowned Gtk.MenuButton filter_button;

    [GtkChild]
    private unowned Gtk.Spinner spinner;

    public MainHeaderBar (MainWindow window, State state) {
        this.window = window;
        this.state = state;
        this.set_layout_manager (new Gtk.BinLayout ());

        this.state.notify["network-status"].connect (this.on_network_status_updated);
        
        this.state.notify["groups"].connect (this.update_filter_menu);
        this.state.notify["current-group"].connect (this.update_filter_menu);
        this.update_filter_menu ();
    }

    private void update_filter_menu () {
        var menu = new GLib.Menu ();
        
        var section_filter = new GLib.Menu ();
        section_filter.append (_("All"), "win.set-group('')");
        
        foreach (string group in this.state.groups) {
             section_filter.append (group, @"win.set-group('$group')");
        }
        menu.append_section (null, section_filter);
        
        var section_manage = new GLib.Menu ();
        section_manage.append (_("Create Group..."), "win.create-group");
        
        if (this.state.current_group != "") {
            section_manage.append (_("Delete Group"), "win.delete-group");
        }
        
        menu.append_section (null, section_manage);
        
        this.filter_button.menu_model = menu;
    }

    [GtkCallback]
    private void on_search_toggled () {
        var search_bar = this.window.search_bar;
        if (search_bar != null) {
            search_bar.search_mode_enabled = this.search_button.active;
            
            // If disabled, clear query
            if (!this.search_button.active) {
                this.state.filter_query = "";
            }
        }
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

    [GtkCallback]
    private void on_refresh_clicked () {
        // Trigger a symbol update (which calls on_tick/update via store_symbols... wait, actually store_symbols just saves)
        // We need to trigger the update service logic.
        // The service listens to notify["symbols"].
        // But simply notifying might not be enough if the list hasn't changed.
        // Actually Service.vala has `on_tick` which calls `update`.
        // But `Service` is not directly accessible here, only `State`.
        // However, `State` doesn't have a "refresh" signal that Service listens to for *fetching*.
        // Service listens to `pull-interval` and `symbols`.
        
        // A hacky but effective way is to just trigger the symbols notification even if they haven't changed, 
        // because Service connects `this.state.notify["symbols"].connect (this.on_symbols_updated);`
        // and `on_symbols_updated` calls `this.on_tick ()`.
        
        this.state.notify_property ("symbols");
    }

    private void on_network_status_updated () {
        this.spinner.visible =
            this.state.network_status == State.NetworkStatus.IN_PROGRESS;
    }
}
