[GtkTemplate (ui = "/biz/zaxo/Markets/ChartView.ui")]
public class Markets.ChartView : Gtk.Widget {

    [GtkChild]
    private unowned Gtk.DrawingArea chart_area;

    [GtkChild]
    private unowned Gtk.Label status_label;

    [GtkChild]
    private unowned Gtk.Label val_open;
    [GtkChild]
    private unowned Gtk.Label val_high;
    [GtkChild]
    private unowned Gtk.Label val_low;
    [GtkChild]
    private unowned Gtk.Label val_vol;
    [GtkChild]
    private unowned Gtk.Label val_pe;
    [GtkChild]
    private unowned Gtk.Label val_mkt_cap;
    [GtkChild]
    private unowned Gtk.Label val_52w_h;
    [GtkChild]
    private unowned Gtk.Label val_52w_l;
    [GtkChild]
    private unowned Gtk.Label val_yield;
    [GtkChild]
    private unowned Gtk.Label val_beta;
    [GtkChild]
    private unowned Gtk.Label val_eps;

    [GtkChild]
    private unowned Gtk.ToggleButton range_1d;

    private Symbol symbol;
    private RestClient client;
    private ChartData? chart_data = null;
    private State state;

    // Measurement tool state
    private int? selected_index = null;
    private int? range_start_index = null;
    private int? range_end_index = null;

    public ChartView (State state) {
        this.state = state;
        this.set_layout_manager (new Gtk.BinLayout ());
        this.client = new RestClient ();

        this.chart_area.set_draw_func (this.draw_chart);
        
        var click_controller = new Gtk.GestureClick ();
        click_controller.button = 0; // Accept all buttons
        click_controller.pressed.connect (this.on_chart_clicked);
        this.chart_area.add_controller (click_controller);
        
        this.state.notify["chart-symbol"].connect (this.on_chart_symbol_updated);
        
        // Setup initial state
        if (this.state.chart_symbol != null) {
            this.symbol = this.state.chart_symbol;
            this.range_1d.active = true;
        }
    }

    private void on_chart_clicked (Gtk.GestureClick gesture, int n_press, double x, double y) {
        if (gesture.get_current_button () == Gdk.BUTTON_SECONDARY) {
            // Right click: Reset measurement tool
            this.selected_index = null;
            this.range_start_index = null;
            this.range_end_index = null;
            this.chart_area.queue_draw ();
            return;
        }

        if (this.chart_data == null || this.chart_data.prices.length == 0) return;

        int width = this.chart_area.get_width ();
        int height = this.chart_area.get_height ();

        // Padding constants (must match draw_chart)
        double padding_left = 50.0;
        double padding_right = 10.0;
        double graph_width = width - padding_left - padding_right;

        // Calculate index from X
        // x = padding_left + i * step_x;
        // step_x = graph_width / (count - 1);
        // x - padding_left = i * graph_width / (count - 1)
        // i = (x - padding_left) * (count - 1) / graph_width
        
        int count = this.chart_data.prices.length;
        if (x < padding_left) x = padding_left;
        if (x > width - padding_right) x = width - padding_right;
        
        double rel_x = x - padding_left;
        int index = (int) Math.round ((rel_x / graph_width) * (count - 1));
        
        if (index < 0) index = 0;
        if (index >= count) index = count - 1;

        if (n_press == 1) {
            // Single click: Set vertical line
            this.selected_index = index;
        } else if (n_press == 2) {
            // Double click: Range selection
            if (this.range_start_index == null) {
                this.range_start_index = index;
                this.range_end_index = null;
            } else if (this.range_end_index == null) {
                this.range_end_index = index;
            } else {
                // Reset range if starting new
                this.range_start_index = index;
                this.range_end_index = null;
            }
        }

        this.chart_area.queue_draw ();
    }

    private void on_chart_symbol_updated () {
        if (this.state.chart_symbol != null) {
            this.symbol = this.state.chart_symbol;
            
            // Update details
            this.val_open.label = @"%'.$(this.symbol.precision)f".printf (this.symbol.regular_market_open);
            this.val_high.label = @"%'.$(this.symbol.precision)f".printf (this.symbol.regular_market_day_high);
            this.val_low.label = @"%'.$(this.symbol.precision)f".printf (this.symbol.regular_market_day_low);
            this.val_vol.label = this.format_large_number (this.symbol.regular_market_volume);
            this.val_pe.label = "%.2f".printf (this.symbol.trailing_pe);
            this.val_mkt_cap.label = this.format_large_number (this.symbol.market_cap);
            this.val_52w_h.label = @"%'.$(this.symbol.precision)f".printf (this.symbol.fifty_two_week_high);
            this.val_52w_l.label = @"%'.$(this.symbol.precision)f".printf (this.symbol.fifty_two_week_low);
            this.val_yield.label = "%.2f%%".printf (this.symbol.dividend_yield);
            this.val_beta.label = "%.2f".printf (this.symbol.beta);
            this.val_eps.label = "%.2f".printf (this.symbol.eps);

            // Triggers load_data via signal if already active, otherwise we set it
            if (this.range_1d.active) {
                // Manually trigger if it was already active (e.g. switching back)
                // Actually, if we switch symbols, we might want to reset to 1D or keep range?
                // Let's force 1D for now or just trigger load.
                this.on_range_toggled (this.range_1d);
            } else {
                this.range_1d.active = true;
            }
        }
    }

