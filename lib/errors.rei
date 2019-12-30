exception MissingEnvVar(string);
exception IncorrectDestinationPath(string);
exception IncorrectTemplateName(string);
exception Config_fileSyntaxError;
exception CurrentDirectoryNotASpinProject;
exception GeneratorDoesNotExist(string);

let handleErrors: (unit => 'a) => 'a;

type error = {
  doc: string,
  exit_code: int,
};

let all: unit => list(error);
