# project name and programming language
project(
    '${APP_ID}',
    'vala',
    'c',
    version: '${PROJECT_VERSION}',
)

app_title = '${APP_TITLE}'
app_summary = '${APP_SUMMARY}'

app_id = '${APP_ID}'
app_name = '${APP_NAME}'

# Feel free to change it to whatever you prefer
# Don't forget to create your LICENSE.md or COPYING file!
app_license_type = 'GPL-3.0'

# Import modules
gnome = import('gnome')
i18n = import('i18n')

add_global_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(app_id),
    language: 'c',
)

config_data = configuration_data()
config_data.set_quoted(
    'LOCALEDIR',
    join_paths(get_option('prefix'), get_option('localedir')),
)

config_data.set_quoted('APP_ID', app_id)
config_data.set_quoted('APP_PATH', '/' + app_id.replace('.', '/') + '/')
config_data.set_quoted('APP_NAME', app_name)
config_data.set_quoted('APP_TITLE', app_title)
config_data.set_quoted('APP_SUMMARY', app_summary)
config_data.set_quoted('APP_LICENSE_TYPE', app_license_type)
config_data.set_quoted('APP_VERSION', meson.project_version())
config_data.set_quoted('GETTEXT_PACKAGE', app_id)
config_file = configure_file(
    input: 'src/Config.vala.in',
    output: '@BASENAME@',
    configuration: config_data,
)

# Define common dependencies used in all targets
global_dependencies = [
    dependency('gee-0.8'),
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
]

libadwaita = dependency(
    'libadwaita-1',
    version: '>= 1.0.0',
    fallback: ['libadwaita', 'libadwaita_dep'],
    default_options: [
        'examples=false',
        'introspection=disabled',
        'tests=false',
        'vapi=false',
    ],
)

# Read meson.build files in specified sub directories
subdir('src')
subdir('tests')

# Tell meson where to find our resources file and to compile it as a GResource
gresource = gnome.compile_resources(
    'gresource',
    input_file: configure_file(
        input: 'data' / app_name + '.gresource.xml.in',
        output: 'data' / app_name + '.gresource.xml',
        configuration: conf_data,
    ),
    source_dir: join_paths(meson.source_root(), 'data'),
)

# Create a new executable, list the files we want to compile, list the dependencies we need, and install
executable(
    app_id,
    app_sources,
    gresource,
    dependencies: app_dependencies,
    install: true,
)

# Create executable for unit tests
test_exe = executable(
    app_name + '-unit-tests',
    unit_test_sources,
    dependencies: unit_test_dependencies,
)
test(app_name + '-unit-tests', test_exe)

#Translate and install our .desktop file

desktop_file = i18n.merge_file(
    input: configure_file(
        input: 'data' / app_name + '.desktop.in.in',
        output: 'data' / app_name + '.desktop.in',
        configuration: conf_data,
    ),
    output: app_id + '.desktop',
    po_dir: meson.source_root() / 'po',
    type: 'desktop',
    install: true,
    install_dir: get_option('datadir') / 'applications',
)

desktop_utils = find_program('desktop-file-validate', required: false)
if desktop_utils.found()
    test('Validate desktop file', desktop_utils, args: [desktop_file])
endif

# Translate and install our .metainfo file
appstream_file = i18n.merge_file(
    input: configure_file(
        input: 'data' / app_name + '.metainfo.xml.in.in',
        output: 'data' / app_name + '.metainfo.xml.in',
        configuration: conf_data,
    ),
    output: app_id + '.metainfo.xml',
    po_dir: meson.source_root() / 'po',
    install: true,
    install_dir: get_option('datadir') / 'metainfo',
)

subdir('po')

# Install our icons in all the required sizes
icon_sizes = ['16', '24', '32', '48', '64', '128']

foreach i : icon_sizes
    install_data(
        'data' / i + '.svg',
        install_dir: get_option('datadir') / 'icons' / 'hicolor' / i + 'x' + i /
        'apps',
        rename: app_id + '.svg',
    )
    install_data(
        'data' / i + '.svg',
        install_dir: get_option('datadir') / 'icons' / 'hicolor' / i + 'x' + i +
        '@2' / 'apps',
        rename: app_id + '.svg',
    )
endforeach

# Install gschema (settings) file
gschema_file = configure_file(
    input: 'data' / app_name + '.gschema.xml.in',
    output: app_id + '.gschema.xml',
    configuration: conf_data,
    install_dir: get_option('datadir') / 'glib-2.0' / 'schemas',
)

compile_schemas = find_program('glib-compile-schemas', required: false)
if compile_schemas.found()
    test(
        'Validate schema file',
        compile_schemas,
        args: ['--strict', '--dry-run', meson.current_build_dir()],
    )
endif

meson.add_install_script('meson/post_install.py')
