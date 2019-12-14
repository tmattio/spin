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

module Bool = {
  let rec all_true =
    fun
    | [] => true
    | [false, ...rest] => false
    | [true, ...rest] => all_true(rest);

  let rec any_true =
    fun
    | [] => false
    | [true, ...rest] => true
    | [false, ...rest] => any_true(rest);
};

module Sys = {
  let ls_dir =
      (~recursive=true, ~ignore_files: option(list(string))=?, directory) => {
    let ignore_file = f => {
      Option.map(ignore_files, ~f=patterns => {
        Bool.any_true(
          List.map(
            patterns,
            ~f=pattern => {
              let regexp = Str.regexp(pattern);
              Str.string_match(regexp, f, 0);
            },
          ),
        )
      })
      |> Option.value(~default=false);
    };

    if (recursive) {
      let rec loop = result =>
        fun
        | [f, ...fs] when Caml.Sys.is_directory(f) && !ignore_file(f) =>
          Caml.Sys.readdir(f)
          |> Array.to_list
          |> List.map(~f=Caml.Filename.concat(f))
          |> List.append(fs)
          |> loop(result)
        | [f, ...fs] when !ignore_file(f) => loop([f, ...result], fs)
        | [f, ...fs] => loop(result, fs)
        | [] => result;

      loop([], [directory]) |> List.rev;
    } else {
      Caml.Sys.readdir(directory) |> Array.to_list;
    };
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
