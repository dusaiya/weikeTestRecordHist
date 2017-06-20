---------------------------worker部分完成------------------------------------------
--首先确认任务提交时间
create table train_2015_task_split
select a.task_id,
count(1)  ct,
a.task_Release_Date,
a.p_Release_Date,
a.p_Crowd_Submit_Date,
min(b.submit_datetime)  min_submit_datetime,
max(b.submit_datetime) max_submit_datetime
from task_f a
left join piecework_f b on a.task_id = b.task_id
where a.first_catagory in 
('品牌设计','起名取名','文案策划','软件开发',
'动画漫画','装修服务','网站建设','摄影摄像','UI设计','电商服务')
group by a.task_id;

create index idx_task_id on train_2015_task_split(task_id);
--更正时间，将每个string 时间都转换成 时间函数
alter table train_2015_task_split add column task_Release_Datetime datetime;
alter table train_2015_task_split add column p_Release_Datetime datetime;
alter table train_2015_task_split add column p_Crowd_Submit_Datetime datetime;
alter table train_2015_task_split add column task_start_datetime datetime;
alter table train_2015_task_split add column task_end_datetime datetime;
alter table train_2015_task_split add column task_days int(11);

update train_2015_task_split set p_Release_Datetime = p_Release_Date;
update train_2015_task_split set task_Release_Datetime=task_Release_Date;
update train_2015_task_split set p_Crowd_Submit_Datetime=p_Crowd_Submit_Date;
--时间标准化
update train_2015_task_split
	set max_submit_datetime=DATE_FORMAT(max_submit_datetime,'%Y-%m-%d') 
	,min_submit_datetime=DATE_FORMAT(min_submit_datetime,'%Y-%m-%d') ;
--设置起始时间
update train_2015_task_split set task_end_datetime =p_Crowd_Submit_Datetime;
update train_2015_task_split set task_end_datetime = max_submit_datetime
	where max_submit_datetime > p_Crowd_Submit_Datetime or p_Crowd_Submit_Datetime is null;
--设置任务结束时间
update train_2015_task_split set task_start_datetime = p_Release_Datetime;
update train_2015_task_split set task_start_datetime=min_submit_datetime
	where task_start_datetime>min_submit_datetime ; 
--更新任务周期
update train_2015_task_split set task_days=DATEDIFF(task_end_datetime ,task_start_datetime)+1;

update piecework_f a,
	train_2015_task_split b
	set a.submit_days=DATEDIFF(a.submit_datetime,b.task_start_datetime)+1
	where a.task_id=b.task_id;

--获取 全部任务信息
create table train_2015_base_task
	as select a.task_id,
	b.first_catagory,
	a.task_start_datetime,
	a.task_end_datetime,
	a.task_days,
	b.release_user_id,
	b.price_level,
	b.total_amt,
	b.task_Mode
	from train_2015_task_split a
	left join task b on a.task_id = b.task_id
	where a.task_end_datetime>='2015-01-01'
	and a.task_end_datetime<'2016-01-01';
create index idx_task_id on train_2015_base_task(task_id);
alter table train_2015_base_task add column category int(11);
update train_2015_base_task b
	set category = case when b.first_catagory='UI设计'  then 0 
						when b.first_catagory='动画漫画'  then 1 
		 				when b.first_catagory='品牌设计'  then 2 
		 				when b.first_catagory='摄影摄像'  then 3 
		 				when b.first_catagory='文案策划'  then 4 
		 				when b.first_catagory='网站建设'  then 5 
		 				when b.first_catagory='装修服务'  then 6 
		 				when b.first_catagory='起名取名'  then 7 
		 				when b.first_catagory='软件开发'  then 8 
		 				when b.first_catagory='电商服务'  then 9 end ;

--获取全部稿件信息
create table train_2015_base_piecework as 
	select b.piecework_id,
		a.task_id,
		b.user_id,
		a.release_user_id,
		b.work_quality,
		100 as reward_amt,
		b.ability_level_int,
		b.ability_value_int,
		b.special_customer_type,
		b.fuwubao,
		b.recomment_employ,
		b.recommend_customer,
		a.first_catagory,
		a.task_start_datetime,
		a.task_end_datetime,
		a.task_days,
		b.submit_days,
		b.submit_datetime,
		a.price_level,
		a.total_amt,
		a.task_Mode
from train_2015_base_task a
left join piecework_f b on a.task_id=b.task_id
order by a.task_id asc, b.piecework_id asc
;


create index idx_task_id on train_2015_base_piecework(task_Id);
create index idx_user_id on train_2015_base_piecework(user_id);
create index idx_piecework_id on train_2015_base_piecework(piecework_id);
create index idx_release_user_id on train_2015_base_piecework(release_user_id,user_id);

update train_2015_base_piecework a,  piecework_f b
	set a.submit_days=b.submit_days
	where a.piecework_id=b.piecework_id;
--user 和 requester
--create table train_2015_ever_meet_in_train 
--	as select distinct release_user_id, user_id
--	from train_2015_base_piecework
--	where task_end_datetime>='2015-01-01'
--	and task_end_datetime<'2016-01-01';
--create table train_2015_ever_meet_in_test 
--	as select distinct release_user_id, user_id
--	from train_2015_base_piecework
--	where task_end_datetime>='2016-01-01'
--	and task_end_datetime<'2016-01-01';
--create index idx_release_user_id on train_2015_ever_meet_in_train(release_user_id,user_id);
--create index idx_release_user_id on train_2015_ever_meet_in_test(release_user_id,user_id);
--create table train_2015_base_ever_met
--	as select distinct a.release_user_id,a.user_id
--	from train_2015_ever_meet_in_test a
--	left join train_2015_ever_meet_in_train b 
--	on a.release_user_id=b.release_user_id and a.user_id=b.user_id
--	where b.release_user_id is not null
--	and b.user_id is not null;
--create index idx_release_user_id on train_2015_base_ever_met(release_user_id,user_id);

--创建 已有用户数据 索引
create table train_2015_base_user_id
	as select distinct user_id  from train_2015_base_piecework b
	where b.task_end_datetime>='2015-01-01' and b.task_end_datetime<'2016-01-01';
create index idx_user_id on train_2015_base_user_id(user_id);

