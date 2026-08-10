#!/usr/bin/env python3
"""Generate the PROJECT JARVIS manual GitHub deployment checklist PDF."""
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (SimpleDocTemplate, Paragraph, Spacer, Table,
                                TableStyle, ListFlowable, ListItem, HRFlowable)

OUT = "PROJECT_JARVIS_DEPLOY_CHECKLIST.pdf"

doc = SimpleDocTemplate(
    OUT, pagesize=A4,
    leftMargin=18*mm, rightMargin=18*mm, topMargin=16*mm, bottomMargin=16*mm,
    title="PROJECT JARVIS — Manual GitHub Build Checklist",
)

styles = getSampleStyleSheet()
green = colors.HexColor("#00E676")
dark = colors.HexColor("#0B0F14")
grey = colors.HexColor("#555555")

title = ParagraphStyle("title", parent=styles["Title"], textColor=dark,
                       fontSize=20, spaceAfter=2, leading=24)
subtitle = ParagraphStyle("subtitle", parent=styles["Normal"], textColor=grey,
                          fontSize=10.5, spaceAfter=4)
h2 = ParagraphStyle("h2", parent=styles["Heading2"], textColor=green,
                    fontSize=13, spaceBefore=8, spaceAfter=4)
body = ParagraphStyle("body", parent=styles["Normal"], fontSize=10.5,
                      leading=15, spaceAfter=2)
code = ParagraphStyle("code", parent=styles["Code"], fontSize=9,
                      backColor=colors.HexColor("#EEF1F4"),
                      borderPadding=4, leftIndent=4)

story = []

story.append(Paragraph("🤖 PROJECT JARVIS", title))
story.append(Paragraph(
    "Manual GitHub Actions Build — Step-by-Step Checklist", subtitle))
story.append(Spacer(1, 2))
story.append(HRFlowable(width="100%", thickness=1.2, color=green))
story.append(Spacer(1, 8))

def step(no, heading, *points):
    story.append(Paragraph(f"{no}. {heading}", h2))
    if points:
        items = [ListItem(Paragraph(p, body), leftIndent=14) for p in points]
        story.append(ListFlowable(items, bulletType="bullet",
                                  start="•", bulletColor=green, leftIndent=16))
    story.append(Spacer(1, 2))

def cmd(c):
    story.append(Paragraph(c, code))
    story.append(Spacer(1, 4))

# ---- Steps ----
step(1, "Prerequisites — install these once",
     "Git — github.com/git-guides/install-git",
     "GitHub CLI (optional, for one-command deploy) — cli.github.com",
     "Flutter SDK — docs.flutter.dev/get-started/install (Android toolchain configured).")
story.append(Paragraph(
    "Verify with: <b>flutter doctor</b> — it should show “Flutter”, “Android toolchain” and “Android Studio” all ✓.",
    body))
story.append(Spacer(1, 2))

step(2, "Create a GitHub repository",
     "Go to github.com → New repository.",
     "Name it <b>project_jarvis</b> (or anything), keep it <b>Private</b> if you want, do NOT tick “Add a README”.",
     "Click <b>Create repository</b> — you'll see the push commands (we'll use our own below).")
story.append(Spacer(1, 2))

step(3, "Generate missing platform scaffolding (once)",
     "The repo ships source code but the binary Gradle wrapper jar can't be versioned as text. Run this in the project folder:")
cmd("flutter create --platforms=android --org com.example .")
story.append(Spacer(1, 2))

step(4, "Push the code to GitHub",
     "In your project folder (where pubspec.yaml lives):")
cmd("git init")
cmd("git add .")
cmd('git commit -m "Project JARVIS — initial commit"')
cmd("git branch -M main")
cmd("git remote add origin https://github.com/YOUR_USERNAME/project_jarvis.git")
cmd("git push -u origin main")
story.append(Spacer(1, 2))

