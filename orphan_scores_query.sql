select * from contests where id in (select contest_id from flights where id in (select distinct id from flights where id in (select flight_id from pilot_flights where id in (select pilot_flight_id from scores where not exists (select * from judges where scores.judge_id = id)))));