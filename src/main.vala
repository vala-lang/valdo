/* main.vala
 *
 * Copyright 2021 Princeton Ferro <princetonferro@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// main options
[CCode (array_length = false, array_null_terminated = true)]
private string[] template_names;    // we only want one template, and we discard the rest
private bool opt_version;

private const OptionEntry[] main_options = {
    { "version", 'V', 0, OptionArg.NONE, ref opt_version, "Output version", null },
    { OPTION_REMAINING, 0, 0, OptionArg.STRING_ARRAY, ref template_names, (string)0, "TEMPLATE" },
    // list terminator (we can't use `null` here, see https://gitlab.gnome.org/GNOME/vala/-/issues/1185)
    { }
};

// developer options
private bool opt_list_vars;
private bool opt_list_defaults;
private string? opt_output;
[CCode (array_length = false, array_null_terminated = true)]
private string[] defines;

private const OptionEntry[] dev_options = {
    { "list-vars", 0, 0, OptionArg.NONE, ref opt_list_vars, "List variables belonging to a template", null },
    { "list-defaults", 0, 0, OptionArg.NONE, ref opt_list_defaults, "List variables common in all templates", null },
    { "output", 'o', 0, OptionArg.FILENAME, ref opt_output, "Specify parent directory of project (default: CWD)", "DIRECTORY" },
    { "define", 'D', 0, OptionArg.STRING_ARRAY, ref defines, "Define a variable", "NAME=VALUE" },
    { }
};

errordomain Valdo.TemplateApplicationError {
    USER_QUIT
}

int list_templates () {
    var templates_dir = File.new_for_path (Config.TEMPLATES_DIR);
    bool printed_header = false;

    try {
        var enumerator = templates_dir.enumerate_children (
            FileAttribute.ID_FILE,
            FileQueryInfoFlags.NOFOLLOW_SYMLINKS);

        var errors = new Array<Error> ();
        var templates = new HashTable<string, string> (str_hash, str_equal);
        FileInfo? finfo = null;
        int max_template_name_len = -1;
        while ((finfo = enumerator.next_file ()) != null) {
            unowned var template_name = /* FIXME: non-null */ ((!)finfo).get_name ();
            try {
                var template = Valdo.Template.new_from_directory (File.new_build_filename (Config.TEMPLATES_DIR, template_name));
                if (!printed_header) {
                    stdout.printf ("Available templates:\n--------------------\n");
                    printed_header = true;
                }
                templates[template_name] = template.description;
                if (max_template_name_len < template_name.length)
                    max_template_name_len = template_name.length;
            } catch (Error e) {
                errors.append_val (e);
            }
        }

        foreach (unowned var name in templates.get_keys_as_array ())
            print ("%s%s - %s\n", name, string.nfill (max_template_name_len - name.length, ' '), templates[name]);

        for (var i = 0; i < errors.length; i++)
            stderr.printf ("%s\n", errors.index (i).message);
    } catch (Error e) {
        stderr.printf ("%s\n", e.message);
        stderr.printf ("could not enumerate templates.\n");
        return 1;
    }
    if (!printed_header) {
        stdout.printf ("There are no templates available.\n");
    }
    return 0;
}

