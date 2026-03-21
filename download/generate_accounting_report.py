from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT, TA_JUSTIFY
from reportlab.lib import colors
from reportlab.lib.units import cm, inch
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfbase.pdfmetrics import registerFontFamily

# Register Arabic/Chinese fonts
pdfmetrics.registerFont(TTFont('SimHei', '/usr/share/fonts/truetype/chinese/SimHei.ttf'))
pdfmetrics.registerFont(TTFont('Microsoft YaHei', '/usr/share/fonts/truetype/chinese/msyh.ttf'))
pdfmetrics.registerFont(TTFont('Times New Roman', '/usr/share/fonts/truetype/english/Times-New-Roman.ttf'))

registerFontFamily('Microsoft YaHei', normal='Microsoft YaHei', bold='Microsoft YaHei')
registerFontFamily('SimHei', normal='SimHei', bold='SimHei')
registerFontFamily('Times New Roman', normal='Times New Roman', bold='Times New Roman')

# Create document
doc = SimpleDocTemplate(
    "/home/z/my-project/download/advanced_accounting_projects_github.pdf",
    pagesize=A4,
    rightMargin=2*cm,
    leftMargin=2*cm,
    topMargin=2*cm,
    bottomMargin=2*cm,
    title="Advanced Accounting Projects on GitHub",
    author="Z.ai",
    creator="Z.ai",
    subject="تقرير شامل عن أفضل مشاريع التطبيقات المحاسبية المتطورة مفتوحة المصدر على GitHub"
)

# Define styles
styles = getSampleStyleSheet()

title_style = ParagraphStyle(
    name='ArabicTitle',
    fontName='Microsoft YaHei',
    fontSize=28,
    leading=38,
    alignment=TA_CENTER,
    spaceAfter=20,
    textColor=colors.HexColor('#1F4E79')
)

subtitle_style = ParagraphStyle(
    name='ArabicSubtitle',
    fontName='SimHei',
    fontSize=14,
    leading=22,
    alignment=TA_CENTER,
    spaceAfter=30,
    textColor=colors.HexColor('#666666')
)

heading1_style = ParagraphStyle(
    name='ArabicHeading1',
    fontName='Microsoft YaHei',
    fontSize=18,
    leading=26,
    alignment=TA_LEFT,
    spaceBefore=20,
    spaceAfter=12,
    textColor=colors.HexColor('#1F4E79')
)

heading2_style = ParagraphStyle(
    name='ArabicHeading2',
    fontName='Microsoft YaHei',
    fontSize=14,
    leading=22,
    alignment=TA_LEFT,
    spaceBefore=15,
    spaceAfter=10,
    textColor=colors.HexColor('#2E75B6')
)

body_style = ParagraphStyle(
    name='ArabicBody',
    fontName='SimHei',
    fontSize=11,
    leading=18,
    alignment=TA_LEFT,
    spaceAfter=10,
    wordWrap='CJK'
)

link_style = ParagraphStyle(
    name='LinkStyle',
    fontName='Times New Roman',
    fontSize=10,
    leading=16,
    alignment=TA_LEFT,
    textColor=colors.HexColor('#0563C1')
)

header_style = ParagraphStyle(
    name='TableHeader',
    fontName='Microsoft YaHei',
    fontSize=11,
    leading=14,
    alignment=TA_CENTER,
    textColor=colors.white
)

cell_style = ParagraphStyle(
    name='TableCell',
    fontName='SimHei',
    fontSize=10,
    leading=14,
    alignment=TA_CENTER,
    wordWrap='CJK'
)

cell_left_style = ParagraphStyle(
    name='TableCellLeft',
    fontName='SimHei',
    fontSize=10,
    leading=14,
    alignment=TA_LEFT,
    wordWrap='CJK'
)

story = []

# Cover page
story.append(Spacer(1, 100))
story.append(Paragraph("أفضل مشاريع التطبيقات المحاسبية المتطورة", title_style))
story.append(Spacer(1, 15))
story.append(Paragraph("على GitHub", title_style))
story.append(Spacer(1, 30))
story.append(Paragraph("تقرير شامل عن أفضل المشاريع مفتوحة المصدر", subtitle_style))
story.append(Paragraph("2026", subtitle_style))
story.append(PageBreak())

