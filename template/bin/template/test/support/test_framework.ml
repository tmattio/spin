(** Initialize the test framework.

    Here we are specifying where snapshots should be stored as well as the root
    directory of the project for the formatting of terminal output. *)

include Rely.Make (struct
  let config =
    Rely.TestFrameworkConfig.initialize
      { snapshotDir = "test/_snapshots"; projectDir = "" }
end)
