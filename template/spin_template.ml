module type Template = sig
  val name : string

  val file_list : string list

  val read : string -> string option
end

module Bs_react : Template = struct
  include Bs_react

  let name = "bs-react"
end

module Cli : Template = struct
  include Cli

  let name = "cli"
end

module Lib : Template = struct
  include Lib

  let name = "lib"
end

module Bin : Template = struct
  include Bin

  let name = "bin"
end

module Ppx : Template = struct
  include Ppx

  let name = "ppx"
end

let all : (module Template) list =
  [ (module Bs_react)
  ; (module Cli)
  ; (module Lib)
  ; (module Bin)
  ; (module Ppx)
  ]
