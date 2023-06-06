CREATE OR REPLACE PROCEDURE insert_check(
	order_date DATE,
	order_client_id INTEGER,
	order_services_id INTEGER[],
	order_employee_id INTEGER,
	order_start_time TIME
)
AS $$
from datetime import time, datetime, timedelta

def str_to_timedelta(str_time):
	t = datetime.strptime(str_time, '%H:%M:%S')
	return timedelta(hours=t.hour, minutes=t.minute, seconds=t.second)

start_time = str_to_timedelta(order_start_time)

check_plan = plpy.prepare(
	'''INSERT INTO checks(check_date, client_id, employee_id)
		VALUES($1, $2, $3)
		RETURNING check_id''', 
	['date', 'integer', 'integer']
)

orders_plan = plpy.prepare(
	'''INSERT INTO orders(odrer_start, order_end, check_id, service_id)
    	VALUES($1, $2, $3, $4)
    	RETURNING order_id''',
	['time', 'time', 'integer', 'integer']
)

end_time_plan = plpy.prepare(
	'''SELECT duration
		FROM services
		WHERE service_id = $1''',
	['integer']
)
with plpy.subtransaction():
	check_id = check_plan.execute([order_date, order_client_id, order_employee_id], 1)[0]['check_id']
	for ser_id in order_services_id:
		end_time = str_to_timedelta(end_time_plan.execute([ser_id])[0]['duration']) + start_time
		order_id = orders_plan.execute([start_time, end_time, check_id, ser_id])[0]['order_id']
		start_time = end_time
$$
LANGUAGE 'plpython3u';