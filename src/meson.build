app_sources = [
  'Application.vala',
  'NewSymbolDialog.vala',
  'PreferencesWindow.vala',
  'ChartView.vala',
  'ChartHeaderBar.vala',
  'ChartData.vala',
  'SymbolsView.vala',
  'NoSymbolsView.vala',
  'SymbolRow.vala',
  'MainHeaderBar.vala',
  'SelectionHeaderBar.vala',
  'State.vala',
  'Service.vala',
  'Symbol.vala',
  'RestClient.vala',
  'MainWindow.vala',
  app_constants,
  app_ui_resources
]

app_deps = [
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gtk4', version: '>= 4.0'),
  dependency('libadwaita-1', version: '>= 1.0.0'),
  dependency('libsoup-3.0', version: '>= 3.0'),
  dependency('json-glib-1.0'),
  dependency('gee-0.8'),
  meson.get_compiler('c').find_library('m', required : false)
]

app_c_args = [
  '-DADWAITA_USE_UNSTABLE_API',
]

executable(app_binary, app_sources,
  dependencies: app_deps,
  c_args: app_c_args,
  install: true,
)
