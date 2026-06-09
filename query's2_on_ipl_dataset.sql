-- Dense rank players according to total runs

select
    dense_rank() over( order by sum(bs.runs) desc) as dens_rnk,
    p.player_id,
    p.player_name,
	sum(bs.runs) as total
from players p 
join batting_scorecard bs
on p.player_id = bs.player_id
group by p.player_id,p.player_name;

-- alternative way
with player_runs as (
           select
				p.player_id,
			    p.player_name,
	           sum(bs.runs) as total
         from players p 
         join batting_scorecard bs
         on p.player_id = bs.player_id
         group by p.player_id,p.player_name
)
select dense_rank() over(order by total desc) rank_no_dns,
      player_runs.*
from player_runs;
-- same
with player_runs as (
    select
        player_id,
        sum(runs) total_runs
    from batting_scorecard
    group by player_id
)
select
    dense_rank() over(order by total_runs desc) rank_no,
    player_runs.*
from player_runs;


-- Dense rank bowlers according to wickets.

select 
     dense_rank() over(order by sum(bs.wickets) desc) as dens_rank,
     p.player_id,
     p.player_name,
     sum(bs.wickets) as total_wickets
from players p
join bowling_scorecard bs 
on p.player_id = bs.player_id
group by p.player_id,p.player_name;

-- alternative way
with wickets as (
select
     p.player_id,
     p.player_name,
     sum(bs.wickets) as total_wickets
from players p
join bowling_scorecard bs 
on p.player_id = bs.player_id
group by p.player_id,p.player_name
)
select dense_rank() over(order by total_wickets desc) dense_rnk,
       wickets.*
from wickets;

-- For each team, dense rank players according to runs.
-- first try
select
    dense_rank() over(partition by t.team_id order by sum(bs.runs) desc) as dens_rnk,
    t.team_name,
    p.player_id,
    p.player_name,
	sum(bs.runs) as total
from players p 
join batting_scorecard bs on p.player_id = bs.player_id
join teams t on p.team_id = t.team_id
group by p.player_id,p.player_name;

-- best way
select
    dense_rank() over(
        partition by t.team_id
        order by sum(bs.runs) desc
    ) as dens_rnk,
    t.team_name,
    p.player_id,
    p.player_name,
    sum(bs.runs) total_runs
from players p
join batting_scorecard bs
    on p.player_id = bs.player_id
join teams t
    on p.team_id = t.team_id
group by
    t.team_id,
    t.team_name,
    p.player_id,
    p.player_name; -- here some correction from previous one

-- Find the top 3 run scorers using DENSE_RANK().
with top_batters as (
      select
            dense_rank() over( order by sum(bs.runs) desc) as dens_rnk,
            p.player_id,
            p.player_name,
	        sum(bs.runs) as total
    from players p 
    join batting_scorecard bs
    on p.player_id = bs.player_id
    group by p.player_id,p.player_name
)
select * from top_batters where dens_rnk <= 3;

-- Dense rank players according to total sixes hit.

select
    dense_rank() over( order by sum(bs.sixes) desc) as dens_rnk,
    p.player_id,
    p.player_name,
	sum(bs.sixes) as total_sixs
from players p 
join batting_scorecard bs
on p.player_id = bs.player_id
group by p.player_id,p.player_name;

-- For every match, show the next match date.
select m.*,
  lead(m.match_date) over(order by m.match_date) as next_match_date from matches m;
  
-- For each player's batting performances ordered by match date, show runs scored in the next match.

select
   
    p.player_id,
    p.player_name,
    m.match_date,
    bs.runs run,
    bs.balls ball,
    lead(bs.runs) over( partition by p.player_id order by m.match_date ) as next_match_run_score
    
from players p
join batting_scorecard bs on p.player_id = bs.player_id
join matches m on bs.match_id = m.match_id
;

-- For every season, show the next match played.
select
     m.*,
     lead(m.match_id,1,0) over(partition by m.season order by m.match_date) as next_match_id
from matches m;

-- For each player, calculate the difference between current match runs and next match runs.
-- half part
select 
      m.match_date,
      p.player_id,
      p.player_name,
      bs.runs,
      lead(runs,1,0) over(partition by p.player_id order by m.match_date) as next_inning_score
from players p 
join batting_scorecard bs 
on p.player_id = bs.player_id
join matches m on bs.match_id = m.match_id;
-- full part
with next_score as (
select 
      
      p.player_id,
      p.player_name,
      bs.runs,
      lead(runs,1,0) over(partition by p.player_name order by m.match_date) as next_inning_score
from players p 
join batting_scorecard bs 
   on p.player_id = bs.player_id
join matches m
   on bs.match_id = m.match_id
)
select next_score.*,
	   (next_score.runs - next_score.next_inning_score) as diff_between_cur_next
