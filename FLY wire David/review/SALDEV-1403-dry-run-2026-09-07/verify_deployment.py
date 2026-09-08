import json,re
from pathlib import Path
from collections import Counter
R=Path(__file__).resolve().parent; D=R/'deployment'; E=R/'evidence'
def read(path):return json.loads(path.read_text(encoding='utf-8-sig'))
checks=[]
def check(name,passed,detail=''):checks.append({'check':name,'pass':bool(passed),'detail':detail})
def array(value):return value if isinstance(value,list) else ([value] if isinstance(value,dict) else [])
payloads={}
for name in ['baseline','baseline-extra']:
    result=read(D/f'post-{name}.json')
    check(name+' native execution',result['status']==0 and result['result']['success'])
    for line in result['result']['logs'].splitlines():
        if '|USER_DEBUG|' not in line:continue
        m=re.search(r'SALDEV1403_BASELINE(?:&#124;|\|)(Q-\d+)(?:&#124;|\|)(\{.*)',line)
        if m:payloads[m[1]]=json.loads(m[2])
check('All eight post-deployment scenarios captured',len(payloads)==8)
(D/'post-payloads.json').write_text(json.dumps(payloads,indent=2))
source=read(E/'lines.json')['records']+read(E/'lines-extra.json')['records']
groups=read(E/'groups.json')['records']
findings=[]
for quote,p in payloads.items():
    x=p['transformed']; actual_groups=[g for g in array(x.get('Group')) if g.get('Name')]
    check(quote+' no mapper errors',not p['extractErrors'] and not p['transformErrors'])
    check(quote+' Ship-To condition',bool(x['IF_MultipleShipToAccounts'])==(x['MultipleShipToAccounts']=='Yes'))
    qgroups=[g for g in groups if g['SBQQ__Quote__r']['Name']==quote]
    expected_groups=sorted(qgroups,key=lambda g:(g['SBQQ__StartDate__c'] is None,g['SBQQ__StartDate__c'] or '',g['SBQQ__SubscriptionTerm__c'] is None,-(g['SBQQ__SubscriptionTerm__c'] or 0),g['SBQQ__Number__c']))
    if x['IF_QuoteLineGroupsPresentTrue']:
        check(quote+' group order',[g['Number'] for g in actual_groups]==[g['SBQQ__Number__c'] for g in expected_groups])
        check(quote+' group subscription terms',all(a.get('SubscriptionTerm')==b['SBQQ__SubscriptionTerm__c'] for a,b in zip(actual_groups,expected_groups)))
    else:check(quote+' ungrouped heading hidden',x['IF_QuoteLineGroupsPresentFalse'] and not x['IF_QuoteLineGroupsPresentTrue'])
    rows=[r for r in source if r['SBQQ__Quote__r']['Name']==quote and r['Quote_Line_Type__c'] not in ('Amendment',None)]
    count=0; descriptions=0; rates=0
    buckets=[]
    if x['IF_QuoteLineGroupsPresentTrue']:
        for group in qgroups:
            actual=next(g for g in actual_groups if g['Number']==group['SBQQ__Number__c'])
            buckets.append((group['Id'],[l for l in array(actual.get('QuoteLine')) if l.get('ProductName')]))
    else:buckets.append((None,[l for l in array(x.get('Line')) if l.get('ProductName')]))
    for gid,actual in buckets:
        expected=sorted([r for r in rows if r['SBQQ__Group__c']==gid],key=lambda r:r['SBQQ__Number__c'])
        check(quote+' product order '+str(gid),[r['ProductName'] for r in actual]==[r['SBQQ__ProductName__c'] for r in expected])
        check(quote+' product multiplicities '+str(gid),Counter(r['ProductName'] for r in actual)==Counter(r['SBQQ__ProductName__c'] for r in expected))
        count+=len(actual)
        for actual_line,source_line in zip(actual,expected):
            d=source_line.get('External_Description__c') or ''; rate=source_line.get('Rate_Details__c') or ''; typ=source_line['Quote_Line_Type__c']
            expected_description=' '.join(v for v in [d,rate] if v)
            if typ in ['Cancellation','Quantity Increase','Quantity Reduction']:expected_description+=(' ' if expected_description else '')+'('+typ+')'
            check(quote+' Description '+source_line['Id'],actual_line.get('LineDescriptionWithType','')==expected_description)
            descriptions+=1; rates+=bool(rate)
    findings.append({'quote':quote,'grouped':x['IF_QuoteLineGroupsPresentTrue'],'shipTo':x['MultipleShipToAccounts'],'lines':count,'rateDetailLines':rates,'groupOrder':[g['Name'] for g in actual_groups]})
patch=read(R/'candidate/mapper-change-spec.json')
before=read(D/'before-mapper-items.json'); after=read(D/'after-mapper-items.json'); b={r['Id']:r for r in before}; a={r['Id']:r for r in after}
check('Exactly four mapper records added',len(after)==len(before)+4)
updated={r['Id'] for r in patch['updates']}
def stable(row):return {k:v for k,v in row.items() if k not in ['attributes','LastModifiedDate','SystemModstamp','LastModifiedById','LastViewedDate','LastReferencedDate']}
check('Other 162 mapper records unchanged',all(stable(b[i])==stable(a[i]) for i in b if i not in updated))
for u in patch['updates']:check('Formula deployed '+u['Id'],a[u['Id']]['FormulaExpression']==u['after'])
newrows=[r for i,r in a.items() if i not in b]
for c in patch['creates']:
    found=next((r for r in newrows if r['GlobalKey']==c['GlobalKey']),None)
    check('New mapper rule '+c['GlobalKey'],found and all((found.get(k) or None)==(v or None) for k,v in c.items()))
receipt=read(D/'template-upload-receipt.json')
check('Live template references uploaded version',read(D/'after-template-links.json')[0]['LatestContentVersionId']==receipt['id'])
check('Template still active',read(D/'after-template.json')[0]['IsActive'])
report={'checks':checks,'passed':sum(c['pass'] for c in checks),'total':len(checks),'scenarios':findings,'contentVersionId':receipt['id'],
    'pending':'Browser-generated document visual acceptance, including automatic Term numbering; missing-term test data remains unchanged.'}
(D/'verification-results.json').write_text(json.dumps(report,indent=2))
print(f'{report["passed"]}/{report["total"]} checks passed.')
for c in checks:
    if not c['pass']:print('FAIL',c['check'],c['detail'])
print(json.dumps(findings,indent=2))
assert all(c['pass'] for c in checks)