--创建用户数据表
--类目顺序 动画漫画--1;品牌设计--2;摄影摄像--3;文案策划--4;网站建设--5;装修服务--6;起名取名--7;软件开发--8
create table train_2015_worker_summary
	as select a.user_id,
	count(distinct b.first_catagory) task_cate_ct, 
	count(distinct b.task_id) task_ct, 
	count(distinct b.piecework_id) piecework_ct,
	sum(case when b.first_catagory='UI设计'   then 1 else 0 end) as c0_piecework_ct,
	sum(case when b.first_catagory='动画漫画'  then 1 else 0 end) as c1_piecework_ct,
	sum(case when b.first_catagory='品牌设计'  then 1 else 0 end) as c2_piecework_ct,
	sum(case when b.first_catagory='摄影摄像'  then 1 else 0 end) as c3_piecework_ct,
	sum(case when b.first_catagory='文案策划'  then 1 else 0 end) as c4_piecework_ct,
	sum(case when b.first_catagory='网站建设'  then 1 else 0 end) as c5_piecework_ct,
	sum(case when b.first_catagory='装修服务'  then 1 else 0 end) as c6_piecework_ct,
	sum(case when b.first_catagory='起名取名'  then 1 else 0 end) as c7_piecework_ct,
	sum(case when b.first_catagory='软件开发'  then 1 else 0 end) as c8_piecework_ct,
	sum(case when b.first_catagory='电商服务'  then 1 else 0 end) as c9_piecework_ct,
	sum(case when b.first_catagory='UI设计'   then 1 else 0 end)/count(distinct b.piecework_id) as c_piecework_ct_rate,
	sum(case when b.first_catagory='动画漫画'  then 1 else 0 end)/count(distinct b.piecework_id) as c1_piecework_ct_rate,
	sum(case when b.first_catagory='品牌设计'  then 1 else 0 end)/count(distinct b.piecework_id) as c2_piecework_ct_rate,
	sum(case when b.first_catagory='摄影摄像'  then 1 else 0 end)/count(distinct b.piecework_id) as c3_piecework_ct_rate,
	sum(case when b.first_catagory='文案策划'  then 1 else 0 end)/count(distinct b.piecework_id) as c4_piecework_ct_rate,
	sum(case when b.first_catagory='网站建设'  then 1 else 0 end)/count(distinct b.piecework_id) as c5_piecework_ct_rate,
	sum(case when b.first_catagory='装修服务'  then 1 else 0 end)/count(distinct b.piecework_id) as c6_piecework_ct_rate,
	sum(case when b.first_catagory='起名取名'  then 1 else 0 end)/count(distinct b.piecework_id) as c7_piecework_ct_rate,
	sum(case when b.first_catagory='软件开发'  then 1 else 0 end)/count(distinct b.piecework_id) as c8_piecework_ct_rate,
	sum(case when b.first_catagory='电商服务'  then 1 else 0 end)/count(distinct b.piecework_id) as c9_piecework_ct_rate,
	sum(case when b.price_level=1  then 1 else 0 end) as p1_piecework_ct,
	sum(case when b.price_level=2  then 1 else 0 end) as p2_piecework_ct,
	sum(case when b.price_level=3  then 1 else 0 end) as p3_piecework_ct,
	sum(case when b.price_level=4  then 1 else 0 end) as p4_piecework_ct,
	sum(case when b.price_level=5  then 1 else 0 end) as p5_piecework_ct,
	sum(case when b.price_level=1  then 1 else 0 end)/count(distinct b.piecework_id) as p1_piecework_ct_rate,
	sum(case when b.price_level=2  then 1 else 0 end)/count(distinct b.piecework_id) as p2_piecework_ct_rate,
	sum(case when b.price_level=3  then 1 else 0 end)/count(distinct b.piecework_id) as p3_piecework_ct_rate,
	sum(case when b.price_level=4  then 1 else 0 end)/count(distinct b.piecework_id) as p4_piecework_ct_rate,
	sum(case when b.price_level=5  then 1 else 0 end)/count(distinct b.piecework_id) as p5_piecework_ct_rate,
	max(b.ability_value_int) ability_value_int,
	max(b.ability_level_int) ability_level_int,
	max(b.special_customer_type) as special_customer_type,
	max(b.fuwubao) as fuwubao,
	max(b.recomment_employ) as recomment_employ,
	max(b.recommend_customer) as recommend_customer,
	max(b.submit_datetime) as max_submit_datetime,
	max(b.piecework_id) as max_piecework_id
	from train_2015_base_user_id a
	left join train_2015_base_piecework b 
	on a.user_id =b.user_id and b.task_end_datetime>='2015-01-01' and b.task_end_datetime<'2016-01-01'
	group by a.user_id;
alter table train_2015_worker_summary modify column fuwubao int(5);
alter table train_2015_worker_summary modify column recomment_employ int(5);
create index idx_user_id on train_2015_worker_summary(user_id);
create index idx_piecework_id on train_2015_worker_summary(max_piecework_id);
--创建
select user_id,piecework_ct from train_2015_worker_summary where piecework_ct=5 order by piecework_ct desc limit 5;
--创建排序记录
create table train_2015_worker_price_rank as 
select piecework_id,user_id,total_amt,price_level, rank  from
(	select t1.piecework_id,t1.user_id,t1.total_amt,t1.price_level,@rownum:=@rownum+1,
		case when @puser_id=t1.user_id then @rank:=@rank+1 else @rank:=1 end as rank,
		@puser_id:=t1.user_id,
		@rownum as row_num
		from
	(	(	select piecework_id,user_id,total_amt,price_level from train_2015_base_piecework
				where  task_end_datetime>='2015-01-01' and task_end_datetime<'2016-01-01'
				order by user_id asc, total_amt asc
		) t1,
		(select @rownum:=0, @rank:=0, @puser_id=null
		) t2
	)
) result;	
create index idx_user_id on train_2015_worker_price_rank(user_id);
alter table train_2015_worker_summary add column median_price int(11);
alter table train_2015_worker_summary add column median_price_level int(2);
--根据rank 更新 median 数据
update train_2015_worker_summary a, train_2015_worker_price_rank b
	set a.median_price= b.total_amt
	, a.median_price_level=b.price_level
	where a.user_id = b.user_id
	and ceil(a.piecework_ct/2)=b.rank;
--增加 efficiency  和 quality  相关信息
alter table train_2015_worker_summary add column 7d_work_ct_all    int(11);
alter table train_2015_worker_summary add column 7d_work_ct_all_c1 int(11);
alter table train_2015_worker_summary add column 7d_work_ct_all_c2 int(11);
alter table train_2015_worker_summary add column 7d_work_ct_all_c3 int(11);
alter table train_2015_worker_summary add column 7d_work_ct_all_c4 int(11);
alter table train_2015_worker_summary add column 7d_work_ct_all_c5 int(11);
alter table train_2015_worker_summary add column 7d_work_ct_all_c6 int(11);
alter table train_2015_worker_summary add column 7d_work_ct_all_c7 int(11);
alter table train_2015_worker_summary add column 7d_work_ct_all_c8 int(11);
alter table train_2015_worker_summary add column 7d_work_ct_all_p1 int(11);
alter table train_2015_worker_summary add column 7d_work_ct_all_p2 int(11);
alter table train_2015_worker_summary add column 7d_work_ct_all_p3 int(11);
alter table train_2015_worker_summary add column 7d_work_ct_all_p4 int(11);
alter table train_2015_worker_summary add column 7d_work_ct_all_p5 int(11);
alter table train_2015_worker_summary add column 14d_work_ct_all    int(11);
alter table train_2015_worker_summary add column 14d_work_ct_all_c1 int(11);
alter table train_2015_worker_summary add column 14d_work_ct_all_c2 int(11);
alter table train_2015_worker_summary add column 14d_work_ct_all_c3 int(11);
alter table train_2015_worker_summary add column 14d_work_ct_all_c4 int(11);
alter table train_2015_worker_summary add column 14d_work_ct_all_c5 int(11);
alter table train_2015_worker_summary add column 14d_work_ct_all_c6 int(11);
alter table train_2015_worker_summary add column 14d_work_ct_all_c7 int(11);
alter table train_2015_worker_summary add column 14d_work_ct_all_c8 int(11);
alter table train_2015_worker_summary add column 14d_work_ct_all_p1 int(11);
alter table train_2015_worker_summary add column 14d_work_ct_all_p2 int(11);
alter table train_2015_worker_summary add column 14d_work_ct_all_p3 int(11);
alter table train_2015_worker_summary add column 14d_work_ct_all_p4 int(11);
alter table train_2015_worker_summary add column 14d_work_ct_all_p5 int(11);
alter table train_2015_worker_summary add column 30d_work_ct_all    int(11);
alter table train_2015_worker_summary add column 30d_work_ct_all_c1 int(11);
alter table train_2015_worker_summary add column 30d_work_ct_all_c2 int(11);
alter table train_2015_worker_summary add column 30d_work_ct_all_c3 int(11);
alter table train_2015_worker_summary add column 30d_work_ct_all_c4 int(11);
alter table train_2015_worker_summary add column 30d_work_ct_all_c5 int(11);
alter table train_2015_worker_summary add column 30d_work_ct_all_c6 int(11);
alter table train_2015_worker_summary add column 30d_work_ct_all_c7 int(11);
alter table train_2015_worker_summary add column 30d_work_ct_all_c8 int(11);
alter table train_2015_worker_summary add column 30d_work_ct_all_p1 int(11);
alter table train_2015_worker_summary add column 30d_work_ct_all_p2 int(11);
alter table train_2015_worker_summary add column 30d_work_ct_all_p3 int(11);
alter table train_2015_worker_summary add column 30d_work_ct_all_p4 int(11);
alter table train_2015_worker_summary add column 30d_work_ct_all_p5 int(11);

