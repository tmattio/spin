open Jingoo

(* From
   https://github.com/sindresorhus/binary-extensions/blob/master/binary-extensions.json *)
let binary_extensions =
  [ ".3dm"
  ; ".3ds"
  ; ".3g2"
  ; ".3gp"
  ; ".7z"
  ; ".a"
  ; ".aac"
  ; ".adp"
  ; ".ai"
  ; ".aif"
  ; ".aiff"
  ; ".alz"
  ; ".ape"
  ; ".apk"
  ; ".appimage"
  ; ".ar"
  ; ".arj"
  ; ".asf"
  ; ".au"
  ; ".avi"
  ; ".bak"
  ; ".baml"
  ; ".bh"
  ; ".bin"
  ; ".bk"
  ; ".bmp"
  ; ".btif"
  ; ".bz2"
  ; ".bzip2"
  ; ".cab"
  ; ".caf"
  ; ".cgm"
  ; ".class"
  ; ".cmx"
  ; ".cpio"
  ; ".cr2"
  ; ".cur"
  ; ".dat"
  ; ".dcm"
  ; ".deb"
  ; ".dex"
  ; ".djvu"
  ; ".dll"
  ; ".dmg"
  ; ".dng"
  ; ".doc"
  ; ".docm"
  ; ".docx"
  ; ".dot"
  ; ".dotm"
  ; ".dra"
  ; ".DS_Store"
  ; ".dsk"
  ; ".dts"
  ; ".dtshd"
  ; ".dvb"
  ; ".dwg"
  ; ".dxf"
  ; ".ecelp4800"
  ; ".ecelp7470"
  ; ".ecelp9600"
  ; ".egg"
  ; ".eol"
  ; ".eot"
  ; ".epub"
  ; ".exe"
  ; ".f4v"
  ; ".fbs"
  ; ".fh"
  ; ".fla"
  ; ".flac"
  ; ".flatpak"
  ; ".fli"
  ; ".flv"
  ; ".fpx"
  ; ".fst"
  ; ".fvt"
  ; ".g3"
  ; ".gh"
  ; ".gif"
  ; ".graffle"
  ; ".gz"
  ; ".gzip"
  ; ".h261"
  ; ".h263"
  ; ".h264"
  ; ".icns"
  ; ".ico"
  ; ".ief"
  ; ".img"
  ; ".ipa"
  ; ".iso"
  ; ".jar"
  ; ".jpeg"
  ; ".jpg"
  ; ".jpgv"
  ; ".jpm"
  ; ".jxr"
  ; ".key"
  ; ".ktx"
  ; ".lha"
  ; ".lib"
  ; ".lvp"
  ; ".lz"
  ; ".lzh"
  ; ".lzma"
  ; ".lzo"
  ; ".m3u"
  ; ".m4a"
  ; ".m4v"
  ; ".mar"
  ; ".mdi"
  ; ".mht"
  ; ".mid"
  ; ".midi"
  ; ".mj2"
  ; ".mka"
  ; ".mkv"
  ; ".mmr"
  ; ".mng"
  ; ".mobi"
  ; ".mov"
  ; ".movie"
  ; ".mp3"
  ; ".mp4"
  ; ".mp4a"
  ; ".mpeg"
  ; ".mpg"
  ; ".mpga"
  ; ".mxu"
  ; ".nef"
  ; ".npx"
  ; ".numbers"
  ; ".nupkg"
  ; ".o"
  ; ".oga"
  ; ".ogg"
  ; ".ogv"
  ; ".otf"
  ; ".pages"
  ; ".pbm"
  ; ".pcx"
  ; ".pdb"
  ; ".pdf"
  ; ".pea"
  ; ".pgm"
  ; ".pic"
  ; ".png"
  ; ".pnm"
  ; ".pot"
  ; ".potm"
  ; ".potx"
  ; ".ppa"
  ; ".ppam"
  ; ".ppm"
  ; ".pps"
  ; ".ppsm"
  ; ".ppsx"
  ; ".ppt"
  ; ".pptm"
  ; ".pptx"
  ; ".psd"
  ; ".pya"
  ; ".pyc"
  ; ".pyo"
  ; ".pyv"
  ; ".qt"
  ; ".rar"
  ; ".ras"
  ; ".raw"
  ; ".resources"
  ; ".rgb"
  ; ".rip"
  ; ".rlc"
  ; ".rmf"
  ; ".rmvb"
  ; ".rpm"
  ; ".rtf"
  ; ".rz"
  ; ".s3m"
  ; ".s7z"
  ; ".scpt"
  ; ".sgi"
  ; ".shar"
  ; ".snap"
  ; ".sil"
  ; ".sketch"
  ; ".slk"
  ; ".smv"
  ; ".snk"
  ; ".so"
  ; ".stl"
  ; ".suo"
  ; ".sub"
  ; ".swf"
  ; ".tar"
  ; ".tbz"
  ; ".tbz2"
  ; ".tga"
  ; ".tgz"
  ; ".thmx"
  ; ".tif"
  ; ".tiff"
  ; ".tlz"
  ; ".ttc"
  ; ".ttf"
  ; ".txz"
  ; ".udf"
  ; ".uvh"
  ; ".uvi"
  ; ".uvm"
  ; ".uvp"
  ; ".uvs"
  ; ".uvu"
  ; ".viv"
  ; ".vob"
  ; ".war"
  ; ".wav"
  ; ".wax"
  ; ".wbmp"
  ; ".wdp"
  ; ".weba"
  ; ".webm"
  ; ".webp"
  ; ".whl"
  ; ".wim"
  ; ".wm"
  ; ".wma"
  ; ".wmv"
  ; ".wmx"
  ; ".woff"
  ; ".woff2"
  ; ".wrm"
  ; ".wvx"
  ; ".xbm"
  ; ".xif"
  ; ".xla"
  ; ".xlam"
  ; ".xls"
  ; ".xlsb"
  ; ".xlsm"
  ; ".xlsx"
  ; ".xlt"
  ; ".xltm"
  ; ".xltx"
  ; ".xm"
  ; ".xmind"
  ; ".xpi"
  ; ".xpm"
  ; ".xwd"
  ; ".xz"
  ; ".z"
  ; ".zip"
  ; ".zipx"
  ]

let jg_string_fn ?kwargs:_ ?defaults:_ fn value =
  let value = Jg_runtime.string_of_tvalue value in
  let slug = fn value in
  Jg_types.Tstr slug

let filters =
  [ "slugify", Helpers.slugify |> jg_string_fn |> Jg_types.func_arg1_no_kw
  ; "snake_case", Helpers.snake_case |> jg_string_fn |> Jg_types.func_arg1_no_kw
  ; "camel_case", Helpers.camel_case |> jg_string_fn |> Jg_types.func_arg1_no_kw
  ]

let jg_models_of_context context =
  Hashtbl.to_alist context |> List.map ~f:(fun (k, v) -> k, Jg_types.Tstr v)

let generate_string ~context s =
  Jg_template.from_string
    s
    ~models:(jg_models_of_context context)
    ~env:{ Jg_types.std_env with filters = Jg_types.std_env.filters @ filters }

let normalize_path path =
  String.substr_replace_all path ~pattern:"\\" ~with_:"/"

let is_binary_file path =
  List.mem binary_extensions (Fpath.v path |> Fpath.get_ext) ~equal:String.equal

let copy ~context ~content path =
  let open Lwt_result.Syntax in
  (* Need to normalize the file separation because "\\" will escape the
     expressions to evaluate in the template engine *)
  let normalized_path = normalize_path path in
  let* normalized_path =
    (try Ok (generate_string normalized_path ~context) with
    | _ ->
      Error
        (Spin_error.failed_to_generate
           (Printf.sprintf
              "Error while running the template engine on the path of %S"
              path)))
    |> Lwt.return
  in
  let* () = Logs_lwt.debug (fun m -> m "Generating %s" path) |> Lwt_result.ok in
  Filename.dirname normalized_path |> Spin_unix.mkdir_p;
  Lwt_io.with_file
    normalized_path
    (fun oc -> Lwt_io.write oc content |> Lwt_result.ok)
    ~mode:Lwt_io.Output

let generate ~context ~content path =
  let open Lwt_result.Syntax in
  let* content =
    (try Ok (generate_string content ~context) with
    | _ ->
      Error
        (Spin_error.failed_to_generate
           (Printf.sprintf
              "Error while running the template engine on content of %S."
              path)))
    |> Lwt.return
  in
  copy ~context ~content path
