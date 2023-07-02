blueprints = files(
    'ui/window.blp',
)

blp_target = custom_target(
    'blueprints',

    input: blueprints,
    output: '.',
    command: [ find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@' ],
)

project_resources = gnome.compile_resources(
    project_name + '-resources',
    project_name + '.gresource.xml',
    dependencies: blp_target
)
