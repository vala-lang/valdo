desktop_file = i18n.merge_file(
  input: configure_file(
    input: f'@app_id@.desktop.in.in',
    output: f'@app_id@.desktop.in',
    configuration: conf_data
  ),
  output: f'@app_id@.desktop',
  type: 'desktop',
  po_dir: '..' / 'po',
  install: true,
  install_dir: get_option('datadir') / 'applications'
)

desktop_utils = find_program('desktop-file-validate', required: false)
if desktop_utils.found()
  test('Validate desktop file', desktop_utils,
    args: [desktop_file]
  )
endif

appstream_file = i18n.merge_file(
  input: configure_file(
    input: f'@app_id@.appdata.xml.in.in',
    output: f'@app_id@.appdata.xml.in',
    configuration: conf_data
  ),
  output: f'@app_id@.appdata.xml',
  po_dir: '../po',
  install: true,
  install_dir: get_option('datadir') / 'appdata'
)

appstream_util = find_program('appstream-util', required: false)
if appstream_util.found()
  test('Validate appstream file', appstream_util,
    args: ['validate', appstream_file]
  )
endif

gschema_file = configure_file(
  input: f'@app_id@.gschema.xml.in',
  output: f'@app_id@.gschema.xml',
  configuration: conf_data,
  install_dir: get_option('datadir') / 'glib-2.0' / 'schemas'
)

compile_schemas = find_program('glib-compile-schemas', required: false)
if compile_schemas.found()
  test('Validate schema file', compile_schemas,
    args: ['--strict', '--dry-run', meson.current_build_dir()]
  )
endif

scalable_dir = 'icons' / 'hicolor' / 'scalable' / 'apps'
install_data(
  scalable_dir / f'@app_id@.svg',
  install_dir: get_option('datadir') / scalable_dir
)

symbolic_dir = 'icons' / 'hicolor' / 'symbolic' / 'apps'
install_data(
  symbolic_dir / f'@app_id@-symbolic.svg',
  install_dir: get_option('datadir') / symbolic_dir
)
