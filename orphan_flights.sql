select * from jf_results where not exists (select id from flights where jf_results.flight_id = id);