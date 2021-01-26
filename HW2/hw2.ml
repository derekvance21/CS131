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

let rec use_rule rule producer accepter frag =
  match rule with 
  | [] -> accepter frag (* if there are no more symbols in the rule, return result of accepter frag *)
  | rule_hd::rule_tl -> match (rule_hd, frag) with
    (* This is like saying, for all the rules that this nonterimal entails, make sure that they can accept the rest of the current rule *)
    | (N nonterm, frag) -> use_rules (producer nonterm) producer (use_rule rule_tl producer accepter) frag
    (* if the symbol is a terminal, then check if the hd of frag equals the symbol, if so, call use_rule on the rest of the rule, else, None *)
    | (T term, frag_hd::frag_tl) when frag_hd = term -> use_rule rule_tl producer accepter frag_tl
    | _ -> None

and use_rules rules producer accepter frag = 
  match rules with 
  | [] -> None
  | rules_hd::rules_tl -> 
    match use_rule rules_hd producer accepter frag with
    | Some suffix -> Some suffix
    | None -> use_rules rules_tl producer accepter frag

let make_matcher = function
  | (start_symbol, producer) ->
    fun accepter frag -> use_rules (producer start_symbol) producer accepter frag

let make_parser gram = 
  make_matcher gram accept_all
