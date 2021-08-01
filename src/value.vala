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
    private struct Substitution {
        public string pattern;
        public string replacement;

        public Substitution (owned string pattern, owned string replacement) {
            this.pattern = pattern;
            this.replacement = replacement;
        }
    }

    private string? replaced_var;
    private Substitution[] subs = {};
    private string value_pattern;

    public Value (string value_pattern) {
        this.value_pattern = value_pattern;
        try {
            MatchInfo match_info;
            // check whether `value_pattern` is a regex
            if (new Regex ("^\\/\\${(\\w+)}").match (value_pattern, 0, out match_info)) {
                replaced_var = (!)match_info.fetch (1);
                MatchInfo submatch_info;
                int end_pos;
                if (match_info.fetch_pos (0, null, out end_pos)) {
                    var substring = value_pattern[end_pos:value_pattern.length];
                    if (new Regex ("\\/(([^\\/]|\\\\/)+)\\/(([^\\/]|\\\\/)+)")
                        .match (substring, 0, out submatch_info)) {
                        while (submatch_info.matches ()) {
                            subs += Substitution ((!) submatch_info.fetch (1), submatch_info.fetch (3) ?? "");
                            submatch_info.next ();
                        }
                    }
                }
            }
        } catch (Error e) {
            error ("malformed regex for %s - %s", typeof (Value).name (), e.message);
        }
    }

    /**
     * Substitute variables in this value.
     *
     * @param substitutions maps a variable name to a value
     */
    public string substitute (HashTable<string, string> substitutions) {
        if (replaced_var != null) {
            // attempt to substitute
            string? substitution = substitutions[(!)replaced_var];

            if (substitution == null) {
                warning ("could not get substitution for variable %s", /* FIXME: non-null */(!)replaced_var);
                return "";
            }

            string representation = /* FIXME: non-null */ (!)substitution;
            bool have_regex = false;

            for (var i = 0; i < subs.length; i++) {
                try {
                    var regex = new Regex (subs[i].pattern);
                    have_regex = true;
                    representation = regex.replace (representation, representation.length, 0, subs[i].replacement);
                } catch (Error e) {
                    if (!have_regex)
                        warning ("invalid match pattern in template file: %s - %s", subs[i].pattern, e.message);
                    else
                        warning ("invalid replacement pattern in template file: %s - %s", subs[i].replacement, e.message);
                }
            }

            return representation;
        } else {
            // substitute variables as they appear in the string
            try {
                return /(?!<\$)\${(\w+)}/m.replace_eval (value_pattern, value_pattern.length, 0, 0, (match_info, result) => {
                    string variable_name = (!)match_info.fetch (1);

                    if (variable_name in substitutions) {
                        result.append (substitutions[variable_name]);
                    } else {
                        warning ("could not substitute `${%s}` in default pattern `%s` - prepend a `$` if this was intentional",
                                 variable_name, value_pattern);
                        result.append (variable_name);
                    }

                    return false;
                });
            } catch (Error e) {
                error ("invalid pattern - %s", e.message);
            }
        }
    }
}
