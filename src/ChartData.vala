public class Markets.ChartData : Object {
    public int64[] timestamps;
    public double[] prices;
    public double min_price;
    public double max_price;
    public double prev_close;

    public ChartData (Json.Object json) {
        // Parse JSON response from chart API
        // Structure: chart.result[0].timestamp (array), chart.result[0].indicators.quote[0].close (array)
        // meta.chartPreviousClose
        
        var result = json.get_object_member ("chart")
                         .get_array_member ("result")
                         .get_object_element (0);
                         
        var meta = result.get_object_member ("meta");
        if (meta.has_member ("chartPreviousClose")) {
            this.prev_close = meta.get_double_member ("chartPreviousClose");
        } else if (meta.has_member ("previousClose")) {
            this.prev_close = meta.get_double_member ("previousClose");
        }

        var timestamp_array = result.get_array_member ("timestamp");
        this.timestamps = new int64[timestamp_array.get_length ()];
        for (int i = 0; i < timestamp_array.get_length (); i++) {
            this.timestamps[i] = timestamp_array.get_int_element (i);
        }

        var quote = result.get_object_member ("indicators")
                          .get_array_member ("quote")
                          .get_object_element (0);
        
        var close_array = quote.get_array_member ("close");
        this.prices = new double[close_array.get_length ()];
        
        this.min_price = double.MAX;
        this.max_price = -double.MAX;

        for (int i = 0; i < close_array.get_length (); i++) {
            // Some values might be null
            if (close_array.get_element (i).get_node_type () == Json.NodeType.NULL) {
                // Use previous value or 0 if first
                this.prices[i] = (i > 0) ? this.prices[i-1] : 0;
            } else {
                this.prices[i] = close_array.get_double_element (i);
            }
            
            if (this.prices[i] < this.min_price) this.min_price = this.prices[i];
            if (this.prices[i] > this.max_price) this.max_price = this.prices[i];
        }
    }
}
