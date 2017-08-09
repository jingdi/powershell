#! /bin/bash
source /etc/profile
: '
    NOTE:This script is used for running some command concurrently.
    author:  alex.lvxin
    date:    2017-08-09
    comment: This script is used for running some command concurrently You should use the shell as follows:
    Example: sh concurrent_exec.sh startDate end_Date concurrent_num customer_command parameter1 parameter2 ... parameterN 
                     Begin_date: the begin date value of the partition,like : 2017-07-01 
                     end_date: the end date value of the partition,like : 2017-08-01 
                     concurrent_num: the number of concurrent processes, it is an integer number,like:1 or 8 or 16 ..."
                     customer_command: your shell command to be executed with the concurrent_num processes
                     parameter1 parameter2 ... parameterN:the parameters used by the customer_command
             The Begin_date,end_date,concurrent_num and customer_command  are necessary,and the  parameter1 parameter2 ... parameterN are optional.
             The final command executed is :customer_command parameter1 parameter2 ... parameterN Begin_date . The final  command will be executed  with the concurrent_num processes.
'
my_pid=$$
FD=$$
tempfifo=$$.fifo        # $$表示当前执行文件的PID
tempruntime=$$.runtime        # $$表示当前执行文件的PID
begin_date=$1          # 开始时间
end_date=$2           # 结束时间
date_interval="+1 day"
current_number=$3

if [ $# -lt 4 ] 
then
     echo "[ERROR] Thera are not enough parameters,You should use this script as follows:
Example: sh concurrent_exec.sh startDate end_Date concurrent_num customer_command parameter1 parameter2 ... parameterN 
Begin_date: the begin date value of the partition,like : 2017-07-01 
end_date: the end date value of the partition,like : 2017-08-01 
[NOTE] If the Begin_date is less than end_date,Then the script will run the customer_command serially.But If the Begin_date is greater than end_date,Then the script will run the customer_command in Reverse order.
concurrent_num: the number of concurrent processes, it is an integer number,like:1 or 8 or 16 ...
customer_command: your shell command to be executed with the concurrent_num processes
parameter1 parameter2 ... parameterN:the parameters used by the customer_command
The Begin_date,end_date,concurrent_num and customer_command  are necessary,and the  parameter1 parameter2 ... parameterN are optional.
The final command executed is :customer_command parameter1 parameter2 ... parameterN Begin_date . The final  command will be executed  with the concurrent_num processe."
        exit 1;
    
fi

echo "Begin date is :$begin_date and End Date is :$end_date"

if [ "$begin_date" \> "$end_date" ]
then
    echo "[INFO] Begin date is greater than the end date,We will use Reverse order!"
    date_interval="-1 day"
fi
parameters=""
index=1
ps=""
for i in $@
do
    if [ "$index" -gt "3" ];then
    parameters=$parameters" "$i
    fi
    let index+=1;
done
echo "The actually program is : $parameters" 

trap "exec ${FD}>&-;exec ${FD}<&-;/bin/rm -rf $tempruntime;exit 0" 2
echo "1">$tempruntime
mkfifo $tempfifo
eval exec "${FD}"'<>"$tempfifo"'
#exec {FD}<>$tempfifo
rm -rf $tempfifo
echo "[INFO] fifo file's file descriptor is : $FD"
for ((i=1; i<=$current_number; i++))
do
    echo >&$FD
done

status=`cat $tempruntime`
while [ $begin_date != $end_date -a "$status" != "0" ]
do
    read -u$FD
    {
        echo "[INFO] parent process id is : ${my_pid} running  $parameters $begin_date  and the status is $status"
        $parameters $begin_date
        echo >& $FD
    } &

    begin_date=`date -d "$date_interval $begin_date" +"%Y-%m-%d"`
    status=`cat $tempruntime`
done

wait
echo "[INFO] done!"
/bin/rm -f $tempruntime
