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
        { "version",        'v', OptionFlags.NONE, OptionArg.NONE,         ref option_version,                              "Display version number",         null },

        { "custom-dir",     'c', OptionFlags.NONE, OptionArg.FILENAME,     ref option_argument_custom_directory_override,   "Set custom templates directory", "CUSTOM_DIRECTORY" },

        /* Non-named argument is treated as name of template to use */
        { OPTION_REMAINING,   0, OptionFlags.NONE, OptionArg.STRING_ARRAY, ref non_option_arguments,                        (string) null,                    "TEMPLATE" },

        /* Array terminator */
        { }
    };

    /**
     * Whether --version option is used
     */
    private bool option_version;

    /**
     * Value of --custom-dir option argument
     */
    private string? option_argument_custom_directory_override;

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
     * @param custom_directory_override_path Path to custom templates directory provided by user
     *
     * @return {@link true} on success, {@link false} otherwise
     */
    bool initialize_project (string template_name, string? custom_directory_override_path) {
        var template_dir = File.new_build_filename (Config.TEMPLATES_DIR, template_name);

        if (!template_dir.query_exists ()) {
            try {
                var custom_templates_dir = retrieve_custom_templates_dir (custom_directory_override_path);
                string? custom_templates_dir_path = custom_templates_dir.get_path ();
                if (custom_templates_dir_path == null) {
                    throw new FileError.NOENT ("Could not find custom template directory paths");
                }

                template_dir = File.new_build_filename ((!) custom_templates_dir_path, template_name);
            } catch (Error e) {
                debug ("%s\n\n", e.message);
            }

            if (!template_dir.query_exists ()) {
                stderr.printf ("Error: '%s' is not an available template.\n\n", template_name);
                stderr.printf ("Run '%s' to see a list of available templates.\n", APP_NAME);
                return false;
            }
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
     * Enumerate templates from the specified templates directory
     * 
     * @param templates_dir Templates directory
     * @param templates Key value store for storing the name of the template as a key and the description as a value
     * @param max_template_name_len Maximum template name length. Will be used to format the output of the list of templates
     * @param error_on_fail If set to true, an error log message will be output on failure, which will cause the program to stop
     */
    void enumerate_templates (File templates_dir,
                              HashTable<string, string> templates,
                              ref int max_template_name_len,
                              bool error_on_fail = false) {
        try {
            var enumerator = templates_dir.enumerate_children (
                FileAttribute.ID_FILE,
                FileQueryInfoFlags.NONE
            );

            FileInfo? fileinfo;
            while ((fileinfo = enumerator.next_file ()) != null) {
                var template_name = ((!) fileinfo).get_name ();
                string? templates_dir_path = templates_dir.get_path ();
                if (templates_dir_path == null) {
                    throw new FileError.NOENT ("Could not find template directory path while enumerating templates:");
                }

                var template = Valdo.Template.new_from_directory (File.new_build_filename (
                    (!) templates_dir_path, template_name
                ));

                templates[template_name] = template.description;
                if (max_template_name_len < template_name.length)
                    max_template_name_len = template_name.length;
            }
        } catch (Error e) {
            string error_message = "Can't enumerate templates: %s\n\n";
            if (error_on_fail) {
                error (error_message, e.message);
            } else {
                debug (error_message, e.message);
            }
        }
    }

    /**
     * Retrieve one of the default custom templates directories
     * 
     * @param custom_directory_override_path Path to custom templates directory provided by user 
     * 
     * @return {@link GLib.File} custom template directory
     */
    File retrieve_custom_templates_dir (string? custom_directory_override_path) {
        File custom_templates_dir;

        if (custom_directory_override_path == null) {
            string? xdg_data_home_result = Environment.get_variable (Config.XDG_DATA_HOME);
            string xdg_data_home_template_path = xdg_data_home_result == null
                ? "error/not/found"
                : Path.build_filename ((string) xdg_data_home_result, Config.CUSTOM_TEMPLATES_DIR_SUB_PATH);

            debug ("XDG_DATA_HOME_TEMPLATE_PATH: %s\n\n", xdg_data_home_template_path);

            custom_templates_dir = File.new_for_path (xdg_data_home_template_path);

            if (!custom_templates_dir.query_exists ()) {
                custom_templates_dir = File.new_for_path (
                    Path.build_filename (Environment.get_home_dir (), "/", Config.FALLBACK_CUSTOM_TEMPLATES_DIR)
                );
            }
        } else {
            custom_templates_dir = File.new_for_path ((!) custom_directory_override_path);
        }

        return custom_templates_dir;
    }

    /**
     * List available templates
     * 
     * @param custom_directory_override_path Path to custom templates directory provided by user 
     */
    void list_templates (string? custom_directory_override_path) {
        var templates_dir = File.new_for_path (Config.TEMPLATES_DIR);
        File custom_templates_dir = retrieve_custom_templates_dir (custom_directory_override_path);

        var templates = new HashTable<string, string> (str_hash, str_equal);
        var custom_templates = new HashTable<string, string> (str_hash, str_equal);

        int max_template_name_len = 0;

        enumerate_templates (templates_dir, templates, ref max_template_name_len, true);
        enumerate_templates (custom_templates_dir, custom_templates, ref max_template_name_len);

        if (templates.length != 0) {
            stdout.printf ("Available templates:\n");
            stdout.printf ("--------------------\n");

            foreach (unowned string name in templates.get_keys_as_array ())
                print ("%s%s - %s\n", name, string.nfill (max_template_name_len - name.length, ' '), templates[name]);

            stdout.printf ("\n");
        } else {
            stdout.printf ("There are no templates available.\n\n");
        }

        if (custom_templates.length != 0) {
            stdout.printf ("Custom Templates:\n");
            stdout.printf ("-----------------\n");

            foreach (unowned string name in custom_templates.get_keys_as_array ()) {
                print (
                    "%s%s - %s\n", name, string.nfill (max_template_name_len - name.length, ' '),
                    custom_templates[name]
                );
            }
        } else {
            stdout.printf (Config.MISSING_CUSTOM_TEMPLATES_MESSAGE);
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

        if (option_argument_custom_directory_override != null) {
            debug ("Custom directory override path: %s\n\n", (!) option_argument_custom_directory_override);
        }

        /* --version/-v */
        if (option_version) {
            stdout.printf ("%s %s\n", APP_NAME, Config.VERSION);
            return 0;
        }

        /* List tempaltes when are no arguments provided */
        if (non_option_arguments.length == 0) {
            list_templates (option_argument_custom_directory_override);
            return 0;
        }

        /* Quit if not one template specified */
        if (non_option_arguments.length > 1) {
            stderr.printf ("Usage: %s [TEMPLATE NAME]\n", APP_NAME);
            stderr.printf ("Try '%s --help' for more information\n", APP_NAME);
            return 1;
        }

        if (initialize_project (non_option_arguments[0], option_argument_custom_directory_override))
            return 0;
        else
            return 1;
    }
}
