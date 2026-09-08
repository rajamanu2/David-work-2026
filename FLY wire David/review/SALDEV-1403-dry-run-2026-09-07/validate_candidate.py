"""Offline checks of the exact candidate and captured live data, not native validation."""
import json, re
from pathlib import Path
from zipfile import ZipFile
from xml.etree import ElementTree as ET
from collections import Counter, defaultdict

R=Path(__file__).resolve().parent; E=R/'evidence'; C=R/'candidate'
results=[]
def check(name, condition, detail=''):
    results.append({'check':name,'status':'PASS' if condition else 'FAIL','detail':detail})
def read(name): return json.loads((E/name).read_text(encoding='utf-8-sig'))
payloads={}
for filename in ['baseline-result.json','baseline-extra-result.json']:
    data=read(filename)
    check(filename+' execution',data['status']==0 and data['result']['success'])
    log=data['result']['logs']
    check(filename+' no DML',not re.search(r'\|DML_BEGIN\|',log),'Read-only current configuration execution')
    for line in log.splitlines():
        if '|USER_DEBUG|' not in line: continue
        m=re.search(r'SALDEV1403_BASELINE(?:&#124;|\|)(Q-\d+)(?:&#124;|\|)(\{.*)',line)
        if m: payloads[m[1]]=json.loads(m[2])
(E/'baseline-payloads.json').write_text(json.dumps(payloads,indent=2))
for name,payload in payloads.items():
    check(name+' native baseline mapper errors',not payload['extractErrors'] and not payload['transformErrors'])
    x=payload['transformed']
    check(name+' Ship-To flag',bool(x['IF_MultipleShipToAccounts'])==(x['MultipleShipToAccounts']=='Yes'))
    check(name+' grouped flag exclusivity',bool(x['IF_QuoteLineGroupsPresentTrue']) != bool(x['IF_QuoteLineGroupsPresentFalse']))

patch=json.loads((C/'mapper-change-spec.json').read_text())
check('Local-only scope',patch['deploy'] is False and patch['activate'] is False)
check('Exact mapper change scope',len(patch['creates'])==4 and len(patch['updates'])==2)
source=read('mapper-items.json')['result']['records']; byid={x['Id']:x for x in source}
check('Formula before-values match live snapshot',all(byid[u['Id']][u['field']]==u['before'] for u in patch['updates']))
check('Preserve whole group list mapping',any(x['InputFieldName']=='QuoteLineGroup' and x['OutputFieldName']=='Group' and not x['IsDisabled'] for x in source))
check('Preserve amendment exclusion filters',sum(x['FilterValue']=='"Amendment"' and x['FilterOperator']=='<>' and not x['IsDisabled'] for x in source)==2)

# Evaluate the actual proposed formula AST, with lazy IF branches and null inputs.
def parse(s):
    tokens=re.findall(r'"[^"\\]*(?:\\.[^"\\]*)*"|[A-Za-z_][A-Za-z_0-9:]*|[(),=]',s)
    i=0
    def expr():
        nonlocal i
        token=tokens[i]; i+=1
        if token.startswith('"'): node=('literal',json.loads(token))
        elif i<len(tokens) and tokens[i]=='(':
            i+=1; args=[]
            if tokens[i]!=')':
                args.append(expr())
                while tokens[i]==',': i+=1; args.append(expr())
            assert tokens[i]==')'; i+=1; node=(token,args)
        else: node=('field',token)
        if i<len(tokens) and tokens[i]=='=':
            i+=1; node=('=',[node,expr()])
        return node
    node=expr(); assert i==len(tokens); return node
def evaluate(node,row):
    op,args=node
    if op=='literal':return args
    if op=='field':return row.get(args)
    if op=='IF':return evaluate(args[1] if evaluate(args[0],row) else args[2],row)
    vals=[evaluate(x,row) for x in args]
    if op=='ISBLANK':return vals[0] in (None,'')
    if op=='CONCAT':return ''.join('' if x is None else str(x) for x in vals)
    if op=='=':return vals[0]==vals[1]
    raise AssertionError(op)