# Introduction
story.append(Paragraph("مقدمة", heading1_style))
story.append(Paragraph(
    "يقدم هذا التقرير نظرة شاملة على أفضل مشاريع التطبيقات المحاسبية المتطورة والمفتوحة المصدر المتاحة على منصة GitHub. "
    "تشهد صناعة البرمجيات المحاسبية نمواً متسارعاً في تبني الحلول مفتوحة المصدر، حيث توفر هذه المشاريع مرونة عالية وقابلة للتخصيص وتكاليف أقل مقارنة بالحلول التجارية التقليدية. "
    "يتناول التقرير مجموعة متنوعة من المشاريع التي تغطي احتياجات الأعمال المختلفة، من الأنظمة المتكاملة لإدارة موارد المؤسسات ERP إلى تطبيقات الفوترة وإدارة الحسابات البسيطة.",
    body_style
))

story.append(Paragraph(
    "تتميز هذه المشاريع بتقنيات حديثة ومتطورة، حيث تستخدم أطر عمل مثل React و Node.js و Laravel و Python، "
    "كما توفر واجهات برمجية API قوية ودعماً للغات متعددة. "
    "سنستعرض في هذا التقرير أبرز 10 مشاريع محاسبية متطورة مع تفاصيل تقنية وشروحات عن المميزات والاستخدامات.",
    body_style
))

story.append(Spacer(1, 20))

# Summary table
story.append(Paragraph("ملخص المشاريع الرئيسية", heading1_style))

summary_data = [
    [Paragraph('<b>المشروع</b>', header_style), Paragraph('<b>النجوم</b>', header_style), 
     Paragraph('<b>التقنيات</b>', header_style), Paragraph('<b>الترخيص</b>', header_style)],
    [Paragraph('ERPNext', cell_style), Paragraph('31,000+', cell_style), 
     Paragraph('Python, Frappe', cell_style), Paragraph('GPLv3', cell_style)],
    [Paragraph('Odoo', cell_style), Paragraph('48,500+', cell_style), 
     Paragraph('Python, PostgreSQL', cell_style), Paragraph('LGPLv3', cell_style)],
    [Paragraph('IDURAR ERP', cell_style), Paragraph('8,200+', cell_style), 
     Paragraph('React, Node.js, MongoDB', cell_style), Paragraph('AGPLv3', cell_style)],
    [Paragraph('Akaunting', cell_style), Paragraph('8,100+', cell_style), 
     Paragraph('Laravel, Vue.js', cell_style), Paragraph('GPLv3', cell_style)],
    [Paragraph('Frappe Books', cell_style), Paragraph('3,000+', cell_style), 
     Paragraph('Python, Electron', cell_style), Paragraph('AGPLv3', cell_style)],
    [Paragraph('Dolibarr', cell_style), Paragraph('5,300+', cell_style), 
     Paragraph('PHP, MySQL', cell_style), Paragraph('GPLv3', cell_style)],
    [Paragraph('Invoice Ninja', cell_style), Paragraph('8,500+', cell_style), 
     Paragraph('Laravel, Flutter', cell_style), Paragraph('Source-available', cell_style)],
]

summary_table = Table(summary_data, colWidths=[3.5*cm, 2.5*cm, 4.5*cm, 3*cm])
summary_table.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1F4E79')),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
    ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ('FONTNAME', (0, 0), (-1, -1), 'SimHei'),
    ('FONTSIZE', (0, 0), (-1, -1), 10),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
    ('TOPPADDING', (0, 0), (-1, -1), 8),
    ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
    ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#F5F5F5')]),
]))
story.append(summary_table)
story.append(Spacer(1, 8))
story.append(Paragraph("جدول 1: ملخص المشاريع المحاسبية الرئيسية", 
    ParagraphStyle('Caption', fontName='SimHei', fontSize=10, alignment=TA_CENTER)))
story.append(Spacer(1, 20))

# Project 1: ERPNext
story.append(Paragraph("1. ERPNext - نظام إدارة موارد المؤسسات المتكامل", heading1_style))

