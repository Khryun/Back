CREATE FUNCTION update_empl_amount() RETURNS TRIGGER AS $$
  BEGIN
    UPDATE establishments
    SET empl_amount = empl_amount + 1
    WHERE establishment_id = NEW.establishment_id;
    RETURN NULL;
  END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_bonus_client() RETURNS TRIGGER AS $$
  DECLARE
    bonus_percent NUMERIC(3,2);
    client_estate VARCHAR(10);
  BEGIN
    SELECT estate INTO client_estate FROM clients WHERE client_id = NEW.client_id;
    IF client_estate = 'Золото' THEN
      bonus_percent = 0.15;
     ELSIF client_estate = 'Серебро' THEN
       bonus_percent = 0.1;
     ELSE
       bonus_percent = 0.05;
    END IF;
    UPDATE clients
    SET bonus = bonus + FLOOR((NEW.total_cost) * bonus_percent)
    WHERE client_id = NEW.client_id;
    RETURN NULL;
  END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION update_estate_client() RETURNS TRIGGER AS $$
  BEGIN
    IF NEW.amount_visits > 60 THEN
      NEW.estate := 'Золото';
    ELSIF NEW.amount_visits > 15 THEN
      NEW.estate := 'Серебро';
    ELSE
      NEW.estate := 'Бронза';
    END IF;
    RETURN NEW;
  END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION update_amount_visits_client() RETURNS TRIGGER AS $$
  BEGIN
    IF OLD IS NULL THEN
      UPDATE clients
      SET amount_visits = amount_visits + 1
      WHERE client_id = NEW.client_id;
    ELSE 
      UPDATE clients
      SET amount_visits = amount_visits - 1
      WHERE client_id = OLD.client_id;
    END IF;
    RETURN NULL;
  END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION update_total_cost_check() RETURNS TRIGGER AS $$
  BEGIN
    UPDATE checks
    SET total_cost = total_cost + (SELECT cost FROM services WHERE service_id = NEW.service_id)
    WHERE check_id = (SELECT check_id FROM orders WHERE order_id = NEW.order_id);
    RETURN NULL;
  END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_new_user() RETURNS TRIGGER AS $$
  DECLARE
    empl_post VARCHAR(13);
    role_name TEXT;
  BEGIN
    SELECT post INTO empl_post FROM employees WHERE employee_id = NEW.employee_id;
    IF empl_post = 'Администратор' THEN
      role_name := format('admin#%s', NEW.employee_id);
      EXECUTE format('CREATE ROLE %I WITH PASSWORD %L LOGIN SUPERUSER INHERIT CREATEROLE', role_name, NEW.hash_password);
      EXECUTE format('GRANT admin TO "%s"', role_name);
    ELSIF empl_post = 'Управляющий' THEN
      role_name := format('chief#%s', NEW.employee_id);
      EXECUTE format('CREATE ROLE %I WITH PASSWORD %L LOGIN INHERIT', role_name, NEW.hash_password);
      EXECUTE format('GRANT chief TO "%s"', role_name);
    ELSIF empl_post = 'Менеджер' THEN
      role_name := format('manager#%s', NEW.employee_id);
      EXECUTE format('CREATE ROLE %I WITH PASSWORD %L LOGIN INHERIT', role_name, NEW.hash_password);
      EXECUTE format('GRANT manager TO "%s"', role_name);
    ELSIF empl_post = 'Аналитик' THEN
      role_name := format('analyst#%s', NEW.employee_id);
      EXECUTE format('CREATE ROLE %I WITH PASSWORD %L LOGIN INHERIT', role_name, NEW.hash_password);
      EXECUTE format('GRANT analyst TO "%s"', role_name);
    ELSE
      role_name := format('worker#%s', NEW.employee_id);
      EXECUTE format('CREATE ROLE %I WITH PASSWORD %L LOGIN INHERIT', role_name, NEW.hash_password);
      EXECUTE format('GRANT worker TO "%s"', role_name);
    END IF;
    NEW.hash_password = crypt(
      NEW.hash_password,
      (SELECT phonenumber FROM employees WHERE employee_id = NEW.employee_id)
    );
    NEW.login = role_name;
    RETURN NEW;
  END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION update_user() RETURNS TRIGGER AS $$
  DECLARE
    empl_post VARCHAR(13);
  BEGIN
    EXECUTE format('ALTER ROLE %I WITH PASSWORD %L', OLD.login, NEW.hash_password);
    NEW.hash_password = crypt(
      NEW.hash_password,
      (SELECT telephone FROM employees WHERE employee_id = NEW.employee_id)
    );
    RETURN NEW;
  END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION delete_user() RETURNS TRIGGER AS $$
  BEGIN
    EXECUTE format('DROP ROLE "%s"', OLD.login);
    RETURN NULL;
  END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER count_employees AFTER INSERT ON schedule
FOR EACH ROW EXECUTE FUNCTION update_amount_employees();

CREATE OR REPLACE TRIGGER bonus_client AFTER UPDATE ON checks FOR EACH ROW
WHEN (NEW.paid is true) EXECUTE FUNCTION update_bonus_client();

CREATE TRIGGER amount_visits_client AFTER INSERT OR DELETE ON checks
FOR EACH ROW EXECUTE FUNCTION update_amount_visits_client();

CREATE TRIGGER estate_client AFTER UPDATE OF amount_visits ON clients
FOR EACH ROW EXECUTE FUNCTION update_estate_client();

CREATE TRIGGER total_cost_check AFTER INSERT ON orders
FOR EACH ROW EXECUTE FUNCTION update_total_cost_check();

CREATE TRIGGER new_user BEFORE INSERT ON users
FOR EACH ROW EXECUTE FUNCTION create_new_user();

CREATE TRIGGER new_user_password BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION update_user();

CREATE TRIGGER clear_user AFTER DELETE ON users
FOR EACH ROW EXECUTE FUNCTION delete_user();
