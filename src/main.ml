open Cmdliner
open Rresult

let ranges ?(chunk=1) lower upper =
  let rec loop lower upper =
    if lower > upper then []
    else
      (lower + chunk) :: loop (lower + chunk) upper
  in
  loop lower upper

(* let discover_hosts () = *)
(*   let third_spot = ranges 1 255 in *)
(*   let fourth_spot = ranges 1 254 in *)
(*   let all_targets = List.map (Printf.sprintf "192.168.1.%d") fourth_spot in *)
(*     Lwt_list.filter_map_p *)
(*       (fun the_addr -> *)
(*        try_lwt *)
(*          Unix.inet_addr_of_string the_addr |> *)
(*          Lwt_unix.gethostbyaddr >>= fun result -> *)
(*        Some (result.Unix.h_name, result.Unix.h_addr_list.(0) |> *)
(*                                    Unix.string_of_inet_addr) |> return *)
(*        with *)
(*          Not_found -> return None) *)
(*       all_targets (\* >>= Lwt_list.iter_s Lwt_io.printl *\) *)

let pipe_name = "/tmp/stay_aware_pipe"

let daemonize () =
  match Unix.fork () with
  | x when x < 0 -> Error "Issue with first fork"
  | x when x > 0 -> exit (-1)
  | 0 -> match Unix.setsid () with
         | x when x < 0 -> Error "Issue with setsid"
         | x -> match Unix.fork () with
                | x when x < 0 -> Error "Issue with second fork"
                | x when x > 0 -> exit (-1)
                | x ->
                  Unix.umask 0 |>
                  fun _ ->
                  Unix.chdir "/";
                  List.iter Unix.close [Unix.stdin; Unix.stdout];
                  Ok ()

let program raw_string =
  match raw_string with
  | "up" ->
     if Sys.file_exists pipe_name
     then
       Error "Can't do up again"
     else
       begin
         daemonize () >>= fun () ->
         let handler _ = Sys.remove pipe_name; exit 0 in
         Sys.set_signal Sys.sigterm (Sys.Signal_handle handler);
         Unix.mkfifo pipe_name 0o600;
         let source = Unix.openfile pipe_name
                                    [Unix.O_RDONLY;Unix.O_SYNC]
                                    0o600
         in
         let rec forever () =
           Unix.select [source] [] [] 0.50 |>
             function
             | read_me, _, _ when List.length read_me > 0->
                let read_me_fd = List.hd read_me in
                let buffer = Bytes.create 1024 in
                let count = Unix.read read_me_fd buffer 0 1024 in
                if count > 0
                then begin
                let message = Bytes.sub buffer 0 count in
                if message = "exit" then exit 0;
                (match Unix.fork () with
                 | 0 -> Osx_notify.notify_start message
                 | pid -> Unix.waitpid [] pid |>
                            (function
                             | (_, Unix.WEXITED status) when status = -1 ->
                                prerr_endline "Unable to setup bundle hook"
                             | (_, Unix.WEXITED status) when status = 0 ->
                                ()
                             | (_, Unix.WEXITED status) when status = 1 ->
                                prerr_endline "User clicked on notification"
                             | (_, _) -> prerr_endline "Something fuckedup"))
                end;
                forever ()
             | _ -> forever ()
         in
         forever ()
       end
  | "exit" ->
     let handle = Unix.openfile pipe_name [Unix.O_WRONLY] 0o600 in
     Unix.write handle "exit" 0 4 |> fun _ -> Unix.close handle; Ok ()
(* BUG What about input of less than 3, like hi*)
  | x when String.sub x 0 3 = "msg" ->
     let handle = Unix.openfile pipe_name [Unix.O_WRONLY] 0o600 in
     Unix.write handle x 0 (String.length x) |> fun _ -> Unix.close handle; Ok ()
  | _ -> Error "Unacceptable input"

let first_arg =
  Arg.(required & pos 0 (some string) None & info [])

let cmd =
  let doc = "stay_aware is a simple program that helps you know\n\
             who else is on the network with you." in
  let man = [`S "First Section";
             `P "Something"] in
  Term.(pure program $ first_arg),
  Term.info "stay_aware" ~version:"0.0.1" ~doc ~man

(** Entry point of the program *)
let () =
  match Term.eval cmd with
  | `Error _ -> print_endline "Need to handle clean up"
  | `Ok result  -> (match result with
                    | Ok () -> ()
                    | Error e -> print_endline e)
  | _ -> ()
