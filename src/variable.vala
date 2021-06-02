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
    public string? default { get; protected set; }

    /**
     * Creates a new variable for substitutions.
     *
     * @param name      the variable name
     * @param summary   a short description of the variable's meaning
     * @param default   the default value, or `null`
     */
    public Variable (string name, string summary, string? default = null) {
        this.name = name;
        this.summary = summary;
        this.default = default;
    }

    public uint hash () {
        return name.hash ();
    }

    public bool equal_to (Variable other) {
        return name == other.name;
    }
}
