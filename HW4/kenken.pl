transpose([[]|_], []).
transpose(Matrix, [Row|Rest_rows]) :-
    transpose_col(Matrix, Row, Rest_matrix),
    transpose(Rest_matrix, Rest_rows).

transpose_col([], [], []).
transpose_col([[Eq|Rest_1st_row]|Rest_rows], [Eq|Row_tl], [Rest_1st_row|Rest_matrix]) :-
    transpose_col(Rest_rows, Row_tl, Rest_matrix).

get([I|J], T, Val) :- 
    nth(I, T, Row),
    nth(J, Row, Val).
    % fd_exactly(1, Row, Val).
    % fd_element_var(I, T, Row),
    % fd_element_var(J, Row, Val).

cage(_, +(0, [])).
cage(T, +(Sum, [Sqr | Rest])) :-
    get(Sqr, T, Val),
    Sum #= Val + Rem,
    cage(T, +(Rem, Rest)).

cage(_, *(1, [])).
cage(T, *(Prod, [Sqr | Rest])) :-
    get(Sqr, T, Val),
    Prod #= Val * Rem,
    cage(T, *(Rem, Rest)).

cage(T, -(Diff, J, K)) :-
    get(J, T, Jval),
    get(K, T, Kval),
    Diff #= dist(Jval, Kval).

cage(T, /(Quot, J, K)) :-
    get(J, T, Jval),
    get(K, T, Kval),
    Quot #= max(Jval, Kval) / min(Jval, Kval).

map_fd_domain(Low, High, Var) :- fd_domain(Var, Low, High).
map_length(N, L) :- length(L, N).

cages(T, C) :-
  maplist(cage(T), C).

constraint(N, T) :-
  length(T, N),
  maplist(map_length(N), T),
  maplist(map_fd_domain(1, N), T),
  maplist(fd_all_different, T).

kenken(N, C, T) :- 
    length(T, N),
    maplist(map_length(N), T),
    maplist(map_fd_domain(1, N), T),
    cages(T, C),
    maplist(fd_all_different, T),
    transpose(T, Tt),
    maplist(fd_all_different, Tt),
    maplist(fd_labeling, T).

testE(T) :-
  kenken(3, [], T).

test3(T) :- kenken(3, [
  -(1, [1|1], [2|1]), 
  /(2, [2|1], [3|1]), 
  +(5, [[2|2],[3|1],[3|2]]), 
  *(6, [[2|3],[3|3]])], T).

test4(T) :-
  kenken(
    4,
      [-(1, [1|1], [1|2]),
      /(2, [1|3], [2|3]),
      *(12, [[4|1],[4|2],[4|3]]),
      +(9, [[3|1], [3|2], [4|2]]),
      +(6, [[3|3],[4|3],[4|4]]),
      /(2, [2|1], [2|2]),
      +(1, [[4|1]])
      ], 
    T
  ).

test6(T) :- 
  kenken(
    6, 
      [
   +(11, [[1|1], [2|1]]),
   /(2, [1|2], [1|3]),
   *(20, [[1|4], [2|4]]),
   *(6, [[1|5], [1|6], [2|6], [3|6]]),
   -(3, [2|2], [2|3]),
   /(3, [2|5], [3|5]),
   *(240, [[3|1], [3|2], [4|1], [4|2]]),
   *(6, [[3|3], [3|4]]),
   *(6, [[4|3], [5|3]]),
   +(7, [[4|4], [5|4], [5|5]]),
   *(30, [[4|5], [4|6]]),
   *(6, [[5|1], [5|2]]),
   +(9, [[5|6], [6|6]]),
   +(8, [[6|1], [6|2], [6|3]]),
   /(2, [6|4], [6|5])
  ], 
    T
  ).

test4_mult(T) :- 
  kenken(
  4,
  [
   +(6, [[1|1], [1|2], [2|1]]),
   *(96, [[1|3], [1|4], [2|2], [2|3], [2|4]]),
   -(1, [3|1], [3|2]),
   -(1, [4|1], [4|2]),
   +(8, [[3|3], [4|3], [4|4]]),
   *(2, [[3|4]])
  ],
  T
), write(T), nl, fail.