/* templateengine.vala
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

namespace Valdo.TemplateEngine {
    /**
     * Lists all files in a directory recursively.
     */
    public HashTable<FileInfo, File> list_files (File                       dir,
                                                 HashTable<FileInfo, File>  found = new HashTable<FileInfo, File> (null, null)) throws Error {
        FileEnumerator enumerator = dir.enumerate_children (
            FileAttribute.ID_FILE,
            NOFOLLOW_SYMLINKS
        );

        try {
            FileInfo? finfo;
            while ((finfo = enumerator.next_file ()) != null) {
                var fileinfo = (!) finfo;
                if (fileinfo.get_file_type () == DIRECTORY) {
                    list_files (
                        enumerator.get_child (fileinfo),
                        found
                    );
                }
                found[fileinfo] = enumerator.get_child (fileinfo);
            }
        } catch (Error e) {
            warning ("Could not get next file in dir %s", (!) dir.get_path ());
        }

        return found;
    }


    /**
     * Apply the template to the current directory, with the substitutions.
     * A new directory will be created with the project name.
     *
     * @param template      the template to apply
     * @param current_dir   the current directory
     * @param project_name  the new project's name
     * @param variables the variable substitutions (variables => their new values)
     */
    bool apply_template (Template                   template,
                         File                       current_dir,
                         string                     project_name,
                         HashTable<string, string>  variables) throws Error {
        /* Create the new project directory */
        var project_dir = current_dir.get_child (project_name);
        if (project_dir.query_exists ()) {
            stderr.printf ("Directory already exists\n");
            return false;
        }
        project_dir.make_directory ();

        /* Copy everything into it */
        var files_list = list_files (template.directory);
        foreach (var fileinfo in files_list.get_keys_as_array ()) {
            var file_type = ((!) fileinfo).get_file_type ();
            if (!(file_type == REGULAR || file_type == SYMBOLIC_LINK ||
                  file_type == SHORTCUT || file_type == DIRECTORY))
                continue;

            var template_file = files_list[fileinfo];
            var relative_path = (!) template.directory.get_relative_path (template_file);

            if (relative_path == "template.json")
                continue;   // Don't copy over template.json

            /* Substitute path name */
            relative_path = Expression.expand_variables (relative_path, variables);

            var project_file = project_dir.resolve_relative_path (relative_path);

            if (file_type == DIRECTORY) {
                /* Create an empty directory */
                DirUtils.create_with_parents ((!) project_file.get_path (), 0755);
                continue;
            }

            /* Create the parent directory of the file */
            var parentdir = project_file.get_parent ();
            if (parentdir != null) {
                DirUtils.create_with_parents ((!) ((!) parentdir).get_path (), 0755);
            }

            /* Perform template substitutions */
            string file_contents;
            FileUtils.get_contents ((!) template_file.get_path (), out file_contents);

            file_contents = Expression.expand_variables (file_contents, variables);

            project_file.create (NONE).write_all (file_contents.data, null);
        }

        /* Finally, initialize the git repository (we don't care if this part fails) */
        if (Environment.find_program_in_path ("git") != null) {
            try {
                Process.spawn_sync (
                    project_dir.get_path (),
                    {"git", "init"},
                    Environ.get (),
                    SEARCH_PATH | SEARCH_PATH_FROM_ENVP,
                    null
                );
                /* Create a new gitignore for meson and c files */
                project_dir.get_child (".gitignore").create (NONE).write_all ("build/\n*~".data, null);
            } catch (Error e) {
                warning ("could not initialize a git repository - %s", e.message);
            }
        }

        return true;
    }
}
