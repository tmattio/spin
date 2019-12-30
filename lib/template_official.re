let path =
  Utils.Filename.concat(Config.SPIN_CACHE_DIR.get(), "spin-templates");

let branch = "next";

let url = "git@github.com:tmattio/spin-templates.git";

let ensure_downloaded = () =>
  if (Utils.Filename.test(Utils.Filename.Is_dir, path)) {
    Console.log(<Pastel> "📡  Updating official templates." </Pastel>);
    let _ = Lwt_main.run(Vcs.git_pull(path));
    Console.log(
      <Pastel color=Pastel.GreenBright bold=true> "Done!\n" </Pastel>,
    );
  } else {
    Console.log(<Pastel> "📡  Downloading official templates." </Pastel>);
    let _ = Lwt_main.run(Vcs.git_clone(url, ~destination=path, ~branch));
    Console.log(
      <Pastel color=Pastel.GreenBright bold=true> "Done!\n" </Pastel>,
    );
  };

let all = (): list(Config_file.Doc.doc) => {
  Caml.Sys.readdir(path)
  |> Array.to_list
  |> List.filter(~f=el =>
       Caml.Sys.is_directory(Utils.Filename.concat(path, el))
     )
  |> List.filter(~f=el =>
       switch (Caml.String.get(el, 0)) {
       | '.'
       | '_' => false
       | _ => true
       }
     )
  |> List.map(~f=el =>
       Config_file.Doc.parse_doc(Utils.Filename.concat(path, el))
     );
};
