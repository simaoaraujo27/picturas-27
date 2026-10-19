import os
import matplotlib.pyplot as plt
import matplotlib.patches as patches

os.makedirs('picturas-27/fase1/report/images', exist_ok=True)

# ---------------------------------------------------------------------------
# 1. Diagrama de Casos de Uso
# ---------------------------------------------------------------------------
fig, ax = plt.subplots(figsize=(12, 7), dpi=220)
ax.set_xlim(0, 12)
ax.set_ylim(0, 7)
ax.axis('off')

# System Boundary
sys_rect = patches.FancyBboxPatch((3.2, 0.4), 8.4, 6.2, boxstyle="round,pad=0.1",
                                  facecolor='#FDFEFE', edgecolor='#2C3E50', linewidth=1.5, linestyle='--')
ax.add_patch(sys_rect)
ax.text(7.4, 6.35, "PictuRAS (Fase 1 — Suporte a Vídeo)", ha='center', va='center',
        fontsize=13, weight='bold', color='#1A5276')

# Actors
def draw_actor(x, y, name, color='#2C3E50'):
    ax.plot([x], [y+0.35], 'o', markersize=14, color=color, fillstyle='none', mew=2)
    ax.plot([x, x], [y+0.25, y-0.1], color=color, lw=2)
    ax.plot([x-0.25, x+0.25], [y+0.1, y+0.1], color=color, lw=2)
    ax.plot([x, x-0.2], [y-0.1, y-0.35], color=color, lw=2)
    ax.plot([x, x+0.2], [y-0.1, y-0.35], color=color, lw=2)
    ax.text(x, y-0.55, name, ha='center', va='top', fontsize=9.5, weight='bold', color=color)

draw_actor(1.5, 5.5, "Utilizador Anónimo\n(anonymous)", color='#7F8C8D')
draw_actor(1.5, 3.4, "Utilizador Registado\n(free)", color='#2980B9')
draw_actor(1.5, 1.4, "Subscritor Pago\n(premium)", color='#8E44AD')

# Use cases
def draw_uc(x, y, text, new=True, w=3.4, h=0.7, color='#E8F8F5', border='#16A085'):
    bg = color if new else '#EAEDED'
    bd = border if new else '#BDC3C7'
    tc = '#117864' if new else '#5D6D7E'
    uc = patches.Ellipse((x, y), w, h, facecolor=bg, edgecolor=bd, linewidth=1.8 if new else 1.2)
    ax.add_patch(uc)
    ax.text(x, y, text, ha='center', va='center', fontsize=9, weight='bold' if new else 'normal', color=tc)

# Baseline image use cases (grayed out)
draw_uc(5.2, 5.6, "Manipular Imagens (Base)", new=False, w=3.2, h=0.6)
draw_uc(5.2, 4.6, "Gerir Projetos e Álbuns", new=False, w=3.2, h=0.6)

# New Video use cases
draw_uc(6.0, 3.3, "UC-VID-001: Recortar Vídeo\n(Trim Temporal)", new=True, w=4.2, h=0.9, color='#D4EFDF', border='#27AE60')
draw_uc(10.0, 3.3, "Acompanhar Estado e\nProgresso do Job", new=True, w=3.2, h=0.7, color='#EBF5FB', border='#3498DB')
draw_uc(6.0, 1.8, "FA2: Recorte Rápido em\nKeyframes (Stream Copy)", new=True, w=3.8, h=0.7, color='#F5EEF8', border='#8E44AD')
draw_uc(10.0, 1.8, "FA5: Cancelar Tarefa\nde Vídeo e Estornar", new=True, w=3.4, h=0.7, color='#FDEDEC', border='#E74C3C')

# Connecting lines
# Anonymous blocked
ax.annotate("", xy=(3.8, 5.5), xytext=(2.3, 5.5), arrowprops=dict(arrowstyle="->", color='#7F8C8D', lw=1.2))
ax.annotate("", xy=(4.0, 3.6), xytext=(2.3, 5.3), arrowprops=dict(arrowstyle="->", color='#E74C3C', lw=1.5, ls=':'))
ax.text(2.9, 4.5, "Bloqueado (RN7)", color='#C0392B', fontsize=8, weight='bold', rotation=-25)

# Free connections
ax.annotate("", xy=(3.8, 4.6), xytext=(2.3, 3.4), arrowprops=dict(arrowstyle="->", color='#2980B9', lw=1.2))
ax.annotate("", xy=(3.9, 3.3), xytext=(2.3, 3.4), arrowprops=dict(arrowstyle="->", color='#2980B9', lw=1.8))

