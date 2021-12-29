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
     * The directory where this template resides
     */
    public File directory { get; protected set; }

    /**
     * A short description of the template
     */
    public string description { get; protected set; }

    /**
     * Array of template-specific variables
     */
    public Array<Variable> variables { get; protected set; }

    /**
     * Array of files that must be treated as templates
     */
    public string[] templates { get; protected set; }

    /**
     * Deserializes a {@link Valdo.Template} from a JSON file located at
     * `<directory>/template.json`
     *
     * @param template_dir directory containing the template
     *
     * @return loaded template
     */
    public static Template new_from_directory (File template_dir) throws Error {
        var template_json = template_dir.get_child ("template.json");
        var path = template_json.get_path ();
        if (path == null)
            throw new TemplateError.COULD_NOT_GET_PATH ("%s does not have a path", template_json.get_uri ());

        var parser = new Json.Parser ();
        parser.load_from_file ((!) path);

        if (parser.get_root () == null)
            throw new TemplateError.EMPTY_TEMPLATE_FILE ("%s: no root node", (!) path);

        var object = Json.gobject_deserialize (typeof (Template), (!) parser.get_root ());
        if (!(object is Template))
            throw new TemplateError.DESERIALIZATION_FAILED ("%s: failed to deserialize", (!) path);

        /* Set template directory */
        ((Template) object).directory = template_dir;
        return (Template) object;
    }

    public override bool deserialize_property (string    property_name,
                                               out Value value,
                                               ParamSpec pspec,
                                               Json.Node node) {
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

            ((!) variables).foreach_member ((_, name, node) => {
                var variable_obj = Json.gobject_deserialize (typeof (Variable), node) as Variable;

                if (variable_obj == null) {
                    critical ("failed to deserialize variable '%s'", name);
                    return;
                }

                var variable = (!) variable_obj;
                variable.name = name;

                variable_array.append_val (variable);
            });
            return true;
        default:
            return default_deserialize_property (property_name, out value, pspec, node);
        }
    }
}
