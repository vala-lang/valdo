project('${APP_NAME}', ['c', 'vala'],
           version: '${PROJECT_VERSION}',
     meson_version: '>= 0.58.0',
   default_options: [ 'warning_level=2',
       	            ],
)

pkgdata_dir = get_option('prefix') / get_option('datadir') / meson.project_name()

app_exe = '${APP_EXE}'
app_summary = '${APP_SUMMARY}'

app_id = '${APP_ID}'
app_name = meson.project_name()

conf_data = configuration_data()
conf_data.set('APP_ID', app_id)
conf_data.set('APP_PATH', '/' + app_id.replace('.', '/') + '/')
conf_data.set('APP_NAME', app_name)

conf_data.set('APP_EXE', app_exe)
conf_data.set('APP_SUMMARY', app_summary)

${APP_NAME}_sources = []

valac = meson.get_compiler('vala')
vapi_dir = meson.project_source_root() / 'vapi'

# Dependencies

libadwaita_dep = dependency('libadwaita-1',
  version: '>= 1.0.0-alpha.2',
  required: false,
)

if not libadwaita_dep.found()
  libadwaita = subproject(
    'libadwaita',
    default_options: [
        'examples=false',
       f'package_subdir=@app_name@',
        'tests=false'
    ]
  )
  libadwaita_dep = declare_dependency(
    dependencies: [
        libadwaita.get_variable('libadwaita_dep'),
        libadwaita.get_variable('libadwaita_vapi')
    ]
  )
endif

${APP_NAME}_deps = [
    dependency('gio-2.0', version: '>= 2.50'),
    dependency('gtk4', version: '>= 4.2'),
    libadwaita_dep,
    valac.find_library('config', dirs: vapi_dir),
]

i18n = import('i18n')

subdir('data')
subdir('resources')
subdir('src')
subdir('po')

meson.add_install_script('build-aux' / 'meson' / 'postinstall.py')
