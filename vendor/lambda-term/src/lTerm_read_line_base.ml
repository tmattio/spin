(*
 * lTerm_read_line_base.ml
 * ------------
 * Copyright : (c) 2020, ZAN DoYe <zandoye@gmail.com>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)


(* +-----------------------------------------------------------------+
   | Actions                                                         |
   +-----------------------------------------------------------------+ *)

let pervasives_compare= compare

exception Interrupt

type action =
  | Edit of LTerm_edit.action
  | Interrupt_or_delete_next_char
  | Complete
  | Complete_bar_next
  | Complete_bar_prev
  | Complete_bar_first
  | Complete_bar_last
  | Complete_bar
  | History_prev
  | History_next
  | History_search_prev
  | History_search_next
  | Accept
  | Clear_screen
  | Prev_search
  | Next_search
  | Cancel_search
  | Break
  | Suspend
  | Edit_with_external_editor

let doc_of_action = function
  | Edit action -> LTerm_edit.doc_of_action action
  | Interrupt_or_delete_next_char -> "interrupt if at the beginning of an empty line, or delete the next character."
  | Complete -> "complete current input."
  | Complete_bar_next -> "go to the next possible completion in the completion bar."
  | Complete_bar_prev -> "go to the previous possible completion in the completion bar."
  | Complete_bar_first -> "go to the beginning of the completion bar."
  | Complete_bar_last -> "go to the end of the completion bar."
  | Complete_bar -> "complete current input using the completion bar."
  | History_prev -> "go to the previous entry of the history."
  | History_next -> "go to the next entry of the history."
  | History_search_prev -> "go to the previous entry of the history that matches the start of the current line."
  | History_search_next -> "go to the next entry of the history that matches the start of the current line."
  | Accept -> "accept the current input."
  | Clear_screen -> "clear the screen."
  | Prev_search -> "search backward in the history."
  | Next_search -> "search forward in the history."
  | Cancel_search -> "cancel search mode."
  | Break -> "cancel edition."
  | Suspend -> "suspend edition."
  | Edit_with_external_editor -> "edit input with external editor command."

let actions = [
  Interrupt_or_delete_next_char, "interrupt-or-delete-next-char";
  Complete, "complete";
  Complete_bar_next, "complete-bar-next";
  Complete_bar_prev, "complete-bar-prev";
  Complete_bar_first, "complete-bar-first";
  Complete_bar_last, "complete-bar-last";
  Complete_bar, "complete-bar";
  History_prev, "history-prev";
  History_next, "history-next";
  History_search_prev, "history-search-prev";
  History_search_next, "history-search-next";
  Accept, "accept";
  Clear_screen, "clear-screen";
  Prev_search, "prev-search";
  Next_search, "next-search";
  Cancel_search, "cancel-search";
  Break, "break";
  Suspend, "suspend";
  Edit_with_external_editor, "edit-with-external-editor";
]

let actions_to_names = Array.of_list (List.sort (fun (a1, _) (a2, _) -> pervasives_compare a1 a2) actions)
let names_to_actions = Array.of_list (List.sort (fun (_, n1) (_, n2) -> pervasives_compare n1 n2) actions)

let action_of_name x =
  let rec loop a b =
    if a = b then
      Edit (LTerm_edit.action_of_name x)
    else
      let c = (a + b) / 2 in
      let action, name = Array.unsafe_get names_to_actions c in
      match pervasives_compare x name with
        | d when d < 0 ->
            loop a c
        | d when d > 0 ->
            loop (c + 1) b
        | _ ->
            action
  in
  loop 0 (Array.length names_to_actions)

let name_of_action x =
  let rec loop a b =
    if a = b then
      raise Not_found
    else
      let c = (a + b) / 2 in
      let action, name = Array.unsafe_get actions_to_names c in
      match pervasives_compare x action with
        | d when d < 0 ->
            loop a c
        | d when d > 0 ->
            loop (c + 1) b
        | _ ->
            name
  in
  match x with
    | Edit x -> LTerm_edit.name_of_action x
    | _ -> loop 0 (Array.length actions_to_names)


(* +-----------------------------------------------------------------+
   | Event loop                                                      |
   +-----------------------------------------------------------------+ *)

type 'a loop_result=
  | Result of 'a
  | ContinueLoop of LTerm_key.t list

type 'a loop_status=
  | Ev of LTerm_event.t
  | Loop_result of 'a
  | Interrupted of exn

