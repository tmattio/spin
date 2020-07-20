open Demo

let error = Alcotest.of_pp User.Error.pp

let user = Alcotest.of_pp Account.User.pp

let user_name = Alcotest.of_pp Account.User.Name.pp
