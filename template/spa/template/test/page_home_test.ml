open Alcotest
open Core_kernel
open Incr_dom_testing

let%expect_test _ =
  let driver =
    Driver.create
      ~initial_model:Demo.App.initial_model
      ~sexp_of_model:ADemo.pp.Model.sexp_of_t
      ~initial_state:()
      (module Demo.App)
  in
  let module H = (val Helpers.make driver) in
  H.show_view ();
  [%expect {|
    <body>
      <div> 0 </div>
    </body> |}];
  H.do_actions [ App.Action.Increment ];
  H.perform_update ();
  H.show_model ();
  [%expect {| ((counter 1)) |}];
  H.show_view ();
  [%expect {|
    <body>
      <div> 1 </div>
    </body> |}]
