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

errordomain Valdo.TemplateSubstitutionError {
    COULD_NOT_GET_VARIABLE_SUBSTITUTION
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

    if (template_names.length != 1) {
        with (stderr) {
            printf ("Usage: %s TEMPLATE\n", args[0]);
            printf ("Run %s -l to see a list of templates\n", args[0]);
        }
        return 1;
    }

    // grab the template
    unowned string template_name = template_names[0];
    try {
        var template = Valdo.Template.new_from_directory (File.new_build_filename (Config.TEMPLATES_DIR, template_name));
        var substitutions = new HashTable<string, string> (GLib.str_hash, GLib.str_equal);

        stdout.printf ("creating %s\n", template.description);
        foreach (var variable_name in template.variables.get_keys_as_array ()) {
            string user_input;

            // TODO: have default values
            stdout.printf ("Enter %s: ", template.variables[variable_name]);
            if (stdin.scanf ("%ms", out user_input) == FileStream.EOF) {
                throw new Valdo.TemplateSubstitutionError.COULD_NOT_GET_VARIABLE_SUBSTITUTION (
                    "Error: %s was not specified",
                    template.variables[variable_name]
                );
            }

            substitutions[variable_name] = user_input;
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
        stderr.printf ("%s\n", e.message);
    }

    return 0;
}
