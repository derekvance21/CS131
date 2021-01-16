let my_subset_test0 = subset [3;3;2;3] [1;2;3;4;5]
let my_subset_test1 = subset [1.2;2.2] [3.0;2.2;1.1;1.2;1.3]
let my_subset_test2 = subset ['o';'n';'i';'o';'n'] ['u';'n';'i';'o';'n']
let my_subset_test3 = not (subset ["rectangle"] ["square";"rhombus"])
let my_subset_test4 = not (subset [0] [])
let my_subset_test5 = not (subset ['a'] ['A'])

let my_equal_sets_test0 = equal_sets [] []
let my_equal_sets_test1 = equal_sets [10.0;5.0] [5.0;10.0;5.0]
let my_equal_sets_test2 = not (equal_sets [1;2;4;8] [1;2;4;8;16])
let my_equal_sets_test3 = not (equal_sets ["dog";"dog";"dog";"dog";"cat"] ["dog"])

let my_set_union_test0 = equal_sets (set_union [2;2;2;1] [1;1;1]) [1;2]
let my_set_union_test1 = equal_sets (set_union [] []) []
let my_set_union_test2 = not (equal_sets (set_union ["d";"o";"g"] []) ["dog"])

let my_set_symdiff_test0 = subset (set_symdiff ['A';'B'] ['B';'C']) (set_union ['A';'B'] ['B';'C']) 
let my_set_symdiff_test1 = equal_sets (set_symdiff [10;9;8] [7;8;9;10;11]) [7;11]
let my_set_symdiff_test2 = equal_sets (set_symdiff ["wolf";"husky"] ["pug";"husky"]) ["wolf";"pug"]

let my_computed_fixed_point_test0 =
  computed_fixed_point (=) (fun x -> x / 2 + 42) 1000 = 84
let my_computed_fixed_point_test1 =
  computed_fixed_point (=) (fun x -> x *. x) 1. = 1.
let my_computed_fixed_point_test2 =
  computed_fixed_point (=) (fun x -> x *. x) 1.001 = infinity
let my_computed_fixed_point_test3 =
  computed_fixed_point (=) (fun x -> x *. x) 0.999 = 0.
let my_computed_fixed_point_test4 =
  computed_fixed_point (fun x y -> (x mod 10) = (y mod 10)) (fun x -> x * x) 2 = 16
let my_computed_fixed_point_test5 =
  equal_sets (computed_fixed_point equal_sets (fun x -> set_union x ["wolf"]) []) ["wolf"]

type english_nonterminals =
  | S | NP | VP | Adv | Noun | Verb | Adj

let english_rules = [
    S, [N NP; N VP; T "."];
    NP, [T"the"; N Noun];
    NP, [T"the"; N Adj; N Noun];
    VP, [N Verb];
    VP, [N Verb; N NP];
    VP, [N Verb; N Adv];
    Noun, [T"dog"];
    Noun, [T"cat"];
    Noun, [T"cookie"];
    Verb, [T"ate"];
    Verb, [T"asked"];
    Adj, [T"brown"];
    Adj, [T"ferocious"];
    Adj, [T"tasty"];
    Adv, [T"rapidly"];
    Adv, [T"cautiously"]
]

let my_filter_reachable_test_0 = filter_reachable (S, english_rules) = (S, english_rules)
let my_filter_reachable_test_1 = filter_reachable (VP, english_rules) = (VP, List.tl english_rules)
let my_filter_reachable_test_2 = filter_reachable (NP, english_rules) != (NP, List.tl english_rules)
let my_filter_reachable_test_3 = filter_reachable 
    (Verb, set_union (List.tl english_rules) [Verb, [N VP; T"???"; N NP]]) = (Verb, set_union (List.tl english_rules) [Verb, [N VP; T"???"; N NP]])
let my_filter_reachable_test_4 = filter_reachable (Adv, english_rules) = (Adv, [Adv, [T"rapidly"]; Adv, [T"cautiously"]])