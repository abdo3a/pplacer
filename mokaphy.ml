(* mokaphy v0.3. Copyright (C) 2010  Frederick A Matsen.
 * This file is part of mokaphy. mokaphy is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. pplacer is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with pplacer. If not, see <http://www.gnu.org/licenses/>.
 *
 *)

open Fam_batteries
open MapsSets
open Placement

let parse_args () =
  let files = ref [] 
  and prefs = Mokaphy_prefs.defaults ()
  in
  let usage =
    "mokaphy "^Version.version_revision^"\nmokaphy [options] ex1.place ex2.place...\n"
  and anon_arg arg =
    files := arg :: !files
  in
  Arg.parse (Mokaphy_prefs.args prefs) anon_arg usage;
  (List.rev !files, prefs)
     
let () =
  if not !Sys.interactive then begin
    let (fnames, prefs) = parse_args () in
    let parsed = List.map Placerun_io.of_file fnames in
    if parsed = [] then exit 0;
    Random.init (Mokaphy_prefs.seed prefs);
    List.iter 
      (fun p -> 
        if Placerun.contains_unplaced_queries p then
          failwith((Placerun.get_name p)^" contains unplaced queries."))
      parsed;
    let out_ch = 
      if Mokaphy_prefs.out_fname prefs = "" then stdout
      else open_out (Mokaphy_prefs.out_fname prefs)
    in
    let criterion = 
      if Mokaphy_prefs.use_pp prefs then Placement.post_prob
      else Placement.ml_ratio
    in
    Mokaphy_core.core
      prefs
      criterion
      out_ch
      (Array.of_list parsed);
    if Mokaphy_prefs.out_fname prefs <> "" then close_out out_ch
  end
