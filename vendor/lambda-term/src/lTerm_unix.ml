(*
 * lTerm_unix.ml
 * -------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

open LTerm_key

let return, (>>=), (>|=) = Lwt.return, Lwt.(>>=), Lwt.(>|=)

external get_sigwinch : unit -> int option = "lt_unix_get_sigwinch"
external get_system_encoding : unit -> string = "lt_unix_get_system_encoding"

let sigwinch = get_sigwinch ()

(* Obtained by running the folliwing makefile in the "localedata"
   directory of the glibc:

   {[
     include SUPPORTED
     all:
             @echo $(SUPPORTED-LOCALES) | sed 's/ /\n/g' | awk -F/ '$$1 ~ /[.]/ { next; }; { print "  | \""$$1"\" -> \""$$2"\"" }'
   ]}
*)
let encoding_of_lang = function
  | "aa_DJ" -> "ISO-8859-1"
  | "aa_ER" -> "UTF-8"
  | "aa_ER@saaho" -> "UTF-8"
  | "aa_ET" -> "UTF-8"
  | "af_ZA" -> "ISO-8859-1"
  | "am_ET" -> "UTF-8"
  | "an_ES" -> "ISO-8859-15"
  | "ar_AE" -> "ISO-8859-6"
  | "ar_BH" -> "ISO-8859-6"
  | "ar_DZ" -> "ISO-8859-6"
  | "ar_EG" -> "ISO-8859-6"
  | "ar_IN" -> "UTF-8"
  | "ar_IQ" -> "ISO-8859-6"
  | "ar_JO" -> "ISO-8859-6"
  | "ar_KW" -> "ISO-8859-6"
  | "ar_LB" -> "ISO-8859-6"
  | "ar_LY" -> "ISO-8859-6"
  | "ar_MA" -> "ISO-8859-6"
  | "ar_OM" -> "ISO-8859-6"
  | "ar_QA" -> "ISO-8859-6"
  | "ar_SA" -> "ISO-8859-6"
  | "ar_SD" -> "ISO-8859-6"
  | "ar_SY" -> "ISO-8859-6"
  | "ar_TN" -> "ISO-8859-6"
  | "ar_YE" -> "ISO-8859-6"
  | "az_AZ" -> "UTF-8"
  | "as_IN" -> "UTF-8"
  | "ast_ES" -> "ISO-8859-15"
  | "be_BY" -> "CP1251"
  | "be_BY@latin" -> "UTF-8"
  | "bem_ZM" -> "UTF-8"
  | "ber_DZ" -> "UTF-8"
  | "ber_MA" -> "UTF-8"
  | "bg_BG" -> "CP1251"
  | "bn_BD" -> "UTF-8"
  | "bn_IN" -> "UTF-8"
  | "bo_CN" -> "UTF-8"
  | "bo_IN" -> "UTF-8"
  | "br_FR" -> "ISO-8859-1"
  | "br_FR@euro" -> "ISO-8859-15"
  | "bs_BA" -> "ISO-8859-2"
  | "byn_ER" -> "UTF-8"
  | "ca_AD" -> "ISO-8859-15"
  | "ca_ES" -> "ISO-8859-1"
  | "ca_ES@euro" -> "ISO-8859-15"
  | "ca_FR" -> "ISO-8859-15"
  | "ca_IT" -> "ISO-8859-15"
  | "crh_UA" -> "UTF-8"
  | "cs_CZ" -> "ISO-8859-2"
  | "csb_PL" -> "UTF-8"
  | "cv_RU" -> "UTF-8"
  | "cy_GB" -> "ISO-8859-14"
  | "da_DK" -> "ISO-8859-1"
  | "de_AT" -> "ISO-8859-1"
  | "de_AT@euro" -> "ISO-8859-15"
  | "de_BE" -> "ISO-8859-1"
  | "de_BE@euro" -> "ISO-8859-15"
  | "de_CH" -> "ISO-8859-1"
  | "de_DE" -> "ISO-8859-1"
  | "de_DE@euro" -> "ISO-8859-15"
  | "de_LU" -> "ISO-8859-1"
  | "de_LU@euro" -> "ISO-8859-15"
  | "dv_MV" -> "UTF-8"
  | "dz_BT" -> "UTF-8"
  | "el_GR" -> "ISO-8859-7"
  | "el_CY" -> "ISO-8859-7"
  | "en_AG" -> "UTF-8"
  | "en_AU" -> "ISO-8859-1"
  | "en_BW" -> "ISO-8859-1"
  | "en_CA" -> "ISO-8859-1"
  | "en_DK" -> "ISO-8859-1"
  | "en_GB" -> "ISO-8859-1"
  | "en_HK" -> "ISO-8859-1"
  | "en_IE" -> "ISO-8859-1"
  | "en_IE@euro" -> "ISO-8859-15"
  | "en_IN" -> "UTF-8"
  | "en_NG" -> "UTF-8"
  | "en_NZ" -> "ISO-8859-1"
  | "en_PH" -> "ISO-8859-1"
  | "en_SG" -> "ISO-8859-1"
  | "en_US" -> "ISO-8859-1"
  | "en_ZA" -> "ISO-8859-1"
  | "en_ZM" -> "UTF-8"
  | "en_ZW" -> "ISO-8859-1"
  | "es_AR" -> "ISO-8859-1"
  | "es_BO" -> "ISO-8859-1"
  | "es_CL" -> "ISO-8859-1"
  | "es_CO" -> "ISO-8859-1"
  | "es_CR" -> "ISO-8859-1"
  | "es_DO" -> "ISO-8859-1"
  | "es_EC" -> "ISO-8859-1"
  | "es_ES" -> "ISO-8859-1"
  | "es_ES@euro" -> "ISO-8859-15"
  | "es_GT" -> "ISO-8859-1"
  | "es_HN" -> "ISO-8859-1"
  | "es_MX" -> "ISO-8859-1"
  | "es_NI" -> "ISO-8859-1"
  | "es_PA" -> "ISO-8859-1"
  | "es_PE" -> "ISO-8859-1"
  | "es_PR" -> "ISO-8859-1"
  | "es_PY" -> "ISO-8859-1"
  | "es_SV" -> "ISO-8859-1"
  | "es_US" -> "ISO-8859-1"
  | "es_UY" -> "ISO-8859-1"
  | "es_VE" -> "ISO-8859-1"
  | "et_EE" -> "ISO-8859-1"
  | "eu_ES" -> "ISO-8859-1"
  | "eu_ES@euro" -> "ISO-8859-15"
  | "fa_IR" -> "UTF-8"
  | "ff_SN" -> "UTF-8"
  | "fi_FI" -> "ISO-8859-1"
  | "fi_FI@euro" -> "ISO-8859-15"
  | "fil_PH" -> "UTF-8"
  | "fo_FO" -> "ISO-8859-1"
  | "fr_BE" -> "ISO-8859-1"
  | "fr_BE@euro" -> "ISO-8859-15"
  | "fr_CA" -> "ISO-8859-1"
  | "fr_CH" -> "ISO-8859-1"
  | "fr_FR" -> "ISO-8859-1"
  | "fr_FR@euro" -> "ISO-8859-15"
  | "fr_LU" -> "ISO-8859-1"
  | "fr_LU@euro" -> "ISO-8859-15"
  | "fur_IT" -> "UTF-8"
  | "fy_NL" -> "UTF-8"
  | "fy_DE" -> "UTF-8"
  | "ga_IE" -> "ISO-8859-1"
  | "ga_IE@euro" -> "ISO-8859-15"
  | "gd_GB" -> "ISO-8859-15"
  | "gez_ER" -> "UTF-8"
  | "gez_ER@abegede" -> "UTF-8"
  | "gez_ET" -> "UTF-8"
  | "gez_ET@abegede" -> "UTF-8"
  | "gl_ES" -> "ISO-8859-1"
  | "gl_ES@euro" -> "ISO-8859-15"
  | "gu_IN" -> "UTF-8"
  | "gv_GB" -> "ISO-8859-1"
  | "ha_NG" -> "UTF-8"
  | "he_IL" -> "ISO-8859-8"
  | "hi_IN" -> "UTF-8"
  | "hne_IN" -> "UTF-8"
  | "hr_HR" -> "ISO-8859-2"
  | "hsb_DE" -> "ISO-8859-2"
  | "ht_HT" -> "UTF-8"
  | "hu_HU" -> "ISO-8859-2"
  | "hy_AM" -> "UTF-8"
  | "id_ID" -> "ISO-8859-1"
  | "ig_NG" -> "UTF-8"
  | "ik_CA" -> "UTF-8"
  | "is_IS" -> "ISO-8859-1"
  | "it_CH" -> "ISO-8859-1"
  | "it_IT" -> "ISO-8859-1"
  | "it_IT@euro" -> "ISO-8859-15"
  | "iu_CA" -> "UTF-8"
  | "iw_IL" -> "ISO-8859-8"
  | "ka_GE" -> "GEORGIAN-PS"
  | "kk_KZ" -> "PT154"
  | "kl_GL" -> "ISO-8859-1"
  | "km_KH" -> "UTF-8"
  | "kn_IN" -> "UTF-8"
  | "kok_IN" -> "UTF-8"
  | "ks_IN" -> "UTF-8"
  | "ks_IN@devanagari" -> "UTF-8"
  | "ku_TR" -> "ISO-8859-9"
  | "kw_GB" -> "ISO-8859-1"
  | "ky_KG" -> "UTF-8"
  | "lb_LU" -> "UTF-8"
  | "lg_UG" -> "ISO-8859-10"
  | "li_BE" -> "UTF-8"
  | "li_NL" -> "UTF-8"
  | "lij_IT" -> "UTF-8"
  | "lo_LA" -> "UTF-8"
  | "lt_LT" -> "ISO-8859-13"
  | "lv_LV" -> "ISO-8859-13"
  | "mai_IN" -> "UTF-8"
  | "mg_MG" -> "ISO-8859-15"
  | "mhr_RU" -> "UTF-8"
  | "mi_NZ" -> "ISO-8859-13"
  | "mk_MK" -> "ISO-8859-5"
  | "ml_IN" -> "UTF-8"
  | "mn_MN" -> "UTF-8"
  | "mr_IN" -> "UTF-8"
  | "ms_MY" -> "ISO-8859-1"
  | "mt_MT" -> "ISO-8859-3"
  | "my_MM" -> "UTF-8"
  | "nan_TW@latin" -> "UTF-8"
  | "nb_NO" -> "ISO-8859-1"
  | "nds_DE" -> "UTF-8"
  | "nds_NL" -> "UTF-8"
  | "ne_NP" -> "UTF-8"
  | "nl_AW" -> "UTF-8"
  | "nl_BE" -> "ISO-8859-1"
  | "nl_BE@euro" -> "ISO-8859-15"
  | "nl_NL" -> "ISO-8859-1"
  | "nl_NL@euro" -> "ISO-8859-15"
  | "nn_NO" -> "ISO-8859-1"
  | "nr_ZA" -> "UTF-8"
  | "nso_ZA" -> "UTF-8"
  | "oc_FR" -> "ISO-8859-1"
  | "om_ET" -> "UTF-8"
  | "om_KE" -> "ISO-8859-1"
  | "or_IN" -> "UTF-8"
  | "os_RU" -> "UTF-8"
  | "pa_IN" -> "UTF-8"
  | "pa_PK" -> "UTF-8"
  | "pap_AN" -> "UTF-8"
  | "pl_PL" -> "ISO-8859-2"
  | "ps_AF" -> "UTF-8"
  | "pt_BR" -> "ISO-8859-1"
  | "pt_PT" -> "ISO-8859-1"
  | "pt_PT@euro" -> "ISO-8859-15"
  | "ro_RO" -> "ISO-8859-2"
  | "ru_RU" -> "ISO-8859-5"
  | "ru_UA" -> "KOI8-U"
  | "rw_RW" -> "UTF-8"
  | "sa_IN" -> "UTF-8"
  | "sc_IT" -> "UTF-8"
  | "sd_IN" -> "UTF-8"
  | "sd_IN@devanagari" -> "UTF-8"
  | "se_NO" -> "UTF-8"
  | "shs_CA" -> "UTF-8"
  | "si_LK" -> "UTF-8"
  | "sid_ET" -> "UTF-8"
  | "sk_SK" -> "ISO-8859-2"
  | "sl_SI" -> "ISO-8859-2"
  | "so_DJ" -> "ISO-8859-1"
  | "so_ET" -> "UTF-8"
  | "so_KE" -> "ISO-8859-1"
  | "so_SO" -> "ISO-8859-1"
  | "sq_AL" -> "ISO-8859-1"
  | "sq_MK" -> "UTF-8"
  | "sr_ME" -> "UTF-8"
  | "sr_RS" -> "UTF-8"
  | "sr_RS@latin" -> "UTF-8"
  | "ss_ZA" -> "UTF-8"
  | "st_ZA" -> "ISO-8859-1"
  | "sv_FI" -> "ISO-8859-1"
  | "sv_FI@euro" -> "ISO-8859-15"
  | "sv_SE" -> "ISO-8859-1"
  | "sw_KE" -> "UTF-8"
  | "sw_TZ" -> "UTF-8"
  | "ta_IN" -> "UTF-8"
  | "te_IN" -> "UTF-8"
  | "tg_TJ" -> "KOI8-T"
  | "th_TH" -> "TIS-620"
  | "ti_ER" -> "UTF-8"
  | "ti_ET" -> "UTF-8"
  | "tig_ER" -> "UTF-8"
  | "tk_TM" -> "UTF-8"
  | "tl_PH" -> "ISO-8859-1"
  | "tn_ZA" -> "UTF-8"
  | "tr_CY" -> "ISO-8859-9"
  | "tr_TR" -> "ISO-8859-9"
  | "ts_ZA" -> "UTF-8"
  | "tt_RU" -> "UTF-8"
  | "tt_RU@iqtelif" -> "UTF-8"
  | "ug_CN" -> "UTF-8"
  | "uk_UA" -> "KOI8-U"
  | "ur_PK" -> "UTF-8"
  | "uz_UZ" -> "ISO-8859-1"
  | "uz_UZ@cyrillic" -> "UTF-8"
  | "ve_ZA" -> "UTF-8"
  | "vi_VN" -> "UTF-8"
  | "wa_BE" -> "ISO-8859-1"
  | "wa_BE@euro" -> "ISO-8859-15"
  | "wae_CH" -> "UTF-8"
  | "wo_SN" -> "UTF-8"
  | "xh_ZA" -> "ISO-8859-1"
  | "yi_US" -> "CP1255"
  | "yo_NG" -> "UTF-8"
  | "yue_HK" -> "UTF-8"
  | "zh_CN" -> "GB2312"
  | "zh_HK" -> "BIG5-HKSCS"
  | "zh_SG" -> "GB2312"
  | "zh_TW" -> "BIG5"
  | "zu_ZA" -> "ISO-8859-1"
  | _ -> "ASCII"

let system_encoding =
  match get_system_encoding () with
    | "" -> begin
        match try Some (Sys.getenv "LANG") with Not_found -> None with
          | None ->
              "ASCII"
          | Some lang ->
              match try Some (String.index lang '.') with Not_found -> None with
                | None ->
                    encoding_of_lang lang
                | Some idx ->
                    String.sub lang (idx + 1) (String.length lang - idx - 1)
      end
    | enc ->
        enc

(* +-----------------------------------------------------------------+
   | Parsing of encoded characters                                   |
   +-----------------------------------------------------------------+ *)

let parse_char st first_byte =
  let open Lwt in
  let cp1= int_of_char first_byte in
  let parse st=
    match first_byte with
    | '\x00' .. '\x7f'-> return (Uchar.of_int cp1)
    | '\xc0' .. '\xdf'-> Lwt_stream.next st >|= int_of_char >>= fun cp2->
      return @@ Uchar.of_int
        (((cp1 land 0x1f) lsl 6) lor (cp2 land 0x3f))
    | '\xe0' .. '\xef'->
      Lwt_stream.next st >|= int_of_char >>= fun cp2->
      Lwt_stream.next st >|= int_of_char >>= fun cp3->
      return @@ Uchar.of_int
        (((cp1 land 0x0f) lsl 12)
        lor ((cp2 land 0x3f) lsl 6)
        lor (cp3 land 0x3f))
    | '\xf0' .. '\xf7'->
      Lwt_stream.next st >|= int_of_char >>= fun cp2->
      Lwt_stream.next st >|= int_of_char >>= fun cp3->
      Lwt_stream.next st >|= int_of_char >>= fun cp4->
      return @@ Uchar.of_int
        (((cp1 land 0x07) lsl 18)
        lor ((cp2 land 0x3f) lsl 12)
        lor ((cp3 land 0x3f) lsl 6)
        lor (cp4 land 0x3f))
    | _-> assert false
  in
  Lwt.catch
    (fun () -> Lwt_stream.parse st parse)
    (function
    | Lwt_stream.Empty ->
        return (Uchar.of_char first_byte)
    | exn -> Lwt.fail exn)

(* +-----------------------------------------------------------------+
   | Input of escape sequence                                        |
   +-----------------------------------------------------------------+ *)

exception Not_a_sequence

let parse_escape escape_time st =
  let buf = Buffer.create 32 in
  (* Read one character and add it to [buf]: *)
  let get () =
    Lwt.pick [Lwt_stream.get st; Lwt_unix.sleep escape_time >>= fun () -> return None] >>= fun ch ->
    match ch with
      | None ->
          (* If the rest is not immediatly available, conclude that
             this is not an escape sequence but just the escape
             key: *)
          Lwt.fail Not_a_sequence
      | Some('\x00' .. '\x1f' | '\x80' .. '\xff') ->
          (* Control characters and non-ascii characters are not part
             of escape sequences. *)
          Lwt.fail Not_a_sequence
      | Some ch ->
          Buffer.add_char buf ch;
          return ch
  in

  let rec loop () =
    get () >>= function
      | '0' .. '9' | ';' | '[' ->
          loop ()
      | _ ->
          return (Buffer.contents buf)
  in

  get () >>= function
    | '[' | 'O' ->
        loop ()
    | _ ->
        Lwt.fail Not_a_sequence

(* +-----------------------------------------------------------------+
   | Escape sequences mapping                                        |
   +-----------------------------------------------------------------+ *)

let controls = [|
  Char(Uchar.of_char ' ');
  Char(Uchar.of_char 'a');
  Char(Uchar.of_char 'b');
  Char(Uchar.of_char 'c');
  Char(Uchar.of_char 'd');
  Char(Uchar.of_char 'e');
  Char(Uchar.of_char 'f');
  Char(Uchar.of_char 'g');
  Char(Uchar.of_char 'h');
  Tab;
  Enter;
  Char(Uchar.of_char 'k');
  Char(Uchar.of_char 'l');
  Char(Uchar.of_char 'm');
  Char(Uchar.of_char 'n');
  Char(Uchar.of_char 'o');
  Char(Uchar.of_char 'p');
  Char(Uchar.of_char 'q');
  Char(Uchar.of_char 'r');
  Char(Uchar.of_char 's');
  Char(Uchar.of_char 't');
  Char(Uchar.of_char 'u');
  Char(Uchar.of_char 'v');
  Char(Uchar.of_char 'w');
  Char(Uchar.of_char 'x');
  Char(Uchar.of_char 'y');
  Char(Uchar.of_char 'z');
  Escape;
  Char(Uchar.of_char '\\');
  Char(Uchar.of_char ']');
  Char(Uchar.of_char '^');
  Char(Uchar.of_char '_');
|]

let sequences = [|
  "[1~", { control = false; meta = false; shift = false; code = Home };
  "[2~", { control = false; meta = false; shift = false; code = Insert };
  "[3~", { control = false; meta = false; shift = false; code = Delete };
  "[4~", { control = false; meta = false; shift = false; code = End };
  "[5~", { control = false; meta = false; shift = false; code = Prev_page };
  "[6~", { control = false; meta = false; shift = false; code = Next_page };
  "[7~", { control = false; meta = false; shift = false; code = Home };
  "[8~", { control = false; meta = false; shift = false; code = End };
  "[11~", { control = false; meta = false; shift = false; code = F1 };
  "[12~", { control = false; meta = false; shift = false; code = F2 };
  "[13~", { control = false; meta = false; shift = false; code = F3 };
  "[14~", { control = false; meta = false; shift = false; code = F4 };
  "[15~", { control = false; meta = false; shift = false; code = F5 };
  "[17~", { control = false; meta = false; shift = false; code = F6 };
  "[18~", { control = false; meta = false; shift = false; code = F7 };
  "[19~", { control = false; meta = false; shift = false; code = F8 };
  "[20~", { control = false; meta = false; shift = false; code = F9 };
  "[21~", { control = false; meta = false; shift = false; code = F10 };
  "[23~", { control = false; meta = false; shift = false; code = F11 };
  "[24~", { control = false; meta = false; shift = false; code = F12 };

  "[1^", { control = true; meta = false; shift = false; code = Home };
  "[2^", { control = true; meta = false; shift = false; code = Insert };
  "[3^", { control = true; meta = false; shift = false; code = Delete };
  "[4^", { control = true; meta = false; shift = false; code = End };
  "[5^", { control = true; meta = false; shift = false; code = Prev_page };
  "[6^", { control = true; meta = false; shift = false; code = Next_page };
  "[7^", { control = true; meta = false; shift = false; code = Home };
  "[8^", { control = true; meta = false; shift = false; code = End };
  "[11^", { control = true; meta = false; shift = false; code = F1 };
  "[12^", { control = true; meta = false; shift = false; code = F2 };
  "[13^", { control = true; meta = false; shift = false; code = F3 };
  "[14^", { control = true; meta = false; shift = false; code = F4 };
  "[15^", { control = true; meta = false; shift = false; code = F5 };
  "[17^", { control = true; meta = false; shift = false; code = F6 };
  "[18^", { control = true; meta = false; shift = false; code = F7 };
  "[19^", { control = true; meta = false; shift = false; code = F8 };
  "[20^", { control = true; meta = false; shift = false; code = F9 };
  "[21^", { control = true; meta = false; shift = false; code = F10 };
  "[23^", { control = true; meta = false; shift = false; code = F11 };
  "[24^", { control = true; meta = false; shift = false; code = F12 };

  "[1$", { control = false; meta = false; shift = true; code = Home };
  "[2$", { control = false; meta = false; shift = true; code = Insert };
  "[3$", { control = false; meta = false; shift = true; code = Delete };
  "[4$", { control = false; meta = false; shift = true; code = End };
  "[5$", { control = false; meta = false; shift = true; code = Prev_page };
  "[6$", { control = false; meta = false; shift = true; code = Next_page };
  "[7$", { control = false; meta = false; shift = true; code = Home };
  "[8$", { control = false; meta = false; shift = true; code = End };

  "[1@", { control = true; meta = false; shift = true; code = Home };
  "[2@", { control = true; meta = false; shift = true; code = Insert };
  "[3@", { control = true; meta = false; shift = true; code = Delete };
  "[4@", { control = true; meta = false; shift = true; code = End };
  "[5@", { control = true; meta = false; shift = true; code = Prev_page };
  "[6@", { control = true; meta = false; shift = true; code = Next_page };
  "[7@", { control = true; meta = false; shift = true; code = Home };
  "[8@", { control = true; meta = false; shift = true; code = End };

  "[25~", { control = false; meta = false; shift = true; code = F3 };
  "[26~", { control = false; meta = false; shift = true; code = F4 };
  "[28~", { control = false; meta = false; shift = true; code = F5 };
  "[29~", { control = false; meta = false; shift = true; code = F6 };
  "[31~", { control = false; meta = false; shift = true; code = F7 };
  "[32~", { control = false; meta = false; shift = true; code = F8 };
  "[33~", { control = false; meta = false; shift = true; code = F9 };
  "[34~", { control = false; meta = false; shift = true; code = F10 };
  "[23$", { control = false; meta = false; shift = true; code = F11 };
  "[24$", { control = false; meta = false; shift = true; code = F12 };

  "[25^", { control = true; meta = false; shift = true; code = F3 };
  "[26^", { control = true; meta = false; shift = true; code = F4 };
  "[28^", { control = true; meta = false; shift = true; code = F5 };
  "[29^", { control = true; meta = false; shift = true; code = F6 };
  "[31^", { control = true; meta = false; shift = true; code = F7 };
  "[32^", { control = true; meta = false; shift = true; code = F8 };
  "[33^", { control = true; meta = false; shift = true; code = F9 };
  "[34^", { control = true; meta = false; shift = true; code = F10 };
  "[23@", { control = true; meta = false; shift = true; code = F11 };
  "[24@", { control = true; meta = false; shift = true; code = F12 };

  "[Z", { control = false; meta = false; shift = true; code = Tab };

  "[A", { control = false; meta = false; shift = false; code = Up };
  "[B", { control = false; meta = false; shift = false; code = Down };
  "[C", { control = false; meta = false; shift = false; code = Right };
  "[D", { control = false; meta = false; shift = false; code = Left };

  "[a", { control = false; meta = false; shift = true; code = Up };
  "[b", { control = false; meta = false; shift = true; code = Down };
  "[c", { control = false; meta = false; shift = true; code = Right };
  "[d", { control = false; meta = false; shift = true; code = Left };

  "A", { control = false; meta = false; shift = false; code = Up };
  "B", { control = false; meta = false; shift = false; code = Down };
  "C", { control = false; meta = false; shift = false; code = Right };
  "D", { control = false; meta = false; shift = false; code = Left };

  "OA", { control = false; meta = false; shift = false; code = Up };
  "OB", { control = false; meta = false; shift = false; code = Down };
  "OC", { control = false; meta = false; shift = false; code = Right };
  "OD", { control = false; meta = false; shift = false; code = Left };

  "Oa", { control = true; meta = false; shift = false; code = Up };
  "Ob", { control = true; meta = false; shift = false; code = Down };
  "Oc", { control = true; meta = false; shift = false; code = Right };
  "Od", { control = true; meta = false; shift = false; code = Left };

  "OP", { control = false; meta = false; shift = false; code = F1 };
  "OQ", { control = false; meta = false; shift = false; code = F2 };
  "OR", { control = false; meta = false; shift = false; code = F3 };
  "OS", { control = false; meta = false; shift = false; code = F4 };

  "O2P", { control = false; meta = false; shift = true; code = F1 };
  "O2Q", { control = false; meta = false; shift = true; code = F2 };
  "O2R", { control = false; meta = false; shift = true; code = F3 };
  "O2S", { control = false; meta = false; shift = true; code = F4 };

  "O3P", { control = false; meta = true; shift = false; code = F1 };
  "O3Q", { control = false; meta = true; shift = false; code = F2 };
  "O3R", { control = false; meta = true; shift = false; code = F3 };
  "O3S", { control = false; meta = true; shift = false; code = F4 };

  "O4P", { control = false; meta = true; shift = true; code = F1 };
  "O4Q", { control = false; meta = true; shift = true; code = F2 };
  "O4R", { control = false; meta = true; shift = true; code = F3 };
  "O4S", { control = false; meta = true; shift = true; code = F4 };

  "O5P", { control = true; meta = false; shift = false; code = F1 };
  "O5Q", { control = true; meta = false; shift = false; code = F2 };
  "O5R", { control = true; meta = false; shift = false; code = F3 };
  "O5S", { control = true; meta = false; shift = false; code = F4 };

  "O6P", { control = true; meta = false; shift = true; code = F1 };
  "O6Q", { control = true; meta = false; shift = true; code = F2 };
  "O6R", { control = true; meta = false; shift = true; code = F3 };
  "O6S", { control = true; meta = false; shift = true; code = F4 };

  "O7P", { control = true; meta = true; shift = false; code = F1 };
  "O7Q", { control = true; meta = true; shift = false; code = F2 };
  "O7R", { control = true; meta = true; shift = false; code = F3 };
  "O7S", { control = true; meta = true; shift = false; code = F4 };

  "O8P", { control = true; meta = true; shift = true; code = F1 };
  "O8Q", { control = true; meta = true; shift = true; code = F2 };
  "O8R", { control = true; meta = true; shift = true; code = F3 };
  "O8S", { control = true; meta = true; shift = true; code = F4 };

  "[[A", { control = false; meta = false; shift = false; code = F1 };
  "[[B", { control = false; meta = false; shift = false; code = F2 };
  "[[C", { control = false; meta = false; shift = false; code = F3 };
  "[[D", { control = false; meta = false; shift = false; code = F4 };
  "[[E", { control = false; meta = false; shift = false; code = F5 };

  "[H", { control = false; meta = false; shift = false; code = Home };
  "[F", { control = false; meta = false; shift = false; code = End };

  "OH", { control = false; meta = false; shift = false; code = Home };
  "OF", { control = false; meta = false; shift = false; code = End };

  "H", { control = false; meta = false; shift = false; code = Home };
  "F", { control = false; meta = false; shift = false; code = End };

  "[1;2A", { control = false; meta = false; shift = true; code = Up };
  "[1;2B", { control = false; meta = false; shift = true; code = Down };
  "[1;2C", { control = false; meta = false; shift = true; code = Right };
  "[1;2D", { control = false; meta = false; shift = true; code = Left };

  "[1;3A", { control = false; meta = true; shift = false; code = Up };
  "[1;3B", { control = false; meta = true; shift = false; code = Down };
  "[1;3C", { control = false; meta = true; shift = false; code = Right };
  "[1;3D", { control = false; meta = true; shift = false; code = Left };

  "[1;4A", { control = false; meta = true; shift = true; code = Up };
  "[1;4B", { control = false; meta = true; shift = true; code = Down };
  "[1;4C", { control = false; meta = true; shift = true; code = Right };
  "[1;4D", { control = false; meta = true; shift = true; code = Left };

  "[1;5A", { control = true; meta = false; shift = false; code = Up };
  "[1;5B", { control = true; meta = false; shift = false; code = Down };
  "[1;5C", { control = true; meta = false; shift = false; code = Right };
  "[1;5D", { control = true; meta = false; shift = false; code = Left };

  "[1;6A", { control = true; meta = false; shift = true; code = Up };
  "[1;6B", { control = true; meta = false; shift = true; code = Down };
  "[1;6C", { control = true; meta = false; shift = true; code = Right };
  "[1;6D", { control = true; meta = false; shift = true; code = Left };

  "[1;7A", { control = true; meta = true; shift = false; code = Up };
  "[1;7B", { control = true; meta = true; shift = false; code = Down };
  "[1;7C", { control = true; meta = true; shift = false; code = Right };
  "[1;7D", { control = true; meta = true; shift = false; code = Left };

  "[1;8A", { control = true; meta = true; shift = true; code = Up };
  "[1;8B", { control = true; meta = true; shift = true; code = Down };
  "[1;8C", { control = true; meta = true; shift = true; code = Right };
  "[1;8D", { control = true; meta = true; shift = true; code = Left };

  "[1;2P", { control = false; meta = false; shift = true; code = F1 };
  "[1;2Q", { control = false; meta = false; shift = true; code = F2 };
  "[1;2R", { control = false; meta = false; shift = true; code = F3 };
  "[1;2S", { control = false; meta = false; shift = true; code = F4 };

  "[1;3P", { control = false; meta = true; shift = false; code = F1 };
  "[1;3Q", { control = false; meta = true; shift = false; code = F2 };
  "[1;3R", { control = false; meta = true; shift = false; code = F3 };
  "[1;3S", { control = false; meta = true; shift = false; code = F4 };

  "[1;4P", { control = false; meta = true; shift = true; code = F1 };
  "[1;4Q", { control = false; meta = true; shift = true; code = F2 };
  "[1;4R", { control = false; meta = true; shift = true; code = F3 };
  "[1;4S", { control = false; meta = true; shift = true; code = F4 };

  "[1;5P", { control = true; meta = false; shift = false; code = F1 };
  "[1;5Q", { control = true; meta = false; shift = false; code = F2 };
  "[1;5R", { control = true; meta = false; shift = false; code = F3 };
  "[1;5S", { control = true; meta = false; shift = false; code = F4 };

  "[1;6P", { control = true; meta = false; shift = true; code = F1 };
  "[1;6Q", { control = true; meta = false; shift = true; code = F2 };
  "[1;6R", { control = true; meta = false; shift = true; code = F3 };
  "[1;6S", { control = true; meta = false; shift = true; code = F4 };

  "[1;7P", { control = true; meta = true; shift = false; code = F1 };
  "[1;7Q", { control = true; meta = true; shift = false; code = F2 };
  "[1;7R", { control = true; meta = true; shift = false; code = F3 };
  "[1;7S", { control = true; meta = true; shift = false; code = F4 };

  "[1;8P", { control = true; meta = true; shift = true; code = F1 };
  "[1;8Q", { control = true; meta = true; shift = true; code = F2 };
  "[1;8R", { control = true; meta = true; shift = true; code = F3 };
  "[1;8S", { control = true; meta = true; shift = true; code = F4 };

  "O1;2P", { control = false; meta = false; shift = true; code = F1 };
  "O1;2Q", { control = false; meta = false; shift = true; code = F2 };
  "O1;2R", { control = false; meta = false; shift = true; code = F3 };
  "O1;2S", { control = false; meta = false; shift = true; code = F4 };

  "O1;3P", { control = false; meta = true; shift = false; code = F1 };
  "O1;3Q", { control = false; meta = true; shift = false; code = F2 };
  "O1;3R", { control = false; meta = true; shift = false; code = F3 };
  "O1;3S", { control = false; meta = true; shift = false; code = F4 };

  "O1;4P", { control = false; meta = true; shift = true; code = F1 };
  "O1;4Q", { control = false; meta = true; shift = true; code = F2 };
  "O1;4R", { control = false; meta = true; shift = true; code = F3 };
  "O1;4S", { control = false; meta = true; shift = true; code = F4 };

  "O1;5P", { control = true; meta = false; shift = false; code = F1 };
  "O1;5Q", { control = true; meta = false; shift = false; code = F2 };
  "O1;5R", { control = true; meta = false; shift = false; code = F3 };
  "O1;5S", { control = true; meta = false; shift = false; code = F4 };

  "O1;6P", { control = true; meta = false; shift = true; code = F1 };
  "O1;6Q", { control = true; meta = false; shift = true; code = F2 };
  "O1;6R", { control = true; meta = false; shift = true; code = F3 };
  "O1;6S", { control = true; meta = false; shift = true; code = F4 };

  "O1;7P", { control = true; meta = true; shift = false; code = F1 };
  "O1;7Q", { control = true; meta = true; shift = false; code = F2 };
  "O1;7R", { control = true; meta = true; shift = false; code = F3 };
  "O1;7S", { control = true; meta = true; shift = false; code = F4 };

  "O1;8P", { control = true; meta = true; shift = true; code = F1 };
  "O1;8Q", { control = true; meta = true; shift = true; code = F2 };
  "O1;8R", { control = true; meta = true; shift = true; code = F3 };
  "O1;8S", { control = true; meta = true; shift = true; code = F4 };

  "[15;2~", { control = false; meta = false; shift = true; code = F5 };
  "[17;2~", { control = false; meta = false; shift = true; code = F6 };
  "[18;2~", { control = false; meta = false; shift = true; code = F7 };
  "[19;2~", { control = false; meta = false; shift = true; code = F8 };
  "[20;2~", { control = false; meta = false; shift = true; code = F9 };
  "[21;2~", { control = false; meta = false; shift = true; code = F10 };
  "[23;2~", { control = false; meta = false; shift = true; code = F11 };
  "[24;2~", { control = false; meta = false; shift = true; code = F12 };

  "[15;3~", { control = false; meta = true; shift = false; code = F5 };
  "[17;3~", { control = false; meta = true; shift = false; code = F6 };
  "[18;3~", { control = false; meta = true; shift = false; code = F7 };
  "[19;3~", { control = false; meta = true; shift = false; code = F8 };
  "[20;3~", { control = false; meta = true; shift = false; code = F9 };
  "[21;3~", { control = false; meta = true; shift = false; code = F10 };
  "[23;3~", { control = false; meta = true; shift = false; code = F11 };
  "[24;3~", { control = false; meta = true; shift = false; code = F12 };

  "[15;4~", { control = false; meta = true; shift = true; code = F5 };
  "[17;4~", { control = false; meta = true; shift = true; code = F6 };
  "[18;4~", { control = false; meta = true; shift = true; code = F7 };
  "[19;4~", { control = false; meta = true; shift = true; code = F8 };
  "[20;4~", { control = false; meta = true; shift = true; code = F9 };
  "[21;4~", { control = false; meta = true; shift = true; code = F10 };
  "[23;4~", { control = false; meta = true; shift = true; code = F11 };
  "[24;4~", { control = false; meta = true; shift = true; code = F12 };

  "[15;5~", { control = true; meta = false; shift = false; code = F5 };
  "[17;5~", { control = true; meta = false; shift = false; code = F6 };
  "[18;5~", { control = true; meta = false; shift = false; code = F7 };
  "[19;5~", { control = true; meta = false; shift = false; code = F8 };
  "[20;5~", { control = true; meta = false; shift = false; code = F9 };
  "[21;5~", { control = true; meta = false; shift = false; code = F10 };
  "[23;5~", { control = true; meta = false; shift = false; code = F11 };
  "[24;5~", { control = true; meta = false; shift = false; code = F12 };

  "[15;6~", { control = true; meta = false; shift = true; code = F5 };
  "[17;6~", { control = true; meta = false; shift = true; code = F6 };
  "[18;6~", { control = true; meta = false; shift = true; code = F7 };
  "[19;6~", { control = true; meta = false; shift = true; code = F8 };
  "[20;6~", { control = true; meta = false; shift = true; code = F9 };
  "[21;6~", { control = true; meta = false; shift = true; code = F10 };
  "[23;6~", { control = true; meta = false; shift = true; code = F11 };
  "[24;6~", { control = true; meta = false; shift = true; code = F12 };

  "[15;7~", { control = true; meta = true; shift = false; code = F5 };
  "[17;7~", { control = true; meta = true; shift = false; code = F6 };
  "[18;7~", { control = true; meta = true; shift = false; code = F7 };
  "[19;7~", { control = true; meta = true; shift = false; code = F8 };
  "[20;7~", { control = true; meta = true; shift = false; code = F9 };
  "[21;7~", { control = true; meta = true; shift = false; code = F10 };
  "[23;7~", { control = true; meta = true; shift = false; code = F11 };
  "[24;7~", { control = true; meta = true; shift = false; code = F12 };

  "[15;8~", { control = true; meta = true; shift = true; code = F5 };
  "[17;8~", { control = true; meta = true; shift = true; code = F6 };
  "[18;8~", { control = true; meta = true; shift = true; code = F7 };
  "[19;8~", { control = true; meta = true; shift = true; code = F8 };
  "[20;8~", { control = true; meta = true; shift = true; code = F9 };
  "[21;8~", { control = true; meta = true; shift = true; code = F10 };
  "[23;8~", { control = true; meta = true; shift = true; code = F11 };
  "[24;8~", { control = true; meta = true; shift = true; code = F12 };

  "[1;2H", { control = false; meta = false; shift = true; code = Home };
  "[1;2F", { control = false; meta = false; shift = true; code = End };

  "[1;3H", { control = false; meta = true; shift = false; code = Home };
  "[1;3F", { control = false; meta = true; shift = false; code = End };

  "[1;4H", { control = false; meta = true; shift = true; code = Home };
  "[1;4F", { control = false; meta = true; shift = true; code = End };

  "[1;5H", { control = true; meta = false; shift = false; code = Home };
  "[1;5F", { control = true; meta = false; shift = false; code = End };

  "[1;6H", { control = true; meta = false; shift = true; code = Home };
  "[1;6F", { control = true; meta = false; shift = true; code = End };

  "[1;7H", { control = true; meta = true; shift = false; code = Home };
  "[1;7F", { control = true; meta = true; shift = false; code = End };

  "[1;8H", { control = true; meta = true; shift = true; code = Home };
  "[1;8F", { control = true; meta = true; shift = true; code = End };

  "[2;2~", { control = false; meta = false; shift = true; code = Insert };
  "[3;2~", { control = false; meta = false; shift = true; code = Delete };
  "[5;2~", { control = false; meta = false; shift = true; code = Prev_page };
  "[6;2~", { control = false; meta = false; shift = true; code = Next_page };

  "[2;3~", { control = false; meta = true; shift = false; code = Insert };
  "[3;3~", { control = false; meta = true; shift = false; code = Delete };
  "[5;3~", { control = false; meta = true; shift = false; code = Prev_page };
  "[6;3~", { control = false; meta = true; shift = false; code = Next_page };

  "[2;4~", { control = false; meta = true; shift = true; code = Insert };
  "[3;4~", { control = false; meta = true; shift = true; code = Delete };
  "[5;4~", { control = false; meta = true; shift = true; code = Prev_page };
  "[6;4~", { control = false; meta = true; shift = true; code = Next_page };

  "[2;5~", { control = true; meta = false; shift = false; code = Insert };
  "[3;5~", { control = true; meta = false; shift = false; code = Delete };
  "[5;5~", { control = true; meta = false; shift = false; code = Prev_page };
  "[6;5~", { control = true; meta = false; shift = false; code = Next_page };

  "[2;6~", { control = true; meta = false; shift = true; code = Insert };
  "[3;6~", { control = true; meta = false; shift = true; code = Delete };
  "[5;6~", { control = true; meta = false; shift = true; code = Prev_page };
  "[6;6~", { control = true; meta = false; shift = true; code = Next_page };

  "[2;7~", { control = true; meta = true; shift = false; code = Insert };
  "[3;7~", { control = true; meta = true; shift = false; code = Delete };
  "[5;7~", { control = true; meta = true; shift = false; code = Prev_page };
  "[6;7~", { control = true; meta = true; shift = false; code = Next_page };

  "[2;8~", { control = true; meta = true; shift = true; code = Insert };
  "[3;8~", { control = true; meta = true; shift = true; code = Delete };
  "[5;8~", { control = true; meta = true; shift = true; code = Prev_page };
  "[6;8~", { control = true; meta = true; shift = true; code = Next_page };

  (* iTerm2 *)
  "[1;9A", { control = false; meta = true; shift = false; code = Up };
  "[1;9B", { control = false; meta = true; shift = false; code = Down };
  "[1;9C", { control = false; meta = true; shift = false; code = Right };
  "[1;9D", { control = false; meta = true; shift = false; code = Left };
|]

let () = Array.sort (fun (seq1, _) (seq2, _) -> String.compare seq1 seq2) sequences

let find_sequence seq =
  let rec loop a b =
    if a = b then
      None
    else
      let c = (a + b) / 2 in
      let k, v = Array.unsafe_get sequences c in
      match String.compare seq k with
        | d when d < 0 ->
            loop a c
        | d when d > 0 ->
            loop (c + 1) b
        | _ ->
            Some v
  in
  loop 0 (Array.length sequences)

let rec parse_event ?(escape_time = 0.1) stream =
  Lwt_stream.next stream >>= fun byte ->
  match byte with
    | '\x1b' -> begin
        (* Escape sequences *)
        Lwt.catch (fun () ->
          (* Try to parse an escape seqsuence *)
          Lwt_stream.parse stream (parse_escape escape_time) >>= function
            | "[M" -> begin
                (* Mouse report *)
                let open LTerm_mouse in
                Lwt_stream.next stream >|= Char.code >>= fun mask ->
                Lwt_stream.next stream >|= Char.code >>= fun x ->
                Lwt_stream.next stream >|= Char.code >>= fun y ->
                try
                  if mask = 0b00100011 then raise Exit;
                  return (LTerm_event.Mouse {
                            control = mask land 0b00010000 <> 0;
                            meta = mask land 0b00001000 <> 0;
                            shift = false;
                            row = y - 33;
                            col = x - 33;
                            button =
                              (match mask land 0b11000111 with
                                 | 0b00000000 -> Button1
                                 | 0b00000001 -> Button2
                                 | 0b00000010 -> Button3
                                 | 0b01000000 -> Button4
                                 | 0b01000001 -> Button5
                                 | 0b01000010 -> Button6
                                 | 0b01000011 -> Button7
                                 | 0b01000100 -> Button8
                                 | 0b01000101 -> Button9
                                 | _ -> raise Exit);
                          })
                with Exit ->
                  parse_event stream
              end
            | seq ->
                match find_sequence seq with
                  | Some key ->
                      return (LTerm_event.Key key)
                  | None ->
                      return (LTerm_event.Sequence ("\x1b" ^ seq)))
          (function
          | Not_a_sequence -> begin
              (* If it is not, test if it is META+key. *)
              Lwt.pick [Lwt_stream.peek stream;
                        Lwt_unix.sleep escape_time >>= fun () -> return None] >>= fun ch ->
              match ch with
                | None ->
                    return (LTerm_event.Key { control = false; meta = false;
                                              shift = false; code = Escape })
                | Some byte -> begin
                    match byte with
                      | '\x1b' -> begin
                          (* Escape sequences *)
                          Lwt.catch (fun () ->
                            begin
                              Lwt_stream.parse stream
                                (fun stream ->
                                   Lwt_stream.junk stream >>= fun () ->
                                   Lwt.pick [Lwt_stream.peek stream;
                                             Lwt_unix.sleep escape_time >>= fun () -> return None]
                                             >>= fun ch ->
                                   match ch with
                                     | None ->
                                         Lwt.fail Not_a_sequence
                                     | Some _ ->
                                         parse_escape escape_time stream)
                            end >>= fun seq ->
                            match find_sequence seq with
                              | Some key ->
                                  return (LTerm_event.Key { key with meta = true })
                              | None ->
                                  return (LTerm_event.Sequence ("\x1b\x1b" ^ seq)))
                            (function
                            | Not_a_sequence ->
                                return (LTerm_event.Key { control = false; meta = false;
                                                          shift = false; code = Escape })
                            | exn -> Lwt.fail exn)
                        end
                      | '\x00' .. '\x1b' ->
                          (* Control characters *)
                          Lwt_stream.junk stream >>= fun () ->
                          let code = controls.(Char.code byte) in
                          return (LTerm_event.Key { control = (match code with Char _ -> true | _ -> false); meta = true; shift = false; code })
                      | '\x7f' ->
                          (* Backspace *)
                          Lwt_stream.junk stream >>= fun () ->
                          return (LTerm_event.Key { control = false; meta = true;
                                                    shift = false; code = Backspace })
                      | '\x00' .. '\x7f' ->
                          (* Other ascii characters *)
                          Lwt_stream.junk stream >>= fun () ->
                          return(LTerm_event.Key  { control = false; meta = true;
                                                    shift = false; code = Char(Uchar.of_char byte) })
                      | byte' ->
                          Lwt_stream.junk stream >>= fun () ->
                          parse_char stream byte' >>= fun code ->
                          return (LTerm_event.Key { control = false; meta = true;
                                                    shift = false; code = Char code })
                    end
            end
          | exn -> Lwt.fail exn)
      end
    | '\x00' .. '\x1f' ->
        (* Control characters *)
        let code = controls.(Char.code byte) in
        return (LTerm_event.Key { control = (match code with Char _ -> true | _ -> false); meta = false; shift = false; code })
    | '\x7f' ->
        (* Backspace *)
        return (LTerm_event.Key { control = false; meta = false;
                                  shift = false; code = Backspace })
    | '\x00' .. '\x7f' ->
        (* Other ascii characters *)
        return (LTerm_event.Key { control = false; meta = false;
                                  shift = false; code = Char(Uchar.of_char byte) })
    | _ ->
        (* Encoded characters *)
        parse_char stream byte >>= fun code ->
        return (LTerm_event.Key { control = false; meta = false;
                                  shift = false; code = Char code })
