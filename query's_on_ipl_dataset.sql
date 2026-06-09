-- Write a CTE called player_runs that calculates total runs scored by each player. 
-- Then SELECT from it to show player names and their total runs, ordered highest first.

with player_runs(id,total) as (select player_id as id, sum(runs) as total
                     from batting_scorecard 
					 group by player_id) 
select p.player_name,pv.total
from players p
join player_runs pv 
on p.player_id = pv.id
order by pv.total desc;

-- alternative
with player_runs as (select player_id as id, sum(runs) as total
				from batting_scorecard
                group by player_id)
select p.player_name,pv.total
from players p
join player_runs pv
on p.player_id = pv.id
order by pv.total desc;

-- Using a CTE, find the bowler with the most total wickets in each team.
--  Show team name, player name, and total wickets.

with most_wicket as (
					select p.team_id, p.player_id as id, p.player_name as player, sum(bs.wickets) as total_wicket,
                    dense_rank() over(partition by p.team_id  order by sum(bs.wickets) desc) as rnk
                    from players p join
                    bowling_scorecard bs 
                    on p.player_id = bs.player_id 
                    group by p.player_id)
select row_number() over() as num ,p.player_name,t.team_name,mw.total_wicket
from players p 
join teams t on p.team_id = t.team_id
join most_wicket mw on p.player_id = mw.id
where mw.rnk = 1
group by p.player_name,t.team_name,mw.total_wicket;

-- Using two chained CTEs: first calculate each player's total runs, then calculate each team's average runs. 
-- Finally show players who scored more than their team's average. Show player name, team, player total, team average.

--  first calculate each player's total runs
select p.player_name,sum(bs.runs)
from players p
join batting_scorecard bs
on p.player_id = bs.player_id
group by p.player_name;

-- then calculate each team's average runs. 
with total_runs_by_players as (select p.player_name,sum(bs.runs) as total
						  from players p 
                          join batting_scorecard bs
                          on p.player_id = bs.player_id
                          group by p.player_name)
select avg(tr.total) as total,team_name 
from teams t
join players p on t.team_id = p.team_id
join total_runs_by_players tr on p.player_name = tr.player_name
group by team_name order by total desc;

-- Finally show players who scored more than their team's average.
-- Show player name, team, player total, team average.
-- my try
with total_runs_by_player as (
                           select p.player_name,sum(bs.runs) total
                           from players p
						   join batting_scorecard bs
                           on p.player_id = bs.player_id
                           group by p.player_name),
                           
    avg_runs_by_team as (
select avg(tr.total) as total2,team_name 
from teams t
join players p on t.team_id = p.team_id
join total_runs_by_player tr on p.player_name = tr.player_name
group by team_name
)
select distinct(total_runs_by_player.player_name),total_runs_by_player.total,avg_runs_by_team.total2 from
total_runs_by_player 
join avg_runs_by_team
on total_runs_by_player.total > avg_runs_by_team.total2;

-- my second try
with total_runs_by_player as (
                           select 
                               p.team_id,
                               p.player_name,
                               sum(bs.runs) total
                           from players p
						   join batting_scorecard bs on p.player_id = bs.player_id
                           group by p.player_name,p.team_id
),
                           
avg_runs_by_team as (
   select 
      p.team_id,
      avg(tr.total) as avg_total,
      team_name 
from teams t
join players p on t.team_id = p.team_id
join total_runs_by_player tr on p.player_name = tr.player_name
group by team_name,p.team_id)

select  rank() over(order by tr.total desc) as rank_,tr.player_name,
       t.team_name,
       tr.total as player_total,
       round(ar.avg_total,1) as team_avg
	from total_runs_by_player tr
    join avg_runs_by_team ar on tr.team_id = ar.team_id
    join teams t on tr.team_id = t.team_id
where tr.total > ar.avg_total;


-- claude
WITH player_totals AS (
    SELECT player_id, SUM(runs) AS total_runs
    FROM batting_scorecard
    GROUP BY player_id
),
team_avg AS (
    SELECT p.team_id, AVG(pt.total_runs) AS avg_runs
    FROM player_totals pt
    JOIN players p ON pt.player_id = p.player_id
    GROUP BY p.team_id
)
SELECT p.player_name, t.team_name,
       pt.total_runs,
       ROUND(ta.avg_runs, 1) AS team_avg
FROM player_totals pt
JOIN players p  ON pt.player_id = p.player_id
JOIN teams   t  ON p.team_id    = t.team_id
JOIN team_avg ta ON p.team_id   = ta.team_id
WHERE pt.total_runs > ta.avg_runs
ORDER BY t.team_name, pt.total_runs DESC;

