public class NoWorkingDays {
    private static Integer workingDays = 0;
    private static Date startDate = Date.Today().addDays(5);
    private static Integer leadTime;
    private static Integer diffDate = 0;
    private static Integer returnDays = 0;

/*
    public NoWorkingDays()
    {
        //startDate = Date.Today().addDays(5); 
        workingDays = 0; 
        diffDate = 0;
        returnDays = 0;  
    }
*/

    public static Date workingDays(Date inputDate, Integer repairLeadTime) {
        startDate = inputDate;
        leadTime = repairLeadTime;
        Date tempDate = startDate;
        for (Integer i = 1; i <= leadTime; i++) {
            DateTime dt = DateTime.newInstance(tempDate, Time.newInstance(0, 0, 0, 0));
            String dayOfWeek = dt.format('EEEE');
            //System.debug('::::::::::: Day Name :::::::::::::::'+dayOfWeek);

            if (dayOfWeek == 'Saturday' || dayOfWeek == 'Sunday') {
                workingDays += 1;
            }
            tempDate = tempDate.addDays(1);
            //System.debug('::::::::::: Next Date :::::::::::::::'+tempDate);
        }

        Integer temp = workingDays + leadTime;
        Date newDate = startDate.addDays(temp);

        DateTime dt1 = DateTime.newInstance(newDate, Time.newInstance(0, 0, 0, 0));
        String dayOfWeek = dt1.format('EEEE');
        if (dayOfWeek == 'Saturday') {
            newDate = newDate.addDays(2);
        } else if (dayOfWeek == 'Sunday') {
            newDate = newDate.addDays(1);
        }
        System.debug('::::::::::::::::::: Output Result :::::::::::::::::::::::' + newDate);

        return newDate;
    }

    public static Integer betweenWorkingDays(Date inputDate) {
        Date dt1 = inputDate;
        Date todayDate = Date.Today();

        Integer numberDaysDue = Date.Today().daysBetween(dt1);
        for (Integer i = 1; i <= numberDaysDue; i++) {
            DateTime dt = DateTime.newInstance(todayDate, Time.newInstance(0, 0, 0, 0));
            String dayOfWeek = dt.format('EEEE');
            //System.debug('::::::::::: Day Name :::::::::::::::'+dayOfWeek);

            if (dayOfWeek == 'Saturday' || dayOfWeek == 'Sunday') {
                diffDate += 1;
            }
            todayDate = todayDate.addDays(1);
            //System.debug('::::::::::: Next Date :::::::::::::::'+tempDate);
        }
        returnDays = numberDaysDue - diffDate;
        System.debug('::::::::::: No. of Working Days :::::::::::::::' + returnDays);
        return returnDays;
    }

 /*   public Date workingDays(Date inputDate, Integer repairLeadTime) {
        startDate = inputDate;
        leadTime = repairLeadTime;
        Date tempDate = startDate;
        for (Integer i = 1; i <= leadTime; i++) {
            DateTime dt = DateTime.newInstance(tempDate, Time.newInstance(0, 0, 0, 0));
            String dayOfWeek = dt.format('EEEE');
            //System.debug('::::::::::: Day Name :::::::::::::::'+dayOfWeek);

            if (dayOfWeek == 'Saturday' || dayOfWeek == 'Sunday') {
                workingDays += 1;
            }
            tempDate = tempDate.addDays(1);
            //System.debug('::::::::::: Next Date :::::::::::::::'+tempDate);
        }
        Integer temp = workingDays + leadTime;
        Date newDate = startDate.addDays(temp);

        DateTime dt1 = DateTime.newInstance(newDate, Time.newInstance(0, 0, 0, 0));
        String dayOfWeek = dt1.format('EEEE');
        if (dayOfWeek == 'Saturday') {
            newDate = newDate.addDays(2);
        } else if (dayOfWeek == 'Sunday') {
            newDate = newDate.addDays(1);
        }
        System.debug('::::::::::::::::::: Output Result :::::::::::::::::::::::' + newDate);

        return newDate;
    }


    public Integer betweenWorkingDays(Date inputDate) {
        Date dt1 = inputDate;
        Date todayDate = Date.Today();

        Integer numberDaysDue = Date.Today().daysBetween(dt1);
        for (Integer i = 1; i <= numberDaysDue; i++) {
            DateTime dt = DateTime.newInstance(todayDate, Time.newInstance(0, 0, 0, 0));
            String dayOfWeek = dt.format('EEEE');
            //System.debug('::::::::::: Day Name :::::::::::::::'+dayOfWeek);

            if (dayOfWeek == 'Saturday' || dayOfWeek == 'Sunday') {
                diffDate += 1;
            }
            todayDate = todayDate.addDays(1);
            //System.debug('::::::::::: Next Date :::::::::::::::'+tempDate);  
        }
        returnDays = numberDaysDue - diffDate;
        System.debug('::::::::::: No. of Working Days :::::::::::::::' + returnDays);
        return returnDays;
    }

*/}