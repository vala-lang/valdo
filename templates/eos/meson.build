# project name and programming language
project(
    '${APP_ID}',
    'vala',
    'c',
    version: '${PROJECT_VERSION}',
)

app_id = '${APP_ID}'
app_title = '${APP_TITLE}'
app_name = '${APP_NAME}'
app_developer_name = '${AUTHOR}'
app_summary = '${APP_SUMMARY}'
app_homepage_url = '${APP_HOMEPAGE_URL}'
app_bug_tracker_url = '${APP_BUG_TRACKER_URL}'

# Feel free to change it to whatever you prefer
# Don't forget to create your LICENSE.md or COPYING file!
app_license_type = 'GPL-3.0-or-later'

# Import modules
gnome = import('gnome')
i18n = import('i18n')

add_global_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(app_id),
    language: 'c',
)

config_data = configuration_data()
config_data.set(
    'LOCALEDIR',
    join_paths(get_option('prefix'), get_option('localedir')),
)

config_data.set('APP_ID', app_id)
config_data.set('APP_PATH', '/' + app_id.replace('.', '/') + '/')
config_data.set('APP_NAME', app_name)
config_data.set('APP_TITLE', app_title)
config_data.set('APP_SUMMARY', app_summary)
config_data.set('APP_LICENSE_TYPE', app_license_type)
config_data.set('APP_DEVELOPER_NAME', app_developer_name)
config_data.set('APP_HOMEPAGE_URL', app_homepage_url)
config_data.set('APP_BUG_TRACKER_URL', app_bug_tracker_url)
config_data.set('APP_VERSION', meson.project_version())
config_data.set('GETTEXT_PACKAGE', app_id)
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
subdir('data')
subdir('po')

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

meson.add_install_script('meson/post_install.py')
