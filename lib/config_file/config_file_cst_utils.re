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

let rec getUnique = (~f: 'a => option('b)) =>
  fun
  | [] => None
  | [el, ...rest] =>
    switch (f(el)) {
    | Some(v) => Some(v)
    | None => getUnique(rest, ~f)
    };

let getUniqueExn = (~f, cst: list('a)) => {
  switch (getUnique(cst, ~f)) {
  | Some(v) => v
  | None => raise(Errors.Config_fileSyntaxError)
  };
};
