public class Markets.Symbol : Object {
    public bool selected {
        get; set; default = false;
    }

    public string id {
        get; set; default = "";
    }

    public string instrument_type {
        get; set; default = "";
    }

    public string name {
        get; set; default = "";
    }

    public string exchange_name {
        get; set; default = "";
    }

    public string market_state {
        get; set; default = "closed";
    }

    public Gee.ArrayList<string> groups {
        get; set; default = new Gee.ArrayList<string> ();
    }

    public int precision {
        get; set; default = 2;
    }

    public string currency {
        get; set; default = "";
    }

    public DateTime ? regular_market_time {
        get; set; default = null;
    }

    public double regular_market_price {
        get; set; default = 0;
    }

    public double regular_market_change {
        get; set; default = 0;
    }

    public double regular_market_change_percent {
        get; set; default = 0;
    }

    public double regular_market_open {
        get; set; default = 0;
    }

    public double regular_market_day_high {
        get; set; default = 0;
    }

    public double regular_market_day_low {
        get; set; default = 0;
    }

    public int64 regular_market_volume {
        get; set; default = 0;
    }

    public double trailing_pe {
        get; set; default = 0;
    }

    public int64 market_cap {
        get; set; default = 0;
    }

    public double fifty_two_week_high {
        get; set; default = 0;
    }

    public double fifty_two_week_low {
        get; set; default = 0;
    }

    public double dividend_yield {
        get; set; default = 0;
    }

    public double beta {
        get; set; default = 0;
    }

    public double eps {
        get; set; default = 0;
    }

    public bool is_marked_closed {
        get {
            return this.market_state.down () != "regular";
        }
    }

    public string link  {
        owned get {
            return @"https://finance.yahoo.com/quote/$(this.id)";
        }
    }

    public Symbol.from_search (Json.Object json) {
        if (json.has_member ("symbol")) {
            this.id = json.get_string_member ("symbol");
        }

        if (json.has_member ("longname")) {
            this.name = this.decode_entities (
                json.get_string_member ("longname")
            );
        } else if (json.has_member ("shortname")) {
            this.name = this.decode_entities (
                json.get_string_member ("shortname")
            );
        }

        if (json.has_member ("typeDisp")) {
            this.instrument_type = json.get_string_member ("typeDisp");
        } else if (json.has_member ("quoteType")) {
            this.instrument_type = json.get_string_member ("quoteType");
        }

        if (json.has_member ("exchange")) {
            this.exchange_name = json.get_string_member ("exchange");
        }
    }

    public Symbol.from_quote (Json.Object json) {
        if (json.has_member ("symbol")) {
            this.id = json.get_string_member ("symbol");
        }

        this.update (json);
    }

    public Symbol.from_mock (
        string id,
        string name,
        string instrument_type,
        string exchange_name
    ) {
        this.id = id;
        this.name = name;
        this.instrument_type = instrument_type;
        this.exchange_name = exchange_name;
    }