update train_2015_worker_summary a,
    ( select t1.user_id 
    	,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=7  then 1 else 0 end) as 7d_work_ct_all    
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=7 and t2.first_catagory='动画漫画' then 1 else 0 end) as 7d_work_ct_all_c1 
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=7 and t2.first_catagory='品牌设计' then 1 else 0 end) as 7d_work_ct_all_c2 
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=7 and t2.first_catagory='摄影摄像' then 1 else 0 end) as 7d_work_ct_all_c3 
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=7 and t2.first_catagory='文案策划' then 1 else 0 end) as 7d_work_ct_all_c4 
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=7 and t2.first_catagory='网站建设' then 1 else 0 end) as 7d_work_ct_all_c5 
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=7 and t2.first_catagory='装修服务' then 1 else 0 end) as 7d_work_ct_all_c6 
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=7 and t2.first_catagory='起名取名' then 1 else 0 end) as 7d_work_ct_all_c7 
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=7 and t2.first_catagory='软件开发' then 1 else 0 end) as 7d_work_ct_all_c8 
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=7 and t2.price_level=1 then 1 else 0 end) as 7d_work_ct_all_p1 
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=7 and t2.price_level=2 then 1 else 0 end) as 7d_work_ct_all_p2 
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=7 and t2.price_level=3 then 1 else 0 end) as 7d_work_ct_all_p3 
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=7 and t2.price_level=4 then 1 else 0 end) as 7d_work_ct_all_p4 
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=7 and t2.price_level=5 then 1 else 0 end) as 7d_work_ct_all_p5 
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=14 then 1 else 0 end) as 14d_work_ct_all   
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=14 and t2.first_catagory='动画漫画' then 1 else 0 end) as 14d_work_ct_all_c1
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=14 and t2.first_catagory='品牌设计' then 1 else 0 end) as 14d_work_ct_all_c2
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=14 and t2.first_catagory='摄影摄像' then 1 else 0 end) as 14d_work_ct_all_c3
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=14 and t2.first_catagory='文案策划' then 1 else 0 end) as 14d_work_ct_all_c4
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=14 and t2.first_catagory='网站建设' then 1 else 0 end) as 14d_work_ct_all_c5
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=14 and t2.first_catagory='装修服务' then 1 else 0 end) as 14d_work_ct_all_c6
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=14 and t2.first_catagory='起名取名' then 1 else 0 end) as 14d_work_ct_all_c7
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=14 and t2.first_catagory='软件开发' then 1 else 0 end) as 14d_work_ct_all_c8
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=14 and t2.price_level=1 then 1 else 0 end) as 14d_work_ct_all_p1
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=14 and t2.price_level=2 then 1 else 0 end) as 14d_work_ct_all_p2
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=14 and t2.price_level=3 then 1 else 0 end) as 14d_work_ct_all_p3
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=14 and t2.price_level=4 then 1 else 0 end) as 14d_work_ct_all_p4
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=14 and t2.price_level=5 then 1 else 0 end) as 14d_work_ct_all_p5
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=30 then 1 else 0 end) as 30d_work_ct_all   
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=30 and t2.first_catagory='动画漫画' then 1 else 0 end) as 30d_work_ct_all_c1
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=30 and t2.first_catagory='品牌设计' then 1 else 0 end) as 30d_work_ct_all_c2
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=30 and t2.first_catagory='摄影摄像' then 1 else 0 end) as 30d_work_ct_all_c3
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=30 and t2.first_catagory='文案策划' then 1 else 0 end) as 30d_work_ct_all_c4
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=30 and t2.first_catagory='网站建设' then 1 else 0 end) as 30d_work_ct_all_c5
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=30 and t2.first_catagory='装修服务' then 1 else 0 end) as 30d_work_ct_all_c6
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=30 and t2.first_catagory='起名取名' then 1 else 0 end) as 30d_work_ct_all_c7
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=30 and t2.first_catagory='软件开发' then 1 else 0 end) as 30d_work_ct_all_c8
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=30 and t2.price_level=1 then 1 else 0 end) as 30d_work_ct_all_p1
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=30 and t2.price_level=2 then 1 else 0 end) as 30d_work_ct_all_p2
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=30 and t2.price_level=3 then 1 else 0 end) as 30d_work_ct_all_p3
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=30 and t2.price_level=4 then 1 else 0 end) as 30d_work_ct_all_p4
		,sum(case when DATEDIFF(t1.max_submit_datetime,t2.submit_datetime)<=30 and t2.price_level=5 then 1 else 0 end) as 30d_work_ct_all_p5
	from train_2015_worker_summary t1
	left join train_2015_base_piecework t2 on t1.user_id=t2.user_id and t2.task_end_datetime<'2016-01-01'
	group by t1.user_id
	) b
