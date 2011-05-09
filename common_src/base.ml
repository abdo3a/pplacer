(* some basic functions.
 *
 * This definitely needs some cleaning out, as much functionality isn't used or
 * duplicated somewhere else.
 *
 * Some of the code here is not very good!
*)

open MapsSets

let round x = int_of_float (floor (x +. 0.5))

(*
# int_pow 10. 3;;
- : float = 1000.
# int_pow 10. 0;;
- : float = 1.
*)
let int_pow x n =
  assert(n >= 0);
  let rec aux accu i = if i=0 then accu else aux (x*.accu) (i-1) in
  aux 1. n

let date_time_str () =
  let the_time = Unix.localtime (Unix.time ()) in
  Printf.sprintf "%02d/%02d/%d %02d:%02d:%02d"
    (the_time.Unix.tm_mon+1)
    the_time.Unix.tm_mday
    (the_time.Unix.tm_year+1900)
    the_time.Unix.tm_hour
    the_time.Unix.tm_min
    the_time.Unix.tm_sec

let safe_chop_extension s =
  try Filename.chop_extension s with | Invalid_argument _ -> s

let safe_chop_suffix name suff =
  if Filename.check_suffix name suff then Filename.chop_suffix name suff
  else name

(* pull_each_out :
# pull_each_out [1;2;3];;
- : (int * int list) list = [(1, [2; 3]); (2, [1; 3]); (3, [1; 2])]
*)
let pull_each_out init_list =
  let rec aux all_pairs start = function
    | x::l ->
        aux ((x, List.rev_append start l)::all_pairs) (x::start) l
    | [] -> all_pairs
  in
  List.rev (aux [] [] init_list)


(* funny.
# list_sub 4 [1;2;3;4;5;6;7;8];;
- : int list = [1; 2; 3; 4]
# list_sub ~start:2 ~len:4 [1;2;3;4;5;6;7;8];;
- : int list = [3; 4; 5; 6]
 * *)
let list_sub ?start:(start=0) ~len l =
  Array.to_list (Array.sub (Array.of_list l) start len)


exception Different of int

let raise_if_different cmp x1 x2 =
  let c = cmp x1 x2 in
  if c <> 0 then raise (Different c)

(* get the unique items from a list
 * slow, clearly.
 *)
let list_uniques linit =
  List.rev (
    List.fold_left (
      fun l x ->
        if List.mem x l then l
        else x :: l
    ) [] linit )

(*
# list_find_loc 2 [0;1;2;3;4;5;6;7];;
- : int = 2
*)
let list_find_loc x l =
  let rec aux i = function
    | hd::tl -> if x = hd then i else aux (i+1) tl
    | [] -> raise Not_found
  in
  aux 0 l


(* given f and a list, apply f to all unordered pairs of the list.
# list_iterpairs (Printf.printf "(%d,%d)\t") [1;2;3];;
(1,2)   (1,3)   (2,3)   - : unit = ()
 * *)
let rec list_iterpairs f = function
  | x::l -> List.iter (f x) l; list_iterpairs f l
  | [] -> ()

(* apply f to each pair in each pairing of the lists
# list_list_iterpairs (Printf.printf "(%d,%d)\t") [[1;2];[3];[4;5]];;
(1,3)   (2,3)   (1,4)   (1,5)   (2,4)   (2,5)   (3,4)   (3,5)   - : unit = ()
* note that we don't get (1,2).
*)
let list_list_iterpairs f ll =
  list_iterpairs
    (fun l1 l2 ->
      List.iter
        (fun x -> List.iter (fun y -> f x y) l2)
        l1)
    ll

(* get from map, but return an empty list if not in map *)
let get_from_list_intmap id m =
  if IntMap.mem id m then IntMap.find id m
  else []

(*
# let divbyk k x = x mod k = 0;;
val divbyk : int -> int -> bool = <fun>
# let x = find_multiple_matches [divbyk 2; divbyk 3] [1;2;3;4;5;6;7;8];;
val x : int list = [6]
*)
let find_multiple_matches f_list =
  let rec aux accu = function
    | [] -> List.rev accu
    | x::l ->
        if (List.fold_left
             (fun accu f ->
               accu+(if f x then 1 else 0))
             0
             f_list)
           > 1 then
             aux (x::accu) l
        else
          aux accu l
  in
  aux []


let combine_over_intmaps combine_fun keys m1 m2 =
  try
    List.fold_right
      (fun key -> IntMap.add key
                    (combine_fun (IntMap.find key m1) (IntMap.find key m2)))
      keys
      IntMap.empty
  with
  | Not_found -> invalid_arg "combine_over_maps: key not contained in map!"


(* 'a MapsSets.IntMap.t list -> 'a list MapsSets.IntMap.t = <fun>
 * combine all the maps into a single one, with k bound to a list of all of the
 * bindings for k in map_list.
 *)
