open Alcotest
open Lwt.Syntax
open Test_testable_account
open Test_fixture_account.User

let () = Test_support.setup_logger ~log_level:Logs.Warning ()

let test_case n = Test_support.test_case_db n `Quick

let check_user = Alcotest.check (Alcotest.result user error)

let setup () =
  let+ user = user_fixture () in
  user

let suite =
  [ ( "list_users"
    , [ test_case "returns all user users" (fun _switch () ->
            let* user_ = user_fixture () in
            let+ fetched_users =
              Demo.Account.list_users ()
              |> Test_support.get_lwt_ok ~msg:"could not fetch list of users"
            in
            check (list user) "is same list" [ user_ ] fetched_users)
      ; test_case "does not return other users users" (fun _switch () ->
            let* user_ = user_fixture () in
            let* user_2 = user_fixture () in
            let* fetched_users =
              Demo.Account.list_users ()
              |> Test_support.get_lwt_ok ~msg:"could not fetch list of users"
            in
            let+ fetched_users2 =
              Demo.Account.list_users ()
              |> Test_support.get_lwt_ok ~msg:"could not fetch list of users"
            in
            check (list user) "is same list" [ user_ ] fetched_users;
            check (list user) "is same list" [ user_2 ] fetched_users2)
      ] )
  ; ( "get_user_by_id"
    , [ test_case "returns the user with given id" (fun _switch () ->
            let* user_ = setup () in
            let+ fetched_user =
              Demo.Account.get_user_by_id user_.id
              |> Test_support.get_lwt_ok
                   ~msg:"could not fetch user with given id"
            in
            check user "is same user" user_ fetched_user)
      ] )
  ; ( "create_user"
    , [ test_case "with valid data creates a user" (fun _switch () ->
            let* user = user_fixture () in
            let name = name_fixture () in
            let+ result = Demo.Account.create_user ~name () in
            check bool "is ok" true (Result.is_ok result))
      ; test_case "with invalid data returns error changeset" (fun _switch () ->
            let* user = user_fixture () in
            let name = name_fixture () in
            let+ result = Demo.Account.create_user ~name () in
            check bool "is error" true (Result.is_error result))
      ] )
  ; ( "update_user"
    , [ test_case "with valid data updates the user" (fun _switch () ->
            let* user_ = user_fixture () in
            let name_ = name_fixture ~v:"new-name" () in
            let+ updated_user =
              Demo.Account.update_user ~name:name_ user_
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
              Demo.Account.delete_user user_
              |> Test_support.get_lwt_ok ~msg:"could not delete user"
            in
            let+ result_ = Demo.Account.get_user_by_id user_.id in
            check (result user error) "is not found" (Error `Not_found) result_)
      ] )
  ]

let () = Lwt_main.run @@ Alcotest_lwt.run "demo - User" suite
