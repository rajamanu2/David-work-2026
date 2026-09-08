from pathlib import Path
import json
BASE=Path(__file__).resolve().parents[2]
source=(BASE/'flywire-docgen/scripts/build_sald1403_artifacts_list.py').read_text()
exec(source.split('p = doc.add_paragraph(style="Title")')[0])
OUT=BASE/'review/SALDEV-1403-artifact-list/SALDEV-1403-Updated-Artifacts-and-Deployment-List.docx'
for st in doc.styles:
 if st.type==1:st.font.color.rgb=RGBColor(0,0,0)
 for x in list(st.element.iter(qn('w:pBdr'))):x.getparent().remove(x)
for rr in header.runs:rr.font.color.rgb=RGBColor(0,0,0)
doc.core_properties.author='Salesforce QA'
doc.core_properties.title='SALDEV 1403 Artifacts and Deployment List'
def p(t,bold=False):
 x=doc.add_paragraph();style_paragraph(x,after=6);set_run(x.add_run(t),size=10,bold=bold,color='000000');return x
def title(t):doc.add_paragraph(t,style='Title')
def heading(t):doc.add_paragraph(t,style='Heading 2')
number=0
def page(t):
 global number
 number=0
 doc.add_page_break();doc.add_paragraph(t,style='Heading 1')
def add_numbered(doc,text):
 global number
 number+=1
 pp=doc.add_paragraph();style_paragraph(pp,after=3,line=1.08)
 set_run(pp.add_run(f'{number}. {text}'),size=10,color='000000')
def matrix(headers,rows,widths,size=9):
 t=doc.add_table(rows=1,cols=len(headers));t.style='Table Grid'
 for c,text in zip(t.rows[0].cells,headers):
  set_cell_shading(c,NAVY);set_run(c.paragraphs[0].add_run(text),size=9.5,bold=True,color=WHITE)
 t.rows[0]._tr.get_or_add_trPr().append(OxmlElement('w:tblHeader'))
 for ri,row in enumerate(rows):
  cells=t.add_row().cells
  for ci,text in enumerate(row):
   if ri%2==1:set_cell_shading(cells[ci],LIGHT_GRAY)
   pp=cells[ci].paragraphs[0];style_paragraph(pp,after=0,line=1.02)
   set_run(pp.add_run(text),size=size,bold=ci==0,color='000000')
 for row in t.rows:
  row._tr.get_or_add_trPr().append(OxmlElement('w:cantSplit'))
  for c in row.cells:
   c.vertical_alignment=WD_CELL_VERTICAL_ALIGNMENT.CENTER
   b=OxmlElement('w:tcBorders')
   for edge in ['top','left','bottom','right']:
    e=OxmlElement('w:'+edge);e.set(qn('w:val'),'single');e.set(qn('w:sz'),'4');e.set(qn('w:color'),'D9D9D9');b.append(e)
   c._tc.get_or_add_tcPr().append(b)
 set_table_geometry(t,widths)
 return t

title('SALDEV 1403 Artifacts and Deployment List')
p('Story: Update output documents for stepped-up pricing (OmniStudio)   |   Reference environment: FlywirePartial   |   7 September 2026')
p('Required change set: two Data Mappers and one proposal DOCX. No Apex class or Apex test is required. These changes are already present in Partial; this list describes the scope to promote to another approved environment, not a request to repeat the Partial deployment.',True)
matrix(['Type and action','Component name','Source API name or record ID','Dependency','Change and deployment scope'],[
['Extract Data Mapper\nINCLUDE','GetQuoteProposalDataSteppedUpPricing','0jIhG0000000GsnUAE\nType: Extract','Quote, Quote Line Group and Quote Line data','Four added items: group start-date/term/sequence sorting; grouped line sorting; ungrouped line sorting; group subscription-term mapping. Preserve the other Extract items.'],
['Transform Data Mapper\nINCLUDE','CPQQuoteProposalDocumentSteppedUpPricing','0jIhG0000000HX7UAM\nType: Transform','Extract output and existing document token model','Two Description formula updates: append Rate Details with null-safe spacing and preserve Cancellation, Quantity Increase and Quantity Reduction suffixes.'],
['Template content\nINCLUDE','CPQ Quote Proposal\nUpdated proposal DOCX','ContentVersion: 068hG000003PryiQAC\nContentDocument: 069hG000003DZfnQAG','Existing CPQ Quote Proposal template and content link','Both grouped branches use sequential Term n: XX Months headings. Remove both service-period paragraphs. Preserve tables, signature content and Ship-To conditions.'],
['Document Template\nDEPENDENCY ONLY','CPQ Quote Proposal','2dtPb0000000BwLIAU\nMicrosoftWord / ClientSide\nLink: 2ddhG0000001bwnQAA','Transform output and proposal content','Existing template configuration is unchanged. Verify the target template and its content link resolve to the updated DOCX. Do not add an unrelated template-record change.'],
['OmniScript\nDEPENDENCY ONLY','Generate Quote Document - SteppedUpPricing\nExisting version 2','0jNhG0000000umzUAA\nCPQ / QuoteDocument / English','Both Data Mappers and template-selection action','Existing entry point is unchanged. Verify it exists and is active in the target. No new OmniScript version or activation change belongs to this fix.']
],[1550,2600,2900,2350,5000],9)
p('Recommended order: 1) Extract Data Mapper  2) Transform Data Mapper  3) Proposal DOCX and existing content association  4) Verify dependencies  5) Run the scoped validation and business tests.')
p('All record IDs shown are Partial reference IDs. Resolve records and relationships in the target org; do not reuse source IDs as target IDs.')

