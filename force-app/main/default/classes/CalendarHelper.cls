public class CalendarHelper { // Question 2 of Collections

    // 1. Print list of month names
    public static void getMonths() {
        List<String> months = new List<String>{
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'
        };
        System.debug('Months: ' + months);
    }

    // 2. Print date range for a month in a given year
    public static void getDateRange(Integer year, Integer month) {
        Date startDate = Date.newInstance(year, month, 1);// first day of month
        Integer lastDay = Date.daysInMonth(year, month);// last day of month
        Date endDate = Date.newInstance(year, month, lastDay);// last day of month
        Map<String, Date> dateRange = new Map<String, Date>{
            'startDate' => startDate, 'endDate' => endDate
        };
        System.debug('Date Range: ' + dateRange);
    }

    // 3. Print week number of a given date (Monday as week start)
    public static void getWeekNumber(Date inputDate) { //format: 2025-09-22
        Date firstDayOfMonth = Date.newInstance(inputDate.year(), inputDate.month(), 1);
        //ISO format is used to determine the weekday (1=Mon ..7=Sun), syntax: .format('u')
        Integer firstDayWeekday = Integer.valueOf(((Datetime)firstDayOfMonth).format('u')); // 1=Mon ..7=Sun .format('u') gives ISO day of week
        //example value of firstDayWeekday = 1 (Mon), 2 (Tue), 3 (Wed), ..., 7 (Sun)
        Integer inputDay = inputDate.day();

        /*logic: we need to find the first Monday of the month, and then count weeks from there
        also if the first day is Monday, then the first week starts from day 1
        if the first day is not Monday, then the first week starts from the first Monday (which will be between day 2 to day 7)
        so we calculate an offset to adjust the input day accordingly
        e.g. if first day is Wed (3), then offset = 8 - 3 = 5, so week starts from day 6
        e.g. if first day is Mon (1), then offset = 0, so week starts from day 1
        then we calculate the adjusted day = inputDay - offset
        if adjustedDay <= 0, then weekNum = 1 (as it falls in the first week)
        else weekNum = (adjustedDay + 6) / 7 + 1 (integer division) to get the week number   
        */
        Integer offset = 0;
        if(firstDayWeekday != 1) { // not Monday
            offset = 8 - firstDayWeekday; 
        }
        Integer adjustedDay = inputDay - offset; // days after first Monday
        Integer weekNum;
        if(adjustedDay <= 0) {
            weekNum = 1;
        } else {
            weekNum = (adjustedDay + 6) / 7 + 1;
        }
        System.debug('Week Number: ' + weekNum);
    }

    // 4. Print column number as per calendar (Monday=1, Sunday=7)
    public static void getColumnNumber(Date inputDate) {
        Integer colNum = Integer.valueOf(((Datetime)inputDate).format('u'));
        /*logic: .format('u') gives ISO day of week (1=Mon ..7=Sun)
        so we can directly use that value as column number
        */
        System.debug('Column Number: ' + colNum);
    }
}
/*
CalendarHelper.getMonths();
CalendarHelper.getDateRange(2025, 9);
CalendarHelper.getWeekNumber(Date.newInstance(2025, 9, 22));
CalendarHelper.getColumnNumber(Date.newInstance(2025, 9, 22));
*/