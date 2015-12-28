CREATE DATABASE c3;
\connect c3;
CREATE SCHEMA api;
CREATE SCHEMA gis;
CREATE EXTENSION postgis;
SET search_path TO api, gis, public;

CREATE EXTENSION "uuid-ossp";
CREATE DOMAIN uint2 AS integer
   CHECK(VALUE >= 0 AND VALUE <= 65535);

-- CREATE TYPE owner_type as ENUM ('user','org');
-- CREATE TABLE owner_parents (
--   id serial PRIMARY KEY,
--   obj_type owner_type NOT NULL
-- );

-- CREATE TABLE alerts (
--   id serial PRIMARY KEY,
--   method varchar NOT NULL,
--   args varchar DEFAULT NULL,
--   enabled boolean NOT NULL DEFAULT FALSE,
--   timestamp timestamp NOT NULL DEFAULT now(),
--   owner_id integer REFERENCES owner_parents ON DELETE CASCADE
-- );

CREATE TYPE eventable as ENUM ('beacon', 'zone', 'listener');
CREATE TABLE event_parents (
  id serial PRIMARY KEY,
  obj_type eventable NOT NULL
);

CREATE TABLE zones (
  id integer REFERENCES event_parents PRIMARY KEY,
  name varchar NOT NULL,
  geom geometry(POLYGON,3857) DEFAULT NULL,
  owner_id integer
);

-- CREATE TABLE beacon_groups (
--   id serial PRIMARY KEY,
--   name varchar NOT NULL,
--   description text DEFAULT NULL,
--   major uint2 DEFAULT NULL,
--   owner_id integer REFERENCES owner_parents ON DELETE CASCADE,
--   UNIQUE (major, owner_id),
--   UNIQUE (owner_id, name)
-- );
-- CREATE INDEX beacon_groups__owner ON beacon_groups (owner_id);

CREATE DOMAIN percent AS smallint
   CHECK(VALUE >= 0 AND VALUE <= 100);

CREATE TABLE beacons (
  id integer REFERENCES event_parents PRIMARY KEY,
  state varchar DEFAULT '',
  name varchar DEFAULT NULL,
  geom geometry(POINT,3857) DEFAULT NULL,
  major uint2 NOT NULL,
  minor uint2 NOT NULL,
  description text DEFAULT NULL,
  battery percent DEFAULT NULL,
  zone_id integer REFERENCES zones,
  uuid uuid NOT NULL,
  last_seen timestamp DEFAULT NULL,
  location_quality integer DEFAULT 0,
  owner_id integer DEFAULT NULL,
  UNIQUE (minor, major, uuid)
);

CREATE TABLE beacon_logs (
  id serial PRIMARY KEY,
  beacon_id integer REFERENCES beacons ON DELETE CASCADE,
  geom geometry(POINT,3857),
  zone_id integer REFERENCES zones,
  timestamp timestamp NOT NULL DEFAULT now(),
  state varchar DEFAULT '',
  owner_id integer DEFAULT NULL
);
CREATE INDEX beacon_logs_beacon_id ON beacon_logs(beacon_id);
CREATE INDEX beacon_logs_zone_id ON beacon_logs(zone_id);
CREATE INDEX beacon_logs_timestamp ON beacon_logs(timestamp);