story.append(Paragraph("نظرة عامة", heading2_style))
story.append(Paragraph(
    "ERPNext هو أحد أبرز الأنظمة مفتوحة المصدر لإدارة موارد المؤسسات، يتميز بكونه نظاماً متكاملاً يغطي جميع جوانب إدارة الأعمال. "
    "تم تطويره بواسطة Frappe Technologies ويستند إلى إطار عمل Frappe Framework القوي والمرن. "
    "يحتوي النظام على أكثر من 31,000 نجمة على GitHub مما يعكس شعبيته الكبيرة في المجتمع التقني. "
    "يوفر ERPNext وحدات متعددة تشمل المحاسبة، إدارة المخزون، الموارد البشرية، إدارة المشاريع، إدارة العملاء CRM، والمبيعات والشراء.",
    body_style
))

story.append(Paragraph("المميزات التقنية", heading2_style))
story.append(Paragraph(
    "يتميز ERPNext بواجهة مستخدم حديثة وسهلة الاستخدام مع دعم كامل للأجهزة المحمولة عبر تطبيقات iOS و Android. "
    "كما يدعم النظام التكامل مع خدمات خارجية متعددة مثل بوابات الدفع، خدمات البريد الإلكتروني، ومنصات التجارة الإلكترونية. "
    "يوفر واجهة برمجية RESTful قوية تتيح التكامل مع أنظمة أخرى بسهولة، ويشمل نظام تقارير متقدم مع لوحات تحكم تفاعلية. "
    "يعمل النظام على بنية Python و MariaDB مع إمكانية النشر على خوادم سحابية أو محلية.",
    body_style
))

story.append(Paragraph("الرابط: ", body_style))
story.append(Paragraph("https://github.com/frappe/erpnext", link_style))
story.append(Spacer(1, 15))

# Project 2: Odoo
story.append(Paragraph("2. Odoo - المنصة الشاملة لتطبيقات الأعمال", heading1_style))

story.append(Paragraph("نظرة عامة", heading2_style))
story.append(Paragraph(
    "Odoo هو نظام ERP شامل يحظى بشعبية هائلة على مستوى العالم، مع أكثر من 48,500 نجمة على GitHub. "
    "يتميز ببنية معيارية تتيح للمؤسسات اختيار التطبيقات التي تحتاجها فقط، ثم إضافة المزيد مع نمو الأعمال. "
    "يتوفر أكثر من 30 تطبيقاً أساسياً تغطي احتياجات المؤسسات المختلفة، من المحاسبة والمخزون إلى الموارد البشرية والتسويق. "
    "يدعم النظام أكثر من 40 لغة مما يجعله مناسباً للمؤسسات الدولية ومتعددة الجنسيات.",
    body_style
))

story.append(Paragraph("المميزات التقنية", heading2_style))
story.append(Paragraph(
    "يعتمد Odoo على Python و PostgreSQL كتقنيات أساسية، مع واجهة أمامية مبنية على JavaScript. "
    "يتميز بنظام ORM قوي يسهل التطوير والتخصيص، إضافة إلى محرك سير عمل مرن يدعم أتمتة العمليات التجارية المعقدة. "
    "يوفر Odoo Studio أداة سحب وإفلات لتخصيص الواجهات والتقارير دون الحاجة للبرمجة. "
    "كما يتكامل النظام بشكل سلس مع منصات التجارة الإلكترونية مثل WooCommerce و Shopify، ويشمل نظام POS متطور لنقاط البيع.",
    body_style
))

story.append(Paragraph("الرابط: ", body_style))
story.append(Paragraph("https://github.com/odoo/odoo", link_style))
story.append(Spacer(1, 15))

# Project 3: IDURAR
story.append(Paragraph("3. IDURAR ERP CRM - نظام MERN Stack المتقدم", heading1_style))

story.append(Paragraph("نظرة عامة", heading2_style))
story.append(Paragraph(
    "IDURAR هو نظام ERP و CRM مفتوح المصدر مبتكر مبني على حزمة MERN Stack التقنية المتطورة (MongoDB, Express.js, React, Node.js). "
    "يتميز بتصميم عصري وواجهة مستخدم جذابة مبنية على Ant Design، مما يوفر تجربة مستخدم سلسة ومتسقة. "
    "يحتوي المشروع على أكثر من 8,200 نجمة على GitHub وهو في تطور مستمر، حيث يتم تحديثه بانتظام بميزات جديدة وتحسينات. "
    "يغطي IDURAR احتياجات الأعمال الأساسية من إصدار الفواتير، إدارة العملاء، تتبع المصروفات، وإدارة المخزون.",
    body_style
))

