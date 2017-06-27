init_agent:-
	retractall(agent_location(_,_)),
	retractall(agent_orientation(_)),
	retractall(agent_in_cave(_)),
	retractall(agent_health(_)),
	retractall(agent_gold(_)),
	retractall(agent_arrows(_)),
	assert(agent_location(1,1)),
	assert(agent_orientation(0)),
	assert(agent_in_cave(yes)),
	assert(agent_health(alive)),
	assert(agent_gold(0)),
	assert(agent_arrows(1)).

restart_agent:-
	retractall(agent_location(_,_)),
	retractall(agent_orientation(_)),
	retractall(agent_in_cave(_)),
	retractall(agent_health(_)),
	retractall(agent_gold(_)),
	retractall(agent_arrows(_)),
	assert(agent_location(1,1)),
	assert(agent_orientation(0)),
	assert(agent_in_cave(yes)),
	assert(agent_health(alive)),
	assert(agent_gold(0)),
	assert(agent_arrows(1)).

start_point(1, 1).

% set goal as either gold location or back to start point
formulate_goal(X, Y) :-
	agent_gold(0),
	gold(X, Y),
	not(pit(X, Y)).

formulate_goal(X, Y) :-
	X = 1, Y = 1.

% Search predicate - search(X_Goal, Y_Goal, Next_Action)

% at any gold location
search(_, _, Action) :-
	agent_location(X, Y),
	gold(X, Y),
	Action = grab.

% at goal state
search(X, Y, Action) :-
	agent_location(X, Y),
	start_point(X, Y),
	Action = climb.

search(X, Y, Action) :-
	agent_location(X, Y),
	Action = grab.

% just next to the goal location
search(X, Y, Action) :-
	agent_location(X-1, Y),
	(agent_orientation(0) -> Action = goforward ; Action = turnright).

search(X, Y, Action) :-
	agent_location(X, Y+1),
	(agent_orientation(270) -> Action = goforward ; Action = turnright).

search(X, Y, Action) :-
	agent_location(X+1, Y),
	(agent_orientation(180) -> Action = goforward ; Action = turnright).

search(X, Y, Action) :-
	agent_location(X, Y-1),
	(agent_orientation(90) -> Action = goforward ; Action = turnright).

% shoot wumpus if in line with it
search(_, _, Action) :-
	agent_orientation(0),
	wumpus_health(alive),
	agent_location(X, Y),
	wumpus_location(Xw, Y),
	Xw > X,
	Action = shoot.

search(_, _, Action) :-
	agent_orientation(90),
	wumpus_health(alive),
	agent_location(X, Y),
	wumpus_location(X, Yw),
	Yw > Y,
	Action = shoot.

search(_, _, Action) :-
	agent_orientation(180),
	wumpus_health(alive),
	agent_location(X, Y),
	wumpus_location(Xw, Y),
	Xw < X,
	Action = shoot.

search(_, _, Action) :-
	agent_orientation(270),
	wumpus_health(alive),
	agent_location(X, Y),
	wumpus_location(X, Yw),
	Yw < Y,
	Action = shoot.

% next to a pit
% pit to the right
search(_, _, Action) :-
	agent_orientation(0),
	agent_location(Xa, Ya),
	Xb is Xa + 1,
	pit(Xb, Ya),
	Ya =:= 1,
	Action = turnleft.

search(_, _, Action) :-
	agent_orientation(0),
	agent_location(Xa, Ya),
	Xb is Xa + 1,
	pit(Xb, Ya),
	Yb is Ya - 1,
	not(pit(Xa, Yb)),
	Action = turnright.

search(_, _, Action) :-
	agent_orientation(0),
	agent_location(Xa, Ya),
	Xb is Xa + 1,
	pit(Xb, Ya),
	Action = turnleft.

% pit to the top
search(_, _, Action) :-
	agent_orientation(90),
	agent_location(Xa, Ya),
	Yb is Ya + 1,
	pit(Xa, Yb),
	Xa =:= 4,
	Action = turnleft.

