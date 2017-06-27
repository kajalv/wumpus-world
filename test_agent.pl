:- [wumpus].
:- [navigate].
:- [my_agent].

test_agent:-
	test_agent('random_worlds.pl',[MS,SS],[MT,ST]),
	write('Score: '), write(MS), write([SS]), nl,
	write('Time: '), write(MT), write([ST]), nl,
	write('****************'), nl.

% test_agent(+File,-ScoreStats,-TimeStats)
% test agent performance
%	. File is file containing randomly generated worlds
%	. returns mean/sd of score and time
test_agent(File,[MS,SS],[MT,ST]):-
	exists_file(File), !,
	retractall(ww_scores(_,_)),
	assert(ww_scores([],[])),
	open(File,read,Stream),
	repeat,
	read(Stream,Fact),
	(Fact = end_of_file ->
		close(Stream);
		statistics(runtime,[Start|_]),
		(once(evaluate_agent(Fact,S1,T1)) -> true;
			write('evaluate agent failed'), nl,
			statistics(runtime,[Finish|_]),
			T1 is Finish - Start,
			S1 = 0),
		retract(ww_scores(S0,T0)),
		assert(ww_scores([S1|S0],[T1|T0])),
	fail),
	!,
	retract(ww_scores(Scores,Times)),
	length(Scores,NWorlds),
	write('****************'), nl,
	write('Tested: '), write(NWorlds), nl,
	mean(Scores,MS), sd(Scores,SS),
	mean(Times,MT), sd(Times,ST).
  

mean(L,M):-
        sum(L,Sum),
        length(L,N),
        M is Sum/N. 

sd(L,Sd):-
        sum(L,Sum),
        sumsq(L,SumSq),
        length(L,N),
        Sd is sqrt(SumSq/(N-1) - (Sum*Sum)/(N*(N-1))).

sum([],0).
sum([X|T],S):-
        sum(T,S1),
        S is X + S1.

sumsq([],0).
sumsq([X|T],S):-
        sumsq(T,S1),
        S is X*X + S1.


