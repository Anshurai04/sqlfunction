  select * from salary

 create or replace function salary(age int)
 returns varchar as $$
 declare age_calculate varchar;
 begin 
     if age<=20 then 
	 age_calculate :='teenager';
	 elseif age<=45 then age_calculate :='younger';
	 elseif age<105 and age>45 then age_calculate :='senior citizen';
	 else age_calculate :='not able';
	 end if;
return 	age_calculate;
end;
$$ language plpgsql;

select salary(17)
select salary(21)
select salary(101)
select * from salary

create or replace function yearsalary(annual_salary int)
returns varchar as $$
declare salary_count varchar;
begin 
   if annual_salary <=10000 then salary_count :='taking basic salary';
   elseif  annual_salary <=30000 then salary_count :='taking avrage salary';
   elseif annual_salary<=60000 then salary_count :='taking high salary';
   else salary_count :='taking high post salary';
  end if;
return salary_count;
end;
$$ language plpgsql;
select yearsalary(20000)
select yearsalary(8000)
select yearsalary(50000)
select yearsalary(100000)

drop function yearsalary(annual_salary int)
