[GtkTemplate (ui = "/biz/zaxo/Markets/MainWindow.ui")]
public class Markets.MainWindow : Adw.ApplicationWindow {

    [GtkChild]
    private unowned Gtk.Stack stack;

    [GtkChild]
    private unowned Gtk.Box titlebar;

    [GtkChild]
    public unowned Gtk.SearchBar search_bar;

    [GtkChild]
    private unowned Gtk.SearchEntry search_entry;

    private State state;

    private MainHeaderBar main_header_bar;

    private SelectionHeaderBar selection_header_bar;

    private ChartHeaderBar chart_header_bar;

    public MainWindow (Gtk.Application app, State state) {
        Object (
            application: app,
            icon_name: Constants.APP_ID,
            title: _("Markets")
        );

        this.state = state;

        this.main_header_bar = new MainHeaderBar (this, state);

        this.selection_header_bar = new SelectionHeaderBar (this, state);
        this.selection_header_bar.visible = false;

        this.chart_header_bar = new ChartHeaderBar (this, state);
        this.chart_header_bar.visible = false;

        this.titlebar.append (this.main_header_bar);
        this.titlebar.append (this.selection_header_bar);
        this.titlebar.append (this.chart_header_bar);

        var symbols_view = new SymbolsView (this.state);
        stack.add_named (symbols_view, "symbols_view");

        var no_symbols_view = new NoSymbolsView ();
        stack.add_named (no_symbols_view, "no_symbols_view");

        var chart_view = new ChartView (this.state);
        stack.add_named (chart_view, "chart_view");

        this.close_request.connect (this.on_quit);
        this.state.notify["view-mode"].connect (this.on_selection_mode_update);
        this.state.notify["symbols"].connect (this.on_symbols_updated);
        this.state.notify["chart-symbol"].connect (this.on_chart_symbol_updated);
        this.on_symbols_updated ();

        this.set_default_size (this.state.window_width, this.state.window_height);

        // Setup search
        this.search_bar.connect_entry (this.search_entry);
        this.search_bar.set_key_capture_widget (this);
        
        // Listen for search toggle from headerbar
        this.state.notify["filter-query"].connect (this.on_filter_query_updated);

        // Setup keyboard shortcuts using actions
        this.setup_actions ();
    }

