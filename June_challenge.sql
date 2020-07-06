SELECT *
FROM (
SELECT user_id, login__ifit__email, personal__firstname, personal__lastname,
shipping__name, shipping__street1, shipping__city, shipping__state, shipping__zip, shipping__country
count(*)
FROM (
	SELECT A.user_id, start_minute, duration,
	(duration / 1000) as Duration_Secs,
	round((duration / 1000) / target_value, 2) as Percent_Complete,
	login__ifit__email, personal__firstname, personal__lastname, shipping__name,
	shipping__street1, shipping__city, shipping__state, shipping__zip, shipping__country
	FROM unique_logs A
	JOIN prodmongo.workouts on A.workout_id = workouts._id
	JOIN prodmongo.users on A.user_id = users._id
	WHERE CONVERT_TIMEZONE('America/Denver', start_minute)::date BETWEEN '2020-06-01' AND '2020-06-30'
	AND workout_id IN ('5ecff5384d0bde000873b729',
	'5d77d632b2f2d80587ff4d6f',
	'5d1b9c57c9b4a4007cf57e4a',
	'5c61c2c085afba0518226ea7',
	'5e6fb1c84fed0100086b27c2',
	'5e3d9b9a1780e2000728d896',
	'5d83d4a35a0ef701d3aef5b0',
	'5aa0181111bab7002f4e1c23',
	'5d7fb04c2dab490707ef12ef',
	'5d66c300c18c5e04442d7d65',
	'5d5c0bf7cffba503572f2009',
	'5e2a0dd28de9150008ee15a3',
	'5937361c728c88002492c205',
	'599f467da46168003fcf56a3',
	'5ca4e888ceb5ca01dab8c20d',
	'5ecff5e6f4965200096969a4',
	'5a908d4d86438900295f314e',
	'5a908d9c86438900295f3151',
	'5ab182b3f4f2a60029b81f9a',
	'5ab18bcbf4f2a60029b81f9b',
	'5a8f4c2a789559002acc82d7',
	'5a8f323461a0a5002ffd13f6',
	'5a996f3602e3ae0034c1c5f7',
	'5ab19008b9bf30002f75f285',
	'5a996c0e02e3ae0034c1c5f6',
	'5db7447006cef40038bb1333',
	'5db86b5346fc3101012b23d2',
	'5dbb050fef48460139e2ea2f',
	'5dbb076f0463b501173f01b6',
	'5dbc6896d717da003206a27b',
	'5ecff69d4d0bde000873b72a',
	'5d796fe2e076ac00927ab728',
	'5eab0c3f8e50720007a6c199',
	'5eab1802d9c4880007c00c17',
	'5b9c404bb61738002cccdf0b',
	'5d52e19d35e26c008cd823b8',
	'5d52e2de3612b202e2bec6a5',
	'5bbbddf677c0d4002c27d5fb',
	'5bc6618ec6cebe002da3f1b6',
	'5b9947c094184c002d3f7ef3',
	'5b92a2dd0a22210028a23b48',
	'5b9fef4cad09b7002d4c1cfe',
	'5b58fdb572b4db002ee50745',
	'5b999c130c2b95002c6ae167',
	'5ba525c1b0117e002cc58f84',
	'5ecff8d4f4965200096969b0',
	'5d1b9c57c9b4a4007cf57e4a',
	'5c61c2c085afba0518226ea7',
	'5e6fb1c84fed0100086b27c2',
	'5e3d9b9a1780e2000728d896',
	'5dc33428db5e8801d6ca2692',
	'5dc5ca6d640dfa003c5bb026',
	'5d83d4a35a0ef701d3aef5b0',
	'5dc5bcd133d4da009b5da69a',
	'5e2a0dd28de9150008ee15a3',
	'5937361c728c88002492c205',
	'599f467da46168003fcf56a3',
	'5ca4e888ceb5ca01dab8c20d',
	'5e135b92c7768b053547d4aa',
	'5ca782eb71b1b103b80fca63'))
	WHERE percent_complete >= 0.7
	AND shipping__country IN ('US', NULL)
	GROUP BY user_id, login__ifit__email, personal__firstname, personal__lastname,
	shipping__name, shipping__street1, shipping__city, shipping__state, shipping__zip, shipping__country)
/*WHERE (program = 'Switzerland' AND count >= 5)
OR (program = 'Niagra' AND count >= 4) */
WHERE count >= 7
