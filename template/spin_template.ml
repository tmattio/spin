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

module Ppx_deriver : Template = struct
  include Ppx_deriver

  let name = "ppx-deriver"
end

module Ppx_rewriter : Template = struct
  include Ppx_rewriter

  let name = "ppx-rewriter"
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
  ; (module Ppx_deriver)
  ; (module Ppx_rewriter)
  ; (module C_bindings)
  ; (module Js)
  ]
