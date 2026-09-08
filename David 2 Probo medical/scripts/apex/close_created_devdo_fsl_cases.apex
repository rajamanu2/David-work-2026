Set<Id> caseIds = new Set<Id>{
    '500iK000000L6aIQAS',
    '500iK000000L6aJQAS',
    '500iK000000L6aKQAS',
    '500iK000000L6aLQAS'
};

List<Case> casesToClose = [
    SELECT Id, Status
    FROM Case
    WHERE Id IN :caseIds
];

for (Case caseToClose : casesToClose) {
    caseToClose.Status = 'Closed';
}

update casesToClose;

for (Case closedCase : [
    SELECT Id, CaseNumber, Subject, Status, IsClosed, ClosedDate
    FROM Case
    WHERE Id IN :caseIds
    ORDER BY CaseNumber
]) {
    System.debug(LoggingLevel.ERROR,
        'CLOSED_DEVDO_CASE|' + closedCase.CaseNumber + '|' + closedCase.Id + '|' +
        closedCase.Status + '|' + closedCase.IsClosed + '|' + closedCase.ClosedDate
    );
}