story.append(Paragraph("المميزات التقنية", heading2_style))
story.append(Paragraph(
    "يعتمد IDURAR على تقنيات JavaScript الحديثة بالكامل، مما يسهل على المطورين العمل عليه والتخصيص. "
    "يستخدم MongoDB كقاعدة بيانات NoSQL مرنة وقابلة للتوسع، مع Express.js كإطار عمل للخادم الخلفي. "
    "تتضمن الميزات نظام صلاحيات متقدم، تقارير ولوحات تحكم تفاعلية، دعم متعدد العملات، ونظام إشعارات متكامل. "
    "يوفر المشروع أيضاً دعماً للنشر السحابي مع إمكانية التشغيل في حاويات Docker.",
    body_style
))

story.append(Paragraph("الرابط: ", body_style))
story.append(Paragraph("https://github.com/idurar/idurar-erp-crm", link_style))
story.append(Spacer(1, 15))

# Project 4: Akaunting
story.append(Paragraph("4. Akaunting - برنامج المحاسبة السحابي", heading1_style))

story.append(Paragraph("نظرة عامة", heading2_style))
story.append(Paragraph(
    "Akaunting هو برنامج محاسبة سحابي مفتوح المصدر مصمم خصيصاً للشركات الصغيرة والمتوسطة والمستقلين. "
    "يتميز بواجهة مستخدم سهلة وبديهية تجعل إدارة الحسابات في متناول الجميع دون الحاجة لخبرة محاسبية متخصصة. "
    "يحتوي المشروع على أكثر من 8,100 نجمة على GitHub ويدعم أكثر من 45 لغة. "
    "يوفر Akaunting تطبيقات للهواتف المحمولة على iOS و Android مما يتيح إدارة الحسابات من أي مكان.",
    body_style
))

story.append(Paragraph("المميزات التقنية", heading2_style))
story.append(Paragraph(
    "مبني على إطار عمل Laravel القوي مع Vue.js للواجهة الأمامية وTailwind CSS للتنسيق. "
    "يتميز ببنية معيارية تسمح بإضافة تطبيقات وملحقات من المتجر الإلكتروني الخاص به. "
    "يدعم الفوترة المتكررة، تتبع المصروفات، إدارة العملاء والموردين، والتقارير المالية الشاملة. "
    "يوفر تكاملاً مع بوابات الدفع مثل PayPal و Stripe، ويشمل نظام صلاحيات متعدد المستخدمين مع أدوار قابلة للتخصيص.",
    body_style
))

story.append(Paragraph("الرابط: ", body_style))
story.append(Paragraph("https://github.com/akaunting/akaunting", link_style))
story.append(Spacer(1, 15))

# Project 5: Frappe Books
story.append(Paragraph("5. Frappe Books - برنامج المحاسبة للمكتب", heading1_style))

story.append(Paragraph("نظرة عامة", heading2_style))
story.append(Paragraph(
    "Frappe Books هو برنامج محاسبة مجاني ومفتوح المصدر مصمم لتبسيط الإدارة المالية للأعمال الصغيرة والمتوسطة. "
    "يتميز بواجهة نظيفة وسهلة الاستخدام توفر تجربة مستخدم ممتازة مع الحفاظ على قوة الوظائف المحاسبية. "
    "يعمل كتطبيق سطح مكتب عبر تقنية Electron مما يتيح استخدامه على أنظمة Windows و macOS و Linux. "
    "يحتوي المشروع على أكثر من 3,000 نجمة على GitHub وهو مدعوم من نفس الفريق المطور لـ ERPNext.",
    body_style
))

story.append(Paragraph("المميزات التقنية", heading2_style))
story.append(Paragraph(
    "مبني على Python مع إطار عمل Frappe، ويستخدم SQLite كقاعدة بيانات محلية خفيفة الوزن. "
    "يتميز بنظام دفتر الأستاذ العام المتكامل مع دعم لقيود اليومية والفواتير. "
    "يوفر تقارير مالية متنوعة تشمل الميزانية العمومية، قائمة الدخل، وميزان المراجعة. "
    "يدعم تصدير البيانات بصيغ متعددة ويشمل نظام إشعارات وتنبيهات ذكي.",
    body_style
))

story.append(Paragraph("الرابط: ", body_style))
story.append(Paragraph("https://github.com/frappe/books", link_style))
story.append(Spacer(1, 15))

# Project 6: Dolibarr
story.append(Paragraph("6. Dolibarr ERP CRM - الحل المتكامل للشركات", heading1_style))

