open Subcommand
open Guppy_cmdobjs
open Ppatteries

let epsilon = 1e-10

let merge a x = a := x +. !a
let lmerge = List.fold_left ((!) |- (+.) |> flip) 0. |- ref

module I = Mass_map.Indiv

let total_along_mass gt mass cb =
  let partial_total id = Kr_distance.total_along_edge
    cb
    (Gtree.get_bl gt id)
    (IntMap.get id [] mass |> List.map I.to_pair |> List.sort compare)
    merge
  in
  Kr_distance.total_over_tree
    partial_total
    (const ())
    lmerge
    (fun () -> ref 0.)
    (Gtree.get_stree gt)

(* When we're passing along the induced tree, the mass will be on the range
 * (0, total_mass), and the branch length coefficient should be 1. Otherwise,
 * we're either before or after the induced tree and the multiplier should
 * be 0. *)
let bump_function r =
  if r = 0. || approx_equal ~epsilon r 1. then 0. else 1.

let pd_of_placerun criterion normalized pr =
  let gt = Placerun.get_ref_tree pr
  and mass = I.of_placerun
    Mass_map.Point
    criterion
    pr
  in
  total_along_mass
    gt
    mass
    (fun r bl -> bump_function !r *. bl)
  |> (if not normalized then identity
    else fun pd -> pd /. (Gtree.tree_length gt))

class cmd () =
object (self)
  inherit subcommand () as super
  inherit mass_cmd ~point_choice_allowed:false () as super_mass
  inherit placefile_cmd () as super_placefile
  inherit tabular_cmd () as super_tabular

  val normalized = flag "--normalized"
    (Plain (false, "Divide by total tree length."))

  method specl =
    super_mass#specl
  @ super_tabular#specl
  @ [toggle_flag normalized]

  method desc = "calculate phylogenetic diversity"
  method usage = "usage: pd [options] placefile[s]"

  method private placefile_action prl =
    let criterion = self#criterion in
    let pd = pd_of_placerun criterion (fv normalized) in
    prl
      |> List.map
          (fun pr -> [Placerun.get_name pr; pd pr |> Printf.sprintf "%g"])
      |> self#write_ll_tab

end
