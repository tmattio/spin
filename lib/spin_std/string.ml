include Stdlib.String

let lsplit2_exn on s =
  let i = index s on in
  sub s 0 i, sub s (i + 1) (length s - i - 1)

let lsplit2 on s = try Some (lsplit2_exn s on) with Not_found -> None

let prefix s len = try sub s 0 len with Invalid_argument _ -> ""

let suffix s len =
  try sub s (length s - len) len with Invalid_argument _ -> ""

let drop_prefix s len = sub s len (length s - len)

let drop_suffix s len = sub s 0 (length s - len)