-- Rank all players by their total runs across all matches using RANK(). 
-- Show rank, player name, and total runs. 
-- If two players have the same runs, they should share the same rank.

select 
   rank() over(order by sum(bs.runs) desc) rnk,
   p.player_name,
   sum(bs.runs) as total_run 
from players p 
join batting_scorecard bs
on p.player_id = bs.player_id
group by p.player_name
order by rnk;

-- Show each player's total runs with both RANK() and DENSE_RANK() side by side. 
-- Notice where they differ — that's where tied players cause a gap in RANK but not in DENSE_RANK.

select 
   rank() over(order by sum(bs.runs) desc) rnk,
   dense_rank() over(order by sum(bs.runs) desc) dense_rnk,
   p.player_name,
   sum(bs.runs) as total_run 
from players p 
join batting_scorecard bs
on p.player_id = bs.player_id
group by p.player_name;


-- Rank batsmen within each team by total runs using DENSE_RANK(). 
-- Show only the top 2 batsmen from each team. Show team name, player name, total runs, rank within team.

-- half answer
select 
    dense_rank() over(partition by team_name order by sum(bs.runs) desc ) as dense_rnk,
   t.team_name,
   p.player_name,
   sum(bs.runs) as total_run 
from players p 
join batting_scorecard bs on p.player_id = bs.player_id
join teams t on p.team_id = t.team_id
group by t.team_name,p.player_name;

-- full answer

with top_rank_bastmen_by_team as (
      select 
            dense_rank() over(partition by team_name order by sum(bs.runs)  desc ) as dense_rnk,
            t.team_name,
            p.player_name,
            sum(bs.runs) as total_run 
     from players p 
     join batting_scorecard bs on p.player_id = bs.player_id
     join teams t on p.team_id = t.team_id
	 group by t.team_name,p.player_name
)
select
	dense_rnk,
    team_name,
    player_name,
    total_run
from  top_rank_bastmen_by_team
where dense_rnk < 3;

-- alternative

WITH scored AS (
    SELECT p.player_name, t.team_name, p.team_id,
           SUM(bs.runs) AS total_runs
    FROM batting_scorecard bs
    JOIN players p ON bs.player_id = p.player_id
    JOIN teams   t ON p.team_id    = t.team_id
    GROUP BY bs.player_id, p.player_name, t.team_name, p.team_id
),
ranked AS (
    SELECT *,
        DENSE_RANK() OVER (
            PARTITION BY team_id
            ORDER BY total_runs DESC
        ) AS team_rank
    FROM scored
)
SELECT  * -- team_name, player_name, total_runs, team_rank -- 
FROM ranked
WHERE team_rank <= 2
ORDER BY team_name, team_rank;



 -- Assign a row number to each batting entry for every player ordered by runs descending.
 -- Show player name, match_id, runs, and row number. 
 -- This shows each player's innings ranked best to worst.
 
-- first attempt few mistack like unneccesary sum because i need each entry no sum ,
-- also i use group by which also unneccesary because i no need to  gruop here i can do it in row_number function
-- but query runs perfect but some unnecessary parts
 select 
     row_number() over(partition by p.player_name order by sum(bs.runs) desc) as rnk,
     p.player_name,
     bs.match_id,
     sum(bs.runs)
from players p
join batting_scorecard bs
on p.player_id = bs.player_id
group by p.player_name, bs.match_id;

-- recorrected

 select 
     row_number() over(partition by p.player_id order by bs.runs desc) as rank_inning,
     p.player_name,
     bs.match_id,
     bs.runs
from players p
join batting_scorecard bs
on p.player_id = bs.player_id
ORDER BY p.player_name, rank_inning;


-- Each player has played multiple innings. Use ROW_NUMBER() to keep only each player's single best innings (highest runs).
-- Show player name, match_id, and runs for that best innings.


with best_inning as (
 select 
     rank() over(partition by p.player_id order by bs.runs desc) as rank_inning, -- rank might gave duplicate like best 2 score for rank 1 
     p.player_name,
     bs.match_id,
     bs.runs
from players p
join batting_scorecard bs
on p.player_id = bs.player_id
ORDER BY p.player_name, rank_inning)

select 
  player_name,
  match_id,
  runs as best_score
  from best_inning
where rank_inning = 1 
order by player_name;

with best_inning as (
 select 
     row_number() over(partition by p.player_id order by bs.runs desc) as rank_inning, -- row number select only first best score
     p.player_name,
     bs.match_id,
     bs.runs
from players p
join batting_scorecard bs
on p.player_id = bs.player_id
ORDER BY p.player_name, rank_inning)

select 
  player_name,
  match_id,
  runs as best_score
  from best_inning
where rank_inning = 1 
order by best_score desc;


