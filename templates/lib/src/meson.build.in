conf = configuration_data()
conf.set('prefix', get_option('prefix'))
conf.set('libdir', get_option ('libdir'))
conf.set('PROJECT_NAME', '${PROJECT_NAME}')
conf.set('PROJECT_VERSION', '${PROJECT_VERSION}')
conf.set('API_VERSION', API_VERSION)

sources = files([
  'library.vala'
  ])

lib${LIBRARY_DEPNAME} = library('${LIBRARY_NAME}-' + API_VERSION,
  sources,
  vala_header: '${LIBRARY_NAME}.h',
  vala_vapi: '${LIBRARY_NAME}-' + API_VERSION + '.vapi',
  vala_gir: '${API_NAMESPACE}-' + API_VERSION + '.gir',
  dependencies : dependencies,
  vala_args: [
    '--abi-stability'
    ],
  install: true,
  install_dir: [
    true,
    get_option('includedir') / '${LIBRARY_NAME}-' + API_VERSION / '${LIBRARY_NAME}',
    vapidir,
    g_ir_compiler.found()
  ]
)

if g_ir_compiler.found()
  custom_target('lib${LIBRARY_NAME}-typelib',
    command: [
      g_ir_compiler,
      '--shared-library', 'lib${LIBRARY_NAME}-@0@.so'.format (API_VERSION),
      '--output', '@OUTPUT@',
      meson.current_build_dir() / '${API_NAMESPACE}-' + API_VERSION + '.gir'
    ],
    output: '${API_NAMESPACE}-' + API_VERSION + '.typelib',
    depends: lib${LIBRARY_DEPNAME},
    install: true,
    install_dir: join_paths(get_option('libdir'), 'girepository-1.0'))
endif

pkgconfig.generate(lib${LIBRARY_DEPNAME},
  subdirs: '${LIBRARY_NAME}-' + API_VERSION,
  version: API_VERSION,
  name: '${LIBRARY_NAME}',
  filebase: '${LIBRARY_NAME}-' + API_VERSION,
  requires: PKGCONFIG_DEPS,
  description: '${PROJECT_SUMMARY}')

if get_option('enable_valadoc')
  valadoc = find_program('valadoc')
  ${LIBRARY_DEPNAME}_docs = custom_target('${LIBRARY_NAME}_apidocs',
    input: sources,
    install: true,
    # FIXME: Installing to tmp, so the target will be built
    #        the problem is we cannot access a subfolder of the
    #        buildtarget via the output parameter.
    #        Find a nicer solution
    install_dir: get_option('datadir') / 'devhelp' / 'books',
    command: [
      valadoc,
      '-o', meson.current_build_dir() / '${API_NAMESPACE}-' + API_VERSION,
      '--doclet',
      'devhelp',
      '@INPUT@',
      '--force'
    ],
    output: '${API_NAMESPACE}-' + API_VERSION)

  install_subdir(meson.current_build_dir() / '${API_NAMESPACE}-' + API_VERSION / '${API_NAMESPACE}-' + API_VERSION,
    install_dir: get_option('datadir') / 'devhelp' / 'books')
endif
