conf_data = configuration_data()
conf_data.set('DATA_DIR', templates_dir)
conf_data.set('VCS_TAG', '@VCS_TAG@')

config_vala_in = configure_file(
  input: 'config.vala.in.in',
  output: 'config.vala.in',
  configuration: conf_data
)
config_vala = vcs_tag(
  input: config_vala_in,
  output: 'config.vala',
)

executable('valdo',
  config_vala,
  'main.vala',
  'template.vala',
  'templateengine.vala',
  dependencies: [deps],
  install: true)
