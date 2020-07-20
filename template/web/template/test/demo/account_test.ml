open Alcotest
open Lwt.Syntax
open Test_testable_user
open Test_fixture_user

let () =
  Test_support.setup_logger ~log_level:Logs.Warning ();
  Test_support.setup_rnd_generators ()

let test_case n = Test_support.test_case_db n `Quick

let check_user = Alcotest.check (Alcotest.result user error)

let setup () =
  let+ user = user_fixture () in
  user

let suite =
  [ ( "list_users"
    , [ test_case "returns all user users" (fun _switch () ->
            let* user_ = Test_fixture_account.user_fixture () in
            let* user_ = user_fixture ~user:user_ () in
            let+ fetched_users =
              Demo.User.list_user_users user_
              |> Test_support.get_lwt_ok ~msg:"could not fetch list of users"
            in
            check (list user) "is same list" [ user_ ] fetched_users)
      ; test_case "does not return other users users" (fun _switch () ->
            let* user_ = Test_fixture_account.user_fixture () in
            let* user_ = user_fixture ~user:user_ () in
            let* user_2 = Test_fixture_account.user_fixture () in
            let* user_2 = user_fixture ~user:user_2 () in
            let* fetched_users =
              Demo.User.list_user_users user_
              |> Test_support.get_lwt_ok ~msg:"could not fetch list of users"
            in
            let+ fetched_users2 =
              Demo.User.list_user_users user_2
              |> Test_support.get_lwt_ok ~msg:"could not fetch list of users"
            in
            check (list user) "is same list" [ user_ ] fetched_users;
            check (list user) "is same list" [ user_2 ] fetched_users2)
      ] )
  ; ( "get_user_by_id"
    , [ test_case "returns the user with given id" (fun _switch () ->
            let* user_ = setup () in
            let+ fetched_user =
              Demo.User.get_user_by_id user_.id
              |> Test_support.get_lwt_ok
                   ~msg:"could not fetch user with given id"
            in
            check user "is same user" user_ fetched_user)
      ] )
  ; ( "create_user"
    , [ test_case "with valid data creates a user" (fun _switch () ->
            let* user = Test_fixture_account.user_fixture () in
            let name = name_fixture () in
            let+ result = Demo.User.create_user ~user ~name () in
            check bool "is ok" true (Result.is_ok result))
      ; test_case "with invalid data returns error changeset" (fun _switch () ->
            let* user = Test_fixture_account.user_fixture () in
            (* Change ID of user to non-existing ID *)
            let user = { user with id = 1234 } in
            let name = name_fixture () in
            let+ result = Demo.User.create_user ~user ~name () in
            check bool "is error" true (Result.is_error result))
      ] )
  ; ( "update_user"
    , [ test_case "with valid data updates the user" (fun _switch () ->
            let* user_ = user_fixture () in
            let name_ = name_fixture ~v:"new-name" () in
            let+ updated_user =
              Demo.User.update_user ~name:name_ user_
              |> Test_support.get_lwt_ok ~msg:"could not update the user"
            in
            check
              user
              "is updated user"
              { user_ with
                name =
                  Demo.Account.User.Name.of_string "new-name"
                  |> Test_support.get_ok ~msg:"failed to create user name"
              }
              updated_user)
      ] )
  ; ( "delete_user"
    , [ test_case "deletes the user" (fun _switch () ->
            let* user_ = user_fixture () in
            let* () =
              Demo.User.delete_user user_
              |> Test_support.get_lwt_ok ~msg:"could not delete user"
            in
            let+ result_ = Demo.User.get_user_by_id user_.id in
            check (result user error) "is not found" (Error `Not_found) result_)
      ] )
  ]

let () = Lwt_main.run @@ Alcotest_lwt.run "demo - User" suite
