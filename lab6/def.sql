 CASE
         WHEN COALESCE(ec.employee_count,0) > 0 AND COALESCE(pc.project_count,0) > 0 THEN 'Fully Operational'
         WHEN COALESCE(ec.employee_count,0) = 0 AND COALESCE(pc.project_count,0) > 0 THEN 'Needs Employees'
         WHEN COALESCE(ec.employee_count,0) > 0 AND COALESCE(pc.project_count,0) = 0 THEN 'Needs Projects'
         ELSE 'Empty Department'
       END AS status