    private void setup_actions () {
        // Escape - Close search bar or chart view
        var escape_action = new SimpleAction ("escape", null);
        escape_action.activate.connect (() => {
            // First priority: close search bar if open
            if (this.search_bar.search_mode_enabled) {
                this.search_bar.search_mode_enabled = false;
            }
            // Second priority: close chart view if open
            else if (this.state.chart_symbol != null) {
                this.state.chart_symbol = null;
            }
        });
        this.add_action (escape_action);
        this.application.set_accels_for_action ("win.escape", {"Escape"});

        // Ctrl+R - Reload/Refresh
        var refresh_action = new SimpleAction ("refresh", null);
        refresh_action.activate.connect (() => {
            if (this.state.chart_symbol == null && this.state.symbols.size > 0) {
                this.state.notify_property ("symbols");
            }
        });
        this.add_action (refresh_action);
        this.application.set_accels_for_action ("win.refresh", {"<Control>R"});

        // Ctrl+F - Toggle search
        var search_action = new SimpleAction ("search", null);
        search_action.activate.connect (() => {
            if (this.state.chart_symbol == null && this.state.symbols.size > 0 && this.state.view_mode == State.ViewMode.PRESENTATION) {
                this.search_bar.search_mode_enabled = !this.search_bar.search_mode_enabled;
            }
        });
        this.add_action (search_action);
        this.application.set_accels_for_action ("win.search", {"<Control>F"});

        // Ctrl+A - Add symbol
        var add_action = new SimpleAction ("add", null);
        add_action.activate.connect (() => {
            if (this.state.chart_symbol == null) {
                var dialog = new NewSymbolDialog (this, this.state);
                dialog.present ();
            }
        });
        this.add_action (add_action);
        this.application.set_accels_for_action ("win.add", {"<Control>A"});

        // Ctrl+E - Enter selection mode
        var edit_action = new SimpleAction ("edit", null);
        edit_action.activate.connect (() => {
            if (this.state.chart_symbol == null && this.state.symbols.size > 0 && this.state.view_mode == State.ViewMode.PRESENTATION) {
                this.state.view_mode = State.ViewMode.SELECTION;
            }
        });
        this.add_action (edit_action);
        this.application.set_accels_for_action ("win.edit", {"<Control>E"});

        // Ctrl+O - Open current stock in Yahoo Finance
        var open_yahoo_action = new SimpleAction ("open-yahoo", null);
        open_yahoo_action.activate.connect (() => {
            if (this.state.chart_symbol != null) {
                this.state.link = this.state.chart_symbol.link;
            }
        });
        this.add_action (open_yahoo_action);
        this.application.set_accels_for_action ("win.open-yahoo", {"<Control>O"});

        // Group Actions
        var set_group_action = new SimpleAction.stateful ("set-group", new VariantType ("s"), new Variant.string (""));
        set_group_action.activate.connect ((action, parameter) => {
            action.change_state (parameter);
        });
        set_group_action.change_state.connect ((action, parameter) => {
            string group_name = parameter.get_string ();
            this.state.current_group = group_name;
            action.set_state (parameter);
        });
        this.add_action (set_group_action);
        
        // Sync state to action
        this.state.notify["current-group"].connect (() => {
             var action = this.lookup_action ("set-group") as SimpleAction;
             if (action != null) {
                 action.set_state (new Variant.string (this.state.current_group));
             }
        });

        var create_group_action = new SimpleAction ("create-group", null);
        create_group_action.activate.connect (() => {
             var entry = new Gtk.Entry ();
             entry.placeholder_text = _("Group Name");
             entry.activates_default = true;

             var dialog = new Adw.MessageDialog (this, _("Create Group"), _("Enter the name of the new group."));
             dialog.add_response ("cancel", _("Cancel"));
             dialog.add_response ("create", _("Create"));
             dialog.set_response_appearance ("create", Adw.ResponseAppearance.SUGGESTED);
             dialog.set_default_response ("create");
             dialog.set_close_response ("cancel");
             
             dialog.set_extra_child (entry);
             
             dialog.response.connect ((response) => {
                 if (response == "create") {
                     string name = entry.text.strip ();
                     if (name != "") {
                         this.state.create_group (name);
                     }
                 }
             });
             
             dialog.present ();
        });
        this.add_action (create_group_action);

        var delete_group_action = new SimpleAction ("delete-group", null);
        delete_group_action.activate.connect (() => {
             string group = this.state.current_group;
             if (group == "") return;

             var dialog = new Adw.MessageDialog (this, _("Delete Group"), _("Are you sure you want to delete the group '%s'? Symbols will remain in your list.").printf (group));
             dialog.add_response ("cancel", _("Cancel"));
             dialog.add_response ("delete", _("Delete"));
             dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
             dialog.set_default_response ("cancel");
             dialog.set_close_response ("cancel");
             
             dialog.response.connect ((response) => {
                 if (response == "delete") {
                     this.state.delete_group (group);
                 }
             });
             
             dialog.present ();
        });
        this.add_action (delete_group_action);
    }

    [GtkCallback]
    private void on_search_changed (Gtk.SearchEntry entry) {
        this.state.filter_query = entry.text;
    }

    [GtkCallback]
    private void on_search_stopped (Gtk.SearchEntry entry) {
        this.search_bar.search_mode_enabled = false;
        this.state.filter_query = "";
        // Sync button state
        this.main_header_bar.search_button.active = false;
    }

    private void on_filter_query_updated () {
        // If filter query is changed externally (e.g. cleared), update entry if needed
        if (this.state.filter_query != this.search_entry.text) {
            this.search_entry.text = this.state.filter_query;
        }
    }

    private void on_chart_symbol_updated () {
        if (this.state.chart_symbol != null) {
            this.stack.set_visible_child_name ("chart_view");
            this.main_header_bar.visible = false;
            this.selection_header_bar.visible = false;
            this.chart_header_bar.visible = true;
        } else {
            // Revert to normal view
            this.chart_header_bar.visible = false;
            this.on_selection_mode_update (); // Restore correct header bar
            this.on_symbols_updated (); // Restore correct list view
        }
    }

    private bool on_quit () {
        int width, height;
        width = this.get_width ();
        height = this.get_height ();

        this.state.window_width = width;
        this.state.window_height = height;

        return false;
    }

    private void on_symbols_updated () {
        if (this.state.symbols.size > 0) {
            this.stack.set_visible_child_name ("symbols_view");
        } else {
            this.stack.set_visible_child_name ("no_symbols_view");
        }
    }

    private void on_selection_mode_update () {
        switch (this.state.view_mode) {
            case State.ViewMode.PRESENTATION:
                this.selection_header_bar.visible = false;
                this.main_header_bar.visible = true;
                break;
            case State.ViewMode.SELECTION:
                this.state.select_none ();
                this.selection_header_bar.visible = true;
                this.main_header_bar.visible = false;
                break;
        }
    }
}
