-- Database: "TinnyTweet"

-- DROP DATABASE "TinnyTweet";
/* PostgreSQL ( >=9) database system is required to achieve this assignment. */
CREATE DATABASE "TinnyTweet"
  WITH OWNER = postgres
       ENCODING = 'UTF8'
       TABLESPACE = pg_default
       LC_COLLATE = 'French_France.1252'
       LC_CTYPE = 'French_France.1252'
       CONNECTION LIMIT = -1;
	   


--%%%%%%%%%%%%%%% FOR DDL PART, create table  %%%%%%%%%%%%%%%%%%%%%%

CREATE TABLE users(
userid serial PRIMARY KEY,
username varchar(50)  Unique NOT NULL,
password varchar(50) NOT NULL,
geotag varchar(100)
);
CREATE TABLE tweet(
tid serial PRIMARY KEY,
text varchar(255) NOT NULL,
timestamp varchar(100) NOT NULL,
userid integer REFERENCES users(userid)
);
CREATE TABLE hashtag(
hid serial PRIMARY KEY,
labeltag varchar(50)
);
CREATE TABLE tagintweet(
tagid integer PRIMARY KEY,
hid integer REFERENCES hashtag(hid),
tid integer REFERENCES tweet(tid)
);
CREATE TABLE mention(
mentionid serial PRIMARY KEY,
tid integer REFERENCES tweet(tid), 
userid integer REFERENCES users(userid)
);
----%%%%%the user cannot retweet his own tweet
CREATE TABLE retweet(
id serial PRIMARY KEY,
tid integer REFERENCES tweet(tid),
retweetid integer CHECK ( tid > retweetid OR retweetid > tid)
);
--%%% 'if the user has no friend then we did not store his information.%%%%the user cannot follow himself'
CREATE TABLE follower(
followerid serial PRIMARY KEY,
userid integer REFERENCES users(userid),
friendid integer NOT NULL CHECK ( friendid > userid OR userid > friendid)
);
---%%%%% the user can favorite his own tweets
CREATE TABLE favorite(
favoriteid serial PRIMARY KEY,
userid integer REFERENCES users(userid),
tid integer REFERENCES tweet(tid)
);

--%%%%%%============PART 2 insert the information into the database    ========================

INSERT INTO users (userid, username,password, geotag)
VALUES
(1, 'me', 'zhege00', 'lyon'),
(2, 'yuehe', 'zuoye11', 'lyon'),
(3, 'donghua', 'shishuju', 'denmark'),
(4, 'huihui', 'shujuku', 'london'),
(5, 'lucy', 'basicsql', 'china');

INSERT INTO tweet (tid,text, timestamp,userid)
VALUES
('1', 'This is the first day in #DMKM, @yuehe','20130901',1),
('2', 'I heard the guys in #Nantes enjoyed the life @me','20131001',2),
('3', 're:Everybody, there is a huge discount in Auchan!','20131001',2),
('4', 'Perpignan is the biggest one in our department of the Pyrenees Orientales.@me','20131001',3),
('5', 'In which city do you want to go to the #Christmas Market?','20131003',4),
('6', 'The buildings are just as grand, but are on a scale that feels intimate. ','20131004',5),
('7', '#Christmas, A few balconies have been festooned with tinsel and small boxes decorated to look like presents.','20131004',1),
('8', '#food If you are feeling hungry, I can recommend the Paninis, such a great hot pressed sandwich.','20131014',2),
('9', '#food My parents told me "Croque Monsieur", traditional hot ham and cheese sandwiches, are really good.@me','20131014',3),
('10', 'In #Nantes, its banks decorated with long well-kept lawns and pretty flower beds.@me ','20131021',4),
('11', 'The snow is artificial but it does make it feel like #Christmas.@lucy','20131021',2),
('12', 'Mmmm, I smell spice bread, a traditional French #Christmas treat. Thanks for #DMKM','20131022',3),
('13', 're:re:Everybody, there is a huge discount in Auchan!','20131101',4),
('14', 're:What a great day it is been but now it is time to go home and put our feet up','20131103',5),
('15', 'After dinner we wander back out into a fairyland of sparkling lights.','20131101',3),
('16', 'What a great day it is been but now it is time to go home and put our feet up.','20131102',2),
('17', 'Fighting!#DMKM','20131103',4),
('18', 'Everybody, there is a huge discount in Auchan!','20130925',1);

INSERT INTO hashtag (hid, labeltag)
VALUES
(1, 'DMKM'),
(2, 'Christmas'),
(3, 'food'),
(4, 'Nantes');

INSERT INTO tagintweet (tagid, hid, tid)
VALUES
(1, 1, 1),
(2, 1, 17),
(3, 2, 5),
(4, 2, 7),
(5, 2, 11),
(6, 2, 12),
(7, 3, 8),
(8, 3, 9),
(9, 4, 2),
(10, 4, 10);

INSERT INTO mention (mentionid,tid, userid)
VALUES
(1, 1, 2),
(2, 2, 1),
(3, 4, 1),
(4, 9, 1),
(5, 10, 1),
(6, 11, 5);