# Premium connections
ax.annotate("", xy=(4.0, 3.1), xytext=(2.3, 1.4), arrowprops=dict(arrowstyle="->", color='#8E44AD', lw=1.8))
ax.annotate("", xy=(4.1, 1.8), xytext=(2.3, 1.4), arrowprops=dict(arrowstyle="->", color='#8E44AD', lw=1.8))

# Relationships between UCs
ax.annotate("<<include>>", xy=(8.4, 3.3), xytext=(8.1, 3.3), color='#2980B9', fontsize=8, weight='bold',
            arrowprops=dict(arrowstyle="<-", color='#3498DB', lw=1.2, ls='--'))
ax.annotate("<<extend>>", xy=(6.0, 2.8), xytext=(6.0, 2.15), color='#8E44AD', fontsize=8, weight='bold',
            arrowprops=dict(arrowstyle="->", color='#8E44AD', lw=1.2, ls='--'))
ax.annotate("<<extend>>", xy=(8.3, 2.1), xytext=(7.8, 3.0), color='#C0392B', fontsize=8, weight='bold',
            arrowprops=dict(arrowstyle="->", color='#E74C3C', lw=1.2, ls='--'))

# Legend
leg_rect = patches.Rectangle((3.4, 0.6), 8.0, 0.6, facecolor='#F8F9F9', edgecolor='#BDC3C7')
ax.add_patch(leg_rect)
ax.text(3.6, 0.9, "Legenda:", fontsize=8.5, weight='bold', color='#2C3E50', va='center')
ax.add_patch(patches.Ellipse((4.7, 0.9), 1.2, 0.35, facecolor='#EAEDED', edgecolor='#BDC3C7'))
ax.text(4.7, 0.9, "Baseline", fontsize=7.5, ha='center', va='center')
ax.add_patch(patches.Ellipse((6.2, 0.9), 1.4, 0.35, facecolor='#D4EFDF', edgecolor='#27AE60'))
ax.text(6.2, 0.9, "Novo (Fase 1)", fontsize=7.5, ha='center', va='center', weight='bold', color='#196F3D')
ax.text(7.6, 0.9, "Perfis: [free: max 180s, 5 ops/dia, 1GB] | [premium: max 60m, ilimitado, 5GB]", fontsize=7.5, va='center', color='#34495E')

plt.tight_layout()
plt.savefig('picturas-27/fase1/report/images/diagrama_casos_uso.png', bbox_inches='tight')
plt.close(fig)
print("Generated diagrama_casos_uso.png")

# ---------------------------------------------------------------------------
# 2. Modelo de Domínio
# ---------------------------------------------------------------------------
fig, ax = plt.subplots(figsize=(12, 7.5), dpi=220)
ax.set_xlim(0, 12)
ax.set_ylim(0, 7.5)
ax.axis('off')

def draw_class(x, y, w, h, title, attrs, color='#F8F9F9', header_col='#2980B9', text_col='white'):
    rect = patches.FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.05",
                                  facecolor=color, edgecolor='#34495E', linewidth=1.2)
    ax.add_patch(rect)
    # Header
    hdr = patches.FancyBboxPatch((x, y+h-0.5), w, 0.5, boxstyle="round,pad=0.05",
                                facecolor=header_col, edgecolor='#34495E', linewidth=1.2)
    ax.add_patch(hdr)
    ax.text(x + w/2, y + h - 0.25, title, ha='center', va='center', fontsize=9.5, weight='bold', color=text_col)
    
    # Attributes
    curr_y = y + h - 0.75
    for attr in attrs:
        ax.text(x + 0.15, curr_y, attr, ha='left', va='center', fontsize=8, color='#2C3E50')
        curr_y -= 0.32

# Classes
draw_class(0.6, 4.4, 3.2, 2.6, "Utilizador", [
    "- id: String",
    "- username: String",
    "- perfil: {anonymous, free, premium}",
    "- quotaDiariaOps: Integer (= 5 em free)",
    "- limiteStorageBytes: Long (1GB/5GB)",
    "- bytesOcupados: Long"
], header_col='#2C3E50')

draw_class(4.6, 4.6, 2.8, 2.2, "Projeto", [
    "- id: String",
    "- nome: String",
    "- proprietario: Utilizador",
    "- dataCriacao: Date",
    "- partilhas: List<Partilha>"
], header_col='#2471A3')

