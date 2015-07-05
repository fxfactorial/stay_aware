open Lwt
open Cmdliner

module R = Rresult

let rec prog raw_string =
  match Lwt_unix.fork () with
  | 0 -> (* Just for the child code *)
     return (Osx_notify.notify_start raw_string)
  | pid -> Lwt_unix.waitpid [] pid >>= function
           | (_, Unix.WEXITED status) when status = -1 ->
              Lwt_io.printl "Unable to setup bundle hook"
           | (_, Unix.WEXITED status) when status = 0 ->
              Lwt_io.printl "Application ended"
           | (_, Unix.WEXITED status) when status = 1 ->
              Lwt_io.printl "User clicked on notification"
           | (_, _) -> Lwt_io.printl "Something fuckedup"

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
