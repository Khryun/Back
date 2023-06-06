-- EMPLOYEE_SERVICE
CREATE POLICY employee_service_for_chief ON employee_service AS PERMISSIVE FOR ALL TO chief
USING(
	employee_id = ANY(
		SELECT employee_id
		FROM employees
		WHERE post = 'Парикмахер'
  )
)
WITH CHECK(
  employee_id = ANY(
		SELECT employee_id
		FROM employees
		WHERE post = 'Парикмахер'
  )
);

CREATE POLICY employee_service_for_analyst ON employee_service AS PERMISSIVE FOR SELECT TO analyst
USING(true);

CREATE POLICY employee_service_for_manager ON employee_service AS PERMISSIVE FOR SELECT TO manager
USING(true);

CREATE POLICY employee_service_for_worker ON employee_service AS PERMISSIVE FOR SELECT TO worker 
USING(employee_id::text = substring(current_user from '[0-9]+'));

-- EMPLOYEES
CREATE POLICY employees_for_chief ON employees AS PERMISSIVE FOR ALL TO chief
USING(
	employee_id = ANY(
		SELECT employee_id
		FROM schedule
		WHERE establishment_id = ANY(
			SELECT establishment_id
			FROM schedule
			WHERE schedule.employee_id::text = substring(current_user from '[0-9]+')
			GROUP BY establishment_id
		) AND work_date >= current_date
		GROUP BY employee_id
	) 
	OR employee_id not IN(
		SELECT employee_id
		FROM schedule
    WHERE work_date >= current_date
		GROUP BY employee_id
	)
)
WITH CHECK(true);

CREATE POLICY employees_for_worker ON employees AS PERMISSIVE FOR SELECT TO worker
USING(employee_id::text = substring(current_user from '[0-9]+'));

CREATE POLICY employees_for_analyst ON employees AS PERMISSIVE FOR SELECT TO analyst
USING(true);

CREATE POLICY employees_for_manager ON employees AS PERMISSIVE FOR SELECT TO manager
USING(
	post = 'Парикмахер' OR
	employee_id::text = substring(current_user from '[0-9]+')
);

-- ESTABLISHMENTS
CREATE POLICY establishments_for_chief ON establishments AS PERMISSIVE FOR ALL TO chief
USING(
	establishment_id = ANY(
		SELECT establishment_id
		FROM schedule
		WHERE employee_id::text = substring(current_user from '[0-9]+')
		 AND work_date >= current_date
		GROUP BY establishment_id
	)
);

CREATE POLICY establishments_for_worker ON establishments AS PERMISSIVE FOR SELECT TO worker
USING(
	establishment_id = ANY (
		SELECT establishment_id
		FROM schedule
	)
);

CREATE POLICY establishments_for_analyst ON establishments AS PERMISSIVE FOR SELECT TO analyst
USING(true);

CREATE POLICY establishments_for_manager ON establishments AS PERMISSIVE FOR SELECT TO manager
USING(true);

-- SCHEDULE
CREATE POLICY schedule_for_chief ON schedule AS PERMISSIVE FOR ALL TO chief USING(true);

CREATE POLICY schedule_for_worker ON schedule AS PERMISSIVE FOR SELECT TO worker
USING(employee_id::text = substring(current_user from '[0-9]+'));

CREATE POLICY schedule_for_analyst ON schedule AS PERMISSIVE FOR SELECT TO analyst
USING(true);

CREATE POLICY schedule_for_manager ON schedule AS PERMISSIVE FOR SELECT TO manager
USING(
	employee_id = ANY(
		SELECT employee_id
		FROM employees
	) OR
	employee_id::text = substring(current_user from '[0-9]+')
);

-- USERS
CREATE POLICY users_for_all ON users AS PERMISSIVE FOR SELECT 
USING(login = current_user);