INSERT INTO retweet (tid, retweetid)
VALUES
(18, 3),
(18, 13),
(16, 14);

INSERT INTO follower (followerid, userid,friendid)
VALUES
(1, 1, 2),
(2, 1, 3),
(3, 1, 4),
(4, 2, 5),
(5, 3, 4),
(6, 4, 5),
(7, 2, 1),
(8, 3, 1),
(9, 4, 1),
(10, 5, 2),
(11, 4, 3);

INSERT INTO favorite (favoriteid, userid,tid)
VALUES
(1, 1, 2),
(2, 1, 3),
(3, 1, 4),
(4, 1, 5),
(5, 2, 6),
(6, 1, 13),
(7, 3,13);

--%%%%%%==================PART 3 query the information from the database    ==================
-- Write SQL statements to translate the queries

--%%% 1-a List all tweets of user me in descending timestamp order

SELECT text, timestamp 
FROM tweet
WHERE userid in (SELECT userid FROM users WHERE username LIKE 'me')
ORDER BY timestamp DESC;

--% 'there is another way to solve the problem'
SELECT text, timestamp 
FROM tweet
WHERE userid = (SELECT userid FROM users WHERE username LIKE 'me')
ORDER BY timestamp DESC;

--% 'there is another way to solve the problem'
SELECT text, timestamp 
FROM users,tweet 
WHERE users.userid = tweet.userid AND 
	username like 'me';
ORDER BY timestamp DESC;

--% 'there is another way to solve the problem'
SELECT text, timestamp 
FROM tweet INNER JOIN users ON tweet.userid = users.userid
WHERE username LIKE 'me'
ORDER BY timestamp DESC;

--%%% 1-b List the 10 more recent tweets from friends of me

SELECT text, timestamp 
From tweet
WHERE userid in (SELECT friendid FROM follower WHERE userid = (SELECT userid FROM users WHERE username LIKE 'me'))
ORDER BY timestamp DESC LIMIT 10;

--%%% 1-c Give location of users that tweet about #Nantes
--%% 'firstly, find the tweet with 'Nantes', then find the user information (userid). At last find the geo information based on the userid'

SELECT geotag 
FROM users
WHERE userid in (
	SELECT userid 
	FROM tweet 
	WHERE tid in(
		SELECT tid 
		FROM tagintweet
		WHERE hid in(
			SELECT hid 
			FROM hashtag
			WHERE labeltag = 'Nantes')
			)
		);
	
--%%% 2-a Give the average number of followers by user

WITH friendnum AS
(
SELECT userid,COUNT(*) AS fnum
FROM follower
GROUP BY userid
)
SELECT AVG(fnum) AS avg_followers
FROM friendnum 

--%%% 2-b Give the number of tweets a day for the entire last month.

SELECT timestamp, COUNT(*) AS num_tweet_oneday
FROM tweet
WHERE timestamp LIKE '201310%'
GROUP BY timestamp
ORDER BY timestamp

--%%% 3-a List in descending timestamp order both tweets that mention user me, and retweets from me

WITH
related_me AS
(
SELECT tweet.tid, text, timestamp
FROM tweet, users,mention
WHERE
	users.username LIKE 'me' AND
	users.userid = mention.userid AND
	mention.tid = tweet.tid
union

SELECT tweet.tid, text, timestamp
FROM tweet
WHERE tid in (
	SELECT retweet.retweetid
	FROM retweet, users,tweet
	WHERE 
		users.username LIKE 'me' AND
		users.userid = tweet.userid AND
		tweet.tid = retweet.tid
		)
)
SELECT *
FROM  related_me
ORDER BY timestamp DESC

--%%% 2-b  Find users that never mention their friends
--% 'IN this case, the person can only metion their friends, not himself or whom he did not know' 

WITH  mentionset AS
(
SELECT userid
FROM tweet
WHERE tid in(
	SELECT tid
	FROM mention
		)
GROUP BY userid
)
SELECT userid AS never_mention_frd
FROM users
WHERE userid NOT IN (
SELECT userid
FROM mentionset
)

--%%% 2-c Find users that have retweeted all their friends

WITH 
orguid AS
(
SELECT retweet.id, users.userid AS original_user
FROM retweet, tweet, users
WHERE retweet.tid = tweet.tid AND 
	tweet.userid = users.userid 
),
reuid AS
(
SELECT retweet.id, users.userid AS re_userid
FROM retweet, tweet, users
WHERE retweet.retweetid = tweet.tid AND
	tweet.userid = users.userid
),
num_re AS
(
SELECT re_userid, COUNT (*) AS num_retweet
FROM orguid INNER JOIN reuid ON orguid.id = reuid.id
GROUP BY re_userid
),
num_fr AS
(
SELECT follower.userid, COUNT (*) AS num_friend
FROM follower 
GROUP BY follower.userid
),
reslut AS
(
SELECT  userid, num_friend - num_retweet AS tempt
FROM num_fr, num_re
WHERE   num_re.re_userid = num_fr.userid
)
SELECT userid AS re_all_frd
FROM reslut
WHERE tempt = 0








