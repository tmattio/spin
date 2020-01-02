let get = (~f: 'a => option('b), cst: list('a)) => {
  let rec loop = acc =>
    fun
    | [] => List.rev(acc)
    | [el, ...rest] =>
      switch (f(el)) {
      | Some(v) => loop([v, ...acc], rest)
      | None => loop(acc, rest)
      };

  loop([], cst);
};

let rec get_unique = (~f: 'a => option('b)) =>
  fun
  | [] => None
  | [el, ...rest] =>
    switch (f(el)) {
    | Some(v) => Some(v)
    | None => get_unique(rest, ~f)
    };

let get_unique_exn = (~f, cst: list('a)) => {
  switch (get_unique(cst, ~f)) {
  | Some(v) => v
  | None => raise(Errors.Config_file_syntax_error)
  };
};