set  a.7d_work_ct_all     = b.7d_work_ct_all    
	,a.7d_work_ct_all_c1  = b.7d_work_ct_all_c1 
	,a.7d_work_ct_all_c2  = b.7d_work_ct_all_c2 
	,a.7d_work_ct_all_c3  = b.7d_work_ct_all_c3 
	,a.7d_work_ct_all_c4  = b.7d_work_ct_all_c4 
	,a.7d_work_ct_all_c5  = b.7d_work_ct_all_c5 
	,a.7d_work_ct_all_c6  = b.7d_work_ct_all_c6 
	,a.7d_work_ct_all_c7  = b.7d_work_ct_all_c7 
	,a.7d_work_ct_all_c8  = b.7d_work_ct_all_c8 
	,a.7d_work_ct_all_p1  = b.7d_work_ct_all_p1 
	,a.7d_work_ct_all_p2  = b.7d_work_ct_all_p2 
	,a.7d_work_ct_all_p3  = b.7d_work_ct_all_p3 
	,a.7d_work_ct_all_p4  = b.7d_work_ct_all_p4 
	,a.7d_work_ct_all_p5  = b.7d_work_ct_all_p5 
	,a.14d_work_ct_all    = b.14d_work_ct_all   
	,a.14d_work_ct_all_c1 = b.14d_work_ct_all_c1
	,a.14d_work_ct_all_c2 = b.14d_work_ct_all_c2
	,a.14d_work_ct_all_c3 = b.14d_work_ct_all_c3
	,a.14d_work_ct_all_c4 = b.14d_work_ct_all_c4
	,a.14d_work_ct_all_c5 = b.14d_work_ct_all_c5
	,a.14d_work_ct_all_c6 = b.14d_work_ct_all_c6
	,a.14d_work_ct_all_c7 = b.14d_work_ct_all_c7
	,a.14d_work_ct_all_c8 = b.14d_work_ct_all_c8
	,a.14d_work_ct_all_p1 = b.14d_work_ct_all_p1
	,a.14d_work_ct_all_p2 = b.14d_work_ct_all_p2
	,a.14d_work_ct_all_p3 = b.14d_work_ct_all_p3
	,a.14d_work_ct_all_p4 = b.14d_work_ct_all_p4
	,a.14d_work_ct_all_p5 = b.14d_work_ct_all_p5
	,a.30d_work_ct_all    = b.30d_work_ct_all   
	,a.30d_work_ct_all_c1 = b.30d_work_ct_all_c1
	,a.30d_work_ct_all_c2 = b.30d_work_ct_all_c2
	,a.30d_work_ct_all_c3 = b.30d_work_ct_all_c3
	,a.30d_work_ct_all_c4 = b.30d_work_ct_all_c4
	,a.30d_work_ct_all_c5 = b.30d_work_ct_all_c5
	,a.30d_work_ct_all_c6 = b.30d_work_ct_all_c6
	,a.30d_work_ct_all_c7 = b.30d_work_ct_all_c7
	,a.30d_work_ct_all_c8 = b.30d_work_ct_all_c8
	,a.30d_work_ct_all_p1 = b.30d_work_ct_all_p1
	,a.30d_work_ct_all_p2 = b.30d_work_ct_all_p2
	,a.30d_work_ct_all_p3 = b.30d_work_ct_all_p3
	,a.30d_work_ct_all_p4 = b.30d_work_ct_all_p4
	,a.30d_work_ct_all_p5 = b.30d_work_ct_all_p5 
where a.user_id =b.user_id;
--更新质量参数
alter table train_2015_worker_summary add column num_suc_work_ct_all    int(11);
alter table train_2015_worker_summary add column num_suc_work_ct_all_c1 int(11);
alter table train_2015_worker_summary add column num_suc_work_ct_all_c2 int(11);
alter table train_2015_worker_summary add column num_suc_work_ct_all_c3 int(11);
alter table train_2015_worker_summary add column num_suc_work_ct_all_c4 int(11);
alter table train_2015_worker_summary add column num_suc_work_ct_all_c5 int(11);
alter table train_2015_worker_summary add column num_suc_work_ct_all_c6 int(11);
alter table train_2015_worker_summary add column num_suc_work_ct_all_c7 int(11);
alter table train_2015_worker_summary add column num_suc_work_ct_all_c8 int(11);
alter table train_2015_worker_summary add column num_suc_work_ct_all_p1 int(11);
alter table train_2015_worker_summary add column num_suc_work_ct_all_p2 int(11);
alter table train_2015_worker_summary add column num_suc_work_ct_all_p3 int(11);
alter table train_2015_worker_summary add column num_suc_work_ct_all_p4 int(11);
alter table train_2015_worker_summary add column num_suc_work_ct_all_p5 int(11);

alter table train_2015_worker_summary add column num_cost_work_ct_all    int(11);
alter table train_2015_worker_summary add column num_cost_work_ct_all_c1 int(11);
alter table train_2015_worker_summary add column num_cost_work_ct_all_c2 int(11);
alter table train_2015_worker_summary add column num_cost_work_ct_all_c3 int(11);
alter table train_2015_worker_summary add column num_cost_work_ct_all_c4 int(11);
alter table train_2015_worker_summary add column num_cost_work_ct_all_c5 int(11);
alter table train_2015_worker_summary add column num_cost_work_ct_all_c6 int(11);
alter table train_2015_worker_summary add column num_cost_work_ct_all_c7 int(11);
alter table train_2015_worker_summary add column num_cost_work_ct_all_c8 int(11);
alter table train_2015_worker_summary add column num_cost_work_ct_all_p1 int(11);
alter table train_2015_worker_summary add column num_cost_work_ct_all_p2 int(11);
alter table train_2015_worker_summary add column num_cost_work_ct_all_p3 int(11);
alter table train_2015_worker_summary add column num_cost_work_ct_all_p4 int(11);
alter table train_2015_worker_summary add column num_cost_work_ct_all_p5 int(11);

alter table train_2015_worker_summary add column suc_rate_all    decimal(14,4);
alter table train_2015_worker_summary add column suc_rate_all_c1 decimal(14,4);
alter table train_2015_worker_summary add column suc_rate_all_c2 decimal(14,4);
alter table train_2015_worker_summary add column suc_rate_all_c3 decimal(14,4);
alter table train_2015_worker_summary add column suc_rate_all_c4 decimal(14,4);
alter table train_2015_worker_summary add column suc_rate_all_c5 decimal(14,4);
alter table train_2015_worker_summary add column suc_rate_all_c6 decimal(14,4);
alter table train_2015_worker_summary add column suc_rate_all_c7 decimal(14,4);
alter table train_2015_worker_summary add column suc_rate_all_c8 decimal(14,4);
alter table train_2015_worker_summary add column suc_rate_all_p1 decimal(14,4);
alter table train_2015_worker_summary add column suc_rate_all_p2 decimal(14,4);
alter table train_2015_worker_summary add column suc_rate_all_p3 decimal(14,4);
alter table train_2015_worker_summary add column suc_rate_all_p4 decimal(14,4);
alter table train_2015_worker_summary add column suc_rate_all_p5 decimal(14,4);