story.append(Paragraph("نظرة عامة", heading2_style))
story.append(Paragraph(
    "Dolibarr هو برنامج ERP و CRM حديث مفتوح المصدر مصمم لإدارة أنشطة الشركات والمؤسسات المختلفة. "
    "يغطي مجموعة واسعة من الوظائف تشمل إدارة جهات الاتصال، الموردين، الفواتير، الطلبات، المخزون، والأجندة. "
    "يحتوي المشروع على أكثر من 5,300 نجمة على GitHub ويستخدمه آلاف المؤسسات حول العالم. "
    "يتميز بسهولة التثبيت والإعداد مع واجهة ويب سهلة الاستخدام لا تتطلب خبرة تقنية عميقة.",
    body_style
))

story.append(Paragraph("المميزات التقنية", heading2_style))
story.append(Paragraph(
    "مبني على PHP مع MySQL أو PostgreSQL كقواعد بيانات مدعومة. "
    "يتضمن أكثر من 50 وحدة قابلة للتفعيل حسب الحاجة، مما يوفر مرونة عالية في التخصيص. "
    "يدعم التكامل مع خدمات خارجية مثل Google Calendar، Mailchimp، و PayPal. "
    "يوفر نظام POS لنقاط البيع، إدارة المشاريع، ونظام موارد بشرية أساسي. "
    "يتميز بمجتمع نشط من المطورين والمساهمين مع تحديثات منتظمة.",
    body_style
))

story.append(Paragraph("الرابط: ", body_style))
story.append(Paragraph("https://github.com/dolibarr/dolibarr", link_style))
story.append(Spacer(1, 15))

# Project 7: Invoice Ninja
story.append(Paragraph("7. Invoice Ninja - نظام الفوترة المتكامل", heading1_style))

story.append(Paragraph("نظرة عامة", heading2_style))
story.append(Paragraph(
    "Invoice Ninja هو تطبيق متكامل للفوترة، إدارة المشاريع، وتتبع الوقت والمصروفات. "
    "يتميز بتصميم عصري ومميزات متقدمة تجعله بديلاً قوياً للتطبيقات التجارية مثل FreshBooks و Zoho. "
    "يحتوي المشروع على أكثر من 8,500 نجمة على GitHub ويستخدمه أكثر من 150,000 مستخدم حول العالم. "
    "يوفر تطبيقات أصلية للهواتف المحمولة على iOS و Android مع مزامنة تلقائية للبيانات.",
    body_style
))

story.append(Paragraph("المميزات التقنية", heading2_style))
story.append(Paragraph(
    "مبني على إطار عمل Laravel مع واجهة أمامية مبنية على Flutter لتطبيقات الهواتف المحمولة. "
    "يدعم إنشاء وإرسال الفواتير بطرق متعددة، مع إمكانية قبول المدفوعات عبر أكثر من 40 بوابة دفع. "
    "يتضمن نظام إدارة العملاء والموردين، تتبع الوقت والمصروفات، وإدارة المشاريع والمهام. "
    "يوفر تقارير مفصلة وقوالب فواتير قابلة للتخصيص مع إمكانية إضافة شعار الشركة وتخصيص الألوان.",
    body_style
))

story.append(Paragraph("الرابط: ", body_style))
story.append(Paragraph("https://github.com/invoiceninja/invoiceninja", link_style))
story.append(Spacer(1, 15))

# Comparison section
story.append(Paragraph("مقارنة شاملة بين المشاريع", heading1_style))

