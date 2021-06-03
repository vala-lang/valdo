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

private bool should_list;

[CCode (array_length = false, array_null_terminated = true)]
private string[] template_names;    // we only want one template, and we discard the rest

private const OptionEntry[] entries = {
    { "list", 'l', 0, OptionArg.NONE, ref should_list, "list all templates", null },
    { OPTION_REMAINING, 0, 0, OptionArg.STRING_ARRAY, ref template_names, (string)0, "TEMPLATE" },
    // list terminator (we can't use `null` here, see https://gitlab.gnome.org/GNOME/vala/-/issues/1185)
    { (string)0 }
};

errordomain Valdo.TemplateApplicationError {
    EMPTY_VARIABLE,
    USER_QUIT
}

int main (string[] args) {
    try {
        with (new OptionContext ("- create a Vala project from a template")) {
            add_main_entries (entries, null);
            parse (ref args);
        }
    } catch (Error e) {
        with (stderr) {
            printf ("%s\n", e.message);
            printf ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
        }
        return 1;
    }

    if (should_list) {
        if (template_names.length != 0) {
            with (stderr) {
                printf ("Usage: %s TEMPLATE\n", args[0]);
                printf ("Run %s -l to see a list of templates\n", args[0]);
            }
            return 1;
        }

        var templates_dir = File.new_for_path (Config.TEMPLATES_DIR);

        try {
            var enumerator = templates_dir.enumerate_children (
                FileAttribute.ID_FILE,
                FileQueryInfoFlags.NOFOLLOW_SYMLINKS);

            var errors = new Array<Error> ();
            FileInfo? finfo = null;
            while ((finfo = enumerator.next_file ()) != null) {
                unowned var template_name = /* FIXME: non-null */ ((!)finfo).get_name ();
                try {
                    var template = Valdo.Template.new_from_directory (File.new_build_filename (Config.TEMPLATES_DIR, template_name));
                    stdout.printf ("%s - %s\n", template_name, template.description);
                } catch (Error e) {
                    errors.append_val (e);
                }
            }

            for (var i = 0; i < errors.length; i++)
                stderr.printf ("%s\n", errors.index (i).message);
        } catch (Error e) {
            with (stderr) {
                printf ("%s\n", e.message);
                printf ("could not enumerate templates.\n");
            }
            return 1;
        }
        return 0;
    }

    if (template_names.length != 1) {
        with (stderr) {
            printf ("Usage: %s TEMPLATE\n", args[0]);
            printf ("Run %s -l to see a list of templates\n", args[0]);
        }
        return 1;
    }

    // grab the template
    unowned string template_name = template_names[0];
    var template_dir = File.new_build_filename (Config.TEMPLATES_DIR, template_name);

    if (!template_dir.query_exists ()) {
        with (stderr) {
            printf ("`%s' is not an available template.\n", template_name);
            printf ("Run %s -l to see a list of templates\n", args[0]);
        }
        return 1;
    }

    try {
        var template = Valdo.Template.new_from_directory (template_dir);
        var substitutions = new HashTable<string, string> (GLib.str_hash, GLib.str_equal);

        stdout.printf ("creating %s\n", template.description);
        for (var i = 0; i < template.variables.length;) {
            unowned var variable = template.variables.index (i);
            string? user_input = null;

            if (variable.default != null)
                stdout.printf ("Enter %s [default=%s]: ", variable.summary, /* FIXME: non-null */(!)variable.default);
            else
                stdout.printf ("Enter %s: ", variable.summary);

            if ((user_input = stdin.read_line ()) == null) {
                throw new Valdo.TemplateApplicationError.USER_QUIT ("user has quit");
            }

            if (user_input == "" && variable.default == null) {
                throw new Valdo.TemplateApplicationError.EMPTY_VARIABLE (
                    "Error: %s was not specified",
                    variable.summary
                );
            }

            if (user_input == "")
                user_input = variable.default;

            // verify input
            if (variable.pattern != null) {
                if (!new Regex (/* FIXME: non-null */(!)variable.pattern).match (/* FIXME: non-null */(!)user_input)) {
                    stderr.printf ("Error: your entry must match the pattern: %s\n", /* FIXME: non-null */(!)variable.pattern);
                    continue;
                }
            }

            substitutions[variable.name] = /* FIXME: non-null */ (!)user_input;
            i++;
        }

        // now apply the template to the new directory
        string project_name = substitutions["PROJECT_NAME"];
        Valdo.TemplateEngine.apply_template (
            template,
            File.new_for_path (Environment.get_current_dir ()),
            project_name,
            substitutions
        );
    } catch (Error e) {
        if (!(e is Valdo.TemplateApplicationError.USER_QUIT))
            stderr.printf ("%s\n", e.message);
        return 1;
    }

    return 0;
}
