CREATE DATABASE c3;
\connect c3;
CREATE SCHEMA api;
SET search_path TO api;

CREATE EXTENSION "uuid-ossp";
CREATE DOMAIN uint2 AS smallint
   CHECK(VALUE >= 0 AND VALUE <= 32767);

CREATE TYPE owner_type as ENUM ('user','org');
CREATE TABLE owner_parents (
  id serial PRIMARY KEY,
  obj_type owner_type NOT NULL
);

CREATE TABLE alerts (
  id serial PRIMARY KEY,
  method varchar NOT NULL,
  args varchar DEFAULT NULL,
  enabled boolean NOT NULL DEFAULT FALSE,
  timestamp timestamp NOT NULL DEFAULT now(),
  owner_id integer REFERENCES owner_parents
);

CREATE TYPE eventable as ENUM ('beacon', 'zone', 'listener');
CREATE TABLE event_parents (
  id serial PRIMARY KEY,
  obj_type eventable NOT NULL
);

CREATE TABLE zones (
  id integer REFERENCES event_parents PRIMARY KEY,
  name varchar NOT NULL,
  grid_string text  NOT NULL,
  color varchar  NOT NULL DEFAULT '#ffffff',
  owner_id integer REFERENCES owner_parents
);

CREATE TABLE beacon_groups (
  id serial PRIMARY KEY,
  name varchar NOT NULL,
  description text DEFAULT NULL,
  major uint2 DEFAULT NULL,
  owner_id integer REFERENCES owner_parents,
  UNIQUE (major, owner_id),
  UNIQUE (owner_id, name)
);
CREATE INDEX beacon_groups__owner ON beacon_groups (owner_id);

CREATE DOMAIN percent AS smallint
   CHECK(VALUE >= 0 AND VALUE <= 100);

CREATE TABLE beacons (
  id integer REFERENCES event_parents PRIMARY KEY,
  state varchar DEFAULT '',
  name varchar NOT NULL,
  map_x double precision DEFAULT NULL,
  map_y double precision DEFAULT NULL,
  group_id integer REFERENCES beacon_groups DEFAULT NULL,
  major uint2 NOT NULL,
  minor uint2 NOT NULL,
  description text DEFAULT NULL,
  battery percent DEFAULT NULL,
  zone_id integer REFERENCES zones,
  uuid uuid NOT NULL,
  power smallint NOT NULL,
  last_seen timestamp DEFAULT now(),
  owner_id integer REFERENCES owner_parents,
  UNIQUE (minor, major, uuid)
);

CREATE TABLE beacon_logs (
  id serial PRIMARY KEY,
  beacon_id integer REFERENCES beacons,
  map_x double precision DEFAULT NULL,
  map_y double precision DEFAULT NULL,
  zone_id integer REFERENCES zones,
  timestamp timestamp NOT NULL DEFAULT now(),
  state varchar DEFAULT ''
);
CREATE INDEX beacon_logs_beacon_id ON beacon_logs(beacon_id);
CREATE INDEX beacon_logs_zone_id ON beacon_logs(zone_id);
CREATE INDEX beacon_logs_timestamp ON beacon_logs(timestamp);

CREATE OR REPLACE FUNCTION log_beacon_changes() RETURNS TRIGGER AS $$
BEGIN
  IF (OLD.zone_id IS DISTINCT FROM NEW.zone_id OR
      OLD.map_x IS DISTINCT FROM NEW.map_x OR
      OLD.map_y IS DISTINCT FROM NEW.map_y OR
      OLD.state IS DISTINCT FROM NEW.state)
    THEN
      INSERT INTO beacon_logs (beacon_id, zone_id, map_x, map_y, state)
        VALUES (NEW.id, NEW.zone_id, NEW.map_x, NEW.map_y, NEW.state);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insert_beacon_log_rows AFTER UPDATE ON beacons FOR EACH ROW 
  EXECUTE PROCEDURE log_beacon_changes();

