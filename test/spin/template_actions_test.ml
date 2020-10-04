open Alcotest
open Spin

let spin_error = Alcotest.of_pp Spin_error.pp

let test_refmt () =
  let temp_dir = Test_utils.get_tempdir "test_refmt" in
  Spin_unix.mkdir_p temp_dir;
  let temp_file = Caml.Filename.concat temp_dir "sample.ml" in
  Stdio.Out_channel.write_all
    temp_file
    ~data:{|let () = print_endline "Hello World"|};
  let result_ =
    Template_actions.run
      Template_actions.
        { message = None; actions = [ Template_actions.Refmt [ "*.ml" ] ] }
      ~path:(Filename.dirname temp_file)
    |> Lwt_main.run
  in
  check (result unit spin_error) "" result_ (Ok ());
  let output_file = Caml.Filename.chop_suffix temp_file ".ml" ^ ".re" in
  let content = Stdio.In_channel.read_all output_file in
  check string "equals" "let () = print_endline(\"Hello World\");" content

let suite = [ "can run a Refmt action", `Quick, test_refmt ]
