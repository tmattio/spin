open Cmdliner;
open Spin;

let run = () => {
  let global_context = Config.read_global_context();

  let context_name =
    Global_context.opt_value(global_context, Name, ~default="");
  let context_email =
    Global_context.opt_value(global_context, Email, ~default="");
  let context_github_username =
    Global_context.opt_value(global_context, Github_username, ~default="");
  let context_npm_username =
    Global_context.opt_value(global_context, Npm_username, ~default="");

  let name = Prompt.input("Your name", ~default=context_name);
  let email = Prompt.input("Your email", ~default=context_email);
  let github_username =
    Prompt.input("Your Github username", ~default=context_github_username);
  let npm_username =
    Prompt.input("Your NPM username", ~default=context_npm_username);

  let non_empty_string = v => String.equal(v, "") ? None : Some(v);

  let user_config =
    Config_file_user.{
      name: non_empty_string(name),
      email: non_empty_string(email),
      github_username: non_empty_string(github_username),
      npm_username: non_empty_string(npm_username),
    };

  Config_file_user.save(user_config, ~from_dir=Config.SPIN_CONFIG_DIR.get());

  Lwt.return();
};

let cmd = {
  let doc = "Configure user global context. The global context will be used when generating new projects, unless `--ignore-config` is used.";

  let run_command = () => run |> Errors.handle_errors |> Lwt_main.run;

  (
    Term.(app(const(run_command), const())),
    Term.info(
      "config",
      ~doc,
      ~envs=Man.envs,
      ~version=Man.version,
      ~exits=Man.exits,
      ~man=Man.man,
      ~sdocs=Man.sdocs,
    ),
  );
};
