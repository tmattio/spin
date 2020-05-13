open {{ project_slug | modulify }}

(** Main entry point for our application. *)

let () = print_endline @@ Utils.greet "World"
