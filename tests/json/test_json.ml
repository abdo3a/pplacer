open Ppatteries
open OUnit
open Test_util

let suite = List.map
  (fun fname ->
    let name = Filename.basename fname in
    name >:: match String.sub name 0 4 with
      | "pass" -> fun () ->
        let parsed = Json.of_file fname in
        let roundtrip = Json.of_string (Json.to_string parsed) in
        json_equal parsed roundtrip
      | "fail" -> fun () ->
        "parsing didn't fail" @? begin
          try
            let _ = Json.of_file fname in false
          with
            | Sparse.Parse_error _ -> true
        end
      | _ -> failwith (Printf.sprintf "unexpected json file %s" fname)
  )
  (get_dir_contents
     ~pred:(flip MaybeZipped.check_suffix "jtest")
     (tests_dir ^ "data/json")
   |> List.of_enum)
