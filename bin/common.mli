val term : int Cmdliner.Term.t

val handle_errors : (unit, Spin.Spin_error.t) Result.t -> int

val ignore_config_arg : bool Cmdliner.Term.t

val use_defaults_arg : bool Cmdliner.Term.t

val envs : Cmdliner.Cmd.Env.info list

val exits : Cmdliner.Cmd.Exit.info list

module Syntax : sig
  val ( let+ ) : 'a Cmdliner.Term.t -> ('a -> 'b) -> 'b Cmdliner.Term.t

  val ( and+ )
    :  'a Cmdliner.Term.t
    -> 'b Cmdliner.Term.t
    -> ('a * 'b) Cmdliner.Term.t
end