update train_2015_worker_summary a
    left join ( select t1.user_id 
    	,sum(case when (t2.work_quality ='中标' or t2.work_quality like '%等奖')  then 1 else 0 end) as num_suc_work_ct_all    
		,sum(case when (t2.work_quality ='中标' or t2.work_quality like '%等奖') and t2.first_catagory='动画漫画' then 1 else 0 end) as num_suc_work_ct_all_c1 
		,sum(case when (t2.work_quality ='中标' or t2.work_quality like '%等奖') and t2.first_catagory='品牌设计' then 1 else 0 end) as num_suc_work_ct_all_c2 
		,sum(case when (t2.work_quality ='中标' or t2.work_quality like '%等奖') and t2.first_catagory='摄影摄像' then 1 else 0 end) as num_suc_work_ct_all_c3 
		,sum(case when (t2.work_quality ='中标' or t2.work_quality like '%等奖') and t2.first_catagory='文案策划' then 1 else 0 end) as num_suc_work_ct_all_c4 
		,sum(case when (t2.work_quality ='中标' or t2.work_quality like '%等奖') and t2.first_catagory='网站建设' then 1 else 0 end) as num_suc_work_ct_all_c5 
		,sum(case when (t2.work_quality ='中标' or t2.work_quality like '%等奖') and t2.first_catagory='装修服务' then 1 else 0 end) as num_suc_work_ct_all_c6 
		,sum(case when (t2.work_quality ='中标' or t2.work_quality like '%等奖') and t2.first_catagory='起名取名' then 1 else 0 end) as num_suc_work_ct_all_c7 
		,sum(case when (t2.work_quality ='中标' or t2.work_quality like '%等奖') and t2.first_catagory='软件开发' then 1 else 0 end) as num_suc_work_ct_all_c8 
		,sum(case when (t2.work_quality ='中标' or t2.work_quality like '%等奖') and t2.price_level=1 then 1 else 0 end) as num_suc_work_ct_all_p1 
		,sum(case when (t2.work_quality ='中标' or t2.work_quality like '%等奖') and t2.price_level=2 then 1 else 0 end) as num_suc_work_ct_all_p2 
		,sum(case when (t2.work_quality ='中标' or t2.work_quality like '%等奖') and t2.price_level=3 then 1 else 0 end) as num_suc_work_ct_all_p3 
		,sum(case when (t2.work_quality ='中标' or t2.work_quality like '%等奖') and t2.price_level=4 then 1 else 0 end) as num_suc_work_ct_all_p4 
		,sum(case when (t2.work_quality ='中标' or t2.work_quality like '%等奖') and t2.price_level=5 then 1 else 0 end) as num_suc_work_ct_all_p5 
		from train_2015_worker_summary t1
	left join train_2015_base_piecework t2 on t1.user_id=t2.user_id and t2.task_end_datetime<'2016-01-01'
	group by t1.user_id
	) b on a.user_id = b.user_id
set  a.num_suc_work_ct_all     = b.num_suc_work_ct_all    
	,a.num_suc_work_ct_all_c1  = b.num_suc_work_ct_all_c1 
	,a.num_suc_work_ct_all_c2  = b.num_suc_work_ct_all_c2 
	,a.num_suc_work_ct_all_c3  = b.num_suc_work_ct_all_c3 
	,a.num_suc_work_ct_all_c4  = b.num_suc_work_ct_all_c4 
	,a.num_suc_work_ct_all_c5  = b.num_suc_work_ct_all_c5 
	,a.num_suc_work_ct_all_c6  = b.num_suc_work_ct_all_c6 
	,a.num_suc_work_ct_all_c7  = b.num_suc_work_ct_all_c7 
	,a.num_suc_work_ct_all_c8  = b.num_suc_work_ct_all_c8 
	,a.num_suc_work_ct_all_p1  = b.num_suc_work_ct_all_p1 
	,a.num_suc_work_ct_all_p2  = b.num_suc_work_ct_all_p2 
	,a.num_suc_work_ct_all_p3  = b.num_suc_work_ct_all_p3 
	,a.num_suc_work_ct_all_p4  = b.num_suc_work_ct_all_p4 
	,a.num_suc_work_ct_all_p5  = b.num_suc_work_ct_all_p5 
;
update train_2015_worker_summary t
	set  t.num_cost_work_ct_all    = t.num_suc_work_ct_all   *2 - t.piecework_ct
		,t.num_cost_work_ct_all_c1 = t.num_suc_work_ct_all_c1*2 - t.piecework_ct
		,t.num_cost_work_ct_all_c2 = t.num_suc_work_ct_all_c2*2 - t.piecework_ct
		,t.num_cost_work_ct_all_c3 = t.num_suc_work_ct_all_c3*2 - t.piecework_ct
		,t.num_cost_work_ct_all_c4 = t.num_suc_work_ct_all_c4*2 - t.piecework_ct
		,t.num_cost_work_ct_all_c5 = t.num_suc_work_ct_all_c5*2 - t.piecework_ct
		,t.num_cost_work_ct_all_c6 = t.num_suc_work_ct_all_c6*2 - t.piecework_ct
		,t.num_cost_work_ct_all_c7 = t.num_suc_work_ct_all_c7*2 - t.piecework_ct
		,t.num_cost_work_ct_all_c8 = t.num_suc_work_ct_all_c8*2 - t.piecework_ct
		,t.num_cost_work_ct_all_p1 = t.num_suc_work_ct_all_p1*2 - t.piecework_ct
		,t.num_cost_work_ct_all_p2 = t.num_suc_work_ct_all_p2*2 - t.piecework_ct
		,t.num_cost_work_ct_all_p3 = t.num_suc_work_ct_all_p3*2 - t.piecework_ct
		,t.num_cost_work_ct_all_p4 = t.num_suc_work_ct_all_p4*2 - t.piecework_ct
		,t.num_cost_work_ct_all_p5 = t.num_suc_work_ct_all_p5*2 - t.piecework_ct
;
update train_2015_worker_summary t
	set  t.suc_rate_all    = t.num_suc_work_ct_all   /t.piecework_ct
		,t.suc_rate_all_c1 = t.num_suc_work_ct_all_c1/t.piecework_ct
		,t.suc_rate_all_c2 = t.num_suc_work_ct_all_c2/t.piecework_ct
		,t.suc_rate_all_c3 = t.num_suc_work_ct_all_c3/t.piecework_ct
		,t.suc_rate_all_c4 = t.num_suc_work_ct_all_c4/t.piecework_ct
		,t.suc_rate_all_c5 = t.num_suc_work_ct_all_c5/t.piecework_ct
		,t.suc_rate_all_c6 = t.num_suc_work_ct_all_c6/t.piecework_ct
		,t.suc_rate_all_c7 = t.num_suc_work_ct_all_c7/t.piecework_ct
		,t.suc_rate_all_c8 = t.num_suc_work_ct_all_c8/t.piecework_ct
		,t.suc_rate_all_p1 = t.num_suc_work_ct_all_p1/t.piecework_ct
		,t.suc_rate_all_p2 = t.num_suc_work_ct_all_p2/t.piecework_ct
		,t.suc_rate_all_p3 = t.num_suc_work_ct_all_p3/t.piecework_ct
		,t.suc_rate_all_p4 = t.num_suc_work_ct_all_p4/t.piecework_ct
		,t.suc_rate_all_p5 = t.num_suc_work_ct_all_p5/t.piecework_ct
;
---------------------------worker部分完成------------------------------------------

