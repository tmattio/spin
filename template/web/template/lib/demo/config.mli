(** Configuration of the application.

    The configurations values depend on the application environment defined by
    the environment variable [DEMO_ENV]. *)

val is_test : bool
(** Whether the application is running in test environment.

    The application runs in a test environment when the environment variable
    [DEMO_ENV] is set to [test] (e.g. [export DEMO_ENV=test]) *)

val is_prod : bool
(** Whether the application is running in production environment.

    The application runs in a production environment when the environment
    variable [DEMO_ENV] is set to [production] (e.g.
    [export DEMO_ENV=production]) *)

val is_dev : bool
(** Whether the application is running in development environment.

    The application runs in a development environment when the environment
    variable [DEMO_ENV] is set to [production] (e.g.
    [export DEMO_ENV=production]) or when the environment variable [DEMO_ENV] is
    undefined. *)

val choose_env : prod:'a -> dev:'a -> test:'a -> 'a
(** Choose an environment depending on the value of the environment variable
    [DEMO_ENV]. *)

val database_host : string
(** The host URI of the database.

    Defined with the environment variable [DEMO_DATABASE_HOST] *)

val database_port : int
(** The TCP port of the database.

    Defined with the environment variable [DEMO_DATABASE_PORT] *)

val database_name : string
(** The database name.

    Defined with the environment variable [DEMO_DATABASE_NAME] *)

val database_uri : string
(** The full URI of the database.

    [database_uri] is built from the values of [database_host], [database_port]
    and [database_name]. *)
