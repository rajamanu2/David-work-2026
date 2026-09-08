from pathlib import Path
from copy import deepcopy
from docx import Document
from docx.enum.section import WD_SECTION_START
from docx.shared import RGBColor
from docx.oxml.ns import qn
from lxml import etree
import zipfile

folder=Path('outputs/business_templates_2026-09-08')
a=Document(folder/'Probo_Medical_Business_Requirements_Presentation_Template.docx')
b=Document(folder/'Probo_Medical_Full_Fillable_Requirements_Workbook.docx')
# Both documents contain native text, tables and fields without linked media.
for doc in [a,b]:
 assert not doc.element.xpath('.//w:drawing | .//w:object | .//w:hyperlink')
expected=len(b.element.xpath('.//w:sdt'))
section=a.add_section(WD_SECTION_START.NEW_PAGE)
section.different_first_page_header_footer=True
for child in b.element.body:
 if child.tag!=qn('w:sectPr'): a.element.body.insert(len(a.element.body)-1,deepcopy(child))
a.styles['Caption'].font.color.rgb=RGBColor(0,0,0)
for section in a.sections:
 for header in [section.header, section.first_page_header]:
  for p in header.paragraphs:
   if p.text:p.text='PROBO MEDICAL                                      BUSINESS REQUIREMENTS'
 for footer in [section.footer,section.first_page_footer]:
  for p in footer.paragraphs:
   if p.runs:p.runs[0].text='Probo Medical  |  Requirements and completion workbook'
a.core_properties.title='Probo Medical Business Requirements and Fillable Workbook'
a.core_properties.subject='Combined business presentation template and full fillable requirements workbook'
out=folder/'Probo_Medical_Combined_Requirements_and_Fillable_Workbook.docx'
a.save(out)
with zipfile.ZipFile(out) as z:
 assert z.testzip() is None
 root=etree.fromstring(z.read('word/document.xml'))
 ns={'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
 assert len(root.xpath('//w:sdt',namespaces=ns))==expected==171
 # Every body text item from each source remains present in order.
 merged=root.xpath('//w:t/text()',namespaces=ns)
 original=a.element.xpath('.//w:t/text()')
 assert merged==original
print(str(out.resolve()))
print('Preserved 171 fillable controls; two document sections')