---------------------------piecework部分开始---------------------------------------
create table train_2015_piecework_4train
as select  b.piecework_id,
b.user_id, 
b.release_user_id,
b.task_id,
b.ability_level_int,
0 as relative_reputation_rank,
0.0 as relative_reputation, ##need java to code or use piecework_rank 按照task来循环
b.submit_days,
b.submit_datetime,
0 as submit_rank,##need java to code
0.0 as relative_submit_rank, ##b.submit_rank/count(1)
0 as discrete_relative_submit_bin, ##bin
b.task_end_datetime, ## 时间截取位
b.work_quality
from  train_2015_base_piecework b ;
--不需要加时间，整体一起算起来，然后等需要用的时候根据时间来进行截取 
--where task_end_datetime>='2015-01-01' and task_end_datetime<'2016-01-01';
create index idx_piecework_id on train_2015_piecework_4train(piecework_id);
create index idx_task_id on train_2015_piecework_4train(task_id);
create index idx_user_id on train_2015_piecework_4train(user_id);
create index idx_release_user_id on train_2015_piecework_4train(release_user_id);
alter table train_2015_piecework_4train modify column relative_reputation_rank int(11);
alter table train_2015_piecework_4train modify column relative_reputation decimal(13,4);
alter table train_2015_piecework_4train modify column submit_rank int(11);
alter table train_2015_piecework_4train modify column relative_submit_rank decimal(13,4);
alter table train_2015_piecework_4train add column task_piece_ct int(11);
--更新rating信息
update train_2015_piecework_4train t1
	left join (	select a.piecework_id,
				sum(case when b.ability_level_int>a.ability_level_int then 1 else 0 end)+1 as relative_reputation_rank,
				sum(case when b.submit_datetime<a.submit_datetime then 1 else 0 end)+1 as submit_rank
				from train_2015_piecework_4train a
				left join train_2015_piecework_4train b on a.task_id = b.task_id
				group by a.piecework_id 
				) t2 on t1.piecework_id = t2.piecework_id
	set t1.relative_reputation_rank = t2.relative_reputation_rank
		, t1.submit_rank = t2.submit_rank;
##Query OK, 2334822 rows affected (51 min 57.27 sec)
--更新task信息
alter table train_2015_base_task add column task_piece_ct int(11);
alter table train_2015_base_task add column task_good_piece_ct int(11);
update train_2015_base_task a 
	left join (select task_id,
					 count(1) task_piece_ct,
					 sum(case when t.work_quality ='中标' or t.work_quality like '%等奖' then 1 else 0 end ) as task_good_piece_ct 
				from  train_2015_base_piecework t
				group by t.task_id
				)b on a.task_id = b.task_id
set a.task_piece_ct=b.task_piece_ct
,	a.task_good_piece_ct = b.task_good_piece_ct;
update train_2015_piecework_4train a
	left join train_2015_base_task b on a.task_id=b.task_id
	set a.task_piece_ct = b.task_piece_ct;
update train_2015_piecework_4train a
	set a.relative_reputation =a.relative_reputation_rank/a.task_piece_ct
	,a.relative_submit_rank=a.submit_rank/a.task_piece_ct;
-- discrete_relative_submit_bin
--需要更新submit_days
update train_2015_piecework_4train a
	left join train_2015_base_task b on a.task_id=b.task_id
	set a.discrete_relative_submit_bin=ceil(a.submit_days/b.task_days*10);

--为 piecework 增加 user
create index idx_release_user on train_2015_piecework_4train(release_user_id,user_id);
alter table train_2015_piecework_4train add column ever_met int(2) default 0;
update train_2015_piecework_4train t1,
	 ( select  distinct a.piecework_id
				from train_2015_piecework_4train a
				left join train_2015_piecework_4train b on a.release_user_id=b.release_user_id and a.user_id=b.user_id
				where a.submit_datetime>b.submit_datetime
				and (b.work_quality='中标' or b.work_quality like '%等奖')
				) t2 
	set t1.ever_met = 1  
	where t1.piecework_id=t2.piecework_id;
--work_quality 转换成 selected字段
alter table train_2015_piecework_4train add column selected int(1) default 0;
update train_2015_piecework_4train
	set selected =1
	where work_quality='中标' or work_quality like '%等奖';


--
alter table train_2015_piecework_4train add column task_c0 int(11);
alter table train_2015_piecework_4train add column task_c1 int(11);
alter table train_2015_piecework_4train add column task_c2 int(11);
alter table train_2015_piecework_4train add column task_c3 int(11);
alter table train_2015_piecework_4train add column task_c4 int(11);
alter table train_2015_piecework_4train add column task_c5 int(11);
alter table train_2015_piecework_4train add column task_c6 int(11);
alter table train_2015_piecework_4train add column task_c7 int(11);
alter table train_2015_piecework_4train add column task_c8 int(11);
alter table train_2015_piecework_4train add column task_c9 int(11);
alter table train_2015_piecework_4train add column task_p1 int(11);
alter table train_2015_piecework_4train add column task_p2 int(11);
alter table train_2015_piecework_4train add column task_p3 int(11);
alter table train_2015_piecework_4train add column task_p4 int(11);
alter table train_2015_piecework_4train add column task_p5 int(11);

update train_2015_piecework_4train a
	left join train_2015_base_task b on a.task_id=b.task_id
	set  task_c0 = case when b.first_catagory='UI设计'  then 1 else 0 end
		,task_c1 = case when b.first_catagory='动画漫画'  then 1 else 0 end
		,task_c2 = case when b.first_catagory='品牌设计'  then 1 else 0 end
		,task_c3 = case when b.first_catagory='摄影摄像'  then 1 else 0 end
		,task_c4 = case when b.first_catagory='文案策划'  then 1 else 0 end
		,task_c5 = case when b.first_catagory='网站建设'  then 1 else 0 end
		,task_c6 = case when b.first_catagory='装修服务'  then 1 else 0 end
		,task_c7 = case when b.first_catagory='起名取名'  then 1 else 0 end
		,task_c8 = case when b.first_catagory='软件开发'  then 1 else 0 end
		,task_c9 = case when b.first_catagory='电商服务'  then 1 else 0 end
		,task_p1 = case when b.price_level=1  then 1 else 0 end
		,task_p2 = case when b.price_level=2  then 1 else 0 end
		,task_p3 = case when b.price_level=3  then 1 else 0 end
		,task_p4 = case when b.price_level=4  then 1 else 0 end
		,task_p5 = case when b.price_level=5  then 1 else 0 end
	;
--增加程度表达
alter table train_2015_piecework_4train add column selected_value decimal(5,2);

update train_2015_piecework_4train 
	set selected_value = case when work_quality='中标' then 1
							  when work_quality='一等奖' then 1
							  when work_quality='二等奖' then 0.9
							  when work_quality='三等奖' then 0.8
							  when work_quality='四等奖' then 0.7
							  when work_quality='五等奖' then 0.6
							  when work_quality='备选' 	then 0.4
							  else 0 end;
							  
---------------------------piecework部分结束---------------------------------------
---------------------------requester部分开始---------------------------------------
create table train_2015_base_requester_choice as 
	select piecework_id, release_user_id, ability_level_int, 
	 relative_reputation, submit_days
	from train_2015_piecework_4train
	where task_end_datetime>='2015-01-01' and task_end_datetime<'2016-01-01'
		and work_quality ='中标' or work_quality like '%等奖';
