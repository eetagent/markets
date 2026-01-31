[GtkTemplate (ui = "/biz/zaxo/Markets/SymbolsView.ui")]
public class Markets.SymbolsView : Gtk.Widget {

    [GtkChild]
    private unowned Gtk.ListBox symbols;

    private State state;

    public SymbolsView (State state) {
        this.state = state;
        this.set_layout_manager (new Gtk.BinLayout ());

        this.state.notify["symbols"].connect (this.on_symbols_update);
        this.state.notify["filter-query"].connect (this.on_filter_query_changed);
        this.state.notify["current-group"].connect (this.on_filter_query_changed);
        this.on_symbols_update ();
        
        this.symbols.set_filter_func (this.filter_func);
    }

    private void on_filter_query_changed () {
        this.symbols.invalidate_filter ();
    }

    private bool filter_func (Gtk.ListBoxRow row) {
        var symbol_row = row as SymbolRow;
        if (symbol_row == null) return true;

        if (this.state.current_group != "" && !symbol_row.symbol.groups.contains (this.state.current_group)) {
            return false;
        }

        if (this.state.filter_query == "") return true;
        
        var s = symbol_row.symbol;
        var query = this.state.filter_query.down ();
        
        return s.name.down ().contains (query) || s.id.down ().contains (query);
    }

    [GtkCallback]
    private void on_row_click (Gtk.ListBox box, Gtk.ListBoxRow row) {
        if (row is SymbolRow) {
            ((SymbolRow) row).on_row_clicked ();
        }
    }

    private void on_symbols_update () {
        Gtk.Widget child = this.symbols.get_first_child ();
        while (child != null) {
            Gtk.Widget next = child.get_next_sibling ();
            this.symbols.remove (child);
            child = next;
        }

        foreach (Symbol symbol in this.state.symbols) {
            symbols.append (new SymbolRow (symbol, state));
        }
    }
}
