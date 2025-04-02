# Site Maintenance Log

## March 2024 - Preview Deployment Investigation

### Issue
- Preview deployments showing failures in GitHub Actions
- Production site remained functional throughout
- Concerns about gh-pages deployment conflicts with Vercel

### Investigation & Resolution
- Identified that failed previews were only affecting gh-pages branch deployments
- Production deployments through Vercel remained stable
- Site accessibility and functionality verified through incognito testing
- DNS and domain configuration confirmed correct

### Current Status
- Production site (www.meteoscientific.com) - ✅ Fully functional
- Vercel deployments - ✅ Working as expected
- Preview deployments - ⚠️ Expected failures (gh-pages related, can be ignored)

### Technical Details
- Deployment platform: Vercel
- Main branch: Deploys successfully to production
- gh-pages branch: Preview failures expected and don't impact production
- Last successful production deployment: March 6, 2024 (added media page)

### Future Considerations
- Optional: Could disable GitHub Pages workflow if preview failures are concerning
- Optional: Docusaurus update available (3.1.1 → 3.7.0) - not urgent
- Keep this log updated with any significant changes or investigations

### Dependencies
- Current Docusaurus version: 3.1.1
- Deployment: Vercel
- DNS: Configured correctly with Vercel's recommended settings 