alter table train_2015_base_requester_choice add column reputation_median_rank int(11);
alter table train_2015_base_requester_choice add column relative_reputation_median_rank int(11);
alter table train_2015_base_requester_choice add column submit_days_median_rank int(11);
--更新median数据
update train_2015_base_requester_choice a
	left join (	select t1.piecework_id,t1.release_user_id,t1.ability_level_int,@rownum:=@rownum+1,
		case when @prelease_user_id=t1.release_user_id then @rank:=@rank+1 else @rank:=1 end as rank,
		@prelease_user_id:=t1.release_user_id,
		@rownum as row_num
		from
	(	(	select piecework_id,release_user_id,ability_level_int from train_2015_base_requester_choice
				order by release_user_id asc, ability_level_int asc
		) t1,
		(select @rownum:=0, @rank:=0, @prelease_user_id=null
		) t2
	)
) b on a.piecework_id = b.piecework_id
	set a.reputation_median_rank = b.rank;

update train_2015_base_requester_choice a
	left join (	select t1.piecework_id,t1.release_user_id,t1.relative_reputation,@rownum:=@rownum+1,
		case when @prelease_user_id=t1.release_user_id then @rank:=@rank+1 else @rank:=1 end as rank,
		@prelease_user_id:=t1.release_user_id,
		@rownum as row_num
		from
	(	(	select piecework_id,release_user_id,relative_reputation from train_2015_base_requester_choice
				order by release_user_id asc, relative_reputation asc
		) t1,
		(select @rownum:=0, @rank:=0, @prelease_user_id=null
		) t2
	)
) b on a.piecework_id = b.piecework_id
	set a.relative_reputation_median_rank = b.rank;
update train_2015_base_requester_choice a
	left join (	select t1.piecework_id,t1.release_user_id,t1.submit_days,@rownum:=@rownum+1,
		case when @prelease_user_id=t1.release_user_id then @rank:=@rank+1 else @rank:=1 end as rank,
		@prelease_user_id:=t1.release_user_id,
		@rownum as row_num
		from
	(	(	select piecework_id,release_user_id,submit_days from train_2015_base_requester_choice
				order by release_user_id asc, submit_days asc
		) t1,
		(select @rownum:=0, @rank:=0, @prelease_user_id=null
		) t2
	)
) b on a.piecework_id = b.piecework_id
	set a.submit_days_median_rank = b.rank;
create index idx_release_user_id on train_2015_base_requester_choice(release_user_id);
create index idx_piecework_id on train_2015_base_requester_choice(piecework_id);
--最终的 requester 数据
create table train_2015_base_requester_choice_summary as 
	select release_user_id,
		count(1) as select_piecework_ct,
		sum(ability_level_int)/count(1) as mean_selected_reputation,
		0 as median_selected_reputation,
		sum(relative_reputation)/count(1) as mean_selected_relateive_reputation,
		0 as median_selected_relateive_reputation,
		sum(submit_days)/count(1) as mean_selected_submit_days,
		0 as median_selected_submit_days
		from train_2015_base_requester_choice group by release_user_id;
alter table train_2015_base_requester_choice_summary modify  column median_selected_reputation           int(11);
alter table train_2015_base_requester_choice_summary modify  column median_selected_relateive_reputation decimal(11,6);
alter table train_2015_base_requester_choice_summary modify  column median_selected_submit_days          int(11);
create index idx_release_user_id on train_2015_base_requester_choice_summary(release_user_id);
update train_2015_base_requester_choice_summary a , train_2015_base_requester_choice b 
	set a.median_selected_reputation = b.ability_level_int
	 where a.release_user_id=b.release_user_id and 
	 ceil(a.select_piecework_ct/2)=b.reputation_median_rank;
update train_2015_base_requester_choice_summary a , train_2015_base_requester_choice b 
	set a.median_selected_relateive_reputation = b.relative_reputation
	 where a.release_user_id=b.release_user_id and 
	 ceil(a.select_piecework_ct/2)=b.relative_reputation_median_rank;
update train_2015_base_requester_choice_summary a , train_2015_base_requester_choice b 
	set a.median_selected_submit_days = b.submit_days
	 where a.release_user_id=b.release_user_id and 
	 ceil(a.select_piecework_ct/2)=b.submit_days_median_rank;

alter table train_2015_base_requester_choice_summary modify release_user_id int(11);
---------------------------requester部分结束---------------------------------------
alter table train_2015_piecework_4train add column work_quality_random int(3);
alter table train_2015_piecework_4train add column work_quality_higher int(3);
alter table train_2015_piecework_4train add column work_quality_suc_rate int(3);
alter table train_2015_piecework_4train add column work_quality_suc_rate_cate int(3);
update train_2015_piecework_4train set work_quality_random =0;
update train_2015_piecework_4train set work_quality_higher =0;	
update train_2015_piecework_4train set work_quality_suc_rate =0;	
update train_2015_piecework_4train set work_quality_suc_rate_cate =0;	
select count(1),count(distinct task_id),sum(selected),
sum(work_quality_random),sum(work_quality_higher),
sum(work_quality_suc_rate),sum(work_quality_suc_rate_cate) 
from train_2015_piecework_4train 
where task_end_datetime>='2016-01-01' and task_end_datetime<'2016-01-01' ;
---------------------------组合获取，选择sql。 暂缓----------------------------------
---------------------------不同原则选择稿件----------------------------------------------
--where task_id in ('6142269','6142344','6142516')
--随机选择
update train_2015_piecework_4train a,
	 (	select t1.piecework_id,t1.task_id,@rownum:=@rownum+1,
			case when @ptask_id=t1.task_id then @rank:=@rank+1 else @rank:=1 end as rank,
			@ptask_id:=t1.task_id,
			@rownum as row_num
			from
		(	(	select m1.piecework_id,m1.task_id from train_2015_piecework_4train m1
			left join train_2015_worker_summary m2 on m1.user_id=m2.user_id
					order by m1.task_id asc, rand()
			) t1,
			(select @rownum:=0, @rank:=0, @ptask_id=null
			) t2
		)
	) b ,
	 train_2015_base_task c
	set a.work_quality_higher = 1
	where a.piecework_id=b.piecework_id 
	and b.task_id=c.task_id
	and b.rank<=c.task_good_piece_ct;
--按照reputation最高进行选择
update train_2015_piecework_4train a,
	 (	select t1.piecework_id,t1.task_id,t1.ability_level_int,@rownum:=@rownum+1,
			case when @ptask_id=t1.task_id then @rank:=@rank+1 else @rank:=1 end as rank,
			@ptask_id:=t1.task_id,
			@rownum as row_num
			from
		(	(	select piecework_id,task_id,ability_level_int from train_2015_piecework_4train
					order by task_id asc, ability_level_int desc
			) t1,
			(select @rownum:=0, @rank:=0, @ptask_id=null
			) t2
		)
	) b ,
	 train_2015_base_task c
	set a.work_quality_higher = 1
	where a.piecework_id=b.piecework_id 
	and b.task_id=c.task_id
	and b.rank<=c.task_good_piece_ct;