cases=0
for update in patch['updates']:
    prefix=update['preservedFormulaResultPath'].rsplit(':',1)[0]; ast=parse(update['after'])
    for desc,rate in [(None,None),('Base description',None),(None,'USD 10 per unit'),('Base description','USD 10 per unit')]:
        for typ in ['New','Renewal','Cancellation','Quantity Increase','Quantity Reduction']:
            row={prefix+':LineDescription':desc,prefix+':RateDetails':rate,prefix+':QuoteLineType':typ}
            expected=' '.join(v for v in [desc,rate] if v)
            if typ in ['Cancellation','Quantity Increase','Quantity Reduction']:
                expected+=' ' if expected else ''; expected+='('+typ+')'
            assert evaluate(ast,row)==expected,(row,evaluate(ast,row),expected)
            cases+=1
check('Null-safe description formula cases',cases==40,f'{cases} exact candidate formula evaluations; includes amendment labels and rates')

groups=read('groups.json')['records']; lines=read('lines.json')['records']+read('lines-extra.json')['records']
def group_key(g):
    start=g['SBQQ__StartDate__c']; term=g['SBQQ__SubscriptionTerm__c']
    return (start is None,start or '',term is None,-(term or 0),g['SBQQ__Number__c'])
ordered=sorted([g for g in groups if g['SBQQ__Quote__r']['Name']=='Q-37912'],key=group_key)
check('Q-37912 expected group order', [x['Name'] for x in ordered]==['Group4','Group1','Group2','Group3'])
check('Exact proposed ORDER BY accepted by live SOQL', [x['Id'] for x in read('group-order-query.json')['records']]==[x['Id'] for x in ordered])
check('Q-37912 sequential header data', [f'Term {i}: {int(g["SBQQ__SubscriptionTerm__c"])} Months' for i,g in enumerate(ordered,1)]==['Term 1: 36 Months','Term 2: 12 Months','Term 3: 12 Months','Term 4: 12 Months'])
missing=[g for g in groups if g['SBQQ__SubscriptionTerm__c'] is None]

# Compare source QLE order with subtree traversal: catches parent/standalone/child interleaving.
line_results=[]
for quote in sorted({x['SBQQ__Quote__r']['Name'] for x in lines}):
    rows=[x for x in lines if x['SBQQ__Quote__r']['Name']==quote and x['Quote_Line_Type__c']!='Amendment']
    buckets=defaultdict(list)
    for row in rows:buckets[row['SBQQ__Group__c']].append(row)
    for gid,bucket in buckets.items():
        bucket=sorted(bucket,key=lambda r:r['SBQQ__Number__c']); ids={r['Id'] for r in bucket}
        children=defaultdict(list)
        for row in bucket:children[row['SBQQ__RequiredBy__c'] if row['SBQQ__RequiredBy__c'] in ids else None].append(row)
        expected=[]
        def visit(row):
            expected.append(row['Id'])
            for child in children[row['Id']]:visit(child)
        for row in children[None]:visit(row)
        actual=[r['Id'] for r in bucket]
        line_results.append(actual==expected)
    check(quote+' local QLE sort keeps bundle subtrees',all(line_results[-len(buckets):]))
check('Captured source line identities unique',len({x['Id'] for x in lines})==len(lines),f'{len(lines)} lines inspected')
readback=read('mapper-items-readback.json')['records']
def stable(rows):
    return sorted([{k:v for k,v in row.items() if k not in ['attributes','LastViewedDate','LastReferencedDate']} for row in rows],key=lambda r:r['Id'])