page('Exact changes and deployment handling')
matrix(['Changed item','Partial item ID','Required behavior'],[
['Extract group order','0kdhG0000003FiTQAU','ORDER BY SBQQ__StartDate__c ASC NULLS LAST, SBQQ__SubscriptionTerm__c DESC NULLS LAST, SBQQ__Number__c ASC'],
['Extract grouped line order','0kdhG0000003FiUQAU','ORDER BY SBQQ__Number__c ASC on grouped Quote Lines.'],
['Extract ungrouped line order','0kdhG0000003FiVQAU','ORDER BY SBQQ__Number__c ASC on ungrouped Quote Lines.'],
['Extract group term mapping','0kdhG0000003FiWQAU','SBQuote:QuoteLineGroup:SBQQ__SubscriptionTerm__c → QuoteLineGroup:SubscriptionTerm'],
['Transform grouped Description','0kdhG0000002nUTQAY','Update FormulaExpression. Preserve result path QuoteLineGroup:QuoteLine:LineDescriptionWithType.'],
['Transform ungrouped Description','0kdhG0000002m5NQAQ','Update FormulaExpression. Preserve existing result path UngroupedLine:LineDescriptionWIthType.']
],[3100,2800,8500],9.5)
heading('How to package the changes')
for text in [
'Use the two named Data Mappers and the updated DOCX as the artifact allowlist. The item-level delta is four additions and two formula updates; a whole-mapper export must preserve all unrelated items.',
'The Partial run used scoped configuration-record changes and a new ContentVersion, not a successful Metadata API package. The recorded Metadata API retrieval did not expose these mapper/template records. Confirm the supported OmniStudio transfer mechanism in the destination before preparing an import-ready package.',
'Resolve the target CPQ Quote Proposal template and ContentDocument, then associate the updated DOCX with that existing template. The source file is CPQ Quote Proposal - SALDEV-1403 - dry-run.docx; the verified Partial ContentVersion is listed on page 1.',
'Refresh only the two affected Data Mapper caches if required by the target workflow. Verify the existing OmniScript remains available and invokes the expected mappers/template. This does not require a new OmniScript version.',
'After transfer, independently compare the six item changes and proposal bytes, then run the native Extract/Transform checks and fresh document tests.']:
 add_numbered(doc,text)
heading('Do not include')
p('No Apex class, Apex test, LWC, Flow, custom field, permission set or Visualforce change is required for this fix. Exclude the historical CPQQuoteProposalOutputSerializer and its test utilities. SALDEV-1420 approval-email components are separate and must not be added to this package. Local scripts, validation JSON and render folders are supporting evidence, not deployable Salesforce components.')

page('Validation and business test steps')
p('Latest recorded Partial dry run: 236 of 236 backend checks passed across eight native Extract/Transform executions and 153 eligible product rows. Configuration and proposal bytes matched the verified changes. Generated-document appearance and sequential Term numbering still require business acceptance.',True)
heading('Main reproduction case')
for text in [
'Open Q-37912 in FlywirePartial: https://flywire--partial.sandbox.lightning.force.com/lightning/r/SBQQ__Quote__c/a2NhG000003lAjmUAE/view. Capture the current group dates, terms and product order in Edit Lines.',
'Choose Generate Document or Generate Quote Document using the existing stepped-up-pricing action. Select CPQ Quote Proposal when prompted and open a fresh Preview or generated document.',
'Expect Group4, Group1, Group2, Group3, headed Term 1: 36 Months and Terms 2, 3 and 4: 12 Months. Confirm no service dates in group headings and that numbering restarts at 1 for a second document.',
'Compare all 78 eligible rows with QLE: correct group, product order, bundle-child placement and no duplicate/missing lines. Ship-To Account should be hidden for this quote. Capture output evidence.']:
 add_numbered(doc,text)
matrix(['Quote','Regression purpose','Expected result'],[
['Q-37640','Grouped; Ship-To No','Three 12-month groups; 12 rows; Ship-To hidden. This is no longer an ungrouped case.'],
['Q-38009 / Q-38023','Ungrouped new quotes','9 / 2 rows; Ship-To visible / hidden respectively; no Term or Group header.'],
['Q-38021','Ungrouped renewal','20 rows in QLE order; Ship-To hidden; Rate Details inside Description.'],
['Q-37723 / Q-37780','Grouped structure and Ship-To','14 / 18 rows; Ship-To visible / hidden. Missing group terms limit these to structure checks.'],
['Q-38029','Amendment exclusion','Two Amendment source lines excluded; zero eligible rows. Positive amendment output requires another suitable record.']
],[2000,3400,9000],9.5)
heading('Acceptance and evidence')
p('Verify Rate Details in Description, readable spacing, blank-value handling, preserved line-type suffixes and final table/page layout. Use records with populated group terms for full heading acceptance. Save quote ID, test date, generated filename, source QLE screenshot, output screenshot, expected/actual result and Pass/Fail/Blocked. Obtain business acceptance after these checks; backend success alone does not close the story.')
p('Prepared as an updated artifact list using the supplied reference layout. No deployment was performed while preparing this document.')
OUT.parent.mkdir(exist_ok=True);doc.save(OUT);print(OUT)
