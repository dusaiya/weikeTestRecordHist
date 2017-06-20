--第一步，先要确认每个任务的最后提交时间
--提交以后才能确认
alter table train_base_task add column task_end_date datetime;
update train_base_task t,
(select 
a.task_id,
max(submit_datetime)  submit_date
from train_base_task a
left join piecework_f b on a.task_id =b.task_id
group by a.task_id
) s
set t.task_end_date = s.submit_date
where t.task_id=s.task_id
;





--时间处理完成,进行feature赋值。
select user_id,
count(distinct b.first_catagory) task_cate_ct,-- 参与的任务类型数量
count(distinct b.task_id) task_ct,
0.0 as c1_task_ct,
0.0 as c2_task_ct,
0.0 as c3_task_ct,
0.0 as c4_task_ct,
0.0 as c5_task_ct,
0.0 as c6_task_ct,
0.0 as c7_task_ct,
0.0 as c8_task_ct,
0.0 as c1_task_ct_rate,
0.0 as c2_task_ct_rate,
0.0 as c3_task_ct_rate,
0.0 as c4_task_ct_rate,
0.0 as c5_task_ct_rate,
0.0 as c6_task_ct_rate,
0.0 as c7_task_ct_rate,
0.0 as c8_task_ct_rate,
0 as p1_piecework_ct,
0 as p2_piecework_ct,
0 as p3_piecework_ct,
0 as p4_piecework_ct,
0 as p5_piecework_ct,
0 as p1_piecework_ct_rate,
0 as p2_piecework_ct_rate,
0 as p3_piecework_ct_rate,
0 as p4_piecework_ct_rate,
0 as p5_piecework_ct_rate,
max(ability_value_int) ability_value_int,
max(ability_level_int) ability_level_int,
--over all efficiency 暂时不记录进去 (7,14,30) * (1+8C+5price) =42
0 as median_price,--用程序来计算
--quality (num_suc,num_cost,suc_rate) * (1+8C+4price)=39
num_suc,
num_cost,
suc_rate
from train_base_piecework group by user_id;
--28+42+42+1=113 维;

--piecework 
select  b.piecework_id,
b.user_id, 
a.release_user_id,
b.relative_reputation, --need java to code or use piecework_rank 按照task来循环
b.submit_days,
b.submit_rank,--need java to code
b.relative_submit_rank, --b.submit_rank/count(1)
b.discrete_relative_submit_bin --bin
from train_base_task a left join piecework_f b on a.task_id= b.task_id;

--requester
select release_user_id,


