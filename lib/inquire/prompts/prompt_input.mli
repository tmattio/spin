val prompt
  :  ?validate:(string -> (string, string) result)
  -> ?default:string
  -> ?style:Style.t
  -> string
  -> string
