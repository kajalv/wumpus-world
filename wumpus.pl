% Wumpus World Simulator
%
%
% Modified variant of Larry Holder v 2.3.1
%

:- dynamic
  ww_scores/2,
  ww_initial_state/1,
  wumpus_world_extent/1,
  wumpus_location/2,
  wumpus_health/1,
  gold/2,
  pit/2,
  agent_location/2,
  agent_orientation/1,
  agent_in_cave/1,
  agent_health/1,
  agent_gold/1,
  agent_arrows/1,
  agent_score/1.


gold_probability(0.10).  % Probability that a location has gold
pit_probability(0.20).   % Probability that a non-(1,1) location has a pit
max_agent_actions(128).   % Maximum actions per trial allowed by agent
max_agent_tries(1).      % Maximum agent tries (climb or die) per world

% evaluate_agent(World,Score,Time): Performs a single trial
%   calling the externally-defined procedure
%   navigate(World,Actions,Score1,Time1) described below and returning the
%   accumulated Score and Time (in millisecs) over all trials.
%   World is either 'rnbook', 'random' or a ww_initial_state/1 fact.

evaluate_agent(World,Score,Time) :-
  evaluate_agent(World,1,Score,Time).

% evaluate_agent2(File,Score,Time): calls evaluate_agent on
%   each world defined in File. Worlds are stored as
%   ww_initial_state/1 facts. The scores and times are
%   accumulated Score and Time (in millisecs) over all worlds.

evaluate_agent2(File,Score,Time) :-
  exists_file(File), !,
  retractall(ww_scores(_,_)),
  assert(ww_scores(0,0)),
  open(File,read,Stream),
  repeat,
  read(Stream,Fact),
  (Fact = end_of_file ->
      close(Stream);
      evaluate_agent(Fact,S1,T1),
      retract(ww_scores(S0,T0)),
      S is S0 + S1,
      T is T0 + T1,
      assert(ww_scores(S,T)),
      fail),
  !,
  retract(ww_scores(Score,Time)).


% evaluate_agent(World,Trials,Score,Time): Performs Trials trials, where each
%   trial involves calling the externally-defined procedure
%   navigate(World,Actions,Score1,Time1) described below and returning the
%   accumulated Score and Time (in millisecs) over all trials.
%   World is either 'rnbook' or 'random'.
%
%   This procedure requires the external definition of the procedure:
%
%     navigate(World,Actions,Score,Time): Initializes a wumpus world with a
%       call to initialize(World,Percept) and then makes at most
%       max_agent_tries attempts to solve the generated world, calling
%       restart(Percept) whenever the agent dies or exceeds the maximum
%       number of actions per try as defined by max_agent_actions.

evaluate_agent(World,Trials,Score,Time) :-
  run_agent_trials(World,Trials,1,Score,Time).

% run_agent_trials(World,Trials,NextTrial,Score,Time): Runs trials from NextTrial
%   to Trial and returns the total Score and Time (millisecs) spent inside
%   calls to init_agent and run_agent.

run_agent_trials(_,Trials,NextTrial,0,0) :-
  NextTrial > Trials.

run_agent_trials(World,Trials,NextTrial,Score,Time) :-
  NextTrial =< Trials,
  format("Trial ~d~n",[NextTrial]),
  navigate(World,Actions,Score1,Time1),
  format("  Actions = ~w~n",[Actions]),
  NextTrial1 is NextTrial + 1,
  run_agent_trials(World,Trials,NextTrial1,Score2,Time2),
  Score is Score1 + Score2,
  Time is Time1 + Time2.

% initialize(World,Percept): initializes the Wumpus world and our fearless
%   agent according to the given World and returns the Percept from square
%   1,1.  World can be either 'rnbook' for Figure 6.2 of Russell and Norvig,
%   'random' to generate a random world, or a ww_initial_state/1 fact.

initialize(World,[Stench,Breeze,Glitter,no,no]) :-
  initialize_world(World),
  initialize_agent,
  stench(Stench),
  breeze(Breeze),
  glitter(Glitter),
  display_action(initialize).


