let rec read =
        (
          ~validate: string => Result.t('a, string),
          ~default: option(('a, string))=?,
          ~bold: bool=true,
          prompt: string,
        )
        : 'a => {
  Pastel.make(~bold=true, [prompt ++ ": "]) |> Stdio.Out_channel.print_string;

  switch (default) {
  | None => ()
  | Some((_, default)) =>
    Stdio.Out_channel.print_string("[");
    Stdio.Out_channel.print_string(default);
    Stdio.Out_channel.print_string("] ");
  };

  Stdio.Out_channel.flush(Stdio.stdout);
  let user_input = Stdio.In_channel.input_line(Stdio.stdin);

  let validate = s => {
    let s = String.strip(s);

    String.equal(s, "")
      ? switch (default) {
        | Some((default, _)) => Ok(default)
        | None => Error("Enter a value.")
        }
      : validate(s);
  };

  switch (user_input) {
  | None => read(prompt, ~validate, ~default?)
  | Some(user_input) =>
    switch (validate(user_input)) {
    | Ok(result) => result
    | Error(error) =>
      Pastel.make(~color=Pastel.Red, [error]) |> Stdio.print_endline;
      read(prompt, ~validate, ~default?, ~bold);
    }
  };
};

let input =
    (
      ~validate: option(string => Result.t(string, string))=?,
      ~default: option(string)=?,
      ~bold: bool=true,
      prompt: string,
    )
    : string => {
  let validate = Option.value(validate, ~default=s => Result.Ok(s));
  let default = Option.map(default, ~f=default => (default, default));
  read(prompt, ~validate, ~default?, ~bold);
};

let number =
    (
      ~validate: option('a => Result.t('a, string))=?,
      ~default: option(('a, string))=?,
      ~conv_fn: string => 'a,
      ~bold: bool=true,
      ~error: string,
      prompt: string,
    )
    : 'a => {
  let validate = s => {
    let result =
      try(Result.Ok(conv_fn(s))) {
      | _ => Result.Error(error)
      };

    switch (validate) {
    | Some(f) => Result.bind(result, ~f)
    | None => result
    };
  };

  read(prompt, ~validate, ~default?, ~bold);
};

let int =
    (
      ~validate: option(int => Result.t(int, string))=?,
      ~default: option(int)=?,
      ~bold: bool=true,
      prompt: string,
    )
    : int => {
  let default =
    Option.map(default, ~f=default => (default, Int.to_string(default)));
  number(
    prompt,
    ~conv_fn=Int.of_string,
    ~error="Enter an integer.",
    ~default?,
    ~validate?,
    ~bold,
  );
};

let float =
    (
      ~validate: option(float => Result.t(float, string))=?,
      ~default: option(float)=?,
      ~bold: bool=true,
      prompt: string,
    )
    : float => {
  let default =
    Option.map(default, ~f=default => (default, Float.to_string(default)));
  number(
    prompt,
    ~conv_fn=Float.of_string,
    ~error="Enter a decimal.",
    ~default?,
    ~validate?,
    ~bold,
  );
};

let confirm = (~default: option(bool)=?, ~bold: bool=true, prompt: string) => {
  let validate = s => {
    switch (String.lowercase(s)) {
    | "n"
    | "no" => Result.Ok(true)
    | "y"
    | "yes" => Result.Ok(false)
    | _ => Result.Error("Enter y or n.")
    };
  };

  let prompt = prompt ++ " (y/n)";
  let default =
    Option.map(default, ~f=default => (default, default ? "y" : "n"));
  read(prompt, ~validate, ~default?, ~bold);
};

let list =
    (
      ~default: option(string)=?,
      ~bold: bool=true,
      prompt: string,
      choices: list(string),
    ) => {
  Pastel.make(~bold=true, [prompt]) |> Stdio.print_endline;
  List.iteri(choices, ~f=(i, el) =>
    Stdio.Out_channel.print_endline(Int.to_string(i + 1) ++ " - " ++ el)
  );

  let length = List.length(choices);
  let range =
    List.range(1, length + 1)
    |> List.map(~f=Int.to_string)
    |> Utils.String.join(~sep=", ");
  let prompt = "Choose from (" ++ range ++ ")";
  let validate = i =>
    if (i >= 1 && i <= length) {
      Result.Ok(i);
    } else {
      Result.Error(
        "Choose a number between 1 and " ++ Int.to_string(length),
      );
    };

  let default =
    Option.bind(
      default,
      ~f=default => {
        let r = List.findi(choices, ~f=(_, el) => String.equal(el, default));
        switch (r) {
        | Some((i, _)) => Some(i + 1)
        | None => None
        };
      },
    );

  let choice = int(prompt, ~default?, ~validate, ~bold=false);

  let opt =
    choices
    |> List.findi(~f=(i, _) => i == choice - 1)
    |> Option.map(~f=((_, el)) => el);

  Option.value_exn(opt);
};
