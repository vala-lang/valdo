conf_data = configuration_data()
conf_data.set('DATA_DIR', templates_dir)
conf_data.set('VCS_TAG', '@VCS_TAG@')

config_vala = vcs_tag(
  input: configure_file(
    input: 'config.vala.in',
    output: 'config.vala.in',
    configuration: conf_data
  ),
  output: 'config.vala',
  command: ['git', 'describe', '--tags', '--dirty']
)

executable('valdo',
  config_vala,
  'main.vala',
  'template.vala',
  'templateengine.vala',
  'value.vala',
  'variable.vala',
  dependencies: [deps],
  install: true)
