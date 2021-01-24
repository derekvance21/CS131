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

let rec parse_tree_leaves tree = 
  match tree with
  | Leaf lf -> [lf]
  | Node (_, subtrees) -> (List.concat (List.map parse_tree_leaves subtrees))

type 'terminal fragment = 'terminal list
type ('terminal, 'result) acceptor = 'terminal fragment -> 'result option

let accept_all string = Some string
let accept_empty_suffix = function
   | _::_ -> None
   | x -> Some x

type ('terminal, 'result) matcher =
  ('terminal, 'result) acceptor -> 'terminal fragment -> 'result option

let rec use_rule rule frag producer accepter =
  match rule with 
  | [] -> accepter frag (* if there are no more symbols in the rule, return result of accepter frag *)
  | rule_hd::rule_tl -> match (rule_hd, frag) with
    (* if the symbol is a terminal, then check if the hd of frag equals the symbol, if so, call use_rule on the rest of the rule, else, None *)
    | (_, []) -> None
    | (N nonterm, frag) -> (match use_rules (producer nonterm) frag producer accepter with (* THIS NEEDS WORK *)
      | Some suffix -> use_rule rule_tl suffix producer accepter
      | None -> None
    )
    | (T term, frag_hd::frag_tl) when frag_hd = term -> use_rule rule_tl frag_tl producer accepter
    | _ -> None

and use_rules rules frag producer accepter = 
  match rules with 
  | [] -> None
  | rules_hd::rules_tl -> (* need a function for if applying the rule 'hd' to frag works *)
  (* if the frag matches the rule 'hd', return the result of accepter frag
    if not, then recursively pass the same frag to the rules that are left: 'tl'
   *)
    match use_rule rules_hd frag producer accepter with
    | Some suffix -> Some suffix
    | None -> use_rules rules_tl frag producer accepter

let make_matcher = function
  | (start_symbol, producer) ->
    fun acceptor -> function 
    (* this is the fragment argument *)
    | hd::tl -> Some hd
    | [] -> None