/* defaultvalue.vala
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

class Valdo.Value {
    /**
     * A pattern for patterns.
     */
    const string pattern_pattern = "^\\/\\${(\\w+)}\\/((([^\\/]|\\\\\\/)+)\\/(([^\\/]|\\\\\\/)*)\\/)+$";

    private string? referenced_var;
    private string[] patterns = {};
    private string[] replacements = {};

    public Value (string value_pattern) {
        try {
            MatchInfo match_info;
            if (new Regex (pattern_pattern).match (value_pattern, 0, out match_info)) {
                referenced_var = (!)match_info.fetch (1);
                while (match_info.matches ()) {
                    patterns += (!)match_info.fetch (3);
                    replacements += match_info.fetch (5) ?? "";
                    match_info.next ();
                }
            } else {
                replacements += value_pattern;
            }
        } catch (Error e) {
            error ("malformed regex for %s.pattern_pattern - %s", typeof (Value).name (), e.message);
        }
    }

    public string to_string (HashTable<string, string>? substitutions = null) {
        if (referenced_var != null) {
            // attempt to substitute
            string? substitution = null;    // FIXME: non-null with ternary operator
            if (substitutions != null)
                substitution = ((!)substitutions)[(!)referenced_var];   // FIXME: non-null

            if (substitution == null) {
                warning ("could not get substitution for variable %s", /* FIXME: non-null */(!)referenced_var);
                return "";
            }

            string representation = /* FIXME: non-null */ (!)substitution;
            bool have_regex = false;

            for (var i = 0; i < patterns.length && i < replacements.length; i++) {
                try {
                    var regex = new Regex (patterns[i]);
                    have_regex = true;
                    representation = regex.replace (representation, representation.length, 0, replacements[i]);
                } catch (Error e) {
                    if (!have_regex)
                        warning ("invalid match pattern in template file: %s - %s", patterns[i], e.message);
                    else
                        warning ("invalid replacement pattern in template file: %s - %s", replacements[i], e.message);
                }
            }

            return representation;
        } else {
            return replacements[0];
        }
    }
}