% restart(Percept): Restarts the current world from scratch and returns
%   the initial Percept.

restart([Stench,Breeze,Glitter,no,no]):-
  ww_retractall,
  ww_initial_state(L),
  assert_list(L),
  initialize_agent,
  stench(Stench),
  breeze(Breeze),
  glitter(Glitter),
  display_action(restart).


% initialize_world(World): Initializes the Wumpus world.  World is either
%   rnbook, which generates the wumpus world in Figure 6.2 of [Russell &
%   Norvig], or World=random, which generates a random world according to
%   or World=ww_initial_state(L) where L is a list encoding of a wumpus world.
%   Guidelines for generating a wumpus world are as follows:
%
%   Size: The size of the wumpus world is fixed at 4x4, but can be set
%         arbitrarily using different values for wumpus_world_extent(E).
%
%   Wumpus Location: The initial wumpus location is chosen at random
%                    anywhere in the cave except location (1,1).
%
%   Pit Location: Each square has a pit with probability P set by
%                 pit_probability(P), except location (1,1), which
%                 will never have a pit.
%
%   Gold Location: Each square has gold with probability P set by
%                  gold_probability(P).  At least one square will have
%                  gold; no more than one gold piece per square.
%
% wumpus_world_extent(E): defines world to be E by E
% wumpus_location(X,Y): the Wumpus is in square X,Y
% wumpus_health(H): H is 'dead' or 'alive', initially 'alive'.
% gold(X,Y): there is gold in square X,Y
% pit(X,Y): there is a pit in square X,Y

initialize_world(rnbook) :-
  ww_retractall,
  retractall(ww_initial_state(_)),
  assert(ww_initial_state([])),
  addto_ww_init_state(wumpus_world_extent(4)),
  addto_ww_init_state(wumpus_location(1,3)),
  addto_ww_init_state(wumpus_health(alive)),
  addto_ww_init_state(gold(2,3)),
  addto_ww_init_state(pit(3,1)),
  addto_ww_init_state(pit(3,3)),
  addto_ww_init_state(pit(4,4)),
  ww_initial_state(L),
  assert_list(L).

initialize_world(random) :-
  ww_retractall,
  retractall(ww_initial_state(_)),
  assert(ww_initial_state([])),
  addto_ww_init_state(wumpus_world_extent(4)),
  all_squares(4,AllSqrs),
  gold_probability(PG),             % place gold
  place_objects(gold,PG,AllSqrs),
  at_least_one_gold(4),
  del([1,1],AllSqrs,AllSqrs1),
  pit_probability(PP),              % place pits
  place_objects(pit,PP,AllSqrs1),
  random_member([WX,WY],AllSqrs1),  % initialize wumpus
  addto_ww_init_state(wumpus_location(WX,WY)),
  addto_ww_init_state(wumpus_health(alive)),
  ww_initial_state(L),
  assert_list(L).

initialize_world(ww_initial_state(L)) :-
  ww_retractall,
  retractall(ww_initial_state(_)),
  assert(ww_initial_state(L)),
  assert_list(L).


% initialize_agent: agent is initially alive, destitute (except for one
%   arrow), in grid 1,1 and facing to the right (0 degrees).

initialize_agent :-
  retractall(agent_location(_,_)),
  retractall(agent_orientation(_)),
  retractall(agent_in_cave(_)),
  retractall(agent_health(_)),
  retractall(agent_gold(_)),
  retractall(agent_arrows(_)),
  retractall(agent_score(_)),
  assert(agent_location(1,1)),
  assert(agent_orientation(0)),
  assert(agent_in_cave(yes)),
  assert(agent_health(alive)),
  assert(agent_gold(0)),
  assert(agent_arrows(1)),
  assert(agent_score(0)).


% ww_retractall: Retract all wumpus world information, except about the
%   agent.

ww_retractall :-
  retractall(wumpus_world_extent(_)),
  retractall(wumpus_location(_,_)),
  retractall(wumpus_health(_)),
  retractall(gold(_,_)),
  retractall(pit(_,_)).


