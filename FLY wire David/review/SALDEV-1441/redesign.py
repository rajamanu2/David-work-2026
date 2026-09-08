from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
from copy import deepcopy
from hashlib import sha256
from lxml import etree as E
import json

root=Path(__file__).resolve().parent
ref=Path('C:/Users/LIKKI/.codex/plugins/cache/openai-curated-remote/openai-templates/0.1.1/skills/artifact-template-system-design/assets/reference.docx')
out=root/'SALDEV-1441_Architect_Review_Redesigned.docx'
ns={'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
W='{'+ns['w']+'}'
with ZipFile(ref) as z: parts={n:z.read(n) for n in z.namelist()}
doc=E.fromstring(parts['word/document.xml']); body=doc.find('w:body',ns)
ps=body.findall('w:p',ns); ts=body.findall('w:tbl',ns)
section=deepcopy(body.find('w:sectPr',ns))
inventory={n:{'size':len(v),'sha256':sha256(v).hexdigest(),'mode':'editable' if n in ['word/document.xml','word/footer1.xml','word/footer2.xml'] else 'preserve'} for n,v in parts.items()}
(root/'template-part-inventory.json').write_text(json.dumps(inventory,indent=2))
(root/'artifact.md').write_text(f'''# System Design template contract
Reference: {ref}
SHA256: {sha256(ref.read_bytes()).hexdigest()}
Reference render: template-reference.pdf, seven pages; template-render/page-1.png through page-7.png.
One letter portrait section, 8.5 x 11 inches. Margins top/left/right .7 inches, bottom .6201389 inches. Preserve section XML exactly.
Preserve all styles, theme, embedded Helvetica Neue fonts, numbering, relationships and header parts byte for byte. Detailed part inventory is template-part-inventory.json.
Typography: clone body paragraph 22 (Helvetica Neue, 1.25 line spacing, 5.5 pt after, justified), heading paragraph 21, subheading 35. Cover paragraphs 8 and 9 use 36 pt Helvetica Neue Light slate and Helvetica Neue navy. Preserve source run properties.
Cover: preserve paragraphs and two metadata tables through the first Heading 1. Replace cover title and metadata text only.
Content slots: replace the abstract with review decision and boundary; goals table with four requirement comparisons; background with group isolation example. Reuse heading and prose components for architecture, findings and testing pages. Omit unsupported generic API, security, alternatives, rollout and example diagram slots. Add explicit page starts for the four review sections. Reuse the two-column table style only for requirements; long findings remain prose.
Editable locators: document.xml/body/p[9:10] cover; first two body tables metadata; cloned p[22] heading, p[23] body, p[36] subheading; table[3] requirement matrix. Footer text slot replaces organization placeholder with story identifier. All unused template body placeholders are removed.
Footer geometry preserved; footer text becomes SALDEV-1441 | Architect Review. Source diagram media remains preserved but its optional example is not used. No external facts or rollout authority are added.
Fidelity gates: preserve-only hashes match, no placeholder text, unchanged section, valid XML, inspect every final rendered page. Reference remains unchanged.
''')

def replace_text(el,text):
    nodes=el.findall('.//w:t',ns)
    if nodes:
        nodes[0].text=text
        for n in nodes[1:]: n.text=''
    else:
        r=E.SubElement(el,W+'r'); E.SubElement(r,W+'t').text=text
    return el

def para(text,index=22,newpage=False):
    p=deepcopy(ps[index])
    for b in p.findall('.//w:bookmarkStart',ns)+p.findall('.//w:bookmarkEnd',ns): b.getparent().remove(b)
    p.attrib.clear()
    replace_text(p,text)
    pr=p.find('w:pPr',ns)
    if newpage: E.SubElement(pr,W+'pageBreakBefore')
    body.append(p)
    return p
def h(text,newpage=False): para(text,21,newpage)
def sub(title,text): para(title,35); para(text)
def table(template,rows):
    t=deepcopy(ts[template]); trs=t.findall('w:tr',ns)
    for tr,row in zip(trs,rows):
        for cell,text in zip(tr.findall('w:tc',ns),row): replace_text(cell,text)
    body.append(t)
    return t

# Preserve the cover's real layout elements and replace its text in place.
cover=[]
for child in body:
    if child is ps[21]: break
    cover.append(deepcopy(child))
for child in list(body): body.remove(child)
for child in cover: body.append(child)
coverps=body.findall('w:p',ns)
replace_text(coverps[8],'SALDEV 1441')
replace_text(coverps[9],'Architect Review')
ct=body.findall('w:tbl',ns)
for cell,texts in zip(ct[0].findall('w:tr/w:tc',ns),[['STATUS','Changes Requested'],[''],['REVIEW TYPE','Architecture'],[''],['LAST UPDATED','08 September 2026']]):
    cps=cell.findall('w:p',ns)
    for i,p in enumerate(cps): replace_text(p,texts[i] if i<len(texts) else '')
for row,values in zip(ct[1].findall('w:tr',ns),[
    ['Story','Step Up product validation and grouping'],
    ['Prepared for','David Okolo'],
    ['Source','SALDEV-1441 (1).docx'],
    ['Scope','Requirements and architecture review. No deployment.']]):
    for c,t in zip(row.findall('w:tc',ns),values):replace_text(c,t)

h('1  Review conclusion',True)
para('Changes Requested. The proposed group-aware QCP approach aligns with the business requirement. Architect sign-off remains pending because the story does not explain the one-time-product cloning change or include executed acceptance and regression results.')
para('This review assesses the supplied story and its implementation notes. The reported implementation has not been independently verified against source code or a Salesforce org. No tests, check-only validation, deployment or Salesforce changes were performed.')
h('2  Business requirements')
table(2,[['Scenario','Expected behavior'],['Step Up groups','Evaluate each group independently. Allow valid product repetition across separate ramping groups.'],['Standard groups','Preserve existing quote-wide errors, warnings and duplicate restrictions.'],['Ungrouped quotes','Preserve the existing validation behavior without requiring groups.'],['One time products','Keep implementation fees and other one-time products out of subsequent cloned groups.']])
h('3  Architecture principle')
para('A product in one Step-Up group must not satisfy a missing counterpart in another. For example, an Amex DOM line in Group 1 and an Amex XB line in Group 2 do not form a valid same-group pair. Each group must meet its own requirements.')
para('Automatic additions must also remain correct. The ticket says certain products will be supplied by cloning; this needs evidence alongside the validation tests.')

h('4  Proposed architecture assessment',True)
para('The ticket reports updates to four QCP methods. Their stated responsibilities are consistent with a shared validation context, subject to the checks below.')
sub('Amex pairing','validateAmexPairing reportedly checks DOM/XB pairs within each Step-Up group, including nested bundle lines. Confirm that the Amex attribute-mismatch hard stop remains covered; pairing alone does not prove attribute equality.')
sub('Financial Aid Disbursement','checkDuplicateQuoteLineUSLoanProduct reportedly checks the group and Ship To Account together. Each FAD product needs the corresponding DOM/XB product in that context, and duplicate FAD products in the same context must be rejected.')
sub('Payment method and country','checkPaymentAndCountryMatrixRules reportedly makes CC Country and MC/Visa Credit/Debit pairing group-aware while retaining payment method, country, quantity, currency, transaction type and Ship To matching criteria.')
sub('Surcharging','checkIdenticalSurchargePairRule reportedly requires Surcharging Yes/No counterparts within the same Step-Up group. A line from another group must not satisfy the requirement.')
sub('Shared context and error fields','The ticket says isStepUpLine, getGroupIdentity and getValidationContext are reused without changes, with non-Step-Up checks remaining quote-wide. Verify effective parent-group resolution and that any invalid group keeps the existing quote-level error flag set.')
sub('Configuration and cloning','The UK/Canada auto-add Product Rule a1thG0000004EsUQAU reportedly no longer applies to XB Payments FWXB1000. Confirm intended SFS behavior remains. HC Professional Services and applicable Payments XB additions rely on cloning; the two Payex rules are described as deactivated.')

h('5  Review findings',True)
para('These findings identify missing clarification or evidence. They do not establish that the implementation is defective.')
sub('AR 01  One time product cloning  High','The exclusion of one-time products is explicitly required by acceptance criterion 1.a, but the implementation notes do not describe this change. Identify the cloning code and show that one-time fees remain in the first group and are absent from all later cloned groups.')
sub('AR 02  Acceptance evidence  High','No executed test results are included. Provide valid and invalid examples for all applicable rules across Step-Up, standard grouped and ungrouped quotes, with expected and actual outcomes.')
sub('AR 03  Amex attribute validation  Medium','The design names the attribute-mismatch hard stop, but its coverage is not explicit in the implementation notes. Map it to the relevant logic and field, and demonstrate both a mismatch and a corrected pair.')
sub('AR 04  Group resolution and error aggregation  Medium','Provide a scoped code diff and results for nested bundles, newly cloned groups and multiple groups where only one is invalid. Confirm that a later valid group cannot clear another group’s error and that corrections clear stale flags.')
sub('AR 05  Automatic additions  Medium','Verify the products present before and after cloning. Confirm the UK/Canada change removes only the intended XB Payments applicability and preserves required SFS behavior.')
h('6  Dependencies and ownership')
para('SALDEV-1417 is listed as the group-type prerequisite. The one-time-product work was moved from SALDEV-1427 into this story on 17 August. The developer should identify the scoped changes, QA should provide test evidence, and the architect should reassess the findings before sign-off.')

h('7  Required acceptance tests',True)
para('Test all applicable rules in three modes: Step-Up groups with Allow Product Ramping checked, standard groups with it unchecked, and quotes with no groups. None of the following tests were executed in this review.')
sub('Pairing and duplicate rules','Amex: test DOM/XB pairing and attribute equality. FAD: test the same-group and Ship To relationship plus duplicate rejection. CC Country: test Locally Issued/Non-Locally Issued pairs. MC/Visa: test Credit/Debit pairs. Surcharging: test Yes/No pairs. Include valid and invalid cases and preserve all existing matching dimensions.')
sub('Cross group isolation','Split a required pair across Step-Up groups and confirm the error remains. Complete the pair within each group and confirm it clears. Repeat products across valid Step-Up groups while retaining applicable duplicate restrictions within a group.')
sub('Cloning and automatic additions','Clone multiple ramping groups. Confirm one-time fees are present only in the first group and recurring products copy as intended. Verify applicable HC and Payments XB additions, plus retained SFS behavior after the UK/Canada configuration change.')
sub('Architecture edge cases','Test nested bundles, newly cloned lines, distinct groups with the same start date, and quotes mixing standard and Step-Up groups. Confirm correct context separation. Correct or delete invalid lines and recalculate to check that error flags reflect the current state.')
h('8  Sign off evidence')
para('For each test, record the environment, quote ID, setup, expected result, actual result and supporting screenshots or equivalent evidence. Attach the scoped QCP and configuration diff, including the one-time cloning logic. Reassess all five findings when that evidence is available.')
h('9  Suggested ticket comment')
para('Architect review completed for SALDEV-1441 based on the supplied story. The group-aware QCP approach aligns with the requirement, but sign-off remains pending. Please identify the one-time-product cloning change, confirm Amex attribute-mismatch coverage, and provide the scoped diff and test results for Step-Up, standard grouped and ungrouped quotes. Include group isolation, error aggregation and automatic additions. No deployment was performed.')

body.append(section)
parts['word/document.xml']=E.tostring(doc,xml_declaration=True,encoding='UTF-8',standalone=True)
for name in ['word/footer1.xml','word/footer2.xml']:
    r=E.fromstring(parts[name])
    for p in r.findall('.//w:p',ns):
        if p.findall('.//w:t',ns): replace_text(p,'SALDEV-1441 | Architect Review')
    parts[name]=E.tostring(r,xml_declaration=True,encoding='UTF-8',standalone=True)
with ZipFile(out,'w',ZIP_DEFLATED) as z:
    for name,data in parts.items():z.writestr(name,data)
with ZipFile(out) as z:
    assert z.testzip() is None
    for name,entry in inventory.items():
        if entry['mode']=='preserve': assert sha256(z.read(name)).hexdigest()==entry['sha256'],name
    assert '[' not in ''.join(E.fromstring(z.read('word/document.xml')).itertext())
print(out)
print('All preserve-only parts unchanged; package integrity passed.')
