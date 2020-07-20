(*
 * zed_string.ml
 * -----------
 * Copyright : (c) 2019, ZAN DoYe <zandoye@gmail.com>
 * Licence   : BSD3
 *
 * This file is a part of Zed, an editor engine.
 *)

(* This aliasing needs to come before 'open Result' which now offers a
   'compare' function. We don't use 'Pervasives.compare' or 'Stdlib.compare'
   because neither seems to work with every version of OCaml. *)
let pervasives_compare= compare

open Result

exception Invalid of string * string
exception Out_of_bounds
  (** Exception raised when trying to access a character which is
      outside the bounds of a string. *)

let fail str pos msg = raise (Invalid(Printf.sprintf "at position %d: %s" pos msg, str))

module Zed_string0 = struct

  type seg_width= {
    start: int;
    len: int;
    width: int;
  }

  type all_width= {
    len: int;
    width: int;
  }

  type width= (all_width, seg_width) result

  type t= Zed_utf8.t

  let aval_width= function
    | Ok {len=_;width}-> width
    | Error {start=_;len=_;width}-> width

  let bytes str= String.length str

  let size str= Zed_utf8.length str

  let copy t= t

  let unsafe_next str ofs=
    let str_len= String.length str in
    let rec skip str ofs=
      if ofs >= str_len then
        str_len
      else
        let chr, next= Zed_utf8.unsafe_extract_next str ofs in
        if Zed_char.is_combining_mark chr then
          skip str next
        else
          ofs
    in
    if ofs < 0 || ofs >= String.length str then
      raise Out_of_bounds
    else
      let chr, next= Zed_utf8.unsafe_extract_next str ofs in
      if Zed_char.is_printable chr then
        skip str next
      else
        next

  let next_ofs str ofs=
    let str_len= String.length str in
    let rec skip str ofs=
      if ofs >= str_len then
        str_len
      else
        let chr, next= Zed_utf8.unsafe_extract_next str ofs in
        if Zed_char.is_combining_mark chr then
          skip str next
        else
          ofs
    in
    if ofs < 0 || ofs >= String.length str then
      raise Out_of_bounds
    else
      let chr, next= Zed_utf8.unsafe_extract_next str ofs in
      if Zed_char.is_printable_core chr then
        skip str next
      else if Zed_char.is_combining_mark chr then
        fail str ofs "individual combining marks encountered"
      else
        next

  let length str=
    let eos= String.length str in
    let rec length len ofs=
      if ofs < eos then
        length (len + 1) (unsafe_next str ofs)
      else
        len
    in
    length 0 0

  let unsafe_prev str ofs=
    let rec skip str ofs=
      if ofs = 0 then
        ofs
      else
        let chr, prev= Zed_utf8.unsafe_extract_prev str ofs in
        if Zed_char.is_combining_mark chr then
          skip str prev
        else
          prev
    in
    if ofs <= 0 || ofs > String.length str then
      raise Out_of_bounds
    else
      let chr, prev= Zed_utf8.extract_prev str ofs in
      if Zed_char.is_combining_mark chr then
        skip str prev
      else
        prev

  let prev_ofs str ofs=
    let rec skip str ofs=
      if ofs = 0 then
        ofs
      else
        let chr, prev= Zed_utf8.unsafe_extract_prev str ofs in
        if Zed_char.is_combining_mark chr then
          skip str prev
        else
          prev
    in
    if ofs <= 0 || ofs > String.length str then
      raise Out_of_bounds
    else
      let chr, prev= Zed_utf8.extract_prev str ofs in
      if Zed_char.is_combining_mark chr then
        let prev= skip str prev in
        if prev = 0 then
          if Zed_char.is_printable_core (Zed_utf8.unsafe_extract str 0) then
            prev
          else
            fail str 0 "individual combining marks encountered"
        else
          let chr, next= Zed_utf8.unsafe_extract_next str prev in
          match Zed_char.prop_uChar chr with
          | Printable 0
          | Other
          | Null -> fail str next "individual combining marks encountered"
          | _-> prev
      else
        prev

  let rec move_l str ofs len=
    if len = 0 then
      ofs
    else if ofs >= String.length str then
      raise Out_of_bounds
    else
      move_l str (unsafe_next str ofs) (len - 1)

  let move_b str ofs len=
    let rec move str ofs len=
      if len = 0 then
        ofs
      else if ofs < 0 then
        raise Out_of_bounds
      else
        move str (unsafe_prev str ofs) (len - 1)
    in
    if ofs < 0 || ofs > String.length str then
      raise Out_of_bounds
    else
      move str ofs len

  let rec move_l_raw str ofs len=
    if len = 0 then
      ofs
    else if ofs >= String.length str then
      raise Out_of_bounds
    else
      move_l_raw str (Zed_utf8.unsafe_next str ofs) (len - 1)

  let move_b_raw str ofs len=
    let rec move str ofs len=
      if len = 0 then
        ofs
      else if ofs < 0 then
        raise Out_of_bounds
      else
        move str (Zed_utf8.unsafe_prev str ofs) (len - 1)
    in
    if ofs < 0 || ofs > String.length str then
      raise Out_of_bounds
    else
      move str ofs len

  let extract str ofs=
    let next= next_ofs str ofs in
    Zed_char.unsafe_of_utf8 (String.sub str ofs (next - ofs))

  let extract_next str ofs=
    let next= next_ofs str ofs in
    (Zed_char.unsafe_of_utf8 (String.sub str ofs (next - ofs)), next)

  let extract_prev str ofs=
    let prev= prev_ofs str ofs in
    (Zed_char.unsafe_of_utf8 (String.sub str prev (ofs - prev)), prev)

  let to_raw_list str= Zed_utf8.explode str

  let to_raw_array str= Array.of_list (to_raw_list str)

  type index= int

  let get str idx =
    if idx < 0 then
      raise Out_of_bounds
    else
      extract str (move_l str 0 idx)

  let get_raw= Zed_utf8.get

  let empty ()= ""

  let width_ofs ?(start=0) ?num str=
    let str_len= String.length str in
    let rec calc w idx ofs=
      if ofs < str_len then
        let chr, next= extract_next str ofs in
        let chr_width= Zed_char.width chr in
        if chr_width > 0 then
          calc (w + chr_width) (idx+1) next
        else
          Error { start; len= idx - start; width= w }
      else Ok {len= idx - start; width= w }
    in
    let calc_num num w idx ofs=
      let rec calc n w idx ofs=
        if ofs < str_len && n > 0 then
          let chr, next= extract_next str ofs in
          let chr_width= Zed_char.width chr in
          if chr_width > 0 then
            calc (n-1) (w + chr_width) (idx+1) next
          else
            Error { start; len= idx - start; width= w }
        else Ok {len= idx - start; width= w }
      in
      calc num w idx ofs
    in
    match num with
    | Some num-> calc_num num 0 start start
    | None-> calc 0 start start

  let width ?(start=0) ?num str=
    let ofs= move_l str 0 start in
    width_ofs ~start:ofs ?num str

  let explode str=
    let str_len= String.length str in
    let rec aux acc str ofs=
      if ofs > 0 then
        let chr, prev= extract_prev str ofs in
        aux (chr::acc) str prev
      else
        acc
    in
    if str_len > 0 then
      aux [] str str_len
    else
      []

  let rev_explode str=
    let str_len= String.length str in
    let rec aux acc ofs=
      if ofs < str_len then
        let chr, next= extract_next str ofs in
        aux (chr::acc) next
      else
        []
    in
    if str_len > 0 then
      aux [] 0
    else
      []

  let unsafe_explode str=
    let str_len= String.length str in
    let rec aux acc str ofs=
      if ofs > 0 then
        let chr, prev= extract_prev str ofs in
        aux (chr::acc) str prev
      else
        acc
    in
    if str_len > 0 then
      aux [] str str_len
    else
      []

  let unsafe_rev_explode str=
    let str_len= String.length str in
    let rec aux acc ofs=
      if ofs < str_len then
        let chr, next= extract_next str ofs in
        aux (chr::acc) next
      else
        []
    in
    if str_len > 0 then
      aux [] 0
    else
      []

  let implode chars=
    String.concat "" (List.map Zed_char.to_utf8 chars)

  let init len (f: int -> Zed_char.t)=
    let rec create acc n=
      if n > 0 then
        create ((f (n-1))::acc) (n-1)
      else acc
    in
    implode (create [] len)

  let init_from_uChars len f=
    match len with
    | 0-> empty ()
    | len when len > 0 ->
      let rec create acc n=
        if n > 0 then
          create ((f (n-1))::acc) (n-1)
        else acc
      in
      let uChars= create [] len in
      let zChars, _= Zed_char.zChars_of_uChars uChars in
      implode zChars
    | _-> raise (Invalid_argument "Zed_string0.init_from_uChars")


  let unsafe_of_uChars uChars=
    match uChars with
    | []-> ""
    | _-> String.concat "" (List.map Zed_utf8.singleton uChars)

  let of_uChars uChars=
    match uChars with
    | []-> "", []
    | fst::_->
      if Zed_char.is_combining_mark fst then
        ("", uChars)
      else
        (uChars |> List.map Zed_utf8.singleton |> String.concat "", [])

  let unsafe_append s1 s2=
    s1 ^ s2

  let append s1 s2=
    let validate_s2 ()=
      let s2_first= Zed_utf8.unsafe_extract s2 0 in
      if Zed_char.is_combining_mark s2_first then
        fail s2 0 "individual combining marks encountered"
      else
        s2
    in
    if s1 = "" then
      validate_s2 ()
    else if s2 = "" then
      s1
    else
      let (s1_last, _)= extract_prev s1 (bytes s1) in
      if Zed_char.(is_printable_core (core s1_last)) then
        unsafe_append s1 s2
      else
        unsafe_append s1 (validate_s2 ())

  external id : 'a -> 'a = "%identity"
  let unsafe_of_utf8 : string -> t= id
  let of_utf8 : string -> t= fun str->
    if String.length str = 0 then ""
    else if Zed_char.is_combining_mark (Zed_utf8.extract str 0) then
      fail str 0 "individual combining marks encountered"
    else
      unsafe_of_utf8 str
  let to_utf8 : t -> string= id

  let for_all p str= List.for_all p (explode str)

  let check_range t n= n >= 0 && n <= length t

  let look str ofs= Zed_utf8.extract str ofs

  let nth t n= if check_range t n
    then n
    else raise (Invalid_argument "Zed_string.nth")

  let next t n=
    let n= n + 1 in
    if check_range t n
    then n
    else raise (Invalid_argument "Zed_string.next")

  let prev t n=
    let n= n - 1 in
    if check_range t n
    then n
    else raise (Invalid_argument "Zed_string.prev")

  let out_of_range t n= n < 0 || n >= length t

  let iter f str= List.iter f (explode str)

  let rev_iter f str= List.iter f (rev_explode str)

  let fold f str acc=
    let rec aux f chars acc=
      match chars with
      | []-> acc
      | chr::tl-> aux f tl (f chr acc)
    in
    aux f (explode str) acc

  let rev_fold f str acc=
    let rec aux f chars acc=
      match chars with
      | []-> acc
      | chr::tl-> aux f tl (f chr acc)
    in
    aux f (rev_explode str) acc

  let map f str=
    implode (List.map f (explode str))

  let rev_map f str=
    implode (List.map f (rev_explode str))

  let compare str1 str2= Zed_utils.list_compare
    ~compare:Zed_char.compare_raw
    (explode str1) (explode str2)

  let first (_:t)= 0
  let last t= max (length t - 1) 0

  let move t i n=
    if n >= 0 then move_l t i n
    else move_b t i n

  let move_raw t i n=
    if n >= 0 then move_l_raw t i n
    else move_b_raw t i n

  let compare_index (_:t) i j= pervasives_compare i j

  let sub_ofs ~ofs ~len s=
    if ofs < 0 || len < 0 || ofs > bytes s - len then
      invalid_arg "Zed_string.sub"
    else
      String.sub s ofs len

  let sub ~pos ~len s=
    if pos < 0 || len < 0 || pos > length s - len then
      invalid_arg "Zed_string.sub"
    else
      let ofs_start= move_l s 0 pos in
      let ofs_end= move_l s ofs_start len in
      String.sub s ofs_start (ofs_end - ofs_start)

  let after s i=
    let len= length s in
    if i < len then
      sub ~pos:i ~len:(len-i) s
    else
      empty ()

  let rec unsafe_sub_equal str ofs sub ofs_sub=
    if ofs_sub = String.length sub then
      true
    else
      (String.unsafe_get str ofs = String.unsafe_get sub ofs_sub)
      && unsafe_sub_equal str (ofs + 1) sub (ofs_sub + 1)

  let starts_with ~prefix str=
    if String.length prefix > String.length str then
      false
    else
      unsafe_sub_equal str 0 prefix 0

  let make len c=
    implode (Array.to_list (Array.make len c))

  let ends_with ~suffix str=
    Zed_utf8.ends_with str suffix

  module Buf0 = struct
    type buf= Buffer.t

    let create n= Buffer.create n

    let contents b= Buffer.contents b

    let clear b= Buffer.clear b

    let reset b= Buffer.reset b

    let length b= length (contents b)

    let add_zChar b zChar=
      Buffer.add_string b (Zed_char.to_utf8 zChar)

    let add_uChar b uChar=
      Buffer.add_string b (Zed_utf8.singleton uChar)

    let add_string b s= Buffer.add_string b s

    let add_buffer b1 b2= Buffer.add_buffer b1 b2
  end
end

include Zed_string0
module Buf = Buf0

