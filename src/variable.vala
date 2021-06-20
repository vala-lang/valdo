/* variable.vala
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
 * Represents a variable to be substituted in a template.
 */
class Valdo.Variable : Object, Json.Serializable {
    /**
     * The variable name to substitute
     */
    public string name { get; set; }

    /**
     * A short description of the variable's meaning
     */
    public string summary { get; protected set; }

    /**
     * The variable's default value, or `null`
     */
    public Value? default { get; protected set; }

    /**
     * The pattern that the string must match, or `null` if any string is
     * accepted.
     */
    public string? pattern { get; protected set; }

    public bool auto { get; protected set; }

    /**
     * Creates a new variable for substitutions.
     *
     * @param name      the variable name
     * @param summary   a short description of the variable's meaning
     * @param default   the default value, or `null`
     * @param pattern   the pattern that the string must match
     */
    public Variable (string name, string summary, string? default = null, string? pattern = null) {
        this.name = name;
        this.summary = summary;
        if (default != null)
            this.default = new Value (/* FIXME: non-null */(!)default);
        this.pattern = pattern;
    }

    public override bool deserialize_property (string           property_name,
                                               out GLib.Value   value,
                                               GLib.ParamSpec   pspec,
                                               Json.Node        property_node) {
        if (property_name == "default") {
            if (property_node.get_value_type () != typeof (string)) {
                value = "";
                warning ("could not deserialize property '%s' from template file", property_name);
                return false;
            }

            value = new Valdo.Value ((!)property_node.get_string ());
            return true;
        } else if (property_name == "name" || property_name == "summary" || property_name == "pattern") {
            // workaround for json-glib < 1.5.2 (Ubuntu 20.04 / eOS 6)
            if (property_node.get_value_type () != typeof (string)) {
                value = "";
                warning ("could not deserialize property '%s' from template file", property_name);
                return false;
            }

            value = (!)property_node.get_string ();
            return true;
        } else if (property_name == "auto") {
            // workaround for json-glib < 1.5.2 (Ubuntu 20.04 / eOS 6)
            if (property_node.get_value_type () != typeof (bool)) {
                value = false;
                warning ("could not deserialize property '%s' from tempalte file", property_name);
                return true;
            }

            value = (!)property_node.get_boolean ();
            return true;
        } else {
            return default_deserialize_property (property_name, out value, pspec, property_node);
        }
    }

    public uint hash () {
        return name.hash ();
    }

    public bool equal_to (Variable other) {
        return name == other.name;
    }
}