CREATE TYPE prio_type as ENUM ('LOW','MEDIUM','HIGH');
CREATE TABLE events (
  id serial PRIMARY KEY,
  subj_id integer REFERENCES event_parents,
  obj_id integer REFERENCES event_parents,
  verb varchar NOT NULL,
  priority prio_type DEFAULT 'LOW',
  name varchar NOT NULL,
  owner_id integer REFERENCES owner_parents
);

CREATE TABLE event_logs (
  event_id integer REFERENCES events NOT NULL,
  archived boolean NOT NULL DEFAULT FALSE,
  timestamp timestamp NOT NULL DEFAULT now()
);

CREATE TABLE listeners (
  id integer REFERENCES event_parents PRIMARY KEY,
  state varchar DEFAULT '',
  name varchar NOT NULL,
  uuid uuid UNIQUE NOT NULL,
  description text DEFAULT NULL,
  map_x double precision DEFAULT NULL,
  map_y double precision DEFAULT NULL,
  zone_id integer REFERENCES zones,
  owner_id integer REFERENCES owner_parents
);

CREATE TABLE events_alerts (
  id serial PRIMARY KEY,
  alert_id integer REFERENCES alerts,
  event_id integer REFERENCES events
);

CREATE TABLE users (
  id integer REFERENCES owner_parents ON DELETE CASCADE PRIMARY KEY,
  username varchar UNIQUE NOT NULL,
  password varchar NOT NULL,
  first_name varchar NOT NULL DEFAULT '',
  last_name varchar NOT NULL DEFAULT '',
  last_login timestamp DEFAULT NULL,
  is_admin boolean NOT NULL DEFAULT FALSE,
  is_active boolean NOT NULL DEFAULT TRUE,
  date_joined date DEFAULT NULL,
  email varchar NOT NULL
);
CREATE INDEX users_username ON users (username);

CREATE TABLE orgs (
  id integer REFERENCES owner_parents ON DELETE CASCADE PRIMARY KEY,
  name varchar NOT NULL,
  uuid uuid NOT NULL DEFAULT uuid_generate_v4()
);

CREATE TYPE perm_type AS ENUM ('READ','WRITE','MANAGE');
CREATE TABLE users_orgs (
  id serial PRIMARY KEY,
  user_id integer REFERENCES users,
  org_id integer REFERENCES orgs,
  permissions perm_type NOT NULL
);
CREATE UNIQUE INDEX users_orgs__user_id_org_id ON users_orgs (user_id, org_id);
CREATE INDEX users_orgs__user_id ON users_orgs (user_id);

CREATE TABLE events_alerts (
  event_id integer REFERENCES events NOT NULL,
  alert_id integer REFERENCES alerts NOT NULL
);

CREATE TABLE api_keys (
  id serial PRIMARY KEY,
  org_id integer REFERENCES orgs,
  permissions perm_type NOT NULL,
  key varchar NOT NULL,
  secret varchar NOT NULL
);

CREATE USER c3api WITH PASSWORD 'apidemo';
ALTER ROLE c3api SET search_path = api;
GRANT USAGE ON SCHEMA api TO c3api;
GRANT SELECT, INSERT, DELETE, UPDATE ON ALL TABLES IN SCHEMA api to c3api;
GRANT ALL ON ALL SEQUENCES IN SCHEMA api to c3api;
GRANT CONNECT ON DATABASE c3 to c3api;

CREATE SCHEMA django;
CREATE USER c3webfront WITH PASSWORD 'webdemo';
ALTER ROLE c3webfront SET search_path = django,api;
GRANT USAGE ON SCHEMA api to c3webfront;
GRANT ALL ON SCHEMA django to c3webfront;
GRANT SELECT, INSERT, DELETE, UPDATE, REFERENCES ON ALL TABLES IN SCHEMA api to c3webfront;
GRANT ALL ON ALL SEQUENCES IN SCHEMA api to c3webfront;
GRANT CONNECT ON DATABASE c3 to c3webfront;
