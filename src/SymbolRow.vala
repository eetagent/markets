[GtkTemplate (ui = "/biz/zaxo/Markets/SymbolRow.ui")]
public class Markets.SymbolRow : Gtk.ListBoxRow {

    [GtkChild]
    private unowned Gtk.Label title1;

    [GtkChild]
    private unowned Gtk.Label title2;

    [GtkChild]
    private unowned Gtk.Label change;

    [GtkChild]
    private unowned Gtk.Label price;

    [GtkChild]
    private unowned Gtk.Label currency;

    [GtkChild]
    private unowned Gtk.Label market;

    [GtkChild]
    private unowned Gtk.Label time;

    [GtkChild]
    private unowned Gtk.CheckButton checkbox;

    [GtkChild]
    private unowned Gtk.Image drag_icon;

    [GtkChild]
    private unowned Gtk.Box extra_info;

    [GtkChild]
    private unowned Gtk.Box price_info;

    private State state;

    private Symbol symbol;

    public SymbolRow (Symbol symbol, State state) {
        this.symbol = symbol;
        this.state = state;

        this.symbol.notify.connect (this.on_symbol_update);
        this.state.notify["view-mode"].connect (this.on_view_mode_update);

        this.on_symbol_update ();
        this.on_view_mode_update ();

        this.setup_dnd ();
    }

    private void setup_dnd () {
        // Drag Source
        var source = new Gtk.DragSource ();
        source.actions = Gdk.DragAction.MOVE;
        
        source.prepare.connect ((x, y) => {
            var value = new GLib.Value (typeof (string));
            value.set_string (this.symbol.id);
            return new Gdk.ContentProvider.for_value (value);
        });

        source.drag_begin.connect ((drag) => {
            this.add_css_class ("drag-begin");
        });

        source.drag_end.connect ((drag, delete_data) => {
            this.remove_css_class ("drag-begin");
        });

        this.drag_icon.add_controller (source);

        // Drop Target
        var target = new Gtk.DropTarget (typeof (string), Gdk.DragAction.MOVE);
        
        target.drop.connect ((value, x, y) => {
            string src_id = value.get_string ();
            Symbol? src_symbol = null;
            foreach (var s in this.state.symbols) {
                if (s.id == src_id) {
                    src_symbol = s;
                    break;
                }
            }
            if (src_symbol != null) {
                this.state.move_symbol (src_symbol, this.symbol);
                return true;
            }
            return false;
        });

        this.add_controller (target);
    }

    private void on_symbol_update () {
        var s = this.symbol;

        this.checkbox.active = s.selected;

        this.title1.label = s.name;
        this.title2.label = s.name;

        this.price.label = @"%'.$(s.precision)F".printf (s.regular_market_price);

        this.currency.label = s.currency.up ();
        this.currency.visible = s.currency != ""; // Hide currency for market indices

        this.change.label =
            @"%'+.$(s.precision)F (%'+.2F%)".printf (
                s.regular_market_change,
                s.regular_market_change_percent
            );

        this.change.remove_css_class ("profit");
        this.change.remove_css_class ("loss");
        if (s.regular_market_change >= 0) {
            this.change.add_css_class ("profit");
        } else {
            this.change.add_css_class ("loss");
        }

        this.market.remove_css_class ("open");
        this.market.remove_css_class ("dim-label");
        if (s.is_marked_closed) {
            this.market.label = _("Market Closed");
            this.market.add_css_class ("dim-label");
        } else {
            this.market.label = _("Market Open");
            this.market.add_css_class ("open");
        }

        if (s.regular_market_time != null) {
            this.time.label = s.regular_market_time
                               .to_local ()
                               .format ("%b %e, %X");
        }
    }

    private void on_view_mode_update () {
        var visible = this.state.view_mode == State.ViewMode.SELECTION;
        this.title1.visible = !visible;
        this.extra_info.visible = !visible;
        this.price_info.visible = !visible;
        this.title2.visible = visible;
        this.checkbox.visible = visible;
        this.drag_icon.visible = visible;
        this.activatable = !visible;
    }

    [GtkCallback]
    private void on_checkbox_toggled () {
        this.state.select(this.symbol, this.checkbox.active);
    }

    public void on_row_clicked () {
        if (this.state.view_mode == State.ViewMode.PRESENTATION) {
            this.state.link = this.symbol.link;
        }
    }
}