draw_class(8.2, 4.4, 3.3, 2.6, "RecursoMultimédia", [
    "«abstract»",
    "- id: String",
    "- nomeFicheiro: String",
    "- dataUpload: Date",
    "- tamanhoBytes: Long",
    "- storageUrl: String"
], header_col='#16A085')

draw_class(7.0, 1.8, 2.2, 1.8, "Imagem", [
    "- largura: Int",
    "- altura: Int",
    "- formato: String",
    "- canaisCor: Int"
], header_col='#7D6608', color='#FEF9E7')

draw_class(9.6, 1.2, 2.2, 2.4, "Vídeo", [
    "«novo»",
    "- duracao: Float",
    "- largura: Int",
    "- altura: Int",
    "- codecVideo: String (=h264)",
    "- codecAudio: String (=aac)",
    "- framerate: Float"
], header_col='#1E8449', color='#EAFAF1')

draw_class(4.2, 1.2, 3.4, 2.4, "TrabalhoProcessamento\n(TrimJob)", [
    "«novo»",
    "- jobId: String",
    "- estado: EstadoJob",
    "- instanteInicio: Float (tin)",
    "- instanteFim: Float (tout)",
    "- progressoPercentual: Int",
    "- criadoEm: Date"
], header_col='#8E44AD', color='#F5EEF8')

draw_class(0.6, 1.6, 2.8, 1.8, "EstadoJob", [
    "«enumeration»",
    "QUEUED",
    "PROCESSING",
    "COMPLETED",
    "FAILED",
    "CANCELLED"
], header_col='#A04000', color='#FBEEE6')

# Associations and arrows
# Utilizador -> Projeto
ax.plot([3.8, 4.6], [5.6, 5.6], color='#2C3E50', lw=1.4)
ax.text(3.9, 5.75, "1", fontsize=8.5, weight='bold')
ax.text(4.4, 5.75, "0..*", fontsize=8.5, weight='bold')
ax.text(4.1, 5.35, "gere", fontsize=8, style='italic')

# Projeto -> RecursoMultimédia
ax.plot([7.4, 8.2], [5.6, 5.6], color='#2C3E50', lw=1.4)
ax.text(7.5, 5.75, "1", fontsize=8.5, weight='bold')
ax.text(8.0, 5.75, "0..*", fontsize=8.5, weight='bold')
ax.text(7.7, 5.35, "contém", fontsize=8, style='italic')

# Generalization: Imagem / Vídeo -> RecursoMultimédia
ax.annotate("", xy=(9.4, 4.4), xytext=(8.1, 3.6), arrowprops=dict(arrowstyle="-|>", color='#16A085', lw=1.4))
ax.annotate("", xy=(10.0, 4.4), xytext=(10.5, 3.6), arrowprops=dict(arrowstyle="-|>", color='#16A085', lw=1.4))

# Vídeo -> TrimJob
ax.annotate("", xy=(7.6, 2.2), xytext=(9.6, 2.2), arrowprops=dict(arrowstyle="->", color='#8E44AD', lw=1.4))
ax.text(8.8, 2.35, "origina", fontsize=8, style='italic', color='#8E44AD')
ax.text(9.4, 2.05, "1", fontsize=8.5, weight='bold')
ax.text(7.8, 2.05, "0..*", fontsize=8.5, weight='bold')

# TrimJob -> Vídeo (gerado)
ax.annotate("", xy=(9.6, 1.6), xytext=(7.6, 1.6), arrowprops=dict(arrowstyle="->", color='#27AE60', lw=1.4, ls='--'))
ax.text(8.3, 1.35, "produz (resultado)", fontsize=8, style='italic', color='#27AE60')

# TrimJob -> EstadoJob
ax.plot([3.4, 4.2], [2.2, 2.2], color='#34495E', lw=1.2, ls=':')

plt.tight_layout()
plt.savefig('picturas-27/fase1/report/images/modelo_dominio.png', bbox_inches='tight')
plt.close(fig)
print("Generated modelo_dominio.png")

# ---------------------------------------------------------------------------
# 3. Vista de Componentes da Arquitetura
# ---------------------------------------------------------------------------
fig, ax = plt.subplots(figsize=(12, 7), dpi=220)
ax.set_xlim(0, 12)
ax.set_ylim(0, 7)
ax.axis('off')

