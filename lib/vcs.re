let git_clone = (~destination, ~branch=?, repo) => {
  Console.log(
    <Pastel> {"📡  Downloading " ++ repo ++ " to " ++ destination} </Pastel>,
  );

  let args =
    switch (branch) {
    | Some(branch) => [|"clone", "-b", branch, repo, destination|]
    | None => [|"clone", repo, destination|]
    };

  let%lwt result =
    Utils.Sys.exec(
      "git",
      ~args,
      ~stdout=Lwt_process.(`Dev_null),
    );
  try(result |> Lwt.return) {
  | _ => Lwt.fail_with("Error while cloning the repository")
  };
};

/* Inspired from the reges "((git|ssh|http(s)?)|(git@[\w\.]+))(:(//)?)([\w\.@\:/\-~]+)(\.git)(/)?".
   Source: https://stackoverflow.com/questions/2514859/regular-expression-for-git-repository */
let is_git_url = value => {
  let regexp =
    Str.regexp(
      "\\(\\(git\\|ssh\\|http\\(s\\)?\\)\\|\\(git@[a-zA-Z0-9_\\.-]+\\)\\)\\(:\\(//\\)?\\)\\([[a-zA-Z0-9_\\.@:/~-]+\\)\\(\\.git\\)\\(/\\)?",
    );
  Str.string_match(regexp, value, 0);
};

let git_pull = repo => {
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
