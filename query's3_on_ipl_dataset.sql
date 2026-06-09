-- Divide players into 4 groups according to total runs.
-- half part
select 
  p.player_id,
  p.player_name,
  sum(bs.runs) as total_runs
from players p
join batting_scorecard bs
on p.player_id = bs.player_id
group by p.player_id,p.player_name
order by total_runs desc;

-- final part
with player_score as (
select 
  p.player_id,
  p.player_name,
  sum(bs.runs) as total_runs
from players p
join batting_scorecard bs
on p.player_id = bs.player_id
group by p.player_id,p.player_name
)
select ps.*, ntile(4) over( order by ps.total_runs desc) as group_category,
case ntile(4) over (order by ps.total_runs desc) 
      when 1 then 'Elite'
      when 2 then 'Good'
      when 3 then 'Average'
      when 4 then 'Needs Improvement'
end as group_label
from player_score ps
order by ps.total_runs desc;

-- Divide bowlers into 3 performance buckets according to wickets.
-- half way
select
   p.player_id,p.player_name,
   sum(bs.wickets) as total_w
from players p
join bowling_scorecard bs 
on p.player_id = bs.player_id
group by p.player_id,p.player_name
;
-- my final answer

with wickets as (
select
   p.player_id,p.player_name,
   sum(bs.wickets) as total_w
from players p
join bowling_scorecard bs 
on p.player_id = bs.player_id
group by p.player_id,p.player_name
)
select w.*,ntile(3) over(order by w.total_w desc) as bucket_s,
case ntile(3) over(order by w.total_w desc)
   when 1 then 'Goal'
   when 2 then 'Average'
   when 3 then 'below Average Player'
   end as bowler_category
from wickets w
order by w.total_w desc
;

-- Split matches into 5 groups according to date.
select 
    m.*, ntile(5) over(order by m.match_date) as date_group
from matches m;
-- partitionn by season (extra)
select 
    m.*, ntile(5) over(partition by m.season order by m.match_date) as date_group
from matches m;

-- Divide players into quartiles based on strike rate.
-- half part
select 
    p.player_name,
    p.player_id,
    sum(bs.runs) as total_run,
    sum(bs.balls) as total_balls,
    -- avoiding divided by 0
    case 
       when sum(bs.balls) = 0 then 0
       else round( sum(bs.runs) *100.0 /  sum(bs.balls),2 ) 
    end as strike_rate
from players p
join batting_scorecard bs
on p.player_id = bs.player_id
group by p.player_id,p.player_name;

-- full part

with info_tab as (
select 
    p.player_name,
    p.player_id,
    sum(bs.runs) as total_run,
    sum(bs.balls) as total_balls,
	-- round( sum(bs.runs) *100.0 /  sum(bs.balls),2 ) as strike_rate -- here if balls played 0 then it devide by  0 which danguorus
    case 
        when sum(bs.balls) = 0 then 0
        else round( sum(bs.runs) *100.0 /  sum(bs.balls),2 ) 
    end as strike_rate
from players p
join batting_scorecard bs
on p.player_id = bs.player_id
group by p.player_id,p.player_name
)
select it.*,
        ntile(4) over(order by it.strike_rate desc) as quartiles
from info_tab it;


-- Find players belonging to the top quartile.
with info_tab as (
select 
    p.player_name,
    p.player_id,
    sum(bs.runs) as total_run,
    sum(bs.balls) as total_balls,
    case 
      when sum(bs.balls) = 0 then 0
      else round( sum(bs.runs) *100.0 /  sum(bs.balls),2 ) 
	end as strike_rate
from players p
join batting_scorecard bs
on p.player_id = bs.player_id
group by p.player_id,p.player_name
),
quartile_dist as (
select it.*,
        ntile(4) over(order by it.strike_rate desc) as quartiles
from info_tab it
)
select qd.* from quartile_dist qd where qd.quartiles = 1;

-- For every player's innings, show the 2nd highest score that player has ever made. Use NTH_VALUE() to find it.

