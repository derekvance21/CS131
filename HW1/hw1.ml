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

let self_member s = s;;

let rec computed_fixed_point eq f x = 
  let fx = f x in
  if eq x fx
    then x
    else computed_fixed_point eq f fx;;
  
type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal