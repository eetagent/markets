![](data/icons/biz.zaxo.Markets.svg?raw=true)

# Markets
The Markets application delivers financial data to your fingertips. Track stocks, currencies and cryptocurrencies. Stay on top of the market and never miss an investment opportunity!

## Screenshots


<img width="1560" height="1266" alt="obrazek" src="https://github.com/user-attachments/assets/9091c812-e8c6-4ed1-b5d1-1bbba9dd697b" />

<img width="1560" height="1266" alt="obrazek" src="https://github.com/user-attachments/assets/0f1c26bd-ff94-4bf1-9c51-8c11dca47800" />

<img width="1560" height="1266" alt="obrazek" src="https://github.com/user-attachments/assets/f156ba3b-7fbb-4c6e-9802-93a0503ee92b" />

<img width="1560" height="1266" alt="obrazek" src="https://github.com/user-attachments/assets/89b0891e-5490-4364-b30e-fdfd9825bad2" />

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