from next_score;

-- For each team, show current match result and next match result.
WITH team_results AS
(
    SELECT
        match_id,
        match_date,
        team1_id AS team_id,

        CASE
            WHEN winner_id = team1_id THEN 'WIN'
            ELSE 'LOSS'
        END AS result

    FROM matches

    UNION ALL

    SELECT
        match_id,
        match_date,
        team2_id AS team_id,

        CASE
            WHEN winner_id = team2_id THEN 'WIN'
            ELSE 'LOSS'
        END AS result

    FROM matches
)
SELECT
    tr.team_id,
    t.team_name,
    tr.match_id,
    tr.match_date,
    tr.result AS current_result,

    LEAD(tr.result)
    OVER(
        PARTITION BY tr.team_id
        ORDER BY tr.match_date
    ) AS next_result

FROM team_results tr
JOIN teams t
ON tr.team_id = t.team_id;
      
-- Show previous match date for every match.
select m.*,
lag(m.match_date) over() as previous_match_date
from matches m;

-- For each player's innings, show runs scored in previous innings.
select
   p.player_name,
   bs.runs,
   lag(bs.runs,1,0) over(partition by p.player_id order by m.match_date ) as previous_score
from players p
join batting_scorecard bs
     on p.player_id = bs.player_id
join matches m
     on bs.match_id = m.match_id;

-- Calculate run difference between current innings and previous innings
with previous_scored_runs as (
select
   p.player_name,
   bs.runs,
   lag(bs.runs,1,0) over(partition by p.player_id order by m.match_date) as previous_score
from players p
join batting_scorecard bs
on p.player_id = bs.player_id
join matches m 
on bs.match_id = m.match_id
)
select previous_scored_runs.*,
       (previous_scored_runs.runs - previous_scored_runs.previous_score) as diff_between_cur_prev
from previous_scored_runs;

-- For every season, compare current match with previous match.
-- half part
select 
     m.*,
     lag(m.match_id,1,0) over(partition by season) prev_match_id
from matches m;

-- full part
with match_detail as (
select 
     m.*,
     lag(m.match_id,1,0) over(partition by season) prev_match_id
from matches m
)
select md.*,m.* 
from match_detail md
join matches m 
on md.prev_match_id = m.match_id;

-- Find players whose current innings score is higher than previous innings score.
with previous_scored_runs as (
select
   p.player_name,
   bs.runs,
   lag(bs.runs,1,0) over(partition by p.player_id order by m.match_date) as previous_score
from players p
join batting_scorecard bs
  on p.player_id = bs.player_id
join matches m
  on bs.match_id = m.match_id
),
diff as (select previous_scored_runs.*,
       (previous_scored_runs.runs - previous_scored_runs.previous_score) as previous_scored_runs
from previous_scored_runs
)
select diff.* from diff
where diff.previous_scored_runs > 0;

-- For every player's innings, show the first score they ever made

select
    first_value(bs.runs) over(partition by p.player_id order by m.match_date  )as first_inning_score,
    p.player_id,
    p.player_name,
	bs.runs 
from players p 
join batting_scorecard bs
on p.player_id = bs.player_id
join matches m
on bs.match_id = m.match_id;
;

-- For each season, show the first match played
select
    m.*,
    first_value(match_id) over(partition by m.season order by m.match_date ) as first_match
from matches m;

-- For each team, show the first player alphabetically.

select 
    first_value(p.player_name) over(partition by t.team_id order by p.player_name) as alphabetically_first,
    p.player_name,
    t.team_name
from players p
join teams t
   on p.team_id = t.team_id;
   
-- For each player's innings, compare current score with first innings score.

select 
    p.player_name,
    bs.runs,
    first_value(bs.runs) over(partition by p.player_id order by m.match_date) as first_inning_score
from players p
join batting_scorecard bs 
     on p.player_id = bs.player_id
join matches m 
     on bs.match_id = m.match_id;
     
-- For each player, calculate improvement over their first innings.

with inning as (
select 
    p.player_name,
    bs.runs,
    first_value(bs.runs) over(partition by p.player_id order by m.match_date) as first_inning_score
from players p
join batting_scorecard bs 
     on p.player_id = bs.player_id
join matches m 
     on bs.match_id = m.match_id
)
select inning.* ,
       (inning.runs - first_inning_score) as improvement
from inning ;

-- "Show only the latest improvement for each player"
WITH player_scores AS
(
    SELECT
        p.player_name,
        bs.runs,
        FIRST_VALUE(bs.runs)
        OVER(
            PARTITION BY p.player_id
            ORDER BY m.match_date
        ) AS first_score,

        ROW_NUMBER()
        OVER(
            PARTITION BY p.player_id
            ORDER BY m.match_date DESC
        ) AS rn
    FROM players p
    JOIN batting_scorecard bs
        ON p.player_id = bs.player_id
    JOIN matches m
        ON bs.match_id = m.match_id
)

