%token EOF COLON SEMICOLON COMMA LPAREN RPAREN LBRACK RBRACK LBRACE RBRACE
%token <string> LABEL

%start tree
%type <Newick_bark.newick_bark Gtree.gtree> tree
%%

%{
open Ppatteries
open Newick_parse_state

(* parse state *)
type ps = {
  stree: Stree.stree;
  bark: Newick_bark.newick_bark IntMap.t;
  my_bark: Newick_bark.newick_bark IntMap.t;
}
(* list parse state *)
type lps = {
  stree_l: Stree.stree list;
  bark_l: Newick_bark.newick_bark IntMap.t;
  my_bark_l: Newick_bark.newick_bark IntMap.t;
}

let combine = IntMap.fold IntMap.add
let empty_lps = {stree_l = []; bark_l = IntMap.empty; my_bark_l = IntMap.empty}
let lps_append lp lps =
  {lps with
    stree_l = lp.stree :: lps.stree_l;
    bark_l = combine lp.bark lp.my_bark |> combine lps.bark_l}

let add_bark add_fun x s =
  {s with my_bark = add_fun (Stree.top_id s.stree) x s.my_bark}
let add_bl = add_bark Newick_bark.map_set_bl
let add_node_label = add_bark Newick_bark.map_set_node_label
let add_edge_label = add_bark Newick_bark.map_set_edge_label
let add_id id lp =
  {lp with
    stree = Stree.of_id id lp.stree;
    my_bark =
      try
        let value, bark' = Stree.top_id lp.stree
          |> flip IntMap.extract lp.my_bark
        in
        IntMap.add id value bark'
      with Not_found -> lp.my_bark
  }

let add_leaf () =
  incr node_num;
  {
    stree = Stree.leaf !node_num;
    bark = IntMap.empty;
    my_bark = IntMap.empty;
  }
let add_internal ls =
  incr node_num;
  {
    stree = Stree.node !node_num ls.stree_l;
    bark = combine ls.bark_l ls.my_bark_l;
    my_bark = IntMap.empty;
  }

let bl x tok =
  Sparse.try_map float_of_string x tok "branch lengths must be floats"
let node_number x tok =
  Sparse.try_map int_of_string x tok "node numbers must be integers"
let check_legacy tok =
  if !legacy_format then
    Sparse.parse_error tok "braced node numbers not allowed in legacy format"
let add_id_or_edge_label x tok =
  if !legacy_format then
    add_id (node_number x tok)
  else
    add_edge_label x

%}

node_labeled_leaf:
  | LABEL
      { add_leaf () |> add_node_label $1 }

lengthy_leaf:
  | COLON LABEL
      { add_leaf () |> add_bl (bl $2 2) }
  | node_labeled_leaf COLON LABEL
      { add_bl (bl $3 3) $1 }
  | node_labeled_leaf { $1 }

node_numbered_leaf:
  | LBRACE LABEL RBRACE
      { check_legacy 1; add_leaf () |> add_id (node_number $2 2) }
  | lengthy_leaf LBRACE LABEL RBRACE
      { check_legacy 2; add_id (node_number $3 3) $1 }
  | lengthy_leaf { $1 }

leaf:
  | LBRACK LABEL RBRACK
      { add_leaf () |> add_id_or_edge_label $2 2 }
  | node_numbered_leaf LBRACK LABEL RBRACK
      { add_id_or_edge_label $3 3 $1 }
  | node_numbered_leaf { $1 }

subtree_list:
  | subtree COMMA subtree_list
      { lps_append $1 $3 }
  | subtree
      { lps_append $1 empty_lps }

bare_subtree_group:
  | LPAREN subtree_list RPAREN
      { add_internal $2 }

node_labeled_subtree_group:
  | bare_subtree_group LABEL
      { add_node_label $2 $1 }
  | bare_subtree_group { $1 }

lengthy_subtree_group:
  | node_labeled_subtree_group COLON LABEL
      { add_bl (bl $3 3) $1 }
  | node_labeled_subtree_group { $1 }

node_numbered_subtree_group:
  | lengthy_subtree_group LBRACE LABEL RBRACE
      { check_legacy 2; add_id (node_number $3 3) $1 }
  | lengthy_subtree_group { $1 }

subtree_group:
  | node_numbered_subtree_group LBRACK LABEL RBRACK
      { add_id_or_edge_label $3 3 $1 }
  | node_numbered_subtree_group { $1 }

subtree: /* empty */ { add_leaf () }
  | subtree_group { $1 }
  | leaf { $1 }

bare_tree:
  | subtree SEMICOLON
      { $1 }
  | subtree { $1 }

tree:
  | bare_tree EOF
      { Gtree.gtree $1.stree (combine $1.bark $1.my_bark) }
  | error EOF
      { Sparse.parse_error 1 "syntax error parsing" }
