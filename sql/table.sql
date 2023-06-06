CREATE TABLE clients(
  client_id SERIAL PRIMARY KEY,
  client_name VARCHAR(128) NOT NULL,
  phone_number VARCHAR(18) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NULL,
  amount_visits SMALLINT DEFAULT 0 CONSTRAINT positive_amount_visits CHECK (amount_visits >= 0) NOT NULL,
  bonus INT DEFAULT 0 CONSTRAINT positive_bonus CHECK (bonus >= 0) NOT NULL,
  status VARCHAR(10) DEFAULT 'Бронза' NOT NULL
);


CREATE TABLE establishments(
  establishment_id SERIAL PRIMARY KEY,
  address VARCHAR(128) NOT NULL,
  postcode INT NOT NULL,
  phonenumber VARCHAR(18) UNIQUE NOT NULL,
  empl_amount SMALLINT DEFAULT 0 CONSTRAINT positive_amount_employees CHECK (empl_amount >= 0) NOT NULL
);

CREATE TABLE employees(
  employee_id SERIAL PRIMARY KEY,
  employee_name VARCHAR(128) NOT NULL,
  phonenumber VARCHAR(18) UNIQUE NOT NULL,
  email VARCHAR(128) UNIQUE NULL,
  experience SMALLINT DEFAULT 0 CONSTRAINT positive_experience CHECK (experience >= 0) NOT NULL,
  salary INT CONSTRAINT positive_salary CHECK (salary > 24800) NOT NULL,
  resume TEXT NULL,
  age SMALLINT CONSTRAINT positive_age CHECK (age >= 16 AND
    age * 365 - experience * 30 >= 16 * 365) NOT NULL,
  post VARCHAR(13) NOT NULL
);

CREATE TABLE checks(
  check_id SERIAL PRIMARY KEY,
  check_date DATE NOT NULL,
  total_cost INT DEFAULT 0 CONSTRAINT positive_total_cost CHECK (total_cost >= 0) NOT NULL,
  is_paid BOOLEAN DEFAULT false NOT NULL,
  client_id INT REFERENCES clients ON DELETE SET NULL NULL,
  employee_id INT REFERENCES employees ON DELETE SET NULL NULL
);

CREATE TABLE schedule(
  schedule_id SERIAL PRIMARY KEY,
  work_date DATE NOT NULL,
  work_start TIME NOT NULL,
  work_end TIME NOT NULL CONSTRAINT end_more_than_start CHECK (work_end > work_start),
  presence BOOLEAN DEFAULT true NOT NULL,
  establishment_id INT REFERENCES establishments ON DELETE CASCADE NOT NULL,
  employee_id INT REFERENCES employees ON DELETE CASCADE NOT NULL
);

CREATE TABLE services(
  service_id SERIAL PRIMARY KEY,
  service_title VARCHAR(50) NOT NULL,
  cost SMALLINT CONSTRAINT positive_cost CHECK (cost > 0) NOT NULL,
  duration INTERVAL NOT NULL
);

CREATE TABLE orders(
  order_id SERIAL PRIMARY KEY,
  order_start TIME NOT NULL,
  order_end TIME NOT NULL,
  check_id INT REFERENCES checks ON DELETE CASCADE NOT NULL,
  service_id INT REFERENCES services NOT NULL
);

CREATE TABLE employee_service(
  employee_id INT REFERENCES employees ON DELETE CASCADE NOT NULL,
  service_id INT REFERENCES services ON DELETE CASCADE NOT NULL,
  PRIMARY KEY (employee_id, service_id)
);

CREATE TABLE users(
  user_id SERIAL PRIMARY KEY,
  login VARCHAR(255) UNIQUE NOT NULL,
  hash_password VARCHAR(255) NOT NULL,
  employee_id INT UNIQUE REFERENCES employees ON DELETE CASCADE NOT NULL
);