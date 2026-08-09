"""Prescription PDF generation (reportlab).

Only ISSUED prescriptions can be rendered. The document is returned over an
authenticated endpoint - it is never publicly accessible.
"""
from io import BytesIO

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_RIGHT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (
    HRFlowable,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

_PRIMARY = colors.HexColor("#00685F")
_GREY = colors.HexColor("#5F6B6A")


def _human_duration(item: dict) -> str:
    duration = item.get("duration")
    unit = item.get("duration_unit") or "days"
    if not duration:
        return ""
    return f"for {duration} {unit}"


def _dose_line(item: dict) -> str:
    parts = [part for part in (
        item.get("dose") or "",
        item.get("frequency") or "",
        (item.get("timing") or "").lower(),
        _human_duration(item),
    ) if part]
    return " ".join(parts)


def build_prescription_pdf(rx: dict, doctor: dict, patient: dict) -> bytes:
    """Render an issued prescription to PDF bytes."""
    buf = BytesIO()
    doc = SimpleDocTemplate(
        buf,
        pagesize=A4,
        topMargin=18 * mm,
        bottomMargin=18 * mm,
        leftMargin=18 * mm,
        rightMargin=18 * mm,
        title=f"Prescription {rx['id']}",
        author=doctor.get("name") or rx.get("doctor_name") or "",
    )

    styles = getSampleStyleSheet()
    brand = ParagraphStyle(
        "brand", parent=styles["Title"], fontSize=24, textColor=_PRIMARY,
        spaceAfter=2,
    )
    subtitle = ParagraphStyle(
        "subtitle", parent=styles["Normal"], fontSize=9, textColor=_GREY,
        spaceAfter=10,
    )
    section = ParagraphStyle(
        "section", parent=styles["Normal"], fontSize=9, textColor=_GREY,
        spaceBefore=8, spaceAfter=4, fontName="Helvetica-Bold",
    )
    label = ParagraphStyle(
        "label", parent=styles["Normal"], fontSize=8, textColor=_GREY,
        fontName="Helvetica-Bold",
    )
    value = ParagraphStyle(
        "value", parent=styles["Normal"], fontSize=11, spaceAfter=6,
    )
    rx_style = ParagraphStyle(
        "rx", parent=styles["Normal"], fontSize=12, fontName="Helvetica-Bold",
        spaceBefore=6, spaceAfter=4,
    )
    med_style = ParagraphStyle(
        "med", parent=styles["Normal"], fontSize=11, spaceAfter=1,
    )
    dose_style = ParagraphStyle(
        "dose", parent=styles["Normal"], fontSize=9.5, textColor=colors.HexColor("#333333"),
        spaceAfter=7, leftIndent=12,
    )
    footnote = ParagraphStyle(
        "footnote", parent=styles["Normal"], fontSize=7.5, textColor=_GREY,
        alignment=TA_CENTER, spaceBefore=10,
    )

    story = []
    story.append(Paragraph("JeevanDoot", brand))
    story.append(Paragraph("Health Assistant &amp; Telemedicine", subtitle))
    story.append(HRFlowable(width="100%", thickness=1.2, color=_PRIMARY))
    story.append(Spacer(1, 8))

    # Doctor + patient blocks
    doctor_cells = [
        [Paragraph("DOCTOR", label), Paragraph("PATIENT", label)],
        [
            Paragraph(
                f"{doctor.get('name') or rx.get('doctor_name') or 'Doctor'}"
                f"<br/><font size=8>{doctor.get('specialization') or ''}</font>"
                f"<br/><font size=8>Reg: {doctor.get('registration_id') or '—'}</font>",
                value,
            ),
            Paragraph(
                f"{patient.get('name') or ''}"
                f"<br/><font size=8>Age: {patient.get('age') or '—'} yrs"
                f" &nbsp;•&nbsp; {patient.get('gender') or ''}</font>"
                f"<br/><font size=8>Patient ID: {patient.get('id') or rx.get('patient_id')}</font>",
                value,
            ),
        ],
    ]
    info = Table(doctor_cells, colWidths=[doc.width / 2.0, doc.width / 2.0])
    info.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 0),
    ]))
    story.append(info)
    story.append(Spacer(1, 6))

    allergies = patient.get("allergies") or []
    if allergies:
        story.append(Paragraph(
            f"<font color='#B3261E'><b>⚠ Known allergy:</b> "
            f"{', '.join(allergies)}</font>",
            ParagraphStyle("allergy", parent=styles["Normal"], fontSize=9,
                           spaceAfter=8),
        ))

    story.append(HRFlowable(width="100%", thickness=0.5, color=colors.HexColor("#BBCAC5")))
    story.append(Paragraph("Rx", rx_style))

    for idx, item in enumerate(rx.get("medicines", []), start=1):
        name = item.get("name") or item.get("generic_name") or "Medicine"
        strength = item.get("strength") or ""
        story.append(Paragraph(
            f"{idx}. {name}{f' <font color=#5F6B6A><b>{strength}</b></font>' if strength else ''}",
            med_style,
        ))
        story.append(Paragraph(_dose_line(item), dose_style))

    if rx.get("additional_instructions"):
        story.append(Spacer(1, 4))
        story.append(Paragraph("ADDITIONAL INSTRUCTIONS", section))
        story.append(Paragraph(rx["additional_instructions"], med_style))

    story.append(Spacer(1, 10))
    story.append(HRFlowable(width="100%", thickness=0.5, color=colors.HexColor("#BBCAC5")))
    story.append(Spacer(1, 8))

    issued = rx.get("issued_at") or rx.get("updated_at") or ""
    issued_label = issued.replace("T", " ")[:16] if issued else ""
    footer_cells = [
        [
            Paragraph(
                f"<b>Issued:</b> {issued_label}",
                ParagraphStyle("f1", parent=styles["Normal"], fontSize=9),
            ),
            Paragraph(
                f"<b>Prescription ID:</b> {rx['id']}",
                ParagraphStyle("f2", parent=styles["Normal"], fontSize=9,
                               alignment=TA_RIGHT),
            ),
        ],
    ]
    story.append(Table(footer_cells, colWidths=[doc.width / 2.0, doc.width / 2.0],
                       style=[("LEFTPADDING", (0, 0), (-1, -1), 0),
                              ("RIGHTPADDING", (0, 0), (-1, -1), 0)]))
    story.append(Spacer(1, 14))
    story.append(Paragraph(
        "This is a computer-generated prescription. Please verify all medicines, "
        "doses and instructions with your healthcare professional.",
        footnote,
    ))

    doc.build(story)
    return buf.getvalue()
