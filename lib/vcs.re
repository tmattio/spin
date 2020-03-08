open Lwt;

let git_clone = (~destination, ~branch=?, repo) => {
  let args =
    switch (branch) {
    | Some(branch) => [|"clone", "-b", branch, repo, destination|]
    | None => [|"clone", repo, destination|]
    };

  Utils.Sys.exec(
    "git",
    ~args,
    ~stdout=Lwt_process.(`Dev_null),
    ~stderr=Lwt_process.(`Dev_null),
  )
  >>= (
    result =>
      try(result |> Lwt.return) {
      | _ => Lwt.fail_with("Error while cloning the repository")
      }
  );
};

/* Inspired from the regex "((git|ssh|http(s)?)|(git@[\w\.]+))(:(//)?)([\w\.@\:/\-~]+)(\.git)(/)?".
   Source: https://stackoverflow.com/questions/2514859/regular-expression-for-git-repository */
let is_git_url = value => {
  let regexp =
    Str.regexp(
      "\\(\\(git\\|ssh\\|http\\(s\\)?\\)\\|\\(git@[a-zA-Z0-9_\\.-]+\\)\\)\\(:\\(//\\)?\\)\\([[a-zA-Z0-9_\\.@:/~-]+\\)\\(\\.git\\)\\(/\\)?",
    );
  Str.string_match(regexp, value, 0);
};

let git_pull = repo => {
  Utils.Sys.exec(
    "git",
    ~args=[|"-C", repo, "pull"|],
    ~stdout=Lwt_process.(`Dev_null),
    ~stderr=Lwt_process.(`Dev_null),
  )
  >>= (
    result =>
      try(result |> Lwt.return) {
      | _ => Lwt.fail_with("Error while pulling the repository")
      }
  );
};