search(_, _, Action) :-
	agent_orientation(90),
	agent_location(Xa, Ya),
	Yb is Ya + 1,
	pit(Xa, Yb),
	Xb is Xa + 1,
	not(pit(Xb, Ya)),
	Action = turnright.

search(_, _, Action) :-
	agent_orientation(90),
	agent_location(Xa, Ya),
	Yb is Ya + 1,
	pit(Xa, Yb),
	Action = turnleft.

% pit to the left
search(_, _, Action) :-
	agent_orientation(180),
	agent_location(Xa, Ya),
	Xb is Xa - 1,
	pit(Xb, Ya),
	Ya =:= 4,
	Action = turnleft.

search(_, _, Action) :-
	agent_orientation(180),
	agent_location(Xa, Ya),
	Xb is Xa - 1,
	pit(Xb, Ya),
	Yb is Ya + 1,
	not(pit(Xa, Yb)),
	Action = turnright.

search(_, _, Action) :-
	agent_orientation(180),
	agent_location(Xa, Ya),
	Xb is Xa - 1,
	pit(Xb, Ya),
	Action = turnleft.

% pit to the bottom
search(_, _, Action) :-
	agent_orientation(270),
	agent_location(Xa, Ya),
	Yb is Ya - 1,
	pit(Xa, Yb),
	Xa =:= 1,
	Action = turnleft.

search(_, _, Action) :-
	agent_orientation(270),
	agent_location(Xa, Ya),
	Yb is Ya - 1,
	pit(Xa, Yb),
	Xb is Xa - 1,
	not(pit(Xb, Ya)),
	Action = turnright.

% boundary conditions
search(_, _, Action) :-
	agent_orientation(0),
	agent_location(Xa, Ya),
	Xa =:= 4,
	Ya =:= 1,
	Action = turnleft.

search(_, _, Action) :-
	agent_orientation(270),
	agent_location(Xa, Ya),
	Xa =:= 4,
	Ya =:= 1,
	Action = turnleft.

search(_, _, Action) :-
	agent_orientation(0),
	agent_location(Xa, Ya),
	Xa =:= 4,
	Ya =:= 4,
	Action = turnright.

search(_, _, Action) :-
	agent_orientation(90),
	agent_location(Xa, Ya),
	Xa =:= 4,
	Ya =:= 4,
	Action = turnleft.

search(_, _, Action) :-
	agent_orientation(90),
	agent_location(Xa, Ya),
	Xa =:= 1,
	Ya =:= 4,
	Action = turnright.

search(_, _, Action) :-
	agent_orientation(180),
	agent_location(Xa, Ya),
	Xa =:= 1,
	Ya =:= 4,
	Action = turnleft.

search(_, _, Action) :-
	agent_orientation(0),
	agent_location(Xa, _),
	Xa =:= 4,
	Action = turnleft.

search(_, _, Action) :-
	agent_orientation(90),
	agent_location(_, Ya),
	Ya =:= 4,
	Action = turnleft.

search(X, Y, Action) :-
	agent_orientation(270),
	agent_location(Xa, Ya),
	Ya =:= 1,
	Xa > 1,
	(start_point(X, Y) -> Action = turnright ; Action = turnleft).

search(X, Y, Action) :-
	agent_orientation(180),
	agent_location(Xa, Ya),
	Xa =:= 1,
	Ya > 1,
	(start_point(X, Y) -> Action = turnleft ; Action = turnright).

% once the agent is back to start
search(_, _, Action) :-
	(agent_orientation(180);
	agent_orientation(270)),
	agent_location(1, 1),
	Action = climb.

% any other safe point
search(_, _, Action) :-
	Action = goforward.
	

simple_problem_solving_agent([_,_,_,_,_], Action):-
	formulate_goal(Xg, Yg),
	search(Xg, Yg, Action).