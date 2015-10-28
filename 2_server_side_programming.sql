
-- 3 SERVER-SIDE PROGRAMMING
-- 3.1 Database triggers
----------------------------------------------------------------------------------------------

--BEGIN 3.1.a insertion of a Mention tuple on @<username> pattern in chirps
CREATE OR REPLACE FUNCTION user_id(user_name varchar(50)) RETURNS integer AS $$
DECLARE
	numUser integer;
BEGIN
	SELECT uid INTO numUser FROM users WHERE username=user_name;	
	RETURN numUser;
END;	
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_in_mention() RETURNS trigger AS $$
DECLARE		
	word text; word_without_at text;
	arr varchar[];
	id_user integer;
BEGIN	        
	SELECT regexp_split_to_array(NEW.text, E'\\s+') INTO arr; --split the chirp into array
	   FOREACH word IN ARRAY arr 
	   LOOP
			IF (word ~ '^[@]') THEN
				word_without_at = substr(word, 2, char_length(word));
				--clean the word, removing ',' or '.' or ')' or '}' at the end
				IF (word_without_at ~ '[.]$' OR word_without_at ~ '[,]$' OR word_without_at ~ '[)]$' OR word_without_at ~ '[}]$') THEN
					word_without_at = substr(word, 2, char_length(word)-2);					
				END IF;
				id_user = user_id(word_without_at);				
				IF id_user IS NOT NULL THEN								
					INSERT INTO mention VALUES (NEW.cid,id_user);															
				ELSE
					-- The mentioned user must be exist in the table before
				END IF;
			END IF;	        			
        END LOOP;		
	RETURN NEW;
END;
$$ LANGUAGE plpgsql; 

CREATE TRIGGER trigger_insert_metion
    AFTER INSERT ON chirp
    FOR EACH ROW
    EXECUTE PROCEDURE insert_in_mention();
-- END 3.1.a

----------------------------------------------------------------------------------------------

--BEGIN 3.1.b insert a TaginChirp tuple each time a chirp has a #tag. If tag is new, then insert in the Hashtag table as well
CREATE OR REPLACE FUNCTION tag_id(tag varchar(50)) RETURNS integer AS $$
DECLARE
	id_tag integer;
BEGIN
	SELECT hid INTO id_tag FROM HashTag WHERE label=tag;	
	RETURN id_tag;
END;	
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION new_hid() RETURNS integer AS $$
DECLARE
	new_hid integer;
BEGIN
	SELECT max(hid) INTO new_hid FROM HashTag;	
	RETURN new_hid+1;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_in_taginchirp() RETURNS trigger AS $$
DECLARE		
	word_without_dash text; word text;
	chirpArray varchar[];
	id_tag integer;
BEGIN	        
	SELECT regexp_split_to_array(NEW.text, E'\\s+') INTO chirpArray;
    FOREACH word IN ARRAY chirpArray 
    LOOP	        
		IF (word ~ '^[#]') THEN
			word_without_dash = substr(word, 2, char_length(word));
			--clean the word, removing ',' or '.' or ')' or '}'
			IF (word_without_dash ~ '[.]$' OR word_without_dash ~ '[,]$' OR word_without_dash ~ '[)]$' OR word_without_dash ~ '[}]$') THEN
				word_without_dash = substr(word, 2, char_length(word)-2);					
			END IF;
			id_tag = tag_id(word_without_dash);				
			IF id_tag IS NOT NULL THEN								
				INSERT INTO taginchirp VALUES (id_tag,NEW.cid);															
			ELSE
				-- Insertion of the new tag
				id_tag = new_hid();
				INSERT INTO hashtag (label) VALUES (word_without_dash);
				--id_tag = tag_id(word_without_dash);												
				INSERT INTO taginchirp VALUES (id_tag,NEW.cid);	
			END IF;
		END IF;	        			
    END LOOP;		
	RETURN NEW;
END;
$$ LANGUAGE plpgsql; 

CREATE TRIGGER trigger_insert_taginchirp
    AFTER INSERT ON chirp
    FOR EACH ROW
    EXECUTE PROCEDURE insert_in_taginchirp();
--END 3.1.b

----------------------------------------------------------------------------------------------

--3.2 More on design issues

----------------------------------------------------------------------------------------------

--BEGIN 3.2.1 Split content of the Chirp table into several chirp-by month tables such like chirp-2013-10, chirp-2013-11, chirp-2013-12, etc
CREATE OR REPLACE FUNCTION partitionning() RETURNS VOID AS $$
DECLARE
	tableName varchar(15); yearStr varchar(15); monthStr varchar(15); yearstring varchar(15); monthstring varchar(15);
	myview RECORD;
