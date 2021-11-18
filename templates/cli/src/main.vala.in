[CCode (array_length = false, array_null_terminated = true)]
private static string[] commands;

private static bool version = false;

private const GLib.OptionEntry[] MAIN_ENTRIES = {
    { "version", '\0', OptionFlags.NONE, OptionArg.NONE, ref version, "Display version number", null },
    { OPTION_REMAINING, 0, 0, OptionArg.STRING_ARRAY, ref commands, (string)0, "COMMAND" },
    // list terminator
    { }
};

private const Command[] DEFINED_COMMANDS = {
    { "hello", "Greets you" },
};

private static void list_commands () {
    bool printed_header = false;
    int max_command_name_length = -1;

    foreach (var command in DEFINED_COMMANDS) {
        if (!printed_header) {
            stdout.printf ("Commands:\n");
            printed_header = true;
        }

        if (max_command_name_length < command.name.length) {
            max_command_name_length = command.name.length;
        }
    }

    foreach (var command in DEFINED_COMMANDS) {
        print ("  %s%s     %s\n", command.name,
            string.nfill (max_command_name_length - command.name.length, ' '), command.summary
        );
    }
    print ("\n");
}

private static bool is_in_command_list (string command_name_to_check) {
    for (int i = DEFINED_COMMANDS.length - 1; i > -1; i--) {
        var command = DEFINED_COMMANDS[i];

        if (command_name_to_check == command.name ) {
            return true;
        }
    }

    return false;
}

public static int main (string[] args) {
    // For more info, check out: https://valadoc.org/glib-2.0/GLib.OptionContext.html
    var opt_context = new OptionContext ("- ${PROJECT_SUMMARY}");
    try {
        opt_context.set_help_enabled (true);
        opt_context.add_main_entries (MAIN_ENTRIES, null);
        opt_context.parse (ref args);
    } catch (OptionError e) {
        stderr.printf ("error: %s\n", e.message);
        stderr.printf ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
        return 1;
    }

    if (version) {
        stdout.printf ("${PROJECT_VERSION}\n");
        return 0;
    }

    if (commands.length == 0) {
        list_commands ();
        return 0;
    }

    if (commands.length != 1) {
        stderr.printf ("%s", opt_context.get_help (false, null));
        return 1;
    }

    string command = commands[0];

    if (is_in_command_list (command)) {
        switch (command) {
            case "hello":
                stdout.printf ("Hello!\n");
                break;
        }

        return 0;
    } else {
        stderr.printf ("`%s` is not a valid command. Run `%s` for a list of commands\n", command, "${PROGRAM_NAME}");
    }

    return 0;
}
