/*
Number of employees hired for each job and department in 2021 divided by quarter. The
table must be ordered alphabetically by department and job
*/

SELECT 
    d.department,
    j.job,
    SUM(CASE WHEN EXTRACT(QUARTER FROM h.datetime) = 1 THEN 1 ELSE 0 END) AS q1,
    SUM(CASE WHEN EXTRACT(QUARTER FROM h.datetime) = 2 THEN 1 ELSE 0 END) AS q2,
    SUM(CASE WHEN EXTRACT(QUARTER FROM h.datetime) = 3 THEN 1 ELSE 0 END) AS q3,
    SUM(CASE WHEN EXTRACT(QUARTER FROM h.datetime) = 4 THEN 1 ELSE 0 END) AS q4
FROM hired_employees h
JOIN departments d ON h.department_id = d.id
JOIN jobs j ON h.job_id = j.id
WHERE EXTRACT(YEAR FROM h.datetime) = 2021
GROUP BY d.department, j.job
ORDER BY d.department ASC, j.job ASC;
