module User = Account_user

module Error = struct
  type t = [ | Error.t ] [@@deriving show, eq]
end

let list_users () = User.get_all ()

let get_user_by_id id = User.get_by_id id

let create_user ~name () = User.create ~name ()

let update_user ?name user = User.update ?name user

let delete_user user = User.delete user
