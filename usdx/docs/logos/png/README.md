# USDX Logo PNG Exports

All PNG files exported from SVG sources at various sizes for different use cases.

## Files Overview

### Concept 1: Hub-Spoke Classic
- **logo-1-hub-spoke-800.png** (69 KB) - High resolution for web/docs
- **logo-1-hub-spoke-400.png** (29 KB) - Standard web size

### Concept 2: Minimal X with Growth (Best for Icons)
- **logo-2-minimal-x-800.png** (38 KB) - High resolution
- **logo-2-minimal-x-512-square.png** (24 KB) - Social media profile (512x512)
- **logo-2-minimal-x-400.png** (18 KB) - Standard web size
- **logo-2-minimal-x-256-square.png** (12 KB) - App icon size

### Concept 3: Network Visualization
- **logo-3-network-1200-og.png** (156 KB) - Open Graph image (1200x1200)
- **logo-3-network-800.png** (98 KB) - High resolution for web
- **logo-3-network-400.png** (45 KB) - Standard web size

### Concept 4: Premium Wordmark ⭐ RECOMMENDED
- **logo-4-premium-2400-large.png** (110 KB) - Print quality / High DPI
- **logo-4-premium-1600.png** (70 KB) - High resolution for web
- **logo-4-premium-800.png** (32 KB) - Standard web size

### Concept 5: Geometric Abstract
- **logo-5-geometric-800.png** (69 KB) - High resolution
- **logo-5-geometric-400.png** (32 KB) - Standard web size

## Use Cases by Size

### Profile Pictures / Icons (Square formats)
- **512x512** - Twitter, Discord, GitHub profile pictures
- **256x256** - App icons, favicons (larger)
- Use: `logo-2-minimal-x-512-square.png` or `logo-2-minimal-x-256-square.png`

### Social Media Posts
- **1200x1200** - Open Graph, Twitter cards, LinkedIn
- Use: `logo-3-network-1200-og.png`

### Website Headers / Banners
- **1600-2400px wide** - Website headers, hero sections
- Use: `logo-4-premium-1600.png` or `logo-4-premium-2400-large.png`

### General Web Use
- **800px** - Most common web applications
- Use any `*-800.png` file

### Documentation / Presentations
- **800px** - Good balance of quality and file size
- Use: `logo-1-hub-spoke-800.png` (technical) or `logo-4-premium-800.png` (general)

### Print Materials
- **2400px+** - Flyers, posters, banners
- Use: `logo-4-premium-2400-large.png`

## Quick Reference

| Use Case | Recommended File |
|----------|------------------|
| Twitter Profile | `logo-2-minimal-x-512-square.png` |
| Discord Server | `logo-2-minimal-x-512-square.png` |
| GitHub Profile | `logo-2-minimal-x-512-square.png` |
| Website Header | `logo-4-premium-1600.png` |
| Documentation | `logo-1-hub-spoke-800.png` |
| Presentations | `logo-4-premium-800.png` |
| Open Graph | `logo-3-network-1200-og.png` |
| Print Materials | `logo-4-premium-2400-large.png` |
| General Web | Any `*-800.png` |

## Converting Additional Sizes

If you need other sizes, use the SVG source files with `rsvg-convert`:

```bash
# Example: Convert to 1024px width
rsvg-convert ../logo-concept-4-premium.svg -w 1024 -o logo-4-premium-1024.png

# Example: Convert to specific height
rsvg-convert ../logo-concept-2-minimal-x.svg -h 512 -o logo-2-minimal-x-h512.png
```

## File Formats

### Available
- ✅ PNG (all files here) - Best for web, transparent backgrounds
- ✅ SVG (source files in parent directory) - Scalable, best quality

### Can Be Generated
- 🔄 JPEG - If you need smaller file sizes (no transparency)
- 🔄 WebP - Modern format, best compression
- 🔄 ICO - Windows icons
- 🔄 ICNS - macOS app icons

## Converting to JPEG

If you need JPEG versions (smaller file sizes, no transparency):

```bash
# Install ImageMagick if needed
sudo apt-get install imagemagick

# Convert PNG to JPEG
convert logo-4-premium-800.png -background white -flatten logo-4-premium-800.jpg
```

## Notes

- All PNGs maintain aspect ratio from SVG source
- Transparent backgrounds preserved
- High quality anti-aliasing applied
- Generated with librsvg2-bin (rsvg-convert)

---

**Generated:** 2025-11-23  
**Source:** `/workspace/usdx/docs/logo-concept-*.svg`
