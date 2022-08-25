
-- Impoting CSV of Vancouver
-- Read top 10 Rows from Vancouver CSV

Select top 10 * from [dbo].[host_vancouver_df]
Select top 10 * from [dbo].[listing_vancouver_df]
Select top 10 * from [dbo].[review_vancouver_df]
Select top 10 * from [dbo].[df_vancouver_availability]

-- Checking no of rows in each tables
Select COUNT(*)as no_of_rows from [dbo].[host_V]
 
--Finding Hosts Acceptance rate & response rate
Select 
Avg(host_response_rate) As host_response_rate,
Avg(host_acceptance_rate) as host_acceptance_rate,
host_is_superhost from [dbo].[host_Vancouver_df] 
where  host_response_rate is not null or host_acceptance_rate is not null  
group by host_is_superhost;

-- Checking Hosts having Profile picture

select host_is_superhost,sum(true) as Host_have_profile_pic,
sum(false)as Host_dont_have_profile_pic 
from(
select host_is_superhost,[TRUE],[FALSE] 
from [dbo].[host_Vancouver_df]
pivot (count(host_id) for
host_has_profile_pic in ([TRUE],[FALSE]))a)a
group by host_is_superhost

-- Checking Hosts having identity verified

select host_is_superhost,sum(true) as Verified,
sum(false)as Not_verified from(
select host_is_superhost,[TRUE],[FALSE] 
from [dbo].[host_Vancouver_df]
pivot (count(host_id) for
host_Identity_verified in ([TRUE],[FALSE]))a)a 
group by host_is_superhost

-- Checking if Customer can do instant booking

Select B.Host_is_superhost,A.instant_bookable,
Count(A.HOST_ID) AS count 
From listing_Vancouver_df A Inner Join host_Vancouver_df B 
ON A.HOST_ID = B.HOST_ID 
Group by Host_is_superhost,instant_bookable

-- Checking Customer review scores

Select B.Host_is_superhost,
avg(A.review_scores_value) as review_scores_value  
From listing_Vancouver_df A Inner Join host_Vancouver_df B 
ON A.HOST_ID = B.HOST_ID 
Group by Host_is_superhost

-- Calculate average no of bookings per month.

Select MONTH,host_is_superhost,
Avg(Total_Bookings)Over(Partition by Month,host_is_superhost 
Order by Month) as Avg_bookings 
from(
Select month(a.date) as Month, 
Count(B.id) as Total_Bookings,C.host_is_superhost
from df_Vancouver_availability A Inner Join listing_Vancouver_df B ON A.listing_id = B.id
Inner join host_Vancouver_df C ON B.Host_ID = C.HOST_ID
where host_is_superhost is not null AND A.available = 'FALSE'
group by month(date),Year(Date),C.host_is_superhost )c

-- Analyzing  comments of reviewers varies for listings of Super Hosts vs Other Hosts

Select Sum(Total_Comments) from (
Select A.comments,Count(B.Host_ID) As Total_comments
from review_Vancouver_df A Inner Join listing_Vancouver_df B ON A.listing_id = B.id
Inner join host_Vancouver_df C ON B.Host_ID = C.HOST_ID 
where C.Host_is_superhost = 'False' and A.comments  like '%Beautiful%' or A.comments  like '%Fantastic%'
or A.comments  like '%100%%' or A.comments  like '%10/10%'
or A.comments  like '%11/10%' or A.comments  like '%12/10%'
or A.comments  like '%5 star%' or A.comments  like '%5 of 5 stars%'
or A.comments  like '%Great%' or A.comments  like '%Clean%'
or A.comments  like '%amazing%' or A.comments  like '%Wonderful%'
or A.comments  like '%5star%' or A.comments  like '%best%'
or A.comments  like '%Definitely%' or A.comments  like '%excellent%'
or A.comments  like '%Awesome%' or A.comments  like '%excellent%'
or A.comments  like '%Decent%'or A.comments  like '%Well%'
or A.comments  like '%quiet%' or A.comments  like '%love%'
group by A.comments)c

-- Analyzing large property types For Normal-hosts

Select A.Property_type,Count(A.Host_ID) as Total_Property_Otherhost
From listing_Vancouver_df A Inner Join host_Vancouver_df B 
ON A.HOST_ID = B.HOST_ID 
where B.Host_is_superhost = 'False'  and property_type  like '%ENTIRE%'
group by A.Property_type

-- Analyzing large property types For Superhost

Select A.Property_type,Count(A.Host_ID) as Total_Property_Superhost
From listing_Vancouver_df A Inner Join host_Vancouver_df B 
ON A.HOST_ID = B.HOST_ID where B.Host_is_superhost = 'TRUE' and property_type  like '%ENTIRE%'
group by A.Property_type

-- Analyzing Average price of the listings 

Create procedure p1 @superhost nvarchar(10) as begin 
Select * from (
Select A.listing_id,AVG(A.Price) AS AVG,
YEAR(date) AS YEAR
from df_Vancouver_availability A Inner Join 
listing_Vancouver_df B ON A.listing_id = B.id
Inner join host_Vancouver_df C ON B.Host_ID = C.HOST_ID
WHERE C.host_is_superhost = @superhost
GROUP BY A.listing_id,YEAR(date))c
PIVOT(AVG(AVG) for Year IN ([2022],[2023])) as PVT2
end;

exec p1 'TRUE';

-- Analyzing AVAILABILITY of the listings 

Select A.listing_id,count(A.available) as ava,YEAR(A.date) AS YEAR into #mmm
from df_Vancouver_availability as A  Inner Join listing_Vancouver_df as  B ON A.listing_id = B.id
Inner join host_Vancouver_df as  C ON B.Host_ID = C.HOST_ID WHERE C.host_is_superhost = 'True' and A.available='True'
GROUP BY A.listing_id,YEAR(A.date)
Select A.listing_id,count(A.available) as total,YEAR(A.date) AS YEAR into #nnn
from df_Vancouver_availability as A Inner Join listing_Vancouver_df as  B ON A.listing_id = B.id
Inner join host_Vancouver_df as  C ON B.Host_ID = C.HOST_ID WHERE C.host_is_superhost = 'True'
GROUP BY A.listing_id,YEAR(A.date)
select top 10* from #mmm order by listing_id,year
select  top 10* from #nnn order by listing_id,year
select A.listing_id , (A.ava)*100/B.total as per,A.year from #mmm as A inner join #nnn as B on
A.listing_id=B.listing_id where A.year=B.year
order by A.listing_id, A.year


-- For NON-LOCAL hosts

Select A.Host_id, Avg(host_response_rate) As host_response_rate, Avg(host_acceptance_rate) 
as host_acceptance_rate from [dbo].[host_Vancouver_df] A Inner Join #c B ON B.host_id = A.host_id
where  host_response_rate is not null or host_acceptance_rate is not null GROUP BY A.host_id;


-- For LOCAL hosts

Select A.Host_id, Avg(host_response_rate) As host_response_rate,Avg(host_acceptance_rate) 
as host_acceptance_rate from [dbo].[host_Vancouver_df] B Inner Join #A A ON A.host_id = B.host_id
where  host_response_rate is not null or host_acceptance_rate is not null GROUP BY A.host_id;


 
 



