(** [Repo] is the main interface to the database.

    Generally, every database interaction should be done with [Repo]. This
    ensure that the error handling is centralized and make it easy to localize
    parts of the code that require database access.

    {1 Querying}

    [Repo] provides two functions to execute queries:

    - [query f]
    - [query_opt f]

    These functions will take care of logging the query and any error that
    occurs. They also handle Caqti errors and map them to an [`Internal_error]
    variant.

    [query_opt] behaves the same way, but excepts the query result to be an
    [option]. If the result is [Some _], it is returned, otherwise, an
    [Error `Not_found] is returned.

    {1 Transaction}

    The transaction API is the same as the query API. [Repo] provides two
    functions:

    - [transaction f]
    - [transaction_opt f]

    Any database request done in [f] will be wrapped in a transaction.

    {1 Cleaning}

    [Repo] provides functions to clean database tables without deleting them.
    The main use case is unit tests where any data persisted during the test
    must be cleaned before another one is run.

    You probably don't want to use a cleaning function outside of your unit
    tests. *)

type pool = (Caqti_lwt.connection, Caqti_error.t) Caqti_lwt.Pool.t

type ('res, 'err) query =
  Caqti_lwt.connection -> ('res, ([< Caqti_error.t ] as 'err)) Lwt_result.t

type 'a result = ('a, Caqti_error.t) Lwt_result.t

type connection = (module Caqti_lwt.CONNECTION)

type mode =
  | ReadUncommitted
  | ReadCommitted
  | RepeatableRead
  | Serializable

val query
  :  ?pool:pool
  -> (connection -> 'a result)
  -> ('a, [> `Internal_error of string ]) Lwt_result.t
(** [query_ query] is the [Ok res] of the [res] obtained by executing the
    database [query], or else the [Error err] reporting the error causing the
    query to fail. *)

val query_opt
  :  ?pool:pool
  -> (connection -> 'a option result)
  -> ('a, [> `Internal_error of string | `Not_found ]) Lwt_result.t
(** [query_opt query] is [query] but return an [Error `Not_found] when the query
    expected at list one result and none was returned from the query. *)

val transaction
  :  ?mode:mode
  -> ?pool:pool
  -> (connection -> 'a result)
  -> ('a, [> `Internal_error of string ]) Lwt_result.t

val transaction_opt
  :  ?mode:mode
  -> ?pool:pool
  -> (connection -> 'a option result)
  -> ('a, [> `Internal_error of string | `Not_found ]) Lwt_result.t