select
     p.player_name,
     m.match_id,
     bs.runs,
     nth_value(bs.runs,2) over(partition by p.player_id order by bs.runs desc
							  rows between unbounded preceding and unbounded following) as second_highest_score
     
from players p
join batting_scorecard bs 
         on p.player_id = bs.player_id
join matches m
		 on bs.match_id = m.match_id
order by p.player_name, bs.runs desc;

-- For each team, show every bowler's wickets along with the 3rd highest wicket haul ever taken by any bowler in that team.
select 
     t.team_name,
     p.player_name,
     bs.wickets,
     nth_value(bs.wickets,3) over(partition by t.team_id order by bs.wickets desc
                            rows between unbounded preceding and unbounded following) as third_highest_wicket_hual
from players p
join bowling_scorecard bs
    on p.player_id = bs.player_id
join teams t 
   on p.team_id = t.team_id
order by t.team_name, bs.wickets desc;
     
-- Within each IPL season, show every match along with the 2nd earliest match date of that season. 
-- This tells you when the second game of the season was played.

select m.season,
       m.match_id,
       m.match_date,
       nth_value(m.match_date,2) over(partition by m.season order by m.match_date 
									 rows between unbounded preceding and unbounded following) as second_earliest_match,
		case when m.match_date = nth_value(m.match_date, 2) over(
                 partition by m.season order by m.match_date rows between unbounded preceding and unbounded following)
    then '2nd match of season' else '' end as flag
from matches m
order by m.match_date,m.season;

-- For each player, find their 3rd innings (3rd match they batted in, ordered by match date). 
-- Show it alongside their actual runs in every innings — so you can see how their 3rd game compares to each game.

select
    p.player_name,
    m.match_date,
    bs.runs,
    nth_value(bs.runs,3) over(partition by p.player_id order by m.match_date 
                           rows between unbounded preceding and unbounded following ) as third_inning_score,
	case 
        when nth_value(bs.runs,3) over(partition by p.player_id order by m.match_date 
		rows between unbounded preceding and unbounded following ) is null then 'Less than 3 innings'
        else cast( nth_value(bs.runs,3) over(partition by p.player_id order by m.match_date 
                           rows between unbounded preceding and unbounded following ) as char )
		end as third_inning_score
	from players p
	join batting_scorecard bs
         on p.player_id = bs.player_id
	join matches m 
         on bs.match_id = m.match_id;
         
-- Using a CTE, find all players whose 2nd best innings score is greater than 50. 
-- These are players who have been consistently good — not just a one-time century.

with second_best_score_per_player as (
select
     p.player_name,
     bs.runs,
     nth_value(bs.runs,2) over(partition by p.player_id order by bs.runs desc
                              rows between unbounded preceding and unbounded following ) as second_best_score 
from players p
join batting_scorecard bs
on p.player_id = bs.player_id
)
select distinct sbspp.player_name ,sbspp.second_best_score  
from  second_best_score_per_player sbspp where sbspp.second_best_score > 50 ;
-- more clear

with scores as 
(select
     p.player_name,
     bs.runs,
     nth_value(bs.runs,1) over w as first_best_score,
     nth_value(bs.runs,2) over w as second_best_score,
     case
         when nth_value(bs.runs,2) over w is null then 'less then 2 inning'
         else nth_value(bs.runs,2) over w
	 end as second_in
from players p
join batting_scorecard bs
on p.player_id = bs.player_id
window w as (partition by p.player_id order by bs.runs desc
                              rows between unbounded preceding and unbounded following ) 
)
select distinct s.player_name , s.first_best_score, s.second_best_score
from scores s 
where second_best_score > 50
order by second_best_score desc;


-- Calculate cumulative distribution of players by runs.

select 
     p.player_name,
     p.player_id,
     sum(bs.runs) as total_runs,
     round(cume_dist()over(order by  sum(bs.runs) desc )*100,2) as cume_dist_runs,
     rank() over(order by sum(bs.runs) desc) as run_rank
from players p
join batting_scorecard bs
  on p.player_id = bs.player_id