BEGIN	
	-- creating the tables
	FOR myview IN SELECT distinct date_part('YEAR', timestamp) AS col1,date_part('month', timestamp) AS col2 FROM chirp
	LOOP		
		yearStr = myview.col1;
		monthStr = myview.col2;	
		yearstring = 'YEAR';
		monthstring = 'month';
		tableName = 'chirp-' || yearStr || '-' || monthStr;
		-- very important quote_ident() or quote_literal()
		EXECUTE 'CREATE TABLE IF NOT EXISTS '
			|| quote_ident(tableName)
			||'(CHECK('
			||'date_part('||quote_literal(yearstring)
			||', timestamp)='
			||quote_literal(yearStr)
			||' AND date_part('||quote_literal(monthstring)
			||', timestamp)='
			||quote_literal(monthStr)
			||'))INHERITS (chirp)';		
	END LOOP;
	-- splitting the content of chirp into each corresponding tables
	FOR myview IN SELECT * FROM chirp
	LOOP
    	yearStr = date_part('year',myview.timestamp);
		monthStr = date_part('month',myview.timestamp);
    	tableName = 'chirp-' || yearStr || '-' || monthStr; 	
	    EXECUTE 'INSERT INTO '
		||quote_ident(tableName)
		||' VALUES ('
		||quote_literal(myview.cid)||','
		||quote_literal(myview.text)||','
		||quote_literal(myview.timestamp)||','
		||quote_literal(myview.author)
		||')';		
	END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM partitionning();
--END 3.2.1 

----------------------------------------------------------------------------------------------

--BEGIN 3.2.2 Allow for right insertion (depending on the timestamp) when adding a new tuple into the Chirp table
CREATE OR REPLACE FUNCTION chirp_insert() RETURNS TRIGGER AS $$
DECLARE
	tableName varchar(15); yearStr varchar(15); monthStr varchar(15); yearstring varchar(15); monthstring varchar(15); text varchar; timest varchar;	
	cid int; author int;
	
BEGIN
    yearstring = 'YEAR';
    monthstring = 'month';
    yearStr = date_part('year',NEW.timestamp);
    monthStr = date_part('month',NEW.timestamp);
    tableName = 'chirp-' || yearStr || '-' || monthStr;    
    cid = NEW.cid;   text=NEW.text; timest=NEW.timestamp;  author=NEW.author;
    EXECUTE 'CREATE TABLE IF NOT EXISTS '
	|| quote_ident(tableName)
	||'(CHECK('
	||'date_part('||quote_literal(yearstring)
	||', timestamp)='
	||quote_literal(yearStr)
	||' AND date_part('||quote_literal(monthstring)
	||', timestamp)='
	||quote_literal(monthStr)
	||'))INHERITS (chirp)';    
    EXECUTE 'INSERT INTO '
	||quote_ident(tableName)
	||' VALUES ('
	||quote_literal(cid)||','
	||quote_literal(text)||','
	||quote_literal(timest)||','
	||quote_literal(author)
	||')';
   RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER chirp_insert_trigger
-- in this case if we use before, at first, we insert the chirp in the child table before inserting into the parent table
	BEFORE INSERT ON chirp 
	FOR EACH ROW EXECUTE PROCEDURE chirp_insert();

DROP TRIGGER chirp_insert_trigger ON chirp;
--END 3.2.2

----------------------------------------------------------------------------------------------

--BEGIN 3.2.3 Write a 'conceptual' view for chirp in Birdie
CREATE OR REPLACE VIEW birdie(username,chirp,timestamp,tagset,mentionset,rechirp_from)
    AS SELECT 
	username,	
	text,
	timestamp,
	array(SELECT tag FROM taginchirp WHERE taginchirp.chirp=chirp.cid),
	array(SELECT FKuid FROM mention WHERE mention.chirp=chirp.cid),
	rechirp.chirp	
    FROM users 
    INNER JOIN chirp ON (users.uid=chirp.author)     
    FULL OUTER JOIN rechirp ON (chirp.cid=rechirp.rechirp);

SELECT * FROM birdie;
--END 3.2.3

----------------------------------------------------------------------------------------------

--BEGIN 3.2.4 Make the view updatable!
CREATE OR REPLACE FUNCTION new_cid() RETURNS integer AS $$
DECLARE
	new_cid integer;
BEGIN
	SELECT max(cid) INTO new_cid FROM chirp;	
	RETURN new_cid+1;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION updateBirdie() RETURNS TRIGGER AS $$
DECLARE
	varcid int; varuid int;
	new_cid int;
