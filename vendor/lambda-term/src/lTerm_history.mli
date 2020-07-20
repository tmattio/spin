(*
 * lTerm_history.mli
 * -----------------
 * Copyright : (c) 2012, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

(** History management *)

type t
  (** Type of a history. *)

val create : ?max_size : int -> ?max_entries : int -> Zed_string.t list -> t
  (** [create ?max_size ?max_lines init] creates a new history.

      [max_size] is the maximum size in bytes of the history. Oldest
      entries are dropped if this limit is reached. The default is
      [max_int].

      [max_entries] is the maximum number of entries of the
      history. Oldest entries are dropped if this limit is
      reached. The default is no [max_int].

      [init] is the initial contents of the history. All entries of
      [init] are considered "old". Old entries are not saved by
      {!save} when [append] is set to [true].

      Note: the first element of [init] must be the most recent
      entry. *)

val add : t -> ?skip_empty : bool -> ?skip_dup : bool -> Zed_string.t -> unit
  (** [add history ?skip_empty ?skip_dup entry] adds [entry] to the
      top of the history. If [skip_empty] is [true] (the default) and
      [entry] contains only spaces, it is not added. If [skip_dup] is
      [true] (the default) and [entry] is equal to the top of the
      history, it is not added.

      If [entry] is bigger than the maximum size of the history, the
      history is not modified. *)

val contents : t -> Zed_string.t list
  (** Returns all the entries of the history. The first element of the
      list is the most recent entry. *)

val size : t -> int
  (** Returns the size (in bytes) of the history. *)

val length : t -> int
  (** Returns the number of entries in the history. *)

val old_count : t -> int
  (** Returns the number of old entries in the history. *)

val set_old_count : t -> int -> unit
  (** [set_old_count history count] sets the number of old entries in
      the history. *)

val max_size : t -> int
  (** Returns the maximum size of the history. *)

val set_max_size : t -> int -> unit
  (** Sets the maximum size of the history. It may drop oldest entries
      to honor the new limit. *)

val max_entries : t -> int
  (** Returns the maximum number of entries of the history. *)

val set_max_entries : t -> int -> unit
  (** Sets the maximum number of entries of the history. It may drop
      oldest entries to honor the new limit. *)

val load : t ->
  ?log : (int -> string -> unit) ->
  ?skip_empty : bool ->
  ?skip_dup : bool ->
  string -> unit Lwt.t
  (** [load history ?log ?skip_empty ?skip_dup filename] loads entries
      from [filename] to [history]. If [filename] does not exists
      [history] is not modified.

      [log] is the function used to log errors contained in the
      history file (errors are because of non-UTF8 data). Arguments
      are a line number and an error message. The default is to use
      the default logger (of [Lwt_log]). Entries containing errors are
      skipped.

      Note: all entries are marked as old, i.e. [old_count history =
      length history]. *)

val save : t ->
  ?max_size : int ->
  ?max_entries : int ->
  ?skip_empty : bool ->
  ?skip_dup : bool ->
  ?append : bool ->
  ?perm : int ->
  string -> unit Lwt.t
  (** [save history ?max_size ?max_entries ?skip_empty ?sjip_dup ?perm
      filename] saves [history] to [filename].

      If [append] is [false] then the file is truncated and new
      entries are saved. If it is [true] (the default) then new
      entries are added at the end. [perm] are the file permissions in
      case it is created.

      If [append] is [true] and there is no new entries, the file is
      not touched. In any other case, limits are honored and the
      resulting file will never contains more bytes than [max_size] or
      more entries than [max_entries]. If [max_size] and/or
      [max_entries] are not specified, the ones of [history] are used.

      After the history is successfully saved, all entries of
      [history] are marked as old, i.e. [old_count history = length
      history]. *)

val entry_size : Zed_string.t -> int
  (** [entry_size entry] returns the size taken by an entry in the
      history file in bytes. This is not exactly [String.length entry]
      since some characters are escaped and the entry is terminated by
      a newline character. *)
