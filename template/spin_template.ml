module Cli : Spin.Template_intf.S = struct
  include Cli

  let name = "cli"
end

module Lib : Spin.Template_intf.S = struct
  include Lib

  let name = "lib"
end

module Bin : Spin.Template_intf.S = struct
  include Bin

  let name = "bin"
end

module Ppx : Spin.Template_intf.S = struct
  include Ppx

  let name = "ppx"
end

module C_bindings : Spin.Template_intf.S = struct
  include C_bindings

  let name = "c-bindings"
end

module Js : Spin.Template_intf.S = struct
  include Js

  let name = "js"
end

module Hello : Spin.Template_intf.S = struct
  include Hello

  let name = "hello"
end

let hello : (module Spin.Template_intf.S) = (module Hello)

let all : (module Spin.Template_intf.S) list =
  [ (module Cli)
  ; (module Lib)
  ; (module Bin)
  ; (module Ppx)
  ; (module C_bindings)
  ; (module Js)
  ]
