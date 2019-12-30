open Spin;

let get_tempdir = prefix => {
  Printf.sprintf(
    "spin-test-%s-%s",
    prefix,
    Unix.time() |> Float.to_int |> Int.to_string,
  )
  |> Utils.Filename.concat(Caml.Filename.get_temp_dir_name());
};