def draw_comp(x, y, w, h, name, tech, state='baseline', col='#EBF5FB', bcol='#2980B9'):
    if state == 'new':
        col, bcol = '#D4EFDF', '#27AE60'
    elif state == 'modified':
        col, bcol = '#FCF3CF', '#F39C12'
    
    rect = patches.FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.1",
                                  facecolor=col, edgecolor=bcol, linewidth=1.8)
    ax.add_patch(rect)
    ax.text(x + w/2, y + h - 0.28, name, ha='center', va='center', fontsize=9.5, weight='bold', color='#1A252F')
    ax.text(x + w/2, y + 0.28, tech, ha='center', va='center', fontsize=8, style='italic', color='#566573')

# Frontend
draw_comp(0.8, 4.8, 3.0, 1.5, "Frontend Web (UI)", "Next.js / React (VideoWorkspace)", state='modified')

# API Gateway
draw_comp(4.6, 4.8, 2.8, 1.5, "API Gateway", "Express.js / HTTPS Reverse Proxy", state='modified')

# Backend services
draw_comp(8.2, 5.0, 3.2, 1.4, "Users Service", "Node.js (Reserva atómica de quota)", state='modified')
draw_comp(8.2, 3.1, 3.2, 1.5, "Projects Service", "Node.js (TrimJob API & Storage Quota)", state='modified')

# RabbitMQ
draw_comp(4.6, 2.6, 2.8, 1.4, "RabbitMQ Broker", "Fila durável: video_trim_queue", state='modified')

# Video Worker
draw_comp(4.6, 0.6, 2.8, 1.5, "videoTrimWorker", "Python 3.11 + FFmpeg Nativo", state='new')

# SeaweedFS
draw_comp(8.2, 0.6, 3.2, 1.5, "Media Storage", "SeaweedFS (S3 Encrypted Storage)", state='baseline')

# Arrows
ax.annotate("", xy=(4.6, 5.55), xytext=(3.8, 5.55), arrowprops=dict(arrowstyle="->", color='#2C3E50', lw=1.5))
ax.text(4.2, 5.75, "HTTPS", fontsize=8, ha='center')

ax.annotate("", xy=(8.2, 5.7), xytext=(7.4, 5.7), arrowprops=dict(arrowstyle="->", color='#2C3E50', lw=1.5))
ax.text(7.8, 5.9, "/users", fontsize=8, ha='center')

ax.annotate("", xy=(8.2, 4.1), xytext=(7.4, 5.1), arrowprops=dict(arrowstyle="->", color='#2C3E50', lw=1.5))
ax.text(7.7, 4.7, "/projects", fontsize=8, ha='center')

# Projects -> Users (reserva atómica)
ax.annotate("", xy=(9.8, 5.0), xytext=(9.8, 4.6), arrowprops=dict(arrowstyle="->", color='#F39C12', lw=1.5))
ax.text(10.1, 4.8, "reserva quota", fontsize=7.5, color='#B9770E', va='center')

# Projects -> RabbitMQ
ax.annotate("", xy=(7.4, 3.3), xytext=(8.2, 3.6), arrowprops=dict(arrowstyle="->", color='#2C3E50', lw=1.5))
ax.text(7.7, 3.7, "publish", fontsize=8, color='#2C3E50')

# Worker -> RabbitMQ (consume)
ax.annotate("", xy=(6.0, 2.6), xytext=(6.0, 2.1), arrowprops=dict(arrowstyle="<-", color='#27AE60', lw=1.8))
ax.text(6.3, 2.35, "consume", fontsize=8, color='#1E8449')

# Worker -> SeaweedFS (download original / upload trimmed)
ax.annotate("", xy=(8.2, 1.35), xytext=(7.4, 1.35), arrowprops=dict(arrowstyle="<->", color='#27AE60', lw=1.8))
ax.text(7.8, 1.6, "S3 Stream", fontsize=8, color='#1E8449', ha='center')

# Legend
leg_rect = patches.Rectangle((0.8, 0.6), 3.2, 1.5, facecolor='#F8F9F9', edgecolor='#BDC3C7')
ax.add_patch(leg_rect)
ax.text(1.0, 1.8, "Legenda da Arquitetura:", fontsize=8.5, weight='bold', color='#2C3E50')
ax.add_patch(patches.Rectangle((1.0, 1.35), 0.4, 0.25, facecolor='#D4EFDF', edgecolor='#27AE60'))
ax.text(1.5, 1.45, "Componente Novo (Fase 1)", fontsize=8, va='center')
ax.add_patch(patches.Rectangle((1.0, 0.95), 0.4, 0.25, facecolor='#FCF3CF', edgecolor='#F39C12'))
ax.text(1.5, 1.05, "Componente Alterado (Delta)", fontsize=8, va='center')

