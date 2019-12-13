module String = {
  type t = Base.String.t;

  let rec join = (~sep: string="", l: list(t)) => {
    switch (l) {
    | [] => ""
    | [el] => el
    | [el, ...rest] => el ++ sep ++ join(rest, ~sep)
    };
  };
};

module Sys = {
  let ls_dir = (~recursive=true, directory) =>
    if (recursive) {
      let rec loop = result =>
        fun
        | [f, ...fs] when Caml.Sys.is_directory(f) =>
          Caml.Sys.readdir(f)
          |> Array.to_list
          |> List.map(~f=Caml.Filename.concat(f))
          |> List.append(fs)
          |> loop(result)
        | [f, ...fs] => loop([f, ...result], fs)
        | [] => result;

      loop([], [directory]) |> List.rev;
    } else {
      Caml.Sys.readdir(directory) |> Array.to_list;
    };

  let rename = Caml.Sys.rename;

  let exec =
      (
        ~args=[||],
        ~env=?,
        ~stderr: Lwt_process.redirection=`Keep,
        ~stdout: Lwt_process.redirection=`Keep,
        command,
      ) => {
    let realArgs = Array.append([|command|], args);
    Lwt_process.exec(~stderr, ~stdout, ~env?, ("", realArgs));
  };

  let exec_in_dir =
      (
        ~args=[||],
        ~env=?,
        ~stderr: Lwt_process.redirection=`Keep,
        ~stdout: Lwt_process.redirection=`Keep,
        ~dir: string,
        command,
      ) => {
    open Lwt;

    let old_cwd = Caml.Sys.getcwd();
    Lwt_unix.chdir(dir)
    >>= (
      () =>
        Lwt.finalize(
          () => exec(~args, ~env?, ~stderr, ~stdout, command),
          () => Lwt_unix.chdir(old_cwd),
        )
    );
  };

  let get_tempdir = prefix => {
    Printf.sprintf(
      "%s-%s",
      prefix,
      Unix.time() |> Float.to_int |> Int.to_string,
    )
    |> Caml.Filename.concat(Caml.Filename.get_temp_dir_name());
  };
};

module Filename = {
  include FileUtil;
  include FilePath;

  let ensure_trailing = s =>
    switch (Caml.String.get(s, Caml.String.length(s) - 1)) {
    | '/' => s
    | _ => s ++ "/"
    };

  let rec join = ls => {
    let rec loop = acc =>
      fun
      | [] => acc
      | [el, ...rest] =>
        Base.String.equal(acc, "")
          ? loop(el, rest) : loop(concat(acc, el), rest);
    loop("", ls);
  };
};
