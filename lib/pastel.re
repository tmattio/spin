/** Module to style a string in the terminal.

    This tries to mimic Pastel's API. As Pastel is not on Opam, we don't want to depend on if for now.
    Once it is release, however, we would like to replace this module by Pastel. */

type color =
  | Default
  | Black
  | Red
  | Green
  | Yellow
  | Blue
  | Magenta
  | Cyan
  | White
  | BlackBright
  | RedBright
  | GreenBright
  | YellowBright
  | BlueBright
  | MagentaBright
  | CyanBright
  | WhiteBright;

type t = {
  bold: bool,
  dim: bool,
  italic: bool,
  underline: bool,
  inverse: bool,
  hidden: bool,
  strikethrough: bool,
  color,
  background: color,
};

let default = {
  bold: false,
  dim: false,
  italic: false,
  underline: false,
  inverse: false,
  hidden: false,
  strikethrough: false,
  color: Default,
  background: Default,
};

module Style = {
  let apply_code = (~start, ~stop, s) =>
    "\027["
    ++ Int.to_string(start)
    ++ "m"
    ++ s
    ++ "\027["
    ++ Int.to_string(stop)
    ++ "m";

  let apply_color = (~color, s) =>
    switch (color) {
    | Default => s
    | Black => apply_code(s, ~start=30, ~stop=39)
    | Red => apply_code(s, ~start=31, ~stop=39)
    | Green => apply_code(s, ~start=32, ~stop=39)
    | Yellow => apply_code(s, ~start=33, ~stop=39)
    | Blue => apply_code(s, ~start=34, ~stop=39)
    | Magenta => apply_code(s, ~start=35, ~stop=39)
    | Cyan => apply_code(s, ~start=36, ~stop=39)
    | White => apply_code(s, ~start=37, ~stop=39)
    | BlackBright => apply_code(s, ~start=90, ~stop=39)
    | RedBright => apply_code(s, ~start=91, ~stop=39)
    | GreenBright => apply_code(s, ~start=92, ~stop=39)
    | YellowBright => apply_code(s, ~start=93, ~stop=39)
    | BlueBright => apply_code(s, ~start=94, ~stop=39)
    | MagentaBright => apply_code(s, ~start=95, ~stop=39)
    | CyanBright => apply_code(s, ~start=96, ~stop=39)
    | WhiteBright => apply_code(s, ~start=97, ~stop=39)
    };

  let apply_background = (~background, s) =>
    switch (background) {
    | Default => s
    | Black => apply_code(s, ~start=40, ~stop=49)
    | Red => apply_code(s, ~start=41, ~stop=49)
    | Green => apply_code(s, ~start=42, ~stop=49)
    | Yellow => apply_code(s, ~start=43, ~stop=49)
    | Blue => apply_code(s, ~start=44, ~stop=49)
    | Magenta => apply_code(s, ~start=45, ~stop=49)
    | Cyan => apply_code(s, ~start=46, ~stop=49)
    | White => apply_code(s, ~start=47, ~stop=49)
    | BlackBright => apply_code(s, ~start=100, ~stop=49)
    | RedBright => apply_code(s, ~start=101, ~stop=49)
    | GreenBright => apply_code(s, ~start=102, ~stop=49)
    | YellowBright => apply_code(s, ~start=103, ~stop=49)
    | BlueBright => apply_code(s, ~start=104, ~stop=49)
    | MagentaBright => apply_code(s, ~start=105, ~stop=49)
    | CyanBright => apply_code(s, ~start=106, ~stop=49)
    | WhiteBright => apply_code(s, ~start=107, ~stop=49)
    };

  let apply_bold = (~bold, s) =>
    if (bold) {
      apply_code(s, ~start=1, ~stop=22);
    } else {
      s;
    };

  let apply_dim = (~dim, s) =>
    if (dim) {
      apply_code(s, ~start=2, ~stop=22);
    } else {
      s;
    };

  let apply_italic = (~italic, s) =>
    if (italic) {
      apply_code(s, ~start=3, ~stop=23);
    } else {
      s;
    };

  let apply_underline = (~underline, s) =>
    if (underline) {
      apply_code(s, ~start=4, ~stop=24);
    } else {
      s;
    };

  let apply_inverse = (~inverse, s) =>
    if (inverse) {
      apply_code(s, ~start=7, ~stop=27);
    } else {
      s;
    };

  let apply_hidden = (~hidden, s) =>
    if (hidden) {
      apply_code(s, ~start=8, ~stop=28);
    } else {
      s;
    };

  let apply_strikethrough = (~strikethrough, s) =>
    if (strikethrough) {
      apply_code(s, ~start=9, ~stop=29);
    } else {
      s;
    };

  let apply = (~style, s) => {
    let s = apply_bold(s, ~bold=style.bold);
    let s = apply_dim(s, ~dim=style.dim);
    let s = apply_italic(s, ~italic=style.italic);
    let s = apply_underline(s, ~underline=style.underline);
    let s = apply_inverse(s, ~inverse=style.inverse);
    let s = apply_hidden(s, ~hidden=style.hidden);
    let s = apply_strikethrough(s, ~strikethrough=style.strikethrough);
    let s = apply_color(s, ~color=style.color);
    let s = apply_background(s, ~background=style.background);
    s;
  };

  let bold = (~style, v) => {...style, bold: v};

  let dim = (~style, v) => {...style, dim: v};

  let italic = (~style, v) => {...style, italic: v};

  let underline = (~style, v) => {...style, underline: v};

  let inverse = (~style, v) => {...style, inverse: v};

  let hidden = (~style, v) => {...style, hidden: v};

  let strikethrough = (~style, v) => {...style, strikethrough: v};

  let color = (~style, v) => {...style, color: v};

  let background = (~style, v) => {...style, background: v};
};

let make =
    (
      ~bold=?,
      ~dim=?,
      ~italic=?,
      ~underline=?,
      ~inverse=?,
      ~hidden=?,
      ~strikethrough=?,
      ~color=?,
      ~background=?,
      l,
    ) => {
  let style = default;
  let style = Option.value(bold, ~default=style.bold) |> Style.bold(~style);
  let style = Option.value(dim, ~default=style.dim) |> Style.dim(~style);
  let style =
    Option.value(italic, ~default=style.italic) |> Style.italic(~style);
  let style =
    Option.value(underline, ~default=style.underline)
    |> Style.underline(~style);
  let style =
    Option.value(inverse, ~default=style.inverse) |> Style.inverse(~style);
  let style =
    Option.value(hidden, ~default=style.hidden) |> Style.hidden(~style);
  let style =
    Option.value(strikethrough, ~default=style.strikethrough)
    |> Style.strikethrough(~style);
  let style =
    Option.value(color, ~default=style.color) |> Style.color(~style);
  let style =
    Option.value(background, ~default=style.background)
    |> Style.background(~style);

  List.fold(l, ~init="", ~f=(acc, el) => {acc ++ Style.apply(~style, el)});
};
