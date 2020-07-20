let index_user ~user ?alert ~users () =
  let open Tyxml.Html in
  Layout.make
    ~title:"User list · Demo"
    ~user
    [ div
        ~a:[ a_class [ "w-full md:w-3/4 mt-6 md:mt-0 md:pl-6" ] ]
        [ h2
            ~a:[ a_class [ "text-3xl pb-2 border-b mb-6" ] ]
            [ txt "User list" ]
        ; txt "Hello World"
        ]
    ]

let new_user ?alert () =
  let open Tyxml.Html in
  Layout.make
    ~title:"Create a user · Demo"
    [ Layout.page_title ~title:"Create a new user" ()
    ; Layout.content
        [ (match alert with
          | Some alert ->
            div ~a:[ a_class [ "mb-8" ] ] [ Alert.make alert ]
          | None ->
            div [])
        ; form
            ~a:[ a_action "/users"; a_method `Post ]
            [ div
                [ div
                    [ div
                        ~a:
                          [ a_class
                              [ "sm:grid sm:grid-cols-3 sm:gap-4 \
                                 sm:items-start sm:border-t sm:border-gray-200 \
                                 sm:pt-5"
                              ]
                          ]
                        [ label
                            ~a:
                              [ a_label_for "user-name"
                              ; a_class
                                  [ "block text-sm font-medium leading-5 \
                                     text-gray-700 sm:mt-px sm:pt-2"
                                  ]
                              ]
                            [ txt "User Name" ]
                        ; div
                            ~a:[ a_class [ "mt-1 sm:mt-0 sm:col-span-2" ] ]
                            [ input
                                ~a:
                                  [ a_id "user-name"
                                  ; a_name "name"
                                  ; a_required ()
                                  ; a_class
                                      [ "max-w-lg rounded-md shadow-sm \
                                         form-input block w-full transition \
                                         duration-150 ease-in-out sm:text-sm \
                                         sm:leading-5"
                                      ]
                                  ]
                                ()
                            ]
                        ]
                    ]
                ]
            ; div
                ~a:[ a_class [ "mt-8 border-t border-gray-200 pt-5" ] ]
                [ div
                    ~a:[ a_class [ "flex justify-end" ] ]
                    [ span
                        ~a:
                          [ a_class [ "ml-3 inline-flex rounded-md shadow-sm" ]
                          ]
                        [ button
                            ~a:
                              [ a_button_type `Submit
                              ; a_class
                                  [ "inline-flex justify-center py-2 px-4 \
                                     border border-transparent text-sm \
                                     leading-5 font-medium rounded-md \
                                     text-white bg-indigo-600 \
                                     hover:bg-indigo-500 focus:outline-none \
                                     focus:border-indigo-700 \
                                     focus:shadow-outline-indigo \
                                     active:bg-indigo-700 transition \
                                     duration-150 ease-in-out"
                                  ]
                              ]
                            [ txt "Create user" ]
                        ]
                    ]
                ]
            ]
        ]
    ]

let show_user ~user ?alert () =
  let open Tyxml.Html in
  User_layout.make
    ~title:"Show user · Demo"
    ~user
    ~user
    [ div
        ~a:[ a_class [ "w-full md:w-3/4 mt-6 md:mt-0 md:pl-6" ] ]
        [ h2
            ~a:[ a_class [ "text-3xl pb-2 border-b mb-6" ] ]
            [ txt "Show User" ]
        ; txt "Hello World"
        ]
    ]

let edit_user ~user ?alert () =
  let open Tyxml.Html in
  User_layout.make
    ~title:"Edit user · Demo"
    ~user
    ~user
    [ div
        ~a:[ a_class [ "w-full md:w-3/4 mt-6 md:mt-0 md:pl-6" ] ]
        [ h2
            ~a:[ a_class [ "text-3xl pb-2 border-b mb-6" ] ]
            [ txt "Edit User" ]
        ; txt "Hello World"
        ]
    ]