plt.tight_layout()
plt.savefig('picturas-27/fase1/report/images/arquitetura_componentes.png', bbox_inches='tight')
plt.close(fig)
print("Generated arquitetura_componentes.png")

# ---------------------------------------------------------------------------
# 4. Diagrama de Sequência de Processamento de Vídeo
# ---------------------------------------------------------------------------
fig, ax = plt.subplots(figsize=(13, 8), dpi=220)
ax.set_xlim(0, 13)
ax.set_ylim(0, 8.5)
ax.axis('off')

lifelines = [
    ("Utilizador\n(Browser)", 1.2),
    ("Frontend\n(VideoWorkspace)", 3.0),
    ("Projects\nService", 5.2),
    ("Users\nService", 7.2),
    ("RabbitMQ\nBroker", 9.0),
    ("videoTrim\nWorker", 10.8),
    ("SeaweedFS\n(Storage)", 12.3)
]

# Draw Lifelines
for name, x in lifelines:
    ax.text(x, 8.2, name, ha='center', va='center', fontsize=8.5, weight='bold', color='#1A5276',
            bbox=dict(boxstyle="round,pad=0.2", facecolor='#EBF5FB', edgecolor='#3498DB'))
    ax.plot([x, x], [0.4, 7.8], color='#BDC3C7', lw=1, ls='--')

def draw_msg(y, x1, x2, text, col='#2C3E50', ret=False):
    ls = '--' if ret else '-'
    ax.annotate("", xy=(x2, y), xytext=(x1, y),
                arrowprops=dict(arrowstyle="->", color=col, lw=1.3, ls=ls))
    mid_x = (x1 + x2) / 2
    ax.text(mid_x, y + 0.12, text, ha='center', va='bottom', fontsize=7.5, color=col, weight='bold')

# Messages in sequence
draw_msg(7.4, 1.2, 3.0, "1. Define tin, tout e clica Recortar")
draw_msg(7.0, 3.0, 5.2, "2. POST /projects/.../trim {tin, tout}")
draw_msg(6.6, 5.2, 7.2, "3. POST /users/quota/reserve {jobId}", col='#D35400')
draw_msg(6.2, 7.2, 5.2, "4. 200 OK (Quota Free reservada: 4)", col='#D35400', ret=True)
draw_msg(5.8, 5.2, 9.0, "5. publish(jobId, QUEUED)", col='#2980B9')
draw_msg(5.4, 5.2, 3.0, "6. 202 Accepted {jobId, state: QUEUED}", ret=True)
draw_msg(5.0, 3.0, 1.2, "7. Exibe 'Em fila' + polling 4s", ret=True)

# Worker picks job
draw_msg(4.6, 9.0, 10.8, "8. consume(jobId)", col='#27AE60')
draw_msg(4.2, 10.8, 5.2, "9. PATCH job state=PROCESSING", col='#27AE60')
draw_msg(3.8, 10.8, 12.3, "10. GET video_original.mp4", col='#16A085')
draw_msg(3.4, 12.3, 10.8, "11. Stream video (S3)", col='#16A085', ret=True)

# FFmpeg execution
ax.text(10.8, 2.95, "[ Executa FFmpeg em /tmp ]", ha='center', va='center', fontsize=7.5, color='#8E44AD', weight='bold')
ax.plot([10.6, 11.0], [2.8, 2.8], color='#8E44AD', lw=3)

draw_msg(2.5, 10.8, 12.3, "12. PUT video_trimmed.mp4", col='#16A085')
draw_msg(2.1, 10.8, 5.2, "13. PATCH job COMPLETED {result}", col='#27AE60')
draw_msg(1.7, 5.2, 7.2, "14. POST /users/quota/commit", col='#D35400')

draw_msg(1.3, 3.0, 5.2, "15. Polling: GET /jobs/:id -> COMPLETED")
draw_msg(0.9, 3.0, 5.2, "16. GET /playback -> Cookie 5 min")
draw_msg(0.5, 3.0, 5.2, "17. GET /play (HTTP 206 Range Stream)", col='#2980B9')

plt.tight_layout()
plt.savefig('picturas-27/fase1/report/images/sequencia_processamento.png', bbox_inches='tight')
plt.close(fig)
print("Generated sequencia_processamento.png")

