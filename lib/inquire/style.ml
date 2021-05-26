include Ansi

type t =
  { qmark_icon : string
  ; qmark_format : Ansi.style list
  ; message_format : Ansi.style list
  ; error_icon : string
  ; error_format : Ansi.style list
  ; default_format : Ansi.style list
  ; option_icon_marked : string
  ; option_icon_unmarked : string
  ; pointer_icon : string
  }

let default =
  { qmark_icon = "?"
  ; qmark_format = [ Ansi.green ]
  ; message_format = [ Ansi.bold ]
  ; error_icon = "X"
  ; error_format = [ Ansi.red; Ansi.bold ]
  ; default_format = []
  ; option_icon_marked = "○"
  ; option_icon_unmarked = "●"
  ; pointer_icon = "»"
  }

let make
    ?qmark_icon
    ?qmark_format
    ?message_format
    ?error_icon
    ?error_format
    ?default_format
    ?option_icon_marked
    ?option_icon_unmarked
    ?pointer_icon
    ()
  =
  let qmark_icon = Option.value qmark_icon ~default:default.qmark_icon in
  let qmark_format = Option.value qmark_format ~default:default.qmark_format in
  let message_format =
    Option.value message_format ~default:default.message_format
  in
  let error_icon = Option.value error_icon ~default:default.error_icon in
  let error_format = Option.value error_format ~default:default.error_format in
  let default_format =
    Option.value default_format ~default:default.default_format
  in
  let option_icon_marked =
    Option.value option_icon_marked ~default:default.option_icon_marked
  in
  let option_icon_unmarked =
    Option.value option_icon_unmarked ~default:default.option_icon_unmarked
  in
  let pointer_icon = Option.value pointer_icon ~default:default.pointer_icon in
  { qmark_icon
  ; qmark_format
  ; message_format
  ; error_icon
  ; error_format
  ; default_format
  ; option_icon_marked
  ; option_icon_unmarked
  ; pointer_icon
  }
