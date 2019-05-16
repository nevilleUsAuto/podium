/**
 * Created by admin on 4/5/18.
 */

global class PodiumScheduler implements Schedulable {

    global static String CRON_EXP = '0 0 11 * * ?';

    global void execute (SchedulableContext SC) {
        PodiumCallout.doPodiumProcess();

        /*
        PodiumScheduler pc = new PodiumScheduler();
        String sch = '0 0 9 * * ?';
        String jobID = system.schedule('Podium Schedule', sch, pc);
         */
    }
}