check('All 164 mapper items unchanged after dry run',stable(source)==stable(readback))
before_template=read('document-template.json')['result']['records'][0]
after_template=read('template-readback.json')['records'][0]
check('Template configuration unchanged after dry run',all(before_template[k]==v for k,v in after_template.items() if k!='attributes'))
check('Active OmniScript remains version 2',read('omniscript-readback.json')['records'][0]['IsActive'] and read('omniscript-readback.json')['records'][0]['VersionNumber']==2)
native_findings=[]
def array(value):return value if isinstance(value,list) else ([value] if isinstance(value,dict) else [])
for quote,payload in payloads.items():
    output=payload['transformed']; actual_groups=array(output.get('Group'))
    source_rows=[x for x in lines if x['SBQQ__Quote__r']['Name']==quote and x['Quote_Line_Type__c'] not in ('Amendment',None)]
    source_groups=[x for x in groups if x['SBQQ__Quote__r']['Name']==quote]
    comparisons=[]; actual_all=[]
    if output['IF_QuoteLineGroupsPresentTrue']:
        for g in source_groups:
            actual_group=next((x for x in actual_groups if x.get('Number')==g['SBQQ__Number__c']),{})
            actual=[x.get('ProductName') for x in array(actual_group.get('QuoteLine')) if x.get('ProductName')]
            expected=[x['SBQQ__ProductName__c'] for x in sorted(source_rows,key=lambda x:x['SBQQ__Number__c']) if x['SBQQ__Group__c']==g['Id']]
            comparisons.append({'group':g['Name'],'sameLineMultiset':Counter(actual)==Counter(expected),'matchesQLEOrder':actual==expected})
            actual_all+=actual
    else:
        actual_all=[x.get('ProductName') for x in array(output.get('Line')) if x.get('ProductName')]
        expected=[x['SBQQ__ProductName__c'] for x in sorted(source_rows,key=lambda x:x['SBQQ__Number__c']) if x['SBQQ__Group__c'] is None]
        comparisons.append({'group':'ungrouped','sameLineMultiset':Counter(actual_all)==Counter(expected),'matchesQLEOrder':actual_all==expected})
    native_findings.append({'quote':quote,'grouped':output['IF_QuoteLineGroupsPresentTrue'],'shipTo':output['MultipleShipToAccounts'],
      'actualGroupOrder':[x.get('Name') for x in actual_groups if x.get('Name')],
      'expectedGroupOrder':[x['Name'] for x in sorted(source_groups,key=group_key)],
      'outputLineCount':len(actual_all),'lineComparisons':comparisons})
(R/'native-baseline-findings.json').write_text(json.dumps(native_findings,indent=2))

ns={'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
with ZipFile(C/'CPQ Quote Proposal - SALDEV-1403 - dry-run.docx') as z:
    check('DOCX ZIP integrity',z.testzip() is None)
    root=ET.fromstring(z.read('word/document.xml'))
    text=''.join(root.itertext())
    check('No service date tokens or group name heading',all(s not in text for s in ['{{StartDate}}','{{EndDate}}','Service Period:','{{Name}}']))
    check('Both group branches use subscription term',text.count('{{SubscriptionTerm}} Months')==2)
    numbered=[p for p in root.findall('.//w:p',ns) if p.find('w:pPr/w:numPr',ns) is not None and '{{SubscriptionTerm}}' in ''.join(p.itertext())]
    check('Both headings use sequential Word numbering',len(numbered)==2 and b'Term %1:' in z.read('word/numbering.xml'))
    stack=[]
    for kind,name in re.findall(r'{{([#/])([^}]+)}}',text):
        if kind=='#':stack.append(name)
        else: assert stack and stack.pop()==name
    check('Template conditional nesting',not stack)
    old=ET.fromstring(ZipFile(E/'current-template.docx').read('word/document.xml'))
    oldtables=old.findall('.//w:tbl',ns); newtables=root.findall('.//w:tbl',ns)
    check('All original tables preserved',len(oldtables)==len(newtables) and all(ET.tostring(a)==ET.tostring(b) for a,b in zip(oldtables,newtables)))
report={'scope':'Offline candidate checks and read-only current-org baseline; NOT a native candidate execution or deployment validation',
        'results':results,'nativeBaselineQuotes':list(payloads),
        'missingTermGroups':[{'quote':g['SBQQ__Quote__r']['Name'],'group':g['Name']} for g in missing],
        'pending':['Native execution of candidate mapper changes','Native DocGen preservation of sequential Word numbering','Generated-document business UAT','Metadata API check-only unavailable for these records']}
(R/'validation-results.json').write_text(json.dumps(report,indent=2))
print(f'{sum(r["status"]=="PASS" for r in results)}/{len(results)} checks passed; {len(payloads)} native baseline quotes; {len(missing)} groups lack term data.')
for r in results:
    if r['status']!='PASS':print(r)
assert all(x['status']=='PASS' for x in results)
