const imagemin = require('imagemin');
const imageminMozjpeg = require('imagemin-mozjpeg');
const imageminPngquant = require('imagemin-pngquant');

async function optimizeImages() {
  try {
    const files = await imagemin(['static/img/**/*.{jpg,png}'], {
      destination: 'static/img/optimized',
      plugins: [
        imageminMozjpeg({ quality: 80 }),
        imageminPngquant({ quality: [0.6, 0.8] })
      ]
    });

    console.log('Images optimized:', files.length);
  } catch (error) {
    console.error('Error optimizing images:', error);
    // Don't fail the build if image optimization fails
    process.exit(0);
  }
}

optimizeImages(); 