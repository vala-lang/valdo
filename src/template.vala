/* template.vala
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

/**
 * An error that occurred during the construction of a template.
 */
errordomain Valdo.TemplateError {
    COULD_NOT_GET_PATH,
    EMPTY_TEMPLATE_FILE,
    DESERIALIZATION_FAILED
}

/**
 * A template record is a JSON file containing a description of a project,
 * substitutions, and any additional commands needed to install the project.
 */
class Valdo.Template : Object, Json.Serializable {
    /**
     * Regex used to validate email
     *
     * See https://stackoverflow.com/questions/201323/how-can-i-validate-an-email-address-using-a-regular-expression
     */
    const string EMAIL_REGEX = "(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";

    /**
     * The directory where this template resides
     */
    public File directory { get; protected set; }

    /**
     * A short description of the template
     */
    public string description { get; protected set; }

    /**
     * Maps variable names to their description. The variable name is
     * recognized in the form `${VARIABLE}` inside a `.in` file.
     */
    public Array<Variable> variables { get; protected set; }

    /**
     * A list of input files (ending with `.in`) to be substituted.
     */
    public GenericSet<string> inputs { get; protected set; }

    protected Template () {}

    /**
     * Deserializes a {@link Valdo.Template} from a JSON file located at
     * `<directory>/template.json`
     */
    public static Template new_from_directory (File template_dir) throws Error {
        var template_json = template_dir.get_child ("template.json");
        var path = template_json.get_path ();
        if (path == null)
            throw new TemplateError.COULD_NOT_GET_PATH ("%s does not have a path", template_json.get_uri ());

        var parser = new Json.Parser ();
        parser.load_from_file (/* FIXME: non-null */ (!)path);

        if (parser.get_root () == null)
            throw new TemplateError.EMPTY_TEMPLATE_FILE ("%s: no root node", (!)path);

        var object = Json.gobject_deserialize (typeof (Template), /* FIXME: non-null */ (!)parser.get_root ());
        if (!(object is Template))
            throw new TemplateError.DESERIALIZATION_FAILED ("%s: failed to deserialize", (!)path);

        // set template directory
        ((Template)object).directory = template_dir;
        return (Template)object;
    }

    public override bool deserialize_property (string           property_name,
                                               out GLib.Value   value,
                                               GLib.ParamSpec   pspec,
                                               Json.Node        node) {
        switch (property_name) {
        case "variables":
            var variable_array = new Array<Variable> ();
            value = variable_array;

            var variables = node.get_node_type () == OBJECT
                ? node.get_object ()
                : null;
            if (variables == null) {
                critical ("expected dictionary for '%s' property", property_name);
                return false;
            }

            /* Load template-specific variables */
            variables?.foreach_member ((_, variable_name, node) => {
                var variable_obj = Json.gobject_deserialize (typeof (Variable), node) as Variable;
                if (variable_obj == null) {
                    warning ("failed to deserialize variable '%s'", variable_name);
                    return;
                }
                var variable = (!) variable_obj;
                variable.name = variable_name;
                if (variable.auto && variable.default == null) {
                    warning ("auto variable '%s' must have a default value", variable_name);
                }
                variable_array.append_val ((!) variable);
            });

            /* Load pre-defined variable */

            /* Real name */
            string realname;
            try {
                Process.spawn_command_line_sync ("git config --get user.name", out realname);
                realname = realname.strip ();
            } catch (SpawnError e) {
                realname = Environment.get_real_name ();
            }
            variable_array.prepend_val (new Variable ("AUTHOR", "the authors's real name", realname));

            /* Username */
            var username = Environment.get_user_name ();
            variable_array.prepend_val (new Variable ("USERNAME", "the user name", username));

            /* Email */
            string email;
            try {
                Process.spawn_command_line_sync ("git config --get user.email", out email);
                email = email.strip ();
            } catch (SpawnError e) {
                email = @"$username@$(Environment.get_host_name ())";
            }
            variable_array.prepend_val (new Variable ("USERADDR", "the user email", email, EMAIL_REGEX));

            /* Project info */
            variable_array.prepend_val (new Variable ("PROJECT_DIR", "the folder name", "/${PROJECT_NAME}/\\w+/\\L\\0\\E/\\W+/-/"));
            variable_array.prepend_val (new Variable ("PROJECT_VERSION", "the project version", "0.0.1", "^\\d+(\\.\\d+)*$"));
            variable_array.prepend_val (new Variable ("PROJECT_NAME", "the project name", null, "^[^\\\\\\/#?'\"\\n]+$"));

            return true;
        case "inputs":
            var inputs = new GenericSet<string> (str_hash, str_equal);
            value = inputs;

            var inputs_array = node.get_node_type () == ARRAY
                ? node.get_array ()
                : null;
            if (inputs_array == null) {
                warning ("expected array for '%s' property", property_name);
                return false;
            }

            inputs_array?.foreach_element ((_, i, node) => {
                var filename = node.get_string ();
                if (filename == null) {
                    warning ("expected string in inputs array");
                    return;
                }
                inputs.add ((!) filename);
            });

            return true;
        case "description":
        default:
            return default_deserialize_property (property_name, out value, pspec, node);
        }
    }
}
