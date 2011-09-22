open Ppatteries
open OUnit
open Test_util

let suite = [
  "test_simple" >:: begin fun () ->
    placeruns_of_dir "simple"
      |> List.cons (placerun_of_dir "multi" "test1and3")
      |> List.map
          (Placerun.get_name &&& Guppy_wpd.wpd_of_placerun Placement.ml_ratio)
      |> List.sort
      |> List.enum
      |> check_map_approx_equal
          "unequal (%s(%g) and %s(%g))"
          (List.enum [
            "test1", 8.;
            "test1and3", 6.66667;
            "test2", 4.;
            "test3", 0.;
          ])
  end;

]
