let write fn s =
  let oc = open_out fn in
  output_string oc s;
  close_out oc

let () =
  let ic = open_in "ocamlc-config" in
  let rec loop acc =
    match input_line ic with
    | exception End_of_file -> close_in ic; acc
    | line ->
      loop (Scanf.sscanf line "%[^:]: %s" (fun a b -> (a, b)) :: acc)
  in
  let config = loop [] in
  let system = List.assoc "system" config in
  Printf.ksprintf (write "lTerm_config.h") "\
#ifndef __LTERM_CONFIG_H
#define __LTERM_CONFIG_H

#define SYS_%s

#endif /* __LTERM_CONFIG_H */
" system;
  if system = "openbsd" then begin
    write "c_flags"         "(-I/usr/local/include)";
    write "c_library_flags" "(-L/usr/local/lib -lcharset)"
  end else begin
    write "c_flags"         "()";
    write "c_library_flags" "()"
  end

