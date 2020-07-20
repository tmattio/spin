(*
 * lTerm_history.ml
 * ----------------
 * Copyright : (c) 2012, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

let return, (>>=) = Lwt.return, Lwt.(>>=)

(* A node contains an entry of the history. *)
type node = {
  mutable data : Zed_string.t;
  mutable size : int;
  mutable prev : node;
}

type t = {
  mutable entries : node;
  (* Points to the first entry (the most recent). Its [prev] is a fake
     node used as marker, is after the oldest entry. *)
  mutable full_size : int;
  mutable length : int;
  mutable max_size : int;
  mutable max_entries : int;
  mutable old_count : int;
  mutable cache : Zed_string.t list option;
  (* When set, the cache is equal to the list of entries, from the
     most recent to the oldest. *)
}

let entry_size str =
  let zChar_newline= Zed_char.unsafe_of_char '\n'
  and zChar_slash= Zed_char.unsafe_of_char '\\' in
  let size = ref 0 in
  let eos= Zed_string.bytes str in
  let rec calc ofs=
    if ofs < eos then
      let ch, ofs= Zed_string.extract_next str ofs in
      if Zed_char.compare ch zChar_newline = 0 || Zed_char.compare ch zChar_slash = 0 then
        size := !size + 2
      else
        size := !size + 1;
      calc ofs
  in
  calc 0;
  !size + 1

(* Check that [size1 + size2 < limit], handling overflow. *)
let size_ok size1 size2 limit =
  let sum = size1 + size2 in
  sum >= 0 && sum <= limit

let create ?(max_size=max_int) ?(max_entries=max_int) init =
  if max_size < 0 then
    invalid_arg "LTerm_history.create: negative maximum size";
  if max_entries < 0 then
    invalid_arg "LTerm_history.create: negative maximum number of entries";
  let rec aux size count node entries =
    match entries with
      | [] ->
          (size, count, node)
      | entry :: entries ->
          let entry_size = entry_size entry in
          if size_ok size entry_size max_size && count + 1 < max_entries then begin
            let next = { data = Zed_string.empty (); prev = node; size = 0 } in
            node.data <- entry;
            node.size <- entry_size;
            aux (size + entry_size) (count + 1) next entries
          end else
            (size, count, node)
  in
  let rec node = { data = Zed_string.empty (); size = 0; prev = node } in
  let size, count, marker = aux 0 0 node init in
  node.prev <- marker;
  {
    entries = node;
    full_size = size;
    length = count;
    max_size = max_size;
    max_entries = max_entries;
    old_count = count;
    cache = None;
  }

let is_space_uChar ch = Uucp.White.is_white_space ch
let is_space ch = Zed_char.for_all is_space_uChar ch
let is_empty str = Zed_string.for_all is_space str

let is_dup history entry =
  history.length > 0 && history.entries.data = entry

(* Remove the oldest entry of history, precondition: the history
   contains at least one entry. *)
let drop_oldest history =
  let last = history.entries.prev.prev in
  (* Make [last] become the end of entries marker. *)
  history.entries.prev <- last;
  (* Update counters. *)
  history.length <- history.length - 1;
  history.full_size <- history.full_size - last.size;
  if history.old_count > 0 then history.old_count <- history.old_count - 1;
  (* Clear the marker so its contents can be garbage collected. *)
  last.data <- Zed_string.empty ();
  last.size <- 0

let add_aux history data size =
  if size <= history.max_size then begin
    (* Check length. *)
    if history.length = history.max_entries then begin
      history.cache <- None;
      (* We know that [max_entries > 0], so the precondition is
         verified. *)
      drop_oldest history
    end;
    (* Check size. *)
    if not (size_ok history.full_size size history.max_size) then begin
      history.cache <- None;
      (* We know that size <= max_size, so we are here only if there
         is at least one other entry in the history, so the
         precondition is verified. *)
      drop_oldest history;
      while not (size_ok history.full_size size history.max_size) do
        (* Same here. *)
        drop_oldest history
      done
    end;
    (* Add the entry. *)
    let node = { data = data; size = size; prev = history.entries.prev } in
    history.entries.prev <- node;
    history.entries <- node;
    history.length <- history.length + 1;
    history.full_size <- history.full_size + size;
    match history.cache with
      | None ->
          ()
      | Some l ->
          history.cache <- Some (data :: l)
  end

let add history ?(skip_empty=true) ?(skip_dup=true) entry =
  if history.max_entries > 0 && history.max_size > 0 && not (skip_empty && is_empty entry) && not (skip_dup && is_dup history entry) then
    add_aux history entry (entry_size entry)

let rec list_of_nodes marker acc node =
  if node == marker then
    acc
  else
    list_of_nodes marker (node.data :: acc) node.prev

let contents history =
  match history.cache with
    | Some l ->
        l
    | None ->
        let marker = history.entries.prev in
        let l = list_of_nodes marker [] marker.prev in
        history.cache <- Some l;
        l

let size history = history.full_size
let length history = history.length
let old_count history = history.old_count
let max_size history = history.max_size
let max_entries history = history.max_entries

let set_old_count history n =
  if n < 0 then
    invalid_arg "LTerm_history.set_old_count: negative old count";
  if n > history.length then
    invalid_arg "LTerm_history.set_old_count: old count greater than the length of the history";
  history.old_count <- n

let set_max_size history size =
  if size < 0 then
    invalid_arg "LTerm_history.set_max_size: negative maximum size";
  if size < history.full_size then begin
    history.cache <- None;
    (* 0 <= size < full_size so there is at least one element. *)
    drop_oldest history;
    while size < history.full_size do
      (* Same here. *)
      drop_oldest history
    done
  end;
  history.max_size <- size

let set_max_entries history n =
  if n < 0 then
    invalid_arg "LTerm_history.set_max_entries: negative maximum number of entries";
  if n < history.length then begin
    history.cache <- None;
    (* 0 <= n < length so there is at least one element. *)
    drop_oldest history;
    while n < history.length do
      (* Same here. *)
      drop_oldest history
    done
  end;
  history.max_entries <- n

(*let escape_utf8 entry =
  let len = String.length entry in
  let buf = Buffer.create len in
  let rec loop ofs =
    if ofs = len then
      Buffer.contents buf
    else
      match String.unsafe_get entry ofs with
        | '\n' ->
            Buffer.add_string buf "\\n";
            loop (ofs + 1)
        | '\\' ->
            Buffer.add_string buf "\\\\";
            loop (ofs + 1)
        | ch when Char.code ch <= 127 ->
            Buffer.add_char buf ch;
            loop (ofs + 1)
        | _ ->
            let ofs' = Zed_utf8.unsafe_next entry ofs in
            Buffer.add_substring buf entry ofs (ofs' - ofs);
            loop ofs'
  in
  loop 0*)

let escape entry =
  let len = Zed_string.bytes entry in
  let buf = Zed_string.Buf.create len in
  let zChar_n= Zed_char.unsafe_of_char 'n' in
  let zChar_slash= Zed_char.unsafe_of_char '\\' in
  let zChar_nl= Zed_char.unsafe_of_char '\n' in
  let rec loop ofs =
    if ofs = len then
      Zed_string.Buf.contents buf
    else
      let ch, ofs= Zed_string.extract_next entry ofs in
      if Zed_char.compare ch zChar_nl = 0 then
        begin
          Zed_string.Buf.add_zChar buf zChar_slash;
          Zed_string.Buf.add_zChar buf zChar_n;
          loop ofs;
        end
      else if Zed_char.compare ch zChar_slash = 0 then
        begin
          Zed_string.Buf.add_zChar buf zChar_slash;
          Zed_string.Buf.add_zChar buf zChar_slash;
          loop ofs;
        end
      else
        begin
          Zed_string.Buf.add_zChar buf ch;
          loop ofs;
        end
  in
  loop 0

(*let unescape_utf8 line =
  let len = String.length line in
  let buf = Buffer.create len in
  let rec loop ofs size =
    if ofs = len then
      (Buffer.contents buf, size + 1)
    else
      match String.unsafe_get line ofs with
        | '\\' ->
            if ofs = len then begin
              Buffer.add_char buf '\\';
              (Buffer.contents buf, size + 3)
            end else begin
              match String.unsafe_get line (ofs + 1) with
                | 'n' ->
                    Buffer.add_char buf '\n';
                    loop (ofs + 2) (size + 2)
                | '\\' ->
                    Buffer.add_char buf '\\';
                    loop (ofs + 2) (size + 2)
                | _ ->
                    Buffer.add_char buf '\\';
                    loop (ofs + 1) (size + 2)
            end
        | ch when Char.code ch <= 127 ->
            Buffer.add_char buf ch;
            loop (ofs + 1) (size + 1)
        | _ ->
            let ofs' = Zed_utf8.unsafe_next line ofs in
            Buffer.add_substring buf line ofs (ofs' - ofs);
            loop ofs' (size + ofs' - ofs)
  in
  loop 0 0*)

let unescape line =
  let eos= Zed_string.bytes line in
  let buf= Zed_string.Buf.create 0 in
  let zChar_n= Zed_char.unsafe_of_char 'n' in
  let zChar_slash= Zed_char.unsafe_of_char '\\' in
  let zChar_nl= Zed_char.unsafe_of_char '\n' in
  let rec loop ofs size =
    if ofs >= eos then
      (Zed_string.Buf.contents buf, size + 1)
    else
      let ch, ofs= Zed_string.extract_next line ofs in
      if Zed_char.compare ch zChar_slash = 0 then
        if ofs >= eos then
          (Zed_string.Buf.add_zChar buf zChar_slash;
          (Zed_string.Buf.contents buf, size + 3);)
        else
          (let next, ofs_next= Zed_string.extract_next line ofs in
          if Zed_char.compare next zChar_n = 0 then
            (Zed_string.Buf.add_zChar buf zChar_nl;
            loop ofs_next (size + 2);)
          else if Zed_char.compare next zChar_slash = 0 then
            (Zed_string.Buf.add_zChar buf zChar_slash;
            loop ofs_next (size + 2);)
          else
            (Zed_string.Buf.add_zChar buf zChar_slash;
            loop ofs (size + 2);))
      else
        (Zed_string.Buf.add_zChar buf ch;
        loop ofs (size + Zed_char.size ch);)
  in
  loop 0 0

let section = Lwt_log.Section.make "lambda-term(history)"

let rec safe_lockf fn fd cmd ofs =
  Lwt.catch (fun () ->
      Lwt_unix.lockf fd cmd ofs >>= fun () ->
      return true)
    (function
    | Unix.Unix_error (Unix.EINTR, _, _) ->
        safe_lockf fn fd cmd ofs
    | Unix.Unix_error (error, _, _) ->
        Lwt_log.ign_warning_f ~section "failed to lock file '%s': %s" fn (Unix.error_message error);
        return false
    | exn -> Lwt.fail exn)

let open_history fn =
  Lwt.catch (fun () ->
      Lwt_unix.openfile fn [Unix.O_RDWR] 0 >>= fun fd ->
      safe_lockf fn fd Lwt_unix.F_LOCK 0 >>= fun locked ->
      return (Some (fd, locked)))
    (function
    | Unix.Unix_error (Unix.ENOENT, _, _) ->
        return None
    | Unix.Unix_error (Unix.EACCES, _, _) ->
        Lwt_log.ign_info_f "cannot open file '%s' in read and write mode: %s" fn (Unix.error_message Unix.EACCES);
        (* If the file cannot be openned in read & write mode,
           open it in read only mode but do not lock it. *)
        Lwt.catch (fun () ->
            Lwt_unix.openfile fn [Unix.O_RDONLY] 0 >>= fun fd ->
            return (Some (fd, false)))
          (function
          | Unix.Unix_error (Unix.ENOENT, _, _) ->
              return None
          | exn -> Lwt.fail exn)
    | exn -> Lwt.fail exn)

let load history ?log ?(skip_empty=true) ?(skip_dup=true) fn =
  (* In case we do not load anything. *)
  history.old_count <- history.length;
  if history.max_entries = 0 || history.max_size = 0 then
    (* Do not bother loading the file for nothing... *)
    return ()
  else begin
    let log =
      match log with
        | Some func ->
            func
        | None ->
            fun line msg ->
              Lwt_log.ign_error_f ~section "File %S, at line %d: %s" fn line msg
    in
    (* File opening. *)
    open_history fn >>= fun history_file ->
    match history_file with
      | None ->
          return ()
      | Some (fd, locked) ->
          (* File loading. *)
          let ic = Lwt_io.of_fd ~mode:Lwt_io.input fd in
          Lwt.finalize (fun () ->
            let rec aux num =
              Lwt_io.read_line_opt ic >>= fun line ->
              match line with
                | None ->
                    return ()
                | Some line ->
                  (try
                    let line= Zed_string.of_utf8 line in
                       let entry, size = unescape line in
                       if not (skip_empty && is_empty entry) && not (skip_dup && is_dup history entry) then begin
                         add_aux history entry size;
                         history.old_count <- history.length
                       end
                    with
                      | Zed_string.Invalid (msg, _)-> log num msg
                      | Zed_utf8.Invalid (msg, _)-> log num msg
                   );
                    aux (num + 1)
            in
            aux 1)
            (fun () ->
              (* Cleanup. *)
              (if locked then safe_lockf fn fd Lwt_unix.F_ULOCK 0 else return true) >>= fun _ ->
              Lwt_unix.close fd)
  end

let rec skip_nodes node count =
  if count = 0 then
    node
  else
    skip_nodes node.prev (count - 1)

let rec copy history marker node skip_empty skip_dup =
  if node != marker then begin
    let line = escape node.data in
    if not (skip_empty && is_empty line) && not (skip_dup && is_dup history line) then
      add_aux history line node.size;
    copy history marker node.prev skip_empty skip_dup
  end

let rec dump_entries oc marker node =
  if node == marker then
    return ()
  else begin
    Lwt_io.write_line oc (Zed_string.to_utf8 node.data) >>= fun () ->
    dump_entries oc marker node.prev
  end

let save history ?max_size ?max_entries ?(skip_empty=true) ?(skip_dup=true) ?(append=true) ?(perm=0o666) fn =
  let max_size =
    match max_size with
      | Some m -> m
      | None -> history.max_size
  and max_entries =
    match max_entries with
      | Some m -> m
      | None -> history.max_entries
  in
  let history_save = create ~max_size ~max_entries [] in
  if history_save.max_size = 0 || history_save.max_entries = 0 || (not append && history.old_count = history.length) then
    (* Just empty the history. *)
    Lwt_unix.openfile fn [Unix.O_CREAT; Unix.O_TRUNC] perm >>= Lwt_unix.close
  else if append && history.old_count = history.length then
    (* Do not touch the file. *)
    return ()
  else begin
    Lwt_unix.openfile fn [Unix.O_CREAT; Unix.O_RDWR] perm >>= fun fd ->
    (* Lock the entire file. *)
    safe_lockf fn fd Unix.F_LOCK 0 >>= fun locked ->
    Lwt.finalize (fun () ->
      begin
        if append then begin
          (* Load existing entries into [history_save].

             We return the number of entries read. This may be greater
             than the number of entries stored in [history_save]:
             - because of limits
             - because the history files contains duplicated lines
               and/or empty lines and [skip_dup] and/or [skip_empty]
               have been specified. *)
          let ic = Lwt_io.of_fd ~mode:Lwt_io.input ~close:return fd in
          let rec aux count =
            Lwt_io.read_line_opt ic >>= fun line ->
            match line with
              | None ->
                  history_save.old_count <- history_save.length;
                  Lwt_io.close ic >>= fun () ->
                  return count
              | Some line ->
                  let line= Zed_string.unsafe_of_utf8 line in
                  (* Do not bother unescaping. Tests remain the same
                     on the unescaped version. *)
                  if not (skip_empty && is_empty line) && not (skip_dup && is_dup history_save line) then
                    add_aux history_save line (Zed_string.bytes line + 1);
                  aux (count + 1)
          in
          aux 0
        end else
          return 0
      end >>= fun count ->
      let marker = history.entries.prev in
      (* Copy new entries into the saving history. *)
      copy history_save marker (skip_nodes marker.prev history.old_count) skip_empty skip_dup;
      begin
        if append && history_save.old_count = count then
          (* We are in append mode and no old entries were removed: do
             not modify the file and append new entries at the end of
             the file. *)
          return count
        else
          (* Otherwise truncate the file and save everything. *)
          Lwt_unix.lseek fd 0 Unix.SEEK_SET >>= fun _ ->
          Lwt_unix.ftruncate fd 0 >>= fun () ->
          return 0
      end >>= fun to_skip ->
      (* Save entries to the temporary file. *)
      let oc = Lwt_io.of_fd ~mode:Lwt_io.output ~close:return fd in
      let marker = history_save.entries.prev in
      dump_entries oc marker (skip_nodes marker.prev to_skip) >>= fun () ->
      Lwt_io.close oc >>= fun () ->
      (* Done! *)
      history.old_count <- history.length;
      return ())
      (fun () ->
        (if locked then safe_lockf fn fd Lwt_unix.F_ULOCK 0 else return true) >>= fun _ ->
        Lwt_unix.close fd)
  end
