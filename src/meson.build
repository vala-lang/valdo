conf_data = configuration_data()
conf_data.set('DATA_DIR', templates_dir)
conf_data.set('VCS_TAG', '@VCS_TAG@')

config_vala = configure_file(
  input: 'config.vala.in',
  output: 'config.vala',
  configuration: conf_data
)
version_vala = vcs_tag(
  input: 'version.vala.in',
  output: 'version.vala',
  command: ['git', 'describe', '--tags', '--dirty']
)

executable('valdo',
  config_vala,
  version_vala,
  'main.vala',
  'template.vala',
  'templateengine.vala',
  'value.vala',
  'variable.vala',
  dependencies: [deps],
  install: true)
