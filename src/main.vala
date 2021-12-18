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

[CCode (array_length = false, array_null_terminated = true)]
private string[] template_names;    // we only want one template, and we discard the rest

private bool version;

private const OptionEntry[] ENTRIES = {
    /* --version/-v, print Valdo version and quit */
    { "version", 'v', 0, NONE, ref version, "Output version", null },
    /* Non-named argument is treated as name of template to use */
    { OPTION_REMAINING, 0, 0, STRING_ARRAY, ref template_names, (string)0, "TEMPLATE" },
    /* Array terminator */
    { }
};

errordomain Valdo.TemplateApplicationError {
    USER_QUIT
}

int list_templates (string[] args) {
    var templates_dir = File.new_for_path (Config.TEMPLATES_DIR);
    bool printed_header = false;

    try {
        var enumerator = templates_dir.enumerate_children (
            FileAttribute.ID_FILE,
            NOFOLLOW_SYMLINKS);

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

        foreach (unowned string name in templates.get_keys_as_array ())
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
    try {
        ctx.add_main_entries (ENTRIES, null);
        ctx.parse (ref args);
    } catch (Error e) {
        stderr.printf ("%s\n", e.message);
        stderr.printf ("Run '%s' to see a list of available templates.\n", args[0]);
        return 1;
    }

    if (version) {
        stdout.printf ("valdo %s\n", Config.PROJECT_VERSION);
        return 0;
    }

    if (template_names.length == 0) {
        return list_templates (args);
    }

    if (template_names.length != 1) {
        stderr.printf ("%s", ctx.get_help (false, null));
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
        var substitutions = new HashTable<string, string> (GLib.str_hash, GLib.str_equal);

        stdout.printf ("creating %s\n", template.description);

        for (var i = 0; i < template.variables.length; i++) {
            unowned var variable = template.variables.index (i);
            string? user_input = null;
            string? default_value = null;
            bool input_verified = false;

            do {
                if (variable.default != null) {
                    default_value = /* FIXME: non-null */((!)variable.default).substitute (substitutions);
                    if (!variable.auto)
                        stdout.printf ("Enter %s [default=%s]: ", variable.summary, (!)default_value);
                } else {
                    stdout.printf ("Enter %s: ", variable.summary);
                }

                // (user_input == "") => user hit enter key, opt for the default value
                // (user_input == null) => user sent EOF

                if (variable.auto) {
                    user_input = "";
                } else if ((user_input = stdin.read_line ()) == null) {
                    throw new Valdo.TemplateApplicationError.USER_QUIT ("User has quit");
                }

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
            File.new_for_path (Environment.get_current_dir ()),
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
