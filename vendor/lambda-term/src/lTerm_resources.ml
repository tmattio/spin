
(*
 * lTerm_resources.ml
 * ------------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

(* little hack to maintain 4.02.3 compat with warnings *)
module String = struct
  [@@@ocaml.warning "-3-32"]
  let lowercase_ascii =  StringLabels.lowercase
  include String
end

let (>>=) = Lwt.(>>=)

let home =
  try
    Sys.getenv "HOME"
  with Not_found ->
    try
      (Unix.getpwuid (Unix.getuid ())).Unix.pw_dir
    with Unix.Unix_error _ | Not_found ->
      if Sys.win32 then
        try
          Sys.getenv "AppData"
        with Not_found ->
          ""
      else
        ""

type xdg_location = Cache | Config | Data

module XDGBD = struct
  let ( / ) = Filename.concat

  let get env_var unix_default win32_default =
    try
      Sys.getenv env_var
    with Not_found ->
      if Sys.win32 then win32_default else unix_default

  let cache  = get "XDG_CACHE_HOME"  (home / ".cache")           (home / "Local Settings" / "Cache")
  let config = get "XDG_CONFIG_HOME" (home / ".config")          (home / "Local Settings")
  let data   = get "XDG_DATA_HOME"   (home / ".local" / "share") (try Sys.getenv "AppData" with Not_found -> "")

  let user_dir = function
    | Cache  -> cache
    | Config -> config
    | Data   -> data
end

let xdgbd_warning loc file_name =
  let loc_name = match loc with
    | Cache  -> "$XDG_CACHE_HOME"
    | Config -> "$XDG_CONFIG_HOME"
    | Data   -> "$XDG_DATA_HOME" in
  Printf.eprintf
    "Warning: it is recommended to move `%s` to `%s`, see:\n%s\n"
    file_name loc_name
    "http://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html"

let xdgbd_file ~loc ?(allow_legacy_location=false) name =
  let home_file = Filename.concat home name in
  if allow_legacy_location && Sys.file_exists home_file then
    let () = xdgbd_warning loc home_file in
    home_file
  else
    Filename.concat (XDGBD.user_dir loc) name

(* +-----------------------------------------------------------------+
   | Types                                                           |
   +-----------------------------------------------------------------+ *)

type pattern = string list
    (* Type of a pattern. For example the pattern ["foo*bar*"] is
       represented by the list [["foo"; "bar"; ""]]. *)

type t = (pattern * string) list

(* +-----------------------------------------------------------------+
   | Pattern matching                                                |
   +-----------------------------------------------------------------+ *)

let sub_equal str ofs patt =
  let str_len = String.length str and patt_len = String.length patt in
  let rec loop ofs ofs_patt =
    ofs_patt = patt_len || (str.[ofs] = patt.[ofs_patt] && loop (ofs + 1) (ofs_patt + 1))
  in
  ofs + patt_len <= str_len && loop ofs 0

let pattern_match pattern string =
  let length = String.length string in
  let rec loop offset pattern =
    if offset = length then
      pattern = [] || pattern = [""]
    else
      match pattern with
        | [] ->
            false
        | literal :: pattern ->
            let literal_length = String.length literal in
            let max_offset = length - literal_length in
            let rec search offset =
              offset <= max_offset
              && ((sub_equal string offset literal && loop (offset + literal_length) pattern)
                  || search (offset + 1))
            in
            search offset
  in
  match pattern with
    | [] ->
        string = ""
    | literal :: pattern ->
        sub_equal string 0 literal && loop (String.length literal) pattern

(* +-----------------------------------------------------------------+
   | Pattern creation                                                |
   +-----------------------------------------------------------------+ *)

let split pattern =
  let len = String.length pattern in
  let rec loop ofs =
    if ofs = len then
      [""]
    else
      match try Some(String.index_from pattern ofs '*') with Not_found -> None with
        | Some ofs' ->
            String.sub pattern ofs (ofs' - ofs) :: loop (ofs' + 1)
        | None ->
            [String.sub pattern ofs (len - ofs)]
  in
  loop 0

(* +-----------------------------------------------------------------+
   | Set operations                                                  |
   +-----------------------------------------------------------------+ *)

let empty = []

let rec get key = function
  | [] ->
      ""
  | (pattern, value) :: rest ->
      if pattern_match pattern key then
        value
      else
        get key rest

let add pattern value resources = (split pattern, value) :: resources

let merge = ( @ )

(* +-----------------------------------------------------------------+
   | Readers                                                         |
   +-----------------------------------------------------------------+ *)

exception Error of string
let error str = raise (Error str)

let get_bool key resources =
  match String.lowercase_ascii (get key resources) with
    | "true" -> Some true
    | "false" -> Some false
    | "" | "none" -> None
    | s -> Printf.ksprintf error "invalid boolean value %S" s

let hex_of_char ch = match ch with
  | '0' .. '9' -> Char.code ch - Char.code '0'
  | 'A' .. 'F' -> Char.code ch - Char.code 'A' + 10
  | 'a' .. 'f' -> Char.code ch - Char.code 'a' + 10
  | _ -> raise Exit

let get_color key resources =
  match String.lowercase_ascii (get key resources) with

    (* Terminal colors. *)

    | "default" -> Some LTerm_style.default
    | "black" -> Some LTerm_style.black
    | "red" -> Some LTerm_style.red
    | "green" -> Some LTerm_style.green
    | "yellow" -> Some LTerm_style.yellow
    | "blue" -> Some LTerm_style.blue
    | "magenta" -> Some LTerm_style.magenta
    | "cyan" -> Some LTerm_style.cyan
    | "white" -> Some LTerm_style.white
    | "lblack" -> Some LTerm_style.lblack
    | "lred" -> Some LTerm_style.lred
    | "lgreen" -> Some LTerm_style.lgreen
    | "lyellow" -> Some LTerm_style.lyellow
    | "lblue" -> Some LTerm_style.lblue
    | "lmagenta" -> Some LTerm_style.lmagenta
    | "lcyan" -> Some LTerm_style.lcyan
    | "lwhite" -> Some LTerm_style.lwhite
    | "light-black" -> Some LTerm_style.lblack
    | "light-red" -> Some LTerm_style.lred
    | "light-green" -> Some LTerm_style.lgreen
    | "light-yellow" -> Some LTerm_style.lyellow
    | "light-blue" -> Some LTerm_style.lblue
    | "light-magenta" -> Some LTerm_style.lmagenta
    | "light-cyan" -> Some LTerm_style.lcyan
    | "light-white" -> Some LTerm_style.lwhite

    (* X11 colors. *)

    | "x-snow" -> Some (LTerm_style.rgb 255 250 250)
    | "x-ghost-white" -> Some (LTerm_style.rgb 248 248 255)
    | "x-ghostwhite" -> Some (LTerm_style.rgb 248 248 255)
    | "x-white-smoke" -> Some (LTerm_style.rgb 245 245 245)
    | "x-whitesmoke" -> Some (LTerm_style.rgb 245 245 245)
    | "x-gainsboro" -> Some (LTerm_style.rgb 220 220 220)
    | "x-floral-white" -> Some (LTerm_style.rgb 255 250 240)
    | "x-floralwhite" -> Some (LTerm_style.rgb 255 250 240)
    | "x-old-lace" -> Some (LTerm_style.rgb 253 245 230)
    | "x-oldlace" -> Some (LTerm_style.rgb 253 245 230)
    | "x-linen" -> Some (LTerm_style.rgb 250 240 230)
    | "x-antique-white" -> Some (LTerm_style.rgb 250 235 215)
    | "x-antiquewhite" -> Some (LTerm_style.rgb 250 235 215)
    | "x-papaya-whip" -> Some (LTerm_style.rgb 255 239 213)
    | "x-papayawhip" -> Some (LTerm_style.rgb 255 239 213)
    | "x-blanched-almond" -> Some (LTerm_style.rgb 255 235 205)
    | "x-blanchedalmond" -> Some (LTerm_style.rgb 255 235 205)
    | "x-bisque" -> Some (LTerm_style.rgb 255 228 196)
    | "x-peach-puff" -> Some (LTerm_style.rgb 255 218 185)
    | "x-peachpuff" -> Some (LTerm_style.rgb 255 218 185)
    | "x-navajo-white" -> Some (LTerm_style.rgb 255 222 173)
    | "x-navajowhite" -> Some (LTerm_style.rgb 255 222 173)
    | "x-moccasin" -> Some (LTerm_style.rgb 255 228 181)
    | "x-cornsilk" -> Some (LTerm_style.rgb 255 248 220)
    | "x-ivory" -> Some (LTerm_style.rgb 255 255 240)
    | "x-lemon-chiffon" -> Some (LTerm_style.rgb 255 250 205)
    | "x-lemonchiffon" -> Some (LTerm_style.rgb 255 250 205)
    | "x-seashell" -> Some (LTerm_style.rgb 255 245 238)
    | "x-honeydew" -> Some (LTerm_style.rgb 240 255 240)
    | "x-mint-cream" -> Some (LTerm_style.rgb 245 255 250)
    | "x-mintcream" -> Some (LTerm_style.rgb 245 255 250)
    | "x-azure" -> Some (LTerm_style.rgb 240 255 255)
    | "x-alice-blue" -> Some (LTerm_style.rgb 240 248 255)
    | "x-aliceblue" -> Some (LTerm_style.rgb 240 248 255)
    | "x-lavender" -> Some (LTerm_style.rgb 230 230 250)
    | "x-lavender-blush" -> Some (LTerm_style.rgb 255 240 245)
    | "x-lavenderblush" -> Some (LTerm_style.rgb 255 240 245)
    | "x-misty-rose" -> Some (LTerm_style.rgb 255 228 225)
    | "x-mistyrose" -> Some (LTerm_style.rgb 255 228 225)
    | "x-white" -> Some (LTerm_style.rgb 255 255 255)
    | "x-black" -> Some (LTerm_style.rgb 0 0 0)
    | "x-dark-slate-gray" -> Some (LTerm_style.rgb 47 79 79)
    | "x-darkslategray" -> Some (LTerm_style.rgb 47 79 79)
    | "x-dark-slate-grey" -> Some (LTerm_style.rgb 47 79 79)
    | "x-darkslategrey" -> Some (LTerm_style.rgb 47 79 79)
    | "x-dim-gray" -> Some (LTerm_style.rgb 105 105 105)
    | "x-dimgray" -> Some (LTerm_style.rgb 105 105 105)
    | "x-dim-grey" -> Some (LTerm_style.rgb 105 105 105)
    | "x-dimgrey" -> Some (LTerm_style.rgb 105 105 105)
    | "x-slate-gray" -> Some (LTerm_style.rgb 112 128 144)
    | "x-slategray" -> Some (LTerm_style.rgb 112 128 144)
    | "x-slate-grey" -> Some (LTerm_style.rgb 112 128 144)
    | "x-slategrey" -> Some (LTerm_style.rgb 112 128 144)
    | "x-light-slate-gray" -> Some (LTerm_style.rgb 119 136 153)
    | "x-lightslategray" -> Some (LTerm_style.rgb 119 136 153)
    | "x-light-slate-grey" -> Some (LTerm_style.rgb 119 136 153)
    | "x-lightslategrey" -> Some (LTerm_style.rgb 119 136 153)
    | "x-gray" -> Some (LTerm_style.rgb 190 190 190)
    | "x-grey" -> Some (LTerm_style.rgb 190 190 190)
    | "x-light-grey" -> Some (LTerm_style.rgb 211 211 211)
    | "x-lightgrey" -> Some (LTerm_style.rgb 211 211 211)
    | "x-light-gray" -> Some (LTerm_style.rgb 211 211 211)
    | "x-lightgray" -> Some (LTerm_style.rgb 211 211 211)
    | "x-midnight-blue" -> Some (LTerm_style.rgb 25 25 112)
    | "x-midnightblue" -> Some (LTerm_style.rgb 25 25 112)
    | "x-navy" -> Some (LTerm_style.rgb 0 0 128)
    | "x-navy-blue" -> Some (LTerm_style.rgb 0 0 128)
    | "x-navyblue" -> Some (LTerm_style.rgb 0 0 128)
    | "x-cornflower-blue" -> Some (LTerm_style.rgb 100 149 237)
    | "x-cornflowerblue" -> Some (LTerm_style.rgb 100 149 237)
    | "x-dark-slate-blue" -> Some (LTerm_style.rgb 72 61 139)
    | "x-darkslateblue" -> Some (LTerm_style.rgb 72 61 139)
    | "x-slate-blue" -> Some (LTerm_style.rgb 106 90 205)
    | "x-slateblue" -> Some (LTerm_style.rgb 106 90 205)
    | "x-medium-slate-blue" -> Some (LTerm_style.rgb 123 104 238)
    | "x-mediumslateblue" -> Some (LTerm_style.rgb 123 104 238)
    | "x-light-slate-blue" -> Some (LTerm_style.rgb 132 112 255)
    | "x-lightslateblue" -> Some (LTerm_style.rgb 132 112 255)
    | "x-medium-blue" -> Some (LTerm_style.rgb 0 0 205)
    | "x-mediumblue" -> Some (LTerm_style.rgb 0 0 205)
    | "x-royal-blue" -> Some (LTerm_style.rgb 65 105 225)
    | "x-royalblue" -> Some (LTerm_style.rgb 65 105 225)
    | "x-blue" -> Some (LTerm_style.rgb 0 0 255)
    | "x-dodger-blue" -> Some (LTerm_style.rgb 30 144 255)
    | "x-dodgerblue" -> Some (LTerm_style.rgb 30 144 255)
    | "x-deep-sky-blue" -> Some (LTerm_style.rgb 0 191 255)
    | "x-deepskyblue" -> Some (LTerm_style.rgb 0 191 255)
    | "x-sky-blue" -> Some (LTerm_style.rgb 135 206 235)
    | "x-skyblue" -> Some (LTerm_style.rgb 135 206 235)
    | "x-light-sky-blue" -> Some (LTerm_style.rgb 135 206 250)
    | "x-lightskyblue" -> Some (LTerm_style.rgb 135 206 250)
    | "x-steel-blue" -> Some (LTerm_style.rgb 70 130 180)
    | "x-steelblue" -> Some (LTerm_style.rgb 70 130 180)
    | "x-light-steel-blue" -> Some (LTerm_style.rgb 176 196 222)
    | "x-lightsteelblue" -> Some (LTerm_style.rgb 176 196 222)
    | "x-light-blue" -> Some (LTerm_style.rgb 173 216 230)
    | "x-lightblue" -> Some (LTerm_style.rgb 173 216 230)
    | "x-powder-blue" -> Some (LTerm_style.rgb 176 224 230)
    | "x-powderblue" -> Some (LTerm_style.rgb 176 224 230)
    | "x-pale-turquoise" -> Some (LTerm_style.rgb 175 238 238)
    | "x-paleturquoise" -> Some (LTerm_style.rgb 175 238 238)
    | "x-dark-turquoise" -> Some (LTerm_style.rgb 0 206 209)
    | "x-darkturquoise" -> Some (LTerm_style.rgb 0 206 209)
    | "x-medium-turquoise" -> Some (LTerm_style.rgb 72 209 204)
    | "x-mediumturquoise" -> Some (LTerm_style.rgb 72 209 204)
    | "x-turquoise" -> Some (LTerm_style.rgb 64 224 208)
    | "x-cyan" -> Some (LTerm_style.rgb 0 255 255)
    | "x-light-cyan" -> Some (LTerm_style.rgb 224 255 255)
    | "x-lightcyan" -> Some (LTerm_style.rgb 224 255 255)
    | "x-cadet-blue" -> Some (LTerm_style.rgb 95 158 160)
    | "x-cadetblue" -> Some (LTerm_style.rgb 95 158 160)
    | "x-medium-aquamarine" -> Some (LTerm_style.rgb 102 205 170)
    | "x-mediumaquamarine" -> Some (LTerm_style.rgb 102 205 170)
    | "x-aquamarine" -> Some (LTerm_style.rgb 127 255 212)
    | "x-dark-green" -> Some (LTerm_style.rgb 0 100 0)
    | "x-darkgreen" -> Some (LTerm_style.rgb 0 100 0)
    | "x-dark-olive-green" -> Some (LTerm_style.rgb 85 107 47)
    | "x-darkolivegreen" -> Some (LTerm_style.rgb 85 107 47)
    | "x-dark-sea-green" -> Some (LTerm_style.rgb 143 188 143)
    | "x-darkseagreen" -> Some (LTerm_style.rgb 143 188 143)
    | "x-sea-green" -> Some (LTerm_style.rgb 46 139 87)
    | "x-seagreen" -> Some (LTerm_style.rgb 46 139 87)
    | "x-medium-sea-green" -> Some (LTerm_style.rgb 60 179 113)
    | "x-mediumseagreen" -> Some (LTerm_style.rgb 60 179 113)
    | "x-light-sea-green" -> Some (LTerm_style.rgb 32 178 170)
    | "x-lightseagreen" -> Some (LTerm_style.rgb 32 178 170)
    | "x-pale-green" -> Some (LTerm_style.rgb 152 251 152)
    | "x-palegreen" -> Some (LTerm_style.rgb 152 251 152)
    | "x-spring-green" -> Some (LTerm_style.rgb 0 255 127)
    | "x-springgreen" -> Some (LTerm_style.rgb 0 255 127)
    | "x-lawn-green" -> Some (LTerm_style.rgb 124 252 0)
    | "x-lawngreen" -> Some (LTerm_style.rgb 124 252 0)
    | "x-green" -> Some (LTerm_style.rgb 0 255 0)
    | "x-chartreuse" -> Some (LTerm_style.rgb 127 255 0)
    | "x-medium-spring-green" -> Some (LTerm_style.rgb 0 250 154)
    | "x-mediumspringgreen" -> Some (LTerm_style.rgb 0 250 154)
    | "x-green-yellow" -> Some (LTerm_style.rgb 173 255 47)
    | "x-greenyellow" -> Some (LTerm_style.rgb 173 255 47)
    | "x-lime-green" -> Some (LTerm_style.rgb 50 205 50)
    | "x-limegreen" -> Some (LTerm_style.rgb 50 205 50)
    | "x-yellow-green" -> Some (LTerm_style.rgb 154 205 50)
    | "x-yellowgreen" -> Some (LTerm_style.rgb 154 205 50)
    | "x-forest-green" -> Some (LTerm_style.rgb 34 139 34)
    | "x-forestgreen" -> Some (LTerm_style.rgb 34 139 34)
    | "x-olive-drab" -> Some (LTerm_style.rgb 107 142 35)
    | "x-olivedrab" -> Some (LTerm_style.rgb 107 142 35)
    | "x-dark-khaki" -> Some (LTerm_style.rgb 189 183 107)
    | "x-darkkhaki" -> Some (LTerm_style.rgb 189 183 107)
    | "x-khaki" -> Some (LTerm_style.rgb 240 230 140)
    | "x-pale-goldenrod" -> Some (LTerm_style.rgb 238 232 170)
    | "x-palegoldenrod" -> Some (LTerm_style.rgb 238 232 170)
    | "x-light-goldenrod-yellow" -> Some (LTerm_style.rgb 250 250 210)
    | "x-lightgoldenrodyellow" -> Some (LTerm_style.rgb 250 250 210)
    | "x-light-yellow" -> Some (LTerm_style.rgb 255 255 224)
    | "x-lightyellow" -> Some (LTerm_style.rgb 255 255 224)
    | "x-yellow" -> Some (LTerm_style.rgb 255 255 0)
    | "x-gold" -> Some (LTerm_style.rgb 255 215 0)
    | "x-light-goldenrod" -> Some (LTerm_style.rgb 238 221 130)
    | "x-lightgoldenrod" -> Some (LTerm_style.rgb 238 221 130)
    | "x-goldenrod" -> Some (LTerm_style.rgb 218 165 32)
    | "x-dark-goldenrod" -> Some (LTerm_style.rgb 184 134 11)
    | "x-darkgoldenrod" -> Some (LTerm_style.rgb 184 134 11)
    | "x-rosy-brown" -> Some (LTerm_style.rgb 188 143 143)
    | "x-rosybrown" -> Some (LTerm_style.rgb 188 143 143)
    | "x-indian-red" -> Some (LTerm_style.rgb 205 92 92)
    | "x-indianred" -> Some (LTerm_style.rgb 205 92 92)
    | "x-saddle-brown" -> Some (LTerm_style.rgb 139 69 19)
    | "x-saddlebrown" -> Some (LTerm_style.rgb 139 69 19)
    | "x-sienna" -> Some (LTerm_style.rgb 160 82 45)
    | "x-peru" -> Some (LTerm_style.rgb 205 133 63)
    | "x-burlywood" -> Some (LTerm_style.rgb 222 184 135)
    | "x-beige" -> Some (LTerm_style.rgb 245 245 220)
    | "x-wheat" -> Some (LTerm_style.rgb 245 222 179)
    | "x-sandy-brown" -> Some (LTerm_style.rgb 244 164 96)
    | "x-sandybrown" -> Some (LTerm_style.rgb 244 164 96)
    | "x-tan" -> Some (LTerm_style.rgb 210 180 140)
    | "x-chocolate" -> Some (LTerm_style.rgb 210 105 30)
    | "x-firebrick" -> Some (LTerm_style.rgb 178 34 34)
    | "x-brown" -> Some (LTerm_style.rgb 165 42 42)
    | "x-dark-salmon" -> Some (LTerm_style.rgb 233 150 122)
    | "x-darksalmon" -> Some (LTerm_style.rgb 233 150 122)
    | "x-salmon" -> Some (LTerm_style.rgb 250 128 114)
    | "x-light-salmon" -> Some (LTerm_style.rgb 255 160 122)
    | "x-lightsalmon" -> Some (LTerm_style.rgb 255 160 122)
    | "x-orange" -> Some (LTerm_style.rgb 255 165 0)
    | "x-dark-orange" -> Some (LTerm_style.rgb 255 140 0)
    | "x-darkorange" -> Some (LTerm_style.rgb 255 140 0)
    | "x-coral" -> Some (LTerm_style.rgb 255 127 80)
    | "x-light-coral" -> Some (LTerm_style.rgb 240 128 128)
    | "x-lightcoral" -> Some (LTerm_style.rgb 240 128 128)
    | "x-tomato" -> Some (LTerm_style.rgb 255 99 71)
    | "x-orange-red" -> Some (LTerm_style.rgb 255 69 0)
    | "x-orangered" -> Some (LTerm_style.rgb 255 69 0)
    | "x-red" -> Some (LTerm_style.rgb 255 0 0)
    | "x-hot-pink" -> Some (LTerm_style.rgb 255 105 180)
    | "x-hotpink" -> Some (LTerm_style.rgb 255 105 180)
    | "x-deep-pink" -> Some (LTerm_style.rgb 255 20 147)
    | "x-deeppink" -> Some (LTerm_style.rgb 255 20 147)
    | "x-pink" -> Some (LTerm_style.rgb 255 192 203)
    | "x-light-pink" -> Some (LTerm_style.rgb 255 182 193)
    | "x-lightpink" -> Some (LTerm_style.rgb 255 182 193)
    | "x-pale-violet-red" -> Some (LTerm_style.rgb 219 112 147)
    | "x-palevioletred" -> Some (LTerm_style.rgb 219 112 147)
    | "x-maroon" -> Some (LTerm_style.rgb 176 48 96)
    | "x-medium-violet-red" -> Some (LTerm_style.rgb 199 21 133)
    | "x-mediumvioletred" -> Some (LTerm_style.rgb 199 21 133)
    | "x-violet-red" -> Some (LTerm_style.rgb 208 32 144)
    | "x-violetred" -> Some (LTerm_style.rgb 208 32 144)
    | "x-magenta" -> Some (LTerm_style.rgb 255 0 255)
    | "x-violet" -> Some (LTerm_style.rgb 238 130 238)
    | "x-plum" -> Some (LTerm_style.rgb 221 160 221)
    | "x-orchid" -> Some (LTerm_style.rgb 218 112 214)
    | "x-medium-orchid" -> Some (LTerm_style.rgb 186 85 211)
    | "x-mediumorchid" -> Some (LTerm_style.rgb 186 85 211)
    | "x-dark-orchid" -> Some (LTerm_style.rgb 153 50 204)
    | "x-darkorchid" -> Some (LTerm_style.rgb 153 50 204)
    | "x-dark-violet" -> Some (LTerm_style.rgb 148 0 211)
    | "x-darkviolet" -> Some (LTerm_style.rgb 148 0 211)
    | "x-blue-violet" -> Some (LTerm_style.rgb 138 43 226)
    | "x-blueviolet" -> Some (LTerm_style.rgb 138 43 226)
    | "x-purple" -> Some (LTerm_style.rgb 160 32 240)
    | "x-medium-purple" -> Some (LTerm_style.rgb 147 112 219)
    | "x-mediumpurple" -> Some (LTerm_style.rgb 147 112 219)
    | "x-thistle" -> Some (LTerm_style.rgb 216 191 216)
    | "x-snow1" -> Some (LTerm_style.rgb 255 250 250)
    | "x-snow2" -> Some (LTerm_style.rgb 238 233 233)
    | "x-snow3" -> Some (LTerm_style.rgb 205 201 201)
    | "x-snow4" -> Some (LTerm_style.rgb 139 137 137)
    | "x-seashell1" -> Some (LTerm_style.rgb 255 245 238)
    | "x-seashell2" -> Some (LTerm_style.rgb 238 229 222)
    | "x-seashell3" -> Some (LTerm_style.rgb 205 197 191)
    | "x-seashell4" -> Some (LTerm_style.rgb 139 134 130)
    | "x-antiquewhite1" -> Some (LTerm_style.rgb 255 239 219)
    | "x-antiquewhite2" -> Some (LTerm_style.rgb 238 223 204)
    | "x-antiquewhite3" -> Some (LTerm_style.rgb 205 192 176)
    | "x-antiquewhite4" -> Some (LTerm_style.rgb 139 131 120)
    | "x-bisque1" -> Some (LTerm_style.rgb 255 228 196)
    | "x-bisque2" -> Some (LTerm_style.rgb 238 213 183)
    | "x-bisque3" -> Some (LTerm_style.rgb 205 183 158)
    | "x-bisque4" -> Some (LTerm_style.rgb 139 125 107)
    | "x-peachpuff1" -> Some (LTerm_style.rgb 255 218 185)
    | "x-peachpuff2" -> Some (LTerm_style.rgb 238 203 173)
    | "x-peachpuff3" -> Some (LTerm_style.rgb 205 175 149)
    | "x-peachpuff4" -> Some (LTerm_style.rgb 139 119 101)
    | "x-navajowhite1" -> Some (LTerm_style.rgb 255 222 173)
    | "x-navajowhite2" -> Some (LTerm_style.rgb 238 207 161)
    | "x-navajowhite3" -> Some (LTerm_style.rgb 205 179 139)
    | "x-navajowhite4" -> Some (LTerm_style.rgb 139 121 94)
    | "x-lemonchiffon1" -> Some (LTerm_style.rgb 255 250 205)
    | "x-lemonchiffon2" -> Some (LTerm_style.rgb 238 233 191)
    | "x-lemonchiffon3" -> Some (LTerm_style.rgb 205 201 165)
    | "x-lemonchiffon4" -> Some (LTerm_style.rgb 139 137 112)
    | "x-cornsilk1" -> Some (LTerm_style.rgb 255 248 220)
    | "x-cornsilk2" -> Some (LTerm_style.rgb 238 232 205)
    | "x-cornsilk3" -> Some (LTerm_style.rgb 205 200 177)
    | "x-cornsilk4" -> Some (LTerm_style.rgb 139 136 120)
    | "x-ivory1" -> Some (LTerm_style.rgb 255 255 240)
    | "x-ivory2" -> Some (LTerm_style.rgb 238 238 224)
    | "x-ivory3" -> Some (LTerm_style.rgb 205 205 193)
    | "x-ivory4" -> Some (LTerm_style.rgb 139 139 131)
    | "x-honeydew1" -> Some (LTerm_style.rgb 240 255 240)
    | "x-honeydew2" -> Some (LTerm_style.rgb 224 238 224)
    | "x-honeydew3" -> Some (LTerm_style.rgb 193 205 193)
    | "x-honeydew4" -> Some (LTerm_style.rgb 131 139 131)
    | "x-lavenderblush1" -> Some (LTerm_style.rgb 255 240 245)
    | "x-lavenderblush2" -> Some (LTerm_style.rgb 238 224 229)
    | "x-lavenderblush3" -> Some (LTerm_style.rgb 205 193 197)
    | "x-lavenderblush4" -> Some (LTerm_style.rgb 139 131 134)
    | "x-mistyrose1" -> Some (LTerm_style.rgb 255 228 225)
    | "x-mistyrose2" -> Some (LTerm_style.rgb 238 213 210)
    | "x-mistyrose3" -> Some (LTerm_style.rgb 205 183 181)
    | "x-mistyrose4" -> Some (LTerm_style.rgb 139 125 123)
    | "x-azure1" -> Some (LTerm_style.rgb 240 255 255)
    | "x-azure2" -> Some (LTerm_style.rgb 224 238 238)
    | "x-azure3" -> Some (LTerm_style.rgb 193 205 205)
    | "x-azure4" -> Some (LTerm_style.rgb 131 139 139)
    | "x-slateblue1" -> Some (LTerm_style.rgb 131 111 255)
    | "x-slateblue2" -> Some (LTerm_style.rgb 122 103 238)
    | "x-slateblue3" -> Some (LTerm_style.rgb 105 89 205)
    | "x-slateblue4" -> Some (LTerm_style.rgb 71 60 139)
    | "x-royalblue1" -> Some (LTerm_style.rgb 72 118 255)
    | "x-royalblue2" -> Some (LTerm_style.rgb 67 110 238)
    | "x-royalblue3" -> Some (LTerm_style.rgb 58 95 205)
    | "x-royalblue4" -> Some (LTerm_style.rgb 39 64 139)
    | "x-blue1" -> Some (LTerm_style.rgb 0 0 255)
    | "x-blue2" -> Some (LTerm_style.rgb 0 0 238)
    | "x-blue3" -> Some (LTerm_style.rgb 0 0 205)
    | "x-blue4" -> Some (LTerm_style.rgb 0 0 139)
    | "x-dodgerblue1" -> Some (LTerm_style.rgb 30 144 255)
    | "x-dodgerblue2" -> Some (LTerm_style.rgb 28 134 238)
    | "x-dodgerblue3" -> Some (LTerm_style.rgb 24 116 205)
    | "x-dodgerblue4" -> Some (LTerm_style.rgb 16 78 139)
    | "x-steelblue1" -> Some (LTerm_style.rgb 99 184 255)
    | "x-steelblue2" -> Some (LTerm_style.rgb 92 172 238)
    | "x-steelblue3" -> Some (LTerm_style.rgb 79 148 205)
    | "x-steelblue4" -> Some (LTerm_style.rgb 54 100 139)
    | "x-deepskyblue1" -> Some (LTerm_style.rgb 0 191 255)
    | "x-deepskyblue2" -> Some (LTerm_style.rgb 0 178 238)
    | "x-deepskyblue3" -> Some (LTerm_style.rgb 0 154 205)
    | "x-deepskyblue4" -> Some (LTerm_style.rgb 0 104 139)
    | "x-skyblue1" -> Some (LTerm_style.rgb 135 206 255)
    | "x-skyblue2" -> Some (LTerm_style.rgb 126 192 238)
    | "x-skyblue3" -> Some (LTerm_style.rgb 108 166 205)
    | "x-skyblue4" -> Some (LTerm_style.rgb 74 112 139)
    | "x-lightskyblue1" -> Some (LTerm_style.rgb 176 226 255)
    | "x-lightskyblue2" -> Some (LTerm_style.rgb 164 211 238)
    | "x-lightskyblue3" -> Some (LTerm_style.rgb 141 182 205)
    | "x-lightskyblue4" -> Some (LTerm_style.rgb 96 123 139)
    | "x-slategray1" -> Some (LTerm_style.rgb 198 226 255)
    | "x-slategray2" -> Some (LTerm_style.rgb 185 211 238)
    | "x-slategray3" -> Some (LTerm_style.rgb 159 182 205)
    | "x-slategray4" -> Some (LTerm_style.rgb 108 123 139)
    | "x-lightsteelblue1" -> Some (LTerm_style.rgb 202 225 255)
    | "x-lightsteelblue2" -> Some (LTerm_style.rgb 188 210 238)
    | "x-lightsteelblue3" -> Some (LTerm_style.rgb 162 181 205)
    | "x-lightsteelblue4" -> Some (LTerm_style.rgb 110 123 139)
    | "x-lightblue1" -> Some (LTerm_style.rgb 191 239 255)
    | "x-lightblue2" -> Some (LTerm_style.rgb 178 223 238)
    | "x-lightblue3" -> Some (LTerm_style.rgb 154 192 205)
    | "x-lightblue4" -> Some (LTerm_style.rgb 104 131 139)
    | "x-lightcyan1" -> Some (LTerm_style.rgb 224 255 255)
    | "x-lightcyan2" -> Some (LTerm_style.rgb 209 238 238)
    | "x-lightcyan3" -> Some (LTerm_style.rgb 180 205 205)
    | "x-lightcyan4" -> Some (LTerm_style.rgb 122 139 139)
    | "x-paleturquoise1" -> Some (LTerm_style.rgb 187 255 255)
    | "x-paleturquoise2" -> Some (LTerm_style.rgb 174 238 238)
    | "x-paleturquoise3" -> Some (LTerm_style.rgb 150 205 205)
    | "x-paleturquoise4" -> Some (LTerm_style.rgb 102 139 139)
    | "x-cadetblue1" -> Some (LTerm_style.rgb 152 245 255)
    | "x-cadetblue2" -> Some (LTerm_style.rgb 142 229 238)
    | "x-cadetblue3" -> Some (LTerm_style.rgb 122 197 205)
    | "x-cadetblue4" -> Some (LTerm_style.rgb 83 134 139)
    | "x-turquoise1" -> Some (LTerm_style.rgb 0 245 255)
    | "x-turquoise2" -> Some (LTerm_style.rgb 0 229 238)
    | "x-turquoise3" -> Some (LTerm_style.rgb 0 197 205)
    | "x-turquoise4" -> Some (LTerm_style.rgb 0 134 139)
    | "x-cyan1" -> Some (LTerm_style.rgb 0 255 255)
    | "x-cyan2" -> Some (LTerm_style.rgb 0 238 238)
    | "x-cyan3" -> Some (LTerm_style.rgb 0 205 205)
    | "x-cyan4" -> Some (LTerm_style.rgb 0 139 139)
    | "x-darkslategray1" -> Some (LTerm_style.rgb 151 255 255)
    | "x-darkslategray2" -> Some (LTerm_style.rgb 141 238 238)
    | "x-darkslategray3" -> Some (LTerm_style.rgb 121 205 205)
    | "x-darkslategray4" -> Some (LTerm_style.rgb 82 139 139)
    | "x-aquamarine1" -> Some (LTerm_style.rgb 127 255 212)
    | "x-aquamarine2" -> Some (LTerm_style.rgb 118 238 198)
    | "x-aquamarine3" -> Some (LTerm_style.rgb 102 205 170)
    | "x-aquamarine4" -> Some (LTerm_style.rgb 69 139 116)
    | "x-darkseagreen1" -> Some (LTerm_style.rgb 193 255 193)
    | "x-darkseagreen2" -> Some (LTerm_style.rgb 180 238 180)
    | "x-darkseagreen3" -> Some (LTerm_style.rgb 155 205 155)
    | "x-darkseagreen4" -> Some (LTerm_style.rgb 105 139 105)
    | "x-seagreen1" -> Some (LTerm_style.rgb 84 255 159)
    | "x-seagreen2" -> Some (LTerm_style.rgb 78 238 148)
    | "x-seagreen3" -> Some (LTerm_style.rgb 67 205 128)
    | "x-seagreen4" -> Some (LTerm_style.rgb 46 139 87)
    | "x-palegreen1" -> Some (LTerm_style.rgb 154 255 154)
    | "x-palegreen2" -> Some (LTerm_style.rgb 144 238 144)
    | "x-palegreen3" -> Some (LTerm_style.rgb 124 205 124)
    | "x-palegreen4" -> Some (LTerm_style.rgb 84 139 84)
    | "x-springgreen1" -> Some (LTerm_style.rgb 0 255 127)
    | "x-springgreen2" -> Some (LTerm_style.rgb 0 238 118)
    | "x-springgreen3" -> Some (LTerm_style.rgb 0 205 102)
    | "x-springgreen4" -> Some (LTerm_style.rgb 0 139 69)
    | "x-green1" -> Some (LTerm_style.rgb 0 255 0)
    | "x-green2" -> Some (LTerm_style.rgb 0 238 0)
    | "x-green3" -> Some (LTerm_style.rgb 0 205 0)
    | "x-green4" -> Some (LTerm_style.rgb 0 139 0)
    | "x-chartreuse1" -> Some (LTerm_style.rgb 127 255 0)
    | "x-chartreuse2" -> Some (LTerm_style.rgb 118 238 0)
    | "x-chartreuse3" -> Some (LTerm_style.rgb 102 205 0)
    | "x-chartreuse4" -> Some (LTerm_style.rgb 69 139 0)
    | "x-olivedrab1" -> Some (LTerm_style.rgb 192 255 62)
    | "x-olivedrab2" -> Some (LTerm_style.rgb 179 238 58)
    | "x-olivedrab3" -> Some (LTerm_style.rgb 154 205 50)
    | "x-olivedrab4" -> Some (LTerm_style.rgb 105 139 34)
    | "x-darkolivegreen1" -> Some (LTerm_style.rgb 202 255 112)
    | "x-darkolivegreen2" -> Some (LTerm_style.rgb 188 238 104)
    | "x-darkolivegreen3" -> Some (LTerm_style.rgb 162 205 90)
    | "x-darkolivegreen4" -> Some (LTerm_style.rgb 110 139 61)
    | "x-khaki1" -> Some (LTerm_style.rgb 255 246 143)
    | "x-khaki2" -> Some (LTerm_style.rgb 238 230 133)
    | "x-khaki3" -> Some (LTerm_style.rgb 205 198 115)
    | "x-khaki4" -> Some (LTerm_style.rgb 139 134 78)
    | "x-lightgoldenrod1" -> Some (LTerm_style.rgb 255 236 139)
    | "x-lightgoldenrod2" -> Some (LTerm_style.rgb 238 220 130)
    | "x-lightgoldenrod3" -> Some (LTerm_style.rgb 205 190 112)
    | "x-lightgoldenrod4" -> Some (LTerm_style.rgb 139 129 76)
    | "x-lightyellow1" -> Some (LTerm_style.rgb 255 255 224)
    | "x-lightyellow2" -> Some (LTerm_style.rgb 238 238 209)
    | "x-lightyellow3" -> Some (LTerm_style.rgb 205 205 180)
    | "x-lightyellow4" -> Some (LTerm_style.rgb 139 139 122)
    | "x-yellow1" -> Some (LTerm_style.rgb 255 255 0)
    | "x-yellow2" -> Some (LTerm_style.rgb 238 238 0)
    | "x-yellow3" -> Some (LTerm_style.rgb 205 205 0)
    | "x-yellow4" -> Some (LTerm_style.rgb 139 139 0)
    | "x-gold1" -> Some (LTerm_style.rgb 255 215 0)
    | "x-gold2" -> Some (LTerm_style.rgb 238 201 0)
    | "x-gold3" -> Some (LTerm_style.rgb 205 173 0)
    | "x-gold4" -> Some (LTerm_style.rgb 139 117 0)
    | "x-goldenrod1" -> Some (LTerm_style.rgb 255 193 37)
    | "x-goldenrod2" -> Some (LTerm_style.rgb 238 180 34)
    | "x-goldenrod3" -> Some (LTerm_style.rgb 205 155 29)
    | "x-goldenrod4" -> Some (LTerm_style.rgb 139 105 20)
    | "x-darkgoldenrod1" -> Some (LTerm_style.rgb 255 185 15)
    | "x-darkgoldenrod2" -> Some (LTerm_style.rgb 238 173 14)
    | "x-darkgoldenrod3" -> Some (LTerm_style.rgb 205 149 12)
    | "x-darkgoldenrod4" -> Some (LTerm_style.rgb 139 101 8)
    | "x-rosybrown1" -> Some (LTerm_style.rgb 255 193 193)
    | "x-rosybrown2" -> Some (LTerm_style.rgb 238 180 180)
    | "x-rosybrown3" -> Some (LTerm_style.rgb 205 155 155)
    | "x-rosybrown4" -> Some (LTerm_style.rgb 139 105 105)
    | "x-indianred1" -> Some (LTerm_style.rgb 255 106 106)
    | "x-indianred2" -> Some (LTerm_style.rgb 238 99 99)
    | "x-indianred3" -> Some (LTerm_style.rgb 205 85 85)
    | "x-indianred4" -> Some (LTerm_style.rgb 139 58 58)
    | "x-sienna1" -> Some (LTerm_style.rgb 255 130 71)
    | "x-sienna2" -> Some (LTerm_style.rgb 238 121 66)
    | "x-sienna3" -> Some (LTerm_style.rgb 205 104 57)
    | "x-sienna4" -> Some (LTerm_style.rgb 139 71 38)
    | "x-burlywood1" -> Some (LTerm_style.rgb 255 211 155)
    | "x-burlywood2" -> Some (LTerm_style.rgb 238 197 145)
    | "x-burlywood3" -> Some (LTerm_style.rgb 205 170 125)
    | "x-burlywood4" -> Some (LTerm_style.rgb 139 115 85)
    | "x-wheat1" -> Some (LTerm_style.rgb 255 231 186)
    | "x-wheat2" -> Some (LTerm_style.rgb 238 216 174)
    | "x-wheat3" -> Some (LTerm_style.rgb 205 186 150)
    | "x-wheat4" -> Some (LTerm_style.rgb 139 126 102)
    | "x-tan1" -> Some (LTerm_style.rgb 255 165 79)
    | "x-tan2" -> Some (LTerm_style.rgb 238 154 73)
    | "x-tan3" -> Some (LTerm_style.rgb 205 133 63)
    | "x-tan4" -> Some (LTerm_style.rgb 139 90 43)
    | "x-chocolate1" -> Some (LTerm_style.rgb 255 127 36)
    | "x-chocolate2" -> Some (LTerm_style.rgb 238 118 33)
    | "x-chocolate3" -> Some (LTerm_style.rgb 205 102 29)
    | "x-chocolate4" -> Some (LTerm_style.rgb 139 69 19)
    | "x-firebrick1" -> Some (LTerm_style.rgb 255 48 48)
    | "x-firebrick2" -> Some (LTerm_style.rgb 238 44 44)
    | "x-firebrick3" -> Some (LTerm_style.rgb 205 38 38)
    | "x-firebrick4" -> Some (LTerm_style.rgb 139 26 26)
    | "x-brown1" -> Some (LTerm_style.rgb 255 64 64)
    | "x-brown2" -> Some (LTerm_style.rgb 238 59 59)
    | "x-brown3" -> Some (LTerm_style.rgb 205 51 51)
    | "x-brown4" -> Some (LTerm_style.rgb 139 35 35)
    | "x-salmon1" -> Some (LTerm_style.rgb 255 140 105)
    | "x-salmon2" -> Some (LTerm_style.rgb 238 130 98)
    | "x-salmon3" -> Some (LTerm_style.rgb 205 112 84)
    | "x-salmon4" -> Some (LTerm_style.rgb 139 76 57)
    | "x-lightsalmon1" -> Some (LTerm_style.rgb 255 160 122)
    | "x-lightsalmon2" -> Some (LTerm_style.rgb 238 149 114)
    | "x-lightsalmon3" -> Some (LTerm_style.rgb 205 129 98)
    | "x-lightsalmon4" -> Some (LTerm_style.rgb 139 87 66)
    | "x-orange1" -> Some (LTerm_style.rgb 255 165 0)
    | "x-orange2" -> Some (LTerm_style.rgb 238 154 0)
    | "x-orange3" -> Some (LTerm_style.rgb 205 133 0)
    | "x-orange4" -> Some (LTerm_style.rgb 139 90 0)
    | "x-darkorange1" -> Some (LTerm_style.rgb 255 127 0)
    | "x-darkorange2" -> Some (LTerm_style.rgb 238 118 0)
    | "x-darkorange3" -> Some (LTerm_style.rgb 205 102 0)
    | "x-darkorange4" -> Some (LTerm_style.rgb 139 69 0)
    | "x-coral1" -> Some (LTerm_style.rgb 255 114 86)
    | "x-coral2" -> Some (LTerm_style.rgb 238 106 80)
    | "x-coral3" -> Some (LTerm_style.rgb 205 91 69)
    | "x-coral4" -> Some (LTerm_style.rgb 139 62 47)
    | "x-tomato1" -> Some (LTerm_style.rgb 255 99 71)
    | "x-tomato2" -> Some (LTerm_style.rgb 238 92 66)
    | "x-tomato3" -> Some (LTerm_style.rgb 205 79 57)
    | "x-tomato4" -> Some (LTerm_style.rgb 139 54 38)
    | "x-orangered1" -> Some (LTerm_style.rgb 255 69 0)
    | "x-orangered2" -> Some (LTerm_style.rgb 238 64 0)
    | "x-orangered3" -> Some (LTerm_style.rgb 205 55 0)
    | "x-orangered4" -> Some (LTerm_style.rgb 139 37 0)
    | "x-red1" -> Some (LTerm_style.rgb 255 0 0)
    | "x-red2" -> Some (LTerm_style.rgb 238 0 0)
    | "x-red3" -> Some (LTerm_style.rgb 205 0 0)
    | "x-red4" -> Some (LTerm_style.rgb 139 0 0)
    | "x-debianred" -> Some (LTerm_style.rgb 215 7 81)
    | "x-deeppink1" -> Some (LTerm_style.rgb 255 20 147)
    | "x-deeppink2" -> Some (LTerm_style.rgb 238 18 137)
    | "x-deeppink3" -> Some (LTerm_style.rgb 205 16 118)
    | "x-deeppink4" -> Some (LTerm_style.rgb 139 10 80)
    | "x-hotpink1" -> Some (LTerm_style.rgb 255 110 180)
    | "x-hotpink2" -> Some (LTerm_style.rgb 238 106 167)
    | "x-hotpink3" -> Some (LTerm_style.rgb 205 96 144)
    | "x-hotpink4" -> Some (LTerm_style.rgb 139 58 98)
    | "x-pink1" -> Some (LTerm_style.rgb 255 181 197)
    | "x-pink2" -> Some (LTerm_style.rgb 238 169 184)
    | "x-pink3" -> Some (LTerm_style.rgb 205 145 158)
    | "x-pink4" -> Some (LTerm_style.rgb 139 99 108)
    | "x-lightpink1" -> Some (LTerm_style.rgb 255 174 185)
    | "x-lightpink2" -> Some (LTerm_style.rgb 238 162 173)
    | "x-lightpink3" -> Some (LTerm_style.rgb 205 140 149)
    | "x-lightpink4" -> Some (LTerm_style.rgb 139 95 101)
    | "x-palevioletred1" -> Some (LTerm_style.rgb 255 130 171)
    | "x-palevioletred2" -> Some (LTerm_style.rgb 238 121 159)
    | "x-palevioletred3" -> Some (LTerm_style.rgb 205 104 137)
    | "x-palevioletred4" -> Some (LTerm_style.rgb 139 71 93)
    | "x-maroon1" -> Some (LTerm_style.rgb 255 52 179)
    | "x-maroon2" -> Some (LTerm_style.rgb 238 48 167)
    | "x-maroon3" -> Some (LTerm_style.rgb 205 41 144)
    | "x-maroon4" -> Some (LTerm_style.rgb 139 28 98)
    | "x-violetred1" -> Some (LTerm_style.rgb 255 62 150)
    | "x-violetred2" -> Some (LTerm_style.rgb 238 58 140)
    | "x-violetred3" -> Some (LTerm_style.rgb 205 50 120)
    | "x-violetred4" -> Some (LTerm_style.rgb 139 34 82)
    | "x-magenta1" -> Some (LTerm_style.rgb 255 0 255)
    | "x-magenta2" -> Some (LTerm_style.rgb 238 0 238)
    | "x-magenta3" -> Some (LTerm_style.rgb 205 0 205)
    | "x-magenta4" -> Some (LTerm_style.rgb 139 0 139)
    | "x-orchid1" -> Some (LTerm_style.rgb 255 131 250)
    | "x-orchid2" -> Some (LTerm_style.rgb 238 122 233)
    | "x-orchid3" -> Some (LTerm_style.rgb 205 105 201)
    | "x-orchid4" -> Some (LTerm_style.rgb 139 71 137)
    | "x-plum1" -> Some (LTerm_style.rgb 255 187 255)
    | "x-plum2" -> Some (LTerm_style.rgb 238 174 238)
    | "x-plum3" -> Some (LTerm_style.rgb 205 150 205)
    | "x-plum4" -> Some (LTerm_style.rgb 139 102 139)
    | "x-mediumorchid1" -> Some (LTerm_style.rgb 224 102 255)
    | "x-mediumorchid2" -> Some (LTerm_style.rgb 209 95 238)
    | "x-mediumorchid3" -> Some (LTerm_style.rgb 180 82 205)
    | "x-mediumorchid4" -> Some (LTerm_style.rgb 122 55 139)
    | "x-darkorchid1" -> Some (LTerm_style.rgb 191 62 255)
    | "x-darkorchid2" -> Some (LTerm_style.rgb 178 58 238)
    | "x-darkorchid3" -> Some (LTerm_style.rgb 154 50 205)
    | "x-darkorchid4" -> Some (LTerm_style.rgb 104 34 139)
    | "x-purple1" -> Some (LTerm_style.rgb 155 48 255)
    | "x-purple2" -> Some (LTerm_style.rgb 145 44 238)
    | "x-purple3" -> Some (LTerm_style.rgb 125 38 205)
    | "x-purple4" -> Some (LTerm_style.rgb 85 26 139)
    | "x-mediumpurple1" -> Some (LTerm_style.rgb 171 130 255)
    | "x-mediumpurple2" -> Some (LTerm_style.rgb 159 121 238)
    | "x-mediumpurple3" -> Some (LTerm_style.rgb 137 104 205)
    | "x-mediumpurple4" -> Some (LTerm_style.rgb 93 71 139)
    | "x-thistle1" -> Some (LTerm_style.rgb 255 225 255)
    | "x-thistle2" -> Some (LTerm_style.rgb 238 210 238)
    | "x-thistle3" -> Some (LTerm_style.rgb 205 181 205)
    | "x-thistle4" -> Some (LTerm_style.rgb 139 123 139)
    | "x-gray0" -> Some (LTerm_style.rgb 0 0 0)
    | "x-grey0" -> Some (LTerm_style.rgb 0 0 0)
    | "x-gray1" -> Some (LTerm_style.rgb 3 3 3)
    | "x-grey1" -> Some (LTerm_style.rgb 3 3 3)
    | "x-gray2" -> Some (LTerm_style.rgb 5 5 5)
    | "x-grey2" -> Some (LTerm_style.rgb 5 5 5)
    | "x-gray3" -> Some (LTerm_style.rgb 8 8 8)
    | "x-grey3" -> Some (LTerm_style.rgb 8 8 8)
    | "x-gray4" -> Some (LTerm_style.rgb 10 10 10)
    | "x-grey4" -> Some (LTerm_style.rgb 10 10 10)
    | "x-gray5" -> Some (LTerm_style.rgb 13 13 13)
    | "x-grey5" -> Some (LTerm_style.rgb 13 13 13)
    | "x-gray6" -> Some (LTerm_style.rgb 15 15 15)
    | "x-grey6" -> Some (LTerm_style.rgb 15 15 15)
    | "x-gray7" -> Some (LTerm_style.rgb 18 18 18)
    | "x-grey7" -> Some (LTerm_style.rgb 18 18 18)
    | "x-gray8" -> Some (LTerm_style.rgb 20 20 20)
    | "x-grey8" -> Some (LTerm_style.rgb 20 20 20)
    | "x-gray9" -> Some (LTerm_style.rgb 23 23 23)
    | "x-grey9" -> Some (LTerm_style.rgb 23 23 23)
    | "x-gray10" -> Some (LTerm_style.rgb 26 26 26)
    | "x-grey10" -> Some (LTerm_style.rgb 26 26 26)
    | "x-gray11" -> Some (LTerm_style.rgb 28 28 28)
    | "x-grey11" -> Some (LTerm_style.rgb 28 28 28)
    | "x-gray12" -> Some (LTerm_style.rgb 31 31 31)
    | "x-grey12" -> Some (LTerm_style.rgb 31 31 31)
    | "x-gray13" -> Some (LTerm_style.rgb 33 33 33)
    | "x-grey13" -> Some (LTerm_style.rgb 33 33 33)
    | "x-gray14" -> Some (LTerm_style.rgb 36 36 36)
    | "x-grey14" -> Some (LTerm_style.rgb 36 36 36)
    | "x-gray15" -> Some (LTerm_style.rgb 38 38 38)
    | "x-grey15" -> Some (LTerm_style.rgb 38 38 38)
    | "x-gray16" -> Some (LTerm_style.rgb 41 41 41)
    | "x-grey16" -> Some (LTerm_style.rgb 41 41 41)
    | "x-gray17" -> Some (LTerm_style.rgb 43 43 43)
    | "x-grey17" -> Some (LTerm_style.rgb 43 43 43)
    | "x-gray18" -> Some (LTerm_style.rgb 46 46 46)
    | "x-grey18" -> Some (LTerm_style.rgb 46 46 46)
    | "x-gray19" -> Some (LTerm_style.rgb 48 48 48)
    | "x-grey19" -> Some (LTerm_style.rgb 48 48 48)
    | "x-gray20" -> Some (LTerm_style.rgb 51 51 51)
    | "x-grey20" -> Some (LTerm_style.rgb 51 51 51)
    | "x-gray21" -> Some (LTerm_style.rgb 54 54 54)
    | "x-grey21" -> Some (LTerm_style.rgb 54 54 54)
    | "x-gray22" -> Some (LTerm_style.rgb 56 56 56)
    | "x-grey22" -> Some (LTerm_style.rgb 56 56 56)
    | "x-gray23" -> Some (LTerm_style.rgb 59 59 59)
    | "x-grey23" -> Some (LTerm_style.rgb 59 59 59)
    | "x-gray24" -> Some (LTerm_style.rgb 61 61 61)
    | "x-grey24" -> Some (LTerm_style.rgb 61 61 61)
    | "x-gray25" -> Some (LTerm_style.rgb 64 64 64)
    | "x-grey25" -> Some (LTerm_style.rgb 64 64 64)
    | "x-gray26" -> Some (LTerm_style.rgb 66 66 66)
    | "x-grey26" -> Some (LTerm_style.rgb 66 66 66)
    | "x-gray27" -> Some (LTerm_style.rgb 69 69 69)
    | "x-grey27" -> Some (LTerm_style.rgb 69 69 69)
    | "x-gray28" -> Some (LTerm_style.rgb 71 71 71)
    | "x-grey28" -> Some (LTerm_style.rgb 71 71 71)
    | "x-gray29" -> Some (LTerm_style.rgb 74 74 74)
    | "x-grey29" -> Some (LTerm_style.rgb 74 74 74)
    | "x-gray30" -> Some (LTerm_style.rgb 77 77 77)
    | "x-grey30" -> Some (LTerm_style.rgb 77 77 77)
    | "x-gray31" -> Some (LTerm_style.rgb 79 79 79)
    | "x-grey31" -> Some (LTerm_style.rgb 79 79 79)
    | "x-gray32" -> Some (LTerm_style.rgb 82 82 82)
    | "x-grey32" -> Some (LTerm_style.rgb 82 82 82)
    | "x-gray33" -> Some (LTerm_style.rgb 84 84 84)
    | "x-grey33" -> Some (LTerm_style.rgb 84 84 84)
    | "x-gray34" -> Some (LTerm_style.rgb 87 87 87)
    | "x-grey34" -> Some (LTerm_style.rgb 87 87 87)
    | "x-gray35" -> Some (LTerm_style.rgb 89 89 89)
    | "x-grey35" -> Some (LTerm_style.rgb 89 89 89)
    | "x-gray36" -> Some (LTerm_style.rgb 92 92 92)
    | "x-grey36" -> Some (LTerm_style.rgb 92 92 92)
    | "x-gray37" -> Some (LTerm_style.rgb 94 94 94)
    | "x-grey37" -> Some (LTerm_style.rgb 94 94 94)
    | "x-gray38" -> Some (LTerm_style.rgb 97 97 97)
    | "x-grey38" -> Some (LTerm_style.rgb 97 97 97)
    | "x-gray39" -> Some (LTerm_style.rgb 99 99 99)
    | "x-grey39" -> Some (LTerm_style.rgb 99 99 99)
    | "x-gray40" -> Some (LTerm_style.rgb 102 102 102)
    | "x-grey40" -> Some (LTerm_style.rgb 102 102 102)
    | "x-gray41" -> Some (LTerm_style.rgb 105 105 105)
    | "x-grey41" -> Some (LTerm_style.rgb 105 105 105)
    | "x-gray42" -> Some (LTerm_style.rgb 107 107 107)
    | "x-grey42" -> Some (LTerm_style.rgb 107 107 107)
    | "x-gray43" -> Some (LTerm_style.rgb 110 110 110)
    | "x-grey43" -> Some (LTerm_style.rgb 110 110 110)
    | "x-gray44" -> Some (LTerm_style.rgb 112 112 112)
    | "x-grey44" -> Some (LTerm_style.rgb 112 112 112)
    | "x-gray45" -> Some (LTerm_style.rgb 115 115 115)
    | "x-grey45" -> Some (LTerm_style.rgb 115 115 115)
    | "x-gray46" -> Some (LTerm_style.rgb 117 117 117)
    | "x-grey46" -> Some (LTerm_style.rgb 117 117 117)
    | "x-gray47" -> Some (LTerm_style.rgb 120 120 120)
    | "x-grey47" -> Some (LTerm_style.rgb 120 120 120)
    | "x-gray48" -> Some (LTerm_style.rgb 122 122 122)
    | "x-grey48" -> Some (LTerm_style.rgb 122 122 122)
    | "x-gray49" -> Some (LTerm_style.rgb 125 125 125)
    | "x-grey49" -> Some (LTerm_style.rgb 125 125 125)
    | "x-gray50" -> Some (LTerm_style.rgb 127 127 127)
    | "x-grey50" -> Some (LTerm_style.rgb 127 127 127)
    | "x-gray51" -> Some (LTerm_style.rgb 130 130 130)
    | "x-grey51" -> Some (LTerm_style.rgb 130 130 130)
    | "x-gray52" -> Some (LTerm_style.rgb 133 133 133)
    | "x-grey52" -> Some (LTerm_style.rgb 133 133 133)
    | "x-gray53" -> Some (LTerm_style.rgb 135 135 135)
    | "x-grey53" -> Some (LTerm_style.rgb 135 135 135)
    | "x-gray54" -> Some (LTerm_style.rgb 138 138 138)
    | "x-grey54" -> Some (LTerm_style.rgb 138 138 138)
    | "x-gray55" -> Some (LTerm_style.rgb 140 140 140)
    | "x-grey55" -> Some (LTerm_style.rgb 140 140 140)
    | "x-gray56" -> Some (LTerm_style.rgb 143 143 143)
    | "x-grey56" -> Some (LTerm_style.rgb 143 143 143)
    | "x-gray57" -> Some (LTerm_style.rgb 145 145 145)
    | "x-grey57" -> Some (LTerm_style.rgb 145 145 145)
    | "x-gray58" -> Some (LTerm_style.rgb 148 148 148)
    | "x-grey58" -> Some (LTerm_style.rgb 148 148 148)
    | "x-gray59" -> Some (LTerm_style.rgb 150 150 150)
    | "x-grey59" -> Some (LTerm_style.rgb 150 150 150)
    | "x-gray60" -> Some (LTerm_style.rgb 153 153 153)
    | "x-grey60" -> Some (LTerm_style.rgb 153 153 153)
    | "x-gray61" -> Some (LTerm_style.rgb 156 156 156)
    | "x-grey61" -> Some (LTerm_style.rgb 156 156 156)
    | "x-gray62" -> Some (LTerm_style.rgb 158 158 158)
    | "x-grey62" -> Some (LTerm_style.rgb 158 158 158)
    | "x-gray63" -> Some (LTerm_style.rgb 161 161 161)
    | "x-grey63" -> Some (LTerm_style.rgb 161 161 161)
    | "x-gray64" -> Some (LTerm_style.rgb 163 163 163)
    | "x-grey64" -> Some (LTerm_style.rgb 163 163 163)
    | "x-gray65" -> Some (LTerm_style.rgb 166 166 166)
    | "x-grey65" -> Some (LTerm_style.rgb 166 166 166)
    | "x-gray66" -> Some (LTerm_style.rgb 168 168 168)
    | "x-grey66" -> Some (LTerm_style.rgb 168 168 168)
    | "x-gray67" -> Some (LTerm_style.rgb 171 171 171)
    | "x-grey67" -> Some (LTerm_style.rgb 171 171 171)
    | "x-gray68" -> Some (LTerm_style.rgb 173 173 173)
    | "x-grey68" -> Some (LTerm_style.rgb 173 173 173)
    | "x-gray69" -> Some (LTerm_style.rgb 176 176 176)
    | "x-grey69" -> Some (LTerm_style.rgb 176 176 176)
    | "x-gray70" -> Some (LTerm_style.rgb 179 179 179)
    | "x-grey70" -> Some (LTerm_style.rgb 179 179 179)
    | "x-gray71" -> Some (LTerm_style.rgb 181 181 181)
    | "x-grey71" -> Some (LTerm_style.rgb 181 181 181)
    | "x-gray72" -> Some (LTerm_style.rgb 184 184 184)
    | "x-grey72" -> Some (LTerm_style.rgb 184 184 184)
    | "x-gray73" -> Some (LTerm_style.rgb 186 186 186)
    | "x-grey73" -> Some (LTerm_style.rgb 186 186 186)
    | "x-gray74" -> Some (LTerm_style.rgb 189 189 189)
    | "x-grey74" -> Some (LTerm_style.rgb 189 189 189)
    | "x-gray75" -> Some (LTerm_style.rgb 191 191 191)
    | "x-grey75" -> Some (LTerm_style.rgb 191 191 191)
    | "x-gray76" -> Some (LTerm_style.rgb 194 194 194)
    | "x-grey76" -> Some (LTerm_style.rgb 194 194 194)
    | "x-gray77" -> Some (LTerm_style.rgb 196 196 196)
    | "x-grey77" -> Some (LTerm_style.rgb 196 196 196)
    | "x-gray78" -> Some (LTerm_style.rgb 199 199 199)
    | "x-grey78" -> Some (LTerm_style.rgb 199 199 199)
    | "x-gray79" -> Some (LTerm_style.rgb 201 201 201)
    | "x-grey79" -> Some (LTerm_style.rgb 201 201 201)
    | "x-gray80" -> Some (LTerm_style.rgb 204 204 204)
    | "x-grey80" -> Some (LTerm_style.rgb 204 204 204)
    | "x-gray81" -> Some (LTerm_style.rgb 207 207 207)
    | "x-grey81" -> Some (LTerm_style.rgb 207 207 207)
    | "x-gray82" -> Some (LTerm_style.rgb 209 209 209)
    | "x-grey82" -> Some (LTerm_style.rgb 209 209 209)
    | "x-gray83" -> Some (LTerm_style.rgb 212 212 212)
    | "x-grey83" -> Some (LTerm_style.rgb 212 212 212)
    | "x-gray84" -> Some (LTerm_style.rgb 214 214 214)
    | "x-grey84" -> Some (LTerm_style.rgb 214 214 214)
    | "x-gray85" -> Some (LTerm_style.rgb 217 217 217)
    | "x-grey85" -> Some (LTerm_style.rgb 217 217 217)
    | "x-gray86" -> Some (LTerm_style.rgb 219 219 219)
    | "x-grey86" -> Some (LTerm_style.rgb 219 219 219)
    | "x-gray87" -> Some (LTerm_style.rgb 222 222 222)
    | "x-grey87" -> Some (LTerm_style.rgb 222 222 222)
    | "x-gray88" -> Some (LTerm_style.rgb 224 224 224)
    | "x-grey88" -> Some (LTerm_style.rgb 224 224 224)
    | "x-gray89" -> Some (LTerm_style.rgb 227 227 227)
    | "x-grey89" -> Some (LTerm_style.rgb 227 227 227)
    | "x-gray90" -> Some (LTerm_style.rgb 229 229 229)
    | "x-grey90" -> Some (LTerm_style.rgb 229 229 229)
    | "x-gray91" -> Some (LTerm_style.rgb 232 232 232)
    | "x-grey91" -> Some (LTerm_style.rgb 232 232 232)
    | "x-gray92" -> Some (LTerm_style.rgb 235 235 235)
    | "x-grey92" -> Some (LTerm_style.rgb 235 235 235)
    | "x-gray93" -> Some (LTerm_style.rgb 237 237 237)
    | "x-grey93" -> Some (LTerm_style.rgb 237 237 237)
    | "x-gray94" -> Some (LTerm_style.rgb 240 240 240)
    | "x-grey94" -> Some (LTerm_style.rgb 240 240 240)
    | "x-gray95" -> Some (LTerm_style.rgb 242 242 242)
    | "x-grey95" -> Some (LTerm_style.rgb 242 242 242)
    | "x-gray96" -> Some (LTerm_style.rgb 245 245 245)
    | "x-grey96" -> Some (LTerm_style.rgb 245 245 245)
    | "x-gray97" -> Some (LTerm_style.rgb 247 247 247)
    | "x-grey97" -> Some (LTerm_style.rgb 247 247 247)
    | "x-gray98" -> Some (LTerm_style.rgb 250 250 250)
    | "x-grey98" -> Some (LTerm_style.rgb 250 250 250)
    | "x-gray99" -> Some (LTerm_style.rgb 252 252 252)
    | "x-grey99" -> Some (LTerm_style.rgb 252 252 252)
    | "x-gray100" -> Some (LTerm_style.rgb 255 255 255)
    | "x-grey100" -> Some (LTerm_style.rgb 255 255 255)
    | "x-dark-grey" -> Some (LTerm_style.rgb 169 169 169)
    | "x-darkgrey" -> Some (LTerm_style.rgb 169 169 169)
    | "x-dark-gray" -> Some (LTerm_style.rgb 169 169 169)
    | "x-darkgray" -> Some (LTerm_style.rgb 169 169 169)
    | "x-dark-blue" -> Some (LTerm_style.rgb 0 0 139)
    | "x-darkblue" -> Some (LTerm_style.rgb 0 0 139)
    | "x-dark-cyan" -> Some (LTerm_style.rgb 0 139 139)
    | "x-darkcyan" -> Some (LTerm_style.rgb 0 139 139)
    | "x-dark-magenta" -> Some (LTerm_style.rgb 139 0 139)
    | "x-darkmagenta" -> Some (LTerm_style.rgb 139 0 139)
    | "x-dark-red" -> Some (LTerm_style.rgb 139 0 0)
    | "x-darkred" -> Some (LTerm_style.rgb 139 0 0)
    | "x-light-green" -> Some (LTerm_style.rgb 144 238 144)
    | "x-lightgreen" -> Some (LTerm_style.rgb 144 238 144)

    | "" | "none" -> None
    | str when str.[0] = '#' ->
        if String.length str = 7 then
          try
            Some(LTerm_style.rgb
                   (hex_of_char str.[1] lsl 4 lor hex_of_char str.[2])
                   (hex_of_char str.[3] lsl 4 lor hex_of_char str.[4])
                   (hex_of_char str.[5] lsl 4 lor hex_of_char str.[6]))
          with Exit ->
            Printf.ksprintf error "invalid color %S" str
        else
          Printf.ksprintf error "invalid color %S" str
    | str ->
        try
          Some(LTerm_style.index (int_of_string str))
        with Failure _ ->
          Printf.ksprintf error "invalid color %S" str

let get_style prefix resources = {
  LTerm_style.bold = get_bool (prefix ^ ".bold") resources;
  LTerm_style.underline = get_bool (prefix ^ ".underline") resources;
  LTerm_style.blink = get_bool (prefix ^ ".blink") resources;
  LTerm_style.reverse = get_bool (prefix ^ ".reverse") resources;
  LTerm_style.foreground = get_color (prefix ^ ".foreground") resources;
  LTerm_style.background = get_color (prefix ^ ".background") resources;
}

let get_connection key resources =
  match String.lowercase_ascii (get key resources) with
    | "blank" -> LTerm_draw.Blank
    | "light" -> LTerm_draw.Light
    | "heavy" -> LTerm_draw.Heavy
    | "" -> LTerm_draw.Light
    | str -> Printf.ksprintf error "invalid connection %S" str

(* +-----------------------------------------------------------------+
   | Parsing                                                         |
   +-----------------------------------------------------------------+ *)

exception Parse_error of string * int * string

let parse str =
  let lexbuf = Lexing.from_string str in
  let rec loop line acc =
    match LTerm_resource_lexer.line lexbuf with
      | `EOF ->
          acc
      | `Empty ->
          loop (line + 1) acc
      | `Assoc(pattern, value) ->
          loop (line + 1) (add pattern value acc)
      | `Error msg ->
          raise (Parse_error("<string>", line, msg))
  in
  loop 1 []

let load file =
  Lwt_io.open_file ~mode:Lwt_io.input file >>= fun ic ->
  let rec loop lineno acc =
    Lwt_io.read_line_opt ic >>= fun line ->
    match line with
      | None ->
          Lwt.return acc
      | Some str ->
          match LTerm_resource_lexer.line (Lexing.from_string str) with
            | `EOF ->
                loop (lineno + 1) acc
            | `Empty ->
                loop (lineno + 1) acc
            | `Assoc(pattern, value) ->
                loop (lineno + 1) (add pattern value acc)
            | `Error msg ->
                Lwt.fail (Parse_error(file, lineno, msg))
  in
  Lwt.finalize
    (fun () -> loop 1 [])
    (fun () -> Lwt_io.close ic)
