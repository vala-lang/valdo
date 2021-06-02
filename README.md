# Valdo

_(like "**Val**a **Do**", pronounced like "Waldo")_

Create a new Vala project from a repository of templates.

## Example use

`valdo new` - initializes a new project (from a template `new`) in the current directory

`valdo gtk` - initializes a new GTK app

`valdo lib` - initializes a new library

`valdo -l` - lists all available templates

## Creating a new a template

Templates should be added here so that they can be used by everyone.

Fork this repository and add a new directory under `templates/`. The name of the directory is the template name. Then you need to add a `template.json` describing the template, the variables it uses, and the files that need to be substituted.

Here is what a template might look like:

```
.
├── meson.build.in
├── README.md.in
├── src
│   ├── main.vala
│   └── meson.build.in
└── template.json

1 directory, 5 files
```

Each file ending with `.in` is a template file.

Your `template.json` may start off looking like:
```json
{
    "description": "a bare app, with minimal dependencies",
    "variables": {
        "PROGRAM_NAME": {
            "summary": "the name of the program",
            "default": "main"
        }
    },
    "inputs": [
        "src/meson.build.in",
        "meson.build.in",
        "README.md.in"
    ]
}
```

`"variables"` is a dictionary mapping each variable name to a short description. Having a default value for a variable is optional. There are at least two variables every template uses, `PROJECT_NAME` and `PROJECT_VERSION`, which you don't have to specify.

For every variable listed, the template engine will substitute `${VARIABLE_NAME}` in each templated file listed in `"inputs"` after prompting the user. All other files in the template directory will be copied over unmodified. Templated files should end with `.in`.

**Once you're done, submit a PR to https://github.com/Prince781/valdo**