--根据成功率计算
update train_2015_piecework_4train a,
	 (	select t1.piecework_id,t1.task_id,t1.suc_rate_all,@rownum:=@rownum+1,
			case when @ptask_id=t1.task_id then @rank:=@rank+1 else @rank:=1 end as rank,
			@ptask_id:=t1.task_id,
			@rownum as row_num
			from
		(	(	select m1.piecework_id,m1.task_id,m2.suc_rate_all from train_2015_piecework_4train m1
			left join train_2015_worker_summary m2 on m1.user_id=m2.user_id
					order by m1.task_id asc, m2.suc_rate_all desc
			) t1,
			(select @rownum:=0, @rank:=0, @ptask_id=null
			) t2
		)
	) b ,
	 train_2015_base_task c
	set a.work_quality_suc_rate = 1
	where a.piecework_id=b.piecework_id 
	and b.task_id=c.task_id
	and b.rank<=c.task_good_piece_ct;
--按照各类目成功率计算
update train_2015_piecework_4train a,
	 (	select t1.piecework_id,t1.task_id,t1.cate_suc_rate,@rownum:=@rownum+1,
			case when @ptask_id=t1.task_id then @rank:=@rank+1 else @rank:=1 end as rank,
			@ptask_id:=t1.task_id,
			@rownum as row_num
			from
		(	(	select m1.piecework_id,m1.task_id,
			case when m3.first_catagory='动画漫画' then  suc_rate_all_c1 
	 			when m3.first_catagory='品牌设计' then  suc_rate_all_c2 
	 			when m3.first_catagory='摄影摄像' then  suc_rate_all_c3 
	 			when m3.first_catagory='文案策划' then  suc_rate_all_c4 
	 			when m3.first_catagory='网站建设' then  suc_rate_all_c5 
	 			when m3.first_catagory='装修服务' then  suc_rate_all_c6 
	 			when m3.first_catagory='起名取名' then  suc_rate_all_c7 
	 			when m3.first_catagory='软件开发' then  suc_rate_all_c8 
	 		end as cate_suc_rate 
			from train_2015_piecework_4train m1
			left join train_2015_worker_summary m2 on m1.user_id=m2.user_id
			left join train_2015_base_task m3 on m1.task_id=m3.task_id
					order by m1.task_id asc, cate_suc_rate desc
			) t1,
			(select @rownum:=0, @rank:=0, @ptask_id=null
			) t2
		)
	) b ,
	 train_2015_base_task c
	set a.work_quality_suc_rate_cate = 1
	where a.piecework_id=b.piecework_id 
	and b.task_id=c.task_id
	and b.rank<=c.task_good_piece_ct;

---------------------------------------------------------------------------------------
-----------------------------pairwise--------------------------------------------------
select count(1) from train_2015_piecework_4train a
left join train_2015_piecework_4train b
on a.task_id = b.task_id
where a.task_end_datetime<"2015-09-01"
and a.selected_value<>b.selected_value
;

create table train_2015_piecework_4train_2015_order1
as 
select @rank:=@rank+1 id, t1.* from 
(select a.* from train_2015_piecework_4train a
left join train_2015_worker_zero b on a.user_id = b.user_id
where a.task_end_datetime<"2015-09-01"
and b.user_id is null
)t1,
(select @rank:=0) t2
order by t1.task_id asc, t1.piecework_id asc
;
create index idx_task_id on train_2015_piecework_4train_2015_order1(task_id);
create table train_2015_piecework_4train_2015_order2
as 
select @rank:=@rank+1 id, t1.* from 
(select a.* from train_2015_piecework_4train a
where a.task_end_datetime>="2015-09-01"
)t1,
(select @rank:=0) t2
order by t1.task_id asc, t1.piecework_id asc
;
create index idx_task_id on train_2015_piecework_4train_2015_order2(task_id);


create table train_2015_piecework_pairwise_1
select 
cast(a.piecework_id as decimal(22,0)) as a_pid, 
cast(b.piecework_id as decimal(22,0)) as b_pid,
a.id as a_id,
b.id as b_id,
cast(a.task_id as decimal(22,0)) as task_id, 
a.task_end_datetime,
a.selected_value a_value, 
b.selected_value b_value,
case when a.selected_value>b.selected_value then 1
when a.selected_value<b.selected_value then -1
else 0 end as class
from train_2015_piecework_4train_2015_order1 a
left join train_2015_piecework_4train_2015_order1 b
on a.task_id = b.task_id
where a.selected_value<>b.selected_value
;

create table train_2015_piecework_pairwise_2
select 
cast(a.piecework_id as decimal(22,0)) as a_pid, 
cast(b.piecework_id as decimal(22,0)) as b_pid,
a.id as a_id,
b.id as b_id,
cast(a.task_id as decimal(22,0)) as task_id, 
a.task_end_datetime,
a.selected_value a_value, 
b.selected_value b_value,
case when a.selected_value>b.selected_value then 1
when a.selected_value<b.selected_value then -1
else 0 end as class
from train_2015_piecework_4train_2015_order2 a
left join train_2015_piecework_4train_2015_order2 b
on a.task_id = b.task_id
;


create index idx_task_id on train_2015_piecework_pairwise_2(task_id);
update train_2015_piecework_pairwise_2 a force index (idx_task_id) left join train_2015_base_task b force index (idx_task_id) on a.task_id =b.task_id set a.category = b.category;


update train_2015_piecework_pairwise_1 a force index (idx_task_id) left join train_2015_base_task b force index (idx_task_id) on a.task_id =b.task_id set a.category = b.category;


explain update train_2015_piecework_pairwise_2 a  left join train_2015_base_task b  on a.task_id =b.task_id set a.category = b.category;

explain update train_2015_piecework_pairwise_2 a  left join train_2015_base_task b  on a.idx_task =b.task_id set a.category = b.category;

alter table train_2015_piecework_pairwise_1 add column idx_task varchar(64);
update train_2015_piecework_pairwise_1 set idx_task=task_id;
create index idx_task on train_2015_piecework_pairwise_1(idx_task);
update train_2015_piecework_pairwise_1 a  left join train_2015_base_task b  on a.idx_task =b.task_id set a.category = b.category;





---------------------------------------------------------------------------------------

price_detail
;

赏金分配：比赛，已选51个，还需要0个 奖项 一等奖1名(已颁发)，赏金￥999.00元 二等奖5名(已颁发5个)，赏金￥799.80元 三等奖10名(已颁发10个)，赏金￥500.10元 四等奖15名(已颁发15个)，赏金￥200.00元 五等奖20名(已颁发20个)，赏金￥100.05元

select payment_detail from task_f_reward 
where first_catagory in 
('品牌设计','起名取名','文案策划','软件开发',
'动画漫画','装修服务','网站建设','摄影摄像','UI设计','电商服务')
;


alter table task_f_reward add column count1  int(11); 
alter table task_f_reward add column reward1 int(11); 
alter table task_f_reward add column count2  int(11); 
alter table task_f_reward add column reward2 int(11); 
alter table task_f_reward add column count3  int(11); 
alter table task_f_reward add column reward3 int(11); 
alter table task_f_reward add column count4  int(11); 
alter table task_f_reward add column reward4 int(11); 
alter table task_f_reward add column count5  int(11); 
alter table task_f_reward add column reward5 int(11); 


create table task_f_reward_2 as 
select task_id, payment_detail, 
	count1, reward1, count2, reward2, 
	count3, reward3, count4, reward4, 
	count5, reward5
	from task_f_reward
	where count1 is not null;















