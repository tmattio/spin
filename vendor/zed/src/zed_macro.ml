(*
 * zed_macro.ml
 * ------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Zed, an editor engine.
 *)

open React

type 'a t = {
  recording : bool signal;
  set_recording : bool -> unit;
  mutable tmp_macro : 'a list;
  mutable macro : 'a list;
  count : int signal;
  set_count : int -> unit;
  counter : int signal;
  set_counter : int -> unit;
}

let create macro =
  let recording, set_recording = S.create false in
  let count, set_count = S.create 0 in
  let counter, set_counter = S.create 0 in
  {
    recording;
    set_recording;
    macro;
    tmp_macro = [];
    count;
    set_count;
    counter;
    set_counter;
  }

let recording r = r.recording

let get_recording r = S.value r.recording

let set_recording r state =
  match state with
    | true ->
        r.tmp_macro <- [];
        r.set_recording true;
        r.set_count 0;
        r.set_counter 0
    | false ->
        if S.value r.recording then begin
          r.macro <- List.rev r.tmp_macro;
          r.tmp_macro <- [];
          r.set_recording false;
          r.set_count 0
        end

let cancel r =
  if S.value r.recording then begin
    r.tmp_macro <- [];
    r.set_recording false;
    r.set_count 0
  end

let count r = r.count
let get_count r = S.value r.count

let counter r = r.counter
let get_counter r = S.value r.counter
let set_counter r v = r.set_counter v
let add_counter r v = r.set_counter (S.value r.counter + v)

let add r x =
  if S.value r.recording then begin
    r.tmp_macro <- x :: r.tmp_macro;
    r.set_count (S.value r.count + 1)
  end

let contents r = r.macro
