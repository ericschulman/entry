#figure out the average number of stores per state
with obs_per_state as (select state, count(*) as num_obs from entry group by state)

select avg(num_obs) from obs_per_state

#calculate the variance of number of stores
with obs_per_state as (select state, count(*) as num_obs from entry group by state)

select avg(num_obs*num_obs) - avg(num_obs)*avg(num_obs) from obs_per_state


# final
with entry_states AS (SELECT entry.address, entry.city, entry.store, entry.time, entry.url, entry.zipcode, 
states.STATE, states.STATENS, states.STATE_NAME, states.STUSAB
FROM entry, states
WHERE entry.state = states.STATE_NAME
OR entry.state = states.STUSAB), 

census_asc as (SELECT * FROM census ORDER BY population ASC),

census_join AS (SELECT * FROM entry_states
LEFT JOIN census_asc AS census ON instr(census.name, entry_states.city) >= 1 
and instr(census.name, entry_states.STATE_NAME) >= 1
GROUP BY address
ORDER BY population ASC),

hd_no_dups AS (SELECT * FROM entry_states WHERE store='HD' 
	GROUP BY address,zipcode), 

lo_no_dups AS (SELECT * FROM entry_states WHERE store='LOW'
	GROUP BY address,zipcode),

hd AS (SELECT count(*) as HD, city, state 
	FROM hd_no_dups group by city, state order by state,city), 

lo AS (SELECT count(*) as LO, city, state  
	FROM lo_no_dups group by city, state order by state,city),
	
hd_join AS (SELECT  hd.city, STUSAB, HD, LO, 
place, name, zipcode, income_per_capita, population, 
under44_1, under44_2, under44_3, older65_1, older_65_2 
FROM hd
LEFT JOIN lo ON hd.city = lo.city
AND hd.state = lo.state
LEFT JOIN census_join ON hd.city = census_join.city
AND hd.state = census_join.STATE 
GROUP BY hd.city, hd.state),

lo_join AS ( SELECT  lo.city, STUSAB, HD, LO, 
place, name, zipcode, income_per_capita, population, 
under44_1, under44_2, under44_3, older65_1, older_65_2  
FROM lo
LEFT JOIN hd ON lo.city = hd.city
AND lo.state = hd.state
LEFT JOIN census_join ON lo.city = census_join.city
AND lo.state = census_join.STATE 
GROUP BY lo.city, lo.state)

SELECT * FROM (SELECT * FROM hd_join 
UNION 
SELECT * FROM lo_join)
