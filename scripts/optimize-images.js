const sharp = require('sharp');
const glob = require('glob');
const fs = require('fs-extra');

async function optimizeImages() {
  const images = glob.sync('static/img/**/*.{png,jpg,jpeg}');
  
  for (const image of images) {
    const optimized = await sharp(image)
      .resize(1200, 1200, {
        fit: 'inside',
        withoutEnlargement: true
      })
      .jpeg({ quality: 75 })
      .toBuffer();
      
    await fs.writeFile(image, optimized);
  }
}

optimizeImages(); 