open Dec_template

exception Invalid_expr of string

let rec eval ~context = function
  | Expr.Var name ->
    (match Hashtbl.find_opt context name with
    | Some var ->
      var
    | None ->
      raise
        (Invalid_expr
           (Printf.sprintf "The context variable is missing: %s" name)))
  | Expr.Function fn ->
    eval_fn fn ~context
  | Expr.String s ->
    s

and eval_fn ~context =
  let eval = eval ~context in
  let to_bool = to_bool ~context in
  function
  | Expr.If (e1, e2, e3) ->
    let e1 = to_bool e1 in
    if e1 then eval e2 else eval e3
  | Expr.And (e1, e2) ->
    let e1 = to_bool e1 in
    let e2 = to_bool e2 in
    (e1 && e2) |> Bool.to_string
  | Expr.Or (e1, e2) ->
    let e1 = to_bool e1 in
    let e2 = to_bool e2 in
    (e1 || e2) |> Bool.to_string
  | Expr.Eq (e1, e2) ->
    let e1 = eval e1 in
    let e2 = eval e2 in
    String.equal e1 e2 |> Bool.to_string
  | Expr.Neq (e1, e2) ->
    let e1 = eval e1 in
    let e2 = eval e2 in
    (not (String.equal e1 e2)) |> Bool.to_string
  | Expr.Not e ->
    let e = to_bool e in
    (not e) |> Bool.to_string
  | Expr.Slugify e ->
    let e = eval e in
    Helpers.slugify e
  | Expr.Upper e ->
    let e = eval e in
    String.uppercase_ascii e
  | Expr.Lower e ->
    let e = eval e in
    String.lowercase_ascii e
  | Expr.Snake_case e ->
    let e = eval e in
    Helpers.snake_case e
  | Expr.Camel_case e ->
    let e = eval e in
    Helpers.camel_case e
  | Expr.Trim e ->
    let e = eval e in
    String.trim e
  | Expr.First_char e ->
    let e = eval e in
    String.prefix e 1
  | Expr.Last_char e ->
    let e = eval e in
    String.suffix e 1
  | Expr.Run (cmd, args) ->
    let cmd = eval cmd in
    let args = List.fold_left (fun acc arg -> eval arg :: acc) [] args in
    (match Spawn.exec cmd (List.rev args) with Ok () -> "false" | _ -> "true")
  | Expr.Concat l ->
    let l = List.fold_left (fun acc arg -> eval arg :: acc) [] l in
    String.concat "" (List.rev l)

and to_bool ~context expr =
  let e = eval expr ~context in
  try bool_of_string e with
  | Invalid_expr _ as e ->
    raise e
  | _ ->
    raise (Invalid_expr "The expression cannot be evaluated to a boolean")

let to_result ~context f expr =
  try f ~context expr |> Result.ok with
  | Invalid_expr reason ->
    Error (Spin_error.failed_to_generate reason)
  | _ ->
    Error
      (Spin_error.failed_to_generate
         "Failed to evaluate an expression for unknown reason")

let filter_map ~context ~condition f l =
  let open Result.Syntax in
  List.fold_right
    (fun el acc ->
      let* acc = acc in
      match condition el with
      | None ->
        Result.ok (f el :: acc)
      | Some expr ->
        let+ result = to_result to_bool expr ~context in
        if result then
          f el :: acc
        else
          acc)
    l
    (Result.ok [])
