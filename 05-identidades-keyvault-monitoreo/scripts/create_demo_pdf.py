from pathlib import Path
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from pypdf import PdfReader

root = Path(__file__).resolve().parents[1]
destination = root / 'output' / 'pdf' / 'documento-demo.pdf'
destination.parent.mkdir(parents=True, exist_ok=True)
styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name='Hero', fontName='Helvetica-Bold', fontSize=26, leading=30, textColor=colors.HexColor('#143D36'), spaceAfter=20))
styles.add(ParagraphStyle(name='Text', fontName='Helvetica', fontSize=11, leading=17, textColor=colors.HexColor('#334B44'), spaceAfter=14))
story = [Paragraph('LEAD UTP / LABORATORIO 05', styles['Heading3']), Spacer(1, 14),
    Paragraph('Acceso seguro<br/>a documentos', styles['Hero']),
    Paragraph('Este PDF demuestra la lectura de un documento privado en Azure Storage mediante la identidad administrada de una máquina virtual.', styles['Text'])]
data = [[Paragraph('<b>Componente</b>', styles['Text']), Paragraph('<b>Responsabilidad</b>', styles['Text'])],
        [Paragraph('VM01', styles['Text']), Paragraph('Solicita un token temporal al servicio de identidad de Azure.', styles['Text'])],
        [Paragraph('Azure Storage', styles['Text']), Paragraph('Autoriza la lectura del contenedor documents mediante RBAC.', styles['Text'])],
        [Paragraph('Verificación', styles['Text']), Paragraph('Compara la huella SHA-256 del archivo original y del documento leído por la VM.', styles['Text'])]]
table = Table(data, colWidths=[125, 360], hAlign='LEFT')
table.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#E5EEE8')),('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),12),('RIGHTPADDING',(0,0),(-1,-1),12),('TOPPADDING',(0,0),(-1,-1),10),('BOTTOMPADDING',(0,0),(-1,-1),5),('LINEBELOW',(0,0),(-1,-1),0.5,colors.HexColor('#D3DFD5'))]))
story += [Spacer(1, 12), table, Spacer(1, 25), Paragraph('Datos de demostración. No contiene información personal, contraseñas ni claves de acceso.', styles['Text']), Paragraph('Identificador: LEAD_UTP_MI_STORAGE_DEMO', styles['Code'])]
def footer(canvas, document):
    canvas.setFont('Helvetica',9)
    canvas.setFillColor(colors.HexColor('#64786E'))
    canvas.drawString(50,35,'LEAD UTP - Identidades, Key Vault y monitoreo')
    canvas.drawRightString(A4[0]-50,35,str(document.page))
SimpleDocTemplate(str(destination), pagesize=A4, rightMargin=50, leftMargin=50, topMargin=50, bottomMargin=55, title='LEAD UTP - Documento privado de demostración').build(story,onFirstPage=footer,onLaterPages=footer)
reader = PdfReader(destination)
assert len(reader.pages) == 1
assert 'LEAD_UTP_MI_STORAGE_DEMO' in reader.pages[0].extract_text()
print(destination)
