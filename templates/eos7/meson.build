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

# Import modules
gnome = import('gnome')
i18n = import('i18n')

add_global_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    language: 'c',
)

config_data = configuration_data()
config_data.set_quoted(
    'LOCALEDIR',
    join_paths(get_option('prefix'), get_option('localedir')),
)

config_data.set_quoted('APP_ID', app_id)
config_data.set_quoted('APP_PATH', app_path)
config_data.set_quoted('APP_NAME', app_name)
config_data.set_quoted('APP_TITLE', app_title)
config_data.set_quoted('APP_SUMMARY', app_summary)
config_data.set_quoted('APP_VERSION', meson.project_version())
config_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config_file = configure_file(
    input: 'src/Config.vala.in',
    output: '@BASENAME@',
    configuration: config_data,
)

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
    'data' / app_name + '.gresource.xml',
    source_dir: join_paths(meson.source_root(), 'data'),
)

# Create a new executable, list the files we want to compile, list the dependencies we need, and install
executable(
    meson.project_name(),
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
i18n.merge_file(
    input: 'data' / app_name + '.desktop.in',
    output: meson.project_name() + '.desktop',
    po_dir: meson.source_root() / 'po',
    type: 'desktop',
    install: true,
    install_dir: get_option('datadir') / 'applications',
)

# Translate and install our .metainfo file
i18n.merge_file(
    input: 'data' / app_name + '.metainfo.xml.in',
    output: meson.project_name() + '.metainfo.xml',
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
        rename: meson.project_name() + '.svg',
    )
    install_data(
        'data' / i + '.svg',
        install_dir: get_option('datadir') / 'icons' / 'hicolor' / i + 'x' + i +
        '@2' / 'apps',
        rename: meson.project_name() + '.svg',
    )
endforeach

# Install gschema (settings) file
install_data(
    'data' / 'quickfirenotes.gschema.xml',
    install_dir: get_option('datadir') / 'glib-2.0' / 'schemas',
    rename: meson.project_name() + '.gschema.xml',
)

meson.add_install_script('meson/post_install.py')
