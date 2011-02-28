(* generate reStructuredText *)

open Fam_batteries

let underline_levels = StringFuns.to_char_array "=-~`'\""

let underline_of_str s level =
  String.make (String.length s) underline_levels.(level)

let write_section_title ch s level =
  Printf.fprintf ch "%s\n%s\n" s (underline_of_str s level)

let write_top_title ch s =
  Printf.fprintf ch "%s\n" (underline_of_str s 0);
  write_section_title ch s 0

let write_literal_block_start ch =
  Printf.fprintf ch "\n::\n\n"

let write_option ch flagstr description =
  Printf.fprintf ch "%s  %s\n" flagstr description

