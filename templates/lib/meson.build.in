project('${PROJECT_NAME}', 'vala', 'c',
  version: '${PROJECT_VERSION}')

dependencies = [
  dependency('glib-2.0'),
  dependency('gobject-2.0')
]

pkgconfig = import('pkgconfig')

PKGCONFIG_DEPS = ['glib-2.0', 'gobject-2.0']
API_VERSION = '${API_VERSION}'
vapidir = get_option('datadir') / 'vala' / 'vapi'

add_project_arguments(['--enable-experimental'], language: 'vala')

g_ir_compiler = find_program('g-ir-compiler', required: false)

subdir('src')
