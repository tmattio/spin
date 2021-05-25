open Cmdliner

let cmds = [ Cmd_hello.cmd ]

(* Command line interface *)

let doc = "{{ project_description }}"

let sdocs = Manpage.s_common_options

let exits = Common.exits

let envs = Common.envs

let man =
  [ `S Manpage.s_description
  ; `P "{{ project_description }}"
  ; `S Manpage.s_commands
  ; `S Manpage.s_common_options
  ; `S Manpage.s_exit_status
  ; `P "These environment variables affect the execution of $(mname):"
  ; `S Manpage.s_environment
  ; `S Manpage.s_bugs
  ; `P "File bug reports at $(i,%%{% raw %}PKG_ISSUE{% endraw %}S%%)"
  ; `S Manpage.s_authors
  ; `P "{{ username }}, $(i,https://github.com/{{ github_username }})"
  ]

let default_cmd =
  let term =
    let open Common.Syntax in
    Term.ret
    @@ let+ _ = Common.term in
       `Help (`Pager, None)
  in
  let info = Term.info "{{ project_slug }}" ~version:"%%{% raw %}VERSION{% endraw %}%%" ~doc ~sdocs ~exits ~man ~envs in
  term, info

let () = Term.(exit_status @@ eval_choice default_cmd cmds)
