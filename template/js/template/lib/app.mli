(** Top level interface for our Javascript application. *)

val inject
  :  < innerHTML :
         < get :
             < concat :
                 Js_of_ocaml.Js.js_string Js_of_ocaml.Js.t
                 -> 't0 Js_of_ocaml.Js.meth
             ; .. >
             Js_of_ocaml.Js.t
         ; set : 't0 -> unit
         ; .. >
         Js_of_ocaml.Js.gen_prop
     ; .. >
     Js_of_ocaml.Js.t
  -> unit
(** Inject the app in the given HTML elemeent

    {4 Examples}

    {[
      let elt = Js_of_ocaml.Dom_html.getElementById_exn "root"

      let () = inject elt
    ]} *)
