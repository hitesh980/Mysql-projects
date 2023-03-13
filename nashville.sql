use nashville1;
select * from nashville;
#Standardize Date Format by converting them to "Date" type
select cast(saledate as date) from nashville;

update nashville
set saledate = cast(saledate as date);

alter table nashville
add salesdayconv date;

update nashville
set salesdayconv = cast(saledate as date);

select salesdayconv from nashville;
#Fill in the Missing Property Address data
SELECT  * from nashville where (PropertyAddress = '' or NULL);
SELECT  * from nashville order by parcelid;
select a.parcelid,a.propertyaddress,b.parcelid,b.propertyaddress, a.salesdayconv,b.salesdayconv,
case when a.propertyaddress ='' then b.propertyaddress else '' end from nashville a JOIN nashville b ON a.parcelid = b.parcelid
and a.UniqueID <> b.UniqueID where a.propertyaddress = '';

select a.parcelid,a.propertyaddress,b.parcelid,b.propertyaddress, a.salesdayconv,b.salesdayconv,
case when (PropertyAddress = '' or NULL) then b.propertyaddress else '' end from nashville a JOIN nashville b ON a.parcelid = b.parcelid
and a.UniqueID <> b.UniqueID where a.propertyaddress = '';

update a
set propertyaddress = case when a.propertyaddress ='' then b.propertyaddress else '' end
from nashville a JOIN nashville b ON a.parcelid = b.parcelid
and a.UniqueID <> b.UniqueID where a.propertyaddress = '';

select
a.uniqueid,
a.parcelId,
a.propertyaddress,
coalesce(a.propertyaddress,b.propertyaddress) as finaladdy
from nashville a JOIN nashville b
ON a.parcelid = b.parcelid and a.uniqueid != b.uniqueid
where a.parcelid IN(
select parcelid from nashville where propertyaddress='')
order by a.parcelid,a.propertyaddress;

update a
set propertyaddress = coalesce(a.propertyaddress,b.propertyaddress) 
from nashville a JOIN nashville b
ON a.parcelid = b.parcelid and a.uniqueid != b.uniqueid
where a.parcelid IN(
select parcelid from nashville where propertyaddress='')
order by a.parcelid,a.propertyaddress;


 
 UPDATE nashville a
LEFT JOIN nashville b ON a.ParcelID = b.ParcelID 
AND a.UniqueID <> b.UniqueID 
SET a.PropertyAddress = b.PropertyAddress 
WHERE
    a.PropertyAddress ='';
    
 select * from nashville where propertyaddress ='';
 #returns zero values 
 
 # breaking out address into individual columns(address,city,state)
 select propertyaddress from nashville;
 select substring(propertyaddress,1,locate(',',propertyaddress)-1) as ad,
 substring(propertyaddress,locate(',',propertyaddress)+1 , char_length(propertyaddress)) as addy
  from nashville;

alter table Nashville
add propertysplitaddress varchar(255);

update nashville
set propertysplitaddress = substring(propertyaddress,1,locate(',',propertyaddress)-1);

alter table Nashville
add propertysplitcity varchar(255);

update nashville
set propertysplitcity = substring(propertyaddress,locate(',',propertyaddress)+1 , char_length(propertyaddress));

select propertysplitaddress , propertysplitcity from nashville;
select owneraddress from nashville;

select 
#substring_index(replace(owneraddress,',','.',1) from nashville;
substring_index2(replace(owneraddress,',' , '.'),1) from nashville;
substring_index('owneraddress',',' , '.',3) from nashville;

#soldasvacant
select distinct(soldasvacant),count(soldasvacant) from nashville group by 1 order by 2;

select soldasvacant ,
case when soldasvacant ='Y' then 'Yes'
     when soldasvacant ='N' then 'No'
     else soldasvacant
     end
from nashville;

update Nashville
set soldasvacant = case when soldasvacant ='Y' then 'Yes'
     when soldasvacant ='N' then 'No'
     else soldasvacant
     end;
#removing duplicates
with rownumcte as
(select *, row_number() over(partition by ParcelID,PropertyAddress,SalePrice,SaleDate,LegalReference
                         order by uniqueid) rownum from nashville)
                         delete from nashville using Nashville JOIN rownumcte on nashville.parcelid = rownumcte.parcelid where rownum>1;
with rownumcte as
(select *, row_number() over(partition by ParcelID,PropertyAddress,SalePrice,SaleDate,LegalReference
                         order by uniqueid) rownum from nashville)
                         select * from rownumcte where rownum>1;#returns zero rows as duplicates are deleted
                         