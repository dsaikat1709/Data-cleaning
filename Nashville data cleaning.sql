create database projects;

# renaming dataset for ease

alter table `nashville housing data`
rename to nashville;
 
select * from nashville;

#creating a new column to insert mysql understandable date data type

alter table nashville
add column sale_date date;

#turning off safe update for data manupulation

set sql_safe_updates = 0;

#inserting data into newly created date column

update nashville
set sale_date = str_to_date(saledate,"%d-%m-%Y");

# spliting the propertyaddress in multiple column

alter table nashville
add column cityname varchar(255);

update nashville
set cityname = substring_index(propertyaddress," ",-1);

alter table nashville
drop column cityname 
 ;
 
#area name column

alter table nashville
add column areaname varchar(255);

update nashville
set areaname = substring(propertyaddress,1,length(propertyaddress)- length(substring_index(propertyaddress," ",-1)));
# now for owner address

#owner cityname

alter table nashville
add column owner_cityname varchar(255);

update nashville
set owner_cityname = substring_index(owneraddress," ",-2);

#onwer area

alter table nashville
add column owner_area varchar(255);

update nashville
set owner_area = substring(owneraddress,1,length(owneraddress)- length(substring_index(owneraddress," ",-2)))
;

#owner state column

alter table nashville
add column owner_state varchar(255);

update nashville
set owner_state = substring_index(owneraddress," ",-1);

#bringing uniformity in the soldasvaccant column

#checking distinct values

select distinct SoldAsVacant
from nashville;

# checking values which have larger portion of data

select soldasvacant,count(soldasvacant)
from nashville
group by SoldAsVacant
order by 2; 

# changing all the Y and N to yes and no

update nashville
set SoldAsVacant = case when soldasvacant = "Y" then "Yes"
when soldasvacant = "N" then "No"
else soldasvacant
end 
;

# removing duplicates from the dataset

WITH duplicates AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY legalreference, owner ORDER BY legalreference) AS rownum
    FROM nashville
)
DELETE FROM nashville
WHERE (legalreference, owner) IN (
    SELECT legalreference, owner
    FROM duplicates
    WHERE rownum > 1
);
 
# checking whether duplicates removed or not 
 
with d_cte as(
select * ,row_number() over(partition by legalreference ,owner order by legalreference) as rownum
from nashville
)
select * from d_cte
where rownum > 1;

select * from nashville;


# if you don't want to manipulate your raw data you can create a temptable and work on it.

create temporary table temp_table as (WITH duplicates AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY legalreference, owner ORDER BY legalreference) AS rownum
    FROM nashville
)
select * from duplicates
);

delete from temp_table
where rownum > 1;

#Dropping unnecessary column

alter table nashville
drop column PropertyAddress,drop column SaleDate,drop column OwnerAddress;

#OUTLIER PROCESS

create temporary table t_table as ( select owner,saleprice ,row_number() over(order by saleprice) as rownum
from nashville);

#DEFINING VARIABLE WITH MAX ROW NUMBER 

set @max_value = (select  max(rownum) from t_table);

#CHECKING WHETHER THE VARIBLE ASSINGED OR NOT

select @max_value;

#FINDING OUR 1ST,2ND AND 3RD QUARTILE

select * from t_table
having rownum in  (round(@max_value*0.25),round(@max_value*0.50),round(@max_value*0.75))
;

# assigning 1st quartile

set @first_quartile = (select saleprice from t_table where rownum in (round(@max_value*0.25)));

select @first_quartile;

#assinging 2nd quartile

set @second_quartile = (select saleprice from t_table where rownum in (round(@max_value*0.50)));

select @second_quartile;

#assinging 3rd quartile

set @third_quartile = (select saleprice from t_table where rownum in (round(@max_value*0.75)));

select @third_quartile;

#detect outlier

select * from t_table
where saleprice < round((@first_quartile - 1.5*@second_quartile)) or 
saleprice > round((@third_quartile+1.5*@second_quartile));

#DELETE THE ROWS WITH OUTLIERS 

delete  FROM nashville
WHERE saleprice in (select saleprice from t_table
where saleprice < round((@first_quartile - 1.5*@second_quartile)) or 
saleprice > round((@third_quartile+1.5*@second_quartile)));


# END OF NASHVILLE DATA CLEANING PROJECT
	
    
