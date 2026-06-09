create database if not exists ipl;
use ipl;
create table teams (
  team_id    INT PRIMARY KEY AUTO_INCREMENT,
  team_name  VARCHAR(50) NOT NULL,
  city       VARCHAR(50),
  titles_won INT DEFAULT 0
);

create table players (
  player_id   INT PRIMARY KEY AUTO_INCREMENT,
  player_name VARCHAR(100) NOT NULL,
  team_id     INT,
  role        VARCHAR(30),
  nationality VARCHAR(30),
  FOREIGN KEY (team_id) REFERENCES teams(team_id)
);

CREATE TABLE matches (
  match_id   INT PRIMARY KEY AUTO_INCREMENT,
  season     INT,
  match_date DATE,
  team1_id   INT,
  team2_id   INT,
  winner_id  INT,
  venue      VARCHAR(100),
  FOREIGN KEY (team1_id) REFERENCES teams(team_id),
  FOREIGN KEY (team2_id) REFERENCES teams(team_id),
  FOREIGN KEY (winner_id) REFERENCES teams(team_id)
);

CREATE TABLE batting_scorecard (
  score_id   INT PRIMARY KEY AUTO_INCREMENT,
  match_id   INT,
  player_id  INT,
  runs       INT DEFAULT 0,
  balls      INT DEFAULT 0,
  fours      INT DEFAULT 0,
  sixes      INT DEFAULT 0,
  is_out     TINYINT DEFAULT 1,
  FOREIGN KEY (match_id)  REFERENCES matches(match_id),
  FOREIGN KEY (player_id) REFERENCES players(player_id)
);

CREATE TABLE bowling_scorecard (
  bowl_id    INT PRIMARY KEY AUTO_INCREMENT,
  match_id   INT,
  player_id  INT,
  overs      DECIMAL(4,1),
  runs_given INT DEFAULT 0,
  wickets    INT DEFAULT 0,
  FOREIGN KEY (match_id)  REFERENCES matches(match_id),
  FOREIGN KEY (player_id) REFERENCES players(player_id)
);

INSERT INTO teams (team_name, city, titles_won) VALUES
  ('Mumbai Indians',          'Mumbai',    5),
  ('Chennai Super Kings',     'Chennai',   5),
  ('Kolkata Knight Riders',   'Kolkata',   3),
  ('Royal Challengers Bengaluru', 'Bengaluru', 0),
  ('Rajasthan Royals',        'Jaipur',    2),
  ('Delhi Capitals',          'Delhi',     0),
  ('Sunrisers Hyderabad',     'Hyderabad', 1),
  ('Punjab Kings',            'Mohali',    0);

-- ---- PLAYERS ----
INSERT INTO players (player_name, team_id, role, nationality) VALUES
  ('Rohit Sharma',      1, 'Batsman',     'Indian'),
  ('Jasprit Bumrah',    1, 'Bowler',      'Indian'),
  ('Suryakumar Yadav',  1, 'Batsman',     'Indian'),
  ('MS Dhoni',          2, 'Wicketkeeper','Indian'),
  ('Ravindra Jadeja',   2, 'All-rounder', 'Indian'),
  ('Ruturaj Gaikwad',   2, 'Batsman',     'Indian'),
  ('Virat Kohli',       4, 'Batsman',     'Indian'),
  ('Glenn Maxwell',     4, 'All-rounder', 'Australian'),
  ('Mohammed Siraj',    4, 'Bowler',      'Indian'),
  ('Shreyas Iyer',      3, 'Batsman',     'Indian'),
  ('Andre Russell',     3, 'All-rounder', 'West Indian'),
  ('Sunil Narine',      3, 'All-rounder', 'West Indian'),
  ('Sanju Samson',      5, 'Wicketkeeper','Indian'),
  ('Jos Buttler',       5, 'Batsman',     'English'),
  ('Yuzvendra Chahal',  5, 'Bowler',      'Indian'),
  ('David Warner',      7, 'Batsman',     'Australian'),
  ('Bhuvneshwar Kumar', 7, 'Bowler',      'Indian'),
  ('KL Rahul',          8, 'Batsman',     'Indian'),
  ('Arshdeep Singh',    8, 'Bowler',      'Indian'),
  ('Rishabh Pant',      6, 'Wicketkeeper','Indian');

-- ---- MATCHES ----
INSERT INTO matches (season, match_date, team1_id, team2_id, winner_id, venue) VALUES
  (2023,'2023-04-01',1,2,1,'Wankhede Stadium'),
  (2023,'2023-04-03',3,4,4,'Eden Gardens'),
  (2023,'2023-04-05',5,6,5,'Sawai Mansingh'),
  (2023,'2023-04-07',7,8,7,'Rajiv Gandhi Stadium'),
  (2023,'2023-04-10',1,3,3,'Wankhede Stadium'),
  (2023,'2023-04-12',2,4,2,'MA Chidambaram'),
  (2023,'2023-04-15',5,7,5,'Sawai Mansingh'),
  (2023,'2023-04-18',6,8,8,'Arun Jaitley Stadium'),
  (2023,'2023-04-20',1,4,1,'Wankhede Stadium'),
  (2023,'2023-04-22',2,3,2,'MA Chidambaram'),
  (2024,'2024-03-22',1,2,2,'Wankhede Stadium'),
  (2024,'2024-03-24',3,5,3,'Eden Gardens'),
  (2024,'2024-03-26',4,6,4,'Chinnaswamy Stadium'),
  (2024,'2024-03-28',7,8,8,'Rajiv Gandhi Stadium'),
  (2024,'2024-04-01',1,5,1,'Wankhede Stadium'),
  (2024,'2024-04-03',2,6,2,'MA Chidambaram'),
  (2024,'2024-04-06',3,7,7,'Eden Gardens'),
  (2024,'2024-04-09',4,8,4,'Chinnaswamy Stadium'),
  (2024,'2024-04-12',1,3,1,'Wankhede Stadium'),
  (2024,'2024-04-15',2,5,5,'MA Chidambaram');

