project('valdo', 'vala', 'c',
  version: '0.0.1',
  license: 'LGPL-2.1-only')

valac = meson.get_compiler('vala')

deps = [
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('gio-2.0'),
  dependency('json-glib-1.0', version: '>= 1.5.2')
]

add_project_arguments([
  '--fatal-warnings',
  '--enable-experimental',
  '--enable-experimental-non-null',
], language: 'vala')

templates_dir = get_option('prefix') / get_option('datadir') / 'valdo' / 'templates'

subdir('templates')
subdir('src')
