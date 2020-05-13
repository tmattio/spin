(* From https://github.com/simonjbeaumont/ocaml-glob *)

val matches_glob : glob:string -> string -> bool

val matches_globs : globs:string list -> string -> bool

val filter_files : globs:string list -> string list -> string list
