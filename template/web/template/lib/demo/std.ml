include StdLabels

module Option = struct
  include Option

  module Infix = struct
    let ( >>| ) t f = map f t

    let ( >>= ) t f = bind t f
  end

  module Syntax = struct
    open Infix

    let ( let+ ) = ( >>| )

    let ( let* ) = ( >>= )

    let ( and+ ) a b =
      a >>= fun a ->
      b >>| fun b -> a, b
  end
end

module Result = struct
  include Result

  module Infix = struct
    let ( >>| ) t f = map f t

    let ( >>= ) t f = bind t f
  end

  module Syntax = struct
    open Infix

    let ( let+ ) = ( >>| )

    let ( let* ) = ( >>= )

    let ( and+ ) a b =
      a >>= fun a ->
      b >>| fun b -> a, b
  end
end