comparison_data = [
    [Paragraph('<b>المشروع</b>', header_style), 
     Paragraph('<b>التعقيد</b>', header_style),
     Paragraph('<b>مناسب لـ</b>', header_style),
     Paragraph('<b>التوثيق</b>', header_style),
     Paragraph('<b>المجتمع</b>', header_style)],
    [Paragraph('ERPNext', cell_style), 
     Paragraph('عالي', cell_style),
     Paragraph('الشركات المتوسطة والكبيرة', cell_left_style),
     Paragraph('ممتاز', cell_style),
     Paragraph('نشط جداً', cell_style)],
    [Paragraph('Odoo', cell_style), 
     Paragraph('عالي', cell_style),
     Paragraph('جميع أحجام الأعمال', cell_left_style),
     Paragraph('ممتاز', cell_style),
     Paragraph('نشط جداً', cell_style)],
    [Paragraph('IDURAR', cell_style), 
     Paragraph('متوسط', cell_style),
     Paragraph('الشركات الصغيرة والمتوسطة', cell_left_style),
     Paragraph('جيد', cell_style),
     Paragraph('نشط', cell_style)],
    [Paragraph('Akaunting', cell_style), 
     Paragraph('منخفض', cell_style),
     Paragraph('المستقلون والشركات الصغيرة', cell_left_style),
     Paragraph('جيد', cell_style),
     Paragraph('نشط', cell_style)],
    [Paragraph('Frappe Books', cell_style), 
     Paragraph('منخفض', cell_style),
     Paragraph('الشركات الصغيرة', cell_left_style),
     Paragraph('جيد', cell_style),
     Paragraph('نشط', cell_style)],
    [Paragraph('Dolibarr', cell_style), 
     Paragraph('متوسط', cell_style),
     Paragraph('الشركات الصغيرة والمتوسطة', cell_left_style),
     Paragraph('جيد', cell_style),
     Paragraph('نشط', cell_style)],
    [Paragraph('Invoice Ninja', cell_style), 
     Paragraph('منخفض-متوسط', cell_style),
     Paragraph('المستقلون والشركات الصغيرة', cell_left_style),
     Paragraph('ممتاز', cell_style),
     Paragraph('نشط', cell_style)],
]

comparison_table = Table(comparison_data, colWidths=[2.8*cm, 2.2*cm, 4.5*cm, 2*cm, 2.2*cm])
comparison_table.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1F4E79')),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
    ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ('FONTNAME', (0, 0), (-1, -1), 'SimHei'),
    ('FONTSIZE', (0, 0), (-1, -1), 9),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
    ('TOPPADDING', (0, 0), (-1, -1), 8),
    ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
    ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#F5F5F5')]),
]))
story.append(comparison_table)
story.append(Spacer(1, 8))
story.append(Paragraph("جدول 2: مقارنة شاملة بين المشاريع المحاسبية", 
    ParagraphStyle('Caption', fontName='SimHei', fontSize=10, alignment=TA_CENTER)))
story.append(Spacer(1, 20))

# Recommendations
story.append(Paragraph("التوصيات", heading1_style))
story.append(Paragraph(
    "بناءً على التحليل الشامل للمشاريع المذكورة، نقدم التوصيات التالية حسب احتياجات المؤسسات المختلفة:",
    body_style
))

story.append(Paragraph("للمؤسسات الكبيرة والمتوسطة:", heading2_style))
story.append(Paragraph(
    "ينصح باستخدام ERPNext أو Odoo نظراً لتوفرهما على نظام متكامل يغطي جميع جوانب إدارة الأعمال. "
    "يوفر كلا النظامين دعماً قوياً ومجتمعاً نشطاً، مع إمكانيات التخصيص العالية والتكامل مع أنظمة أخرى. "
    "كلاهما مناسب للمؤسسات التي تحتاج إلى حل محاسبي متكامل مع إدارة موارد بشرية ومخزون ومشاريع.",
    body_style
))

story.append(Paragraph("للشركات الصغيرة والمستقلين:", heading2_style))
story.append(Paragraph(
    "يُعد Akaunting أو Invoice Ninja خياراً مثالياً نظراً لسهولة الاستخدام والتوثيق الجيد. "
    "تتميز هذه المشاريع بواجهات سهلة لا تتطلب خبرة محاسبية متخصصة، مع إمكانية التوسع مع نمو الأعمال. "
    "Frappe Books أيضاً خيار ممتاز لمن يبحث عن تطبيق سطح مكتب بسيط مع ميزات محاسبية أساسية.",
    body_style
))

story.append(Paragraph("للمطورين والشركات التقنية:", heading2_style))
story.append(Paragraph(
    "يُفضل IDURAR للمطورين الملمين بتقنيات JavaScript و React، حيث يوفر بنية تقنية حديثة وقابلة للتخصيص بسهولة. "
    "كما يعد ERPNext و Odoo خيارات جيدة للمطورين الراغبين في المساهمة في مشاريع كبيرة ومستقرة "
    "مع فرص للتعلم والتطوير المهني في مجال أنظمة ERP.",
    body_style
))

# Build PDF
doc.build(story)
print("PDF generated successfully!")
