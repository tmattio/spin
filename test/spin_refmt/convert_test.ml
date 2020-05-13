open Alcotest
open Spin_refmt

let test_convert () =
  let temp_file = Caml.Filename.temp_file "spin_test_convert" ".ml" in
  Stdio.Out_channel.write_all
    temp_file
    ~data:{|let () = print_endline "Hello World"|};
  convert temp_file;
  let output_file = Caml.Filename.chop_suffix temp_file ".ml" ^ ".re" in
  let content = Stdio.In_channel.read_all output_file in
  check string "equals" content "let () = print_endline(\"Hello World\");\n"

let suite = [ "can convert an ML file to a Reason file", `Quick, test_convert ]
