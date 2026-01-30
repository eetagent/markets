[GtkTemplate (ui = "/biz/zaxo/Markets/SymbolsView.ui")]
public class Markets.SymbolsView : Gtk.Widget {

    [GtkChild]
    private unowned Gtk.ListBox symbols;

    private State state;

    public SymbolsView (State state) {
        this.state = state;
        this.set_layout_manager (new Gtk.BinLayout ());

        this.state.notify["symbols"].connect (this.on_symbols_update);
        this.on_symbols_update ();
    }

    [GtkCallback]
    private void on_row_click (Gtk.ListBox box, Gtk.ListBoxRow row) {
        var child = row.get_child ();
        if (child is SymbolRow) {
            ((SymbolRow) child).on_row_clicked ();
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
