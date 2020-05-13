open Alcotest
open Spin_std

let test_ls_dir () =
  let temp_dir = Spin_sys.mk_temp_dir "spin-test" in
  let temp_file = Filename.concat temp_dir "file" in
  Stdio.Out_channel.write_all temp_file ~data:"";
  let f_list = Spin_sys.ls_dir (Caml.Filename.dirname temp_file) in
  check (list string) "equals" f_list [ temp_file ]

let suite = [ "ls_dir returns the files in the directory", `Quick, test_ls_dir ]
