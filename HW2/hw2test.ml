type english_nonterminals = | S | NP | VP | PP | NOM | Det | Noun | Adj | Verb | ProNoun | ProperNoun | Prep

let english_grammar = 
  (S, 
    function 
      | S -> [[N NP;N VP]]
      | NP -> [[N ProNoun];[N ProperNoun];[N Det; N NOM]]
      | NOM -> [[N Adj; N NOM];[N Noun; N NOM]; [N Noun]]
      | VP -> [[N Verb];[N Verb;N NP];[N Verb; N NP; N PP];[N Verb; N PP]]
      | PP -> [[N Prep; N NP]]
      | Det -> [[T "the"]; [T "a"]; [T "an"]; [T "that"]]
      | Noun -> [[T "agent"];[T "spy"];[T "cheese"];[T "cat"];[T "sunset"]; [T "sunrise"]; [T "snack"]; [T "time"]]
      | Adj -> [[T "secret"];[T "sumptuous"]; [T "brown"]; [T "sophisticated"]]
      | Verb -> [[T "eats"];[T "loves"]; [T "seeks"]; [T "is"]; [T "begins"]; [T "ends"]]
      | ProNoun -> [[T "I"]; [T "it"]; [T "you"]]
      | ProperNoun -> [[T "UCLA"]; [T "Los"; T "Angeles"]; [T "Sylvester"; T "Stallone"]]
      | Prep -> [[T "from"]; [T "to"];[T "on"]; [T "alongside"]; [T "in"]])

let english_frag = ["the";"sophisticated";"secret";"agent";"spy";"cat";"seeks";"a";"sumptuous";"sunset";"snack";"alongside";"Sylvester";"Stallone"]

let make_matcher_test = ((make_matcher english_grammar accept_empty_suffix english_frag) = Some [])

let make_parser_test = match make_parser english_grammar english_frag with 
| Some parse_tree -> ((parse_tree_leaves parse_tree) = english_frag)
| None -> false
