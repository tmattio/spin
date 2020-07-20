open Opium_kernel
open Lwt.Syntax

let index req = Lwt.return @@ Helper.response_of_html (Page_view.index ())
