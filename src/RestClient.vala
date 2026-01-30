using Soup;
using Json;

namespace Markets {
    public class RestClient : GLib.Object {
        private Soup.Session session;
        private string? crumb = null;
        private string config_url = "https://fc.yahoo.com";
        private string get_crumb_url = "https://query1.finance.yahoo.com/v1/test/getcrumb";

        public RestClient () {
            this.session = new Soup.Session ();
            // User-Agent similar to the one in yahoo-finance2
            this.session.user_agent = "Mozilla/5.0 (compatible; yahoo-finance2/2.11.3)";
            this.session.add_feature (new Soup.CookieJar ());
        }

        private async void ensure_crumb () {
            if (this.crumb != null) {
                return;
            }

            try {
                var message = new Soup.Message ("GET", this.config_url);
                message.request_headers.append ("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8");

                yield this.session.send_and_read_async (message, GLib.Priority.DEFAULT, null);

                debug ("Config request status: %u", message.status_code);

                var crumb_message = new Soup.Message ("GET", this.get_crumb_url);
                crumb_message.request_headers.append ("Origin", "https://finance.yahoo.com");
                crumb_message.request_headers.append ("Referer", "https://finance.yahoo.com/");
                crumb_message.request_headers.append ("Accept", "text/plain");

                var crumb_bytes = yield this.session.send_and_read_async (crumb_message, GLib.Priority.DEFAULT, null);

                if (crumb_message.status_code == 200 && crumb_bytes != null) {
                    this.crumb = (string) crumb_bytes.get_data ();
                    debug ("Fetched new crumb: %s", this.crumb);
                } else {
                    warning ("Failed to fetch crumb: %u %s", crumb_message.status_code, crumb_message.reason_phrase);
                }

            } catch (Error e) {
                warning ("Error fetching crumb: %s", e.message);
            }
        }

        public async Json.Node fetch (string url) {
            yield this.ensure_crumb ();

            string final_url = url;
            if (this.crumb != null) {
                if (url.contains ("?")) {
                    final_url += "&crumb=" + this.crumb;
                } else {
                    final_url += "?crumb=" + this.crumb;
                }
            }

            var message = new Soup.Message ("GET", final_url);

            var headers = message.request_headers;
            headers.append ("Accept", "application/json");

            try {
                var bytes = yield this.session.send_and_read_async (message, GLib.Priority.DEFAULT, null);

                if (message.status_code != 200) {
                    warning ("Unexpected response: %u %s for URL: %s", message.status_code, message.reason_phrase, final_url);
                    return new Json.Node (Json.NodeType.NULL);
                }

                if (bytes == null) {
                    return new Json.Node (Json.NodeType.NULL);
                }

                string body = (string) bytes.get_data ();

                try {
                    return Json.from_string (body);
                } catch (Error e) {
                    warning ("Failed to parse JSON response: %s", e.message);
                    return new Json.Node (Json.NodeType.NULL);
                }
            } catch (Error e) {
                warning ("Network error: %s", e.message);
                return new Json.Node (Json.NodeType.NULL);
            }
        }

        public async Json.Node fetch_chart (string symbol, string range, string interval) {
            // Note: We don't append crumb here because fetch() handles it
            string url = @"https://query1.finance.yahoo.com/v8/finance/chart/$symbol?range=$range&interval=$interval";
            return yield this.fetch (url);
        }
    }
}
