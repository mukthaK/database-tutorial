ALTER TABLE users 
	RENAME COLUMN userid TO uid;
ALTER TABLE users 
	ADD COLUMN date_of_registration date;
ALTER TABLE users 
	ADD COLUMN gravatar bytea;

ALTER TABLE tweet
	RENAME TO chirp;
	
ALTER TABLE chirp
	RENAME COLUMN tid TO cid;
	
ALTER TABLE chirp
	RENAME COLUMN userid TO author;

ALTER TABLE hashtag
	RENAME COLUMN labeltag TO label;

ALTER TABLE tagintweet
	RENAME TO taginchirp;

ALTER TABLE taginchirp
	ADD PRIMARY KEY (hid, tid);
ALTER TABLE taginchirp
	RENAME COLUMN hid TO tag;
ALTER TABLE taginchirp
	RENAME COLUMN tid TO chirp;


	
ALTER TABLE mention
	ADD PRIMARY KEY (tid, userid);
ALTER TABLE mention
	RENAME COLUMN tid TO chirp;
ALTER TABLE mention
	RENAME COLUMN userid TO FKuid;


ALTER TABLE retweet
	RENAME TO rechirp;
ALTER TABLE rechirp
	ADD PRIMARY KEY (tid, retweetid);
ALTER TABLE rechirp
	RENAME COLUMN tid TO chirp;
ALTER TABLE rechirp
	RENAME COLUMN retweetid TO rechirp;


ALTER TABLE follower
	ADD PRIMARY KEY (userid, friendid);
ALTER TABLE follower
	RENAME COLUMN userid TO fkuid;
ALTER TABLE follower
	RENAME COLUMN friendid TO friend;


ALTER TABLE favorite
	ADD PRIMARY KEY (userid, tid);
ALTER TABLE favorite
	RENAME COLUMN userid TO chirp;
ALTER TABLE favorite
	RENAME COLUMN tid TO fkuid;



-- BEGIN data in the previous database (first assignment SQL basic)
INSERT INTO users (uid, username,password, date_of_registration, geotag, gravatar)
VALUES
(1, 'me', 'zhege00', '2009-10-01', 'lyon', ''),
(2, 'yuehe', 'zuoye11','2009-10-02', 'lyon', ''),
(3, 'donghua', 'shishuju','2010-09-01', 'denmark','' ),
(4, 'huihui', 'shujuku', '2009-10-09','london', ''),
(5, 'lucy', 'basicsql','2009-12-01', 'china', '');


INSERT INTO hashtag (hid, label)
VALUES
(1, 'DMKM'),
(2, 'Christmas'),
(3, 'food'),
(4, 'Nantes');


INSERT INTO chirp (cid,text, timestamp,author)
VALUES
('1', 'This is the first day in #DMKM, @yuehe','2013-09-01 11:23:22',1),
('2', 'I heard the guys in #Nantes enjoyed the life @me','2013-10-01 11:23:22',2),
('3', 're:Everybody, there is a huge discount in Auchan!','2013-10-01 12:23:22',2),
('4', 'Perpignan is the biggest one in our department of the Pyrenees Orientales.@me','2013-10-01 11:23:22',3),
('5', 'In which city do you want to go to the #Christmas Market?','2013-10-03 11:23:22',4),
('6', 'The buildings are just as grand, but are on a scale that feels intimate. ','2013-10-04 11:23:22',5),
('7', '#Christmas, A few balconies have been festooned with tinsel and small boxes decorated to look like presents.','2013-10-04 11:23:22',1),
('8', '#food If you are feeling hungry, I can recommend the Paninis, such a great hot pressed sandwich.','2013-10-14 11:23:22',2),
('9', '#food My parents told me "Croque Monsieur", traditional hot ham and cheese sandwiches, are really good.@me','2013-10-14 11:23:22',3),
('10', 'In #Nantes, its banks decorated with long well-kept lawns and pretty flower beds.@me ','2013-10-21 11:23:22',4),
('11', 'The snow is artificial but it does make it feel like #Christmas.@lucy','2013-10-21 11:23:22',2),
('12', 'Mmmm, I smell spice bread, a traditional French #Christmas treat. Thanks for #DMKM','2013-10-22 11:23:22',3),
('13', 're:re:Everybody, there is a huge discount in Auchan!','2013-11-01 11:23:22',4),
('14', 're:What a great day it is been but now it is time to go home and put our feet up','2013-11-03 11:23:22',5),
('15', 'After dinner we wander back out into a fairyland of sparkling lights.','2013-11-01 12:23:22',3),
('16', 'What a great day it is been but now it is time to go home and put our feet up.','2013-11-02 11:23:22',2),
('17', 'Fighting!#DMKM','20131103 11:23:22',4),
('18', 'Everybody, there is a huge discount in Auchan!','20130925 11:23:22',1);

INSERT INTO taginchirp (tag, chirp)
VALUES
( 1, 1),
( 1, 17),
( 2, 5),
( 2, 7),
( 2, 11),
( 2, 12),
( 3, 8),
( 3, 9),
( 4, 2),
( 4, 10),
(1,12);

INSERT INTO mention (chirp, fkuid)
VALUES
( 1, 2),
( 2, 1),
( 4, 1),
( 9, 1),
( 10, 1),
( 11, 5);

INSERT INTO rechirp (chirp, rechirp)
VALUES
(18, 3),
(18, 13),
(16, 14);


INSERT INTO follower (fkuid,friend)
VALUES
( 1, 2),
( 1, 3),
( 1, 4),
( 2, 5),
( 3, 4),
( 4, 5),
( 2, 1),
( 3, 1),
( 4, 1),
( 5, 2),
( 4, 3);

INSERT INTO favorite (chirp,fkuid)
VALUES
( 1, 2),
( 1, 3),
( 1, 4),
( 1, 5),
( 2, 6),
( 1, 13),
( 3,13);
-- END data in the previous database (first assignment)


-- BEGIN new added data
INSERT INTO chirp (cid,text, timestamp,author)
VALUES
('19', ' #DMKM','2013-09-01 10:23:22',3);

INSERT INTO taginchirp (tag, chirp)
VALUES
( 1, 19);
------------------------
INSERT INTO chirp (cid,text, timestamp,author)
VALUES
('20', ' #DMKM','2013-09-01 09:23:22',2),
('21', ' #Nantes','2013-09-01 01:23:22',4),
('22', ' #food','2013-09-01 02:23:22',2),
('23', ' #food','2013-09-01 03:23:22',3);

INSERT INTO taginchirp (tag, chirp)
VALUES
( 1, 20),
( 4, 21),
( 3, 22),
( 3, 23);
-----------------
INSERT INTO chirp (cid,text, timestamp,author)
VALUES
('24', ' #DMKM','2013-10-01 09:23:22',2),
('25', ' #Nantes','2013-10-01 01:23:22',4),
('26', ' #Nantes','2013-10-01 02:23:22',2),
('27', ' #food','2013-10-01 03:23:22',3);

INSERT INTO taginchirp (tag, chirp)
VALUES
( 1, 24),
( 4, 25),
( 4, 26),
( 3, 27);


-- END new added data


	