SELECT
    player_name,
    runs,
    first_score,
    runs - first_score AS improvement
FROM player_scores
WHERE rn = 1;


-- For every player innings, show their latest score.
select  
     p.player_name,
     bs.runs,
     last_value(bs.runs) over(partition by p.player_id  order by m.match_date
        rows between unbounded preceding and unbounded following) as latest_inning_score 
from players p
join batting_scorecard bs
     on p.player_id = bs.player_id
join matches m
     on bs.match_id = m.match_id;
     
-- Show last match date of every season.
select 
     m.*,
     last_value(m.match_id) over(partition by m.season order by m.match_date
        rows between unbounded preceding and unbounded following) as last_match_of_season
from matches m;
	
-- For every player, compare current innings with latest innings.
select
    p.player_name,
    bs.runs,
    last_value(bs.runs) over(partition by p.player_id order by m.match_date
        rows between unbounded preceding and unbounded following) as latest_inning
from players p 
join batting_scorecard bs
      on p.player_id = bs.player_id
join matches m
      on bs.match_id = m.match_id;
      
-- best way
select
    p.player_name,
    m.match_date,
    bs.runs                                                          as current_innings,
    last_value(bs.runs) over(
        partition by p.player_id 
        order by m.match_date
        rows between unbounded preceding and unbounded following
    )                                                                as latest_innings,

    -- this is the comparison column that was missing:
    bs.runs - last_value(bs.runs) over(
        partition by p.player_id 
        order by m.match_date
        rows between unbounded preceding and unbounded following
    )                                                                as diff_from_latest,

    -- bonus: label it
    case
        when bs.runs = last_value(bs.runs) over(
            partition by p.player_id order by m.match_date
            rows between unbounded preceding and unbounded following) 
        then 'This is the latest innings'
        when bs.runs > last_value(bs.runs) over(
            partition by p.player_id order by m.match_date
            rows between unbounded preceding and unbounded following)
        then 'Better than latest'
        else 'Worse than latest'
    end                                                              as comparison_label

from players p
join batting_scorecard bs on p.player_id = bs.player_id
join matches m on bs.match_id = m.match_id
order by p.player_name, m.match_date;



-- Show latest wicket count for every bowler.

select
    p.player_name,
    bs.wickets,
    last_value(bs.wickets)over(partition by p.player_id order by m.match_date
        rows between unbounded preceding and unbounded following ) as latest_match_wicket
from players p
join bowling_scorecard bs
on p.player_id = bs.player_id
join matches m
on bs.match_id = m.match_id;

-- best way
select
    p.player_name,
    m.match_date,                          
    bs.wickets                             as this_match_wickets,
    last_value(bs.wickets) over(
        partition by p.player_id 
        order by m.match_date
        rows between unbounded preceding and unbounded following
    )                                      as latest_match_wickets,

    last_value(m.match_date) over(
        partition by p.player_id 
        order by m.match_date
        rows between unbounded preceding and unbounded following
    )                                      as latest_match_date

from players p
join bowling_scorecard bs on p.player_id = bs.player_id
join matches m on bs.match_id = m.match_id
order by p.player_name, m.match_date;

-- Find players whose latest score is their highest score.

select
    last_value(bs.runs)over(partition by p.player_id order by m.match_date 
    rows between unbounded preceding and unbounded following) as latest_inning_score
from players p
join batting_scorecard bs
on p.player_id = bs.player_id
join matches m 
on bs.match_id = m.match_id; -- for latest inninng of each player

select p.player_id,p.player_name,max(bs.runs)
from players p 
join batting_scorecard bs
on p.player_id = bs.player_id
group by p.player_id,p.player_name; -- for highest score inning by each player

-- final query
with latest_score as (
select
    distinct p.player_id,
    last_value(bs.runs)over(partition by p.player_id order by m.match_date 
    rows between unbounded preceding and unbounded following) as latest_inning_score
from players p
join batting_scorecard bs
on p.player_id = bs.player_id
join matches m 
on bs.match_id = m.match_id
),
highest_score as (
select p.player_id,p.player_name,max(bs.runs) as career_highest
from players p 
join batting_scorecard bs
on p.player_id = bs.player_id
group by p.player_id,p.player_name
)

select hs.player_name,ls.latest_inning_score,hs.career_highest
from latest_score ls 
join highest_score hs
on ls.player_id = hs.player_id
where ls.latest_inning_score = hs.career_highest
order by hs.career_highest desc;
 

