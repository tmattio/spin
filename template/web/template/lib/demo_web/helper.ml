let response_of_html
    ?version
    ?status
    ?reason
    ?(headers = Opium_kernel.Rock.Headers.empty)
    ?env
    body
  =
  let body =
    Format.asprintf "%a" (Tyxml.Html.pp ()) body
    |> Opium_kernel.Rock.Body.of_string
  in
  let headers =
    Opium_kernel.Rock.Headers.add_unless_exists
      headers
      "Content-Type"
      "text/html"
  in
  Opium_kernel.Rock.Response.make
    ?version
    ?status
    ?reason
    ~headers
    ~body
    ?env
    ()