% addto_ww_init_state(Fact): Adds Fact to the list L stored in
%   ww_initial_state(L).

addto_ww_init_state(Fact) :-
  retract(ww_initial_state(L)),
  assert(ww_initial_state([Fact|L])).

% assert_list(L): Assert all facts on list L.

assert_list([]).

assert_list([Fact|Facts]) :-
  assert(Fact),
  assert_list(Facts).


% all_squares(Extent,AllSqrs): AllSqrs is the list of all possible
%   squares [X,Y] in a wumpus world of size Extent by Extent.

all_squares(Extent,AllSqrs) :-
  all_squares_1(Extent,1,1,AllSqrs).

all_squares_1(Extent,Extent,Extent,[[Extent,Extent]]).

all_squares_1(Extent,Row,Extent,[[Row,Extent]|RestSqrs]) :-
  Row < Extent,
  Row1 is Row + 1,
  all_squares_1(Extent,Row1,1,RestSqrs).

all_squares_1(Extent,Row,Col,[[Row,Col]|RestSqrs]) :-
  Col < Extent,
  Col1 is Col + 1,
  all_squares_1(Extent,Row,Col1,RestSqrs).


% place_objects(Object,P,Squares): For each square in Squares, place
%   Object at square with probability P.

place_objects(_,_,[]).

place_objects(Object,P,[Square|Squares]) :-
  maybe(P),   % succeeds with probability P
  !,
  Fact =.. [Object|Square],
  addto_ww_init_state(Fact),
  place_objects(Object,P,Squares).

place_objects(Object,P,[_|Squares]) :-
  place_objects(Object,P,Squares).


% at_least_one_gold(Extent): Ensures that at least on gold piece is
%   somewhere in the wumpus world.

at_least_one_gold(_) :-
  ww_initial_state(L),
  member(gold(_,_),L),
  !.

at_least_one_gold(E) :-
  E1 is E + 1,
  random(1,E1,X),
  random(1,E1,Y),
  addto_ww_init_state(gold(X,Y)).


%------------------------------------------------------------------------
% execute(Action,Percept): executes Action and returns Percept
%
%   Action is one of:
%     goforward: move one square along current orientation if possible
%     turnleft:  turn left 90 degrees
%     turnright: turn right 90 degrees
%     grab:      pickup gold if in square
%     shoot:     shoot an arrow along orientation, killing wumpus if
%                in that direction
%     climb:     if in square 1,1, leaves the cave and adds 1000 points
%                for each piece of gold
%
%   Percept = [Stench,Breeze,Glitter,Bump,Scream]
%             These are either 'yes' or 'no'.

execute(_,[no,no,no,no,no]):-
  agent_health(dead), !,         % agent must be alive to execute actions
  format("You are dead!~n",[]).

execute(_,[no,no,no,no,no]):-
  agent_in_cave(no), !,         % agent must be in the cave
  format("You have left the cave.~n",[]).

execute(goforward,[Stench,Breeze,Glitter,Bump,no]):-
  decrement_score,
  goforward(Bump),        % update location and check for bump
  update_agent_health,    % check for wumpus or pit
  stench(Stench),         % update rest of percept
  breeze(Breeze),
  glitter(Glitter),
  display_action(goforward).

execute(turnleft,[Stench,Breeze,Glitter,no,no]):-
  decrement_score,
  agent_orientation(Angle),
  NewAngle is (Angle + 90) mod 360,
  retract(agent_orientation(Angle)),
  assert(agent_orientation(NewAngle)),
  stench(Stench),
  breeze(Breeze),
  glitter(Glitter),
  display_action(turnleft).

execute(turnright,[Stench,Breeze,Glitter,no,no]):-
  decrement_score,
  agent_orientation(Angle),
  NewAngle is (Angle + 270) mod 360,
  retract(agent_orientation(Angle)),
  assert(agent_orientation(NewAngle)),
  stench(Stench),
  breeze(Breeze),
  glitter(Glitter),
  display_action(turnright).

