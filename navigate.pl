% navigate.pl
%

% navigate(World,Actions,Score,Time): Initializes the wumpus world and
%   uses run_agent to select actions to perform.  If the agent leaves
%   the cave, then the actions used are returned in Actions.  If the
%   agent exceeds max_agent_tries attempts without leaving the cave,
%   then Actions = [].  The accumulated Score and Time (in millisecs)
%   spent in init_agent, restart_agent and run_agent are returned.
%   World is one of 'fig62', 'random', or a ww_initial_state/1 fact.

navigate(World,Actions,Score,Time) :-
  initialize(World,Percept),
  statistics(runtime,[T1|_]),
  init_agent,
  statistics(runtime,[T2|_]),
  iterate1(Percept,Actions,1,Score,Time1),
  Time is Time1 + (T2 - T1).


% iterate1(Percept,Actions,NumTries,Score,Time): Given the initial Percept,
%   returns list of Actions from possibly multiple tries to solve the
%   current wumpus world.  The number of tries NumTries is limited to
%   max_agent_tries.  The accumulated Score and Time spent in
%   restart_agent and run_agent are returned.

iterate1(_,[],NumTries,0,0) :-    % agent exceeds maximum tries
  max_agent_tries(N),
  NumTries > N,
  !.

iterate1(Percept,Actions,NumTries,Score,Time) :-
  format("  Try ~d~n",[NumTries]),
  iterate2(1,Percept,Acts,Time1),
  agent_score(Score1),
  process_iteration(Acts,Actions,NumTries,Score2,Time2),
  Score is Score1 + Score2,
  Time is Time1 + Time2.


% process_iteration(Acts,Actions,NumTries,Score,Time): Processes the results
%   of an iteration (attempt to solve cave).  If agent left cave, then done
%   with this world and return Acts in Actions along with the accumulated
%   Score and Time.  Otherwise, restart world and try again.

process_iteration(Acts,Acts,_,0,0) :-
  agent_in_cave(no),
  !.

process_iteration(_,Actions,NumTries,Score,Time) :-
  restart(NewPercept),
  statistics(runtime,[T1|_]),
  restart_agent,
  statistics(runtime,[T2|_]),
  NumTries1 is NumTries + 1,
  iterate1(NewPercept,Actions,NumTries1,Score,Time1),
  Time is Time1 + (T2 - T1).


% iterate2(NumActions,Percept,Actions,Time): Continues trying actions
%   as suggested by run_agent until the agent leaves the dies, leaves
%   the cave or exceeds the maximum number of actions as defined by
%   max_agent_actions.  The actions taken are returned in Actions, and
%   the time spent in run_agent is returned in Time (millisecs).

iterate2(_,_,[],0) :-       % agent died
  agent_health(dead),
  !.

iterate2(_,_,[],0) :-             % agent left cave
  agent_in_cave(no),
  !.

iterate2(NumActions,_,[],0) :-    % agent allowed only N actions
  max_agent_actions(N),
  NumActions > N,
  !.

iterate2(NumActions,Percept,[Action | Actions],Time) :-
  statistics(runtime,[T1|_]),
  run_agent(Percept,Action),
  statistics(runtime,[T2|_]),
  execute(Action,NewPercept),
  NumActions1 is NumActions + 1,
  iterate2(NumActions1,NewPercept,Actions,Time1),
  Time is Time1 + (T2 - T1).

run_agent(Percept,Action) :-
  simple_problem_solving_agent(Percept,Action).
