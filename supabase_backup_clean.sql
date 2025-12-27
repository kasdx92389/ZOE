--
-- PostgreSQL database dump
--

\restrict U1xJsbQL5fovvizFg8EefKxXXyqj62ygV71CYdIf5qT98fpvo3fnddCocBOHQng

-- Dumped from database version 17.4
-- Dumped by pg_dump version 18.0

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: auth; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA auth;


--
-- Name: extensions; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA extensions;


--
-- Name: graphql; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA graphql;


--
-- Name: graphql_public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA graphql_public;


--
-- Name: pgbouncer; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA pgbouncer;


--
-- Name: realtime; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA realtime;


--
-- Name: storage; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA storage;


--
-- Name: vault; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA vault;


--
-- Name: pg_graphql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_graphql WITH SCHEMA graphql;


--
-- Name: EXTENSION pg_graphql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_graphql IS 'pg_graphql: GraphQL support';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA extensions;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: supabase_vault; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS supabase_vault WITH SCHEMA vault;


--
-- Name: EXTENSION supabase_vault; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION supabase_vault IS 'Supabase Vault Extension';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: aal_level; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.aal_level AS ENUM (
    'aal1',
    'aal2',
    'aal3'
);


--
-- Name: code_challenge_method; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.code_challenge_method AS ENUM (
    's256',
    'plain'
);


--
-- Name: factor_status; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_status AS ENUM (
    'unverified',
    'verified'
);


--
-- Name: factor_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_type AS ENUM (
    'totp',
    'webauthn',
    'phone'
);


--
-- Name: oauth_registration_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_registration_type AS ENUM (
    'dynamic',
    'manual'
);


--
-- Name: one_time_token_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.one_time_token_type AS ENUM (
    'confirmation_token',
    'reauthentication_token',
    'recovery_token',
    'email_change_token_new',
    'email_change_token_current',
    'phone_change_token'
);


--
-- Name: action; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.action AS ENUM (
    'INSERT',
    'UPDATE',
    'DELETE',
    'TRUNCATE',
    'ERROR'
);


--
-- Name: equality_op; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.equality_op AS ENUM (
    'eq',
    'neq',
    'lt',
    'lte',
    'gt',
    'gte',
    'in'
);


--
-- Name: user_defined_filter; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.user_defined_filter AS (
	column_name text,
	op realtime.equality_op,
	value text
);


--
-- Name: wal_column; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.wal_column AS (
	name text,
	type_name text,
	type_oid oid,
	value jsonb,
	is_pkey boolean,
	is_selectable boolean
);


--
-- Name: wal_rls; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.wal_rls AS (
	wal jsonb,
	is_rls_enabled boolean,
	subscription_ids uuid[],
	errors text[]
);


--
-- Name: buckettype; Type: TYPE; Schema: storage; Owner: -
--

CREATE TYPE storage.buckettype AS ENUM (
    'STANDARD',
    'ANALYTICS'
);


--
-- Name: email(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.email() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.email', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'email')
  )::text
$$;


--
-- Name: FUNCTION email(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.email() IS 'Deprecated. Use auth.jwt() -> ''email'' instead.';


--
-- Name: jwt(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.jwt() RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
  select 
    coalesce(
        nullif(current_setting('request.jwt.claim', true), ''),
        nullif(current_setting('request.jwt.claims', true), '')
    )::jsonb
$$;


--
-- Name: role(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.role() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  )::text
$$;


--
-- Name: FUNCTION role(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.role() IS 'Deprecated. Use auth.jwt() -> ''role'' instead.';


--
-- Name: uid(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.uid() RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid
$$;


--
-- Name: FUNCTION uid(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.uid() IS 'Deprecated. Use auth.jwt() -> ''sub'' instead.';


--
-- Name: grant_pg_cron_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_cron_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_cron'
  )
  THEN
    grant usage on schema cron to postgres with grant option;

    alter default privileges in schema cron grant all on tables to postgres with grant option;
    alter default privileges in schema cron grant all on functions to postgres with grant option;
    alter default privileges in schema cron grant all on sequences to postgres with grant option;

    alter default privileges for user supabase_admin in schema cron grant all
        on sequences to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on tables to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on functions to postgres with grant option;

    grant all privileges on all tables in schema cron to postgres with grant option;
    revoke all on table cron.job from postgres;
    grant select on table cron.job to postgres with grant option;
  END IF;
END;
$$;


--
-- Name: FUNCTION grant_pg_cron_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_cron_access() IS 'Grants access to pg_cron';


--
-- Name: grant_pg_graphql_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_graphql_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
DECLARE
    func_is_graphql_resolve bool;
BEGIN
    func_is_graphql_resolve = (
        SELECT n.proname = 'resolve'
        FROM pg_event_trigger_ddl_commands() AS ev
        LEFT JOIN pg_catalog.pg_proc AS n
        ON ev.objid = n.oid
    );

    IF func_is_graphql_resolve
    THEN
        -- Update public wrapper to pass all arguments through to the pg_graphql resolve func
        DROP FUNCTION IF EXISTS graphql_public.graphql;
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language sql
        as $$
            select graphql.resolve(
                query := query,
                variables := coalesce(variables, '{}'),
                "operationName" := "operationName",
                extensions := extensions
            );
        $$;

        -- This hook executes when `graphql.resolve` is created. That is not necessarily the last
        -- function in the extension so we need to grant permissions on existing entities AND
        -- update default permissions to any others that are created after `graphql.resolve`
        grant usage on schema graphql to postgres, anon, authenticated, service_role;
        grant select on all tables in schema graphql to postgres, anon, authenticated, service_role;
        grant execute on all functions in schema graphql to postgres, anon, authenticated, service_role;
        grant all on all sequences in schema graphql to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on tables to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on functions to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on sequences to postgres, anon, authenticated, service_role;

        -- Allow postgres role to allow granting usage on graphql and graphql_public schemas to custom roles
        grant usage on schema graphql_public to postgres with grant option;
        grant usage on schema graphql to postgres with grant option;
    END IF;

END;
$_$;


--
-- Name: FUNCTION grant_pg_graphql_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_graphql_access() IS 'Grants access to pg_graphql';


--
-- Name: grant_pg_net_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_net_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_net'
  )
  THEN
    IF NOT EXISTS (
      SELECT 1
      FROM pg_roles
      WHERE rolname = 'supabase_functions_admin'
    )
    THEN
      CREATE USER supabase_functions_admin NOINHERIT CREATEROLE LOGIN NOREPLICATION;
    END IF;

    GRANT USAGE ON SCHEMA net TO supabase_functions_admin, postgres, anon, authenticated, service_role;

    IF EXISTS (
      SELECT FROM pg_extension
      WHERE extname = 'pg_net'
      -- all versions in use on existing projects as of 2025-02-20
      -- version 0.12.0 onwards don't need these applied
      AND extversion IN ('0.2', '0.6', '0.7', '0.7.1', '0.8', '0.10.0', '0.11.0')
    ) THEN
      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;

      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;

      REVOKE ALL ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;
      REVOKE ALL ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;

      GRANT EXECUTE ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
      GRANT EXECUTE ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
    END IF;
  END IF;
END;
$$;


--
-- Name: FUNCTION grant_pg_net_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_net_access() IS 'Grants access to pg_net';


--
-- Name: pgrst_ddl_watch(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.pgrst_ddl_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN SELECT * FROM pg_event_trigger_ddl_commands()
  LOOP
    IF cmd.command_tag IN (
      'CREATE SCHEMA', 'ALTER SCHEMA'
    , 'CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO', 'ALTER TABLE'
    , 'CREATE FOREIGN TABLE', 'ALTER FOREIGN TABLE'
    , 'CREATE VIEW', 'ALTER VIEW'
    , 'CREATE MATERIALIZED VIEW', 'ALTER MATERIALIZED VIEW'
    , 'CREATE FUNCTION', 'ALTER FUNCTION'
    , 'CREATE TRIGGER'
    , 'CREATE TYPE', 'ALTER TYPE'
    , 'CREATE RULE'
    , 'COMMENT'
    )
    -- don't notify in case of CREATE TEMP table or other objects created on pg_temp
    AND cmd.schema_name is distinct from 'pg_temp'
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


--
-- Name: pgrst_drop_watch(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.pgrst_drop_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  obj record;
BEGIN
  FOR obj IN SELECT * FROM pg_event_trigger_dropped_objects()
  LOOP
    IF obj.object_type IN (
      'schema'
    , 'table'
    , 'foreign table'
    , 'view'
    , 'materialized view'
    , 'function'
    , 'trigger'
    , 'type'
    , 'rule'
    )
    AND obj.is_temporary IS false -- no pg_temp objects
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


--
-- Name: set_graphql_placeholder(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.set_graphql_placeholder() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
    DECLARE
    graphql_is_dropped bool;
    BEGIN
    graphql_is_dropped = (
        SELECT ev.schema_name = 'graphql_public'
        FROM pg_event_trigger_dropped_objects() AS ev
        WHERE ev.schema_name = 'graphql_public'
    );

    IF graphql_is_dropped
    THEN
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language plpgsql
        as $$
            DECLARE
                server_version float;
            BEGIN
                server_version = (SELECT (SPLIT_PART((select version()), ' ', 2))::float);

                IF server_version >= 14 THEN
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql extension is not enabled.'
                            )
                        )
                    );
                ELSE
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql is only available on projects running Postgres 14 onwards.'
                            )
                        )
                    );
                END IF;
            END;
        $$;
    END IF;

    END;
$_$;


--
-- Name: FUNCTION set_graphql_placeholder(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.set_graphql_placeholder() IS 'Reintroduces placeholder function for graphql_public.graphql';


--
-- Name: get_auth(text); Type: FUNCTION; Schema: pgbouncer; Owner: -
--

CREATE FUNCTION pgbouncer.get_auth(p_usename text) RETURNS TABLE(username text, password text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
begin
    raise debug 'PgBouncer auth request: %', p_usename;

    return query
    select 
        rolname::text, 
        case when rolvaliduntil < now() 
            then null 
            else rolpassword::text 
        end 
    from pg_authid 
    where rolname=$1 and rolcanlogin;
end;
$_$;


--
-- Name: apply_rls(jsonb, integer); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer DEFAULT (1024 * 1024)) RETURNS SETOF realtime.wal_rls
    LANGUAGE plpgsql
    AS $$
declare
-- Regclass of the table e.g. public.notes
entity_ regclass = (quote_ident(wal ->> 'schema') || '.' || quote_ident(wal ->> 'table'))::regclass;

-- I, U, D, T: insert, update ...
action realtime.action = (
    case wal ->> 'action'
        when 'I' then 'INSERT'
        when 'U' then 'UPDATE'
        when 'D' then 'DELETE'
        else 'ERROR'
    end
);

-- Is row level security enabled for the table
is_rls_enabled bool = relrowsecurity from pg_class where oid = entity_;

subscriptions realtime.subscription[] = array_agg(subs)
    from
        realtime.subscription subs
    where
        subs.entity = entity_;

-- Subscription vars
roles regrole[] = array_agg(distinct us.claims_role::text)
    from
        unnest(subscriptions) us;

working_role regrole;
claimed_role regrole;
claims jsonb;

subscription_id uuid;
subscription_has_access bool;
visible_to_subscription_ids uuid[] = '{}';

-- structured info for wal's columns
columns realtime.wal_column[];
-- previous identity values for update/delete
old_columns realtime.wal_column[];

error_record_exceeds_max_size boolean = octet_length(wal::text) > max_record_bytes;

-- Primary jsonb output for record
output jsonb;

begin
perform set_config('role', null, true);

columns =
    array_agg(
        (
            x->>'name',
            x->>'type',
            x->>'typeoid',
            realtime.cast(
                (x->'value') #>> '{}',
                coalesce(
                    (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                    (x->>'type')::regtype
                )
            ),
            (pks ->> 'name') is not null,
            true
        )::realtime.wal_column
    )
    from
        jsonb_array_elements(wal -> 'columns') x
        left join jsonb_array_elements(wal -> 'pk') pks
            on (x ->> 'name') = (pks ->> 'name');

old_columns =
    array_agg(
        (
            x->>'name',
            x->>'type',
            x->>'typeoid',
            realtime.cast(
                (x->'value') #>> '{}',
                coalesce(
                    (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                    (x->>'type')::regtype
                )
            ),
            (pks ->> 'name') is not null,
            true
        )::realtime.wal_column
    )
    from
        jsonb_array_elements(wal -> 'identity') x
        left join jsonb_array_elements(wal -> 'pk') pks
            on (x ->> 'name') = (pks ->> 'name');

for working_role in select * from unnest(roles) loop

    -- Update `is_selectable` for columns and old_columns
    columns =
        array_agg(
            (
                c.name,
                c.type_name,
                c.type_oid,
                c.value,
                c.is_pkey,
                pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
            )::realtime.wal_column
        )
        from
            unnest(columns) c;

    old_columns =
            array_agg(
                (
                    c.name,
                    c.type_name,
                    c.type_oid,
                    c.value,
                    c.is_pkey,
                    pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
                )::realtime.wal_column
            )
            from
                unnest(old_columns) c;

    if action <> 'DELETE' and count(1) = 0 from unnest(columns) c where c.is_pkey then
        return next (
            jsonb_build_object(
                'schema', wal ->> 'schema',
                'table', wal ->> 'table',
                'type', action
            ),
            is_rls_enabled,
            -- subscriptions is already filtered by entity
            (select array_agg(s.subscription_id) from unnest(subscriptions) as s where claims_role = working_role),
            array['Error 400: Bad Request, no primary key']
        )::realtime.wal_rls;

    -- The claims role does not have SELECT permission to the primary key of entity
    elsif action <> 'DELETE' and sum(c.is_selectable::int) <> count(1) from unnest(columns) c where c.is_pkey then
        return next (
            jsonb_build_object(
                'schema', wal ->> 'schema',
                'table', wal ->> 'table',
                'type', action
            ),
            is_rls_enabled,
            (select array_agg(s.subscription_id) from unnest(subscriptions) as s where claims_role = working_role),
            array['Error 401: Unauthorized']
        )::realtime.wal_rls;

    else
        output = jsonb_build_object(
            'schema', wal ->> 'schema',
            'table', wal ->> 'table',
            'type', action,
            'commit_timestamp', to_char(
                ((wal ->> 'timestamp')::timestamptz at time zone 'utc'),
                'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'
            ),
            'columns', (
                select
                    jsonb_agg(
                        jsonb_build_object(
                            'name', pa.attname,
                            'type', pt.typname
                        )
                        order by pa.attnum asc
                    )
                from
                    pg_attribute pa
                    join pg_type pt
                        on pa.atttypid = pt.oid
                where
                    attrelid = entity_
                    and attnum > 0
                    and pg_catalog.has_column_privilege(working_role, entity_, pa.attname, 'SELECT')
            )
        )
        -- Add "record" key for insert and update
        || case
            when action in ('INSERT', 'UPDATE') then
                jsonb_build_object(
                    'record',
                    (
                        select
                            jsonb_object_agg(
                                -- if unchanged toast, get column name and value from old record
                                coalesce((c).name, (oc).name),
                                case
                                    when (c).name is null then (oc).value
                                    else (c).value
                                end
                            )
                        from
                            unnest(columns) c
                            full outer join unnest(old_columns) oc
                                on (c).name = (oc).name
                        where
                            coalesce((c).is_selectable, (oc).is_selectable)
                            and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                    )
                )
            else '{}'::jsonb
        end
        -- Add "old_record" key for update and delete
        || case
            when action = 'UPDATE' then
                jsonb_build_object(
                        'old_record',
                        (
                            select jsonb_object_agg((c).name, (c).value)
                            from unnest(old_columns) c
                            where
                                (c).is_selectable
                                and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                        )
                    )
            when action = 'DELETE' then
                jsonb_build_object(
                    'old_record',
                    (
                        select jsonb_object_agg((c).name, (c).value)
                        from unnest(old_columns) c
                        where
                            (c).is_selectable
                            and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                            and ( not is_rls_enabled or (c).is_pkey ) -- if RLS enabled, we can't secure deletes so filter to pkey
                    )
                )
            else '{}'::jsonb
        end;

        -- Create the prepared statement
        if is_rls_enabled and action <> 'DELETE' then
            if (select 1 from pg_prepared_statements where name = 'walrus_rls_stmt' limit 1) > 0 then
                deallocate walrus_rls_stmt;
            end if;
            execute realtime.build_prepared_statement_sql('walrus_rls_stmt', entity_, columns);
        end if;

        visible_to_subscription_ids = '{}';

        for subscription_id, claims in (
                select
                    subs.subscription_id,
                    subs.claims
                from
                    unnest(subscriptions) subs
                where
                    subs.entity = entity_
                    and subs.claims_role = working_role
                    and (
                        realtime.is_visible_through_filters(columns, subs.filters)
                        or (
                          action = 'DELETE'
                          and realtime.is_visible_through_filters(old_columns, subs.filters)
                        )
                    )
        ) loop

            if not is_rls_enabled or action = 'DELETE' then
                visible_to_subscription_ids = visible_to_subscription_ids || subscription_id;
            else
                -- Check if RLS allows the role to see the record
                perform
                    -- Trim leading and trailing quotes from working_role because set_config
                    -- doesn't recognize the role as valid if they are included
                    set_config('role', trim(both '"' from working_role::text), true),
                    set_config('request.jwt.claims', claims::text, true);

                execute 'execute walrus_rls_stmt' into subscription_has_access;

                if subscription_has_access then
                    visible_to_subscription_ids = visible_to_subscription_ids || subscription_id;
                end if;
            end if;
        end loop;

        perform set_config('role', null, true);

        return next (
            output,
            is_rls_enabled,
            visible_to_subscription_ids,
            case
                when error_record_exceeds_max_size then array['Error 413: Payload Too Large']
                else '{}'
            end
        )::realtime.wal_rls;

    end if;
end loop;

perform set_config('role', null, true);
end;
$$;


--
-- Name: broadcast_changes(text, text, text, text, text, record, record, text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text DEFAULT 'ROW'::text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    -- Declare a variable to hold the JSONB representation of the row
    row_data jsonb := '{}'::jsonb;
BEGIN
    IF level = 'STATEMENT' THEN
        RAISE EXCEPTION 'function can only be triggered for each row, not for each statement';
    END IF;
    -- Check the operation type and handle accordingly
    IF operation = 'INSERT' OR operation = 'UPDATE' OR operation = 'DELETE' THEN
        row_data := jsonb_build_object('old_record', OLD, 'record', NEW, 'operation', operation, 'table', table_name, 'schema', table_schema);
        PERFORM realtime.send (row_data, event_name, topic_name);
    ELSE
        RAISE EXCEPTION 'Unexpected operation type: %', operation;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to process the row: %', SQLERRM;
END;

$$;


--
-- Name: build_prepared_statement_sql(text, regclass, realtime.wal_column[]); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) RETURNS text
    LANGUAGE sql
    AS $$
      /*
      Builds a sql string that, if executed, creates a prepared statement to
      tests retrive a row from *entity* by its primary key columns.
      Example
          select realtime.build_prepared_statement_sql('public.notes', '{"id"}'::text[], '{"bigint"}'::text[])
      */
          select
      'prepare ' || prepared_statement_name || ' as
          select
              exists(
                  select
                      1
                  from
                      ' || entity || '
                  where
                      ' || string_agg(quote_ident(pkc.name) || '=' || quote_nullable(pkc.value #>> '{}') , ' and ') || '
              )'
          from
              unnest(columns) pkc
          where
              pkc.is_pkey
          group by
              entity
      $$;


--
-- Name: cast(text, regtype); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime."cast"(val text, type_ regtype) RETURNS jsonb
    LANGUAGE plpgsql IMMUTABLE
    AS $$
    declare
      res jsonb;
    begin
      execute format('select to_jsonb(%L::'|| type_::text || ')', val)  into res;
      return res;
    end
    $$;


--
-- Name: check_equality_op(realtime.equality_op, regtype, text, text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
      /*
      Casts *val_1* and *val_2* as type *type_* and check the *op* condition for truthiness
      */
      declare
          op_symbol text = (
              case
                  when op = 'eq' then '='
                  when op = 'neq' then '!='
                  when op = 'lt' then '<'
                  when op = 'lte' then '<='
                  when op = 'gt' then '>'
                  when op = 'gte' then '>='
                  when op = 'in' then '= any'
                  else 'UNKNOWN OP'
              end
          );
          res boolean;
      begin
          execute format(
              'select %L::'|| type_::text || ' ' || op_symbol
              || ' ( %L::'
              || (
                  case
                      when op = 'in' then type_::text || '[]'
                      else type_::text end
              )
              || ')', val_1, val_2) into res;
          return res;
      end;
      $$;


--
-- Name: is_visible_through_filters(realtime.wal_column[], realtime.user_defined_filter[]); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$
    /*
    Should the record be visible (true) or filtered out (false) after *filters* are applied
    */
        select
            -- Default to allowed when no filters present
            $2 is null -- no filters. this should not happen because subscriptions has a default
            or array_length($2, 1) is null -- array length of an empty array is null
            or bool_and(
                coalesce(
                    realtime.check_equality_op(
                        op:=f.op,
                        type_:=coalesce(
                            col.type_oid::regtype, -- null when wal2json version <= 2.4
                            col.type_name::regtype
                        ),
                        -- cast jsonb to text
                        val_1:=col.value #>> '{}',
                        val_2:=f.value
                    ),
                    false -- if null, filter does not match
                )
            )
        from
            unnest(filters) f
            join unnest(columns) col
                on f.column_name = col.name;
    $_$;


--
-- Name: list_changes(name, name, integer, integer); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) RETURNS SETOF realtime.wal_rls
    LANGUAGE sql
    SET log_min_messages TO 'fatal'
    AS $$
      with pub as (
        select
          concat_ws(
            ',',
            case when bool_or(pubinsert) then 'insert' else null end,
            case when bool_or(pubupdate) then 'update' else null end,
            case when bool_or(pubdelete) then 'delete' else null end
          ) as w2j_actions,
          coalesce(
            string_agg(
              realtime.quote_wal2json(format('%I.%I', schemaname, tablename)::regclass),
              ','
            ) filter (where ppt.tablename is not null and ppt.tablename not like '% %'),
            ''
          ) w2j_add_tables
        from
          pg_publication pp
          left join pg_publication_tables ppt
            on pp.pubname = ppt.pubname
        where
          pp.pubname = publication
        group by
          pp.pubname
        limit 1
      ),
      w2j as (
        select
          x.*, pub.w2j_add_tables
        from
          pub,
          pg_logical_slot_get_changes(
            slot_name, null, max_changes,
            'include-pk', 'true',
            'include-transaction', 'false',
            'include-timestamp', 'true',
            'include-type-oids', 'true',
            'format-version', '2',
            'actions', pub.w2j_actions,
            'add-tables', pub.w2j_add_tables
          ) x
      )
      select
        xyz.wal,
        xyz.is_rls_enabled,
        xyz.subscription_ids,
        xyz.errors
      from
        w2j,
        realtime.apply_rls(
          wal := w2j.data::jsonb,
          max_record_bytes := max_record_bytes
        ) xyz(wal, is_rls_enabled, subscription_ids, errors)
      where
        w2j.w2j_add_tables <> ''
        and xyz.subscription_ids[1] is not null
    $$;


--
-- Name: quote_wal2json(regclass); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.quote_wal2json(entity regclass) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
      select
        (
          select string_agg('' || ch,'')
          from unnest(string_to_array(nsp.nspname::text, null)) with ordinality x(ch, idx)
          where
            not (x.idx = 1 and x.ch = '"')
            and not (
              x.idx = array_length(string_to_array(nsp.nspname::text, null), 1)
              and x.ch = '"'
            )
        )
        || '.'
        || (
          select string_agg('' || ch,'')
          from unnest(string_to_array(pc.relname::text, null)) with ordinality x(ch, idx)
          where
            not (x.idx = 1 and x.ch = '"')
            and not (
              x.idx = array_length(string_to_array(nsp.nspname::text, null), 1)
              and x.ch = '"'
            )
          )
      from
        pg_class pc
        join pg_namespace nsp
          on pc.relnamespace = nsp.oid
      where
        pc.oid = entity
    $$;


--
-- Name: send(jsonb, text, text, boolean); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean DEFAULT true) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  BEGIN
    -- Set the topic configuration
    EXECUTE format('SET LOCAL realtime.topic TO %L', topic);

    -- Attempt to insert the message
    INSERT INTO realtime.messages (payload, event, topic, private, extension)
    VALUES (payload, event, topic, private, 'broadcast');
  EXCEPTION
    WHEN OTHERS THEN
      -- Capture and notify the error
      RAISE WARNING 'ErrorSendingBroadcastMessage: %', SQLERRM;
  END;
END;
$$;


--
-- Name: subscription_check_filters(); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.subscription_check_filters() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    /*
    Validates that the user defined filters for a subscription:
    - refer to valid columns that the claimed role may access
    - values are coercable to the correct column type
    */
    declare
        col_names text[] = coalesce(
                array_agg(c.column_name order by c.ordinal_position),
                '{}'::text[]
            )
            from
                information_schema.columns c
            where
                format('%I.%I', c.table_schema, c.table_name)::regclass = new.entity
                and pg_catalog.has_column_privilege(
                    (new.claims ->> 'role'),
                    format('%I.%I', c.table_schema, c.table_name)::regclass,
                    c.column_name,
                    'SELECT'
                );
        filter realtime.user_defined_filter;
        col_type regtype;

        in_val jsonb;
    begin
        for filter in select * from unnest(new.filters) loop
            -- Filtered column is valid
            if not filter.column_name = any(col_names) then
                raise exception 'invalid column for filter %', filter.column_name;
            end if;

            -- Type is sanitized and safe for string interpolation
            col_type = (
                select atttypid::regtype
                from pg_catalog.pg_attribute
                where attrelid = new.entity
                      and attname = filter.column_name
            );
            if col_type is null then
                raise exception 'failed to lookup type for column %', filter.column_name;
            end if;

            -- Set maximum number of entries for in filter
            if filter.op = 'in'::realtime.equality_op then
                in_val = realtime.cast(filter.value, (col_type::text || '[]')::regtype);
                if coalesce(jsonb_array_length(in_val), 0) > 100 then
                    raise exception 'too many values for `in` filter. Maximum 100';
                end if;
            else
                -- raises an exception if value is not coercable to type
                perform realtime.cast(filter.value, col_type);
            end if;

        end loop;

        -- Apply consistent order to filters so the unique constraint on
        -- (subscription_id, entity, filters) can't be tricked by a different filter order
        new.filters = coalesce(
            array_agg(f order by f.column_name, f.op, f.value),
            '{}'
        ) from unnest(new.filters) f;

        return new;
    end;
    $$;


--
-- Name: to_regrole(text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.to_regrole(role_name text) RETURNS regrole
    LANGUAGE sql IMMUTABLE
    AS $$ select role_name::regrole $$;


--
-- Name: topic(); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.topic() RETURNS text
    LANGUAGE sql STABLE
    AS $$
select nullif(current_setting('realtime.topic', true), '')::text;
$$;


--
-- Name: add_prefixes(text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.add_prefixes(_bucket_id text, _name text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    prefixes text[];
BEGIN
    prefixes := "storage"."get_prefixes"("_name");

    IF array_length(prefixes, 1) > 0 THEN
        INSERT INTO storage.prefixes (name, bucket_id)
        SELECT UNNEST(prefixes) as name, "_bucket_id" ON CONFLICT DO NOTHING;
    END IF;
END;
$$;


--
-- Name: can_insert_object(text, text, uuid, jsonb); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.can_insert_object(bucketid text, name text, owner uuid, metadata jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO "storage"."objects" ("bucket_id", "name", "owner", "metadata") VALUES (bucketid, name, owner, metadata);
  -- hack to rollback the successful insert
  RAISE sqlstate 'PT200' using
  message = 'ROLLBACK',
  detail = 'rollback successful insert';
END
$$;


--
-- Name: delete_leaf_prefixes(text[], text[]); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.delete_leaf_prefixes(bucket_ids text[], names text[]) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_rows_deleted integer;
BEGIN
    LOOP
        WITH candidates AS (
            SELECT DISTINCT
                t.bucket_id,
                unnest(storage.get_prefixes(t.name)) AS name
            FROM unnest(bucket_ids, names) AS t(bucket_id, name)
        ),
        uniq AS (
             SELECT
                 bucket_id,
                 name,
                 storage.get_level(name) AS level
             FROM candidates
             WHERE name <> ''
             GROUP BY bucket_id, name
        ),
        leaf AS (
             SELECT
                 p.bucket_id,
                 p.name,
                 p.level
             FROM storage.prefixes AS p
                  JOIN uniq AS u
                       ON u.bucket_id = p.bucket_id
                           AND u.name = p.name
                           AND u.level = p.level
             WHERE NOT EXISTS (
                 SELECT 1
                 FROM storage.objects AS o
                 WHERE o.bucket_id = p.bucket_id
                   AND o.level = p.level + 1
                   AND o.name COLLATE "C" LIKE p.name || '/%'
             )
             AND NOT EXISTS (
                 SELECT 1
                 FROM storage.prefixes AS c
                 WHERE c.bucket_id = p.bucket_id
                   AND c.level = p.level + 1
                   AND c.name COLLATE "C" LIKE p.name || '/%'
             )
        )
        DELETE
        FROM storage.prefixes AS p
            USING leaf AS l
        WHERE p.bucket_id = l.bucket_id
          AND p.name = l.name
          AND p.level = l.level;

        GET DIAGNOSTICS v_rows_deleted = ROW_COUNT;
        EXIT WHEN v_rows_deleted = 0;
    END LOOP;
END;
$$;


--
-- Name: delete_prefix(text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.delete_prefix(_bucket_id text, _name text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    -- Check if we can delete the prefix
    IF EXISTS(
        SELECT FROM "storage"."prefixes"
        WHERE "prefixes"."bucket_id" = "_bucket_id"
          AND level = "storage"."get_level"("_name") + 1
          AND "prefixes"."name" COLLATE "C" LIKE "_name" || '/%'
        LIMIT 1
    )
    OR EXISTS(
        SELECT FROM "storage"."objects"
        WHERE "objects"."bucket_id" = "_bucket_id"
          AND "storage"."get_level"("objects"."name") = "storage"."get_level"("_name") + 1
          AND "objects"."name" COLLATE "C" LIKE "_name" || '/%'
        LIMIT 1
    ) THEN
    -- There are sub-objects, skip deletion
    RETURN false;
    ELSE
        DELETE FROM "storage"."prefixes"
        WHERE "prefixes"."bucket_id" = "_bucket_id"
          AND level = "storage"."get_level"("_name")
          AND "prefixes"."name" = "_name";
        RETURN true;
    END IF;
END;
$$;


--
-- Name: delete_prefix_hierarchy_trigger(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.delete_prefix_hierarchy_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    prefix text;
BEGIN
    prefix := "storage"."get_prefix"(OLD."name");

    IF coalesce(prefix, '') != '' THEN
        PERFORM "storage"."delete_prefix"(OLD."bucket_id", prefix);
    END IF;

    RETURN OLD;
END;
$$;


--
-- Name: enforce_bucket_name_length(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.enforce_bucket_name_length() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    if length(new.name) > 100 then
        raise exception 'bucket name "%" is too long (% characters). Max is 100.', new.name, length(new.name);
    end if;
    return new;
end;
$$;


--
-- Name: extension(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.extension(name text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    _parts text[];
    _filename text;
BEGIN
    SELECT string_to_array(name, '/') INTO _parts;
    SELECT _parts[array_length(_parts,1)] INTO _filename;
    RETURN reverse(split_part(reverse(_filename), '.', 1));
END
$$;


--
-- Name: filename(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.filename(name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
BEGIN
	select string_to_array(name, '/') into _parts;
	return _parts[array_length(_parts,1)];
END
$$;


--
-- Name: foldername(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.foldername(name text) RETURNS text[]
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    _parts text[];
BEGIN
    -- Split on "/" to get path segments
    SELECT string_to_array(name, '/') INTO _parts;
    -- Return everything except the last segment
    RETURN _parts[1 : array_length(_parts,1) - 1];
END
$$;


--
-- Name: get_level(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_level(name text) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
SELECT array_length(string_to_array("name", '/'), 1);
$$;


--
-- Name: get_prefix(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_prefix(name text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
SELECT
    CASE WHEN strpos("name", '/') > 0 THEN
             regexp_replace("name", '[\/]{1}[^\/]+\/?$', '')
         ELSE
             ''
        END;
$_$;


--
-- Name: get_prefixes(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_prefixes(name text) RETURNS text[]
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $$
DECLARE
    parts text[];
    prefixes text[];
    prefix text;
BEGIN
    -- Split the name into parts by '/'
    parts := string_to_array("name", '/');
    prefixes := '{}';

    -- Construct the prefixes, stopping one level below the last part
    FOR i IN 1..array_length(parts, 1) - 1 LOOP
            prefix := array_to_string(parts[1:i], '/');
            prefixes := array_append(prefixes, prefix);
    END LOOP;

    RETURN prefixes;
END;
$$;


--
-- Name: get_size_by_bucket(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_size_by_bucket() RETURNS TABLE(size bigint, bucket_id text)
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    return query
        select sum((metadata->>'size')::bigint) as size, obj.bucket_id
        from "storage".objects as obj
        group by obj.bucket_id;
END
$$;


--
-- Name: list_multipart_uploads_with_delimiter(text, text, text, integer, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.list_multipart_uploads_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, next_key_token text DEFAULT ''::text, next_upload_token text DEFAULT ''::text) RETURNS TABLE(key text, id text, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT DISTINCT ON(key COLLATE "C") * from (
            SELECT
                CASE
                    WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                        substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1)))
                    ELSE
                        key
                END AS key, id, created_at
            FROM
                storage.s3_multipart_uploads
            WHERE
                bucket_id = $5 AND
                key ILIKE $1 || ''%'' AND
                CASE
                    WHEN $4 != '''' AND $6 = '''' THEN
                        CASE
                            WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                                substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1))) COLLATE "C" > $4
                            ELSE
                                key COLLATE "C" > $4
                            END
                    ELSE
                        true
                END AND
                CASE
                    WHEN $6 != '''' THEN
                        id COLLATE "C" > $6
                    ELSE
                        true
                    END
            ORDER BY
                key COLLATE "C" ASC, created_at ASC) as e order by key COLLATE "C" LIMIT $3'
        USING prefix_param, delimiter_param, max_keys, next_key_token, bucket_id, next_upload_token;
END;
$_$;


--
-- Name: list_objects_with_delimiter(text, text, text, integer, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.list_objects_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, start_after text DEFAULT ''::text, next_token text DEFAULT ''::text) RETURNS TABLE(name text, id uuid, metadata jsonb, updated_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT DISTINCT ON(name COLLATE "C") * from (
            SELECT
                CASE
                    WHEN position($2 IN substring(name from length($1) + 1)) > 0 THEN
                        substring(name from 1 for length($1) + position($2 IN substring(name from length($1) + 1)))
                    ELSE
                        name
                END AS name, id, metadata, updated_at
            FROM
                storage.objects
            WHERE
                bucket_id = $5 AND
                name ILIKE $1 || ''%'' AND
                CASE
                    WHEN $6 != '''' THEN
                    name COLLATE "C" > $6
                ELSE true END
                AND CASE
                    WHEN $4 != '''' THEN
                        CASE
                            WHEN position($2 IN substring(name from length($1) + 1)) > 0 THEN
                                substring(name from 1 for length($1) + position($2 IN substring(name from length($1) + 1))) COLLATE "C" > $4
                            ELSE
                                name COLLATE "C" > $4
                            END
                    ELSE
                        true
                END
            ORDER BY
                name COLLATE "C" ASC) as e order by name COLLATE "C" LIMIT $3'
        USING prefix_param, delimiter_param, max_keys, next_token, bucket_id, start_after;
END;
$_$;


--
-- Name: lock_top_prefixes(text[], text[]); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.lock_top_prefixes(bucket_ids text[], names text[]) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_bucket text;
    v_top text;
BEGIN
    FOR v_bucket, v_top IN
        SELECT DISTINCT t.bucket_id,
            split_part(t.name, '/', 1) AS top
        FROM unnest(bucket_ids, names) AS t(bucket_id, name)
        WHERE t.name <> ''
        ORDER BY 1, 2
        LOOP
            PERFORM pg_advisory_xact_lock(hashtextextended(v_bucket || '/' || v_top, 0));
        END LOOP;
END;
$$;


--
-- Name: objects_delete_cleanup(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.objects_delete_cleanup() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_bucket_ids text[];
    v_names      text[];
BEGIN
    IF current_setting('storage.gc.prefixes', true) = '1' THEN
        RETURN NULL;
    END IF;

    PERFORM set_config('storage.gc.prefixes', '1', true);

    SELECT COALESCE(array_agg(d.bucket_id), '{}'),
           COALESCE(array_agg(d.name), '{}')
    INTO v_bucket_ids, v_names
    FROM deleted AS d
    WHERE d.name <> '';

    PERFORM storage.lock_top_prefixes(v_bucket_ids, v_names);
    PERFORM storage.delete_leaf_prefixes(v_bucket_ids, v_names);

    RETURN NULL;
END;
$$;


--
-- Name: objects_insert_prefix_trigger(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.objects_insert_prefix_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM "storage"."add_prefixes"(NEW."bucket_id", NEW."name");
    NEW.level := "storage"."get_level"(NEW."name");

    RETURN NEW;
END;
$$;


--
-- Name: objects_update_cleanup(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.objects_update_cleanup() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    -- NEW - OLD (destinations to create prefixes for)
    v_add_bucket_ids text[];
    v_add_names      text[];

    -- OLD - NEW (sources to prune)
    v_src_bucket_ids text[];
    v_src_names      text[];
BEGIN
    IF TG_OP <> 'UPDATE' THEN
        RETURN NULL;
    END IF;

    -- 1) Compute NEW−OLD (added paths) and OLD−NEW (moved-away paths)
    WITH added AS (
        SELECT n.bucket_id, n.name
        FROM new_rows n
        WHERE n.name <> '' AND position('/' in n.name) > 0
        EXCEPT
        SELECT o.bucket_id, o.name FROM old_rows o WHERE o.name <> ''
    ),
    moved AS (
         SELECT o.bucket_id, o.name
         FROM old_rows o
         WHERE o.name <> ''
         EXCEPT
         SELECT n.bucket_id, n.name FROM new_rows n WHERE n.name <> ''
    )
    SELECT
        -- arrays for ADDED (dest) in stable order
        COALESCE( (SELECT array_agg(a.bucket_id ORDER BY a.bucket_id, a.name) FROM added a), '{}' ),
        COALESCE( (SELECT array_agg(a.name      ORDER BY a.bucket_id, a.name) FROM added a), '{}' ),
        -- arrays for MOVED (src) in stable order
        COALESCE( (SELECT array_agg(m.bucket_id ORDER BY m.bucket_id, m.name) FROM moved m), '{}' ),
        COALESCE( (SELECT array_agg(m.name      ORDER BY m.bucket_id, m.name) FROM moved m), '{}' )
    INTO v_add_bucket_ids, v_add_names, v_src_bucket_ids, v_src_names;

    -- Nothing to do?
    IF (array_length(v_add_bucket_ids, 1) IS NULL) AND (array_length(v_src_bucket_ids, 1) IS NULL) THEN
        RETURN NULL;
    END IF;

    -- 2) Take per-(bucket, top) locks: ALL prefixes in consistent global order to prevent deadlocks
    DECLARE
        v_all_bucket_ids text[];
        v_all_names text[];
    BEGIN
        -- Combine source and destination arrays for consistent lock ordering
        v_all_bucket_ids := COALESCE(v_src_bucket_ids, '{}') || COALESCE(v_add_bucket_ids, '{}');
        v_all_names := COALESCE(v_src_names, '{}') || COALESCE(v_add_names, '{}');

        -- Single lock call ensures consistent global ordering across all transactions
        IF array_length(v_all_bucket_ids, 1) IS NOT NULL THEN
            PERFORM storage.lock_top_prefixes(v_all_bucket_ids, v_all_names);
        END IF;
    END;

    -- 3) Create destination prefixes (NEW−OLD) BEFORE pruning sources
    IF array_length(v_add_bucket_ids, 1) IS NOT NULL THEN
        WITH candidates AS (
            SELECT DISTINCT t.bucket_id, unnest(storage.get_prefixes(t.name)) AS name
            FROM unnest(v_add_bucket_ids, v_add_names) AS t(bucket_id, name)
            WHERE name <> ''
        )
        INSERT INTO storage.prefixes (bucket_id, name)
        SELECT c.bucket_id, c.name
        FROM candidates c
        ON CONFLICT DO NOTHING;
    END IF;

    -- 4) Prune source prefixes bottom-up for OLD−NEW
    IF array_length(v_src_bucket_ids, 1) IS NOT NULL THEN
        -- re-entrancy guard so DELETE on prefixes won't recurse
        IF current_setting('storage.gc.prefixes', true) <> '1' THEN
            PERFORM set_config('storage.gc.prefixes', '1', true);
        END IF;

        PERFORM storage.delete_leaf_prefixes(v_src_bucket_ids, v_src_names);
    END IF;

    RETURN NULL;
END;
$$;


--
-- Name: objects_update_level_trigger(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.objects_update_level_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Ensure this is an update operation and the name has changed
    IF TG_OP = 'UPDATE' AND (NEW."name" <> OLD."name" OR NEW."bucket_id" <> OLD."bucket_id") THEN
        -- Set the new level
        NEW."level" := "storage"."get_level"(NEW."name");
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: objects_update_prefix_trigger(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.objects_update_prefix_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    old_prefixes TEXT[];
BEGIN
    -- Ensure this is an update operation and the name has changed
    IF TG_OP = 'UPDATE' AND (NEW."name" <> OLD."name" OR NEW."bucket_id" <> OLD."bucket_id") THEN
        -- Retrieve old prefixes
        old_prefixes := "storage"."get_prefixes"(OLD."name");

        -- Remove old prefixes that are only used by this object
        WITH all_prefixes as (
            SELECT unnest(old_prefixes) as prefix
        ),
        can_delete_prefixes as (
             SELECT prefix
             FROM all_prefixes
             WHERE NOT EXISTS (
                 SELECT 1 FROM "storage"."objects"
                 WHERE "bucket_id" = OLD."bucket_id"
                   AND "name" <> OLD."name"
                   AND "name" LIKE (prefix || '%')
             )
         )
        DELETE FROM "storage"."prefixes" WHERE name IN (SELECT prefix FROM can_delete_prefixes);

        -- Add new prefixes
        PERFORM "storage"."add_prefixes"(NEW."bucket_id", NEW."name");
    END IF;
    -- Set the new level
    NEW."level" := "storage"."get_level"(NEW."name");

    RETURN NEW;
END;
$$;


--
-- Name: operation(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.operation() RETURNS text
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    RETURN current_setting('storage.operation', true);
END;
$$;


--
-- Name: prefixes_delete_cleanup(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.prefixes_delete_cleanup() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_bucket_ids text[];
    v_names      text[];
BEGIN
    IF current_setting('storage.gc.prefixes', true) = '1' THEN
        RETURN NULL;
    END IF;

    PERFORM set_config('storage.gc.prefixes', '1', true);

    SELECT COALESCE(array_agg(d.bucket_id), '{}'),
           COALESCE(array_agg(d.name), '{}')
    INTO v_bucket_ids, v_names
    FROM deleted AS d
    WHERE d.name <> '';

    PERFORM storage.lock_top_prefixes(v_bucket_ids, v_names);
    PERFORM storage.delete_leaf_prefixes(v_bucket_ids, v_names);

    RETURN NULL;
END;
$$;


--
-- Name: prefixes_insert_trigger(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.prefixes_insert_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM "storage"."add_prefixes"(NEW."bucket_id", NEW."name");
    RETURN NEW;
END;
$$;


--
-- Name: search(text, text, integer, integer, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search(prefix text, bucketname text, limits integer DEFAULT 100, levels integer DEFAULT 1, offsets integer DEFAULT 0, search text DEFAULT ''::text, sortcolumn text DEFAULT 'name'::text, sortorder text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql
    AS $$
declare
    can_bypass_rls BOOLEAN;
begin
    SELECT rolbypassrls
    INTO can_bypass_rls
    FROM pg_roles
    WHERE rolname = coalesce(nullif(current_setting('role', true), 'none'), current_user);

    IF can_bypass_rls THEN
        RETURN QUERY SELECT * FROM storage.search_v1_optimised(prefix, bucketname, limits, levels, offsets, search, sortcolumn, sortorder);
    ELSE
        RETURN QUERY SELECT * FROM storage.search_legacy_v1(prefix, bucketname, limits, levels, offsets, search, sortcolumn, sortorder);
    END IF;
end;
$$;


--
-- Name: search_legacy_v1(text, text, integer, integer, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search_legacy_v1(prefix text, bucketname text, limits integer DEFAULT 100, levels integer DEFAULT 1, offsets integer DEFAULT 0, search text DEFAULT ''::text, sortcolumn text DEFAULT 'name'::text, sortorder text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
declare
    v_order_by text;
    v_sort_order text;
begin
    case
        when sortcolumn = 'name' then
            v_order_by = 'name';
        when sortcolumn = 'updated_at' then
            v_order_by = 'updated_at';
        when sortcolumn = 'created_at' then
            v_order_by = 'created_at';
        when sortcolumn = 'last_accessed_at' then
            v_order_by = 'last_accessed_at';
        else
            v_order_by = 'name';
        end case;

    case
        when sortorder = 'asc' then
            v_sort_order = 'asc';
        when sortorder = 'desc' then
            v_sort_order = 'desc';
        else
            v_sort_order = 'asc';
        end case;

    v_order_by = v_order_by || ' ' || v_sort_order;

    return query execute
        'with folders as (
           select path_tokens[$1] as folder
           from storage.objects
             where objects.name ilike $2 || $3 || ''%''
               and bucket_id = $4
               and array_length(objects.path_tokens, 1) <> $1
           group by folder
           order by folder ' || v_sort_order || '
     )
     (select folder as "name",
            null as id,
            null as updated_at,
            null as created_at,
            null as last_accessed_at,
            null as metadata from folders)
     union all
     (select path_tokens[$1] as "name",
            id,
            updated_at,
            created_at,
            last_accessed_at,
            metadata
     from storage.objects
     where objects.name ilike $2 || $3 || ''%''
       and bucket_id = $4
       and array_length(objects.path_tokens, 1) = $1
     order by ' || v_order_by || ')
     limit $5
     offset $6' using levels, prefix, search, bucketname, limits, offsets;
end;
$_$;


--
-- Name: search_v1_optimised(text, text, integer, integer, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search_v1_optimised(prefix text, bucketname text, limits integer DEFAULT 100, levels integer DEFAULT 1, offsets integer DEFAULT 0, search text DEFAULT ''::text, sortcolumn text DEFAULT 'name'::text, sortorder text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
declare
    v_order_by text;
    v_sort_order text;
begin
    case
        when sortcolumn = 'name' then
            v_order_by = 'name';
        when sortcolumn = 'updated_at' then
            v_order_by = 'updated_at';
        when sortcolumn = 'created_at' then
            v_order_by = 'created_at';
        when sortcolumn = 'last_accessed_at' then
            v_order_by = 'last_accessed_at';
        else
            v_order_by = 'name';
        end case;

    case
        when sortorder = 'asc' then
            v_sort_order = 'asc';
        when sortorder = 'desc' then
            v_sort_order = 'desc';
        else
            v_sort_order = 'asc';
        end case;

    v_order_by = v_order_by || ' ' || v_sort_order;

    return query execute
        'with folders as (
           select (string_to_array(name, ''/''))[level] as name
           from storage.prefixes
             where lower(prefixes.name) like lower($2 || $3) || ''%''
               and bucket_id = $4
               and level = $1
           order by name ' || v_sort_order || '
     )
     (select name,
            null as id,
            null as updated_at,
            null as created_at,
            null as last_accessed_at,
            null as metadata from folders)
     union all
     (select path_tokens[level] as "name",
            id,
            updated_at,
            created_at,
            last_accessed_at,
            metadata
     from storage.objects
     where lower(objects.name) like lower($2 || $3) || ''%''
       and bucket_id = $4
       and level = $1
     order by ' || v_order_by || ')
     limit $5
     offset $6' using levels, prefix, search, bucketname, limits, offsets;
end;
$_$;


--
-- Name: search_v2(text, text, integer, integer, text, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search_v2(prefix text, bucket_name text, limits integer DEFAULT 100, levels integer DEFAULT 1, start_after text DEFAULT ''::text, sort_order text DEFAULT 'asc'::text, sort_column text DEFAULT 'name'::text, sort_column_after text DEFAULT ''::text) RETURNS TABLE(key text, name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    sort_col text;
    sort_ord text;
    cursor_op text;
    cursor_expr text;
    sort_expr text;
BEGIN
    -- Validate sort_order
    sort_ord := lower(sort_order);
    IF sort_ord NOT IN ('asc', 'desc') THEN
        sort_ord := 'asc';
    END IF;

    -- Determine cursor comparison operator
    IF sort_ord = 'asc' THEN
        cursor_op := '>';
    ELSE
        cursor_op := '<';
    END IF;
    
    sort_col := lower(sort_column);
    -- Validate sort column  
    IF sort_col IN ('updated_at', 'created_at') THEN
        cursor_expr := format(
            '($5 = '''' OR ROW(date_trunc(''milliseconds'', %I), name COLLATE "C") %s ROW(COALESCE(NULLIF($6, '''')::timestamptz, ''epoch''::timestamptz), $5))',
            sort_col, cursor_op
        );
        sort_expr := format(
            'COALESCE(date_trunc(''milliseconds'', %I), ''epoch''::timestamptz) %s, name COLLATE "C" %s',
            sort_col, sort_ord, sort_ord
        );
    ELSE
        cursor_expr := format('($5 = '''' OR name COLLATE "C" %s $5)', cursor_op);
        sort_expr := format('name COLLATE "C" %s', sort_ord);
    END IF;

    RETURN QUERY EXECUTE format(
        $sql$
        SELECT * FROM (
            (
                SELECT
                    split_part(name, '/', $4) AS key,
                    name,
                    NULL::uuid AS id,
                    updated_at,
                    created_at,
                    NULL::timestamptz AS last_accessed_at,
                    NULL::jsonb AS metadata
                FROM storage.prefixes
                WHERE name COLLATE "C" LIKE $1 || '%%'
                    AND bucket_id = $2
                    AND level = $4
                    AND %s
                ORDER BY %s
                LIMIT $3
            )
            UNION ALL
            (
                SELECT
                    split_part(name, '/', $4) AS key,
                    name,
                    id,
                    updated_at,
                    created_at,
                    last_accessed_at,
                    metadata
                FROM storage.objects
                WHERE name COLLATE "C" LIKE $1 || '%%'
                    AND bucket_id = $2
                    AND level = $4
                    AND %s
                ORDER BY %s
                LIMIT $3
            )
        ) obj
        ORDER BY %s
        LIMIT $3
        $sql$,
        cursor_expr,    -- prefixes WHERE
        sort_expr,      -- prefixes ORDER BY
        cursor_expr,    -- objects WHERE
        sort_expr,      -- objects ORDER BY
        sort_expr       -- final ORDER BY
    )
    USING prefix, bucket_name, limits, levels, start_after, sort_column_after;
END;
$_$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW; 
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_log_entries; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.audit_log_entries (
    instance_id uuid,
    id uuid NOT NULL,
    payload json,
    created_at timestamp with time zone,
    ip_address character varying(64) DEFAULT ''::character varying NOT NULL
);


--
-- Name: TABLE audit_log_entries; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.audit_log_entries IS 'Auth: Audit trail for user actions.';


--
-- Name: flow_state; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.flow_state (
    id uuid NOT NULL,
    user_id uuid,
    auth_code text NOT NULL,
    code_challenge_method auth.code_challenge_method NOT NULL,
    code_challenge text NOT NULL,
    provider_type text NOT NULL,
    provider_access_token text,
    provider_refresh_token text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    authentication_method text NOT NULL,
    auth_code_issued_at timestamp with time zone
);


--
-- Name: TABLE flow_state; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.flow_state IS 'stores metadata for pkce logins';


--
-- Name: identities; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.identities (
    provider_id text NOT NULL,
    user_id uuid NOT NULL,
    identity_data jsonb NOT NULL,
    provider text NOT NULL,
    last_sign_in_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    email text GENERATED ALWAYS AS (lower((identity_data ->> 'email'::text))) STORED,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


--
-- Name: TABLE identities; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.identities IS 'Auth: Stores identities associated to a user.';


--
-- Name: COLUMN identities.email; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.identities.email IS 'Auth: Email is a generated column that references the optional email property in the identity_data';


--
-- Name: instances; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.instances (
    id uuid NOT NULL,
    uuid uuid,
    raw_base_config text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: TABLE instances; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.instances IS 'Auth: Manages users across multiple sites.';


--
-- Name: mfa_amr_claims; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_amr_claims (
    session_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    authentication_method text NOT NULL,
    id uuid NOT NULL
);


--
-- Name: TABLE mfa_amr_claims; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_amr_claims IS 'auth: stores authenticator method reference claims for multi factor authentication';


--
-- Name: mfa_challenges; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_challenges (
    id uuid NOT NULL,
    factor_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    verified_at timestamp with time zone,
    ip_address inet NOT NULL,
    otp_code text,
    web_authn_session_data jsonb
);


--
-- Name: TABLE mfa_challenges; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_challenges IS 'auth: stores metadata about challenge requests made';


--
-- Name: mfa_factors; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_factors (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    friendly_name text,
    factor_type auth.factor_type NOT NULL,
    status auth.factor_status NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    secret text,
    phone text,
    last_challenged_at timestamp with time zone,
    web_authn_credential jsonb,
    web_authn_aaguid uuid
);


--
-- Name: TABLE mfa_factors; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_factors IS 'auth: stores metadata about factors';


--
-- Name: oauth_clients; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_clients (
    id uuid NOT NULL,
    client_id text NOT NULL,
    client_secret_hash text NOT NULL,
    registration_type auth.oauth_registration_type NOT NULL,
    redirect_uris text NOT NULL,
    grant_types text NOT NULL,
    client_name text,
    client_uri text,
    logo_uri text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT oauth_clients_client_name_length CHECK ((char_length(client_name) <= 1024)),
    CONSTRAINT oauth_clients_client_uri_length CHECK ((char_length(client_uri) <= 2048)),
    CONSTRAINT oauth_clients_logo_uri_length CHECK ((char_length(logo_uri) <= 2048))
);


--
-- Name: one_time_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.one_time_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token_type auth.one_time_token_type NOT NULL,
    token_hash text NOT NULL,
    relates_to text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT one_time_tokens_token_hash_check CHECK ((char_length(token_hash) > 0))
);


--
-- Name: refresh_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.refresh_tokens (
    instance_id uuid,
    id bigint NOT NULL,
    token character varying(255),
    user_id character varying(255),
    revoked boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    parent character varying(255),
    session_id uuid
);


--
-- Name: TABLE refresh_tokens; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.refresh_tokens IS 'Auth: Store of tokens used to refresh JWT tokens once they expire.';


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

CREATE SEQUENCE auth.refresh_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: -
--

ALTER SEQUENCE auth.refresh_tokens_id_seq OWNED BY auth.refresh_tokens.id;


--
-- Name: saml_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_providers (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    entity_id text NOT NULL,
    metadata_xml text NOT NULL,
    metadata_url text,
    attribute_mapping jsonb,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    name_id_format text,
    CONSTRAINT "entity_id not empty" CHECK ((char_length(entity_id) > 0)),
    CONSTRAINT "metadata_url not empty" CHECK (((metadata_url = NULL::text) OR (char_length(metadata_url) > 0))),
    CONSTRAINT "metadata_xml not empty" CHECK ((char_length(metadata_xml) > 0))
);


--
-- Name: TABLE saml_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_providers IS 'Auth: Manages SAML Identity Provider connections.';


--
-- Name: saml_relay_states; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_relay_states (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    request_id text NOT NULL,
    for_email text,
    redirect_to text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    flow_state_id uuid,
    CONSTRAINT "request_id not empty" CHECK ((char_length(request_id) > 0))
);


--
-- Name: TABLE saml_relay_states; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_relay_states IS 'Auth: Contains SAML Relay State information for each Service Provider initiated login.';


--
-- Name: schema_migrations; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: TABLE schema_migrations; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.schema_migrations IS 'Auth: Manages updates to the auth system.';


--
-- Name: sessions; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sessions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    factor_id uuid,
    aal auth.aal_level,
    not_after timestamp with time zone,
    refreshed_at timestamp without time zone,
    user_agent text,
    ip inet,
    tag text
);


--
-- Name: TABLE sessions; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sessions IS 'Auth: Stores session data associated to a user.';


--
-- Name: COLUMN sessions.not_after; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.not_after IS 'Auth: Not after is a nullable column that contains a timestamp after which the session should be regarded as expired.';


--
-- Name: sso_domains; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_domains (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    domain text NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    CONSTRAINT "domain not empty" CHECK ((char_length(domain) > 0))
);


--
-- Name: TABLE sso_domains; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_domains IS 'Auth: Manages SSO email address domain mapping to an SSO Identity Provider.';


--
-- Name: sso_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_providers (
    id uuid NOT NULL,
    resource_id text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    disabled boolean,
    CONSTRAINT "resource_id not empty" CHECK (((resource_id = NULL::text) OR (char_length(resource_id) > 0)))
);


--
-- Name: TABLE sso_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_providers IS 'Auth: Manages SSO identity provider information; see saml_providers for SAML.';


--
-- Name: COLUMN sso_providers.resource_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sso_providers.resource_id IS 'Auth: Uniquely identifies a SSO provider according to a user-chosen resource ID (case insensitive), useful in infrastructure as code.';


--
-- Name: users; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.users (
    instance_id uuid,
    id uuid NOT NULL,
    aud character varying(255),
    role character varying(255),
    email character varying(255),
    encrypted_password character varying(255),
    email_confirmed_at timestamp with time zone,
    invited_at timestamp with time zone,
    confirmation_token character varying(255),
    confirmation_sent_at timestamp with time zone,
    recovery_token character varying(255),
    recovery_sent_at timestamp with time zone,
    email_change_token_new character varying(255),
    email_change character varying(255),
    email_change_sent_at timestamp with time zone,
    last_sign_in_at timestamp with time zone,
    raw_app_meta_data jsonb,
    raw_user_meta_data jsonb,
    is_super_admin boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    phone text DEFAULT NULL::character varying,
    phone_confirmed_at timestamp with time zone,
    phone_change text DEFAULT ''::character varying,
    phone_change_token character varying(255) DEFAULT ''::character varying,
    phone_change_sent_at timestamp with time zone,
    confirmed_at timestamp with time zone GENERATED ALWAYS AS (LEAST(email_confirmed_at, phone_confirmed_at)) STORED,
    email_change_token_current character varying(255) DEFAULT ''::character varying,
    email_change_confirm_status smallint DEFAULT 0,
    banned_until timestamp with time zone,
    reauthentication_token character varying(255) DEFAULT ''::character varying,
    reauthentication_sent_at timestamp with time zone,
    is_sso_user boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    is_anonymous boolean DEFAULT false NOT NULL,
    CONSTRAINT users_email_change_confirm_status_check CHECK (((email_change_confirm_status >= 0) AND (email_change_confirm_status <= 2)))
);


--
-- Name: TABLE users; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.users IS 'Auth: Stores user login data within a secure schema.';


--
-- Name: COLUMN users.is_sso_user; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.users.is_sso_user IS 'Auth: Set this column to true when the account comes from SSO. These accounts can have duplicate emails.';


--
-- Name: admins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admins (
    username text NOT NULL,
    password_hash text NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: app_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.app_config (
    key text NOT NULL,
    value text NOT NULL
);


--
-- Name: order_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.order_items (
    id integer NOT NULL,
    order_id integer NOT NULL,
    package_id integer,
    package_name text,
    product_code text,
    quantity integer DEFAULT 1 NOT NULL,
    unit_price real DEFAULT 0 NOT NULL,
    cost real DEFAULT 0 NOT NULL,
    total_price real DEFAULT 0 NOT NULL
);


--
-- Name: order_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.order_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: order_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.order_items_id_seq OWNED BY public.order_items.id;


--
-- Name: orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orders (
    id integer NOT NULL,
    order_number text NOT NULL,
    order_date timestamp with time zone NOT NULL,
    platform text,
    customer_name text,
    game_name text,
    total_paid real DEFAULT 0 NOT NULL,
    payment_proof_url text,
    sales_proof_url text,
    product_code text,
    package_count integer DEFAULT 0 NOT NULL,
    packages_text text,
    cost real DEFAULT 0 NOT NULL,
    profit real DEFAULT 0 NOT NULL,
    status text DEFAULT 'รอดำเนินการ'::text NOT NULL,
    operator text,
    topup_channel text,
    note text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.orders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.orders_id_seq OWNED BY public.orders.id;


--
-- Name: packages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.packages (
    id integer NOT NULL,
    name text NOT NULL,
    price real NOT NULL,
    product_code text,
    type text NOT NULL,
    channel text NOT NULL,
    game_association text NOT NULL,
    is_active integer DEFAULT 1,
    created_at timestamp with time zone DEFAULT now(),
    sort_order integer DEFAULT 0
);


--
-- Name: packages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.packages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: packages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.packages_id_seq OWNED BY public.packages.id;


--
-- Name: packages_id_seq1; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.packages ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.packages_id_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: user_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_sessions (
    sid character varying NOT NULL,
    sess json NOT NULL,
    expire timestamp(6) without time zone NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    username text NOT NULL,
    password_hash text NOT NULL
);


--
-- Name: messages; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.messages (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL
)
PARTITION BY RANGE (inserted_at);


--
-- Name: schema_migrations; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: subscription; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.subscription (
    id bigint NOT NULL,
    subscription_id uuid NOT NULL,
    entity regclass NOT NULL,
    filters realtime.user_defined_filter[] DEFAULT '{}'::realtime.user_defined_filter[] NOT NULL,
    claims jsonb NOT NULL,
    claims_role regrole GENERATED ALWAYS AS (realtime.to_regrole((claims ->> 'role'::text))) STORED NOT NULL,
    created_at timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);


--
-- Name: subscription_id_seq; Type: SEQUENCE; Schema: realtime; Owner: -
--

ALTER TABLE realtime.subscription ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME realtime.subscription_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: buckets; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets (
    id text NOT NULL,
    name text NOT NULL,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    public boolean DEFAULT false,
    avif_autodetection boolean DEFAULT false,
    file_size_limit bigint,
    allowed_mime_types text[],
    owner_id text,
    type storage.buckettype DEFAULT 'STANDARD'::storage.buckettype NOT NULL
);


--
-- Name: COLUMN buckets.owner; Type: COMMENT; Schema: storage; Owner: -
--

COMMENT ON COLUMN storage.buckets.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: buckets_analytics; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets_analytics (
    id text NOT NULL,
    type storage.buckettype DEFAULT 'ANALYTICS'::storage.buckettype NOT NULL,
    format text DEFAULT 'ICEBERG'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: migrations; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.migrations (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    hash character varying(40) NOT NULL,
    executed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: objects; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.objects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bucket_id text,
    name text,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    last_accessed_at timestamp with time zone DEFAULT now(),
    metadata jsonb,
    path_tokens text[] GENERATED ALWAYS AS (string_to_array(name, '/'::text)) STORED,
    version text,
    owner_id text,
    user_metadata jsonb,
    level integer
);


--
-- Name: COLUMN objects.owner; Type: COMMENT; Schema: storage; Owner: -
--

COMMENT ON COLUMN storage.objects.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: prefixes; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.prefixes (
    bucket_id text NOT NULL,
    name text NOT NULL COLLATE pg_catalog."C",
    level integer GENERATED ALWAYS AS (storage.get_level(name)) STORED NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: s3_multipart_uploads; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.s3_multipart_uploads (
    id text NOT NULL,
    in_progress_size bigint DEFAULT 0 NOT NULL,
    upload_signature text NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    version text NOT NULL,
    owner_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    user_metadata jsonb
);


--
-- Name: s3_multipart_uploads_parts; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.s3_multipart_uploads_parts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    upload_id text NOT NULL,
    size bigint DEFAULT 0 NOT NULL,
    part_number integer NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    etag text NOT NULL,
    owner_id text,
    version text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: refresh_tokens id; Type: DEFAULT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens ALTER COLUMN id SET DEFAULT nextval('auth.refresh_tokens_id_seq'::regclass);


--
-- Name: order_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_items ALTER COLUMN id SET DEFAULT nextval('public.order_items_id_seq'::regclass);


--
-- Name: orders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders ALTER COLUMN id SET DEFAULT nextval('public.orders_id_seq'::regclass);


--
-- Data for Name: audit_log_entries; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) FROM stdin;
\.


--
-- Data for Name: flow_state; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.flow_state (id, user_id, auth_code, code_challenge_method, code_challenge, provider_type, provider_access_token, provider_refresh_token, created_at, updated_at, authentication_method, auth_code_issued_at) FROM stdin;
\.


--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) FROM stdin;
\.


--
-- Data for Name: instances; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.instances (id, uuid, raw_base_config, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: mfa_amr_claims; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) FROM stdin;
\.


--
-- Data for Name: mfa_challenges; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.mfa_challenges (id, factor_id, created_at, verified_at, ip_address, otp_code, web_authn_session_data) FROM stdin;
\.


--
-- Data for Name: mfa_factors; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.mfa_factors (id, user_id, friendly_name, factor_type, status, created_at, updated_at, secret, phone, last_challenged_at, web_authn_credential, web_authn_aaguid) FROM stdin;
\.


--
-- Data for Name: oauth_clients; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.oauth_clients (id, client_id, client_secret_hash, registration_type, redirect_uris, grant_types, client_name, client_uri, logo_uri, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- Data for Name: one_time_tokens; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.one_time_tokens (id, user_id, token_type, token_hash, relates_to, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) FROM stdin;
\.


--
-- Data for Name: saml_providers; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.saml_providers (id, sso_provider_id, entity_id, metadata_xml, metadata_url, attribute_mapping, created_at, updated_at, name_id_format) FROM stdin;
\.


--
-- Data for Name: saml_relay_states; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.saml_relay_states (id, sso_provider_id, request_id, for_email, redirect_to, created_at, updated_at, flow_state_id) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.schema_migrations (version) FROM stdin;
20171026211738
20171026211808
20171026211834
20180103212743
20180108183307
20180119214651
20180125194653
00
20210710035447
20210722035447
20210730183235
20210909172000
20210927181326
20211122151130
20211124214934
20211202183645
20220114185221
20220114185340
20220224000811
20220323170000
20220429102000
20220531120530
20220614074223
20220811173540
20221003041349
20221003041400
20221011041400
20221020193600
20221021073300
20221021082433
20221027105023
20221114143122
20221114143410
20221125140132
20221208132122
20221215195500
20221215195800
20221215195900
20230116124310
20230116124412
20230131181311
20230322519590
20230402418590
20230411005111
20230508135423
20230523124323
20230818113222
20230914180801
20231027141322
20231114161723
20231117164230
20240115144230
20240214120130
20240306115329
20240314092811
20240427152123
20240612123726
20240729123726
20240802193726
20240806073726
20241009103726
20250717082212
20250731150234
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag) FROM stdin;
\.


--
-- Data for Name: sso_domains; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sso_domains (id, sso_provider_id, domain, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: sso_providers; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sso_providers (id, resource_id, created_at, updated_at, disabled) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) FROM stdin;
\.


--
-- Data for Name: admins; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.admins (username, password_hash, created_at) FROM stdin;
ADGRES02	$2a$10$B5O/vUQa0GQaMpal22.4Vuod9g5iQ8uOD/IBm/ztZ2jA5DJNrxBka	2025-09-25 14:52:30.217536+00
tantan	$2b$10$k9hhL.L2IaIfdpUbbiIWEexo//Laq.zW7bPfAn6fbgzlEOJU20Cy.	2025-09-25 14:58:48.406727+00
\.


--
-- Data for Name: app_config; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.app_config (key, value) FROM stdin;
game_order	["(ID-PASS) เติมได้หลายเกม","LOL_WILDRIFT","MINECRAFT","TFT_MOBILE","ROBLOX","VALORANT","LOL (บนคอม)","RACING_MASTER","RACING (LOGIN)","DUNK_DYNASTY","FREEFIRE","ROV_MOBILE","DELTA_FORCE","MARVEL_RIVALS","PUBG_MOBILE","HONKAI_STARRAIL","ZENLESS_ZONE","COA","HOK (GLOBAL)","HARRY_AWAKENED","MOBILE_LEGENDS","GENSHIN_IMPACT","7KNIGHT_Re:BIRTH"]
\.


--
-- Data for Name: order_items; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.order_items (id, order_id, package_id, package_name, product_code, quantity, unit_price, cost, total_price) FROM stdin;
862	312	90	425WC	KU-0000	1	89	0	89
101	22	66	669BAHT ($19.99)	KU-0000	1	539	0	539
549	145	6	(ROSE) 10000WC	KU-0000	1	1590	0	1590
103	21	51	6930GEMS	KU-0032	1	2359	0	2359
863	311	97	5225WC	KU-0000	1	889	0	889
550	144	2	(ROSE) 4800WC	KU-0000	1	789	0	789
551	143	1	(ROSE) 3275WC	KU-0000	1	559	0	559
552	142	6	(ROSE) 10000WC	KU-0000	1	1590	0	1590
682	87	113	3500 เหรียญ	KU-0000	1	209	0	209
683	86	235	5680LATT	KU-0000	1	1399	0	1399
864	311	106	CELESTIAL	KU-0000	1	569	0	569
865	310	22	2050VP	KU-0004	1	505	0	505
553	141	109	960 เหรียญ	KU-0000	1	105	0	105
866	309	173	575TFT	KU-0000	1	119	0	119
562	133	13	399 BAHT (9.99$)	KU-0000	1	289	0	289
447	215	3	(ROSE) 5225WC	KU-0000	1	889	0	889
452	212	6	(ROSE) 10000WC	KU-0000	1	1590	0	1590
453	211	223	400 ROBUX	KU-0000	1	150	0	150
454	210	174	1380TFT	KU-0000	1	239	0	239
867	309	174	1380TFT	KU-0000	1	239	0	239
868	309	177	6500TFT	KU-0000	1	1039	0	1039
869	308	196	บัตรกำนัลเสบียงรถไฟ	KU-0000	1	139	0	139
870	308	267	INTER-KNOT (รายเดือน)	KU-0000	1	139	0	139
871	308	12	199 BAHT (4.99$)	KU-0000	1	149	0	149
872	307	177	6500TFT	KU-0000	1	1039	0	1039
873	306	95	3275WC	KU-0000	1	569	0	569
874	305	174	1380TFT	KU-0000	1	239	0	239
875	305	177	6500TFT	KU-0000	1	1039	0	1039
1079	372	76	Party Membership	KU-0000	1	159	0	159
1080	371	113	3500 เหรียญ	KU-0000	1	209	0	209
878	304	67	999BAHT ($29.49)	KU-0000	1	789	0	789
879	304	260	3400BAHT ($99.99)	KU-0000	1	2659	0	2659
563	132	3	(ROSE) 5225WC	KU-0000	1	889	0	889
564	131	93	1850WC	KU-0000	1	340	0	340
571	126	2	(ROSE) 4800WC	KU-0000	1	789	0	789
572	125	113	3500 เหรียญ	KU-0000	1	209	0	209
573	124	3	(ROSE) 5225WC	KU-0000	1	889	0	889
574	123	20	1000VP	KU-0002	1	250	0	250
880	303	223	400 ROBUX	KU-0000	1	150	0	150
1081	370	48	1470GEMS	KU-0029	1	529	0	529
1082	369	220	8100DELTA	KU-0000	1	2490	0	2490
515	218	74	3880TOKENS	KU-0000	1	1489	0	1489
521	168	78	Premium Pass	KU-0000	1	169	0	169
524	166	129	1801 เพชร	KU-0000	1	489	0	489
527	164	72	1110TOKENS	KU-0000	1	419	0	419
534	157	6	(ROSE) 10000WC	KU-0000	1	1590	0	1590
535	156	108	640 เหรียญ	KU-0000	1	69	0	69
606	227	2	(ROSE) 4800WC	KU-0000	1	789	0	789
537	155	13	399 BAHT (9.99$)	KU-0000	1	289	0	289
538	154	91	1000WC	KU-0000	2	190	0	380
540	153	91	1000WC	KU-0000	1	190	0	190
544	151	90	425WC	KU-0000	1	89	0	89
626	253	71	330TOKENS	KU-0000	1	159	0	159
627	253	76	Party Membership	KU-0000	1	159	0	159
641	250	246	2479 โอปอล	KU-000	1	869	0	869
642	242	248	8606 โอปอล	KU-000	1	2829	0	2829
644	121	23	2525VP	KU-0005	1	630	0	630
655	111	93	1850WC	KU-0000	1	340	0	340
656	110	96	4800WC	KU-0000	1	800	0	800
657	109	4	(ROSE) 6650WC	KU-0000	1	1119	0	1119
658	108	103	30000WC	KU-0000	1	4820	0	4820
659	107	95	3275WC	KU-0000	1	570	0	570
661	106	107	320 เหรียญ	KU-0000	1	35	0	35
663	104	93	1850WC	KU-0000	1	340	0	340
664	103	90	425WC	KU-0000	1	89	0	89
666	102	93	1850WC	KU-0000	1	340	0	340
667	101	96	4800WC	KU-0000	1	800	0	800
669	100	96	4800WC	KU-0000	1	800	0	800
672	97	91	1000WC	KU-0000	1	190	0	190
674	95	95	3275WC	KU-0000	1	570	0	570
676	93	95	3275WC	KU-0000	1	570	0	570
678	91	100	10000WC	KU-0000	1	1620	0	1620
680	89	54	สัญญาขั้นสูง (DELUXE)	KU-0035	1	139	0	139
681	88	230	500LATT	KU-0000	1	150	0	150
82	10	76	Party Membership	KU-0000	1	159	0	159
83	10	77	Party Permanent VIP	KU-0000	1	419	0	419
84	9	145	(FF) BP Card	KU-0000	1	89	0	89
85	11	113	3500 เหรียญ	KU-0000	1	209	0	209
86	12	22	2050VP	KU-0004	1	505	0	505
87	13	63	159BAHT ($4.99)	KU-0000	2	139	0	278
88	13	64	329BAHT ($9.99)	KU-0000	3	275	0	825
89	14	65	479BAHT ($14.49)	KU-0000	3	379	0	1137
90	14	66	669BAHT ($19.99)	KU-0000	1	539	0	539
91	15	102	20000WC	KU-0000	1	3220	0	3220
92	16	113	3500 เหรียญ	KU-0000	1	209	0	209
97	18	68	1590BAHT ($46.99)	KU-0000	1	1269	0	1269
98	19	93	1850WC	KU-0000	1	340	0	340
99	20	30	6825VP	KU-0012	1	1640	0	1640
191	17	12	199 BAHT (4.99$)	KU-0000	1	149	0	149
193	23	93	1850WC	KU-0000	1	340	0	340
196	24	146	110 ปอง	KU-0000	1	89	0	89
197	25	113	3500 เหรียญ	KU-0000	1	209	0	209
198	26	68	1590BAHT ($46.99)	KU-0000	1	1269	0	1269
199	27	46	735GEMS	KU-0027	1	269	0	269
201	28	146	110 ปอง	KU-0000	1	89	0	89
202	28	152	620 ปอง	KU-0000	1	489	0	489
203	30	163	257 เพชร	KU-0000	1	119	0	119
684	85	183	660UC	KU-0000	1	319	0	319
685	84	14	499 BAHT (14.99$)	KU-0000	2	419	0	838
686	83	174	1380TFT	KU-0000	1	239	0	239
881	302	90	425WC	KU-0000	2	89	0	178
1364	464	71	330TOKENS	KU-0000	1	159	0	159
1365	464	72	1110TOKENS	KU-0000	1	419	0	419
554	137	238	แบทเทิลพาส (all)	KU-0000	1	239	0	239
1366	463	93	1850WC	KU-0000	1	339	0	339
692	258	46	735GEMS	KU-0027	1	269	0	269
693	257	243	[2525VP] DEATHWISH ปืนแยก	KU-0000	1	625	0	625
905	322	113	3500 เหรียญ	KU-0000	1	209	0	209
906	321	91	1000WC	KU-0000	1	189	0	189
967	349	229	100LATT	KU-0000	1	30	0	30
968	349	230	500LATT	KU-0000	1	150	0	150
969	348	113	3500 เหรียญ	KU-0000	1	209	0	209
555	140	6	(ROSE) 10000WC	KU-0000	1	1590	0	1590
556	139	30	6825VP	KU-0012	1	1640	0	1640
970	347	85	499BAHT (14.99$)	KU-0000	1	429	0	429
971	346	64	329BAHT ($9.99)	KU-0000	1	275	0	275
557	139	34	11000VP	KU-0016	1	2535	0	2535
558	138	113	3500 เหรียญ	KU-0000	1	209	0	209
972	345	78	Premium Pass	KU-0000	2	169	0	338
973	344	115	7000 เหรียญ	KU-0000	1	349	0	349
974	343	91	1000WC	KU-0000	1	189	0	189
559	136	1	(ROSE) 3275WC	KU-0000	1	559	0	559
560	135	6	(ROSE) 10000WC	KU-0000	1	1590	0	1590
565	130	2	(ROSE) 4800WC	KU-0000	1	789	0	789
566	129	150	185 ปอง	KU-0000	1	149	0	149
567	129	153	1240 ปอง	KU-0000	1	975	0	975
1062	386	96	4800WC	KU-0000	1	800	0	800
1063	385	29	6350VP	KU-0011	1	1515	0	1515
1064	384	258	Phantasium Pass (30 วัน)	KU-0000	1	149	0	149
1066	383	247	4245 โอปอล	KU-000	1	1429	0	1429
1067	382	271	149 BAHT (3.99$)	KU-0000	1	119	0	119
1068	381	270	[7875VP] CHAMP2025 เหมาพาส	KU-0000	1	1889	0	1889
1069	380	25	3650VP	KU-0007	1	885	0	885
1070	379	93	1850WC	KU-0000	1	339	0	339
600	232	76	Party Membership	KU-0000	1	159	0	159
601	231	112	1920 เหรียญ	KU-0000	1	199	0	199
602	230	243	[2525VP] DEATHWISH ปืนแยก	KU-0000	1	625	0	625
603	229	2	(ROSE) 4800WC	KU-0000	1	789	0	789
607	226	93	1850WC	KU-0000	1	340	0	340
1071	378	91	1000WC	KU-0000	1	189	0	189
1072	377	270	[7875VP] CHAMP2025 เหมาพาส	KU-0000	1	1889	0	1889
1073	376	102	20000WC	KU-0000	1	3139	0	3139
1074	375	77	Party Permanent VIP	KU-0000	1	419	0	419
448	214	90	425WC	KU-0000	1	89	0	89
449	214	91	1000WC	KU-0000	1	190	0	190
455	209	91	1000WC	KU-0000	1	190	0	190
456	208	111	1600 เหรียญ	KU-0000	1	169	0	169
508	225	27	5350VP	KU-0009	1	1269	0	1269
509	224	113	3500 เหรียญ	KU-0000	1	209	0	209
510	223	76	Party Membership	KU-0000	1	159	0	159
511	222	113	3500 เหรียญ	KU-0000	1	209	0	209
516	172	1	(ROSE) 3275WC	KU-0000	1	559	0	559
517	173	154	1860 ปอง	KU-0000	1	1469	0	1469
525	167	233	2180LATT	KU-0000	1	575	0	575
528	163	91	1000WC	KU-0000	1	190	0	190
529	162	113	3500 เหรียญ	KU-0000	1	209	0	209
541	152	91	1000WC	KU-0000	1	190	0	190
543	150	91	1000WC	KU-0000	1	190	0	190
545	149	57	MPCOMBO	KU-0038	1	619	0	619
546	148	1	(ROSE) 3275WC	KU-0000	1	559	0	559
547	147	220	8100DELTA	KU-0000	1	2490	0	2490
548	146	8	(ROSE) 50000WC	KU-0000	1	7879	0	7879
628	252	76	Party Membership	KU-0000	1	159	0	159
629	251	22	2050VP	KU-0004	1	505	0	505
630	249	174	1380TFT	KU-0000	1	239	0	239
631	248	107	320 เหรียญ	KU-0000	1	35	0	35
632	247	110	1280 เหรียญ	KU-0000	1	129	0	129
633	246	113	3500 เหรียญ	KU-0000	1	209	0	209
634	245	110	1280 เหรียญ	KU-0000	1	129	0	129
635	244	107	320 เหรียญ	KU-0000	1	35	0	35
636	243	240	[8750VP] DEATHWISH เหมาหมด	KU-0000	1	2129	0	2129
637	241	1	(ROSE) 3275WC	KU-0000	1	559	0	559
638	240	1	(ROSE) 3275WC	KU-0000	1	559	0	559
639	239	90	425WC	KU-0000	1	89	0	89
640	238	6	(ROSE) 10000WC	KU-0000	1	1590	0	1590
643	122	153	1240 ปอง	KU-0000	1	975	0	975
645	120	4	(ROSE) 6650WC	KU-0000	1	1119	0	1119
646	119	7	(ROSE) 30000WC	KU-0000	1	4749	0	4749
647	118	2	(ROSE) 4800WC	KU-0000	1	789	0	789
648	117	5	(ROSE) 8075WC	KU-0000	1	1359	0	1359
649	116	6	(ROSE) 10000WC	KU-0000	1	1590	0	1590
650	115	6	(ROSE) 10000WC	KU-0000	1	1590	0	1590
651	114	4	(ROSE) 6650WC	KU-0000	1	1119	0	1119
652	113	6	(ROSE) 10000WC	KU-0000	1	1590	0	1590
654	112	34	11000VP	KU-0016	1	2535	0	2535
662	105	96	4800WC	KU-0000	1	800	0	800
670	99	93	1850WC	KU-0000	1	340	0	340
671	98	95	3275WC	KU-0000	1	570	0	570
673	96	93	1850WC	KU-0000	1	340	0	340
675	94	95	3275WC	KU-0000	1	570	0	570
677	92	100	10000WC	KU-0000	1	1620	0	1620
679	90	22	2050VP	KU-0004	1	505	0	505
444	217	78	Premium Pass	KU-0000	1	169	0	169
445	217	87	999BAHT (29.99$)	KU-0000	1	849	0	849
561	134	77	Party Permanent VIP	KU-0000	1	419	0	419
450	216	79	Extra Premium Pass	KU-0000	1	279	0	279
451	213	79	Extra Premium Pass	KU-0000	1	279	0	279
457	207	78	Premium Pass	KU-0000	1	169	0	169
568	128	78	Premium Pass	KU-0000	1	169	0	169
459	206	113	3500 เหรียญ	KU-0000	1	209	0	209
460	205	108	640 เหรียญ	KU-0000	1	69	0	69
461	204	113	3500 เหรียญ	KU-0000	1	209	0	209
882	301	76	Party Membership	KU-0000	1	159	0	159
883	300	6	(ROSE) 10000WC	KU-0000	1	1590	0	1590
884	299	107	320 เหรียญ	KU-0000	1	35	0	35
1083	368	48	1470GEMS	KU-0029	1	529	0	529
886	298	1	(ROSE) 3275WC	KU-0000	1	559	0	559
1094	354	113	3500 เหรียญ	KU-0000	1	209	0	209
907	320	93	1850WC	KU-0000	1	339	0	339
908	319	98	6650WC	KU-0000	1	1119	0	1119
357	31	93	1850WC	KU-0000	1	340	0	340
909	318	105	STELLACORN	KU-0000	1	89	0	89
910	317	96	4800WC	KU-0000	1	800	0	800
911	316	113	3500 เหรียญ	KU-0000	1	209	0	209
912	315	80	Rookie Pack	KU-0000	1	99	0	99
913	314	100	10000WC	KU-0000	1	1590	0	1590
945	340	46	735GEMS	KU-0027	1	269	0	269
952	335	95	3275WC	KU-0000	1	569	0	569
953	334	96	4800WC	KU-0000	1	800	0	800
954	333	24	4650VP	KU-0008	1	1135	0	1135
955	332	115	7000 เหรียญ	KU-0000	1	349	0	349
956	331	115	7000 เหรียญ	KU-0000	1	349	0	349
975	342	86	699BAHT (19.99$)	KU-0000	1	559	0	559
976	341	235	5680LATT	KU-0000	1	1399	0	1399
1095	353	86	699BAHT (19.99$)	KU-0000	1	559	0	559
1367	462	90	425WC	KU-0000	1	89	0	89
1381	447	146	110 ปอง	KU-0000	1	89	0	89
1382	447	150	185 ปอง	KU-0000	1	149	0	149
1383	446	193	8080SHARD	KU-0000	1	2420	0	2420
1096	352	47	1050GEMS	KU-0028	1	369	0	369
1384	445	270	[7875VP] CHAMP2025 เหมาพาส	KU-0000	1	1889	0	1889
378	35	107	320 เหรียญ	KU-0000	1	35	0	35
379	36	107	320 เหรียญ	KU-0000	1	35	0	35
380	45	112	1920 เหรียญ	KU-0000	1	199	0	199
382	46	175	2800TFT	KU-0000	1	459	0	459
385	202	175	2800TFT	KU-0000	1	459	0	459
386	201	1	(ROSE) 3275WC	KU-0000	1	559	0	559
387	200	13	399 BAHT (9.99$)	KU-0000	1	289	0	289
389	203	233	2180LATT	KU-0000	1	575	0	575
570	127	76	Party Membership	KU-0000	1	159	0	159
391	198	76	Party Membership	KU-0000	1	159	0	159
392	199	22	2050VP	KU-0004	1	505	0	505
393	197	112	1920 เหรียญ	KU-0000	1	199	0	199
394	196	20	1000VP	KU-0002	1	250	0	250
395	195	176	4500TFT	KU-0000	1	759	0	759
397	193	105	STELLACORN	KU-0000	1	89	0	89
512	221	196	บัตรกำนัลเสบียงรถไฟ	KU-0000	1	139	0	139
399	194	91	1000WC	KU-0000	1	190	0	190
400	192	6	(ROSE) 10000WC	KU-0000	1	1590	0	1590
513	220	237	69 โอปอล	KU-000	1	33	0	33
514	219	19	475VP	KU-0001	1	125	0	125
403	191	175	2800TFT	KU-0000	1	459	0	459
404	191	177	6500TFT	KU-0000	1	1099	0	1099
518	171	153	1240 ปอง	KU-0000	1	975	0	975
406	190	1	(ROSE) 3275WC	KU-0000	1	559	0	559
407	189	174	1380TFT	KU-0000	1	239	0	239
408	189	177	6500TFT	KU-0000	1	1099	0	1099
409	188	34	11000VP	KU-0016	1	2535	0	2535
519	170	93	1850WC	KU-0000	1	340	0	340
520	169	91	1000WC	KU-0000	1	190	0	190
412	187	193	8080SHARD	KU-0000	1	2420	0	2420
413	186	193	8080SHARD	KU-0000	1	2420	0	2420
414	185	1	(ROSE) 3275WC	KU-0000	1	559	0	559
415	184	113	3500 เหรียญ	KU-0000	1	209	0	209
416	183	91	1000WC	KU-0000	1	190	0	190
417	182	186	3850UC	KU-0000	1	1489	0	1489
418	181	147	121 ปอง	KU-0000	1	102	0	102
419	180	22	2050VP	KU-0004	1	505	0	505
420	179	52	รายสัปดาห์ (WEEKLY)	KU-0033	1	29	0	29
526	165	78	Premium Pass	KU-0000	1	169	0	169
422	178	93	1850WC	KU-0000	1	340	0	340
423	177	93	1850WC	KU-0000	1	340	0	340
530	161	3	(ROSE) 5225WC	KU-0000	1	889	0	889
425	176	1	(ROSE) 3275WC	KU-0000	1	559	0	559
426	175	22	2050VP	KU-0004	1	505	0	505
427	174	1	(ROSE) 3275WC	KU-0000	1	559	0	559
531	160	91	1000WC	KU-0000	2	190	0	380
532	159	178	13500TFT	KU-0000	1	2119	0	2119
533	158	178	13500TFT	KU-0000	1	2119	0	2119
593	235	6	(ROSE) 10000WC	KU-0000	1	1590	0	1590
594	237	3	(ROSE) 5225WC	KU-0000	1	889	0	889
595	236	107	320 เหรียญ	KU-0000	1	35	0	35
596	234	25	3650VP	KU-0007	1	885	0	885
598	233	240	[8750VP] DEATHWISH เหมาหมด	KU-0000	1	2129	0	2129
604	228	105	STELLACORN	KU-0000	1	89	0	89
605	228	2	(ROSE) 4800WC	KU-0000	1	789	0	789
1125	401	271	149 BAHT (3.99$)	KU-0000	1	119	0	119
1126	401	12	199 BAHT (4.99$)	KU-0000	1	149	0	149
1127	401	268	299 BAHT (7.99$)	KU-0000	1	239	0	239
1134	396	93	1850WC	KU-0000	1	339	0	339
1368	461	93	1850WC	KU-0000	1	339	0	339
888	297	6	(ROSE) 10000WC	KU-0000	1	1590	0	1590
1369	460	229	100LATT	KU-0000	1	30	0	30
1370	459	282	พรแห่งดวงจันทร์	KU-0000	1	139	0	139
1371	459	196	บัตรกำนัลเสบียงรถไฟ	KU-0000	1	139	0	139
1372	458	233	2180LATT	KU-0000	1	575	0	575
1373	457	234	2680LATT	KU-0000	1	735	0	735
1374	456	95	3275WC	KU-0000	1	569	0	569
1375	455	236	11600LATT	KU-0000	1	2759	0	2759
722	283	79	Extra Premium Pass	KU-0000	1	279	0	279
723	282	66	669BAHT ($19.99)	KU-0000	1	539	0	539
724	281	20	1000VP	KU-0002	1	250	0	250
725	280	6	(ROSE) 10000WC	KU-0000	1	1590	0	1590
726	279	71	330TOKENS	KU-0000	1	159	0	159
727	278	76	Party Membership	KU-0000	1	159	0	159
728	277	2	(ROSE) 4800WC	KU-0000	1	789	0	789
729	276	176	4500TFT	KU-0000	1	749	0	749
730	275	71	330TOKENS	KU-0000	1	159	0	159
731	274	78	Premium Pass	KU-0000	1	169	0	169
732	273	55	สัญญาพิเศษ (PREMIUM)	KU-0036	1	249	0	249
733	272	243	[2525VP] DEATHWISH ปืนแยก	KU-0000	1	625	0	625
734	271	109	960 เหรียญ	KU-0000	1	105	0	105
946	339	97	5225WC	KU-0000	1	889	0	889
947	338	86	699BAHT (19.99$)	KU-0000	1	559	0	559
745	292	6	(ROSE) 10000WC	KU-0000	1	1590	0	1590
746	291	6	(ROSE) 10000WC	KU-0000	1	1590	0	1590
747	290	42	74GEMS	KU-0023	1	29	0	29
748	289	72	1110TOKENS	KU-0000	1	419	0	419
749	288	71	330TOKENS	KU-0000	1	159	0	159
750	287	259	680+70 Jewels	KU-000	1	335	0	335
751	286	73	2280TOKENS	KU-0000	1	899	0	899
752	284	174	1380TFT	KU-0000	1	239	0	239
753	270	20	1000VP	KU-0002	1	250	0	250
754	269	25	3650VP	KU-0007	1	885	0	885
755	268	90	425WC	KU-0000	1	89	0	89
756	268	91	1000WC	KU-0000	1	190	0	190
757	267	113	3500 เหรียญ	KU-0000	1	209	0	209
758	266	78	Premium Pass	KU-0000	1	169	0	169
759	265	123	68 เพชร	KU-0000	1	24	0	24
760	264	113	3500 เหรียญ	KU-0000	1	209	0	209
761	263	124	172 เพชร	KU-0000	1	49	0	49
763	262	34	11000VP	KU-0016	1	2535	0	2535
766	261	220	8100DELTA	KU-0000	1	2490	0	2490
767	260	193	8080SHARD	KU-0000	1	2420	0	2420
769	259	193	8080SHARD	KU-0000	1	2420	0	2420
770	256	76	Party Membership	KU-0000	1	159	0	159
771	255	76	Party Membership	KU-0000	1	159	0	159
772	254	174	1380TFT	KU-0000	1	239	0	239
773	82	151	370 ปอง	KU-0000	1	296	0	296
776	80	91	1000WC	KU-0000	1	190	0	190
778	79	79	Extra Premium Pass	KU-0000	1	279	0	279
779	81	202	80TOKENS	KU-0000	1	33	0	33
780	75	113	3500 เหรียญ	KU-0000	1	209	0	209
781	78	76	Party Membership	KU-0000	1	159	0	159
782	77	76	Party Membership	KU-0000	1	159	0	159
783	76	51	6930GEMS	KU-0032	2	2359	0	4718
784	74	110	1280 เหรียญ	KU-0000	1	129	0	129
785	73	114	3820 เหรียญ	KU-0000	1	239	0	239
786	72	193	8080SHARD	KU-0000	1	2420	0	2420
787	71	47	1050GEMS	KU-0028	1	369	0	369
788	70	34	11000VP	KU-0016	1	2535	0	2535
789	69	95	3275WC	KU-0000	1	570	0	570
791	68	165	2195 เพชร	KU-0000	1	929	0	929
792	67	186	3850UC	KU-0000	1	1489	0	1489
793	66	55	สัญญาพิเศษ (PREMIUM)	KU-0036	1	249	0	249
806	65	95	3275WC	KU-0000	1	570	0	570
808	64	78	Premium Pass	KU-0000	1	169	0	169
809	63	91	1000WC	KU-0000	1	190	0	190
810	62	107	320 เหรียญ	KU-0000	1	35	0	35
811	61	110	1280 เหรียญ	KU-0000	1	129	0	129
812	60	126	517 เพชร	KU-0000	1	149	0	149
813	59	126	517 เพชร	KU-0000	1	149	0	149
814	58	127	690 เพชร	KU-0000	1	199	0	199
815	57	76	Party Membership	KU-0000	1	159	0	159
816	56	90	425WC	KU-0000	1	89	0	89
817	55	113	3500 เหรียญ	KU-0000	1	209	0	209
818	54	76	Party Membership	KU-0000	1	159	0	159
819	53	70	60TOKENS	KU-0000	1	29	0	29
820	52	115	7000 เหรียญ	KU-0000	1	349	0	349
821	51	141	24 ปอง	KU-0000	1	24	0	24
822	50	174	1380TFT	KU-0000	1	239	0	239
823	49	100	10000WC	KU-0000	1	1620	0	1620
824	48	53	รายเดือน (MONTHLY)	KU-0034	1	65	0	65
825	47	113	3500 เหรียญ	KU-0000	1	209	0	209
826	44	72	1110TOKENS	KU-0000	1	419	0	419
827	43	78	Premium Pass	KU-0000	1	169	0	169
828	43	76	Party Membership	KU-0000	1	159	0	159
829	42	49	2205GEMS	KU-0030	1	769	0	769
830	41	50	3570GEMS	KU-0031	1	1239	0	1239
831	41	172	(ECU) 2690BAHT	KU-0000	1	2139	0	2139
832	40	127	690 เพชร	KU-0000	1	199	0	199
833	39	30	6825VP	KU-0012	1	1640	0	1640
835	37	19	475VP	KU-0001	1	125	0	125
836	34	66	669BAHT ($19.99)	KU-0000	1	539	0	539
837	34	67	999BAHT ($29.49)	KU-0000	2	789	0	1578
838	33	161	86 เพชร	KU-0000	1	45	0	45
839	32	76	Party Membership	KU-0000	1	159	0	159
840	32	78	Premium Pass	KU-0000	1	169	0	169
841	32	75	8110TOKENS	KU-0000	1	2519	0	2519
842	29	45	368GEMS	KU-0026	1	139	0	139
843	38	149	170 ปอง	KU-0000	1	139	0	139
1084	367	230	500LATT	KU-0000	1	150	0	150
1085	362	233	2180LATT	KU-0000	1	575	0	575
1086	361	262	330 Monochrome	KU-0000	1	129	0	129
1087	361	263	1090 Monochrome	KU-0000	1	389	0	389
1088	360	51	6930GEMS	KU-0032	1	2359	0	2359
1089	359	76	Party Membership	KU-0000	1	159	0	159
1090	358	269	300 Jewels	KU-0000	1	159	0	159
1091	357	243	[2525VP] DEATHWISH ปืนแยก	KU-0000	1	625	0	625
1092	356	115	7000 เหรียญ	KU-0000	1	349	0	349
1093	355	243	[2525VP] DEATHWISH ปืนแยก	KU-0000	1	625	0	625
1097	351	268	299 BAHT (7.99$)	KU-0000	1	239	0	239
1376	452	272	[6700VP] CHAMP2025 เหมาหมด	KU-0000	1	1635	0	1635
1099	350	174	1380TFT	KU-0000	1	239	0	239
1377	451	22	2050VP	KU-0004	1	505	0	505
1380	448	151	370 ปอง	KU-0000	1	296	0	296
889	296	1	(ROSE) 3275WC	KU-0000	1	559	0	559
861	313	113	3500 เหรียญ	KU-0000	1	209	0	209
890	295	94	2275WC	KU-0000	1	429	0	429
892	294	1	(ROSE) 3275WC	KU-0000	1	559	0	559
893	293	6	(ROSE) 10000WC	KU-0000	1	1590	0	1590
904	323	243	[2525VP] DEATHWISH ปืนแยก	KU-0000	1	625	0	625
924	330	76	Party Membership	KU-0000	1	159	0	159
925	330	79	Extra Premium Pass	KU-0000	1	279	0	279
926	329	53	รายเดือน (MONTHLY)	KU-0034	1	65	0	65
927	328	96	4800WC	KU-0000	1	800	0	800
928	327	243	[2525VP] DEATHWISH ปืนแยก	KU-0000	1	625	0	625
929	326	225	1700 ROBUX	KU-0000	1	590	0	590
930	325	90	425WC	KU-0000	1	89	0	89
931	325	95	3275WC	KU-0000	1	569	0	569
932	324	91	1000WC	KU-0000	1	189	0	189
948	337	121	33 เพชร	KU-0000	1	12	0	12
949	337	125	310 เพชร	KU-0000	1	89	0	89
950	336	126	517 เพชร	KU-0000	1	149	0	149
1129	402	96	4800WC	KU-0000	1	800	0	800
1130	400	93	1850WC	KU-0000	1	339	0	339
1131	399	108	640 เหรียญ	KU-0000	1	69	0	69
1030	392	272	[6700VP] CHAMP2025 เหมาหมด	KU-0000	1	1635	0	1635
1132	398	79	Extra Premium Pass	KU-0000	1	279	0	279
1133	397	91	1000WC	KU-0000	1	189	0	189
1033	391	21	1475VP	KU-0003	1	375	0	375
1034	393	97	5225WC	KU-0000	1	889	0	889
1135	395	95	3275WC	KU-0000	1	569	0	569
1142	408	78	Premium Pass	KU-0000	1	169	0	169
1143	407	113	3500 เหรียญ	KU-0000	1	209	0	209
1144	406	96	4800WC	KU-0000	1	800	0	800
1145	405	91	1000WC	KU-0000	1	189	0	189
1146	404	95	3275WC	KU-0000	1	569	0	569
1147	403	275	BP กิตติคุณ 9.99$	KU-0000	1	310	0	310
1058	390	274	[3050VP] CHAMP2025 ปืนแยก	KU-0000	1	750	0	750
1059	389	151	370 ปอง	KU-0000	1	296	0	296
1060	388	22	2050VP	KU-0004	1	505	0	505
1061	387	30	6825VP	KU-0012	2	1640	0	3280
1075	394	174	1380TFT	KU-0000	1	239	0	239
1076	374	90	425WC	KU-0000	1	89	0	89
1077	373	76	Party Membership	KU-0000	1	159	0	159
1078	373	78	Premium Pass	KU-0000	1	169	0	169
1173	429	272	[6700VP] CHAMP2025 เหมาหมด	KU-0000	1	1635	0	1635
1174	428	110	1280 เหรียญ	KU-0000	1	129	0	129
1175	427	76	Party Membership	KU-0000	1	159	0	159
1176	426	113	3500 เหรียญ	KU-0000	1	209	0	209
1177	425	96	4800WC	KU-0000	1	800	0	800
1178	424	96	4800WC	KU-0000	1	800	0	800
1180	423	96	4800WC	KU-0000	1	800	0	800
1181	422	93	1850WC	KU-0000	1	339	0	339
1182	421	229	100LATT	KU-0000	1	30	0	30
1183	421	231	1000LATT	KU-0000	1	283	0	283
1184	420	113	3500 เหรียญ	KU-0000	1	209	0	209
1185	419	151	370 ปอง	KU-0000	1	296	0	296
1186	418	197	บัตรกำนัลเสบียงรถไฟ (2x)	KU-0000	1	278	0	278
1187	417	76	Party Membership	KU-0000	2	159	0	318
1188	416	78	Premium Pass	KU-0000	1	169	0	169
1189	415	223	400 ROBUX	KU-0000	1	155	0	155
1190	415	225	1700 ROBUX	KU-0000	1	615	0	615
1191	414	21	1475VP	KU-0003	1	375	0	375
1192	413	86	699BAHT (19.99$)	KU-0000	1	559	0	559
1193	412	109	960 เหรียญ	KU-0000	1	105	0	105
1194	411	44	221GEMS	KU-0025	1	86	0	86
1195	410	274	[3050VP] CHAMP2025 ปืนแยก	KU-0000	1	750	0	750
1196	409	95	3275WC	KU-0000	1	569	0	569
1199	430	22	2050VP	KU-0004	1	505	0	505
1205	435	178	13500TFT	KU-0000	1	2049	0	2049
1206	434	272	[6700VP] CHAMP2025 เหมาหมด	KU-0000	1	1635	0	1635
1207	433	174	1380TFT	KU-0000	1	239	0	239
1208	432	19	475VP	KU-0001	1	125	0	125
1209	431	113	3500 เหรียญ	KU-0000	1	209	0	209
1378	450	110	1280 เหรียญ	KU-0000	1	129	0	129
1379	449	146	110 ปอง	KU-0000	1	89	0	89
1220	444	93	1850WC	KU-0000	1	339	0	339
1221	443	183	660UC	KU-0000	1	319	0	319
1222	442	91	1000WC	KU-0000	1	189	0	189
1223	441	114	3820 เหรียญ	KU-0000	1	239	0	239
1224	440	96	4800WC	KU-0000	1	800	0	800
1225	439	95	3275WC	KU-0000	1	569	0	569
1226	438	91	1000WC	KU-0000	2	189	0	378
1227	437	173	575TFT	KU-0000	1	119	0	119
1229	436	178	13500TFT	KU-0000	1	2049	0	2049
1398	512	90	425WC	KU-0000	1	89	0	89
1399	511	293	249BAHT (6.99$)	KU-0000	1	185	0	185
1415	521	196	บัตรกำนัลเสบียงรถไฟ	KU-0000	1	139	0	139
1416	520	291	149BAHT (3.99$)	KU-0000	1	119	0	119
1417	520	293	249BAHT (6.99$)	KU-0000	1	185	0	185
1418	520	294	349BAHT (9.99$)	KU-0000	1	285	0	285
1419	519	247	4245 โอปอล	KU-000	1	1429	0	1429
1420	518	296	1100BAHT (29.99$)	KU-0000	1	800	0	800
1421	518	291	149BAHT (3.99$)	KU-0000	2	119	0	238
1422	518	293	249BAHT (6.99$)	KU-0000	1	185	0	185
1423	517	295	729BAHT (19.99$)	KU-0000	1	525	0	525
1424	516	289	35BAHT (0.99$)	KU-0000	1	28	0	28
1425	516	293	249BAHT (6.99$)	KU-0000	1	185	0	185
1426	516	294	349BAHT (9.99$)	KU-0000	1	285	0	285
1427	515	229	100LATT	KU-0000	1	30	0	30
1428	514	294	349BAHT (9.99$)	KU-0000	1	285	0	285
1429	513	276	BP เหรียญตรา 19.99$	KU-0000	1	620	0	620
1430	510	91	1000WC	KU-0000	1	189	0	189
1431	509	22	2050VP	KU-0004	1	505	0	505
1432	508	294	349BAHT (9.99$)	KU-0000	1	285	0	285
1433	507	76	Party Membership	KU-0000	1	159	0	159
1434	506	297	1150BAHT (31.99$)	KU-0000	1	835	0	835
1435	505	298	[8750VP] PRELUDE 2.0 เหมาหมด	KU-0000	1	2129	0	2129
1436	504	32	8400VP	KU-0014	1	2020	0	2020
1437	503	298	[8750VP] PRELUDE 2.0 เหมาหมด	KU-0000	1	2129	0	2129
1438	502	91	1000WC	KU-0000	1	189	0	189
1439	501	291	149BAHT (3.99$)	KU-0000	1	119	0	119
1440	501	294	349BAHT (9.99$)	KU-0000	1	285	0	285
1442	522	295	729BAHT (19.99$)	KU-0000	1	515	0	515
1443	523	183	660UC	KU-0000	1	319	0	319
1444	524	95	3275WC	KU-0000	1	569	0	569
1445	525	20	1000VP	KU-0002	1	250	0	250
1446	526	76	Party Membership	KU-0000	1	159	0	159
1309	500	297	1150BAHT (31.99$)	KU-0000	2	835	0	1670
1310	499	294	349BAHT (9.99$)	KU-0000	2	285	0	570
1311	499	295	729BAHT (19.99$)	KU-0000	2	525	0	1050
1313	498	71	330TOKENS	KU-0000	1	159	0	159
1315	497	71	330TOKENS	KU-0000	1	159	0	159
1316	496	289	35BAHT (0.99$)	KU-0000	1	28	0	28
1317	496	290	69BAHT (1.99$)	KU-0000	1	55	0	55
1318	496	291	149BAHT (3.99$)	KU-0000	1	119	0	119
1319	496	290	69BAHT (1.99$)	KU-0000	1	55	0	55
1320	496	291	149BAHT (3.99$)	KU-0000	1	119	0	119
1321	496	292	179BAHT (4.99$)	KU-0000	1	135	0	135
1322	496	291	149BAHT (3.99$)	KU-0000	1	119	0	119
1323	496	294	349BAHT (9.99$)	KU-0000	1	285	0	285
1324	496	295	729BAHT (19.99$)	KU-0000	1	525	0	525
1325	496	296	1100BAHT (29.99$)	KU-0000	1	800	0	800
1326	495	291	1x 149BAHT (3.99$)	KU-0000	1	119	0	119
1327	495	294	1x 349BAHT (9.99$)	KU-0000	1	285	0	285
1328	495	295	1x 729BAHT (19.99$)	KU-0000	1	525	0	525
1329	494	233	2180LATT	KU-0000	1	575	0	575
1330	493	230	500LATT	KU-0000	1	150	0	150
1331	492	289	1x 35BAHT (0.99$)	KU-0000	1	28	0	28
1332	492	293	1x 249BAHT (6.99$)	KU-0000	1	185	0	185
1333	492	295	1x 729BAHT (19.99$)	KU-0000	1	525	0	525
1334	492	290	1x 69BAHT (1.99$)	KU-0000	1	55	0	55
1335	492	294	1x 349BAHT (9.99$)	KU-0000	1	285	0	285
1336	492	292	1x 179BAHT (4.99$)	KU-0000	1	135	0	135
1337	491	95	3275WC	KU-0000	1	569	0	569
1338	490	106	CELESTIAL	KU-0000	1	569	0	569
1339	489	91	1000WC	KU-0000	1	189	0	189
1340	487	71	330TOKENS	KU-0000	1	159	0	159
1341	486	90	425WC	KU-0000	1	89	0	89
1342	485	247	4245 โอปอล	KU-000	1	1429	0	1429
1343	484	248	8606 โอปอล	KU-000	1	2829	0	2829
1344	483	125	310 เพชร	KU-0000	1	89	0	89
1345	483	128	1052 เพชร	KU-0000	1	295	0	295
1346	482	125	310 เพชร	KU-0000	1	89	0	89
1347	481	92	1425WC	KU-0000	1	278	0	278
1348	480	95	3275WC	KU-0000	1	569	0	569
1349	479	176	4500TFT	KU-0000	1	739	0	739
1350	478	175	2800TFT	KU-0000	1	439	0	439
1351	478	178	13500TFT	KU-0000	1	2049	0	2049
1352	477	93	1850WC	KU-0000	1	339	0	339
1353	476	76	Party Membership	KU-0000	1	159	0	159
1354	475	78	Premium Pass	KU-0000	1	169	0	169
1355	474	97	5225WC	KU-0000	1	889	0	889
1356	473	34	11000VP	KU-0016	1	2535	0	2535
1357	472	95	3275WC	KU-0000	1	569	0	569
1358	471	223	400 ROBUX	KU-0000	1	155	0	155
1359	468	272	[6700VP] CHAMP2025 เหมาหมด	KU-0000	1	1635	0	1635
1360	467	182	325UC	KU-0000	1	149	0	149
1362	466	91	1000WC	KU-0000	1	189	0	189
1363	465	71	330TOKENS	KU-0000	1	159	0	159
1447	527	174	1380TFT	KU-0000	1	239	0	239
1448	528	270	[7875VP] CHAMP2025 เหมาพาส	KU-0000	1	1889	0	1889
1461	529	230	500LATT	KU-0000	1	150	0	150
1462	530	220	8100DELTA	KU-0000	1	2490	0	2490
1463	531	91	1000WC	KU-0000	1	189	0	189
1464	532	272	[6700VP] CHAMP2025 เหมาหมด	KU-0000	1	1635	0	1635
1465	533	63	159BAHT ($4.99)	KU-0000	1	139	0	139
1466	533	55	สัญญาพิเศษ (PREMIUM)	KU-0036	1	249	0	249
1467	534	63	159BAHT ($4.99)	KU-0000	1	139	0	139
1468	534	55	สัญญาพิเศษ (PREMIUM)	KU-0036	1	249	0	249
1469	535	49	2205GEMS	KU-0030	1	769	0	769
1472	538	195	เหมาทุกแพ็ค (ยกเว้นเสบียง)	KU-0000	1	4840	0	4840
1477	537	294	349BAHT (9.99$)	KU-0000	1	275	0	275
1478	537	295	729BAHT (19.99$)	KU-0000	1	515	0	515
1479	539	23	2525VP	KU-0005	1	630	0	630
1482	541	13	399 BAHT (9.99$)	KU-0000	1	289	0	289
1483	542	296	1100BAHT (29.99$)	KU-0000	1	790	0	790
1506	563	68	1590BAHT ($46.99)	KU-0000	1	1269	0	1269
1507	562	63	159BAHT ($4.99)	KU-0000	1	139	0	139
1508	561	75	8110TOKENS	KU-0000	1	2519	0	2519
1509	560	93	1850WC	KU-0000	1	339	0	339
1510	559	78	Premium Pass	KU-0000	1	169	0	169
1511	558	78	Premium Pass	KU-0000	1	169	0	169
1512	557	193	8080SHARD	KU-0000	1	2290	0	2290
1513	550	298	[8750VP] PRELUDE 2.0 เหมาหมด	KU-0000	1	2129	0	2129
1514	550	272	[6700VP] CHAMP2025 เหมาหมด	KU-0000	1	1635	0	1635
1515	549	78	Premium Pass	KU-0000	1	169	0	169
1516	548	76	Party Membership	KU-0000	1	159	0	159
1517	547	54	สัญญาขั้นสูง (DELUXE)	KU-0035	1	139	0	139
1518	546	272	[6700VP] CHAMP2025 เหมาหมด	KU-0000	1	1635	0	1635
1519	545	193	8080SHARD	KU-0000	1	2290	0	2290
1520	544	193	8080SHARD	KU-0000	1	2290	0	2290
1521	543	163	257 เพชร	KU-0000	1	119	0	119
\.


--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.orders (id, order_number, order_date, platform, customer_name, game_name, total_paid, payment_proof_url, sales_proof_url, product_code, package_count, packages_text, cost, profit, status, operator, topup_channel, note, created_at) FROM stdin;
451	ODR-20250914-3976	2025-09-14 05:02:29+00	FACEBOOK	นัฐสิทธิ์ สุขอิ่ม	VALORANT	505	https://drive.google.com/uc?id=1EAnqqjNaeIQNvqYdZmqdCDcWQoOSqoCW	https://drive.google.com/uc?id=1-Qa5X5rF0fm8C1e2ozVGy_sOYoQlVCAa	\N	1	2050VP x1	481	24	รายการสำเร็จ	เกรซ	RICHMAN		2025-09-14 15:52:34.302922+00
10	ODR-20250814-8835	2025-07-31 17:20:00+00	LINE	NS.01	DUNK_DYNASTY	578	https://drive.google.com/uc?id=15oWr3dlaHBholiA3_Egt4NO0SQRLtwEi	https://drive.google.com/uc?id=1TdCM4uOuBNKc1O2djE1KLF7lgwh0F9Ak	\N	2	Party Membership x1, Party Permanent VIP x1	510.57	67.43	รายการสำเร็จ	เกรซ	RAZERGOLD		2025-08-14 12:15:17.326551+00
11	ODR-20250814-6254	2025-08-01 03:44:00+00	FACEBOOK	Pathapeekan Otasan	MINECRAFT	209	https://drive.google.com/uc?id=1-8hVnyhJaRp8bZGFM7H6amuX5ZLTJKpF	https://drive.google.com/uc?id=1-scKA2179qM3OK8cKE5u7OenSm5nqfuX	\N	1	3500 เหรียญ x1	56.87	152.13	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-14 12:21:46.605948+00
12	ODR-20250814-8426	2025-08-01 04:02:00+00	FACEBOOK	ดุ๊บฮยอน ครายฟอหมี	VALORANT	505	https://drive.google.com/uc?id=13DiJE162cjV79oeESOsq4f_-Fezu-L9C	https://drive.google.com/uc?id=1kcf_AuPvxClZw1DHxysKsh3mjjfYUSR7	\N	1	2050VP x1	481	24	รายการสำเร็จ	เกรซ	RICHMAN		2025-08-14 12:22:47.958392+00
13	ODR-20250814-8944	2025-08-01 06:45:00+00	LINE	T.	RACING (LOGIN)	1103	https://drive.google.com/uc?id=131C9-WI0HzFPHsN6xGmucz8MQBITR8Xo	https://drive.google.com/uc?id=1DrWtRiVr5gq-aM_6Fj-8bd-_61mTYyyw	\N	5	159BAHT ($4.99) x2, 329BAHT ($9.99) x3	937.47	165.53	รายการสำเร็จ	เกรซ	RAZERGOLD		2025-08-14 12:24:15.617319+00
14	ODR-20250814-7574	2025-08-01 07:08:00+00	LINE	T.	RACING (LOGIN)	1676	https://drive.google.com/uc?id=1QoahHJIeEJ6k71w-Xik7-N-d3Rvponw_	https://drive.google.com/uc?id=1WH5Oe3Qqp3JJQ4YWdrZnvQF4Ffg3jOJH	\N	4	479BAHT ($14.49) x3, 669BAHT ($19.99) x1	1456.1	219.9	รายการสำเร็จ	เกรซ	RAZERGOLD		2025-08-14 12:26:36.61457+00
15	ODR-20250814-9194	2025-08-01 07:46:00+00	FACEBOOK	Keng Phattarapon	LOL_WILDRIFT	3220	https://drive.google.com/uc?id=1mREjmtJpQaYCJN_fKSaXAt35afAoAJ-j	https://drive.google.com/uc?id=1RvlJ9uhZ2COxqxnUxabXA15Ojw-ZjgzV	\N	1	20000WC x1	2762.42	457.58	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-14 12:27:42.520482+00
16	ODR-20250814-3687	2025-08-01 09:02:00+00	LINE	RR♡	MINECRAFT	209	https://drive.google.com/uc?id=1DCYv6Mb9qWxzjx2SEKiKIo2X4IDPRJpU	https://drive.google.com/uc?id=1uzp5cMUjpaFmJVZJWRK1Bd_XLNhpODcF	\N	1	3500 เหรียญ x1	56.87	152.13	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-14 12:53:30.770561+00
18	ODR-20250814-6367	2025-08-01 11:07:00+00	LINE	T.	RACING (LOGIN)	1269	https://drive.google.com/uc?id=1xAmbmh1i7UMW3RZHUVxX1kxO1rgE_ZZc	https://drive.google.com/uc?id=1rCbDCZt4sOGk7Zw7jVPXpxNbWMzdjjBD	\N	1	1590BAHT ($46.99) x1	1125.77	143.23	รายการสำเร็จ	เกรซ	RAZERGOLD		2025-08-14 12:56:15.287568+00
24	ODR-20250814-6691	2025-08-01 14:14:00+00	FACEBOOK	Ponlawqt Ninnoi	ROV_MOBILE	89	https://drive.google.com/uc?id=1K1FZME3k8E9_QJelPBnAmeE74QrTW2Zm	https://drive.google.com/uc?id=1Ntknuk_Y9qD4SQ2SdRFtL3e1PBFtqYcO	\N	1	110 ปอง x1	85	4	รายการสำเร็จ	เกรซ	RICHMAN		2025-08-14 15:32:59.308446+00
20	ODR-20250814-4164	2025-08-01 11:28:00+00	FACEBOOK	สรพัศ พลคชา	VALORANT	1640	https://drive.google.com/uc?id=1qovQyljvMiFjLD4mkXA8TdioU6DMXofW	https://drive.google.com/uc?id=1jCbMT9n5sXV2C296VcdkgDsl81O5oZFA	\N	1	6825VP x1	1581.8	58.2	รายการสำเร็จ	เกรซ	RICHMAN		2025-08-14 12:59:53.861526+00
22	ODR-20250814-7219	2025-08-01 11:43:00+00	LINE	T.	RACING (LOGIN)	539	https://drive.google.com/uc?id=1rWh6HTk_tjVCiKurSxRXMx7LGl_NtVi8	https://drive.google.com/uc?id=1_1csvcgx7eC02PZpfi2HeOeeoSYFp3Hz	\N	1	669BAHT ($19.99) x1	464.03	74.97	รายการสำเร็จ	เกรซ	RAZERGOLD		2025-08-14 13:02:22.983246+00
23	ODR-20250814-8300	2025-08-01 05:17:00+00	LINE	Siwapol Burithat	LOL_WILDRIFT	340	https://drive.google.com/uc?id=19RNTa4pS8ikxXSyEfk2mKW_kxrYz6LFG	https://drive.google.com/uc?id=1sOenxGUwFuwaKKl5y9Il8PpZyRCiLll-	\N	1	1850WC x1	276.24	63.76	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-14 13:03:43.596436+00
25	ODR-20250814-2650	2025-08-01 15:03:00+00	FACEBOOK	ณัฐพงษ์ แย้มสุวรรณ	MINECRAFT	209	https://drive.google.com/uc?id=13-KTZ5EyPRB0qcB3Jjy9Qixta_qLpqgk	https://drive.google.com/uc?id=1NBtit_5D3GTPmKTbVcEEvrTJSB6tET2L	\N	1	3500 เหรียญ x1	56.87	152.13	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-14 15:35:05.333267+00
26	ODR-20250814-2391	2025-08-01 15:08:00+00	FACEBOOK	Apirak Pamai	RACING (LOGIN)	1269	https://drive.google.com/uc?id=1K6urWgEpX9Kwe-tXHZNMNVeBebvb3Weu	https://drive.google.com/uc?id=1aUsi-F1ENzg4tER5HVsCnofnbkee-mvP	\N	1	1590BAHT ($46.99) x1	1125.77	143.23	รายการสำเร็จ	เกรซ	RAZERGOLD		2025-08-14 15:35:55.909233+00
38	ODR-20250814-4138	2025-08-02 08:15:00+00	FACEBOOK	Chalerm Phon	ROV_MOBILE	139	https://drive.google.com/uc?id=1k1lpsn77IAv8aT6V6MLyQpMFDijH6wUv	https://drive.google.com/uc?id=1Qw626lAB8Q-QZuMYQgP6ZUUDrH-Wdf6Q	\N	1	170 ปอง x1	132	7	แก้ไขรายการ	แทน	RICHMAN	ลูกค้าชำระเงินครั้งแรกไม่ครบ ชำระมา 2 ครั้ง 130+9	2025-08-14 16:21:58.410535+00
30	ODR-20250814-9381	2025-08-01 16:53:00+00	LINE	Daeng Noy	MOBILE_LEGENDS	119	https://drive.google.com/uc?id=1cTor2zGfcD9ZqKBI_AFYQZgc5FW1GLsP	https://drive.google.com/uc?id=1VZ90jJNbhWYASVFyv_JYZIu6v1mWdf3T	\N	1	257 เพชร x1	109	10	รายการสำเร็จ	เกรซ	RICHMAN		2025-08-14 15:40:37.857772+00
31	ODR-20250814-9162	2025-08-01 17:23:00+00	FACEBOOK	Nvmmxn Raungsuparut	LOL_WILDRIFT	340	https://drive.google.com/uc?id=1lMHP52XXKuJojs7NAz1w4VBeSaJV3ixo	https://drive.google.com/uc?id=1Rwbekqlzry4CcUZNZhYg3CcRkq1VppNP	\N	1	1850WC x1	276.24	63.76	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-14 16:14:00.977147+00
29	ODR-20250814-4266	2025-08-01 16:14:00+00	FACEBOOK	Apirak Pamai	RACING_MASTER	139	https://drive.google.com/uc?id=1Mh1H_I_eUeTWOVaD2R9nn-DgfN2MeZ5F	https://drive.google.com/uc?id=1Lwpu8VbQ-as5X1yVOPqCIX7QQcO0Asw2	\N	1	368GEMS x1	117.28	21.72	รายการสำเร็จ	เกรซ	RAZERGOLD	4.36*26.90	2025-08-14 15:38:12.600943+00
36	ODR-20250814-4898	2025-08-02 05:38:00+00	FACEBOOK	Pathapeekan Otasan	MINECRAFT	35	https://drive.google.com/uc?id=1PLiibIIi0c1rrNyGEoC5SQfwXxpLW0sM	https://drive.google.com/uc?id=1KjHnuyCjCJRksH9HkNl5eai3t7CJmaUC	\N	1	320 เหรียญ x1	5.7	29.3	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-14 16:19:01.933794+00
40	ODR-20250814-4270	2025-08-02 10:43:00+00	FACEBOOK	Peem Sittikorn	FREEFIRE	199	https://drive.google.com/uc?id=1vLn3OHfnhzz6tDAYoyVYXYsyKXaN5c-Z	https://drive.google.com/uc?id=1DR5YwnhTAa45kOCNRORYP-duSjZGq6Wu	\N	1	690 เพชร x1	190	9	รายการสำเร็จ	เกรซ	RICHMAN		2025-08-14 16:23:58.760034+00
33	ODR-20250814-5464	2025-08-02 04:23:31+00	LINE	Daeng Noy	MOBILE_LEGENDS	45	https://drive.google.com/uc?id=1AUGC9dDHxO5V1nz-d9k7JUveJQ_EShIK	https://drive.google.com/uc?id=1YlrBIlDuFNdFgC8nOiL7_i0_XAL2-Z6U	\N	1	86 เพชร x1	40	5	รายการสำเร็จ	เกรซ	RICHMAN		2025-08-14 16:16:29.220197+00
9	ODR-20250814-1962	2025-07-31 17:04:00+00	FACEBOOK	Nuttanicha Chaipakde	FREEFIRE	89	https://drive.google.com/uc?id=1hdI_Mu-GHJXbMmAhtlO4PtnyLhjzMUmv	https://drive.google.com/uc?id=1DJb-cDtFDohemrUiZ5dsjXOvVbhzzVDZ	\N	1	(FF) BP Card x1	85	4	รายการสำเร็จ	เกรซ	24BUYM		2025-08-14 12:12:54.716484+00
19	ODR-20250814-1496	2025-08-01 11:17:00+00	FACEBOOK	Aphichai Buacharoen	LOL_WILDRIFT	340	https://drive.google.com/uc?id=1c_QpZLqC-sDO5SFsUkaAXivPZhlR2iIW	https://drive.google.com/uc?id=13dDeweHf2jG5kcSwkZnTOiFoAVRfSPA5	\N	1	1850WC x1	276.24	63.76	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-14 12:57:21.82714+00
21	ODR-20250814-5504	2025-08-01 11:43:00+00	FACEBOOK	Suticha Makkhuntod	RACING_MASTER	2359	https://drive.google.com/uc?id=1h1hK-rXaBevgTJ7cxOrMd49yyOeglZUP	https://drive.google.com/uc?id=1NhH9MzpXHFY5ITBKhF3ygPXS4phxZDXw	\N	1	6930GEMS x1	2295.65	63.35	รายการสำเร็จ	เกรซ	RAZERGOLD		2025-08-14 13:01:31.447055+00
69	ODR-20250816-6372	2025-08-05 11:49:24+00	LINE	D E W🕊	LOL_WILDRIFT	570.01	https://drive.google.com/uc?id=15OoCHYNENsG6jbcyLBzuIBJbRunx1EFe	https://drive.google.com/uc?id=1oZaCau97HFHmMxTLiz21Qrfm7tHeflRx	\N	1	3275WC x1	468.16	101.85	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-16 07:14:31.459119+00
45	ODR-20250815-8808	2025-08-02 15:33:00+00	FACEBOOK	Tassu Good Time	MINECRAFT	199	https://drive.google.com/uc?id=1IZ16jTZBgRO7XqKmx0mh8yiR-DWMtlsW	https://drive.google.com/uc?id=1Mzuz5YjEsTJ5fm1vhhQXVZBpUb_EoYJS	\N	1	1920 เหรียญ x1	34.2	164.8	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-15 07:40:09.735834+00
61	ODR-20250815-6436	2025-08-04 11:00:53+00	FACEBOOK	Natakron Suknit	MINECRAFT	129	https://drive.google.com/uc?id=10MxncgQDCmL6C18y8FriPSimY8qhQcrb	https://drive.google.com/uc?id=1RCVvGhB4klEPeZktRNV7GJysQZ_vGbih	\N	1	1280 เหรียญ x1	22.8	106.2	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-15 11:59:41.267727+00
56	ODR-20250815-8999	2025-08-03 17:21:00+00	FACEBOOK	Thanapat Beer	LOL_WILDRIFT	89	https://drive.google.com/uc?id=10PWbnoeP70Y2L1xV-1hRaM71uTDmicq1	https://drive.google.com/uc?id=1dpiT5ql8wn4oU6F8aMDhHd5I0QRMUouh	\N	1	425WC x1	69.31	19.69	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-15 11:52:33.545531+00
55	ODR-20250815-5071	2025-08-03 12:46:58+00	FACEBOOK	Khamin Somboonpan	MINECRAFT	209	https://drive.google.com/uc?id=1hzCYVbmP0Y3ykBvnIJWjWV_RGRxVnlRw	https://drive.google.com/uc?id=13GCSP9nbJOlxaOqD1RvqRcRJQsPXyII-	\N	1	3500 เหรียญ x1	57.07	151.93	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-15 11:50:53.390311+00
53	ODR-20250815-3131	2025-08-03 08:48:33+00	FACEBOOK	Tnp Gaming	DUNK_DYNASTY	29	https://drive.google.com/uc?id=1AnQ5zxVnF7ywDiRTCdwhIhwfusBFp7D3	https://drive.google.com/uc?id=1JAahlPFcAu6ToHS2aoC7PNIuD4PDaRBx	\N	1	60TOKENS x1	22.93	6.07	รายการสำเร็จ	เกรซ	RAZERGOLD	0.84*27.30	2025-08-15 11:49:21.602139+00
63	ODR-20250815-2656	2025-08-04 15:08:37+00	LINE	💪boss🕴♂🍃 246	LOL_WILDRIFT	190	https://drive.google.com/uc?id=1vG-GZo2MyerGCyYRW4YiqYXtQ5HX6QYv	https://drive.google.com/uc?id=1QJcLcogXo83Kec-EIANq6TjFrkwPJlAk	\N	1	1000WC x1	154.92	35.08	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-15 12:03:02.149438+00
67	ODR-20250816-5781	2025-08-05 06:20:57+00	FACEBOOK	ۦ hoshi	PUBG_MOBILE	1469	https://drive.google.com/uc?id=1Xl82ftonSf3LWxKxuBwUB-Zr66Im1Tau	https://drive.google.com/uc?id=1Lk0NbmARRqTDed-NItR4j7kaUVB7c_yY	\N	1	3850UC x1	1470	-1	รายการสำเร็จ	แทน	24BUYM		2025-08-16 07:08:48.577842+00
41	ODR-20250815-9547	2025-08-02 12:11:00+00	LINE	T.	RACING (LOGIN)	3378	https://drive.google.com/uc?id=1lWVU8b1rYCoyUhrOc2LuuXRLiTq2t7Xu	https://drive.google.com/uc?id=1_8o6VwgFHmcnBnh5O5AxiGVtXHT8feo1	\N	2	3570GEMS x1, (ECU) 2690BAHT x1	3031.95	346.05	รายการสำเร็จ	เกรซ	RAZERGOLD	111.88*27.10	2025-08-15 07:35:48.195983+00
43	ODR-20250815-9703	2025-08-02 14:09:39+00	FACEBOOK	AchiAchi Boonleab	DUNK_DYNASTY	328	https://drive.google.com/uc?id=1O6Y7NxO0ArXy78eQOAoQ2hGTi91VGarC	https://drive.google.com/uc?id=1wETm2_1C-wxFUsdaRK3Hc5FsYaBZxAC3	\N	2	Premium Pass x1, Party Membership x1	262.06	65.94	รายการสำเร็จ	เกรซ	RAZERGOLD	9.67*27.10	2025-08-15 07:38:15.300163+00
51	ODR-20250815-9886	2025-08-03 07:17:17+00	FACEBOOK	Chalerm Phon	ROV_MOBILE	24	https://drive.google.com/uc?id=14NCnBy_yXXFFBshDFvHOnjf1oWep9Atp	https://drive.google.com/uc?id=1Re727qHduswkWaHueW3KbEIFVfu5c1HH	\N	1	24 ปอง x1	19	5	รายการสำเร็จ	แทน	RICHMAN		2025-08-15 11:46:54.186348+00
50	ODR-20250815-9229	2025-08-03 07:10:00+00	LINE	Armm	TFT_MOBILE	239.01	https://drive.google.com/uc?id=1KKIYRwcKGZ3wrAp2qCbwQPB9Z1-buZ3j	https://drive.google.com/uc?id=1t8DaDLdqBsmFqyl9-7UirnFJlfhc8vLM	\N	1	1380TFT x1	203.84	35.17	รายการสำเร็จ	แทน	YOUTRIP		2025-08-15 11:46:09.392831+00
48	ODR-20250815-3353	2025-08-02 17:35:25+00	FACEBOOK	Thanapat Sansanor	RACING_MASTER	65	https://drive.google.com/uc?id=184nXOYj2dzjRrVTMYATqDsi8mdkneI3D	https://drive.google.com/uc?id=1eXNUYQ6s5mBfU9ciIeh1QAjim8S5zXuU	\N	1	รายเดือน (MONTHLY) x1	53.7	11.3	รายการสำเร็จ	แทน	RAZERGOLD	1.96*27.40	2025-08-15 11:42:40.732564+00
47	ODR-20250815-3069	2025-08-02 17:18:57+00	LINE	ป้อ	MINECRAFT	209.1	https://drive.google.com/uc?id=1HxKyFjmHSOmtCc1tCAWGpF2xDMakYUk5	https://drive.google.com/uc?id=1qA1fPMuB4p8pRHvqqaO5o5Tx4cbIMSt-	\N	1	3500 เหรียญ x1	57.7	151.4	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-15 11:41:28.475129+00
60	ODR-20250815-2307	2025-08-04 07:39:41+00	LINE	wuttichai_132	FREEFIRE	149	https://drive.google.com/uc?id=1TMwpqt_LsbHeJphlve4I-Hwu8raHpK-_	https://drive.google.com/uc?id=1vFmYRYAv4jqekSjfuXwQrph548-qnFy_	\N	1	517 เพชร x1	141	8	รายการสำเร็จ	เกรซ	24BUYM		2025-08-15 11:58:02.158311+00
58	ODR-20250815-7664	2025-08-04 05:21:00+00	FACEBOOK	Peem Sittikorn	FREEFIRE	199	https://drive.google.com/uc?id=1daBLG0tc7zR_h8z_CHqWcPg_qOePLsMa	https://drive.google.com/uc?id=1hi0JogKU1LMZ_37wSUDyoMKH23Ev2G9a	\N	1	690 เพชร x1	188	11	รายการสำเร็จ	เกรซ	24BUYM		2025-08-15 11:55:15.972651+00
66	ODR-20250815-6527	2025-08-05 04:46:15+00	FACEBOOK	จักรวาล สาปลั่ง	RACING_MASTER	249	https://drive.google.com/uc?id=1MhLXiRAyUDZA3CvpKujIlVudOW2Grr_J	https://drive.google.com/uc?id=1WhrdwQ34cVeh5-WXnwut-cetYMBqqDIG	\N	1	สัญญาพิเศษ (PREMIUM) x1	224.39	24.61	รายการสำเร็จ	เกรซ	RAZERGOLD	8.28*27.10	2025-08-15 12:06:11.928941+00
64	ODR-20250815-3675	2025-08-05 04:24:43+00	FACEBOOK	Axt Pnppl	DUNK_DYNASTY	169	https://drive.google.com/uc?id=1nB8Y96xZJZ1zylyzE7GhVCoWdYm2WRfv	https://drive.google.com/uc?id=1rWEM2mWCIRvkRbrgBMjVjub1oMaiqQ32	\N	1	Premium Pass x1	141.19	27.81	รายการสำเร็จ	เกรซ	RAZERGOLD	5.21*27.10	2025-08-15 12:04:15.16718+00
70	ODR-20250816-2378	2025-08-05 12:52:12+00	FACEBOOK	Sarunwath Chanthajohn	VALORANT	2536	https://drive.google.com/uc?id=1bu-iFH4yTQ2VGJoFf9kGaJfk5TEOVxun	https://drive.google.com/uc?id=1z1Oyhw-XKbbJ07HId70-l1VzOsyRr5Ny	\N	1	11000VP x1	2442	94	รายการสำเร็จ	เกรซ	RICHMAN		2025-08-16 07:16:47.426163+00
17	ODR-20250814-8173	2025-08-01 09:20:00+00	FACEBOOK	Kaopun Tangchutaveesub	(ID-PASS) เติมได้หลายเกม	149	https://drive.google.com/uc?id=1ORsg9O1HHAvT_W9Pvkm7ontIY1VZxkY4	https://drive.google.com/uc?id=1qUn_HpJ2ApgcbfsgQF_qGiN8CM38PGFy	\N	1	199 BAHT (4.99$) x1	124.25	24.75	รายการสำเร็จ	เกรซ	ITUNES		2025-08-14 12:54:47.396494+00
27	ODR-20250814-4823	2025-08-01 16:02:00+00	FACEBOOK	Apirak Pamai	RACING_MASTER	269	https://drive.google.com/uc?id=17llRHtmKcbSdi9tg0ge4xpyFgqqO2zvc	https://drive.google.com/uc?id=1e17IzcbTaiocpVnZ2xP3hE5UpuhJQb0a	\N	1	735GEMS x1	234.3	34.7	รายการสำเร็จ	เกรซ	RAZERGOLD		2025-08-14 15:36:45.322722+00
28	ODR-20250814-3532	2025-08-01 16:04:00+00	FACEBOOK	Thanaphat Chakainta	ROV_MOBILE	578	https://drive.google.com/uc?id=1YErheaRfEC_QE5nxLtKcxqkVVNnDOOdc	https://drive.google.com/uc?id=1VfnZK_JK3Z_bneOg7MPbePsaDmltHvs0	\N	2	110 ปอง x1, 620 ปอง x1	555	23	รายการสำเร็จ	แทน	RICHMAN		2025-08-14 15:37:36.709089+00
82	ODR-20250816-4241	2025-08-07 10:42:00+00	FACEBOOK	タナ トー ン	ROV_MOBILE	296	https://drive.google.com/uc?id=1VH0-c8J-c9leXyNNlgH55dD3_efeiK-d	https://drive.google.com/uc?id=1b1kL2C7KBUepOaL3mllMJucKXxIj1Qn0	\N	1	370 ปอง x1	282	14	รายการสำเร็จ	เกรซ	RICHMAN		2025-08-16 07:45:27.101978+00
79	ODR-20250816-1534	2025-08-06 19:48:31+00	FACEBOOK	Peeradech Rungsiri	DUNK_DYNASTY	279	https://drive.google.com/uc?id=1RZ9U0nR9rnX1K6pp-blNy4tOpwCdUfsI	https://drive.google.com/uc?id=1n3G-P7VFMBI2HX20MercE2_QwYusnKau	\N	1	Extra Premium Pass x1	235.23	43.77	รายการสำเร็จ	เกรซ	RAZERGOLD	8.68*27.10	2025-08-16 07:30:19.082118+00
81	ODR-20250816-7871	2025-08-07 05:19:15+00	FACEBOOK	โนว ซิ	HOK (GLOBAL)	33	https://drive.google.com/uc?id=1-fjJODodis0XOrHnHM0NL6hXLoQkGRH3	https://drive.google.com/uc?id=1JM8kLgXt8MMufZMTLlyJavAXEvWmpTzh	\N	1	80TOKENS x1	31	2	รายการสำเร็จ	เกรซ	RICHMAN		2025-08-16 07:44:15.178558+00
78	ODR-20250816-9905	2025-08-06 14:20:39+00	FACEBOOK	Worawit Chainaranon	DUNK_DYNASTY	159	https://drive.google.com/uc?id=1YFT6iKsPibgRiQ-0d0HoVCvakw9FaUSd	https://drive.google.com/uc?id=1UDTDUaaR5c6oK2WeYq9n5-ZMhZTSz3fY	\N	1	Party Membership x1	125.74	33.26	รายการสำเร็จ	แทน	RAZERGOLD	4.64*27.10	2025-08-16 07:27:42.643286+00
77	ODR-20250816-3354	2025-08-06 14:15:19+00	FACEBOOK	Worawit Chainaranon	DUNK_DYNASTY	159	https://drive.google.com/uc?id=1Y5jgcHzH5PfJjDQ303ZcSX4q7-Na8Etd	https://drive.google.com/uc?id=1jzl0ZgWBW8601FkJrDyF8tHQ_TJLgGx-	\N	1	Party Membership x1	125.74	33.26	รายการสำเร็จ	แทน	RAZERGOLD	4.64*27.10	2025-08-16 07:27:02.031986+00
86	ODR-20250817-6494	2025-08-08 11:48:40+00	LINE	🌺 ONOSAN 小野 🌺	MARVEL_RIVALS	1390	https://drive.google.com/uc?id=1yrEvgj7tkbgjfaIe6oEjmh9LEOV_hqD7	https://drive.google.com/uc?id=1g9ct-3RnIDuBd69RgFJhByh8ItlZaM1t	\N	1	5680LATT x1	1313	77	รายการสำเร็จ	แทน	24BUYM		2025-08-17 17:01:05.924339+00
85	ODR-20250817-7354	2025-08-08 09:18:00+00	FACEBOOK	มิลิน เมนเทล	PUBG_MOBILE	319	https://drive.google.com/uc?id=1EwRbHzUrvFgREYx72N0wiyPhNPJ3Eviq	https://drive.google.com/uc?id=1l5LulNXblZwZOdpAReQifQPaOA_MMJSh	\N	1	660UC x1	276.96	42.04	รายการสำเร็จ	แทน	RAZERGOLD	10.22*27.10	2025-08-17 16:58:34.100479+00
83	ODR-20250816-7795	2025-08-07 19:04:06+00	FACEBOOK	Kaopun Tangchutaveesub	TFT_MOBILE	239	https://drive.google.com/uc?id=123oO5H1vGA1kJsQ1IQj3AA_kjkYQY_HW	https://drive.google.com/uc?id=1rRrb1gDAIYouB2Dn2R0tVES0K2Rkm5_L	\N	1	1380TFT x1	200.72	38.28	รายการสำเร็จ	แทน	YOUTRIP		2025-08-16 07:48:53.423662+00
88	ODR-20250817-3156	2025-08-08 16:45:17+00	FACEBOOK	Pasit Title	MARVEL_RIVALS	150	https://drive.google.com/uc?id=1dtI1e_5UhTCk0GrENhodbXi8cJFxpNLV	https://drive.google.com/uc?id=1NzQH014dVFEdpWTEOUfYAPkR1oxg29I5	\N	1	500LATT x1	131	19	รายการสำเร็จ	เกรซ	24BUYM		2025-08-17 17:07:17.011811+00
91	ODR-20250817-7866	2025-08-09 00:32:37+00	LINE	pp.sttv	LOL_WILDRIFT	1620	https://drive.google.com/uc?id=1eZa4m39KXhmN8haWwmP8SVhz4__03VHt	https://drive.google.com/uc?id=1IQZ-DHQ-OJDxEpJjSb0ADhZhv44gV7RX	\N	1	10000WC x1	1365.86	254.14	รายการสำเร็จ	แทน	YOUTRIP		2025-08-17 17:12:03.080611+00
74	ODR-20250816-2827	2025-08-06 05:31:57+00	FACEBOOK	Natchaya Janbundit	MINECRAFT	129	https://drive.google.com/uc?id=14T1mR5YelKq0cmNVp76ImiMVJdp-p-m6	https://drive.google.com/uc?id=1b8QhyswOSyDOcCdJrU8JQjchdOey72MR	\N	1	1280 เหรียญ x1	22.48	106.52	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-16 07:23:50.409961+00
73	ODR-20250816-8647	2025-08-06 05:07:53+00	FACEBOOK	Kook Supakron	MINECRAFT	239	https://drive.google.com/uc?id=1UbxQsZLk2x9dDq5SXOW0ly6s2xFbRRfo	https://drive.google.com/uc?id=1QBzRntBPbIpbfdd_M3BwKDUMiKUBsLwI	\N	1	3820 เหรียญ x1	61.94	177.06	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-16 07:22:48.316449+00
71	ODR-20250816-3796	2025-08-05 14:10:27+00	FACEBOOK	Konchanok Milintrakas	RACING_MASTER	369	https://drive.google.com/uc?id=1tlFsQJ9sapjAZ95e8VLl5TuQC6IeS3CV	https://drive.google.com/uc?id=12k9tpETEFkgg09R5EWtwodMM4vHVTtb0	\N	1	1050GEMS x1	339.83	29.17	รายการสำเร็จ	เกรซ	RAZERGOLD	12.54*27.10	2025-08-16 07:17:55.496327+00
99	ODR-20250817-8524	2025-08-09 03:17:05+00	FACEBOOK	Pull-up Everyday	LOL_WILDRIFT	340	https://drive.google.com/uc?id=1AWDaRwqs1rmF3hn7RywYKPBLureZx_96	https://drive.google.com/uc?id=1Na3BeNtb9PYz_maqiKqN0e4pUAounthU	\N	1	1850WC x1	273.17	66.83	รายการสำเร็จ	แทน	YOUTRIP		2025-08-17 17:22:38.152522+00
98	ODR-20250817-6065	2025-08-09 02:29:22+00	FACEBOOK	Tacho Wasan	LOL_WILDRIFT	570	https://drive.google.com/uc?id=1fNwyTGSKXxUwBzOKujBsQkNk-XY1hPwS	https://drive.google.com/uc?id=1jyUmQNQ6eBE0J4DFnVPeuWsbf2nApTNT	\N	1	3275WC x1	466	104	รายการสำเร็จ	แทน	YOUTRIP		2025-08-17 17:20:51.798833+00
96	ODR-20250817-8557	2025-08-09 01:56:44+00	FACEBOOK	Sumet Tongyong	LOL_WILDRIFT	340	https://drive.google.com/uc?id=1OihSEjxqPCZK6j2BQ3kp6FWvx39bM7e2	https://drive.google.com/uc?id=18ePLiCBpTYPuNQr9VSt8mzcVl_LDK9g6	\N	1	1850WC x1	273.17	66.83	รายการสำเร็จ	แทน	YOUTRIP		2025-08-17 17:18:39.278412+00
94	ODR-20250817-1677	2025-08-09 01:46:55+00	FACEBOOK	Nattapoom Saranarth	LOL_WILDRIFT	570.01	https://drive.google.com/uc?id=1KRC7AA9ZA9_vHRQg0rx6IQbMIjSvOela	https://drive.google.com/uc?id=1_Ux2Xzd7LsSGA6SQO5OCqFVXMWybbgIB	\N	1	3275WC x1	466	104.01	รายการสำเร็จ	แทน	YOUTRIP		2025-08-17 17:14:52.840044+00
93	ODR-20250817-2696	2025-08-09 01:20:01+00	FACEBOOK	Nattapoom Saranarth	LOL_WILDRIFT	570.01	https://drive.google.com/uc?id=1iHenrEfb_RQkB8UzrOJfu7_kNgYjb-HR	https://drive.google.com/uc?id=1_NbkZMZctSJtmzHrjWO9r-xKHOZi66Hc	\N	1	3275WC x1	466	104.01	รายการสำเร็จ	แทน	YOUTRIP		2025-08-17 17:14:07.725391+00
89	ODR-20250817-9685	2025-08-08 23:12:00+00	FACEBOOK	Ammarin Roonkate	RACING_MASTER	139	https://drive.google.com/uc?id=1OWYf381C4ne_mpYG7LqT7ZYPb9vAYG0H	https://drive.google.com/uc?id=1w6t0WLih1fP55oaP4iPEhvGycdBAYSXX	\N	1	สัญญาขั้นสูง (DELUXE) x1	121.14	17.86	รายการสำเร็จ	แทน	RAZERGOLD	4.47*27.10	2025-08-17 17:09:44.650637+00
121	ODR-20250817-6200	2025-08-09 16:24:59+00	FACEBOOK	แฟ้มไง ไม่ต้องถาม	VALORANT	630	https://drive.google.com/uc?id=1UFJ-86T12YF463y0DpQBf3POkg3H0fPh	https://drive.google.com/uc?id=10aD5AZ-xsQwyQjk6UUtNtPnQE2iNbC9f	\N	1	2525VP x1	601.3	28.7	รายการสำเร็จ	เกรซ	RICHMAN		2025-08-17 17:45:33.550688+00
132	ODR-20250818-6105	2025-08-10 12:18:24+00	FACEBOOK	Inla Gust Punnawat	(🌹) LOL_WILDRIFT	889	https://drive.google.com/uc?id=1AggTto8oKsBCBmzoHEtqfGrHriVpl9ZH	https://drive.google.com/uc?id=1IwljYDpLjAAb76EmhZqKOVLz1xpLUeyk	\N	1	(ROSE) 5225WC x1	731.13	157.87	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 17:29:48.387216+00
134	ODR-20250818-8206	2025-08-10 14:22:45+00	FACEBOOK	Peeradech Rungsiri	DUNK_DYNASTY	419	https://drive.google.com/uc?id=1L9VNlAw23R2sBALTbh3dQfOa32Y4eUdg	https://drive.google.com/uc?id=1ZxwvYhTEuv6gqwLnxwJ_zs4Zt3AgPaKo	\N	1	Party Permanent VIP x1	375.63	43.37	รายการสำเร็จ	เกรซ	RAZERGOLD	13.99*26.85	2025-08-18 17:32:46.408273+00
131	ODR-20250818-6630	2025-08-10 08:14:07+00	FACEBOOK	Chawin Lerdsiwapon	LOL_WILDRIFT	340.07	https://drive.google.com/uc?id=1noJaWFHzN6esW54Gt-hB5nS2IH-xyOJK	https://drive.google.com/uc?id=1qnbL-uZin-5w7WcnmLZt72qWq5lddMsl	\N	1	1850WC x1	273.17	66.9	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 17:28:53.896175+00
129	ODR-20250818-4698	2025-08-10 04:42:51+00	LINE	ᵂ	ROV_MOBILE	1124	https://drive.google.com/uc?id=1Nam-lPuuZ6akFX-Z_VlGhXYpQ99qdHXn	https://drive.google.com/uc?id=1RwU8rDVZiXKBeJRQpHDsQthapcAhzHYb	\N	2	185 ปอง x1, 1240 ปอง x1	1081	43	รายการสำเร็จ	เกรซ	RICHMAN		2025-08-18 17:27:02.113859+00
128	ODR-20250818-6556	2025-08-10 03:26:38+00	FACEBOOK	Phakhamongkhon Konghom	DUNK_DYNASTY	169	https://drive.google.com/uc?id=1o1VJp8yDzSlymAs7gDab-f3-eX130Kpt	https://drive.google.com/uc?id=1PTxIshx6lX87IsseKQmLn4pZCINSCPzd	\N	1	Premium Pass x1	142	27	รายการสำเร็จ	แทน	RAZERGOLD	5.24*27.10	2025-08-18 17:26:01.106233+00
126	ODR-20250818-4927	2025-08-10 00:35:22+00	FACEBOOK	Max Jessada	(🌹) LOL_WILDRIFT	789	https://drive.google.com/uc?id=1KYedNAApc1iMYJpyCVvAHiTYO-6iXKJE	https://drive.google.com/uc?id=1YeQfdwCAuOFd3NYdOa9Ugz9-J_yjT9ja	\N	1	(ROSE) 4800WC x1	662.84	126.16	รายการสำเร็จ	แทน	YOUTRIP		2025-08-18 17:24:03.297506+00
125	ODR-20250818-4646	2025-08-09 23:58:48+00	FACEBOOK	Chawanil Wilaingam	MINECRAFT	209	https://drive.google.com/uc?id=1-dsffiA4puBaCUwG7LwGQdtogZ5d3fic	https://drive.google.com/uc?id=1gqbGlYV8ShGwentW6MmLvNLjo1Vgc8cf	\N	1	3500 เหรียญ x1	56.23	152.77	รายการสำเร็จ	แทน	YOUTRIP		2025-08-18 17:22:51.515217+00
123	ODR-20250818-7685	2025-08-09 18:35:55+00	FACEBOOK	Tachin Doungjinda	VALORANT	250	https://drive.google.com/uc?id=1URc37oJ8TcFx9zGSZb6eHYitfJ8rs80B	https://drive.google.com/uc?id=1euwvc5hlVdg0Jwv5QS_uBJrsrbGPeNQM	\N	1	1000VP x1	240.5	9.5	รายการสำเร็จ	แทน	RICHMAN		2025-08-18 17:20:42.538282+00
120	ODR-20250817-1284	2025-08-09 14:13:05+00	FACEBOOK	Yiw Kimhun	(🌹) LOL_WILDRIFT	1119	https://drive.google.com/uc?id=1obeTS5cBMA9_XcItym_gmOgM25mRK5pe	https://drive.google.com/uc?id=14xXmzAtojQM9fFzVWjM8ZonXD0lUxOBH	\N	1	(ROSE) 6650WC x1	936.01	182.99	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-17 17:44:40.80805+00
118	ODR-20250817-5720	2025-08-09 11:46:40+00	FACEBOOK	Aing Kawintra	(🌹) LOL_WILDRIFT	789	https://drive.google.com/uc?id=1f-ervVsSOUqNGYSPR7z8jjd-sHSWnhk0	https://drive.google.com/uc?id=1jRNazbbh8_iKo55jPvWFR1Y3X6T44ycE	\N	1	(ROSE) 4800WC x1	662.84	126.16	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-17 17:43:03.859551+00
116	ODR-20250817-7696	2025-08-09 10:46:51+00	FACEBOOK	Pao Alieness	(🌹) LOL_WILDRIFT	1590	https://drive.google.com/uc?id=1eToWSsWd4SykHx1KWYViBRUFZ_Poe-su	https://drive.google.com/uc?id=19woqchsNZ7155gYpv0cedMeRQtWh86Ed	\N	1	(ROSE) 10000WC x1	1365.86	224.14	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-17 17:41:19.087702+00
115	ODR-20250817-9645	2025-08-09 10:09:51+00	FACEBOOK	Fon Swift	(🌹) LOL_WILDRIFT	1590	https://drive.google.com/uc?id=1qbfPlx6uDrc4YeAokngDqT58M9_sqmf8	https://drive.google.com/uc?id=1yXcqulet8gY8N-F7OFaJNKst4a3XzFp9	\N	1	(ROSE) 10000WC x1	1365.86	224.14	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-17 17:40:40.919926+00
113	ODR-20250817-7921	2025-08-09 08:56:07+00	FACEBOOK	Chattarin Tonzhat Sirisak	(🌹) LOL_WILDRIFT	1590	https://drive.google.com/uc?id=1MQmX7bWQ3hjysveyuTgNJFcFuCLGUqjJ	https://drive.google.com/uc?id=1GvcEAE9KcwfK9IPJdhztbewwD_AFDX3a	\N	1	(ROSE) 10000WC x1	1365.86	224.14	รายการสำเร็จ	แทน	YOUTRIP		2025-08-17 17:39:09.899273+00
111	ODR-20250817-2213	2025-08-09 07:33:35+00	FACEBOOK	Ploykwuan R Boonnok	LOL_WILDRIFT	340	https://drive.google.com/uc?id=1CpqY2Euu5s6qGGLDuBUj6kU72x3lJK8k	https://drive.google.com/uc?id=10Iw9ZBqGa_mDJutHgExbIGcxGO6ylJ3d	\N	1	1850WC x1	273.17	66.83	รายการสำเร็จ	แทน	YOUTRIP		2025-08-17 17:37:03.873795+00
110	ODR-20250817-2350	2025-08-09 06:12:42+00	LINE	w	LOL_WILDRIFT	800	https://drive.google.com/uc?id=1BOo4c7mLkb8NbgIOlkOGRnNxkGrjxnQS	https://drive.google.com/uc?id=11HNlVqAirRu8Pqhzv3x7QtWv21yb2hJS	\N	1	4800WC x1	662.84	137.16	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-17 17:36:19.57919+00
108	ODR-20250817-7397	2025-08-09 04:49:54+00	FACEBOOK	IBeg Chutrakul	LOL_WILDRIFT	4820.03	https://drive.google.com/uc?id=17dT8i56N4Df10ypM1NvTHsyYomUQskqg	https://drive.google.com/uc?id=15wf2mYfSGdQKk2cOd5SsKAECrmJIoZmG	\N	1	30000WC x1	4097.58	722.45	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-17 17:32:45.441259+00
105	ODR-20250817-2570	2025-08-09 04:18:10+00	FACEBOOK	ไอเสื้อเเดง สุดหล่อเท่ห์	LOL_WILDRIFT	800	https://drive.google.com/uc?id=1alvXThM6jPZ8y331lBBYrJWzZmDxvybf	https://drive.google.com/uc?id=1kEPycP3XP4tej3Pj_ap2tnojRp3uVftm	\N	1	4800WC x1	662.84	137.16	รายการสำเร็จ	แทน	YOUTRIP		2025-08-17 17:29:51.094804+00
106	ODR-20250817-5482	2025-08-09 04:36:56+00	LINE	ณภัทร	MINECRAFT	35	https://drive.google.com/uc?id=1wtMUOQcEfwU-1jMRlEfjrovDG3xsFjPD	https://drive.google.com/uc?id=1EI9DfP_ig8rzXAORmznpuRZAH1vazI7L	\N	1	320 เหรียญ x1	5.62	29.38	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-17 17:30:28.75479+00
103	ODR-20250817-3947	2025-08-09 03:45:55+00	FACEBOOK	Methus Lapchaicharoenkit	LOL_WILDRIFT	89	https://drive.google.com/uc?id=1O38F30VzYp8hQ4TjwRd_w8EMA-LgDfmz	https://drive.google.com/uc?id=1cBrPCl9ZUOWe6aRz-c9PHYzELVKJiMLt	\N	1	425WC x1	68.29	20.71	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-17 17:28:01.723834+00
101	ODR-20250817-8427	2025-08-09 03:30:11+00	FACEBOOK	Pull-up Everyday	LOL_WILDRIFT	800	https://drive.google.com/uc?id=1DSzceU1brNd4MxX6tV7otoJuHspXx0QI	https://drive.google.com/uc?id=1JVyKqQTboxPMUXU4k4TSV4udEHFYyz9r	\N	1	4800WC x1	662.84	137.16	รายการสำเร็จ	แทน	YOUTRIP		2025-08-17 17:25:06.24795+00
100	ODR-20250817-9543	2025-08-09 03:20:25+00	FACEBOOK	Methus Lapchaicharoenkit	LOL_WILDRIFT	800	https://drive.google.com/uc?id=1uBYnJsY41W7uwe3rY8v2ArbFWzMv3ufn	https://drive.google.com/uc?id=17fJzxHUnoVd9c9xZtFBgjUScELpGgPoV	\N	1	4800WC x1	662.84	137.16	รายการสำเร็จ	แทน	YOUTRIP		2025-08-17 17:23:42.020232+00
136	ODR-20250818-4982	2025-08-11 06:18:09+00	FACEBOOK	Inla Gust Punnawat	(🌹) LOL_WILDRIFT	559	https://drive.google.com/uc?id=1yIaCzw1gcbXozGqayqYglKFdFEVNq1nB	https://drive.google.com/uc?id=1KEmIVK4d1SG5cu_tlEdvs3jLcUucAoGo	\N	1	(ROSE) 3275WC x1	466	93	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 17:34:46.802446+00
147	ODR-20250818-4113	2025-08-12 09:38:41+00	FACEBOOK	โด้ เตาปูน	DELTA_FORCE	2490	https://drive.google.com/uc?id=1B5rzuIVoytSitLw84rhtZjDhu583uIJy	https://drive.google.com/uc?id=1L_PyH1zTcxrSwblr9aFhq6KRAJvXGyC8	\N	1	8100DELTA x1	2273.39	216.61	รายการสำเร็จ	เกรซ	RAZERGOLD	84.67x26.85	2025-08-18 17:46:20.90711+00
146	ODR-20250818-8365	2025-08-12 09:16:19+00	LINE	BƎNZ	(🌹) LOL_WILDRIFT	7879.01	https://drive.google.com/uc?id=1hhzPn1fDMVI3akm2rTmaX5UGWKZGwiuI	https://drive.google.com/uc?id=1ZzTUIh8BuRZoZLjePwuRXQZ20WEkVxFY	\N	1	(ROSE) 50000WC x1	6833.5	1045.51	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 17:45:25.140038+00
151	ODR-20250818-6500	2025-08-13 11:22:10+00	FACEBOOK	Nong John	LOL_WILDRIFT	89	https://drive.google.com/uc?id=1qg326fZd0ncX9zB01gbHxU7a_fyOQnAc	https://drive.google.com/uc?id=1RG8D2oMglgVoGRiGzibQHxc21j4oRYhs	\N	1	425WC x1	68.4	20.6	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 17:51:20.612946+00
171	ODR-20250818-5892	2025-08-15 11:15:43+00	FACEBOOK	Peem Anuchit	ROV_MOBILE	975	https://drive.google.com/uc?id=1gl0Ede6kANoFJcxdkVxcN6IDm8M8Iqdz	https://drive.google.com/uc?id=1lrwaKIAzi2mXbCSSrM01biJPZiInSsS5	\N	1	1240 ปอง x1	940	35	รายการสำเร็จ	เกรซ	24BUYM		2025-08-18 18:11:20.184443+00
169	ODR-20250818-7713	2025-08-15 11:00:29+00	LINE	⛅️Y.	LOL_WILDRIFT	190	https://drive.google.com/uc?id=12SvPLSouaZpTarXL1X1HLWtmXVIVesoE	https://drive.google.com/uc?id=1OIovFZp__j752eJE4ckYEJR-7kUlfEFD	\N	1	1000WC x1	152.3	37.7	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 18:09:53.774509+00
164	ODR-20250818-6858	2025-08-14 13:44:11+00	FACEBOOK	Nantiwat Suksawat	DUNK_DYNASTY	419	https://drive.google.com/uc?id=1WnSa6xMwjBp5jMklBCoCCQryCRjsk5Ro	https://drive.google.com/uc?id=1WbAHp-PyG9XIBAqt7CZl9XE0aM6xYjYa	\N	1	1110TOKENS x1	378.85	40.15	รายการสำเร็จ	เกรซ	RAZERGOLD	14.11x26.85	2025-08-18 18:04:47.197164+00
167	ODR-20250818-1668	2025-08-15 08:33:17+00	FACEBOOK	Chayanon Srilofung	MARVEL_RIVALS	575	https://drive.google.com/uc?id=1c1d7LE1QlcfpA_mY4zoUaNR5kz9l8VrF	https://drive.google.com/uc?id=1OlePIJlQ-G-5O8JSyYN2hbjjVtF9MrtQ	\N	1	2180LATT x1	525	50	รายการสำเร็จ	เกรซ	24BUYM		2025-08-18 18:07:38.191776+00
163	ODR-20250818-2287	2025-08-14 13:22:29+00	FACEBOOK	Anusorn Chalempit	LOL_WILDRIFT	190	https://drive.google.com/uc?id=1VHrbJArOWJBf51OlxVTF76Zc-gNWPiYl	https://drive.google.com/uc?id=1om8l0Zn7WR9TfcKrBEHH8HuC4ioq2aUY	\N	1	1000WC x1	152.54	37.46	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 18:03:52.069653+00
162	ODR-20250818-3702	2025-08-14 12:37:11+00	FACEBOOK	Aom My	MINECRAFT	209	https://drive.google.com/uc?id=11kCaN_Q7076X-40ZhOesBxa9COKpGNu9	https://drive.google.com/uc?id=12vC6K6QFT1kPKInI8c9UPR2Yn6gzRtCI	\N	1	3500 เหรียญ x1	56.19	152.81	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 18:03:03.821872+00
160	ODR-20250818-6700	2025-08-14 05:41:26+00	FACEBOOK	Charlies Peeraphol	LOL_WILDRIFT	380	https://drive.google.com/uc?id=1KMZQa7SlwJDNKfOqsoVD0lqvfNvqnWEn	https://drive.google.com/uc?id=1LZlG6Z9FHyKlyTMH9J3NBXwjH4EHMiUG	\N	2	1000WC x2	305.08	74.92	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 18:00:42.283963+00
158	ODR-20250818-7586	2025-08-14 03:56:39+00	FACEBOOK	Methus Lapchaicharoenkit	TFT_MOBILE	2119	https://drive.google.com/uc?id=1Z3JhvP93-yTpZYvR0m46dNTFFucB5574	https://drive.google.com/uc?id=1nS0ko1toN5nWLzRnru011QdAMuiS6sXF	\N	1	13500TFT x1	1846.49	272.51	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 17:57:59.525056+00
157	ODR-20250818-9021	2025-08-14 03:26:25+00	FACEBOOK	Theeraphat Sakulpaprasert	(🌹) LOL_WILDRIFT	1590.01	https://drive.google.com/uc?id=1tOW1trGkuDp9QT0crbDDndAjrg_k_M8V	https://drive.google.com/uc?id=1uGf-W62-adITeZPZgDPuQ6-XhBvlmIJN	\N	1	(ROSE) 10000WC x1	1364.8	225.21	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 17:56:51.569868+00
154	ODR-20250818-3124	2025-08-13 14:45:14+00	FACEBOOK	Charlies Peeraphol	LOL_WILDRIFT	380	https://drive.google.com/uc?id=1GNG1xRaepnNR9mx-gT7AhVlV_b22R-_i	https://drive.google.com/uc?id=1YOFLxtBc-KOd7cwQHwin2KA6xIySuhrf	\N	2	1000WC x2	305.78	74.22	รายการสำเร็จ	แทน	YOUTRIP		2025-08-18 17:53:55.230699+00
152	ODR-20250818-1014	2025-08-13 13:07:06+00	FACEBOOK	ทักษ์ดนัย ไปร์ ร่มรื่น	LOL_WILDRIFT	190	https://drive.google.com/uc?id=1JH5iFohC16k1LnzrMm9mt6JHa8-Ul9Vp	https://drive.google.com/uc?id=1gq9kXBe-vYD9Tubf2fCzXEERrw9WYWLw	\N	1	1000WC x1	152.89	37.11	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 17:52:13.463867+00
153	ODR-20250818-7598	2025-08-13 13:22:27+00	FACEBOOK	Napasorn Phothiprom	LOL_WILDRIFT	190	https://drive.google.com/uc?id=1LmJWuD9n7PqrikjuOXUeVdfdU7nTW2bU	https://drive.google.com/uc?id=15FDRak5Hd97M8llLen0rHEED0_EneGcz	\N	1	1000WC x1	152.89	37.11	รายการสำเร็จ	แทน	YOUTRIP		2025-08-18 17:53:05.504932+00
149	ODR-20250818-6276	2025-08-12 14:29:35+00	FACEBOOK	PO Tae	RACING_MASTER	619	https://drive.google.com/uc?id=1IWhV-llf6dB4U4hGfmy8q0Qyu5YRNZzz	https://drive.google.com/uc?id=1woKd5KHj1Z5UU4M1t-U-NPUsUvaiBbsI	\N	1	MPCOMBO x1	564.39	54.61	รายการสำเร็จ	แทน	RAZERGOLD	21.02x26.85	2025-08-18 17:48:25.081568+00
144	ODR-20250818-4943	2025-08-12 06:06:56+00	FACEBOOK	Poon Poonyawee	(🌹) LOL_WILDRIFT	789	https://drive.google.com/uc?id=1Wo3MtPH0c0R3DOXv_oTsWRWYrzqmccGm	https://drive.google.com/uc?id=1CGIx3f0-1J4wNpKiPTNVc2CASQKuSGKA	\N	1	(ROSE) 4800WC x1	663.25	125.75	รายการสำเร็จ	แทน	YOUTRIP		2025-08-18 17:43:59.221038+00
142	ODR-20250818-6974	2025-08-11 17:30:31+00	FACEBOOK	Theeraphat Sakulpaprasert	(🌹) LOL_WILDRIFT	1590.04	https://drive.google.com/uc?id=1uLU-kkRxMHfSdg8Z_N2q0ytWQym9mZ8d	https://drive.google.com/uc?id=1lK9YFdfQVQ3TGK8eNUMabm7uF-i2qQx8	\N	1	(ROSE) 10000WC x1	1365.86	224.18	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 17:42:28.850479+00
141	ODR-20250818-2231	2025-08-11 17:04:23+00	FACEBOOK	Natthaphat Chanthawan	MINECRAFT	105	https://drive.google.com/uc?id=1yCovI3u2h7BGbHPRR3-1YiGNig0d6FdY	https://drive.google.com/uc?id=1ghh2NIiyPiogr0oThpbv7GXzTf3SUwAQ	\N	1	960 เหรียญ x1	16.86	88.14	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 17:41:43.177904+00
140	ODR-20250818-5883	2025-08-11 16:15:48+00	FACEBOOK	Theeraphat Sakulpaprasert	(🌹) LOL_WILDRIFT	1590.03	https://drive.google.com/uc?id=14cMRlEBL0mKuthffwO3GCJJKkOgcfjkE	https://drive.google.com/uc?id=180nZHetMJ1JGjW3G28QwnRCQlhl3ynRK	\N	1	(ROSE) 10000WC x1	1365.86	224.17	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 17:40:35.607798+00
139	ODR-20250818-3714	2025-08-11 11:05:00+00	FACEBOOK	Ba Ros	VALORANT	4174	https://drive.google.com/uc?id=1goLb_4SvI0fYQCQTl86usH7WNKdbonbj	https://drive.google.com/uc?id=12OBlcLSG5wzdKn1A9WsQoubDlw9kEnVb	\N	2	6825VP x1, 11000VP x1	4023.8	150.2	รายการสำเร็จ	แทน	RICHMAN		2025-08-18 17:39:43.579452+00
185	ODR-20250818-6989	2025-08-16 17:25:46+00	FACEBOOK	Max Jessada	(🌹) LOL_WILDRIFT	559	https://drive.google.com/uc?id=1pH6E_uLgHEQDvkLjp9jHlXJWFCpKAYC7	https://drive.google.com/uc?id=1inRbVPZd0aMnHSEwExtkmIpjfzgPrw8z	\N	1	(ROSE) 3275WC x1	465.11	93.89	รายการสำเร็จ	แทน	YOUTRIP		2025-08-18 18:24:54.517331+00
187	ODR-20250818-5286	2025-08-16 23:47:14+00	LINE	🌺 ONOSAN 小野 🌺	HONKAI_STARRAIL	2400	https://drive.google.com/uc?id=1HZfEQXnLp_COzjUxuzjL6z8z39_NFuo1	https://drive.google.com/uc?id=12W9-aeVBAluzq9HfiPym5odrOmVjYeiO	\N	1	8080SHARD x1	2285	115	รายการสำเร็จ	แทน	RICHMAN		2025-08-18 18:27:12.560605+00
193	ODR-20250818-6479	2025-08-18 06:14:00+00	FACEBOOK	Sumet Tongyong	LOL_WILDRIFT	89	https://drive.google.com/uc?id=1aiQMF-aA3rHxcLpeQXlsKnzKjU3WaIn6	https://drive.google.com/uc?id=1NoRYi7Ppc9MwrUe9FJNzfKQbLrRTPC5R	\N	1	STELLACORN x1	68.16	20.84	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 18:41:42.084348+00
35	ODR-20250814-4538	2025-08-02 05:23:00+00	FACEBOOK	Pathapeekan Otasan	MINECRAFT	35	https://drive.google.com/uc?id=1ysQXkvp0qMDrGXlxUUsCLrjT0cJ5I5S_	https://drive.google.com/uc?id=1iC62pW9Z31RtIqF430msadwxlpuvnLbJ	\N	1	320 เหรียญ x1	5.7	29.3	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-14 16:18:35.984862+00
46	ODR-20250815-5781	2025-08-02 16:08:00+00	FACEBOOK	Mekk Ponthep	TFT_MOBILE	459	https://drive.google.com/uc?id=1IVL9lms2AuG1U9p_9vaAg02Cak7Bs5hF	https://drive.google.com/uc?id=1c-OM1JPiB8JcWPzDvGeP8ndKw2UNeaGq	\N	1	2800TFT x1	407.68	51.32	รายการสำเร็จ	แทน	YOUTRIP		2025-08-15 10:00:15.72386+00
202	ODR-20250818-2800	2025-08-18 15:58:46+00	FACEBOOK	Natthapong Wechwong	TFT_MOBILE	459	https://drive.google.com/uc?id=1tCn7CKjKHUt59VNu8Dvhhh6dQuUA876K	https://drive.google.com/uc?id=16BlXTTVPJdVRqIk8hnXM6zExRIqB4hcD	\N	1	2800TFT x1	400.96	58.04	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 18:49:54.772519+00
197	ODR-20250818-2707	2025-08-18 09:52:19+00	FACEBOOK	Anucha Longthung	MINECRAFT	199	https://drive.google.com/uc?id=1rw8N8Ab7GXUYKYeRAk3ovX_zg6MRX5XC	https://drive.google.com/uc?id=1OLJZznkHEMSIC5ybkeTAuUcbOAVonpgV	\N	1	1920 เหรียญ x1	33.66	165.34	รายการสำเร็จ	แทน	YOUTRIP		2025-08-18 18:46:07.702248+00
199	ODR-20250818-8286	2025-08-18 13:31:23+00	FACEBOOK	โด้ เตาปูน	VALORANT	505	https://drive.google.com/uc?id=1Kl1uZdvSwbU7BI4RrwxaK4Te1maiTj-k	https://drive.google.com/uc?id=1TeD1lOguTEG1my0Z8P1ilT6CQD1qRdoy	\N	1	2050VP x1	481	24	รายการสำเร็จ	เกรซ	RICHMAN		2025-08-18 18:47:22.327131+00
198	ODR-20250818-2359	2025-08-18 12:17:37+00	FACEBOOK	Aun 'sirikit	DUNK_DYNASTY	159	https://drive.google.com/uc?id=1ScI1vio50TNpOqc3787CiklDDCGzv2jG	https://drive.google.com/uc?id=1rvEPF5QZGDqo3jxORJ_p0rbn5hxjOJTk	\N	1	Party Membership x1	127	32	รายการสำเร็จ	เกรซ	RAZERGOLD	4.73x26.85	2025-08-18 18:46:52.236706+00
195	ODR-20250818-5273	2025-08-18 07:45:34+00	FACEBOOK	Chana Suebsakwong	TFT_MOBILE	759	https://drive.google.com/uc?id=1Zb1z7thdQb7TZrmvsnP_pii4rj8BfJNM	https://drive.google.com/uc?id=1rVBrtE3oJDbO1uOlvTDaFvvBl3o0KC4n	\N	1	4500TFT x1	641.53	117.47	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 18:44:32.827366+00
192	ODR-20250818-1793	2025-08-18 06:02:48+00	FACEBOOK	Baeni Ur	(🌹) LOL_WILDRIFT	1590	https://drive.google.com/uc?id=1JjSGXfF-Pl5VL-tcBp9pbiAEGouDJdJl	https://drive.google.com/uc?id=1_375pmI-ZZ5aKGcqqtKfIPW9arQPSqcs	\N	1	(ROSE) 10000WC x1	1363.25	226.75	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 18:41:02.379381+00
189	ODR-20250818-9790	2025-08-17 12:01:56+00	FACEBOOK	Por	TFT_MOBILE	1338	https://drive.google.com/uc?id=1FnMEbtMhCCeAAB3HQ6KiIi5z0URp2XV0	https://drive.google.com/uc?id=1ESFwKUN8ZVftkz767N7vDVTt2K1fuF_B	\N	2	1380TFT x1, 6500TFT x1	1122.68	215.32	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 18:30:25.840127+00
188	ODR-20250818-5311	2025-08-17 09:03:48+00	FACEBOOK	Ba Ros	VALORANT	2535	https://drive.google.com/uc?id=1AjDGIvzVNTPf2m7CuVaFhaa0o3KMHn9l	https://drive.google.com/uc?id=1MNPw4J6h9v636KojMmFGGJkYLD76jBPF	\N	1	11000VP x1	2442	93	รายการสำเร็จ	แทน	RICHMAN		2025-08-18 18:28:00.615651+00
184	ODR-20250818-1383	2025-08-16 17:11:14+00	LINE	pond	MINECRAFT	209	https://drive.google.com/uc?id=16Tsfi-KPZK7J6O984KZ_7cTMGmC_-Dti	https://drive.google.com/uc?id=1PhQrTfqzGemQ4-jWaTgdMgGwqMdh8EzM	\N	1	3500 เหรียญ x1	56.13	152.87	รายการสำเร็จ	แทน	YOUTRIP		2025-08-18 18:24:09.978081+00
182	ODR-20250818-1951	2025-08-16 13:56:24+00	FACEBOOK	ۦ hoshi	PUBG_MOBILE	1489	https://drive.google.com/uc?id=1H8AYlHgsMn8Pj_n9RzyiobEIZrjVELgz	https://drive.google.com/uc?id=1NOCKJL1gx-NYDEmMcaMk4Cx_2NQvSxZA	\N	1	3850UC x1	1365.86	123.14	รายการสำเร็จ	เกรซ	RAZERGOLD	50.87x26.85	2025-08-18 18:22:13.098748+00
180	ODR-20250818-1128	2025-08-16 08:56:05+00	FACEBOOK	บัณฑิต กาญจนระพีพรรณ	VALORANT	505	https://drive.google.com/uc?id=117xYn4EBs-vSkwsNe_cNHf14clP0rRbc	https://drive.google.com/uc?id=1qRfHVVDsZ5_NPmzy2_Gp2hTdMXQlvT8D	\N	1	2050VP x1	481	24	รายการสำเร็จ	เกรซ	RICHMAN		2025-08-18 18:20:42.438038+00
179	ODR-20250818-3966	2025-08-16 06:52:28+00	FACEBOOK	Thanapat Sansanor	RACING_MASTER	29	https://drive.google.com/uc?id=1_JaBLfsD5wsJJAjmVN09pBEc0I4yvhkT	https://drive.google.com/uc?id=17kOaG8xWDprzv38GkrMlpqQ_qrJbWMzN	\N	1	รายสัปดาห์ (WEEKLY) x1	23.85	5.15	รายการสำเร็จ	แทน	RAZERGOLD	0.88x27.10	2025-08-18 18:19:50.249929+00
177	ODR-20250818-1739	2025-08-16 05:09:19+00	FACEBOOK	Chawin Lerdsiwapon	LOL_WILDRIFT	340.07	https://drive.google.com/uc?id=1hEmgeET31CGF9oLKHQ9LXHO451cvW27L	https://drive.google.com/uc?id=1l5jbXlY5a4w_dSg_ZygoMEscrcZFateN	\N	1	1850WC x1	272.65	67.42	รายการสำเร็จ	แทน	YOUTRIP		2025-08-18 18:18:31.301706+00
175	ODR-20250818-5226	2025-08-15 19:40:40+00	FACEBOOK	แฟ้มไง ไม่ต้องถาม	VALORANT	505	https://drive.google.com/uc?id=1pEEBdWF4YhZV5I5pYbOR0mHdT1xo01pZ	https://drive.google.com/uc?id=1jgYrXY5_Cym8fbJh4Ibe5SgUCaF6tqxe	\N	1	2050VP x1	481	24	รายการสำเร็จ	แทน	RICHMAN		2025-08-18 18:16:29.541999+00
174	ODR-20250818-6162	2025-08-15 18:04:12+00	FACEBOOK	Sumet Tongyong	(🌹) LOL_WILDRIFT	559	https://drive.google.com/uc?id=1z7OfbhJiOih_jfh6ZC_BJfuV2EHx94Qw	https://drive.google.com/uc?id=1aDwBcoojOlfGb0GMxZRVzxN2va0hHcS2	\N	1	(ROSE) 3275WC x1	464.92	94.08	รายการสำเร็จ	แทน	YOUTRIP		2025-08-18 18:14:22.179763+00
34	ODR-20250814-5853	2025-08-02 04:35:49+00	LINE	T.	RACING (LOGIN)	2117	https://drive.google.com/uc?id=1P4ClJN4R_65aqQ5GiexcFg0WFaVuvX8D	https://drive.google.com/uc?id=1Q8vmfNIWfdlBCu3l1THs2_YlNrIPICC_	\N	3	669BAHT ($19.99) x1, 999BAHT ($29.49) x2	1860.67	256.33	รายการสำเร็จ	เกรซ	RAZERGOLD	69.17*26.90	2025-08-14 16:17:44.537091+00
173	ODR-20250818-4139	2025-08-15 11:29:57+00	FACEBOOK	Peem Anuchit	ROV_MOBILE	1469	https://drive.google.com/uc?id=1g-Ns5zdtSfC6rcGWa2CslQ7B0Tl0nPGy	https://drive.google.com/uc?id=1XydtCd6Pa-7L2BTdSUmZTfP4qj44oy5v	\N	1	1860 ปอง x1	1410	59	รายการสำเร็จ	เกรซ	RICHMAN		2025-08-18 18:12:37.041029+00
201	ODR-20250818-2367	2025-08-18 14:55:30+00	LINE	Siwapol Burithat	(🌹) LOL_WILDRIFT	559	https://drive.google.com/uc?id=1asGerdyuMtV1ShrQEXAOITq_tF9VpF4q	https://drive.google.com/uc?id=1vtoMoRBiuQ18tRTDHgmlEZgjgzbvzNb9	\N	1	(ROSE) 3275WC x1	465.11	93.89	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 18:49:03.471368+00
200	ODR-20250818-9867	2025-08-18 13:55:55+00	FACEBOOK	Kaopun Tangchutaveesub	(ID-PASS) เติมได้หลายเกม	289	https://drive.google.com/uc?id=1gSdTWUSaCwSOM6KTwjR43hmACpqgfWqQ	https://drive.google.com/uc?id=1riIhdY9tlC6YbqxTkEtEzinwV7CNFMcz	\N	1	399 BAHT (9.99$) x1	252.75	36.25	รายการสำเร็จ	แทน	ITUNES	ชำระด้วยเงินด้วย Itunes ด้วยเรท 9.99x25.3	2025-08-18 18:48:12.503208+00
203	ODR-20250818-6494	2025-08-18 16:33:31+00	FACEBOOK	Kaopun Tangchutaveesub	MARVEL_RIVALS	575	https://drive.google.com/uc?id=16rCKfsVk2MhbvM1iKSwCiicm8QxDvaz-	https://drive.google.com/uc?id=14YKfrV26UeNskCfX3AO99qpvZ-_uim4Y	\N	1	2180LATT x1	525	50	รายการสำเร็จ	แทน	24BUYM		2025-08-18 18:50:43.384186+00
196	ODR-20250818-1848	2025-08-18 08:49:56+00	FACEBOOK	Awathip Salaeh	VALORANT	250	https://drive.google.com/uc?id=1AKANxkaqcFs0MI47SgWZiP2TNKzOwKWs	https://drive.google.com/uc?id=1Mv9kwEasmD6fEDg2iqJVzlStyzop9uqH	\N	1	1000VP x1	240.5	9.5	รายการสำเร็จ	แทน	RICHMAN		2025-08-18 18:45:19.057702+00
194	ODR-20250818-9773	2025-08-18 06:49:39+00	FACEBOOK	Baeni Ur	LOL_WILDRIFT	175	https://drive.google.com/uc?id=1kqrdatXcKNus9ooDFM4IPo8s5O1iDAym	https://drive.google.com/uc?id=1hUCM8AduVs_LOf0oWbOIyujgYC1B5CFU	\N	1	1000WC x1	152.36	22.64	รายการสำเร็จ	เกรซ	YOUTRIP	ทำรายการผิดพลาด/เติมผิดแพ็ค	2025-08-18 18:42:30.586157+00
191	ODR-20250818-4525	2025-08-17 12:48:41+00	FACEBOOK	Por	TFT_MOBILE	1558	https://drive.google.com/uc?id=1OLDP2M29wve51RRo33L9c3jYjApyBwy7	https://drive.google.com/uc?id=1YhIVbf5NG8cxfMtYqKMCuja6yd101jI5	\N	2	2800TFT x1, 6500TFT x1	1323.16	234.84	รายการสำเร็จ	แทน	YOUTRIP		2025-08-18 18:32:57.65104+00
190	ODR-20250818-4189	2025-08-17 12:17:36+00	FACEBOOK	Yiw Kimhun	(🌹) LOL_WILDRIFT	559	https://drive.google.com/uc?id=1YB0MqJBII40kd4ZS_-bs7bwOWyRLF3BP	https://drive.google.com/uc?id=1zAf4A0WIg84cv5DKFsjdTCWNmKfVSz8e	\N	1	(ROSE) 3275WC x1	465.11	93.89	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 18:32:03.310077+00
186	ODR-20250818-8963	2025-08-16 23:33:46+00	LINE	🌺 ONOSAN 小野 🌺	HONKAI_STARRAIL	2400	https://drive.google.com/uc?id=1tVGyJSpniV1w31WZRVA3SNhnMENV952Z	https://drive.google.com/uc?id=1T1v5_-Oy53ltS3c9A6E2v5zbP2lmlbBI	\N	1	8080SHARD x1	2285	115	รายการสำเร็จ	แทน	RICHMAN		2025-08-18 18:26:20.782983+00
183	ODR-20250818-8855	2025-08-16 14:35:29+00	FACEBOOK	ทักษ์ดนัย ไปร์ ร่มรื่น	LOL_WILDRIFT	190	https://drive.google.com/uc?id=1qaHB9_vvcfP3rYjZZRnf7C6xotXGUeXU	https://drive.google.com/uc?id=1JvGHiMI6aQhfxw-UYv9uN93kaiFamn40	\N	1	1000WC x1	152.36	37.64	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 18:22:47.550765+00
181	ODR-20250818-8892	2025-08-16 12:35:23+00	FACEBOOK	Tanabordin Noipitak	ROV_MOBILE	102	https://drive.google.com/uc?id=1VEMRjxHtMbhqvW62P87tGWFT0esR7egg	https://drive.google.com/uc?id=1D8lOGMSvR-VIS0ETS_0mufvyq6KTxLDI	\N	1	121 ปอง x1	95	7	รายการสำเร็จ	เกรซ	RICHMAN		2025-08-18 18:21:33.844659+00
178	ODR-20250818-3335	2025-08-16 05:21:56+00	FACEBOOK	Chawin Lerdsiwapon	LOL_WILDRIFT	340.07	https://drive.google.com/uc?id=1raTEaVCwESwgBP9qDnJZ9pWCRBqyP60t	https://drive.google.com/uc?id=1Z033L8ZIvTuBl0YUiUKGrF8FOeRt7qjB	\N	1	1850WC x1	272.65	67.42	รายการสำเร็จ	แทน	YOUTRIP		2025-08-18 18:19:08.618485+00
176	ODR-20250818-7630	2025-08-15 23:14:34+00	FACEBOOK	ทักษ์ดนัย ไปร์ ร่มรื่น	(🌹) LOL_WILDRIFT	559	https://drive.google.com/uc?id=1jagWO9AFhrX4DB3ayWF0SYOofCrwCV6I	https://drive.google.com/uc?id=1kNiDnLjqmDM1PYLBfnZsKjz0E1eOqEFM	\N	1	(ROSE) 3275WC x1	465.11	93.89	รายการสำเร็จ	แทน	YOUTRIP		2025-08-18 18:17:29.57765+00
217	ODR-20250820-5548	2025-08-20 16:25:01+00	FACEBOOK	Jaofarmza Eiei	DUNK_DYNASTY	1018	https://drive.google.com/uc?id=15vdpoNMYvmCOh9c2NQK4pRhyvOytXQbZ	https://drive.google.com/uc?id=1A4IZCvNqzYXTgi1NkaZsp7d97JqiEm_0	\N	2	Premium Pass x1, 999BAHT (29.99$) x1	899.71	118.29	รายการสำเร็จ	แทน	ITUNES	29.99x25.30 + 5.25x26.85	2025-08-20 18:18:15.248691+00
212	ODR-20250820-8053	2025-08-20 05:02:53+00	FACEBOOK	ทักษ์ดนัย ไปร์ ร่มรื่น	(🌹) LOL_WILDRIFT	1590	https://drive.google.com/uc?id=1lM3GKOJbzPLhbqDCdC0Hpj1brHnEBOt2	https://drive.google.com/uc?id=1_hZu6IGSe_-ftwsvMZTAc7jnA-rCvL32	\N	1	(ROSE) 10000WC x1	1362.93	227.07	รายการสำเร็จ	แทน	YOUTRIP		2025-08-20 18:14:15.247335+00
214	ODR-20250820-1571	2025-08-20 13:34:19+00	FACEBOOK	ทักษ์ดนัย ไปร์ ร่มรื่น	LOL_WILDRIFT	279	https://drive.google.com/uc?id=1HgX4G6ZKRo5rT32LOVDfCNJX1gFswtHH	https://drive.google.com/uc?id=1JmeTXMjGicugo3ECHTSCn2DanIO5oCH-	\N	2	425WC x1, 1000WC x1	220.48	58.52	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-20 18:15:50.614262+00
216	ODR-20250820-6167	2025-08-20 15:59:45+00	FACEBOOK	Aun 'sirikit	DUNK_DYNASTY	279	https://drive.google.com/uc?id=1THKbwPpMjvSig1BPf9LjaVvR922W1RCD	https://drive.google.com/uc?id=1LD9d6HJazaiU5v_6e78XbjcQVTxD54kW	\N	1	Extra Premium Pass x1	234.4	44.6	รายการสำเร็จ	แทน	RAZERGOLD	8.73x26.85	2025-08-20 18:17:17.958284+00
211	ODR-20250820-6995	2025-08-20 02:36:43+00	FACEBOOK	Thanaphon Kaewkongka	ROBLOX	155	https://drive.google.com/uc?id=16PklGD-Rej110RtLnkBpruEVC5p1OEix	https://drive.google.com/uc?id=1e_DquWHGSxxMptknreiOtFSvyY3QkoHG	\N	1	400 ROBUX x1	126.25	28.75	รายการสำเร็จ	เกรซ	ITUNES	4.99x25.30	2025-08-20 18:13:18.956743+00
209	ODR-20250819-6022	2025-08-19 14:39:06+00	FACEBOOK	ทักษ์ดนัย ไปร์ ร่มรื่น	LOL_WILDRIFT	190	https://drive.google.com/uc?id=1C3M5EkgGi3zORFkoBrRQKQ39LLtv5s9U	https://drive.google.com/uc?id=1a-2esy9tKoA7agdB76O4W_M3fIUbV4qx	\N	1	1000WC x1	152.1	37.9	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-19 17:02:56.679341+00
208	ODR-20250819-1338	2025-08-19 11:13:00+00	LINE	BiBi	MINECRAFT	169	https://drive.google.com/uc?id=1xoNr97LhkyVAM2BvM8VogE3RTc2-g1oT	https://drive.google.com/uc?id=19Nt3KBPkM9sV06pGxgFic1VHNOOV4zra	\N	1	1600 เหรียญ x1	28	141	รายการสำเร็จ	แทน	YOUTRIP		2025-08-19 17:02:04.719832+00
205	ODR-20250819-5766	2025-08-19 05:40:42+00	LINE	aRnOoNg78	MINECRAFT	69	https://drive.google.com/uc?id=1uIit73YkY0VYoiCJgfmHuVQ1Gu1dz7xk	https://drive.google.com/uc?id=1IGrUXfQhnai4fPJzPplAcHVPW8k8-zcM	\N	1	640 เหรียญ x1	11.2	57.8	รายการสำเร็จ	แทน	YOUTRIP		2025-08-19 17:00:17.260103+00
204	ODR-20250819-1923	2025-08-19 01:45:14+00	LINE	มะเขียบ	MINECRAFT	209	https://drive.google.com/uc?id=1rURyO7G0QxEee28q93fH3TrZGk4kdVFW	https://drive.google.com/uc?id=13qWVVbikC40w0pjtQq5VRBq_HLD2hV6s	\N	1	3500 เหรียญ x1	56.03	152.97	รายการสำเร็จ	แทน	YOUTRIP		2025-08-19 16:59:33.464565+00
215	ODR-20250820-6591	2025-08-20 15:16:40+00	FACEBOOK	Aueaathon Sirisakorn	(🌹) LOL_WILDRIFT	889	https://drive.google.com/uc?id=13lv5U2Ys7akHZ2IE2JGKFrYdSPyB5yAg	https://drive.google.com/uc?id=1Vv8DqAJfT25O67_aEJAHEQT58hoJ_AEd	\N	1	(ROSE) 5225WC x1	729.57	159.43	รายการสำเร็จ	แทน	YOUTRIP		2025-08-20 18:16:42.549396+00
213	ODR-20250820-1297	2025-08-20 11:15:31+00	FACEBOOK	Nopanan Khamcha	DUNK_DYNASTY	279	https://drive.google.com/uc?id=15SfLW0HCb_iRRhpLa9j4o6Zu-KmNPM3o	https://drive.google.com/uc?id=1dJZ41prJ6TCjuYJvU3X7y55hhxD4zoYt	\N	1	Extra Premium Pass x1	234.4	44.6	รายการสำเร็จ	เกรซ	RAZERGOLD		2025-08-20 18:14:51.405391+00
210	ODR-20250820-7745	2025-08-19 18:55:46+00	FACEBOOK	Methus Lapchaicharoenkit	TFT_MOBILE	239	https://drive.google.com/uc?id=1bJQqAIuHoNbGD8jQsvdHqJ6tlbUieQvh	https://drive.google.com/uc?id=1rj9wYFhQ1E482sajJAdSj3MQE2v5Ewsg	\N	1	1380TFT x1	200.13	38.87	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-20 18:12:24.073747+00
207	ODR-20250819-8448	2025-08-19 08:03:53+00	FACEBOOK	Kun Chonnakun Wiset	DUNK_DYNASTY	169	https://drive.google.com/uc?id=1VTYwRipKXDj_GVz1Fj3vNCKZZiFCyVJy	https://drive.google.com/uc?id=1ID1CP8SrpuYRcp__nm_5IEhhYS37FdNh	\N	1	Premium Pass x1	140.96	28.04	รายการสำเร็จ	แทน	RAZERGOLD		2025-08-19 17:01:32.908718+00
206	ODR-20250819-5756	2025-08-19 06:09:34+00	LINE	aRnOoNg78	MINECRAFT	209	https://drive.google.com/uc?id=1C-vcsWlku-q5cSKHNrdJ0JK6t7Xyzh4h	https://drive.google.com/uc?id=1zh1KjsyIvNTsKerqPPoQEPUBkdmOzY8z	\N	1	3500 เหรียญ x1	56.03	152.97	รายการสำเร็จ	แทน	YOUTRIP		2025-08-19 17:00:45.70169+00
225	ODR-20250821-2843	2025-08-21 15:37:07+00	FACEBOOK	Kanokwan BJ	VALORANT	1269	https://drive.google.com/uc?id=1hfE2rkzxDFk4VVPbSfNNREqxV_CkHaGJ	https://drive.google.com/uc?id=1Zl8OzAVKlhSsxTOsB5bDKMiRCiMpzlGa	\N	1	5350VP x1	1221	48	รายการสำเร็จ	เกรซ	RICHMAN		2025-08-21 16:13:52.780817+00
224	ODR-20250821-9603	2025-08-21 15:33:12+00	FACEBOOK	นลธวัช พันกับ	MINECRAFT	209	https://drive.google.com/uc?id=15UBOSO5IkWHrtGxxH8O5ifSNo_7grYoQ	https://drive.google.com/uc?id=1GtwYWaQ6j12iVmV0AN-OewkyjcdlVh9m	\N	1	3500 เหรียญ x1	56.14	152.86	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-21 16:13:12.544601+00
223	ODR-20250821-2097	2025-08-21 14:30:44+00	FACEBOOK	Nopanan Khamcha	DUNK_DYNASTY	159	https://drive.google.com/uc?id=1ifFRpvJQvRrHBPcsr7RK-2qk64pE4ZTP	https://drive.google.com/uc?id=17tuzVRQpQhLfGJB1hDsVZ6vA62zTq-bK	\N	1	Party Membership x1	125.12	33.88	รายการสำเร็จ	เกรซ	RAZERGOLD	4.66x26.85	2025-08-21 14:46:33.571846+00
222	ODR-20250821-8610	2025-08-21 13:58:01+00	FACEBOOK	Wutiiphon Bonburee	MINECRAFT	209	https://drive.google.com/uc?id=1e7F48VHUytSmCyuuaUw_c1IQFc4f7JeX	https://drive.google.com/uc?id=19tiIn4oJ9swlQyHihu7VphRqUjGSdo82	\N	1	3500 เหรียญ x1	56.14	152.86	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-21 14:45:58.822978+00
221	ODR-20250821-2314	2025-08-21 11:31:41+00	FACEBOOK	Chitsanuphong Na Chaisri	HONKAI_STARRAIL	139	https://drive.google.com/uc?id=1RBMTn1ek-bGqqWQy4YbfwnTaMUz2aD-B	https://drive.google.com/uc?id=1QSagM10ITBsqL86DtST5z9ZZ5LZ1yNQD	\N	1	บัตรกำนัลเสบียงรถไฟ x1	0	139	รายการสำเร็จ	แทน	RAZERGOLD	ชำระด้วยการแลก Razer Silver	2025-08-21 14:45:24.82565+00
220	ODR-20250821-5998	2025-08-21 04:48:06+00	FACEBOOK	Apisit Kanna	COA	33	https://drive.google.com/uc?id=15_gloi9X3p5ugoB_NhTIoHvgB3xGLMB3	https://drive.google.com/uc?id=10D2f6CshQt4IuXL8EGo_49YQbww1TTyC	\N	1	69 โอปอล x1	29	4	รายการสำเร็จ	แทน	24BUYM		2025-08-21 14:44:36.686376+00
219	ODR-20250821-2196	2025-08-21 04:25:02+00	FACEBOOK	Saibass Thengmongkon	VALORANT	125	https://drive.google.com/uc?id=1dPBYImgvK-wVxGIgn96XTOWqTlEiZKYs	https://drive.google.com/uc?id=1tiYfvg72ovfep2l-kLgpOf9cC844pTo4	\N	1	475VP x1	120.3	4.7	รายการสำเร็จ	แทน	RICHMAN		2025-08-21 14:44:06.136677+00
218	ODR-20250821-5641	2025-08-20 18:19:35+00	FACEBOOK	Worawit Chainaranon	DUNK_DYNASTY	1489	https://drive.google.com/uc?id=11iLCBMYWz_IugNoa-1ErF6mrgX1TdNbu	https://drive.google.com/uc?id=1SFiV8i9Z53fpFvobweFXiC6cRIqbR0Q7	\N	1	3880TOKENS x1	1250.67	238.33	รายการสำเร็จ	แทน	RAZERGOLD	46.58x26.85	2025-08-21 14:43:27.901475+00
172	ODR-20250818-3031	2025-08-15 11:16:00+00	FACEBOOK	Prem Rock	(🌹) LOL_WILDRIFT	559	https://drive.google.com/uc?id=1oEZ4IvmBOW9J69ECrNLy1yXTpM1ThQcd	https://drive.google.com/uc?id=1iTtVg8QfwMY-bEfCmEDQ0u6IbcjDy6_O	\N	1	(ROSE) 3275WC x1	464.92	94.08	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 18:11:56.589954+00
170	ODR-20250818-5403	2025-08-15 11:12:37+00	FACEBOOK	Owo Milo	LOL_WILDRIFT	340	https://drive.google.com/uc?id=1Q64uDxGpqUK0RosEOfYpdqNpx2-wOOwo	https://drive.google.com/uc?id=1dBNlz2G-56jBDqBnI6EnuKEFbYdRf65S	\N	1	1850WC x1	272.54	67.46	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 18:10:41.558355+00
168	ODR-20250818-6813	2025-08-15 10:46:22+00	FACEBOOK	Bank Apisit	DUNK_DYNASTY	159	https://drive.google.com/uc?id=1gSvpoDRmLnTE-PAsAhoxoZkMKbOZz2Pl	https://drive.google.com/uc?id=10XPQc46SMtcF6ACgH9BsNeNNGcyM61gE	\N	1	Premium Pass x1	140.7	18.3	รายการสำเร็จ	เกรซ	RAZERGOLD	ใช้เครดิตที่โอนมาเกิน10บาท, 5.24x26.85	2025-08-18 18:09:11.743559+00
166	ODR-20250818-7953	2025-08-15 05:32:59+00	FACEBOOK	คน'น มอ ซอ	FREEFIRE	489	https://drive.google.com/uc?id=1C3CohIokpVBKZM9Wm_0go4ZR9BPNPP1o	https://drive.google.com/uc?id=1ADvOgCkomEpzHK4ZeKOCj5da41MtuEUY	\N	1	1801 เพชร x1	470	19	รายการสำเร็จ	เกรซ	24BUYM		2025-08-18 18:06:57.79448+00
165	ODR-20250818-1769	2025-08-14 18:14:56+00	FACEBOOK	Worawit Chainaranon	DUNK_DYNASTY	169	https://drive.google.com/uc?id=12PemTIGS-Il09l5LOYMn5yYFjM6f283l	https://drive.google.com/uc?id=1lZMidJQeRTqZcp2R-S9zJks9k5Iugha6	\N	1	Premium Pass x1	141.77	27.23	รายการสำเร็จ	แทน	RAZERGOLD	5.28x26.85	2025-08-18 18:06:01.903199+00
161	ODR-20250818-4887	2025-08-14 12:14:46+00	LINE	Anuwat Karitha	(🌹) LOL_WILDRIFT	1078	https://drive.google.com/uc?id=1OJ7AfCQjjMLqhydqo0NbJox5kbk6f528	https://drive.google.com/uc?id=1XLGL4DhHVpfzWe7DdpGwEyvlsrfF829G	\N	1	(ROSE) 5225WC x1	867.03	210.97	รายการสำเร็จ	เกรซ	YOUTRIP	ลูกค้าไอดีต่างประเทศเติมด้วยเรทต่างจากปกติ	2025-08-18 18:02:14.035432+00
159	ODR-20250818-6252	2025-08-14 04:56:23+00	FACEBOOK	Methus Lapchaicharoenkit	TFT_MOBILE	2119	https://drive.google.com/uc?id=1E5qVGhA5Q2InwAD7u2jkJUvBnU_3eRLW	https://drive.google.com/uc?id=1YWoCLzyeEPTWLOaGHUz3PhMnRXppbvV8	\N	1	13500TFT x1	1846.49	272.51	รายการสำเร็จ	แทน	YOUTRIP		2025-08-18 17:59:45.438875+00
156	ODR-20250818-5109	2025-08-13 18:39:13+00	FACEBOOK	เนีย'ง แชม'ป์	MINECRAFT	69	https://drive.google.com/uc?id=1FOGKvnZmt8577ncew9NaewE5rGk-cf5p	https://drive.google.com/uc?id=1DO0qm80IRJRTCBvcsR-j1C8NsDMFvY_Z	\N	1	640 เหรียญ x1	11.24	57.76	รายการสำเร็จ	แทน	YOUTRIP		2025-08-18 17:55:59.672318+00
155	ODR-20250818-4985	2025-08-13 17:52:38+00	FACEBOOK	Kaopun Tangchutaveesub	(ID-PASS) เติมได้หลายเกม	289	https://drive.google.com/uc?id=1PwHFL7YUisLU85uEshJ9juFtWYRO0_vw	https://drive.google.com/uc?id=19-hdxZO3soTl-kKjM_543vrAdfR22v1S	\N	1	399 BAHT (9.99$) x1	252.75	36.25	รายการสำเร็จ	แทน	ITUNES		2025-08-18 17:55:14.350512+00
150	ODR-20250818-1102	2025-08-13 06:22:58+00	FACEBOOK	ทักษ์ดนัย ไปร์ ร่มรื่น	LOL_WILDRIFT	190	https://drive.google.com/uc?id=18MX1aoPHu9kBtDQT96WKJpOtCg5dARjo	https://drive.google.com/uc?id=1zt-4WLFt2o2MFhqF1t8wYCFCygeyVm7M	\N	1	1000WC x1	152.89	37.11	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 17:50:16.666211+00
148	ODR-20250818-5962	2025-08-12 12:00:44+00	LINE	w	(🌹) LOL_WILDRIFT	559	https://drive.google.com/uc?id=13wt5fbLUxsp4KxGved1ZTDfH1LChE68s	https://drive.google.com/uc?id=1Moh9wyaDEQQnHNAecsQPajwVXXubf8dL	\N	1	(ROSE) 3275WC x1	466.29	92.71	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 17:47:05.641995+00
145	ODR-20250818-5753	2025-08-12 08:01:47+00	FACEBOOK	Dusnee Watt	(🌹) LOL_WILDRIFT	1590	https://drive.google.com/uc?id=1ETgrCB1FDTN7FsyP1h7v8SNKwBsQze5Y	https://drive.google.com/uc?id=1rR8MJhasrfOODlx2ur9nETeJqEzNPjts	\N	1	(ROSE) 10000WC x1	1366.7	223.3	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 17:44:44.927921+00
143	ODR-20250818-6370	2025-08-12 02:30:14+00	FACEBOOK	ทักษ์ดนัย ไปร์ ร่มรื่น	(🌹) LOL_WILDRIFT	559	https://drive.google.com/uc?id=1Y4qNYQTwI26Z4RHIUOjMbxPbTVvVWBND	https://drive.google.com/uc?id=1qrIoHVWmB5hIq1lIf4nlTycYtnGj7Aaf	\N	1	(ROSE) 3275WC x1	466.29	92.71	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 17:43:10.306241+00
137	ODR-20250818-2518	2025-08-11 08:50:33+00	FACEBOOK	Tar Siripast	DELTA_FORCE	239	https://drive.google.com/uc?id=1rVCUkHmQNxGLFFI5RplM8_dSbrti-6yW	https://drive.google.com/uc?id=16xpHSKXigP732zoJHhvkf0JPzN3bHs4U	\N	1	แบทเทิลพาส (all) x1	198.99	40.01	รายการสำเร็จ	เกรซ	RAZERGOLD	1.26x27.30 + 6.13x26.85	2025-08-18 17:37:35.478821+00
138	ODR-20250818-3345	2025-08-11 08:53:26+00	FACEBOOK	ปารมี ตุลารักษ์	MINECRAFT	209	https://drive.google.com/uc?id=1zJFFiavCGO0Wmd2JU5ZLySoDaVQQnGNc	https://drive.google.com/uc?id=14wkj7Zlsl3oJiSpkrrlzrQUE-IopG_P4	\N	1	3500 เหรียญ x1	56.23	152.77	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-18 17:38:29.409436+00
135	ODR-20250818-1947	2025-08-10 18:42:46+00	FACEBOOK	Nattasit Teankai	(🌹) LOL_WILDRIFT	1590	https://drive.google.com/uc?id=1_bhZEWrBZnrVBUPq1bv2wJ5VSMQkM0tS	https://drive.google.com/uc?id=1pChViy8iY6GPqk0y8Xst-O1poyYr6cOo	\N	1	(ROSE) 10000WC x1	1365.86	224.14	รายการสำเร็จ	แทน	YOUTRIP		2025-08-18 17:33:54.738483+00
133	ODR-20250818-2110	2025-08-10 13:23:16+00	FACEBOOK	ฝันดี นะค้าบ	(ID-PASS) เติมได้หลายเกม	310.02	https://drive.google.com/uc?id=1eAwLv640_9vBa5D9MnGEqLrL52Twus-G	https://drive.google.com/uc?id=14EJAhrjyeF6NQHxInxvdlSoJ7ggt1JCJ	\N	1	399 BAHT (9.99$) x1	252.75	57.27	รายการสำเร็จ	แทน	ITUNES	9.99*25.30	2025-08-18 17:31:40.849546+00
130	ODR-20250818-6335	2025-08-10 05:18:49+00	FACEBOOK	Chawin Lerdsiwapon	(🌹) LOL_WILDRIFT	789.07	https://drive.google.com/uc?id=13-V30-BgzaGsQiDq63k2WGiPSWDOj2XE	https://drive.google.com/uc?id=1747MHIdEXZDyvvnL0sfTc0E3wdYGOpho	\N	1	(ROSE) 4800WC x1	662.84	126.23	รายการสำเร็จ	แทน	YOUTRIP		2025-08-18 17:28:16.515283+00
127	ODR-20250818-3962	2025-08-10 02:22:35+00	FACEBOOK	Bank Apisit	DUNK_DYNASTY	169	https://drive.google.com/uc?id=1bqYqUA709maA4J-7dlEGdfwxy6Sd6qZH	https://drive.google.com/uc?id=11A-PUl-8fD0N5qT0UWEX5pq-BIhe7kA7	\N	1	Party Membership x1	127.64	41.36	รายการสำเร็จ	แทน	RAZERGOLD	ลูกค้าโอนเกินมา 10 บาท/เครดิต 10 บาท, 4.71*27.10	2025-08-18 17:25:13.141876+00
124	ODR-20250818-5301	2025-08-09 21:10:06+00	FACEBOOK	Nvmmxn Raungsuparut	(🌹) LOL_WILDRIFT	889	https://drive.google.com/uc?id=1n_QmGYFA3nHQPAh0ayPFDQS07_NQRTf7	https://drive.google.com/uc?id=1jj7JUxJ7Ej8ryLK96P0bPA-Qi7woz2w0	\N	1	(ROSE) 5225WC x1	662.84	226.16	รายการสำเร็จ	แทน	YOUTRIP		2025-08-18 17:22:03.31091+00
227	ODR-20250822-6685	2025-08-22 03:20:31+00	LINE	Kaoglong	(🌹) LOL_WILDRIFT	789	https://drive.google.com/uc?id=1rPS_eh_FQOW9lywXQXoyvEMqAOfHZUhd	https://drive.google.com/uc?id=1irpavlnNDTJ_tYIDFjxxfPIUg6oany-A	\N	1	(ROSE) 4800WC x1	661.28	127.72	รายการสำเร็จ	แทน	YOUTRIP		2025-08-22 16:28:55.909385+00
228	ODR-20250822-8452	2025-08-22 04:28:00+00	LINE	Kaoglong	(🌹) LOL_WILDRIFT	878	https://drive.google.com/uc?id=1Ub4d1elzE88CJJQOXJ0CCevwnmN2rIdp	https://drive.google.com/uc?id=1JbXgm7BdU3bO2DgWnm7LddK3wOZTuL6f	\N	2	STELLACORN x1, (ROSE) 4800WC x1	729.41	148.59	รายการสำเร็จ	แทน	YOUTRIP		2025-08-22 16:32:43.680548+00
236	ODR-20250822-5244	2025-08-22 16:00:05+00	FACEBOOK	River Flows Through	MINECRAFT	35	https://drive.google.com/uc?id=12QGlSAVNL2KPyXgXQdTOCd_Wwi5Zh0_v	https://drive.google.com/uc?id=1sKp_Z1jfhha3rff8cnN16rN3e2GgfA1o	\N	1	320 เหรียญ x1	5.6	29.4	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-22 16:58:07.773006+00
234	ODR-20250822-1766	2025-08-22 12:11:09+00	FACEBOOK	Methasit Pumphothong	VALORANT	885	https://drive.google.com/uc?id=1CeGMIwHhBkYkklK_WeQLpq9kixb-7v-3	https://drive.google.com/uc?id=1S7MbgtKZOsMGYBdROqExHyc60HlEF18k	\N	1	3650VP x1	851	34	รายการสำเร็จ	เกรซ	RICHMAN		2025-08-22 16:54:51.524096+00
235	ODR-20250822-5449	2025-08-22 14:53:41+00	FACEBOOK	Theeraphat Sakulpaprasert	(🌹) LOL_WILDRIFT	1570.03	https://drive.google.com/uc?id=1I1s2RA-66s7VMq5KbUtH7sY2wxruL37Z	https://drive.google.com/uc?id=1gvy_gdnlrIIf2LIGLrXw-XFtb2s384pu	\N	1	(ROSE) 10000WC x1	1362.63	207.4	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-22 16:56:52.479897+00
237	ODR-20250822-3114	2025-08-22 16:07:03+00	FACEBOOK	Theeraphat Sakulpaprasert	(🌹) LOL_WILDRIFT	869	https://drive.google.com/uc?id=1zx2JNs1snkl_UOFysFVRN9fbImoy8ZdT	https://drive.google.com/uc?id=1-IZGJNSmYHUEYRdSJm7N3pFeysRN4VdF	\N	1	(ROSE) 5225WC x1	729.41	139.59	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-22 16:59:14.063801+00
231	ODR-20250822-8105	2025-08-22 06:41:42+00	FACEBOOK	Danai Saraban	MINECRAFT	199	https://drive.google.com/uc?id=1orWouerOMdMK1bZRibG9UIN5cJEIYUCg	https://drive.google.com/uc?id=1mzTASJmSMAUffgHxi7Ubi2SgfmOs-cKd	\N	1	1920 เหรียญ x1	33.6	165.4	รายการสำเร็จ	แทน	YOUTRIP		2025-08-22 16:49:18.242955+00
233	ODR-20250822-1824	2025-08-22 10:21:44+00	FACEBOOK	Kanokwan BJ	VALORANT	2129	https://drive.google.com/uc?id=1fiuR3As9ZECHCi9t8u4FmYSez-xFGdob	https://drive.google.com/uc?id=1jeThbIEMkVE4jsNSRlPmJdUVatGvBzYi	\N	1	[8750VP] DEATHWISH เหมาหมด x1	2053.5	75.5	รายการสำเร็จ	เกรซ	RICHMAN		2025-08-22 16:53:28.986945+00
232	ODR-20250822-6111	2025-08-22 07:12:55+00	FACEBOOK	Phoonsup Udomsri	DUNK_DYNASTY	159	https://drive.google.com/uc?id=1qR-63i90EWnCHUFtoXVKCQkhTZbamipi	https://drive.google.com/uc?id=1YNX8LRsyxnFNZy_CYjSvnWUxEat47Rvc	\N	1	Party Membership x1	126.56	32.44	รายการสำเร็จ	แทน	RAZERGOLD	4.67*27.10	2025-08-22 16:51:06.545596+00
230	ODR-20250822-1521	2025-08-22 06:41:04+00	FACEBOOK	ชลลดา กระพลอย	VALORANT	625	https://drive.google.com/uc?id=1lAtgxdfJo-9ck0AqrHEvYy6Iqmp0I2kx	https://drive.google.com/uc?id=1ST_O-A4uYsO5vW4dUNQRROCZObESY3hZ	\N	1	[2525VP] DEATHWISH ปืนแยก x1	601.3	23.7	รายการสำเร็จ	แทน	RICHMAN		2025-08-22 16:47:14.470521+00
436	ODR-20250912-6896	2025-09-11 17:44:02+00	FACEBOOK	Mekk Ponthep	TFT_MOBILE	1890	https://drive.google.com/uc?id=1LHcnWnb37NMytGXXlr_I4mXomKbEHi2S	https://drive.google.com/uc?id=1VWExNcsyinalu1wWJ6B_hZQOOf-hYZeJ	\N	1	13500TFT x1	1786.4	103.6	รายการสำเร็จ	แทน	YOUTRIP		2025-09-12 14:45:30.134245+00
229	ODR-20250822-2760	2025-08-22 06:02:00+00	FACEBOOK	Charlies Peeraphol	(🌹) LOL_WILDRIFT	789	https://drive.google.com/uc?id=1EQVxidAU-yhTiBf9Mw98i61SpHgBgtKJ	https://drive.google.com/uc?id=1VC7J4zLzMmIuSeAo2lvE_Zc50FsISgyJ	\N	1	(ROSE) 4800WC x1	661.28	127.72	รายการสำเร็จ	แทน	YOUTRIP		2025-08-22 16:44:23.317987+00
226	ODR-20250822-1206	2025-08-21 17:47:34+00	FACEBOOK	Supakan Jittamaro	LOL_WILDRIFT	340.01	https://drive.google.com/uc?id=1HnNP1bMbLKj44QjZqx17pPcx4ffquJxZ	https://drive.google.com/uc?id=1jZWw7F-G363IartXEVnmpxoQy-XB_Ovm	\N	1	1850WC x1	272.73	67.28	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-22 16:25:05.085706+00
242	ODR-20250823-7344	2025-08-23 04:08:22+00	LINE	MOS Tanakon	COA	2829	https://drive.google.com/uc?id=1gr5Gxs0TyXPNB1gDu6YGRU42uV-o89eF	https://drive.google.com/uc?id=1pl4TJZjVaBoVy_BWRtKNJUf8Uv3fSUe1	\N	1	8606 โอปอล x1	2674.54	154.46	รายการสำเร็จ	แทน	RAZERGOLD	100.17*26.70	2025-08-23 16:16:25.928122+00
253	ODR-20250823-2353	2025-08-23 14:50:18+00	FACEBOOK	Jaofarmza Eiei	DUNK_DYNASTY	318	https://drive.google.com/uc?id=1do9Scn1L76vR8CtXCBBsRmUnV-vmIxfN	https://drive.google.com/uc?id=1El1LEX5giVF4YJFYUoll3gJoud93EHqN	\N	2	330TOKENS x1, Party Membership x1	250.78	67.22	รายการสำเร็จ	เกรซ	RAZERGOLD	9.34*26.85	2025-08-23 16:26:16.174994+00
252	ODR-20250823-7239	2025-08-23 14:04:00+00	FACEBOOK	Wutthipat Lueangronthong	DUNK_DYNASTY	159	https://drive.google.com/uc?id=1g6miZJTopxRRrLk5bCS7XsHMUv_sgUaN	https://drive.google.com/uc?id=1amdEybL2sxQWGLDmjthDjkRDVIIdT4kW	\N	1	Party Membership x1	125.39	33.61	รายการสำเร็จ	เกรซ	RAZERGOLD	4.67*26.85	2025-08-23 16:25:42.563508+00
251	ODR-20250823-1646	2025-08-23 14:01:33+00	FACEBOOK	Punnathon Tekootong	VALORANT	505	https://drive.google.com/uc?id=1TBpLDeunyH4okfGyEH3XWRq-bU_d9P-L	https://drive.google.com/uc?id=1Fzeu54aV__Aa9Mpvv6uzc7mJ9QjxG9n3	\N	1	2050VP x1	481	24	รายการสำเร็จ	เกรซ	RICHMAN		2025-08-23 16:25:11.574156+00
249	ODR-20250823-2905	2025-08-23 09:20:55+00	FACEBOOK	Mai Kup	TFT_MOBILE	239	https://drive.google.com/uc?id=1vnNdud5lTJ9eI-d0kLHGHRcc-Kk3gIsi	https://drive.google.com/uc?id=10SeRKemSb4eepFUw--a23wUakGv5kaB8	\N	1	1380TFT x1	200.71	38.29	รายการสำเร็จ	แทน	YOUTRIP		2025-08-23 16:23:18.321569+00
248	ODR-20250823-9412	2025-08-23 08:11:02+00	FACEBOOK	River Flows Through	MINECRAFT	35	https://drive.google.com/uc?id=1c4x8P-9p_X6iNdYKAGN8LpyXofzBLiFs	https://drive.google.com/uc?id=1RM1ZlCJVFvy1q6wfh5Qt4SBL3BdALUBh	\N	1	320 เหรียญ x1	5.61	29.39	รายการสำเร็จ	แทน	YOUTRIP		2025-08-23 16:22:32.820588+00
247	ODR-20250823-3377	2025-08-23 07:58:25+00	FACEBOOK	River Flows Through	MINECRAFT	129	https://drive.google.com/uc?id=1ivkc3CrU9BKXQffLvT3voVB5yq0id92D	https://drive.google.com/uc?id=1xrna0AWBfAlSEe4bRMiwpG7N4XpwW3Cn	\N	1	1280 เหรียญ x1	22.44	106.56	รายการสำเร็จ	แทน	YOUTRIP		2025-08-23 16:21:59.116112+00
246	ODR-20250823-4119	2025-08-23 07:51:38+00	LINE	菲希。	MINECRAFT	209	https://drive.google.com/uc?id=1ClLMiHt9d_3JT9ild_41emBo9zmTdyD8	https://drive.google.com/uc?id=13rw-vQ3kfXxTMp9s3IAp4e5oYyTzJ0t6	\N	1	3500 เหรียญ x1	56.19	152.81	รายการสำเร็จ	แทน	YOUTRIP		2025-08-23 16:21:15.856475+00
245	ODR-20250823-8779	2025-08-23 06:26:03+00	LINE	菲希。	MINECRAFT	129	https://drive.google.com/uc?id=1rwgjQmDxMv6AsQW0fuD3MmESaveSQF7e	https://drive.google.com/uc?id=1HGmzA0PJ0DAE6rYHvHunKCDWImvP4LhP	\N	1	1280 เหรียญ x1	22.44	106.56	รายการสำเร็จ	แทน	YOUTRIP		2025-08-23 16:20:16.028227+00
244	ODR-20250823-3045	2025-08-23 04:36:52+00	FACEBOOK	Punpapron Boonmee	MINECRAFT	35	https://drive.google.com/uc?id=1V5-smQM8fGtOpC_guMtDpw0WgGnWJImb	https://drive.google.com/uc?id=1oAvo_q-VzwUDZZnzUPG1PXLc90t8r8qs	\N	1	320 เหรียญ x1	5.61	29.39	รายการสำเร็จ	แทน	YOUTRIP		2025-08-23 16:19:08.369736+00
243	ODR-20250823-6487	2025-08-23 04:23:16+00	FACEBOOK	Ba Ros	VALORANT	2130	https://drive.google.com/uc?id=15quIO2ASWxFNUJa-jDmOZ0tXLBhvlLBl	https://drive.google.com/uc?id=19oI1PRStiF9v-bRAYSuAs04H_bOxML00	\N	1	[8750VP] DEATHWISH เหมาหมด x1	2053.5	76.5	รายการสำเร็จ	แทน	RICHMAN		2025-08-23 16:17:38.659629+00
241	ODR-20250823-3270	2025-08-23 00:46:35+00	FACEBOOK	ShadowHand Quillen	(🌹) LOL_WILDRIFT	559	https://drive.google.com/uc?id=1tdD0MGBvFx-4lO8BYWyhik4i-VBlOwQW	https://drive.google.com/uc?id=1ILqdh1vcYIgpCAvhPGj_wCSEoIwA_iWE	\N	1	(ROSE) 3275WC x1	465.64	93.36	รายการสำเร็จ	แทน	YOUTRIP		2025-08-23 16:15:02.034177+00
240	ODR-20250823-3777	2025-08-22 22:14:51+00	FACEBOOK	Charlies Peeraphol	(🌹) LOL_WILDRIFT	559	https://drive.google.com/uc?id=1YXOQPfJ9O7XOhndC0fMN8bBgnP2RKDO5	https://drive.google.com/uc?id=134Z0wBnxCHKi-L0S4GS45zILcQcS05SP	\N	1	(ROSE) 3275WC x1	465.64	93.36	รายการสำเร็จ	แทน	YOUTRIP		2025-08-23 16:14:14.829013+00
239	ODR-20250823-2332	2025-08-22 18:47:16+00	FACEBOOK	Thanapat Beer	LOL_WILDRIFT	89	https://drive.google.com/uc?id=1peyPkA8AOJRfxmdgfzWHKjFu6UXPELz6	https://drive.google.com/uc?id=1w9IXaXjfBQrLE8klAt_0icWA-A2gJqpu	\N	1	425WC x1	68.13	20.87	รายการสำเร็จ	แทน	YOUTRIP		2025-08-23 16:13:29.068044+00
238	ODR-20250823-8005	2025-08-22 17:44:34+00	FACEBOOK	Pond Rasri	(🌹) LOL_WILDRIFT	1590	https://drive.google.com/uc?id=18BLISq7qlPqj3vOBy5mx_Ni-LTv6flM1	https://drive.google.com/uc?id=1CIKKWJwell1DNWtKFGaxfLgJLf_Xs_qU	\N	1	(ROSE) 10000WC x1	1362.63	227.37	รายการสำเร็จ	แทน	YOUTRIP		2025-08-23 16:12:29.798386+00
250	ODR-20250823-6638	2025-08-23 10:48:25+00	LINE	MOS Tanakon	COA	869	https://drive.google.com/uc?id=100kp0ym1yCzt-DhrLud5KLjF2x8_WZSC	https://drive.google.com/uc?id=1GKsUiykuErf-2fBBMGMN8OGTnzinrCRJ	\N	1	2479 โอปอล x1	802.87	66.13	รายการสำเร็จ	แทน	RAZERGOLD	30.07*26.70	2025-08-23 16:24:42.325703+00
122	ODR-20250817-1444	2025-08-09 16:25:13+00	LINE	ᵂ	ROV_MOBILE	975	https://drive.google.com/uc?id=1Mft8pk8GBapCYEcL6UIdyS6J2e8XDB6r	https://drive.google.com/uc?id=1eGXHvIFjgqeGrzMgmmRNhHHZD4argWHm	\N	1	1240 ปอง x1	940	35	รายการสำเร็จ	แทน	24BUYM		2025-08-17 17:46:23.678667+00
119	ODR-20250817-4087	2025-08-09 13:45:53+00	FACEBOOK	IBeg Chutrakul	(🌹) LOL_WILDRIFT	4749.03	https://drive.google.com/uc?id=1iyjEFnVfXoRKZrT9k3osBwKyzSe7q67e	https://drive.google.com/uc?id=17rKOAgPQX9qBproUL3O8Lwyv0HdgDvpk	\N	1	(ROSE) 30000WC x1	4097.58	651.45	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-17 17:44:02.162976+00
117	ODR-20250817-3546	2025-08-09 11:38:00+00	FACEBOOK	Max Jessada	(🌹) LOL_WILDRIFT	1359	https://drive.google.com/uc?id=1tDUGG2xZugMs691NATucpHoeENZ4L7uf	https://drive.google.com/uc?id=1CudG2E7P9O4_LoLDmBxrimKstOsfZTSE	\N	1	(ROSE) 8075WC x1	1128.84	230.16	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-17 17:41:57.285357+00
114	ODR-20250817-2670	2025-08-09 09:52:08+00	FACEBOOK	Ma Leen	(🌹) LOL_WILDRIFT	1119	https://drive.google.com/uc?id=1YCuVy5TPZkujuYBDQa88W5mQw-0zwFqK	https://drive.google.com/uc?id=1GDKAPJqEr8-5pyiJDAFLJsc68BT0pAAN	\N	1	(ROSE) 6650WC x1	936.01	182.99	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-17 17:40:04.562319+00
112	ODR-20250817-2346	2025-08-09 08:51:00+00	FACEBOOK	Ba Ros	VALORANT	2535	https://drive.google.com/uc?id=1WU9LO0mVtzLdySwpNRVNCzCggblllSZG	https://drive.google.com/uc?id=1O9pCLHzxkJCz9M0WjyhkBBlWOzFXYaiS	\N	1	11000VP x1	2442	93	รายการสำเร็จ	แทน	RICHMAN		2025-08-17 17:38:12.718014+00
109	ODR-20250817-4281	2025-08-09 05:22:11+00	FACEBOOK	Mick Chisanucha	(🌹) LOL_WILDRIFT	1125.1	https://drive.google.com/uc?id=10F7M0Rkw2lUdFrFqrsvd3rfUWkROZ5kb	https://drive.google.com/uc?id=1D3RgiKPgECrBs-_Pqh57WPj1rKX4Ml44	\N	1	(ROSE) 6650WC x1	936.01	189.09	รายการสำเร็จ	แทน	YOUTRIP		2025-08-17 17:35:10.564501+00
107	ODR-20250817-1748	2025-08-09 04:48:09+00	FACEBOOK	ไอเสื้อเเดง สุดหล่อเท่ห์	LOL_WILDRIFT	570	https://drive.google.com/uc?id=144WpisQGbpQilI1PKhtnTTertnjjEuJ5	https://drive.google.com/uc?id=1eBvkZBkWzgDoRKz6gBUteWJ6ARIIHral	\N	1	3275WC x1	466	104	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-17 17:31:15.123239+00
104	ODR-20250817-8993	2025-08-09 03:47:35+00	FACEBOOK	ทักษ์ดนัย ไปร์ ร่มรื่น	LOL_WILDRIFT	340	https://drive.google.com/uc?id=16Mi8Osgf0sXCGGaSTK8EhK9iAFxWCxv0	https://drive.google.com/uc?id=11_cPtKzSQpiqcqBMYN26-QuVheQHvWMJ	\N	1	1850WC x1	273.17	66.83	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-17 17:28:48.613702+00
102	ODR-20250817-9018	2025-08-09 03:32:26+00	FACEBOOK	Pherapat Phe Nueanin	LOL_WILDRIFT	340	https://drive.google.com/uc?id=1IUv6-vJhhPCRDNPGDq-vi_z0XUsrhTrH	https://drive.google.com/uc?id=117qPoMsiSOHvqZ0NkDXJeO_3ud5X-dka	\N	1	1850WC x1	273.17	66.83	รายการสำเร็จ	แทน	YOUTRIP		2025-08-17 17:26:46.206369+00
97	ODR-20250817-8787	2025-08-09 02:15:38+00	FACEBOOK	Sumet Tongyong	LOL_WILDRIFT	190	https://drive.google.com/uc?id=1bYHHGspovI5CfwC9iv-oUN3QHNC-8jbs	https://drive.google.com/uc?id=1-NJiJfN6OvYeCSVE47eXKBRIlvH9MVRz	\N	1	1000WC x1	152.65	37.35	รายการสำเร็จ	แทน	YOUTRIP		2025-08-17 17:19:40.539537+00
95	ODR-20250817-7236	2025-08-09 01:49:49+00	FACEBOOK	Zdx Lock	LOL_WILDRIFT	570.11	https://drive.google.com/uc?id=1fOlMc4eskpIoV7Hsyv_D9g9eeF8o9Rr_	https://drive.google.com/uc?id=1s73YY097TQJ4wMD_kzRR8spEuuVu-hHR	\N	1	3275WC x1	466	104.11	รายการสำเร็จ	แทน	YOUTRIP		2025-08-17 17:17:11.752577+00
92	ODR-20250817-9559	2025-08-09 00:47:13+00	LINE	⛅️Y.	LOL_WILDRIFT	1620	https://drive.google.com/uc?id=1797t75dxFXXvYtW9zPBNnfrQgI9HHxkk	https://drive.google.com/uc?id=1iYUldJW5dyIxEJwZjwanPx0Rz0-b6-Tc	\N	1	10000WC x1	1365.86	254.14	รายการสำเร็จ	แทน	YOUTRIP		2025-08-17 17:13:05.023959+00
90	ODR-20250817-8812	2025-08-08 23:24:15+00	LINE	𝐼 𝑚𝑖𝑠𝑠 ℎ𝑒𝑟	VALORANT	505	https://drive.google.com/uc?id=1RqS1OcwYfiTB89Y04mdEAh3RGdBKWWLj	https://drive.google.com/uc?id=1Ft07iCkfD_gABXR6l6h5x61okn4fur08	\N	1	2050VP x1	481	24	รายการสำเร็จ	แทน	RICHMAN		2025-08-17 17:10:59.655476+00
87	ODR-20250817-3307	2025-08-08 12:54:46+00	FACEBOOK	ภูรินทร์ แก้วแย้ม	MINECRAFT	209	https://drive.google.com/uc?id=1ezslNQkWQsz9PiNq6lO3Jp_qR5ZfD5X-	https://drive.google.com/uc?id=1zhIOFgAHFoAQjsM2-DQLqLc8UWxT1wwA	\N	1	3500 เหรียญ x1	56.19	152.81	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-17 17:04:17.05615+00
84	ODR-20250817-7780	2025-08-08 06:55:29+00	FACEBOOK	ฝันดี นะค้าบ	(ID-PASS) เติมได้หลายเกม	918.03	https://drive.google.com/uc?id=1eXNnr72Jzi9Pc-9MrU-pQWju5U1e7ZHk	https://drive.google.com/uc?id=19ldeCebFksdYATaV-4eryg63YIx9VYuz	\N	2	499 BAHT (14.99$) x2	758.5	159.53	รายการสำเร็จ	เกรซ	ITUNES	29.98*25.30	2025-08-17 16:56:33.386849+00
258	ODR-20250824-1200	2025-08-24 16:43:59+00	FACEBOOK	Sataporn Ponyiam	RACING_MASTER	269	https://drive.google.com/uc?id=1Y7wpKau_5nEklL4iEu5RV3JpwTabIMbB	https://drive.google.com/uc?id=198sNlfqDX5yy_rsr9y0OBld6-sllmqDQ	\N	1	735GEMS x1	240.04	28.96	รายการสำเร็จ	เกรซ	RAZERGOLD		2025-08-24 17:36:23.721333+00
257	ODR-20250824-2706	2025-08-24 11:30:43+00	FACEBOOK	Kanmanee Thkl	VALORANT	625	https://drive.google.com/uc?id=1S5ZlURf7YNya__1oAH9ol59dCW0mgNwB	https://drive.google.com/uc?id=1CZVqVl9vVDv5z9nhBJVqRiCxUugbo9tP	\N	1	[2525VP] DEATHWISH ปืนแยก x1	601.3	23.7	รายการสำเร็จ	แทน	RICHMAN		2025-08-24 17:35:58.80354+00
261	ODR-20250825-2769	2025-08-25 02:39:40+00	FACEBOOK	Wachirawit Peam	DELTA_FORCE	2390	https://drive.google.com/uc?id=1kHqMEeEIqre_9IDef4YgOJel-Py8d213	https://drive.google.com/uc?id=1EU6wG98o6817VSgPQFnDr2V9AeWAbsdX	\N	1	8100DELTA x1	2264.69	125.31	รายการสำเร็จ	แทน	RAZERGOLD	84.82*26.70	2025-08-25 09:58:49.083607+00
270	ODR-20250826-7012	2025-08-26 15:38:04+00	FACEBOOK	แฟ้มไง ไม่ต้องถาม	VALORANT	250	https://drive.google.com/uc?id=1Ovtm0NEhiTdtHm0n7LDQqofBRxNgW1wv	https://drive.google.com/uc?id=1FMlbshagS8AVWSF6khTB1JoTfutGXLS3	\N	1	1000VP x1	240.5	9.5	รายการสำเร็จ	เกรซ	RICHMAN		2025-08-26 15:47:22.246624+00
269	ODR-20250826-3504	2025-08-26 15:19:28+00	FACEBOOK	แฟ้มไง ไม่ต้องถาม	VALORANT	885	https://drive.google.com/uc?id=1d3q7-H3puu3g0ILXwffeetzhR81CtZUL	https://drive.google.com/uc?id=190UOt2E4Ds2K5kamEs52WSR28m2sZMsi	\N	1	3650VP x1	851	34	รายการสำเร็จ	เกรซ	RICHMAN		2025-08-26 15:46:56.246951+00
267	ODR-20250826-9680	2025-08-26 10:46:21+00	FACEBOOK	ฮอลล์	MINECRAFT	209	https://drive.google.com/uc?id=1Gj2QZe7eY912Z0Q-DRln06pw_b9Rfwhi	https://drive.google.com/uc?id=1KKvhTkblTqdukTQGBNyEAwbwqSqFfhyy	\N	1	3500 เหรียญ x1	56.06	152.94	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-26 15:45:45.019345+00
266	ODR-20250826-6643	2025-08-26 04:33:34+00	FACEBOOK	Nantiwat Suksawat	DUNK_DYNASTY	169	https://drive.google.com/uc?id=1gs2uWAzaeqQjAxEPVVkZB2tULWReqOor	https://drive.google.com/uc?id=1EI2daTXZl3Am7_DPFXeXBcfGtBf0c4cB	\N	1	Premium Pass x1	141.5	27.5	รายการสำเร็จ	แทน	RAZERGOLD	5.27*26.85	2025-08-26 15:45:13.310697+00
264	ODR-20250826-3448	2025-08-25 17:10:04+00	FACEBOOK	ฮอลล์	MINECRAFT	209	https://drive.google.com/uc?id=1khmlNrp6fnaxrIT__QEpRmkRRc5d1Gg7	https://drive.google.com/uc?id=1_Xgu2AH1IYIOO_qLC8eqzPmLMQ3lumYL	\N	1	3500 เหรียญ x1	56.19	152.81	รายการสำเร็จ	แทน	YOUTRIP		2025-08-26 15:44:09.31401+00
262	ODR-20250825-2720	2025-08-25 09:51:26+00	FACEBOOK	Sarunwath Chanthajohn	VALORANT	2535	https://drive.google.com/uc?id=1Wz7l9FGQ2G9HUSZebFeoAruynRTp2kmY	https://drive.google.com/uc?id=1LCyU6ALA3qv_o1lrzWWfGPAF3fZ8KlBH	\N	1	11000VP x1	2442	93	รายการสำเร็จ	เกรซ	RICHMAN		2025-08-25 09:59:29.517941+00
256	ODR-20250824-4743	2025-08-24 09:37:02+00	FACEBOOK	Dagga Roll	DUNK_DYNASTY	159	https://drive.google.com/uc?id=1A8_8h6PKaGxnySgePzb_wM8nHJ3ZmxHZ	https://drive.google.com/uc?id=1HGJmuDsE0ocofsAXUk3JbGOoINP76IeR	\N	1	Party Membership x1	125.39	33.61	รายการสำเร็จ	แทน	RAZERGOLD	4.67*26.85	2025-08-24 17:35:23.865227+00
259	ODR-20250825-8920	2025-08-24 19:21:04+00	FACEBOOK	Wachirawit Peam	HONKAI_STARRAIL	2390	https://drive.google.com/uc?id=1J8Fo1a_fpZpTJse9mpX3QYuvrpVkY1ZP	https://drive.google.com/uc?id=15KL0pRphMT5_rMA7trmh-QqSpNMAsUx4	\N	1	8080SHARD x1	2285	105	รายการสำเร็จ	แทน	RICHMAN		2025-08-25 09:56:53.078805+00
254	ODR-20250824-4683	2025-08-23 18:35:57+00	FACEBOOK	Kotchamon Wonganankij	TFT_MOBILE	239	https://drive.google.com/uc?id=13npRuXxixSF2WxPWXIwuRH6N5LRae3Fq	https://drive.google.com/uc?id=1tmDI5UXcxsKzjrZgpvIao8LEUX5YXDjA	\N	1	1380TFT x1	200.71	38.29	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-24 17:32:53.229317+00
283	ODR-20250827-3685	2025-08-27 14:59:20+00	FACEBOOK	Peeradech Rungsiri	DUNK_DYNASTY	279	https://drive.google.com/uc?id=1p0G8dSeeg7bQgkUkBu5yhz_p6SVyN7QN	https://drive.google.com/uc?id=16G1oS1fIosw4YkY0QWA9bs-zzETRXtqZ	\N	1	Extra Premium Pass x1	235.21	43.79	รายการสำเร็จ	เกรซ	RAZERGOLD	8.76*26.85	2025-08-27 22:39:24.151419+00
282	ODR-20250827-8256	2025-08-27 12:42:51+00	FACEBOOK	Possavee Dhammasiri	RACING (LOGIN)	539	https://drive.google.com/uc?id=1OzlQ29eOIMMOWpFd2KKiqTRGYCEF8qvo	https://drive.google.com/uc?id=1UcJ7qSdrUSvZn6ym0zwQ2pjqb_ki32XD	\N	1	669BAHT ($19.99) x1	476.05	62.95	รายการสำเร็จ	แทน	RAZERGOLD	17.73*26.85	2025-08-27 22:38:59.006582+00
281	ODR-20250827-3200	2025-08-27 12:05:55+00	FACEBOOK	Dratae Rublik	VALORANT	250	https://drive.google.com/uc?id=1lwlACFWxf27QU1JFoRjIoXugyto3BP4H	https://drive.google.com/uc?id=15JMv_UTuUQPLjRPKg91pQEWm1u_8JsDC	\N	1	1000VP x1	240.5	9.5	รายการสำเร็จ	แทน	RICHMAN		2025-08-27 22:37:57.776457+00
280	ODR-20250827-5224	2025-08-27 11:07:41+00	FACEBOOK	โคโดโมะ จ้า	(🌹) LOL_WILDRIFT	1590	https://drive.google.com/uc?id=1ry5VCGmh7HEtkPNs2HX8EbUxBYJAXRQe	https://drive.google.com/uc?id=1pMeg-IEkeF2YGD-y6nSH-dzLZP1_9d2p	\N	1	(ROSE) 10000WC x1	1355.77	234.23	รายการสำเร็จ	แทน	YOUTRIP		2025-08-27 22:36:36.583219+00
279	ODR-20250827-1886	2025-08-27 10:17:45+00	FACEBOOK	Jaofarmza Eiei	DUNK_DYNASTY	159	https://drive.google.com/uc?id=18xJu7xI2jtyqWIS7Tim7okkxtgVsB0qN	https://drive.google.com/uc?id=15UN5vF-cRfCVWreFRYUe0Gdkk79ZWe49	\N	1	330TOKENS x1	126.2	32.8	รายการสำเร็จ	แทน	RAZERGOLD	4.70*26.85	2025-08-27 22:35:46.907477+00
278	ODR-20250827-1921	2025-08-27 10:12:26+00	FACEBOOK	Kun Chonnakun Wiset	DUNK_DYNASTY	159	https://drive.google.com/uc?id=1P59LEQKFvfmseZSeqr1Tm6J05wpAaTDj	https://drive.google.com/uc?id=1mzWJ63bNPDNrV5cFChDXFdxuVyEInp5m	\N	1	Party Membership x1	126.2	32.8	รายการสำเร็จ	แทน	RAZERGOLD		2025-08-27 22:35:10.076919+00
277	ODR-20250827-8259	2025-08-27 09:53:15+00	FACEBOOK	Santa Like	(🌹) LOL_WILDRIFT	789.01	https://drive.google.com/uc?id=1rUH-EllYRh9l0PLrvcKvMEwiWxci3dv3	https://drive.google.com/uc?id=1DtkJIS1AQGb1-HxKjuHEmVJcJfu7lgv5	\N	1	(ROSE) 4800WC x1	657.95	131.06	รายการสำเร็จ	แทน	YOUTRIP		2025-08-27 22:34:10.717254+00
276	ODR-20250827-5584	2025-08-27 09:54:15+00	FACEBOOK	Araya Nattavaranon	TFT_MOBILE	749	https://drive.google.com/uc?id=1oc7sVtDvyEZsQF-cVUsVBn93poPO04Cx	https://drive.google.com/uc?id=1OOag4TGp_cnnzpKR2MmvqiEbXthmeYYg	\N	1	4500TFT x1	638.01	110.99	รายการสำเร็จ	แทน	YOUTRIP		2025-08-27 22:33:21.631222+00
275	ODR-20250827-7335	2025-08-27 08:17:57+00	FACEBOOK	Jaofarmza Eiei	DUNK_DYNASTY	159	https://drive.google.com/uc?id=1WCt-_sYif-0KhViQMYiADOHHoeRowUfN	https://drive.google.com/uc?id=1ffbNpUggHEelHJlhqPFKIuS5r5ikpAap	\N	1	330TOKENS x1	126.2	32.8	รายการสำเร็จ	แทน	RAZERGOLD	4.70*26.85	2025-08-27 22:32:29.586702+00
274	ODR-20250827-2999	2025-08-27 07:32:43+00	FACEBOOK	Phoonsup Udomsri	DUNK_DYNASTY	169	https://drive.google.com/uc?id=1UjcqCEm061gFsHspgEtsYcC7PQLp_jB8	https://drive.google.com/uc?id=1QyO722DJZ5sA7ZX98Dk6HvaYy8oimx5U	\N	1	Premium Pass x1	140.96	28.04	รายการสำเร็จ	แทน	RAZERGOLD	5.25*26.85	2025-08-27 22:30:56.40061+00
273	ODR-20250827-2602	2025-08-27 04:40:44+00	FACEBOOK	จักรวาล สาปลั่ง	RACING_MASTER	249	https://drive.google.com/uc?id=1r-FIHdah0FYHFjAsWuGamDtFIxlHFU_f	https://drive.google.com/uc?id=1hTO3Hkz1ZoyVQpT9GQB6OwjDOcNg6WaA	\N	1	สัญญาพิเศษ (PREMIUM) x1	223.93	25.07	รายการสำเร็จ	แทน	RAZERGOLD	8.34*26.85	2025-08-27 22:29:43.706697+00
272	ODR-20250827-3398	2025-08-26 18:41:23+00	FACEBOOK	ฝันดี นะค้าบ	VALORANT	625	https://drive.google.com/uc?id=1xzln9VWacsac_8mJBVkDIj5t5hKS8p4M	https://drive.google.com/uc?id=1LjdFSpKy75LRCFxRDPrBr4F9cLqC9jP_	\N	1	[2525VP] DEATHWISH ปืนแยก x1	601.3	23.7	รายการสำเร็จ	แทน	RICHMAN		2025-08-27 22:28:56.224457+00
271	ODR-20250827-9228	2025-08-26 17:05:43+00	FACEBOOK	Natthaphat Chanthawan	MINECRAFT	105	https://drive.google.com/uc?id=1PlZ_dkldG2pV6t7FluphHXaoqMwzHkgh	https://drive.google.com/uc?id=19rf9qy_pmrzYAkA3fo7Xp0wRMsiiKy_3	\N	1	960 เหรียญ x1	16.8	88.2	รายการสำเร็จ	แทน	YOUTRIP		2025-08-27 22:28:22.35397+00
290	ODR-20250828-4351	2025-08-28 09:56:28+00	FACEBOOK	Kanitta Chaiyakan	RACING_MASTER	29	https://drive.google.com/uc?id=1Rmlysjfwy7Yc3O6h-vBtVon9C7uY6jvR	https://drive.google.com/uc?id=13r0BEWihUNOlnqbSbHSn2O9E5qCejLZv	\N	1	74GEMS x1	24.2	4.8	รายการสำเร็จ	แทน	RAZERGOLD	0.88*27.50	2025-08-28 15:56:20.383239+00
292	ODR-20250828-2618	2025-08-28 15:29:42+00	FACEBOOK	Pond Rasri	(🌹) LOL_WILDRIFT	1590	https://drive.google.com/uc?id=1qGkIXbjRGtdeaPL3jS61kdfHNMo5FMiM	https://drive.google.com/uc?id=1etowpfAv9_6xFZxrfaneiBgh_ud0Uugs	\N	1	(ROSE) 10000WC x1	1357.08	232.92	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-28 15:57:33.217701+00
291	ODR-20250828-3871	2025-08-28 15:05:46+00	FACEBOOK	Pond Rasri	(🌹) LOL_WILDRIFT	1590	https://drive.google.com/uc?id=1Xj2xgAgqh2N2MsThRdliga7msluLYteT	https://drive.google.com/uc?id=1lcv8QXTXy_6KvptRhRUH7FO3IGjvcBBw	\N	1	(ROSE) 10000WC x1	1357.08	232.92	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-28 15:57:00.755876+00
289	ODR-20250828-3474	2025-08-28 05:18:18+00	FACEBOOK	Jaofarmza Eiei	DUNK_DYNASTY	419	https://drive.google.com/uc?id=1V0mhfpL-8Uc2J1RTc87rgLOn9ca1avOk	https://drive.google.com/uc?id=1WtF6CiGKqu3qUaamvYozh27idMoP7eNm	\N	1	1110TOKENS x1	373.53	45.47	รายการสำเร็จ	แทน	RAZERGOLD	13.99*26.70	2025-08-28 07:17:10.523385+00
288	ODR-20250828-4235	2025-08-28 05:11:48+00	FACEBOOK	Jaofarmza Eiei	DUNK_DYNASTY	159	https://drive.google.com/uc?id=1XgC5QjWi6kEDZKlphy-Iu8YHQ2hXjMXs	https://drive.google.com/uc?id=1tz3swzOrAM_tqGP0mLYyaPFusmewDlTz	\N	1	330TOKENS x1	126.46	32.54	รายการสำเร็จ	แทน	RAZERGOLD	4.71*26.85	2025-08-28 07:16:02.346709+00
287	ODR-20250828-3409	2025-08-28 04:54:21+00	FACEBOOK	Thanawut Wong	HARRY_AWAKENED	335	https://drive.google.com/uc?id=15ix3Poi1dr40NI9k2fHF1BiUdnRDNYtx	https://drive.google.com/uc?id=1CaJ1mevy6ssyMJI-nGxOIVIG8CmrbrIq	\N	1	680+70 Jewels x1	222.86	112.14	รายการสำเร็จ	แทน	RAZERGOLD	8.30*26.85	2025-08-28 07:14:38.954651+00
286	ODR-20250828-2308	2025-08-28 03:53:50+00	FACEBOOK	Jaofarmza Eiei	DUNK_DYNASTY	899	https://drive.google.com/uc?id=1ZFsiHoJac6V6AkqMXC3mZJ85LLGTezj8	https://drive.google.com/uc?id=1glJZkGGfqimBWLC2P9p-mwJMImL5U6g4	\N	1	2280TOKENS x1	761.47	137.53	รายการสำเร็จ	แทน	RAZERGOLD	28.36*26.85	2025-08-28 07:13:51.740135+00
284	ODR-20250828-1125	2025-08-28 03:09:27+00	FACEBOOK	Ball Khomsan	TFT_MOBILE	239	https://drive.google.com/uc?id=1a6rCSH3iYWKX9pt88RoLggN4k0_Dohoq	https://drive.google.com/uc?id=1fI7XxxEIi6-d0l9AzSJLsLCFKX3Vyp2N	\N	1	1380TFT x1	199.57	39.43	รายการสำเร็จ	แทน	YOUTRIP		2025-08-28 07:10:00.446873+00
268	ODR-20250826-9154	2025-08-26 12:48:50+00	FACEBOOK	ทักษ์ดนัย ไปร์ ร่มรื่น	LOL_WILDRIFT	279	https://drive.google.com/uc?id=1c1wtfQhLx6MJ1CtzaaaPtmRjz-bpyISB	https://drive.google.com/uc?id=1sWjjFbNYRf1IGGbTAjQHPTIMMgVYigJo	\N	2	425WC x1, 1000WC x1	220.25	58.75	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-26 15:46:21.663191+00
265	ODR-20250826-8959	2025-08-26 01:00:10+00	FACEBOOK	พงศ์ธนพัจน์ ฯ.	FREEFIRE	24	https://drive.google.com/uc?id=15HvDoysWpR0XRqPQU9sr2_X_e7oTYISx	https://drive.google.com/uc?id=1paXTeZJG7ooF5WVrxO6eZyQK3eFhxo-6	\N	1	68 เพชร x1	19	5	รายการสำเร็จ	แทน	24BUYM		2025-08-26 15:44:37.037524+00
263	ODR-20250825-2512	2025-08-25 10:59:03+00	FACEBOOK	พงศ์ธนพัจน์ ฯ.	FREEFIRE	49	https://drive.google.com/uc?id=1Occ_iF-b3dCe-GnEnUY2Ibh1LAqL7nMn	https://drive.google.com/uc?id=1D6oEG2mEDFTXvT8FFEusMwiS1dAiG-X-	\N	1	172 เพชร x1	47	2	รายการสำเร็จ	เกรซ	24BUYM		2025-08-25 17:11:45.398491+00
260	ODR-20250825-8373	2025-08-25 01:40:29+00	LINE	🌺 ONOSAN 小野 🌺	HONKAI_STARRAIL	2390	https://drive.google.com/uc?id=1wsvFf4nJyiIQU03ksjNmi4z5IUVkpPBu	https://drive.google.com/uc?id=1M4Xv5cuXX87UOOd5ODAQLrutaKmbNUTX	\N	1	8080SHARD x1	2285	105	รายการสำเร็จ	แทน	RICHMAN		2025-08-25 09:58:00.067526+00
255	ODR-20250824-5477	2025-08-24 02:15:52+00	FACEBOOK	Dagga Roll	DUNK_DYNASTY	159	https://drive.google.com/uc?id=11OUKQrCba46IRHi0F6s7VRme5VzR3mbU	https://drive.google.com/uc?id=1QpcJXOUOo_PmPVwD9AAGwIEmafT3f_OV	\N	1	Party Membership x1	125.39	33.61	รายการสำเร็จ	แทน	RAZERGOLD	4.67*26.85	2025-08-24 17:33:52.96345+00
80	ODR-20250816-3640	2025-08-07 02:27:48+00	FACEBOOK	Charlies Peeraphol	LOL_WILDRIFT	190	https://drive.google.com/uc?id=1NFb148m_RRDmX4pay7peMUvJvmqazbwF	https://drive.google.com/uc?id=19KrVIlX8soCtrMt_14jJ4zoGi0OjgieS	\N	1	1000WC x1	152.23	37.77	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-16 07:31:26.760973+00
75	ODR-20250816-4911	2025-08-06 11:28:44+00	FACEBOOK	ฟลุ๊ค โซ'แซด	MINECRAFT	209	https://drive.google.com/uc?id=1eRV0aJjy4apuQMxyUE0ftOGxEcbTI6ki	https://drive.google.com/uc?id=1O05d9EVhwHlAWiwJNhnY4wk7ExkTuMap	\N	1	3500 เหรียญ x1	56.32	152.68	รายการสำเร็จ	แทน	YOUTRIP		2025-08-16 07:24:45.296793+00
76	ODR-20250816-2618	2025-08-06 12:10:44+00	FACEBOOK	Suticha Makkhuntod	RACING_MASTER	4718	https://drive.google.com/uc?id=1J_jo1WXJEe8nloAWnAgRqWOd8_zYdG97	https://drive.google.com/uc?id=1fyUNQi_LmamzwJoHJsAzSSsHZDaVT-gf	\N	2	6930GEMS x2	4434.55	283.45	รายการสำเร็จ	แทน	RAZERGOLD	165.16*26.85	2025-08-16 07:25:57.208676+00
72	ODR-20250816-6307	2025-08-05 18:56:21+00	LINE	🌺 ONOSAN 小野 🌺	HONKAI_STARRAIL	2420	https://drive.google.com/uc?id=1AJq2hGExgjeo2_-7BU7GtrUvr3pNG5nW	https://drive.google.com/uc?id=1dHUTp24P1xXVvFFBWaTQwoE8Ij617SIN	\N	1	8080SHARD x1	2300	120	รายการสำเร็จ	เกรซ	RICHMAN		2025-08-16 07:21:07.741053+00
68	ODR-20250816-2909	2025-08-05 10:49:08+00	FACEBOOK	Bumbim Panita	MOBILE_LEGENDS	929	https://drive.google.com/uc?id=1JzY6ZNfvYt-JtXJXxZN5WMjqPEMR69jK	https://drive.google.com/uc?id=1pFEhwS75kqbAQYnlvuqHrV67MI-LKZ4b	\N	1	2195 เพชร x1	870	59	รายการสำเร็จ	แทน	RICHMAN		2025-08-16 07:11:17.187918+00
444	ODR-20250912-5220	2025-09-12 16:51:36+00	LINE	W	LOL_WILDRIFT	339	https://drive.google.com/uc?id=1IKW7t4oThHqeJcTrH_VnxqLaHT6k50Ug	https://drive.google.com/uc?id=1q0PWOl9tsgCRpBmvPdEGwvXKrO17gVpG	\N	1	1850WC x1	264.03	74.97	รายการสำเร็จ	เกรซ	YOUTRIP		2025-09-12 17:01:35.324132+00
65	ODR-20250815-2796	2025-08-05 04:25:32+00	FACEBOOK	Muassin Sangob	LOL_WILDRIFT	570	https://drive.google.com/uc?id=1QXJw86xC81Gwi9qqFnwDCHZSq5DFDfKE	https://drive.google.com/uc?id=1Fv2z3gpkyflY4U6inWY4B-M8Vb4KW3PR	\N	1	3275WC x1	468.16	101.84	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-15 12:05:22.357819+00
62	ODR-20250815-3794	2025-08-04 11:28:33+00	FACEBOOK	กฤษณะ พูลเพิ่ม	MINECRAFT	35	https://drive.google.com/uc?id=1fmck8IdQzGw_1cB7H_MtC5qwiBvKCeC6	https://drive.google.com/uc?id=1GbDt7jtJ_84ZBf1z36VygpQGZcuwRHLw	\N	1	320 เหรียญ x1	5.7	29.3	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-15 12:00:50.772909+00
59	ODR-20250815-2286	2025-08-04 05:58:00+00	FACEBOOK	Peem Sittikorn	FREEFIRE	149	https://drive.google.com/uc?id=1Jo7jNV_H6L6jsLCluAZ-aQGoNK-gfbxU	https://drive.google.com/uc?id=1OGoiPPJELmYYBtbsKAjoos_7ypNpp68L	\N	1	517 เพชร x1	141	8	รายการสำเร็จ	เกรซ	24BUYM		2025-08-15 11:57:03.322621+00
57	ODR-20250815-3396	2025-08-04 03:04:54+00	FACEBOOK	Nantiwat Suksawat	DUNK_DYNASTY	159	https://drive.google.com/uc?id=1ppNh2mzzQrkkt0OM-COyKV6iqWIr9aOB	https://drive.google.com/uc?id=18FMrTX6DN35OCuSSOa4_jNjdHXT9csCx	\N	1	Party Membership x1	124.93	34.07	รายการสำเร็จ	แทน	RAZERGOLD	4.61*27.10	2025-08-15 11:53:36.934688+00
54	ODR-20250815-3079	2025-08-03 09:39:53+00	FACEBOOK	Peeradech Rungsiri	DUNK_DYNASTY	159	https://drive.google.com/uc?id=1GQxR4vqATzp-kXCIrDEg05It7wiMnC4r	https://drive.google.com/uc?id=1yGd4tgun2cTVqZ-Z_wdzC10PikeGz0cF	\N	1	Party Membership x1	123.58	35.42	รายการสำเร็จ	แทน	RAZERGOLD	4.56*27.10	2025-08-15 11:50:04.219368+00
52	ODR-20250815-1492	2025-08-03 08:30:42+00	FACEBOOK	กฤษณะ พูลเพิ่ม	MINECRAFT	349	https://drive.google.com/uc?id=18of7drzzqacjos5pQWHSqOpusxCjad_B	https://drive.google.com/uc?id=1rL28Ef9pqeFB2jauaH9Tb5BraYTJk-nR	\N	1	7000 เหรียญ x1	114.14	234.86	รายการสำเร็จ	แทน	YOUTRIP		2025-08-15 11:48:37.918961+00
49	ODR-20250815-4695	2025-08-02 17:38:23+00	FACEBOOK	Pond Rasri	LOL_WILDRIFT	1620	https://drive.google.com/uc?id=1X8mR6UfyqihvBy0m1VnlgalyeXspklPO	https://drive.google.com/uc?id=1ExCP4ILBkPfTlTVqABPLDRWfdipWszEz	\N	1	10000WC x1	1386.12	233.88	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-15 11:44:21.056504+00
302	ODR-20250829-1381	2025-08-29 08:28:35+00	FACEBOOK	Pull-up Everyday	LOL_WILDRIFT	178	https://drive.google.com/uc?id=1gJxBHJq8lcXUpiQIwkI13ettFDhO0vf5	https://drive.google.com/uc?id=1epbGoGtoCHJ3rQ5yxwWCxI4DxVfl6tVy	\N	2	425WC x2	135.18	42.82	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-29 10:22:38.432182+00
300	ODR-20250829-4437	2025-08-29 05:31:00+00	FACEBOOK	Baeni Ur	(🌹) LOL_WILDRIFT	1590	https://drive.google.com/uc?id=1yZfim0MNPYY9Y0_9Wnbal4U82HTFpqEd	https://drive.google.com/uc?id=1dPaY6x9gT9JWKNcwFI30oNV9DC0jT2xE	\N	1	(ROSE) 10000WC x1	1351.87	238.13	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-29 07:33:57.279122+00
296	ODR-20250829-9913	2025-08-29 00:56:05+00	FACEBOOK	Sumet Tongyong	(🌹) LOL_WILDRIFT	559	https://drive.google.com/uc?id=1amNE1Dgg6oYaaFL5q8AoaFdnipshRZlU	https://drive.google.com/uc?id=1xohxYpvLife_ioD1wYUVw2X6g53sYyrT	\N	1	(ROSE) 3275WC x1	461.23	97.77	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-29 07:31:07.962038+00
298	ODR-20250829-9834	2025-08-29 03:09:26+00	FACEBOOK	Suppanat Settaprom	(🌹) LOL_WILDRIFT	559	https://drive.google.com/uc?id=10LK3wzgGkwqp7keEsibiDsh13p8EtezD	https://drive.google.com/uc?id=1EopbbP7aW3z3YgO5blY9yUI46lFQ-m1U	\N	1	(ROSE) 3275WC x1	461.23	97.77	รายการสำเร็จ	แทน	YOUTRIP		2025-08-29 07:32:38.002633+00
295	ODR-20250829-2933	2025-08-28 18:24:37+00	FACEBOOK	Thanapat Beer	LOL_WILDRIFT	429	https://drive.google.com/uc?id=1Kr3vpNKaODMlXLoUn6H2gtSv84mKJZ3W	https://drive.google.com/uc?id=1-XJSFim4ZNdldW-d95thaER-QmbaG8wj	\N	1	2275WC x1	339.27	89.73	รายการสำเร็จ	แทน	YOUTRIP	271.42+67.85	2025-08-29 07:29:23.044588+00
293	ODR-20250829-5421	2025-08-28 17:44:00+00	FACEBOOK	Pond Rasri	(🌹) LOL_WILDRIFT	1590	https://drive.google.com/uc?id=110T0K3ev27d-UzZwhFauAjOaMdRfGOA0	https://drive.google.com/uc?id=1IL1hPnbvWFjVU8C_fA3aMeeXPtTtUZ9-	\N	1	(ROSE) 10000WC x1	1357.08	232.92	รายการสำเร็จ	แทน	YOUTRIP		2025-08-29 07:26:35.193184+00
44	ODR-20250815-8117	2025-08-02 15:23:28+00	FACEBOOK	Jaofarmza Eiei	DUNK_DYNASTY	419	https://drive.google.com/uc?id=1c0fMqy6v5pSDOb5w5lLws8dixZNDcKNB	https://drive.google.com/uc?id=1n8uYrBf35NP5JuoZUk8xeWLqI4oPpyf2	\N	1	1110TOKENS x1	369.92	49.08	รายการสำเร็จ	เกรซ	RAZERGOLD	13.65*27.10	2025-08-15 07:39:18.270396+00
42	ODR-20250815-1636	2025-08-02 12:53:12+00	LINE	T.	RACING_MASTER	769	https://drive.google.com/uc?id=1oF6CAi0fflbA4sXyRqlgurTytwM8w-R0	https://drive.google.com/uc?id=1675RwIwYRiYAtQyHzmwcHwqpyRdk91Yx	\N	1	2205GEMS x1	703.52	65.48	รายการสำเร็จ	เกรซ	RAZERGOLD	25.96*27.10	2025-08-15 07:36:40.704142+00
39	ODR-20250814-9180	2025-08-02 08:53:00+00	FACEBOOK	Boonyarat Vineyard	VALORANT	1639	https://drive.google.com/uc?id=19pZLBoiMfFZeU2jyq9V33QBZH52G4zeH	https://drive.google.com/uc?id=1c-16uwEu83QaiE4Qil7av5u_eSyS10GD	\N	1	6825VP x1	1581.8	57.2	รายการสำเร็จ	แทน	RICHMAN		2025-08-14 16:23:05.434443+00
37	ODR-20250814-2819	2025-08-02 07:38:00+00	FACEBOOK	Warann	VALORANT	125	https://drive.google.com/uc?id=1cHI2uh3VPHq_C-FjczLPtLQVe8LCU8Ta	https://drive.google.com/uc?id=1YkuFYgqzPoq-j66G9uOCXUELyqPnPLBO	\N	1	475VP x1	120.3	4.7	รายการสำเร็จ	แทน	RICHMAN		2025-08-14 16:20:03.268355+00
32	ODR-20250814-4682	2025-08-01 21:32:00+00	FACEBOOK	Thepparaj Sangnil	DUNK_DYNASTY	2847	https://drive.google.com/uc?id=12oy7_AsdZNsDJRV4DJV1ndy3sYEI_0In	https://drive.google.com/uc?id=1n_QOfpzZtgO_s8L62uBjsi-qdbUQsZt8	\N	3	Party Membership x1, Premium Pass x1, 8110TOKENS x1	2552.81	294.19	รายการสำเร็จ	แทน	RAZERGOLD	94.9*26.90	2025-08-14 16:15:35.933864+00
313	ODR-20250829-3352	2025-08-29 15:15:49+00	LINE	ชินภัทร(Mew)	MINECRAFT	209	https://drive.google.com/uc?id=1jaRaUlSaynLLZL5Sy-cuWJi-GA3Gi2am	https://drive.google.com/uc?id=126dUsa7aro4pVAH7m3ZABJLsp4Q0gaUL	\N	1	3500 เหรียญ x1	55.66	153.34	รายการสำเร็จ	แทน	YOUTRIP		2025-08-29 16:16:17.990436+00
312	ODR-20250829-3884	2025-08-29 14:36:40+00	FACEBOOK	Thanapat Beer	LOL_WILDRIFT	89	https://drive.google.com/uc?id=1kJLG5LfxIdVdvBlhpWukh1jcUNN7jKnU	https://drive.google.com/uc?id=1YPpbtXIE0JBxzZnrvg9wqr-7N3UXMMYm	\N	1	425WC x1	67.59	21.41	รายการสำเร็จ	แทน	YOUTRIP		2025-08-29 16:15:54.955421+00
311	ODR-20250829-5907	2025-08-29 13:44:09+00	FACEBOOK	Punyanuch Raman	LOL_WILDRIFT	1459	https://drive.google.com/uc?id=1fAF2cVvnK9C5ZsmaVX61YWk5CkUSGjhH	https://drive.google.com/uc?id=1VUUVDz3dTY5W_JmSjP6PtcJ5QnsK77ab	\N	2	5225WC x1, CELESTIAL x1	1184.87	274.13	รายการสำเร็จ	แทน	YOUTRIP		2025-08-29 16:14:55.317517+00
310	ODR-20250829-1030	2025-08-29 13:22:56+00	FACEBOOK	ดุ๊บฮยอน ครายฟอหมี	VALORANT	505	https://drive.google.com/uc?id=1PZarno96G9cHQlJJNXAqXMZIXzGF0d5o	https://drive.google.com/uc?id=17UtBsz0EmQjJIzYTQ_A-Rn2vMsJLlV8d	\N	1	2050VP x1	481	24	รายการสำเร็จ	เกรซ	RICHMAN		2025-08-29 16:13:41.635376+00
309	ODR-20250829-6013	2025-08-29 12:51:34+00	FACEBOOK	Saharat Sompong	TFT_MOBILE	1397	https://drive.google.com/uc?id=1uAbAUbdDdGGZOOl8B7iJbUfHwCYciFs2	https://drive.google.com/uc?id=1xRpotWCTbAQzfKhWD_C2D_PFj5XWpCWB	\N	3	575TFT x1, 1380TFT x1, 6500TFT x1	1208.73	188.27	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-29 16:13:05.399883+00
308	ODR-20250829-3691	2025-08-29 12:49:01+00	FACEBOOK	Kaopun Tangchutaveesub	(ID-PASS) เติมได้หลายเกม	390	https://drive.google.com/uc?id=1zV8Mo_FErnMCFd8j9XvWqhy_hbRBJALi	https://drive.google.com/uc?id=1-Y8waM1PSgXN7rnewH2NMYfHxV6IVoab	\N	3	บัตรกำนัลเสบียงรถไฟ x1, INTER-KNOT (รายเดือน) x1, 199 BAHT (4.99$) x1	240.75	149.25	รายการสำเร็จ	แทน	ITUNES	117+123.75	2025-08-29 16:12:10.497082+00
307	ODR-20250829-4517	2025-08-29 12:27:19+00	FACEBOOK	Saharat Sompong	TFT_MOBILE	1039	https://drive.google.com/uc?id=13IY6p5M306XzYQJ0Tc11fxcG4ktgc7QD	https://drive.google.com/uc?id=16Z1POemsEzA5x2fMWPsxbW7uMyKTd3rq	\N	1	6500TFT x1	914.5	124.5	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-29 16:08:43.047588+00
306	ODR-20250829-6478	2025-08-29 12:25:47+00	FACEBOOK	Thanapat Beer	LOL_WILDRIFT	569	https://drive.google.com/uc?id=1hmq-98NGoQhsWiAyEhFe4kTaJPGIvZDa	https://drive.google.com/uc?id=1Sf5fSINBSevSwbsphGCbKb_J7ApMD9XM	\N	1	3275WC x1	461.23	107.77	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-29 16:06:36.905513+00
305	ODR-20250829-5684	2025-08-29 12:03:39+00	FACEBOOK	Saharat Sompong	TFT_MOBILE	1278	https://drive.google.com/uc?id=1vb-7prPiE39-zvmBA9lNtJWVWzrU4IZT	https://drive.google.com/uc?id=1R1xDh_dO2DEs_KMZgIAfjB5sNjBcoqQf	\N	2	1380TFT x1, 6500TFT x1	1113.3	164.7	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-29 16:05:46.608636+00
304	ODR-20250829-1400	2025-08-29 11:02:12+00	FACEBOOK	Possavee Dhammasiri	RACING (LOGIN)	3448	https://drive.google.com/uc?id=1bbouW_dfh01SlPNBpPy0x_bkrUh4MSib	https://drive.google.com/uc?id=1YMcJXDZK_lGdkFKM2t1x0-txKNyzE7s0	\N	2	999BAHT ($29.49) x1, 3400BAHT ($99.99) x1	3103.66	344.34	รายการสำเร็จ	แทน	RAZERGOLD	118.01*26.30	2025-08-29 16:04:37.685772+00
303	ODR-20250829-3508	2025-08-29 08:34:25+00	LINE	ice	ROBLOX	150.01	https://drive.google.com/uc?id=17pdJ4Kl1OsTf4-GymMWXANvJfuX0kzQY	https://drive.google.com/uc?id=1XTnLW9ReumUR5D78xApNuh-lQU_E9FZA	\N	1	400 ROBUX x1	139.95	10.06	รายการสำเร็จ	เกรซ	ITUNES	(ITUNES)2.97*24.90+(24BUYM)33+33	2025-08-29 10:23:21.497305+00
301	ODR-20250829-1518	2025-08-29 07:09:41+00	FACEBOOK	Nattanon Khanthong	DUNK_DYNASTY	159	https://drive.google.com/uc?id=1Kes1pQGNZGFtvxzgP6n1x5cszfewO_n5	https://drive.google.com/uc?id=1fkmcCygrtk5X92RYx9nPgHkFv8WkjBYP	\N	1	Party Membership x1	126.46	32.54	รายการสำเร็จ	เกรซ	RAZERGOLD	4.71*26.85	2025-08-29 07:34:22.645123+00
299	ODR-20250829-4023	2025-08-29 03:34:39+00	FACEBOOK	River Flows Through	MINECRAFT	35	https://drive.google.com/uc?id=187PrOs3aT8TRgvta0UweD-rniaiYQA_5	https://drive.google.com/uc?id=1ha-Wwo_sDqhLBc_Yq8l0mI4NbE1wE1Q6	\N	1	320 เหรียญ x1	5.56	29.44	รายการสำเร็จ	แทน	YOUTRIP		2025-08-29 07:33:32.534261+00
297	ODR-20250829-4559	2025-08-29 02:45:24+00	FACEBOOK	Pull-up Everyday	(🌹) LOL_WILDRIFT	1590	https://drive.google.com/uc?id=15D_QjkDB3D6Z3PKxk_bRTCk99sGjo3jq	https://drive.google.com/uc?id=15yRx21HJX-eeweRoKFZOkFa1A7NZFpRf	\N	1	(ROSE) 10000WC x1	1351.87	238.13	รายการสำเร็จ	แทน	YOUTRIP		2025-08-29 07:31:48.764783+00
294	ODR-20250829-5930	2025-08-28 17:55:03+00	FACEBOOK	Thanapat Beer	(🌹) LOL_WILDRIFT	559	https://drive.google.com/uc?id=1hfrkZBrnXEifoMW17C22HUCPrG1Mmroi	https://drive.google.com/uc?id=1pXxJc66_AsD0oP-_Jk2tU3Ww6oMT_X3X	\N	1	(ROSE) 3275WC x1	463	96	รายการสำเร็จ	แทน	YOUTRIP		2025-08-29 07:28:32.96252+00
315	ODR-20250830-5769	2025-08-30 03:17:26+00	FACEBOOK	Nopanan Khamcha	DUNK_DYNASTY	99	https://drive.google.com/uc?id=1aXlHqcsZyZop55CyZgf66HOp_LPJgJmf	https://drive.google.com/uc?id=1qFG6-IbvLukwB758oUYHe43KTNF152nD	\N	1	Rookie Pack x1	76.99	22.01	รายการสำเร็จ	แทน	RAZERGOLD	2.82*27.30	2025-08-30 13:57:43.591729+00
314	ODR-20250830-3117	2025-08-29 19:06:25+00	FACEBOOK	Ma Leen	LOL_WILDRIFT	1590	https://drive.google.com/uc?id=1c4eGEplUukBdchRFdWTbRpfhtIZWdAhd	https://drive.google.com/uc?id=1O0wAs-RySEgfCAEbtHguBLEdEEqcsy9I	\N	1	10000WC x1	1351.04	238.96	รายการสำเร็จ	แทน	YOUTRIP		2025-08-30 13:57:01.343971+00
323	ODR-20250830-4019	2025-08-30 16:25:00+00	LINE	ณัฐพงศ์	VALORANT	625	https://drive.google.com/uc?id=1f_XGYl6_WVfF_CvvxdEHgErk0X3txGpM	https://drive.google.com/uc?id=1norcrS7NrJzHOW-iXzpeyx-zoNDxB3s-	\N	1	[2525VP] DEATHWISH ปืนแยก x1	601.3	23.7	รายการสำเร็จ	เกรซ	RICHMAN		2025-08-30 16:30:22.345266+00
322	ODR-20250830-8744	2025-08-30 12:33:11+00	LINE	ชินภัทร(Mew)	MINECRAFT	209	https://drive.google.com/uc?id=1Gl4m8nmAnBf_qsVWayUhRwVF2H7rLb3W	https://drive.google.com/uc?id=1s28xsGLZ45_xb5zhKZesJOI7mHZqCIlu	\N	1	3500 เหรียญ x1	55.62	153.38	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-30 14:03:18.669157+00
321	ODR-20250830-4972	2025-08-30 12:28:04+00	FACEBOOK	Aueaathon Sirisakorn	LOL_WILDRIFT	189	https://drive.google.com/uc?id=19MoeQDmUDvBw2PKMFSgseeoOl5ldxGgC	https://drive.google.com/uc?id=17FeqnVZcDmGHD_zw9y5PRqmo4Yhth2rh	\N	1	1000WC x1	151	38	รายการสำเร็จ	เกรซ	YOUTRIP		2025-08-30 14:02:48.638676+00
320	ODR-20250830-7063	2025-08-30 11:54:26+00	FACEBOOK	Aueaathon Sirisakorn	LOL_WILDRIFT	339	https://drive.google.com/uc?id=1KFbXJzPbwly-4ubgZ-V3Id3motIiyPgX	https://drive.google.com/uc?id=1hpZjyxdNI8JokxpOpQBej1JFEuTsgrAn	\N	1	1850WC x1	270.21	68.79	รายการสำเร็จ	แทน	YOUTRIP		2025-08-30 14:02:18.463679+00
319	ODR-20250830-8924	2025-08-30 11:08:05+00	FACEBOOK	Pao Alieness	LOL_WILDRIFT	1119.13	https://drive.google.com/uc?id=1_YtdxHFNkuyBXuOElwpuOXDq0ykrjDOw	https://drive.google.com/uc?id=1nhUo5bKajjqDqEWYMSEmOQrI7vePqu3V	\N	1	6650WC x1	925.86	193.27	รายการสำเร็จ	แทน	YOUTRIP		2025-08-30 14:01:34.310622+00
318	ODR-20250830-7486	2025-08-30 10:47:38+00	FACEBOOK	Santa Like	LOL_WILDRIFT	89.01	https://drive.google.com/uc?id=1YPtmTCZExzG6qVHpWl6NKTxlcWz6FUBT	https://drive.google.com/uc?id=1NTm-ZoOQdV1TPJBxxtbxDuKcJTO-j40p	\N	1	STELLACORN x1	67.55	21.46	รายการสำเร็จ	แทน	YOUTRIP		2025-08-30 14:00:52.022464+00
317	ODR-20250830-1690	2025-08-30 06:55:56+00	LINE	HEDтᎥsт	LOL_WILDRIFT	800	https://drive.google.com/uc?id=13ZzCMbpu4nBCp15gTxC7cVD--EGkNaye	https://drive.google.com/uc?id=1-wowwlLUHedpj6F8FaXpbbTG_q4WV9n3	\N	1	4800WC x1	655.65	144.35	รายการสำเร็จ	แทน	YOUTRIP		2025-08-30 13:59:59.152697+00
316	ODR-20250830-2452	2025-08-30 05:48:32+00	LINE	ชินภัทร(Mew)	MINECRAFT	209	https://drive.google.com/uc?id=16fO-ed30v8x3XWuPf8pD4Wzzlry07S7H	https://drive.google.com/uc?id=1ooMMOP5haXjYwiDt0mrng-PZSa8sL37U	\N	1	3500 เหรียญ x1	55.62	153.38	รายการสำเร็จ	แทน	YOUTRIP		2025-08-30 13:58:27.753293+00
325	ODR-20250831-4740	2025-08-31 05:02:31+00	FACEBOOK	อาร์ม ตื่นได้เเล้วลูก	LOL_WILDRIFT	658	https://drive.google.com/uc?id=1NJ4cQDJCLz9xjGN5yJXR5ujkHgPf5OMl	https://drive.google.com/uc?id=1V9ExawTG64jwHMV9YX0XkwUPT8O236i6	\N	2	425WC x1, 3275WC x1	528.49	129.51	รายการสำเร็จ	เกรซ	YOUTRIP	67.55+460.94	2025-08-31 16:50:12.508147+00
330	ODR-20250831-9882	2025-08-31 15:34:20+00	FACEBOOK	Chaiyaphon Nuphengrat	DUNK_DYNASTY	438	https://drive.google.com/uc?id=1MfnwtZ98C8d31ees8q-9XoGfa41Qoixa	https://drive.google.com/uc?id=12Ben_taRqTKihj0xO8YI63Z7slAaE-I3	\N	2	Party Membership x1, Extra Premium Pass x1	359.65	78.35	รายการสำเร็จ	เกรซ	RAZERGOLD	13.47*26.70	2025-08-31 16:54:35.425632+00
329	ODR-20250831-2735	2025-08-31 14:27:05+00	FACEBOOK	ชีวิต ต้องสู้	RACING_MASTER	65	https://drive.google.com/uc?id=1n1fT4bzB8gJNLVcHeWsrFFLMt9tpZrS2	https://drive.google.com/uc?id=1WsqTFsj_GkNY6b9GCWEQp23kipwknmOX	\N	1	รายเดือน (MONTHLY) x1	54.34	10.66	รายการสำเร็จ	เกรซ	RAZERGOLD	2.02*26.90	2025-08-31 16:54:06.68611+00
328	ODR-20250831-6157	2025-08-31 12:03:02+00	FACEBOOK	Boomm Tanawat	LOL_WILDRIFT	800	https://drive.google.com/uc?id=1QAmNMJ0SJ0qiBddvmIsIo-GRmypyBjKo	https://drive.google.com/uc?id=15IT2AEA90NUrwmXSEBLyul0RkBXCWCd7	\N	1	4800WC x1	655.65	144.35	รายการสำเร็จ	แทน	YOUTRIP		2025-08-31 16:53:40.63379+00
327	ODR-20250831-5088	2025-08-31 11:28:22+00	FACEBOOK	รหัสศูนย์สอง สลิ่มเลือดเหล็ก	VALORANT	625	https://drive.google.com/uc?id=16gUt2hXw9fNJrae2qeF3RAS_oks8VLO9	https://drive.google.com/uc?id=1tP73m50GN_TGjqiY7vszEgDIJ9pMk21m	\N	1	[2525VP] DEATHWISH ปืนแยก x1	601.3	23.7	แก้ไขรายการ	แทน	RICHMAN	ลูกค้าโอนเงินไม่ครบ / ทำการโอนเพิ่ม	2025-08-31 16:52:21.897349+00
326	ODR-20250831-1226	2025-08-31 07:13:55+00	FACEBOOK	Thongchai Raksat	ROBLOX	590	https://drive.google.com/uc?id=1Y7kMQ9nPMqa1t6SS0k8AZZGKgbAJ145n	https://drive.google.com/uc?id=1Jh0EeH_62vI96W8WbLBaJEycBQhKxn9D	\N	1	1700 ROBUX x1	495.75	94.25	รายการสำเร็จ	แทน	ITUNES	19.99*24.80	2025-08-31 16:51:14.174164+00
324	ODR-20250831-6534	2025-08-30 17:19:12+00	FACEBOOK	Boomm Tanawat	LOL_WILDRIFT	190	https://drive.google.com/uc?id=1ojnaU4uiLtCz49sTEXdoiFTJL0le38i7	https://drive.google.com/uc?id=1IagMFoSn6yVfZd3UW73p6cW7LVqUQuBj	\N	1	1000WC x1	151	39	รายการสำเร็จ	แทน	YOUTRIP		2025-08-31 16:49:11.761592+00
443	ODR-20250912-4366	2025-09-12 14:06:10+00	FACEBOOK	hoshi	PUBG_MOBILE	319	https://drive.google.com/uc?id=1h2Vsbgex3Xfeux7obFGiNOFfRgNgx_as	https://drive.google.com/uc?id=1SZhNTctIRZ__SgbE3dB-s9uOz8_a0I_R	\N	1	660UC x1	267.27	51.73	รายการสำเร็จ	เกรซ	RAZERGOLD	10.01*26.70	2025-09-12 14:50:25.085907+00
332	ODR-20250901-4078	2025-08-31 17:37:53+00	FACEBOOK	Sanpraween Boonplod	MINECRAFT	349	https://drive.google.com/uc?id=10gi0D6nN6ltKNtwls8p3W5XMsGjxff6c	https://drive.google.com/uc?id=1syTSYsZBEl9ob-Sd_mq6W2WzFQiHUfX7	\N	1	7000 เหรียญ x1	111.24	237.76	รายการสำเร็จ	แทน	YOUTRIP		2025-09-01 16:05:47.080687+00
340	ODR-20250901-6159	2025-09-01 14:36:46+00	FACEBOOK	Possavee Dhammasiri	RACING_MASTER	269	https://drive.google.com/uc?id=13aMyfERsvBLYV5oWuKKmEtqbG6oVDV3C	https://drive.google.com/uc?id=1gsqr5-iLXLzQxxS0r9roS1grgLVydTfw	\N	1	735GEMS x1	239.23	29.77	รายการสำเร็จ	เกรซ	RAZERGOLD	8.96*26.7	2025-09-01 16:12:00.357206+00
338	ODR-20250901-6276	2025-09-01 07:08:33+00	FACEBOOK	Jaofarmza Eiei	DUNK_DYNASTY	559	https://drive.google.com/uc?id=1YqP2T1ukm92AngiDmpMMyWZtsk2gRFyP	https://drive.google.com/uc?id=1FBHi_UzsM-4fhichkzARNDa7I1Uj4uXo	\N	1	699BAHT (19.99$) x1	495.75	63.25	รายการสำเร็จ	แทน	ITUNES	19.99*24.80	2025-09-01 16:10:54.218806+00
337	ODR-20250901-3297	2025-09-01 05:44:17+00	FACEBOOK	Thanaphat Chakainta	FREEFIRE	101	https://drive.google.com/uc?id=1_kYC-upZhPjox-JwgpI3e0a1L6Okx8zS	https://drive.google.com/uc?id=1oFWL5Un1RhozDUic-WErTD_IuaTsanzH	\N	2	33 เพชร x1, 310 เพชร x1	95	6	รายการสำเร็จ	เกรซ	24BUYM		2025-09-01 16:10:02.477791+00
334	ODR-20250901-1211	2025-08-31 21:02:01+00	FACEBOOK	MA MY	LOL_WILDRIFT	800	https://drive.google.com/uc?id=1pP8JLPWbnHGOY31biibI0QcUbHSTFzeQ	https://drive.google.com/uc?id=14gC7p6qMFSR8zmM2yHSPnDYrBQV1BuZp	\N	1	4800WC x1	655.65	144.35	รายการสำเร็จ	แทน	YOUTRIP		2025-09-01 16:08:17.418057+00
335	ODR-20250901-1638	2025-09-01 05:09:29+00	FACEBOOK	Dusnee Watt	LOL_WILDRIFT	569	https://drive.google.com/uc?id=1L5NoqM8q1Qv1ZnQbhKvSJcbm_Sbbc2Ou	https://drive.google.com/uc?id=1xxHxRb_D5LwKGa_WTZxz7SXSgWBfUWGE	\N	1	3275WC x1	460.94	108.06	รายการสำเร็จ	เกรซ	YOUTRIP		2025-09-01 16:08:50.245938+00
339	ODR-20250901-2676	2025-09-01 07:18:49+00	FACEBOOK	โคโดโมะ จ้า	LOL_WILDRIFT	889	https://drive.google.com/uc?id=1aISS0kdlmv71LXXdymZDp8HhQN8xyk_j	https://drive.google.com/uc?id=1JZ4YHOiS24tRoWL5LEWEdxfgd4QiHo1g	\N	1	5225WC x1	723.2	165.8	รายการสำเร็จ	แทน	YOUTRIP		2025-09-01 16:11:34.538437+00
336	ODR-20250901-8038	2025-09-01 05:34:44+00	FACEBOOK	Thanaphat Chakainta	FREEFIRE	149	https://drive.google.com/uc?id=1CStkfAnDKOgqLLIWxN9W9-A6VyuRyw8r	https://drive.google.com/uc?id=1GQNSpEBOVnhcjJl__VrhGzIB6n9_k9dy	\N	1	517 เพชร x1	141	8	รายการสำเร็จ	เกรซ	24BUYM		2025-09-01 16:09:23.676447+00
333	ODR-20250901-6920	2025-08-31 18:36:33+00	FACEBOOK	แฟ้มไง ไม่ต้องถาม	VALORANT	1135	https://drive.google.com/uc?id=1pHWehUfiOIi1gayHZGqEeydLVM93-K5a	https://drive.google.com/uc?id=1wDxZFCzVafDc3TykXCILg7jnepJhEVM0	\N	1	4650VP x1	1091.5	43.5	รายการสำเร็จ	แทน	RICHMAN		2025-09-01 16:06:54.294696+00
331	ODR-20250901-3263	2025-08-31 17:37:05+00	FACEBOOK	Suphakit Rueangsiri	MINECRAFT	349	https://drive.google.com/uc?id=1tHPfSfagoum88DFeN2oDDboKbtTLJfm5	https://drive.google.com/uc?id=1V0xglr-TiAQpW0YvpLyfCrz_dmXOxp_a	\N	1	7000 เหรียญ x1	111.24	237.76	รายการสำเร็จ	แทน	YOUTRIP		2025-09-01 16:05:07.036024+00
349	ODR-20250902-3211	2025-09-02 16:49:02+00	FACEBOOK	Thanaset Chatchonlimwat	MARVEL_RIVALS	180	https://drive.google.com/uc?id=1vCK2K_PxLWvee3_8FY3cb22Jdc3dTGRT	https://drive.google.com/uc?id=1VYlHBNAH6tsJ0f363YTKO3g4nYLij7VB	\N	2	100LATT x1, 500LATT x1	160	20	รายการสำเร็จ	เกรซ	24BUYM		2025-09-02 17:14:10.720623+00
348	ODR-20250902-5437	2025-09-02 16:31:20+00	FACEBOOK	Surapan Komolmusig	MINECRAFT	209	https://drive.google.com/uc?id=1ExXtu7izuZ0cmX0GK2y7P08GcSWUBlic	https://drive.google.com/uc?id=18yI9Qco-bUGL1kz8H7GM5g_2YZlLi6mS	\N	1	3500 เหรียญ x1	55.51	153.49	รายการสำเร็จ	เกรซ	YOUTRIP		2025-09-02 17:13:38.527296+00
347	ODR-20250902-3453	2025-09-02 15:53:28+00	FACEBOOK	Jaofarmza Eiei	DUNK_DYNASTY	429	https://drive.google.com/uc?id=1lS_NevgMj_cUv_RiyMkv4AshhCKu4_eV	https://drive.google.com/uc?id=1lWz2jUN9eJONrEEv9AwGK9lvoxMDyeBN	\N	1	499BAHT (14.99$) x1	371.75	57.25	รายการสำเร็จ	เกรซ	ITUNES	14.99*24.80	2025-09-02 17:13:00.425587+00
346	ODR-20250902-1302	2025-09-02 15:51:40+00	FACEBOOK	Bow Bsp	RACING (LOGIN)	275	https://drive.google.com/uc?id=1JObTibNDCyWD2CxNDyjuCpKsL8X3iS9s	https://drive.google.com/uc?id=1yuzypKZql1Lm23g-DubCN_nqopRnxxub	\N	1	329BAHT ($9.99) x1	238.16	36.84	รายการสำเร็จ	เกรซ	RAZERGOLD	8.92*26.70	2025-09-02 17:12:33.005614+00
345	ODR-20250902-5129	2025-09-02 15:13:47+00	FACEBOOK	Worawit Chainaranon	DUNK_DYNASTY	338	https://drive.google.com/uc?id=14y48CJFUZDtblul3geip-zmGN2ZKVMG1	https://drive.google.com/uc?id=1iZwllace-y7EktovM1knidFgfs2T-hbV	\N	2	Premium Pass x2	279.28	58.72	รายการสำเร็จ	เกรซ	RAZERGOLD	10.46*26.70	2025-09-02 15:27:20.00289+00
344	ODR-20250902-4008	2025-09-02 13:11:53+00	LINE	ชินภัทร(Mew)	MINECRAFT	349	https://drive.google.com/uc?id=1TU-L-Tw7j8Nnf9KYOlMaTUUldUmnVgyz	https://drive.google.com/uc?id=110_N7886-GGOR6SUm4UFY80l11m7ctFT	\N	1	7000 เหรียญ x1	111.02	237.98	รายการสำเร็จ	เกรซ	YOUTRIP		2025-09-02 15:26:20.800916+00
343	ODR-20250902-2409	2025-09-02 11:42:15+00	FACEBOOK	Jarusak Jung	LOL_WILDRIFT	189	https://drive.google.com/uc?id=1YIcGgYF9tv8vOg3ERrQwOJaJ_dB0W2yC	https://drive.google.com/uc?id=1ZCPswbgywONKVh4RMO4RvpQzwW90BTkM	\N	1	1000WC x1	150.68	38.32	รายการสำเร็จ	เกรซ	YOUTRIP		2025-09-02 15:25:37.835883+00
342	ODR-20250902-4591	2025-09-02 09:53:06+00	FACEBOOK	Jaofarmza Eiei	DUNK_DYNASTY	559	https://drive.google.com/uc?id=1L8KlFnNrWFb4RsbvpF2Hu4QMdPbV2zib	https://drive.google.com/uc?id=1RHPelgaohBEsXb4fPYv1vyhy9VDFiO9c	\N	1	699BAHT (19.99$) x1	495.75	63.25	รายการสำเร็จ	เกรซ	ITUNES	19.99*24.80	2025-09-02 15:24:39.097237+00
341	ODR-20250902-2704	2025-09-01 17:25:15+00	LINE	ONOSAN 小野	MARVEL_RIVALS	1439	https://drive.google.com/uc?id=1wMzdGJ7azro-_egXaS-Jc71X_WF61684	https://drive.google.com/uc?id=1J3KmrhIP_CLhnlZa-kA50s1Yru8-t_-l	\N	1	5680LATT x1	1330	109	รายการสำเร็จ	แทน	24BUYM		2025-09-02 15:23:28.64271+00
442	ODR-20250912-4154	2025-09-12 10:26:59+00	FACEBOOK	Poom Kanarat	LOL_WILDRIFT	189	https://drive.google.com/uc?id=12gk0-OotxcQnG7PGcr0ZDJ1O00cmNobe	https://drive.google.com/uc?id=1pa7YkYCh6tbu4Z7Eotv4N612j5fICfPn	\N	1	1000WC x1	147.55	41.45	รายการสำเร็จ	แทน	YOUTRIP		2025-09-12 14:49:58.711084+00
362	ODR-20250904-3222	2025-09-03 14:26:11+00	FACEBOOK	Pasit Title	MARVEL_RIVALS	575	https://drive.google.com/uc?id=1Wxy8rmC6nZ-sKLL-JYnkhHlOYtjxmoXX	https://drive.google.com/uc?id=1u4xA80YfEE6g8-f9Bw4UlKGEafrCYwFn	\N	1	2180LATT x1	532	43	รายการสำเร็จ	แทน	24BUYM		2025-09-04 00:35:25.896097+00
360	ODR-20250903-8021	2025-09-03 10:04:46+00	FACEBOOK	Suticha Makkhuntod	RACING_MASTER	2359	https://drive.google.com/uc?id=1BqJfbDY8PegBNpvCcpcSWDSBcUttKKEm	https://drive.google.com/uc?id=1qpX2eFkSehY8_G7lNm_Fi_hu21vN2df7	\N	1	6930GEMS x1	2208.36	150.64	รายการสำเร็จ	แทน	RAZERGOLD	82.71*26.70	2025-09-03 14:10:41.844576+00
359	ODR-20250903-7130	2025-09-03 10:00:53+00	FACEBOOK	Peeradech Rungsiri	DUNK_DYNASTY	159	https://drive.google.com/uc?id=1ZtJZMtgVyM2qYjEye8uXkLe9GZDny9gm	https://drive.google.com/uc?id=1ByHnkz05Wrtun8VRgghIyGk_jMrm9ACH	\N	1	Party Membership x1	124.69	34.31	รายการสำเร็จ	แทน	RAZERGOLD	4.67*26.70	2025-09-03 14:09:52.793182+00
358	ODR-20250903-5651	2025-09-03 09:01:24+00	FACEBOOK	Thanawut Wong	HARRY_AWAKENED	159	https://drive.google.com/uc?id=1ZiGHjxJsZ2q27SUYDlww-taJsrpET6nO	https://drive.google.com/uc?id=12PBeYoMkIEbLX-9wbpvjOVpIOT9XgQjN	\N	1	300 Jewels x1	110	49	รายการสำเร็จ	แทน	RAZERGOLD	4.12*26.70	2025-09-03 14:09:28.188195+00
357	ODR-20250903-7898	2025-09-03 07:59:11+00	FACEBOOK	Kanokwan BJ	VALORANT	625	https://drive.google.com/uc?id=1vUCv2F46gwZB5t0owc_Wx6YZkQHY6I6R	https://drive.google.com/uc?id=1Gy47PFvJAdgwwNLMEwajReQYiccadkE5	\N	1	[2525VP] DEATHWISH ปืนแยก x1	601.3	23.7	รายการสำเร็จ	แทน	RICHMAN		2025-09-03 14:08:44.806517+00
355	ODR-20250903-3480	2025-09-03 07:27:59+00	FACEBOOK	Weeraphat Taoboonchu	VALORANT	625	https://drive.google.com/uc?id=1ahS7xH6gcFKSjr00t3XJfcYVcPIXN9XY	https://drive.google.com/uc?id=1hR4lQ05pBB6jDPu5kQyhZE1IUiKlooul	\N	1	[2525VP] DEATHWISH ปืนแยก x1	601.3	23.7	รายการสำเร็จ	แทน	RICHMAN		2025-09-03 14:07:35.6119+00
353	ODR-20250903-1060	2025-09-03 07:10:21+00	FACEBOOK	Jaofarmza Eiei	DUNK_DYNASTY	559	https://drive.google.com/uc?id=1DfUlJtN5hPIZls7SQnjkgUNv4uzsBugm	https://drive.google.com/uc?id=1ba-xLxwVJXoU4nZmgRlJuE-L_kETKZu8	\N	1	699BAHT (19.99$) x1	497.75	61.25	รายการสำเร็จ	แทน	ITUNES	19.99*24.90	2025-09-03 14:06:21.409978+00
352	ODR-20250903-7062	2025-09-03 02:15:32+00	FACEBOOK	Possavee Dhammasiri	RACING_MASTER	369	https://drive.google.com/uc?id=10zxYD9YyMEZzD4m3WHmig31dnNN3f5uL	https://drive.google.com/uc?id=1XSBPNQecSvU8d0jm5YaRXXmyjwX7SIEm	\N	1	1050GEMS x1	336.15	32.85	รายการสำเร็จ	เกรซ	RAZERGOLD	12.59*26.70	2025-09-03 14:05:27.499396+00
350	ODR-20250903-2927	2025-09-02 18:25:09+00	LINE	palm	TFT_MOBILE	239	https://drive.google.com/uc?id=1i65PVABgOPh0ZwtvG7rVPO_ZOVdrQpPg	https://drive.google.com/uc?id=1fBOv8UrcpXeynvGv9F_E3XrYT6MPB7KY	\N	1	1380TFT x1	198.27	40.73	รายการสำเร็จ	แทน	YOUTRIP		2025-09-03 14:03:45.565643+00
374	ODR-20250904-1653	2025-09-04 13:58:05+00	FACEBOOK	ShadowHand Quillen	LOL_WILDRIFT	89	https://drive.google.com/uc?id=1ZQ1k9Oz3q9WdJUqKwBkBSNHPMgN0N5bH	https://drive.google.com/uc?id=1nBKqrtasi6bYu37FFRkXJfN60tsypXIa	\N	1	425WC x1	67.38	21.62	รายการสำเร็จ	เกรซ	YOUTRIP		2025-09-04 15:31:40.115741+00
390	ODR-20250905-7606	2025-09-05 15:16:53+00	FACEBOOK	Nick Zalntz	VALORANT	750	https://drive.google.com/uc?id=1CllsbBTB1Vi3PfCq6PwmsIz7_Icg-sc5	https://drive.google.com/uc?id=1gtUa_GvnmsOkeq74jv4GmT1dmmiIYW4_	\N	1	[3050VP] CHAMP2025 ปืนแยก x1	721.5	28.5	รายการสำเร็จ	เกรซ	RICHMAN		2025-09-05 15:49:22.608893+00
385	ODR-20250905-6071	2025-09-05 11:41:55+00	FACEBOOK	D’dai Hoondee	VALORANT	1515.77	https://drive.google.com/uc?id=1GFqnEBUq35t0kJusj4WmApn9ag136AFO	https://drive.google.com/uc?id=1tFTBSsiLt1DXxrGoyV_uo96xBWivW45G	\N	1	6350VP x1	1461.5	54.27	รายการสำเร็จ	แทน	RICHMAN		2025-09-05 14:39:13.892419+00
384	ODR-20250905-6932	2025-09-05 10:55:23+00	LINE	MOS Tanakon	COA	149	https://drive.google.com/uc?id=1QZ8rXJqIeaXAnPZveBnW0Ogcrppnn2vF	https://drive.google.com/uc?id=1_DAwCjUxs-JCSEFGJOB3w7tW3C3yGzsI	\N	1	Phantasium Pass (30 วัน) x1	127.09	21.91	รายการสำเร็จ	แทน	RAZERGOLD	4.76*26.70	2025-09-05 14:36:50.514893+00
392	ODR-20250905-8667	2025-09-05 16:40:20+00	FACEBOOK	Dratae Rublik	VALORANT	1635	https://drive.google.com/file/d/105A5vWO0Ysu7LeJ8px_RhGbJtL45l6Da/view?usp=drivesdk	https://drive.google.com/file/d/1gQNh6x03EhYiFjJC3ZhSEKBlWeYvorO5/view?usp=drivesdk	\N	1	[6700VP] CHAMP2025 เหมาหมด x1	1572.5	62.5	รายการสำเร็จ	เกรซ	RICHMAN		2025-09-05 16:49:35.33551+00
382	ODR-20250905-2385	2025-09-05 10:49:31+00	FACEBOOK	Ko Rn	(ID-PASS) เติมได้หลายเกม	119	https://drive.google.com/uc?id=16T5hJXSHf6vsPSi3YMthc7kOOwWEdxsd	https://drive.google.com/uc?id=1BSXejFn9N9To-sieMhWetQvpH_Bdp_pw	\N	1	149 BAHT (3.99$) x1	0	119	ยกเลิก/คืนเงิน	แทน	ITUNES		2025-09-05 14:32:38.580917+00
383	ODR-20250905-7208	2025-09-05 10:51:34+00	LINE	MOS Tanakon	COA	1429	https://drive.google.com/uc?id=1_0_0WwCP_zBXwfMQvg9IcP6tGw9_aSM-	https://drive.google.com/uc?id=1_DAwCjUxs-JCSEFGJOB3w7tW3C3yGzsI	\N	1	4245 โอปอล x1	1326.99	102.01	รายการสำเร็จ	แทน	RAZERGOLD	49.70*26.70	2025-09-05 14:35:41.309341+00
391	ODR-20250905-3787	2025-09-05 15:39:29+00	FACEBOOK	ชลลดา กระพลอย	VALORANT	375	https://drive.google.com/uc?id=1KPV66v1I9JWjlEqa6ysLCpeTmC5oI9OV	https://drive.google.com/uc?id=1xGgD-TixmjwpPpU_IENgoPyJuI4B_8_8	\N	1	1475VP x1	360.8	14.2	รายการสำเร็จ	เกรซ	RICHMAN		2025-09-05 15:50:36.107543+00
393	ODR-20250905-8559	2025-09-05 16:52:53+00	FACEBOOK	Theeraphat Sakulpaprasert	LOL_WILDRIFT	889.02	https://drive.google.com/file/d/1zaJF4MtrDcE5hLN31RjIFhmV5xdKKDuK/view?usp=drivesdk	https://drive.google.com/file/d/1lqRMbz71DsWYZkxD1cJ-ddw98BtXE_v4/view?usp=drivesdk	\N	1	5225WC x1	719.93	169.09	รายการสำเร็จ	เกรซ	YOUTRIP		2025-09-05 16:58:33.557903+00
387	ODR-20250905-5773	2025-09-05 12:55:01+00	FACEBOOK	Ba Ros	VALORANT	3270	https://drive.google.com/uc?id=1fUCbxSIwoLtCC2CvncQO-mpSNNvlXBMr	https://drive.google.com/uc?id=1mS5jFBpxIqeWYDMqOlyi9jZFfAzC9Kxn	\N	2	6825VP x2	3163.6	106.4	รายการสำเร็จ	เกรซ	RICHMAN		2025-09-05 14:42:33.955092+00
386	ODR-20250905-4107	2025-09-05 12:17:03+00	FACEBOOK	Sirinat Metrailler	LOL_WILDRIFT	800.01	https://drive.google.com/uc?id=1frlGcCnzXGfn2lLVG5NuvDUsfMzbEcqv	https://drive.google.com/uc?id=1oaHAczgJNFZWuaxb1PXFAuHjsSjjrJ1l	\N	1	4800WC x1	652.68	147.33	รายการสำเร็จ	เกรซ	YOUTRIP		2025-09-05 14:40:50.230835+00
381	ODR-20250905-1763	2025-09-05 10:16:55+00	FACEBOOK	Methasit Pumphothong	VALORANT	1889	https://drive.google.com/uc?id=1OavoD5XNTu9XpNHMYEJfE2buJ2umubKn	https://drive.google.com/uc?id=14nrLxMmz2CFEAbdBNC5bIWt27XzRsiG2	\N	1	[7875VP] CHAMP2025 เหมาพาส x1	1822.3	66.7	รายการสำเร็จ	แทน	RICHMAN		2025-09-05 14:30:44.764701+00
380	ODR-20250905-3868	2025-09-05 10:09:15+00	FACEBOOK	Punnathon Tekootong	VALORANT	885	https://drive.google.com/uc?id=1rdDqB7ZFGNgcujr7YxEejUEoaJDvektc	https://drive.google.com/uc?id=1UgqnGTFoIc860zMVgALFrr_Wq-xnBGFK	\N	1	3650VP x1	851	34	รายการสำเร็จ	แทน	RICHMAN		2025-09-05 14:28:04.040782+00
379	ODR-20250905-7058	2025-09-05 09:35:25+00	FACEBOOK	Boat Pennueng	LOL_WILDRIFT	339	https://drive.google.com/uc?id=182OoPIxH6BK0q-1IT3O7Zicv58l2pfaD	https://drive.google.com/uc?id=1fly32G66YIUw4xZujJ4BYqii_HCNu0st	\N	1	1850WC x1	268.99	70.01	รายการสำเร็จ	แทน	YOUTRIP		2025-09-05 14:25:28.436744+00
378	ODR-20250905-8363	2025-09-05 09:26:33+00	LINE	w	LOL_WILDRIFT	189	https://drive.google.com/uc?id=1b523qpwNtBOyCiTGAQVHXplUwHEM1kLE	https://drive.google.com/uc?id=1QH_zGgv2Pv7oPGFfMiIMyCJm7RZlI0Yg	\N	1	1000WC x1	150.32	38.68	รายการสำเร็จ	แทน	YOUTRIP		2025-09-05 14:23:02.656833+00
376	ODR-20250905-5478	2025-09-05 04:40:50+00	FACEBOOK	IBeg Chutrakul	LOL_WILDRIFT	3139.03	https://drive.google.com/uc?id=1PWgzWtPYf9pg5quHEGB4fLo4d259dd75	https://drive.google.com/uc?id=1HitY9K9kqtbqTlAp4e2hVsE6z6iwjpl1	\N	1	20000WC x1	2689.86	449.17	รายการสำเร็จ	แทน	YOUTRIP		2025-09-05 14:07:11.384049+00
394	ODR-20250906-3886	2025-09-04 16:39:56+00	FACEBOOK	Theerapong Thajiramongkolkit	TFT_MOBILE	239	https://drive.google.com/uc?id=1QltDYp3-r8OrdIzzc3JjThXEVtZbQvri	https://drive.google.com/uc?id=1oGkzmwtHhZZ0yYDmihTijeHvJ2WwLD-D	\N	1	1380TFT x1	198.18	40.82	รายการสำเร็จ	แทน	YOUTRIP		2025-09-06 00:52:46.258634+00
372	ODR-20250904-1774	2025-09-04 10:32:38+00	FACEBOOK	Nantiwat Suksawat	DUNK_DYNASTY	159	https://drive.google.com/uc?id=1htTrIkjVTz4MqJvF_HUac68WZifpVcGL	https://drive.google.com/uc?id=1TjNTNll_WsU-FTc2duy44PxGlexwoiSa	\N	1	Party Membership x1	124.96	34.04	รายการสำเร็จ	เกรซ	RAZERGOLD	4.68*26.70	2025-09-04 13:17:01.453604+00
371	ODR-20250904-6823	2025-09-04 06:59:27+00	FACEBOOK	Apirat Kaewrueng	MINECRAFT	209	https://drive.google.com/uc?id=1pXTDB9MLxhokSRP_3Nd0S76eJCF2bGzy	https://drive.google.com/uc?id=18_tCoPxq4JQwSFthuOjRxPc8WVAe338z	\N	1	3500 เหรียญ x1	55.48	153.52	รายการสำเร็จ	เกรซ	YOUTRIP		2025-09-04 13:15:34.011508+00
361	ODR-20250904-6606	2025-09-03 14:18:15+00	FACEBOOK	Kaopun Tangchutaveesub	ZENLESS_ZONE	515	https://drive.google.com/uc?id=1TqncsvmDLPffuasLbet365LnfcnXtpd_	https://drive.google.com/uc?id=1CJsFdY3Pg1rjPDH-rNEACuyYPO3ZXkyE	\N	2	330 Monochrome x1, 1090 Monochrome x1	462	53	รายการสำเร็จ	แทน	RICHMAN		2025-09-04 00:33:33.858037+00
389	ODR-20250905-2161	2025-09-05 13:52:12+00	FACEBOOK	Ratchata Lumpongpung	ROV_MOBILE	296.01	https://drive.google.com/uc?id=1HFpnOYEwcRG4mlLqIgO6-pNhS1MRGjpU	https://drive.google.com/uc?id=1OP-MC_2DUWNKCDYMHsuCm9JW1iX-6Fcv	\N	1	370 ปอง x1	282	14.01	รายการสำเร็จ	เกรซ	RICHMAN		2025-09-05 14:52:18.06506+00
388	ODR-20250905-9141	2025-09-05 13:04:12+00	FACEBOOK	Mhu Yangx	VALORANT	505	https://drive.google.com/uc?id=1HHg2j8rV7eLG4qh6U5TtQ2onOw-sOwHY	https://drive.google.com/uc?id=1WMFgqPeYULrxJJNVkHoirkn7r-POfYqj	\N	1	2050VP x1	481	24	รายการสำเร็จ	เกรซ	RICHMAN		2025-09-05 14:43:49.564437+00
377	ODR-20250905-7412	2025-09-05 09:05:07+00	FACEBOOK	Tienpansa	VALORANT	1889	https://drive.google.com/uc?id=1Vmvqj1YZE0gTtqprKYIbnmdi5DRBToU2	https://drive.google.com/uc?id=1FItWGrGMhP6Ls3W8BWrf0cyRePvXFNls	\N	1	[7875VP] CHAMP2025 เหมาพาส x1	1822.3	66.7	รายการสำเร็จ	แทน	RICHMAN		2025-09-05 14:13:51.548313+00
375	ODR-20250905-4364	2025-09-05 04:13:31+00	FACEBOOK	กิตติคุณ ขันติกุล	DUNK_DYNASTY	419	https://drive.google.com/uc?id=1KOpEpJ3bUSVR0RrnLCBulult6Tq6_74L	https://drive.google.com/uc?id=1jj5MOw4Hp139OG4mIMWsVRMV4wGjWFLU	\N	1	Party Permanent VIP x1	372.47	46.53	รายการสำเร็จ	แทน	RAZERGOLD	13.95*26.70	2025-09-05 14:03:31.296397+00
373	ODR-20250904-6180	2025-09-04 13:45:40+00	FACEBOOK	AchiAchi Boonleab	DUNK_DYNASTY	328	https://drive.google.com/uc?id=1LnGw-QEIAitawpdgXKsWk_bzfdOq8Jhr	https://drive.google.com/uc?id=19KZC5nj8xki8xrHKBvQE-eAlEFjMi3dk	\N	2	Party Membership x1, Premium Pass x1	264.33	63.67	รายการสำเร็จ	แทน	RAZERGOLD	9.90*26.70	2025-09-04 15:03:00.812778+00
370	ODR-20250904-2876	2025-09-03 17:23:25+00	FACEBOOK	เต๊ก หลี	RACING_MASTER	529	https://drive.google.com/uc?id=1Ny382fh0EzFDKaXgIyee0TpDgm29Uyur	https://drive.google.com/uc?id=1DcE0hhXqgXc_bKj0PGG1RkqMbh8IGqcm	\N	1	1470GEMS x1	469.65	59.35	รายการสำเร็จ	แทน	RAZERGOLD	17.59*26.70	2025-09-04 00:46:14.409928+00
369	ODR-20250904-7218	2025-09-03 17:15:15+00	FACEBOOK	Wachirawit Peam	DELTA_FORCE	2390	https://drive.google.com/uc?id=1rGbBq3KHA0SWvKL30mAqEIFOI4tmBVLq	https://drive.google.com/uc?id=1JyI0tSN55D1MQROJsBcWa5y753iBQu3V	\N	1	8100DELTA x1	2263.09	126.91	รายการสำเร็จ	แทน	RAZERGOLD	84.76*26.70	2025-09-04 00:45:43.173671+00
368	ODR-20250904-1628	2025-09-03 17:11:42+00	FACEBOOK	เต๊ก หลี	RACING_MASTER	529	https://drive.google.com/uc?id=1yRAMQGbwOINYFBJb7VPXbyKHjD_XHsKO	https://drive.google.com/uc?id=1W-UlOCEzlNS4fCm2XIKZLbhfNu9Dwrhz	\N	1	1470GEMS x1	469.65	59.35	รายการสำเร็จ	แทน	RAZERGOLD	17.59*26.70	2025-09-04 00:45:04.942821+00
367	ODR-20250904-9561	2025-09-03 15:27:27+00	FACEBOOK	Pasit Title	MARVEL_RIVALS	150	https://drive.google.com/uc?id=1hT-t6qgp1VXE1r9CYon5CHriSVpy1syI	https://drive.google.com/uc?id=1SOy8LOhopAreAPRrTIqdJ6BjZzMZEUnq	\N	1	500LATT x1	133	17	รายการสำเร็จ	แทน	24BUYM		2025-09-04 00:43:36.459635+00
356	ODR-20250903-4913	2025-09-03 07:53:42+00	FACEBOOK	Aum Supakorn	MINECRAFT	349	https://drive.google.com/uc?id=1qPJ6Z3n_eZKt2_XFQh-UTd3gk7RTrj3m	https://drive.google.com/uc?id=11z-Ma4f86R2AjWnF-mpm-tQR83Dxdmfm	\N	1	7000 เหรียญ x1	111	238	รายการสำเร็จ	แทน	YOUTRIP		2025-09-03 14:08:09.251935+00
354	ODR-20250903-8429	2025-09-03 07:19:39+00	FACEBOOK	Pee Phiraphon	MINECRAFT	209	https://drive.google.com/uc?id=1P1SJ6YcwKwnTM3lyVoa_YvAQF5fZzt0t	https://drive.google.com/uc?id=1KP7lzMLKnv2_X2x2cnvt4SDdtYp3JKN4	\N	1	3500 เหรียญ x1	55.5	153.5	รายการสำเร็จ	แทน	YOUTRIP		2025-09-03 14:06:58.953068+00
351	ODR-20250903-2763	2025-09-02 18:35:15+00	FACEBOOK	Thanawut Punchotz	(ID-PASS) เติมได้หลายเกม	239	https://drive.google.com/uc?id=11tQgT_LARJ8rujDurujIs0Sr4l9Owiem	https://drive.google.com/uc?id=1xSmpkeqba7P9jhDr6TOlDLs9STagVBtM	\N	1	299 BAHT (7.99$) x1	198.15	40.85	รายการสำเร็จ	แทน	ITUNES	7.99*24.80	2025-09-03 14:05:04.249818+00
441	ODR-20250912-1801	2025-09-12 07:30:40+00	FACEBOOK	ทินภัทร์ แซ่เฮง	MINECRAFT	239	https://drive.google.com/uc?id=1B2O7dBvMssC1QD3kG5ueOxcy6OKdW-d-	https://drive.google.com/uc?id=1nb5NpETowU0JNPvSXqrLW77byXe61dsh	\N	1	3820 เหรียญ x1	0	239	ยกเลิก/คืนเงิน	เกรซ	YOUTRIP	ทำรายการเติมให้ลูกค้าไม่ได้ // เกมอัพเดท	2025-09-12 14:49:31.675574+00
398	ODR-20250906-3435	2025-09-06 09:47:21+00	LINE	Papungkon	DUNK_DYNASTY	279	https://drive.google.com/uc?id=1bD5Qi39Y-cv_07wRCbzYyJTfvPZpxHHQ	https://drive.google.com/uc?id=1cpSKf8xT-_q9E9tC6tDmay1mWB4aMJ_z	\N	1	Extra Premium Pass x1	232.56	46.44	รายการสำเร็จ	แทน	RAZERGOLD	8.71*26.70	2025-09-06 15:57:41.357488+00
397	ODR-20250906-3096	2025-09-06 08:45:43+00	FACEBOOK	Jijie Poompech	LOL_WILDRIFT	189	https://drive.google.com/uc?id=1QrAvI5UWDGy4LXUH6zfXNC2oD6i5SsJi	https://drive.google.com/uc?id=1BNuPHdas1Le7dcw9-Pb5l4tjiavRbzlZ	\N	1	1000WC x1	149.92	39.08	รายการสำเร็จ	แทน	YOUTRIP		2025-09-06 15:55:54.576395+00
396	ODR-20250906-6283	2025-09-06 08:29:51+00	FACEBOOK	Jijie Poompech	LOL_WILDRIFT	339	https://drive.google.com/uc?id=1UOJ-zo3zk7xfO2M3pNCJm2Dt7gGS9irw	https://drive.google.com/uc?id=1_urMmc_PQxffOInOELfrM8_7C9kAHJ3a	\N	1	1850WC x1	268.28	70.72	รายการสำเร็จ	แทน	YOUTRIP		2025-09-06 15:53:28.053936+00
395	ODR-20250906-7105	2025-09-06 01:14:03+00	FACEBOOK	Zdx Lock	LOL_WILDRIFT	569.11	https://drive.google.com/uc?id=1_dmwx0RmROR5PlYZX97jjFi1EHL3hEmd	https://drive.google.com/uc?id=1WLb5_xc06ZwEtiBznfaGj1NrRYW5Z43k	\N	1	3275WC x1	457.66	111.45	รายการสำเร็จ	เกรซ	YOUTRIP		2025-09-06 15:20:18.045047+00
401	ODR-20250906-5060	2025-09-06 13:37:23+00	FACEBOOK	Thanawut Punchotz	(ID-PASS) เติมได้หลายเกม	537	https://drive.google.com/uc?id=1cTcMqkjR8yVFQClU8zvl_T21nbDegJHN	https://drive.google.com/uc?id=1djqAXvHQ1CkHRvLhaoh4L6T9qPYIXIf0	\N	3	149 BAHT (3.99$) x1, 199 BAHT (4.99$) x1, 299 BAHT (7.99$) x1	443.26	93.74	แก้ไขรายการ	แทน	ITUNES	3.99*24.80+7.99*24.8+5.99*24.40 // ลูกค้าโอนเงินชำระเพิ่ม 30 บาท	2025-09-06 16:02:47.77315+00
402	ODR-20250906-4849	2025-09-06 16:13:33+00	FACEBOOK	אוליבר סייקס	LOL_WILDRIFT	800	https://drive.google.com/uc?id=1OhyvnYvIYSWUc5YYVwm9wq3XzaNGUwDh	https://drive.google.com/uc?id=1_5BB3KOWnFdUBPFtG7Y7iVvPXIrU723X	\N	1	4800WC x1	650.98	149.02	รายการสำเร็จ	เกรซ	YOUTRIP		2025-09-06 16:22:53.1964+00
400	ODR-20250906-4130	2025-09-06 11:44:49+00	FACEBOOK	Theeraphat Sakulpaprasert	LOL_WILDRIFT	339.33	https://drive.google.com/uc?id=1Ugjk-r21v-ZEGdz-Pylo62DoYX00K9_e	https://drive.google.com/uc?id=1ruV3b07uin3iIx98y2edQfkkZuwWPtqz	\N	1	1850WC x1	268.28	71.05	รายการสำเร็จ	แทน	YOUTRIP		2025-09-06 16:00:43.963561+00
399	ODR-20250906-7020	2025-09-06 10:26:11+00	LINE	宋雪 (28) Jidapha	MINECRAFT	69.01	https://drive.google.com/uc?id=1EEn9ZUNBiWZviOCy1EFRfuk14m9bBNwF	https://drive.google.com/uc?id=1KorCLCt8UeXknyGLPWaLygHvbGG_PF1B	\N	1	640 เหรียญ x1	11.04	57.97	รายการสำเร็จ	แทน	YOUTRIP		2025-09-06 15:59:04.770605+00
407	ODR-20250907-4587	2025-09-07 12:55:18+00	FACEBOOK	Yanisa Poolklin	MINECRAFT	209	https://drive.google.com/uc?id=1xJ6MNPzuFV1bngyIptU43t5sgNM4h1hX	https://drive.google.com/uc?id=16nY6KW2xt4HxkI3Wksz7EADx6cDyIuji	\N	1	3500 เหรียญ x1	55.23	153.77	รายการสำเร็จ	เกรซ	YOUTRIP		2025-09-07 13:23:08.185953+00
406	ODR-20250907-7867	2025-09-07 09:15:57+00	LINE	HEDтᎥsт	LOL_WILDRIFT	800	https://drive.google.com/uc?id=1zdgBWeZDWNh3V1KsbdcH8eZVia-5yw5b	https://drive.google.com/uc?id=1CJzk6lTCVxAOnpLgHNkv2S0_7Qkrjslm	\N	1	4800WC x1	650.98	149.02	รายการสำเร็จ	แทน	YOUTRIP		2025-09-07 13:22:27.971535+00
404	ODR-20250907-1843	2025-09-07 07:52:08+00	FACEBOOK	Panittha Inpayung	LOL_WILDRIFT	569	https://drive.google.com/uc?id=1N1wupBClvRCZ6OyV9XWN4vW7vhLMEwJm	https://drive.google.com/uc?id=1HhalvnOHaFkU_Ce18ocLiK2I9Nf3inH1	\N	1	3275WC x1	457.66	111.34	รายการสำเร็จ	เกรซ	YOUTRIP		2025-09-07 13:20:53.721818+00
408	ODR-20250907-3169	2025-09-07 13:01:29+00	FACEBOOK	Axt Pnppl	DUNK_DYNASTY	169	https://drive.google.com/uc?id=17kBga10TwY7_hv5F4l-LQiyi3Oh53qkB	https://drive.google.com/uc?id=1lgJSIkltqBPXUn9zRuDHBqLnTbe1Frad	\N	1	Premium Pass x1	139.37	29.63	รายการสำเร็จ	เกรซ	RAZERGOLD	5.22*26.70	2025-09-07 13:23:30.113086+00
405	ODR-20250907-7178	2025-09-07 08:24:52+00	FACEBOOK	Panittha Inpayung	LOL_WILDRIFT	189	https://drive.google.com/uc?id=1-klrdKoCz0X3hMX8x5fHvTPMePn4lAq_	https://drive.google.com/uc?id=1ORoXoM3dEbEAi-E2ePkU-w7JpIki8wbJ	\N	1	1000WC x1	149.92	39.08	รายการสำเร็จ	แทน	YOUTRIP		2025-09-07 13:21:27.716999+00
403	ODR-20250907-2728	2025-09-06 19:57:34+00	FACEBOOK	Kaopun Tangchutaveesub	HONKAI_STARRAIL	290	https://drive.google.com/uc?id=12Iip_b5IrquP2xnnBM2jSjuzavGZBKWC	https://drive.google.com/uc?id=1AVygnr4jgYCRs8sPtZ0_p1uwEGsGWH7r	\N	1	BP กิตติคุณ 9.99$ x1	243.76	46.24	รายการสำเร็จ	แทน	ITUNES	9.99*24.4	2025-09-07 13:19:49.023775+00
419	ODR-20250909-6935	2025-09-09 08:41:48+00	FACEBOOK	Alex Phataradorn	ROV_MOBILE	296	https://drive.google.com/uc?id=1gcnVeU1hH_jGCB3MePQD1Gyx8ZugOyF6	https://drive.google.com/uc?id=1G2Bu8QwgWHH7lN2bAXIH5-V-dOzzRmXD	\N	1	370 ปอง x1	282	14	รายการสำเร็จ	แทน	RICHMAN		2025-09-09 17:11:03.652652+00
429	ODR-20250910-7804	2025-09-10 12:19:58+00	FACEBOOK	โด้ เตาปูน	VALORANT	1635	https://drive.google.com/uc?id=1Z-2CzAxXhQRM1cfz5OxwI6WSfNhf7hzV	https://drive.google.com/uc?id=1VmxLCxCTy2t3RaWKHdjuHkSQqBuWHB5T	\N	1	[6700VP] CHAMP2025 เหมาหมด x1	1572.5	62.5	รายการสำเร็จ	แทน	RICHMAN		2025-09-10 15:38:23.630676+00
428	ODR-20250910-9552	2025-09-10 09:59:03+00	FACEBOOK	Natakron Suknit	MINECRAFT	129	https://drive.google.com/uc?id=1bX3m262ZfX_yTAmnFanXEoaKMJxGEEWo	https://drive.google.com/uc?id=1lyovGNY7l4JiTQNxbJOGMGopRqaVZWhj	\N	1	1280 เหรียญ x1	21.64	107.36	รายการสำเร็จ	แทน	YOUTRIP		2025-09-10 15:37:24.662964+00
427	ODR-20250910-9899	2025-09-10 08:39:58+00	FACEBOOK	Pongspak Kitnitchee	DUNK_DYNASTY	159	https://drive.google.com/uc?id=1B-Lpr1d501tazPmyUFIplwaUqUmRgM9a	https://drive.google.com/uc?id=1_O_sFDFArZEXYOsX2CwF7agtzPhQw83p	\N	1	Party Membership x1	125.49	33.51	รายการสำเร็จ	แทน	RAZERGOLD	4.70*26.70	2025-09-10 15:36:22.027731+00
426	ODR-20250910-1126	2025-09-10 08:24:06+00	FACEBOOK	Boss Bosz	MINECRAFT	209	https://drive.google.com/uc?id=18zUq4T0rdIi6ytuDCzLN48aoJoCMCanq	https://drive.google.com/uc?id=14XV4kQ8H76X8MouSRV9DqiPh0iLFsovM	\N	1	3500 เหรียญ x1	54.13	154.87	รายการสำเร็จ	แทน	YOUTRIP		2025-09-10 15:35:54.081673+00
425	ODR-20250910-1885	2025-09-09 19:04:28+00	FACEBOOK	MA MY	LOL_WILDRIFT	800	https://drive.google.com/uc?id=1-dXFRpMMDKkCVP-V9XoV3kY6JBFqu4B-	https://drive.google.com/uc?id=1iHp2LoxCzDEoKF9J4w214ufQfEpElz19	\N	1	4800WC x1	638.07	161.93	รายการสำเร็จ	แทน	YOUTRIP		2025-09-10 15:35:17.127566+00
424	ODR-20250910-6808	2025-09-09 18:54:14+00	FACEBOOK	MA MY	LOL_WILDRIFT	800	https://drive.google.com/uc?id=17ydg8PM29ATisFegHC8sfbuDfXTMhgT0	https://drive.google.com/uc?id=1023WoX3O71B9BIJsXag1xskEv-1-OIVB	\N	1	4800WC x1	646.16	153.84	รายการสำเร็จ	แทน	YOUTRIP		2025-09-10 15:34:02.55631+00
420	ODR-20250909-1874	2025-09-09 13:55:58+00	FACEBOOK	Boss Bosz	MINECRAFT	209	https://drive.google.com/uc?id=1j9zbWV64Vp3FF5hA28zRDvRFCbBzwISj	https://drive.google.com/uc?id=1jod7aZ93HphMqkoVI5zhfmwsErlI3NDc	\N	1	3500 เหรียญ x1	54.82	154.18	รายการสำเร็จ	แทน	YOUTRIP		2025-09-09 17:13:04.499474+00
423	ODR-20250910-2580	2025-09-09 18:35:14+00	FACEBOOK	MA MY	LOL_WILDRIFT	800	https://drive.google.com/uc?id=1M7AbEM9Lm_wOiYPMLGOelpWIZc3McXwJ	https://drive.google.com/uc?id=1924tY96knen_HLDRrcsE5Msmipk1wsLI	\N	1	4800WC x1	646.16	153.84	รายการสำเร็จ	แทน	YOUTRIP		2025-09-10 15:33:30.973326+00
422	ODR-20250909-2800	2025-09-09 15:08:03+00	LINE	💪boss🕴♂🍃 246	LOL_WILDRIFT	339	https://drive.google.com/uc?id=1KYC-MVpQrMWeQgvTH_0OXSsLZklLR5Ll	https://drive.google.com/uc?id=1Yg1QddChX6mjuuruZEwF6dqnb5IW-m4J	\N	1	1850WC x1	266.3	72.7	รายการสำเร็จ	เกรซ	YOUTRIP		2025-09-09 17:14:24.781136+00
421	ODR-20250909-2202	2025-09-09 14:58:36+00	FACEBOOK	Kaopun Tangchutaveesub	MARVEL_RIVALS	300	https://drive.google.com/uc?id=1ncjI9d_stPOYWz1ed4SCu9MyUAhV2kqA	https://drive.google.com/uc?id=1UT2Dlyd0iEjWDka2Ol_pX57Gn7xnh0yx	\N	2	100LATT x1, 1000LATT x1	293	7	รายการสำเร็จ	แทน	24BUYM		2025-09-09 17:13:47.557033+00
418	ODR-20250909-5560	2025-09-09 07:14:00+00	FACEBOOK	ฝันดี นะค้าบ	HONKAI_STARRAIL	278	https://drive.google.com/uc?id=1EzvsV2yyLM6xfAHhtyjdYsVf1ZibSnxn	https://drive.google.com/uc?id=1blToMFDdWx9mg6e33uQTux7hZk9O9ME4	\N	1	บัตรกำนัลเสบียงรถไฟ (2x) x1	0	278	รายการสำเร็จ	แทน	RAZERGOLD		2025-09-09 17:10:18.121177+00
417	ODR-20250908-8050	2025-09-08 15:46:54+00	FACEBOOK	Worawit Chainaranon	DUNK_DYNASTY	318	https://drive.google.com/uc?id=127AwrjP9KENuUFnjVUiH8HTHJfZsmg7S	https://drive.google.com/uc?id=10Tgdy8QBXTEGWEmi3Wid3KjeX-MUZPcW	\N	2	Party Membership x2	251.51	66.49	รายการสำเร็จ	เกรซ	RAZERGOLD		2025-09-08 15:53:13.693008+00
416	ODR-20250908-6720	2025-09-08 14:39:08+00	FACEBOOK	Marilyn Kitty's	DUNK_DYNASTY	169	https://drive.google.com/uc?id=1mlGy0HEuCR7xAky9_sZfHuv2nby3ZDlt	https://drive.google.com/uc?id=1IbGnhZJfK9aDc0hzqrrfW77nXoXFTY9E	\N	1	Premium Pass x1	140.71	28.29	รายการสำเร็จ	เกรซ	RAZERGOLD	5.27*26.70	2025-09-08 14:51:01.614303+00
415	ODR-20250908-5778	2025-09-08 14:49:53+00	FACEBOOK	Mekk Ponthep	ROBLOX	759	https://drive.google.com/uc?id=1B9p63oXQTYHbUFs1XPsYzQazeUlgp3fc	https://drive.google.com/uc?id=1EC7Pm00be4R3Mu28h3VUcDjR0jPSfBHB	\N	2	400 ROBUX x1, 1700 ROBUX x1	609.51	149.49	รายการสำเร็จ	แทน	ITUNES	24.98*24.40	2025-09-08 14:50:33.882944+00
414	ODR-20250908-6003	2025-09-08 13:50:28+00	FACEBOOK	แฟ้มไง ไม่ต้องถาม	VALORANT	375	https://drive.google.com/uc?id=1oRPJt5KDcf5EnHP6LWyhnF8FIMU8Y9W-	https://drive.google.com/uc?id=14rX1om8FADC5UL7ZZFaFRbFRmch_6Vnv	\N	1	1475VP x1	360.8	14.2	รายการสำเร็จ	เกรซ	RICHMAN		2025-09-08 14:49:44.577448+00
412	ODR-20250908-4974	2025-09-08 11:33:26+00	LINE	28 แพรศศิ	MINECRAFT	105	https://drive.google.com/uc?id=1brm-IVvjjIThjHRkUxYn8RUUQMSWy-Xj	https://drive.google.com/uc?id=1cNXZlqe2LMTH4OpIcsNybWDMzInrfcrP	\N	1	960 เหรียญ x1	16.56	88.44	รายการสำเร็จ	แทน	YOUTRIP		2025-09-08 14:48:43.651749+00
411	ODR-20250908-5328	2025-09-08 08:43:33+00	FACEBOOK	Possavee Dhammasiri	RACING_MASTER	86	https://drive.google.com/uc?id=1gcBGRDLfpyhlGxF8UQeNPcpQurwCUMHr	https://drive.google.com/uc?id=1vvolvTsXz8zkLPK5TbyLKZOiZBEfbMWu	\N	1	221GEMS x1	70.49	15.51	รายการสำเร็จ	แทน	RAZERGOLD	2.64*26.70	2025-09-08 14:47:29.43434+00
409	ODR-20250908-4292	2025-09-08 05:17:48+00	FACEBOOK	น้องอ้วงง อุ้ง อุ้ง	LOL_WILDRIFT	569	https://drive.google.com/uc?id=1nBdl5aNwzL0mHx0KXtBtCs0ur4HhRF4R	https://drive.google.com/uc?id=1-LlvgQ3oMnbtZnc-aSAaIPFuyPIbHY7_	\N	1	3275WC x1	457.66	111.34	รายการสำเร็จ	แทน	YOUTRIP		2025-09-08 14:45:56.070521+00
413	ODR-20250908-8139	2025-09-08 12:56:35+00	FACEBOOK	Jaofarmza Eiei	DUNK_DYNASTY	559	https://drive.google.com/uc?id=183b-N60tNRHj0EPzhb9MCMBXJGAudGAA	https://drive.google.com/uc?id=1l7VS8uzBYVDptU_kRhmrWrwFM4-whYB0	\N	1	699BAHT (19.99$) x1	487.76	71.24	รายการสำเร็จ	แทน	ITUNES	19.99*24.40	2025-09-08 14:49:18.188165+00
410	ODR-20250908-1013	2025-09-08 06:47:28+00	LINE	𝐼 𝑚𝑖𝑠𝑠 ℎ𝑒𝑟	VALORANT	750	https://drive.google.com/uc?id=1L7fAGIe0BUSqELCmUXD2wyPXoAsyRUNs	https://drive.google.com/uc?id=1k2VEXxQ-BjgYjNzQvLb5NpSMIjNQ620p	\N	1	[3050VP] CHAMP2025 ปืนแยก x1	721.5	28.5	รายการสำเร็จ	แทน	RICHMAN		2025-09-08 14:46:47.057834+00
440	ODR-20250912-9353	2025-09-12 02:34:12+00	FACEBOOK	โคโดโมะ จ้า	LOL_WILDRIFT	800	https://drive.google.com/uc?id=1aCweTZEpm0Tzi9W-U9r5e0i7U6S2X6KS	https://drive.google.com/uc?id=1lIAq0FSmOaiVIhGFKrv29ka7E9uoxPi9	\N	1	4800WC x1	640.67	159.33	รายการสำเร็จ	เกรซ	YOUTRIP		2025-09-12 14:48:26.871667+00
430	ODR-20250910-6229	2025-09-10 16:21:15+00	LINE	ณัฐพงศ์	VALORANT	505.05	https://drive.google.com/uc?id=1Kh2ZD0nc8dbuk88LtaXcpTPY26RpPct7	https://drive.google.com/uc?id=1KYRvYu3O0vH4DgZkR9FQuQp4E73wPI5J	\N	1	2050VP x1	481	24.05	รายการสำเร็จ	แทน	RICHMAN		2025-09-10 17:29:59.139348+00
435	ODR-20250911-1525	2025-09-11 15:05:29+00	FACEBOOK	Nattasit Teankai	TFT_MOBILE	2049	https://drive.google.com/uc?id=1x_t3yT-fHU8dQusFvSlYWhcDCDVdJG0_	https://drive.google.com/uc?id=1JWi4hhsdtDfNYolWzdbBvjqR5bwVk77s	\N	1	13500TFT x1	1786.4	262.6	รายการสำเร็จ	แทน	YOUTRIP		2025-09-11 15:37:24.068185+00
434	ODR-20250911-5885	2025-09-11 13:41:05+00	FACEBOOK	Phurinat Chrm	VALORANT	1635	https://drive.google.com/uc?id=1b5mzjHN4afIdGkodQG31f8UwEK6FW15U	https://drive.google.com/uc?id=1-Nv0aOME7vkhOcO8azHliJrnFpf0gB9t	\N	1	[6700VP] CHAMP2025 เหมาหมด x1	1572.5	62.5	รายการสำเร็จ	เกรซ	RICHMAN		2025-09-11 15:36:53.778947+00
433	ODR-20250911-7425	2025-09-11 10:49:39+00	FACEBOOK	Giming LoveNa	TFT_MOBILE	239	https://drive.google.com/uc?id=1G28Yzr7P_C0b0wsSLYWZ5oaaKelAwVBx	https://drive.google.com/uc?id=164pcK_PeCArkErUAPy5yYkEmM_FOJ26X	\N	1	1380TFT x1	194.17	44.83	รายการสำเร็จ	เกรซ	YOUTRIP		2025-09-11 15:36:27.563874+00
432	ODR-20250911-1972	2025-09-11 09:17:05+00	FACEBOOK	Oat Wachirayut Niranam	VALORANT	125	https://drive.google.com/uc?id=1uxYX15CzKta5UEXlTdh3svsdyCIvOEvR	https://drive.google.com/uc?id=12Eu6OfRq6klNrsBVWSNWxFitV7o9MMTr	\N	1	475VP x1	120.3	4.7	รายการสำเร็จ	แทน	RICHMAN		2025-09-11 15:35:57.863613+00
431	ODR-20250911-7058	2025-09-11 05:28:42+00	FACEBOOK	Khwanchai Sriwirut	MINECRAFT	209	https://drive.google.com/uc?id=1Te16Q8mYgYFUf0rLXHQ1dI4deEonmyIT	https://drive.google.com/uc?id=15ahP3fnzjFGotNRB9ixsz_gH7Jxy4dst	\N	1	3500 เหรียญ x1	54.36	154.64	รายการสำเร็จ	เกรซ	YOUTRIP		2025-09-11 15:34:38.647289+00
439	ODR-20250912-6963	2025-09-12 01:53:36+00	FACEBOOK	Sorasak Nakbun	LOL_WILDRIFT	569	https://drive.google.com/uc?id=14etK_afvPsfaz7MqOKcVSrRecpe2cWEs	https://drive.google.com/uc?id=1NoDyhukOf4C3wB-v9KNrZwOYXRJRYrQh	\N	1	3275WC x1	450.41	118.59	รายการสำเร็จ	เกรซ	YOUTRIP		2025-09-12 14:48:02.416695+00
438	ODR-20250912-2378	2025-09-12 01:40:23+00	FACEBOOK	Aueaathon Sirisakorn	LOL_WILDRIFT	378	https://drive.google.com/uc?id=1Mz37QdulA33NKbcQxpqYFRUEFRCmhGVO	https://drive.google.com/uc?id=1yRe4T2i2pAyTLovUPOeoq4kx4ae9cjbU	\N	2	1000WC x2	295.1	82.9	รายการสำเร็จ	เกรซ	YOUTRIP		2025-09-12 14:47:26.271621+00
437	ODR-20250912-7498	2025-09-11 17:57:52+00	FACEBOOK	Mekk Ponthep	TFT_MOBILE	119	https://drive.google.com/uc?id=1L6q5oSwyp_PjO67YvdTgCck8Y6bAsk9k	https://drive.google.com/uc?id=1dMju_pEtKEXjwuVh4IqTbI-iFfw5v0DO	\N	1	575TFT x1	93.2	25.8	รายการสำเร็จ	แทน	YOUTRIP		2025-09-12 14:46:26.378304+00
468	ODR-20250915-2228	2025-09-15 08:17:45+00	FACEBOOK	Tum Weerapat	VALORANT	1635	https://drive.google.com/uc?id=1gX1Rv_HDr_bFHJ1UfuHjfeagvkt-y9h8	https://drive.google.com/uc?id=1httroK9AwAuOWVWJzz4ibMMevfoTf_X4	\N	1	[6700VP] CHAMP2025 เหมาหมด x1	1572.5	62.5	รายการสำเร็จ	เกรซ	RICHMAN		2025-09-15 16:24:32.740712+00
467	ODR-20250915-1429	2025-09-15 08:10:00+00	FACEBOOK	Kongpob Roayutara	PUBG_MOBILE	149	https://drive.google.com/uc?id=16iLIaeoGkuVVJdM5d85j2sIhJ_TFoFEz	https://drive.google.com/uc?id=1sqPDXoiMALnS56G8Ktqakz0sJVRUzVwQ	\N	1	325UC x1	133.77	15.23	รายการสำเร็จ	เกรซ	RAZERGOLD	5.01*26.70	2025-09-15 16:23:58.971717+00
465	ODR-20250915-3792	2025-09-15 02:29:00+00	FACEBOOK	Jaofarmza Eiei	DUNK_DYNASTY	159	https://drive.google.com/uc?id=1wp5zQDxiHDRWz9gugy0GJ3ZmQEEWUTIB	https://drive.google.com/uc?id=1Dc6Se2dH6skalZnvUUN2ORyEAW6IICgA	\N	1	330TOKENS x1	126.56	32.44	รายการสำเร็จ	แทน	RAZERGOLD	4.74*26.70	2025-09-15 16:22:25.953465+00
464	ODR-20250915-1067	2025-09-15 14:16:00+00	FACEBOOK	Jaofarmza Eiei	DUNK_DYNASTY	578	https://drive.google.com/uc?id=1kO_CXAXylPcLKjfls79aL7jljqMBa2wA	https://drive.google.com/uc?id=1uUu5eO0FFvPayiXrHfVLBEtxgL2eXj51	\N	2	330TOKENS x1, 1110TOKENS x1	499.82	78.18	รายการสำเร็จ	แทน	RAZERGOLD	18.72*26.70	2025-09-15 16:21:25.045151+00
462	ODR-20250915-2680	2025-09-14 20:59:16+00	FACEBOOK	MA MY	LOL_WILDRIFT	89	https://drive.google.com/uc?id=1fFjB9fdpRBoIMFtlBajn12ZTNNPqXW85	https://drive.google.com/uc?id=1Atk39quuCOAppW_ky0zC5bDrL3Jcptrn	\N	1	425WC x1	65.91	23.09	รายการสำเร็จ	แทน	YOUTRIP		2025-09-15 16:19:21.150948+00
461	ODR-20250915-2334	2025-09-14 20:46:53+00	FACEBOOK	MA MY	LOL_WILDRIFT	339	https://drive.google.com/uc?id=1eR1adA4QlMo6OdsT7nQ7di3yo000WGoY	https://drive.google.com/uc?id=1qMmKeXFvaX5JVv4Eew-dFcytvLFDLhdI	\N	1	1850WC x1	263.65	75.35	รายการสำเร็จ	แทน	YOUTRIP		2025-09-15 16:18:45.359666+00
459	ODR-20250915-2377	2025-09-14 19:23:47+00	FACEBOOK	Wachirawit Peam	HONKAI_STARRAIL	239	https://drive.google.com/uc?id=1YI0ve38163LK2MAj8JSpElm8mfU9R60N	https://drive.google.com/uc?id=10ehOSAMXiimFxtEoYm9X2DrU9DwtE44F	\N	2	พรแห่งดวงจันทร์ x1, บัตรกำนัลเสบียงรถไฟ x1	117	122	รายการสำเร็จ	แทน	RICHMAN		2025-09-15 16:16:41.203359+00
457	ODR-20250914-8345	2025-09-14 15:34:53+00	FACEBOOK	Pasit Title	MARVEL_RIVALS	735	https://drive.google.com/uc?id=1nGfyWImUabryvN5Uzt9OteHWvwKu6XDF	https://drive.google.com/uc?id=1tNikxY1bBagKuZq-bsx0OWbGhgAjC-fg	\N	1	2680LATT x1	665	70	รายการสำเร็จ	เกรซ	24BUYM		2025-09-14 15:58:44.4979+00
456	ODR-20250914-6097	2025-09-14 10:53:22+00	FACEBOOK	มะ แมว งง	LOL_WILDRIFT	569	https://drive.google.com/uc?id=10kTR5vQcxFjZKh-yd7GQa4cF4KT065aR	https://drive.google.com/uc?id=1WotqFZNwvwkTctpz2o0EsZerD3NMSJyT	\N	1	3275WC x1	449.76	119.24	รายการสำเร็จ	แทน	YOUTRIP		2025-09-14 15:58:23.009273+00
450	ODR-20250914-9011	2025-09-13 16:26:00+00	FACEBOOK	Sharks Dong	MINECRAFT	109	https://drive.google.com/uc?id=176DVfXBfwzkEKVJzzvtuPQJSCLJrfgZl	https://drive.google.com/uc?id=1FMVl5c0SMH2NlplUOO9ivPEbBT4NNK8V	\N	1	1280 เหรียญ x1	0	109	ยกเลิก/คืนเงิน	เกรซ	YOUTRIP	คืนเงินเนื่องจากระบบเติมมีปัญหา	2025-09-14 01:42:02.154441+00
475	ODR-20250916-7431	2025-09-16 07:43:15+00	FACEBOOK	Wutthipat Lueangronthong	DUNK_DYNASTY	169	https://drive.google.com/uc?id=1-03r5ATS3tdC59z_nMSh3T82IOHgnKJk	https://drive.google.com/uc?id=1oknHFnu5MmOYZpLssEIzwKdJPu-vfSdK	\N	1	Premium Pass x1	139.64	29.36	รายการสำเร็จ	แทน	RAZERGOLD	5.23*26.70	2025-09-16 15:57:06.395102+00
487	ODR-20250917-4624	2025-09-17 15:44:00+00	FACEBOOK	Jaofarmza Eiei	DUNK_DYNASTY	159	https://drive.google.com/uc?id=1bDL97d97jJaQZcrJTvsydJSoahLNAyai	https://drive.google.com/uc?id=1V3KKUBxBN8G9FsjeZJ2qQZlIjDoh9SFg	\N	1	330TOKENS x1	128.69	30.31	รายการสำเร็จ	เกรซ	RAZERGOLD	4.82*26.70	2025-09-17 16:20:07.680795+00
486	ODR-20250917-9342	2025-09-17 08:36:40+00	FACEBOOK	Jarusak Jung	LOL_WILDRIFT	89	https://drive.google.com/uc?id=1B3u2FTEOF56KKitXiyJkBVIf3sU91iB-	https://drive.google.com/uc?id=1EIzpzvGhmbJw9b2yj4XA_Uvm7Xt5remr	\N	1	425WC x1	65.88	23.12	รายการสำเร็จ	แทน	YOUTRIP		2025-09-17 16:18:48.93986+00
485	ODR-20250917-1907	2025-09-17 04:53:23+00	LINE	MOS Tanakon	COA	1429	https://drive.google.com/uc?id=1rXE7fKNbFxKUS0ub5V285rAOgON8VFHO	https://drive.google.com/uc?id=1T8jPCS0CENzaXZbpZrHnoHb2PlkunO3o	\N	1	4245 โอปอล x1	1322.72	106.28	รายการสำเร็จ	แทน	RAZERGOLD	49.54*26.70	2025-09-17 16:17:49.676047+00
484	ODR-20250917-2934	2025-09-17 04:49:42+00	LINE	MOS Tanakon	COA	2829	https://drive.google.com/uc?id=1AEkvWPLVpVjpXRE9AL1uK9lPKWGauFhf	https://drive.google.com/uc?id=1BkYmpS9GStYAvgpZFhA7RY96t9T-axBA	\N	1	8606 โอปอล x1	2643.83	185.17	รายการสำเร็จ	แทน	RAZERGOLD	99.02*26.70	2025-09-17 16:16:57.548633+00
483	ODR-20250917-8022	2025-09-17 04:37:00+00	FACEBOOK	Flook Rattasart	FREEFIRE	384	https://drive.google.com/uc?id=1Yy7IRCtmChQhcTTVGN3OEDfQ93AFJQC2	https://drive.google.com/uc?id=1G6dDkkeB92vJyB89YfrAgMuf1O7FwIDi	\N	2	310 เพชร x1, 1052 เพชร x1	367	17	รายการสำเร็จ	แทน	24BUYM		2025-09-17 16:16:12.281631+00
482	ODR-20250917-2662	2025-09-17 03:52:00+00	FACEBOOK	Flook Rattasart	FREEFIRE	89	https://drive.google.com/uc?id=1R4la2cbWpVzFxLZpnXhvZ97zZH2nXx-M	https://drive.google.com/uc?id=1xZm3AwPKzHAbI8enhd0avvWXiX32zrxN	\N	1	310 เพชร x1	85	4	รายการสำเร็จ	แทน	24BUYM		2025-09-17 16:15:00.387013+00
481	ODR-20250917-9345	2025-09-17 03:46:04+00	FACEBOOK	Sumet Tongyong	LOL_WILDRIFT	278	https://drive.google.com/uc?id=1ugbA6cWi0oWEzcptT10mSTl4USQPnLid	https://drive.google.com/uc?id=134vwB03O3nEqVXElTTnIOJ4UJbMOvI8Z	\N	1	1425WC x1	213.15	64.85	รายการสำเร็จ	แทน	YOUTRIP	147.27+65.88	2025-09-17 16:13:57.565425+00
480	ODR-20250917-3133	2025-09-17 02:50:54+00	LINE	Siwapol Burithat	LOL_WILDRIFT	569	https://drive.google.com/uc?id=1lVKH4Nj7KTBF_yiUya0ZKb7fwoqK95yg	https://drive.google.com/uc?id=14vp6V6b1zJIk84tfZZf-npLAxF0cPRok	\N	1	3275WC x1	449.55	119.45	รายการสำเร็จ	เกรซ	YOUTRIP		2025-09-17 16:13:22.008363+00
479	ODR-20250916-8304	2025-09-16 11:25:12+00	FACEBOOK	Nattasit Teankai	TFT_MOBILE	739	https://drive.google.com/uc?id=1Vgvhzr0T4fO07T9oaKwXorazBPgY7g6t	https://drive.google.com/uc?id=1Sc_rhz64wTGWnWHgtuHmtd3YPeNzdxnx	\N	1	4500TFT x1	624.28	114.72	รายการสำเร็จ	เกรซ	YOUTRIP		2025-09-16 16:00:31.763073+00
478	ODR-20250916-6871	2025-09-16 11:07:32+00	FACEBOOK	Nattasit Teankai	TFT_MOBILE	2488	https://drive.google.com/uc?id=1f9oDOzp-6UUQpnCGD0oj409q-tGhu-Xh	https://drive.google.com/uc?id=129r11T1fPvFsXSg3p164WVlN7MLbYXNS	\N	2	2800TFT x1, 13500TFT x1	2184.99	303.01	รายการสำเร็จ	เกรซ	YOUTRIP	1794.81+390.18	2025-09-16 15:59:56.528943+00
477	ODR-20250916-8926	2025-09-16 10:20:34+00	FACEBOOK	Ma Leen	LOL_WILDRIFT	339	https://drive.google.com/uc?id=1xu6me5lQWDduTv7tw201_fN3kDrgf-7K	https://drive.google.com/uc?id=1fYTgRkR0rgBrI8GS8sUDh4mOMPQjOSdq	\N	1	1850WC x1	265.32	73.68	รายการสำเร็จ	เกรซ	YOUTRIP		2025-09-16 15:59:19.218265+00
476	ODR-20250916-5525	2025-09-16 07:47:00+00	FACEBOOK	Marilyn Kitty's	DUNK_DYNASTY	159	https://drive.google.com/uc?id=1yyZYsDbmOuf6o-i5CND1kBUD06Fnf76G	https://drive.google.com/uc?id=1nbxwJcuXiUtevRChteWinXS-ruO4n9vs	\N	1	Party Membership x1	126.56	32.44	รายการสำเร็จ	แทน	RAZERGOLD	4.74*26.70	2025-09-16 15:57:53.935251+00
474	ODR-20250916-5273	2025-09-15 17:18:58+00	FACEBOOK	Max Jessada	LOL_WILDRIFT	889	https://drive.google.com/uc?id=1-Ry2MU851Maeq05lozO0c4Jjk_VA2T0h	https://drive.google.com/uc?id=1s5DTOrvu9zEVOD97dxjaU3Uw6fQXofk6	\N	1	5225WC x1	639.75	249.25	รายการสำเร็จ	แทน	YOUTRIP		2025-09-16 05:40:50.261337+00
500	ODR-20250918-7182	2025-09-18 18:12:32+00	FACEBOOK	Mekk Ponthep	7KNIGHT_Re:BIRTH	1670	https://drive.google.com/uc?id=1tPxCABcg_tAksQmpMmn5Gm0xF1VCLGFu	https://drive.google.com/uc?id=1yEHWj4WE_j1ZRhTcR2fmyo9Al_qbCWM1	\N	2	1150BAHT (31.99$) x2	1554.71	115.29	รายการสำเร็จ	แทน	ITUNES	63.98*2	2025-09-18 18:35:21.0723+00
499	ODR-20250918-8456	2025-09-18 17:30:50+00	FACEBOOK	Mekk Ponthep	7KNIGHT_Re:BIRTH	1620	https://drive.google.com/uc?id=19r_CSpPifY0VPoD3KgLepKBhtlpHzQDs	https://drive.google.com/uc?id=1-pIrwWQ0Zf3wzq1oVNdrQvIJzQ2xN5gj	\N	4	349BAHT (9.99$) x2, 729BAHT (19.99$) x2	1461.03	158.97	รายการสำเร็จ	แทน	ITUNES	(39.98*24.4) + (19.98*24.3) = 975.512+485.514	2025-09-18 18:34:15.85976+00
489	ODR-20250918-7843	2025-09-17 17:55:41+00	LINE	D E W🕊	LOL_WILDRIFT	160	https://drive.google.com/uc?id=1N3sYv2_aPwWTOsd__cS90OGMbWeLUznE	https://drive.google.com/uc?id=1YXbTNe_sDE570ZH6FqFP2Nq8jvaAYTfI	\N	1	1000WC x1	152.23	7.77	รายการสำเร็จ	แทน	YOUTRIP	ทำรายการวันที่ 7 สิงหาคม // เนื่องจากทำรายการผิด	2025-09-18 17:04:18.951188+00
498	ODR-20250918-3763	2025-09-18 17:24:00+00	FACEBOOK	Jaofarmza Eiei	DUNK_DYNASTY	159	https://drive.google.com/uc?id=1sah9BhQ-SZwlXTjFcceygoZCCC14xLiE	https://drive.google.com/uc?id=1pXhSVEFj7CbtmwMLrNFaEfxJYBMNX9fD	\N	1	330TOKENS x1	128.43	30.57	รายการสำเร็จ	เกรซ	RAZERGOLD	4.81*26.70	2025-09-18 18:31:10.67809+00
473	ODR-20250916-7688	2025-09-15 14:22:37+00	FACEBOOK	Sarunwath Chanthajohn	VALORANT	2535	https://drive.google.com/uc?id=1m4PMjiMcrPRmHgGJbeOS3C04FWyGfE-t	https://drive.google.com/uc?id=1JOLpFSJlwIwNbZ-TWSINkDszjmwBcLWb	\N	1	11000VP x1	2442	93	รายการสำเร็จ	เกรซ	RICHMAN		2025-09-16 05:40:20.485861+00
497	ODR-20250918-2855	2025-09-18 17:18:00+00	FACEBOOK	Jaofarmza Eiei	DUNK_DYNASTY	159	https://drive.google.com/uc?id=1qorc6gQhWYwI8wybvUKomzfviKHP6TpN	https://drive.google.com/uc?id=1DSxbsiuCGQOr1n6uwyUpdgWjnY8Ynx_O	\N	1	330TOKENS x1	128.43	30.57	รายการสำเร็จ	เกรซ	RAZERGOLD	4.81*26.70	2025-09-18 18:30:27.996531+00
496	ODR-20250918-9525	2025-09-18 17:12:56+00	FACEBOOK	Mekk Ponthep	7KNIGHT_Re:BIRTH	2240	https://drive.google.com/uc?id=1VgWp1bNPEMiNJpnsbtD-aSziHTbd9AHA	https://drive.google.com/uc?id=1b0_qIIwRc3TnhY_DN0NWWsDctxWOoC9X	\N	10	35BAHT (0.99$) x1, 69BAHT (1.99$) x1, 149BAHT (3.99$) x1, 69BAHT (1.99$) x1, 149BAHT (3.99$) x1, 179BAHT (4.99$) x1, 149BAHT (3.99$) x1, 349BAHT (9.99$) x1, 729BAHT (19.99$) x1, 1100BAHT (29.99$) x1	1998.36	241.64	รายการสำเร็จ	แทน	ITUNES	81.90*24.40	2025-09-18 18:26:11.611415+00
495	ODR-20250918-7846	2025-09-18 15:28:21+00	FACEBOOK	Mekk Ponthep	7KNIGHT_Re:BIRTH	929	https://drive.google.com/uc?id=1vXemqFsTRNMzgOgTAB_c4hQcL5B1yrx7	https://drive.google.com/uc?id=1V2qu_cjXFh0enxHsiVYvtSoifc5z_fBs	\N	3	1x 149BAHT (3.99$) x1, 1x 349BAHT (9.99$) x1, 1x 729BAHT (19.99$) x1	828.87	100.13	รายการสำเร็จ	แทน	ITUNES	33.97*24.40	2025-09-18 17:09:59.486491+00
494	ODR-20250918-3086	2025-09-18 15:07:10+00	LINE	🌺 ONOSAN 小野 🌺	MARVEL_RIVALS	575	https://drive.google.com/uc?id=1g6MAigCQf4nd3aHl_shkkMJTPPhenfzp	https://drive.google.com/uc?id=1MVVxyzmkf6BjhcQ2WxvTaKhm1wDxdga3	\N	1	2180LATT x1	532	43	รายการสำเร็จ	แทน	24BUYM		2025-09-18 17:08:49.978746+00
493	ODR-20250918-8698	2025-09-18 13:19:44+00	FACEBOOK	วงศธร อังศุธารานุกุล	MARVEL_RIVALS	150	https://drive.google.com/uc?id=1Z9mduLD2Ekprt_p2zRV-UOkpZtuvjfTD	https://drive.google.com/uc?id=178ZstvIty1EQDI5Q9mLQoCUKdoaCcEBK	\N	1	500LATT x1	133	17	รายการสำเร็จ	เกรซ	24BUYM		2025-09-18 17:07:34.704376+00
492	ODR-20250918-7716	2025-09-18 05:37:32+00	FACEBOOK	Mekk Ponthep	7KNIGHT_Re:BIRTH	1213	https://drive.google.com/uc?id=1SYBRxRr_wLtIgrlPrG6d_hh79iDgw1-V	https://drive.google.com/uc?id=1OwKN280nDIVOrp3GyTicCrYT7kMgV93w	\N	6	1x 35BAHT (0.99$) x1, 1x 249BAHT (6.99$) x1, 1x 729BAHT (19.99$) x1, 1x 69BAHT (1.99$) x1, 1x 349BAHT (9.99$) x1, 1x 179BAHT (4.99$) x1	1096.54	116.46	รายการสำเร็จ	แทน	ITUNES	44.94*24.40	2025-09-18 17:06:54.855979+00
491	ODR-20250918-3618	2025-09-18 03:54:17+00	FACEBOOK	Wongsathon Choothien	LOL_WILDRIFT	569	https://drive.google.com/uc?id=1jrku355QoioWCc0K9_vsDdH70xYU2KQE	https://drive.google.com/uc?id=16_XV4sLShh08YQ8wJ23WB4a-b87uVLN7	\N	1	3275WC x1	449.9	119.1	รายการสำเร็จ	แทน	YOUTRIP		2025-09-18 17:05:33.492578+00
490	ODR-20250918-7569	2025-09-17 18:06:56+00	FACEBOOK	D E W🕊	LOL_WILDRIFT	569.01	https://drive.google.com/uc?id=1sO-bsNKnFgocOyeF-GYOTEZ_zd1hvXYm	https://drive.google.com/uc?id=1y3kw5nxwCmGhMMuoglch_s0HYawHcerZ	\N	1	CELESTIAL x1	449.55	119.46	รายการสำเร็จ	แทน	YOUTRIP		2025-09-18 17:04:49.304231+00
472	ODR-20250916-3422	2025-09-15 12:58:00+00	FACEBOOK	Sumet Tongyong	LOL_WILDRIFT	569	https://drive.google.com/uc?id=14Pt3ekVFumJ-0J80mcMzqXC6mgQAkoZl	https://drive.google.com/uc?id=1cUB82ZvKjXe5JDRbamNXC2Q6s7VXeGc4	\N	1	3275WC x1	449.76	119.24	รายการสำเร็จ	เกรซ	YOUTRIP		2025-09-16 05:39:46.187217+00
471	ODR-20250916-3064	2025-09-15 10:56:53+00	FACEBOOK	ปาณิสรา กอมะณี	ROBLOX	155	https://drive.google.com/uc?id=1cHVjPkS2aykuFgbvKWGvsJ8_LAe_ORai	https://drive.google.com/uc?id=1fxbezpKaCftCREqnQDs7v0rIZtn-Rve-	\N	1	400 ROBUX x1	0	155	ยกเลิก/คืนเงิน	เกรซ	ITUNES	คืนเงินเนื่องจากลูกค้าจำรหัสผ่านไม่ได้	2025-09-16 05:38:55.790826+00
466	ODR-20250915-9590	2025-09-15 04:04:52+00	FACEBOOK	Aing Kawintra	LOL_WILDRIFT	189	https://drive.google.com/uc?id=1Q44pB7b7XYTZKDSjxIQEDZej4m3C92vG	https://drive.google.com/uc?id=16mMRoNl2t_ahLXu9Z99LPybxe-7ABiQM	\N	1	1000WC x1	147.34	41.66	รายการสำเร็จ	แทน	YOUTRIP		2025-09-15 16:22:50.863564+00
463	ODR-20250915-6548	2025-09-14 21:06:51+00	FACEBOOK	MA MY	LOL_WILDRIFT	339	https://drive.google.com/uc?id=1xNUXBpKcU-DkuQvkAzhBhF_MW8TL2Re_	https://drive.google.com/uc?id=1Xpy2pnzICDZahgE4CYbiLTlDHqKEqppD	\N	1	1850WC x1	263.65	75.35	รายการสำเร็จ	แทน	YOUTRIP		2025-09-15 16:20:09.340491+00
460	ODR-20250915-5949	2025-09-14 20:29:04+00	FACEBOOK	Thanaset Chatchonlimwat	MARVEL_RIVALS	30	https://drive.google.com/uc?id=1r_bkcnTXieqjW-CAho4FFfrf0lZxvX8k	https://drive.google.com/uc?id=11HKlojK9NmrinwVb9pL3waVrhPBM2860	\N	1	100LATT x1	27.26	2.74	รายการสำเร็จ	แทน	YOUTRIP		2025-09-15 16:17:21.284403+00
458	ODR-20250915-6759	2025-09-14 17:01:08+00	FACEBOOK	วงศธร อังศุธารานุกุล	MARVEL_RIVALS	570	https://drive.google.com/uc?id=1HRemoxRN1ceJ9LDao1lSqCn1PpUJPdvZ	https://drive.google.com/uc?id=19Jhv0f0ku4hSpDkZcay99zUJZmQp3TkZ	\N	1	2180LATT x1	532	38	รายการสำเร็จ	เกรซ	24BUYM		2025-09-15 16:15:17.217992+00
455	ODR-20250914-6991	2025-09-14 10:09:51+00	LINE	🌺 ONOSAN 小野 🌺	MARVEL_RIVALS	2729	https://drive.google.com/uc?id=1XI-kmkHj4lgpK63C_-x0ZI2OjWsA-EXj	https://drive.google.com/uc?id=1c5hD4Au5PWMeF6B4hNKXXWYHeGzDMbCk	\N	1	11600LATT x1	2650	79	รายการสำเร็จ	แทน	24BUYM		2025-09-14 15:58:01.91584+00
452	ODR-20250914-1382	2025-09-14 09:04:56+00	FACEBOOK	สรพัศ พลคชา	VALORANT	1635	https://drive.google.com/uc?id=1LIdCS9hn1gzEsuJedjUXwyBXpIwV8jyi	https://drive.google.com/uc?id=1Cn4IAB65bt546_kMXj7O1LKwOltu2ajV	\N	1	[6700VP] CHAMP2025 เหมาหมด x1	1572.5	62.5	รายการสำเร็จ	เกรซ	RICHMAN		2025-09-14 15:53:27.400321+00
449	ODR-20250913-6922	2025-09-13 09:48:12+00	FACEBOOK	Pound Kittisan	ROV_MOBILE	89	https://drive.google.com/uc?id=13gc09d-ySyV17JIjHVWs3g5vbTl_7W0A	https://drive.google.com/uc?id=1LwzYjrGYlfdrWkz2RvF5NDb8oda04vkz	\N	1	110 ปอง x1	85	4	รายการสำเร็จ	เกรซ	RICHMAN		2025-09-13 16:21:25.511341+00
448	ODR-20250913-8447	2025-09-13 09:36:45+00	FACEBOOK	Pound Kittisan	ROV_MOBILE	296	https://drive.google.com/uc?id=1_vWI4ZhwQ-eNbNPcPjwFeaWUtfLDuKNR	https://drive.google.com/uc?id=1pZ0YZYiBKl-3PQ7If_CkPLNWjcsZfnWT	\N	1	370 ปอง x1	282	14	รายการสำเร็จ	เกรซ	RICHMAN		2025-09-13 16:20:26.264628+00
447	ODR-20250913-4714	2025-09-13 07:04:16+00	FACEBOOK	Flook Rattasart	ROV_MOBILE	238	https://drive.google.com/uc?id=1c4q8mtkYkekC_LcUcHED1tZtX6aPs9o3	https://drive.google.com/uc?id=13raO8l5_OarLoS73XKnDaaMxQXYr5Gji	\N	2	110 ปอง x1, 185 ปอง x1	226	12	รายการสำเร็จ	เกรซ	RICHMAN		2025-09-13 16:19:57.323339+00
446	ODR-20250913-9982	2025-09-12 18:41:23+00	FACEBOOK	🌺 ONOSAN 小野 🌺	HONKAI_STARRAIL	2290	https://drive.google.com/uc?id=1igdmxtJJxZGaI3ObtB9pBY9n-IYamEKu	https://drive.google.com/uc?id=1kg8CgBtzV-R3dgq_TQrV8tdNA7YgOqze	\N	1	8080SHARD x1	2189	101	รายการสำเร็จ	แทน	24BUYM		2025-09-13 16:19:21.835521+00
445	ODR-20250913-4001	2025-09-12 17:09:00+00	FACEBOOK	Karn Nattarat	VALORANT	1889	https://drive.google.com/uc?id=1-F0kmSzEfGzNwHEF04oDh6h4L1WX_b54	https://drive.google.com/uc?id=1Pt-g9NLFmKn_dgbslkh8nFabFHB_yToa	\N	1	[7875VP] CHAMP2025 เหมาพาส x1	1822.3	66.7	รายการสำเร็จ	เกรซ	RICHMAN		2025-09-13 16:16:40.369551+00
512	ODR-20250919-8961	2025-09-19 16:15:22+00	FACEBOOK	Theeraphat Sakulpaprasert	LOL_WILDRIFT	89.03	https://drive.google.com/uc?id=1eVux_ovOJTMgwBEFeXUjZWwdV0ZOFwg3	https://drive.google.com/uc?id=1rUFtAtjpVCz328OfkZNIdCC10KsI0BqG	\N	1	425WC x1	66.17	22.86	รายการสำเร็จ	เกรซ	YOUTRIP		2025-09-19 17:30:39.385994+00
511	ODR-20250919-1887	2025-09-19 16:11:29+00	FACEBOOK	Peat Strnytk	7KNIGHT_Re:BIRTH	185	https://drive.google.com/uc?id=1koJzk6q-6vWzqqAv_oVvG45MKr2hBLxk	https://drive.google.com/uc?id=1JYfNvRJ2MHoz1BzQjBJ16PlKZzTE-u_N	\N	1	249BAHT (6.99$) x1	169.86	15.14	รายการสำเร็จ	แทน	ITUNES	6.99*24.30	2025-09-19 17:30:06.352388+00
521	ODR-20250920-6935	2025-09-20 11:38:59+00	FACEBOOK	Chitsanuphong Na Chaisri	HONKAI_STARRAIL	139	https://drive.google.com/uc?id=1ZpCwEa9uKfJ0AEXOLtsJrp0B-wiC3g37	https://drive.google.com/uc?id=1rSxXwFflOZ0ik9IRX8iHs0J4m3_aStfk	\N	1	บัตรกำนัลเสบียงรถไฟ x1	117	22	รายการสำเร็จ	เกรซ	RICHMAN		2025-09-20 15:31:53.410138+00
520	ODR-20250920-7566	2025-09-20 09:06:10+00	FACEBOOK	Thanadon Pliantawin	7KNIGHT_Re:BIRTH	589	https://drive.google.com/uc?id=1WkxprL5EwEVBRL9JgoGbzLTWhXcMydKn	https://drive.google.com/uc?id=1nIOFEsu6P6CJAs0vKt18mOoij9_Mkb7Q	\N	3	149BAHT (3.99$) x1, 249BAHT (6.99$) x1, 349BAHT (9.99$) x1	509.57	79.43	รายการสำเร็จ	แทน	ITUNES	20.97*24.30	2025-09-20 15:31:27.966658+00
519	ODR-20250920-3373	2025-09-20 08:36:36+00	LINE	MOS Tanakon	COA	1429	https://drive.google.com/uc?id=1UYIfvsCGEJnWRg8470dvPZ8YFyMIAbXZ	https://drive.google.com/uc?id=1Tj509nMatLp_incPn3razVYZa0q-szNl	\N	1	4245 โอปอล x1	1317.11	111.89	รายการสำเร็จ	แทน	RAZERGOLD	49.33*26.70	2025-09-20 15:30:41.95618+00
518	ODR-20250920-8132	2025-09-20 07:22:34+00	FACEBOOK	Thanadon Pliantawin	7KNIGHT_Re:BIRTH	1223	https://drive.google.com/uc?id=1Fs-r-js2NPtfDXrrXE8C_XEslFHRkaQN	https://drive.google.com/uc?id=1XewgUHpUyU0ezl2M4sdHgGDpRVpS1Wdp	\N	4	1100BAHT (29.99$) x1, 149BAHT (3.99$) x2, 249BAHT (6.99$) x1	1092.52	130.48	รายการสำเร็จ	เกรซ	ITUNES	44.96*24.30	2025-09-20 15:29:49.28307+00
517	ODR-20250920-8352	2025-09-19 21:58:32+00	FACEBOOK	Mekk Ponthep	7KNIGHT_Re:BIRTH	525	https://drive.google.com/uc?id=14cTTZCv73rJ06Aaw3L23U7vTfYa-vQtJ	https://drive.google.com/uc?id=1xN50WvfJgIvbH5atpNOAv27fPpKtrr0P	\N	1	729BAHT (19.99$) x1	485.76	39.24	รายการสำเร็จ	แทน	ITUNES	19.99*24.30	2025-09-20 15:28:44.873314+00
516	ODR-20250920-8754	2025-09-19 21:00:10+00	FACEBOOK	Mekk Ponthep	7KNIGHT_Re:BIRTH	498	https://drive.google.com/uc?id=1AITSNY7VG-g_e7Dwn6Esh45-pZg5MHp5	https://drive.google.com/uc?id=1SVfQLhb0nQ8EWuVsdJ4NbP4t2QO4i_UZ	\N	3	35BAHT (0.99$) x1, 249BAHT (6.99$) x1, 349BAHT (9.99$) x1	436.67	61.33	รายการสำเร็จ	แทน	ITUNES	17.97*24.30	2025-09-20 15:27:56.176305+00
515	ODR-20250920-9493	2025-09-19 19:40:00+00	FACEBOOK	วงศธร อังศุธารานุกุล	MARVEL_RIVALS	30	https://drive.google.com/uc?id=1BsIs_OKat6aofvggq7wvVO0AELQ2RIx-	https://drive.google.com/uc?id=1Arww1XJoto5y4VIFyT3BJ47FVkjHM4nB	\N	1	100LATT x1	27	3	รายการสำเร็จ	แทน	24BUYM		2025-09-20 15:26:47.837599+00
514	ODR-20250920-7823	2025-09-19 19:20:00+00	FACEBOOK	Mekk Ponthep	7KNIGHT_Re:BIRTH	285	https://drive.google.com/uc?id=15UIGW7yEULwgrtdkqZLohILbxPi_gHAc	https://drive.google.com/uc?id=14GCGgBbk3DqxP6aYOlM2bSVx0zGCEoSG	\N	1	349BAHT (9.99$) x1	242.76	42.24	รายการสำเร็จ	แทน	ITUNES	9.99*24.30	2025-09-20 15:26:02.052049+00
513	ODR-20250920-5342	2025-09-19 17:26:47+00	FACEBOOK	Wachirawit Peam	HONKAI_STARRAIL	610	https://drive.google.com/uc?id=1QzGd7quXIzr4nC7Vq436JiNhXuPXmRHa	https://drive.google.com/uc?id=1HJ8tWAXoR-nx6xlRj5czAGbvfF4A7qch	\N	1	BP เหรียญตรา 19.99$ x1	485.75	124.25	รายการสำเร็จ	แทน	ITUNES	19.99*24.30	2025-09-20 15:25:01.236178+00
510	ODR-20250919-7545	2025-09-19 15:57:08+00	FACEBOOK	Theeraphat Sakulpaprasert	LOL_WILDRIFT	189.02	https://drive.google.com/uc?id=1UuDsuQ3n8lMOUMiKrdOi9OIkmR8CMF0T	https://drive.google.com/uc?id=1bS7Xo9hwapxDHkbkXeuCSNfi3lwwwSdE	\N	1	1000WC x1	147.9	41.12	รายการสำเร็จ	เกรซ	YOUTRIP		2025-09-19 17:29:32.373488+00
508	ODR-20250919-5217	2025-09-19 07:11:27+00	FACEBOOK	New Ton	7KNIGHT_Re:BIRTH	285	https://drive.google.com/uc?id=1tocerCMq2mI6CtcK9TOmZhA1M5ygRrRG	https://drive.google.com/uc?id=1ZVEIzy-PCECOS7GaBq-rJIKoR-99F5QQ	\N	1	349BAHT (9.99$) x1	242.76	42.24	รายการสำเร็จ	แทน	ITUNES	9.99*24.30	2025-09-19 17:28:19.997179+00
506	ODR-20250919-4316	2025-09-19 06:13:23+00	FACEBOOK	Mekk Ponthep	7KNIGHT_Re:BIRTH	800	https://drive.google.com/uc?id=1-Rq4LDFLxogzRUJ0makpo-9OL170JacL	https://drive.google.com/uc?id=1l2KD7I6I0f6DedgT1AAkKuu3iM7ZzMeE	\N	1	1150BAHT (31.99$) x1	777.36	22.64	รายการสำเร็จ	แทน	ITUNES	31.99*24.30	2025-09-19 17:26:19.911738+00
504	ODR-20250919-9489	2025-09-19 03:14:48+00	FACEBOOK	Tienpansa ィ	VALORANT	2000	https://drive.google.com/uc?id=1YFdF291zqOHrWqiIvOXAVSrBR8Lppfqk	https://drive.google.com/uc?id=1ZnUiqOrm3I3bMRxiknwJtK6MbRKLggZX	\N	1	8400VP x1	1942.5	57.5	รายการสำเร็จ	แทน	RICHMAN		2025-09-19 17:15:21.297893+00
503	ODR-20250919-9132	2025-09-19 01:56:25+00	FACEBOOK	แฟ้มไง ไม่ต้องถาม	VALORANT	2129	https://drive.google.com/uc?id=17cI1gV3LzUymQIomOluW3mA7LyZMFbVA	https://drive.google.com/uc?id=1hDvMyPwHaQIUTuUpQ176kr0tYFkr-E3r	\N	1	[8750VP] PRELUDE 2.0 เหมาหมด x1	2053.5	75.5	รายการสำเร็จ	แทน	RICHMAN		2025-09-19 17:14:29.207463+00
502	ODR-20250919-5050	2025-09-19 00:16:21+00	FACEBOOK	Poom Kanarat	LOL_WILDRIFT	189	https://drive.google.com/uc?id=1EdyLEDqwpneZmSCiDAaWuPgcfaxVsPWz	https://drive.google.com/uc?id=1NFxc2XFE2fgU7GWJcIh0540aIoNPaff4	\N	1	1000WC x1	147.9	41.1	รายการสำเร็จ	แทน	YOUTRIP		2025-09-19 17:13:24.010111+00
523	ODR-20250921-3851	2025-09-20 21:04:37+00	FACEBOOK	ۦ hoshi	PUBG_MOBILE	319			\N	1	660UC x1	0	319	รอดำเนินการ	แทน	RAZERGOLD		2025-09-21 14:07:37.210728+00
524	ODR-20250921-2229	2025-09-20 21:21:53+00	FACEBOOK	Boomm Tanawat	LOL_WILDRIFT	569			\N	1	3275WC x1	0	569	รอดำเนินการ	แทน	YOUTRIP		2025-09-21 14:08:11.965901+00
509	ODR-20250919-7480	2025-09-19 12:44:55+00	FACEBOOK	Sarunwath Chanthajohn	VALORANT	505	https://drive.google.com/uc?id=1Q1h_iPXkjUDFt1RF7JMiBFwzEHqPJuzP	https://drive.google.com/uc?id=1SSZgQRa3UmAZ4gdan5nqYX9ORhmsTcqA	\N	1	2050VP x1	481	24	รายการสำเร็จ	เกรซ	RICHMAN		2025-09-19 17:28:45.483902+00
507	ODR-20250919-8772	2025-09-19 06:23:15+00	FACEBOOK	Aun 'sirikit	DUNK_DYNASTY	159	https://drive.google.com/uc?id=1LzYgYesoWFKL5F_Wpom8OPu_7Al3rFqc	https://drive.google.com/uc?id=1npbjpb7JiQ7xMZEU1xDpB7RpAGlvv8b8	\N	1	Party Membership x1	128.43	30.57	รายการสำเร็จ	แทน	RAZERGOLD	4.81*26.70	2025-09-19 17:27:15.358194+00
505	ODR-20250919-4533	2025-09-19 05:12:49+00	FACEBOOK	Boonyarat Vineyard	VALORANT	2129	https://drive.google.com/uc?id=1b9t1Ap2NOpK48kGWxHaSRbUQsuXypueK	https://drive.google.com/uc?id=1-9ab5Jw9MkLXtXqNiL4DHrkH1kalDxMG	\N	1	[8750VP] PRELUDE 2.0 เหมาหมด x1	2053.5	75.5	รายการสำเร็จ	แทน	RICHMAN		2025-09-19 17:16:12.77086+00
501	ODR-20250919-1791	2025-09-18 19:19:40+00	FACEBOOK	Mekk Ponthep	7KNIGHT_Re:BIRTH	404	https://drive.google.com/uc?id=1dzRG0WeQGebbwliLnApaia4lVde92w-r	https://drive.google.com/uc?id=1NSNjv9mWGwzxvef-5FS_qc-aGcA4XiAG	\N	2	149BAHT (3.99$) x1, 349BAHT (9.99$) x1	339.71	64.29	รายการสำเร็จ	แทน	ITUNES	13.98*24.30	2025-09-19 17:11:12.920666+00
522	ODR-20250921-5378	2025-09-20 20:25:00+00	FACEBOOK	Mekk Ponthep	7KNIGHT_Re:BIRTH	500			\N	1	729BAHT (19.99$) x1	0	500	รอดำเนินการ	แทน	ITUNES		2025-09-21 14:06:49.94955+00
525	ODR-20250921-4709	2025-09-21 12:40:37+00	FACEBOOK	Nattawat Jantima	VALORANT	250			\N	1	1000VP x1	0	250	รอดำเนินการ	เกรซ	RICHMAN		2025-09-21 14:08:32.25603+00
526	ODR-20250921-6212	2025-09-21 14:21:43+00	FACEBOOK	Nopanan Khamcha	DUNK_DYNASTY	159			\N	1	Party Membership x1	0	159	รอดำเนินการ	เกรซ	RAZERGOLD		2025-09-21 14:25:33.296297+00
527	ODR-20250921-6389	2025-09-21 15:51:54+00	FACEBOOK	Songphon Jantapan	TFT_MOBILE	239			\N	1	1380TFT x1	0	239	รอดำเนินการ	เกรซ	YOUTRIP		2025-09-21 16:20:57.782721+00
528	ODR-20250921-4838	2025-09-21 16:29:26+00	FACEBOOK	Kanmanee Thkl	VALORANT	1889			\N	1	[7875VP] CHAMP2025 เหมาพาส x1	0	1889	รอดำเนินการ	เกรซ	RICHMAN		2025-09-21 16:39:44.1129+00
542	ODR-20250924-9422	2025-09-23 20:21:11+00	FACEBOOK	Mekk Ponthep	7KNIGHT_Re:BIRTH	790			\N	1	1100BAHT (29.99$) x1	0	790	รอดำเนินการ	แทน	ITUNES		2025-09-24 16:54:02.818657+00
529	ODR-20250922-2982	2025-09-21 17:03:52+00	FACEBOOK	วงศธร อังศุธารานุกุล	MARVEL_RIVALS	150			\N	1	500LATT x1	0	150	รอดำเนินการ	แทน	24BUYM		2025-09-22 14:56:54.754058+00
530	ODR-20250922-8054	2025-09-22 03:44:39+00	FACEBOOK	พงศ์ศิริ มาร์ค กิจเถกิง	DELTA_FORCE	2490			\N	1	8100DELTA x1	0	2490	รอดำเนินการ	แทน	RAZERGOLD		2025-09-22 14:58:25.983033+00
531	ODR-20250922-9946	2025-09-22 05:29:09+00	FACEBOOK	Jarusak Jung	LOL_WILDRIFT	189			\N	1	1000WC x1	0	189	รอดำเนินการ	แทน	YOUTRIP		2025-09-22 15:00:15.005284+00
532	ODR-20250922-5035	2025-09-22 05:29:51+00	FACEBOOK	รณกร มาลัยรัตนา	VALORANT	1635			\N	1	[6700VP] CHAMP2025 เหมาหมด x1	0	1635	รอดำเนินการ	แทน	RICHMAN		2025-09-22 15:03:25.994873+00
533	ODR-20250922-5663	2025-09-22 07:59:11+00	FACEBOOK	จักรวาล สาปลั่ง	RACING_MASTER	398			\N	2	159BAHT ($4.99) x1, สัญญาพิเศษ (PREMIUM) x1	0	398	รอดำเนินการ	แทน	RAZERGOLD		2025-09-22 15:08:16.392367+00
534	ODR-20250922-6416	2025-09-22 12:53:36+00	FACEBOOK	จักรวาล สาปลั่ง	RACING_MASTER	398			\N	2	159BAHT ($4.99) x1, สัญญาพิเศษ (PREMIUM) x1	0	398	รอดำเนินการ	เกรซ	RAZERGOLD		2025-09-22 15:09:23.242481+00
535	ODR-20250922-2636	2025-09-22 14:36:32+00	FACEBOOK	จักรวาล สาปลั่ง	RACING_MASTER	779			\N	1	2205GEMS x1	0	779	รอดำเนินการ	เกรซ	RAZERGOLD		2025-09-22 15:10:32.773942+00
538	ODR-20250923-7810	2025-09-22 16:39:41+00	FACEBOOK	Wachirawit Peam	HONKAI_STARRAIL	4840			\N	1	เหมาทุกแพ็ค (ยกเว้นเสบียง) x1	0	4840	รอดำเนินการ	แทน	RICHMAN		2025-09-23 04:42:07.201286+00
537	ODR-20250923-4912	2025-09-22 15:17:53+00	FACEBOOK	Mekk Ponthep	7KNIGHT_Re:BIRTH	780			\N	2	349BAHT (9.99$) x1, 729BAHT (19.99$) x1	0	780	รอดำเนินการ	แทน	ITUNES		2025-09-23 04:40:53.855243+00
539	ODR-20250923-9298	2025-09-23 08:30:53+00	FACEBOOK	แฟ้มไง ไม่ต้องถาม	VALORANT	630			\N	1	2525VP x1	0	630	รอดำเนินการ	แทน	RICHMAN		2025-09-23 15:09:11.76018+00
541	ODR-20250924-7682	2025-09-23 17:27:15+00	FACEBOOK	Kaopun Tangchutaveesub	(ID-PASS) เติมได้หลายเกม	279			\N	1	399 BAHT (9.99$) x1	0	279	รอดำเนินการ	แทน	ITUNES		2025-09-24 16:53:24.066518+00
563	ODR-20250924-7676	2025-09-24 14:25:02+00	FACEBOOK	จักรวาล สาปลั่ง	RACING (LOGIN)	1269	https://drive.google.com/uc?id=1lG68LZHkeeCfsSX7cIDylrMDBaO7uUAA	https://drive.google.com/uc?id=1p_omoods0HqEV5LjZ7TKZhEUVgtunaAf	\N	1	1590BAHT ($46.99) x1	1125.11	143.89	รายการสำเร็จ	เกรซ	RAZERGOLD	42.78*26.30	2025-09-24 17:10:04.853218+00
562	ODR-20250924-2640	2025-09-24 14:05:07+00	FACEBOOK	Nantipark Pinitmontree	RACING (LOGIN)	139	https://drive.google.com/uc?id=1xg63jWInMmpRUiF5BsLdDRt74uCdb8Fj	https://drive.google.com/uc?id=1DFvoDVXaY1plRRJnV1D6QEAVXcqTwKq6	\N	1	159BAHT ($4.99) x1	118.82	20.18	รายการสำเร็จ	เกรซ	RAZERGOLD	4.45*26.70	2025-09-24 17:09:19.360914+00
561	ODR-20250924-5083	2025-09-24 13:11:08+00	FACEBOOK	Chaiyaphon Nuphengrat	DUNK_DYNASTY	2519	https://drive.google.com/uc?id=1HygWIOPhsr3WuYM3n9lxWFlRciYsMIFC	https://drive.google.com/uc?id=1sbZ0lWkLMl86M0dygF_8DReEYuutdo5-	\N	1	8110TOKENS x1	2326.37	192.63	รายการสำเร็จ	เกรซ	RAZERGOLD	87.13*26.70	2025-09-24 17:08:54.178643+00
560	ODR-20250924-5521	2025-09-24 10:59:53+00	FACEBOOK	Boomm Tanawat	LOL_WILDRIFT	339	https://drive.google.com/uc?id=1a7F-_m8eI1TRbUDhtUVmZHfPy255uYop	https://drive.google.com/uc?id=1fArZTWF7QquSfpQEiMQuvXz2HX3pSZQ9	\N	1	1850WC x1	263.64	75.36	รายการสำเร็จ	แทน	YOUTRIP		2025-09-24 17:08:29.845257+00
558	ODR-20250924-7815	2025-09-24 10:53:27+00	FACEBOOK	Aun 'sirikit	DUNK_DYNASTY	169	https://drive.google.com/uc?id=1ormj_8l7eOTUH2helmU_SaHkFWjZYjlC	https://drive.google.com/uc?id=1qnfp4PsUHCrQg-rV50pFUjWyq6i2kdoc	\N	1	Premium Pass x1	139.37	29.63	รายการสำเร็จ	แทน	RAZERGOLD	5.22*26.70	2025-09-24 17:07:31.219975+00
557	ODR-20250924-3184	2025-09-24 10:18:10+00	FACEBOOK	🌺 ONOSAN 小野 🌺	HONKAI_STARRAIL	2290	https://drive.google.com/uc?id=11fsCec0d6UX1D5QDhtp2KIPMZQ4Sms0r	https://drive.google.com/uc?id=19PjULrVrPtxxQlD497JUX8DMNWV4LSVC	\N	1	8080SHARD x1	2150	140	รายการสำเร็จ	แทน	RICHMAN		2025-09-24 17:06:57.984445+00
549	ODR-20250924-4612	2025-09-24 07:37:34+00	FACEBOOK	AchiAchi Boonleab	DUNK_DYNASTY	169	https://drive.google.com/uc?id=1wtpZoO6FuHTf8cTyfMdhmBRQ_JnzW24S	https://drive.google.com/uc?id=1zIwXEA-hGO7-c2IBUFmuYHAPKXzBaJ_m	\N	1	Premium Pass x1	139.37	29.63	รายการสำเร็จ	แทน	RAZERGOLD	5.22*26.70	2025-09-24 17:00:46.236856+00
547	ODR-20250924-7151	2025-09-24 06:20:22+00	FACEBOOK	จักรวาล สาปลั่ง	RACING_MASTER	139	https://drive.google.com/uc?id=174BkoKMT_7mfqGHK2EG8gTfA0DbAKRp7	https://drive.google.com/uc?id=1gytX9mp_XxVt8ng4p-HMdhbEErdZkhnL	\N	1	สัญญาขั้นสูง (DELUXE) x1	118.82	20.18	รายการสำเร็จ	แทน	RAZERGOLD	4.45*26.70	2025-09-24 16:59:46.041653+00
546	ODR-20250924-2466	2025-09-24 05:11:33+00	FACEBOOK	ชลลดา กระพลอย	VALORANT	1635	https://drive.google.com/uc?id=1IhByxib51zBxUECw7CBqbG-gVAwM8qff	https://drive.google.com/uc?id=1_-eMe_z-b8f1q5CyUD3ypKKFo6jmh60U	\N	1	[6700VP] CHAMP2025 เหมาหมด x1	1572.5	62.5	รายการสำเร็จ	แทน	RICHMAN		2025-09-24 16:57:42.256648+00
544	ODR-20250924-7371	2025-09-24 03:02:19+00	FACEBOOK	Wachirawit Peam	HONKAI_STARRAIL	2260	https://drive.google.com/uc?id=1kvEGq-i1-pgeRlh16ANxWYcH0SRA_l-6	https://drive.google.com/uc?id=1Ljxna9KL7az2M6JBo3Ic_KmdqSQNkNzB	\N	1	8080SHARD x1	2159	101	รายการสำเร็จ	แทน	RICHMAN		2025-09-24 16:55:57.86419+00
543	ODR-20250924-3632	2025-09-23 21:44:03+00		Farm Anantasp	MOBILE_LEGENDS	119	https://drive.google.com/uc?id=1IEXm8TeBKK0ZNtMUqAwaKZpy5J16P8eR	https://drive.google.com/uc?id=1EUwmDGkWD-TfGoS4YFUuLqk2fL2h5zKA	\N	1	257 เพชร x1	109	10	รายการสำเร็จ	แทน	RICHMAN		2025-09-24 16:54:58.835047+00
559	ODR-20250924-8717	2025-09-24 10:56:00+00	FACEBOOK	Dagga Roll	DUNK_DYNASTY	169	https://drive.google.com/uc?id=1XJOkUtmtV82eTNjbSmXFBJBPU0iVVv4d	https://drive.google.com/uc?id=10VGyi4VGgrS_2c44-9N7-23CQjwwSuO3	\N	1	Premium Pass x1	139.37	29.63	รายการสำเร็จ	แทน	RAZERGOLD	5.22*26.70	2025-09-24 17:08:09.125485+00
550	ODR-20250924-1579	2025-09-24 08:28:27+00	FACEBOOK	Kanokwan BJ	VALORANT	3764	https://drive.google.com/uc?id=1oduTKwmMeancy2iCAvKBQvj2ZH-e6K1t	https://drive.google.com/uc?id=1SvcJy5hegu8UiZw8fC2H0zw8-pZUILEg	\N	2	[8750VP] PRELUDE 2.0 เหมาหมด x1, [6700VP] CHAMP2025 เหมาหมด x1	3626	138	รายการสำเร็จ	แทน	RICHMAN		2025-09-24 17:01:55.522436+00
548	ODR-20250924-1787	2025-09-24 07:16:56+00	FACEBOOK	Wutthipat Lueangronthong	DUNK_DYNASTY	159	https://drive.google.com/uc?id=1Ke2EOr3g8Am1AWzW6slr-tm7DzFbWKYB	https://drive.google.com/uc?id=1LkKs8G6XRtg7N8UcnOfmImaXh9twYKpM	\N	1	Party Membership x1	128.96	30.04	รายการสำเร็จ	แทน	RAZERGOLD	4.83*26.70	2025-09-24 17:00:13.542707+00
545	ODR-20250924-1814	2025-09-24 03:20:19+00	FACEBOOK	Wachirawit Peam	HONKAI_STARRAIL	2260	https://drive.google.com/uc?id=10iPqz-vH2tcZzmH7DqDdHquBvJAs4Kii	https://drive.google.com/uc?id=1GmgSTLwkVqHF5wB7gp4HJgrsjpTEPTYT	\N	1	8080SHARD x1	2159	101	รายการสำเร็จ	แทน	RICHMAN		2025-09-24 16:57:08.19991+00
\.


--
-- Data for Name: packages; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.packages (id, name, price, product_code, type, channel, game_association, is_active, created_at, sort_order) FROM stdin;
42	74GEMS	29	KU-0023	UID	RAZERGOLD	RACING_MASTER	1	2025-08-14 04:10:42.706787+00	0
43	147GEMS	59	KU-0024	UID	RAZERGOLD	RACING_MASTER	1	2025-08-14 04:11:31.415043+00	1
44	221GEMS	86	KU-0025	UID	RAZERGOLD	RACING_MASTER	1	2025-08-14 04:11:48.555231+00	2
45	368GEMS	139	KU-0026	UID	RAZERGOLD	RACING_MASTER	1	2025-08-14 04:12:43.8105+00	3
46	735GEMS	269	KU-0027	UID	RAZERGOLD	RACING_MASTER	1	2025-08-14 04:14:47.648116+00	4
47	1050GEMS	369	KU-0028	UID	RAZERGOLD	RACING_MASTER	1	2025-08-14 04:15:22.88278+00	5
48	1470GEMS	529	KU-0029	UID	RAZERGOLD	RACING_MASTER	1	2025-08-14 04:15:52.640007+00	6
49	2205GEMS	769	KU-0030	UID	RAZERGOLD	RACING_MASTER	1	2025-08-14 04:16:24.560763+00	7
50	3570GEMS	1239	KU-0031	UID	RAZERGOLD	RACING_MASTER	1	2025-08-14 04:16:46.07835+00	8
51	6930GEMS	2359	KU-0032	UID	RAZERGOLD	RACING_MASTER	1	2025-08-14 04:18:26.328326+00	9
55	สัญญาพิเศษ (PREMIUM)	249	KU-0036	UID	RAZERGOLD	RACING_MASTER	1	2025-08-14 04:20:22.431756+00	13
56	อัพเกรดสัญญา	139	KU-0037	UID	RAZERGOLD	RACING_MASTER	1	2025-08-14 04:20:57.242411+00	14
305	2500BAHT (69.99$)	1780	KU-0000	ID-PASS	ITUNES	7KNIGHT_Re:BIRTH	1	2025-09-21 00:34:11.0492+00	18
52	รายสัปดาห์ (WEEKLY)	29	KU-0033	UID	RAZERGOLD	RACING_MASTER	1	2025-08-14 04:19:10.571732+00	10
53	รายเดือน (MONTHLY)	65	KU-0034	UID	RAZERGOLD	RACING_MASTER	1	2025-08-14 04:19:29.854825+00	11
54	สัญญาขั้นสูง (DELUXE)	139	KU-0035	UID	RAZERGOLD	RACING_MASTER	1	2025-08-14 04:19:57.145186+00	12
57	MPCOMBO	619	KU-0038	UID	RAZERGOLD	RACING_MASTER	1	2025-08-14 04:21:33.996416+00	15
36	1380RP	280	KU-0018	RIOT#	RICHMAN	LOL (บนคอม)	1	2025-08-13 15:56:39.357642+00	1
40	13500RP	2435	KU-0022	RIOT#	RICHMAN	LOL (บนคอม)	1	2025-08-13 15:58:17.095233+00	5
39	6500RP	1205	KU-0021	RIOT#	RICHMAN	LOL (บนคอม)	1	2025-08-13 15:57:52.6756+00	4
38	4500RP	849	KU-0020	RIOT#	RICHMAN	LOL (บนคอม)	1	2025-08-13 15:57:33.759939+00	3
35	575RP	125	KU-0017	RIOT#	RICHMAN	LOL (บนคอม)	1	2025-08-13 14:27:55.151302+00	0
37	2800RP	539	KU-0019	RIOT#	RICHMAN	LOL (บนคอม)	1	2025-08-13 15:57:13.326366+00	2
74	3880TOKENS	1489	KU-0000	UID	RAZERGOLD	DUNK_DYNASTY	1	2025-08-14 05:10:41.355205+00	4
79	Extra Premium Pass	279	KU-0000	UID	RAZERGOLD	DUNK_DYNASTY	1	2025-08-14 05:13:20.570105+00	9
78	Premium Pass	169	KU-0000	UID	RAZERGOLD	DUNK_DYNASTY	1	2025-08-14 05:13:05.460811+00	8
77	Party Permanent VIP	419	KU-0000	UID	RAZERGOLD	DUNK_DYNASTY	1	2025-08-14 05:12:51.50809+00	7
73	2280TOKENS	899	KU-0000	UID	RAZERGOLD	DUNK_DYNASTY	1	2025-08-14 05:10:22.238508+00	3
10	39 BAHT (0.99$)	29	KU-0000	ID-PASS	ITUNES	(ID-PASS) เติมได้หลายเกม	1	2025-08-12 20:15:20.783049+00	0
11	79 BAHT (1.99$)	56	KU-0000	ID-PASS	ITUNES	(ID-PASS) เติมได้หลายเกม	1	2025-08-12 20:15:33.760136+00	1
12	199 BAHT (4.99$)	149	KU-0000	ID-PASS	ITUNES	(ID-PASS) เติมได้หลายเกม	1	2025-08-12 20:15:43.617586+00	3
13	399 BAHT (9.99$)	289	KU-0000	ID-PASS	ITUNES	(ID-PASS) เติมได้หลายเกม	1	2025-08-12 20:16:00.274155+00	5
14	499 BAHT (14.99$)	419	KU-0000	ID-PASS	ITUNES	(ID-PASS) เติมได้หลายเกม	1	2025-08-12 20:16:13.787893+00	6
76	Party Membership	159	KU-0000	UID	RAZERGOLD	DUNK_DYNASTY	1	2025-08-14 05:12:37.244854+00	6
75	8110TOKENS	2519	KU-0000	UID	RAZERGOLD	DUNK_DYNASTY	1	2025-08-14 05:12:08.33604+00	5
15	799 BAHT (19.99$)	549	KU-0000	ID-PASS	ITUNES	(ID-PASS) เติมได้หลายเกม	1	2025-08-12 20:16:34.67315+00	7
16	1100 BAHT (29.99$)	819	KU-0000	ID-PASS	ITUNES	(ID-PASS) เติมได้หลายเกม	1	2025-08-12 20:16:55.826132+00	8
17	1990 BAHT (49.99$)	1329	KU-0000	ID-PASS	ITUNES	(ID-PASS) เติมได้หลายเกม	1	2025-08-12 20:17:12.511119+00	9
18	3990 BAHT (99.99$)	2690	KU-0000	ID-PASS	ITUNES	(ID-PASS) เติมได้หลายเกม	1	2025-08-12 20:17:28.247699+00	10
90	425WC	89	KU-0000	ID-PASS	YOUTRIP	LOL_WILDRIFT	1	2025-08-14 08:06:34.453892+00	5
19	475VP	125	KU-0001	RIOT#	RICHMAN	VALORANT	1	2025-08-13 14:12:08.956828+00	8
20	1000VP	250	KU-0002	RIOT#	RICHMAN	VALORANT	1	2025-08-13 14:12:28.988413+00	9
21	1475VP	375	KU-0003	RIOT#	RICHMAN	VALORANT	1	2025-08-13 14:13:06.438125+00	10
22	2050VP	505	KU-0004	RIOT#	RICHMAN	VALORANT	1	2025-08-13 14:13:40.230912+00	11
23	2525VP	630	KU-0005	RIOT#	RICHMAN	VALORANT	1	2025-08-13 14:14:25.705905+00	12
26	3050VP	750	KU-0006	RIOT#	RICHMAN	VALORANT	1	2025-08-13 14:18:41.218513+00	13
25	3650VP	885	KU-0007	RIOT#	RICHMAN	VALORANT	1	2025-08-13 14:17:38.23939+00	14
24	4650VP	1135	KU-0008	RIOT#	RICHMAN	VALORANT	1	2025-08-13 14:15:38.552787+00	15
27	5350VP	1269	KU-0009	RIOT#	RICHMAN	VALORANT	1	2025-08-13 14:19:26.655233+00	16
28	5825VP	1390	KU-0010	RIOT#	RICHMAN	VALORANT	1	2025-08-13 14:19:55.457214+00	17
29	6350VP	1515	KU-0011	RIOT#	RICHMAN	VALORANT	1	2025-08-13 14:20:25.000054+00	18
30	6825VP	1640	KU-0012	RIOT#	RICHMAN	VALORANT	1	2025-08-13 14:20:48.154123+00	19
31	7400VP	1770	KU-0013	RIOT#	RICHMAN	VALORANT	1	2025-08-13 14:21:33.435319+00	20
32	8400VP	2020	KU-0014	RIOT#	RICHMAN	VALORANT	1	2025-08-13 14:22:03.043727+00	21
33	9000VP	2150	KU-0015	RIOT#	RICHMAN	VALORANT	1	2025-08-13 14:22:22.869122+00	22
58	กองทุนพัฒนา (GROWTH)	169	KU-0039	UID	RAZERGOLD	RACING_MASTER	1	2025-08-14 04:21:59.690895+00	16
59	แพ็คแฟชั่น (VALUE)	29	KU-0040	UID	RAZERGOLD	RACING_MASTER	1	2025-08-14 04:22:16.910232+00	17
60	EXPO (10)	269	KU-0041	UID	RAZERGOLD	RACING_MASTER	1	2025-08-14 04:22:40.602728+00	18
61	EXPO (15)	369	KU-0042	UID	RAZERGOLD	RACING_MASTER	1	2025-08-14 04:22:54.268005+00	19
62	EXPO (100)	2359	KU-0043	UID	RAZERGOLD	RACING_MASTER	1	2025-08-14 04:23:12.075848+00	20
108	640 เหรียญ	69	KU-0000	ID-PASS	YOUTRIP	MINECRAFT	0	2025-08-14 08:16:51.73081+00	1
70	60TOKENS	29	KU-0000	UID	RAZERGOLD	DUNK_DYNASTY	1	2025-08-14 05:09:15.303339+00	0
121	33 เพชร	12	KU-0000	UID	24BUYM	FREEFIRE	1	2025-08-14 11:43:44.214446+00	0
123	68 เพชร	24	KU-0000	UID	24BUYM	FREEFIRE	1	2025-08-14 11:45:50.129423+00	1
92	1425WC	278	KU-0000	ID-PASS	YOUTRIP	LOL_WILDRIFT	1	2025-08-14 08:07:01.11333+00	7
124	172 เพชร	49	KU-0000	UID	24BUYM	FREEFIRE	1	2025-08-14 11:46:43.596373+00	2
107	320 เหรียญ	35	KU-0000	ID-PASS	YOUTRIP	MINECRAFT	0	2025-08-14 08:16:24.369691+00	0
109	960 เหรียญ	105	KU-0000	ID-PASS	YOUTRIP	MINECRAFT	0	2025-08-14 08:17:08.447325+00	2
111	1600 เหรียญ	169	KU-0000	ID-PASS	YOUTRIP	MINECRAFT	0	2025-08-14 08:17:47.0918+00	4
93	1850WC	339	KU-0000	ID-PASS	YOUTRIP	LOL_WILDRIFT	1	2025-08-14 08:07:15.056262+00	8
125	310 เพชร	89	KU-0000	UID	24BUYM	FREEFIRE	1	2025-08-14 11:46:58.77897+00	3
126	517 เพชร	149	KU-0000	UID	24BUYM	FREEFIRE	1	2025-08-14 11:47:42.05861+00	4
113	3500 เหรียญ	209	KU-0000	ID-PASS	YOUTRIP	MINECRAFT	0	2025-08-14 08:18:30.338021+00	6
127	690 เพชร	199	KU-0000	UID	24BUYM	FREEFIRE	1	2025-08-14 11:48:27.360281+00	5
110	1280 เหรียญ	129	KU-0000	ID-PASS	YOUTRIP	MINECRAFT	0	2025-08-14 08:17:26.42003+00	3
112	1920 เหรียญ	199	KU-0000	ID-PASS	YOUTRIP	MINECRAFT	0	2025-08-14 08:18:07.268038+00	5
128	1052 เพชร	295	KU-0000	UID	24BUYM	FREEFIRE	1	2025-08-14 11:48:59.182789+00	6
129	1801 เพชร	489	KU-0000	UID	24BUYM	FREEFIRE	1	2025-08-14 11:49:32.946445+00	7
130	3698 เพชร	975	KU-0000	UID	24BUYM	FREEFIRE	1	2025-08-14 11:50:07.017727+00	8
83	199BAHT (4.99$)	139	KU-0000	ID-PASS	ITUNES	DUNK_DYNASTY	1	2025-08-14 05:22:39.878585+00	13
131	5499 เพชร	1479	KU-0000	UID	24BUYM	FREEFIRE	1	2025-08-14 11:50:27.74866+00	9
132	6551 เพชร	1759	KU-0000	UID	24BUYM	FREEFIRE	1	2025-08-14 11:50:54.134426+00	10
72	1110TOKENS	419	KU-0000	UID	RAZERGOLD	DUNK_DYNASTY	1	2025-08-14 05:10:01.412704+00	2
71	330TOKENS	159	KU-0000	UID	RAZERGOLD	DUNK_DYNASTY	1	2025-08-14 05:09:40.941321+00	1
85	499BAHT (14.99$)	429	KU-0000	ID-PASS	ITUNES	DUNK_DYNASTY	1	2025-08-14 05:23:18.505017+00	15
91	1000WC	189	KU-0000	ID-PASS	YOUTRIP	LOL_WILDRIFT	1	2025-08-14 08:06:47.666549+00	6
94	2275WC	428	KU-0000	ID-PASS	YOUTRIP	LOL_WILDRIFT	1	2025-08-14 08:07:30.581188+00	9
84	399BAHT (9.99$)	289	KU-0000	ID-PASS	ITUNES	DUNK_DYNASTY	1	2025-08-14 05:22:58.971565+00	14
63	159BAHT ($4.99)	139	KU-0000	QRCODE	RAZERGOLD	RACING (LOGIN)	1	2025-08-14 04:28:20.027774+00	1
95	3275WC	569	KU-0000	ID-PASS	YOUTRIP	LOL_WILDRIFT	1	2025-08-14 08:07:43.892011+00	10
96	4800WC	800	KU-0000	ID-PASS	YOUTRIP	LOL_WILDRIFT	1	2025-08-14 08:08:04.575559+00	11
97	5225WC	889	KU-0000	ID-PASS	YOUTRIP	LOL_WILDRIFT	1	2025-08-14 08:08:51.502934+00	12
98	6650WC	1119	KU-0000	ID-PASS	YOUTRIP	LOL_WILDRIFT	1	2025-08-14 08:09:38.939106+00	13
99	8075WC	1349	KU-0000	ID-PASS	YOUTRIP	LOL_WILDRIFT	1	2025-08-14 08:10:16.798042+00	14
100	10000WC	1590	KU-0000	ID-PASS	YOUTRIP	LOL_WILDRIFT	1	2025-08-14 08:11:00.253439+00	15
101	14800WC	2390	KU-0000	ID-PASS	YOUTRIP	LOL_WILDRIFT	1	2025-08-14 08:11:22.96318+00	16
102	20000WC	3139	KU-0000	ID-PASS	YOUTRIP	LOL_WILDRIFT	1	2025-08-14 08:12:01.870166+00	17
103	30000WC	4739	KU-0000	ID-PASS	YOUTRIP	LOL_WILDRIFT	1	2025-08-14 08:12:29.2566+00	18
104	50000WC	7859	KU-0000	ID-PASS	YOUTRIP	LOL_WILDRIFT	1	2025-08-14 08:12:51.130812+00	19
105	STELLACORN	89	KU-0000	ID-PASS	YOUTRIP	LOL_WILDRIFT	1	2025-08-14 08:13:29.448844+00	20
141	24 ปอง	24	KU-0000	OPEN/ID	RICHMAN	ROV_MOBILE	1	2025-08-14 11:57:32.52653+00	1
142	60 ปอง	49	KU-0000	OPEN/ID	RICHMAN	ROV_MOBILE	1	2025-08-14 11:57:46.824635+00	2
143	72 ปอง	62	KU-0000	OPEN/ID	RICHMAN	ROV_MOBILE	1	2025-08-14 11:57:59.62032+00	3
144	84 ปอง	75	KU-0000	OPEN/ID	RICHMAN	ROV_MOBILE	1	2025-08-14 11:58:12.276094+00	4
146	110 ปอง	89	KU-0000	OPEN/ID	RICHMAN	ROV_MOBILE	1	2025-08-14 15:28:31.6112+00	5
147	121 ปอง	102	KU-0000	OPEN/ID	RICHMAN	ROV_MOBILE	1	2025-08-14 15:28:52.440882+00	6
148	134 ปอง	114	KU-0000	OPEN/ID	RICHMAN	ROV_MOBILE	1	2025-08-14 15:29:38.298547+00	7
149	170 ปอง	139	KU-0000	OPEN/ID	RICHMAN	ROV_MOBILE	1	2025-08-14 15:29:57.504824+00	8
150	185 ปอง	149	KU-0000	OPEN/ID	RICHMAN	ROV_MOBILE	1	2025-08-14 15:30:12.672916+00	9
151	370 ปอง	296	KU-0000	OPEN/ID	RICHMAN	ROV_MOBILE	1	2025-08-14 15:30:27.170567+00	10
152	620 ปอง	489	KU-0000	OPEN/ID	RICHMAN	ROV_MOBILE	1	2025-08-14 15:30:43.241062+00	11
153	1240 ปอง	975	KU-0000	OPEN/ID	RICHMAN	ROV_MOBILE	1	2025-08-14 15:32:01.792758+00	12
154	1860 ปอง	1469	KU-0000	OPEN/ID	RICHMAN	ROV_MOBILE	1	2025-08-14 15:32:20.616212+00	13
155	2480 ปอง	1950	KU-0000	OPEN/ID	RICHMAN	ROV_MOBILE	1	2025-08-14 15:32:56.194133+00	14
156	3100 ปอง	2439	KU-0000	OPEN/ID	RICHMAN	ROV_MOBILE	1	2025-08-14 15:33:15.427783+00	15
157	3720 ปอง	2925	KU-0000	OPEN/ID	RICHMAN	ROV_MOBILE	1	2025-08-14 15:33:47.458798+00	16
158	4340 ปอง	3419	KU-0000	OPEN/ID	RICHMAN	ROV_MOBILE	1	2025-08-14 15:34:09.45325+00	17
159	5580 ปอง	4389	KU-0000	OPEN/ID	RICHMAN	ROV_MOBILE	1	2025-08-14 15:34:37.302691+00	18
160	6820 ปอง	5369	KU-0000	OPEN/ID	RICHMAN	ROV_MOBILE	1	2025-08-14 15:34:59.718889+00	19
133	7396 เพชร	1959	KU-0000	UID	24BUYM	FREEFIRE	1	2025-08-14 11:51:13.776711+00	11
134	9197 เพชร	2439	KU-0000	UID	24BUYM	FREEFIRE	1	2025-08-14 11:51:44.779056+00	12
135	11094 เพชร	2925	KU-0000	UID	24BUYM	FREEFIRE	1	2025-08-14 11:52:07.135247+00	13
136	12895 เพชร	3419	KU-0000	UID	24BUYM	FREEFIRE	1	2025-08-14 11:52:51.72134+00	14
137	14792 เพชร	3900	KU-0000	UID	24BUYM	FREEFIRE	1	2025-08-14 11:53:19.897831+00	15
138	(FF) รายสัปดาห์	67	KU-0000	UID	24BUYM	FREEFIRE	1	2025-08-14 11:54:51.600201+00	16
139	(FF) รายเดือน	295	KU-0000	UID	24BUYM	FREEFIRE	1	2025-08-14 11:55:13.674403+00	17
145	(FF) BP Card	89	KU-0000	UID	24BUYM	FREEFIRE	1	2025-08-14 11:59:02.276061+00	18
67	999BAHT ($29.49)	789	KU-0000	QRCODE	RAZERGOLD	RACING (LOGIN)	1	2025-08-14 05:04:23.233812+00	5
190	1090SHARD	389	KU-0000	UID	RICHMAN	HONKAI_STARRAIL	1	2025-08-16 06:01:53.571323+00	3
161	86 เพชร	45	KU-0000	UID	RICHMAN	MOBILE_LEGENDS	1	2025-08-14 15:36:28.418841+00	0
162	172 เพชร	79	KU-0000	UID	RICHMAN	MOBILE_LEGENDS	1	2025-08-14 15:36:54.711198+00	1
163	257 เพชร	119	KU-0000	UID	RICHMAN	MOBILE_LEGENDS	1	2025-08-14 15:37:06.966863+00	2
164	706 เพชร	309	KU-0000	UID	RICHMAN	MOBILE_LEGENDS	1	2025-08-14 15:37:23.51626+00	3
165	2195 เพชร	929	KU-0000	UID	RICHMAN	MOBILE_LEGENDS	1	2025-08-14 15:37:37.285082+00	4
166	3688 เพชร	1549	KU-0000	UID	RICHMAN	MOBILE_LEGENDS	1	2025-08-14 15:37:51.052079+00	5
167	5532 เพชร	2299	KU-0000	UID	RICHMAN	MOBILE_LEGENDS	1	2025-08-14 15:38:05.678098+00	6
168	9288 เพชร	3799	KU-0000	UID	RICHMAN	MOBILE_LEGENDS	1	2025-08-14 15:38:27.93899+00	7
169	(MBL) Twilight Pass	259	KU-0000	UID	RICHMAN	MOBILE_LEGENDS	1	2025-08-14 15:39:02.824248+00	8
170	(MBL) One-Time	55	KU-0000	UID	RICHMAN	MOBILE_LEGENDS	1	2025-08-14 15:39:33.985719+00	9
69	3090BAHT ($90.99)	2419	KU-0000	QRCODE	RAZERGOLD	RACING (LOGIN)	1	2025-08-14 05:05:07.912674+00	7
172	(ECU) 2690BAHT	2139	KU-0000	QRCODE	RAZERGOLD	RACING (LOGIN)	1	2025-08-14 20:38:25.028675+00	0
66	669BAHT ($19.99)	539	KU-0000	QRCODE	RAZERGOLD	RACING (LOGIN)	1	2025-08-14 05:04:04.555955+00	4
191	2240SHARD	759	KU-0000	UID	RICHMAN	HONKAI_STARRAIL	1	2025-08-16 06:02:08.550152+00	4
68	1590BAHT ($46.99)	1269	KU-0000	QRCODE	RAZERGOLD	RACING (LOGIN)	1	2025-08-14 05:04:42.656015+00	6
65	479BAHT ($14.49)	379	KU-0000	QRCODE	RAZERGOLD	RACING (LOGIN)	1	2025-08-14 05:03:46.996526+00	3
140	11 ปอง	12	KU-0000	OPEN/ID	RICHMAN	ROV_MOBILE	1	2025-08-14 11:57:05.490811+00	0
64	329BAHT ($9.99)	275	KU-0000	QRCODE	RAZERGOLD	RACING (LOGIN)	1	2025-08-14 04:29:28.560373+00	2
192	3880SHARD	1235	KU-0000	UID	RICHMAN	HONKAI_STARRAIL	1	2025-08-16 06:02:22.241397+00	5
188	60SHARD	33	KU-0000	UID	RICHMAN	HONKAI_STARRAIL	1	2025-08-16 06:01:21.306326+00	1
181	60UC	33	KU-0000	UID	RAZERGOLD	PUBG_MOBILE	1	2025-08-15 23:58:51.783497+00	0
177	6500TFT	1039	KU-0000	ID-PASS	YOUTRIP	TFT_MOBILE	1	2025-08-15 09:00:03.988976+00	4
189	330SHARD	139	KU-0000	UID	RICHMAN	HONKAI_STARRAIL	1	2025-08-16 06:01:40.134714+00	2
193	8080SHARD	2290	KU-0000	UID	RICHMAN	HONKAI_STARRAIL	1	2025-08-16 06:02:36.380317+00	6
175	2800TFT	439	KU-0000	ID-PASS	YOUTRIP	TFT_MOBILE	1	2025-08-15 08:59:17.911459+00	2
174	1380TFT	239	KU-0000	ID-PASS	YOUTRIP	TFT_MOBILE	1	2025-08-15 08:59:00.08022+00	1
178	13500TFT	2049	KU-0000	ID-PASS	YOUTRIP	TFT_MOBILE	1	2025-08-15 09:00:19.74626+00	5
182	325UC	149	KU-0000	UID	RAZERGOLD	PUBG_MOBILE	1	2025-08-15 23:59:05.53303+00	1
183	660UC	319	KU-0000	UID	RAZERGOLD	PUBG_MOBILE	1	2025-08-15 23:59:40.715385+00	2
184	1800UC	749	KU-0000	UID	RAZERGOLD	PUBG_MOBILE	1	2025-08-15 23:59:57.645059+00	3
186	3850UC	1489	KU-0000	UID	RAZERGOLD	PUBG_MOBILE	1	2025-08-16 00:13:53.283849+00	5
187	8100UC	2899	KU-0000	UID	RAZERGOLD	PUBG_MOBILE	1	2025-08-16 00:14:09.673696+00	6
180	40500TFT	6099	KU-0000	ID-PASS	YOUTRIP	TFT_MOBILE	1	2025-08-15 09:00:58.52749+00	7
173	575TFT	119	KU-0000	ID-PASS	YOUTRIP	TFT_MOBILE	1	2025-08-15 08:58:47.260846+00	0
179	27000TFT	4059	KU-0000	ID-PASS	YOUTRIP	TFT_MOBILE	1	2025-08-15 09:00:41.981395+00	6
176	4500TFT	749	KU-0000	ID-PASS	YOUTRIP	TFT_MOBILE	1	2025-08-15 08:59:38.729021+00	3
207	1245TOKENS	469	KU-0000	UID	RICHMAN	HOK (GLOBAL)	1	2025-08-16 07:36:29.901741+00	5
197	บัตรกำนัลเสบียงรถไฟ (2x)	278	KU-0000	UID	RICHMAN	HONKAI_STARRAIL	1	2025-08-16 06:03:56.254788+00	10
209	4180TOKENS	1439	KU-0000	UID	RICHMAN	HOK (GLOBAL)	1	2025-08-16 07:36:58.045606+00	7
205	560TOKENS	239	KU-0000	UID	RICHMAN	HOK (GLOBAL)	1	2025-08-16 07:36:02.31023+00	3
236	11600LATT	2759	KU-0000	UID	24BUYM	MARVEL_RIVALS	1	2025-08-18 16:39:24.872133+00	7
198	บัตรกำนัลเสบียงรถไฟ (3x)	415	KU-0000	UID	RICHMAN	HONKAI_STARRAIL	1	2025-08-16 06:04:09.897317+00	11
194	8080SHARD (2x)	4689	KU-0000	UID	RICHMAN	HONKAI_STARRAIL	1	2025-08-16 06:03:10.338776+00	7
210	8360TOKENS	2790	KU-0000	UID	RICHMAN	HOK (GLOBAL)	1	2025-08-16 07:37:11.909194+00	8
196	บัตรกำนัลเสบียงรถไฟ	139	KU-0000	UID	RICHMAN	HONKAI_STARRAIL	1	2025-08-16 06:03:41.657115+00	9
206	830TOKENS	319	KU-0000	UID	RICHMAN	HOK (GLOBAL)	1	2025-08-16 07:36:14.824682+00	4
202	80TOKENS	36	KU-0000	UID	RICHMAN	HOK (GLOBAL)	1	2025-08-16 07:35:19.265961+00	0
208	2508TOKENS	889	KU-0000	UID	RICHMAN	HOK (GLOBAL)	1	2025-08-16 07:36:44.30227+00	6
204	400TOKENS	159	KU-0000	UID	RICHMAN	HOK (GLOBAL)	1	2025-08-16 07:35:49.077646+00	2
195	เหมาทุกแพ็ค (ยกเว้นเสบียง)	4840	KU-0000	UID	RICHMAN	HONKAI_STARRAIL	1	2025-08-16 06:03:25.690167+00	8
34	11000VP	2535	KU-0016	RIOT#	RICHMAN	VALORANT	1	2025-08-13 14:24:05.057822+00	23
213	30DELTA	19	KU-0000	UID	RAZERGOLD	DELTA_FORCE	1	2025-08-17 00:48:32.493823+00	2
214	60DELTA	34	KU-0000	UID	RAZERGOLD	DELTA_FORCE	1	2025-08-17 00:48:43.155659+00	3
215	320DELTA	139	KU-0000	UID	RAZERGOLD	DELTA_FORCE	1	2025-08-17 00:48:55.806182+00	4
216	750DELTA	269	KU-0000	UID	RAZERGOLD	DELTA_FORCE	1	2025-08-17 00:49:09.543429+00	5
217	1480DELTA	519	KU-0000	UID	RAZERGOLD	DELTA_FORCE	1	2025-08-17 00:49:24.163525+00	6
218	1980DELTA	649	KU-0000	UID	RAZERGOLD	DELTA_FORCE	1	2025-08-17 00:49:37.913426+00	7
219	3950DELTA	1279	KU-0000	UID	RAZERGOLD	DELTA_FORCE	1	2025-08-17 00:49:53.586084+00	8
220	8100DELTA	2490	KU-0000	UID	RAZERGOLD	DELTA_FORCE	1	2025-08-17 00:50:08.451311+00	9
229	100LATT	30	KU-0000	UID	24BUYM	MARVEL_RIVALS	1	2025-08-18 16:35:26.57624+00	0
230	500LATT	150	KU-0000	UID	24BUYM	MARVEL_RIVALS	1	2025-08-18 16:35:51.203629+00	1
231	1000LATT	283	KU-0000	UID	24BUYM	MARVEL_RIVALS	1	2025-08-18 16:36:11.321984+00	2
232	1600LATT	453	KU-0000	UID	24BUYM	MARVEL_RIVALS	1	2025-08-18 16:36:52.592139+00	3
233	2180LATT	575	KU-0000	UID	24BUYM	MARVEL_RIVALS	1	2025-08-18 16:37:21.325307+00	4
82	29BAHT (0.99$)	29	KU-0000	ID-PASS	ITUNES	DUNK_DYNASTY	1	2025-08-14 05:21:51.619636+00	12
87	999BAHT (29.99$)	829	KU-0000	ID-PASS	ITUNES	DUNK_DYNASTY	1	2025-08-14 05:24:10.641997+00	17
86	699BAHT (19.99$)	559	KU-0000	ID-PASS	ITUNES	DUNK_DYNASTY	1	2025-08-14 05:23:56.235173+00	16
81	เหมาหมด (ยกเว้น Premium Pass)	919	KU-0000	UID	RAZERGOLD	DUNK_DYNASTY	1	2025-08-14 05:14:02.95257+00	11
88	1990BAHT (49.99$)	1390	KU-0000	ID-PASS	ITUNES	DUNK_DYNASTY	1	2025-08-14 05:24:29.738256+00	18
80	Rookie Pack	99	KU-0000	UID	RAZERGOLD	DUNK_DYNASTY	1	2025-08-14 05:13:46.472577+00	10
89	3990BAHT (99.99$)	2729	KU-0000	ID-PASS	ITUNES	DUNK_DYNASTY	1	2025-08-14 05:24:44.390533+00	19
203	240TOKENS	99	KU-0000	UID	RICHMAN	HOK (GLOBAL)	1	2025-08-16 07:35:33.700003+00	1
234	2680LATT	735	KU-0000	UID	24BUYM	MARVEL_RIVALS	1	2025-08-18 16:38:12.927057+00	5
227	10000 ROBUX	2899	KU-0000	ID-PASS	ITUNES	ROBLOX	1	2025-08-17 00:55:21.377378+00	6
235	5680LATT	1399	KU-0000	UID	24BUYM	MARVEL_RIVALS	1	2025-08-18 16:39:04.572522+00	6
221	40 ROBUX	19	KU-0000	ID-PASS	ITUNES	ROBLOX	1	2025-08-17 00:54:01.439522+00	0
224	800 ROBUX	299	KU-0000	ID-PASS	ITUNES	ROBLOX	1	2025-08-17 00:54:42.976628+00	3
223	400 ROBUX	149	KU-0000	ID-PASS	ITUNES	ROBLOX	1	2025-08-17 00:54:30.682351+00	2
226	4500 ROBUX	1499	KU-0000	ID-PASS	ITUNES	ROBLOX	1	2025-08-17 00:55:07.744749+00	5
239	แบทเทิลพาส (select) 	180	KU-0000	UID	RAZERGOLD	DELTA_FORCE	1	2025-08-22 00:38:23.68585+00	0
238	แบทเทิลพาส (all)	239	KU-0000	UID	RAZERGOLD	DELTA_FORCE	1	2025-08-22 00:37:14.643471+00	1
237	69 โอปอล	33	KU-000	UID	RAZERGOLD	COA	1	2025-08-21 04:45:02.326445+00	2
244	360 โอปอล	149	KU-000	UID	RAZERGOLD	COA	1	2025-08-24 01:20:27.747817+00	3
245	1209 โอปอล	459	KU-000	UID	RAZERGOLD	COA	1	2025-08-24 01:20:46.498616+00	4
225	1700 ROBUX	599	KU-0000	ID-PASS	ITUNES	ROBLOX	1	2025-08-17 00:54:56.502738+00	4
228	22500 ROBUX	5890	KU-0000	ID-PASS	ITUNES	ROBLOX	1	2025-08-17 00:55:32.290113+00	7
222	80 ROBUX	32	KU-0000	ID-PASS	ITUNES	ROBLOX	1	2025-08-17 00:54:17.708412+00	1
246	2479 โอปอล	869	KU-000	UID	RAZERGOLD	COA	1	2025-08-24 01:21:04.096871+00	5
247	4245 โอปอล	1429	KU-000	UID	RAZERGOLD	COA	1	2025-08-24 01:21:46.391383+00	6
248	8606 โอปอล	2829	KU-000	UID	RAZERGOLD	COA	1	2025-08-24 01:22:02.723649+00	7
256	20800 บัตรกำนัล	8490	KU-000	UID	RAZERGOLD	COA	1	2025-08-24 01:24:31.995059+00	15
259	680+70 Jewels	335	KU-000	UID	RAZERGOLD	HARRY_AWAKENED	1	2025-08-28 04:53:03.051733+00	0
266	8080 Monochrome	2349	KU-0000	UID	RICHMAN	ZENLESS_ZONE	1	2025-08-29 15:40:34.917733+00	5
274	[3050VP] CHAMP2025 ปืนแยก	750	KU-0000	RIOT#	RICHMAN	VALORANT	1	2025-09-05 14:20:55.240809+00	7
291	149BAHT (3.99$)	119	KU-0000	ID-PASS	ITUNES	7KNIGHT_Re:BIRTH	1	2025-09-18 16:14:29.450162+00	8
267	INTER-KNOT (รายเดือน)	139	KU-0000	UID	RICHMAN	ZENLESS_ZONE	1	2025-08-29 15:40:50.418058+00	6
260	3400BAHT ($99.99)	2419	KU-0000	QRCODE	RAZERGOLD	RACING (LOGIN)	1	2025-08-29 10:58:40.900658+00	8
284	109 PRISM	269	KU-0000	UID	RAZERGOLD	7KNIGHT_Re:BIRTH	1	2025-09-18 16:09:39.812926+00	1
293	249BAHT (6.99$)	185	KU-0000	ID-PASS	ITUNES	7KNIGHT_Re:BIRTH	1	2025-09-18 16:51:59.144486+00	10
269	300 Jewels	159	KU-0000	UID	RAZERGOLD	HARRY_AWAKENED	1	2025-09-03 08:59:43.113585+00	0
286	409 PRISM	949	KU-0000	UID	RAZERGOLD	7KNIGHT_Re:BIRTH	1	2025-09-18 16:10:25.487097+00	3
288	990 PRISM	2090	KU-0000	UID	RAZERGOLD	7KNIGHT_Re:BIRTH	1	2025-09-18 16:11:06.26737+00	5
268	299 BAHT (7.99$)	239	KU-0000	ID-PASS	ITUNES	(ID-PASS) เติมได้หลายเกม	1	2025-09-02 18:30:01.13992+00	4
271	149 BAHT (3.99$)	119	KU-0000	ID-PASS	ITUNES	(ID-PASS) เติมได้หลายเกม	1	2025-09-05 10:47:35.779191+00	2
277	(SUMMER) SERAPHINE 2275WC	425	KU-0000	ID-PASS	YOUTRIP	LOL_WILDRIFT	1	2025-09-13 03:59:01.812535+00	0
278	(SUMMER) YASUO 1425WC	275	KU-0000	ID-PASS	YOUTRIP	LOL_WILDRIFT	1	2025-09-13 04:00:09.220312+00	1
257	Phantasium Pass (15 วัน)	85	KU-0000	UID	RAZERGOLD	COA	1	2025-08-24 01:25:05.440309+00	0
258	Phantasium Pass (30 วัน)	149	KU-0000	UID	RAZERGOLD	COA	1	2025-08-24 01:25:20.432635+00	1
249	26300 โอปอล	8490	KU-000	UID	RAZERGOLD	COA	1	2025-08-24 01:22:22.839225+00	8
250	63 บัตรกำนัล	33	KU-000	UID	RAZERGOLD	COA	1	2025-08-24 01:22:54.015779+00	9
251	315 บัตรกำนัล	149	KU-000	UID	RAZERGOLD	COA	1	2025-08-24 01:23:13.707296+00	10
252	1029 บัตรกำนัล	459	KU-000	UID	RAZERGOLD	COA	1	2025-08-24 01:23:26.716154+00	11
253	2079 บัตรกำนัล	869	KU-000	UID	RAZERGOLD	COA	1	2025-08-24 01:23:41.54823+00	12
254	3445 บัตรกำนัล	1429	KU-000	UID	RAZERGOLD	COA	1	2025-08-24 01:23:56.570875+00	13
255	6806 บัตรกำนัล	2829	KU-000	UID	RAZERGOLD	COA	1	2025-08-24 01:24:15.229974+00	14
279	(SUMMER) AURORA 1425WC	275	KU-0000	ID-PASS	YOUTRIP	LOL_WILDRIFT	1	2025-09-13 04:00:42.738427+00	2
280	(SUMMER) SAMIRA 1425WC	275	KU-0000	ID-PASS	YOUTRIP	LOL_WILDRIFT	1	2025-09-13 04:01:04.878723+00	3
281	(SUMMER) KATARINA 1425WC	275	KU-0000	ID-PASS	YOUTRIP	LOL_WILDRIFT	1	2025-09-13 04:01:26.624693+00	4
261	60 Monochrome	31	KU-0000	UID	RICHMAN	ZENLESS_ZONE	1	2025-08-29 15:39:31.396408+00	0
262	330 Monochrome	129	KU-0000	UID	RICHMAN	ZENLESS_ZONE	1	2025-08-29 15:39:45.363362+00	1
263	1090 Monochrome	389	KU-0000	UID	RICHMAN	ZENLESS_ZONE	1	2025-08-29 15:39:56.214749+00	2
264	2240 Monochrome	749	KU-0000	UID	RICHMAN	ZENLESS_ZONE	1	2025-08-29 15:40:11.37101+00	3
265	3880 Monochrome	1219	KU-0000	UID	RICHMAN	ZENLESS_ZONE	1	2025-08-29 15:40:22.798448+00	4
106	CELESTIAL	569	KU-0000	ID-PASS	YOUTRIP	LOL_WILDRIFT	1	2025-08-14 08:13:51.883908+00	21
282	พรแห่งดวงจันทร์	139	KU-0000	UID	RICHMAN	GENSHIN_IMPACT	1	2025-09-14 19:25:06.688404+00	0
200	บัตรกำนัลเสบียงรถไฟ (5x)	695	KU-0000	UID	RICHMAN	HONKAI_STARRAIL	1	2025-08-16 06:04:37.00444+00	13
275	BP กิตติคุณ 9.99$	310	KU-0000	ID-PASS	ITUNES	HONKAI_STARRAIL	1	2025-09-06 20:03:57.672977+00	0
270	[7875VP] CHAMP2025 เหมาพาส	1889	KU-0000	RIOT#	RICHMAN	VALORANT	1	2025-09-05 08:58:57.440323+00	4
272	[6700VP] CHAMP2025 เหมาหมด	1635	KU-0000	RIOT#	RICHMAN	VALORANT	1	2025-09-05 14:19:01.435883+00	5
289	35BAHT (0.99$)	28	KU-0000	ID-PASS	ITUNES	7KNIGHT_Re:BIRTH	1	2025-09-18 16:12:45.278193+00	6
273	[5350VP] CHAMP2025 มีดแยก	1265	KU-0000	RIOT#	RICHMAN	VALORANT	1	2025-09-05 14:20:19.62974+00	6
285	273 PRISM	629	KU-0000	UID	RAZERGOLD	7KNIGHT_Re:BIRTH	1	2025-09-18 16:10:06.817999+00	2
294	349BAHT (9.99$)	275	KU-0000	ID-PASS	ITUNES	7KNIGHT_Re:BIRTH	1	2025-09-18 16:52:37.603725+00	11
295	729BAHT (19.99$)	515	KU-0000	ID-PASS	ITUNES	7KNIGHT_Re:BIRTH	1	2025-09-18 16:53:19.351629+00	13
287	708 PRISM	1529	KU-0000	UID	RAZERGOLD	7KNIGHT_Re:BIRTH	1	2025-09-18 16:10:46.361529+00	4
283	27 PRISM	59	KU-0000	UID	RAZERGOLD	7KNIGHT_Re:BIRTH	1	2025-09-18 16:09:13.991416+00	0
292	179BAHT (4.99$)	135	KU-0000	ID-PASS	ITUNES	7KNIGHT_Re:BIRTH	1	2025-09-18 16:51:14.741199+00	9
290	69BAHT (1.99$)	55	KU-0000	ID-PASS	ITUNES	7KNIGHT_Re:BIRTH	1	2025-09-18 16:13:40.526773+00	7
276	BP เหรียญตรา 19.99$	620	KU-0000	ID-PASS	ITUNES	HONKAI_STARRAIL	1	2025-09-06 20:04:26.616373+00	0
201	บัตรกำนัลเสบียงรถไฟ (10x)	1390	KU-0000	UID	RICHMAN	HONKAI_STARRAIL	1	2025-08-16 06:05:17.576453+00	14
199	บัตรกำนัลเสบียงรถไฟ (4x)	549	KU-0000	UID	RICHMAN	HONKAI_STARRAIL	1	2025-08-16 06:04:23.010353+00	12
298	[8750VP] PRELUDE 2.0 เหมาหมด	2129	KU-0000	RIOT#	RICHMAN	VALORANT	1	2025-09-19 02:48:06.214063+00	0
299	[9800VP] PRELUDE 2.0 เหมาพาส	2385	KU-0000	RIOT#	RICHMAN	VALORANT	1	2025-09-19 02:48:46.656516+00	1
300	[4650VP] PRELUDE 2.0 มีดแยก	1135	KU-0000	RIOT#	RICHMAN	VALORANT	1	2025-09-19 02:49:18.847219+00	2
301	[2525VP] PRELUDE 2.0 ปืนแยก	625	KU-0000	RIOT#	RICHMAN	VALORANT	1	2025-09-19 02:49:46.661444+00	3
116	8920 เหรียญ	529	KU-0000	ID-PASS	YOUTRIP	MINECRAFT	0	2025-08-14 08:19:42.985313+00	9
115	7000 เหรียญ	349	KU-0000	ID-PASS	YOUTRIP	MINECRAFT	0	2025-08-14 08:19:17.564609+00	8
114	3820 เหรียญ	239	KU-0000	ID-PASS	YOUTRIP	MINECRAFT	0	2025-08-14 08:18:55.008897+00	7
117	10500 เหรียญ	649	KU-0000	ID-PASS	YOUTRIP	MINECRAFT	0	2025-08-14 08:20:01.853259+00	10
303	549BAHT (14.99$)	385	KU-0000	ID-PASS	ITUNES	7KNIGHT_Re:BIRTH	1	2025-09-21 00:31:43.140335+00	12
304	1800BAHT (49.99$)	1235	KU-0000	ID-PASS	ITUNES	7KNIGHT_Re:BIRTH	1	2025-09-21 00:32:29.176248+00	17
297	1150BAHT (31.99$)	835	KU-0000	ID-PASS	ITUNES	7KNIGHT_Re:BIRTH	1	2025-09-18 18:10:59.699396+00	15
296	1100BAHT (29.99$)	790	KU-0000	ID-PASS	ITUNES	7KNIGHT_Re:BIRTH	1	2025-09-18 17:09:23.172795+00	14
302	1450BAHT (39.99$)	990	KU-0000	ID-PASS	ITUNES	7KNIGHT_Re:BIRTH	1	2025-09-20 19:01:02.714018+00	16
\.


--
-- Data for Name: user_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_sessions (sid, sess, expire) FROM stdin;
EBSkIiD5SVl6GoJpokFBcYyU1cn7Ipdy	{"cookie":{"originalMaxAge":2592000000,"expires":"2025-10-25T17:26:44.114Z","secure":true,"httpOnly":true,"path":"/"},"userId":"tantan"}	2025-10-25 17:26:47
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (username, password_hash) FROM stdin;
admin	$2b$10$y.i5.3Q/N1B5gSL2p1XKAe9O.z5x2c2/S.X.g.i/w2nZ.f5k3J.kO
ADGRES02	$2b$10$QZC4PUtsMgzFAXRmSvxvK.LZWhBbEHosWfvthfb8JI0dRVs0N1iAC
tantan	$2b$10$m96Tvh9dtkPUWmiOEWZc9OZncLUZlQz9pTc.0QqFS6BG8JSLv0lDG
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: realtime; Owner: -
--

COPY realtime.schema_migrations (version, inserted_at) FROM stdin;
20211116024918	2025-08-12 18:05:41
20211116045059	2025-08-12 18:05:41
20211116050929	2025-08-12 18:05:41
20211116051442	2025-08-12 18:05:41
20211116212300	2025-08-12 18:05:41
20211116213355	2025-08-12 18:05:41
20211116213934	2025-08-12 18:05:41
20211116214523	2025-08-12 18:05:41
20211122062447	2025-08-12 18:05:41
20211124070109	2025-08-12 18:05:42
20211202204204	2025-08-12 18:05:42
20211202204605	2025-08-12 18:05:42
20211210212804	2025-08-12 18:05:42
20211228014915	2025-08-12 18:05:42
20220107221237	2025-08-12 18:05:42
20220228202821	2025-08-12 18:05:42
20220312004840	2025-08-12 18:05:42
20220603231003	2025-08-12 18:05:42
20220603232444	2025-08-12 18:05:42
20220615214548	2025-08-12 18:05:42
20220712093339	2025-08-12 18:05:42
20220908172859	2025-08-12 18:05:42
20220916233421	2025-08-12 18:05:42
20230119133233	2025-08-12 18:05:42
20230128025114	2025-08-12 18:05:42
20230128025212	2025-08-12 18:05:42
20230227211149	2025-08-12 18:05:42
20230228184745	2025-08-12 18:05:42
20230308225145	2025-08-12 18:05:42
20230328144023	2025-08-12 18:05:42
20231018144023	2025-08-12 18:05:42
20231204144023	2025-08-12 18:05:43
20231204144024	2025-08-12 18:05:43
20231204144025	2025-08-12 18:05:43
20240108234812	2025-08-12 18:05:43
20240109165339	2025-08-12 18:05:43
20240227174441	2025-08-12 18:05:43
20240311171622	2025-08-12 18:05:43
20240321100241	2025-08-12 18:05:43
20240401105812	2025-08-12 18:05:43
20240418121054	2025-08-12 18:05:43
20240523004032	2025-08-12 18:05:43
20240618124746	2025-08-12 18:05:43
20240801235015	2025-08-12 18:05:43
20240805133720	2025-08-12 18:05:43
20240827160934	2025-08-12 18:05:43
20240919163303	2025-08-12 18:05:43
20240919163305	2025-08-12 18:05:43
20241019105805	2025-08-12 18:05:43
20241030150047	2025-08-12 18:05:43
20241108114728	2025-08-12 18:05:43
20241121104152	2025-08-12 18:05:43
20241130184212	2025-08-12 18:05:43
20241220035512	2025-08-12 18:05:43
20241220123912	2025-08-12 18:05:43
20241224161212	2025-08-12 18:05:43
20250107150512	2025-08-12 18:05:43
20250110162412	2025-08-12 18:05:43
20250123174212	2025-08-12 18:05:43
20250128220012	2025-08-12 18:05:43
20250506224012	2025-08-12 18:05:43
20250523164012	2025-08-12 18:05:43
20250714121412	2025-08-12 18:05:43
20250905041441	2025-09-25 04:13:27
\.


--
-- Data for Name: subscription; Type: TABLE DATA; Schema: realtime; Owner: -
--

COPY realtime.subscription (id, subscription_id, entity, filters, claims, created_at) FROM stdin;
\.


--
-- Data for Name: buckets; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.buckets (id, name, owner, created_at, updated_at, public, avif_autodetection, file_size_limit, allowed_mime_types, owner_id, type) FROM stdin;
\.


--
-- Data for Name: buckets_analytics; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.buckets_analytics (id, type, format, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.migrations (id, name, hash, executed_at) FROM stdin;
0	create-migrations-table	e18db593bcde2aca2a408c4d1100f6abba2195df	2025-08-12 18:05:41.178132
1	initialmigration	6ab16121fbaa08bbd11b712d05f358f9b555d777	2025-08-12 18:05:41.196101
2	storage-schema	5c7968fd083fcea04050c1b7f6253c9771b99011	2025-08-12 18:05:41.209908
3	pathtoken-column	2cb1b0004b817b29d5b0a971af16bafeede4b70d	2025-08-12 18:05:41.668196
4	add-migrations-rls	427c5b63fe1c5937495d9c635c263ee7a5905058	2025-08-12 18:05:42.537278
5	add-size-functions	79e081a1455b63666c1294a440f8ad4b1e6a7f84	2025-08-12 18:05:42.543551
6	change-column-name-in-get-size	f93f62afdf6613ee5e7e815b30d02dc990201044	2025-08-12 18:05:42.551133
7	add-rls-to-buckets	e7e7f86adbc51049f341dfe8d30256c1abca17aa	2025-08-12 18:05:42.559413
8	add-public-to-buckets	fd670db39ed65f9d08b01db09d6202503ca2bab3	2025-08-12 18:05:42.566415
9	fix-search-function	3a0af29f42e35a4d101c259ed955b67e1bee6825	2025-08-12 18:05:42.572665
10	search-files-search-function	68dc14822daad0ffac3746a502234f486182ef6e	2025-08-12 18:05:42.583581
11	add-trigger-to-auto-update-updated_at-column	7425bdb14366d1739fa8a18c83100636d74dcaa2	2025-08-12 18:05:42.589864
12	add-automatic-avif-detection-flag	8e92e1266eb29518b6a4c5313ab8f29dd0d08df9	2025-08-12 18:05:42.595976
13	add-bucket-custom-limits	cce962054138135cd9a8c4bcd531598684b25e7d	2025-08-12 18:05:42.602386
14	use-bytes-for-max-size	941c41b346f9802b411f06f30e972ad4744dad27	2025-08-12 18:05:42.608603
15	add-can-insert-object-function	934146bc38ead475f4ef4b555c524ee5d66799e5	2025-08-12 18:05:42.646976
16	add-version	76debf38d3fd07dcfc747ca49096457d95b1221b	2025-08-12 18:05:42.652783
17	drop-owner-foreign-key	f1cbb288f1b7a4c1eb8c38504b80ae2a0153d101	2025-08-12 18:05:42.658706
18	add_owner_id_column_deprecate_owner	e7a511b379110b08e2f214be852c35414749fe66	2025-08-12 18:05:42.664819
19	alter-default-value-objects-id	02e5e22a78626187e00d173dc45f58fa66a4f043	2025-08-12 18:05:42.789499
20	list-objects-with-delimiter	cd694ae708e51ba82bf012bba00caf4f3b6393b7	2025-08-12 18:05:42.797677
21	s3-multipart-uploads	8c804d4a566c40cd1e4cc5b3725a664a9303657f	2025-08-12 18:05:42.807772
22	s3-multipart-uploads-big-ints	9737dc258d2397953c9953d9b86920b8be0cdb73	2025-08-12 18:05:42.823467
23	optimize-search-function	9d7e604cddc4b56a5422dc68c9313f4a1b6f132c	2025-08-12 18:05:42.838345
24	operation-function	8312e37c2bf9e76bbe841aa5fda889206d2bf8aa	2025-08-12 18:05:42.844168
25	custom-metadata	d974c6057c3db1c1f847afa0e291e6165693b990	2025-08-12 18:05:42.850469
26	objects-prefixes	ef3f7871121cdc47a65308e6702519e853422ae2	2025-08-14 09:11:43.893868
27	search-v2	33b8f2a7ae53105f028e13e9fcda9dc4f356b4a2	2025-08-14 09:11:43.983227
28	object-bucket-name-sorting	ba85ec41b62c6a30a3f136788227ee47f311c436	2025-08-14 09:11:43.993499
29	create-prefixes	a7b1a22c0dc3ab630e3055bfec7ce7d2045c5b7b	2025-08-14 09:11:44.002971
30	update-object-levels	6c6f6cc9430d570f26284a24cf7b210599032db7	2025-08-14 09:11:44.007741
31	objects-level-index	33f1fef7ec7fea08bb892222f4f0f5d79bab5eb8	2025-08-14 09:11:44.014672
32	backward-compatible-index-on-objects	2d51eeb437a96868b36fcdfb1ddefdf13bef1647	2025-08-14 09:11:44.021723
33	backward-compatible-index-on-prefixes	fe473390e1b8c407434c0e470655945b110507bf	2025-08-14 09:11:44.030908
34	optimize-search-function-v1	82b0e469a00e8ebce495e29bfa70a0797f7ebd2c	2025-08-14 09:11:44.032908
35	add-insert-trigger-prefixes	63bb9fd05deb3dc5e9fa66c83e82b152f0caf589	2025-08-14 09:11:44.040461
36	optimise-existing-functions	81cf92eb0c36612865a18016a38496c530443899	2025-08-14 09:11:44.045391
37	add-bucket-name-length-trigger	3944135b4e3e8b22d6d4cbb568fe3b0b51df15c1	2025-08-14 09:11:44.062352
38	iceberg-catalog-flag-on-buckets	19a8bd89d5dfa69af7f222a46c726b7c41e462c5	2025-08-14 09:11:44.068204
39	add-search-v2-sort-support	39cf7d1e6bf515f4b02e41237aba845a7b492853	2025-09-25 14:28:41.29515
40	fix-prefix-race-conditions-optimized	fd02297e1c67df25a9fc110bf8c8a9af7fb06d1f	2025-09-25 14:28:41.35153
41	add-object-level-update-trigger	44c22478bf01744b2129efc480cd2edc9a7d60e9	2025-09-25 14:28:41.376583
42	rollback-prefix-triggers	f2ab4f526ab7f979541082992593938c05ee4b47	2025-09-25 14:28:41.38291
43	fix-object-level	ab837ad8f1c7d00cc0b7310e989a23388ff29fc6	2025-09-25 14:28:41.388236
\.


--
-- Data for Name: objects; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata, level) FROM stdin;
\.


--
-- Data for Name: prefixes; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.prefixes (bucket_id, name, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: s3_multipart_uploads; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.s3_multipart_uploads (id, in_progress_size, upload_signature, bucket_id, key, version, owner_id, created_at, user_metadata) FROM stdin;
\.


--
-- Data for Name: s3_multipart_uploads_parts; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.s3_multipart_uploads_parts (id, upload_id, size, part_number, bucket_id, key, etag, owner_id, version, created_at) FROM stdin;
\.


--
-- Data for Name: secrets; Type: TABLE DATA; Schema: vault; Owner: -
--

COPY vault.secrets (id, name, description, secret, key_id, nonce, created_at, updated_at) FROM stdin;
\.


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: -
--

SELECT pg_catalog.setval('auth.refresh_tokens_id_seq', 1, false);


--
-- Name: order_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.order_items_id_seq', 1521, true);


--
-- Name: orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.orders_id_seq', 563, true);


--
-- Name: packages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.packages_id_seq', 118, true);


--
-- Name: packages_id_seq1; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.packages_id_seq1', 305, true);


--
-- Name: subscription_id_seq; Type: SEQUENCE SET; Schema: realtime; Owner: -
--

SELECT pg_catalog.setval('realtime.subscription_id_seq', 1, false);


--
-- Name: mfa_amr_claims amr_id_pk; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT amr_id_pk PRIMARY KEY (id);


--
-- Name: audit_log_entries audit_log_entries_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.audit_log_entries
    ADD CONSTRAINT audit_log_entries_pkey PRIMARY KEY (id);


--
-- Name: flow_state flow_state_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.flow_state
    ADD CONSTRAINT flow_state_pkey PRIMARY KEY (id);


--
-- Name: identities identities_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_pkey PRIMARY KEY (id);


--
-- Name: identities identities_provider_id_provider_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_provider_id_provider_unique UNIQUE (provider_id, provider);


--
-- Name: instances instances_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.instances
    ADD CONSTRAINT instances_pkey PRIMARY KEY (id);


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_authentication_method_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_authentication_method_pkey UNIQUE (session_id, authentication_method);


--
-- Name: mfa_challenges mfa_challenges_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_pkey PRIMARY KEY (id);


--
-- Name: mfa_factors mfa_factors_last_challenged_at_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_last_challenged_at_key UNIQUE (last_challenged_at);


--
-- Name: mfa_factors mfa_factors_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_pkey PRIMARY KEY (id);


--
-- Name: oauth_clients oauth_clients_client_id_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_clients
    ADD CONSTRAINT oauth_clients_client_id_key UNIQUE (client_id);


--
-- Name: oauth_clients oauth_clients_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_clients
    ADD CONSTRAINT oauth_clients_pkey PRIMARY KEY (id);


--
-- Name: one_time_tokens one_time_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_token_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_token_unique UNIQUE (token);


--
-- Name: saml_providers saml_providers_entity_id_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_entity_id_key UNIQUE (entity_id);


--
-- Name: saml_providers saml_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_pkey PRIMARY KEY (id);


--
-- Name: saml_relay_states saml_relay_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sso_domains sso_domains_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_pkey PRIMARY KEY (id);


--
-- Name: sso_providers sso_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_providers
    ADD CONSTRAINT sso_providers_pkey PRIMARY KEY (id);


--
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: admins admins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (username);


--
-- Name: app_config app_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_config
    ADD CONSTRAINT app_config_pkey PRIMARY KEY (key);


--
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (id);


--
-- Name: orders orders_order_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_order_number_key UNIQUE (order_number);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: packages packages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.packages
    ADD CONSTRAINT packages_pkey PRIMARY KEY (id);


--
-- Name: user_sessions session_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT session_pkey PRIMARY KEY (sid);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (username);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: subscription pk_subscription; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.subscription
    ADD CONSTRAINT pk_subscription PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: buckets_analytics buckets_analytics_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets_analytics
    ADD CONSTRAINT buckets_analytics_pkey PRIMARY KEY (id);


--
-- Name: buckets buckets_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets
    ADD CONSTRAINT buckets_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_name_key; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_name_key UNIQUE (name);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: objects objects_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT objects_pkey PRIMARY KEY (id);


--
-- Name: prefixes prefixes_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.prefixes
    ADD CONSTRAINT prefixes_pkey PRIMARY KEY (bucket_id, level, name);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_pkey PRIMARY KEY (id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_pkey PRIMARY KEY (id);


--
-- Name: audit_logs_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX audit_logs_instance_id_idx ON auth.audit_log_entries USING btree (instance_id);


--
-- Name: confirmation_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX confirmation_token_idx ON auth.users USING btree (confirmation_token) WHERE ((confirmation_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_current_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_current_idx ON auth.users USING btree (email_change_token_current) WHERE ((email_change_token_current)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_new_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_new_idx ON auth.users USING btree (email_change_token_new) WHERE ((email_change_token_new)::text !~ '^[0-9 ]*$'::text);


--
-- Name: factor_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX factor_id_created_at_idx ON auth.mfa_factors USING btree (user_id, created_at);


--
-- Name: flow_state_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX flow_state_created_at_idx ON auth.flow_state USING btree (created_at DESC);


--
-- Name: identities_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_email_idx ON auth.identities USING btree (email text_pattern_ops);


--
-- Name: INDEX identities_email_idx; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.identities_email_idx IS 'Auth: Ensures indexed queries on the email column';


--
-- Name: identities_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_user_id_idx ON auth.identities USING btree (user_id);


--
-- Name: idx_auth_code; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_auth_code ON auth.flow_state USING btree (auth_code);


--
-- Name: idx_user_id_auth_method; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_user_id_auth_method ON auth.flow_state USING btree (user_id, authentication_method);


--
-- Name: mfa_challenge_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_challenge_created_at_idx ON auth.mfa_challenges USING btree (created_at DESC);


--
-- Name: mfa_factors_user_friendly_name_unique; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX mfa_factors_user_friendly_name_unique ON auth.mfa_factors USING btree (friendly_name, user_id) WHERE (TRIM(BOTH FROM friendly_name) <> ''::text);


--
-- Name: mfa_factors_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_factors_user_id_idx ON auth.mfa_factors USING btree (user_id);


--
-- Name: oauth_clients_client_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_clients_client_id_idx ON auth.oauth_clients USING btree (client_id);


--
-- Name: oauth_clients_deleted_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_clients_deleted_at_idx ON auth.oauth_clients USING btree (deleted_at);


--
-- Name: one_time_tokens_relates_to_hash_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX one_time_tokens_relates_to_hash_idx ON auth.one_time_tokens USING hash (relates_to);


--
-- Name: one_time_tokens_token_hash_hash_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX one_time_tokens_token_hash_hash_idx ON auth.one_time_tokens USING hash (token_hash);


--
-- Name: one_time_tokens_user_id_token_type_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX one_time_tokens_user_id_token_type_key ON auth.one_time_tokens USING btree (user_id, token_type);


--
-- Name: reauthentication_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX reauthentication_token_idx ON auth.users USING btree (reauthentication_token) WHERE ((reauthentication_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: recovery_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX recovery_token_idx ON auth.users USING btree (recovery_token) WHERE ((recovery_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: refresh_tokens_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_idx ON auth.refresh_tokens USING btree (instance_id);


--
-- Name: refresh_tokens_instance_id_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_user_id_idx ON auth.refresh_tokens USING btree (instance_id, user_id);


--
-- Name: refresh_tokens_parent_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_parent_idx ON auth.refresh_tokens USING btree (parent);


--
-- Name: refresh_tokens_session_id_revoked_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_session_id_revoked_idx ON auth.refresh_tokens USING btree (session_id, revoked);


--
-- Name: refresh_tokens_updated_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_updated_at_idx ON auth.refresh_tokens USING btree (updated_at DESC);


--
-- Name: saml_providers_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_providers_sso_provider_id_idx ON auth.saml_providers USING btree (sso_provider_id);


--
-- Name: saml_relay_states_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_created_at_idx ON auth.saml_relay_states USING btree (created_at DESC);


--
-- Name: saml_relay_states_for_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_for_email_idx ON auth.saml_relay_states USING btree (for_email);


--
-- Name: saml_relay_states_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_sso_provider_id_idx ON auth.saml_relay_states USING btree (sso_provider_id);


--
-- Name: sessions_not_after_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_not_after_idx ON auth.sessions USING btree (not_after DESC);


--
-- Name: sessions_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_user_id_idx ON auth.sessions USING btree (user_id);


--
-- Name: sso_domains_domain_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_domains_domain_idx ON auth.sso_domains USING btree (lower(domain));


--
-- Name: sso_domains_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sso_domains_sso_provider_id_idx ON auth.sso_domains USING btree (sso_provider_id);


--
-- Name: sso_providers_resource_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_providers_resource_id_idx ON auth.sso_providers USING btree (lower(resource_id));


--
-- Name: sso_providers_resource_id_pattern_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sso_providers_resource_id_pattern_idx ON auth.sso_providers USING btree (resource_id text_pattern_ops);


--
-- Name: unique_phone_factor_per_user; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX unique_phone_factor_per_user ON auth.mfa_factors USING btree (user_id, phone);


--
-- Name: user_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX user_id_created_at_idx ON auth.sessions USING btree (user_id, created_at);


--
-- Name: users_email_partial_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX users_email_partial_key ON auth.users USING btree (email) WHERE (is_sso_user = false);


--
-- Name: INDEX users_email_partial_key; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.users_email_partial_key IS 'Auth: A partial unique index that applies only when is_sso_user is false';


--
-- Name: users_instance_id_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_email_idx ON auth.users USING btree (instance_id, lower((email)::text));


--
-- Name: users_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_idx ON auth.users USING btree (instance_id);


--
-- Name: users_is_anonymous_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_is_anonymous_idx ON auth.users USING btree (is_anonymous);


--
-- Name: ix_realtime_subscription_entity; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX ix_realtime_subscription_entity ON realtime.subscription USING btree (entity);


--
-- Name: messages_inserted_at_topic_index; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX messages_inserted_at_topic_index ON ONLY realtime.messages USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: subscription_subscription_id_entity_filters_key; Type: INDEX; Schema: realtime; Owner: -
--

CREATE UNIQUE INDEX subscription_subscription_id_entity_filters_key ON realtime.subscription USING btree (subscription_id, entity, filters);


--
-- Name: bname; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX bname ON storage.buckets USING btree (name);


--
-- Name: bucketid_objname; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX bucketid_objname ON storage.objects USING btree (bucket_id, name);


--
-- Name: idx_multipart_uploads_list; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_multipart_uploads_list ON storage.s3_multipart_uploads USING btree (bucket_id, key, created_at);


--
-- Name: idx_name_bucket_level_unique; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX idx_name_bucket_level_unique ON storage.objects USING btree (name COLLATE "C", bucket_id, level);


--
-- Name: idx_objects_bucket_id_name; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_objects_bucket_id_name ON storage.objects USING btree (bucket_id, name COLLATE "C");


--
-- Name: idx_objects_lower_name; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_objects_lower_name ON storage.objects USING btree ((path_tokens[level]), lower(name) text_pattern_ops, bucket_id, level);


--
-- Name: idx_prefixes_lower_name; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_prefixes_lower_name ON storage.prefixes USING btree (bucket_id, level, ((string_to_array(name, '/'::text))[level]), lower(name) text_pattern_ops);


--
-- Name: name_prefix_search; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX name_prefix_search ON storage.objects USING btree (name text_pattern_ops);


--
-- Name: objects_bucket_id_level_idx; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX objects_bucket_id_level_idx ON storage.objects USING btree (bucket_id, level, name COLLATE "C");


--
-- Name: subscription tr_check_filters; Type: TRIGGER; Schema: realtime; Owner: -
--

CREATE TRIGGER tr_check_filters BEFORE INSERT OR UPDATE ON realtime.subscription FOR EACH ROW EXECUTE FUNCTION realtime.subscription_check_filters();


--
-- Name: buckets enforce_bucket_name_length_trigger; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER enforce_bucket_name_length_trigger BEFORE INSERT OR UPDATE OF name ON storage.buckets FOR EACH ROW EXECUTE FUNCTION storage.enforce_bucket_name_length();


--
-- Name: objects objects_delete_delete_prefix; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER objects_delete_delete_prefix AFTER DELETE ON storage.objects FOR EACH ROW EXECUTE FUNCTION storage.delete_prefix_hierarchy_trigger();


--
-- Name: objects objects_insert_create_prefix; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER objects_insert_create_prefix BEFORE INSERT ON storage.objects FOR EACH ROW EXECUTE FUNCTION storage.objects_insert_prefix_trigger();


--
-- Name: objects objects_update_create_prefix; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER objects_update_create_prefix BEFORE UPDATE ON storage.objects FOR EACH ROW WHEN (((new.name <> old.name) OR (new.bucket_id <> old.bucket_id))) EXECUTE FUNCTION storage.objects_update_prefix_trigger();


--
-- Name: prefixes prefixes_create_hierarchy; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER prefixes_create_hierarchy BEFORE INSERT ON storage.prefixes FOR EACH ROW WHEN ((pg_trigger_depth() < 1)) EXECUTE FUNCTION storage.prefixes_insert_trigger();


--
-- Name: prefixes prefixes_delete_hierarchy; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER prefixes_delete_hierarchy AFTER DELETE ON storage.prefixes FOR EACH ROW EXECUTE FUNCTION storage.delete_prefix_hierarchy_trigger();


--
-- Name: objects update_objects_updated_at; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER update_objects_updated_at BEFORE UPDATE ON storage.objects FOR EACH ROW EXECUTE FUNCTION storage.update_updated_at_column();


--
-- Name: identities identities_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: mfa_challenges mfa_challenges_auth_factor_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_auth_factor_id_fkey FOREIGN KEY (factor_id) REFERENCES auth.mfa_factors(id) ON DELETE CASCADE;


--
-- Name: mfa_factors mfa_factors_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: one_time_tokens one_time_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: refresh_tokens refresh_tokens_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: saml_providers saml_providers_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_flow_state_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_flow_state_id_fkey FOREIGN KEY (flow_state_id) REFERENCES auth.flow_state(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: sso_domains sso_domains_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: order_items order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: objects objects_bucketId_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT "objects_bucketId_fkey" FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: prefixes prefixes_bucketId_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.prefixes
    ADD CONSTRAINT "prefixes_bucketId_fkey" FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_upload_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_upload_id_fkey FOREIGN KEY (upload_id) REFERENCES storage.s3_multipart_uploads(id) ON DELETE CASCADE;


--
-- Name: audit_log_entries; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.audit_log_entries ENABLE ROW LEVEL SECURITY;

--
-- Name: flow_state; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.flow_state ENABLE ROW LEVEL SECURITY;

--
-- Name: identities; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.identities ENABLE ROW LEVEL SECURITY;

--
-- Name: instances; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.instances ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_amr_claims; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_amr_claims ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_challenges; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_challenges ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_factors; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_factors ENABLE ROW LEVEL SECURITY;

--
-- Name: one_time_tokens; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.one_time_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: refresh_tokens; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.refresh_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_providers; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.saml_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_relay_states; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.saml_relay_states ENABLE ROW LEVEL SECURITY;

--
-- Name: schema_migrations; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.schema_migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: sessions; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_domains; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sso_domains ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_providers; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sso_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: users; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

--
-- Name: messages; Type: ROW SECURITY; Schema: realtime; Owner: -
--

ALTER TABLE realtime.messages ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets_analytics; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets_analytics ENABLE ROW LEVEL SECURITY;

--
-- Name: migrations; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: objects; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

--
-- Name: prefixes; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.prefixes ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.s3_multipart_uploads ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads_parts; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.s3_multipart_uploads_parts ENABLE ROW LEVEL SECURITY;

--
-- Name: supabase_realtime; Type: PUBLICATION; Schema: -; Owner: -
--

CREATE PUBLICATION supabase_realtime WITH (publish = 'insert, update, delete, truncate');


--
-- Name: supabase_realtime packages; Type: PUBLICATION TABLE; Schema: public; Owner: -
--

ALTER PUBLICATION supabase_realtime ADD TABLE ONLY public.packages;


--
-- Name: supabase_realtime users; Type: PUBLICATION TABLE; Schema: public; Owner: -
--

ALTER PUBLICATION supabase_realtime ADD TABLE ONLY public.users;


--
-- Name: issue_graphql_placeholder; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_graphql_placeholder ON sql_drop
         WHEN TAG IN ('DROP EXTENSION')
   EXECUTE FUNCTION extensions.set_graphql_placeholder();


--
-- Name: issue_pg_cron_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_cron_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_cron_access();


--
-- Name: issue_pg_graphql_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_graphql_access ON ddl_command_end
         WHEN TAG IN ('CREATE FUNCTION')
   EXECUTE FUNCTION extensions.grant_pg_graphql_access();


--
-- Name: issue_pg_net_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_net_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_net_access();


--
-- Name: pgrst_ddl_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER pgrst_ddl_watch ON ddl_command_end
   EXECUTE FUNCTION extensions.pgrst_ddl_watch();


--
-- Name: pgrst_drop_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER pgrst_drop_watch ON sql_drop
   EXECUTE FUNCTION extensions.pgrst_drop_watch();


--
-- PostgreSQL database dump complete
--

\unrestrict U1xJsbQL5fovvizFg8EefKxXXyqj62ygV71CYdIf5qT98fpvo3fnddCocBOHQng

