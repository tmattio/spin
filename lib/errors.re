exception MissingEnvVar(string);
exception IncorrectDestinationPath(string);
exception IncorrectTemplateName(string);
exception Config_fileSyntaxError;
exception CurrentDirectoryNotASpinProject;
exception GeneratorDoesNotExist(string);

let handleErrors = fn =>
  try(fn()) {
  | MissingEnvVar(name) =>
    Console.error(
      <Pastel color=Pastel.Red>
        {"😱  Ooops, it seems you don't have an environment variable named \""
         ++ name
         ++ "\". I need it to work!"}
      </Pastel>,
    );
    Caml.exit(201);
  | IncorrectDestinationPath(reason) =>
    Console.error(
      <Pastel color=Pastel.Red>
        {"😱  Can't generate the template at this destination: " ++ reason}
      </Pastel>,
    );
    Caml.exit(202);
  | IncorrectTemplateName(name) =>
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
  | Config_fileSyntaxError =>
    Console.error(
      <Pastel color=Pastel.Red>
        "😱  There is a syntax error in one of the configuration file. I can't generate your project."
      </Pastel>,
    );
    Caml.exit(204);
  | CurrentDirectoryNotASpinProject =>
    Console.error(
      <Pastel>
        "You need to be inside a Spin project to run this command, but the current directory is not in a Spin project.\nA Spin project contains a file `.spin` at its root."
      </Pastel>,
    );
    Caml.exit(205);
  | GeneratorDoesNotExist(name) =>
    Console.error(
      <Pastel color=Pastel.Red>
        "😱  This generator does not exist, you can list the generators of the current project with the command `spin gen`."
      </Pastel>,
    );
    Caml.exit(205);
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
  {doc: "on other exceptions.", exit_code: 299},
];