    private string format_large_number (int64 number) {
        if (number >= 1000000000000) {
            return "%.2fT".printf (number / 1000000000000.0);
        } else if (number >= 1000000000) {
            return "%.2fB".printf (number / 1000000000.0);
        } else if (number >= 1000000) {
            return "%.2fM".printf (number / 1000000.0);
        } else if (number >= 1000) {
            return "%.2fK".printf (number / 1000.0);
        } else {
            return number.to_string ();
        }
    }

    [GtkCallback]
    private void on_range_toggled (Gtk.ToggleButton button) {
        if (!button.active || this.symbol == null) return;

        // Reset measurement tool
        this.selected_index = null;
        this.range_start_index = null;
        this.range_end_index = null;

        string range = "1d";
        string interval = "2m";

        if (button.label == "1D") { range = "1d"; interval = "2m"; }
        else if (button.label == "1W") { range = "5d"; interval = "15m"; }
        else if (button.label == "1M") { range = "1mo"; interval = "1h"; }
        else if (button.label == "3M") { range = "3mo"; interval = "1d"; }
        else if (button.label == "YTD") { range = "ytd"; interval = "1d"; }
        else if (button.label == "1Y") { range = "1y"; interval = "1d"; }
        else if (button.label == "2Y") { range = "2y"; interval = "1wk"; }
        else if (button.label == "5Y") { range = "5y"; interval = "1wk"; }
        else if (button.label == "10Y") { range = "10y"; interval = "1mo"; }
        else if (button.label == "Max") { range = "max"; interval = "3mo"; }

        this.load_data (range, interval);
    }

    private async void load_data (string range, string interval) {
        this.status_label.label = _("Loading...");
        this.chart_data = null;
        this.chart_area.queue_draw ();

        var json = yield this.client.fetch_chart (this.symbol.id, range, interval);
        
        if (json.get_node_type () != Json.NodeType.NULL) {
            try {
                this.chart_data = new ChartData (json.get_object ());
                this.status_label.label = "";
            } catch (Error e) {
                this.status_label.label = _("Error parsing data");
                warning ("Error parsing chart data: %s", e.message);
            }
        } else {
            this.status_label.label = _("Failed to fetch data");
        }
        
        this.chart_area.queue_draw ();
    }