-- ---- BATTING SCORECARD ----
INSERT INTO batting_scorecard (match_id, player_id, runs, balls, fours, sixes, is_out) VALUES
  (1,1,74,48,8,3,1),(1,3,45,30,4,2,1),(1,7,12,10,1,0,1),
  (2,10,67,45,6,2,1),(2,7,89,56,7,4,0),(2,8,34,20,2,2,1),
  (3,13,92,58,8,5,1),(3,14,55,38,4,3,1),(3,18,23,18,2,0,1),
  (4,16,81,52,7,4,1),(4,17,0,2,0,0,1),(4,18,41,30,3,2,1),
  (5,1,55,40,5,2,1),(5,10,38,28,3,1,1),(5,11,67,32,4,5,1),
  (6,4,18,15,1,0,1),(6,6,72,50,6,3,1),(6,7,44,35,3,2,1),
  (7,13,48,35,4,2,1),(7,15,5,8,0,0,1),(7,16,33,25,2,1,1),
  (8,20,61,40,5,3,1),(8,19,8,6,0,0,1),(8,18,54,38,4,2,1),
  (9,1,102,60,10,6,0),(9,3,34,25,3,1,1),(9,7,21,18,1,1,1),
  (10,4,9,10,0,0,1),(10,5,43,30,3,2,1),(10,6,88,55,7,4,0),
  (11,1,68,45,7,2,1),(11,4,22,18,2,0,1),(11,7,15,12,1,0,1),
  (12,10,44,32,4,1,1),(12,13,76,48,6,4,1),(12,14,31,22,2,1,1),
  (13,7,93,58,8,5,0),(13,8,47,30,3,3,1),(13,20,39,28,3,1,1),
  (14,16,29,22,2,1,1),(14,18,62,42,5,3,1),(14,19,4,5,0,0,1),
  (15,1,85,52,8,4,1),(15,3,51,38,4,2,1),(15,13,28,20,2,1,1),
  (16,6,66,45,5,3,0),(16,4,14,12,1,0,1),(16,5,37,28,3,1,1),
  (17,16,71,50,6,3,1),(17,17,3,4,0,0,1),(17,10,49,35,4,2,1),
  (18,7,58,40,5,2,1),(18,8,82,48,6,5,1),(18,20,27,20,2,1,1),
  (19,1,91,55,9,5,0),(19,11,53,33,3,4,1),(19,3,29,22,2,1,1),
  (20,13,77,50,6,4,1),(20,14,42,30,3,2,1),(20,5,60,42,5,3,0);

-- ---- BOWLING SCORECARD ----
INSERT INTO bowling_scorecard (match_id, player_id, overs, runs_given, wickets) VALUES
  (1,2,4.0,28,2),(1,9,4.0,35,1),(1,5,4.0,22,2),
  (2,2,4.0,31,3),(2,9,3.0,29,1),(2,15,4.0,18,2),
  (3,2,4.0,24,1),(3,17,4.0,32,2),(3,15,4.0,26,3),
  (4,2,4.0,19,3),(4,9,4.0,38,0),(4,19,4.0,27,2),
  (5,2,4.0,33,2),(5,12,4.0,21,3),(5,9,3.0,25,1),
  (6,2,4.0,29,1),(6,5,4.0,18,2),(6,15,4.0,24,2),
  (7,17,4.0,30,2),(7,2,4.0,22,3),(7,19,4.0,34,1),
  (8,2,4.0,26,2),(8,9,4.0,31,1),(8,19,4.0,20,3),
  (9,9,4.0,42,1),(9,5,4.0,28,2),(9,15,4.0,39,0),
  (10,2,4.0,24,3),(10,9,4.0,27,2),(10,17,4.0,22,1),
  (11,2,4.0,30,2),(11,9,4.0,33,1),(11,5,3.0,20,2),
  (12,2,4.0,25,3),(12,15,4.0,29,2),(12,17,4.0,31,0),
  (13,2,4.0,38,1),(13,19,4.0,27,2),(13,5,4.0,24,3),
  (14,2,4.0,21,3),(14,9,4.0,35,1),(14,17,3.0,18,2),
  (15,9,4.0,32,2),(15,2,4.0,28,1),(15,15,4.0,24,3),
  (16,2,4.0,23,2),(16,5,4.0,26,2),(16,17,4.0,30,1),
  (17,2,4.0,19,4),(17,9,4.0,28,1),(17,19,3.0,22,2),
  (18,9,4.0,35,2),(18,2,4.0,31,3),(18,5,3.0,21,1),
  (19,9,4.0,29,3),(19,2,4.0,24,2),(19,15,4.0,33,1),
  (20,2,4.0,22,3),(20,17,4.0,27,2),(20,15,4.0,31,1);