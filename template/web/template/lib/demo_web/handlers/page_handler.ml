open Opium_kernel

let index req = Lwt.return @@ Response.of_html (Page_view.index ())