int main (string[] args) {
    var ctx = new OptionContext ("- create a Vala project from a template");
    ctx.set_summary (@"Run $(args[0]) without any args to list all available templates");
    ctx.set_description ("Report bugs to https://github.com/Prince781/valdo/issues");
    var grp = new OptionGroup ("dev", "Developer Options", "Show options for frontend developers");
    grp.add_entries (dev_options);
    try {
        ctx.add_main_entries (main_options, null);
        ctx.add_group (grp);
        ctx.parse (ref args);
    } catch (Error e) {
        stderr.printf ("%s\n", e.message);
        stderr.printf ("%s", ctx.get_help (false, null));
        return 1;
    }

    if (opt_version) {
        stdout.printf ("valdo %s\n", Config.PROJECT_VERSION);
        return 0;
    }

    if (opt_list_vars && template_names.length != 1) {
        stderr.printf ("Option --list-vars requires a template\n");
        stderr.printf ("Run '%s' to see a list of available templates.\n", args[0]);
        return 1;
    }

    if (opt_list_defaults && !opt_list_vars) {
        var array = new Array<Valdo.Variable> ();
        Valdo.Template.add_default_variables (array);
        var vars_array = new Json.Array();
        for (var i = 0; i < array.length; i++) {
            var variable = array.index (i);
            vars_array.add_element (Json.gobject_serialize (variable));
        }
        stdout.printf ("%s\n", Json.to_string (new Json.Node.alloc ().init_array (vars_array), true));
        return 0;
    }

    if (template_names.length == 0) {
        return list_templates ();
    }

    if (template_names.length != 1) {
        stderr.printf ("%s", ctx.get_help (true, null));
        return 1;
    }

    // grab the template
    unowned string template_name = template_names[0];
    var template_dir = File.new_build_filename (Config.TEMPLATES_DIR, template_name);

    if (!template_dir.query_exists ()) {
        stderr.printf ("Error: `%s' is not an available template.\n\n", template_name);
        stderr.printf ("Run '%s' to see a list of available templates.\n", args[0]);
        return 1;
    }

    try {
        var template = Valdo.Template.new_from_directory (template_dir);

        if (opt_list_vars) {                // valdo TEMPLATE --list-vars
            var vars_array = new Json.Array ();
            for (var i = 0; i < template.variables.length; i++) {
                unowned var variable = template.variables.index (i);
                // valdo TEMPLATE --list-vars --list-defaults
                if (variable.auto || variable.is_default && !opt_list_defaults)
                    continue;
                vars_array.add_element (Json.gobject_serialize (variable));
            }
            stdout.printf ("%s\n", Json.to_string (new Json.Node.alloc ().init_array (vars_array), true));
            return 0;
        }

        var substitutions = new HashTable<string, string> (GLib.str_hash, GLib.str_equal);
        var definitions = new HashTable<string, string> (GLib.str_hash, GLib.str_equal);

        foreach (var define in defines) {
            int eq_idx = define.index_of_char ('=');
            string name = define.substring (0, eq_idx);
            string val = define.substring (eq_idx + 1);

            if (eq_idx == -1 || name.length == 0 || val.length == 0) {
                stderr.printf ("Error: invalid definition: %s\n", define);
                stderr.printf ("Defines must be in the format NAME=VALUE\n");
                return 1;
            }

            definitions[name] = val;
        }

        stdout.printf ("creating %s\n", template.description);

        for (var i = 0; i < template.variables.length; i++) {
            unowned var variable = template.variables.index (i);
            string? user_input = null;
            string? default_value = null;
            bool input_verified = false;

            do {
                if (variable.default != null) {
                    default_value = /* FIXME: non-null */((!)variable.default).substitute (substitutions);
                    if (!variable.auto && !(variable.name in definitions))
                        stdout.printf ("Enter %s [default=%s]: ", variable.summary, (!)default_value);
                } else if (!(variable.name in definitions)) {
                    stdout.printf ("Enter %s: ", variable.summary);
                }

                if (variable.name in definitions) {
                    user_input = definitions[variable.name];
                } else if (variable.auto) {
                    user_input = "";
                } else if ((user_input = stdin.read_line ()) == null) {
                    throw new Valdo.TemplateApplicationError.USER_QUIT ("User has quit");
                }

                // (user_input == "") => user hit enter key, opt for the default value
                // (user_input == null) => user sent EOF

                if (user_input == "" && default_value == null) {
                    stderr.printf ("Error: %s was not specified\n", variable.summary);
                } else if (user_input != null) {
                    if (user_input == "")
                        user_input = default_value;

                    // verify input
                    if (variable.pattern != null) {
                        if (!new Regex (/* FIXME: non-null */(!)variable.pattern).match (/* FIXME: non-null */(!)user_input)) {
                            stderr.printf ("Error: your entry must match the pattern: %s\n", /* FIXME: non-null */(!)variable.pattern);
                        } else {
                            input_verified = true;
                        }
                    } else {
                        input_verified = true;
                    }
                }
            } while (!input_verified);

            substitutions[variable.name] = /* FIXME: non-null */ (!)user_input;
        }

        // now apply the template to the new directory
        string project_name = substitutions["PROJECT_DIR"];
        Valdo.TemplateEngine.apply_template (
            template,
            File.new_for_commandline_arg (opt_output ?? Environment.get_current_dir ()),
            project_name,
            substitutions
        );
    } catch (Error e) {
        if (!(e is Valdo.TemplateApplicationError.USER_QUIT)) {
            stderr.printf ("Applying template failed\n");
            stderr.printf ("%s\n", e.message);
        }
        return 1;
    }

    return 0;
}
