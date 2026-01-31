![](data/icons/biz.zaxo.Markets.svg?raw=true)

# Markets
The Markets application delivers financial data to your fingertips. Track stocks, currencies and cryptocurrencies. Stay on top of the market and never miss an investment opportunity!

## Screenshots


<img width="1646" height="1490" alt="obrazek" src="https://github.com/user-attachments/assets/cc8357a5-ea7a-4a53-9104-aba6a684ea72" />

<img width="1646" height="1490" alt="obrazek" src="https://github.com/user-attachments/assets/ad0158b3-8750-41c8-8b54-b919ac6ad11b" />

<img width="1646" height="1490" alt="obrazek" src="https://github.com/user-attachments/assets/4438760f-9831-443f-9ba7-96c755c32d04" />

<img width="1646" height="1490" alt="obrazek" src="https://github.com/user-attachments/assets/de9c3514-89ba-4226-94dd-c0351b726c8f" />

![](preview.png?raw=true)

## Features

* Create your personal portfolio
* Track stocks, currencies, cryptocurrencies, commodities and indexes
* Designed for Phosh (Librem5, PinePhone) and Gnome
* Open any symbol for detailed view
* 1d, 1w, 1m, 3m, 6m, YTD, 1y, 5y, Max time ranges
* Stock price history charts
* Search for symbols
* Detail view with key statistics
* Group symbols into categories
* Adjust the refresh rate
* Dark Mode

## Building from source

You'll need the following dependencies:

* libsoup
* libgee
* libadwaita
* json-glib
* gettext
* glib2
* gtk4
* meson
* vala
* ninja
* git

Clone the repository and change to the project directory

```
https://github.com/EETagent/markets.git
cd markets
```

Run `meson build` to configure the build environment. Change to the build directory and run `ninja` to build

```
meson build --prefix=/usr
cd build
ninja
```

To install, use `ninja install`, then execute with `markets`

```
sudo ninja install
markets
```

## License

The GNU General Public License, version 3.0 or later
