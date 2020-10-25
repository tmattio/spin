open Ctypes

module Def (F : Cstubs.FOREIGN) = struct
  open F

  let printf = F.foreign "printf" (string @-> returning void)
end