execute(grab,[Stench,Breeze,no,no,no]):-
  decrement_score,
  get_the_gold,
  stench(Stench),
  breeze(Breeze),
  display_action(grab).

execute(shoot,[Stench,Breeze,Glitter,no,Scream]):-
  decrement_score,
  shoot_arrow(Scream),
  stench(Stench),
  breeze(Breeze),
  glitter(Glitter),
  display_action(shoot).

execute(climb,[no,no,no,no,no]) :-  % climb works, no wumpus movement
  agent_location(1,1), !,
  decrement_score,
  agent_gold(G),
  retract(agent_score(S)),
  S1 is (S + (1000 * G)),
  assert(agent_score(S1)),
  retract(agent_in_cave(yes)),
  assert(agent_in_cave(no)),
  display_action(climb),
  format("I am outta here.~n",[]).

execute(climb,[Stench,Breeze,Glitter,no,no]):-
  decrement_score,
  stench(Stench),
  breeze(Breeze),
  glitter(Glitter),
  display_action(climb),
  format("You cannot leave the cave from here.~n",[]).


% decrement_score: subtracts one from agent_score for each move

decrement_score :-
  retract(agent_score(S)),
  S1 is S - 1,
  assert(agent_score(S1)).


% stench(Stench): Stench = yes if wumpus (dead or alive) is in a square
%   directly up, down, left, or right of the current agent location.

stench(yes) :-
  agent_location(X,Y),
  X1 is X + 1,
  X0 is X - 1,
  Y1 is Y + 1,
  Y0 is Y - 1,
  ( wumpus_location(X1,Y) ;
    wumpus_location(X0,Y) ;
    wumpus_location(X,Y1) ;
    wumpus_location(X,Y0) ;
    wumpus_location(X,Y) ),
  !.

stench(no).


% breeze(Breeze): Breeze = yes if a pit is in a square directly up, down,
%   left, or right of the current agent location.

breeze(yes) :-
  agent_location(X,Y),
  X1 is X + 1,
  X0 is X - 1,
  Y1 is Y + 1,
  Y0 is Y - 1,
  ( pit(X1,Y) ;
    pit(X0,Y) ;
    pit(X,Y1) ;
    pit(X,Y0) ;
    pit(X,Y)  ),
  !.

breeze(no).


% glitter(Glitter): Glitter = yes if there is gold in the current agent
%   location.

glitter(yes) :-
  agent_location(X,Y),
  gold(X,Y),
  !.

glitter(no).


% kill_wumpus: pretty obvious

kill_wumpus :-
  retract(wumpus_health(alive)),
  assert(wumpus_health(dead)).


% goforward(Bump): Attempts to move agent forward one unit along
%   its current orientation.

goforward(no) :-
  agent_orientation(Angle),
  agent_location(X,Y),
  new_location(X,Y,Angle,X1,Y1),
  wumpus_world_extent(E),         % check if agent off world
  X1 > 0,
  X1 =< E,
  Y1 > 0,
  Y1 =< E,
  !,
  retract(agent_location(X,Y)),   % update location
  assert(agent_location(X1,Y1)).

goforward(yes).     % Ran into wall, Bump = yes


% new_location(X,Y,Orientation,X1,Y1): returns new coordinates X1,Y1
%   after moving from X,Y along Orientation: 0, 90, 180, 270 degrees.

new_location(X,Y,0,X1,Y) :-
  X1 is X + 1.

new_location(X,Y,90,X,Y1) :-
  Y1 is Y + 1.

new_location(X,Y,180,X1,Y) :-
  X1 is X - 1.

new_location(X,Y,270,X,Y1) :-
  Y1 is Y - 1.


% update_agent_health: kills agent if in a room with a live wumpus or a
%   pit.

update_agent_health :-
  agent_health(alive),
  agent_location(X,Y),
  wumpus_health(alive),
  wumpus_location(X,Y),
  !,
  retract(agent_health(alive)),
  assert(agent_health(dead)),
  retract(agent_score(S)),
  S1 is S - 10000,
  assert(agent_score(S1)),
  format("You are Wumpus food!~n",[]).

