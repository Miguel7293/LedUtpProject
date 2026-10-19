"""Generate the fictional knowledge source; run from any working directory."""
from pathlib import Path
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer

ROOT = Path(__file__).resolve().parents[1]
out = ROOT / 'output/pdf/banco-abc-guia-marca.pdf'
out.parent.mkdir(parents=True, exist_ok=True)
styles = getSampleStyleSheet()
styles['Title'].textColor = colors.HexColor('#123D57')
sections = [
    ('Identidad y tono', 'Banco ABC es una marca ficticia para un laboratorio educativo. Habla de tú con respeto, claridad y cercanía. Usa español de Perú, frases breves y beneficios concretos. No uses presión, miedo ni urgencia artificial.'),
    ('Correo, SMS y pop-up', 'Correo: asunto breve, preheader complementario y cuerpo claro. SMS: máximo 160 caracteres. Pop-up: título breve y mensaje directo. Cierra con una invitación a consultar condiciones. Todo contenido es un borrador sujeto a revisión humana.'),
    ('Exactitud comercial', 'Solo se pueden comunicar beneficios y condiciones del catálogo vigente. No inventes porcentajes, montos, tasas, fechas ni aprobaciones de crédito. No prometas rentabilidad ni aprobación garantizada. Conserva literalmente las condiciones de cada campaña.'),
    ('Privacidad y consentimiento', 'Solo personaliza con intereses declarados y categorías de consumo ficticias. No menciones DNI, estado civil, hijos, ingresos o datos sensibles. Requiere consentimiento de marketing. No envíes mensajes: este laboratorio genera borradores.'),
    ('Dirección visual', 'Prompts de imágenes en inglés. Paleta azul petróleo y turquesa, luz natural y objetos relacionados con el interés comercial. Sin logotipos, texto, documentos, datos personales ni estereotipos demográficos. No generar imágenes automáticamente.'),
]
story = [Paragraph('BANCO ABC', styles['Title']), Paragraph('Guía de marca y comunicación', styles['Heading1']), Paragraph('Documento ficticio | Laboratorio 08 | Versión 1.0', styles['Normal']), Spacer(1, 20)]
for title, body in sections:
    story.extend([Paragraph(title, styles['Heading2']), Paragraph(body, styles['BodyText']), Spacer(1, 10)])
def footer(canvas, doc):
    canvas.setFont('Helvetica', 8)
    canvas.drawString(48, 30, 'Material educativo. No representa a una entidad bancaria real.')
    canvas.drawRightString(547, 30, str(doc.page))
SimpleDocTemplate(str(out), rightMargin=48, leftMargin=48, topMargin=40, bottomMargin=48).build(story, onFirstPage=footer, onLaterPages=footer)
print(out)
