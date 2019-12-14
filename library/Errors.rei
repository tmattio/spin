exception MissingEnvVar(string);
exception IncorrectDestinationPath(string);
exception IncorrectTemplateName(string);
exception ConfigFileSyntaxError;

let handleErrors: (unit => 'a) => 'a;

type error = {
  doc: string,
  exit_code: int,
};

let all: unit => list(error);
