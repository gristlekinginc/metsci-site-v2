const fs = require('fs').promises;
const path = require('path');
const sharp = require('sharp');

const MAX_WIDTH = 1200; // Maximum width we want for any image
const QUALITY = 80; // Quality setting for JPEG/PNG compression

async function optimizeAndGetDimensions(imagePath) {
  try {
    const metadata = await sharp(imagePath).metadata();
    
    // Only resize if image is wider than MAX_WIDTH
    if (metadata.width > MAX_WIDTH) {
      const resizedImage = await sharp(imagePath)
        .resize(MAX_WIDTH, null, { // null maintains aspect ratio
          withoutEnlargement: true
        })
        .jpeg({ quality: QUALITY })
        .toBuffer();
      
      // Save the optimized image back
      await fs.writeFile(imagePath, resizedImage);
      
      // Get new dimensions
      const newMetadata = await sharp(resizedImage).metadata();
      return {
        width: newMetadata.width,
        height: newMetadata.height
      };
    }
    
    return {
      width: metadata.width,
      height: metadata.height
    };
  } catch (error) {
    console.error(`Error processing ${imagePath}:`, error);
    return null;
  }
}

async function updateSingleFile() {
  // Updated test file path
  const testFile = 'docs/tutorial-basics/008-configure-a-device.md';
  
  try {
    console.log(`Processing ${testFile}...`);
    let content = await fs.readFile(testFile, 'utf8');
    const imageRegex = /!\[(.*?)\]\((.*?)\)(?!\{)/g;
    let modified = false;
    let matches = [...content.matchAll(imageRegex)];
    
    console.log(`Found ${matches.length} images in file`);
    
    for (const match of matches) {
      const [fullMatch, alt, src] = match;
      console.log(`Processing image: ${src}`);
      
      // Get full path to image
      const imagePath = path.join('static', src.startsWith('/') ? src.slice(1) : src);
      console.log(`Looking for image at: ${imagePath}`);
      
      try {
        const dimensions = await optimizeAndGetDimensions(imagePath);
        if (dimensions) {
          console.log(`Dimensions after optimization: ${dimensions.width}x${dimensions.height}`);
          const replacement = `![${alt}](${src}) <!-- width=${dimensions.width} height=${dimensions.height} -->`;
          content = content.replace(fullMatch, replacement);
          modified = true;
        }
      } catch (error) {
        console.error(`Could not process ${imagePath}:`, error);
      }
    }

    if (modified) {
      // Create a backup of the original file
      await fs.writeFile(`${testFile}.backup`, await fs.readFile(testFile));
      await fs.writeFile(testFile, content, 'utf8');
      console.log(`Updated: ${testFile}`);
    } else {
      console.log('No changes were needed');
    }
    
  } catch (error) {
    console.error(`Error processing file:`, error);
  }
}

// Run the script
console.log('Starting test run...');
updateSingleFile().then(() => {
  console.log('Finished test run');
}).catch(console.error); 