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
     * Expand variables in string
     *
     * Variables must be in that form:  ${<variable name>}.
     * To prevent variable expansion
     * add another $ before.
     *
     * @param str string containing variables to expand
     *
     * @return string with variable values instead of variable names
     */
    public string expand_variables (string                    str,
                                    HashTable<string, string> variables) {
        var res = str;
        try {
            /* Expand variables */
            res = /(?<!\$)\$\{(\w+)\}/.replace_eval (str, str.length, 0, 0, (match, builder) => {
                var variable = (!) match.fetch (1);

                if (!(variable in variables)) {
                    critical ("Variable \'%s\' doesn't exists", variable);
                    return false;
                }

                builder.append (variables[variable]);

                return false;
            });

            /* Unespace escaped variables */
            res = /\$(\$\{(\w+)\})/.replace_eval (res, res.length, res.length, 0, (match, builder) => {
                builder.append ((!) match.fetch (1));

                return false;
            });
        } catch (RegexError e) {
            critical ("Can't expand variables: %s", e.message);
        }

        return res;
    }


    /**
     * Evaluate expression in string
     *
     * Expression must have this form:
     * `value/regex/replacement/regex/replacement/...`
     *
     * Also variables can be used in expression.
     *
     * @param expression expression to evaluate
     * @param variables  hash table of variable names and values
     *
     * @return result of expression evaluating
     */
    public string evaluate (string                    expression,
                            HashTable<string, string> variables) {
        var res = expression;
        /* Evaluate regular expressions */
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

                        var input_string = expand_variables (((!) match.fetch_named ("input")).replace ("\\/", "/"), variables);
                        var regex_string = ((!) match.fetch_named ("regex")).replace ("\\/", "/");
                        var replacement = expand_variables (((!) match.fetch_named ("replacement")).replace ("\\/", "/"), variables);

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