-- "Keep exactly 1 row per group"     → ROW_NUMBER() = 1  (safest)
-- "Keep all tied rows at top"        → RANK() = 1
-- "Keep top N with no gap"           → DENSE_RAN-- -- -- K() <= N


-- Assign a row number to every player based on their total runs scored, highest runs first.

select 
     row_number() over(order by sum(bs.runs) desc) as rnk ,
     p.player_id,
     p.player_name,
     sum(bs.runs)
from players p
join batting_scorecard bs 
on p.player_id = bs.player_id
group by p.player_id,p.player_name;

-- For each team, assign row numbers to players based on total runs scored within that team.

select 
     row_number() over(partition by t.team_id order by sum(bs.runs) desc) as rnk ,
     t.team_name,
     p.player_id,
     p.player_name,
     sum(bs.runs)
from players p
join batting_scorecard bs on p.player_id = bs.player_id
join teams t on p.team_id = t.team_id

group by p.player_id,p.player_name;

-- For every season, assign row numbers to matches based on match date.
select m.*,
    row_number() over(partition by m.season order by m.match_date) as num
from matches m;

-- Find the latest batting performance of each player using ROW_NUMBER().
-- half part
select m.match_id,m.match_date,
       p.player_name,
	   bs.runs,
       row_number() over(partition by p.player_id order by match_date desc) as lattest_inning_score
       

from players p
join batting_scorecard bs on p.player_id = bs.player_id
join matches m on bs.match_id = m.match_id;

-- full part

with lattest_innings as (
                         select m.match_id,m.match_date,
							p.player_name,
							bs.runs,
                            row_number() over(partition by p.player_id order by match_date desc) as lattest_inning_score
       from players p
       join batting_scorecard bs on p.player_id = bs.player_id
       join matches m on bs.match_id = m.match_id
) 
select 
     lattest_innings.* 
     from lattest_innings 
     where lattest_inning_score = 1; 


-- For each team, find the top 2 batsmen based on total runs scored.
-- half part
select  row_number() over(partition by t.team_id order by sum(bs.runs) desc) as rnk,
        t.team_id,t.team_name,p.player_name,sum(bs.runs) as total
from players p
join batting_scorecard bs on p.player_id = bs.player_id
join teams t on p.team_id = t.team_id
group by  t.team_name,p.player_name, t.team_id,t.team_name;

-- full  part
with top_scorer_per_team as (
select  row_number() over(partition by t.team_id order by sum(bs.runs) desc) as rnk,
        t.team_id,t.team_name,p.player_name,sum(bs.runs) as total
from players p
join batting_scorecard bs on p.player_id = bs.player_id
join teams t on p.team_id = t.team_id
group by  t.team_name,p.player_name, t.team_id,t.team_name
         
)
select top_scorer_per_team.*
from top_scorer_per_team
where rnk <=2;

-- Rank players according to total runs scored.

select 
     rank() over(order by sum(bs.runs) desc) as rnk ,
     p.player_id,
     p.player_name,
     sum(bs.runs) as total
from players p
join batting_scorecard bs 
on p.player_id = bs.player_id
group by p.player_id,p.player_name;

-- Rank bowlers according to total wickets taken.

select 
    rank() over(order by sum(bs.wickets) desc ) as rnk ,
    p.player_id,
    p.player_name,
    sum(bs.wickets) as total_wickets
from players p
join bowling_scorecard bs
on p.player_id = bs.player_id
group by  p.player_id,p.player_name;

-- Rank teams according to number of matches won.
select
     rank() over( order by count(m.winner_id) desc) as rnk,
     t.team_id,
     t.team_name,
     count(m.winner_id) as  total_win
from teams t
join matches m on t.team_id = m.winner_id

group by  t.team_id,t.team_name;

-- For every season, rank players based on runs scored in that season.

select 
	rank() over(partition by m.season order by   sum(bs.runs) desc) as rnk,
    p.player_name,
    p.player_id,
    sum(bs.runs) as total_runs,
    m.season
from players p 
join batting_scorecard bs on p.player_id = bs.player_id
join matches m on bs.match_id = m.match_id
group by m.season,p.player_name,p.player_id;

-- Rank players by strike rate (runs*100/balls) considering only players who faced at least 50 balls.
select
    rank() over(order by sum(bs.runs)*100.0/sum(bs.balls) desc) as rnk,
    p.player_id,
    p.player_name,
    sum(bs.runs) total_runs,
    sum(bs.balls) total_balls,
    round(sum(bs.runs)*100.0/sum(bs.balls) ,2)strike_rate
from players p
join batting_scorecard bs
on p.player_id = bs.player_id
group by    p.player_id,p.player_name
having total_balls >= 50;