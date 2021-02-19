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

kenken(N, C, T) :- 
  length(T, N),
  maplist(map_length(N), T),
  maplist(map_fd_domain(1, N), T),
  maplist(cage(T), C),
  maplist(fd_all_different, T),
  transpose(T, Tt),
  maplist(fd_all_different, Tt),
  maplist(fd_labeling, T).

testcase_3(
3, 
  [-(1, [1|1], [2|1]), 
  /(2, [2|1], [3|1]), 
  +(5, [[2|2], [3|1], [3|2]]), 
  *(6, [[2|3], [3|3]])]
).

testcase_4(
4,
  [-(1, [1|1], [1|2]),
  /(2, [1|3], [2|3]),
  *(12, [[4|1],[4|2],[4|3]]),
  +(9, [[3|1], [3|2], [4|2]]),
  +(6, [[3|3],[4|3],[4|4]]),
  /(2, [2|1], [2|2]),
  +(1, [[4|1]])
  ]
).

testcase_6(
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
  ]
).

testcase_4_mult(
  4,
  [
   +(6, [[1|1], [1|2], [2|1]]),
   *(96, [[1|3], [1|4], [2|2], [2|3], [2|4]]),
   -(1, [3|1], [3|2]),
   -(1, [4|1], [4|2]),
   +(8, [[3|3], [4|3], [4|4]]),
   *(2, [[3|4]])
  ]
).

plain_cage_help(_, +(Sum, []), Sum).
plain_cage_help(T, +(Sum, [Sqr | Rest]), Acc) :-
  get(Sqr, T, Val),
  Next_Acc is Acc + Val,
  plain_cage_help(T, +(Sum, Rest), Next_Acc).

plain_cage_help(_, *(Prod, []), Prod).
plain_cage_help(T, *(Prod, [Sqr | Rest]), Acc) :-
  get(Sqr, T, Val),
  Next_Acc is Acc * Val,
  plain_cage_help(T, *(Prod, Rest), Next_Acc).

plain_cage(T, -(Diff, J, K)) :-
  get(J, T, Jval),
  get(K, T, Kval),
  Diff is abs(Jval - Kval).

plain_cage(T, /(Quot, J, K)) :-
  get(J, T, Jval),
  get(K, T, Kval),
  Quot_F is float(Quot),
  Quot_F is max(Jval, Kval) / min(Jval, Kval).

plain_cage(T, +(Sum, Sqrs)) :- plain_cage_help(T, +(Sum, Sqrs), 0).
plain_cage(T, *(Prod, Sqrs)) :- plain_cage_help(T, *(Prod, Sqrs), 1).

list_1_N(0, []).
list_1_N(N, [N|Tl]) :-
  succ(D, N),
  list_1_N(D, Tl).

% plain_kenken/3 does not use the finite domain solver and is thus much slower than kenken/3
% I measured there total real runtimes using the compound term:
%   testcase_4(N, C), statistics(real_time, _), <kenken_solving_predicate>(N, C, T), statistics(real_time, [_,Total_ms]).

% Solving testcase_3 with kenken/3 took real time:
%    0 ms
% Solving testcase_3 with plain_kenken/3 took real time:
%    0 ms

% Solving testcase_4 with kenken/3 took real time:
%    0 ms
% Solving testcase_4 with plain_kenken/3 took real time:
%    48 ms

% Solving testcase_6 with kenken/3 took real time:
%    0 ms
% Solving testcase_6 with plain_kenken/3 hung indefinitely:
%    N/A

plain_kenken(N, C, T) :- 
  length(T, N),
  maplist(map_length(N), T),
  list_1_N(N, L),
  maplist(permutation(L), T),
  transpose(T, Tt),
  maplist(permutation(L), Tt),
  maplist(plain_cage(T), C).

% --- No-op --- %
% A no-op kenken solver would use the same Prolog terms as kenken/3, except the constraint cages in 
% C would need to be of the form [Op_{index}, <target>, <sqrs>], where 
% <target> is an integer arithmetic target, 
% <sqrs> is the list of [Row|Col] squares for this constraint (all ground terms),
% and Op_{index} is a prolog term where {index} is the number constraint in the list C, i.e. Op_1 for the first constraint.
% For possible division or subtraction cages, <sqrs> would become <J>, <K>, where J and K are two [Row|Col] squares.
% Then, the no-op kenken solver would be passed the number of rows and columns N, the list of constraints C, and the grid G, 
% and would unify the Op's in the list of constraints C, as well as the grid T.
% The noop_cage predicates would then be passed terms of the form T, and the constraint C as [Op, Target, Sqrs].
% I went ahead and implemented the noop solver, with an additional operator '=' for cages with only one square,
% since otherwise there would be some ambiguity whether '+' or '*' should be used for these one square cages.

