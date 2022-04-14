/* main.vala
 *
 * Copyright 2021 Princeton Ferro <princetonferro@gmail.com>
 * Copyright 2021 Gleb Smirnov <glebsmirnov0708@gmail.com>
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

namespace Valdo.Main {
    /**
     * Application name retrieved from arguments
     */
    static string APP_NAME;

    /**
     * Command-line options
     */
    private const OptionEntry[] ENTRIES = {
        { "version",        'v', OptionFlags.NONE, OptionArg.NONE, ref option_version,        "Display version number",   null },

        /* Non-named argument is treated as name of template to use */
        { OPTION_REMAINING,   0, OptionFlags.NONE, OptionArg.STRING_ARRAY, ref non_option_arguments, (string) null, "TEMPLATE" },

        /* Array terminator */
        { }
    };

    /**
     * Whether --version option is used
     */
    private bool option_version;

    /**
     * Non-option command-line arguments
     *
     * There should be only one such argument
     * representing template name to use
     */
    [CCode (array_length = false, array_null_terminated = true)]
    private string[] non_option_arguments;

    /**
     * Initialize project from template
     *
     * @param template_name the name of template to use
     *
     * @return {@link true} on success, {@link false} otherwise
     */
    bool initialize_project (string template_name) {
        var template_dir = File.new_build_filename (Config.TEMPLATES_DIR, template_name);

        if (!template_dir.query_exists ()) {
            stderr.printf ("Error: '%s' is not an available template.\n\n", template_name);
            stderr.printf ("Run '%s' to see a list of available templates.\n", APP_NAME);
            return false;
        }

        try {
            var variables = new HashTable<string, string> (str_hash, str_equal);
            var template = Valdo.Template.new_from_directory (template_dir);

            stdout.printf ("Creating %s\n", template.description);

            var vars = Variable.list_pre_defined ();
            foreach (var variable in template.variables.data)
                vars.append_val (variable);

            foreach (var variable in vars.data) {
                string value;
                string? default_value;
                if (variable.default == null)
                    default_value = null;
                else {
                    default_value = Valdo.Expression.expand_variables (
                        Valdo.Expression.evaluate (
                            (!) variable.default,
                            variables
                        ),
                        variables
                    );
                }

                while (true) {
                    /* Print prompt */
                    if (!variable.auto) {
                        stdout.printf ("Enter %s", variable.summary);
                        if (default_value != null)
                            stdout.printf (" [default=%s]", (!) default_value);
                        stdout.printf (": ");
                    }

                    /* Don't ask for auto variables */
                    if (variable.auto) {
                        if (default_value == null)
                            error ("Can't get variable '%s': auto variables must have default value", variable.name);
                        value = (!) default_value;
                        break;
                    }

                    var user_input = stdin.read_line ();

                    /* User sent EOF */
                    if (user_input == null) {
                        stderr.printf ("\nProject initialization was terminated by user\n");
                        return false;
                    }
                    user_input = ((!) user_input).strip ();

                    /* Use default if
                       value not specified */
                    if (((!) user_input).length == 0) {
                        if (default_value == null) {
                            stderr.printf ("Please, specify %s\n", variable.summary);
                            continue;
                        }
                        value = (!) default_value;
                    } else {
                        value = (!) user_input;
                    }

                    /* Verify input */
                    if (!new Regex (variable.pattern ?? "").match (value)) {
                        stderr.printf ("Error: your entry must match the pattern: %s\n", (!) variable.pattern);
                        continue;
                    }

                    break;
                }

                variables[variable.name] = value;
            }

            /* Now apply the template to the new directory */
            string project_name = variables["PROJECT_DIR"];
            return Valdo.TemplateEngine.apply_template (
                template,
                File.new_for_path (Environment.get_current_dir ()),
                project_name,
                variables
            );
        } catch (Error e) {
            error ("Can't initialize project from template: %s", e.message);
        }
    }

    /**
     * List available templates
     */
    void list_templates () {
        var templates_dir = File.new_for_path (Config.TEMPLATES_DIR);
        var templates = new HashTable<string, string> (str_hash, str_equal);
        int max_template_name_len = 0;

        try {
            var enumerator = templates_dir.enumerate_children (
                FileAttribute.ID_FILE,
                FileQueryInfoFlags.NONE
            );

            FileInfo? fileinfo;
            while ((fileinfo = enumerator.next_file ()) != null) {
                var template_name = ((!) fileinfo).get_name ();
                var template = Valdo.Template.new_from_directory (File.new_build_filename (
                    Config.TEMPLATES_DIR, template_name
                ));
                templates[template_name] = template.description;
                if (max_template_name_len < template_name.length)
                    max_template_name_len = template_name.length;
            }
        } catch (Error e) {
            error ("Can't enumerate templates: %s", e.message);
        }

        if (templates.length != 0) {
            stdout.printf ("Available templates:\n");
            stdout.printf ("--------------------\n");

            foreach (unowned string name in templates.get_keys_as_array ())
                print ("%s%s - %s\n", name, string.nfill (max_template_name_len - name.length, ' '), templates[name]);
        } else {
            stdout.printf ("There are no templates available.\n");
        }
    }

    /**
     * Application entry point
     *
     * @param args command-line arguments
     *
     * @return result code
     */
    int main (string[] args) {
        APP_NAME = args.length > 0 ? args[0] : "valdo";

        /* Parse command-line options */
        var ctx = new OptionContext ("- create a Vala project from a template");

        ctx.set_summary (@"Run $(APP_NAME) without any args to list all available templates");
        ctx.set_description ("Report bugs to https://github.com/Prince781/valdo/issues");
        ctx.add_main_entries (ENTRIES, null);

        try {
            ctx.parse (ref args);
        } catch (Error e) {
            stderr.printf ("%s\n", e.message);
            stderr.printf ("Try '%s --help' for more information\n", APP_NAME);
            return 1;
        }

        /* --version/-v */
        if (option_version) {
            stdout.printf ("%s %s\n", APP_NAME, Config.VERSION);
            return 0;
        }

        /* List tempaltes when are no arguments provided */
        if (non_option_arguments.length == 0) {
            list_templates ();
            return 0;
        }

        /* Quit if not one template specified */
        if (non_option_arguments.length > 1) {
            stderr.printf ("Usage: %s [TEMPLATE NAME]\n", APP_NAME);
            stderr.printf ("Try '%s --help' for more information\n", APP_NAME);
            return 1;
        }

        if (initialize_project (non_option_arguments[0]))
            return 0;
        else
            return 1;
    }
}
