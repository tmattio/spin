module type Template = sig
  val name : string

  val file_list : string list

  val read : string -> string option
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

module C_bindings : Template = struct
  include C_bindings

  let name = "c-bindings"
end

module Js : Template = struct
  include Js

  let name = "js"
end

let all : (module Template) list =
  [ (module Cli)
  ; (module Lib)
  ; (module Bin)
  ; (module Ppx)
  ; (module C_bindings)
  ; (module Js)
  ]
