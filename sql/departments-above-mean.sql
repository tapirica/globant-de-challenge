/*
List of ids, name and number of employees hired of each department that hired more
employees than the mean of employees hired in 2021 for all the departments, ordered
by the number of employees hired (descending)
*/
WITH hires AS (
    SELECT department_id, COUNT(*) AS hired
    FROM hired_employees
    WHERE EXTRACT(YEAR FROM datetime) = 2021
    GROUP BY department_id
),
avg_hired AS (
    SELECT AVG(hired) AS mean_hired
    FROM hires
)
SELECT d.id, d.department, h.hired
FROM hires h
JOIN departments d ON h.department_id = d.id
JOIN avg_hired a ON h.hired > a.mean_hired
ORDER BY h.hired DESC;