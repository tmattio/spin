exception Missing_env_var(string);
exception Incorrect_destination_path(string);
exception Incorrect_template_name(string);
exception Config_file_syntax_error;
exception Current_directory_not_a_spin_project;
exception Generator_does_not_exist(string);
exception Cannot_parse_template_file(string);
exception Cannot_access_remote_repository;
exception Generator_files_already_exist(string);

let handle_errors = fn =>
  try(fn()) {
  | Missing_env_var(name) =>
    Console.error(
      <Pastel color=Pastel.Red>
        {"😱  Ooops, it seems you don't have an environment variable named \""
         ++ name
         ++ "\". I need it to work!"}
      </Pastel>,
    );
    Caml.exit(201);
  | Incorrect_destination_path(reason) =>
    Console.error(
      <Pastel color=Pastel.Red>
        {"😱  Can't generate the template at this destination: " ++ reason}
      </Pastel>,
    );
    Caml.exit(202);
  | Incorrect_template_name(name) =>
    Console.error(
      <Pastel color=Pastel.Red>
        {"😱  The template \""
         ++ name
         ++ "\" does not exist.\n"
         ++ "The template can be a local path, a git repository or the name of an official template.\n"
         ++ "To get the list of official templates, you can use the subcommand `ls`"}
      </Pastel>,
    );
    Caml.exit(203);
  | Config_file_syntax_error =>
    Console.error(
      <Pastel color=Pastel.Red>
        "😱  There is a syntax error in one of the configuration file. I can't generate your project."
      </Pastel>,
    );
    Caml.exit(204);
  | Current_directory_not_a_spin_project =>
    Console.error(
      <Pastel>
        "You need to be inside a Spin project to run this command, but the current directory is not in a Spin project.\nA Spin project contains a file `.spin` at its root."
      </Pastel>,
    );
    Caml.exit(205);
  | Generator_does_not_exist(name) =>
    Console.error(
      <Pastel color=Pastel.Red>
        "😱  This generator does not exist, you can list the generators of the current project with the command `spin gen`."
      </Pastel>,
    );
    Caml.exit(206);
  | Cannot_parse_template_file(file) =>
    Console.error(
      <Pastel color=Pastel.Red>
        {"😱  An error occured while parsing "
         ++ file
         ++ ". Please, make sure this is a correct Jingoo template."}
      </Pastel>,
    );
    Caml.exit(207);
  | Cannot_access_remote_repository =>
    Console.error(
      <Pastel color=Pastel.Red>
        "😱  Error while accessing remote repository, please check your Internet connection."}
        </Pastel>,
      );
      Caml.exit(208);
  | Generator_files_already_exist(file) =>
    Console.error(
      <Pastel color=Pastel.Red>
        {"The generator wants to create the file "
         ++ file
         ++ ", but it already exist."}
      </Pastel>,
    );
    Caml.exit(209);
  | _ as exn =>
    Console.log(
      <Pastel color=Pastel.Red>
        {"😱  Ooops, an unknown error occured. You can file a bug reports at https://github.com/tmattio/spin.\n"
         ++ "Here is the stack trace in case it helps:\n"}
      </Pastel>,
    );

    raise(exn);
  };

type error = {
  doc: string,
  exit_code: int,
};

let all = () => [
  {doc: "on missing required environment variable.", exit_code: 201},
  {doc: "on incorrect template destination path.", exit_code: 202},
  {doc: "on incorrect template names.", exit_code: 203},
  {doc: "on syntax error in the spin configuration file.", exit_code: 204},
  {
    doc: "on project commands executed outside of a Spin project.",
    exit_code: 205,
  },
  {doc: "on calling a generator that does not exist.", exit_code: 206},
  {doc: "on failure to parse a template file.", exit_code: 207},
  {doc: "on failure to access the remote repository", exit_code: 208},
  {doc: "on generating a file that already exist.", exit_code: 209},
];
