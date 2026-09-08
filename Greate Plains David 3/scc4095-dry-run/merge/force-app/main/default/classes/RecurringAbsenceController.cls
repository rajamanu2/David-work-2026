/**
 * @class       						   RecurringAbsenceController
 * @description 						   controller for custom recurring absenses so we can have grant label.
 * 
 * @author      						   Daniel Perez
 * @created     						   2026-07-20
 */
public with sharing class RecurringAbsenceController {
    private static final Map<String, Integer> DAY_OF_WEEK_MAP = new Map<String, Integer>{
        'Sunday' => 0,
        'Monday' => 1,
        'Tuesday' => 2,
        'Wednesday' => 3,
        'Thursday' => 4,
        'Friday' => 5,
        'Saturday' => 6
    };

    private static final Map<String, Integer> POSITION_INDEX_MAP = new Map<String, Integer>{
        'First' => 0,
        'Second' => 1,
        'Third' => 2,
        'Fourth' => 3
    };

    /** 						   
     * gets/sets value for the controller
     * @returns absence
     */
    public ResourceAbsence absence { get; set; }
    /**
     * Gets/sets the recurrence type.
     * @return The recurrence type.
     */
    
     public String recurrenceType { get; set; }

    private Set<String> targetDays = new Set<String>();
    /**
     * Gets/sets the number of occurrences.
     * @return The number of occurrences.
     */
    public Integer numberOfOccurrences { get; set; }

    /**
     * Gets/sets the recurrence pattern end date.
     * @return The recurrence pattern end date.
     */
    public Date patternEndDate { get; set; }

    /**
     * Gets/sets the recurrence frequency.
     * @return The recurrence frequency.
     */
    public Integer frequency { get; set; }

    /**
     * Gets/sets the recurrence end type.
     * @return The recurrence end type.
     */
    public String recurrenceEndType { get; set; }

    /**
     * Gets/sets the selected recurrence days.
     * @return The selected recurrence days.
     */
    public String selectedRecurrenceDays { get; set; }

    /**
     * Gets/sets the monthly recurring type.
     * @return The monthly recurring type.
     */
    public String monthlyRecurringType { get; set; }

    /**
     * Gets/sets the day of the month for monthly recurrence.
     * @return The day of the month for monthly recurrence.
     */
    public Integer monthlyDayOfMonth { get; set; }

    /**
     * Gets/sets the week position for monthly recurrence.
     * @return The week position for monthly recurrence.
     */
    public String monthlyWeekPosition { get; set; }

    /**
     * Gets/sets the day of the week for monthly recurrence.
     * @return The day of the week for monthly recurrence.
     */
    public String monthlyDayOfWeek { get; set; }

    /**
     * Gets/sets the yearly recurring type.
     * @return The yearly recurring type.
     */
    public String yearlyRecurringType { get; set; }
   
    /**
     * Gets/sets the month for yearly recurrence.
     * @return The month for yearly recurrence.
     */
    public String yearlyMonth { get; set; }

    /**
     * Gets/sets the day of the month for yearly recurrence.
     * @return The day of the month for yearly recurrence.
     */
    public Integer yearlyDayOfMonth { get; set; }

    /**
     * Gets/sets the week position for yearly recurrence.
     * @return The week position for yearly recurrence.
     */
    public String yearlyWeekPosition { get; set; }

    /**
     * Gets/sets the day of the week for yearly recurrence.
     * @return The day of the week for yearly recurrence.
     */
    public String yearlyDayOfWeek { get; set; }

    /**
     * Gets/sets the month used with yearly week-based recurrence.
     * @return The month used with yearly week-based recurrence.
     */
    public String yearlyWeekMonth { get; set; }

    /**
     * Gets/sets the start date input.
     * @return The start date input.
     */
    public Date startDateInput { get; set; }

    /**
     * Gets/sets the start time input.
     * @return The start time input.
     */
    public String startTimeInput { get; set; }

    /**
     * Gets/sets the end date input.
     * @return The end date input.
     */
    public Date endDateInput { get; set; }

    /**
     * Gets/sets the end time input.
     * @return The end time input.
     */
    
    public String endTimeInput { get; set; }

    /**
     * Gets the list of available time options.
     * @return The list of available time options.
     */
    public List<SelectOption> timeOptions { get; set; }
	
     /**
     * @method                              RecurringAbsenceController
     * @description                         Initializes the recurring absence controller.
     * @param stdSetController              StandardController instance.
     */
    public RecurringAbsenceController(ApexPages.StandardSetController stdSetController) {
        initController();
    }
    
     /**
     * @method                              RecurringAbsenceController
     * @description                         Initializes the recurring absence controller.
     * @param    stdController              StandardController instance.
     * 
     */
    public RecurringAbsenceController(ApexPages.StandardController stdController) {
        initController();
    }

    /**
     * @method                              initController
     * @description                         Initializes the controller with default values and page parameters.
     * 
     */
    private void initController() {
        absence = new ResourceAbsence();
        frequency = 1; 
        recurrenceEndType = 'Occurrences'; 
        selectedRecurrenceDays = '';
        monthlyRecurringType = 'Date';
        monthlyDayOfMonth = 1;
        monthlyWeekPosition = 'First';
        monthlyDayOfWeek = 'Sunday';
        yearlyRecurringType = 'Date';
        yearlyMonth = 'January';
        yearlyDayOfMonth = 1;
        yearlyWeekPosition = 'First';
        yearlyDayOfWeek = 'Sunday';
        yearlyWeekMonth = 'January';
        Id resourceId = ApexPages.currentPage().getParameters().get('id');
        if (resourceId != null) {
            absence.ResourceId = resourceId;
        }
        
        // Default values for separate UI fields
        DateTime defaultStart = DateTime.now();
        DateTime defaultEnd = DateTime.now().addHours(1);
        startDateInput = defaultStart.date();
        endDateInput = defaultEnd.date();
        
        
        startTimeInput = '12:00';
        endTimeInput =  '01:00';
        
       
        buildTimeOptions();
    }
    
    /**
     * @method                              buildTimeOptions
     * @description                         Builds the 15-minute interval time picklist used for start and end times.
     * @param                               None.
     * 
     */
    private void buildTimeOptions() {
        timeOptions = new List<SelectOption>();
        for (Integer h = 0; h < 24; h++) {
            for (Integer m = 0; m < 60; m += 15) {
                String hourStr = String.valueOf(h).leftPad(2, '0');
                String minStr = String.valueOf(m).leftPad(2, '0');
                String valueStr = hourStr + ':' + minStr; // e.g. "13:15"
                
                // Construct Display Label (12-hour AM/PM format)
                Integer displayHour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
                String ampm = h < 12 ? 'AM' : 'PM';
                String labelStr = displayHour + ':' + minStr + ' ' + ampm;
                
                timeOptions.add(new SelectOption(valueStr, labelStr));
            }
        }
    }
    
    /**
     * @property                            monthlyDayOptions
     * @description                         Provides a list of selectable days (1-31) for monthly recurrence configuration.
     *                                      The list is lazily initialized when first accessed.
     * @return List<SelectOption>            List of day options used for monthly recurrence selection.
     */
    @TestVisible
    public List<SelectOption> monthlyDayOptions { 
        get {
            if (monthlyDayOptions == null) {
                monthlyDayOptions = new List<SelectOption>();
                for (Integer i = 1; i <= 31; i++) {
                    monthlyDayOptions.add(new SelectOption(String.valueOf(i), String.valueOf(i)));
                }
            }
            return monthlyDayOptions;
        }
        private set;
    }
    
  	/**
     * @property                            monthOptions
     * @description                         Provides a list of month options (January-December) for yearly recurrence configuration.
     *                                      The list is lazily initialized when first accessed.
     * @return List<SelectOption>            List of month options used for yearly recurrence selection.
     */
    @TestVisible
    public List<SelectOption> monthOptions {

        get {
    
            if (monthOptions == null) {
    
                monthOptions = new List<SelectOption>();
    
                List<String> months = new List<String>{
                    'January',
                    'February',
                    'March',
                    'April',
                    'May',
                    'June',
                    'July',
                    'August',
                    'September',
                    'October',
                    'November',
                    'December'
                };
    
                for (String m : months) {
                    monthOptions.add(new SelectOption(m, m));
                }
            }
    
            return monthOptions;
        }
    
        private set;
    }
    
    /**
     * @method                              saveAbsences
     * @description                         Saves the recurring absence records and redirects to the resource record upon success.
     * @param                               None.
     * @return                              PageReference
     */
    public PageReference saveAbsences() {
        if (executeInsert()) {
            return new PageReference('/' + absence.ResourceId);
        }
        return null;
    }
    
    /**
     * @method                              executeInsert
     * @description                         Validates the recurrence settings, generates recurring Resource Absence records, and inserts them.
     * @param                               None.
     * @return                              Boolean
     */
    private Boolean executeInsert() {
        try {
            // Merge independent UI Date and Time selections into single DateTime objects
            DateTime mergedStart = combineDateAndTime(startDateInput, startTimeInput);
            DateTime mergedEnd = combineDateAndTime(endDateInput, endTimeInput);

            if (!checkIfValid(mergedStart, mergedEnd)) {
                return false;
            }
            
            List<ResourceAbsence> absencesToInsert = generateAbsences( mergedStart, mergedEnd,targetDays);
            
            if (!absencesToInsert.isEmpty()) {
                insert absencesToInsert;
            }
            return true;
        } catch(Exception e) {
            ApexPages.addMessages(e);
            return false;
        }
    }


    
    /**
     * @method       generateAbsences
     * @description  Creates resource absences based on the configured recurrence type
     *              and recurrence frequency.
     * @param        mergedStart  The start date and time of the initial absence.
     * @param        mergedEnd    The end date and time of the initial absence.
     * @param        targetDays   The days of the week on which weekly absences should be created.
     *
     * @return       List of ResourceAbsence records to be created.
     */
    private List<ResourceAbsence> generateAbsences(DateTime mergedStart, DateTime mergedEnd, Set<String> targetDays) {
        List<ResourceAbsence> absencesToInsert = new List<ResourceAbsence>();

        DateTime currentStart = mergedStart;
        DateTime currentEnd = mergedEnd;
        Integer occurrences = 0;
        Integer step = (frequency != null && frequency > 0) ? frequency : 1;

        // Generate absences until the configured occurrence/date limit is reached.
        while (createMoreOccurrences(occurrences, currentStart.date())) {
            if (recurrenceType == 'Weekly') {
                if (processWeeklyOccurrence(new DateTime[] { currentStart, currentEnd }, targetDays, absencesToInsert)) {
                    occurrences++;
                }

                DateTime[] nextDates = getNextWeeklyDates(
                    currentStart,
                    currentEnd,
                    step
                );

                currentStart = nextDates[0];
                currentEnd = nextDates[1];
            } else {
                // Create the absence for daily, monthly, and yearly recurrences.
                addAbsence(currentStart, currentEnd, absencesToInsert);
                occurrences++;

                DateTime nextStart = getNextOccurrence(currentStart, step);
                Long durationMinutes = getDurationMinutes(currentStart, currentEnd);

                currentStart = nextStart;
                currentEnd = nextStart.addMinutes((Integer) durationMinutes);
            }
        }

        return absencesToInsert;
    }

    /**
     * @method       processWeeklyOccurrence
     * @description  Checks whether the current day is configured as a target
     *              day and creates an absence when applicable.
     *
     *
     * @param        occurrenceDates      stores the start and end times
     * @param        targetDays           Configured days for weekly recurrence.
     * @param        absencesToInsert     List to which the new absence is added.
     *
     * @return       returns true or false if it was updated
     */
    private Boolean processWeeklyOccurrence(DateTime[] occurrenceDates, Set<String> targetDays, List<ResourceAbsence> absencesToInsert) {
         String currentDayOfWeek = occurrenceDates[0].format('E');

        if (!targetDays.contains(currentDayOfWeek)) {
            return false;
        }
    
        addAbsence(occurrenceDates[0], occurrenceDates[1], absencesToInsert);
        return true;
    }

    /**
     * @method       getNextWeeklyDates
     * @description  Calculates the start and end dates for the next weekly
     *              occurrence while respecting the configured frequency.
     *
     * @param        currentStart  Current occurrence start date and time.
     * @param        currentEnd    Current occurrence end date and time.
     * @param        step          Number of weeks between weekly recurrences.
     *
     * @return       Array containing the next start date at index 0 and
     *              next end date at index 1.
     */
    private DateTime[] getNextWeeklyDates(DateTime currentStart, DateTime currentEnd,Integer step) {
        String currentDayOfWeek = currentStart.format('E');
        Integer daysToAdd = 1;

        // After Saturday, move to the next applicable week based on frequency.
        if (currentDayOfWeek == 'Sat') {
            daysToAdd += 7 * (step - 1);
        }

        return new DateTime[] {
            currentStart.addDays(daysToAdd),
            currentEnd.addDays(daysToAdd)
        };
    }

    /**
     * @method       getNextOccurrence
     * @description  Calculates the next occurrence date based on the configured
     *              recurrence type.
     *
     * @param        currentStart  Current occurrence start date and time.
     * @param        step          Number of days for daily recurrence.
     *
     * @return       DateTime representing the next occurrence.
     */
    private DateTime getNextOccurrence(DateTime currentStart, Integer step) {
        if (recurrenceType == 'Daily') {
            return currentStart.addDays(step);
        }

        if (recurrenceType == 'Monthly') {
            return getNextMonthlyOccurrence(currentStart);
        }

        if (recurrenceType == 'Yearly') {
            return getNextYearlyOccurrence(currentStart);
        }

        return currentStart;
    }

    /**
     * @method       addAbsence
     * @description  Clones the configured absence and adds it to the list
     *              of absences to be inserted.
     *
     * @param        start              Start date and time of the absence.
     * @param        endDate                End date and time of the absence.
     * @param        absencesToInsert   List to which the cloned absence is added.
     */
    private void addAbsence(DateTime start,DateTime endDate,List<ResourceAbsence> absencesToInsert) {
        ResourceAbsence newAbs = absence.clone(false, true, false, false);
        newAbs.Start = start;
        newAbs.End = endDate;
        absencesToInsert.add(newAbs);
    }

    /**
     * @method       getDurationMinutes
     * @description  Calculates the duration between the start and end times
     *              in minutes.
     *
     * @param        start  Start date and time.
     * @param        endDate    End date and time.
     *
     * @return       Duration between start and end in minutes.
     */
    private Long getDurationMinutes(DateTime start, DateTime endDate) {
        return (endDate.getTime() - start.getTime()) / (1000 * 60);
    }

    
    
    /**
     * @method                              combineDateAndTime
     * @description                         Combines a Date value and time string into a single DateTime value.
     * @param d                             Date portion.
     * @param t                             Time portion in HH:mm format.
     * @return                              DateTime
     */
    @TestVisible
    private DateTime combineDateAndTime(Date d, String t) {
        if (d == null || String.isBlank(t)){
            return null;
        }
        List<String> timeParts = t.split(':');
        Integer hour = Integer.valueOf(timeParts[0]);
        Integer minute = Integer.valueOf(timeParts[1]);
        return DateTime.newInstance(d.year(), d.month(), d.day(), hour, minute, 0);
    }

    /**
     * @method                              cancel
     * @description                         Cancels the operation and redirects the user back to the resource or Resource Absence home page.
     * @param                               None.
     * @return                              PageReference
     */
    public PageReference cancel() {
        if (absence.ResourceId != null) {
            return new PageReference('/' + absence.ResourceId);
        }
        return new PageReference('/lightning/o/ResourceAbsence/home');
    }
	
    /**
     * @method                              getNextMonthlyOccurrence
     * @description                         Calculates the next monthly occurrence based on the selected recurrence pattern.
     * @param currentStart                  Current occurrence start DateTime.
     * @return                              DateTime
     */
    @TestVisible
    private DateTime getNextMonthlyOccurrence(DateTime currentStart) {

        Integer step = (frequency != null && frequency > 0)
            ? frequency
            : 1;
    
        Date targetMonth = currentStart.date().addMonths(step);
    
        Date nextDate;
    
        if (monthlyRecurringType == 'Date') {
    
            Integer day = Math.min(
                monthlyDayOfMonth,
                Date.daysInMonth(targetMonth.year(), targetMonth.month())
            );
    
            nextDate = Date.newInstance(
                targetMonth.year(),
                targetMonth.month(),
                day
            );
    
        } else {
            DateInfo dateInfo = new DateInfo(targetMonth.year(),targetMonth.month());
            
            nextDate = getNthWeekdayOfMonth(dateInfo,monthlyWeekPosition, monthlyDayOfWeek);
        }
    
        return DateTime.newInstance(
            nextDate.year(),
            nextDate.month(),
            nextDate.day(),
            currentStart.hour(),
            currentStart.minute(),
            currentStart.second()
        );
    }
    
     /**
     * @method                              checkValidDates
     * @description                         Calculates the next monthly occurrence based on the selected recurrence pattern.
     * @param mergedStart                   Current occurrence mergedStart.
     * @param mergedEnd                     Current occurrence mergedEnd.
     * @return                              if true or false
     */
    @TestVisible
    private Boolean checkValidDates(DateTime mergedStart, DateTime mergedEnd) {
        if (mergedStart == null || mergedEnd == null) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Please provide valid start and end dates and times.'
            ));
            return false;
        }
    
        if (mergedEnd <= mergedStart) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'End Time must be after Start Time.'
            ));
            return false;
        }
    
        return true;
    }
    
     /**
     * @method                              checkValidRecurrenceEndType
     * @description                         check if valid recurrence End Type
     
     * @return                              if true or false
     */
    private Boolean checkValidRecurrenceEndType() {
        if (recurrenceEndType == 'Occurrences') {
            patternEndDate = null;
    
            if (numberOfOccurrences == null || numberOfOccurrences <= 0) {
                ApexPages.addMessage(new ApexPages.Message(
                    ApexPages.Severity.ERROR,
                    'Please specify an occurrence count greater than 0.'
                ));
                return false;
            }
    
        } else if (recurrenceEndType == 'Date') {
            numberOfOccurrences = null;
    
            if (patternEndDate == null) {
                ApexPages.addMessage(new ApexPages.Message(
                    ApexPages.Severity.ERROR,
                    'Please specify a pattern end date.'
                ));
                return false;
            }
        }
    
        return true;
    }
    
    /**
     * @method                              checkIfValid
     * @description                         Calculates the next monthly occurrence based on the selected recurrence pattern.
     * @param mergedStart                   startDateTime check if valid
     * @param mergedEnd                     mergedEnd check if valid
     * @return                              Boolean on if valid
     */
    @TestVisible
    private Boolean checkIfValid(DateTime mergedStart, DateTime mergedEnd) {
        if (!checkValidDates(mergedStart, mergedEnd)) {
            return false;
        }

        if (!checkValidRecurrenceEndType()) {
            return false;
        }

        targetDays.clear();

        if (recurrenceType == 'Weekly') {
            if (String.isNotBlank(selectedRecurrenceDays)) {
                targetDays.addAll(selectedRecurrenceDays.split(','));
            } else {
                ApexPages.addMessage(new ApexPages.Message(
                    ApexPages.Severity.ERROR,
                    'Please select at least one day for weekly recurrence.'
                ));
                return false;
            }
        }

        if (recurrenceType == 'Monthly'
            && monthlyRecurringType == 'Date'
            && monthlyDayOfMonth == null) {

            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Please select a day of the month.'
            ));
            return false;
        }

        if (recurrenceType == 'Yearly'
            && yearlyRecurringType == 'Date'
            && (String.isBlank(yearlyMonth) || yearlyDayOfMonth == null)) {

            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Please complete the yearly recurrence.'
            ));
            return false;
        }

        return true;
    }
    
    /**
     * @method                              getNextYearlyOccurrence
     * @description                         Calculates the next yearly occurrence based on the selected recurrence pattern.
     * @param currentStart                  Current occurrence start DateTime.
     * @return                              DateTime
     */
    @TestVisible
    private DateTime getNextYearlyOccurrence(DateTime currentStart) {

        Integer step = (frequency != null && frequency > 0)
            ? frequency
            : 1;
    
        Integer year = currentStart.year() + step;
    
        Integer month =
            monthNumber(
                yearlyRecurringType == 'Date'
                    ? yearlyMonth
                    : yearlyWeekMonth
            );
    
        Date nextDate;
    
        if (yearlyRecurringType == 'Date') {
    
            Integer day = Math.min(
                yearlyDayOfMonth,
                Date.daysInMonth(year, month)
            );
    
            nextDate = Date.newInstance(
                year,
                month,
                day
            );
    
        } else {
    
            DateInfo dateInfo = new DateInfo(year, month);
            
            nextDate = getNthWeekdayOfMonth(dateInfo,monthlyWeekPosition, monthlyDayOfWeek);
        }
    
        return DateTime.newInstance(
            nextDate.year(),
            nextDate.month(),
            nextDate.day(),
            currentStart.hour(),
            currentStart.minute(),
            currentStart.second()
        );
    }
    
    /**
     * @method                              monthNumber
     * @description                         Converts a month name into its corresponding numeric month value.
     * @param month                         Month name.
     * @return                              Integer
     */
    @TestVisible 
    private Integer monthNumber(String month) {

        Map<String,Integer> months = new Map<String,Integer>{
    
            'January' => 1,
            'February' => 2,
            'March' => 3,
            'April' => 4,
            'May' => 5,
            'June' => 6,
            'July' => 7,
            'August' => 8,
            'September' => 9,
            'October' => 10,
            'November' => 11,
            'December' => 12
        };
    
        return months.get(month);
    }
	
    /**
     * @method                              getNthWeekdayOfMonth
     * @description                         Returns the date of the specified weekday occurrence within a given month and year.
     * @param dateInfo                      contains the year and month.
     * @param position                      Week occurrence (First, Second, Third, Fourth, or Last).
     * @param rule                          Day matching rule (Day, Weekday, Weekend Day, or specific weekday).
     * @return Date                         Matching date based on the supplied rule and position.
     */
    @TestVisible
    private Date getNthWeekdayOfMonth(DateInfo dateInfo, String position, String rule) {
    
        List<Date> matches = new List<Date>();
    
        Integer days = Date.daysInMonth(dateInfo.year, dateInfo.month);
    
        Date first = Date.newInstance(dateInfo.year, dateInfo.month, 1);
    
        for (Integer i = 0; i < days; i++) {
            Date d = first.addDays(i);
            if (matchesRule(d, rule)) {
                matches.add(d);
            }
        }
    
        if (matches.isEmpty()) {
            return first;
        }
    
        if (POSITION_INDEX_MAP.containsKey(position)) {
            Integer index = POSITION_INDEX_MAP.get(position);

            return matches.size() > index
                ? matches[index]
                : matches[matches.size() - 1];
        }
                
        return matches[matches.size()-1];
    
    }
    
    /**
     * @method                              matchesRule
     * @description                         Determines whether the provided date satisfies the specified recurrence rule.
     * @param d                             Date to evaluate.
     * @param rule                          Recurrence rule (Day, Weekday, Weekend Day, or specific weekday).
     * @return Boolean                      True if the date matches the rule; otherwise, false.
     */
    @TestVisible
    private Boolean matchesRule(Date d, String rule) {
        Integer dow = Math.mod(Date.newInstance(1900,1,7).daysBetween(d),7);    
        
        if (DAY_OF_WEEK_MAP.containsKey(rule) && dow == DAY_OF_WEEK_MAP.get(rule)) {
            return true;
        }

        if(rule == 'Day') {
            return true;
        }

        if(rule == 'Weekday') {
            return dow >= 1 && dow <= 5;
        }

        if(rule == 'Weekend Day') {
            return dow == 0 || dow == 6;
        }
        
    
        return false;
    
    }
	
    /**
     * @method                              matchesMonthlyRule
     * @description                         Determines whether the specified date satisfies the provided monthly recurrence rule.
     * @param d                             Date to evaluate.
     * @param rule                          Monthly recurrence rule (Day, Weekday, Weekend Day, or specific weekday).
     * @return Boolean                      True if the date matches the specified monthly recurrence rule; otherwise, false.
     */
    @TestVisible
    private Boolean matchesMonthlyRule(Date d, String rule) {

        Datetime dt = Datetime.newInstance(d, Time.newInstance(0,0,0,0));
        String dow = dt.format('EEEE');

        if(rule == 'Day') {
            return true;
        }

        if(rule == 'Weekday') {
            return dow != 'Saturday' && dow != 'Sunday';
        }

        if(rule == 'Weekend Day') {
            return dow == 'Saturday' || dow == 'Sunday';
        }

        return dow == rule;
    }
	
    /**
     * @method                              createMoreOccurrences
     * @description                         Determines whether additional recurring absence records should be generated.
     * @param currentCount                  Number of occurrences created so far.
     * @param currentDate                   Current occurrence date.
     * @return                              Boolean
     */
    @TestVisible
    private Boolean createMoreOccurrences(Integer currentCount, Date currentDate) {
        if (patternEndDate != null) {
            return currentDate <= patternEndDate;
        }
        return currentCount < numberOfOccurrences;
    }

    /**
     * @class       						   DateInfo
     * @description 						   whole the date info for what was selected
     * 
     * @author      						   Daniel Perez
     * @created     						   2026-07-20
     */
    public class DateInfo {
         /** 						   
         * gets/sets value for the dateInfo
         * @returns year
         */
        public Integer year { get; set; }
        /** 						   
         * gets/sets value for the dateInfo
         * @returns month
         */
        public Integer month { get; set; }
    
         /** 						   
         * constructor to store the dateinfo
         * @param year to store the year
         * @param month to store the month
         * 
         */
        public DateInfo(Integer year, Integer month) {
            this.year = year;
            this.month = month;
        }
	}
}