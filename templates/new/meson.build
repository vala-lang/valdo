project('${PROJECT_NAME}', 'vala', 'c',
  version: '${PROJECT_VERSION}')

dependencies = [
  dependency('glib-2.0'),
  dependency('gobject-2.0')
]

add_project_arguments(['--enable-experimental'], language: 'vala')

subdir('src')