group by p.player_name,p.player_id
order by total_runs desc;


 -- Find players in top 20% run scorers.
 
 with cume_dist_by_run as (
 select 
     p.player_name,
     p.player_id,
     sum(bs.runs) as total_runs,
     cume_dist() over(order by sum(bs.runs) desc) as raw_cd,
     round(cume_dist()over(order by  sum(bs.runs) desc )*100,2) as cume_dist_runs
from players p
join batting_scorecard bs
  on p.player_id = bs.player_id
group by p.player_name,p.player_id
order by total_runs desc
)
select cdbr.* 
from cume_dist_by_run cdbr 
where cdbr.raw_cd < 0.20;

-- Find bowlers in top 25% wicket takers.
with wicket_takers as (
select p.player_name,
       p.player_id,
       sum(bs.wickets) as total_wicket,
       cume_dist() over(order by sum(bs.wickets) desc) as raw_cd,
       round(cume_dist() over(order by  sum(bs.wickets) desc)*100 ,2) as cume_dist_wickets
from players p
join bowling_scorecard bs
         on p.player_id = bs.player_id
group by p.player_id,p.player_name
order by total_wicket desc 
)
select wt.* 
from wicket_takers wt 
where wt.raw_cd < 0.25 ;

-- Calculate cumulative distribution within each team.

-- select t.team_id,
--        t.team_name,
--        cume_dist()  over( order by t.team_name )*100 as team_cume_dist
-- from teams t;

select 
    t.team_name,
    t.titles_won,
    round(cume_dist() over(order by t.titles_won desc) * 100, 2) as cume_dist_pct
from teams t
order by titles_won desc;

select 
    t.team_name,
    p.player_name,
    sum(bs.runs) as total_runs,
    round(cume_dist() over(
        partition by p.team_id          -- within each team
        order by sum(bs.runs) desc      -- by performance
    ) * 100, 2) as cume_dist_within_team
from players p
join batting_scorecard bs on p.player_id = bs.player_id
join teams t on p.team_id = t.team_id
group by p.team_id, p.player_id, p.player_name, t.team_name
order by t.team_name, total_runs desc;

-- Calculate percent rank of players by runs

select 
     p.player_name,
     p.player_id,
     sum(bs.runs) as total_runs,
     percent_rank() over(order by sum(bs.runs) desc) as perc_by_run,
     round(cume_dist()over(order by  sum(bs.runs) desc )*100,2) as cume_dist_runs,
     rank() over(order by sum(bs.runs) desc) as run_rank
from players p
join batting_scorecard bs
  on p.player_id = bs.player_id
group by p.player_name,p.player_id
order by total_runs desc;      

-- Calculate percent rank of bowlers by wickets.
select p.player_name,
       p.player_id,
       sum(bs.wickets) as total_wicket,
       cume_dist() over(order by sum(bs.wickets) desc) as raw_cd,
       round(cume_dist() over(order by  sum(bs.wickets) desc)*100 ,2) as cume_dist_wickets,
       percent_rank() over( order by sum(bs.wickets)  desc ) as wicket_perc
from players p
join bowling_scorecard bs
         on p.player_id = bs.player_id
group by p.player_id,p.player_name
order by total_wicket desc ;

-- Find players in top 10% by runs.
with player_perc as (
select 
     p.player_name,
     p.player_id,
     sum(bs.runs) as total_runs,
     percent_rank() over(order by sum(bs.runs) desc) as perc_by_run,
     round(cume_dist()over(order by  sum(bs.runs) desc )*100,2) as cume_dist_runs,
     rank() over(order by sum(bs.runs) desc) as run_rank
from players p
join batting_scorecard bs
  on p.player_id = bs.player_id
group by p.player_name,p.player_id
)
select pp.player_name,pp.player_id,pp.total_runs,pp.perc_by_run 
from player_perc pp where pp.perc_by_run < 0.10 ;

-- Find teams by win percentage and assign percent rank.
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
)-- ,
 -- total_win as
 -- (
 select tr.team_id,
	   t.team_name,
       count(*) as matches_played,
       count(tr.result)
   
from team_results tr
join teams t
   on tr.team_id = t.team_id

   
where tr.result = 'win'
group by tr.team_id
-- )