BEGIN    
    IF TG_OP = 'INSERT' then
        --raise notice 'INSERT trigger, NEW = [%]', NEW;
        -- trigger_insert_taginchirp & trigger_insert_metion & trigger_insert_rechirp should be activated 
        -- => insertion in taginchirp 
        -- => & insertion in mention 
        -- => & insertion in rechirp even if they are not given
        new_cid=new_cid();
        SELECT uid INTO varuid FROM users WHERE username = NEW.username;
        EXECUTE 'INSERT INTO chirp(cid,text,timestamp,author) VALUES (' -- insert into chirp and the triggers handle the lasts
		|| quote_literal(new_cid)||','
		|| quote_literal(NEW.chirp)||','
		||quote_literal(NEW.timestamp )||','
		||quote_literal(varuid)||')';
		        
    ELSIF TG_OP = 'UPDATE' then
        --raise notice 'UPDATE trigger, OLD = [%], NEW = [%]', OLD, NEW;
        -- we suppose that only the fields username,chirp,timestamp can be updated and the updates of the other fields will be done with the other triggers
        SELECT cid INTO varcid
		FROM users 
		INNER JOIN chirp ON (users.uid=chirp.author)     
		FULL OUTER JOIN rechirp ON (chirp.cid=rechirp.rechirp)
		WHERE username=OLD.username AND text=OLD.chirp AND "timestamp"=OLD.timestamp 
		AND array(SELECT tag FROM taginchirp WHERE taginchirp.chirp=chirp.cid)=OLD.tagset
		AND array(SELECT FKuid FROM mention WHERE mention.chirp=chirp.cid)=OLD.mentionset
		AND rechirp.chirp = OLD.rechirp_from;

		EXECUTE 'DELETE FROM taginchirp WHERE chirp='||quote_literal(varcid);
		EXECUTE 'DELETE FROM mention WHERE chirp='||quote_literal(varcid);
		EXECUTE 'DELETE FROM rechirp WHERE rechirp='||quote_literal(varcid);
		EXECUTE 'DELETE FROM favorite WHERE chirp='||quote_literal(varcid);
		EXECUTE 'DELETE FROM chirp WHERE cid='||quote_literal(varcid);					
		
        SELECT uid INTO varuid FROM users WHERE username = NEW.username;
        EXECUTE 'INSERT INTO chirp(text,timestamp,author) VALUES (' -- insert into chirp and the triggers handle the lasts
		|| quote_literal(NEW.chirp)||','
		||quote_literal(NEW.timestamp )||','
		||quote_literal(varuid)||')';		
	 
        
    ELSIF TG_OP = 'DELETE' THEN	
        --raise notice 'DELETE trigger, OLD = [%]', OLD;
        SELECT cid INTO varcid
		FROM users 
		INNER JOIN chirp ON (users.uid=chirp.author)     
		FULL OUTER JOIN rechirp ON (chirp.cid=rechirp.rechirp)
		WHERE username=OLD.username AND text=OLD.chirp AND "timestamp"=OLD.timestamp 
		AND array(SELECT tag FROM taginchirp WHERE taginchirp.chirp=chirp.cid)=OLD.tagset
		AND array(SELECT FKuid FROM mention WHERE mention.chirp=chirp.cid)=OLD.mentionset
		AND rechirp.chirp = OLD.rechirp_from;	
	--raise notice '[%]',varcid;
	EXECUTE 'DELETE FROM taginchirp WHERE chirp='||quote_literal(varcid);
	EXECUTE 'DELETE FROM mention WHERE chirp='||quote_literal(varcid);
	EXECUTE 'DELETE FROM rechirp WHERE rechirp='||quote_literal(varcid);	
	EXECUTE 'DELETE FROM favorite WHERE chirp='||quote_literal(varcid);
	EXECUTE 'DELETE FROM chirp WHERE cid='||quote_literal(varcid);	
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_birdie
    INSTEAD OF INSERT OR UPDATE OR DELETE ON
      birdie FOR EACH ROW EXECUTE PROCEDURE updateBirdie();

-- SELECT * FROM birdie;
-- INSERT INTO birdie(username,chirp,timestamp) VALUES('me','This is the first day in #DMKM_Faly',now());
-- UPDATE birdie SET chirp='well it works' WHERE timestamp='2013-09-25 11:23:22';
--DELETE FROM birdie WHERE rechirp_from='21';
--END 3.2.4

----------------------------------------------------------------------------------------------

-- needed function for updating, inserting in the view birdie, for filling rechirp
CREATE OR REPLACE FUNCTION insert_in_rechirp() RETURNS trigger AS $$
DECLARE			
	origin int :=0;	
	newvarcid int;
BEGIN	   	
	SELECT cid INTO origin FROM chirp WHERE text=NEW.text ORDER BY timestamp ASC LIMIT 1;
	-- The origin chirp must have a small timestamp if we relate it to the othes
	raise notice 'varcid [%]',origin;
	IF origin=0 THEN
		raise notice 'new chirp [%]',origin; 
		--=> nothing to do, just insert data into chirp
		NULL;
	ELSE
		raise notice 'rechirp!!![%]',origin;
		INSERT INTO rechirp VALUES (origin,NEW.cid);
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql; 

CREATE TRIGGER trigger_insert_rechirp
    AFTER INSERT ON chirp
    FOR EACH ROW
    EXECUTE PROCEDURE insert_in_rechirp();
    
----------------------------------------------------------------------------------------------    