CREATE OR REPLACE FUNCTION log_beacon_changes() RETURNS TRIGGER AS $$
BEGIN
  IF (OLD.zone_id IS DISTINCT FROM NEW.zone_id OR
      ST_AsBinary(OLD.geom) IS DISTINCT FROM ST_AsBinary(NEW.geom) OR
      OLD.state IS DISTINCT FROM NEW.state)
    THEN
      INSERT INTO beacon_logs (beacon_id, zone_id, geom, state, owner_id)
        VALUES (NEW.id, NEW.zone_id, NEW.geom, NEW.state, NEW.owner_id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insert_beacon_log_rows AFTER UPDATE ON beacons FOR EACH ROW 
  EXECUTE PROCEDURE log_beacon_changes();

-- CREATE TYPE prio_type as ENUM ('LOW','MEDIUM','HIGH');
-- CREATE TABLE events (
--   id serial PRIMARY KEY,
--   subj_id integer REFERENCES event_parents,
--   obj_id integer REFERENCES event_parents,
--   verb varchar NOT NULL,
--   priority prio_type DEFAULT 'LOW',
--   name varchar NOT NULL,
--   owner_id integer REFERENCES owner_parents ON DELETE CASCADE
-- );

-- CREATE TABLE event_logs (
--   event_id integer REFERENCES events NOT NULL,
--   archived boolean NOT NULL DEFAULT FALSE,
--   timestamp timestamp NOT NULL DEFAULT now()
-- );

CREATE TABLE listeners (
  id integer REFERENCES event_parents PRIMARY KEY,
  state varchar DEFAULT '',
  name varchar DEFAULT NULL,
  mac varchar UNIQUE NOT NULL,
  description text DEFAULT NULL,
  geom geometry(POINT,3857) DEFAULT NULL,
  zone_id integer REFERENCES zones ON DELETE SET NULL,
  owner_id integer,
  last_seen timestamp DEFAULT NULL
);

-- CREATE TABLE events_alerts (
--   id serial PRIMARY KEY,
--   alert_id integer REFERENCES alerts,
--   event_id integer REFERENCES events
-- );

-- CREATE TABLE users (
--   id integer REFERENCES owner_parents ON DELETE CASCADE PRIMARY KEY,
--   username varchar UNIQUE NOT NULL,
--   password varchar NOT NULL,
--   first_name varchar NOT NULL DEFAULT '',
--   last_name varchar NOT NULL DEFAULT '',
--   last_login timestamp DEFAULT NULL,
--   is_admin boolean NOT NULL DEFAULT FALSE,
--   is_active boolean NOT NULL DEFAULT TRUE,
--   date_joined date DEFAULT NULL,
--   email varchar NOT NULL
-- );
-- CREATE INDEX users_username ON users (username);

-- CREATE TABLE orgs (
--   id integer REFERENCES owner_parents ON DELETE CASCADE PRIMARY KEY,
--   name varchar NOT NULL,
--   uuid uuid NOT NULL DEFAULT uuid_generate_v4()
-- );

CREATE TABLE roi (
  id serial PRIMARY KEY,
  name varchar NOT NULL,
  geom geometry(POLYGON,3857), --Defines inital zoom on map
  rast raster, -- Floorplan overlay
  owner_id integer
);

-- CREATE TYPE perm_type AS ENUM ('READ','WRITE','MANAGE');
-- CREATE TABLE users_orgs (
--   id serial PRIMARY KEY,
--   user_id integer REFERENCES users,
--   org_id integer REFERENCES orgs,
--   permissions perm_type NOT NULL
-- );
-- CREATE UNIQUE INDEX users_orgs__user_id_org_id ON users_orgs (user_id, org_id);
-- CREATE INDEX users_orgs__user_id ON users_orgs (user_id);

-- CREATE TABLE api_keys (
--   id serial PRIMARY KEY,
--   org_id integer REFERENCES orgs,
--   permissions perm_type NOT NULL,
--   key varchar NOT NULL,
--   secret varchar NOT NULL
-- );

CREATE OR REPLACE FUNCTION eventable_trigger() RETURNS TRIGGER AS $$
DECLARE
  newid integer;
  newtype eventable;
BEGIN
  newtype := TG_ARGV[0];
  INSERT INTO event_parents VALUES (DEFAULT, newtype) RETURNING id INTO newid;
  NEW.id = newid;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insert_beacon_parent BEFORE INSERT ON beacons FOR EACH ROW EXECUTE PROCEDURE eventable_trigger('beacon');
CREATE TRIGGER insert_zone_parent BEFORE INSERT ON zones FOR EACH ROW EXECUTE PROCEDURE eventable_trigger('zone');
CREATE TRIGGER insert_listener_parent BEFORE INSERT ON listeners FOR EACH ROW EXECUTE PROCEDURE eventable_trigger('listener');

-- CREATE OR REPLACE FUNCTION ownable_trigger() RETURNS TRIGGER AS $$
-- DECLARE
--   newid integer;
--   newtype owner_type;
-- BEGIN
--   newtype := TG_ARGV[0];
--   INSERT INTO owner_parents VALUES (DEFAULT, newtype) RETURNING id INTO newid;
--   NEW.id = newid;
--   RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER insert_user_parent BEFORE INSERT ON users FOR EACH ROW EXECUTE PROCEDURE ownable_trigger('user');
-- CREATE TRIGGER insert_org_parent BEFORE INSERT ON orgs FOR EACH ROW EXECUTE PROCEDURE ownable_trigger('org');

CREATE USER gis WITH PASSWORD 'gisdemo';
ALTER ROLE gis SET search_path = gis,api,public;
GRANT USAGE ON SCHEMA api TO gis;
GRANT ALL ON SCHEMA gis TO gis;
GRANT SELECT, INSERT, DELETE, UPDATE ON ALL TABLES IN SCHEMA api to gis;
GRANT ALL ON ALL TABLES IN SCHEMA gis to gis;
GRANT ALL ON ALL SEQUENCES IN SCHEMA api to gis;
GRANT ALL ON ALL SEQUENCES IN SCHEMA gis to gis;
GRANT CONNECT ON DATABASE c3 to gis;

CREATE USER c3api WITH PASSWORD 'apidemo';
ALTER ROLE c3api SET search_path = api,gis,public;
GRANT USAGE ON SCHEMA api TO c3api;
GRANT USAGE ON SCHEMA gis to c3api;
GRANT SELECT, INSERT, DELETE, UPDATE ON ALL TABLES IN SCHEMA api to c3api;
GRANT SELECT, INSERT, DELETE, UPDATE ON ALL TABLES IN SCHEMA gis to c3api;
GRANT ALL ON ALL SEQUENCES IN SCHEMA api to c3api;
GRANT ALL ON ALL SEQUENCES IN SCHEMA gis to c3api;
GRANT CONNECT ON DATABASE c3 to c3api;

CREATE SCHEMA django;
CREATE USER c3webfront WITH PASSWORD 'webdemo';
ALTER ROLE c3webfront SET search_path = django,api,gis,public;
GRANT USAGE ON SCHEMA api to c3webfront;
GRANT ALL ON SCHEMA django to c3webfront;
GRANT SELECT, INSERT, DELETE, UPDATE, REFERENCES ON ALL TABLES IN SCHEMA api to c3webfront;
GRANT ALL ON ALL SEQUENCES IN SCHEMA api to c3webfront;
GRANT CONNECT ON DATABASE c3 to c3webfront;

ALTER ROLE c3app_live SET search_path = api,gis,django,public;


