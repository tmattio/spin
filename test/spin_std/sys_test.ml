open Alcotest

let test_ls_dir () =
  let temp_dir = Spin_std.Sys.mk_temp_dir "spin-test" in
  let temp_file = Filename.concat temp_dir "file" in
  let oc = open_out temp_file in
  Printf.fprintf oc "%s" "Hello world!";
  close_out oc;
  let f_list = Spin_std.Sys.ls_dir (Filename.dirname temp_file) in
  check (list string) "equals" f_list [ temp_file ]

let test_read_write_file () =
  let temp_dir = Spin_std.Sys.mk_temp_dir "spin-test" in
  let temp_file = Filename.concat temp_dir "file" in
  let contents = "Hello world!\n" in
  Spin_std.Sys.write_file temp_file contents;
  let read_contents = Spin_std.Sys.read_file temp_file in
  check string "equals" contents read_contents

let suite =
  [ "ls_dir returns the files in the directory", `Quick, test_ls_dir
  ; ( "write_file/read_file preserves newlines at end of file"
    , `Quick
    , test_read_write_file )
  ]
