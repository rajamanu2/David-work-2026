"""Build a local-only proposal template and guarded mapper change specification."""
import copy, hashlib, json, uuid
from pathlib import Path
from docx import Document
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

ROOT = Path(__file__).resolve().parent
E = ROOT/'evidence'
C = ROOT/'candidate'
C.mkdir(exist_ok=True)
items = json.loads((E/'mapper-items.json').read_text(encoding='utf-8-sig'))['result']['records']
extract = 'GetQuoteProposalDataSteppedUpPricing'
transform = 'CPQQuoteProposalDocumentSteppedUpPricing'
patch = {'story':'SALDEV-1403', 'targetOrg':'FlywirePartial', 'verifiedOrgId':'00DhG0000000jOXUAY',
         'deploy':False, 'activate':False, 'status':'LOCAL CANDIDATE - native validation pending',
         'sourceSha256':hashlib.sha256((E/'mapper-items.json').read_bytes()).hexdigest(),
         'creates':[], 'updates':[],
         'exclusions':['SALDEV-1420','OmniScript activation','Business record updates','ContentVersion upload','Experimental Apex serializers']}
def create(source, changes, key):
    # Carry only configuration fields; never copy audit fields or record IDs.
    fields = ['Name','OmniDataTransformationId','InputObjectName','InputObjectQuerySequence',
              'InputFieldName','OutputFieldName','OutputObjectName','OutputCreationSequence',
              'FilterGroup','FilterOperator','FilterValue','IsDisabled']
    row = {k:source[k] for k in fields if source.get(k) is not None}
    row.update(changes, GlobalKey=str(uuid.uuid5(uuid.NAMESPACE_URL,'SALDEV1403-20260907-'+key)))
    patch['creates'].append(row)
for path, expression in [
    ('SBQuote:QuoteLineGroup','SBQQ__StartDate__c ASC NULLS LAST, SBQQ__SubscriptionTerm__c DESC NULLS LAST, SBQQ__Number__c ASC'),
    ('SBQuote:QuoteLineGroup:QuoteLine','SBQQ__Number__c ASC'),
    ('SBQuote:UngroupedLine','SBQQ__Number__c ASC')]:
    source = next(x for x in items if x['Name']==extract and x['OutputFieldName']==path and x['FilterOperator']=='=')
    assert not any(x['OutputFieldName']==path and x['FilterOperator']=='ORDER BY' for x in items)
    create(source, {'InputFieldName':'','FilterOperator':'ORDER BY','FilterValue':expression},path)
source = next(x for x in items if x['OutputFieldName']=='QuoteLineGroup:Number')
create(source, {'InputFieldName':'SBQuote:QuoteLineGroup:SBQQ__SubscriptionTerm__c',
                'OutputFieldName':'QuoteLineGroup:SubscriptionTerm'}, 'group-term')

def description_formula(prefix):
    d, r, t = [prefix+':'+x for x in ('LineDescription','RateDetails','QuoteLineType')]
    base = f'IF(ISBLANK({d}), "", {d})'
    rate = f'IF(ISBLANK({r}), "", CONCAT(IF(ISBLANK({d}), "", " "), {r}))'
    label = f'CONCAT(IF(ISBLANK({d}), IF(ISBLANK({r}), "", " "), " "), "(", {t}, ")")'
    suffix = f'IF({t} = "Cancellation", {label}, IF({t} = "Quantity Increase", {label}, IF({t} = "Quantity Reduction", {label}, "")))'
    return f'CONCAT({base}, {rate}, {suffix})'
for prefix in ['QuoteLineGroup:QuoteLine','UngroupedLine']:
    row = next(x for x in items if x['Name']==transform and x.get('FormulaResultPath','') and x['FormulaResultPath'].lower()==(prefix+':LineDescriptionWithType').lower())
    patch['updates'].append({'Id':row['Id'],'GlobalKey':row['GlobalKey'],'Name':row['Name'],
       'field':'FormulaExpression','before':row['FormulaExpression'],'after':description_formula(prefix),
       'preservedFormulaResultPath':row['FormulaResultPath']})
(C/'mapper-change-spec.json').write_text(json.dumps(patch,indent=2),encoding='utf-8')

doc = Document(E/'current-template.docx')
# Word decimal numbering gives each rendered group a sequential display ordinal.
# It does not reuse SBQQ__Number__c, which would produce 4,1,2,3 after sorting Q-37912.
# Native DocGen preservation of this numbering is a required later integration gate.
numbering = doc.part.numbering_part.element
abstract_id = max([int(x.get(qn('w:abstractNumId'))) for x in numbering.findall(qn('w:abstractNum'))]+[-1])+1
num_id = max([int(x.get(qn('w:numId'))) for x in numbering.findall(qn('w:num'))]+[0])+1
abstract = OxmlElement('w:abstractNum'); abstract.set(qn('w:abstractNumId'), str(abstract_id))
lvl=OxmlElement('w:lvl'); lvl.set(qn('w:ilvl'),'0')
for tag, value in [('start','1'),('numFmt','decimal'),('lvlText','Term %1:'),('suff','space'),('lvlJc','left')]:
    el=OxmlElement('w:'+tag); el.set(qn('w:val'),value); lvl.append(el)
abstract.append(lvl); numbering.append(abstract)
rp=OxmlElement('w:rPr'); bold=OxmlElement('w:b'); rp.append(bold)
sz=OxmlElement('w:sz'); sz.set(qn('w:val'),'24'); rp.append(sz); lvl.append(rp)
num=OxmlElement('w:num'); num.set(qn('w:numId'),str(num_id))
ref=OxmlElement('w:abstractNumId'); ref.set(qn('w:val'),str(abstract_id)); num.append(ref); numbering.append(num)
changed=0; removed=0
for p in list(doc.paragraphs):
    if p.text=='{{Name}}':
        p.runs[0].text='{{SubscriptionTerm}} Months'
        for r in p.runs[1:]: r.text=''
        p.paragraph_format.keep_with_next=True
        pr=p._p.get_or_add_pPr(); np=OxmlElement('w:numPr')
        for tag,value in [('ilvl','0'),('numId',str(num_id))]:
            el=OxmlElement('w:'+tag); el.set(qn('w:val'),value); np.append(el)
        pr.append(np); changed+=1
    elif p.text=='Service Period: {{StartDate}} to {{EndDate}}':
        p._p.getparent().remove(p._p); removed+=1
assert changed==2 and removed==2
doc.save(C/'CPQ Quote Proposal - SALDEV-1403 - dry-run.docx')
print('Created local candidate: two group headings changed; two service-period paragraphs removed; four mapper creates and two formula updates.')
