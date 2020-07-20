(*
 * lTerm_resource_lexer.mll
 * ------------------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

let blank = [' ' '\t']
let eol = ('\n' | eof)

rule line = parse
  | eof
      { `EOF }
  | blank* ('!' [^'\n']* eol | eol)
      { `Empty }
  | blank* ([^' ' '\t' '\n']+ as key) blank* ':' blank* ([^' ' '\t' '\n']* as value) blank* eol
      { `Assoc(key, value) }
  | [^':' '\n']+ eol
      { `Error("':' missing") }
  | blank* ':' [^'\n']* eol
      { `Error("key missing") }
  | [^'\n']* eol
      { `Error("unknown error") }
