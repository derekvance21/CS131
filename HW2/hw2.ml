type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal

let alternative_list rules nonterminal = 
  List.map 
    (function (_, rhs) -> rhs) 
    (List.filter (function (lhs, _) -> lhs == nonterminal) rules)

let convert_grammar = 
  function (start_symbol, rules) ->
    (start_symbol, fun nonterminal -> alternative_list rules nonterminal)

type ('nonterminal, 'terminal) parse_tree =
  | Node of 'nonterminal * ('nonterminal, 'terminal) parse_tree list
  | Leaf of 'terminal

let rec parse_tree_leaves = function
  | Leaf lf -> [lf]
  | Node (_, subtrees) -> (List.concat (List.map parse_tree_leaves subtrees))

type 'terminal fragment = 'terminal list
type ('terminal, 'result) acceptor = 'terminal fragment -> 'result option

let accept_all frag = Some frag
let accept_empty_suffix = function
   | _::_ -> None
   | x -> Some x

type ('terminal, 'result) matcher =
  ('terminal, 'result) acceptor -> 'terminal fragment -> 'result option

let rec match_rule rule producer accepter frag =
  match rule with 
  | [] -> accepter frag (* if there are no more symbols in the rule, return result of accepter frag *)
  | symbol::rest_symbols -> 
    let accepter_rest_symbols = match_rule rest_symbols producer accepter in
    match (symbol, frag) with
    (* This is like saying, for all the rules that this nonterimal entails, make sure that they can accept the rest of the current rule *)
    | (N nonterm, frag) -> match_rules (producer nonterm) producer accepter_rest_symbols frag (* is like append_matchers (stricter than below) *)
    (* if the symbol is a terminal, then check if the hd of frag equals the symbol, if so, call match_rule on the rest of the rule, else, None *)
    | (T term, frag_hd::frag_tl) when frag_hd = term -> accepter_rest_symbols frag_tl
    | _ -> None

and match_rules rules producer accepter frag = 
  match rules with 
  | [] -> None
  | rule::rest_rules -> 
    match match_rule rule producer accepter frag with (* is like make_or_matcher *)
    | Some suffix -> Some suffix (* Some rule::suffix *)
    | None -> match_rules rest_rules producer accepter frag

let make_matcher = function
  | (start_symbol, producer) ->
    fun accepter frag -> match_rules (producer start_symbol) producer accepter frag

let rec parse_match_rule rule producer accepter frag =
  match rule with 
  | [] -> accepter frag (* if there are no more symbols in the rule, return result of accepter frag *)
  | symbol::rest_symbols -> 
    let accepter_rest_symbols = parse_match_rule rest_symbols producer accepter in
    match (symbol, frag) with
    (* This is like saying, for all the rules that this nonterimal entails, make sure that they can accept the rest of the current rule *)
    | (N nonterm, frag) -> parse_match_rules nonterm (producer nonterm) producer accepter_rest_symbols frag (* is like append_matchers (stricter than below) *)
    (* if the symbol is a terminal, then check if the hd of frag equals the symbol, if so, call parse_match_rule on the rest of the rule, else, None *)
    | (T term, frag_hd::frag_tl) when frag_hd = term -> accepter_rest_symbols frag_tl
    | _ -> None

and parse_match_rules symbol rules producer accepter frag = 
  match rules with 
  | [] -> None
  | rule::rest_rules -> 
    match parse_match_rule rule producer accepter frag with (* is like make_or_matcher *)
    | Some suffix -> Some ((symbol, rule)::suffix)
    | None -> parse_match_rules symbol rest_rules producer accepter frag

let parse_accept = function
| _::_ -> None
| _ -> Some []

let rec construct_node rules_list = 
  match rules_list with
  | rule::rest_rules -> 
    let (path, children) = add_children rest_rules (snd rule) in
    (path, Node((fst rule), children))

and add_children rules_list rule = 
  match rule with
  | [] -> (rules_list, [])
  | (T terminal)::rest_symbols -> 
    let (rules_left, tree) = add_children rules_list rest_symbols in
      (rules_left, (Leaf terminal)::tree)
  | (N nonterminal)::rest_symbols -> 
    let (rules_left, tree) = construct_node rules_list in
    let (rules_left_after_siblings, sibling_trees) = add_children rules_left rest_symbols in
      (rules_left_after_siblings, tree::sibling_trees)

let gen_parser_rules = function 
| (start_symbol, producer) -> fun frag ->
  parse_match_rules start_symbol (producer start_symbol) producer parse_accept frag

let make_parser gram frag =
    match gen_parser_rules gram frag with
    | Some rules -> let (_, tree) = construct_node rules in Some tree
    | None -> None
