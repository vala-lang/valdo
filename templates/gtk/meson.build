project('${PROJECT_NAME}', 'vala', 'c',
  version: '${PROJECT_VERSION}')

deps = [
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('gtk+-3.0')
]

add_project_arguments(['--enable-experimental'], language: 'vala')

subdir('src')
subdir('ui')

executable('${PROGRAM_NAME}',
           [src, resources],
           dependencies: deps,
           vala_args: [resource_args])
