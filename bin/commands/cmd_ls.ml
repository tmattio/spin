open Spin

let run () =
  let open Result.Let_syntax in
  let+ templates = Official_template.all_doc () in
  let sorted_templates =
    List.sort templates ~compare:(fun { name = t1; _ } { name = t2; _ } ->
        if String.equal (String.prefix t1 3) "bs-" then
          if String.equal (String.prefix t2 3) "bs-" then
            String.compare t1 t2
          else
            -1
        else if String.equal (String.prefix t2 3) "bs-" then
          1
        else
          String.compare t1 t2)
  in
  let pp_name : string Fmt.t =
    let open Fmt in
    styled (`Fg `Blue) Fmt.string |> styled `Bold
  in
  Logs.app (fun m -> m "");
  List.iter sorted_templates ~f:(fun { name; description } ->
      Logs.app (fun m -> m "  %a" pp_name name);
      Logs.app (fun m -> m "    %s" description);
      Logs.app (fun m -> m ""))

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
  let open Common.Let_syntax in
  let+ _term = Common.term in
  run () |> Common.handle_errors

let cmd = term, info
