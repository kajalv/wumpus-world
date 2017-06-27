# Wumpus World

The Wumpus World problem is a well known problem in the domain of artificial intelligence. This is an implementation of a simple problem solving agent that can navigate the Wumpus World, as a part of an introductory course on AI.

## Simple Problem Solving Agent

The agent is a simple one; it assumes that it has the knowledge of the world already, and decides the next best move based on its immediate surroundings.

The search predicate is such that the agent will never be killed by a wumpus or fall into a pit, and it can collect gold in most cases, or even shoot the wumpus if it is facing it - but it does not perform a best-path depth-first search procedure, and instead only looks for the next feasible step.

The end result is that on evaluating the agent with a hundred test cases, we get a positive score for all of them, because we can collect gold and never die.

## Code Details

The agent code is in *my_agent.pl*. To modify the functioning of the agent and implement a different logic, changes will need to be made to this file.

The simulator is based on Larry Holder's Wumpus World simulator. *random_worlds.pl* and *test_agent.pl* are used to evaluate the agent.
