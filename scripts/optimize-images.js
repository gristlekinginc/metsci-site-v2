const imagemin = require('imagemin');
const imageminWebp = require('imagemin-webp');
const imageminMozjpeg = require('imagemin-mozjpeg');
const imageminPngquant = require('imagemin-pngquant');

async function optimizeImages() {
  // Optimize JPG/PNG
  await imagemin(['static/img/**/*.{jpg,png}'], {
    destination: 'static/img/optimized',
    plugins: [
      imageminMozjpeg({ quality: 85 }),
      imageminPngquant({ quality: [0.6, 0.8] })
    ]
  });

  // Convert to WebP
  await imagemin(['static/img/**/*.{jpg,png}'], {
    destination: 'static/img/optimized',
    plugins: [
      imageminWebp({ quality: 85 })
    ]
  });
}

optimizeImages(); 