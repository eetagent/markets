[GtkTemplate (ui = "/biz/zaxo/Markets/ChartHeaderBar.ui")]
public class Markets.ChartHeaderBar : Gtk.Widget {
    private Markets.MainWindow window;
    private Markets.State state;

    [GtkChild]
    private unowned Gtk.Button back_button;

    [GtkChild]
    private unowned Adw.WindowTitle title_widget;

    public ChartHeaderBar (MainWindow window, State state) {
        this.window = window;
        this.state = state;
        this.set_layout_manager (new Gtk.BinLayout ());

        this.state.notify["chart-symbol"].connect (this.on_chart_symbol_updated);
    }

    private void on_chart_symbol_updated () {
        if (this.state.chart_symbol != null) {
            this.title_widget.title = this.state.chart_symbol.name;
            this.title_widget.subtitle = this.state.chart_symbol.id;
        }
    }

    [GtkCallback]
    private void on_back_clicked () {
        this.state.chart_symbol = null;
    }
}