let combine_intmaps_listly map_list =
  List.fold_right
    (fun m ->
      IntMap.fold
        (fun k v sofar ->
          if IntMap.mem k sofar then
            IntMap.add k (v::(IntMap.find k sofar)) sofar
          else
            IntMap.add k [v] sofar)
        m)
    (List.rev map_list) (* the above rev's things *)
    IntMap.empty

(*
 * 'a list MapsSets.IntMap.t list -> 'a list MapsSets.IntMap.t = <fun>
 * combine all the maps into a single one, with k bound to the concatenated set
 * of bindings for k in map_list.
 *)
let combine_list_intmaps map_list =
  IntMap.map
    List.flatten
    (combine_intmaps_listly map_list)


(* mask_to_list:
 * Mask an array into a list
 *)
let mask_to_list mask_arr a =
  assert(Array.length mask_arr = Array.length a);
  let masked = ref [] in
(* count down so that we don't have to reverse after adding them *)
  for i = Array.length mask_arr - 1 downto 0 do
    if mask_arr.(i) then masked := a.(i)::!masked
  done;
  !masked

(* the L_1 norm of a float list *)
let normalized_prob fl =
  let sum = List.fold_left ( +. ) 0. fl in
  List.map (fun x -> x /. sum) fl

(* the L_1 norm of a float array *)
let arr_normalized_prob fa =
  let sum = Array.fold_left ( +. ) 0. fa in
  Array.map (fun x -> x /. sum) fa

(* ll_normalized_prob :
 * ll_list is a list of log likelihoods. this function gives the normalized
 * probabilities, i.e. exponentiate then our_like / (sum other_likes)
 * have to do it this way to avoid underflow problems.
 * *)
let ll_normalized_prob ll_list =
  List.map
    (fun log_like ->
      1. /.
        (List.fold_left ( +. ) 0.
          (List.map
            (fun other_ll -> exp (other_ll -. log_like))
            ll_list)))
    ll_list

let time_fun f =
  let prev = Sys.time () in
  f ();
  ((Sys.time ()) -. prev)

let print_time_fun name f =
  Printf.printf "%s took %g seconds\n" name (time_fun f)

(* iter over all ordered pairs in a list.
# let print_pair = Printf.printf "(%d,%d) ";;
val print_pair : int -> int -> unit = <fun>
# list_iter_over_pairs_of_single print_pair [1;2;3;4];;
(1,2) (1,3) (1,4) (2,3) (2,4) (3,4) - : unit = ()
*)
let rec list_iter_over_pairs_of_single f = function
  | x::l ->
      List.iter (fun y -> f x y) l;
      list_iter_over_pairs_of_single f l
  | [] -> ()

let list_pairs_of_single l =
  let rec aux accum = function
    | x :: l ->
      aux
        (List.rev_append
           (List.map (fun y -> x, y) l)
           accum)
        l
    | [] -> accum
  in
  aux [] l

(* iter over pairs from two lists.
# list_iter_over_pairs_of_two print_pair [1;3] [4;5];;
(1,4) (1,5) (3,4) (3,5) - : unit = ()
*)
let list_iter_over_pairs_of_two f l1 l2 =
  List.iter (fun x -> List.iter (f x) l2) l1

(* find the first element of an array satisfying a predicate *)
let array_first f a =
  let n = Array.length a in
  let rec aux i =
    if i >= n then invalid_arg "array_first: no first!"
    else if f (Array.unsafe_get a i) then i
    else aux (i+1)
  in
  aux 0

(* find the last element of an array satisfying a predicate *)
let array_last f a =
  let rec aux i =
    if i < 0 then invalid_arg "array_last: no last!"
    else if f (Array.unsafe_get a i) then i
    else aux (i-1)
  in
  aux ((Array.length a)-1)

let rec find_zero_pad_width n =
  assert(n>=0);
  if n <= 9 then 1
  else 1+(find_zero_pad_width (n/10))

let quote_regex = Str.regexp "'"
let sqlite_escape s =
  Printf.sprintf "'%s'" (Str.global_replace quote_regex "''" s)

(* parsing *)
exception Syntax_error of int * int

let rec first_match groups s =
  match groups with
    | g :: rest ->
      begin
        try
          g, Str.matched_group g s
        with
          | Not_found -> first_match rest s
      end
    | [] -> raise Not_found

let pos s ch =
  let rec aux pos line =
    try
      let pos' = String.index_from s pos '\n' in
      if pos' >= ch then
        line, ch - pos
      else
        aux (succ pos') (succ line)
    with
      | Not_found -> line, ch - pos
  in aux 0 1

let tokenize_string regexp to_token ?eof_token s =
  let rec aux en accum =
    if String.length s = en then
      accum
    else if Str.string_match regexp s en then
      let accum =
        try
          (to_token s) :: accum
        with
          | Not_found -> accum
      in aux (Str.match_end ()) accum
    else
      let line, col = pos s en in
      raise (Syntax_error (line, col))
  in
  let res = aux 0 [] in
  List.rev begin match eof_token with
    | Some tok -> tok :: res
    | None -> res
  end

let map_and_flatten f l =
  List.rev
    (List.fold_left
       (fun accum x -> List.rev_append (f x) accum)
       []
       l)

