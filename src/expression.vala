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

namespace Valdo.Expression {
    /**
     * Evaluate expression in string
     */
    public static string evaluate (string expression, HashTable<string, string> variables) {
        var res = expression;

        /* First, replace variables with their values */
        try {
            res = /(?<!\$)\$\{(?<variable>[A-Za-z_0-9]+)\}/.replace_eval (
                expression,
                expression.length,
                0,
                0,
                (match, res) => {
                    var variable = (!) match.fetch_named ("variable");

                    if (variable in variables) {
                        res.append (variables[variable]);
                    } else {
                        error ("Variable \'%s\' used in expression \'%s\' doesn't exists", variable, expression);
                    }

                    return false;
                }
            );
        } catch (RegexError e) {
            error ("Invalid expression \'%s\': %s", expression, e.message);
        }

        message ("RES IS %s", res);

        /* Then evaluate regular expressions */
        try {
            if (res[0] == '/' && res[res.length - 1] == '/')
                res = res[1:-1];
            else
                return res;

            var replacement_regex = /(?<input>(\\\/|[^\/])*)\/(?<regex>(\\\/|[^\/])*)\/(?<replacement>(\\\/|[^\/])*)/;

            var matches = true;
            while (matches) {
                matches = false;
                res = replacement_regex.replace_eval (
                    res,
                    res.length,
                    0,
                    0,
                    (match, builder) => {
                        matches = true;

                        var input_string = ((!) match.fetch_named ("input")).replace ("\\/", "/");
                        var regex_string = ((!) match.fetch_named ("regex")).replace ("\\/", "/");
                        var replacement = ((!) match.fetch_named ("replacement")).replace ("\\/", "/");

                        try {
                            var regex = new Regex (regex_string);
                            builder.append (regex.replace (input_string, input_string.length, 0, replacement, 0));
                        } catch (RegexError e) {
                            error (
                                "Can't do replacement `%s/%s/%s`: %s",
                                input_string,
                                regex_string,
                                replacement,
                                e.message
                            );
                        }

                        return true;
                    }
                );
            }
        } catch (RegexError e) {
            error ("Can't evaluate expression \'%s\': %s", expression, e.message);
        }

        return res;
    }
}
