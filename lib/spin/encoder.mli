type 'a t = 'a -> Sexplib.Sexp.t

val string : string t

val int : int t

val float : float t

val bool : bool t

val null : Sexplib.Sexp.t

val nullable : 'a t -> 'a option t

val list : 'a t -> 'a list t

val obj : (string * Sexplib.Sexp.t) list t

val encode_sexp : 'a -> 'a t -> Sexplib.Sexp.t

val encode_string : 'a -> 'a t -> string

val encode_sexps_string : 'a -> 'a t -> string

val encode_file : string -> 'a -> 'a t -> unit