update_agent_health :-
  agent_health(alive),
  agent_location(X,Y),
  pit(X,Y),
  !,
  retract(agent_health(alive)),
  assert(agent_health(dead)),
  retract(agent_score(S)),
  S1 is S - 10000,
  assert(agent_score(S1)),
  format("Aaaaaaaaaaaaaaaaaaa!~n",[]).

update_agent_health.


% get_the_gold: adds gold to agents loot if any gold in the square

get_the_gold :-
  agent_location(X,Y),
  gold(X,Y), !,                   % there is gold in this square!
  agent_gold(NGold),              %   add to agents loot
  NGold1 is NGold + 1,
  retract(agent_gold(NGold)),
  assert(agent_gold(NGold1)),
  format("You now have ~d piece(s) of gold!~n",NGold1),
  retract(gold(X,Y)).             %   delete gold from square

get_the_gold.


% shoot_arrow(Scream): If agent has an arrow, then shoot it in the
%   direction the agent is facing and listen for Scream.

shoot_arrow(Scream) :-
  agent_arrows(Arrows),
  Arrows > 0, !,                  % agent has an arrow and will use it!
  Arrows1 is Arrows - 1,          %   update number of arrows
  retract(agent_arrows(Arrows)),
  assert(agent_arrows(Arrows1)),
  format("You now have ~d arrow(s).~n",Arrows1),
  agent_location(X,Y),
  agent_orientation(Angle),
  propagate_arrow(X,Y,Angle,Scream).

shoot_arrow(no).


% propagate_arrow(X,Y,Angle,Scream): If wumpus is at X,Y then hear its
%   woeful scream as you vanquish the creature.  If not, then move arrow
%   one square along Angle and try again.  If arrow hits a wall, then
%   you missed.

propagate_arrow(X,Y,_,yes) :-
  wumpus_location(X,Y), !,
  kill_wumpus.

propagate_arrow(X,Y,0,Scream) :-
  X1 is X + 1,
  wumpus_world_extent(E),
  X1 =< E,
  !,
  propagate_arrow(X1,Y,0,Scream).

propagate_arrow(X,Y,90,Scream) :-
  Y1 is Y + 1,
  wumpus_world_extent(E),
  Y1 =< E,
  !,
  propagate_arrow(X,Y1,90,Scream).

propagate_arrow(X,Y,180,Scream) :-
  X1 is X - 1,
  X1 > 0,
  !,
  propagate_arrow(X1,Y,180,Scream).

propagate_arrow(X,Y,270,Scream) :-
  Y1 is Y - 1,
  Y1 > 0,
  !,
  propagate_arrow(X,Y1,270,Scream).

propagate_arrow(_,_,_,no).


% display_world: Displays everything known about the wumpus world,

display_world :-
  nl,
  wumpus_world_extent(E),
  display_rows(E,E),
  % wumpus_health(WH),
  agent_orientation(AA),
  agent_health(AH),
  agent_arrows(N),
  agent_gold(G),
  % format('wumpus_health(~w)~n',[WH]),
  format('agent_orientation(~d)~n',[AA]),
  format('agent_health(~w)~n',[AH]),
  format('agent_arrows(~d)~n',[N]),
  format('agent_gold(~d)~n',[G]).


display_rows(0,E) :-
  !,
  display_dashes(E).

display_rows(Row,E) :-
  display_dashes(E),
  display_row(Row,E),
  Row1 is Row - 1,
  display_rows(Row1,E).

display_row(Row,E) :-
  display_square(1,Row,E).

display_square(X,_,E) :-
  X > E,
  !,
  format('|~n',[]).

display_square(X,Y,E) :-
  format('| ',[]),
  display_info(X,Y),
  X1 is X + 1,
  display_square(X1,Y,E).

display_info(X,Y) :-
  display_location_fact(wumpus_location,X,Y,'W'),
  agent_orientation(Orientation),
  get_agent_icon(Orientation,Icon),
  display_location_fact(agent_location,X,Y,Icon),
  display_location_fact(pit,X,Y,'P'),
  display_location_fact(gold,X,Y,'G').

