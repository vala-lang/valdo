/* variable.vala
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

/**
 * Represents a variable to be substituted in a template.
 */
class Valdo.Variable : Object, Json.Serializable {
    /**
     * The variable name to substitute
     */
    public string name { get; construct set; }

    /**
     * A short description of the variable's meaning
     */
    public string summary { get; construct; default = ""; }

    /**
     * The variable's default value, or `null`
     */
    public string? @default { get; construct; }

    /**
     * The pattern that the string must match, or `null` if any string is
     * accepted.
     */
    public string? pattern { get; construct; }

    public bool auto { get; construct; }

    /**
     * Creates a new variable for substitutions.
     *
     * @param name      the variable name
     * @param summary   a short description of the variable's meaning
     * @param default   the default value, or `null`
     * @param pattern   the pattern that the string must match
     */
    public Variable (string name, string summary, string? @default = null, string? pattern = null) {
        Object (
            name: name,
            summary: summary,
            @default: @default,
            pattern: pattern
        );
    }

    /**
     * Regex used to validate email
     *
     * See https://stackoverflow.com/questions/201323/how-can-i-validate-an-email-address-using-a-regular-expression
     */
    const string EMAIL_REGEX = "(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";

    /**
     * Get list of pre-defined variables
     *
     * @return array of pre-defined variables
     */
    public static Array<Variable> list_pre_defined () {
        var variables = new Array<Variable> ();

        /* Project info */
        variables.append_val (new Variable ("PROJECT_NAME", "the project name", null, "^[^\\\\\\/#?'\"\\n]+$"));
        variables.append_val (new Variable ("PROJECT_VERSION", "the project version", "0.0.1", "^\\d+(\\.\\d+)*$"));
        variables.append_val (new Variable ("PROJECT_DIR", "the folder name", "/${PROJECT_NAME}/\\w+/\\L\\0\\E/\\W+/-/"));

        /* User's email */
        var username = Environment.get_user_name ();
        string email = @"$username@$(Environment.get_host_name ())";
        try {
            string git_email;
            Process.spawn_command_line_sync ("git config --get user.email", out git_email);
            git_email = git_email.strip ();
            if (git_email.length > 0)
                email = git_email;
        } catch (SpawnError e) {
            /* do nothing */
        }
        variables.append_val (new Variable ("USERADDR", "the user email", email, EMAIL_REGEX));

        /* Username */
        variables.append_val (new Variable ("USERNAME", "the user name", username));

        /* Get user's real name */
        string realname = Environment.get_real_name ();
        try {
            string git_realname;
            Process.spawn_command_line_sync ("git config --get user.name", out git_realname);
            git_realname = git_realname.strip ();
            if (git_realname.length > 0)
                realname = git_realname;
        } catch (SpawnError e) {
            /* do nothing */
        }
        variables.append_val (new Variable ("AUTHOR", "the authors's real name", realname));

        return variables;
    }
}
