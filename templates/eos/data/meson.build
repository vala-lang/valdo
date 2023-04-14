# Tell meson where to find our resources file and to compile it as a GResource
gresource = gnome.compile_resources(
    'gresource',
    configure_file(
        input: app_name + '.gresource.xml.in',
        output: app_name + '.gresource.xml',
        configuration: config_data,
    ),
    source_dir: join_paths(meson.source_root(), 'data'),
)

#Translate and install our .desktop file
desktop_file = i18n.merge_file(
    input: configure_file(
        input: app_name + '.desktop.in.in',
        output: app_name + '.desktop.in',
        configuration: config_data,
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
        input: app_name + '.metainfo.xml.in.in',
        output: app_name + '.metainfo.xml.in',
        configuration: config_data,
    ),
    output: app_id + '.metainfo.xml',
    po_dir: meson.source_root() / 'po',
    install: true,
    install_dir: get_option('datadir') / 'metainfo',
)

appstream_util = find_program('appstream-util', required: false)
if appstream_util.found()
    test(
        'Validate appstream file',
        appstream_util,
        args: ['validate', appstream_file],
    )
endif

# Install gschema (settings) file
gschema_file = configure_file(
    input: app_name + '.gschema.xml.in',
    output: app_id + '.gschema.xml',
    configuration: config_data,
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

# Install our icons in all the required sizes
icon_sizes = ['16', '24', '32', '48', '64', '128']

foreach i : icon_sizes
    install_data(
        'icons' / i + '.svg',
        install_dir: get_option('datadir') / 'icons' / 'hicolor' / i + 'x' + i /
        'apps',
        rename: app_id + '.svg',
    )
    install_data(
        'icons' / i + '.svg',
        install_dir: get_option('datadir') / 'icons' / 'hicolor' / i + 'x' + i +
        '@2' / 'apps',
        rename: app_id + '.svg',
    )
endforeach


