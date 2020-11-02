--Use this to assure the query is killed in the backend as well (as opposed to just CANCEL )

SELECT pg_cancel_backend(<pid>)