step(5, "(Recommended) Add your Gemini API key as a Secret",
     "On GitHub: repo → <b>Settings</b> → <b>Secrets and variables</b> → <b>Actions</b> → <b>New repository secret</b>.",
     "<b>Name:</b> <code>GEMINI_KEY</code>",
     "<b>Value:</b> your Google AI Studio API key",
     "Save. The workflow injects it via <code>--dart-define</code> — it is never committed.",
     "Add signing secrets too if you want a properly signed release APK:",
     "<code>KEYSTORE_BASE64</code>, <code>KEYSTORE_PASSWORD</code>, <code>KEY_PASSWORD</code>, <code>KEY_ALIAS</code>.")
story.append(Spacer(1, 2))

step(6, "Trigger the build",
     "Option A — automatic: pushing to <b>main</b> already starts the workflow.",
     "Option B — manual: repo → <b>Actions</b> tab → “Build Release APK” → <b>Run workflow</b>.",
     "Watch the run turn green (5–10 minutes).")
story.append(Spacer(1, 2))

step(7, "Download your APK",
     "Open the finished run (green ✓).",
     "Scroll to the <b>Artifacts</b> section.",
     "Click <b>project-jarvis-release</b> → downloads <b>app-release.apk</b>.",
     "That direct link looks like:",
     "<code>https://github.com/YOUR_USERNAME/project_jarvis/actions/runs/&lt;run-id&gt;/artifacts/&lt;artifact-id&gt;</code>",
     "Install on Android: copy the APK to your phone and open it (allow “install unknown apps”).")
story.append(Spacer(1, 2))

step(8, "One-command alternative (deploy.sh)",
     "If GitHub CLI is installed, just run <b>./deploy.sh</b> — it pushes, sets secrets, "
     "starts the workflow, waits, and prints your download link automatically.",
     "Setup: <code>brew install gh</code> → <code>gh auth login</code> → <code>./deploy.sh</code>")
story.append(Spacer(1, 6))

# ---- Troubleshooting table ----
story.append(Paragraph("Troubleshooting", h2))
rows = [
    [Paragraph("<b>Problem</b>", body), Paragraph("<b>Fix</b>", body)],
    [Paragraph("“Missing gradle-wrapper.jar”", body),
     Paragraph("Run <code>flutter create --platforms=android .</code> once, then commit.", body)],
    [Paragraph("“Gemini API key not configured”", body),
     Paragraph("Set the GEMINI_KEY secret, or set it in <code>lib/config/app_config.dart</code>.", body)],
    [Paragraph("<code>gemini-2.5-flash</code> not found", body),
     Paragraph("Your tier may not expose it — change the model in <code>app_config.dart</code> to <code>gemini-1.5-flash</code>.", body)],
    [Paragraph("Build passes but no artifact", body),
     Paragraph("Check the run → steps → “Upload release APK artifact” logs.", body)],
]
t = Table(rows, colWidths=[52*mm, 122*mm])
t.setStyle(TableStyle([
    ("BACKGROUND", (0,0), (-1,0), dark),
    ("TEXTCOLOR", (0,0), (-1,0), colors.white),
    ("BACKGROUND", (0,1), (-1,-1), colors.HexColor("#F4F7F9")),
    ("GRID", (0,0), (-1,-1), 0.5, colors.HexColor("#CCCCCC")),
    ("VALIGN", (0,0), (-1,-1), "TOP"),
    ("ROWBACKGROUNDS", (0,1), (-1,-1), [colors.white, colors.HexColor("#F4F7F9")]),
    ("LEFTPADDING", (0,0), (-1,-1), 8),
    ("RIGHTPADDING", (0,0), (-1,-1), 8),
    ("TOPPADDING", (0,0), (-1,-1), 6),
    ("BOTTOMPADDING", (0,0), (-1,-1), 6),
]))
story.append(t)

doc.build(story)
print(f"Wrote {OUT}")
