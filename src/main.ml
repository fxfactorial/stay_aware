open Lwt
open Cmdliner

module R = Rresult

let prog raw_string =
  return (Osx_notify.notify_start raw_string)

let first_arg =
  Arg.(required & pos 0 (some string) None & info [])

let cmd =
  let doc = "stay_aware is a simple program that helps you know\n\
             who else is on the network with you." in
  let man = [`S "First Section";
             `P "Something"] in
  Term.(pure prog $ first_arg),
  Term.info "stay_aware" ~version:"0.0.1" ~doc ~man

(** Entry point of the program *)
let () =
  match Term.eval cmd with
  | `Error _ -> print_endline "Need to handle clean up"
  | `Ok a  -> Lwt_main.run a
  | _ -> ()
