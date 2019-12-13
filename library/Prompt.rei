let input: (
  ~validate: string => Result.t(string, string)=?,
  ~default: string=?,
  ~bold: Base.bool=?,
  string,
) => string;

let int: (
  ~validate: int => Result.t(int, string)=?,
  ~default: int=?,
  ~bold: Base.bool=?,
  string,
) => int;

let float: (
  ~validate: float => Result.t(float, string)=?,
  ~default: float=?,
  ~bold: Base.bool=?,
  string,
) => float;

let confirm: (
  ~default: bool=?,
  ~bold: Base.bool=?,
  string,
) => bool;

let list: (
  ~default: string=?,
  ~bold: Base.bool=?,
  string,
  list(string),
) => string;