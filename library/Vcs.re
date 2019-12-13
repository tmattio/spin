let gitClone = (repo, ~destination) => {
  let%lwt result =
    Utils.Sys.exec(
      "git",
      ~args=[|"clone", repo, destination|],
      ~stdout=Lwt_process.(`Dev_null),
    );
  try(result |> Lwt.return) {
  | _ => Lwt.fail_with("Error while cloning the repository")
  };
};

let isGitUrl = value => {
  let regexp =
    Str.regexp(
      "\\(\\(git|ssh|file|https?\\):\\(//\\)?\\)|\\(\\w+@[\\w\\.]+\\)",
    );
  Str.string_match(regexp, value, 0);
};

let gitPull = repo => {
  let%lwt result =
    Utils.Sys.exec(
      "git",
      ~args=[|"-C", repo, "pull"|],
      ~stdout=Lwt_process.(`Dev_null),
    );
  try(result |> Lwt.return) {
  | _ => Lwt.fail_with("Error while pulling the repository")
  };
};
