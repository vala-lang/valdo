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
                                               Json.Node        property_node) {
        if (property_name == "variables") {
            var variable_array = new Array<Variable> ();
            var variable_set = new GenericSet<Variable> (Variable.hash, Variable.equal_to);
            value = variable_array;

            if (property_node.get_node_type () != Json.NodeType.OBJECT) {
                warning ("expected dictionary for '%s' property", property_name);
                return true;
            }

            var object = (!) property_node.get_object ();
            /* FIXME: we can't inline `members` because of owned references and duplicating Lists */
            object.foreach_member ((object, variable_name, member_value) => {
                var variable_obj = Json.gobject_deserialize (typeof (Variable), member_value);
                if (!(variable_obj is Variable))
                    warning ("failed to deserialize variable %s", variable_name);

                if (variable_obj is Variable) {
                    var variable = (Variable)variable_obj;
                    if (variable.auto && variable.default == null) {
                        warning ("auto variable %s must have a default value", variable_name);
                        return;
                    }
                }

                ((Variable)variable_obj).name = variable_name;
                variable_set.add ((Variable) variable_obj);
                variable_array.append_val ((Variable) variable_obj);
            });

            variable_array.prepend_val (new Variable ("PROJECT_VERSION", "the project version", "0.0.1", "^\\d+(\\.\\d+)*$"));
            variable_array.prepend_val (new Variable ("PROJECT_NAME", "the project name", null, "^[^\\\\\\/#?'\"\\n]+$"));

            return true;
        } else if (property_name == "inputs") {
            var list = new GenericSet<string> (GLib.str_hash, GLib.str_equal);
            value = list;

            if (property_node.get_node_type () != Json.NodeType.ARRAY) {
                warning ("expected array for '%s' property", property_name);
                return true;
            }

            var array = (!) property_node.get_array ();
            var elements = array.get_elements ();
            /* FIXME: bindings for GLib.List<T> */
            for (unowned var node = elements; node != (void *)0; node = node.next) {
                if (node.data.get_node_type () != Json.NodeType.VALUE || node.data.get_value_type () != typeof (string)) {
                    warning ("expected string in input array");
                    continue;
                }
                list.add ((!)node.data.get_string ());
            }

            return true;
        } else {
            return default_deserialize_property (property_name, out value, pspec, property_node);
        }
    }
}