get_agent_icon(0,'A>').
get_agent_icon(90,'A^').
get_agent_icon(180,'<A').
get_agent_icon(270,'Av').

display_location_fact(Functor,X,Y,Atom) :-
  Fact =.. [Functor,X,Y],
  Fact,
  !,
  (Functor = agent_location ->
                format('~w',[Atom]);
                format('~w ',[Atom])).

display_location_fact(_,_,_,_) :-
  format('  ',[]).

display_dashes(E) :-
  RowLen is (E * 10) + 1,
  name('-',[Dash]),
  format('~*c~n',[RowLen,Dash]).


% display_action(Action): Updates display after Action taken and

display_action(Action):-
  format("~nExecuting ~w~n",[Action]),
  display_world.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Additional predicates needed for the simulator
%
% random.pl
%
%
random(L,U,R) :-
	integer(L), integer(U), !,
        R is L + random(U).

random_member(X,L):-
	length(L,N),
	random(1,N,R),
	nth1(R,L,X).

random(X):-
	% current_prolog_flag(max_integer,I),
	I = 1000000,
	X is float(random(I-1))/float(I).

maybe(P):-
	random(X),
	X =< P.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% math.pl
%
%
% Math code:
%
%   abs(X,Y): Y is the absolute value of X.
%   sqrt(X,Y): Y is the square root of X.
%   exp(X,Y): Y is e^X.
%   log(X,Y): Y is logarithm base e of X (X >= 0).
%   log2(X,Y): Y is logarithm base 2 of X (X >= 0).
%   log10(X,Y): Y is logarithm base 10 of X (X >=0).
%   cos(X,Y): Y is the cosine of X (X in radians).
%   sin(X,Y): Y is the sine of X (X in radians).
%   arctan(X,Y,Z): Z (-pi < Z <= pi radians) is inverse tangent of the
%                  point (X,Y) (X and Y are any real number).

pi(3.141592654).
sqrt_precision(1.0E-10).  % decimal-place precision of squareroot
exp_series_limit(50).     % Limit on terms of exp series.
log_series_limit(99).     % Limit on terms of log series.
arctan_series_limit(99).  % Limit on terms of tan series.
sin_series_limit(50).     % Limit on terms of sin series.
cos_series_limit(99).     % Limit on terms of cos series.


% abs(X,Y): Y is the absolute value of X.

abs(X,X) :-
  X >= 0.

abs(X,Y) :-
  X < 0,
  Y is - X.


% sqrt(X,Y): Y is the square root of X.

sqrt(X,Y) :-
  sqrt1(X,Y,1.0).

sqrt1(X,Z,Z) :-
  W is ((Z * Z) - X),
  abs(W,AW),
  sqrt_precision(P),
  AW < P,
  !.

sqrt1(X,Y,Z) :-
  Z1 is (Z - (((Z * Z) - X) / (2 * Z))),
  sqrt1(X,Y,Z1).


% exp(X,Y): Y is e^X.

exp(X,Y) :-
  X1 is float(X),
  exp_series(X1,1,Y1,1),
  Y is Y1 + 1.0.


% exp_series(X,Term,Y,Exp): Y is e raised to the X power according
%   to the series:
%
%   e^X = 1 + X + X^2/2! + X^3/3! + X^4/4! + ...
%
%      where (2,3,4,...) continues until exceeding exp_series_limit.

exp_series(_,_,0,Exp) :-
  exp_series_limit(L),
  Exp > L,
  !.

exp_series(X,Term,Y,Exp) :-
  Term1 is Term * X / Exp,
  Exp2 is Exp + 1,
  exp_series(X,Term1,Y2,Exp2),
  Y is Term1 + Y2.


% log2(X,Y): Y is log base 2 of X.

log2(X,Y) :-
  log(X,Ye),
  Y is Ye / 0.69314718.  % log_e(2) = 0.69314718


% log10(X,Y): Y is log base 10 of X.

