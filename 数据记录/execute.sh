rm -rf /home/duanxueye/weike/code/matlab/weike2015/season2month/handler/pointwiseflow*.m

cd ~/Documents/MATLAB/weike2015/season2month/workflow/pointwise/
scp pointwiseflow*.m root@10.60.1.92:/home/duanxueye/weike/code/matlab/weike2015/season2month/handler/

cd /home/duanxueye/weike/code/matlab/weike2015/season2month/handler/
nohup matlab -nosplash -nodesktop -r pointwiseflow

nohup matlab -nosplash -nodesktop -r pointwiseflowTest
1.m

--不能用
nohup matlab -nosplash -nodesktop -r pointwiseflow1.m
nohup matlab -nosplash -nodesktop -r pointwiseflow2.m
nohup matlab -nosplash -nodesktop -r pointwiseflow3.m
nohup matlab -nosplash -nodesktop -r pointwiseflow4.m
--

28290 shifabin  20   0 1759m 1.7g 105m S 100.9  5.5   7:34.54 MATLAB                                               
28568 shifabin  20   0 1418m 1.4g 104m S 100.5  4.4   1:48.66 MATLAB                                               


