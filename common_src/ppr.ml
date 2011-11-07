(* ppr generalized nonsense *)

open Batteries

(* ppr_list_inners : assume that we have opened a box *)
let rec xppr_list_inners val_to_string ff = function
  | [] -> ()
  | [x] -> Format.fprintf ff "%s" (val_to_string x)
  | x::l ->
      Format.fprintf ff "%s;@ " (val_to_string x);
      xppr_list_inners val_to_string ff l

(* ppr_list_inners : assume that we have opened a box *)
let rec ppr_gen_list_inners sepstr ppr_val ff = function
  | [] -> ()
  | [x] -> ppr_val ff x
  | x::l ->
      Format.fprintf ff "%a%s@," ppr_val x sepstr;
      ppr_gen_list_inners sepstr ppr_val ff l

(* %a appears to take two arguments (not put in parens), first a function which
 * takes ff and 'a, then something of type 'a *)
let ppr_list_inners ppr_val ff l = ppr_gen_list_inners "; " ppr_val ff l
let ppr_list ppr_val ff l =
  Format.fprintf ff "@[[%a]@]" (ppr_list_inners ppr_val) l

let ppr_array ppr_val ff a =
  Format.fprintf ff "@[[|%a|]@]" (ppr_list_inners ppr_val) (Array.to_list a)

let ppr_opt ppr_val ff = function
  | Some x -> Format.fprintf ff "Some %a" ppr_val x
  | None -> Format.fprintf ff "None"
let ppr_gfloat ff x = Format.fprintf ff "%g" x

let ppr_bool_list ff l = ppr_list Format.pp_print_bool ff l
let ppr_int_list ff l = ppr_list Format.pp_print_int ff l
let ppr_float_list ff l = ppr_list Format.pp_print_float ff l
let ppr_string_list ff l = ppr_list Format.pp_print_string ff l

let ppr_bool_array ff a = ppr_array Format.pp_print_bool ff a
let ppr_bool_array_array ff a = ppr_array ppr_bool_array ff a
let ppr_int_array ff a = ppr_array Format.pp_print_int ff a
let ppr_int_array_array ff a = ppr_array ppr_int_array ff a
let ppr_float_array ff a = ppr_array Format.pp_print_float ff a
let ppr_float_array_array ff a = ppr_array ppr_float_array ff a
let ppr_string_array ff a = ppr_array Format.pp_print_string ff a

let print_of_ppr ppr_fun x =
  ppr_fun Format.std_formatter x;
  Format.pp_print_newline Format.std_formatter ()

let print_bool_list l = print_of_ppr ppr_bool_list l
let print_bool_array a = print_of_ppr ppr_bool_array a
let print_bool_array_array a = print_of_ppr ppr_bool_array_array a
let print_int_list l = print_of_ppr ppr_int_list l
let print_int_array a = print_of_ppr ppr_int_array a
let print_int_array_array a = print_of_ppr ppr_int_array_array a
let print_float_list l = print_of_ppr ppr_float_list l
let print_float_array a = print_of_ppr ppr_float_array a
let print_float_array_array a = print_of_ppr ppr_float_array_array a
let print_string_list l = print_of_ppr ppr_string_list l
let print_string_array a = print_of_ppr ppr_string_array a
