(** Spin library interface *)

(** Template source *)
type template_source =
  | Local of string     (** Local directory path *)

(** Configuration for a template *)
type template_config

(** Template context with user-provided values *)
type template_context = (string * string) list

(** Custom exceptions *)
exception Template_config_error of string
exception Context_build_error of string
exception Project_generation_error of string
exception Global_config_error of string

(** {2 Template Management} *)

val get_template_config : template_source -> template_config
(** Get the configuration for a given template. The configuration is read from the 'spin.yaml' at the root of the template directory.
    @raise Template_config_error if the configuration cannot be read or parsed *)

(** {2 User Prompting and Context Building} *)

val build_template_context : template_config -> template_context
(** Build a template context by prompting the user for each config item in the template configuration
    @raise Context_build_error if there's an error during context building *)

(** {2 Project Generation} *)

val generate_project : template_source -> template_config -> template_context -> string -> unit
(** Generate a new project based on the given options and context
    @raise Project_generation_error if there's an error during project generation *)

(** {2 Configuration Management} *)

val get_global_config : unit -> (string * string) list
(** Get the global Spin configuration
    @raise Global_config_error if there's an error retrieving the global configuration *)

val set_global_config : string -> string -> unit
(** Set a global configuration value
    @raise Global_config_error if there's an error setting the global configuration *)

(** {2 Utility Functions} *)

val resolve_template_source : string -> template_source
(** Resolve a string to a template source (official, local, or remote) *)