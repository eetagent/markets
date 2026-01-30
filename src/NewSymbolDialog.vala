[GtkTemplate (ui = "/biz/zaxo/Markets/NewSymbolDialog.ui")]
public class Markets.NewSymbolDialog : Adw.Window {

    [GtkChild]
    private unowned Gtk.TreeView results_view;

    [GtkChild]
    private unowned Gtk.Button save_button;

    [GtkChild]
    private unowned Gtk.SearchEntry search_entry;

    private Markets.State state;
    private Gtk.ListStore store;

    public NewSymbolDialog (Gtk.Window parent, State state) {
        Object (transient_for: parent, modal: true);

        this.state = state;
        this.store = new Gtk.ListStore (1, typeof (string));
        this.results_view.model = this.store;

        // Reset the search state.
        //
        // There might be leftovers from a previous search.
        this.state.search_query = "";
        this.state.search_results = new Gee.ArrayList<Symbol> ();

        this.state.notify["search-results"].connect (this.on_search_results_updated);

        this.set_default_widget (this.save_button);

        this.results_view.get_selection ().changed.connect (this.on_selection_changed);
    }

    private void on_search_results_updated () {
        this.store.clear ();

        Gtk.TreeIter iter;
        foreach (Symbol symbol in this.state.search_results) {
            this.store.append (out iter);
            var label = symbol.id + " · " +
                        symbol.name + " · " +
                        symbol.instrument_type + " · " +
                        symbol.exchange_name;
            this.store.set (iter, 0, label);
        }
    }

    [GtkCallback]
    private void on_search_changed () {
        this.save_button.sensitive = false;
        this.state.search_query = this.search_entry.text;
    }

    [GtkCallback]
    private void on_search_stopped () {
        this.close ();
    }

    private void on_selection_changed () {
        Gtk.TreeModel model;
        Gtk.TreeIter iter;
        var selection = this.results_view.get_selection ();

        if (selection.get_selected (out model, out iter)) {
             Gtk.TreePath? path = model.get_path (iter);
             if (path != null) {
                this.state.search_selection = path.get_indices ()[0];
                this.save_button.sensitive = true;
             }
        } else {
            this.save_button.sensitive = false;
        }
    }

    [GtkCallback]
    private void on_save_clicked () {
        var new_symbol = this.state.search_results[this.state.search_selection];
        this.state.add_symbol (new_symbol);
        this.close ();
    }
}
