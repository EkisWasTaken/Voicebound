# Releasing Voicebound on CurseForge

## Files

- **Project logo:** `branding/curseforge-logo-400.png`, 400×400.
- **Upload file:** `release/Voicebound-1.0.0.zip`. It contains the `RaceVoiceSelector/` addon folder with the in-game icon, and leaves out the dev-only `tools/`.
- **Icon source:** `branding/icon.svg`. Edit this to change the icon, then re-render.

## Step by step

1. Sign in at **https://authors.curseforge.com** with your CurseForge account. Accept the author terms if this is your first project.
2. **Create Project**. Choose game **World of Warcraft** and class **Addons**.
3. Fill in the form from the "Page text" section below: name, summary, description, category.
4. **License:** pick one in the form. MIT is the common choice for addons: anyone may reuse the code as long as your name stays on it.
5. Upload `curseforge-logo-400.png` as the project logo and submit. CurseForge moderators review new projects; this usually takes from a few hours to a couple of days.
6. Open the project, go to **Files**, then **Upload File**, and choose `Voicebound-1.0.0.zip`.
   - Display name: `Voicebound 1.0.0`
   - Release type: **Release**
   - Game version: pick **WoW Forever** (build 1.60.x). If Forever isn't listed, choose the closest Classic version and note "WoW Forever 1.60.1" in the changelog.
   - Changelog: see below.
7. Once the project is approved, CurseForge shows its **Project ID**. Add it to `RaceVoiceSelector.toc` in the next version so the CurseForge app matches installs:
   `## X-Curse-Project-ID: <your id>`
8. **Screenshot (recommended):** take one in game with the Voicebound window open (`/rvs`) and add it under **Images**. Pages with a screenshot get far more downloads.

**Releasing an update:** bump `## Version:` in the `.toc` and rebuild the zip. Then upload it as a new file with a changelog.

---

## Page text

**Name:** Voicebound

**Summary and description:** open `branding/curseforge-description.html` in your browser.
Click **Copy summary**, paste it into the Summary field, then click **Copy description** and paste it into the Description field.
CurseForge's description box is a rich-text editor, so pasted Markdown shows as raw symbols. Copying from that page keeps the headings and bullets.

**Changelog for 1.0.0:**
> First release. Swaps error voice lines and 13 voiced emotes to any of the 8 classic races, male or female. Minimap button for quick access. Built for WoW Forever 1.60.1.
