open Opium_kernel
open Lwt.Syntax

let m =
  let filter handler req =
    let* res = handler req in
    let { Rock.Body.content; length } = res.Rock.Response.body in
    let headers =
      match length with
      | None ->
        Httpaf.Headers.add_unless_exists
          res.headers
          "Transfer-Encoding"
          "chunked"
      | Some l ->
        Httpaf.Headers.add_unless_exists
          res.headers
          "Content-Length"
          (Int64.to_string l)
    in
    Lwt.return { res with headers }
  in
  Rock.Middleware.create ~name:"Content length" ~filter
