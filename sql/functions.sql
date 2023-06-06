CREATE OR REPLACE FUNCTION get_all_checks(find_date date, is_paid_check BOOLEAN DEFAULT NULL) 
    RETURNS TABLE (
		check_id INTEGER, 
		check_date DATE, 
		total_cost INTEGER, 
        start_time TIME, 
		end_time TIME, 
        is_paid BOOLEAN, 
		employee_name VARCHAR(128), 
		address VARCHAR(128), 
		post VARCHAR(13),
		client_id INTEGER
) 
AS $$
BEGIN
    RETURN QUERY SELECT 
	checks.check_id, checks.check_date, checks.total_cost, 
	MIN(orders.order_start) as start_time, MAX(orders.order_end) as end_time, 
	checks.is_paid, employees.employee_name, establishments.address, employees.post, checks.client_id
		FROM checks
		INNER JOIN orders USING(check_id)
		INNER JOIN employees USING(employee_id)
		INNER JOIN schedule USING(employee_id)
		INNER JOIN establishments USING(establishment_id)
	WHERE checks.check_date = schedule.work_date 
		AND (find_date IS NULL OR checks.check_date = find_date)
		AND (is_paid_check IS NULL OR checks.is_paid = is_paid_check)
	GROUP BY checks.check_id, employees.employee_name, establishments.address, employees.post
	ORDER BY checks.check_date DESC, checks.check_id DESC;
END; $$ 
LANGUAGE 'plpgsql';

-- Отчет заведений
CREATE OR REPLACE FUNCTION establishments_profit_for_period(start_date DATE, end_date DATE)
RETURNS TABLE (
	establishment_id INTEGER, 
	address VARCHAR(128), 
	profit BIGINT,
	amount_checks INTEGER
) 
AS $$
BEGIN
RETURN QUERY SELECT 
		establishments.establishment_id, establishments.address, 
		COALESCE(SUM(checks.total_cost), 0) as profit, 
		COUNT(check_id)::INTEGER as amount_checks
		FROM establishments
			 LEFT JOIN schedule USING(establishment_id)
			 LEFT JOIN checks ON checks.employee_id = schedule.employee_id 
							   AND schedule.work_date = checks.check_date
							   AND (checks.check_date BETWEEN start_date AND end_date)
							   AND checks.is_paid is True
		GROUP BY establishments.establishment_id;
END; $$ 
LANGUAGE 'plpgsql';

-- Отчет сотрудников
CREATE OR REPLACE FUNCTION employees_profit_for_period(start_date DATE, end_date DATE)
RETURNS TABLE (
	employee_id INTEGER, 
	employee_name VARCHAR(128), 
	profit BIGINT,
	period_grade NUMERIC(2,1),
	amount_checks INTEGER
) 
AS $$
BEGIN
RETURN QUERY 
SELECT employees.employee_id, employees.employee_name, 
		COALESCE(SUM(checks.total_cost), 0) as profit, 
		COUNT(check_id)::INTEGER as amount_checks
FROM employees
	 LEFT JOIN checks ON checks.employee_id = employees.employee_id 
	 		AND (checks.check_date BETWEEN start_date AND end_date)
			AND checks.is_paid is True
WHERE employees.post IN ('Парикмахер')
GROUP BY employees.employee_id;
END; $$ 

LANGUAGE 'plpgsql';


-- Отчет услуг
CREATE OR REPLACE FUNCTION services_profit_for_period(start_date DATE, end_date DATE)
RETURNS TABLE (
	service_id INTEGER, 
	service_title VARCHAR(50), 
	profit BIGINT,
	amount_checks INTEGER
) 
AS $$
services_plan = plpy.prepare(
	'''SELECT services.service_id, services.service_title, 
		COUNT(checks.check_id) * services.cost as profit, 
		COUNT(checks.check_id)::INTEGER as amount_checks
		FROM services
			LEFT JOIN orders USING(service_id)
			LEFT JOIN checks ON checks.check_id = orders.check_id 
							 AND (checks.check_date BETWEEN $1 AND $2)
							 AND checks.is_paid is True
		GROUP BY services.service_id
		ORDER BY services.service_id;''',
	['date', 'date']
)
services = services_plan.execute([start_date, end_date])
checks_plan = plpy.prepare('''
	SELECT ch.check_id, (SUM(cost) - total_cost) / COUNT(service_id) as paid_bonus, 
	ARRAY (
		SELECT services.service_id
		FROM checks
			INNER JOIN orders USING(check_id)
			INNER JOIN services USING(service_id)
		WHERE checks.check_id = ch.check_id AND ch.paid is True
		GROUP BY checks.check_id, services.service_id
		) as services_id
	FROM checks ch
		INNER JOIN orders USING(check_id)
		INNER JOIN services USING(service_id)
	WHERE ch.is_paid is True AND (ch.check_date BETWEEN $1 AND $2)
	GROUP BY ch.check_id;''',
		['date', 'date'])
checks = checks_plan.execute([start_date, end_date])
for ch in checks:
	for s in services:
		if s['service_id'] in ch['services_id']:
			s['profit'] -= ch['paid_bonus']
return services
$$ 
LANGUAGE 'plpython3u';