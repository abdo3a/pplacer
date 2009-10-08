(* pplacer v0.3. Copyright (C) 2009  Frederick A Matsen.
 * This file is part of pplacer. pplacer is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. pplacer is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with pplacer. If not, see <http://www.gnu.org/licenses/>.
 *)

open MapsSets
open Fam_batteries

let bifurcation_warning = 
  "Warning: pplacer results make the most sense when the \
  given tree is multifurcating at the root. See manual for details."

let warn_about_duplicate_names pquery_list = 
  let name_set = StringSet.empty in
  let _ = 
    List.fold_left
      (fun accu pquery ->
        let name = Pquery.name pquery in
        if StringSet.mem name accu then
          Printf.printf "Warning: query name %s appears multiple times.\n" name;
        StringSet.add name accu)
      name_set
      pquery_list
  in
  ()

let write_placeutil_preamble ch version_str argv ref_tree =
  Printf.fprintf ch "# pplacer %s run\n" version_str;
  Printf.fprintf ch 
             "# made by placeutil run as: %s\n" 
             (String.concat " " (Array.to_list argv));
  Printf.fprintf ch "# output format: ML weight ratio, PP, ML likelihood, marginal likelihood, attachment location (distal length), pendant branch length\n";
  if not (Stree.multifurcating_at_root ref_tree.Itree.stree) then
    Printf.fprintf ch "# %s\n" bifurcation_warning;
  Printf.fprintf ch "# numbered reference tree: %s\n"
    (Itree_io.to_newick (Itree_io.make_numbered_tree ref_tree));
  Printf.fprintf ch "# reference tree: %s\n" (Itree_io.to_newick ref_tree)

(* returns (below, above), where below are the pqueries whose best placement is
 * non existent or doesn't satisfy the cutoff, and above are the pqueries that
 * do. *)
let partition_by_cutoff criterion cutoff pquery_list = 
  List.partition 
    (fun pq ->
      match Pquery.opt_best_place criterion pq with
      | Some place -> cutoff <= criterion place
      | None -> false)
    pquery_list
  
