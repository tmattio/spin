(*
 * lTerm_vi.mli
 * ------------
 * Copyright : (c) 2020, ZAN DoYe <zandoye@gmail.com>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)


module Concurrent :
  sig
    module Thread :
      sig
        type 'a t = 'a Lwt.t
        val bind : 'a t -> ('a -> 'b t) -> 'b t
        val return : 'a -> 'a t
        val both : 'a t -> 'b t -> ('a * 'b) t
        val join : unit t list -> unit t
        val pick : 'a t list -> 'a t
        val choose : 'a t list -> 'a t
        val async : (unit -> unit t) -> unit
        val cancel : 'a t -> unit
        val sleep : float -> unit t
        val run : 'a t -> 'a
      end
    module MsgBox :
      sig
        type 'a t = 'a Lwt_mvar.t
        val create : unit -> 'a t
        val put : 'a t -> 'a -> unit Lwt.t
        val get : 'a t -> 'a Lwt.t
      end
  end

module Query :
  sig
    val left : int -> 'a Zed_edit.context -> int * int
    val right : ?newline:bool -> int -> 'a Zed_edit.context -> int * int
    val line_FirstChar : 'a -> 'b Zed_edit.context -> int * int
    val line_LastChar : ?newline:bool -> int -> 'a Zed_edit.context -> int
    val get_category :
      ?nl_as_sp:bool ->
      Uchar.t ->
      Uucp.Gc.t
    val get_boundary : bool -> 'a Zed_edit.context -> int * int
    val is_space : [> `Cc | `Mn | `Zl | `Zp | `Zs ] -> bool
    val is_not_space : [> `Cc | `Mn | `Zl | `Zp | `Zs ] -> bool
    val category_equal : ([> `Ll | `Lu ] as 'a) -> 'a -> bool
    val category_equal_blank :
      [> `Cc | `Mn | `Zl | `Zp | `Zs ] ->
      [> `Cc | `Mn | `Zl | `Zp | `Zs ] -> bool
    val next_category :
      ?nl_as_sp:bool ->
      ?is_equal:(Uucp.Gc.t -> Uucp.Gc.t -> bool) ->
      pos:int -> stop:int -> Zed_rope.t -> int
    val prev_category :
      ?nl_as_sp:bool ->
      ?is_equal:(Uucp.Gc.t -> Uucp.Gc.t -> bool) ->
      pos:int -> start:int -> Zed_rope.t -> int
    val next_word' :
      ?multi_line:bool ->
      next_category:(nl_as_sp:bool -> pos:int -> stop:int -> Zed_rope.t -> int) ->
      pos:int -> stop:int -> Zed_rope.t -> int
    val next_word :
      ?multi_line:bool -> pos:int -> stop:int -> Zed_rope.t -> int
    val next_WORD :
      ?multi_line:bool -> pos:int -> stop:int -> Zed_rope.t -> int
    val line_FirstNonBlank : 'a -> 'b Zed_edit.context -> int
    val prev_word' :
      ?multi_line:bool ->
      prev_category:(nl_as_sp:bool -> pos:int -> start:int -> Zed_rope.t -> int) ->
      pos:int -> start:int -> Zed_rope.t -> int
    val prev_word :
      ?multi_line:bool -> pos:int -> start:int -> Zed_rope.t -> int
    val prev_WORD :
      ?multi_line:bool -> pos:int -> start:int -> Zed_rope.t -> int
    val next_word_end' :
      ?multi_line:bool ->
      next_category:(nl_as_sp:bool -> pos:int -> stop:int -> Zed_rope.t -> int) ->
      pos:int -> stop:int -> Zed_rope.t -> int
    val next_word_end :
      ?multi_line:bool -> pos:int -> stop:int -> Zed_rope.t -> int
    val next_WORD_end :
      ?multi_line:bool -> pos:int -> stop:int -> Zed_rope.t -> int
    val prev_word_end' :
      ?multi_line:bool ->
      prev_category:(nl_as_sp:bool -> pos:int -> start:int -> Zed_rope.t -> int) ->
      pos:int -> start:int -> Zed_rope.t -> int
    val prev_word_end :
      ?multi_line:bool -> pos:int -> start:int -> Zed_rope.t -> int
    val prev_WORD_end :
      ?multi_line:bool -> pos:int -> start:int -> Zed_rope.t -> int
    val occurrence_char :
      pos:int -> stop:int -> Zed_char.t -> Zed_rope.t -> int option
    val occurrence_char_back :
      pos:int -> start:int -> Zed_char.t -> Zed_rope.t -> int option
    val occurrence :
      pos:int ->
      stop:int ->
      cmp:(Zed_char.t -> bool) -> Zed_rope.t -> (int * Zed_char.t) option
    val occurrence_back :
      pos:int ->
      start:int ->
      cmp:(Zed_char.t -> bool) -> Zed_rope.t -> (int * Zed_char.t) option
    val occurrence_pare_raw :
      pos:int ->
      level:int ->
      start:int ->
      stop:int -> Zed_char.t * Zed_char.t -> Zed_rope.t -> (int * int) option
    val occurrence_pare :
      pos:int ->
      level:int ->
      start:int ->
      stop:int -> Zed_char.t * Zed_char.t -> Zed_rope.t -> (int * int) option
    val item_match : start:int -> stop:int -> int -> Zed_rope.t -> int option
    val include_word' :
      ?multi_line:bool ->
      next_category:(nl_as_sp:bool -> pos:int -> stop:int -> Zed_rope.t -> int) ->
      pos:int -> stop:int -> Zed_rope.t -> (int * int) option
    val include_word :
      ?multi_line:bool ->
      pos:int -> stop:int -> Zed_rope.t -> (int * int) option
    val include_WORD :
      ?multi_line:bool ->
      pos:int -> stop:int -> Zed_rope.t -> (int * int) option
    val inner_word' :
      ?multi_line:bool ->
      prev_category:(nl_as_sp:bool -> pos:int -> start:int -> Zed_rope.t -> int) ->
      next_category:(nl_as_sp:bool -> pos:int -> stop:'a -> Zed_rope.t -> int) ->
      pos:int -> stop:'a -> Zed_rope.t -> (int * int) option
    val inner_word :
      ?multi_line:bool ->
      pos:int -> stop:int -> Zed_rope.t -> (int * int) option
    val inner_WORD :
      ?multi_line:bool ->
      pos:int -> stop:int -> Zed_rope.t -> (int * int) option
  end

module Vi :
  sig
    module Edit_action = Mew_vi.Edit_action
    module Vi_action = Mew_vi.Vi_action
    module Base :
      sig
        module Key :
          sig
            type t = Mew_vi.Modal.Key.t
            type code = Mew_vi.Modal.Key.code
            type modifier = Mew_vi.Modal.Key.modifier
            type modifiers = Mew_vi.Modal.Key.modifiers
            val create : code:code -> modifiers:modifiers -> t
            val create_modifiers : modifier list -> modifiers
            val code : t -> code
            val modifiers : t -> modifiers
            val modifier : key:t -> modifier:modifier -> bool
            val compare : t -> t -> int
            val to_string : t -> string
            val equal : t -> t -> bool
            val hash : t -> int
          end
        module Mode :
          sig
            module KeyTrie : Trie.Intf with type path = Key.t list
            type name = Mew_vi.Modal.Name.t
            type action =
              |  Switch of name
              | Key of Key.t
              | KeySeq of Key.t Queue.t
              | Custom of (unit -> unit)
            type t = {
              name : name;
              timeout : float option;
              bindings : action KeyTrie.node;
            }
            module Modes : Map.S with type key= name
            type modes = t Modes.t
            val name : t -> name
            val timeout : t -> float option
            val bindings : t -> action KeyTrie.node
            val compare : t -> t -> int
            val default_mode : 'a Modes.t -> name * 'a
            val bind : t -> KeyTrie.path -> action -> unit
            val unbind : t -> KeyTrie.path -> unit
          end
        val ( >>= ) : 'a Lwt.t -> ('a -> 'b Lwt.t) -> 'b Lwt.t
        class edit :
          < default_mode : 'a * Mode.t; modes : Mode.t Mode.Modes.t;
            timeout : float; .. > ->
          object
            val mutable curr_mode : Mode.t
            val i : Key.t Lwt_mvar.t
            val o : Key.t Lwt_mvar.t
            method bindings : Mode.action Mode.KeyTrie.node
            method getMode : Mode.t
            method i : Key.t Lwt_mvar.t
            method keyin : Key.t -> unit Lwt.t
            method o : Key.t Lwt_mvar.t
            method setMode : Mode.name -> unit
            method timeout : float
          end
        class state :
          Mode.t Mew_vi.Modal.Mode.Modes.t ->
          object
            val mutable default_mode : Mew_vi.Modal.Mode.Modes.key * Mode.t
            val mutable timeout : float
            method default_mode : Mew_vi.Modal.Mode.Modes.key * Mode.t
            method edit : edit
            method modes : Mode.t Mode.Modes.t
            method timeout : float
          end
      end
    module Interpret :
      sig
        val ( >>= ) : 'a Lwt.t -> ('a -> 'b Lwt.t) -> 'b Lwt.t
        type keyseq = Base.Key.t list
        module Resolver :
          sig
            type t = status -> keyseq -> result
            and result =
                Accept of (Edit_action.t * keyseq * Mew_vi.Mode.Name.t)
              | Continue of (t * keyseq)
              | Rejected of keyseq
            and status = {
              mode : Mew_vi.Mode.Name.t React.signal;
              set_mode : ?step:React.step -> Mew_vi.Mode.Name.t -> unit;
              keyseq : keyseq React.signal;
              set_keyseq : ?step:React.step -> keyseq -> unit;
              mutable resolver_insert : t;
              mutable resolver_normal : t;
              mutable resolver_command : t;
            }
            val resolver_dummy : 'a -> keyseq -> result
            val resolver_insert : status -> Mew_vi.Key.t list -> result
            module Normal :
              sig
                val try_count :
                  (int option -> 'a -> keyseq -> result) ->
                  'a -> keyseq -> result
                val try_motion : int option -> 'a -> keyseq -> result
                val try_change_mode : status -> keyseq -> result
                val try_modify : int option -> 'a -> keyseq -> result
                val try_insert : int option -> 'a -> keyseq -> result
                val try_motion_modify_insert :
                  int option -> 'a -> keyseq -> result
                val resolver_normal : status -> keyseq -> result
              end
            val make_status :
              ?mode:Mew_vi.Mode.Name.t ->
              ?keyseq:keyseq ->
              ?resolver_insert:t ->
              ?resolver_normal:t -> ?resolver_command:t -> unit -> status
            val interpret :
              ?resolver:t ->
              ?keyseq:keyseq ->
              status ->
              Base.Key.t Lwt_mvar.t ->
              Edit_action.t Lwt_mvar.t -> unit -> 'a Lwt.t
          end
      end
  end

class edit :
  < default_mode : 'a * Vi.Base.Mode.t; modes : Vi.Base.Mode.t Vi.Base.Mode.Modes.t;
    timeout : float; .. > ->
  object
    val action_output : Vi.Edit_action.t Lwt_mvar.t
    val mutable curr_mode : Vi.Base.Mode.t
    val i : Mew_vi.Key.t Lwt_mvar.t
    val o : Mew_vi.Key.t Lwt_mvar.t
    val status : Vi.Interpret.Resolver.status
    method action_output : Vi.Edit_action.t Lwt_mvar.t
    method bindings : Vi.Base.Mode.action Vi.Base.Mode.KeyTrie.node
    method getMode : Vi.Base.Mode.t
    method i : Mew_vi.Key.t Lwt_mvar.t
    method keyin : Mew_vi.Key.t -> unit Lwt.t
    method o : Mew_vi.Key.t Lwt_mvar.t
    method setMode : Vi.Base.Mode.name -> unit
    method timeout : float
  end
class state :
  object
    val mutable default_mode : Vi.Base.Mode.name * Vi.Base.Mode.t
    val mutable timeout : float
    method default_mode : Vi.Base.Mode.name * Vi.Base.Mode.t
    method edit : Vi.Base.edit
    method modes : Vi.Base.Mode.t Vi.Base.Mode.Modes.t
    method timeout : float
    method vi_edit : edit
  end

val of_lterm_code : LTerm_key.code -> Mew_vi.Key.code
val of_vi_code : Mew_vi.Key.code -> LTerm_key.code
val of_lterm_key : LTerm_key.t -> Mew_vi.Key.t
val of_vi_key : Mew_vi.Key.t -> LTerm_key.t

open LTerm_read_line_base

val perform :
  'a Zed_edit.context ->
  (action list -> 'b loop_result Lwt.t) ->
  Vi.Vi_action.t -> 'b loop_result Lwt.t

