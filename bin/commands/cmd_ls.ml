open Spin

let run () =
  let open Result.Syntax in
  let+ templates = Official_template.all_doc () in
  let sorted_templates =
    List.sort
      (fun Official_template.{ name = t1; _ } Official_template.{ name = t2; _ } ->
        if String.equal (String.prefix t1 3) "bs-" then
          if String.equal (String.prefix t2 3) "bs-" then
            String.compare t1 t2
          else
            -1
        else if String.equal (String.prefix t2 3) "bs-" then
          1
        else
          String.compare t1 t2)
      templates
  in
  Logs.app (fun m -> m "");
  List.iter
    (fun Official_template.{ name; description } ->
      Logs.app (fun m -> m "  %a" Pp.pp_blue name);
      Logs.app (fun m -> m "    %s" description);
      Logs.app (fun m -> m ""))
    sorted_templates

(* Command line interface *)

open Cmdliner

let doc = "List the official templates"

let sdocs = Manpage.s_common_options

let exits = Common.exits

let envs = Common.envs

let man_xrefs = [ `Main ]

let man =
  [ `S Manpage.s_description
  ; `P
      "$(tname) will list the available official template with their \
       description."
  ]

let info = Term.info "ls" ~doc ~sdocs ~exits ~envs ~man ~man_xrefs

let term =
  let open Common.Syntax in
  let+ _term = Common.term in
  run () |> Common.handle_errors

let cmd = term, info
