open React
open Lwt
open LTerm_text

module Interpreter = struct
  let eval ~impl:(module I : Impl.M) ?default_index ~options s =
    match s, default_index with
    | "", Some index ->
      Ok index
    | _ ->
      let index_opt =
        Option.bind (int_of_string_opt s) (fun c ->
            if c > 0 && c <= List.length options then Some c else None)
      in
      (match index_opt with
      | Some index ->
        Ok index
      | None ->
        Error
          (Printf.sprintf
             "Enter a number between 1 and %d"
             (List.length options)))
end

let make_prompt ?default ~impl:(module I : Impl.M) ~options message =
  let default_str =
    match Utils.index_of_default_opt ?default options with
    | None ->
      ""
    | Some v ->
      Printf.sprintf "[%d] " (v + 1)
  in
  let prompt = I.make_prompt message in
  let options_string =
    List.mapi options ~f:(fun i opt ->
        "  " ^ Int.to_string (i + 1) ^ ") " ^ opt ^ "\n")
    |> String.concat ~sep:""
  in
  Array.concat
    [ prompt
    ; LTerm_text.eval
        [ S "\n"; S options_string; S "  Answer: "; S default_str ]
    ]

class read_line ~term prompt =
  object (self)
    inherit LTerm_read_line.read_line ()

    inherit [Zed_string.t] LTerm_read_line.term term

    method! show_box = false

    initializer self#set_prompt (S.const prompt)
  end

let rec loop ~term ~impl:(module I : Impl.M) ?default ~options message =
  let prompt = make_prompt message ?default ~options ~impl:(module I) in
  let rl = new read_line prompt ~term in
  rl#run >>= fun command ->
  let command_utf8 = Zed_string.to_utf8 command in
  let default_index =
    Utils.index_of_default_opt ?default options |> Option.map (( + ) 1)
  in
  match
    Interpreter.eval command_utf8 ~options ?default_index ~impl:(module I)
  with
  | Error e ->
    let error_str = I.make_error e in
    LTerm.fprintls term error_str >>= fun () ->
    loop message ?default ~options ~term ~impl:(module I)
  | Ok v ->
    Lwt.return (List.nth options (v - 1))

let prompt ~impl:(module I : Impl.M) ?default ~options message =
  LTerm_inputrc.load () >>= fun () ->
  Lazy.force LTerm.stdout >>= fun term ->
  loop message ?default ~options ~term ~impl:(module I)
