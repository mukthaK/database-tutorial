-- 2 Advanced SQL Queries
-- 2.1 window function
----------------------------------------------------------------------------------------------

-- BEGIN 2.1.1 List for each day, the 3 most popular hashtags in descending order
-- !!!!NICE EX 2.1
--- use '::date' to show only the date
SELECT 
t2.date,t2.hashtag,t2.count,t2.rank
FROM
(SELECT
t1.date,t1.hashtag,t1.count,
rank()OVER(PARTITION BY t1.date ORDER BY t1.count DESC) AS rank
FROM 
(
SELECT chirp.timestamp::date AS date,   hashtag.label AS hashtag, 
	COUNT(hashtag.label)

FROM hashtag, chirp, taginchirp 
WHERE chirp.cid = taginchirp.chirp AND hashtag.hid = taginchirp.tag
GROUP BY hashtag.label, chirp.timestamp::date
)t1
)t2
 WHERE t2.rank <= 3 ORDER BY t2.date,t2.rank ASC;
-- END 2.1.1

----------------------------------------------------------------------------------------------

-- 2.2 recursive queries
----------------------------------------------------------------------------------------------

--BEGIN 2.2.1 List in descending order the top-10 chirps
--- works!!! Ex 2.2.1

WITH gather(chirpid, rechirp_times) AS
(
SELECT rechirp.chirp, COUNT(*)
FROM	rechirp
GROUP BY rechirp.chirp

)
SELECT chirp.cid, chirp.text, rechirp_times
FROM gather, chirp
WHERE gather.chirpid = chirp.cid
ORDER BY rechirp_times DESC
LIMIT 10;
-- END 2.2.1

----------------------------------------------------------------------------------------------

--BEGIN 2.2.2 List in descending order the betweeness centrality of evry user w.r.t the frien's relationship
-- in order to compute the 'betweeness centrality', 
-- we use the new Table named follower_1 instead of follower where we insert one more column to store the distance between two friend, named 'dis',

CREATE TABLE follower_1(
fkuid integer REFERENCES users(uid),
 friend integer 
   );
---------------------
ALTER TABLE follower_1 
	ADD COLUMN dis int;
	
----------------------
INSERT INTO follower_1 (fkuid, friend,dis)
VALUES
( 1, 2,1),
( 1, 3,1),
( 1, 4,1),
( 2, 5,1),
( 3, 4,1),
( 4, 5,1),
( 2, 1,1),
( 3, 1,1),
( 4, 1,1),
( 5, 2,1),
( 4, 3,1);
------------------------------------
-- at first the distance of every two node in the FOLLOWER_1 should be 1.
-- it can be shown in the following table, the distance between my friend and me is 1 
-- while the distance between my friend's friend (which is not my friend)and me is 2, and so on.
-- this query can show all the relationship between the userid and friendid, even some indirect friendships.

WITH RECURSIVE friend_network(userid,frid,level) AS 
----- userid is the id of the user; frid is the id of the friend, level is the path between the user and the friend
(
  SELECT fkuid, friend, dis
	FROM follower_1
  
UNION
  SELECT a1.fkuid, a2.frid, min(a2.level + a1.dis)over (PARTITION BY a1.fkuid, a2.frid) as level
   FROM follower_1 a1 ,  friend_network a2
   WHERE a1.friend = a2.userid
 
)
SELECT DISTINCT *
FROM
( 
SELECT
p.userid, p.frid, min(p.level)over (PARTITION BY p.userid, p.frid) AS distance --- because we want to find the shortest path
FROM
(
SELECT h.userid, h.frid,h.level
FROM friend_network h
WHERE h.userid <> h.frid -- someone cannot be friend of himself
LIMIT 100
) p
)q
ORDER BY q.distance ASC;
-- END 2.2.2

----------------------------------------------------------------------------------------------