noop_cage(T, [=, Target, Sqr]) :-
  get(Sqr, T, Target).

noop_cage(_, [+, 0, []]).
noop_cage(T, [+, Target, [Sqr|Rest_sqrs]]) :-
  get(Sqr, T, Val),
  Target #= Val + Rem,
  noop_cage(T, [+, Rem, Rest_sqrs]).

noop_cage(_, [*, 1, []]).
noop_cage(T, [*, Target, [Sqr|Rest_sqrs]]) :-
  get(Sqr, T, Val),
  Target #= Val * Rem,
  noop_cage(T, [*, Rem, Rest_sqrs]).

noop_cage(T, [-, Target, J, K]) :-
  get(J, T, Jval),
  get(K, T, Kval),
  Target #= dist(Jval, Kval).

noop_cage(T, [/, Target, J, K]) :-
  get(J, T, Jval),
  get(K, T, Kval),
  Target #= max(Jval, Kval) / min(Jval, Kval).

noop_kenken(N, C, T) :- 
  length(T, N),
  maplist(map_length(N), T),
  maplist(map_fd_domain(1, N), T),
  maplist(noop_cage(T), C),
  maplist(fd_all_different, T),
  transpose(T, Tt),
  maplist(fd_all_different, Tt),
  maplist(fd_labeling, T).

noop_kenken_testcase(N, C, T) :- noop_testcase_6(N, C), noop_kenken(N, C, T).
% This testcase yielded
% | ?- noop_kenken_testcase(N, C, T).
% 
% C = [[+,11,[[1|1],[2|1]]],
%     [/,2,[1|2],[1|3]],
%     [*,20,[[1|4],[2|4]]],
%     [*,6,[[1|5],[1|6],[2|6],[3|6]]],
%     [-,3,[2|2],[2|3]],
%     [/,3,[2|5],[3|5]],
%     [*,240,[[3|1],[3|2],[4|1],[4|2]]],
%     [*,6,[[3|3],[3|4]]],
%     [*,6,[[4|3],[5|3]]],
%     [+,7,[[4|4],[5|4],[5|5]]],
%     [*,30,[[4|5],[4|6]]],
%     [*,6,[[5|1],[5|2]]],
%     [+,9,[[5|6],[6|6]]],
%     [+,8,[[6|1],[6|2],[6|3]]],
%     [/,2,[6|4],[6|5]]]
% N = 6
% T = [[5,6,3,4,1,2],
%      [6,1,4,5,2,3],
%      [4,5,2,3,6,1],
%      [3,4,1,2,5,6],
%      [2,3,6,1,4,5],
%      [1,2,5,6,3,4]] ? ;
% 
% (65 ms) no

% This list of cages C in noop_testcase_6 is the same as the one in testcase_6, but with the operators replaced with variables.
% The noop_kenken/3 predicate was correctly able to produce the same grid T as kenken/3, as well as the same operators in C as testcase_6.

noop_testcase_5(5, 
[
  [Op1, 2, [1|1]],
  [Op2, 6, [[2|1],[3|1]]],
  [Op3, 6, [[4|1],[4|2]]],
  [Op4, 4, [5|1]],
  [Op5, 38, [[1|2],[1|3],[1|4],[2|2],[3|2],[3|3],[3|4],[4|4],[5|2],[5|3],[5|4]]],
  [Op6, 24, [[1|5], [2|3],[2|4],[2|5]]],
  [Op7, 9, [[3|5],[4|5],[5|5]]]
]).

noop_testcase_6(6, 
  [
    [Op1, 11, [[1|1], [2|1]]],
    [Op2, 2, [1|2], [1|3]],
    [Op3, 20, [[1|4], [2|4]]],
    [Op4, 6, [[1|5], [1|6], [2|6], [3|6]]],
    [Op5, 3, [2|2], [2|3]],
    [Op6, 3, [2|5], [3|5]],
    [Op7, 240, [[3|1], [3|2], [4|1], [4|2]]],
    [Op8, 6, [[3|3], [3|4]]],
    [Op9, 6, [[4|3], [5|3]]],
    [Op10, 7, [[4|4], [5|4], [5|5]]],
    [Op11, 30, [[4|5], [4|6]]],
    [Op12, 6, [[5|1], [5|2]]],
    [Op13, 9, [[5|6], [6|6]]],
    [Op14, 8, [[6|1], [6|2], [6|3]]],
    [Op15, 2, [6|4], [6|5]]
  ]
).