    public void update (Json.Object json) {
        if (json.has_member ("quoteType")) {
            this.instrument_type = json.get_string_member ("quoteType");
        }

        if (json.has_member ("shortName")) {
            this.name = this.decode_entities (
                json.get_string_member ("shortName")
            );
        }

        if (json.has_member ("exchange")) {
            this.exchange_name = json.get_string_member ("exchange");
        }

        if (json.has_member ("currency")) {
            // Omits currency units for market indices
            string symbol_string = json.has_member ("symbol") ? json.get_string_member ("symbol") : "";
            bool symbol_starts_with_hat = symbol_string.length != 0 && symbol_string[0 : 1] == "^";
            this.currency = symbol_starts_with_hat ? "" : json.get_string_member ("currency");
        }

        if (json.has_member ("marketState")) {
            this.market_state = json.get_string_member ("marketState");
        }

        if (json.has_member ("groups")) {
            var group_nodes = json.get_array_member ("groups");
            var groups = new Gee.ArrayList<string> ();
            for (var i = 0; i < group_nodes.get_length (); i++) {
                groups.add (group_nodes.get_string_element (i));
            }
            this.groups = groups;
        } else if (json.has_member ("group")) {
            this.groups = new Gee.ArrayList<string> ();
            var g = json.get_string_member ("group");
            if (g != "") this.groups.add (g);
        }

        if (json.has_member ("priceHint")) {
            this.precision = (int) json.get_int_member ("priceHint");
        }

        if (json.has_member ("regularMarketTime")) {
            this.regular_market_time = new DateTime.from_unix_utc (
                json.get_int_member ("regularMarketTime")
            );
        }

        if (json.has_member ("regularMarketPrice")) {
            this.regular_market_price =
                json.get_double_member ("regularMarketPrice");
        }

        if (json.has_member ("regularMarketChange")) {
            this.regular_market_change =
                json.get_double_member ("regularMarketChange");
        }

        if (json.has_member ("regularMarketChangePercent")) {
            this.regular_market_change_percent =
                json.get_double_member ("regularMarketChangePercent");
        }

        if (json.has_member ("regularMarketOpen")) {
            this.regular_market_open = json.get_double_member ("regularMarketOpen");
        }
        if (json.has_member ("regularMarketDayHigh")) {
            this.regular_market_day_high = json.get_double_member ("regularMarketDayHigh");
        }
        if (json.has_member ("regularMarketDayLow")) {
            this.regular_market_day_low = json.get_double_member ("regularMarketDayLow");
        }
        if (json.has_member ("regularMarketVolume")) {
            this.regular_market_volume = json.get_int_member ("regularMarketVolume");
        }
        if (json.has_member ("trailingPE")) {
            this.trailing_pe = json.get_double_member ("trailingPE");
        }
        if (json.has_member ("marketCap")) {
            this.market_cap = json.get_int_member ("marketCap");
        }
        if (json.has_member ("fiftyTwoWeekHigh")) {
            this.fifty_two_week_high = json.get_double_member ("fiftyTwoWeekHigh");
        }
        if (json.has_member ("fiftyTwoWeekLow")) {
            this.fifty_two_week_low = json.get_double_member ("fiftyTwoWeekLow");
        }
        if (json.has_member ("dividendYield")) {
            this.dividend_yield = json.get_double_member ("dividendYield");
        }
        if (json.has_member ("beta")) {
            this.beta = json.get_double_member ("beta");
        }
        if (json.has_member ("epsTrailingTwelveMonths")) {
            this.eps = json.get_double_member ("epsTrailingTwelveMonths");
        }
    }

    public void build_json (Json.Builder builder) {
        builder.begin_object ();

        builder.set_member_name ("symbol");
        builder.add_string_value (this.id);

        builder.set_member_name ("quoteType");
        builder.add_string_value (this.instrument_type);

        builder.set_member_name ("shortName");
        builder.add_string_value (this.name);

        builder.set_member_name ("exchange");
        builder.add_string_value (this.exchange_name);

        builder.set_member_name ("marketState");
        builder.add_string_value (this.market_state);

        builder.set_member_name ("groups");
        builder.begin_array ();
        foreach (string group in this.groups) {
            builder.add_string_value (group);
        }
        builder.end_array ();

        builder.set_member_name ("currency");
        builder.add_string_value (this.currency);

        builder.set_member_name ("priceHint");
        builder.add_int_value (this.precision);

        if (this.regular_market_time != null) {
            builder.set_member_name ("regularMarketTime");
            builder.add_int_value (this.regular_market_time.to_unix ());
        }

        builder.set_member_name ("regularMarketPrice");
        builder.add_double_value (this.regular_market_price);

        builder.set_member_name ("regularMarketChange");
        builder.add_double_value (this.regular_market_change);

        builder.set_member_name ("regularMarketChangePercent");
        builder.add_double_value (this.regular_market_change_percent);

        builder.set_member_name ("regularMarketOpen");
        builder.add_double_value (this.regular_market_open);

        builder.set_member_name ("regularMarketDayHigh");
        builder.add_double_value (this.regular_market_day_high);

        builder.set_member_name ("regularMarketDayLow");
        builder.add_double_value (this.regular_market_day_low);

        builder.set_member_name ("regularMarketVolume");
        builder.add_int_value (this.regular_market_volume);

        builder.set_member_name ("trailingPE");
        builder.add_double_value (this.trailing_pe);

        builder.set_member_name ("marketCap");
        builder.add_int_value (this.market_cap);

        builder.set_member_name ("fiftyTwoWeekHigh");
        builder.add_double_value (this.fifty_two_week_high);

        builder.set_member_name ("fiftyTwoWeekLow");
        builder.add_double_value (this.fifty_two_week_low);

        builder.set_member_name ("dividendYield");
        builder.add_double_value (this.dividend_yield);

        builder.set_member_name ("beta");
        builder.add_double_value (this.beta);

        builder.set_member_name ("epsTrailingTwelveMonths");
        builder.add_double_value (this.eps);

        builder.end_object ();
    }

    private string decode_entities (string value) {
        return value.replace ("&amp;", "&").strip ();
    }
}
