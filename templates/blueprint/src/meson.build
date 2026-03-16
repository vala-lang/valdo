project_deps = [
    dependency('gtk4'),
    dependency('libadwaita-1'),
]

project_sources = files(
    'main.vala',
    
    'core/application.vala',
    'ui/main-window.vala',
)

executable(
    project_name,
    
    project_resources,
    project_sources,
    vala_args: [ '--gresourcesdir=data/' ],
    dependencies: project_deps,
    install: true,
)