log10(X,Y) :-
  log(X,Ye),
  Y is Ye / 2.302585093.  % log_e(10) = 2.302585093


% log(X,Y): Y is the natural logarithm (base e) of X.

log(0,0).

log(X,Y) :-
  X > 0,
  log_series_limit(L),
  log_e_series(X,1,Y,1,L).


% log_e_series(X,Term,Y,Exp,Limit): Y is the natural logarithm (base e)
%   of X (X >= 0) according to the logarithmic series:
%
%   log_e (X) = 2 [ Term + (1/3)*Term^3 + (1/5)*Term^5 + ... +
%                          (1/Exp)*Term^Exp ]
%
%      where Term = ((X-1)/(X+1)) and Exp is the largest odd <= Limit.

log_e_series(_,_,0,Exp,Limit) :-
  Exp > Limit,
  !.

log_e_series(X,_,Y,1,Limit) :-
  !,
  Term1 is ((X-1)/(X+1)),
  Term2 is Term1 * 2,
  log_e_series(X,Term1,Y2,3,Limit),
  Y is Term2 + Y2.

log_e_series(X,Term,Y,Exp,Limit) :-
  Term1 is Term * ((X-1)/(X+1)) * ((X-1)/(X+1)),
  Term2 is Term1 * (2 / Exp),
  Exp2 is Exp + 2,
  log_e_series(X,Term1,Y2,Exp2,Limit),
  Y is Term2 + Y2.


% cos(X,Y): Y is the cosine of X (X in radians).

cos(X,Y) :-
  cos_series(X,Y,1).


% cos_series(X,Y,Base): Expands the following series to compute Y = cos(X):
%
%   cos(X) = (1 - 4X^2/Pi^2)*(1 - 4x^2/(3Pi)^2)*(1 - 4x^2/(5Pi)^2)*...
%
%     until the Base (1,3,5,...) exceeds cos_series_limit(L).

cos_series(_,1.0,Base) :-
  cos_series_limit(Limit),
  Base > Limit,
  !.

cos_series(X,Y,Base) :-
  pi(Pi),
  Term1 is (2.0 * X) / (Base * Pi),
  Term2 is 1.0 - (Term1 * Term1),
  Base1 is Base + 2,
  cos_series(X,Y1,Base1),
  Y is Term2 * Y1.


% sin(X,Y): Y is the sine of X (X in radians).

sin(X,Y) :-
  sin_series(X,Y,1).


% sin_series(X,Y,Base): Expands the following series to compute Y = sin(X):
%
%   sin(X) = (1 - X^2/Pi^2)*(1 - x^2/(2Pi)^2)*(1 - x^2/(3Pi)^2)*...
%
%     until the Base (1,2,3,...) exceeds sin_series_limit(L).

sin_series(X,X,Base) :-
  sin_series_limit(Limit),
  Base > Limit,
  !.

sin_series(X,Y,Base) :-
  pi(Pi),
  Term1 is X / (Base * Pi),
  Term2 is 1.0 - (Term1 * Term1),
  Base1 is Base + 1,
  sin_series(X,Y1,Base1),
  Y is Term2 * Y1.


% arctan(X,Y,Z): Z (-pi < Z <= pi radians) is inverse tangent of the
%   point (X,Y) (X and Y are any real number).


arctan(X,Y,Z) :-
  FX is float(X),
  FY is float(Y),
  arctan1(FX,FY,Z).


% arctan1(X,Y,Z) :- Computes Z as the inverse tangent at (X,Y) based on the
%   quadrant of (X,Y) and their ratio.

arctan1(0.0,Y,Z) :-
  Y > 0.0,
  !,
  pi(Pi),
  Z is Pi / 2.0.

arctan1(0.0,Y,Z) :-
  Y < 0.0,
  !,
  pi(Pi),
  Z is - (Pi / 2.0).

arctan1(X,0.0,0.0) :-
  X >= 0.0,
  !.

arctan1(X,0.0,Z) :-
  X < 0.0,
  !,
  pi(Z).