    private void draw_chart (Gtk.DrawingArea area, Cairo.Context cr, int width, int height) {
        if (this.chart_data == null || this.chart_data.prices.length == 0) {
            return;
        }

        // Padding for axes labels
        double padding_left = 50.0;
        double padding_bottom = 30.0;
        double padding_top = 10.0;
        double padding_right = 10.0;

        double graph_width = width - padding_left - padding_right;
        double graph_height = height - padding_top - padding_bottom;

        double min = this.chart_data.min_price;
        double max = this.chart_data.max_price;
        
        // Add some breathing room to Y axis
        double price_range = max - min;
        if (price_range == 0) price_range = 1.0;
        min -= price_range * 0.05;
        max += price_range * 0.05;
        price_range = max - min;

        // Helper to get Y for a price
        // double normalized_price = (price - min) / price_range;
        // double y = padding_top + graph_height - (normalized_price * graph_height);
        
        // Draw Y-axis labels and grid lines
        cr.set_font_size (10);
        cr.set_source_rgb (0.5, 0.5, 0.5);
        
        int y_steps = 5;
        for (int i = 0; i <= y_steps; i++) {
            double value = min + (price_range * i / y_steps);
            double y = padding_top + graph_height - (graph_height * i / y_steps);
            
            // Grid line
            cr.set_line_width (0.5);
            cr.set_source_rgba (0.5, 0.5, 0.5, 0.2);
            cr.move_to (padding_left, y);
            cr.line_to (width - padding_right, y);
            cr.stroke ();
            
            // Label
            cr.set_source_rgb (0.5, 0.5, 0.5);
            string fmt = "%.2f";
            if (this.symbol != null) fmt = @"%'.$(this.symbol.precision)f";
            string label = fmt.printf (value);
            Cairo.TextExtents extents;
            cr.text_extents (label, out extents);
            cr.move_to (padding_left - extents.width - 5, y + extents.height / 2);
            cr.show_text (label);
        }

        // Draw X-axis labels
        int x_steps = 5;
        int64 start_time = this.chart_data.timestamps[0];
        int64 end_time = this.chart_data.timestamps[this.chart_data.timestamps.length - 1];
        int64 time_range = end_time - start_time;
        if (time_range == 0) time_range = 1;

        for (int i = 0; i <= x_steps; i++) {
            int64 timestamp = (int64)(start_time + (time_range * i / x_steps));
            double x = padding_left + (graph_width * i / x_steps);
            
            var time = new GLib.DateTime.from_unix_local (timestamp);
            string label;
            
            // Decide format based on range
            if (time_range < 86400 * 2) { // Less than 2 days
                label = time.format ("%H:%M");
            } else if (time_range < 86400 * 365) { // Less than a year
                label = time.format ("%b %d");
            } else {
                label = time.format ("%Y");
            }

            Cairo.TextExtents extents;
            cr.text_extents (label, out extents);
            cr.move_to (x - extents.width / 2, height - padding_bottom + extents.height + 5);
            cr.show_text (label);
        }

        // Draw Chart Line
        cr.set_line_width (2.0);
        // Use green if last price > prev_close (or first price), red otherwise
        bool up = this.chart_data.prices[this.chart_data.prices.length - 1] >= this.chart_data.prices[0];
        
        if (up) {
            cr.set_source_rgb (0.18, 0.76, 0.49); // Green
        } else {
            cr.set_source_rgb (0.88, 0.11, 0.14); // Red
        }

        int count = this.chart_data.prices.length;
        double step_x = graph_width / (double)(count - 1);

        for (int i = 0; i < count; i++) {
            double price = this.chart_data.prices[i];
            double x = padding_left + i * step_x;
            // Invert Y axis (0 is top)
            double normalized_price = (price - min) / price_range;
            double y = padding_top + graph_height - (normalized_price * graph_height);

            if (i == 0) {
                cr.move_to (x, y);
            } else {
                cr.line_to (x, y);
            }
        }

        cr.stroke ();
        
        // Draw baseline (prev close) if within range
        if (this.chart_data.prev_close >= min && this.chart_data.prev_close <= max) {
             double normalized_prev = (this.chart_data.prev_close - min) / price_range;
             double y_prev = padding_top + graph_height - (normalized_prev * graph_height);
             
             cr.set_source_rgba (0.5, 0.5, 0.5, 0.5);
             cr.set_dash ({4.0}, 0);
             cr.set_line_width (1.0);
             cr.move_to (padding_left, y_prev);
             cr.line_to (width - padding_right, y_prev);
             cr.stroke ();
        }

        // Draw Interactive Elements (Lines and Ranges)
        
        // Single Line
        if (this.selected_index != null) {
            int index = this.selected_index;
            if (index >= 0 && index < count) {
                double x = padding_left + index * step_x;
                double price = this.chart_data.prices[index];
                double normalized_price = (price - min) / price_range;
                double y = padding_top + graph_height - (normalized_price * graph_height);
                
                // Crosshair Lines
                cr.set_line_width (1.0);
                cr.set_dash ({}, 0); // Solid
                cr.set_source_rgb (1.0, 1.0, 1.0); // White
                
                // Vertical
                cr.move_to (x, padding_top);
                cr.line_to (x, height - padding_bottom);
                
                // Horizontal
                cr.move_to (padding_left, y);
                cr.line_to (width - padding_right, y);
                cr.stroke ();

                // Label (Price next to intersection)
                string fmt = "%.2f";
                if (this.symbol != null) fmt = @"%'.$(this.symbol.precision)f";
                string label = fmt.printf (price);
                
                Cairo.TextExtents extents;
                cr.text_extents (label, out extents);
                
                double label_x = x + 5;
                // Flip label to left if too close to right edge
                if (label_x + extents.width + 4 > width - padding_right) {
                    label_x = x - extents.width - 9;
                }

                // Draw background for label
                cr.set_source_rgb (0.2, 0.2, 0.2);
                cr.rectangle (label_x, y - extents.height / 2 - 2, extents.width + 4, extents.height + 4);
                cr.fill ();

                cr.set_source_rgb (1.0, 1.0, 1.0);
                cr.move_to (label_x + 2, y + extents.height / 2);
                cr.show_text (label);
            }
        }

        // Range
        if (this.range_start_index != null) {
            int start_idx = this.range_start_index;
            if (start_idx >= 0 && start_idx < count) {
                double x_start = padding_left + start_idx * step_x;
                double start_price = this.chart_data.prices[start_idx];
                double normalized_start = (start_price - min) / price_range;
                double y_start_price = padding_top + graph_height - (normalized_start * graph_height);

                // Start Crosshair
                cr.set_line_width (1.0);
                cr.set_dash ({4.0}, 0); // Dashed
                cr.set_source_rgb (1.0, 1.0, 1.0);
                
                // Vertical
                cr.move_to (x_start, padding_top);
                cr.line_to (x_start, height - padding_bottom);
                
                // Horizontal
                cr.move_to (padding_left, y_start_price);
                cr.line_to (width - padding_right, y_start_price);
                cr.stroke ();

                // Start Price Label
                string fmt = "%.2f";
                if (this.symbol != null) fmt = @"%'.$(this.symbol.precision)f";
                string start_label = fmt.printf (start_price);
                
                Cairo.TextExtents extents;
                cr.text_extents (start_label, out extents);
                
                double label_x = x_start + 5;
                if (label_x + extents.width + 4 > width - padding_right) {
                    label_x = x_start - extents.width - 9;
                }
                
                // Draw background for label
                cr.set_source_rgb (0.2, 0.2, 0.2);
                cr.rectangle (label_x, y_start_price - extents.height / 2 - 2, extents.width + 4, extents.height + 4);
                cr.fill ();

                cr.set_source_rgb (1.0, 1.0, 1.0);
                cr.move_to (label_x + 2, y_start_price + extents.height / 2);
                cr.show_text (start_label);

                if (this.range_end_index != null) {
                    int end_idx = this.range_end_index;
                    if (end_idx >= 0 && end_idx < count) {
                        double x_end = padding_left + end_idx * step_x;
                        double end_price = this.chart_data.prices[end_idx];
                        double normalized_end = (end_price - min) / price_range;
                        double y_end_price = padding_top + graph_height - (normalized_end * graph_height);

                        // End Crosshair
                        cr.set_dash ({4.0}, 0);
                        cr.move_to (x_end, padding_top);
                        cr.line_to (x_end, height - padding_bottom);
                        cr.move_to (padding_left, y_end_price);
                        cr.line_to (width - padding_right, y_end_price);
                        cr.stroke ();

                        // End Price Label
                        string end_label = fmt.printf (end_price);
                        
                        cr.text_extents (end_label, out extents);
                        
                        double end_label_x = x_end + 5;
                        if (end_label_x + extents.width + 4 > width - padding_right) {
                            end_label_x = x_end - extents.width - 9;
                        }

                        // Draw background for label
                        cr.set_source_rgb (0.2, 0.2, 0.2);
                        cr.rectangle (end_label_x, y_end_price - extents.height / 2 - 2, extents.width + 4, extents.height + 4);
                        cr.fill ();

                        cr.set_source_rgb (1.0, 1.0, 1.0);
                        cr.move_to (end_label_x + 2, y_end_price + extents.height / 2);
                        cr.show_text (end_label);


                        // Percentage Difference
                        double diff = end_price - start_price;
                        double percent = (diff / start_price) * 100.0;
                        string percent_label = "%+.2f%%".printf (percent);

                        // Draw horizontal connector in the middle
                        double y_mid = padding_top + graph_height / 2;
                        cr.set_line_width (2.0);
                        cr.set_dash ({}, 0); // Solid
                        if (diff >= 0) cr.set_source_rgb (0.18, 0.76, 0.49); // Green
                        else cr.set_source_rgb (0.88, 0.11, 0.14); // Red
                        
                        cr.move_to (x_start, y_mid);
                        cr.line_to (x_end, y_mid);
                        cr.stroke ();

                        // Draw label in the middle of connector
                        cr.text_extents (percent_label, out extents);
                        double x_mid = (x_start + x_end) / 2;
                        
                        // Background box
                        cr.set_source_rgb (0.1, 0.1, 0.1);
                        cr.rectangle (x_mid - extents.width / 2 - 4, y_mid - extents.height / 2 - 4, extents.width + 8, extents.height + 8);
                        cr.fill ();

                        if (diff >= 0) cr.set_source_rgb (0.18, 0.76, 0.49);
                        else cr.set_source_rgb (0.88, 0.11, 0.14);
                        
                        cr.move_to (x_mid - extents.width / 2, y_mid + extents.height / 2);
                        cr.show_text (percent_label);
                    }
                }
            }
        }
    }
}
