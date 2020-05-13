type 'a t = 'a -> Sexp.t

val string : string t

val int : int t

val float : float t

val bool : bool t

val null : Sexp.t

val nullable : 'a t -> 'a option t

val list : 'a t -> 'a list t

val obj : (string * Sexp.t) list t

val encode_sexp : f:'a t -> 'a -> Sexp.t

val encode_string : f:'a t -> 'a -> string

val encode_sexps_string : f:'a t -> 'a -> string

val encode_file : f:'a t -> path:string -> 'a -> unit
