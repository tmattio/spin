let fallback ~status ~error () =
  let open Tyxml.Html in
  let title_ = error ^ " · Demo" in
  let code = Opium_kernel.Rock.Status.to_code status in
  html
    (head
       (title (txt title_))
       [ meta ~a:[ a_charset "utf-8" ] ()
       ; meta
           ~a:
             [ a_name "viewport"
             ; a_content "width=device-width, initial-scale=1"
             ]
           ()
       ; meta
           ~a:[ a_name "description"; a_content "{{ project_description }}" ]
           ()
       ; link ~rel:[ `Icon ] ~href:"/favicon.ico" ()
       ; style
           [ txt
               {|/*! normalize.css v8.0.1 | MIT License | github.com/necolas/normalize.css */html{line-height:1.15;-webkit-text-size-adjust:100%}body,h2{margin:0}html{font-family:system-ui,-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Helvetica Neue,Arial,Noto Sans,sans-serif,Apple Color Emoji,Segoe UI Emoji,Segoe UI Symbol,Noto Color Emoji;line-height:1.5}*,:after,:before{box-sizing:border-box;border:0 solid #e2e8f0}h2{font-size:inherit;font-weight:inherit}.font-semibold{font-weight:600}.text-2xl{font-size:1.5rem}.leading-8{line-height:2rem}.mx-auto{margin-left:auto;margin-right:auto}.mt-0{margin-top:0}.mb-4{margin-bottom:1rem}.py-4{padding-top:1rem;padding-bottom:1rem}.px-4{padding-left:1rem;padding-right:1rem}.text-gray-600{--text-opacity:1;color:#718096;color:rgba(113,128,150,var(--text-opacity))}.text-gray-900{--text-opacity:1;color:#1a202c;color:rgba(26,32,44,var(--text-opacity))}.antialiased{-webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale}@media (min-width:640px){.sm\:text-3xl{font-size:1.875rem}.sm\:leading-9{line-height:2.25rem}.sm\:px-6{padding-left:1.5rem;padding-right:1.5rem}.sm\:py-8{padding-top:2rem;padding-bottom:2rem}}@media (min-width:1024px){.lg\:px-8{padding-left:2rem;padding-right:2rem}}|}
           ]
       ])
    (body
       ~a:[ a_class [ "antialiased" ] ]
       [ div
           ~a:[ a_class [ "py-4 sm:py-8" ] ]
           [ div
               ~a:[ a_class [ "max-w-8xl mx-auto px-4 sm:px-6 lg:px-8" ] ]
               [ h2
                   ~a:
                     [ a_class
                         [ "text-2xl leading-8 font-semibold font-display \
                            text-gray-900 sm:text-3xl sm:leading-9"
                         ]
                     ]
                   [ txt (string_of_int code) ]
               ; div ~a:[ a_class [ "mt-0 mb-4 text-gray-600" ] ] [ txt error ]
               ]
           ]
       ])
