let subset a b = 
  List.for_all (
    fun ax -> (List.exists (
      fun bx -> ax = bx
    ) b)
  ) a;;

let equal_sets a b =
  subset a b && subset b a;;

let set_union a b =
  List.append a b;;

let set_symdiff a b =
  List.filter (
    (fun abx -> not ((
        List.exists (fun ax -> abx = ax) a
      ) && (
        List.exists (fun bx -> abx = bx) b
      ))
    )
  ) (set_union a b)

(* 
  It is impossible to write a self_member s function because of OCaml's type system. 
  A set s is of type 'a list, meaning members of s can only be of type 'a.
  Thus, because s is of type 'a list but requires members to be of type 'a,
  s cannot be a member of itself.
 *)

let rec computed_fixed_point eq f x = 
  let fx = f x in
  if eq x fx
    then x
    else computed_fixed_point eq f fx;;
  
type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal

let get_reachable_symbols rules_and_reachable_symbols = 
  let rec filter_non_terminals rhs = 
    match rhs with
    | [] -> []
    | (N nts)::rst -> nts::(filter_non_terminals rst)
    | hd::rst -> filter_non_terminals rst
  in

  let rec get_reachable_symbols_rec rules reachable_symbols = 
  match rules with 
  | [] -> (rules, reachable_symbols)
  | (lhs, rhs)::rest_rules when subset [lhs] reachable_symbols ->
    get_reachable_symbols_rec
      rest_rules (set_union reachable_symbols (filter_non_terminals rhs))
  | _ -> get_reachable_symbols_rec (List.tl rules) reachable_symbols
  in

  let (rules, reachable_symbols) = rules_and_reachable_symbols in
  let (_, calc_reachable_symbols) = get_reachable_symbols_rec rules reachable_symbols in
  (rules, calc_reachable_symbols)

let filter_reachable g = 
  let equal_reachable_symbol_sets a b = 
  let (_, a2) = a and (_, b2) = b in
    equal_sets a2 b2 
  in

  let (start_symbol, rules) = g in
  let (_, reachable_symbols) = computed_fixed_point equal_reachable_symbol_sets get_reachable_symbols (rules, [start_symbol]) in
  (start_symbol, List.filter (fun rule -> let (lhs, _) = rule in subset [lhs] reachable_symbols) rules)