arctan1(X,Y,Z) :-
  X > 0.0,          % 1st quadrant
  Y > 0.0,
  X >= Y,           % angle =< 45 degrees
  !,
  Ratio is Y / X,
  arctan2(Ratio,Z).

arctan1(X,Y,Z) :-
  X > 0.0,          % 1st quadrant
  Y > 0.0,
  X < Y,            % angle > 45 degrees
  Ratio is X / Y,
  !,
  arctan2(Ratio,Z1),
  pi(Pi),
  Z is (Pi / 2.0) - Z1.

arctan1(X,Y,Z) :-
  X < 0.0,          % 2nd quadrant
  Y > 0.0,
  Y =< - X,         % angle >= 135 degrees
  !,
  Ratio is - Y / X,
  arctan2(Ratio,Z1),
  pi(Pi),
  Z is Pi - Z1.

arctan1(X,Y,Z) :-
  X < 0.0,          % 2nd quadrant
  Y > 0.0,
  Y > - X,          % angle < 135 degrees
  !,
  Ratio is - X / Y,
  arctan2(Ratio,Z1),
  pi(Pi),
  Z is (Pi / 2.0) + Z1.

arctan1(X,Y,Z) :-
  X < 0.0,          % 3rd quadrant
  Y < 0.0,
  X =< Y,           % angle =< 225 degrees
  !,
  Ratio is Y / X,
  arctan2(Ratio,Z1),
  pi(Pi),
  Z is Z1 - Pi.

arctan1(X,Y,Z) :-
  X < 0.0,          % 3rd quadrant
  Y < 0.0,
  X > Y,            % angle > 225 degrees
  !,
  Ratio is X / Y,
  arctan2(Ratio,Z1),
  pi(Pi),
  Z is - (Pi / 2.0) - Z1.

arctan1(X,Y,Z) :-
  X > 0.0,          % 4th quadrant
  Y < 0.0,
  X >= - Y,         % angle >= 315 degrees
  !,
  Ratio is - Y / X,
  arctan2(Ratio,Z1),
  Z is - Z1.

arctan1(X,Y,Z) :-
  X > 0.0,          % 4th quadrant
  Y < 0.0,
  X < - Y,          % angle < 315 degrees
  !,
  Ratio is - X / Y,
  arctan2(Ratio,Z1),
  pi(Pi),
  Z is Z1 - (Pi / 2.0).


% arctan2(X,Y): Y is the inverse tangent of X, where 0.0 < X <= 1.0.

arctan2(1.0,Y) :-
  !,
  pi(Pi),
  Y is Pi / 4.0.

arctan2(X,Y) :-         % 0.0 < X < 1.0
  arctan_series_limit(L),
  arctan_series(X,X,Y,1,1,L).


% arctan_series(X,Term,Y,Sign,Exp,Limit): Y is the inverse tangent
%   of X (0.0 < X < 1.0) according to the series:
%
%   arctan(X) = X - X^3/3 + X^5/5 - X^7/7 + X^9/9 - ... +/-
%                          (1/Exp)*X^Exp ]
%
%      where Exp is the largest odd <= Limit.


arctan_series(_,_,0,_,Exp,Limit) :-
  Exp > Limit,
  !.

arctan_series(X,Term,Y,Sign,Exp,Limit) :-
  Term1 is Term * X * X,
  Term2 is Sign * (Term / Exp),
  Exp2 is Exp + 2,
  OppSign is Sign * (-1),
  arctan_series(X,Term1,Y2,OppSign,Exp2,Limit),
  Y is Term2 + Y2.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% utils.pl
%
%
% Utilities

% :- op(500,fx,not).
%
% not(P) :- P, !, fail ; true.
%
%
% member(X,[X|_]).
%
% member(X,[_|R]) :-
  % member(X,R).


conc([],L,L).

conc([H|T],L1,[H|L2]) :-
  conc(T,L1,L2).


% del(X,L1,L2): True if L2 is L1 minus one occurrence of X.

del(X,[X|L],L).

del(X,[Y|L1],[Y|L2]) :-
  del(X,L1,L2).
